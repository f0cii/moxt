from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr
from stdlib_extensions.builtins.string import *
from base.c import *
from base.mo import *
from base.thread import *
from base.fixed import Fixed
from core.bybitmodel import *
from core.bybitclient import *
from .config import AppConfig
from .types import *
from .helpers import *


struct Platform:
    var _config: AppConfig
    var _client: BybitClient
    var _symbols: list[String]
    var _asks: Pointer[c_void_pointer]
    var _bids: Pointer[c_void_pointer]
    var _symbol_index_dict: dict[HashableStr, Int]
    var _order_cache: dict[HashableStr, Order]  # key: order_client_id
    var _order_cache_lock: RWLock

    fn __init__(inout self, config: AppConfig):
        logd("Platform.__init__")
        self._config = config
        self._client = BybitClient(config.testnet, config.access_key, config.secret_key)
        self._symbols = safe_split(config.symbols, ",")
        let symbol_count = len(self._symbols)
        self._asks = Pointer[c_void_pointer].alloc(symbol_count)
        self._bids = Pointer[c_void_pointer].alloc(symbol_count)
        self._symbol_index_dict = dict[HashableStr, Int]()
        self._order_cache = dict[HashableStr, Order]()
        self._order_cache_lock = RWLock()
        logd("Platform.__init__ done")

    fn __moveinit__(inout self, owned existing: Self):
        logd("Platform.__moveinit__")
        self._config = existing._config
        self._symbols = existing._symbols
        self._client = existing._client ^

        let symbol_count = len(self._symbols)
        self._asks = Pointer[c_void_pointer].alloc(symbol_count)
        # let asks_ptr = existing._asks.load(0)
        # self._asks.store(0, asks_ptr)

        self._bids = Pointer[c_void_pointer].alloc(symbol_count)
        # let bids_ptr = existing._bids.load(0)
        # self._bids.store(0, bids_ptr)

        self._symbol_index_dict = existing._symbol_index_dict
        self._order_cache = existing._order_cache ^
        self._order_cache_lock = existing._order_cache_lock
        logd("Platform.__moveinit__ done")

    fn __del__(owned self):
        logd("Platform.__del__")
        # let NULL = c_void_pointer.get_null()
        # let asks_ptr = self._asks.load(0)
        # if asks_ptr != NULL:
        #     seq_skiplist_free(asks_ptr)
        # let bids_ptr = self._bids.load(0)
        # if bids_ptr != NULL:
        #     seq_skiplist_free(bids_ptr)
        self._asks.free()
        self._bids.free()
        logd("Platform.__del__ done")

    fn setup(inout self) raises:
        # logi("Platform.setup")
        for i in range(len(self._symbols)):
            let sym = self._symbols[i]
            # logi("sym=" + sym + " i=" + str(i))
            self._symbol_index_dict[sym] = i
            self._asks.store(i, seq_skiplist_new(True))
            self._bids.store(i, seq_skiplist_new(False))
        # logi("Platform.setup done")

    fn free(inout self) raises:
        for i in range(len(self._symbols)):
            let asks_ptr = self._asks.load(i)
            seq_skiplist_free(asks_ptr)
            let bids_ptr = self._bids.load(i)
            seq_skiplist_free(bids_ptr)

    fn delete_orders_from_cache(inout self, cids: list[String]) raises:
        if len(cids) == 0:
            return

        self._order_cache_lock.lock()
        for cid in cids:
            try:
                logi("移除订单: " + cid)
                self._order_cache.pop(cid)
            except e:
                logw("清理订单时出错: " + str(e))
        self._order_cache_lock.unlock()

    fn on_update_orderbook(
        self,
        symbol: String,
        type_: String,
        inout asks: list[OrderBookLevel],
        inout bids: list[OrderBookLevel],
    ) raises:
        let index = self._symbol_index_dict[symbol]
        # logd("Platform.update_orderbook")
        if type_ == "snapshot":
            seq_skiplist_free(self._asks.load(index))
            seq_skiplist_free(self._bids.load(index))
            self._asks.store(seq_skiplist_new(True))
            self._bids.store(seq_skiplist_new(False))

        let _asks = self._asks.load(index)
        for i in asks:
            # logd("ask price: " + str(i.price) + " qty: " + str(i.qty))
            if i.qty.is_zero():
                _ = seq_skiplist_remove(_asks, i.price.value())
            else:
                _ = seq_skiplist_insert(_asks, i.price.value(), i.qty.value(), True)

        let _bids = self._bids.load(index)
        for i in bids:
            # logd("bid price: " + str(i.price) + " qty: " + str(i.qty))
            if i.qty.is_zero():
                _ = seq_skiplist_remove(_bids, i.price.value())
            else:
                _ = seq_skiplist_insert(_bids, i.price.value(), i.qty.value(), True)

    fn on_update_order(inout self, order: Order) -> Bool:
        logi("on_update_order: " + str(order))
        let key = order.order_client_id
        self._order_cache_lock.lock()
        # TODO: 需要比较订单版本，如果版本较旧，返回false
        self._order_cache[key] = order
        self._order_cache_lock.unlock()
        return True

    fn get_order(self, cid: String) raises -> Order:
        self._order_cache_lock.lock()
        try:
            let order = self._order_cache[cid]
            self._order_cache_lock.unlock()
            return order
        except e:
            self._order_cache_lock.unlock()
            raise e

    fn get_orderbook(self, symbol: String, n: Int) raises -> OrderBookLite:
        let index: Int = self._symbol_index_dict[symbol]
        var ob = OrderBookLite(symbol=symbol)

        let _asks = self._asks.load(index)
        let _bids = self._bids.load(index)

        var a_node = seq_skiplist_begin(_asks)
        let a_end = seq_skiplist_end(_asks)
        var a_count: Int = 0

        while a_node != a_end:
            var key: Int64 = 0
            var value: Int64 = 0
            seq_skiplist_node_value(
                a_node, Pointer[Int64].address_of(key), Pointer[Int64].address_of(value)
            )
            let key_ = Fixed.from_value(key)
            let value_ = Fixed.from_value(value)
            # print("key: " + str(key_) + " value: " + str(value_))
            ob.asks.append(OrderBookLevel(key_, value_))
            a_count += 1
            if a_count >= n:
                break
            a_node = seq_skiplist_next(_asks, a_node)

        var b_node = seq_skiplist_begin(_bids)
        let b_end = seq_skiplist_end(_bids)
        var b_count: Int = 0

        while b_node != b_end:
            var key: Int64 = 0
            var value: Int64 = 0
            seq_skiplist_node_value(
                b_node, Pointer[Int64].address_of(key), Pointer[Int64].address_of(value)
            )
            let key_ = Fixed.from_value(key)
            let value_ = Fixed.from_value(value)
            # print("key: " + str(key_) + " value: " + str(value_))
            ob.bids.append(OrderBookLevel(key_, value_))
            b_count += 1
            if b_count >= n:
                break
            b_node = seq_skiplist_next(_bids, b_node)

        return ob

    @always_inline
    fn generate_order_id(self) -> String:
        # 基于考虑性能，可以预先生成存池子里面，这里从池子里面直接拿
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
    fn fetch_order(inout self, category: String, symbol: String, order_client_id: String) raises -> Order:
        let res = self._client.fetch_orders(category, symbol, order_link_id=order_client_id)
        if len(res) == 0:
            return Order()
        let order = convert_bybit_order(res[0])
        _ = self.on_update_order(order)
        return order

    @always_inline
    fn fetch_orders(
        self,
        category: String,
        symbol: String,
        order_client_id: String = "",
        limit: Int = 0,
        cursor: String = "",
    ) raises -> list[OrderInfo]:
        return self._client.fetch_orders(category, symbol, order_client_id, limit, cursor)

    @always_inline
    fn cancel_order(
        self,
        category: String,
        symbol: String,
        order_id: String = "",
        order_client_id: String = "",
    ) raises -> CancelOrderResult:
        let res = self._client.cancel_order(category, symbol, order_id, order_client_id)
        return CancelOrderResult(res.order_id, res.order_link_id)

    @always_inline
    fn cancel_orders(
        self,
        category: String,
        symbol: String,
        base_coin: String = "",
        settle_coin: String = "",
    ) raises -> BatchCancelResult:
        let res = self._client.cancel_orders(category, symbol, base_coin, settle_coin)
        var cancelled_orders = list[CancelOrderResult]()
        for i in range(len(res)):
            let item = res[i]
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
        let new_order = Order(
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

    fn cancel_orders_enhanced(self, category: String, symbol: String) raises -> Bool:
        """
        撤销所有活跃订单
        """
        let orders = self.fetch_orders(category, symbol)
        if len(orders) == 0:
            logi("没有活跃订单，撤单操作完成")
            return True

        let res = self.cancel_orders(category, symbol)
        for i in range(len(res.cancelled_orders)):
            logi("撤单返回项目: " + str(res.cancelled_orders[i]))
        return True

    fn close_positions_enhanced(
        inout self, category: String, symbol: String
    ) raises -> Bool:
        """
        平持仓
        """
        logi("关闭持仓")
        let positions = self.fetch_positions(category, symbol)
        if len(positions) == 0:
            logi("没有任何持仓，平仓操作完成")
            return True

        for i in range(len(positions)):
            # logi(str(positions[i]))
            let pos = positions[i]
            let size = Fixed(pos.size)
            if size.is_zero():
                continue
            logi("当前持仓: " + str(pos))
            # 市价平仓
            var side = String("")
            let order_type = String("Market")
            let qty = str(size)
            let price = ""
            let position_idx: Int = pos.position_idx
            if pos.position_idx == 0:
                side = "Sell" if size > 0 else "Buy"
            elif pos.position_idx == 1:
                side = "Sell"
            elif pos.position_idx == 2:
                side = "Buy"
            let order_client_id = self.generate_order_id()
            logi(
                "下单平仓 "
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
                let res = self.place_order(
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
                logi("下单平仓返回: " + str(res))
            except e:
                logw("下单失败 error=" + str(e))
        logi("关闭持仓完成")
        return True
