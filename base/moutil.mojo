from memory import unsafe
import math
import .c
from .mo import *
from ylstdlib.time import time_ns


fn time_ms() -> Int64:
    return Int64(int(time_ns() / 1e6))


fn time_us() -> Int64:
    return Int64(int(time_ns() / 1e3))


fn set_global_value_ptr[V: Intable](id: Int, v: UnsafePointer[V]) -> Int:
    var ptr = int(v)
    seq_set_global_int(id, ptr)
    return ptr


@always_inline
fn strtoi(s: String) -> Int:
    return seq_strtoi(unsafe_ptr_as_scalar_pointer(s.unsafe_ptr()), len(s))


@always_inline
fn strtod(s: String) -> Float64:
    return seq_strtod(unsafe_ptr_as_scalar_pointer(s.unsafe_ptr()), len(s))


fn str_to_bool(s: String) -> Bool:
    if s == "true" or s == "True":
        return True
    elif s == "false" or s == "False":
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
