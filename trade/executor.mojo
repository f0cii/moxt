from os.atomic import Atomic
from stdlib_extensions.builtins.string import __str_contains__, split
from base.sj_ondemand import *
from base.sj_dom import *
from base.thread import *
from core.bybitclient import BybitClient
from core.bybitmodel import *
from core.bybitws import *
from base.mo import logd, logi, logw, loge
from .config import AppConfig
from .platform import *
from .base_strategy import *


alias ParserBufferSize = 1000 * 100


trait Runable:
    fn run(inout self):
        ...


trait IExecutor:
    fn start(inout self) raises:
        ...

    fn stop_now(inout self):
        ...

    fn run(inout self):
        ...

    fn perform_tasks(inout self):
        ...


struct Executor[T: BaseStrategy](Movable, Runable, IExecutor):
    var _client: BybitClient
    var _public_ws: BybitWS
    var _private_ws: BybitWS
    var _strategy: T
    var _is_initialized: AtomicBool
    var _is_running: AtomicBool  # Is it currently running
    var _stop_requested: AtomicBool  # Indicate whether a stop request has been received
    var _is_stopped: AtomicBool  # Has it already ceased
    var _platform: Pointer[Platform]

    fn __init__(inout self, config: AppConfig, owned strategy: T) raises:
        self._client = BybitClient(
            testnet=config.testnet,
            access_key=config.access_key,
            secret_key=config.secret_key,
        )
        var symbols = split(config.symbols, ",")
        var public_topics = String("")
        for sym in symbols:
            if public_topics != "":
                public_topics += ","
            public_topics += "orderbook." + str(config.depth) + "." + sym
        self._public_ws = BybitWS(
            is_private=False,
            testnet=config.testnet,
            access_key="",
            secret_key="",
            category=config.category,
            topics=public_topics,  # "orderbook.1.BTCUSDT",
        )
        var private_topic = "position,execution,order,wallet"
        self._private_ws = BybitWS(
            is_private=True,
            testnet=config.testnet,
            access_key=config.access_key,
            secret_key=config.secret_key,
            category=config.category,
            topics=private_topic,
        )
        self._strategy = strategy ^
        self._is_initialized = AtomicBool(False)
        self._is_running = AtomicBool(False)
        self._stop_requested = AtomicBool(False)
        self._is_stopped = AtomicBool(False)
        self._platform = self._strategy.get_platform_pointer()

    fn __moveinit__(inout self, owned existing: Self):
        print("Executor.__moveinit__")
        self._client = existing._client ^
        self._public_ws = existing._public_ws ^
        self._private_ws = existing._private_ws ^
        self._strategy = existing._strategy ^
        self._is_initialized = AtomicBool(existing._is_initialized.load())
        self._is_running = AtomicBool(existing._is_running.load())
        self._stop_requested = AtomicBool(existing._stop_requested.load())
        self._is_stopped = AtomicBool(existing._is_stopped.load())
        self._platform = self._strategy.get_platform_pointer()

    fn start(inout self) raises:
        var on_connect_private = self._private_ws.get_on_connect()
        var on_heartbeat_private = self._private_ws.get_on_heartbeat()
        var on_message_private = self.get_private_on_message()

        self._private_ws.set_on_connect(on_connect_private)
        self._private_ws.set_on_heartbeat(on_heartbeat_private)
        self._private_ws.set_on_message(on_message_private)

        var on_connect_public = self._public_ws.get_on_connect()
        var on_heartbeat_public = self._public_ws.get_on_heartbeat()
        var on_message_public = self.get_public_on_message()

        self._public_ws.set_on_connect(on_connect_public)
        self._public_ws.set_on_heartbeat(on_heartbeat_public)
        self._public_ws.set_on_message(on_message_public)

        self._strategy.setup()

        self._strategy.on_init()

        self._private_ws.connect()
        self._public_ws.connect()

        # seq_photon_timer_new(1000 * 50, trade_executor_on_timer, True)

        self._is_initialized.store(True)
        self._is_running.store(True)
        self._stop_requested.store(False)
        self._is_stopped.store(False)

        logi("Executor started")

    fn stop_now(inout self):
        logi("Executor.stop")
        # Set stop flag
        self._stop_requested.store(True)
        self._private_ws.disconnect()
        self._public_ws.disconnect()
        # _ = sleep_ms(1000)
        try:
            self._strategy.on_exit()
            # self._private_ws.release()
            # self._public_ws.release()
        except err:
            loge("on_exit error: " + str(err))
        logi("Executor.stop done")

    # fn _get_ptr[T: Movable](inout self) -> AnyPointer[T]:
    #     # constrained[Self._check[T]() != -1, "not a union element type"]()
    #     var ptr = Pointer.address_of(self).address
    #     var result = AnyPointer[T]()
    #     result.value = __mlir_op.`pop.pointer.bitcast`[
    #         _type = __mlir_type[`!kgen.pointer<:`, Movable, ` `, T, `>`]
    #     ](ptr)
    #     return result

    fn get_private_on_message(inout self) -> on_message_callback:
        var self_ptr = Reference(self).get_unsafe_pointer()

        fn wrapper(data: c_char_pointer, data_len: Int):
            __get_address_as_lvalue(self_ptr.address).on_private_message(data, data_len)

        return wrapper

    fn get_public_on_message(inout self) -> on_message_callback:
        var self_ptr = Reference(self).get_unsafe_pointer()

        fn wrapper(data: c_char_pointer, data_len: Int):
            __get_address_as_lvalue(self_ptr.address).on_public_message(data, data_len)
            # var s = c_str_to_string(data, data_len)
            # logd("get_public_on_message message: " + s)

        return wrapper

    fn on_private_message(inout self, data: c_char_pointer, data_len: Int):
        var s = c_str_to_string(data, data_len)
        # logd("on_private_message message: " + s)
        var parser = OndemandParser(ParserBufferSize)
        var doc = parser.parse(s)
        var topic = doc.get_str("topic")

        if topic == "order":
            logi("order message: " + s)
            self.process_order_message(doc)
        elif topic == "position":
            logi("position message: " + s)
            self.process_position_message(doc)
        elif topic == "execution":
            pass
        elif topic == "wallet":
            pass
        elif topic != "":
            return

        _ = doc ^
        _ = parser ^

        self._private_ws.on_message(s)

    fn on_public_message(inout self, data: c_char_pointer, data_len: Int):
        try:
            var s = c_str_to_string(data, data_len)
            # logd("on_public_message message: " + s)

            var parser = DomParser(ParserBufferSize)
            var doc = parser.parse(s)
            # var doc = parser.parse(data, data_len)
            var topic = doc.get_str("topic")

            if __str_contains__("orderbook.", topic):
                self.process_orderbook_message(doc)

            _ = doc ^
            _ = parser ^
        except err:
            loge("on_public_message error: " + str(err))
            _ = exit(0)

    fn process_orderbook_message(inout self, inout doc: DomElement) raises -> None:
        # logd("process_orderbook_message")
        # {"topic":"orderbook.1.BTCUSDT","type":"snapshot","ts":1702645020909,"data":{"s":"BTCUSDT","b":[["42663.50","0.910"]],"a":[["42663.60","11.446"]],"u":2768099,"seq":108881526829},"cts":1702645020906}
        # {"topic":"orderbook.1.BTCUSDT","type":"snapshot","ts":1703834857207,"data":{"s":"BTCUSDT","b":[["42489.90","130.419"]],"a":[["42493.80","132.979"]],"u":326106,"seq":8817548764},"cts":1703834853055}
        var type_ = doc.get_str("type")
        var data = doc.get_object("data")
        # logd("type_: " + type_) # snapshot,delta
        var symbol = data.get_str("s")

        var a = data.get_array("a")
        var a_iter = a.iter()

        var asks = list[OrderBookLevel]()
        var bids = list[OrderBookLevel]()

        while a_iter.has_element():
            var a_obj = a_iter.get()
            var a_arr = a_obj.array()
            var price = a_arr.at_str(0)
            var qty = a_arr.at_str(1)
            # logd("price: " + str(price))
            # logd("qty: " + str(qty))
            asks.append(OrderBookLevel(price, qty))
            _ = a_obj ^
            a_iter.step()

        _ = a ^

        var b = data.get_array("b")
        var b_iter = b.iter()

        while b_iter.has_element():
            var b_obj = b_iter.get()
            var b_arr = b_obj.array()
            var price = b_arr.at_str(0)
            var qty = b_arr.at_str(1)
            # logd("price: " + str(price))
            # logd("qty: " + str(qty))
            bids.append(OrderBookLevel(Fixed(price), Fixed(qty)))
            _ = b_obj
            b_iter.step()

        _ = b ^
        _ = data ^

        # logd("asks=" + str(len(asks)) + " bids=" + str(len(bids)))

        __get_address_as_lvalue(self._platform.address).on_update_orderbook(
            symbol, type_, asks, bids
        )
        if self.is_initialized():
            var ob = __get_address_as_lvalue(self._platform.address).get_orderbook(
                symbol, 5
            )
            self._strategy.on_orderbook(ob)

        # logd("process_orderbook_message done")

    fn process_order_message(inout self, inout doc: OndemandDocument) -> None:
        var data = doc.get_array("data")

        var iter = data.iter()
        while iter.has_value():
            var item = iter.get_object()
            var posIdx = item.get_int("positionIdx")
            var orderId = item.get_str("orderId")
            var symbol = item.get_str("symbol")
            var side = item.get_str("side")
            var orderType = item.get_str("orderType")
            var price = strtod(item.get_str("price"))
            var qty = strtod(item.get_str("qty"))
            var cumExecQty = strtod(item.get_str("cumExecQty"))
            var orderStatus = item.get_str("orderStatus")
            var createdTime = item.get_str("createdTime")
            var updatedTime = item.get_str("updatedTime")
            var avgPrice = strtod(item.get_str("avgPrice"))
            var cumExecFee = strtod(item.get_str("cumExecFee"))
            var tif = item.get_str("timeInForce")
            var reduceOnly = item.get_bool("reduceOnly")
            var orderLinkId = item.get_str("orderLinkId")

            # var order_info =
            #     OrderInfo(posIdx, orderId, sym, side, orderType, price, qty,
            #             cumExecQty, orderStatus, createdTime, updatedTime,
            #             avgPrice, cumExecFee, tif, reduceOnly, orderLinkId)
            # logd("order_info: " + str(order_info))

            var order = Order(
                symbol=symbol,
                order_type=orderType,
                order_client_id=orderLinkId,
                order_id=orderId,
                price=Fixed(price),
                quantity=Fixed(qty),
                filled_qty=Fixed(cumExecQty),
                status=convert_bybit_order_status(orderStatus),
            )

            logi("order: " + str(order))

            _ = __get_address_as_lvalue(self._platform.address).on_update_order(order)

            iter.step()

        _ = data ^

    fn process_position_message(inout self, inout doc: OndemandDocument) -> None:
        var data = doc.get_array("data")

        var positions = list[PositionInfo]()

        var iter = data.iter()
        while iter.has_value():
            var item = iter.get_object()
            var posIdx = item.get_int("positionIdx")
            var sym = item.get_str("symbol")
            var side = item.get_str("side")
            var size = item.get_str("size")
            var avgPrice = item.get_str("entryPrice")
            var positionValue = item.get_str("positionValue")
            var leverage = item.get_str("leverage")
            var markPrice = item.get_str("markPrice")
            var positionMM = item.get_str("positionMM")
            var positionIM = item.get_str("positionIM")
            var takeProfit = item.get_str("takeProfit")
            var stopLoss = item.get_str("stopLoss")
            var unrealisedPnl = item.get_str("unrealisedPnl")
            var cumRealisedPnl = item.get_str("cumRealisedPnl")
            var createdTime = item.get_str("createdTime")
            var updatedTime = item.get_str("updatedTime")
            var position_info = PositionInfo(
                posIdx,
                sym,
                side,
                size,
                avgPrice,
                positionValue,
                strtod(leverage),
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

            try:
                self._strategy.on_position(position_info)
            except err:
                loge("on_position error: " + str(err))

            iter.step()

        _ = data ^

    fn is_initialized(self) -> Bool:
        return self._is_initialized.load()

    fn run(inout self):
        while self._is_running.load():
            # Check for stop request
            if self._stop_requested.load():
                logi("Executor stopping...")
                self._is_running.store(False)
                self._is_stopped.store(True)
                logi("Executor stopped")
                return

            try:
                self._strategy.on_tick()
            except err:
                loge("on_tick error: " + str(err))
            _ = sleep_us(1000 * 100)

    fn perform_tasks(inout self):
        """
        Perform periodic cleanup
        """
        while self._is_running.load():
            # logi("perform_tasks")
            _ = sleep(1)
