from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr
from stdlib_extensions.builtins.string import *
from ylstdlib import *
from ylstdlib.dynamic_vector import DynamicVector
from base.c import *
from base.mo import *
from base.thread import *
from base.fixed import Fixed
from core.bybitmodel import *
from core.bybitclient import *
from .config import AppConfig
from .types import *
from .helpers import *


alias OrderUpdateCallback = fn (order: Order) escaping -> None


@value
struct OrderUpdateCallbackWrapper(CollectionElement):
    var _callback: OrderUpdateCallback

    fn __init__(inout self, owned callback: OrderUpdateCallback):
        self._callback = callback ^

    fn __call__(self, order: Order):
        self._callback(order)

    fn __str__(self) -> String:
        return "OrderUpdateCallbackWrapper"


struct Platform:
    var _config: AppConfig
    var _client: BybitClient
    var _symbols: list[String]
    var _asks: Pointer[c_void_pointer]
    var _bids: Pointer[c_void_pointer]
    var _symbol_index_dict: dict[HashableStr, Int]
    var _order_cache: dict[HashableStr, Order]  # key: order_client_id
    var _order_cache_lock: RWLock
    var _order_update_callbacks: DynamicVector[OrderUpdateCallbackWrapper]

    fn __init__(inout self, config: AppConfig):
        logd("Platform.__init__")
        self._config = config
        self._client = BybitClient(config.testnet, config.access_key, config.secret_key)
        self._symbols = split(config.symbols, ",")
        var symbol_count = len(self._symbols)
        self._asks = Pointer[c_void_pointer].alloc(symbol_count)
        self._bids = Pointer[c_void_pointer].alloc(symbol_count)
        self._symbol_index_dict = dict[HashableStr, Int]()
        self._order_cache = dict[HashableStr, Order]()
        self._order_cache_lock = RWLock()
        self._order_update_callbacks = DynamicVector[OrderUpdateCallbackWrapper](
            capacity=16
        )
        logd("Platform.__init__ done")

    fn __moveinit__(inout self, owned existing: Self):
        logd("Platform.__moveinit__")
        self._config = existing._config
        self._symbols = existing._symbols
        self._client = existing._client ^

        var symbol_count = len(self._symbols)
        self._asks = Pointer[c_void_pointer].alloc(symbol_count)
        self._bids = Pointer[c_void_pointer].alloc(symbol_count)

        self._symbol_index_dict = existing._symbol_index_dict
        self._order_cache = existing._order_cache ^
        self._order_cache_lock = existing._order_cache_lock
        self._order_update_callbacks = existing._order_update_callbacks
        logd("Platform.__moveinit__ done")

    fn __del__(owned self):
        logd("Platform.__del__")
        # var NULL = c_void_pointer.get_null()
        # var asks_ptr = self._asks.load(0)
        # if asks_ptr != NULL:
        #     seq_skiplist_free(asks_ptr)
        # var bids_ptr = self._bids.load(0)
        # if bids_ptr != NULL:
        #     seq_skiplist_free(bids_ptr)
        self._asks.free()
        self._bids.free()
        logd("Platform.__del__ done")

    fn setup(inout self) raises:
        # logi("Platform.setup")
        for i in range(len(self._symbols)):
            var sym = self._symbols[i]
            # logi("sym=" + sym + " i=" + str(i))
            self._symbol_index_dict[sym] = i
            self._asks.store(i, seq_skiplist_new(True))
            self._bids.store(i, seq_skiplist_new(False))
        # logi("Platform.setup done")

    fn register_order_update_callback(
        inout self, owned callback: OrderUpdateCallbackWrapper
    ) raises:
        self._order_update_callbacks.append(callback ^)

    fn free(inout self) raises:
        for i in range(len(self._symbols)):
            var asks_ptr = self._asks.load(i)
            seq_skiplist_free(asks_ptr)
            var bids_ptr = self._bids.load(i)
            seq_skiplist_free(bids_ptr)

    fn delete_orders_from_cache(inout self, cids: list[String]) raises:
        if len(cids) == 0:
            return

        self._order_cache_lock.lock()
        for cid in cids:
            logi("Remove order: " + cid)
            self._order_cache.pop(cid)
        self._order_cache_lock.unlock()

    fn on_update_orderbook(
        self,
        symbol: String,
        type_: String,
        inout asks: list[OrderBookLevel],
        inout bids: list[OrderBookLevel],
    ) raises:
        var index = self._symbol_index_dict[symbol]
        # logd("Platform.update_orderbook")
        if type_ == "snapshot":
            seq_skiplist_free(self._asks.load(index))
            seq_skiplist_free(self._bids.load(index))
            self._asks.store(seq_skiplist_new(True))
            self._bids.store(seq_skiplist_new(False))

        var _asks = self._asks.load(index)
        for i in asks:
            # logd("ask price: " + str(i.price) + " qty: " + str(i.qty))
            if i.qty.is_zero():
                _ = seq_skiplist_remove(_asks, i.price.value())
            else:
                _ = seq_skiplist_insert(_asks, i.price.value(), i.qty.value(), True)

        var _bids = self._bids.load(index)
        for i in bids:
            # logd("bid price: " + str(i.price) + " qty: " + str(i.qty))
            if i.qty.is_zero():
                _ = seq_skiplist_remove(_bids, i.price.value())
            else:
                _ = seq_skiplist_insert(_bids, i.price.value(), i.qty.value(), True)

    fn on_update_order(inout self, order: Order) -> Bool:
        logi("on_update_order: " + str(order))
        var key = order.order_client_id
        self._order_cache_lock.lock()
        # TODO: Order versions need to be compared, returning false if the version is older
        self._order_cache[key] = order
        self._order_cache_lock.unlock()

        self.notify_order_update(order)

        return True

    @always_inline
    fn notify_order_update(inout self, order: Order):
        for i in range(len(self._order_update_callbacks)):
            var ref = self._order_update_callbacks.__refitem__(i)
            ref[](order)

    fn get_order(self, cid: String) raises -> Order:
        self._order_cache_lock.lock()
        try:
            var order = self._order_cache[cid]
            self._order_cache_lock.unlock()
            return order
        except e:
            self._order_cache_lock.unlock()
            raise e

    fn get_orderbook(self, symbol: String, n: Int) raises -> OrderBookLite:
        var index: Int = self._symbol_index_dict[symbol]
        var ob = OrderBookLite(symbol=symbol)

        var _asks = self._asks.load(index)
        var _bids = self._bids.load(index)

        var a_node = seq_skiplist_begin(_asks)
        var a_end = seq_skiplist_end(_asks)
        var a_count: Int = 0

        while a_node != a_end:
            var key: Int64 = 0
            var value: Int64 = 0
            seq_skiplist_node_value(
                a_node, Pointer[Int64].address_of(key), Pointer[Int64].address_of(value)
            )
            var key_ = Fixed.from_value(key)
            var value_ = Fixed.from_value(value)
            # print("key: " + str(key_) + " value: " + str(value_))
            ob.asks.append(OrderBookLevel(key_, value_))
            a_count += 1
            if a_count >= n:
                break
            a_node = seq_skiplist_next(_asks, a_node)

        var b_node = seq_skiplist_begin(_bids)
        var b_end = seq_skiplist_end(_bids)
        var b_count: Int = 0

        while b_node != b_end:
            var key: Int64 = 0
            var value: Int64 = 0
            seq_skiplist_node_value(
                b_node, Pointer[Int64].address_of(key), Pointer[Int64].address_of(value)
            )
            var key_ = Fixed.from_value(key)
            var value_ = Fixed.from_value(value)
            # print("key: " + str(key_) + " value: " + str(value_))
            ob.bids.append(OrderBookLevel(key_, value_))
            b_count += 1
            if b_count >= n:
                break
            b_node = seq_skiplist_next(_bids, b_node)

        return ob

    @always_inline
    fn generate_order_id(self) -> String:
        # Considering performance, it may be beneficial to pre-generate and store in a pool, then directly retrieve from the pool here
        return seq_nanoid()

    @always_inline
    fn fetch_exchange_info(
        self, category: String, symbol: String
    ) raises -> ExchangeInfo:
        return self._client.fetch_exchange_info(category, symbol)

    @always_inline
    fn fetch_orderbook(
        self, category: String, symbol: String, limit: Int
    ) raises -> OrderBook:
        return self._client.fetch_orderbook(category, symbol, limit)

    @always_inline
    fn fetch_order(
        inout self, category: String, symbol: String, order_client_id: String
    ) raises -> Order:
        var res = self._client.fetch_orders(
            category, symbol, order_link_id=order_client_id
        )
        if len(res) == 0:
            return Order()
        var order = convert_bybit_order(res[0])
        _ = self.on_update_order(order)
        return order

    @always_inline
    fn fetch_orders(
        inout self,
        category: String,
        symbol: String,
        order_client_id: String = "",
        limit: Int = 0,
        cursor: String = "",
    ) raises -> list[Order]:
        var orders_original = self._client.fetch_orders(
            category, symbol, order_client_id, limit, cursor
        )
        var orders = list[Order]()
        for i in range(len(orders_original)):
            var order = convert_bybit_order(orders_original[i])
            orders.append(order)
            _ = self.on_update_order(order)
        return orders

    @always_inline
    fn cancel_order(
        inout self,
        category: String,
        symbol: String,
        order_id: String = "",
        order_client_id: String = "",
        fetch_full_info: Bool = False,
    ) raises -> Order:
        var res = self._client.cancel_order(category, symbol, order_id, order_client_id)
        if not fetch_full_info:
            return Order(
                symbol=symbol,
                order_type="",
                order_client_id=res.order_link_id,
                order_id=res.order_id,
                price=Fixed.zero,
                quantity=Fixed.zero,
                filled_qty=Fixed.zero,
                status=OrderStatus.empty,
            )
        else:
            return self.fetch_order(category, symbol, order_client_id)

    @always_inline
    fn cancel_orders(
        self,
        category: String,
        symbol: String,
        base_coin: String = "",
        settle_coin: String = "",
    ) raises -> BatchCancelResult:
        var res = self._client.cancel_orders(category, symbol, base_coin, settle_coin)
        var cancelled_orders = list[CancelOrderResult]()
        for i in range(len(res)):
            var item = res[i]
            cancelled_orders.append(
                CancelOrderResult(item.order_id, item.order_link_id)
            )
        return BatchCancelResult(cancelled_orders)

    @always_inline
    fn fetch_positions(
        self, category: String, symbol: String
    ) raises -> list[PositionInfo]:
        return self._client.fetch_positions(category, symbol)

    @always_inline
    fn place_order(
        inout self,
        category: String,
        symbol: String,
        side: String,
        order_type: String,
        qty: String,
        price: String,
        time_in_force: String = "",
        position_idx: Int = 0,
        order_client_id: String = "",
        reduce_only: Bool = False,
    ) raises -> OrderResponse:
        var new_order = Order(
            symbol=symbol,
            order_type=order_type,
            order_client_id=order_client_id,
            order_id="",
            price=Fixed(price),
            quantity=Fixed(qty),
            filled_qty=Fixed.zero,
            status=OrderStatus.new,
        )
        _ = self.on_update_order(new_order)
        return self._client.place_order(
            category,
            symbol,
            side,
            order_type,
            qty,
            price,
            time_in_force,
            position_idx,
            order_client_id,
            reduce_only,
        )

    fn cancel_orders_enhanced(
        inout self, category: String, symbol: String
    ) raises -> Bool:
        """
        Cancel all active orders
        """
        var orders = self.fetch_orders(category, symbol)
        if len(orders) == 0:
            logi("There are no active orders; the cancellation operation is complete")
            return True

        var res = self.cancel_orders(category, symbol)
        for i in range(len(res.cancelled_orders)):
            logi("Cancellation returns: " + str(res.cancelled_orders[i]))
        return True

    fn close_positions_enhanced(
        inout self, category: String, symbol: String
    ) raises -> Bool:
        """
        Close positions
        """
        logi("Close positions")
        var positions = self.fetch_positions(category, symbol)
        if len(positions) == 0:
            logi("There are no open positions; the closure operation is complete")
            return True

        for i in range(len(positions)):
            # logi(str(positions[i]))
            var pos = positions[i]
            var size = Fixed(pos.size)
            if size.is_zero():
                continue
            logi("Current position: " + str(pos))
            # Close position at market price
            var side = String("")
            var order_type = String("Market")
            var qty = str(size)
            var price = ""
            var position_idx: Int = pos.position_idx
            if pos.position_idx == 0:
                side = "Sell" if size > 0 else "Buy"
            elif pos.position_idx == 1:
                side = "Sell"
            elif pos.position_idx == 2:
                side = "Buy"
            var order_client_id = self.generate_order_id()
            logi(
                "Place an order to close position "
                + side
                + " "
                + qty
                + "@"
                + order_type
                + " order_client_id="
                + order_client_id
                + " order_type="
                + order_type
                + " position_idx="
                + str(position_idx)
            )
            try:
                var res = self.place_order(
                    category,
                    symbol,
                    side=side,
                    order_type=order_type,
                    qty=qty,
                    price=price,
                    position_idx=position_idx,
                    order_client_id=order_client_id,
                    reduce_only=True,
                )
                logi("Place a closing order and return: " + str(res))
            except e:
                logw("Order placement failed error=" + str(e))
        logi("Position closure completed")
        return True
