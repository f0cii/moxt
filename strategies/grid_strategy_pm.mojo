from testing import assert_equal, assert_true, assert_false
from ylstdlib import *
from base.c import *
from base.mo import *
from base.thread import *
from base.moutil import time_ms
import base.log
from base.log import Args
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
    var cell_index: Int  # 当前格子索引

    fn __init__(inout self):
        self.ask = Fixed.zero
        self.bid = Fixed.zero
        self.mid = Fixed.zero
        self.current_cell_level = 0
        self.cell_index = 0


# 交易规则:
# 1.只做多
# 2.网格间距 0.5%
# 3.每次买入总资金的 1/50，每次最多总资金的2%
# 4.盈利或略微亏损时（比如亏损小于5% 持续时间24小时），不定期重置
# 5.止损线8%

# 6000 200
# 5000 卖出100 剩余100
# 4000 买入100 剩余200，均价 5000，止盈 5500
# 3000 卖出100，剩余100
# 2000 买入100，剩余200，均价

# 比如下降5%,则止损,卖出一半仓位 然后如果继续下降5%买入半仓，此时持仓成本降低
# 上涨 5%*0.6 则全部平仓

# 1,1,2,3,5,8,13


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

# 需要增加一个参数:
# account_type: String = "CONTRACT","UNIFIED"

# 下单错误:
# retCode=10006, retMsg=Too many visits


# 交易策略
struct GridStrategyPM(BaseStrategy):
    var platform: UnsafePointer[Platform]
    var grid: UnsafePointer[GridInfo]
    var account_type: String
    var category: String
    var symbols: List[String]
    var symbol: String
    var tick_size: Fixed
    var step_size: Fixed
    var min_order_qty: Fixed
    var min_notional_value: Fixed
    var step_dp: Int
    var config: AppConfig
    var grid_interval: String
    var order_qty: String
    # 定义下单数量，用总金额的一定比率
    var order_qty_pct: Fixed
    # 时间止损(ms)
    var time_sl_ms: Int64
    # 单个格子止损百分比
    var cell_sl_pct: Fixed
    # var allow_trade: Bool
    var order_q: Queue[Order]
    var rwlock: RWLock
    var stop_flag: Bool
    var debug: Bool
    var log_id: Int64

    fn __init__(inout self, config: AppConfig) raises:
        logi("GridStrategyPM.__init__")
        self.platform = UnsafePointer[Platform].alloc(1)
        self.platform.init_pointee_move(Platform(config))
        self.grid = UnsafePointer[GridInfo].alloc(1)
        self.grid.init_pointee_move(GridInfo())
        if "account_type" not in config.params:
            raise "account_type is empty"
        self.account_type = config.params["account_type"]
        if "category" not in config.params:
            raise "category is empty"
        self.category = config.params["category"]
        if "symbols" not in config.params:
            raise "symbols is empty"
        var symbols_str = config.params["symbols"]
        var symbols = symbols_str.split(",")
        if len(symbols) == 0:
            raise "symbols is empty"
        self.symbols = symbols
        self.symbol = symbols[0]
        self.tick_size = Fixed.zero
        self.step_size = Fixed.zero
        self.min_order_qty = Fixed.zero
        self.min_notional_value = Fixed.zero
        self.step_dp = 0
        self.config = config
        if "grid_interval" not in config.params:
            raise "grid_interval is empty"
        if "order_qty" not in config.params:
            raise "order_qty is empty"
        if "order_qty_pct" not in config.params:
            raise "order_qty_pct is empty"
        if "time_sl" not in config.params:
            raise "time_sl is empty"
        if "cell_sl_pct" not in config.params:
            raise "cell_sl_pct is empty"
        for i in config.params:
            logi("param: " + i[] + "=" + config.params[i[]])
        self.grid_interval = config.params["grid_interval"]
        self.order_qty = config.params["order_qty"]
        self.order_qty_pct = Fixed(config.params["order_qty_pct"])
        self.time_sl_ms = int(config.params["time_sl"]) * 1000
        self.cell_sl_pct = Fixed(config.params["cell_sl_pct"])
        self.order_q = Queue[Order](100)
        self.rwlock = RWLock()
        self.stop_flag = False
        self.debug = True
        self.log_id = 0
        # log.log_event("Init", 0, "BUY", Fixed("6000"), Fixed("0.001"))
        logi("GridStrategyPM.__init__ done")

    fn __moveinit__(inout self, owned existing: Self):
        logi("GridStrategyPM.__moveinit__")
        self.platform = existing.platform
        self.grid = existing.grid
        self.account_type = existing.account_type
        self.category = existing.category
        self.symbols = existing.symbols
        self.symbol = existing.symbol
        self.tick_size = existing.tick_size
        self.step_size = existing.step_size
        self.min_order_qty = existing.min_order_qty
        self.min_notional_value = existing.min_notional_value
        self.step_dp = existing.step_dp
        self.config = existing.config
        self.grid_interval = existing.grid_interval
        self.order_qty = existing.order_qty
        self.order_qty_pct = existing.order_qty_pct
        self.time_sl_ms = existing.time_sl_ms
        self.cell_sl_pct = existing.cell_sl_pct
        self.order_q = existing.order_q
        self.rwlock = existing.rwlock
        self.stop_flag = False
        self.debug = existing.debug
        self.log_id = existing.log_id

    fn setup(inout self, platform: UnsafePointer[Platform]) raises:
        var algo_id = _GLOBAL()[].algo_id
        log.log_itf["MAIN"]()[].set_alog_id(algo_id)
        self.platform = platform
        self.platform[].setup()
        var callback = self.get_order_update_callback()
        self.platform[].register_order_update_callback(callback^)

    fn get_log_context(inout self) -> Dict[String, Args]:
        var context = Dict[String, Args]()
        self.log_id += 1
        context["cid"] = self.log_id
        return context

    fn get_order_update_callback(self) -> OrderUpdateCallback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper(ord: Order):
            try:
                self_ptr[].on_order(ord)
            except err:
                pass

        return wrapper

    fn get_platform_pointer(inout self) -> UnsafePointer[Platform]:
        return self.platform

    fn on_init(inout self) raises:
        logi("GridStrategyPM.on_init")

        # 设置持仓模式为双向持仓
        self.platform[].set_position_mode(
            self.category, self.symbol, PositionMode.BothSides
        )

        # 撤销订单
        _ = self.platform[].cancel_orders_enhanced(self.category, self.symbol)
        # 全部平仓
        _ = self.platform[].close_positions_enhanced(self.category, self.symbol)

        # 设置杠杆倍数
        var ok = self.platform[].set_leverage(self.category, self.symbol, 5)
        if not ok:
            raise Error("设置杠杆倍数失败")

        var exchange_info = self.platform[].fetch_exchange_info(
            self.category, self.symbol
        )
        logi(str(exchange_info))

        var tick_size = exchange_info.tick_size
        var min_order_qty = exchange_info.min_order_qty
        var step_size = exchange_info.step_size
        var min_notional_value = exchange_info.min_notional_value
        # logi("tick_size: " + str(tick_size))
        # logi("step_size: " + str(step_size))
        # self.tick_size.copy_from(tick_size)
        # self.step_size.copy_from(step_size)
        self.tick_size = tick_size
        self.step_size = step_size
        self.min_order_qty = min_order_qty
        self.min_notional_value = min_notional_value
        var tick_dp = decimal_places(tick_size.to_float())
        self.step_dp = decimal_places(step_size.to_float())

        # 获取盘口价格
        var ob = self.platform[].fetch_orderbook(self.category, self.symbol, 5)
        if len(ob.asks) == 0 or len(ob.bids) == 0:
            raise Error("获取盘口数据失败")

        var ask = ob.asks[0].price
        var bid = ob.bids[0].price
        logi("ask=" + str(ask) + " bid=" + str(bid))
        var mid = (ask / Fixed(2)) + (bid / Fixed(2))
        logi("mid=" + str(mid))
        var base_price = mid.round(tick_dp)
        var grid_interval = Fixed(self.grid_interval)
        var price_range = Fixed("0.15")

        logi("grid_interval=" + str(grid_interval))
        logi("price_range=" + str(price_range))
        logi("tick_size=" + str(tick_size))
        logi("base_price=" + str(base_price))
        logi("dp=" + str(tick_dp))

        self.grid[].setup(
            grid_interval, price_range, tick_size, base_price, tick_dp
        )
        # logi(str(self.grid))

        # 输出网格
        for i in self.grid[].cells:
            logi(str(i[]))

        # 获取账户
        _ = self.platform[].fetch_accounts("USDT", self.account_type)

        logi("GridStrategyPM.on_init done")

    fn on_exit(inout self) raises:
        logi("GridStrategyPM.on_exit")
        # 撤销订单
        _ = self.platform[].cancel_orders_enhanced(self.category, self.symbol)
        # 全部平仓
        _ = self.platform[].close_positions_enhanced(self.category, self.symbol)
        logi("GridStrategyPM.on_exit done")

    fn on_tick(inout self) raises:
        # logd("GridStrategyPM.on_tick")
        var ob = self.platform[].get_orderbook(self.symbol, 5)
        if len(ob.asks) == 0 or len(ob.bids) == 0:
            # logw("订单薄缺少买卖单")
            return

        # logi("ask=" + str(ob.asks[0].price) + " bid=" + str(ob.bids[0].price))

        self.process_order_event()

        var ctx = IContext()
        ctx.ask = ob.asks[0].price
        ctx.bid = ob.bids[0].price
        ctx.mid = (ctx.ask / Fixed(2)) + (ctx.bid / Fixed(2))
        ctx.current_cell_level = self.grid[].get_cell_level_by_price(ctx.mid)
        # ctx.cell_sl_percent = Fixed.zero - self.cell_sl_percent

        for i in range(len(self.grid[].cells)):
            ctx.cell_index = i
            var cell_ref = Reference(self.grid[].cells[i])
            self.on_tick_one(ctx, cell_ref)

        self.grid[].update(ctx.mid)
    
    fn on_tick_one[L: MutableLifetime](inout self, inout ctx: IContext, cell: Reference[GridCellInfo, L]) raises:
        self.place_buy_order(ctx, cell)
        self.place_sell_order(ctx, cell)
        self.order_monitor(ctx, cell)

    fn calculate_total_profit(
        self, ask: Fixed, bid: Fixed, position_idx: PositionIdx
    ) raises -> Float64:
        # 计算总体浮亏
        var total_profit: Float64 = 0
        for i in self.grid[].cells:
            # 计算每个格子的浮亏并累加
            total_profit += i[].calculate_profit_amount(ask, bid, position_idx)
        return total_profit

    # 计算下单数量
    fn calc_lots(self, account: Account, price: Fixed) -> Fixed:
        if price == Fixed.zero:
            logi("price is zero")
            return Fixed.zero

        var am = account.available_margin()
        var lots = Fixed.zero
        if self.order_qty_pct > Fixed.zero:
            lots = am / price * self.order_qty_pct
        else:
            lots = self.order_qty
        var lots_ = lots.round(self.step_dp)

        if lots_ * price < self.min_notional_value:
            lots_ = (self.min_notional_value / price).round(self.step_dp)
            # lots_ = Fixed.zero
        if lots_ < self.min_order_qty:
            lots_ = self.min_order_qty
        if lots_ * price > am:
            lots_ = Fixed.zero

        # if lots_ > Fixed.zero:
        #     logi(
        #         "am="
        #         + str(am)
        #         + " price="
        #         + str(price)
        #         + " order_qty_percent="
        #         + str(self.order_qty_percent)
        #         + " step_dp="
        #         + str(self.step_dp)
        #         + " lots="
        #         + str(lots)
        #         + " lots_="
        #         + str(lots_)
        #     )

        return lots_

    fn stop_strategy(inout self) raises:
        # 添加总体止损的停止策略逻辑
        logi("执行总体止损的停止策略")
        self.stop_flag = True

    # 判断网格单元是否在买单范围内
    fn is_within_buy_range(
        self, cell: GridCellInfo, current_cell_level: Int
    ) -> Bool:
        var buy_range = 3  # 定义买单的范围，可以根据实际情况调整
        return (
            current_cell_level - cell.level <= buy_range
            and current_cell_level - cell.level >= 0
        )

    fn is_within_sell_range(
        self, cell: GridCellInfo, current_cell_level: Int
    ) -> Bool:
        var sell_range = 3  # 定义卖单的范围，可以根据实际情况调整
        return (
            current_cell_level - cell.level >= -sell_range
            and current_cell_level - cell.level <= 0
        )

    fn place_buy_order[
        L: MutableLifetime
    ](inout self, ctx: IContext, cell: Reference[GridCellInfo, L]) raises:
        """
        下开仓单.
        """
        if (
            cell[].long_open_status != OrderStatus.empty
            or cell[].long_open_cid != ""
        ):
            return

        if cell[].price >= ctx.ask:
            return

        if not self.is_within_buy_range(cell[], ctx.current_cell_level):
            return

        var side = String("Buy")
        var order_type = String("Limit")

        var a = self.platform[].get_account("USDT")
        if a is None:
            logi("no account")
            return

        # var qty = self.order_qty
        var account = a.value()
        var qty = self.calc_lots(account, ctx.mid)
        if qty == Fixed.zero:
            # logi("qty is zero")
            return

        # logi("下单价格: " + str(cell[].price) + " 数量: " + str(qty))
        var price = str(cell[].price)
        var position_idx: Int = int(PositionIdx.both_side_buy)
        var order_client_id = self.platform[].generate_order_id()

        logi(
            "level="
            + str(cell[].level)
            + " 下单 "
            + side
            + " "
            + str(qty)
            + "@"
            + price
            + " order_client_id="
            + order_client_id
            + " order_type="
            + order_type
            + " position_idx="
            + str(position_idx)
            # + " account="
            # + str(account)
            + " long_open_cid="
            + str(cell[].long_open_cid)
            + " long_open_quantity="
            + str(cell[].long_open_quantity)
            + " long_open_status="
            + str(cell[].long_open_status)
            + " current_cell_level="
            + str(ctx.current_cell_level)
            + " mid="
            + str(ctx.mid)
        )
        var res = self.platform[].place_order(
            self.category,
            self.symbol,
            side=side,
            order_type=order_type,
            qty=str(qty),
            price=price,
            position_idx=position_idx,
            order_client_id=order_client_id,
        )

        cell[].long_open_cid = order_client_id
        cell[].long_open_quantity = qty
        cell[].long_open_status = OrderStatus.new

        logi(
            "level="
            + str(cell[].level)
            + " 下单返回: "
            + str(res)
            + " long_open_cid="
            + str(cell[].long_open_cid)
            + " long_open_quantity="
            + str(cell[].long_open_quantity)
            + " long_open_status="
            + str(cell[].long_open_status)
        )

    fn place_sell_order[
        L: MutableLifetime
    ](inout self, ctx: IContext, cell: Reference[GridCellInfo, L]) raises:
        """
        下开仓单.
        """
        if (
            cell[].short_open_status != OrderStatus.empty
            or cell[].short_open_cid != ""
        ):
            return

        if cell[].price <= ctx.bid:
            return

        if not self.is_within_sell_range(cell[], ctx.current_cell_level):
            return

        var side = String("Sell")
        var order_type = String("Limit")

        var a = self.platform[].get_account("USDT")
        if a is None:
            logi("no account")
            return

        # var qty = self.order_qty
        var account = a.value()
        var qty = self.calc_lots(account, ctx.mid)
        if qty == Fixed.zero:
            # logi("qty is zero")
            return

        # logi("下单价格: " + str(cell[].price) + " 数量: " + str(qty))
        var price = str(cell[].price)
        var position_idx: Int = int(PositionIdx.both_side_sell)
        var order_client_id = self.platform[].generate_order_id()

        logi(
            "level="
            + str(cell[].level)
            + " 下单 "
            + side
            + " "
            + str(qty)
            + "@"
            + price
            + " order_client_id="
            + order_client_id
            + " order_type="
            + order_type
            + " position_idx="
            + str(position_idx)
            # + " account="
            # + str(account)
            + " short_open_cid="
            + str(cell[].short_open_cid)
            + " short_open_quantity="
            + str(cell[].short_open_quantity)
            + " short_open_status="
            + str(cell[].short_open_status)
            + " current_cell_level="
            + str(ctx.current_cell_level)
            + " mid="
            + str(ctx.mid)
        )
        var res = self.platform[].place_order(
            self.category,
            self.symbol,
            side=side,
            order_type=order_type,
            qty=str(qty),
            price=price,
            position_idx=position_idx,
            order_client_id=order_client_id,
        )

        cell[].short_open_cid = order_client_id
        cell[].short_open_quantity = qty
        cell[].short_open_status = OrderStatus.new

        logi(
            "level="
            + str(cell[].level)
            + " 下单返回: "
            + str(res)
            + " short_open_cid="
            + str(cell[].short_open_cid)
            + " short_open_quantity="
            + str(cell[].short_open_quantity)
            + " short_open_status="
            + str(cell[].short_open_status)
        )

    # 记录日志
    fn log_cell_info(self, cell: GridCellInfo) raises:
        logi("GridCellInfo: " + str(cell))

    fn order_monitor[
        L: MutableLifetime
    ](inout self, ctx: IContext, cell: Reference[GridCellInfo, L]) raises:
        """
        监控订单状态, 止盈/止损.
        """
        if cell[].long_open_status == OrderStatus.filled:
            if cell[].long_tp_cid == "":
                logi(
                    "level="
                    + str(cell[].level)
                    + " 下止盈单 long_tp_cid="
                    + cell[].long_tp_cid
                )
                self.place_tp_order_real_buy(cell)
            elif cell[].long_tp_status.is_closed():
                logi(
                    "level="
                    + str(cell[].level)
                    + " 清理网格 status="
                    + str(cell[].long_tp_status)
                )
                # 如果是订单被撤销
                if cell[].long_tp_status == OrderStatus.canceled:
                    var cid = cell[].long_tp_cid
                    var order = self.platform[].get_order(cid)
                    if order is None:
                        logw("order is none")
                    else:
                        var order_value = order.value()
                        var qty = (
                            order_value.quantity - order_value.filled_qty
                        ).round(self.step_dp)
                        if qty >= self.min_order_qty:
                            # 重新下单
                            self.place_tp_order_market(
                                cell, qty, PositionIdx.both_side_buy
                            )

                # 清理网格
                self.reset_cell(cell, PositionIdx.both_side_buy)
            elif not cell[].long_tp_status.is_closed():
                # 计算是否触发时间止损
                var time_sl = self.time_sl_ms > 0
                    and cell[].long_open_time_ms != 0
                    and time_ms() - cell[].long_open_time_ms > self.time_sl_ms
                # 计算是否触发浮动止损
                var price = cell[].price
                var current_price = ctx.mid
                var float_profit_pct = (current_price - price) / price
                var profit_sl = float_profit_pct < -self.cell_sl_pct
                if time_sl or profit_sl:
                    logi(
                        "level="
                        + str(cell[].level)
                        + " 止损 status="
                        + str(cell[].long_tp_status)
                    )
                    # 撤单
                    _ = self.platform[].cancel_order(
                        self.category,
                        self.symbol,
                        order_client_id=cell[].long_tp_cid,
                    )
                    cell[].long_open_time_ms = 0
        if cell[].short_open_status == OrderStatus.filled:
            if cell[].short_tp_cid == "":
                logi(
                    "level="
                    + str(cell[].level)
                    + " 下止盈单 short_tp_cid="
                    + cell[].short_tp_cid
                )
                self.place_tp_order_real_sell(cell)
            elif cell[].short_tp_status.is_closed():
                logi(
                    "level="
                    + str(cell[].level)
                    + " 清理网格 status="
                    + str(cell[].short_tp_status)
                )
                # 如果是订单被撤销
                if cell[].short_tp_status == OrderStatus.canceled:
                    var cid = cell[].short_tp_cid
                    var order = self.platform[].get_order(cid)
                    if order is None:
                        logw("order is none")
                    else:
                        var order_value = order.value()
                        var qty = (
                            order_value.quantity - order_value.filled_qty
                        ).round(self.step_dp)
                        if qty >= self.min_order_qty:
                            # 重新下单
                            self.place_tp_order_market(
                                cell, qty, PositionIdx.both_side_sell
                            )
                # 清理网格
                self.reset_cell(cell, PositionIdx.both_side_sell)
            elif not cell[].short_tp_status.is_closed():
                # 计算是否触发时间止损
                var time_sl = self.time_sl_ms > 0
                    and cell[].short_open_time_ms != 0
                    and time_ms() - cell[].short_open_time_ms > self.time_sl_ms
                # 计算是否触发浮动止损
                var price = cell[].price
                var current_price = ctx.mid
                var float_profit_pct = (price - current_price) / price
                var profit_sl = float_profit_pct < -self.cell_sl_pct
                if time_sl or profit_sl:
                    logi(
                        "level="
                        + str(cell[].level)
                        + " 止损 status="
                        + str(cell[].short_tp_status)
                    )
                    # 撤单
                    _ = self.platform[].cancel_order(
                        self.category,
                        self.symbol,
                        order_client_id=cell[].short_tp_cid,
                    )
                    cell[].short_open_time_ms = 0

    fn place_tp_order_real_buy[
        L: MutableLifetime
    ](inout self, cell: Reference[GridCellInfo, L]) raises:
        var side = String("Sell")
        var order_type = String("Limit")
        var qty = str(cell[].long_open_quantity)
        var price = str(self.grid[].get_price_by_level(cell[].level + 1))
        # logi(
        #     "level="
        #     + str(cell[].level)
        #     + " 下止盈单: "
        #     + str(cell[].price)
        #     + ">"
        #     + price
        # )
        var position_idx: Int = int(PositionIdx.both_side_buy)
        var order_client_id = self.platform[].generate_order_id()
        logi(
            "level="
            + str(cell[].level)
            + " 下止盈单 "
            + side
            + " "
            + qty
            + "@"
            + price
            + " order_client_id="
            + order_client_id
            + " order_type="
            + order_type
            + " position_idx="
            + str(position_idx)
        )
        var res = self.platform[].place_order(
            self.category,
            self.symbol,
            side=side,
            order_type=order_type,
            qty=qty,
            price=price,
            position_idx=position_idx,
            order_client_id=order_client_id,
        )
        logi("level=" + str(cell[].level) + " 下平仓单返回: " + str(res))
        cell[].long_tp_cid = order_client_id
        cell[].long_tp_status = OrderStatus.new
        cell[].long_open_time_ms = time_ms()
        assert_equal(cell[].long_tp_cid, order_client_id)
        assert_equal(str(cell[].long_tp_status), str(OrderStatus.new))

    fn place_tp_order_real_sell[
        L: MutableLifetime
    ](inout self, cell: Reference[GridCellInfo, L]) raises:
        var side = String("Buy")
        var order_type = String("Limit")
        var qty = str(cell[].short_open_quantity)
        var price = str(self.grid[].get_price_by_level(cell[].level - 1))
        # logi(
        #     "level="
        #     + str(cell[].level)
        #     + " 下止盈单: "
        #     + str(cell[].price)
        #     + ">"
        #     + price
        # )
        var position_idx: Int = int(PositionIdx.both_side_sell)
        var order_client_id = self.platform[].generate_order_id()
        logi(
            "level="
            + str(cell[].level)
            + " 下止盈单 "
            + side
            + " "
            + qty
            + "@"
            + price
            + " order_client_id="
            + order_client_id
            + " order_type="
            + order_type
            + " position_idx="
            + str(position_idx)
        )
        var res = self.platform[].place_order(
            self.category,
            self.symbol,
            side=side,
            order_type=order_type,
            qty=qty,
            price=price,
            position_idx=position_idx,
            order_client_id=order_client_id,
        )
        logi("level=" + str(cell[].level) + " 下平仓单返回: " + str(res))
        cell[].short_tp_cid = order_client_id
        cell[].short_tp_status = OrderStatus.new
        cell[].short_open_time_ms = time_ms()
        assert_equal(cell[].short_tp_cid, order_client_id)
        assert_equal(str(cell[].short_tp_status), str(OrderStatus.new))

    fn place_tp_order_market[
        L: MutableLifetime
    ](inout self, cell: Reference[GridCellInfo, L], qty: Fixed, position_idx: PositionIdx) raises:
        var side = String(
            "Sell"
        ) if position_idx == PositionIdx.both_side_buy else String("Buy")
        var order_type = String("Market")
        # var position_idx: Int = int(PositionIdx.both_side_buy)
        var order_client_id = "SL_" + self.platform[].generate_order_id()
        logi(
            "level="
            + str(cell[].level)
            + " 下止损单 "
            + side
            + " "
            + str(qty)
            + "@0"
            + " order_client_id="
            + order_client_id
            + " order_type="
            + order_type
            + " position_idx="
            + str(position_idx)
        )
        var res = self.platform[].place_order(
            self.category,
            self.symbol,
            side=side,
            order_type=order_type,
            qty=str(qty),
            price="",
            position_idx=int(position_idx),
            order_client_id=order_client_id,
        )
        logi("level=" + str(cell[].level) + " 下平仓单返回: " + str(res))

    fn reset_cell[
        L: MutableLifetime
    ](
        inout self,
        cell: Reference[GridCellInfo, L],
        position_idx: PositionIdx,
    ) raises:
        if position_idx == PositionIdx.both_side_buy:
            var cids = cell[].reset_long_side()
            self.platform[].delete_orders_from_cache(cids)
        elif position_idx == PositionIdx.both_side_sell:
            var cids = cell[].reset_short_side()
            self.platform[].delete_orders_from_cache(cids)

    fn on_orderbook(inout self, ob: OrderBookLite) raises:
        if len(ob.asks) > 0 and len(ob.bids) > 0:
            # logd(
            #     "GridStrategyPM.on_orderbook ask="
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
                "GridStrategyPM.on_orderbook len(asks)="
                + str(len(ob.asks))
                + " len(bids)="
                + str(len(ob.bids))
            )

    fn on_order(inout self, order: Order) raises:
        logd("GridStrategyPM.on_order " + str(order))

        self.rwlock.lock()
        self.order_q.enqueue(order)
        self.rwlock.unlock()

    fn process_order_event(inout self):
        while True:
            self.rwlock.lock()
            var order_opt = self.order_q.dequeue()
            self.rwlock.unlock()
            if not order_opt:
                break
            var order = order_opt.value()
            logi("process_order_event ok: " + " order=" + str(order))
            for i in range(len(self.grid[].cells)):
                var cell_ref = Reference(self.grid[].cells[i])
                if self.on_order_cell(cell_ref, order):
                    break

    @staticmethod
    fn on_order_cell[
        L: MutableLifetime
    ](cell: Reference[GridCellInfo, L], order: Order) -> Bool:
        # logi("GridStrategyPM.on_order_cell: " + str(cell[]) + " " + str(order))
        var order_client_id = order.order_client_id
        if cell[].long_open_cid == order_client_id:
            cell[].long_open_status = order.status
            logi(
                "level="
                + str(cell[].level)
                + " 更新订单状态 client_id: "
                + order_client_id
                + " status="
                + str(order.status)
            )
            return True
        elif cell[].long_tp_cid == order_client_id:
            cell[].long_tp_status = order.status
            logi(
                "level="
                + str(cell[].level)
                + " 更新订单状态 client_id: "
                + order_client_id
                + " status="
                + str(order.status)
            )
            return True
        elif cell[].long_sl_cid == order_client_id:
            cell[].long_sl_status = order.status
            logi(
                "level="
                + str(cell[].level)
                + " 更新订单状态 client_id: "
                + order_client_id
                + " status="
                + str(order.status)
            )
            return True
        elif cell[].short_open_cid == order_client_id:
            cell[].short_open_status = order.status
            logi(
                "level="
                + str(cell[].level)
                + " 更新订单状态 client_id: "
                + order_client_id
                + " status="
                + str(order.status)
            )
            return True
        elif cell[].short_tp_cid == order_client_id:
            cell[].short_tp_status = order.status
            logi(
                "level="
                + str(cell[].level)
                + " 更新订单状态 client_id: "
                + order_client_id
                + " status="
                + str(order.status)
            )
            return True
        elif cell[].short_sl_cid == order_client_id:
            cell[].short_sl_status = order.status
            logi(
                "level="
                + str(cell[].level)
                + " 更新订单状态 client_id: "
                + order_client_id
                + " status="
                + str(order.status)
            )
            return True

        return False

    fn on_position(inout self, position: PositionInfo) raises:
        logd("GridStrategyPM.on_position " + str(position))
