from math.limit import max_finite, min_finite
from math.bit import bswap
from memory.unsafe import bitcast
from sys.info import is_big_endian

alias is_be = is_big_endian()

@value
@register_passable("trivial")
struct ValueBitWidth:
    alias width8 = ValueBitWidth(0)
    alias width16 = ValueBitWidth(1)
    alias width32 = ValueBitWidth(2)
    alias width64 = ValueBitWidth(3)

    alias min8 = min_finite[DType.int8]().to_int()
    alias max8 = max_finite[DType.int8]().to_int()
    alias umax8 = max_finite[DType.uint8]().cast[DType.uint64]()
    alias min16 = min_finite[DType.int16]().to_int()
    alias max16 = max_finite[DType.int16]().to_int()
    alias umax16 = max_finite[DType.uint16]().cast[DType.uint64]()
    alias min32 = min_finite[DType.int32]().to_int()
    alias max32 = max_finite[DType.int32]().to_int()
    alias umax32 = max_finite[DType.uint32]().cast[DType.uint64]()

    var value: UInt8

    @always_inline
    fn __lt__(self, other: ValueBitWidth) -> Bool:
        return self.value < other.value

    @always_inline
    fn __le__(self, other: ValueBitWidth) -> Bool:
        return self.value <= other.value

    @always_inline
    fn __eq__(self, other: ValueBitWidth) -> Bool:
        return self.value == other.value

    @always_inline
    @staticmethod
    fn of[D: DType](n: SIMD[D, 1]) -> ValueBitWidth:
        @parameter
        if D == DType.uint8 or D == DType.int8 or D == DType.bool:
            return ValueBitWidth.width8
        elif D == DType.uint16 or D == DType.int16 or D == DType.float16:
            return ValueBitWidth.width16
        elif D == DType.uint32 or D == DType.int32 or D == DType.float32:
            return ValueBitWidth.width32
        else:
            return ValueBitWidth.width64

    @always_inline
    @staticmethod
    fn of(n: Int) -> ValueBitWidth:
        if Self.min16 <= n <= Self.max16:
            if Self.min8 <= n <= Self.max8:
                return ValueBitWidth.width8
            else:
                return ValueBitWidth.width16
        else:
            if Self.min32 <= n <= Self.max32:
                return ValueBitWidth.width32
            else:
                return ValueBitWidth.width64
    
    @always_inline
    @staticmethod
    fn of(n: UInt64) -> ValueBitWidth:
        if n <= Self.umax16:
            if n <= Self.umax8:
                return ValueBitWidth.width8
            else:
                return ValueBitWidth.width16
        else:
            if n <= Self.umax32:
                return ValueBitWidth.width32
            else:
                return ValueBitWidth.width64

@always_inline
fn padding_size(buffer_size: UInt64, scalar_size: UInt64) -> UInt64:
    return (~buffer_size + 1) & (scalar_size - 1)

@value
@register_passable("trivial")
struct ValueType:
    alias Null = ValueType(0)
    alias Int = ValueType(1)
    alias UInt = ValueType(2)
    alias Float = ValueType(3)
    alias Key = ValueType(4)
    alias String = ValueType(5)
    alias IndirectInt = ValueType(6)
    alias IndirectUInt = ValueType(7)
    alias IndirectFloat = ValueType(8)
    alias Map = ValueType(9)
    alias Vector = ValueType(10)
    alias VectorInt = ValueType(11)
    alias VectorUInt = ValueType(12)
    alias VectorFloat = ValueType(13)
    alias VectorKey = ValueType(14)
    alias VectorString = ValueType(15)
    alias VectorInt2 = ValueType(16)
    alias VectorUInt2 = ValueType(17)
    alias VectorFloat2 = ValueType(18)
    alias VectorInt3 = ValueType(19)
    alias VectorUInt3 = ValueType(20)
    alias VectorFloat3 = ValueType(21)
    alias VectorInt4 = ValueType(22)
    alias VectorUInt4 = ValueType(23)
    alias VectorFloat4 = ValueType(24)
    alias Blob = ValueType(25)
    alias Bool = ValueType(26)
    alias VectorBool = ValueType(36)

    alias NullPackedType = 0

    var value: UInt8

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    
    @always_inline
    fn __lt__(self, other: Self) -> Bool:
        return self.value < other.value

    @always_inline
    fn __le__(self, other: Self) -> Bool:
        return self.value <= other.value

    @always_inline
    fn __sub__(self, other: Self) -> Self:
        return Self(self.value - other.value)

    @always_inline
    fn __add__(self, other: Self) -> Self:
        return Self(self.value + other.value)

    @always_inline
    fn __add__(self, other: UInt8) -> Self:
        return Self(self.value + other.value)

    @always_inline
    fn __mod__(self, other: UInt8) -> Self:
        return Self(self.value % other)

    @always_inline
    fn __floordiv__(self, other: UInt8) -> Self:
        return Self(self.value // other)

    @always_inline
    fn __lshift__(self, other: UInt8) -> Self:
        return Self(self.value << other)

    @always_inline
    fn is_inline(self) -> Bool:
        return self == ValueType.Bool or self <= ValueType.Float
    
    @always_inline
    fn is_typed_vector_element(self) -> Bool:
        return self == ValueType.Bool or ValueType.Int <= self <= ValueType.String

    @always_inline
    fn is_typed_vector(self) -> Bool:
        return self == ValueType.VectorBool or ValueType.VectorInt <= self <= ValueType.VectorString
    
    @always_inline
    fn is_fixed_typed_vector(self) -> Bool:
        return ValueType.VectorInt2 <= self <= ValueType.VectorFloat4

    @always_inline
    fn is_a_vector(self) -> Bool:
        return self == ValueType.VectorBool or ValueType.Vector <= self <= ValueType.VectorFloat4

    @always_inline
    fn to_typed_vector(self, length: UInt8) raises -> ValueType:
        if length == 0:
            return self - ValueType.Int + ValueType.VectorInt
        if length == 2:
            return self - ValueType.Int + ValueType.VectorInt2
        if length == 3:
            return self - ValueType.Int + ValueType.VectorInt3
        if length == 4:
            return self - ValueType.Int + ValueType.VectorInt4
        raise "Unexpected length " + String(length)

    @always_inline
    fn typed_vector_element_type(self) -> ValueType:
        return self - ValueType.VectorInt + ValueType.Int

    @always_inline
    fn fixed_typed_vector_element_type(self) -> ValueType:
        return ((self - ValueType.VectorInt2) % 3) + ValueType.Int

    @always_inline
    fn fixed_typed_vector_element_size(self) -> Int:
        return ((self - ValueType.VectorInt2) // 3).value.to_int() + 2

    @always_inline
    fn packed_type(self, bit_width: ValueBitWidth) -> UInt8:
        return (self << 2).value | bit_width.value

    @staticmethod
    @always_inline
    fn of[D: DType]() -> Self:
        @parameter
        if D == DType.uint8 or D == DType.uint16 or D == DType.uint32 or D == DType.uint64:
            return ValueType.UInt
        elif D == DType.float16 or D == DType.float32 or D == DType.float64:
            return ValueType.Float
        elif D == DType.bool:
            return ValueType.Bool
        else:
            return ValueType.Int
        

@value
@register_passable("trivial")
struct StackValue(CollectionElement):
    var value: SIMD[DType.uint8, 8]
    var width: ValueBitWidth
    var type: ValueType

    alias Null = StackValue(0, ValueBitWidth.width8, ValueType.Null)

    @staticmethod
    @always_inline
    fn of[D: DType](v: SIMD[D, 1]) -> Self:
        # TODO: make it better
        var value = SIMD[DType.uint8, 8](0)
        @parameter
        if D == DType.bool:
            value[0] = v.cast[DType.uint8]()
            return StackValue(value, ValueBitWidth.of(v), ValueType.of[D]())
        elif D == DType.uint8 or D == DType.int8:
            let v1 = bitcast[DType.uint8, 1](v)
            value[0] = v1[0]
            return StackValue(value, ValueBitWidth.of(v), ValueType.of[D]())
        elif D == DType.uint16 or D == DType.int16 or D == DType.float16:
            var v1 = bitcast[DType.uint8, 2](v)
            @parameter
            if is_be:
                v1 = bswap(v1)
            value[0] = v1[0]
            value[1] = v1[1]
            return StackValue(value, ValueBitWidth.of(v), ValueType.of[D]())
        elif D == DType.uint32 or D == DType.int32 or D == DType.float32:
            var v1 = bitcast[DType.uint8, 4](v)
            @parameter
            if is_be:
                v1 = bswap(v1)
            value[0] = v1[0]
            value[1] = v1[1]
            value[2] = v1[2]
            value[3] = v1[3]
            return StackValue(value, ValueBitWidth.of(v), ValueType.of[D]())
        else:
            var v1 = bitcast[DType.uint8, 8](v)
            @parameter
            if is_be:
                v1 = bswap(v1)
            return StackValue(bitcast[DType.uint8, 8](v), ValueBitWidth.of(v), ValueType.of[D]())

    @staticmethod
    @always_inline
    fn of(v: Int) -> Self:
        let value = bitcast[DType.uint8, 8](Int64(v))
        return StackValue(value, ValueBitWidth.of(v), ValueType.Int)

    @always_inline
    fn stored_width(self, bit_width: ValueBitWidth = ValueBitWidth.width8) -> ValueBitWidth:
        if self.type.is_inline():
            return bit_width if self.width < bit_width else self.width
        return self.width

    @always_inline
    fn stored_packed_type(self, bit_width: ValueBitWidth = ValueBitWidth.width8) -> UInt8:
        return self.type.packed_type(self.stored_width(bit_width))

    @always_inline
    fn element_width(self, size: UInt64, index: Int) raises -> ValueBitWidth:
        if self.type.is_inline():
            return self.width
        for i in range(4):
            let width = UInt64(1 << i)
            let offset_loc = size + padding_size(size, width) + UInt64(index * width)
            let offset = offset_loc - self.as_uint()
            let bit_width = ValueBitWidth.of(offset.to_int())
            if (1 << bit_width.value).cast[DType.uint64]() == width:
                return bit_width

        raise "Element with size " + String(size) + " and index " + String(index) + " is of unknown width"

    @always_inline
    fn as_float(self) -> Float64:
        return bitcast[DType.float64, 1](self.value)

    @always_inline
    fn as_int(self) -> Int64:
        return bitcast[DType.int64, 1](self.value)

    @always_inline
    fn as_uint(self) -> UInt64:
        return bitcast[DType.uint64, 1](self.value)

    fn to_value(self, byte_width: UInt64) -> SIMD[DType.uint8, 8]:
        let self_byte_width = (1 << self.width.value).cast[DType.uint64]()
        if self_byte_width == byte_width or self.type == ValueType.UInt:
            return self.value
        else:
            if self_byte_width > 2:
                if self_byte_width == 4:
                    var v = SIMD[DType.uint8, 4](0)
                    v[0] = self.value[0]
                    v[1] = self.value[1]
                    v[2] = self.value[2]
                    v[3] = self.value[3]
                    if byte_width == 2:
                        if self.type == ValueType.Float:
                            return StackValue.of(bitcast[DType.float32, 1](v).cast[DType.float16]()).value
                        else:
                            return StackValue.of(bitcast[DType.int32, 1](v).cast[DType.int16]()).value
                    else:
                        # byte_width == 8
                        if self.type == ValueType.Float:
                            return StackValue.of(bitcast[DType.float32, 1](v).cast[DType.float64]()).value
                        else:
                            return StackValue.of(bitcast[DType.int32, 1](v).cast[DType.int64]()).value
                else:
                    # self_byte_width == 8
                    if byte_width == 2:
                        if self.type == ValueType.Float:
                            return StackValue.of(bitcast[DType.float64, 1](self.value).cast[DType.float16]()).value
                        else:
                            return StackValue.of(bitcast[DType.int64, 1](self.value).cast[DType.int16]()).value
                    else:
                        if self.type == ValueType.Float:
                            return StackValue.of(bitcast[DType.float64, 1](self.value).cast[DType.float32]()).value
                        else:
                            return StackValue.of(bitcast[DType.int64, 1](self.value).cast[DType.int32]()).value
            else:
                if self_byte_width == 2:
                    var v = SIMD[DType.uint8, 2](0)
                    v[0] = self.value[0]
                    v[1] = self.value[1]
                    if byte_width == 4:
                        if self.type == ValueType.Float:
                            return StackValue.of(bitcast[DType.float16, 1](v).cast[DType.float32]()).value
                        else:
                            return StackValue.of(bitcast[DType.int16, 1](v).cast[DType.int32]()).value
                    else:
                        if self.type == ValueType.Float:
                            return StackValue.of(bitcast[DType.float16, 1](v).cast[DType.float64]()).value
                        else:
                            return StackValue.of(bitcast[DType.int16, 1](v).cast[DType.int64]()).value
                else:
                    if byte_width > 2:
                        if byte_width == 4:
                            return StackValue.of(bitcast[DType.int8, 1](self.value[0]).cast[DType.int32]()).value
                        else:
                            return StackValue.of(bitcast[DType.int8, 1](self.value[0]).cast[DType.int64]()).value
                    else:
                        if byte_width == 2:
                            return StackValue.of(bitcast[DType.int8, 1](self.value[0]).cast[DType.int16]()).value
                        else:
                            return self.value

    @always_inline
    fn is_float32(self) -> Bool:
        return self.type == ValueType.Float and self.width == ValueBitWidth.width32

    @always_inline
    fn is_offset(self) -> Bool:
        return not self.type.is_inline()

    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value 
            or self.width.value != other.width.value
            or self.type != other.type 
