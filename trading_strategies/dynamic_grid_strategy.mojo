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
        self.symbols = split(config.symbols, ",")
        self.symbol = self.symbols[0]
        self.tick_size = Fixed.zero
        self.step_size = Fixed.zero
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

    fn get_platform_pointer(inout self) -> Pointer[Platform]:
        return Reference(self.platform).get_unsafe_pointer()

    fn on_init(inout self) raises:
        logi("DynamicGridStrategy.on_init")

        # Cancel all orders
        _ = self.platform.cancel_orders_enhanced(self.category, self.symbol)
        # Close positions
        _ = self.platform.close_positions_enhanced(self.category, self.symbol)

        var exchange_info = self.platform.fetch_exchange_info(
            self.category, self.symbol
        )
        logi(str(exchange_info))

        var tick_size = Fixed(exchange_info.tick_size)
        var step_size = Fixed(exchange_info.step_size)
        # logi("tick_size: " + str(tick_size))
        # logi("step_size: " + str(step_size))
        # self.tick_size.copy_from(tick_size)
        # self.step_size.copy_from(step_size)
        self.tick_size = tick_size
        self.step_size = step_size
        var dp = decimal_places(tick_size.to_float())

        # fetch orderbook
        var ob = self.platform.fetch_orderbook(self.category, self.symbol, 5)
        if len(ob.asks) == 0 or len(ob.bids) == 0:
            raise Error("Failed to fetch orderbook")

        var ask = Fixed(ob.asks[0].price)
        var bid = Fixed(ob.bids[0].price)
        logi("ask=" + str(ask) + " bid=" + str(bid))
        var mid = (ask + bid) / Fixed(2)
        logi("mid=" + str(mid))
        var base_price = mid.round(dp)
        logi("base_price=" + str(base_price))
        var grid_interval = Fixed(self.grid_interval)
        var price_range = Fixed("0.15")
        logi("grid_interval=" + str(grid_interval))
        logi("price_range=" + str(price_range))
        logi("tick_size=" + str(tick_size))
        logi("dp=" + str(dp))

        self.grid.setup(grid_interval, price_range, tick_size, base_price, dp)
        logi(str(self.grid))

        logi("DynamicGridStrategy.on_init done")

    fn on_exit(inout self) raises:
        logi("DynamicGridStrategy.on_exit")
        # Cancel all orders
        _ = self.platform.cancel_orders_enhanced(self.category, self.symbol)
        # Close positions
        _ = self.platform.close_positions_enhanced(self.category, self.symbol)
        logi("DynamicGridStrategy.on_exit done")

    fn on_tick(inout self) raises:
        # logd("DynamicGridStrategy.on_tick")
        var ob = self.platform.get_orderbook(self.symbol, 5)
        if len(ob.asks) == 0 or len(ob.bids) == 0:
            logw("Order book lacks buy and sell orders")
            return

        var ask = ob.asks[0]
        var bid = ob.bids[0]
        var mid = (ask.price + bid.price) / Fixed(2)
        var current_cell_level = self.grid.get_cell_level_by_price(mid)
        # logi("current_cell_level=" + str(current_cell_level))

        self.place_buy_orders(current_cell_level)
        self.place_tp_orders()

        self.grid.update(mid)

    fn place_buy_orders(inout self, current_cell_level: Int) raises:
        for index in range(len(self.grid.cells)):
            var cell = self.grid.cells[index]
            if self.is_within_buy_range(cell.level, current_cell_level):
                self.place_buy_order(index, cell)

    # Check whether the grid unit is within the buy order range
    fn is_within_buy_range(self, cell_level: Int, current_cell_level: Int) -> Bool:
        var buy_range = 3  # Define the range of buy orders, which can be adjusted according to actual circumstances
        return current_cell_level - buy_range <= cell_level <= current_cell_level

    fn place_buy_order(inout self, index: Int, cell: GridCellInfo) raises:
        """
        Place an opening order
        """
        if cell.long_open_status != OrderStatus.empty:
            return

        var side = String("Buy")
        var order_type = String("Limit")
        var qty = self.order_qty
        var price = str(cell.price)
        var position_idx: Int = int(PositionIdx.both_side_buy)
        var order_client_id = self.platform.generate_order_id()
        logi(
            "Place order "
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
        logi("Place order returns: " + str(res))
        self.grid.cells[index].long_open_cid = order_client_id
        self.grid.cells[index].long_open_status = OrderStatus.new
        logi("Update order id")

    fn place_tp_orders(inout self) raises:
        """
        Place a take-profit order
        """
        for index in range(len(self.grid.cells)):
            var cell = self.grid.cells[index]
            if cell.long_open_status == OrderStatus.filled:
                if cell.long_tp_cid == "":
                    logi("Place a take-profit order")
                    self.place_tp_order(index, cell)
                elif cell.long_tp_status.is_closed():
                    logi("Clean up grid")
                    self.reset_cell(index, PositionIdx.both_side_buy)

    fn place_tp_order(inout self, index: Int, cell: GridCellInfo) raises:
        var side = String("Sell")
        var order_type = String("Limit")
        var qty = str(cell.long_open_quantity)
        var price = str(self.grid.get_price_by_level(cell.level + 1))
        logi("Place a take-profit order: " + str(cell.price) + ">" + price)
        var position_idx: Int = int(PositionIdx.both_side_buy)
        var order_client_id = self.platform.generate_order_id()
        logi(
            "Place take-profit order "
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
        logi("Place a closing order and return: " + str(res))
        self.grid.cells[index].long_tp_cid = order_client_id
        self.grid.cells[index].long_tp_status = OrderStatus.new
        logi("Update order id")

    fn reset_cell(inout self, index: Int, position_idx: PositionIdx) raises:
        if position_idx == PositionIdx.both_side_buy:
            var cids = self.grid.cells[index].reset_long_side()
            self.platform.delete_orders_from_cache(cids)
        elif position_idx == PositionIdx.both_side_sell:
            var cids = self.grid.cells[index].reset_short_side()
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
            var cell = self.grid.cells[i]
            var order_client_id = order.order_client_id
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
        logd("DynamicGridStrategy.on_position " + str(position))
