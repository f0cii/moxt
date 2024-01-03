from .c import *
from .mo import *
from .moutil import *
from stdlib_extensions.builtins import dict, HashableInt


alias TLS1_1_VERSION = 0x0302
alias TLS1_2_VERSION = 0x0303
alias TLS1_3_VERSION = 0x0304


alias on_connect_callback = fn () capturing -> None
alias on_heartbeat_callback = fn () capturing -> None
alias on_message_callback = fn (
    data: c_char_pointer, data_len: c_size_t
) capturing -> None


fn set_on_connect(id: Int, ptr: Int) -> None:
    if id == 0:
        return
    logd("set_on_connect id=" + str(id) + ", ptr=" + str(ptr))
    seq_store_object_address(id, ptr)


fn set_on_heartbeat(id: Int, ptr: Int) -> None:
    if id == 0:
        return
    let id_ = id + 1
    logd("set_on_heartbeat id=" + str(id_) + ", ptr=" + str(ptr))
    seq_store_object_address(id_, ptr)


fn set_on_message(id: Int, ptr: Int) -> None:
    if id == 0:
        return
    let id_ = id + 2
    logd("set_on_message id=" + str(id_) + ", ptr=" + str(ptr))
    seq_store_object_address(id_, ptr)


fn emit_on_connect(id: Int) -> None:
    logd("emit_on_connect")
    let ptr = seq_retrieve_object_address(id)
    if ptr == 0:
        logd("emit_on_connect nil")
        return
    let wrap = unsafe.bitcast[on_connect_callback](ptr).load()
    wrap()
    logd("emit_on_connect done")


fn emit_on_heartbeat(id: Int) -> None:
    logd("emit_on_heartbeat")
    let id_ = id + 1
    let ptr = seq_retrieve_object_address(id_)
    if ptr == 0:
        logd("emit_on_heartbeat nil")
        return
    let wrap = unsafe.bitcast[on_heartbeat_callback](ptr).load()
    wrap()
    logd("emit_on_heartbeat done")


fn emit_on_message(id: Int, data: c_char_pointer, data_len: c_size_t) -> None:
    logd("emit_on_message")
    let id_ = id + 2
    let ptr = seq_retrieve_object_address(id_)
    if ptr == 0:
        logd("emit_on_message nil")
        return
    let wrap = unsafe.bitcast[on_message_callback](ptr).load()
    wrap(data, data_len)
    logd("emit_on_message done")


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
        let host_ = to_schar_ptr(host)
        let port_ = to_schar_ptr(port)
        let path_ = to_schar_ptr(path)
        let ptr = seq_websocket_new(
            host_,
            port_,
            path_,
            tls_version,
        )
        host_.free()
        port_.free()
        path_.free()
        register_websocket(ptr)
        logd("ws._ptr=" + str(seq_address_of(ptr)))
        self._ptr = ptr
        self._id = seq_address_of(ptr)

    fn c_ptr(self) -> c_void_pointer:
        return self._ptr

    fn get_id(self) -> Int:
        return self._id

    fn get_on_connect(self) -> on_connect_callback:
        @parameter
        fn wrapper():
            self.on_connect()

        return wrapper

    fn get_on_heartbeat(self) -> on_heartbeat_callback:
        @parameter
        fn wrapper():
            self.on_heartbeat()

        return wrapper

    fn get_on_message(self) -> on_message_callback:
        @parameter
        fn wrapper(data: c_char_pointer, data_len: Int):
            self.on_message(data, data_len)

        return wrapper

    fn on_connect(self) -> None:
        logd("WebSocket.on_connect")

    fn on_heartbeat(self) -> None:
        logd("WebSocket.on_heartbeat")

    fn on_message(self, data: c_char_pointer, data_len: Int) -> None:
        let s = String(data, data_len)
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
    let id = seq_address_of(ws)
    emit_on_connect(id)
    # logd("websocket_connect_callback done")


fn websocket_heartbeat_callback(ws: c_void_pointer) raises -> None:
    # logd("websocket_heartbeat_callback")
    let id = seq_address_of(ws)
    emit_on_heartbeat(id)
    # logd("websocket_heartbeat_callback done")


fn websocket_message_callback(
    ws: c_void_pointer, data: c_char_pointer, data_len: c_size_t
) raises -> None:
    # logd("websocket_message_callback")
    let id = seq_address_of(ws)
    emit_on_message(id, data, data_len)


def register_websocket(ws: c_void_pointer) -> None:
    seq_websocket_set_on_connect(ws, websocket_connect_callback)
    seq_websocket_set_on_heartbeat(ws, websocket_heartbeat_callback)
    seq_websocket_set_on_message(ws, websocket_message_callback)
