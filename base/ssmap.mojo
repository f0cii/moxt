import sys
from .c import c_str_to_string, c_size_t, c_void_pointer
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
        # logd("SSMap.__init__")
        self.ptr = seq_ssmap_new()

    fn __del__(owned self):
        # logd("SSMap.__del__")
        seq_ssmap_free(self.ptr)

    fn __moveinit__(inout self, owned existing: Self):
        # logd("SSMap.__moveinit__")
        self.ptr = existing.ptr

    fn __setitem__(inout self, key: StringLiteral, value: String):
        seq_ssmap_set(
            self.ptr, key.data()._as_scalar_pointer(), value._buffer.data.value
        )

    fn __getitem__(self, key: StringLiteral) -> String:
        var n: c_size_t = 0
        let s = seq_ssmap_get(
            self.ptr, key.data()._as_scalar_pointer(), Pointer[c_size_t].address_of(n)
        )
        return c_str_to_string(s, n)

    fn __len__(self) -> Int:
        return seq_ssmap_size(self.ptr)
