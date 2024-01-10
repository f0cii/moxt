from stdlib_extensions.builtins import dict, list, HashableInt
from stdlib_extensions.builtins.string import *
from stdlib_extensions.time import time_ns
from base.websocket import *
from base.yyjson import yyjson_doc, yyjson_mut_doc
from base.sj_ondemand import OndemandParser
from .sign import hmac_sha256_hex
from .binanceclient import BinanceClient


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
    var _topics_str: String
    var _heartbeat_time: Pointer[Int64]
    var _client: BinanceClient

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
        self._topics_str = topics
        self._client = BinanceClient(testnet, access_key, secret_key)

        let host: String = "stream.binancefuture.com" if testnet else "fstream.binance.com"
        let port: String = "443"
        var path: String = ""

        if is_private:
            let listen_key = self._client.generate_listen_key()
            logi("listen_key=" + listen_key)
            path = "/ws/" + listen_key
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
        self._ptr = ptr
        self._id = seq_voidptr_to_int(ptr)
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

    fn subscribe(self):
        logd("BinanceWS.subscribe")

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
            pass
        else:
            self.subscribe()

    fn on_heartbeat(self) -> None:
        # logd("BinanceWS.on_heartbeat")
        let elapsed_time = time_ms() - self._heartbeat_time.load()
        if elapsed_time <= 1000 * 60 * 5:
            # logd("BinanceWS.on_heartbeat ignore [" + str(elapsed_time) + "]")
            return

        # 私有订阅，这里要在60分钟内进行listen_key续订
        if self._is_private:
            try:
                let ret = self._client.extend_listen_key()
                logi("续订listen_key返回: " + str(ret))
                self._heartbeat_time.store(time_ms())
            except err:
                loge("续订listen_key出错: " + str(err))

    fn on_message(self, s: String) -> None:
        logd("BinanceWS::on_message: " + s)

        # 下单后事件
        # {"e":"ORDER_TRADE_UPDATE","T":1704459987707,"E":1704459987709,"o":{"s":"BTCUSDT","c":"web_w4Sot5R1ym9ChzWfGdAm","S":"BUY","o":"LIMIT","f":"GTC","q":"0.010","p":"20000","ap":"0","sp":"0","x":"NEW","X":"NEW","i":238950797096,"l":"0","z":"0","L":"0","n":"0","N":"USDT","T":1704459987707,"t":0,"b":"200","a":"0","m":false,"R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"LONG","cp":false,"rp":"0","pP":false,"si":0,"ss":0,"V":"NONE","pm":"NONE","gtd":0}}
        # 撤单
        # {"e":"ORDER_TRADE_UPDATE","T":1704460185744,"E":1704460185746,"o":{"s":"BTCUSDT","c":"web_w4Sot5R1ym9ChzWfGdAm","S":"BUY","o":"LIMIT","f":"GTC","q":"0.010","p":"20000","ap":"0","sp":"0","x":"CANCELED","X":"CANCELED","i":238950797096,"l":"0","z":"0","L":"0","n":"0","N":"USDT","T":1704460185744,"t":0,"b":"0","a":"0","m":false,"R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"LONG","cp":false,"rp":"0","pP":false,"si":0,"ss":0,"V":"NONE","pm":"NONE","gtd":0}}

        # let parser = OndemandParser(ParserBufferSize)
        # let doc = parser.parse(s)

        # _ = doc ^
        # _ = parser ^

    fn release(self) -> None:
        seq_websocket_delete(self._ptr)

    fn send(self, text: String) -> None:
        seq_websocket_send(self._ptr, text._buffer.data.value, len(text))

    fn connect(self):
        seq_websocket_connect(self._ptr)
