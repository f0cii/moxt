from memory import unsafe
import .c
from .mo import *
from stdlib_extensions.time import time_ns


fn time_ms() -> Int64:
    return time_ns() / 1e6


fn time_us() -> Int64:
    return time_ns() / 1e3


fn set_global_value_ptr[V: AnyRegType](id: Int, v: Pointer[V]) -> Int:
    let ptr = v.__as_index()
    seq_store_object_address(id, ptr)
    return ptr


@always_inline
fn get_global_value[V: AnyRegType](id: Int) -> V:
    let ptr = seq_retrieve_object_address(id)
    return unsafe.bitcast[V](ptr).load()


@always_inline
fn strtoi(s: StringLiteral) -> Int:
    return seq_strtoi(s.data()._as_scalar_pointer(), len(s))


@always_inline
fn strtoi(s: String) -> Int:
    return seq_strtoi(s._buffer.data.value, len(s))


@always_inline
fn strtod(s: StringLiteral) -> Float64:
    return seq_strtod(s.data()._as_scalar_pointer(), len(s))


@always_inline
fn strtod(s: String) -> Float64:
    return seq_strtod(s._buffer.data.value, len(s))


# fn to_string(data: Pointer[Int8], data_len: Int) -> String:
#     let ptr = Pointer[Int8]().alloc(data_len)

#     memcpy(ptr, data, data_len)

#     return String(ptr, data_len)




# fn to_string_ref(i: Int) -> StringRef:
#     let s = str(i)
#     return c.to_string_ref(s)
