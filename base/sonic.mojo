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


fn seq_sonic_json_node_new() -> c_void_pointer:
    return external_call[
        "seq_sonic_json_node_new",
        c_void_pointer,
    ]()


fn seq_sonic_json_node_free(node: c_void_pointer):
    external_call[
        "seq_sonic_json_node_free",
        NoneType,
        c_void_pointer,
    ](node)


fn seq_sonic_json_node_set_object(node: c_void_pointer):
    external_call[
        "seq_sonic_json_node_set_object",
        NoneType,
        c_void_pointer,
    ](node)


fn seq_sonic_json_document_add_node(
    doc: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    node: c_void_pointer,
):
    return __mlir_op.`pop.external_call`[
        func = "seq_sonic_json_document_add_node".value, _type=NoneType
    ](doc, alloc, key, key_len, node)


fn seq_sonic_json_node_add_string(
    node: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: c_char_pointer,
    value_len: c_size_t,
) -> None:
    return __mlir_op.`pop.external_call`[
        func = "seq_sonic_json_node_add_string".value, _type=NoneType
    ](node, alloc, key, key_len, value, value_len)


fn seq_sonic_json_node_add_int(
    node: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: Int64,
) -> None:
    external_call[
        "seq_sonic_json_node_add_int",
        NoneType,
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Int64,
    ](node, alloc, key, key_len, value)


fn seq_sonic_json_node_add_double(
    node: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: Float64,
) -> None:
    external_call[
        "seq_sonic_json_node_add_double",
        NoneType,
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Float64,
    ](node, alloc, key, key_len, value)


fn seq_sonic_json_node_add_bool(
    node: c_void_pointer,
    alloc: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: Bool,
) -> None:
    external_call[
        "seq_sonic_json_node_add_bool",
        NoneType,
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Bool,
    ](node, alloc, key, key_len, value)


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

    @always_inline
    fn set_object(self):
        seq_sonic_json_document_set_object(self._doc)

    @always_inline
    fn add_string(inout self, key: String, value: String) raises -> None:
        var v = self._sc.set_string(value)
        seq_sonic_json_document_add_string(
            self._doc,
            self._alloc,
            key._as_ptr()._as_scalar_pointer(),
            len(key),
            v.data,
            v.len,
        )

    @always_inline
    fn add_int(inout self, key: String, value: Int) raises -> None:
        seq_sonic_json_document_add_int(
            self._doc,
            self._alloc,
            key._as_ptr()._as_scalar_pointer(),
            len(key),
            value,
        )

    @always_inline
    fn add_float(inout self, key: String, value: Float64) raises -> None:
        seq_sonic_json_document_add_double(
            self._doc,
            self._alloc,
            key._as_ptr()._as_scalar_pointer(),
            len(key),
            value,
        )

    @always_inline
    fn add_bool(inout self, key: String, value: Bool) raises -> None:
        seq_sonic_json_document_add_bool(
            self._doc,
            self._alloc,
            key._as_ptr()._as_scalar_pointer(),
            len(key),
            value,
        )

    @always_inline
    fn add_node(inout self, key: String, node: SonicNode) raises -> None:
        seq_sonic_json_document_add_node(
            self._doc,
            self._alloc,
            key._as_ptr()._as_scalar_pointer(),
            len(key),
            node._node,
        )

    @always_inline
    fn to_string(self, buff_size: Int = 1024) -> String:
        var result = Pointer[c_schar].alloc(buff_size)
        var n = seq_sonic_json_document_to_string(self._doc, result)
        var result_str = c_str_to_string(result, n)
        result.free()
        return result_str


@value
struct SonicNode:
    var _node: c_void_pointer
    var _alloc: c_void_pointer
    var _sc: MyStringCache

    fn __init__(inout self, doc: SonicDocument):
        self._node = seq_sonic_json_node_new()
        self._alloc = doc._alloc
        self._sc = MyStringCache()

    fn __del__(owned self):
        seq_sonic_json_node_free(self._node)

    @always_inline
    fn set_object(self):
        seq_sonic_json_node_set_object(self._node)

    @always_inline
    fn add_string(inout self, key: String, value: String) raises -> None:
        var v = self._sc.set_string(value)
        seq_sonic_json_node_add_string(
            self._node,
            self._alloc,
            key._as_ptr()._as_scalar_pointer(),
            len(key),
            v.data,
            v.len,
        )

    @always_inline
    fn add_int(inout self, key: String, value: Int) raises -> None:
        seq_sonic_json_node_add_int(
            self._node,
            self._alloc,
            key._as_ptr()._as_scalar_pointer(),
            len(key),
            value,
        )

    @always_inline
    fn add_float(inout self, key: String, value: Float64) raises -> None:
        seq_sonic_json_node_add_double(
            self._node,
            self._alloc,
            key._as_ptr()._as_scalar_pointer(),
            len(key),
            value,
        )

    @always_inline
    fn add_bool(inout self, key: String, value: Bool) raises -> None:
        seq_sonic_json_node_add_bool(
            self._node,
            self._alloc,
            key._as_ptr()._as_scalar_pointer(),
            len(key),
            value,
        )
