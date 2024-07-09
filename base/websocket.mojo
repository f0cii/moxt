from sys.ffi import _get_global
from .c import *
from .mo import *
from .moutil import *
from collections.dict import Dict


alias TLS1_1_VERSION = 0x0302
alias TLS1_2_VERSION = 0x0303
alias TLS1_3_VERSION = 0x0304


alias on_connect_callback = fn () escaping -> None
alias on_heartbeat_callback = fn () escaping -> None
alias on_message_callback = fn (String) escaping -> None


alias OnConnectCallbackHolder = Dict[Int, on_connect_callback]
alias OnHeartbeatCallbackHolder = Dict[Int, on_heartbeat_callback]
alias OnMessageCallbackHolder = Dict[Int, on_message_callback]


fn ws_on_connect_holder_ptr() -> UnsafePointer[OnConnectCallbackHolder]:
    var ptr = _get_global[
        "__ws_on_connect_holder",
        _init_ws_on_connect_holder,
        _destroy_ws_on_connect_holder,
    ]()
    return ptr.bitcast[OnConnectCallbackHolder]()


fn _init_ws_on_connect_holder(
    payload: UnsafePointer[NoneType],
) -> UnsafePointer[NoneType]:
    var ptr = UnsafePointer[OnConnectCallbackHolder].alloc(1)
    ptr.init_pointee_move(OnConnectCallbackHolder())
    return ptr.bitcast[NoneType]()


fn _destroy_ws_on_connect_holder(p: UnsafePointer[NoneType]):
    p.free()


fn ws_on_heartbeat_holder_ptr() -> UnsafePointer[OnHeartbeatCallbackHolder]:
    var ptr = _get_global[
        "__ws_on_heartbeat_holder",
        _init_ws_on_heartbeat_holder,
        _destroy_ws_on_heartbeat_holder,
    ]()
    return ptr.bitcast[OnHeartbeatCallbackHolder]()


fn _init_ws_on_heartbeat_holder(
    payload: UnsafePointer[NoneType],
) -> UnsafePointer[NoneType]:
    var ptr = UnsafePointer[OnHeartbeatCallbackHolder].alloc(1)
    ptr.init_pointee_move(OnHeartbeatCallbackHolder())
    return ptr.bitcast[NoneType]()


fn _destroy_ws_on_heartbeat_holder(p: UnsafePointer[NoneType]):
    p.free()


fn ws_on_message_holder_ptr() -> UnsafePointer[OnMessageCallbackHolder]:
    var ptr = _get_global[
        "__moc", _init_ws_on_message_holder, _destroy_ws_on_message_holder
    ]()
    return ptr.bitcast[OnMessageCallbackHolder]()


fn _init_ws_on_message_holder(
    payload: UnsafePointer[NoneType],
) -> UnsafePointer[NoneType]:
    var ptr = UnsafePointer[OnMessageCallbackHolder].alloc(1)
    ptr.init_pointee_move(OnMessageCallbackHolder())
    return ptr.bitcast[NoneType]()


fn _destroy_ws_on_message_holder(p: UnsafePointer[NoneType]):
    p.free()


fn set_on_connect(id: Int, owned callback: on_connect_callback) -> None:
    if id == 0:
        return
    ws_on_connect_holder_ptr()[][id] = callback^


fn set_on_heartbeat(id: Int, owned callback: on_heartbeat_callback) -> None:
    if id == 0:
        return
    ws_on_heartbeat_holder_ptr()[][id] = callback^


fn set_on_message(id: Int, owned callback: on_message_callback) -> None:
    if id == 0:
        return
    ws_on_message_holder_ptr()[][id] = callback^


fn emit_on_connect(id: Int) -> None:
    try:
        ws_on_connect_holder_ptr()[][id]()
    except e:
        pass


fn emit_on_heartbeat(id: Int) -> None:
    try:
        ws_on_heartbeat_holder_ptr()[][id]()
    except e:
        pass


fn emit_on_message(id: Int, data: c_char_pointer, data_len: c_size_t) -> None:
    try:
        var msg = c_str_to_string(data, data_len)
        ws_on_message_holder_ptr()[][id](msg)
        msg._strref_keepalive()
    except e:
        pass


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
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper():
            self_ptr[].on_connect()

        return wrapper

    fn get_on_heartbeat(self) -> on_heartbeat_callback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper():
            self_ptr[].on_heartbeat()

        return wrapper

    fn get_on_message(self) -> on_message_callback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper(msg: String):
            self_ptr[].on_message(msg)

        return wrapper

    fn on_connect(self) -> None:
        logd("WebSocket.on_connect")

    fn on_heartbeat(self) -> None:
        logd("WebSocket.on_heartbeat")

    fn on_message(self, msg: String) -> None:
        logd("WebSocket::on_message: " + msg)

    fn release(self) -> None:
        seq_websocket_delete(self._ptr)

    fn connect(self):
        seq_websocket_connect(self._ptr)

    fn close(self):
        # seq_websocket_close(self.ws)
        pass

    fn send(self, text: String) -> None:
        seq_websocket_send(
            self._ptr,
            unsafe_ptr_as_scalar_pointer(text.unsafe_ptr()),
            len(text),
        )

    fn __repr__(self) -> String:
        return "<WebSocket: ws={self._ptr}>"


fn websocket_connect_callback(ws: c_void_pointer) raises -> None:
    logi("websocket_connect_callback 100")
    var id = seq_voidptr_to_int(ws)
    emit_on_connect(id)
    logi("websocket_connect_callback done")


fn websocket_heartbeat_callback(ws: c_void_pointer) raises -> None:
    # logi("websocket_heartbeat_callback")
    var id = seq_voidptr_to_int(ws)
    emit_on_heartbeat(id)
    # logi("websocket_heartbeat_callback done")


fn websocket_message_callback(
    ws: c_void_pointer, data: c_char_pointer, data_len: c_size_t
) raises -> None:
    # logi("websocket_message_callback")
    var id = seq_voidptr_to_int(ws)
    emit_on_message(id, data, data_len)
    # logi("websocket_message_callback done")


fn register_websocket(ws: c_void_pointer) -> None:
    seq_websocket_set_on_connect(ws, websocket_connect_callback)
    seq_websocket_set_on_heartbeat(ws, websocket_heartbeat_callback)
    seq_websocket_set_on_message(ws, websocket_message_callback)
