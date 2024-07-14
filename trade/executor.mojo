from os.atomic import Atomic
from base.sj_ondemand import *
from base.sj_dom import *
from base.thread import *
from core.bybitclient import BybitClient
from core.models import OrderBookLevel, OrderBookLite
from core.bybitmodel import *
from core.bybitws import *
from base.mo import logd, logi, logw, loge

# import base.log
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
    var _config: AppConfig
    var _client: BybitClient
    var _public_ws: BybitWS
    var _private_ws: BybitWS
    var _strategy: T
    var _is_initialized: Atomic[DType.int64]
    var _is_running: Atomic[DType.int64]  # Is it currently running
    var _stop_requested: Atomic[
        DType.int64
    ]  # Indicate whether a stop request has been received
    var _is_stopped: Atomic[DType.int64]  # Has it already ceased
    var _platform: UnsafePointer[Platform]
    var _rwlock: RWLock

    fn __init__(inout self, config: AppConfig, owned strategy: T) raises:
        logi("Executor.__init__")
        logi("config.testnet: " + str(config.testnet))
        logi("config.access_key: " + config.access_key)
        logi("config.secret_key: " + config.secret_key)
        self._config = config
        self._client = BybitClient(
            testnet=config.testnet,
            access_key=config.access_key,
            secret_key=config.secret_key,
        )
        var symbols = config.symbols.split(",")
        var public_topics = String("")
        for sym in symbols:
            if public_topics != "":
                public_topics += ","
            public_topics += "orderbook." + str(config.depth) + "." + sym[]
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
        self._strategy = strategy^
        self._is_initialized = 0
        self._is_running = 0
        self._stop_requested = 0
        self._is_stopped = 0
        self._platform = UnsafePointer[Platform].alloc(1)
        self._platform.init_pointee_move(Platform(config))
        self._rwlock = RWLock()

    fn __moveinit__(inout self, owned existing: Self):
        print("Executor.__moveinit__")
        self._config = existing._config
        self._client = existing._client^
        self._public_ws = existing._public_ws^
        self._private_ws = existing._private_ws^
        self._strategy = existing._strategy^
        self._is_initialized = existing._is_initialized.load()
        self._is_running = existing._is_running.load()
        self._stop_requested = existing._stop_requested.load()
        self._is_stopped = existing._is_stopped.load()
        self._platform = existing._platform
        self._rwlock = RWLock()

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

        self._strategy.setup(self._platform)

        self._strategy.on_init()

        self._private_ws.connect()
        self._public_ws.connect()

        self._is_initialized = 1
        self._is_running = 1
        self._stop_requested = 0
        self._is_stopped = 0

        logi("Executor started")

    fn stop_now(inout self):
        logi("Executor.stop_now")
        # Set stop flag
        self._stop_requested = 1
        self._private_ws.disconnect()
        self._public_ws.disconnect()
        # _ = sleep_ms(1000)
        try:
            self._strategy.on_exit()
            # self._private_ws.release()
            # self._public_ws.release()
        except err:
            loge("on_exit error: " + str(err))
        logi("Executor stopped")

    fn get_private_on_message(inout self) -> on_message_callback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper(msg: String):
            self_ptr[].on_private_message(msg)

        return wrapper

    fn get_public_on_message(inout self) -> on_message_callback:
        var self_ptr = UnsafePointer.address_of(self)

        fn wrapper(msg: String):
            self_ptr[].on_public_message(msg)
            # var s = c_str_to_string(data, data_len)
            # logd("get_public_on_message message: " + s)

        return wrapper

    fn on_private_message(inout self, msg: String):
        # logi("on_private_message message: " + msg)
        # self._rwlock.lock()
        # print("on_private_message")
        # var s = c_str_to_string(data, data_len)
        # logd("on_private_message message: " + s)
        var parser = OndemandParser(ParserBufferSize)
        var doc = parser.parse(msg)
        var topic = doc.get_str("topic")

        if topic == "order":
            logi("order message: " + msg)
            self.process_order_message(doc)
        elif topic == "position":
            logi("position message: " + msg)
            self.process_position_message(doc)
        elif topic == "execution":
            pass
        elif topic == "wallet":
            logi("wallet message: " + msg)
            self.process_wallet_message(doc)
        elif topic != "":
            return

        _ = doc^
        _ = parser^

        self._private_ws.on_message(msg)
        # self._rwlock.unlock()
        # logi("on_private_message done")

    fn on_public_message(inout self, msg: String):
        # logi("on_public_message message: " + msg)
        # self._rwlock.lock()
        try:
            # logd("on_public_message message: " + msg)

            var parser = DomParser(ParserBufferSize)
            var doc = parser.parse(msg)
            # var doc = parser.parse(data, data_len)
            var topic = doc.get_str("topic")

            if "orderbook." in topic:
                self.process_orderbook_message(doc)

            _ = doc^
            _ = parser^
        except err:
            loge("on_public_message error: " + str(err))
        # self._rwlock.unlock()
        # logi("on_public_message done")

    fn process_orderbook_message(
        inout self, inout doc: DomElement
    ) raises -> None:
        # logd("process_orderbook_message")
        # {"topic":"orderbook.1.BTCUSDT","type":"snapshot","ts":1702645020909,"data":{"s":"BTCUSDT","b":[["42663.50","0.910"]],"a":[["42663.60","11.446"]],"u":2768099,"seq":108881526829},"cts":1702645020906}
        # {"topic":"orderbook.1.BTCUSDT","type":"snapshot","ts":1703834857207,"data":{"s":"BTCUSDT","b":[["42489.90","130.419"]],"a":[["42493.80","132.979"]],"u":326106,"seq":8817548764},"cts":1703834853055}

        # {"topic":"orderbook.1.BTCUSDT","type":"snapshot","ts":1716274864889,"data":{"s":"BTCUSDT","b":[["71217.20","50.143"]],"a":[["71220.60","104.146"]],"u":517699,"seq":9227412505},"cts":1716274861496}
        var type_ = doc.get_str("type")
        var data = doc.get_object("data")
        # logd("type_: " + type_) # snapshot,delta
        var symbol = data.get_str("s")

        var a = data.get_array("a")
        var a_iter = a.iter()

        var asks = List[OrderBookLevel]()
        var bids = List[OrderBookLevel]()

        while a_iter.has_element():
            var a_obj = a_iter.get()
            var a_arr = a_obj.array()
            var price = a_arr.at_str(0)
            var qty = a_arr.at_str(1)
            # logd("price: " + str(price))
            # logd("qty: " + str(qty))
            asks.append(OrderBookLevel(price, qty))
            _ = a_obj^
            a_iter.step()

        _ = a^

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

        _ = b^
        _ = data^

        # logd("asks=" + str(len(asks)) + " bids=" + str(len(bids)))

        self._platform[].on_update_orderbook(symbol, type_, asks, bids)
        if self.is_initialized():
            var ob = self._platform[].get_orderbook(symbol, 5)
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

            _ = self._platform[].on_update_order(order)

            iter.step()

        _ = data^

    fn process_position_message(
        inout self, inout doc: OndemandDocument
    ) -> None:
        var data = doc.get_array("data")

        var positions = List[PositionInfo]()

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

        _ = data^

    fn process_wallet_message(inout self, inout doc: OndemandDocument) -> None:
        var data = doc.get_array("data")

        # {"topic":"wallet","id":"1713588734196211293-1465508-BTCUSDT","creationTime":1713588734198,"data":[{"accountType":"CONTRACT","accountIMRate":"","accountMMRate":"","accountLTV":"","totalEquity":"","totalWalletBalance":"","totalMarginBalance":"","totalAvailableBalance":"","totalPerpUPL":"","totalInitialMargin":"","totalMaintenanceMargin":"","coin":[{"coin":"USDT","equity":"1290.1674867","usdValue":"","walletBalance":"1290.1673867","availableToWithdraw":"1037.34792527","borrowAmount":"","availableToBorrow":"","accruedInterest":"","totalOrderIM":"188.6517014","totalPositionIM":"64.16776003","totalPositionMM":"","unrealisedPnl":"0.0001","cumRealisedPnl":"790.1673867"}]}]}
        # {
        #     "topic": "wallet",
        #     "id": "1713588734196211293-1465508-BTCUSDT",
        #     "creationTime": 1713588734198,
        #     "data": [{
        #             "accountType": "CONTRACT",
        #             "accountIMRate": "",
        #             "accountMMRate": "",
        #             "accountLTV": "",
        #             "totalEquity": "",
        #             "totalWalletBalance": "",
        #             "totalMarginBalance": "",
        #             "totalAvailableBalance": "",
        #             "totalPerpUPL": "",
        #             "totalInitialMargin": "",
        #             "totalMaintenanceMargin": "",
        #             "coin": [{
        #                     "coin": "USDT",
        #                     "equity": "1290.1674867",
        #                     "usdValue": "",
        #                     "walletBalance": "1290.1673867",
        #                     "availableToWithdraw": "1037.34792527",
        #                     "borrowAmount": "",
        #                     "availableToBorrow": "",
        #                     "accruedInterest": "",
        #                     "totalOrderIM": "188.6517014",
        #                     "totalPositionIM": "64.16776003",
        #                     "totalPositionMM": "",
        #                     "unrealisedPnl": "0.0001",
        #                     "cumRealisedPnl": "790.1673867"
        #                 }
        #             ]
        #         }
        #     ]
        # }

        var accounts = List[Account]()

        var iter = data.iter()
        while iter.has_value():
            var item = iter.get_object()
            var coin_arr = item.get_array("coin")
            var iter1 = coin_arr.iter()
            while iter1.has_value():
                var coin_obj = iter1.get_object()
                var coin = coin_obj.get_str("coin")  # USDT
                var equity = Fixed(coin_obj.get_str("equity"))
                var wallet_balance = Fixed(coin_obj.get_str("walletBalance"))
                var available_to_withdraw = Fixed(
                    coin_obj.get_str("availableToWithdraw")
                )
                var total_order_im = Fixed(coin_obj.get_str("totalOrderIM"))
                var total_position_im = Fixed(
                    coin_obj.get_str("totalPositionIM")
                )
                var unrealised_pnl = Fixed(coin_obj.get_str("unrealisedPnl"))
                var cum_realised_pnl = Fixed(coin_obj.get_str("cumRealisedPnl"))
                # logi("coin: " + coin)
                # logi("equity: " + equity)
                # logi("wallet_balance: " + wallet_balance)
                # logi("available_to_withdraw: " + available_to_withdraw)
                # logi("total_order_im: " + total_order_im)
                # logi("total_position_im: " + total_position_im)
                # logi("unrealised_pnl: " + unrealised_pnl)
                # logi("cum_realised_pnl: " + cum_realised_pnl)
                var account = Account(
                    coin=coin,
                    equity=equity,
                    wallet_balance=wallet_balance,
                    available_to_withdraw=available_to_withdraw,
                    total_order_margin=total_order_im,
                    total_position_margin=total_position_im,
                    unrealised_pnl=unrealised_pnl,
                    cum_realised_pnl=cum_realised_pnl,
                )
                accounts.append(account)
                iter1.step()
            _ = coin_arr^
            _ = item^
            iter.step()

        _ = data^

        self._platform[]._on_update_accounts(accounts)

    fn is_initialized(inout self) -> Bool:
        return self._is_initialized.load() == 1

    fn run_once(inout self):
        # logi("run_once")
        if self._is_running.load() == 0:
            logi("Executor is not running")
            return
        # logi("run_once 100")
        if self._stop_requested.load() == 1:
            logi("Executor stopping...")
            self._is_running = 0
            self._is_stopped = 1
            logi("Executor stopped")
            return

        # logi("start lock")
        # self._rwlock.lock()
        # logi("start lock done")
        try:
            # logi("run tick")
            self._strategy.on_tick()
            # logi("run tick done")
        except err:
            loge("on_tick error: " + str(err))
        # self._rwlock.unlock()
        # logi("Executor.run_once done")

    fn run(inout self):
        logi("Executor starting...")
        # 定义时间，之后用来控制循环，间隔100ms
        # var log_servie = log.log_service_itf()
        var last = time_ns()
        while self._is_running.load():
            # logi("run loop")
            # Check for stop request
            if self._stop_requested.load():
                logi("Executor stopping...")
                self._is_running = 0
                self._is_stopped = 1
                logi("Executor stopped")
                return

            # Check for log messages
            # _ = log_servie[].perform()

            # Check if it's time to run
            var now = time_ns()
            if now - last < 100 * 1000 * 1000:
                continue

            try:
                # logi("run tick")
                self._strategy.on_tick()
            except err:
                loge("on_tick error: " + str(err))
                sleep(10)

            last = now

    fn perform_tasks(inout self):
        """
        Perform periodic cleanup
        """
        while self._is_running.load():
            logi("perform_tasks")
            _ = sleep(1)
