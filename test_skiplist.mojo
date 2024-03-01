from testing import assert_true, assert_false, assert_equal
from base.mo import *
from base.fixed import Fixed


fn test_skiplist() raises:
    var asks = seq_skiplist_new(True)
    _ = seq_skiplist_insert(asks, Fixed(3000).value(), Fixed(100).value(), True)
    _ = seq_skiplist_insert(asks, Fixed(3005).value(), Fixed(200).value(), True)
    _ = seq_skiplist_insert(asks, Fixed(2700.1).value(), Fixed(200).value(), True)
    seq_skiplist_dump(asks)

    var node = seq_skiplist_begin(asks)
    var end = seq_skiplist_end(asks)
    while node != end:
        var key: Int64 = 0
        var value: Int64 = 0
        seq_skiplist_node_value(
            node, Pointer[Int64].address_of(key), Pointer[Int64].address_of(value)
        )
        var key_ = Fixed.from_value(key)
        var value_ = Fixed.from_value(value)
        print("key: " + str(key_) + " value: " + str(value_))
        node = seq_skiplist_next(asks, node)

    var v = seq_skiplist_remove(asks, Fixed(3000).value())
    var vf = Fixed.from_value(v)

    assert_equal(str(vf), "100")

    seq_skiplist_dump(asks)
    seq_skiplist_free(asks)


fn main() raises:
    test_skiplist()
