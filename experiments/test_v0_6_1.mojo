from memory import memcpy, memset_zero


alias any_pointer_simd_int8_to_pointer_simd_int8 = rebind[
    Pointer[SIMD[DType.int8, 1]], AnyPointer[SIMD[DType.int8, 1]]
]


fn to_string_ref(s: String) -> StringRef:
    # var data = rebind[Pointer[SIMD[DType.int8, 1]], AnyPointer[SIMD[DType.int8, 1]]](s._buffer.data)
    # var data = any_pointer_simd_int8_to_pointer_simd_int8(s._buffer.data)
    var data_len = len(s)
    var ptr = Pointer[Int8]().alloc(data_len + 1)

    # memcpy(ptr, data.bitcast[Int8](), data_len)
    memcpy(ptr, s._buffer.data.value, data_len)
    memset_zero(ptr.offset(data_len), 1)

    return StringRef(ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, data_len)


# var a = String("hello")


@value
struct BoxedInt(Stringable):
    var value: Int

    fn __str__(self) -> String:
        return self.value


fn main():
    # print(a[0])

    print(BoxedInt(46))

    var s = String("hello")
    print(s)

    var s_ref = to_string_ref(s)
    print(s_ref)

    print(s + 100)

    var f: Float64 = 100.1
    var i = int(f)
    var i0 = int(Float32(100.1))
    var i1 = int(Int8(10))
    var i2 = int(Int16(10))
    var i3 = int(Int32(10))
    var i4 = int(Int64(10))
    var i5 = int(UInt8(10))
    var i6 = int(UInt16(10))
    var i7 = int(UInt32(10))
    var i8 = int(UInt64(10))

    var vec = List[Bool]()
    var vec0 = List[StringLiteral]()
    var vec1 = List[Int]()
    var vec2 = List[StringRef]()
    var vec3 = List[String]()
    var vec4 = List[Float32]()
    var vec5 = List[Float64]()
    var vec6 = List[Int16]()
    var vec7 = List[Int32]()
    var vec8 = List[Int8]()
    var vec9 = List[Int16]()
