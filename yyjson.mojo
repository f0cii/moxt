import time
import sys
import os

from simpletools.simplelist import SimpleList
from c import *
from mo import *
from yyjsonbase import *


alias List = SimpleList


@value
struct yyjson_mut_doc:
    var doc: c_void_pointer
    var root: c_void_pointer

    @always_inline
    fn __init__(inout self):
        self.doc = seq_yyjson_mut_doc_new(Pointer[UInt8]())
        self.root = seq_yyjson_mut_obj(self.doc)
        seq_yyjson_mut_doc_set_root(self.doc, self.root)

    @always_inline
    fn __del__(owned self):
        seq_yyjson_mut_doc_free(self.doc)

    @always_inline
    fn add_str(self, key: StringLiteral, value: String):
        let c_str = to_schar_ptr(value)
        _ = seq_yyjson_mut_obj_add_strn(
            self.doc,
            self.root,
            key.data()._as_scalar_pointer(),
            c_str,
            len(value),
        )

    @always_inline
    fn add_int(self, key: StringLiteral, value: Int):
        _ = seq_yyjson_mut_obj_add_int(
            self.doc, self.root, key.data()._as_scalar_pointer(), value
        )

    @always_inline
    fn add_float(self, key: StringLiteral, value: Float64):
        _ = seq_yyjson_mut_obj_add_real(
            self.doc, self.root, key.data()._as_scalar_pointer(), value
        )

    @always_inline
    fn add_bool(self, key: StringLiteral, value: Bool):
        _ = seq_yyjson_mut_obj_add_bool(
            self.doc, self.root, key.data()._as_scalar_pointer(), value
        )

    # @always_inline
    # fn arr_with_bool(self, key: StringLiteral, value: List[Bool]) raises:
    #     let n = value.size()
    #     var vp = Pointer[Bool].alloc(n)
    #     for i in range(0, n):
    #         vp[i] = value[i]
    #     # print(vp)
    #     let harr = seq_yyjson_mut_arr_with_bool(self.doc, vp, n)
    #     _ = seq_yyjson_mut_obj_add_val(self.doc, self.root, key.data()._as_scalar_pointer(), harr)

    # @always_inline
    # fn arr_with_float(self, key: StringLiteral, value: List[Float64]) raises:
    #     let n = value.size()
    #     var vp = Pointer[Float64].alloc(n)
    #     for i in range(0, n):
    #         vp[i] = value[i]
    #     # print(vp)
    #     let harr = seq_yyjson_mut_arr_with_real(self.doc, vp, n)
    #     _ = seq_yyjson_mut_obj_add_val(self.doc, self.root, key.data()._as_scalar_pointer(), harr)

    # @always_inline
    # fn arr_with_int(self, key: StringLiteral, value: List[Int]) raises:
    #     let n = value.size()
    #     var vp = Pointer[Int].alloc(n)
    #     for i in range(0, n):
    #         vp[i] = value[i]
    #     # print(vp)
    #     let harr = seq_yyjson_mut_arr_with_sint64(self.doc, vp, n)
    #     _ = seq_yyjson_mut_obj_add_val(self.doc, self.root, key.data()._as_scalar_pointer(), harr)

    # @always_inline
    # fn arr_with_str(self, key: StringLiteral, value: List[StringRef]) raises:
    #     let n = value.size()
    #     var vp = Pointer[c_void_pointer].alloc(n)
    #     for i in range(0, n):
    #         vp[i] = value[i]
    #     # print(vp)
    #     let harr = seq_yyjson_mut_arr_with_str(self.doc, vp, n)
    #     _ = seq_yyjson_mut_obj_add_val(self.doc, self.root, key.data()._as_scalar_pointer(), harr)

    @always_inline
    fn mut_write(self) -> String:
        var pLen: Int = 0
        let json_cstr = seq_yyjson_mut_write(
            self.doc, YYJSON_WRITE_NOFLAG, Pointer[Int].address_of(pLen)
        )
        # logi("pLen: " + str(pLen))
        return c_str_to_string(json_cstr.bitcast[UInt8](), pLen)

    fn __repr__(self) -> String:
        return "<yyjson_mut_doc: doc={self.doc}, root={self.root}>"


@value
@register_passable
struct yyjson_val(CollectionElement):
    var p: c_void_pointer

    fn __init__(inout self, p: c_void_pointer) -> Self:
        self.p = p
        return self

    @always_inline
    fn __getitem__(self, key: StringLiteral) -> yyjson_val:
        return yyjson_val(
            seq_yyjson_obj_getn(self.p, key.data()._as_scalar_pointer(), len(key))
        )

    fn __bool__(self) -> Bool:
        return self.p == c_void_pointer.get_null()

    @always_inline
    fn type(self) -> Int:
        return seq_yyjson_get_type(self.p)

    @always_inline
    fn type_desc(self) -> String:
        return c_str_to_string(seq_yyjson_get_type_desc(self.p))

    @always_inline
    fn str(self) -> String:
        let s = seq_yyjson_get_str(self.p)
        return c_str_to_string(s)

    @always_inline
    fn safe_str(self) -> String:
        if not self:
            return ""
        return c_str_to_string(seq_yyjson_get_str(self.p))

    @always_inline
    fn uint(self) -> Int:
        return seq_yyjson_get_uint(self.p)

    @always_inline
    fn int(self) -> Int:
        return seq_yyjson_get_int(self.p)

    @always_inline
    fn float(self) -> Float64:
        return seq_yyjson_get_real(self.p)

    @always_inline
    fn bool(self) -> Bool:
        return seq_yyjson_get_bool(self.p)

    @always_inline
    fn raw(self) -> String:
        return c_str_to_string(seq_yyjson_get_raw(self.p))

    @always_inline
    fn object(self, key: StringLiteral) -> yyjson_val:
        return yyjson_val(
            seq_yyjson_obj_getn(self.p, key.data()._as_scalar_pointer(), len(key))
        )

    @always_inline
    fn arr_size(self) -> Int:
        return seq_yyjson_arr_size(self.p)

    @always_inline
    fn array_list(self) -> List[yyjson_val]:
        var res = List[yyjson_val]()
        var idx: Int = 0
        let max: Int = seq_yyjson_arr_size(self.p)
        var val = seq_yyjson_arr_get_first(self.p)
        while idx < max:
            res.append(yyjson_val(val))
            idx += 1
            val = seq_unsafe_yyjson_get_next(val)
        return res

    # @always_inline
    # fn obj_list(self) -> List[Tuple[yyjson_val,yyjson_val]]:
    #     res = List[Tuple[yyjson_val,yyjson_val]]()
    #     iter = seq_yyjson_obj_iter_ptr_new(self.p)
    #     key = Ptr[yyjson_val]()
    #     val = Ptr[yyjson_val]()
    #     while True:
    #         key = seq_yyjson_obj_iter_next(iter)
    #         if not key:
    #             break
    #         val = seq_yyjson_obj_iter_get_val(key)
    #         #item: Tuple[yyjson_val,yyjson_val] = (yyjson_val.from_ptr(_key), yyjson_val.from_ptr(_val))
    #         res.append((yyjson_val.from_ptr(key), yyjson_val.from_ptr(val)))
    #     seq_yyjson_obj_iter_ptr_free(iter)
    #     return res

    fn __repr__(self) -> String:
        return "<yyjson_val: p={self.p}>"


@value
struct yyjson_doc:
    var doc: c_void_pointer

    fn __init__(inout self, s: String, read_insitu: Bool = False):
        let flg = YYJSON_READ_INSITU if read_insitu else 0
        self.doc = seq_yyjson_read(to_char_ptr(s), len(s), flg)

    # @always_inline
    # fn __del__(self):
    #     seq_yyjson_doc_free(self.doc)

    @always_inline
    fn release(owned self):
        seq_yyjson_doc_free(self.doc)

    @always_inline
    fn root(self) -> yyjson_val:
        return yyjson_val(seq_yyjson_doc_get_root(self.doc))

    @always_inline
    fn get_read_size(self) -> Int:
        return seq_yyjson_doc_get_read_size(self.doc)

    @always_inline
    fn get_val_count(self) -> Int:
        return seq_yyjson_doc_get_val_count(self.doc)

    fn __repr__(self) -> String:
        return "<yyjson_doc: p={self.p}>"
