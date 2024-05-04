from testing import assert_equal, assert_true, assert_false
from ylstdlib import *
from base.c import *
from base.mo import *
from base.thread import RWLock
from base.globals import _GLOBAL
from core.bybitmodel import *
from trade.base_strategy import *
from trade.config import AppConfig
from trade.platform import *
from .grid_utils import *


# 交易上下文
struct IContext:
    var ask: Fixed
    var bid: Fixed
    var mid: Fixed
    var current_cell_level: Int
    var cell_sl_percent: Fixed
    var cell_index: Int  # 当前格子索引

    fn __init__(inout self):
        self.ask = Fixed.zero
        self.bid = Fixed.zero
        self.mid = Fixed.zero
        self.current_cell_level = 0
        self.cell_sl_percent = Fixed.zero
        self.cell_index = 0


# 参数:
# symbols: "BTCUSDT"
# category: "linear"
# grid_interval: 0.01
# order_qty: 0.001
# total_sl_percent: 0.1
# cell_sl_percent: 0.05
# 是否允许交易
# allow_trade: True

# grid_interval = 0.01
# order_qty = 0.001
# # 设置总体止损百分比
# total_sl_percent = 0.1
# # 设置单个格子止损百分比
# cell_sl_percent = 0.05


# 交易策略
struct GridStrategy(BaseStrategy):
    var platform: Platform
    var grid: GridInfo
    var category: String
    var symbols: List[String]
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
    var allow_trade: Bool
    var order_q: Queue[Order]
    var rwlock: RWLock
    var stop_flag: Bool

    fn __init__(inout self, config: AppConfig) raises:
        logi("GridStrategy.__init__")
        self.platform = Platform(config)
        self.grid = GridInfo()
        self.category = config.category
        self.symbols = config.symbols.split(",")
        if len(self.symbols) == 0:
            raise "symbols is empty"
        self.symbol = self.symbols[0]
        self.tick_size = Fixed.zero
        self.step_size = Fixed.zero
        self.config = config
        if "grid_interval" not in config.params:
            raise "grid_interval is empty"
        if "order_qty" not in config.params:
            raise "order_qty is empty"
        if "total_sl_percent" not in config.params:
            raise "total_sl_percent is empty"
        if "cell_sl_percent" not in config.params:
            raise "cell_sl_percent is empty"
        if "allow_trade" not in config.params:
            raise "allow_trade is empty"
        for i in config.params:
            logi("param: " + i[] + "=" + config.params[i[]])
        self.grid_interval = config.params["grid_interval"]
        self.order_qty = config.params["order_qty"]
        self.total_sl_percent = Fixed(config.params["total_sl_percent"])
        self.cell_sl_percent = Fixed(config.params["cell_sl_percent"])
        var allow_trade_str = config.params["allow_trade"]
        self.allow_trade = (
            allow_trade_str == "true" or allow_trade_str == "True"
        )
        self.order_q = Queue[Order](100)
        self.rwlock = RWLock()
        self.stop_flag = False
        logi("GridStrategy.__init__ done")

    fn __moveinit__(inout self, owned existing: Self):
        logi("GridStrategy.__moveinit__")
        self.platform = existing.platform^
        self.grid = existing.grid^
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
        self.allow_trade = existing.allow_trade
        self.order_q = existing.order_q
        self.rwlock = existing.rwlock
        self.stop_flag = False

    fn setup(inout self) raises:
        # var algo_id = _GLOBAL()[].algo_id
        # log.log_itf["MAIN"]()[].set_alog_id(algo_id)
        self.platform.setup()
        var callback = self.get_order_update_callback()
        self.platform.register_order_update_callback(callback^)

    fn get_order_update_callback(self) -> OrderUpdateCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper(ord: Order):
            try:
                self_ptr[].on_order(ord)
            except err:
                pass

        return wrapper

    fn get_platform_pointer(inout self) -> UnsafePointer[Platform]:
        return UnsafePointer.address_of(self.platform)

    fn on_init(inout self) raises:
        logi("GridStrategy.on_init")

        if self.allow_trade:
            # 撤销订单
            _ = self.platform.cancel_orders_enhanced(self.category, self.symbol)
            # 全部平仓
            _ = self.platform.close_positions_enhanced(
                self.category, self.symbol
            )

        var exchange_info = self.platform.fetch_exchange_info(
            self.category, self.symbol
        )
        logi(str(exchange_info))

        var tick_size: Fixed = exchange_info.tick_size
        var step_size = Fixed(exchange_info.step_size)
        # logi("tick_size: " + str(tick_size))
        # logi("step_size: " + str(step_size))
        # self.tick_size.copy_from(tick_size)
        # self.step_size.copy_from(step_size)
        self.tick_size = tick_size
        self.step_size = step_size
        var dp = decimal_places(tick_size.to_float())

        # 获取盘口价格
        var ob = self.platform.fetch_orderbook(self.category, self.symbol, 5)
        if len(ob.asks) == 0 or len(ob.bids) == 0:
            raise Error("获取盘口数据失败")

        var ask = Fixed(ob.asks[0].price)
        var bid = Fixed(ob.bids[0].price)
        logi("ask=" + str(ask) + " bid=" + str(bid))
        var mid = (ask / Fixed(2)) + (bid / Fixed(2))
        logi("mid=" + str(mid))
        var base_price = mid.round(dp)
        var grid_interval = Fixed(self.grid_interval)
        var price_range = Fixed("0.15")

        logi("grid_interval=" + str(grid_interval))
        logi("price_range=" + str(price_range))
        logi("tick_size=" + str(tick_size))
        logi("base_price=" + str(base_price))
        logi("dp=" + str(dp))

        self.grid.setup(grid_interval, price_range, tick_size, base_price, dp)
        # logi(str(self.grid))

        # 输出网格
        for i in self.grid.cells:
            logi(str(i[]))

        # TODO: 等待网格生成
        sleep(10)

        logi("GridStrategy.on_init done")

    fn on_exit(inout self) raises:
        logi("GridStrategy.on_exit")
        if self.allow_trade:
            # 撤销订单
            _ = self.platform.cancel_orders_enhanced(self.category, self.symbol)
            # 全部平仓
            _ = self.platform.close_positions_enhanced(
                self.category, self.symbol
            )
        logi("GridStrategy.on_exit done")

    fn on_tick(inout self) raises:
        # logd("GridStrategy.on_tick")
        var ob = self.platform.get_orderbook(self.symbol, 5)
        if len(ob.asks) == 0 or len(ob.bids) == 0:
            # logw("订单薄缺少买卖单")
            return

        # logi("ask=" + str(ob.asks[0].price) + " bid=" + str(ob.bids[0].price))

        self.process_order_event()

        var ctx = IContext()
        ctx.ask = ob.asks[0].price
        ctx.bid = ob.bids[0].price
        ctx.mid = (ctx.ask / Fixed(2)) + (ctx.bid / Fixed(2))
        ctx.current_cell_level = self.grid.get_cell_level_by_price(ctx.mid)
        ctx.cell_sl_percent = Fixed.zero - self.cell_sl_percent

        for i in range(len(self.grid.cells)):
            ctx.cell_index = i
            var ref = self.grid.cells.__get_ref(i)
            self.on_tick_one(ctx, ref)

        self.grid.update(ctx.mid)

    fn on_tick_one[
        L: MutLifetime
    ](
        inout self, inout ctx: IContext, cell: Reference[GridCellInfo, i1, L]
    ) raises:
        if not self.allow_trade:
            return

        # 判断单个格子止损条件
        self.process_cell_sl_one(
            ctx,
            cell,
            PositionIdx.both_side_buy,
        )

        self.place_buy_order(ctx, cell)
        self.place_tp_order(ctx, cell)

    fn calculate_total_profit(
        self, ask: Fixed, bid: Fixed, position_idx: PositionIdx
    ) raises -> Float64:
        # 计算总体浮亏
        var total_profit: Float64 = 0
        for i in self.grid.cells:
            # 计算每个格子的浮亏并累加
            total_profit += i[].calculate_profit_amount(ask, bid, position_idx)
        return total_profit

    fn calculate_cell_profits(
        self, ask: Fixed, bid: Fixed, position_idx: PositionIdx
    ) raises -> List[Tuple[Int, Fixed]]:
        """
        计算各格子浮盈
        """
        var cell_profits = List[Tuple[Int, Fixed]]()

        for index in range(len(self.grid.cells)):
            var cell = self.grid.cells[index]
            # 计算每个格子的浮亏并添加到列表中
            cell_profits.append(
                (
                    index,
                    cell.calculate_profit_percentage(ask, bid, position_idx),
                )
            )
        return cell_profits

    fn stop_strategy(inout self) raises:
        # 添加总体止损的停止策略逻辑
        logi("执行总体止损的停止策略")
        self.stop_flag = True

    fn process_cell_sl_one[
        L: MutLifetime
    ](
        inout self,
        ctx: IContext,
        cell: Reference[GridCellInfo, i1, L],
        position_idx: PositionIdx,
    ) raises:
        var profit = cell[].calculate_profit_percentage(
            ctx.ask, ctx.bid, position_idx
        )
        if profit <= ctx.cell_sl_percent:
            logi(
                "触发单个格子止损，停止格子 {index} 的交易 ["
                + str(profit)
                + "] <= ["
                + ctx.cell_sl_percent
                + "]"
            )
            self.stop_cell_trading(cell)

    fn stop_cell_trading[
        L: MutLifetime
    ](inout self, cell: Reference[GridCellInfo, i1, L]) raises:
        # 添加单个格子止损的停止策略逻辑
        logi("执行单个格子止损的停止策略，停止格子 " + str(cell[].level) + " 的交易")
        # 撤销止盈单
        if cell[].long_tp_cid != "":
            var order = self.platform.cancel_order(
                self.category,
                self.symbol,
                order_client_id=cell[].long_tp_cid,
                fetch_full_info=True,
            )
            logi("撤销止盈单返回: " + str(order))
            # 获取订单状态
            if cell[].long_tp_cid != order.order_client_id:
                logw(
                    "撤单返回的id不同 cid=["
                    + cell[].long_tp_cid
                    + "], 返回: "
                    + str(order)
                )
            if not order.status.is_closed():
                logw("撤单后订单状态错误: " + str(order))
            if order.filled_qty > Fixed.zero:
                cell[].long_filled_qty -= order.filled_qty
                # cell.set_long_filled_qty() -= order.filled_qty

        self.reset_cell(cell, PositionIdx.both_side_buy)

    # 判断网格单元是否在买单范围内
    fn is_within_buy_range(
        self, cell: GridCellInfo, current_cell_level: Int
    ) -> Bool:
        var buy_range = 3  # 定义买单的范围，可以根据实际情况调整
        return (
            current_cell_level - buy_range <= cell.level <= current_cell_level
        )

    fn place_buy_order[
        L: MutLifetime
    ](inout self, ctx: IContext, cell: Reference[GridCellInfo, i1, L]) raises:
        """
        下开仓单
        """
        if cell[].long_open_status != OrderStatus.empty:
            return

        if not self.is_within_buy_range(cell[], ctx.current_cell_level):
            return

        var side = String("Buy")
        var order_type = String("Limit")
        var qty = self.order_qty
        logi("下单价格: " + str(cell[].price))
        var price = str(cell[].price)
        var position_idx: Int = int(PositionIdx.both_side_buy)
        var order_client_id = self.platform.generate_order_id()
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
        var res = self.platform.place_order(
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
        cell[].long_open_cid = order_client_id
        cell[].long_open_status = OrderStatus.new
        logi("更新订单号")

    fn place_tp_order[
        L: MutLifetime
    ](inout self, ctx: IContext, cell: Reference[GridCellInfo, i1, L]) raises:
        """
        下止盈单
        """
        if cell[].long_open_status == OrderStatus.filled:
            if cell[].long_tp_cid == "":
                logi("下止盈单")
                self.place_tp_order_real(cell)
            elif cell[].long_tp_status.is_closed():
                logi("清理网格 订单状态: " + str(cell[].long_tp_status))
                self.reset_cell(cell, PositionIdx.both_side_buy)

    fn place_tp_order_real[
        L: MutLifetime
    ](inout self, cell: Reference[GridCellInfo, i1, L]) raises:
        var side = String("Sell")
        var order_type = String("Limit")
        var qty = str(cell[].long_open_quantity)
        var price = str(self.grid.get_price_by_level(cell[].level + 1))
        logi("下止盈单: " + str(cell[].price) + ">" + price)
        var position_idx: Int = int(PositionIdx.both_side_buy)
        var order_client_id = self.platform.generate_order_id()
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
        var res = self.platform.place_order(
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
        cell[].long_tp_cid = order_client_id
        cell[].long_tp_status = OrderStatus.new
        logi("更新订单号")
        assert_equal(cell[].long_tp_cid, order_client_id)
        assert_equal(str(cell[].long_tp_status), str(OrderStatus.new))

    fn reset_cell[
        L: MutLifetime
    ](
        inout self,
        cell: Reference[GridCellInfo, i1, L],
        position_idx: PositionIdx,
    ) raises:
        if position_idx == PositionIdx.both_side_buy:
            var cids = cell[].reset_long_side()
            self.platform.delete_orders_from_cache(cids)
        elif position_idx == PositionIdx.both_side_sell:
            var cids = cell[].reset_short_side()
            self.platform.delete_orders_from_cache(cids)

    fn on_orderbook(inout self, ob: OrderBookLite) raises:
        if len(ob.asks) > 0 and len(ob.bids) > 0:
            # logd(
            #     "GridStrategy.on_orderbook ask="
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
                "GridStrategy.on_orderbook len(asks)="
                + str(len(ob.asks))
                + " len(bids)="
                + str(len(ob.bids))
            )

    fn on_order(inout self, order: Order) raises:
        logd("GridStrategy.on_order " + str(order))

        self.rwlock.lock()
        self.order_q.enqueue(order)
        self.rwlock.unlock()

    fn process_order_event(inout self):
        self.rwlock.lock()
        while True:
            var order_opt = self.order_q.dequeue()
            if not order_opt:
                break
            for i in range(len(self.grid.cells)):
                var ref = self.grid.cells.__get_ref(i)
                if self.on_order_cell(ref, order_opt.value()[]):
                    break
        self.rwlock.unlock()

    @staticmethod
    fn on_order_cell[
        L: MutLifetime
    ](cell: Reference[GridCellInfo, i1, L], order: Order) -> Bool:
        var order_client_id = order.order_client_id
        if cell[].long_open_cid == order_client_id:
            cell[].long_open_status = order.status
            return True
        elif cell[].long_tp_cid == order_client_id:
            cell[].long_tp_status = order.status
            return True
        elif cell[].long_sl_cid == order_client_id:
            cell[].long_sl_status = order.status
            return True
        elif cell[].short_open_cid == order_client_id:
            cell[].short_open_status = order.status
            return True
        elif cell[].short_tp_cid == order_client_id:
            cell[].short_tp_status = order.status
            return True
        elif cell[].short_sl_cid == order_client_id:
            cell[].short_sl_status = order.status
            return True
        else:
            return False

    fn on_position(inout self, position: PositionInfo) raises:
        logd("GridStrategy.on_position " + str(position))
