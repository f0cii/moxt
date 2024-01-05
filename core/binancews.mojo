from base.websocket import *
from base.yyjson import yyjson_doc, yyjson_mut_doc
from stdlib_extensions.builtins import dict, list, HashableInt
from stdlib_extensions.builtins.string import *
from core.sign import hmac_sha256_hex
from stdlib_extensions.time import time_ns
from base.sj_ondemand import OndemandParser


alias ParserBufferSize = 1000 * 100


struct BinanceWS:
    # btcusdt@aggTrade
    # 订阅盘口5/10/20档
    # btcusdt@depth5
    """
    参考文档: https://binance-docs.github.io/apidocs/futures/cn/#135f59a54a
    stream名称中所有交易对均为小写。
    每个链接有效期不超过24小时，请妥善处理断线重连。
    服务端每3分钟会发送ping帧，客户端应当在10分钟内回复pong帧，否则服务端会主动断开链接。允许客户端发送不成对的pong帧(即客户端可以以高于15分钟每次的频率发送pong帧保持链接)。
    Websocket服务器每秒最多接受10个订阅消息。
    如果用户发送的消息超过限制，连接会被断开连接。反复被断开连接的IP有可能被服务器屏蔽。
    单个连接最多可以订阅 200 个Streams。
    """
    var _ptr: c_void_pointer
    var _id: Int
    var _is_private: Bool
    var _access_key: String
    var _secret_key: String
    var _subscription_topics: list[String]
    var _subscription_topics_str: String
    var _heartbeat_time: Pointer[Int64]

    fn __init__(
        inout self,
        is_private: Bool,
        testnet: Bool,
        access_key: String,
        secret_key: String,
        topics: String = "",
    ) raises:
        self._is_private = is_private
        self._access_key = access_key
        self._secret_key = secret_key
        self._subscription_topics = list[String]()
        self._subscription_topics_str = topics

        var host: String = ""
        var port: String = ""
        var path: String = ""
        if testnet:
            host = "stream.binancefuture.com"
        else:
            host = "fstream.binance.com"
        port = "443"
        if is_private:
            path = "/ws"
        else:
            path = "/stream?streams=" + topics
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
        print("BinanceWS.__del__")

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
        logd("BinanceWS.subscribe")
        # if self._subscription_topics_str == "":
        #     logd("BinanceWS 没有任何订阅")
        #     return

        # try:
        #     let id = seq_nanoid()
        #     var yy_doc = yyjson_mut_doc()
        #     yy_doc.add_str("req_id", id)
        #     yy_doc.add_str("op", "subscribe")
        #     var values = list[String]()
        #     let topics = split(self._subscription_topics_str, ",")
        #     for topic in topics:
        #         values.append(topic)
        #     yy_doc.arr_with_str("args", values)
        #     let body_str = yy_doc.mut_write()
        #     logd("send: " + body_str)
        #     self.send(body_str)
        # except err:
        #     loge("subscribe err " + str(err))

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

    fn on_connect(self) -> None:
        logd("BinanceWS.on_connect")
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
        # logd("BinanceWS.on_heartbeat")
        let elapsed_time = time_ms() - self._heartbeat_time.load()
        if elapsed_time <= 5000:
            # logd("BinanceWS.on_heartbeat ignore [" + str(elapsed_time) + "]")
            return

        # let id = seq_nanoid()

        # var yy_doc = yyjson_mut_doc()
        # yy_doc.add_str("req_id", id)
        # yy_doc.add_str("op", "ping")
        # let body_str = yy_doc.mut_write()
        # # logd("send: " + body_str)
        # self.send(body_str)

    fn on_message(self, s: String) -> None:
        logd("BinanceWS::on_message: " + s)
        
        # let parser = OndemandParser(ParserBufferSize)
        # let doc = parser.parse(s)
        # let op = doc.get_str("op")
        # if op == "auth":
        #     let success = doc.get_bool("success")
        #     if success:
        #         logi("ws认证成功")
        #         self.subscribe()
        #     else:
        #         logw("ws认证失败")
        # elif op == "pong":
        #     pass

        # _ = doc
        # _ = parser

    fn release(self) -> None:
        seq_websocket_delete(self._ptr)

    fn send(self, text: String) -> None:
        seq_websocket_send(self._ptr, text._buffer.data.value, len(text))

    fn connect(self):
        seq_websocket_connect(self._ptr)
