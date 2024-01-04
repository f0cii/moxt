from memory import unsafe
from .c import *
from .mo import *
from base.str_cache import *


fn seq_sonic_json_document_new() -> c_void_pointer:
    return external_call[
        "seq_sonic_json_document_new",
        c_void_pointer,
    ]()


fn seq_sonic_json_document_free(doc: c_void_pointer) -> None:
    external_call[
        "seq_sonic_json_document_free",
        NoneType,
        c_void_pointer,
    ](doc)


fn seq_sonic_json_document_get_allocator(doc: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_sonic_json_document_get_allocator",
        c_void_pointer,
        c_void_pointer,
    ](doc)


fn seq_sonic_json_document_set_object(doc: c_void_pointer) -> None:
    external_call[
        "seq_sonic_json_document_set_object",
        NoneType,
        c_void_pointer,
    ](doc)


fn seq_sonic_json_document_add_string(
    doc: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: c_char_pointer,
    value_len: c_size_t,
) -> None:
    return __mlir_op.`pop.external_call`[
        func = "seq_sonic_json_document_add_string".value, _type=NoneType
    ](doc, alloc, key, key_len, value, value_len)


fn seq_sonic_json_document_add_int(
    doc: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: Int64,
) -> None:
    external_call[
        "seq_sonic_json_document_add_int",
        NoneType,
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Int64,
    ](doc, alloc, key, key_len, value)


fn seq_sonic_json_document_add_double(
    doc: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: Float64,
) -> None:
    external_call[
        "seq_sonic_json_document_add_double",
        NoneType,
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Float64,
    ](doc, alloc, key, key_len, value)


fn seq_sonic_json_document_add_bool(
    doc: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: Bool,
) -> None:
    external_call[
        "seq_sonic_json_document_add_bool",
        NoneType,
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Bool,
    ](doc, alloc, key, key_len, value)


fn seq_sonic_json_document_add_string_array(
    doc: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: c_char_pointer,
    value_len: c_size_t,
) -> None:
    return __mlir_op.`pop.external_call`[
        func = "seq_sonic_json_document_add_string_array".value, _type=NoneType
    ](doc, alloc, key, key_len, value, value_len)


fn seq_sonic_json_document_add_int_array(
    doc: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: c_char_pointer,
    value_len: c_size_t,
) -> None:
    return __mlir_op.`pop.external_call`[
        func = "seq_sonic_json_document_add_int_array".value, _type=NoneType
    ](doc, alloc, key, key_len, value, value_len)


fn seq_sonic_json_document_add_double_array(
    doc: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: c_char_pointer,
    value_len: c_size_t,
) -> None:
    return __mlir_op.`pop.external_call`[
        func = "seq_sonic_json_document_add_double_array".value, _type=NoneType
    ](doc, alloc, key, key_len, value, value_len)


fn seq_sonic_json_document_add_bool_array(
    doc: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: c_char_pointer,
    value_len: c_size_t,
) -> None:
    return __mlir_op.`pop.external_call`[
        func = "seq_sonic_json_document_add_bool_array".value, _type=NoneType
    ](doc, alloc, key, key_len, value, value_len)


fn seq_sonic_json_document_to_string(
    doc: c_void_pointer,
    result: c_char_pointer,
) -> c_size_t:
    return external_call[
        "seq_sonic_json_document_to_string",
        c_size_t,
        c_void_pointer,
        c_char_pointer,
    ](doc, result)


@value
struct SonicDocument:
    var _doc: c_void_pointer
    var _alloc: c_void_pointer
    var _sc: MyStringCache

    fn __init__(inout self):
        self._doc = seq_sonic_json_document_new()
        self._alloc = seq_sonic_json_document_get_allocator(self._doc)
        self._sc = MyStringCache()

    fn __del__(owned self):
        seq_sonic_json_document_free(self._doc)

    fn set_object(self):
        seq_sonic_json_document_set_object(self._doc)

    fn add_string(inout self, key: StringLiteral, value: String) raises -> None:
        let v = self._sc.set_string(value)
        seq_sonic_json_document_add_string(
            self._doc,
            self._alloc,
            key.data()._as_scalar_pointer(),
            len(key),
            v.data,
            v.len,
        )

    fn to_string(self, buff_size: Int = 1024) -> String:
        let result = Pointer[c_schar].alloc(buff_size)
        let n = seq_sonic_json_document_to_string(self._doc, result)
        let result_str = c_str_to_string(result, n)
        result.free()
        return result_str
