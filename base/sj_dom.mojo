from .c import *
from .mo import *


fn seq_simdjson_dom_parser_new(max_capacity: Int) -> c_void_pointer:
    return external_call["seq_simdjson_dom_parser_new", c_void_pointer, c_size_t](
        max_capacity
    )


fn seq_simdjson_dom_parser_free(parser: c_void_pointer) -> None:
    external_call["seq_simdjson_dom_parser_free", NoneType, c_void_pointer](parser)


fn seq_simdjson_dom_parser_parse(
    parser: c_void_pointer, s: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_parser_parse",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](parser, s, len)


fn seq_simdjson_dom_element_is_valid(p: c_void_pointer) -> Bool:
    return external_call["seq_simdjson_dom_element_is_valid", Bool, c_void_pointer](p)


fn seq_simdjson_dom_element_free(p: c_void_pointer) -> None:
    external_call["seq_simdjson_dom_element_free", NoneType, c_void_pointer](p)


fn seq_simdjson_dom_document_get_element(
    document: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_document_get_element",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](document, key, len)


fn seq_simdjson_dom_element_get_int(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> Int:
    return external_call[
        "seq_simdjson_dom_element_get_int",
        Int,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_dom_element_get_uint(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> Int:
    return external_call[
        "seq_simdjson_dom_element_get_uint",
        Int,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_dom_element_get_float(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> Float64:
    return external_call[
        "seq_simdjson_dom_element_get_float",
        Float64,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_dom_element_get_bool(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> Bool:
    return external_call[
        "seq_simdjson_dom_element_get_bool",
        Bool,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_dom_object_get_int(
    dom: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> Int:
    return external_call[
        "seq_simdjson_dom_object_get_int", Int, c_void_pointer, c_char_pointer, c_size_t
    ](dom, key, len)


fn seq_simdjson_dom_object_get_uint(
    dom: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> Int:
    return external_call[
        "seq_simdjson_dom_object_get_uint",
        Int,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](dom, key, len)


fn seq_simdjson_dom_object_get_float(
    dom: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> Float64:
    return external_call[
        "seq_simdjson_dom_object_get_float",
        Float64,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](dom, key, len)


fn seq_simdjson_dom_object_get_bool(
    dom: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> Bool:
    return external_call[
        "seq_simdjson_dom_object_get_bool",
        Bool,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](dom, key, len)


fn seq_simdjson_dom_element_get_object(
    element: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_element_get_object",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](element, key, len)


fn seq_simdjson_dom_element_get_array(
    element: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_element_get_array",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](element, key, len)


fn seq_simdjson_dom_object_get_object(
    obj: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_object_get_object",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](obj, key, len)


fn seq_simdjson_dom_object_get_array(
    obj: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_object_get_array",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](obj, key, len)


fn seq_simdjson_dom_element_int(p: c_void_pointer) -> Int:
    return external_call["seq_simdjson_dom_element_int", Int, c_void_pointer](p)


fn seq_simdjson_dom_element_uint(p: c_void_pointer) -> Int:
    return external_call["seq_simdjson_dom_element_uint", Int, c_void_pointer](p)


fn seq_simdjson_dom_element_float(p: c_void_pointer) -> Float64:
    return external_call["seq_simdjson_dom_element_float", Float64, c_void_pointer](p)


fn seq_simdjson_dom_element_bool(p: c_void_pointer) -> Bool:
    return external_call["seq_simdjson_dom_element_bool", Bool, c_void_pointer](p)


fn seq_simdjson_dom_object_free(p: c_void_pointer) -> None:
    external_call["seq_simdjson_dom_object_free", NoneType, c_void_pointer](p)


fn seq_simdjson_dom_array_free(p: c_void_pointer) -> None:
    external_call["seq_simdjson_dom_array_free", NoneType, c_void_pointer](p)


fn seq_simdjson_dom_array_iter_free(p: c_void_pointer) -> None:
    external_call["seq_simdjson_dom_array_iter_free", NoneType, c_void_pointer](p)


fn seq_simdjson_dom_element_str(
    p: c_void_pointer, n: Pointer[c_size_t]
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_element_str",
        c_void_pointer,
        c_void_pointer,
        Pointer[c_size_t],
    ](p, n)


fn seq_simdjson_dom_element_type(p: c_void_pointer) -> Int:
    return external_call["seq_simdjson_dom_element_type", Int, c_void_pointer](p)


fn seq_simdjson_dom_element_object(p: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_element_object", c_void_pointer, c_void_pointer
    ](p)


fn seq_simdjson_dom_element_array(p: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_element_array", c_void_pointer, c_void_pointer
    ](p)


fn seq_simdjson_dom_element_get_str(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t, n: Pointer[c_size_t]
) -> c_char_pointer:
    return external_call[
        "seq_simdjson_dom_element_get_str",
        c_char_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Pointer[c_size_t],
    ](p, key, len, n)


fn seq_simdjson_dom_object_get_str(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t, n: Pointer[c_size_t]
) -> c_char_pointer:
    return external_call[
        "seq_simdjson_dom_object_get_str",
        c_char_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Pointer[c_size_t],
    ](p, key, len, n)


fn seq_simdjson_dom_array_begin(p: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_array_begin", c_void_pointer, c_void_pointer
    ](p)


fn seq_simdjson_dom_array_end(p: c_void_pointer) -> c_void_pointer:
    return external_call["seq_simdjson_dom_array_end", c_void_pointer, c_void_pointer](
        p
    )


fn seq_simdjson_dom_array_size(p: c_void_pointer) -> Int:
    return external_call["seq_simdjson_dom_array_size", Int, c_void_pointer](p)


fn seq_simdjson_dom_array_number_of_slots(p: c_void_pointer) -> Int:
    return external_call["seq_simdjson_dom_array_number_of_slots", Int, c_void_pointer](
        p
    )


fn seq_simdjson_dom_array_at(p: c_void_pointer, index: c_size_t) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_array_at", c_void_pointer, c_void_pointer, c_size_t
    ](p, index)


fn seq_simdjson_dom_array_at_int(p: c_void_pointer, index: c_size_t) -> Int:
    return external_call[
        "seq_simdjson_dom_array_at_int", Int, c_void_pointer, c_size_t
    ](p, index)


fn seq_simdjson_dom_array_at_uint(p: c_void_pointer, index: c_size_t) -> Int:
    return external_call[
        "seq_simdjson_dom_array_at_uint", Int, c_void_pointer, c_size_t
    ](p, index)


fn seq_simdjson_dom_array_at_float(p: c_void_pointer, index: c_size_t) -> Float64:
    return external_call[
        "seq_simdjson_dom_array_at_float", Float64, c_void_pointer, c_size_t
    ](p, index)


fn seq_simdjson_dom_array_at_bool(p: c_void_pointer, index: c_size_t) -> Bool:
    return external_call[
        "seq_simdjson_dom_array_at_bool", Bool, c_void_pointer, c_size_t
    ](p, index)


fn seq_simdjson_dom_array_at_str(
    p: c_void_pointer, index: c_size_t, n: Pointer[c_size_t]
) -> c_char_pointer:
    return external_call[
        "seq_simdjson_dom_array_at_str",
        c_char_pointer,
        c_void_pointer,
        c_size_t,
        Pointer[c_size_t],
    ](p, index, n)


fn seq_simdjson_dom_array_at_obj(p: c_void_pointer, index: c_size_t) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_array_at_obj", c_void_pointer, c_void_pointer, c_size_t
    ](p, index)


fn seq_simdjson_dom_array_at_arr(p: c_void_pointer, index: c_size_t) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_array_at_arr", c_void_pointer, c_void_pointer, c_size_t
    ](p, index)


fn seq_simdjson_dom_array_at_pointer(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_array_at_pointer",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_dom_array_iter_get(it: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_array_iter_get", c_void_pointer, c_void_pointer
    ](it)


fn seq_simdjson_dom_array_iter_get_int(it: c_void_pointer) -> Int:
    return external_call["seq_simdjson_dom_array_iter_get_int", Int, c_void_pointer](it)


fn seq_simdjson_dom_array_iter_get_uint(it: c_void_pointer) -> Int:
    return external_call["seq_simdjson_dom_array_iter_get_uint", Int, c_void_pointer](
        it
    )


fn seq_simdjson_dom_array_iter_get_float(it: c_void_pointer) -> Float64:
    return external_call[
        "seq_simdjson_dom_array_iter_get_float", Float64, c_void_pointer
    ](it)


fn seq_simdjson_dom_array_iter_get_bool(it: c_void_pointer) -> Bool:
    return external_call["seq_simdjson_dom_array_iter_get_bool", Bool, c_void_pointer](
        it
    )


fn seq_simdjson_dom_array_iter_get_str(
    it: c_void_pointer, n: Pointer[c_size_t]
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_array_iter_get_str",
        c_void_pointer,
        c_void_pointer,
        Pointer[c_size_t],
    ](it, n)


fn seq_simdjson_dom_array_iter_get_obj(it: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_array_iter_get_obj", c_void_pointer, c_void_pointer
    ](it)


fn seq_simdjson_dom_array_iter_get_arr(it: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_dom_array_iter_get_arr", c_void_pointer, c_void_pointer
    ](it)


fn seq_simdjson_dom_array_iter_not_equal(
    lhs: c_void_pointer, rhs: c_void_pointer
) -> Bool:
    return external_call[
        "seq_simdjson_dom_array_iter_not_equal", Bool, c_void_pointer, c_void_pointer
    ](lhs, rhs)


fn seq_simdjson_dom_array_iter_step(it: c_void_pointer) -> None:
    external_call["seq_simdjson_dom_array_iter_step", NoneType, c_void_pointer](it)


@value
struct DomElement:
    var p: c_void_pointer

    @always_inline
    fn __init__(inout self, p: c_void_pointer):
        self.p = p

    @always_inline
    fn __del__(owned self):
        # logd("DomElement.__del__")
        seq_simdjson_dom_element_free(self.p)
        # logd("DomElement.__del__ done")

    @always_inline
    fn __getitem__(self, key: StringLiteral) -> DomElement:
        let elem = seq_simdjson_dom_document_get_element(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )
        return DomElement(elem)

    @always_inline
    fn get_int(self, key: StringLiteral) -> Int:
        return seq_simdjson_dom_element_get_int(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_uint(self, key: StringLiteral) -> Int:
        return seq_simdjson_dom_element_get_uint(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_float(self, key: StringLiteral) -> Float64:
        return seq_simdjson_dom_element_get_float(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_bool(self, key: StringLiteral) -> Bool:
        return seq_simdjson_dom_element_get_bool(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_str(self, key: StringLiteral) -> String:
        var n: c_size_t = 0
        let s = seq_simdjson_dom_element_get_str(
            self.p,
            key.data()._as_scalar_pointer(),
            len(key),
            Pointer[c_size_t].address_of(n),
        )
        return c_str_to_string(s, n)

    @always_inline
    fn get_object(self, key: StringLiteral) -> DomObject:
        let p = seq_simdjson_dom_element_get_object(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )
        return DomObject(p)

    @always_inline
    fn get_array(self, key: StringLiteral) -> DomArray:
        let p = seq_simdjson_dom_element_get_array(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )
        return DomArray(p)

    @always_inline
    fn type(self) -> Int:
        return seq_simdjson_dom_element_type(self.p)

    @always_inline
    fn type_desc(self) -> String:
        let type_ = seq_simdjson_dom_element_type(self.p)
        if type_ == 0:
            return "array"
        elif type_ == 1:
            return "object"
        elif type_ == 2:
            return "int64_t"
        elif type_ == 3:
            return "uint64_t"
        elif type_ == 4:
            return "double"
        elif type_ == 5:
            return "string"
        elif type_ == 6:
            return "bool"
        elif type_ == 7:
            return "null"
        elif type_ == 9:
            return "unexpected content!!!"
        else:
            return "--"

    @always_inline
    fn object(self) -> DomObject:
        let p = seq_simdjson_dom_element_object(self.p)
        return DomObject(p)

    @always_inline
    fn array(self) -> DomArray:
        let p = seq_simdjson_dom_element_array(self.p)
        return DomArray(p)

    @always_inline
    fn int(self) -> Int:
        return seq_simdjson_dom_element_int(self.p)

    @always_inline
    fn uint(self) -> Int:
        return seq_simdjson_dom_element_uint(self.p)

    @always_inline
    fn float(self) -> Float64:
        return seq_simdjson_dom_element_float(self.p)

    @always_inline
    fn bool(self) -> Bool:
        return seq_simdjson_dom_element_bool(self.p)

    @always_inline
    fn str(self) -> String:
        var n: c_size_t = 0
        let s = seq_simdjson_dom_element_str(self.p, Pointer[c_size_t].address_of(n))
        return c_str_to_string(s, n)

    fn __repr__(self) -> String:
        return "<DomElement: p={self.p}>"


@value
struct DomObject(CollectionElement):
    var p: c_void_pointer

    @always_inline
    fn __init__(inout self, p: c_void_pointer):
        self.p = p

    @always_inline
    fn __del__(owned self):
        # logd("DomObject.__del__")
        seq_simdjson_dom_object_free(self.p)
        # logd("DomObject.__del__ done")

    @always_inline
    fn get_int(self, key: StringLiteral) -> Int:
        return seq_simdjson_dom_object_get_int(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_uint(self, key: StringLiteral) -> Int:
        return seq_simdjson_dom_object_get_uint(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_float(self, key: StringLiteral) -> Float64:
        return seq_simdjson_dom_object_get_float(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_bool(self, key: StringLiteral) -> Bool:
        return seq_simdjson_dom_object_get_bool(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_str(self, key: StringLiteral) -> String:
        var n: c_size_t = 0
        let s = seq_simdjson_dom_object_get_str(
            self.p,
            key.data()._as_scalar_pointer(),
            len(key),
            Pointer[c_size_t].address_of(n),
        )
        return c_str_to_string(s, n)

    @always_inline
    fn get_object(self, key: StringLiteral) -> DomObject:
        let p = seq_simdjson_dom_object_get_object(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )
        return DomObject(p)

    @always_inline
    fn get_array(self, key: StringLiteral) -> DomArray:
        let p = seq_simdjson_dom_object_get_array(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )
        return DomArray(p)

    fn __repr__(self) -> String:
        return "<DomObject: p={self.p}>"


@value
struct DomArray:
    var p: c_void_pointer

    @always_inline
    fn __init__(inout self, p: c_void_pointer):
        self.p = p

    @always_inline
    fn __del__(owned self):
        # logd("DomArray.__del__")
        seq_simdjson_dom_array_free(self.p)
        # logd("DomArray.__del__ done")

    @always_inline
    fn __len__(self) -> Int:
        return seq_simdjson_dom_array_size(self.p)

    @always_inline
    fn number_of_slots(self) -> Int:
        return seq_simdjson_dom_array_number_of_slots(self.p)

    @always_inline
    fn at(self, index: Int) -> DomElement:
        let p = seq_simdjson_dom_array_at(self.p, index)
        return DomElement(p)

    @always_inline
    fn at_int(self, index: Int) -> Int:
        return seq_simdjson_dom_array_at_int(self.p, index)

    @always_inline
    fn at_uint(self, index: Int) -> Int:
        return seq_simdjson_dom_array_at_uint(self.p, index)

    @always_inline
    fn at_float(self, index: Int) -> Float64:
        return seq_simdjson_dom_array_at_float(self.p, index)

    @always_inline
    fn at_bool(self, index: Int) -> Bool:
        return seq_simdjson_dom_array_at_bool(self.p, index)

    @always_inline
    fn at_str(self, index: Int) -> String:
        var n: c_size_t = 0
        let s = seq_simdjson_dom_array_at_str(
            self.p, index, Pointer[c_size_t].address_of(n)
        )
        return c_str_to_string(s, n)

    @always_inline
    fn at_obj(self, index: Int) -> DomObject:
        let p = seq_simdjson_dom_array_at_obj(self.p, index)
        return DomObject(p)

    @always_inline
    fn at_arr(self, index: Int) -> DomArray:
        let p = seq_simdjson_dom_array_at_arr(self.p, index)
        return DomArray(p)

    @always_inline
    fn iter(self) -> DomArrayIter:
        return DomArrayIter(self.p)

    fn __repr__(self) -> String:
        return "<DomArray: p={self.p}>"


@value
struct DomArrayIter:
    var arr: c_void_pointer
    var it: c_void_pointer
    var end: c_void_pointer

    @always_inline
    fn __init__(inout self, arr: c_void_pointer):
        self.arr = arr
        self.it = seq_simdjson_dom_array_begin(arr)
        self.end = seq_simdjson_dom_array_end(arr)

    @always_inline
    fn __del__(owned self):
        # logd("DomArrayIter.__del__")
        seq_simdjson_dom_array_iter_free(self.it)
        seq_simdjson_dom_array_iter_free(self.end)
        # seq_simdjson_dom_array_free(self.arr)
        # logd("DomArrayIter.__del__ done")

    @always_inline
    fn has_element(self) -> Bool:
        return seq_simdjson_dom_array_iter_not_equal(self.it, self.end)

    @always_inline
    fn get(self) -> DomElement:
        let p = seq_simdjson_dom_array_iter_get(self.it)
        return DomElement(p)

    @always_inline
    fn get_int(self) -> Int:
        return seq_simdjson_dom_array_iter_get_int(self.it)

    @always_inline
    fn get_uint(self) -> Int:
        return seq_simdjson_dom_array_iter_get_uint(self.it)

    @always_inline
    fn get_float(self) -> Float64:
        return seq_simdjson_dom_array_iter_get_float(self.it)

    @always_inline
    fn get_bool(self) -> Bool:
        return seq_simdjson_dom_array_iter_get_bool(self.it)

    @always_inline
    fn get_str(self) -> String:
        var n: c_size_t = 0
        let s = seq_simdjson_dom_array_iter_get_str(
            self.it, Pointer[c_size_t].address_of(n)
        )
        return c_str_to_string(s, n)

    @always_inline
    fn step(self):
        seq_simdjson_dom_array_iter_step(self.it)

    fn __repr__(self) -> String:
        return "<DomArrayIter: arr={self.arr} it={self.it} end={self.end}>"


@value
struct DomParser:
    var p: c_void_pointer

    @always_inline
    fn __init__(inout self, max_capacity: Int):
        self.p = seq_simdjson_dom_parser_new(max_capacity)

    @always_inline
    fn __del__(owned self):
        # logd("DomParser.__del__")
        seq_simdjson_dom_parser_free(self.p)
        # logd("DomParser.__del__ done")

    @always_inline
    fn parse(self, s: StringLiteral) -> DomElement:
        return DomElement(
            seq_simdjson_dom_parser_parse(self.p, s.data()._as_scalar_pointer(), len(s))
        )

    @always_inline
    fn parse(self, s: StringRef) -> DomElement:
        return DomElement(
            seq_simdjson_dom_parser_parse(self.p, s.data._as_scalar_pointer(), len(s))
        )

    @always_inline
    fn parse(self, s: String) raises -> DomElement:
        let p = seq_simdjson_dom_parser_parse(self.p, s._buffer.data.value, len(s))
        if not seq_simdjson_dom_element_is_valid(p):
            raise Error("JSON parsing error: [" + s + "]")
        return DomElement(p)

    @always_inline
    fn parse(self, data: Pointer[c_schar], data_len: Int) raises -> DomElement:
        let p = seq_simdjson_dom_parser_parse(self.p, data, data_len)
        if not seq_simdjson_dom_element_is_valid(p):
            raise Error("JSON parsing error: [" + c_str_to_string(data, data_len) + "]")
        return DomElement(p)

    fn __repr__(self) -> String:
        return "<DomParser: p={self.p}>"
