from base.c import *
from base.mo import *
from base.fixed import Fixed
from core.bybitmodel import *
from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr


@value
struct DataHandler:
    var _asks: Pointer[c_void_pointer]
    var _bids: Pointer[c_void_pointer]

    fn __init__(inout self):
        self._asks = Pointer[c_void_pointer].alloc(1)
        self._bids = Pointer[c_void_pointer].alloc(1)
        self._asks.store(seq_skiplist_new(True))
        self._bids.store(seq_skiplist_new(False))

    fn __del__(owned self):
        seq_skiplist_free(self._asks.load())
        seq_skiplist_free(self._bids.load())
        self._asks.free()
        self._bids.free()

    fn update(
        self,
        type_: String,
        inout asks: list[OrderBookLevel],
        inout bids: list[OrderBookLevel],
    ):
        if type_ == "snapshot":
            seq_skiplist_free(self._asks.load())
            seq_skiplist_free(self._bids.load())
            self._asks.store(seq_skiplist_new(True))
            self._bids.store(seq_skiplist_new(False))

        try:
            let _asks = self._asks.load()
            for i in asks:
                # logd("ask price: " + str(i.price) + " qty: " + str(i.qty))
                if i.qty.is_zero():
                    _ = seq_skiplist_remove(_asks, i.price.value())
                else:
                    _ = seq_skiplist_insert(_asks, i.price.value(), i.qty.value(), True)

            let _bids = self._bids.load()
            for i in bids:
                # logd("bid price: " + str(i.price) + " qty: " + str(i.qty))
                if i.qty.is_zero():
                    _ = seq_skiplist_remove(_bids, i.price.value())
                else:
                    _ = seq_skiplist_insert(_bids, i.price.value(), i.qty.value(), True)
        except err:
            loge("DataHandler.update error: " + str(err))

    fn top_n(self, n: Int) -> OrderBookLite:
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
