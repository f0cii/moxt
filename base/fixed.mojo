from .c import *
from .mo import *


alias FIXED_SCALE_I = 1000000000000
alias FIXED_SCALE_F = 1000000000000.0


fn fixed_12_new_string_n(cstr: c_char_pointer, cstr_len: c_size_t) -> Int64:
    return external_call["fixed_12_new_string_n", Int64, c_char_pointer, c_size_t](
        cstr, cstr_len
    )


fn fixed_12_string_res(fixed: Int64, result: c_void_pointer) -> c_size_t:
    return external_call["fixed_12_string_res", c_size_t, Int64, c_void_pointer](
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
        let v_ = fixed_12_new_string_n(v._buffer.data.value, len(v))
        return Self {
            _value: v_,
        }

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

    # 自定义+
    fn __add__(self, rhs: Self) -> Self:
        return Self {_value: self._value + rhs._value}

    # 自定义-
    fn __sub__(self, rhs: Self) -> Self:
        return Self {_value: self._value - rhs._value}

    # 自定义*
    fn __mul__(self, rhs: Self) -> Self:
        let v = seq_fixed_mul(self._value, rhs._value)
        return Self {_value: v}

    # 自定义/
    fn __truediv__(self, rhs: Self) -> Self:
        let v = seq_fixed_truediv(self._value, rhs._value)
        return Self {_value: v}

    fn __str__(self) -> String:
        let ptr = Pointer[c_char].alloc(17)
        let n = fixed_12_string_res(self._value, ptr)
        let s = c_str_to_string(ptr, n)
        ptr.free()
        return s
