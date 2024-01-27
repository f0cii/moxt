from utils.static_tuple import StaticTuple
from stdlib_extensions.builtins import list, dict, HashableInt, HashableStr
from .c import *


alias TI_TYPE_OVERLAY = 1  # These have roughly the same range as the input data.
alias TI_TYPE_INDICATOR = 2  # Everything else (e.g. oscillators).
alias TI_TYPE_MATH = 3  # These aren't so good for plotting, but are useful with formulas.
alias TI_TYPE_SIMPLE = 4  # These apply a simple operator (e.g. addition, sin, sqrt).
alias TI_TYPE_COMPARATIVE = 5  # These are designed to take inputs from different securities. i.e. compare stock A to stock B.


@value
@register_passable("trivial")
struct ti_stream:
    pass


alias ti_indicator_start_function = fn (options: Pointer[Float64]) raises -> c_int
alias ti_indicator_function = fn (
    size: c_int,
    inputs: Pointer[Pointer[Float64]],
    options: Pointer[Float64],
    outputs: Pointer[Pointer[Float64]],
) raises -> c_int
alias ti_indicator_stream_new = fn (
    options: Pointer[Float64], stream: Pointer[Pointer[ti_stream]]
) raises -> c_int
alias ti_indicator_stream_run = fn (
    stream: Pointer[ti_stream],
    size: c_int,
    inputs: Pointer[Pointer[Float64]],
    outputs: Pointer[Pointer[Float64]],
) raises -> c_int
alias ti_indicator_stream_free = fn (stream: Pointer[ti_stream]) -> None


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
    var _input_names: StaticTuple[16, c_char_pointer]
    var _option_names: StaticTuple[16, c_char_pointer]
    var _output_names: StaticTuple[16, c_char_pointer]
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

    fn input_names(self) -> list[String]:
        var result = list[String]()
        for i in range(self._inputs):
            let s = self._input_names[i]
            result.append(c_str_to_string(s, strlen(s)))
        return result

    fn option_names(self) -> list[String]:
        var result = list[String]()
        for i in range(self._options):
            let s = self._option_names[i]
            result.append(c_str_to_string(s, strlen(s)))
        return result

    fn output_names(self) -> list[String]:
        var result = list[String]()
        for i in range(self._outputs):
            let s = self._output_names[i]
            result.append(c_str_to_string(s, strlen(s)))
        return result


fn seq_test_ti() -> None:
    external_call["seq_test_ti", NoneType]()


fn seq_test_ti1() -> None:
    external_call["seq_test_ti1", NoneType]()


fn seq_test_ti2(
    data_in: Pointer[Float64],
    input_length: c_int,
    options: Pointer[Float64],
    data_out: Pointer[Float64],
) -> None:
    external_call[
        "seq_test_ti2",
        NoneType,
        Pointer[Float64],
        c_int,
        Pointer[Float64],
        Pointer[Float64],
    ](data_in, input_length, options, data_out)


fn seq_test_ti3(
    inputs: Pointer[Pointer[Float64]],
    input_length: c_int,
    options: Pointer[Float64],
    outputs: Pointer[Pointer[Float64]],
) -> None:
    external_call[
        "seq_test_ti3",
        NoneType,
        Pointer[Pointer[Float64]],
        c_int,
        Pointer[Float64],
        Pointer[Pointer[Float64]],
    ](inputs, input_length, options, outputs)


fn seq_ti_get_first_indicator() -> AnyPointer[ti_indicator_info]:
    return external_call["seq_ti_get_first_indicator", AnyPointer[ti_indicator_info]]()


fn seq_ti_is_valid_indicator(info: AnyPointer[ti_indicator_info]) -> Bool:
    return external_call[
        "seq_ti_is_valid_indicator", Bool, AnyPointer[ti_indicator_info]
    ](info)


fn seq_ti_get_next_indicator(
    info: AnyPointer[ti_indicator_info],
) -> AnyPointer[ti_indicator_info]:
    return external_call[
        "seq_ti_get_next_indicator",
        AnyPointer[ti_indicator_info],
        AnyPointer[ti_indicator_info],
    ](info)


fn seq_ti_find_indicator(name: c_char_pointer) -> AnyPointer[ti_indicator_info]:
    return external_call[
        "seq_ti_find_indicator", AnyPointer[ti_indicator_info], c_char_pointer
    ](name)


fn seq_ti_indicator_at_index(index: c_int) -> AnyPointer[ti_indicator_info]:
    return external_call[
        "seq_ti_indicator_at_index", AnyPointer[ti_indicator_info], c_int
    ](index)


fn seq_ti_indicator_start(
    info: AnyPointer[ti_indicator_info],
    options: Pointer[Float64],
) -> c_int:
    return external_call[
        "seq_ti_indicator_start",
        c_int,
        AnyPointer[ti_indicator_info],
        Pointer[Float64],
    ](info, options)


fn seq_ti_indicator_start(
    info: AnyPointer[ti_indicator_info],
    options: AnyPointer[Float64],
) -> c_int:
    return external_call[
        "seq_ti_indicator_start",
        c_int,
        AnyPointer[ti_indicator_info],
        AnyPointer[Float64],
    ](info, options)


fn seq_ti_indicator_run(
    info: AnyPointer[ti_indicator_info],
    input_size: c_int,
    inputs: Pointer[Pointer[Float64]],
    options: Pointer[Float64],
    outputs: Pointer[Pointer[Float64]],
) -> Bool:
    return external_call[
        "seq_ti_indicator_run",
        Bool,
        AnyPointer[ti_indicator_info],
        c_int,
        Pointer[Pointer[Float64]],
        Pointer[Float64],
        Pointer[Pointer[Float64]],
    ](info, input_size, inputs, options, outputs)


fn seq_ti_indicator_run(
    info: AnyPointer[ti_indicator_info],
    input_size: c_int,
    inputs: Pointer[AnyPointer[Float64]],
    options: AnyPointer[Float64],
    outputs: Pointer[AnyPointer[Float64]],
) -> Bool:
    return external_call[
        "seq_ti_indicator_run",
        Bool,
        AnyPointer[ti_indicator_info],
        c_int,
        Pointer[AnyPointer[Float64]],
        AnyPointer[Float64],
        Pointer[AnyPointer[Float64]],
    ](info, input_size, inputs, options, outputs)


@value
struct Indicator:
    var _indicator_info: AnyPointer[ti_indicator_info]

    def __init__(inout self, index: Int):
        self._indicator_info = seq_ti_indicator_at_index(index)

    def run(
        self, input_length: Int, data_in: Pointer[Float64], options: Pointer[Float64]
    ) -> Bool:
        let inputs = Pointer[Pointer[Float64]].alloc(1)
        inputs.store(0, data_in)

        let start = seq_ti_indicator_start(self._indicator_info, options)
        let output_length = input_length - start

        let outputs = Pointer[Pointer[Float64]].alloc(1)
        let data_out = Pointer[Float64].alloc(int(output_length))
        outputs.store(0, data_out)
        let ok = seq_ti_indicator_run(
            self._indicator_info, input_length, inputs, options, outputs
        )

        # data_in.free()
        data_out.free()
        # options.free()
        inputs.free()
        outputs.free()

        return ok
    
    def run(
        self, input_length: Int, inputs: Pointer[AnyPointer[Float64]], options: DynamicVector[Float64]
    ) -> Bool:
        # let inputs = Pointer[AnyPointer[Float64]].alloc(1)
        # inputs.store(0, data_in.data)

        let start = seq_ti_indicator_start(self._indicator_info, options.data)
        let output_length = int(input_length - start)

        let outputs = Pointer[AnyPointer[Float64]].alloc(1)
        var data_out = DynamicVector[Float64](output_length)
        data_out.resize(output_length, 0.0)
        outputs.store(0, data_out.data)
        let ok = seq_ti_indicator_run(
            self._indicator_info, input_length, inputs, options.data, outputs
        )

        # inputs.free()
        outputs.free()

        return ok
