from base.c import *
from base.mo import *
from base.fixed import Fixed
from core.bybitmodel import *
from core.bybitclient import *
from .config import AppConfig
from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr


struct Platform:
    var _asks: Pointer[c_void_pointer]
    var _bids: Pointer[c_void_pointer]
    var _config: AppConfig
    var _client: BybitClient

    fn __init__(inout self, config: AppConfig):
        logd("Platform.__init__")
        self._asks = Pointer[c_void_pointer].alloc(1)
        self._bids = Pointer[c_void_pointer].alloc(1)
        self._asks.store(0, seq_skiplist_new(True))
        self._bids.store(0, seq_skiplist_new(False))
        self._config = config
        self._client = BybitClient(config.testnet, config.access_key, config.secret_key)

    fn __moveinit__(inout self, owned existing: Self):
        logd("Platform.__moveinit__")
        self._asks = Pointer[c_void_pointer].alloc(1)
        self._bids = Pointer[c_void_pointer].alloc(1)
        let asks_ptr = existing._asks.load(0)
        let bids_ptr = existing._bids.load(0)
        self._asks.store(0, asks_ptr)
        self._bids.store(0, bids_ptr)
        self._config = existing._config
        self._client = existing._client ^
        logd("Platform.__moveinit__ done")

    fn __del__(owned self):
        logd("Platform.__del__")
        let NULL = c_void_pointer.get_null()
        let asks_ptr = self._asks.load(0)
        if asks_ptr != NULL:
            seq_skiplist_free(asks_ptr)
        let bids_ptr = self._bids.load(0)
        if bids_ptr != NULL:
            seq_skiplist_free(bids_ptr)
        self._asks.free()
        self._bids.free()
        logd("Platform.__del__ done")

    fn update_orderbook(
        self,
        type_: String,
        inout asks: list[OrderBookLevel],
        inout bids: list[OrderBookLevel],
    ):
        # logd("Platform.update_orderbook")
        if type_ == "snapshot":
            seq_skiplist_free(self._asks.load(0))
            seq_skiplist_free(self._bids.load(0))
            self._asks.store(seq_skiplist_new(True))
            self._bids.store(seq_skiplist_new(False))

        try:
            let _asks = self._asks.load(0)
            for i in asks:
                # logd("ask price: " + str(i.price) + " qty: " + str(i.qty))
                if i.qty.is_zero():
                    _ = seq_skiplist_remove(_asks, i.price.value())
                else:
                    _ = seq_skiplist_insert(_asks, i.price.value(), i.qty.value(), True)

            let _bids = self._bids.load(0)
            for i in bids:
                # logd("bid price: " + str(i.price) + " qty: " + str(i.qty))
                if i.qty.is_zero():
                    _ = seq_skiplist_remove(_bids, i.price.value())
                else:
                    _ = seq_skiplist_insert(_bids, i.price.value(), i.qty.value(), True)
        except err:
            loge("Platform.update error: " + str(err))

    fn get_orderbook(self, n: Int) -> OrderBookLite:
        var ob = OrderBookLite()

        let _asks = self._asks.load()
        let _bids = self._bids.load()

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

    fn fetch_exchange_info(
        self, category: StringLiteral, symbol: StringLiteral
    ) raises -> ExchangeInfo:
        return self._client.fetch_exchange_info(category, symbol)
