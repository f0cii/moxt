from sys.ffi import _get_global
from .mo import seq_set_global_int, seq_get_global_int


# Set global pointer
@always_inline
fn set_global_pointer(key: Int, pointer: Int):
    seq_set_global_int(key, pointer)


# Get global pointer
@always_inline
fn get_global_pointer(key: Int) -> Int:
    return seq_get_global_int(key)


alias SignalHandler = fn (Int) -> None


# SEQ_FUNC void seq_register_signal_handler(int signum, SignalHandler handler)
fn seq_register_signal_handler(signum: Int, handler: SignalHandler):
    external_call["seq_register_signal_handler", NoneType, Int, SignalHandler](
        signum, handler
    )


@value
struct __G:
    var stop_requested_flag: Bool
    var stopped_flag: Bool
    var current_strategy: String
    var executor_ptr: Int
    var algo_id: Int
    var vars: Dict[String, String]

    fn __init__(inout self):
        self.stop_requested_flag = False
        self.stopped_flag = False
        self.current_strategy = ""
        self.executor_ptr = 0
        self.algo_id = 0
        self.vars = Dict[String, String]()


fn _GLOBAL() -> UnsafePointer[__G]:
    var p = _get_global["_GLOBAL", _init_global, _destroy_global]()
    return p.bitcast[__G]()


fn _init_global(payload: UnsafePointer[NoneType]) -> UnsafePointer[NoneType]:
    var ptr = UnsafePointer[__G].alloc(1)
    ptr.init_pointee_move(__G())
    return ptr.bitcast[NoneType]()


fn _destroy_global(p: UnsafePointer[NoneType]):
    p.free()


fn _GLOBAL_INT[name: StringLiteral]() -> Pointer[Int]:
    var p = _get_global[name, _initialize_int, _destroy_int]()
    return p.bitcast[Int]()


fn _initialize_int(payload: Pointer[NoneType]) -> Pointer[NoneType]:
    var data = Pointer[Int].alloc(1)
    data[0] = 0
    return data.bitcast[NoneType]()


fn _destroy_int(p: Pointer[NoneType]):
    p.free()


fn _GLOBAL_FLOAT[name: StringLiteral]() -> Pointer[Float64]:
    var p = _get_global[name, _initialize_float64, _destroy_float64]()
    return p.bitcast[Float64]()


fn _initialize_float64(payload: Pointer[NoneType]) -> Pointer[NoneType]:
    var data = Pointer[Float64].alloc(1)
    data.store(0)
    return data.bitcast[NoneType]()


fn _destroy_float64(p: Pointer[NoneType]):
    p.free()


fn _GLOBAL_BOOL[name: StringLiteral]() -> Pointer[Bool]:
    var p = _get_global[name, _initialize_bool, _destroy_bool]()
    return p.bitcast[Bool]()


fn _initialize_bool(payload: Pointer[NoneType]) -> Pointer[NoneType]:
    var data = Pointer[Bool].alloc(1)
    data.store(False)
    return data.bitcast[NoneType]()


fn _destroy_bool(p: Pointer[NoneType]):
    p.free()


fn _GLOBAL_STRING[name: StringLiteral]() -> UnsafePointer[String]:
    var p = _get_global[name, _initialize_string, _destroy_string]()
    return p.bitcast[String]()


fn _initialize_string(
    payload: UnsafePointer[NoneType],
) -> UnsafePointer[NoneType]:
    var ptr = UnsafePointer[String].alloc(1)
    ptr.init_pointee_move(String(""))
    return ptr.bitcast[NoneType]()


fn _destroy_string(p: UnsafePointer[NoneType]):
    p.free()
