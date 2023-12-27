from core.bybitclient import BybitClient
from core.bybitws import *
from .config import AppConfig


@value
struct TradeExecutor:
    var _client: BybitClient
    var _public_ws: BybitWS
    var _private_ws: BybitWS

    fn __init__(inout self, config: AppConfig) raises:
        self._client = BybitClient(
            testnet=config.testnet,
            access_key=config.access_key,
            secret_key=config.secret_key,
        )
        let public_topic: String = "orderbook." + str(
            config.depth
        ) + "." + config.symbol
        self._public_ws = BybitWS(
            is_private=False,
            testnet=config.testnet,
            access_key="",
            secret_key="",
            category="linear",
            topics=public_topic,  # "orderbook.1.BTCUSDT",
        )
        let private_topic = "position,execution,order,wallet"
        self._private_ws = BybitWS(
            is_private=True,
            testnet=config.testnet,
            access_key=config.access_key,
            secret_key=config.secret_key,
            category="linear",
            topics=private_topic,
        )

    fn start(self):
        var on_connect_private = self._private_ws.get_on_connect()
        var on_heartbeat_private = self._private_ws.get_on_heartbeat()
        var on_message_private = self.get_private_on_message()

        self._private_ws.set_on_connect(
            Pointer[on_connect_callback].address_of(on_connect_private)
        )
        self._private_ws.set_on_heartbeat(
            Pointer[on_heartbeat_callback].address_of(on_heartbeat_private)
        )
        self._private_ws.set_on_message(
            Pointer[on_message_callback].address_of(on_message_private)
        )

        var on_connect_public = self._public_ws.get_on_connect()
        var on_heartbeat_public = self._public_ws.get_on_heartbeat()
        var on_message_public = self.get_public_on_message()

        self._public_ws.set_on_connect(
            Pointer[on_connect_callback].address_of(on_connect_public)
        )
        self._public_ws.set_on_heartbeat(
            Pointer[on_heartbeat_callback].address_of(on_heartbeat_public)
        )
        self._public_ws.set_on_message(
            Pointer[on_message_callback].address_of(on_message_public)
        )

        self._private_ws.connect()
        # self._public_ws.connect()

    fn stop(self):
        logi("TradeExecutor.stop")

    fn get_private_on_message(self) -> on_message_callback:
        fn wrapper(data: c_char_pointer, data_len: Int):
            self.on_private_message(data, data_len)

        return wrapper

    fn get_public_on_message(self) -> on_message_callback:
        fn wrapper(data: c_char_pointer, data_len: Int):
            self.on_public_message(data, data_len)

        return wrapper

    fn on_private_message(self, data: c_char_pointer, data_len: Int):
        let s = c_str_to_string(data, data_len)
        logi("on_private_message message: " + s)
        self._private_ws.on_message(s)

    fn on_public_message(self, data: c_char_pointer, data_len: Int):
        let s = c_str_to_string(data, data_len)
        logi("on_public_message message: " + s)
