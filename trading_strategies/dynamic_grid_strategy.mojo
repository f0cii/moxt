from base.c import *
from base.mo import *
from base.thread import RWLock
from core.bybitmodel import *
from trade.base_strategy import *
from trade.config import AppConfig
from trade.platform import *
from .grid_utils import *


struct DynamicGridStrategy(BaseStrategy):
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
    var rwlock: RWLock

    fn __init__(inout self, config: AppConfig) raises:
        logi("DynamicGridStrategy.__init__")
        self.platform = Platform(config)
        self.grid = GridInfo()
        self.category = config.category
        self.symbols = safe_split(config.symbols, ",")
        self.symbol = self.symbols[0]
        self.tick_size = Fixed(0)
        self.step_size = Fixed(0)
        self.config = config
        self.grid_interval = config.params["grid_interval"]
        self.order_qty = config.params["order_qty"]
        self.rwlock = RWLock()
        logi("DynamicGridStrategy.__init__ done")

    fn __moveinit__(inout self, owned existing: Self):
        logi("DynamicGridStrategy.__moveinit__")
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
        self.platform.on_update_order(order)

    fn get_orderbook(self, symbol: String, n: Int) raises -> OrderBookLite:
        return self.platform.get_orderbook(symbol, n)

    fn on_init(inout self) raises:
        logi("DynamicGridStrategy.on_init")

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

        logi("DynamicGridStrategy.on_init done")

    fn on_exit(inout self) raises:
        logi("DynamicGridStrategy.on_exit")
        # 撤销订单
        _ = self.platform.cancel_orders_enhanced(self.category, self.symbol)
        # 全部平仓
        _ = self.platform.close_positions_enhanced(self.category, self.symbol)
        logi("DynamicGridStrategy.on_exit done")

    fn on_tick(inout self) raises:
        # logd("DynamicGridStrategy.on_tick")
        let ob = self.platform.get_orderbook(self.symbol, 5)
        if len(ob.asks) == 0 or len(ob.bids) == 0:
            logw("订单薄缺少买卖单")
            return

        let ask = ob.asks[0]
        let bid = ob.bids[0]
        let mid = (ask.price + bid.price) / Fixed(2)
        let current_cell_level = self.grid.get_cell_level_by_price(mid)
        # logi("current_cell_level=" + str(current_cell_level))

        self.place_buy_orders(current_cell_level)
        self.place_tp_orders()

        self.grid.update(mid)

    fn place_buy_orders(inout self, current_cell_level: Int) raises:
        for index in range(len(self.grid.cells)):
            let cell = self.grid.cells[index]
            if self.is_within_buy_range(cell.level, current_cell_level):
                self.place_buy_order(index, cell)

    # 判断网格单元是否在买单范围内
    fn is_within_buy_range(self, cell_level: Int, current_cell_level: Int) -> Bool:
        let buy_range = 3  # 定义买单的范围，可以根据实际情况调整
        return current_cell_level - buy_range <= cell_level <= current_cell_level

    fn place_buy_order(inout self, index: Int, cell: GridCellInfo) raises:
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
        let client_order_id = self.platform.generate_order_id()
        logi(
            "下单 "
            + side
            + " "
            + qty
            + "@0"
            + " client_order_id="
            + client_order_id
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
            client_order_id=client_order_id,
        )
        logi("下单返回: " + str(res))
        self.grid.cells[index].set_long_open_cid(client_order_id)
        self.grid.cells[index].set_long_open_status(OrderStatus.new)
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
        let client_order_id = self.platform.generate_order_id()
        logi(
            "下止盈单 "
            + side
            + " "
            + qty
            + "@0"
            + " client_order_id="
            + client_order_id
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
            client_order_id=client_order_id,
        )
        logi("下平仓单返回: " + str(res))
        self.grid.cells[index].set_long_tp_cid(client_order_id)
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
            #     "DynamicGridStrategy.on_orderbook ask="
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
                "DynamicGridStrategy.on_orderbook len(asks)="
                + str(len(ob.asks))
                + " len(bids)="
                + str(len(ob.bids))
            )

    fn on_order(inout self, order: Order) raises:
        logd("DynamicGridStrategy.on_order " + str(order))

        self.rwlock.lock()

        for i in range(len(self.grid.cells)):
            let cell = self.grid.cells[i]
            let client_order_id = order.client_order_id
            if cell.long_open_cid == client_order_id:
                self.grid.cells[i].long_open_status = order.status
                break
            elif cell.long_tp_cid == client_order_id:
                self.grid.cells[i].long_tp_status = order.status
                break
            elif cell.long_sl_cid == client_order_id:
                self.grid.cells[i].long_sl_status = order.status
                break
            elif cell.short_open_cid == client_order_id:
                self.grid.cells[i].short_open_status = order.status
                break
            elif cell.short_tp_cid == client_order_id:
                self.grid.cells[i].short_tp_status = order.status
                break
            elif cell.short_sl_cid == client_order_id:
                self.grid.cells[i].short_sl_status = order.status
                break

        self.rwlock.unlock()

    fn on_position(inout self, position: PositionInfo) raises:
        logd("DynamicGridStrategy.on_position " + str(position))
