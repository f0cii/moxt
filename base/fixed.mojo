from .c import *
from .mo import *


alias FIXED_SCALE_I = 1000000000000
alias FIXED_SCALE_F = 1000000000000.0


fn seq_fixed12_new_string(cstr: c_char_pointer, cstr_len: c_size_t) -> Int64:
    return external_call["seq_fixed12_new_string", Int64, c_char_pointer, c_size_t](
        cstr, cstr_len
    )


fn seq_fixed12_to_string(fixed: Int64, result: c_void_pointer) -> c_size_t:
    return external_call["seq_fixed12_to_string", c_size_t, Int64, c_void_pointer](
        fixed, result
    )


# 自定义*
fn seq_fixed_mul(a: Int64, b: Int64) -> Int64:
    return external_call["seq_fixed_mul", Int64, Int64, Int64](a, b)


# 自定义/
fn seq_fixed_truediv(a: Int64, b: Int64) -> Int64:
    return external_call["seq_fixed_truediv", Int64, Int64, Int64](a, b)


fn seq_fixed_round_to_fractional(a: Int64, scale: Int64) -> Int64:
    return external_call["seq_fixed_round_to_fractional", Int64, Int64, Int64](a, scale)


fn seq_fixed_round(a: Int64, decimalPlaces: Int) -> Int64:
    return external_call["seq_fixed_round", Int64, Int64, Int](a, decimalPlaces)


@value
@register_passable
struct Fixed(Stringable):
    alias zero = Fixed(0)
    alias one = Fixed(1)
    alias two = Fixed(2)
    alias three = Fixed(3)
    alias four = Fixed(4)
    alias five = Fixed(5)
    alias six = Fixed(6)
    alias seven = Fixed(7)
    alias eight = Fixed(8)
    alias nine = Fixed(9)
    alias ten = Fixed(10)

    var _value: Int64

    fn __init__() -> Self:
        return Self {
            _value: 0,
        }

    fn __init__(v: Int) -> Self:
        return Self {
            _value: FIXED_SCALE_I * v,
        }

    fn __init__(v: FloatLiteral) -> Self:
        return Self {_value: int(FIXED_SCALE_F * v)}

    fn __init__(v: Float64) -> Self:
        return Self {_value: int(FIXED_SCALE_F * v)}

    fn __init__(v: String) -> Self:
        let v_ = seq_fixed12_new_string(v._buffer.data.value, len(v))
        return Self {
            _value: v_,
        }

    fn copy_from(inout self, other: Self):
        self._value = other._value

    @staticmethod
    fn from_value(value: Int64) -> Self:
        return Self {
            _value: value,
        }

    fn is_zero(self) -> Bool:
        return self._value == 0

    fn value(self) -> Int64:
        return self._value

    fn to_int(self) -> Int:
        return int(self._value / FIXED_SCALE_I)

    fn to_float(self) -> Float64:
        return self._value.cast[DType.float64]() / FIXED_SCALE_F

    fn to_string(self) -> String:
        let ptr = Pointer[c_char].alloc(17)
        let n = seq_fixed12_to_string(self._value, ptr)
        let s = c_str_to_string(ptr, n)
        ptr.free()
        return s

    fn round_to_fractional(self, scale: Int) -> Self:
        let v = seq_fixed_round_to_fractional(self._value, scale)
        return Self {
            _value: v,
        }

    fn round(self, decimal_places: Int) -> Self:
        let v = seq_fixed_round(self._value, decimal_places)
        return Self {
            _value: v,
        }

    fn __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    fn __ne__(self, other: Self) -> Bool:
        return self._value != other._value

    fn __lt__(self, other: Self) -> Bool:
        return self._value < other._value

    fn __le__(self, other: Self) -> Bool:
        return self._value <= other._value

    fn __gt__(self, other: Self) -> Bool:
        return self._value > other._value

    fn __ge__(self, other: Self) -> Bool:
        return self._value >= other._value

    # 自定义+
    fn __add__(self, other: Self) -> Self:
        return Self {_value: self._value + other._value}

    # 自定义+=
    fn __iadd__(inout self, other: Self):
        self._value += other._value

    # 自定义-
    fn __sub__(self, other: Self) -> Self:
        return Self {_value: self._value - other._value}

    # 自定义-=
    fn __isub__(inout self, other: Self):
        self._value -= other._value

    # 自定义*
    fn __mul__(self, other: Self) -> Self:
        let v = seq_fixed_mul(self._value, other._value)
        return Self {_value: v}

    # 自定义*=
    fn __imul__(inout self, other: Self):
        self._value = seq_fixed_mul(self._value, other._value)

    # 自定义/
    fn __truediv__(self, other: Self) -> Self:
        let v = seq_fixed_truediv(self._value, other._value)
        return Self {_value: v}

    # 自定义/=
    fn __itruediv__(inout self, other: Self):
        self._value = seq_fixed_truediv(self._value, other._value)

    fn __str__(self) -> String:
        return self.to_string()
