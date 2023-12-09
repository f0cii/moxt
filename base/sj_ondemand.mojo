from .c import *
from .mo import *


struct OndemandValue:
    var p: c_void_pointer

    @always_inline
    fn __init__(inout self, p: c_void_pointer):
        self.p = p

    @always_inline
    fn __del__(owned self):
        logd("OndemandValue.__del__")
        seq_simdjson_ondemand_value_free(self.p)

    @always_inline
    fn int(self) -> Int:
        return seq_simdjson_ondemand_int_v(self.p).to_int()

    @always_inline
    fn __copyinit__(inout self, existing: Self):
        self.p = existing.p

    @always_inline
    fn uint(self) -> Int:
        return seq_simdjson_ondemand_uint_v(self.p).to_int()

    @always_inline
    fn float(self) -> Float64:
        return seq_simdjson_ondemand_float_v(self.p)

    @always_inline
    fn bool(self) -> Bool:
        return seq_simdjson_ondemand_bool_v(self.p)

    @always_inline
    fn str(self) -> String:
        var n: c_size_t = 0
        let s = seq_simdjson_ondemand_string_v(self.p, Pointer[c_size_t].address_of(n))
        return c_str_to_string(s, n)

    @always_inline
    fn object(self) -> OndemandObject:
        let p = seq_simdjson_ondemand_object_v(self.p)
        return OndemandObject(p)

    @always_inline
    fn array(self) -> OndemandArray:
        let p = seq_simdjson_ondemand_array_v(self.p)
        return OndemandArray(p)

    @always_inline
    fn type(self) -> Int:
        return seq_simdjson_ondemand_value_type(self.p).to_int()

    @always_inline
    fn type_desc(self) -> String:
        let type_ = seq_simdjson_ondemand_value_type(self.p)
        if type_ == 1:
            return "array"
        elif type_ == 2:
            return "object"
        elif type_ == 3:
            return "number"
        elif type_ == 4:
            return "string"
        elif type_ == 5:
            return "boolean"
        elif type_ == 6:
            return "null"
        else:
            return "--"

    @always_inline
    fn get_int(self, key: StringLiteral) -> Int:
        return seq_simdjson_ondemand_get_int_v(
            self.p, key.data()._as_scalar_pointer(), len(key)
        ).to_int()

    @always_inline
    fn get_uint(self, key: StringLiteral) -> Int:
        return seq_simdjson_ondemand_get_uint_v(
            self.p, key.data()._as_scalar_pointer(), len(key)
        ).to_int()

    @always_inline
    fn get_float(self, key: StringLiteral) -> Float64:
        return seq_simdjson_ondemand_get_float_v(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_bool(self, key: StringLiteral) -> Bool:
        return seq_simdjson_ondemand_get_bool_v(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_str(self, key: StringLiteral) -> String:
        var n: c_size_t = 0
        let s = seq_simdjson_ondemand_get_string_v(
            self.p,
            key.data()._as_scalar_pointer(),
            len(key),
            Pointer[c_size_t].address_of(n),
        )
        return c_str_to_string(s, n)

    @always_inline
    fn get_object(self, key: StringLiteral) -> OndemandObject:
        let p = seq_simdjson_ondemand_get_object_v(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )
        return OndemandObject(p)

    @always_inline
    fn get_array(self, key: StringLiteral) -> OndemandArray:
        let p = seq_simdjson_ondemand_get_array_v(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )
        return OndemandArray(p)

    fn __repr__(self) -> String:
        return "<OndemandValue: ctx={self.ctx} p={self.p}>"


@value
struct OndemandArray:
    var p: c_void_pointer

    @always_inline
    fn __init__(inout self, p: c_void_pointer):
        self.p = p

    @always_inline
    fn __del__(owned self):
        logd("OndemandArray.__del__")
        seq_simdjson_ondemand_array_free(self.p)

    @always_inline
    fn __len__(self) -> Int:
        return seq_simdjson_ondemand_array_count_elements(self.p)

    @always_inline
    fn at(self, index: Int) -> OndemandValue:
        let p = seq_simdjson_ondemand_array_at(self.p, index)
        return OndemandValue(p)

    @always_inline
    fn at_int(self, index: Int) -> Int:
        return seq_simdjson_ondemand_array_at_int(self.p, index).to_int()

    @always_inline
    fn at_uint(self, index: Int) -> Int:
        return seq_simdjson_ondemand_array_at_uint(self.p, index).to_int()

    @always_inline
    fn at_float(self, index: Int) -> Float64:
        return seq_simdjson_ondemand_array_at_float(self.p, index)

    @always_inline
    fn at_bool(self, index: Int) -> Bool:
        return seq_simdjson_ondemand_array_at_bool(self.p, index)

    @always_inline
    fn at_str(self, index: Int) -> String:
        var n: c_size_t = 0
        let s = seq_simdjson_ondemand_array_at_str(
            self.p, index, Pointer[c_size_t].address_of(n)
        )
        return c_str_to_string(s, n)

    @always_inline
    fn at_object(self, index: Int) -> OndemandObject:
        let p = seq_simdjson_ondemand_array_at_obj(self.p, index)
        return OndemandObject(p)

    @always_inline
    fn at_array(self, index: Int) -> OndemandArray:
        let p = seq_simdjson_ondemand_array_at_arr(self.p, index)
        return OndemandArray(p)

    @always_inline
    fn iter(self) -> OndemandArrayIter:
        return OndemandArrayIter(self.p)

    fn __repr__(self) -> String:
        return "<OndemandArray: p={self.p}>"


@value
struct OndemandObject:
    var p: c_void_pointer

    @always_inline
    fn __init__(inout self, p: c_void_pointer):
        self.p = p

    @always_inline
    fn __del__(owned self):
        logd("OndemandObject.__del__")
        seq_simdjson_ondemand_object_free(self.p)

    @always_inline
    fn get_int(self, key: StringLiteral) -> Int:
        return seq_simdjson_ondemand_get_int_o(
            self.p, key.data()._as_scalar_pointer(), len(key)
        ).to_int()

    @always_inline
    fn get_uint(self, key: StringLiteral) -> Int:
        return seq_simdjson_ondemand_get_uint_o(
            self.p, key.data()._as_scalar_pointer(), len(key)
        ).to_int()

    @always_inline
    fn get_float(self, key: StringLiteral) -> Float64:
        return seq_simdjson_ondemand_get_float_o(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_bool(self, key: StringLiteral) -> Bool:
        return seq_simdjson_ondemand_get_bool_o(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_str(self, key: StringLiteral) -> String:
        var n: c_size_t = 0
        let s = seq_simdjson_ondemand_get_string_o(
            self.p,
            key.data()._as_scalar_pointer(),
            len(key),
            Pointer[c_size_t].address_of(n),
        )
        return c_str_to_string(s, n)

    @always_inline
    fn get_object(self, key: StringLiteral) -> OndemandObject:
        let p = seq_simdjson_ondemand_get_object_o(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )
        return OndemandObject(p)

    @always_inline
    fn get_array(self, key: StringLiteral) -> OndemandArray:
        let p = seq_simdjson_ondemand_get_array_o(
            self.p, key.data()._as_scalar_pointer(), len(key)
        )
        return OndemandArray(p)

    fn __repr__(self) -> String:
        return "<OndemandObject: p={self.p}>"


@value
struct OndemandArrayIter:
    var arr: c_void_pointer
    var it: c_void_pointer
    var end: c_void_pointer

    @always_inline
    fn __init__(
        inout self,
        arr: c_void_pointer,
        it: c_void_pointer,
        end: c_void_pointer,
    ):
        self.arr = arr
        self.it = it
        self.end = end

    @always_inline
    fn __init__(inout self, arr: c_void_pointer):
        self.arr = arr
        self.it = seq_simdjson_ondemand_array_begin(arr)
        self.end = seq_simdjson_ondemand_array_end(arr)

    @always_inline
    fn __del__(owned self):
        logd("OndemandArrayIter.__del__")
        seq_simdjson_ondemand_array_free(self.arr)
        seq_simdjson_ondemand_array_iter_free(self.it)
        seq_simdjson_ondemand_array_iter_free(self.end)

    @always_inline
    fn has_value(self) -> Bool:
        return seq_simdjson_ondemand_array_iter_not_equal(self.it, self.end)

    @always_inline
    fn get(self) -> OndemandValue:
        let p = seq_simdjson_ondemand_array_iter_get(self.it)
        return OndemandValue(p)

    @always_inline
    fn get_object(self) -> OndemandObject:
        let p = seq_simdjson_ondemand_array_iter_get_obj(self.it)
        return OndemandObject(p)

    @always_inline
    fn get_array(self) -> OndemandArray:
        let p = seq_simdjson_ondemand_array_iter_get_arr(self.it)
        return OndemandArray(p)

    @always_inline
    fn get_int(self) -> Int:
        return seq_simdjson_ondemand_array_iter_get_int(self.it).to_int()

    @always_inline
    fn get_uint(self) -> Int:
        return seq_simdjson_ondemand_array_iter_get_uint(self.it).to_int()

    @always_inline
    fn get_float(self) -> Float64:
        return seq_simdjson_ondemand_array_iter_get_float(self.it)

    @always_inline
    fn get_bool(self) -> Bool:
        return seq_simdjson_ondemand_array_iter_get_bool(self.it)

    @always_inline
    fn get_str(self) -> String:
        var n: c_size_t = 0
        let s = seq_simdjson_ondemand_array_iter_get_str(
            self.it, Pointer[c_size_t].address_of(n)
        )
        return c_str_to_string(s, n)

    @always_inline
    fn step(self):
        seq_simdjson_ondemand_array_iter_step(self.it)

    fn __repr__(self) -> String:
        return "<DomArrayIter: arr={self.arr} it={self.it} end={self.end}>"


@value
struct OndemandDocument:
    var padded_string: c_void_pointer
    var doc: c_void_pointer

    @always_inline
    fn __init__(
        inout self,
        padded_string: c_void_pointer,
        doc: c_void_pointer,
    ):
        self.padded_string = padded_string
        self.doc = doc

    @always_inline
    fn __del__(owned self):
        logd("OndemandDocument.__del__")
        seq_simdjson_ondemand_document_free(self.doc)
        seq_simdjson_padded_string_free(self.padded_string)

    @always_inline
    fn get_int(self, key: StringLiteral) -> Int:
        let v = seq_simdjson_ondemand_get_int_d(
            self.doc, key.data()._as_scalar_pointer(), len(key)
        )
        return v.to_int()

    @always_inline
    fn get_uint(self, key: StringLiteral) -> Int:
        return seq_simdjson_ondemand_get_uint_d(
            self.doc, key.data()._as_scalar_pointer(), len(key)
        ).to_int()

    @always_inline
    fn get_float(self, key: StringLiteral) -> Float64:
        return seq_simdjson_ondemand_get_float_d(
            self.doc, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_bool(self, key: StringLiteral) -> Bool:
        return seq_simdjson_ondemand_get_bool_d(
            self.doc, key.data()._as_scalar_pointer(), len(key)
        )

    @always_inline
    fn get_str(self, key: StringLiteral) -> String:
        var n: c_size_t = 0
        let s = seq_simdjson_ondemand_get_string_d(
            self.doc,
            key.data()._as_scalar_pointer(),
            len(key),
            Pointer[c_size_t].address_of(n),
        )
        return c_str_to_string(s, n)

    @always_inline
    fn get_object(self, key: StringLiteral) -> OndemandObject:
        let p = seq_simdjson_ondemand_get_object_d(
            self.doc, key.data()._as_scalar_pointer(), len(key)
        )
        return OndemandObject(p)

    @always_inline
    fn get_array(self, key: StringLiteral) -> OndemandArray:
        let p = seq_simdjson_ondemand_get_array_d(
            self.doc, key.data()._as_scalar_pointer(), len(key)
        )
        return OndemandArray(p)

    fn __repr__(self) -> String:
        return "<OndemandDocument: padded_string={self._padded_string} doc={self._doc}>"


@value
struct OndemandParser:
    var parser: c_void_pointer

    @always_inline
    fn __init__(inout self, max_capacity: Int):
        self.parser = seq_simdjson_ondemand_parser_new(max_capacity)

    @always_inline
    fn __del__(owned self):
        logd("OndemandParser.__del__")
        seq_simdjson_ondemand_parser_free(self.parser)

    @always_inline
    fn parse(self, s: StringLiteral) -> OndemandDocument:
        let padded_string = seq_simdjson_padded_string_new(
            s.data()._as_scalar_pointer(), len(s)
        )
        let doc = seq_simdjson_ondemand_parser_parse(self.parser, padded_string)
        return OndemandDocument(padded_string, doc)

    @always_inline
    fn parse(self, s: StringRef) -> OndemandDocument:
        let padded_string = seq_simdjson_padded_string_new(
            s.data._as_scalar_pointer(), len(s)
        )
        let doc = seq_simdjson_ondemand_parser_parse(self.parser, padded_string)
        return OndemandDocument(padded_string, doc)

    @always_inline
    fn parse(self, s: String) -> OndemandDocument:
        let padded_string = seq_simdjson_padded_string_new(s._buffer.data.value, len(s))
        let doc = seq_simdjson_ondemand_parser_parse(self.parser, padded_string)
        return OndemandDocument(padded_string, doc)

    fn __repr__(self) -> String:
        return "<OndemandParser: p={self.p}>"
