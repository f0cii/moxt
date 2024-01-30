from base.c import *
from base.mo import *
from base.thread import RWLock
from core.bybitmodel import *
from trade.base_strategy import *
from trade.config import AppConfig
from trade.platform import *
from .grid_utils import *


struct SmartGridStrategy(BaseStrategy):
    var platform: Platform
    var grid: GridInfo
    var category: String
    var symbols: list[String]
    var symbol: String
    var tick_size: Fixed
    var step_size: Fixed
    var config: AppConfig
    var grid_interval: String
    var order_qty: String
    # 总体止损百分比
    var total_sl_percent: Fixed
    # 单个格子止损百分比
    var cell_sl_percent: Fixed
    var rwlock: RWLock

    fn __init__(inout self, config: AppConfig) raises:
        logi("SmartGridStrategy.__init__")
        self.platform = Platform(config)
        self.grid = GridInfo()
        self.category = config.category
        self.symbols = safe_split(config.symbols, ",")
        self.symbol = self.symbols[0]
        self.tick_size = Fixed.zero
        self.step_size = Fixed.zero
        self.config = config
        self.grid_interval = config.params["grid_interval"]
        self.order_qty = config.params["order_qty"]
        self.total_sl_percent = Fixed(config.params["total_sl_percent"])
        self.cell_sl_percent = Fixed(config.params["cell_sl_percent"])
        self.rwlock = RWLock()
        logi("SmartGridStrategy.__init__ done")

    fn __moveinit__(inout self, owned existing: Self):
        logi("SmartGridStrategy.__moveinit__")
        self.platform = existing.platform ^
        self.grid = existing.grid ^
        self.category = existing.category
        self.symbols = existing.symbols
        self.symbol = existing.symbol
        self.tick_size = existing.tick_size
        self.step_size = existing.step_size
        self.config = existing.config
        self.grid_interval = existing.grid_interval
        self.order_qty = existing.order_qty
        self.total_sl_percent = existing.total_sl_percent
        self.cell_sl_percent = existing.cell_sl_percent
        self.rwlock = existing.rwlock

    fn setup(inout self) raises:
        self.platform.setup()

    fn on_update_orderbook(
        inout self,
        symbol: String,
        type_: String,
        inout asks: list[OrderBookLevel],
        inout bids: list[OrderBookLevel],
    ) raises:
        self.platform.on_update_orderbook(symbol, type_, asks, bids)

    fn on_update_order(inout self, order: Order) raises:
        _ = self.platform.on_update_order(order)

    fn get_orderbook(self, symbol: String, n: Int) raises -> OrderBookLite:
        return self.platform.get_orderbook(symbol, n)

    fn on_init(inout self) raises:
        logi("SmartGridStrategy.on_init")

        # 撤销订单
        _ = self.platform.cancel_orders_enhanced(self.category, self.symbol)
        # 全部平仓
        _ = self.platform.close_positions_enhanced(self.category, self.symbol)

        let exchange_info = self.platform.fetch_exchange_info(
            self.category, self.symbol
        )
        logi(str(exchange_info))

        let tick_size = Fixed(exchange_info.tick_size)
        let step_size = Fixed(exchange_info.step_size)
        # logi("tick_size: " + str(tick_size))
        # logi("step_size: " + str(step_size))
        # self.tick_size.copy_from(tick_size)
        # self.step_size.copy_from(step_size)
        self.tick_size = tick_size
        self.step_size = step_size
        let dp = decimal_places(tick_size.to_float())

        # 获取盘口价格
        let ob = self.platform.fetch_orderbook(self.category, self.symbol, 5)
        if len(ob.asks) == 0 or len(ob.bids) == 0:
            raise Error("获取盘口数据失败")

        let ask = Fixed(ob.asks[0].price)
        let bid = Fixed(ob.bids[0].price)
        logi("ask=" + str(ask) + " bid=" + str(bid))
        let mid = (ask + bid) / Fixed(2)
        logi("mid=" + str(mid))
        let base_price = mid.round(dp)
        logi("base_price=" + str(base_price))
        let grid_interval = Fixed(self.grid_interval)
        let price_range = Fixed("0.15")
        logi("grid_interval=" + str(grid_interval))
        logi("price_range=" + str(price_range))
        logi("tick_size=" + str(tick_size))
        logi("dp=" + str(dp))

        self.grid.setup(grid_interval, price_range, tick_size, base_price, dp)
        logi(str(self.grid))

        logi("SmartGridStrategy.on_init done")

    fn on_exit(inout self) raises:
        logi("SmartGridStrategy.on_exit")
        # 撤销订单
        _ = self.platform.cancel_orders_enhanced(self.category, self.symbol)
        # 全部平仓
        _ = self.platform.close_positions_enhanced(self.category, self.symbol)
        logi("SmartGridStrategy.on_exit done")

    fn on_tick(inout self) raises:
        # logd("SmartGridStrategy.on_tick")
        let ob = self.platform.get_orderbook(self.symbol, 5)
        if len(ob.asks) == 0 or len(ob.bids) == 0:
            logw("订单薄缺少买卖单")
            return

        let ask = ob.asks[0]
        let bid = ob.bids[0]

        let cell_profits = self.calculate_cell_profits(
            ask.price, bid.price, PositionIdx.both_side_buy
        )
        # 判断单个格子止损条件
        for index in range(len(cell_profits)):
            let item = cell_profits[index]
            let level = item.get[0, Int]()
            let profit = item.get[1, Float64]()
            if profit <= -self.cell_sl_percent.to_float():
                logi("触发单个格子止损，停止格子 {level} 的交易")
                self.stop_cell_trading(level)

        let mid = (ask.price + bid.price) / Fixed(2)
        let current_cell_level = self.grid.get_cell_level_by_price(mid)
        # logi("current_cell_level=" + str(current_cell_level))

        self.place_buy_orders(current_cell_level)
        self.place_tp_orders()

        self.grid.update(mid)

    fn calculate_total_profit(
        self, ask: Fixed, bid: Fixed, position_idx: PositionIdx
    ) raises -> Float64:
        # 计算总体浮亏
        var total_profit: Float64 = 0
        for cell_ptr in self.grid.cells:
            # 计算每个格子的浮亏并累加
            total_profit += __get_address_as_lvalue(cell_ptr.value).calculate_profit_amount(ask, bid, position_idx)
        return total_profit

    fn calculate_cell_profits(
        self, ask: Fixed, bid: Fixed, position_idx: PositionIdx
    ) raises -> list[Tuple[Int, Float64]]:
        """
        计算各格子浮盈
        """
        var cell_profits = list[Tuple[Int, Float64]]()

        for index in range(len(self.grid.cells)):
            let cell = self.grid.cells[index]
            # 计算每个格子的浮亏并添加到列表中
            cell_profits.append(
                (index, cell.calculate_profit_percentage(ask, bid, position_idx))
            )
        return cell_profits

    fn stop_strategy(self) raises:
        # 添加总体止损的停止策略逻辑
        logi("执行总体止损的停止策略")
        # ...

    fn stop_cell_trading(inout self, index: Int) raises:
        # 添加单个格子止损的停止策略逻辑
        logi("执行单个格子止损的停止策略，停止格子 " + str(index) + " 的交易")
        let cell = self.grid.cells[index]
        # 撤销止盈单
        if cell.long_tp_cid != "":
            let res = self.platform.cancel_order(
                self.category, self.symbol, order_client_id=cell.long_tp_cid
            )
            logi("撤销止盈单返回: " + str(res))
        self.reset_cell(index, PositionIdx.both_side_buy)

    fn place_buy_orders(inout self, current_cell_level: Int) raises:
        for index in range(len(self.grid.cells)):
            # let cell = self.grid.cells[index]
            let cell_ptr = self.grid.cells.unsafe_get(index)
            if self.is_within_buy_range(__get_address_as_lvalue(cell_ptr.value), current_cell_level):
                self.place_buy_order(index, __get_address_as_lvalue(cell_ptr.value) )

    # 判断网格单元是否在买单范围内
    fn is_within_buy_range(self, inout cell: GridCellInfo, current_cell_level: Int) -> Bool:
        let buy_range = 3  # 定义买单的范围，可以根据实际情况调整
        return current_cell_level - buy_range <= cell.level <= current_cell_level

    fn place_buy_order(inout self, index: Int, inout cell: GridCellInfo) raises:
        """
        下开仓单
        """
        if cell.long_open_status != OrderStatus.empty:
            return

        let side = String("Buy")
        let order_type = String("Limit")
        let qty = self.order_qty
        let price = str(cell.price)
        let position_idx: Int = int(PositionIdx.both_side_buy)
        let order_client_id = self.platform.generate_order_id()
        logi(
            "下单 "
            + side
            + " "
            + qty
            + "@0"
            + " order_client_id="
            + order_client_id
            + " order_type="
            + order_type
            + " position_idx="
            + str(position_idx)
        )
        let res = self.platform.place_order(
            self.category,
            self.symbol,
            side=side,
            order_type=order_type,
            qty=qty,
            price=price,
            position_idx=position_idx,
            order_client_id=order_client_id,
        )
        logi("下单返回: " + str(res))
        cell.long_open_cid = order_client_id
        cell.long_open_status = OrderStatus.new
        logi("更新订单号")

    fn place_tp_orders(inout self) raises:
        """
        下止盈单
        """
        for index in range(len(self.grid.cells)):
            let cell = self.grid.cells[index]
            if cell.long_open_status == OrderStatus.filled:
                if cell.long_tp_cid == "":
                    logi("下止盈单")
                    self.place_tp_order(index, cell)
                elif cell.long_tp_status.is_closed():
                    logi("清理网格")
                    self.reset_cell(index, PositionIdx.both_side_buy)

    fn place_tp_order(inout self, index: Int, cell: GridCellInfo) raises:
        let side = String("Sell")
        let order_type = String("Limit")
        let qty = str(cell.long_open_quantity)
        let price = str(self.grid.get_price_by_level(cell.level + 1))
        logi("下止盈单: " + str(cell.price) + ">" + price)
        let position_idx: Int = int(PositionIdx.both_side_buy)
        let order_client_id = self.platform.generate_order_id()
        logi(
            "下止盈单 "
            + side
            + " "
            + qty
            + "@0"
            + " order_client_id="
            + order_client_id
            + " order_type="
            + order_type
            + " position_idx="
            + str(position_idx)
        )
        let res = self.platform.place_order(
            self.category,
            self.symbol,
            side=side,
            order_type=order_type,
            qty=qty,
            price=price,
            position_idx=position_idx,
            order_client_id=order_client_id,
        )
        logi("下平仓单返回: " + str(res))
        self.grid.cells[index].set_long_tp_cid(order_client_id)
        self.grid.cells[index].set_long_tp_status(OrderStatus.new)
        logi("更新订单号")

    fn reset_cell(inout self, index: Int, position_idx: PositionIdx) raises:
        if position_idx == PositionIdx.both_side_buy:
            let cids = self.grid.cells[index].reset_long_side()
            self.platform.delete_orders_from_cache(cids)
        elif position_idx == PositionIdx.both_side_sell:
            let cids = self.grid.cells[index].reset_short_side()
            self.platform.delete_orders_from_cache(cids)

    fn on_orderbook(inout self, ob: OrderBookLite) raises:
        if len(ob.asks) > 0 and len(ob.bids) > 0:
            # logd(
            #     "SmartGridStrategy.on_orderbook ask="
            #     + str(ob.asks[0].qty)
            #     + "@"
            #     + str(ob.asks[0].price)
            #     + " bid="
            #     + str(ob.bids[0].qty)
            #     + "@"
            #     + str(ob.bids[0].price)
            # )
            pass
        else:
            logd(
                "SmartGridStrategy.on_orderbook len(asks)="
                + str(len(ob.asks))
                + " len(bids)="
                + str(len(ob.bids))
            )

    fn on_order(inout self, order: Order) raises:
        logd("SmartGridStrategy.on_order " + str(order))

        self.rwlock.lock()

        for i in range(len(self.grid.cells)):
            let cell = self.grid.cells[i]
            let order_client_id = order.order_client_id
            if cell.long_open_cid == order_client_id:
                self.grid.cells[i].long_open_status = order.status
                break
            elif cell.long_tp_cid == order_client_id:
                self.grid.cells[i].long_tp_status = order.status
                break
            elif cell.long_sl_cid == order_client_id:
                self.grid.cells[i].long_sl_status = order.status
                break
            elif cell.short_open_cid == order_client_id:
                self.grid.cells[i].short_open_status = order.status
                break
            elif cell.short_tp_cid == order_client_id:
                self.grid.cells[i].short_tp_status = order.status
                break
            elif cell.short_sl_cid == order_client_id:
                self.grid.cells[i].short_sl_status = order.status
                break

        self.rwlock.unlock()

    fn on_position(inout self, position: PositionInfo) raises:
        logd("SmartGridStrategy.on_position " + str(position))
