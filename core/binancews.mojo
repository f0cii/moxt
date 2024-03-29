from ylstdlib.time import time_ns
from base.globals import *
from base.websocket import *
from base.yyjson import yyjson_doc, yyjson_mut_doc
from base.sj_ondemand import OndemandParser
from base.containers import ObjectContainer
from base.websocket import OnConnectWrapper, OnHeartbeatWrapper, OnMessageWrapper
from .sign import hmac_sha256_hex
from .binanceclient import BinanceClient


alias ParserBufferSize = 1000 * 100


struct BinanceWS:
    """
    Reference document: https://binance-docs.github.io/apidocs/futures/en/
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

        var host: String = "stream.binancefuture.com" if testnet else "fstream.binance.com"
        var port: String = "443"
        var path: String = ""

        if is_private:
            var listen_key = self._client.generate_listen_key()
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
        self._ptr = ptr
        self._id = seq_voidptr_to_int(ptr)
        self._heartbeat_time = Pointer[Int64].alloc(1)
        self._heartbeat_time.store(0)

    fn __del__(owned self):
        print("BinanceWS.__del__")

    fn get_id(self) -> Int:
        return self._id

    fn set_on_connect(self, owned wrapper: OnConnectWrapper):
        var id = self.get_id()
        var coc_ptr = get_global_pointer(WS_ON_CONNECT_WRAPPER_PTR_KEY)
        var coc_any_ptr = AnyPointer[ObjectContainer[OnConnectWrapper]].__from_index(
            coc_ptr
        )
        var wrapper_ptr = coc_any_ptr[].emplace_as_index(wrapper)
        seq_set_global_int(id, wrapper_ptr)

    fn set_on_heartbeat(self, owned wrapper: OnHeartbeatWrapper):
        var id = self.get_id()
        var coc_ptr = get_global_pointer(WS_ON_HEARTBEAT_WRAPPER_PTR_KEY)
        var coc_any_ptr = AnyPointer[ObjectContainer[OnHeartbeatWrapper]].__from_index(
            coc_ptr
        )
        var wrapper_ptr = coc_any_ptr[].emplace_as_index(wrapper)
        seq_set_global_int(id, wrapper_ptr)

    fn set_on_message(self, owned wrapper: OnMessageWrapper):
        var id = self.get_id()
        var coc_ptr = get_global_pointer(WS_ON_MESSAGE_WRAPPER_PTR_KEY)
        var coc_any_ptr = AnyPointer[ObjectContainer[OnMessageWrapper]].__from_index(
            coc_ptr
        )
        var wrapper_ptr = coc_any_ptr[].emplace_as_index(wrapper)
        seq_set_global_int(id, wrapper_ptr)

    fn subscribe(self):
        logd("BinanceWS.subscribe")

    fn get_on_connect(self) -> on_connect_callback:
        # var self_ptr = Reference(self).get_unsafe_pointer()

        fn wrapper():
            # self_ptr[].on_connect()
            pass

        return wrapper

    fn get_on_heartbeat(self) -> on_heartbeat_callback:
        # var self_ptr = Reference(self).get_unsafe_pointer()

        fn wrapper():
            # self_ptr[].on_heartbeat()
            pass

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
        var elapsed_time = time_ms() - self._heartbeat_time.load()
        if elapsed_time <= 1000 * 60 * 5:
            # logd("BinanceWS.on_heartbeat ignore [" + str(elapsed_time) + "]")
            return

        # For private subscriptions, listen_key renewal needs to be done within 60 minutes
        if self._is_private:
            try:
                var ret = self._client.extend_listen_key()
                logi("Renewal of listen_key returns: " + str(ret))
                self._heartbeat_time.store(time_ms())
            except err:
                loge("Renewal of listen_key encountered an error: " + str(err))

    fn on_message(self, s: String) -> None:
        logd("BinanceWS::on_message: " + s)

        # {"e":"ORDER_TRADE_UPDATE","T":1704459987707,"E":1704459987709,"o":{"s":"BTCUSDT","c":"web_w4Sot5R1ym9ChzWfGdAm","S":"BUY","o":"LIMIT","f":"GTC","q":"0.010","p":"20000","ap":"0","sp":"0","x":"NEW","X":"NEW","i":238950797096,"l":"0","z":"0","L":"0","n":"0","N":"USDT","T":1704459987707,"t":0,"b":"200","a":"0","m":false,"R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"LONG","cp":false,"rp":"0","pP":false,"si":0,"ss":0,"V":"NONE","pm":"NONE","gtd":0}}
        # {"e":"ORDER_TRADE_UPDATE","T":1704460185744,"E":1704460185746,"o":{"s":"BTCUSDT","c":"web_w4Sot5R1ym9ChzWfGdAm","S":"BUY","o":"LIMIT","f":"GTC","q":"0.010","p":"20000","ap":"0","sp":"0","x":"CANCELED","X":"CANCELED","i":238950797096,"l":"0","z":"0","L":"0","n":"0","N":"USDT","T":1704460185744,"t":0,"b":"0","a":"0","m":false,"R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"LONG","cp":false,"rp":"0","pP":false,"si":0,"ss":0,"V":"NONE","pm":"NONE","gtd":0}}

        # var parser = OndemandParser(ParserBufferSize)
        # var doc = parser.parse(s)

        # _ = doc ^
        # _ = parser ^

    fn release(self) -> None:
        seq_websocket_delete(self._ptr)

    fn send(self, text: String) -> None:
        seq_websocket_send(self._ptr, text._buffer.data.value, len(text))

    fn connect(self):
        seq_websocket_connect(self._ptr)
