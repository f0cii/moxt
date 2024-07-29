from .c import *
from .mo import *


@value
struct Far:
    var ptr: c_void_pointer

    fn __init__(inout self):
        self.ptr = seq_far_new()

    fn __init__(inout self, ptr: c_void_pointer):
        self.ptr = ptr

    @always_inline
    fn get_int(self, key: String) -> Int:
        return int(
            seq_far_get_int(
                self.ptr,
                str_as_scalar_pointer(key),
                len(key),
            )
        )

    @always_inline
    fn get_float(self, key: String) -> Float64:
        return seq_far_get_float(self.ptr, str_as_scalar_pointer(key), len(key))

    @always_inline
    fn get_bool(self, key: String) -> Bool:
        return seq_far_get_bool(self.ptr, str_as_scalar_pointer(key), len(key))

    @always_inline
    fn get_str(self, key: String) -> String:
        var n: c_size_t = 0
        var c_str = seq_far_get_string(
            self.ptr,
            str_as_scalar_pointer(key),
            len(key),
            UnsafePointer[c_size_t].address_of(n),
        )
        return c_str_to_string(c_str, n)

    @always_inline
    fn __len__(self) -> Int:
        return seq_far_size(self.ptr)

    @always_inline
    fn set_int(self, key: String, value: Int):
        _ = seq_far_set_int(
            self.ptr,
            str_as_scalar_pointer(key),
            len(key),
            value,
        )

    @always_inline
    fn set_float(self, key: String, value: Float64):
        _ = seq_far_set_float(
            self.ptr,
            str_as_scalar_pointer(key),
            len(key),
            value,
        )

    @always_inline
    fn set_bool(self, key: String, value: Bool):
        _ = seq_far_set_bool(
            self.ptr,
            str_as_scalar_pointer(key),
            len(key),
            value,
        )

    @always_inline
    fn set_str(self, key: String, value: String):
        _ = seq_far_set_string(
            self.ptr,
            str_as_scalar_pointer(key),
            len(key),
            str_as_scalar_pointer(value),
            len(value),
        )

    @always_inline
    fn free(self):
        seq_far_free(self.ptr)
