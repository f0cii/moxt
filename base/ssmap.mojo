import sys
from .c import c_str_to_string, c_size_t, c_void_pointer
from .mo import (
    seq_ssmap_new,
    seq_ssmap_free,
    seq_ssmap_get,
    seq_ssmap_set,
    seq_ssmap_size,
)


@value
struct SSMap:
    var ptr: c_void_pointer

    fn __init__(inout self):
        self.ptr = seq_ssmap_new()

    fn release(self):
        seq_ssmap_free(self.ptr)

    fn __setitem__(inout self, key: StringLiteral, value: String):
        """
        设置 m[key] = value
        """
        # seq_ssmap_set(self.ptr, key.data()._as_scalar_pointer(), value.data()._as_scalar_pointer())
        seq_ssmap_set(
            self.ptr, key.data()._as_scalar_pointer(), value._buffer.data.value
        )

    fn __getitem__(self, key: StringLiteral) -> String:
        """
        获取 m[key]
        """
        var n: c_size_t = 0
        let s = seq_ssmap_get(
            self.ptr, key.data()._as_scalar_pointer(), Pointer[c_size_t].address_of(n)
        )
        return c_str_to_string(s, n)

    fn __len__(self) -> Int:
        return seq_ssmap_size(self.ptr)
