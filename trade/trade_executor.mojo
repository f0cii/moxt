from stdlib_extensions.builtins.string import __str_contains__
from base.sj_ondemand import *
from base.sj_dom import *
from core.bybitclient import BybitClient
from core.bybitmodel import *
from core.bybitws import *
from .config import AppConfig
from .data_handler import DataHandler
from .base_strategy import *


alias ParserBufferSize = 1000 * 100


struct TradeExecutor[T: BaseStrategy]:
    var _client: BybitClient
    var _public_ws: BybitWS
    var _private_ws: BybitWS
    var _strategy: T

    fn __init__(inout self, config: AppConfig, inout strategy: T) raises:
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
            category=config.category,
            topics=public_topic,  # "orderbook.1.BTCUSDT",
        )
        let private_topic = "position,execution,order,wallet"
        self._private_ws = BybitWS(
            is_private=True,
            testnet=config.testnet,
            access_key=config.access_key,
            secret_key=config.secret_key,
            category=config.category,
            topics=private_topic,
        )
        self._strategy = strategy^
    
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
        self._public_ws.connect()

    fn stop(self):
        logi("TradeExecutor.stop")

    fn get_private_on_message(self) -> on_message_callback:
        @parameter
        fn wrapper(data: c_char_pointer, data_len: Int):
            self.on_private_message(data, data_len)

        return wrapper

    fn get_public_on_message(self) -> on_message_callback:
        @parameter
        fn wrapper(data: c_char_pointer, data_len: Int):
            self.on_public_message(data, data_len)

        return wrapper

    fn on_private_message(self, data: c_char_pointer, data_len: Int):
        let s = c_str_to_string(data, data_len)
        logi("on_private_message message: " + s)
        let parser = OndemandParser(ParserBufferSize)
        var doc = parser.parse(s)
        let topic = doc.get_str("topic")

        if topic == "order":
            self.process_order_message(doc)
        elif topic == "position":
            self.process_position_message(doc)
        elif topic == "execution":
            pass
        elif topic == "wallet":
            pass
        elif topic != "":
            return

        _ = doc
        _ = parser

        let msg = s

        self._private_ws.on_message(msg)

    fn on_public_message(self, data: c_char_pointer, data_len: Int):
        try:
            let s = c_str_to_string(data, data_len)
            logi("on_public_message message: " + s)

            let parser = DomParser(ParserBufferSize)
            var doc = parser.parse(s)
            let topic = doc.get_str("topic")

            if __str_contains__("orderbook.", topic):
                self.process_orderbook_message(doc)

            _ = doc
            _ = parser
        except err:
            loge("on_public_message error: " + str(err))
            _ = exit(0)
    
    fn process_orderbook_message(self, inout doc: DomElement) -> None:
        # logd("process_orderbook_message")
        # {"topic":"orderbook.1.BTCUSDT","type":"snapshot","ts":1702645020909,"data":{"s":"BTCUSDT","b":[["42663.50","0.910"]],"a":[["42663.60","11.446"]],"u":2768099,"seq":108881526829},"cts":1702645020906}
        # {"topic":"orderbook.1.BTCUSDT","type":"snapshot","ts":1703834857207,"data":{"s":"BTCUSDT","b":[["42489.90","130.419"]],"a":[["42493.80","132.979"]],"u":326106,"seq":8817548764},"cts":1703834853055}
        let type_ = doc.get_str("type")
        let data = doc.get_object("data")
        # logd("type_: " + type_) # snapshot,delta

        let a = data.get_array("a")
        let a_iter = a.iter()

        var asks = list[OrderBookLevel]()
        var bids = list[OrderBookLevel]()

        while a_iter.has_element():
            let a_obj = a_iter.get()
            let a_arr = a_obj.array()
            let price = a_arr.at_str(0)
            let qty = a_arr.at_str(1)
            # logd("price: " + str(price))
            # logd("qty: " + str(qty))
            asks.append(OrderBookLevel(price, qty))
            _ = a_obj
            a_iter.step()

        _ = a
        
        let b = data.get_array("b")
        let b_iter = b.iter()

        while b_iter.has_element():
            let b_obj = b_iter.get()
            let b_arr = b_obj.array()
            let price = b_arr.at_str(0)
            let qty = b_arr.at_str(1)
            # logd("price: " + str(price))
            # logd("qty: " + str(qty))
            bids.append(OrderBookLevel(Fixed(price), Fixed(qty)))
            _ = b_obj
            b_iter.step()

        _ = b
        _ = data

        # logd("asks=" + str(len(asks)) + " bids=" + str(len(bids)))

        self._strategy.update_orderbook(type_, asks, bids)

        let ob = self._strategy.get_orderbook(5)
        self._strategy.on_orderbook(ob)

        # logd("process_orderbook_message done")

    fn process_order_message(self, inout doc: OndemandDocument) -> None:
        let data = doc.get_array("data")

        let iter = data.iter()
        while iter.has_value():
            let item = iter.get_object()
            let posIdx = item.get_int("positionIdx")
            let orderId = item.get_str("orderId")
            let sym = item.get_str("symbol")
            let side = item.get_str("side")
            let orderType = item.get_str("orderType")
            let price = strtod(item.get_str("price"))
            let qty = strtod(item.get_str("qty"))
            let cumExecQty = strtod(item.get_str("cumExecQty"))
            let orderStatus = item.get_str("orderStatus")
            let createdTime = item.get_str("createdTime")
            let updatedTime = item.get_str("updatedTime")
            let avgPrice = strtod(item.get_str("avgPrice"))
            let cumExecFee = strtod(item.get_str("cumExecFee"))
            let tif = item.get_str("timeInForce")
            let reduceOnly = item.get_bool("reduceOnly")
            let orderLinkId = item.get_str("orderLinkId")

            let order_info =
                OrderInfo(posIdx, orderId, sym, side, orderType, price, qty,
                        cumExecQty, orderStatus, createdTime, updatedTime,
                        avgPrice, cumExecFee, tif, reduceOnly, orderLinkId)
            logd("order_info: " + str(order_info))

            iter.step()

        _ = data
        
    fn process_position_message(self, inout doc: OndemandDocument) -> None:
        let data = doc.get_array("data")

        var positions = list[PositionInfo]()

        let iter = data.iter()
        while iter.has_value():
            let item = iter.get_object()
            let posIdx = item.get_int("positionIdx")
            let sym = item.get_str("symbol")
            let side = item.get_str("side")
            let size = item.get_str("size")
            let avgPrice = item.get_str("entryPrice")
            let positionValue = item.get_str("positionValue")
            let leverage = item.get_float("leverage")
            let markPrice = item.get_str("markPrice")
            let positionMM = item.get_str("positionMM")
            let positionIM = item.get_str("positionIM")
            let takeProfit = item.get_str("takeProfit")
            let stopLoss = item.get_str("stopLoss")
            let unrealisedPnl = item.get_str("unrealisedPnl")
            let cumRealisedPnl = item.get_str("cumRealisedPnl")
            let createdTime = item.get_str("createdTime")
            let updatedTime = item.get_str("updatedTime")
            let position_info = PositionInfo(
                posIdx,
                sym,
                side,
                size,
                avgPrice,
                positionValue,
                leverage,
                markPrice,
                positionMM,
                positionIM,
                takeProfit,
                stopLoss,
                unrealisedPnl,
                cumRealisedPnl,
                createdTime,
                updatedTime,
            )
            positions.append(position_info)
            logd("postion_info: " + str(position_info))
            iter.step()

        _ = data
