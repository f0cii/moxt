from sys.ffi import _get_global
from .c import *
from .mo import *
from .moutil import *
from .containers import ObjectContainer


alias TLS1_1_VERSION = 0x0302
alias TLS1_2_VERSION = 0x0303
alias TLS1_3_VERSION = 0x0304


alias on_connect_callback = fn () escaping -> None
alias on_heartbeat_callback = fn () escaping -> None
alias on_message_callback = fn (
    data: c_char_pointer, data_len: c_size_t
) escaping -> None


@value
struct OnConnectWrapper(CollectionElement):
    var _callback: on_connect_callback

    fn __init__(inout self, owned callback: on_connect_callback):
        self._callback = callback ^

    fn __call__(self):
        self._callback()


@value
struct OnHeartbeatWrapper(CollectionElement):
    var _callback: on_heartbeat_callback

    fn __init__(inout self, owned callback: on_heartbeat_callback):
        self._callback = callback ^

    fn __call__(self):
        self._callback()


@value
struct OnMessageWrapper(CollectionElement):
    var _callback: on_message_callback

    fn __init__(inout self, owned callback: on_message_callback):
        self._callback = callback ^

    fn __call__(self, data: c_char_pointer, data_len: c_size_t):
        self._callback(data, data_len)


fn set_on_connect(id: Int, ptr: Int) -> None:
    if id == 0:
        return
    logd("set_on_connect id=" + str(id) + ", ptr=" + str(ptr))
    seq_set_global_int(id, ptr)


fn set_on_heartbeat(id: Int, ptr: Int) -> None:
    if id == 0:
        return
    var id_ = id + 1
    logd("set_on_heartbeat id=" + str(id_) + ", ptr=" + str(ptr))
    seq_set_global_int(id_, ptr)


fn set_on_message(id: Int, ptr: Int) -> None:
    if id == 0:
        return
    var id_ = id + 2
    logd("set_on_message id=" + str(id_) + ", ptr=" + str(ptr))
    seq_set_global_int(id_, ptr)


fn emit_on_connect(id: Int) -> None:
    var ptr = seq_get_global_int(id)
    if ptr == 0:
        logd("emit_on_connect nil")
        return
    var pointer = AnyPointer[OnConnectWrapper].__from_index(ptr)
    pointer[]()


fn emit_on_heartbeat(id: Int) -> None:
    var id_ = id + 1
    var ptr = seq_get_global_int(id_)
    if ptr == 0:
        logd("emit_on_heartbeat nil")
        return
    var pointer = AnyPointer[OnHeartbeatWrapper].__from_index(ptr)
    pointer[]()


fn emit_on_message(id: Int, data: c_char_pointer, data_len: c_size_t) -> None:
    # var s = c_str_to_string(data, data_len)
    var id_ = id + 2
    var ptr = seq_get_global_int(id_)
    if ptr == 0:
        logd("emit_on_message nil")
        return
    var pointer = AnyPointer[OnMessageWrapper].__from_index(ptr)
    pointer[](data, data_len)


struct WebSocket:
    var _ptr: c_void_pointer
    var _id: Int

    fn __init__(
        inout self,
        host: String,
        port: String,
        path: String,
        tls_version: Int = TLS1_3_VERSION,
    ) raises:
        var host_ = to_schar_ptr(host)
        var port_ = to_schar_ptr(port)
        var path_ = to_schar_ptr(path)
        var ptr = seq_websocket_new(
            host_,
            port_,
            path_,
            tls_version,
        )
        host_.free()
        port_.free()
        path_.free()
        register_websocket(ptr)
        logd("ws._ptr=" + str(seq_voidptr_to_int(ptr)))
        self._ptr = ptr
        self._id = seq_voidptr_to_int(ptr)

    fn c_ptr(self) -> c_void_pointer:
        return self._ptr

    fn get_id(self) -> Int:
        return self._id

    fn get_on_connect(self) -> on_connect_callback:
        var self_ptr = Reference(self).get_unsafe_pointer()

        fn wrapper():
            self_ptr[].on_connect()

        return wrapper

    fn get_on_heartbeat(self) -> on_heartbeat_callback:
        var self_ptr = Reference(self).get_unsafe_pointer()

        fn wrapper():
            self_ptr[].on_heartbeat()

        return wrapper

    fn get_on_message(self) -> on_message_callback:
        var self_ptr = Reference(self).get_unsafe_pointer()

        fn wrapper(data: c_char_pointer, data_len: Int):
            self_ptr[].on_message(data, data_len)

        return wrapper

    fn on_connect(self) -> None:
        logd("WebSocket.on_connect")

    fn on_heartbeat(self) -> None:
        logd("WebSocket.on_heartbeat")

    fn on_message(self, data: c_char_pointer, data_len: Int) -> None:
        var s = String(data, data_len)
        logd("WebSocket::on_message: " + s)

    fn release(self) -> None:
        seq_websocket_delete(self._ptr)

    fn connect(self):
        seq_websocket_connect(self._ptr)

    fn close(self):
        # seq_websocket_close(self.ws)
        pass

    fn send(self, text: String) -> None:
        seq_websocket_send(self._ptr, text._buffer.data.value, len(text))

    fn __repr__(self) -> String:
        return "<WebSocket: ws={self._ptr}>"


fn websocket_connect_callback(ws: c_void_pointer) raises -> None:
    # logd("websocket_connect_callback")
    var id = seq_voidptr_to_int(ws)
    emit_on_connect(id)
    # logd("websocket_connect_callback done")


fn websocket_heartbeat_callback(ws: c_void_pointer) raises -> None:
    # logd("websocket_heartbeat_callback")
    var id = seq_voidptr_to_int(ws)
    emit_on_heartbeat(id)
    # logd("websocket_heartbeat_callback done")


fn websocket_message_callback(
    ws: c_void_pointer, data: c_char_pointer, data_len: c_size_t
) raises -> None:
    # logd("websocket_message_callback")
    var id = seq_voidptr_to_int(ws)
    emit_on_message(id, data, data_len)


def register_websocket(ws: c_void_pointer) -> None:
    seq_websocket_set_on_connect(ws, websocket_connect_callback)
    seq_websocket_set_on_heartbeat(ws, websocket_heartbeat_callback)
    seq_websocket_set_on_message(ws, websocket_message_callback)


# var coc = ObjectContainer[OnConnectWrapper]()
# var hoc = ObjectContainer[OnHeartbeatWrapper]()
# var moc = ObjectContainer[OnMessageWrapper]()

alias OnConnectWrapperContainer = ObjectContainer[OnConnectWrapper]
alias OnHeartbeatWrapperContainer = ObjectContainer[OnHeartbeatWrapper]
alias OnMessageWrapperContainer = ObjectContainer[OnMessageWrapper]


fn coc_ptr() -> Pointer[OnConnectWrapperContainer]:
    var ptr = _get_global["__coc", _init_coc, _destroy_coc]()
    return ptr.bitcast[OnConnectWrapperContainer]()


fn _init_coc(payload: Pointer[NoneType]) -> Pointer[NoneType]:
    var ptr = Pointer[OnConnectWrapperContainer].alloc(1)
    ptr[] = OnConnectWrapperContainer()
    return ptr.bitcast[NoneType]()


fn _destroy_coc(p: Pointer[NoneType]):
    p.free()


fn hoc_ptr() -> Pointer[OnHeartbeatWrapperContainer]:
    var ptr = _get_global["__hoc", _init_hoc, _destroy_hoc]()
    return ptr.bitcast[OnHeartbeatWrapperContainer]()


fn _init_hoc(payload: Pointer[NoneType]) -> Pointer[NoneType]:
    var ptr = Pointer[OnHeartbeatWrapperContainer].alloc(1)
    ptr[] = OnHeartbeatWrapperContainer()
    return ptr.bitcast[NoneType]()


fn _destroy_hoc(p: Pointer[NoneType]):
    p.free()


fn moc_ptr() -> Pointer[OnMessageWrapperContainer]:
    var ptr = _get_global["__moc", _init_moc, _destroy_moc]()
    return ptr.bitcast[OnMessageWrapperContainer]()


fn _init_moc(payload: Pointer[NoneType]) -> Pointer[NoneType]:
    var ptr = Pointer[OnMessageWrapperContainer].alloc(1)
    ptr[] = OnMessageWrapperContainer()
    return ptr.bitcast[NoneType]()


fn _destroy_moc(p: Pointer[NoneType]):
    p.free()
