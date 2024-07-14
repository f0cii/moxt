from collections.list import List
from .c import *
from .mo import *


fn seq_get_next_cache_key() -> Int64:
    return external_call[
        "seq_get_next_cache_key",
        Int64,
    ]()


fn seq_set_string_in_cache(
    key: Int64, value: c_char_pointer, value_len: c_size_t
) -> c_char_pointer:
    return external_call[
        "seq_set_string_in_cache",
        c_char_pointer,
        Int64,
        c_char_pointer,
        c_size_t,
    ](key, value, value_len)


fn seq_get_string_in_cache(
    key: Int64, result_len: Pointer[c_size_t]
) -> c_char_pointer:
    return external_call[
        "seq_get_string_in_cache",
        c_char_pointer,
        Int64,
        Pointer[c_size_t],
    ](key, result_len)


fn seq_free_string_in_cache(key: Int64) -> Bool:
    return external_call[
        "seq_free_string_in_cache",
        Bool,
        Int64,
    ](key)


@value
struct StringCache:
    fn __init__(inout self):
        pass

    @staticmethod
    fn set_string(s: String) -> Tuple[Int64, CString]:
        var key = seq_get_next_cache_key()
        var length = len(s)
        var result = seq_set_string_in_cache(
            key, unsafe_ptr_as_scalar_pointer(s.unsafe_ptr()), length
        )
        return Tuple[Int64, CString](key, CString(result, length))

    @staticmethod
    fn get_string(key: Int64) -> Tuple[Int64, CString]:
        var length: c_size_t = 0
        var result = seq_get_string_in_cache(
            key, Pointer[c_size_t].address_of(length)
        )
        return Tuple[Int64, CString](key, CString(result, length))

    @staticmethod
    fn free_string(key: Int64) -> Bool:
        return seq_free_string_in_cache(key)


@value
@register_passable
struct CString:
    var data: c_char_pointer
    var len: Int

    fn data_u8(self) -> UnsafePointer[SIMD[DType.uint8, 1]]:
        return rebind[
            UnsafePointer[SIMD[DType.uint8, 1]], UnsafePointer[SIMD[DType.int8, 1]]
        ](self.data)


@value
struct MyStringCache:
    var _keys: List[Int64]

    fn __init__(inout self):
        self._keys = List[Int64]()

    fn __del__(owned self):
        for key in self._keys:
            _ = StringCache.free_string(key[])

    fn set_string(inout self, s: String) -> CString:
        var r = StringCache.set_string(s)
        var key = r.get[0, Int64]()
        var result = r.get[1, CString]()
        self._keys.append(key)
        return result
