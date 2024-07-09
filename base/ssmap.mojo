import sys
from .c import (
    c_str_to_string,
    c_size_t,
    c_void_pointer,
    unsafe_ptr_as_scalar_pointer,
)
from .mo import (
    seq_ssmap_new,
    seq_ssmap_free,
    seq_ssmap_get,
    seq_ssmap_set,
    seq_ssmap_size,
    logd,
)


struct SSMap:
    var ptr: c_void_pointer

    fn __init__(inout self):
        self.ptr = seq_ssmap_new()

    fn __del__(owned self):
        seq_ssmap_free(self.ptr)

    fn __moveinit__(inout self, owned existing: Self):
        self.ptr = existing.ptr

    fn __setitem__(inout self, key: String, value: String):
        seq_ssmap_set(
            self.ptr,
            unsafe_ptr_as_scalar_pointer(key.unsafe_ptr()),
            unsafe_ptr_as_scalar_pointer(value.unsafe_ptr()),
        )

    fn __getitem__(self, key: String) -> String:
        var n: c_size_t = 0
        var s = seq_ssmap_get(
            self.ptr,
            unsafe_ptr_as_scalar_pointer(key.unsafe_ptr()),
            Pointer[c_size_t].address_of(n),
        )
        return c_str_to_string(s, n)

    fn __len__(self) -> Int:
        return seq_ssmap_size(self.ptr)
