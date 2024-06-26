from memory import unsafe
import math
import .c
from .mo import *
from ylstdlib.time import time_ns


fn time_ms() -> Int64:
    return time_ns() / 1e6


fn time_us() -> Int64:
    return time_ns() / 1e3


fn set_global_value_ptr[V: AnyRegType](id: Int, v: Pointer[V]) -> Int:
    var ptr = int(v)
    seq_set_global_int(id, ptr)
    return ptr


# @always_inline
# fn get_global_value[V: AnyRegType](id: Int) -> V:
#     var ptr = seq_get_global_int(id)
#     return unsafe.bitcast[V](ptr).load()


@always_inline
fn strtoi(s: StringLiteral) -> Int:
    return seq_strtoi(s.data()._as_scalar_pointer(), len(s))


@always_inline
fn strtoi(s: String) -> Int:
    return seq_strtoi(s._as_ptr()._as_scalar_pointer(), len(s))


@always_inline
fn strtod(s: StringLiteral) -> Float64:
    return seq_strtod(s.data()._as_scalar_pointer(), len(s))


@always_inline
fn strtod(s: String) -> Float64:
    return seq_strtod(s._as_ptr()._as_scalar_pointer(), len(s))


def str_to_bool(s: String) -> Bool:
    if s == 'true' or s == "True":
        return True
    elif s == 'false' or s == "False":
        return False
    else:
        return False


fn decimal_places(value: Float64) -> Int:
    """
    Return decimal places: 0.0001 -> 4
    """
    if value == 0.0:
        return 0

    return int(math.ceil(math.log10(1.0 / value)))
