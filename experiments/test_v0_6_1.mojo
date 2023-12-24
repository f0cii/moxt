from memory import memcpy, memset_zero


alias any_pointer_simd_int8_to_pointer_simd_int8 = rebind[
    Pointer[SIMD[DType.int8, 1]], AnyPointer[SIMD[DType.int8, 1]]
]


fn to_string_ref(s: String) -> StringRef:
    # let data = rebind[Pointer[SIMD[DType.int8, 1]], AnyPointer[SIMD[DType.int8, 1]]](s._buffer.data)
    # let data = any_pointer_simd_int8_to_pointer_simd_int8(s._buffer.data)
    let data_len = len(s)
    let ptr = Pointer[Int8]().alloc(data_len + 1)

    # memcpy(ptr, data.bitcast[Int8](), data_len)
    memcpy(ptr, s._buffer.data.value, data_len)
    memset_zero(ptr.offset(data_len), 1)

    return StringRef(ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, data_len)


# let a = String("hello")


@value
struct BoxedInt(Stringable):
    var value: Int

    fn __str__(self) -> String:
        return self.value


fn main():
    # print(a[0])

    print(BoxedInt(46))

    let s = String("hello")
    print(s)

    let s_ref = to_string_ref(s)
    print(s_ref)

    print(s + 100)

    let f: Float64 = 100.1
    let i = int(f)
    let i0 = int(Float32(100.1))
    let i1 = int(Int8(10))
    let i2 = int(Int16(10))
    let i3 = int(Int32(10))
    let i4 = int(Int64(10))
    let i5 = int(UInt8(10))
    let i6 = int(UInt16(10))
    let i7 = int(UInt32(10))
    let i8 = int(UInt64(10))

    let vec = DynamicVector[Bool]()
    let vec0 = DynamicVector[StringLiteral]()
    let vec1 = DynamicVector[Int]()
    let vec2 = DynamicVector[StringRef]()
    let vec3 = DynamicVector[String]()
    let vec4 = DynamicVector[Float32]()
    let vec5 = DynamicVector[Float64]()
    let vec6 = DynamicVector[Int16]()
    let vec7 = DynamicVector[Int32]()
    let vec8 = DynamicVector[Int8]()
    let vec9 = DynamicVector[Int16]()
