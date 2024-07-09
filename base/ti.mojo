from utils.static_tuple import StaticTuple
from .c import *


alias TI_TYPE_OVERLAY = 1  # These have roughly the same range as the input data.
alias TI_TYPE_INDICATOR = 2  # Everything else (e.g. oscillators).
alias TI_TYPE_MATH = 3  # These aren't so good for plotting, but are useful with formulas.
alias TI_TYPE_SIMPLE = 4  # These apply a simple operator (e.g. addition, sin, sqrt).
alias TI_TYPE_COMPARATIVE = 5  # These are designed to take inputs from different securities. i.e. compare stock A to stock B.


alias Series = List[Float64]
alias Options = VariadicList[Float64]


@value
@register_passable
struct ti_stream:
    pass


alias ti_indicator_start_function = fn (
    options: Pointer[Float64]
) raises -> c_int
alias ti_indicator_function = fn (
    size: c_int,
    inputs: Pointer[Pointer[Float64]],
    options: Pointer[Float64],
    outputs: Pointer[Pointer[Float64]],
) raises -> c_int
alias ti_indicator_stream_new = fn (
    options: Pointer[Float64], stream: Pointer[UnsafePointer[ti_stream]]
) raises -> c_int
alias ti_indicator_stream_run = fn (
    stream: UnsafePointer[ti_stream],
    size: c_int,
    inputs: Pointer[Pointer[Float64]],
    outputs: Pointer[Pointer[Float64]],
) raises -> c_int
alias ti_indicator_stream_free = fn (stream: UnsafePointer[ti_stream]) -> None


struct ti_indicator_info(Movable):
    var _name: c_char_pointer
    var _full_name: c_char_pointer
    var _start: ti_indicator_start_function
    var _indicator: ti_indicator_function
    var _indicator_ref: ti_indicator_function
    var _type: c_int
    var _inputs: c_int
    var _options: c_int
    var _outputs: c_int
    var _input_names: StaticTuple[c_char_pointer, 16]
    var _option_names: StaticTuple[c_char_pointer, 16]
    var _output_names: StaticTuple[c_char_pointer, 16]
    var _stream_new: ti_indicator_stream_new
    var _stream_run: ti_indicator_stream_run
    var _stream_free: ti_indicator_stream_free

    fn __moveinit__(inout self, owned existing: Self):
        self._name = existing._name
        self._full_name = existing._full_name
        self._start = existing._start
        self._indicator = existing._indicator
        self._indicator_ref = existing._indicator_ref
        self._type = existing._type
        self._inputs = existing._inputs
        self._options = existing._options
        self._outputs = existing._outputs
        self._input_names = existing._input_names
        self._option_names = existing._option_names
        self._output_names = existing._output_names
        self._stream_new = existing._stream_new
        self._stream_run = existing._stream_run
        self._stream_free = existing._stream_free

    fn name(self) -> String:
        return c_str_to_string(self._name, strlen(self._name))

    fn full_name(self) -> String:
        return c_str_to_string(self._full_name, strlen(self._full_name))

    fn indicator_type(self) -> Int:
        return int(self._type)

    fn input_names(self) -> List[String]:
        var result = List[String]()
        for i in range(self._inputs):
            var s = self._input_names[i]
            result.append(c_str_to_string(s, strlen(s)))
        return result

    fn option_names(self) -> List[String]:
        var result = List[String]()
        for i in range(self._options):
            var s = self._option_names[i]
            result.append(c_str_to_string(s, strlen(s)))
        return result

    fn output_names(self) -> List[String]:
        var result = List[String]()
        for i in range(self._outputs):
            var s = self._output_names[i]
            result.append(c_str_to_string(s, strlen(s)))
        return result


fn seq_ti_get_first_indicator() -> UnsafePointer[ti_indicator_info]:
    return external_call[
        "seq_ti_get_first_indicator", UnsafePointer[ti_indicator_info]
    ]()


fn seq_ti_is_valid_indicator(info: UnsafePointer[ti_indicator_info]) -> Bool:
    return external_call[
        "seq_ti_is_valid_indicator", Bool, UnsafePointer[ti_indicator_info]
    ](info)


fn seq_ti_get_next_indicator(
    info: UnsafePointer[ti_indicator_info],
) -> UnsafePointer[ti_indicator_info]:
    return external_call[
        "seq_ti_get_next_indicator",
        UnsafePointer[ti_indicator_info],
        UnsafePointer[ti_indicator_info],
    ](info)


fn seq_ti_find_indicator(
    name: c_char_pointer,
) -> UnsafePointer[ti_indicator_info]:
    return external_call[
        "seq_ti_find_indicator",
        UnsafePointer[ti_indicator_info],
        c_char_pointer,
    ](name)


fn seq_ti_indicator_at_index(index: c_int) -> UnsafePointer[ti_indicator_info]:
    return external_call[
        "seq_ti_indicator_at_index", UnsafePointer[ti_indicator_info], c_int
    ](index)


fn seq_ti_indicator_start(
    info: UnsafePointer[ti_indicator_info],
    options: Pointer[Float64],
) -> c_int:
    return external_call[
        "seq_ti_indicator_start",
        c_int,
        UnsafePointer[ti_indicator_info],
        Pointer[Float64],
    ](info, options)


fn seq_ti_indicator_start(
    info: UnsafePointer[ti_indicator_info],
    options: UnsafePointer[Float64],
) -> c_int:
    return external_call[
        "seq_ti_indicator_start",
        c_int,
        UnsafePointer[ti_indicator_info],
        UnsafePointer[Float64],
    ](info, options)


fn seq_ti_indicator_run(
    info: UnsafePointer[ti_indicator_info],
    input_size: c_int,
    inputs: Pointer[Pointer[Float64]],
    options: Pointer[Float64],
    outputs: Pointer[Pointer[Float64]],
) -> Bool:
    return external_call[
        "seq_ti_indicator_run",
        Bool,
        UnsafePointer[ti_indicator_info],
        c_int,
        Pointer[Pointer[Float64]],
        Pointer[Float64],
        Pointer[Pointer[Float64]],
    ](info, input_size, inputs, options, outputs)


fn seq_ti_indicator_run(
    info: UnsafePointer[ti_indicator_info],
    input_size: c_int,
    inputs: Pointer[UnsafePointer[Float64]],
    options: UnsafePointer[Float64],
    outputs: Pointer[UnsafePointer[Float64]],
) -> Bool:
    return external_call[
        "seq_ti_indicator_run",
        Bool,
        UnsafePointer[ti_indicator_info],
        c_int,
        Pointer[UnsafePointer[Float64]],
        UnsafePointer[Float64],
        Pointer[UnsafePointer[Float64]],
    ](info, input_size, inputs, options, outputs)


struct Inputs:
    var data: Pointer[UnsafePointer[Float64]]
    var data_index: Int

    fn __init__(inout self, capacity: Int = 16):
        self.data = Pointer[UnsafePointer[Float64]].alloc(capacity)
        self.data_index = 0

    fn __del__(owned self):
        self.data.free()

    fn add(inout self, data_in: Series):
        self.data[self.data_index] = data_in.data
        self.data_index += 1


struct Outputs:
    var data: Pointer[UnsafePointer[Float64]]
    var data_list: List[Series]
    var outputs: Int

    fn __init__(inout self, outputs: Int = 4):
        self.data = Pointer[UnsafePointer[Float64]].alloc(outputs)
        self.data_list = List[Series](capacity=outputs)
        self.outputs = outputs

    fn __del__(owned self):
        self.data.free()

    fn __getitem__(self, index: Int) -> Series:
        return self.data_list[index]

    fn resize(inout self, size: Int, value: Float64):
        for i in range(self.outputs):
            var v = Series()
            v.resize(size, 0.0)
            self.data_list.append(v^)
            self.data[i] = (self.data_list.data + i)[].data


@always_inline
fn ti_indicator(
    indicator_index: Int,
    input_length: Int,
    inputs: Inputs,
    inout outputs: Outputs,
    options: VariadicList[Float64],
) raises:
    var info = seq_ti_indicator_at_index(indicator_index)
    var options_ = List[Float64](capacity=len(options))
    options_.append(3)
    for i in options:
        options_.append(i)

    var start = seq_ti_indicator_start(info, options_.data)
    var output_length = input_length - int(start)

    outputs.resize(output_length, 0.0)
    var ok = seq_ti_indicator_run(
        info, input_length, inputs.data, options_.data, outputs.data
    )
    if not ok:
        raise Error("error")

    _ = options_^


fn ti_indicator(
    indicator_index: Int,
    size: Int,
    inputs: Inputs,
    inout outputs: Outputs,
    *options: Float64,
) raises:
    ti_indicator(indicator_index, size, inputs, outputs, options)


# /* Vector Absolute Value */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: abs */
alias TI_INDICATOR_ABS_INDEX = 0


fn ti_abs(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(TI_INDICATOR_ABS_INDEX, size, inputs, outputs, Options())


# /* Vector Arccosine */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: acos */
alias TI_INDICATOR_ACOS_INDEX = 1


fn ti_acos(size: Int, real: Series, inout outputs: Outputs) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(TI_INDICATOR_ACOS_INDEX, size, inputs, outputs, Options())


# /* Accumulation/Distribution Line */
# /* Type: indicator */
# /* Input arrays: 4    Options: 0    Output arrays: 1 */
# /* Inputs: high, low, close, volume */
# /* Options: none */
# /* Outputs: ad */
alias TI_INDICATOR_AD_INDEX = 2


fn ti_ad(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    volume: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(4)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    inputs.add(volume)
    ti_indicator(TI_INDICATOR_AD_INDEX, size, inputs, outputs, Options())


# /* Vector Addition */
# /* Type: simple */
# /* Input arrays: 2    Options: 0    Output arrays: 1 */
# /* Inputs: real, real */
# /* Options: none */
# /* Outputs: add */
alias TI_INDICATOR_ADD_INDEX = 3


fn ti_add(
    size: Int,
    real0: Series,
    real1: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(2)
    inputs.add(real0)
    inputs.add(real1)
    ti_indicator(TI_INDICATOR_ADD_INDEX, size, inputs, outputs, Options())


# /* Accumulation/Distribution Oscillator */
# /* Type: indicator */
# /* Input arrays: 4    Options: 2    Output arrays: 1 */
# /* Inputs: high, low, close, volume */
# /* Options: short_period, long_period */
# /* Outputs: adosc */
alias TI_INDICATOR_ADOSC_INDEX = 4


fn ti_adosc(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    volume: Series,
    inout outputs: Outputs,
    short_period: Float64,
    long_period: Float64,
) raises:
    var inputs = Inputs(4)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    inputs.add(volume)
    ti_indicator(
        TI_INDICATOR_ADOSC_INDEX,
        size,
        inputs,
        outputs,
        Options(short_period, long_period),
    )


# /* Average Directional Movement Index */
# /* Type: indicator */
# /* Input arrays: 2    Options: 1    Output arrays: 1 */
# /* Inputs: high, low */
# /* Options: period */
# /* Outputs: adx */
alias TI_INDICATOR_ADX_INDEX = 5


fn ti_adx(
    size: Int,
    high: Series,
    low: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_ADX_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Average Directional Movement Rating */
# /* Type: indicator */
# /* Input arrays: 2    Options: 1    Output arrays: 1 */
# /* Inputs: high, low */
# /* Options: period */
# /* Outputs: adxr */
alias TI_INDICATOR_ADXR_INDEX = 6


fn ti_adxr(
    size: Int,
    high: Series,
    low: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_ADXR_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Awesome Oscillator */
# /* Type: indicator */
# /* Input arrays: 2    Options: 0    Output arrays: 1 */
# /* Inputs: high, low */
# /* Options: none */
# /* Outputs: ao */
alias TI_INDICATOR_AO_INDEX = 7


fn ti_ao(size: Int, high: Series, low: Series, inout outputs: Outputs) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_AO_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Absolute Price Oscillator */
# /* Type: indicator */
# /* Input arrays: 1    Options: 2    Output arrays: 1 */
# /* Inputs: real */
# /* Options: short_period, long_period */
# /* Outputs: apo */
alias TI_INDICATOR_APO_INDEX = 8


fn ti_apo(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    short_period: Float64,
    long_period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_APO_INDEX,
        size,
        inputs,
        outputs,
        Options(short_period, long_period),
    )


# /* Aroon */
# /* Type: indicator */
# /* Input arrays: 2    Options: 1    Output arrays: 2 */
# /* Inputs: high, low */
# /* Options: period */
# /* Outputs: aroon_down, aroon_up */
alias TI_INDICATOR_AROON_INDEX = 9


fn ti_aroon(
    size: Int,
    high: Series,
    low: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_AROON_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Aroon Oscillator */
# /* Type: indicator */
# /* Input arrays: 2    Options: 1    Output arrays: 1 */
# /* Inputs: high, low */
# /* Options: period */
# /* Outputs: aroonosc */
alias TI_INDICATOR_AROONOSC_INDEX = 10


fn ti_aroonosc(
    size: Int,
    high: Series,
    low: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_AROONOSC_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Arcsine */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: asin */
alias TI_INDICATOR_ASIN_INDEX = 11


fn ti_asin(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_ASIN_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Vector Arctangent */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: atan */
alias TI_INDICATOR_ATAN_INDEX = 12


fn ti_atan(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_ATAN_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Average True Range */
# /* Type: indicator */
# /* Input arrays: 3    Options: 1    Output arrays: 1 */
# /* Inputs: high, low, close */
# /* Options: period */
# /* Outputs: atr */
alias TI_INDICATOR_ATR_INDEX = 13


# int ti_atr_start(TI_REAL const *options);
# int ti_atr(int size, TI_REAL const *const *inputs, TI_REAL const *options, TI_REAL *const *outputs);
# int ti_atr_ref(int size, TI_REAL const *const *inputs, TI_REAL const *options, TI_REAL *const *outputs);
# int ti_atr_stream_new(TI_REAL const *options, ti_stream **stream);
# int ti_atr_stream_run(ti_stream *stream, int size, TI_REAL const *const *inputs, TI_REAL *const *outputs);
# void ti_atr_stream_free(ti_stream *stream);
fn ti_atr(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_ATR_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Average Price */
# /* Type: overlay */
# /* Input arrays: 4    Options: 0    Output arrays: 1 */
# /* Inputs: open, high, low, close */
# /* Options: none */
# /* Outputs: avgprice */
alias TI_INDICATOR_AVGPRICE_INDEX = 14


fn ti_avgprice(
    size: Int,
    open: Series,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(4)
    inputs.add(open)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_AVGPRICE_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Bollinger Bands */
# /* Type: overlay */
# /* Input arrays: 1    Options: 2    Output arrays: 3 */
# /* Inputs: real */
# /* Options: period, stddev */
# /* Outputs: bbands_lower, bbands_middle, bbands_upper */
alias TI_INDICATOR_BBANDS_INDEX = 15


fn ti_bbands(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    period: Float64,
    stddev: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_BBANDS_INDEX,
        size,
        inputs,
        outputs,
        Options(period, stddev),
    )


# /* Balance of Power */
# /* Type: indicator */
# /* Input arrays: 4    Options: 0    Output arrays: 1 */
# /* Inputs: open, high, low, close */
# /* Options: none */
# /* Outputs: bop */
alias TI_INDICATOR_BOP_INDEX = 16


fn ti_bop(
    size: Int,
    open: Series,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(4)
    inputs.add(open)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_BOP_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Commodity Channel Index */
# /* Type: indicator */
# /* Input arrays: 3    Options: 1    Output arrays: 1 */
# /* Inputs: high, low, close */
# /* Options: period */
# /* Outputs: cci */
alias TI_INDICATOR_CCI_INDEX = 17


fn ti_cci(
    size: Int,
    open: Series,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_CCI_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Ceiling */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: ceil */
alias TI_INDICATOR_CEIL_INDEX = 18


fn ti_ceil(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_CEIL_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Chande Momentum Oscillator */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: cmo */
alias TI_INDICATOR_CMO_INDEX = 19


fn ti_cmo(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_CMO_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Cosine */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: cos */
alias TI_INDICATOR_COS_INDEX = 20


# int ti_cos_start(TI_REAL const *options);
# int ti_cos(int size, TI_REAL const *const *inputs, TI_REAL const *options, TI_REAL *const *outputs);
fn ti_cos(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_COS_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Vector Hyperbolic Cosine */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: cosh */
alias TI_INDICATOR_COSH_INDEX = 21


fn ti_cosh(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_COSH_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Crossany */
# /* Type: math */
# /* Input arrays: 2    Options: 0    Output arrays: 1 */
# /* Inputs: real, real */
# /* Options: none */
# /* Outputs: crossany */
alias TI_INDICATOR_CROSSANY_INDEX = 22


fn ti_crossany(
    size: Int,
    real0: Series,
    real1: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(2)
    inputs.add(real0)
    inputs.add(real1)
    ti_indicator(
        TI_INDICATOR_CROSSANY_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Crossover */
# /* Type: math */
# /* Input arrays: 2    Options: 0    Output arrays: 1 */
# /* Inputs: real, real */
# /* Options: none */
# /* Outputs: crossover */
alias TI_INDICATOR_CROSSOVER_INDEX = 23


fn ti_crossover(
    size: Int,
    real0: Series,
    real1: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(2)
    inputs.add(real0)
    inputs.add(real1)
    ti_indicator(
        TI_INDICATOR_CROSSOVER_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Chaikins Volatility */
# /* Type: indicator */
# /* Input arrays: 2    Options: 1    Output arrays: 1 */
# /* Inputs: high, low */
# /* Options: period */
# /* Outputs: cvi */
alias TI_INDICATOR_CVI_INDEX = 24


fn ti_cvi(
    size: Int,
    high: Series,
    low: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_CVI_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Linear Decay */
# /* Type: math */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: decay */
alias TI_INDICATOR_DECAY_INDEX = 25


fn ti_decay(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_DECAY_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Double Exponential Moving Average */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: dema */
alias TI_INDICATOR_DEMA_INDEX = 26


fn ti_dema(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_DEMA_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Directional Indicator */
# /* Type: indicator */
# /* Input arrays: 3    Options: 1    Output arrays: 2 */
# /* Inputs: high, low, close */
# /* Options: period */
# /* Outputs: plus_di, minus_di */
alias TI_INDICATOR_DI_INDEX = 27


fn ti_di(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_DI_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Division */
# /* Type: simple */
# /* Input arrays: 2    Options: 0    Output arrays: 1 */
# /* Inputs: real, real */
# /* Options: none */
# /* Outputs: div */
alias TI_INDICATOR_DIV_INDEX = 28


fn ti_div(
    size: Int,
    real0: Series,
    real1: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(2)
    inputs.add(real0)
    inputs.add(real1)
    ti_indicator(
        TI_INDICATOR_DIV_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Directional Movement */
# /* Type: indicator */
# /* Input arrays: 2    Options: 1    Output arrays: 2 */
# /* Inputs: high, low */
# /* Options: period */
# /* Outputs: plus_dm, minus_dm */
alias TI_INDICATOR_DM_INDEX = 29


fn ti_dm(
    size: Int,
    high: Series,
    low: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_DM_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Detrended Price Oscillator */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: dpo */
alias TI_INDICATOR_DPO_INDEX = 30


fn ti_dpo(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_DPO_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Directional Movement Index */
# /* Type: indicator */
# /* Input arrays: 2    Options: 1    Output arrays: 1 */
# /* Inputs: high, low */
# /* Options: period */
# /* Outputs: dx */
alias TI_INDICATOR_DX_INDEX = 31


fn ti_dx(
    size: Int,
    high: Series,
    low: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_DX_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Exponential Decay */
# /* Type: math */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: edecay */
alias TI_INDICATOR_EDECAY_INDEX = 32


fn ti_edecay(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_EDECAY_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Exponential Moving Average */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: ema */
alias TI_INDICATOR_EMA_INDEX = 33


fn ti_ema(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_EMA_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Ease of Movement */
# /* Type: indicator */
# /* Input arrays: 3    Options: 0    Output arrays: 1 */
# /* Inputs: high, low, volume */
# /* Options: none */
# /* Outputs: emv */
alias TI_INDICATOR_EMV_INDEX = 34


fn ti_emv(
    size: Int,
    high: Series,
    low: Series,
    volume: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(volume)
    ti_indicator(
        TI_INDICATOR_EMV_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Vector Exponential */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: exp */
alias TI_INDICATOR_EXP_INDEX = 35


fn ti_exp(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_EXP_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Fisher Transform */
# /* Type: indicator */
# /* Input arrays: 2    Options: 1    Output arrays: 2 */
# /* Inputs: high, low */
# /* Options: period */
# /* Outputs: fisher, fisher_signal */
alias TI_INDICATOR_FISHER_INDEX = 36


fn ti_fisher(
    size: Int,
    high: Series,
    low: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_FISHER_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Floor */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: floor */
alias TI_INDICATOR_FLOOR_INDEX = 37


fn ti_floor(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_FLOOR_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Forecast Oscillator */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: fosc */
alias TI_INDICATOR_FOSC_INDEX = 38


fn ti_fosc(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_FOSC_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Hull Moving Average */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: hma */
alias TI_INDICATOR_HMA_INDEX = 39


fn ti_hma(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_HMA_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Kaufman Adaptive Moving Average */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: kama */
alias TI_INDICATOR_KAMA_INDEX = 40


fn ti_kama(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_KAMA_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Klinger Volume Oscillator */
# /* Type: indicator */
# /* Input arrays: 4    Options: 2    Output arrays: 1 */
# /* Inputs: high, low, close, volume */
# /* Options: short_period, long_period */
# /* Outputs: kvo */
alias TI_INDICATOR_KVO_INDEX = 41


fn ti_kvo(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    volume: Series,
    inout outputs: Outputs,
    short_period: Float64,
    long_period: Float64,
) raises:
    var inputs = Inputs(4)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    inputs.add(volume)
    ti_indicator(
        TI_INDICATOR_KVO_INDEX,
        size,
        inputs,
        outputs,
        Options(short_period, long_period),
    )


# /* Lag */
# /* Type: math */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: lag */
alias TI_INDICATOR_LAG_INDEX = 42


fn ti_lag(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_LAG_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Linear Regression */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: linreg */
alias TI_INDICATOR_LINREG_INDEX = 43


fn ti_linreg(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_LINREG_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Linear Regression Intercept */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: linregintercept */
alias TI_INDICATOR_LINREGINTERCEPT_INDEX = 44


fn ti_linregintercept(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_LINREGINTERCEPT_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Linear Regression Slope */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: linregslope */
alias TI_INDICATOR_LINREGSLOPE_INDEX = 45


fn ti_linregslope(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_LINREGSLOPE_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Natural Log */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: ln */
alias TI_INDICATOR_LN_INDEX = 46


fn ti_ln(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_LN_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Vector Base-10 Log */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: log10 */
alias TI_INDICATOR_LOG10_INDEX = 47


fn ti_log10(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_LOG10_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Moving Average Convergence/Divergence */
# /* Type: indicator */
# /* Input arrays: 1    Options: 3    Output arrays: 3 */
# /* Inputs: real */
# /* Options: short_period, long_period, signal_period */
# /* Outputs: macd, macd_signal, macd_histogram */
alias TI_INDICATOR_MACD_INDEX = 48


fn ti_macd(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    short_period: Float64,
    long_period: Float64,
    signal_period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_MACD_INDEX,
        size,
        inputs,
        outputs,
        Options(short_period, long_period, signal_period),
    )


# /* Market Facilitation Index */
# /* Type: indicator */
# /* Input arrays: 3    Options: 0    Output arrays: 1 */
# /* Inputs: high, low, volume */
# /* Options: none */
# /* Outputs: marketfi */
alias TI_INDICATOR_MARKETFI_INDEX = 49


fn ti_marketfi(
    size: Int,
    high: Series,
    low: Series,
    volume: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(volume)
    ti_indicator(
        TI_INDICATOR_MARKETFI_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Mass Index */
# /* Type: indicator */
# /* Input arrays: 2    Options: 1    Output arrays: 1 */
# /* Inputs: high, low */
# /* Options: period */
# /* Outputs: mass */
alias TI_INDICATOR_MASS_INDEX = 50


fn ti_mass(
    size: Int,
    high: Series,
    low: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_MASS_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Maximum In Period */
# /* Type: math */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: max */
alias TI_INDICATOR_MAX_INDEX = 51


# int ti_max_start(TI_REAL const *options);
# int ti_max(int size, TI_REAL const *const *inputs, TI_REAL const *options, TI_REAL *const *outputs);
# int ti_max_ref(int size, TI_REAL const *const *inputs, TI_REAL const *options, TI_REAL *const *outputs);
fn ti_max(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_MAX_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Mean Deviation Over Period */
# /* Type: math */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: md */
alias TI_INDICATOR_MD_INDEX = 52


fn ti_md(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_MD_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Median Price */
# /* Type: overlay */
# /* Input arrays: 2    Options: 0    Output arrays: 1 */
# /* Inputs: high, low */
# /* Options: none */
# /* Outputs: medprice */
alias TI_INDICATOR_MEDPRICE_INDEX = 53


fn ti_medprice(
    size: Int,
    high: Series,
    low: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_MEDPRICE_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Money Flow Index */
# /* Type: indicator */
# /* Input arrays: 4    Options: 1    Output arrays: 1 */
# /* Inputs: high, low, close, volume */
# /* Options: period */
# /* Outputs: mfi */
alias TI_INDICATOR_MFI_INDEX = 54


fn ti_mfi(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    volume: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(4)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    inputs.add(volume)
    ti_indicator(
        TI_INDICATOR_MFI_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Minimum In Period */
# /* Type: math */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: min */
alias TI_INDICATOR_MIN_INDEX = 55


# int ti_min_ref(int size, TI_REAL const *const *inputs, TI_REAL const *options, TI_REAL *const *outputs);
fn ti_min(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_MIN_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Momentum */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: mom */
alias TI_INDICATOR_MOM_INDEX = 56


fn ti_mom(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_MOM_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Mesa Sine Wave */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 2 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: msw_sine, msw_lead */
alias TI_INDICATOR_MSW_INDEX = 57


fn ti_msw(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_MSW_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Multiplication */
# /* Type: simple */
# /* Input arrays: 2    Options: 0    Output arrays: 1 */
# /* Inputs: real, real */
# /* Options: none */
# /* Outputs: mul */
alias TI_INDICATOR_MUL_INDEX = 58


fn ti_mul(
    size: Int,
    real0: Series,
    real1: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(2)
    inputs.add(real0)
    inputs.add(real1)
    ti_indicator(
        TI_INDICATOR_MUL_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Normalized Average True Range */
# /* Type: indicator */
# /* Input arrays: 3    Options: 1    Output arrays: 1 */
# /* Inputs: high, low, close */
# /* Options: period */
# /* Outputs: natr */
alias TI_INDICATOR_NATR_INDEX = 59


fn ti_natr(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_NATR_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Negative Volume Index */
# /* Type: indicator */
# /* Input arrays: 2    Options: 0    Output arrays: 1 */
# /* Inputs: close, volume */
# /* Options: none */
# /* Outputs: nvi */
alias TI_INDICATOR_NVI_INDEX = 60


fn ti_nvi(
    size: Int,
    close: Series,
    volume: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(2)
    inputs.add(close)
    inputs.add(volume)
    ti_indicator(
        TI_INDICATOR_NVI_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* On Balance Volume */
# /* Type: indicator */
# /* Input arrays: 2    Options: 0    Output arrays: 1 */
# /* Inputs: close, volume */
# /* Options: none */
# /* Outputs: obv */
alias TI_INDICATOR_OBV_INDEX = 61


fn ti_obv(
    size: Int,
    close: Series,
    volume: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(2)
    inputs.add(close)
    inputs.add(volume)
    ti_indicator(
        TI_INDICATOR_OBV_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Percentage Price Oscillator */
# /* Type: indicator */
# /* Input arrays: 1    Options: 2    Output arrays: 1 */
# /* Inputs: real */
# /* Options: short_period, long_period */
# /* Outputs: ppo */
alias TI_INDICATOR_PPO_INDEX = 62


fn ti_ppo(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    short_period: Float64,
    long_period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_PPO_INDEX,
        size,
        inputs,
        outputs,
        Options(short_period, long_period),
    )


# /* Parabolic SAR */
# /* Type: overlay */
# /* Input arrays: 2    Options: 2    Output arrays: 1 */
# /* Inputs: high, low */
# /* Options: acceleration_factor_step, acceleration_factor_maximum */
# /* Outputs: psar */
alias TI_INDICATOR_PSAR_INDEX = 63


fn ti_psar(
    size: Int,
    high: Series,
    low: Series,
    inout outputs: Outputs,
    acceleration_factor_step: Float64,
    acceleration_factor_maximum: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(high)
    inputs.add(low)
    ti_indicator(
        TI_INDICATOR_PSAR_INDEX,
        size,
        inputs,
        outputs,
        Options(acceleration_factor_step, acceleration_factor_maximum),
    )


# /* Positive Volume Index */
# /* Type: indicator */
# /* Input arrays: 2    Options: 0    Output arrays: 1 */
# /* Inputs: close, volume */
# /* Options: none */
# /* Outputs: pvi */
alias TI_INDICATOR_PVI_INDEX = 64


fn ti_pvi(
    size: Int,
    close: Series,
    volume: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(2)
    inputs.add(close)
    inputs.add(volume)
    ti_indicator(
        TI_INDICATOR_PVI_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Qstick */
# /* Type: indicator */
# /* Input arrays: 2    Options: 1    Output arrays: 1 */
# /* Inputs: open, close */
# /* Options: period */
# /* Outputs: qstick */
alias TI_INDICATOR_QSTICK_INDEX = 65


fn ti_qstick(
    size: Int,
    open: Series,
    close: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(open)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_QSTICK_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Rate of Change */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: roc */
alias TI_INDICATOR_ROC_INDEX = 66


fn ti_roc(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_ROC_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Rate of Change Ratio */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: rocr */
alias TI_INDICATOR_ROCR_INDEX = 67


fn ti_rocr(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_ROCR_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Round */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: round */
alias TI_INDICATOR_ROUND_INDEX = 68


fn ti_round(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_ROCR_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Relative Strength Index */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: rsi */
alias TI_INDICATOR_RSI_INDEX = 69


fn ti_rsi(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_RSI_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Sine */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: sin */
alias TI_INDICATOR_SIN_INDEX = 70


fn ti_sin(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_SIN_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Vector Hyperbolic Sine */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: sinh */
alias TI_INDICATOR_SINH_INDEX = 71


fn ti_sinh(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_SINH_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Simple Moving Average */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: sma */
alias TI_INDICATOR_SMA_INDEX = 72


# int ti_sma_stream_new(TI_REAL const *options, ti_stream **stream);
# int ti_sma_stream_run(ti_stream *stream, int size, TI_REAL const *const *inputs, TI_REAL *const *outputs);
# void ti_sma_stream_free(ti_stream *stream);
fn ti_sma(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(TI_INDICATOR_SMA_INDEX, size, inputs, outputs, Options(period))


# /* Vector Square Root */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: sqrt */
alias TI_INDICATOR_SQRT_INDEX = 73


fn ti_sqrt(size: Int, real: Series, inout outputs: Outputs) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(TI_INDICATOR_SQRT_INDEX, size, inputs, outputs, Options())


# /* Standard Deviation Over Period */
# /* Type: math */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: stddev */
alias TI_INDICATOR_STDDEV_INDEX = 74


fn ti_stddev(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_STDDEV_INDEX, size, inputs, outputs, Options(period)
    )


# /* Standard Error Over Period */
# /* Type: math */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: stderr */
alias TI_INDICATOR_STDERR_INDEX = 75


fn ti_stderr(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_STDERR_INDEX, size, inputs, outputs, Options(period)
    )


# /* Stochastic Oscillator */
# /* Type: indicator */
# /* Input arrays: 3    Options: 3    Output arrays: 2 */
# /* Inputs: high, low, close */
# /* Options: k_period, k_slowing_period, d_period */
# /* Outputs: stoch_k, stoch_d */
alias TI_INDICATOR_STOCH_INDEX = 76


fn ti_stoch(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
    k_period: Float64,
    k_slowing_period: Float64,
    d_period: Float64,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_STOCH_INDEX,
        size,
        inputs,
        outputs,
        Options(k_period, k_slowing_period, d_period),
    )


# /* Stochastic RSI */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: stochrsi */
alias TI_INDICATOR_STOCHRSI_INDEX = 77


fn ti_stochrsi(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_STOCHRSI_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Subtraction */
# /* Type: simple */
# /* Input arrays: 2    Options: 0    Output arrays: 1 */
# /* Inputs: real, real */
# /* Options: none */
# /* Outputs: sub */
alias TI_INDICATOR_SUB_INDEX = 78


fn ti_sub(
    size: Int,
    real0: Series,
    real1: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(2)
    inputs.add(real0)
    inputs.add(real1)
    ti_indicator(
        TI_INDICATOR_SUB_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Sum Over Period */
# /* Type: math */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: sum */
alias TI_INDICATOR_SUM_INDEX = 79


fn ti_sum(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_SUM_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Tangent */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: tan */
alias TI_INDICATOR_TAN_INDEX = 80


fn ti_tan(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_TAN_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Vector Hyperbolic Tangent */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: tanh */
alias TI_INDICATOR_TANH_INDEX = 81


fn ti_tanh(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_TANH_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Triple Exponential Moving Average */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: tema */
alias TI_INDICATOR_TEMA_INDEX = 82


fn ti_tanh(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_TEMA_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Degree Conversion */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: degrees */
alias TI_INDICATOR_TODEG_INDEX = 83


fn ti_todeg(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_TODEG_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Vector Radian Conversion */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: radians */
alias TI_INDICATOR_TORAD_INDEX = 84


fn ti_torad(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_TORAD_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* True Range */
# /* Type: indicator */
# /* Input arrays: 3    Options: 0    Output arrays: 1 */
# /* Inputs: high, low, close */
# /* Options: none */
# /* Outputs: tr */
alias TI_INDICATOR_TR_INDEX = 85


fn ti_tr(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_TR_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Triangular Moving Average */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: trima */
alias TI_INDICATOR_TRIMA_INDEX = 86


fn ti_trima(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_TRIMA_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Trix */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: trix */
alias TI_INDICATOR_TRIX_INDEX = 87


fn ti_trix(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_TRIX_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vector Truncate */
# /* Type: simple */
# /* Input arrays: 1    Options: 0    Output arrays: 1 */
# /* Inputs: real */
# /* Options: none */
# /* Outputs: trunc */
alias TI_INDICATOR_TRUNC_INDEX = 88


fn ti_trunc(
    size: Int,
    real: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_TRUNC_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Time Series Forecast */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: tsf */
alias TI_INDICATOR_TSF_INDEX = 89


fn ti_tsf(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_TSF_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Typical Price */
# /* Type: overlay */
# /* Input arrays: 3    Options: 0    Output arrays: 1 */
# /* Inputs: high, low, close */
# /* Options: none */
# /* Outputs: typprice */
alias TI_INDICATOR_TYPPRICE_INDEX = 90


fn ti_typprice(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_TYPPRICE_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Ultimate Oscillator */
# /* Type: indicator */
# /* Input arrays: 3    Options: 3    Output arrays: 1 */
# /* Inputs: high, low, close */
# /* Options: short_period, medium_period, long_period */
# /* Outputs: ultosc */
alias TI_INDICATOR_ULTOSC_INDEX = 91


fn ti_ultosc(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
    short_period: Float64,
    medium_period: Float64,
    long_period: Float64,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_ULTOSC_INDEX,
        size,
        inputs,
        outputs,
        Options(short_period, medium_period, long_period),
    )


# /* Variance Over Period */
# /* Type: math */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: var */
alias TI_INDICATOR_VAR_INDEX = 92


fn ti_var(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_VAR_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Vertical Horizontal Filter */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: vhf */
alias TI_INDICATOR_VHF_INDEX = 93


fn ti_vhf(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_VHF_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Variable Index Dynamic Average */
# /* Type: overlay */
# /* Input arrays: 1    Options: 3    Output arrays: 1 */
# /* Inputs: real */
# /* Options: short_period, long_period, alpha */
# /* Outputs: vidya */
alias TI_INDICATOR_VIDYA_INDEX = 94


fn ti_vidya(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    short_period: Float64,
    long_period: Float64,
    alpha: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_VIDYA_INDEX,
        size,
        inputs,
        outputs,
        Options(short_period, long_period, alpha),
    )


# /* Annualized Historical Volatility */
# /* Type: indicator */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: volatility */
alias TI_INDICATOR_VOLATILITY_INDEX = 95


fn ti_volatility(
    size: Int,
    real: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_VOLATILITY_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Volume Oscillator */
# /* Type: indicator */
# /* Input arrays: 1    Options: 2    Output arrays: 1 */
# /* Inputs: volume */
# /* Options: short_period, long_period */
# /* Outputs: vosc */
alias TI_INDICATOR_VOSC_INDEX = 96


fn ti_vosc(
    size: Int,
    volume: Series,
    inout outputs: Outputs,
    short_period: Float64,
    long_period: Float64,
) raises:
    var inputs = Inputs(1)
    inputs.add(volume)
    ti_indicator(
        TI_INDICATOR_VOSC_INDEX,
        size,
        inputs,
        outputs,
        Options(short_period, long_period),
    )


# /* Volume Weighted Moving Average */
# /* Type: overlay */
# /* Input arrays: 2    Options: 1    Output arrays: 1 */
# /* Inputs: close, volume */
# /* Options: period */
# /* Outputs: vwma */
alias TI_INDICATOR_VWMA_INDEX = 97


fn ti_vwma(
    size: Int,
    close: Series,
    volume: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(2)
    inputs.add(close)
    inputs.add(volume)
    ti_indicator(
        TI_INDICATOR_VWMA_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Williams Accumulation/Distribution */
# /* Type: indicator */
# /* Input arrays: 3    Options: 0    Output arrays: 1 */
# /* Inputs: high, low, close */
# /* Options: none */
# /* Outputs: wad */
alias TI_INDICATOR_WAD_INDEX = 98


fn ti_wad(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_WAD_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Weighted Close Price */
# /* Type: overlay */
# /* Input arrays: 3    Options: 0    Output arrays: 1 */
# /* Inputs: high, low, close */
# /* Options: none */
# /* Outputs: wcprice */
alias TI_INDICATOR_WCPRICE_INDEX = 99


fn ti_wcprice(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_WCPRICE_INDEX,
        size,
        inputs,
        outputs,
        Options(),
    )


# /* Wilders Smoothing */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: wilders */
alias TI_INDICATOR_WILDERS_INDEX = 100


fn ti_wilders(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_WILDERS_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Williams %R */
# /* Type: indicator */
# /* Input arrays: 3    Options: 1    Output arrays: 1 */
# /* Inputs: high, low, close */
# /* Options: period */
# /* Outputs: willr */
alias TI_INDICATOR_WILLR_INDEX = 101


fn ti_willr(
    size: Int,
    high: Series,
    low: Series,
    close: Series,
    inout outputs: Outputs,
    period: Float64,
) raises:
    var inputs = Inputs(3)
    inputs.add(high)
    inputs.add(low)
    inputs.add(close)
    ti_indicator(
        TI_INDICATOR_WILLR_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Weighted Moving Average */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: wma */
alias TI_INDICATOR_WMA_INDEX = 102


fn ti_wma(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_WMA_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )


# /* Zero-Lag Exponential Moving Average */
# /* Type: overlay */
# /* Input arrays: 1    Options: 1    Output arrays: 1 */
# /* Inputs: real */
# /* Options: period */
# /* Outputs: zlema */
alias TI_INDICATOR_ZLEMA_INDEX = 103


fn ti_zlema(
    size: Int, real: Series, inout outputs: Outputs, period: Float64
) raises:
    var inputs = Inputs(1)
    inputs.add(real)
    ti_indicator(
        TI_INDICATOR_ZLEMA_INDEX,
        size,
        inputs,
        outputs,
        Options(period),
    )
