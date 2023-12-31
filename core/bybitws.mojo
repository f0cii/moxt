from base.websocket import *
from base.yyjson import yyjson_doc, yyjson_mut_doc
from stdlib_extensions.builtins import dict, list, HashableInt
from stdlib_extensions.builtins.string import *
from core.sign import hmac_sha256_hex
from stdlib_extensions.time import time_ns
from base.sj_ondemand import OndemandParser


alias ParserBufferSize = 1000 * 100


@value
struct BybitWS:
    var _ptr: c_void_pointer
    var _id: Int
    var _is_private: Bool
    var _access_key: String
    var _secret_key: String
    var _category: String
    var _subscription_topics: list[String]
    var _subscription_topics_str: String
    var _heartbeat_time: Pointer[Int64]

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
        self._subscription_topics = list[String]()
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
        )

        let host_ = to_schar_ptr(host)
        let port_ = to_schar_ptr(port)
        let path_ = to_schar_ptr(path)
        let ptr = seq_websocket_new(
            host_,
            port_,
            path_,
            TLS1_3_VERSION,
        )
        host_.free()
        port_.free()
        path_.free()
        register_websocket(ptr)
        # logd("ws._ptr=" + str(seq_address_of(ptr)))
        self._ptr = ptr
        self._id = seq_address_of(ptr)
        self._heartbeat_time = Pointer[Int64].alloc(1)
        self._heartbeat_time.store(0)

    fn __del__(owned self):
        print("BybitWS.__del__")

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

    fn get_id(self) -> Int:
        return self._id

    fn set_on_connect(self, callback: Pointer[on_connect_callback]):
        let id = self.get_id()
        let ptr = callback.__as_index()
        set_on_connect(id, ptr)

    fn set_on_heartbeat(self, callback: Pointer[on_heartbeat_callback]):
        let id = self.get_id()
        let ptr = callback.__as_index()
        set_on_heartbeat(id, ptr)

    fn set_on_message(self, callback: Pointer[on_message_callback]):
        let id = self.get_id()
        let ptr = callback.__as_index()
        set_on_message(id, ptr)

    fn set_subscription(inout self, topics: list[String]) raises:
        for topic in topics:
            logd("topic: " + topic)
            self._subscription_topics.append(topic)
            logd("len=" + str(len(self._subscription_topics)))

    fn subscribe(self):
        logd("BybitWS.subscribe")
        # logd("id=" + str(self._id))
        # logd("_subscription_topics_str=" + str(self._subscription_topics_str))
        # if len(self._subscription_topics) == 0:
        #     logd("BybitWS 没有任何订阅")
        #     return
        if self._subscription_topics_str == "":
            logd("BybitWS 没有任何订阅")
            return

        try:
            let id = seq_nanoid()
            var yy_doc = yyjson_mut_doc()
            yy_doc.add_str("req_id", id)
            yy_doc.add_str("op", "subscribe")
            var values = list[String]()
            let topics = split(self._subscription_topics_str, ",")
            for topic in topics:
                values.append(topic)
            yy_doc.arr_with_str("args", values)
            let body_str = yy_doc.mut_write()
            logd("send: " + body_str)
            self.send(body_str)
        except err:
            loge("subscribe err " + str(err))

    fn get_on_connect(self) -> on_connect_callback:
        fn wrapper():
            self.on_connect()

        return wrapper

    fn get_on_heartbeat(self) -> on_heartbeat_callback:
        fn wrapper():
            self.on_heartbeat()

        return wrapper

    # fn get_on_message(self) -> on_message_callback:
    #     fn wrapper(data: c_char_pointer, data_len: Int):
    #         self.on_message(data, data_len)

    #     return wrapper

    fn on_connect(self) -> None:
        logd("BybitWS.on_connect")
        self._heartbeat_time.store(time_ms())
        if self._is_private:
            let param = self.generate_auth_payload()
            # logd("auth: " + param)
            self.send(param)
        else:
            self.subscribe()

    fn generate_auth_payload(self) -> String:
        try:
            let expires = str(time_ns() / 1e6 + 5000)
            let req: String = "GET/realtime" + expires
            let hex_signature = hmac_sha256_hex(req, self._secret_key)

            # logd("expires=" + expires)
            # logd("req=" + req)
            # logd("hex_signature=" + hex_signature)

            let id = seq_nanoid()
            var yy_doc = yyjson_mut_doc()
            yy_doc.add_str("req_id", id)
            yy_doc.add_str("op", "auth")
            var args = list[String]()
            args.append(self._access_key)
            args.append(expires)
            args.append(hex_signature)
            yy_doc.arr_with_str("args", args)
            let body_str = yy_doc.mut_write()
            return body_str
        except err:
            loge("generate_auth_payload error=" + str(err))
            return ""

    fn on_heartbeat(self) -> None:
        logd("BybitWS.on_heartbeat")
        let elapsed_time = time_ms() - self._heartbeat_time.load()
        if elapsed_time <= 5000:
            # logd("BybitWS.on_heartbeat ignore [" + str(elapsed_time) + "]")
            return

        let id = seq_nanoid()

        var yy_doc = yyjson_mut_doc()
        yy_doc.add_str("req_id", id)
        yy_doc.add_str("op", "ping")
        let body_str = yy_doc.mut_write()
        # logd("send: " + body_str)
        self.send(body_str)

    fn on_message(self, s: String) -> None:
        logd("BybitWS::on_message: " + s)
        # 认证成功
        # {"req_id":"LzIP5BH2aBVLUkmsOzg-q","success":true,"ret_msg":"","op":"auth","conn_id":"cldfn01dcjmj8l28s6sg-ngkux"}

        # 订阅成功
        # {"req_id":"74z-iUiWshWGFAyIWQBxk","success":true,"ret_msg":"","op":"subscribe","conn_id":"cl9i0rtdaugsu2kfn8ng-3084a"}

        # pong 消息
        # {"req_id":"VCKnRAeA6qrQXS8H94a-_","op":"pong","args":["1703683273204"],"conn_id":"cl9i0rtdaugsu2kfn8ng-3aqxh"}

        let parser = OndemandParser(ParserBufferSize)
        let doc = parser.parse(s)
        let op = doc.get_str("op")
        if op == "auth":
            let success = doc.get_bool("success")
            if success:
                logi("ws认证成功")
                self.subscribe()
            else:
                logw("ws认证失败")
        elif op == "pong":
            pass

        _ = doc
        _ = parser

    fn release(self) -> None:
        seq_websocket_delete(self._ptr)

    fn send(self, text: String) -> None:
        seq_websocket_send(self._ptr, text._buffer.data.value, len(text))

    fn connect(self):
        seq_websocket_connect(self._ptr)
