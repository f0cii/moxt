from base.c import *
from base.mo import *
from base.globals import *
from base.moutil import *
from base.websocket import (
    seq_websocket_new,
    seq_websocket_delete,
    seq_websocket_connect,
    seq_websocket_disconnect,
    seq_websocket_send,
    register_websocket,
    TLS1_3_VERSION,
    on_connect_callback,
    on_heartbeat_callback,
    on_message_callback,
    set_on_connect,
    set_on_heartbeat,
    set_on_message,
)
from base.yyjson import yyjson_doc, yyjson_mut_doc
from .sign import hmac_sha256_hex
from ylstdlib.time import time_ns
from base.sj_ondemand import OndemandParser


alias ParserBufferSize = 1000 * 100


struct BybitWS:
    var _ptr: c_void_pointer
    var _id: Int
    var _is_private: Bool
    var _access_key: String
    var _secret_key: String
    var _category: String
    var _subscription_topics: List[String]
    var _subscription_topics_str: String
    var _heartbeat_time: UnsafePointer[Int64]
    var _is_subscribed: Bool
    var _verbose: Bool

    fn __init__(
        inout self,
        is_private: Bool,
        testnet: Bool,
        access_key: String,
        secret_key: String,
        category: String = "",
        topics: String = "",
    ) raises:
        self._is_private = is_private
        self._access_key = access_key
        self._secret_key = secret_key
        self._category = category
        self._subscription_topics = List[String]()
        self._subscription_topics_str = topics

        var host: String = ""
        var port: String = ""
        var path: String = ""
        if testnet:
            host = "stream-testnet.bybit.com"
        else:
            host = "stream.bybit.com"
        port = "443"
        if is_private:
            path = "/v5/private"
        else:
            path = "/v5/public/" + category  # linear
        logd(
            "websocket wss://"
            + host
            + ":"
            + port
            + path
            + " isPrivate="
            + str(is_private)
            + " accessKey="
            + self._access_key
            + " secretKey="
            + self._secret_key
        )

        var host_ = to_schar_ptr(host)
        var port_ = to_schar_ptr(port)
        var path_ = to_schar_ptr(path)
        var ptr = seq_websocket_new(
            host_,
            port_,
            path_,
            TLS1_3_VERSION,
        )
        host_.free()
        port_.free()
        path_.free()
        register_websocket(ptr)
        logd("BybitWS.register_websocket ws=" + str(ptr))
        self._ptr = ptr
        self._id = seq_voidptr_to_int(ptr)
        self._heartbeat_time = UnsafePointer[Int64].alloc(1)
        self._heartbeat_time[0] = 0
        self._is_subscribed = False
        self._verbose = False

    fn __moveinit__(inout self, owned existing: Self):
        print("BybitWS.__moveinit__")
        self._ptr = existing._ptr
        self._id = existing._id
        self._is_private = existing._is_private
        self._access_key = existing._access_key
        self._secret_key = existing._secret_key
        self._category = existing._category
        self._subscription_topics = existing._subscription_topics
        self._subscription_topics_str = existing._subscription_topics_str
        self._heartbeat_time = existing._heartbeat_time
        self._is_subscribed = existing._is_subscribed
        self._verbose = existing._verbose

    fn __del__(owned self):
        logd("BybitWS.__del__")

    # fn __copyinit__(inout self, existing: Self):
    #     logd("BybitWS.__copyinit__")
    #     self._ptr = existing._ptr
    #     self._id = existing._id
    #     self._is_private = existing._is_private
    #     self._access_key = existing._access_key
    #     self._secret_key = existing._secret_key
    #     self._category = existing._category
    #     self._subscription_topics = existing._subscription_topics
    #     self._subscription_topics_str = existing._subscription_topics_str
    #     logd(
    #         "BybitWS.__copyinit__ existing._subscription_topics_str: "
    #         + existing._subscription_topics_str
    #     )
    #     logd(
    #         "BybitWS.__copyinit__ self._subscription_topics_str: "
    #         + self._subscription_topics_str
    #     )

    # fn __moveinit__(inout self, owned existing: Self):
    #     logd("BybitWS.__moveinit__")
    #     self._ptr = existing._ptr
    #     self._id = existing._id
    #     self._is_private = existing._is_private
    #     self._access_key = existing._access_key
    #     self._secret_key = existing._secret_key
    #     self._category = existing._category
    #     self._subscription_topics = existing._subscription_topics
    #     self._subscription_topics_str = existing._subscription_topics_str
    #     logd(
    #         "BybitWS.__moveinit__ existing._subscription_topics_str: "
    #         + existing._subscription_topics_str
    #     )
    #     logd(
    #         "BybitWS.__moveinit__ self._subscription_topics_str: "
    #         + self._subscription_topics_str
    #     )

    fn set_verbose(inout self, verbose: Bool):
        self._verbose = verbose

    fn is_subscribed(self) -> Bool:
        return self._is_subscribed

    fn get_id(self) -> Int:
        return self._id

    fn set_on_connect(self, owned callback: on_connect_callback):
        var id = self.get_id()
        set_on_connect(id, callback^)

    fn set_on_heartbeat(self, owned callback: on_heartbeat_callback):
        var id = self.get_id()
        set_on_heartbeat(id, callback^)

    fn set_on_message(self, owned callback: on_message_callback):
        var id = self.get_id()
        set_on_message(id, callback^)

    fn set_subscription(inout self, topics: List[String]) raises:
        for topic in topics:
            logd("topic: " + topic[])
            self._subscription_topics.append(topic[])
            logd("len=" + str(len(self._subscription_topics)))

    fn subscribe(self):
        logd("BybitWS.subscribe")
        # logd("id=" + str(self._id))
        # logd("_subscription_topics_str=" + str(self._subscription_topics_str))
        # if len(self._subscription_topics) == 0:
        #     logd("BybitWS has no active subscriptions")
        #     return
        if self._subscription_topics_str == "":
            logd("BybitWS has no active subscriptions")
            return

        try:
            var id = seq_nanoid()
            var yy_doc = yyjson_mut_doc()
            yy_doc.add_str("req_id", id)
            yy_doc.add_str("op", "subscribe")
            var values = List[String]()
            var topics = self._subscription_topics_str.split(",")
            for topic in topics:
                values.append(topic[])
            yy_doc.arr_with_str("args", values)
            var body_str = yy_doc.mut_write()
            logd("send: " + body_str)
            self.send(body_str)
        except err:
            loge("subscribe err " + str(err))

    fn get_on_connect(self) -> on_connect_callback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper() -> None:
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
        logd("BybitWS.on_connect")
        self._heartbeat_time[0] = time_ms()
        if self._is_private:
            var param = self.generate_auth_payload()
            logd("auth: " + param)
            self.send(param)
        else:
            self.subscribe()

    fn generate_auth_payload(self) -> String:
        try:
            var ns = time_ns()
            var expires = str(int(ns / 1e6 + 5000))
            var req: String = "GET/realtime" + expires
            var hex_signature = hmac_sha256_hex(req, self._secret_key)

            # logd("expires=" + expires)
            # logd("req=" + req)
            # logd("hex_signature=" + hex_signature)

            var id = seq_nanoid()
            var yy_doc = yyjson_mut_doc()
            yy_doc.add_str("req_id", id)
            yy_doc.add_str("op", "auth")
            var args = List[String]()
            args.append(self._access_key)
            args.append(expires)
            args.append(hex_signature)
            yy_doc.arr_with_str("args", args)
            var body_str = yy_doc.mut_write()
            return body_str
        except err:
            loge("generate_auth_payload error=" + str(err))
            return ""

    fn on_heartbeat(self) -> None:
        # logd("BybitWS.on_heartbeat")
        var elapsed_time = time_ms() - self._heartbeat_time[0]
        if elapsed_time <= 5000:
            # logd("BybitWS.on_heartbeat ignore [" + str(elapsed_time) + "]")
            return

        var id = seq_nanoid()

        var yy_doc = yyjson_mut_doc()
        yy_doc.add_str("req_id", id)
        yy_doc.add_str("op", "ping")
        var body_str = yy_doc.mut_write()
        # logd("send: " + body_str)
        self.send(body_str)

    fn on_message(inout self, s: String) -> None:
        # logd("BybitWS::on_message: " + s)
        if self._verbose:
            logd("BybitWS::on_message: " + s)

        # {"req_id":"LzIP5BH2aBVLUkmsOzg-q","success":true,"ret_msg":"","op":"auth","conn_id":"cldfn01dcjmj8l28s6sg-ngkux"}
        # {"req_id":"74z-iUiWshWGFAyIWQBxk","success":true,"ret_msg":"","op":"subscribe","conn_id":"cl9i0rtdaugsu2kfn8ng-3084a"}
        # {"req_id":"VCKnRAeA6qrQXS8H94a-_","op":"pong","args":["1703683273204"],"conn_id":"cl9i0rtdaugsu2kfn8ng-3aqxh"}

        var parser = OndemandParser(ParserBufferSize)
        var doc = parser.parse(s)
        var op = doc.get_str("op")
        if op == "auth":
            var success = doc.get_bool("success")
            if success:
                logi("WebSocket authentication successful")
                self.subscribe()
            else:
                logw("WebSocket authentication failed")
        elif op == "subscribe":
            var success = doc.get_bool("success")
            if success:
                # 设置状态
                self._is_subscribed = True
                logi("WebSocket subscription successful")
            else:
                logw("WebSocket subscription failed")
        elif op == "pong":
            pass

        _ = doc^
        _ = parser^

    fn release(self) -> None:
        seq_websocket_delete(self._ptr)

    fn send(self, text: String) -> None:
        seq_websocket_send(
            self._ptr,
            str_as_scalar_pointer(text),
            len(text),
        )

    fn connect(self):
        seq_websocket_connect(self._ptr)

    fn disconnect(self):
        seq_websocket_disconnect(self._ptr)
