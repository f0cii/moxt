from base.sj_ondemand import OndemandParser
from base.sj_dom import DomParser
from base.c import *
from base.mo import *
from base.moutil import *
from base.httpclient import *

from base.yyjson import yyjson_doc, yyjson_mut_doc
from .bybitmodel import (
    ServerTime,
    ExchangeInfo,
    KlineItem,
    OrderBookItem,
    OrderBook,
    PositionInfo,
    OrderResponse,
    BalanceInfo,
    OrderInfo,
)
from base.str_utils import *
from core.sign import hmac_sha256_hex
from stdlib_extensions.time import time_ns


alias ParserBufferSize = 1000 * 100


struct BybitClient:
    var testnet: Bool
    var access_key: String
    var secret_key: String
    var client: HttpClient

    fn __init__(inout self, testnet: Bool, access_key: String, secret_key: String):
        # print(base_url)
        self.testnet = testnet
        self.access_key = access_key
        self.secret_key = secret_key
        let base_url = "https://api-testnet.bybit.com" if self.testnet else "https://api.bybit.com"
        self.client = HttpClient(base_url, tlsv13_client)

    fn __moveinit__(inout self, owned existing: Self):
        logd("BybitClient.__moveinit__")
        self.testnet = existing.testnet
        self.access_key = existing.access_key
        self.secret_key = existing.secret_key
        let base_url = "https://api-testnet.bybit.com" if self.testnet else "https://api.bybit.com"
        self.client = existing.client ^
        logd("BybitClient.__moveinit__ done")

    fn fetch_public_time(self) raises -> ServerTime:
        let ret = self.do_get("/v3/public/time", "", False)
        if ret.status != 200:
            raise Error("error status=" + str(ret.status))

        # print(ret.body)
        logd("body: " + str(ret.body))

        # {"retCode":0,"retMsg":"OK","result":{"timeSecond":"1696233582","timeNano":"1696233582169993116"},"retExtInfo":{},"time":1696233582169}
        let parser = OndemandParser(ParserBufferSize)
        let doc = parser.parse(ret.body)
        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + str(ret_msg))

        let result = doc.get_object("result")

        let time_second = atol(result.get_str("timeSecond"))
        let time_nano = atol(result.get_str("timeNano"))

        _ = doc
        _ = parser

        return ServerTime(time_second, time_nano)

    fn fetch_exchange_info(
        self, category: StringLiteral, symbol: StringLiteral
    ) raises -> ExchangeInfo:
        var query_values = QueryParams()
        query_values["category"] = category
        query_values["symbol"] = symbol
        let query_str = query_values.to_string()
        logi("query_str: " + query_str)
        let ret = self.do_get("/v5/market/instruments-info", query_str, False)
        if ret.status != 200:
            raise Error("error status=" + str(ret.status))

        logd(ret.body)

        # {"retCode":0,"retMsg":"OK","result":{"category":"linear","list":[{"symbol":"BTCUSDT","contractType":"LinearPerpetual","status":"Trading","baseCoin":"BTC","quoteCoin":"USDT","launchTime":"1584230400000","deliveryTime":"0","deliveryFeeRate":"","priceScale":"2","leverageFilter":{"minLeverage":"1","maxLeverage":"100.00","leverageStep":"0.01"},"priceFilter":{"minPrice":"0.10","maxPrice":"199999.80","tickSize":"0.10"},"lotSizeFilter":{"maxOrderQty":"100.000","minOrderQty":"0.001","qtyStep":"0.001","postOnlyMaxOrderQty":"1000.000"},"unifiedMarginTrade":true,"fundingInterval":480,"settleCoin":"USDT","copyTrading":"both"}],"nextPageCursor":""},"retExtInfo":{},"time":1701762078208}

        var tick_size: Float64 = 0
        var stepSize: Float64 = 0

        let parser = OndemandParser(ParserBufferSize)
        let doc = parser.parse(ret.body)
        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + str(ret_msg))

        let result = doc.get_object("result")
        let result_list = result.get_array("list")
        if result_list.__len__() == 0:
            raise Error("error list length is 0")

        let list_iter = result_list.iter()

        while list_iter.has_value():
            let obj = list_iter.get()
            let symbol_ = obj.get_str("symbol")
            # if symbol.upper() != symbol_.upper():
            # logd("symbol_: " + symbol_ + " symbol: " + symbol)
            if str(symbol) != symbol_:
                # logd("not eq")
                continue

            let priceFilter = obj.get_object("priceFilter")
            tick_size = strtod(priceFilter.get_str("tickSize"))
            let lotSizeFilter = obj.get_object("lotSizeFilter")
            stepSize = strtod(lotSizeFilter.get_str("qtyStep"))

            # logi("tick_size: " + str(tick_size))
            # logi("stepSize: " + str(stepSize))

            _ = obj ^

            list_iter.step()

        _ = result_list ^
        _ = result ^
        _ = doc ^
        _ = parser ^

        return ExchangeInfo(symbol, tick_size, stepSize)

    fn fetch_kline(
        self,
        category: StringLiteral,
        symbol: StringLiteral,
        interval: StringLiteral,
        limit: Int,
        start: Int,
        end: Int,
    ) raises -> list[KlineItem]:
        var query_values = QueryParams()
        query_values["category"] = category
        query_values["symbol"] = symbol
        query_values["interval"] = interval
        if limit > 0:
            query_values["limit"] = str(limit)
        if start > 0:
            query_values["start"] = str(start)
        if end > 0:
            query_values["end"] = str(end)
        let query_str = query_values.to_string()
        let ret = self.do_get("/v5/market/kline", query_str, False)
        if ret.status != 200:
            raise Error("error status=" + str(ret.status))

        # logi(ret.body)
        # {"retCode":0,"retMsg":"OK","result":{"symbol":"BTCUSDT","category":"linear","list":[["1687589640000","30709.9","30710.4","30709.9","30710.3","3.655","112245.7381"],["1687589580000","30707.9","30710","30704.7","30709.9","21.984","675041.8648"],["1687589520000","30708","30714.7","30705","30707.9","33.378","1025097.6459"],["1687589460000","30689.9","30710.3","30689.9","30708","51.984","1595858.2778"],["1687589400000","30678.6","30690.9","30678.5","30689.9","38.747","1188886.4093"]]},"retExtInfo":{},"time":1687589659062}

        var res = list[KlineItem]()

        let parser = DomParser(ParserBufferSize)
        let doc = parser.parse(ret.body)
        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

        let result = doc.get_object("result")
        let result_list = result.get_array("list")

        let list_iter = result_list.iter()

        while list_iter.has_element():
            let obj = list_iter.get()
            let i_arr_list = obj.array()

            let timestamp = strtoi(i_arr_list.at_str(0))
            let open_ = strtod(i_arr_list.at_str(1))
            let high = strtod(i_arr_list.at_str(2))
            let low = strtod(i_arr_list.at_str(3))
            let close = strtod(i_arr_list.at_str(4))
            let volume = strtod(i_arr_list.at_str(5))
            let turnover = strtod(i_arr_list.at_str(6))

            res.append(
                KlineItem(
                    timestamp=timestamp,
                    open=open_,
                    high=high,
                    low=low,
                    close=close,
                    volume=volume,
                    turnover=turnover,
                    confirm=True,
                )
            )

            _ = obj ^

            list_iter.step()

        _ = result_list ^
        _ = result ^
        _ = doc ^
        _ = parser ^

        return res

    fn fetch_orderbook(
        self, category: StringLiteral, symbol: StringLiteral, limit: Int
    ) raises -> OrderBook:
        var query_values = QueryParams()
        query_values["category"] = category
        query_values["symbol"] = symbol
        if limit > 0:
            query_values["limit"] = str(limit)
        let query_str = query_values.to_string()
        let ret = self.do_get("/v5/market/orderbook", query_str, False)
        if ret.status != 200:
            raise Error("error status=" + str(ret.status))

        # print(ret.body)
        # {
        #     "result": {
        #         "a": [["30604.8", "174.267"], ["30648.6", "0.002"], ["30649.1", "0.001"], ["30650", "1.119"], ["30650.3", "0.01"], ["30650.8", "0.001"], ["30651.6", "0.001"], ["30652", "0.001"], ["30652.4", "0.062"], ["30652.5", "0.001"]],
        #         "b": [["30598.7", "142.31"], ["30578.2", "0.004"], ["30575.3", "0.001"], ["30571.8", "0.001"], ["30571.1", "0.002"], ["30568.5", "0.002"], ["30566.6", "0.005"], ["30565.6", "0.01"], ["30565.5", "0.061"], ["30563", "0.001"]],
        #         "s": "BTCUSDT",
        #         "ts": 1689132447413,
        #         "u": 5223166
        #     },
        #     "retCode": 0,
        #     "retExtInfo": {},
        #     "retMsg": "OK",
        #     "time": 1689132448224
        # }

        # res = OrderBook
        var asks = list[OrderBookItem]()
        var bids = list[OrderBookItem]()

        let parser = DomParser(ParserBufferSize)
        let doc = parser.parse(ret.body)
        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

        let result = doc.get_object("result")
        let a_list = result.get_array("a")

        let list_iter_a = a_list.iter()

        while list_iter_a.has_element():
            let obj = list_iter_a.get()
            let i_arr_list = obj.array()

            let price = strtod(i_arr_list.at_str(0))
            let qty = strtod(i_arr_list.at_str(1))

            asks.append(OrderBookItem(price, qty))
            _ = obj ^
            list_iter_a.step()

        _ = a_list ^

        let b_list = result.get_array("b")

        let list_iter_b = b_list.iter()

        while list_iter_b.has_element():
            let obj = list_iter_b.get()
            let i_arr_list = obj.array()

            let price = strtod(i_arr_list.at_str(0))
            let qty = strtod(i_arr_list.at_str(1))

            bids.append(OrderBookItem(price, qty))

            list_iter_b.step()

        _ = b_list ^

        _ = result ^
        _ = doc ^
        _ = parser ^

        return OrderBook(asks, bids)

    fn switch_position_mode(
        self, category: StringLiteral, symbol: StringLiteral, mode: StringLiteral
    ) raises -> Bool:
        """
        切换持仓模式
        mode: 0-PositionModeMergedSingle 3-PositionModeBothSides
        """
        var yy_doc = yyjson_mut_doc()
        yy_doc.add_str("category", category)
        yy_doc.add_str("symbol", symbol)
        yy_doc.add_str("mode", mode)
        let body_str = yy_doc.mut_write()

        # logi("body=" + body_str)
        # {"category":"linear","symbol":"BTCUSDT","mode":"0"}
        let ret = self.do_post("/v5/position/switch-mode", body_str, True)
        # print(ret)
        if ret.status != 200:
            raise Error("error status=" + str(ret.status))
        # /*

        # * {"retCode":10001,"retMsg":"params error: position_mode invalid","result":{},"retExtInfo":{},"time":1687601751714}
        # * {"retCode":110025,"retMsg":"Position mode is not modified","result":{},"retExtInfo":{},"time":1687601811928}
        # * {"retCode":0,"retMsg":"OK","result":{},"retExtInfo":{},"time":1687601855987}
        # * {"retCode":110025,"retMsg":"Position mode is not modified","result":{},"retExtInfo":{},"time":1696337560088}
        # */

        # logi(ret.body)

        let parser = DomParser(ParserBufferSize)
        let doc = parser.parse(ret.body)
        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

        _ = doc ^
        _ = parser ^

        return True

    fn set_leverage(
        self,
        category: StringLiteral,
        symbol: StringLiteral,
        buy_leverage: StringLiteral,
        sell_leverage: StringLiteral,
    ) raises -> Bool:
        """
        设置杠杆倍数
        """
        var yy_doc = yyjson_mut_doc()
        yy_doc.add_str("category", category)
        yy_doc.add_str("symbol", symbol)
        yy_doc.add_str("buyLeverage", buy_leverage)
        yy_doc.add_str("sellLeverage", sell_leverage)
        let body_str = yy_doc.mut_write()

        # print(body_str)

        let ret = self.do_post("/v5/position/set-leverage", body_str, True)
        # print(ret)
        if ret.status != 200:
            raise Error("error status=" + str(ret.status))

        # /*
        # * {"retCode":0,"retMsg":"OK","result":{},"retExtInfo":{},"time":1696339881214}
        # * {"retCode":110043,"retMsg":"Set leverage not modified","result":{},"retExtInfo":{},"time":1696339921712}
        # * {"retCode":110043,"retMsg":"Set leverage not modified","result":{},"retExtInfo":{},"time":1701874812321}
        # */

        let parser = DomParser(ParserBufferSize)
        let doc = parser.parse(ret.body)
        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

        _ = doc ^
        _ = parser ^

        return True

    fn place_order(
        self,
        category: StringLiteral,
        symbol: StringLiteral,
        side: StringLiteral,
        order_type: StringLiteral,
        qty: StringLiteral,
        price: StringLiteral,
        time_in_force: StringLiteral = "",
        position_idx: Int = 0,
        order_link_id: StringLiteral = "",
        reduce_only: Bool = False,
    ) raises -> OrderResponse:
        """
        下单
        """
        var yy_doc = yyjson_mut_doc()
        yy_doc.add_str("category", category)
        yy_doc.add_str("symbol", symbol)
        yy_doc.add_str("side", side)
        yy_doc.add_str("orderType", order_type)
        yy_doc.add_str("qty", qty)
        if price != "":
            yy_doc.add_str("price", price)
        if time_in_force != "":
            yy_doc.add_str("timeInForce", time_in_force)
        if position_idx != 0:
            yy_doc.add_str("positionIdx", str(position_idx))
        if order_link_id != "":
            yy_doc.add_str("orderLinkId", order_link_id)
        if reduce_only:
            yy_doc.add_str("reduceOnly", "true")
        let body_str = yy_doc.mut_write()

        # print(body_str)

        let ret = self.do_post("/v5/order/create", body_str, True)
        # print(ret)
        if ret.status != 200:
            raise Error("error status=" + str(ret.status))

        # * {"retCode":10001,"retMsg":"params error: side invalid","result":{},"retExtInfo":{},"time":1687610278834}
        # * {"retCode":10001,"retMsg":"position idx not match position mode","result":{},"retExtInfo":{},"time":1687610314417}
        # * {"retCode":10001,"retMsg":"The number of contracts exceeds minimum limit allowed","result":{},"retExtInfo":{},"time":1687610435384}
        # * {"retCode":110003,"retMsg":"Order price is out of permissible range","result":{},"retExtInfo":{},"time":1687610383879}
        # * {"retCode":110017,"retMsg":"Reduce-only rule not satisfied","result":{},"retExtInfo":{},"time":1689175546336}
        # * {"retCode":0,"retMsg":"OK","result":{"orderId":"b719e004-0846-4b58-8405-a307133c5146","orderLinkId":""},"retExtInfo":{},"time":1689176180262}
        # * {"retCode":0,"retMsg":"OK","result":{"orderId":"44ce1d85-3458-4ec3-af76-41a4cf80c9b3","orderLinkId":""},"retExtInfo":{},"time":1696404669448}

        # print(ret.body)

        let parser = DomParser(ParserBufferSize)
        let doc = parser.parse(ret.body)
        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

        let result = doc.get_object("result")
        let _order_id = result.get_str("orderId")
        let _order_link_id = result.get_str("orderLinkId")

        _ = result ^
        _ = doc ^
        _ = parser ^

        return OrderResponse(order_id=_order_id, order_link_id=_order_link_id)

    fn cancel_order(
        self,
        category: StringLiteral,
        symbol: StringLiteral,
        order_id: String = "",
        order_link_id: String = "",
    ) raises -> OrderResponse:
        """
        撤单
        """
        var yy_doc = yyjson_mut_doc()
        yy_doc.add_str("category", category)
        yy_doc.add_str("symbol", symbol)
        if order_id != "":
            yy_doc.add_str("orderId", order_id)
        if order_link_id != "":
            yy_doc.add_str("orderLinkId", order_link_id)
        let body_str = yy_doc.mut_write()

        # print(body_str)

        let ret = self.do_post("/v5/order/cancel", body_str, True)
        # print(ret)
        if ret.status != 200:
            raise Error("error status=" + str(ret.status))

        # print(ret.body)

        # * {"retCode":10001,"retMsg":"params error: OrderId or orderLinkId is required","result":{},"retExtInfo":{},"time":1687611859585}
        # * {"retCode":110001,"retMsg":"Order does not exist","result":{},"retExtInfo":{},"time":1689203937336}
        # * {"retCode":0,"retMsg":"OK","result":{"orderId":"1c64212f-8b16-4d4b-90c1-7a4cb55f240a","orderLinkId":""},"retExtInfo":{},"time":1689204723386}

        let parser = DomParser(ParserBufferSize)
        let doc = parser.parse(ret.body)
        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

        let result = doc.get_object("result")
        let _order_id = result.get_str("orderId")
        let _order_link_id = result.get_str("orderLinkId")

        _ = result ^
        _ = doc ^
        _ = parser ^

        return OrderResponse(_order_id, _order_link_id)

    fn cancel_orders(
        self,
        category: StringLiteral,
        symbol: StringLiteral,
        base_coin: StringLiteral = "",
        settle_coin: StringLiteral = "",
    ) raises -> list[OrderResponse]:
        """
        批量撤单
        """
        var yy_doc = yyjson_mut_doc()
        yy_doc.add_str("category", category)
        yy_doc.add_str("symbol", symbol)
        if base_coin != "":
            yy_doc.add_str("baseCoin", base_coin)
        if settle_coin != "":
            yy_doc.add_str("settleCoin", settle_coin)
        let body_str = yy_doc.mut_write()

        # print(body_str)

        let ret = self.do_post("/v5/order/cancel-all", body_str, True)
        # print(ret)
        if ret.status != 200:
            raise Error("error status=" + str(ret.status))

        # print(ret.body)

        # * {"retCode":0,"retMsg":"OK","result":{"list":[]},"retExtInfo":{},"time":1687612231164}
        var res = list[OrderResponse]()

        let parser = DomParser(ParserBufferSize)
        let doc = parser.parse(ret.body)
        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

        let result = doc.get_object("result")
        let a_list = result.get_array("list")

        let list_iter_a = a_list.iter()
        while list_iter_a.has_element():
            let obj = list_iter_a.get()

            let order_id = obj.get_str("orderId")
            let order_link_id = obj.get_str("orderLinkId")
            res.append(OrderResponse(order_id=order_id, order_link_id=order_link_id))

            list_iter_a.step()

        _ = a_list ^
        _ = result ^
        _ = doc ^
        _ = parser ^

        return res

    fn fetch_balance(
        self, account_type: StringLiteral, coin: StringLiteral
    ) raises -> list[BalanceInfo]:
        """
        获取钱包余额
        <param name="accountType">
        統一帳戶: UNIFIED(現貨/USDT和USDC永續/期權), CONTRACT(反向)
        普通帳戶: CONTRACT(期貨), SPOT(現貨)
        </param>
        <param name="coin">USDT,USDC</param>
        """
        var query_values = QueryParams()
        query_values["accountType"] = account_type
        query_values["coin"] = coin
        let query_str = query_values.to_string()
        let ret = self.do_get("/v5/account/wallet-balance", query_str, True)
        if ret.status != 200:
            raise Error("error status=" + str(ret.status))

        # print(ret.body)

        # {"retCode":0,"retMsg":"OK","result":{"list":[{"accountType":"CONTRACT","accountIMRate":"","accountMMRate":"","totalEquity":"","totalWalletBalance":"","totalMarginBalance":"","totalAvailableBalance":"","totalPerpUPL":"","totalInitialMargin":"","totalMaintenanceMargin":"","accountLTV":"","coin":[{"coin":"USDT","equity":"20.21","usdValue":"","walletBalance":"20.21","borrowAmount":"","availableToBorrow":"","availableToWithdraw":"20.21","accruedInterest":"","totalOrderIM":"0","totalPositionIM":"0","totalPositionMM":"","unrealisedPnl":"0","cumRealisedPnl":"0"}]}]},"retExtInfo":{},"time":1687608906096}
        var res = list[BalanceInfo]()

        let parser = OndemandParser(ParserBufferSize)
        let doc = parser.parse(ret.body)

        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

        let result_list = doc.get_object("result").get_array("list")
        let list_iter = result_list.iter()

        while list_iter.has_value():
            let obj = list_iter.get()
            let account_type = obj.get_str("accountType")
            # logi("account_type=" + account_type)
            if account_type == "CONTRACT":
                let coin_list = obj.get_array("coin")
                let coin_iter = coin_list.iter()
                while coin_iter.has_value():
                    let coin_obj = coin_iter.get()
                    let coin_name = coin_obj.get_str("coin")
                    if coin_name != coin:
                        continue
                    # logi("coin_name: " + coin_name)
                    let equity = strtod(coin_obj.get_str("equity"))
                    let available_to_withdraw = strtod(
                        coin_obj.get_str("availableToWithdraw")
                    )
                    let wallet_balance = strtod(coin_obj.get_str("walletBalance"))
                    let total_order_im = strtod(coin_obj.get_str("totalOrderIM"))
                    let total_position_im = strtod(coin_obj.get_str("totalPositionIM"))
                    res.append(
                        BalanceInfo(
                            coin_name=coin_name,
                            equity=equity,
                            available_to_withdraw=available_to_withdraw,
                            wallet_balance=wallet_balance,
                            total_order_im=total_order_im,
                            total_position_im=total_position_im,
                        )
                    )
                    coin_iter.step()

                _ = coin_list ^
            elif account_type == "SPOT":
                pass

            _ = obj ^
            list_iter.step()

        _ = result_list ^
        _ = doc ^
        _ = parser ^

        return res

    fn fetch_orders(
        self,
        category: StringLiteral,
        symbol: StringLiteral,
        order_link_id: StringLiteral = "",
        limit: Int = 0,
        cursor: StringLiteral = "",
    ) raises -> list[OrderInfo]:
        """
        获取当前订单
        https://bybit-exchange.github.io/docs/zh-TW/v5/order/open-order
        """
        var query_values = QueryParams()
        query_values["category"] = category
        query_values["symbol"] = symbol
        if order_link_id != "":
            query_values["orderLinkId"] = order_link_id
        if limit > 0:
            query_values["limit"] = str(limit)
        if cursor != "":
            query_values["cursor"] = cursor
        let query_str = query_values.to_string()
        logd("query_str: " + query_str)
        let ret = self.do_get("/v5/order/realtime", query_str, True)
        if ret.status != 200:
            raise Error("error status=" + str(ret.status) + " body=" + str(ret.body))

        # {"retCode":0,"retMsg":"OK","result":{"list":[],"nextPageCursor":"","category":"linear"},"retExtInfo":{},"time":1696392159183}
        # {"retCode":10002,"retMsg":"invalid request, please check your server timestamp or recv_window param. req_timestamp[1696396708819],server_timestamp[1696396707813],recv_window[15000]","result":{},"retExtInfo":{},"time":1696396707814}
        var res = list[OrderInfo]()

        let parser = DomParser(ParserBufferSize)
        let doc = parser.parse(ret.body)

        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

        let result = doc.get_object("result")
        let result_list = result.get_array("list")

        let list_iter = result_list.iter()

        while list_iter.has_element():
            let i = list_iter.get()
            let position_idx = i.get_int("positionIdx")
            let order_id = i.get_str("orderId")
            let _symbol = i.get_str("symbol")
            let side = i.get_str("side")
            let order_type = i.get_str("orderType")
            let price = strtod(i.get_str("price"))
            let qty = strtod(i.get_str("qty"))
            let cum_exec_qty = strtod(i.get_str("cumExecQty"))
            let order_status = i.get_str("orderStatus")
            let created_time = i.get_str("createdTime")
            let updated_time = i.get_str("updatedTime")
            let avg_price = strtod(i.get_str("avgPrice"))
            let cum_exec_fee = strtod(i.get_str("cumExecFee"))
            let time_in_force = i.get_str("timeInForce")
            let reduce_only = i.get_bool("reduceOnly")
            let order_link_id = i.get_str("orderLinkId")

            res.append(
                OrderInfo(
                    position_idx=position_idx,
                    order_id=order_id,
                    symbol=_symbol,
                    side=side,
                    type_=order_type,
                    price=price,
                    qty=qty,
                    cum_exec_qty=cum_exec_qty,
                    status=order_status,
                    created_time=created_time,
                    updated_time=updated_time,
                    avg_price=avg_price,
                    cum_exec_fee=cum_exec_fee,
                    time_in_force=time_in_force,
                    reduce_only=reduce_only,
                    order_link_id=order_link_id,
                )
            )

            list_iter.step()

        _ = result_list ^
        _ = result ^
        _ = doc ^
        _ = parser ^

        return res

    fn fetch_history_orders(
        self,
        category: StringLiteral,
        symbol: StringLiteral,
        order_id: StringLiteral,
        order_link_id: StringLiteral,
        order_filter: StringLiteral = "",
        order_status: StringLiteral = "",
        start_time_ms: Int = 0,
        end_time_ms: Int = 0,
        limit: Int = 0,
        cursor: StringLiteral = "",
    ) raises -> list[OrderInfo]:
        """
        获取历史订单
        https://bybit-exchange.github.io/docs/zh-TW/v5/order/order-list
        """
        var query_values = QueryParams()
        query_values["category"] = category
        query_values["symbol"] = symbol
        if order_id != "":
            query_values["orderId"] = order_id
        if order_link_id != "":
            query_values["orderLinkId"] = order_link_id
        if order_filter != "":
            query_values["orderFilter"] = order_filter
        if order_status != "":
            query_values["orderStatus"] = order_status
        if start_time_ms > 0:
            query_values["startTimeMs"] = str(start_time_ms)
        if end_time_ms > 0:
            query_values["endTimeMs"] = str(end_time_ms)
        if limit > 0:
            query_values["limit"] = str(limit)
        if cursor != "":
            query_values["cursor"] = cursor
        var query_str = query_values.to_string()
        loge("query_str=" + query_str)
        let ret = self.do_get("/v5/order/history", query_str, True)
        if ret.status != 200:
            raise Error("error status=[" + str(ret.status) + "]")

        # print(ret.body)

        let res = list[OrderInfo]()

        let parser = DomParser(ParserBufferSize)
        let doc = parser.parse(ret.body)
        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

        let result = doc.get_object("result")
        let a_list = result.get_array("list")

        let list_iter_a = a_list.iter()
        while list_iter_a.has_element():
            let i = list_iter_a.get()

            # position_idx: int   # positionIdx
            # order_id: StringLiteral       # orderId
            # symbol: StringLiteral
            # side: StringLiteral
            # type: StringLiteral
            # price: float
            # qty: float
            # cum_exec_qty: float # cumExecQty
            # status: StringLiteral         # orderStatus
            # created_time: StringLiteral   # createdTime
            # updated_time: StringLiteral   # updatedTime
            # avg_price: float    # avgPrice
            # cum_exec_fee: float # cumExecFee
            # time_in_force: StringLiteral  # timeInForce
            # reduce_only: bool   # reduceOnly
            # order_link_id: StringLiteral  # orderLinkId
            let position_idx = i["positionIdx"].int()
            let order_id = i["orderId"].str()
            let _symbol = i["symbol"].str()
            let side = i["side"].str()
            let order_type = i["orderType"].str()
            let price = strtod(i["price"].str())
            let qty = strtod(i["qty"].str())
            let cum_exec_qty = strtod(i["cumExecQty"].str())
            let order_status = i["orderStatus"].str()
            let created_time = i["createdTime"].str()
            let updated_time = i["updatedTime"].str()
            let avg_price = strtod(i["avgPrice"].str())
            let cum_exec_fee = strtod(i["cumExecFee"].str())
            let time_in_force = i["timeInForce"].str()
            let reduce_only = i["reduceOnly"].bool()
            let order_link_id = i["orderLinkId"].str()

            res.append(
                OrderInfo(
                    position_idx=position_idx,
                    order_id=order_id,
                    symbol=_symbol,
                    side=side,
                    type_=order_type,
                    price=price,
                    qty=qty,
                    cum_exec_qty=cum_exec_qty,
                    status=order_status,
                    created_time=created_time,
                    updated_time=updated_time,
                    avg_price=avg_price,
                    cum_exec_fee=cum_exec_fee,
                    time_in_force=time_in_force,
                    reduce_only=reduce_only,
                    order_link_id=order_link_id,
                )
            )

            list_iter_a.step()

        _ = a_list ^
        _ = result ^
        _ = doc ^
        _ = parser ^

        return res

    fn fetch_positions(
        self, category: StringLiteral, symbol: StringLiteral
    ) raises -> list[PositionInfo]:
        var query_values = QueryParams()
        query_values["category"] = category
        query_values["symbol"] = symbol
        # baseCoin, settleCoin, limit, cursor
        let query_str = query_values.to_string()
        let ret = self.do_get("/v5/position/list", query_str, True)
        if ret.status != 200:
            raise Error("error status=[" + str(ret.status) + "]")

        # {"retCode":10002,"retMsg":"invalid request, please check your server timestamp or recv_window param. req_timestamp[1696255257619],server_timestamp[1696255255967],recv_window[15000]","result":{},"retExtInfo":{},"time":1696255255967}

        # print(ret.body)

        let res = list[PositionInfo]()

        let parser = DomParser(ParserBufferSize)
        let doc = parser.parse(ret.body)
        let ret_code = doc.get_int("retCode")
        let ret_msg = doc.get_str("retMsg")
        if ret_code != 0:
            raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

        let result = doc.get_object("result")
        let a_list = result.get_array("list")

        let list_iter_a = a_list.iter()
        while list_iter_a.has_element():
            let i = list_iter_a.get()

            let _symbol = i["symbol"].str()
            if _symbol != symbol:
                continue

            # {
            #     "positionIdx": 0,
            #     "riskId": 1,
            #     "riskLimitValue": "2000000",
            #     "symbol": "BTCUSDT",
            #     "side": "None",
            #     "size": "0.000",
            #     "avgPrice": "0",
            #     "positionValue": "0",
            #     "tradeMode": 0,
            #     "positionStatus": "Normal",
            #     "autoAddMargin": 0,
            #     "adlRankIndicator": 0,
            #     "leverage": "1",
            #     "positionBalance": "0",
            #     "markPrice": "26515.73",
            #     "liqPrice": "",
            #     "bustPrice": "0.00",
            #     "positionMM": "0",
            #     "positionIM": "0",
            #     "tpslMode": "Full",
            #     "takeProfit": "0.00",
            #     "stopLoss": "0.00",
            #     "trailingStop": "0.00",
            #     "unrealisedPnl": "0",
            #     "cumRealisedPnl": "-19.59637027",
            #     "seq": 8172241025,
            #     "createdTime": "1682125794703",
            #     "updatedTime": "1694995200083"
            # }

            let _position_idx = i["positionIdx"].int()
            # _risk_id = i["riskId"].int()
            let _side = i["side"].str()
            let _size = i["size"].str()
            let _avg_price = i["avgPrice"].str()
            let _position_value = i["positionValue"].str()
            let _leverage = i["leverage"].float()
            let _mark_price = i["markPrice"].str()
            # _liq_price = i["liqPrice"].str()
            # _bust_price = i["bustPrice"].str()
            let _position_mm = i["positionMM"].str()
            let _position_im = i["positionIM"].str()
            let _take_profit = i["takeProfit"].str()
            let _stop_loss = i["stopLoss"].str()
            let _unrealised_pnl = i["unrealisedPnl"].str()
            let _cum_realised_pnl = i["cumRealisedPnl"].str()
            # _seq = i["seq"].int()
            let _created_time = i["createdTime"].str()
            let _updated_time = i["updatedTime"].str()
            let pos = PositionInfo(
                position_idx=_position_idx,
                symbol=_symbol,
                side=_side,
                size=_size,
                avg_price=_avg_price,
                position_value=_position_value,
                leverage=_leverage,
                mark_price=_mark_price,
                position_mm=_position_mm,
                position_im=_position_im,
                take_profit=_take_profit,
                stop_loss=_stop_loss,
                unrealised_pnl=_unrealised_pnl,
                cum_realised_pnl=_cum_realised_pnl,
                created_time=_created_time,
                updated_time=_updated_time,
            )
            res.append(pos)

            list_iter_a.step()

        _ = a_list ^
        _ = result ^
        _ = doc ^
        _ = parser ^

        return res

    fn do_sign(
        self, inout headers: Headers, borrowed data: String, sign: Bool
    ) raises -> None:
        if not sign:
            return
        let time_ms_str = str(time_ns() / 1e6)
        let recv_window_str = "15000"
        # logd("do_sign: " + data)
        let payload = data
        # logd("do_sign: " + data)
        let param_str = time_ms_str + self.access_key + recv_window_str + payload
        let sign_str = hmac_sha256_hex(param_str, self.secret_key)
        headers["X-BAPI-API-KEY"] = self.access_key
        headers["X-BAPI-TIMESTAMP"] = time_ms_str
        headers["X-BAPI-SIGN"] = sign_str
        headers["X-BAPI-RECV-WINDOW"] = recv_window_str

    fn do_get(
        self, path: StringLiteral, param: String, sign: Bool
    ) raises -> HttpResponse:
        var headers = Headers()
        let param_ = param
        self.do_sign(headers, param, sign)

        let request_path: String
        if param != "":
            request_path = str(path) + "?" + param_
        else:
            request_path = path
        # logd("request_path: " + request_path)
        # logd("param: " + param_)
        return self.client.get(request_path, headers=headers)

    fn do_post(
        self, path: StringLiteral, body: String, sign: Bool
    ) raises -> HttpResponse:
        var headers = Headers()
        # headers["Content-Type"] = "application/json"
        self.do_sign(headers, body, sign)
        return self.client.post(path, data=body, headers=headers)


# {"retCode":10010,"retMsg":"Unmatched IP, please check your API key's bound IP addresses.","result":{},"retExtInfo":{},"time":1701783283807}
# {"retCode":10004,"retMsg":"error sign! origin_string[1701783394711de21RcqOIH8Gfxvxvv15000]","result":{},"retExtInfo":{},"time":1701783394740}
