from .c import *
from .mo import *


alias TLS1_1_VERSION = 0x0302
alias TLS1_2_VERSION = 0x0303
alias TLS1_3_VERSION = 0x0304


@value
struct WebSocket:
    var ptr: c_void_pointer
    # var on_connect_callback: fn () -> None
    # var on_heartbeat_callback: fn () -> None
    # var on_message_callback: fn (data: c_char_pointer, data_len: Int) -> None

    fn __init__(
        inout self,
        host: StringLiteral,
        port: StringLiteral,
        path: StringLiteral,
        # connect_callback: on_connect_callback,
        # heartbeat_callback: on_heartbeat_callback,
        # message_callback: on_message_callback,
        tls_version: Int = TLS1_3_VERSION,
    ) raises:
        let ptr = seq_websocket_new(
            host.data()._as_scalar_pointer(),
            port.data()._as_scalar_pointer(),
            path.data()._as_scalar_pointer(),
            tls_version,
        )
        register_websocket(ptr)
        self.ptr = ptr

    fn c_ptr(self) -> c_void_pointer:
        return self.ptr

    fn on_connect(self) -> None:
        print("on_connect")

    fn on_heartbeat(self) -> None:
        print("WebSocket.on_heartbeat")

    fn on_message(self, data: c_char_pointer, len: Int) -> None:
        let s = String(data, len)
        print("WebSocket::on_message", s)

    fn release(self) -> None:
        seq_websocket_delete(self.ptr)

    fn connect(self):
        seq_websocket_connect(self.ptr)

    fn close(self):
        # seq_websocket_close(self.ws)
        pass

    fn send(self, text: StringLiteral) -> None:
        seq_websocket_send(self.ptr, text.data()._as_scalar_pointer(), len(text))

    fn __repr__(self) -> String:
        return "<WebSocket: ws={self.ptr}>"


# struct WSHandle:
#     def __init__(self):
#         pass

#     def on_connect(self) -> None:
#         pass

#     def on_heartbeat(self) -> String:
#         return ""


# struct WSMessageHandle:
#     def __init__(inout self):
#         pass

#     def on_message(self, data: c_char_pointer, length: Int) -> None:
#         pass


# let ws_common_event_dict = dict[int, WSHandle]()
# let ws_message_event_dict = dict[int, WSMessageHandle]()


# alias WebSocketMessageHandler = fn (String) capturing -> None

# @value
# @register_passable
# struct HandleWrap:
#     var h: WebSocketMessageHandler

#     fn __init__(inout self, h: WebSocketMessageHandler):
#         self.h = h


# @value
# struct WebSocketHold:
#     var dict: IMapDict[HandleWrap]

#     fn __init__(inout self):
#         self.dict = IMapDict[HandleWrap]

#     fn register(inout self, id: Int, handle: HandleWrap):
#         self.dict.put(id, handle)


# var hold: WebSocketHold = WebSocketHold()


fn websocket_connect_callback(ws: c_void_pointer) raises -> None:
    logi("websocket_connect_callback")
    # try:
    #     pass
    #     # print("websocket_connect_callback 1")
    #     # # ws_common_event_dict[int(ws)].on_connect()
    #     # id = int(ws)
    #     # ws_common_event_dict[id].on_connect()
    #     # # ws_connect_event_dict[id](id)
    #     # print("websocket_connect_callback 2")
    # except:
    #     print("websocket_connect_callback error")


fn websocket_heartbeat_callback(ws: c_void_pointer) raises -> None:
    logi("websocket_heartbeat_callback")
    # try:
    #     # id = int(ws)
    #     # text = ws_common_event_dict[id].on_heartbeat()
    #     # print(f"websocket_heartbeat_callback {text}")
    #     # if text is not None and text != "":
    #     #     seq_websocket_send(ws, text.ptr, text.len)
    #     let text = "hello"
    #     seq_websocket_send(ws, text.data()._as_scalar_pointer(), len(text))
    #     logi("send: " + text)
    # except:
    #     print("websocket_heartbeat_callback error")


fn websocket_message_callback(
    ws: c_void_pointer, data: c_char_pointer, data_len: c_size_t
) raises -> None:
    logi("websocket_message_callback")
    # try:
    #     # let s = String.itoa(c_size_t)
    #     logi("length: " + String(data_len))
    #     # if data_len > 1:
    #     # print("10000")
    #     let s_ref = to_string_ref(data, data_len)
    #     logi("s_ref: " + String(s_ref))
    #     # print("10001")
    #     # base64 解码
    #     # https://base64.us/
    #         # let s = c_charptr_to_string(data.bitcast[Int8](), data_len)#(data, c_size_t)
    #         # logi("message: " + s)
    #     # print(f'websocket_message_callback 1')
    #     # id = int(ws)
    #     # ws_message_event_dict[id].on_message(data, data_len)
    #     # print(f'websocket_message_callback 2')
    # except:
    #     print("websocket_message_callback error")


def register_websocket(ws: c_void_pointer) -> None:
    seq_websocket_set_on_connect(ws, websocket_connect_callback)
    seq_websocket_set_on_heartbeat(ws, websocket_heartbeat_callback)
    seq_websocket_set_on_message(ws, websocket_message_callback)


# def register_ws_callbacks(ws: c_void_pointer, handle: WSHandle):
#     ws_common_event_dict[int(ws)] = handle


# def register_ws_message_callback(ws: c_void_pointer, handle: WSMessageHandle):
#     ws_message_event_dict[int(ws)] = handle
