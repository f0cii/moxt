from base.fixed import Fixed
from base.sj_ondemand import OndemandParser
from base.sj_dom import DomParser
from base.c import *
from base.mo import *
from base.moutil import *
from base.httpclient import *

from base.yyjson import yyjson_mut_doc

from .binancemodel import (
    OrderInfo,
)
from .sign import hmac_sha256_hex
from ylstdlib.time import time_ns


alias ParserBufferSize = 1000 * 100


struct BinanceClient:
    var testnet: Bool
    var access_key: String
    var secret_key: String
    var client: HttpClient

    fn __init__(
        inout self, testnet: Bool, access_key: String, secret_key: String
    ):
        # print(base_url)
        self.testnet = testnet
        self.access_key = access_key
        self.secret_key = secret_key
        var base_url = "https://testnet.binancefuture.com" if self.testnet else "https://fapi.binance.com"
        self.client = HttpClient(base_url, tlsv13_client)

    fn __moveinit__(inout self, owned existing: Self):
        logd("BybitClient.__moveinit__")
        self.testnet = existing.testnet
        self.access_key = existing.access_key
        self.secret_key = existing.secret_key
        # var base_url = "https://api-testnet.bybit.com" if self.testnet else "https://api.bybit.com"
        self.client = existing.client^
        logd("BybitClient.__moveinit__ done")

    fn set_verbose(inout self, verbose: Bool):
        self.client.set_verbose(verbose)

    fn public_time(self) raises -> Int:
        var ret = self.do_get("/fapi/v1/time", "", False)
        if ret.status_code != 200:
            raise Error(
                "error status_code="
                + str(ret.status_code)
                + " text="
                + ret.text
            )

        logd("text: " + str(ret.text))

        # {"serverTime":1704283776645}
        var parser = OndemandParser(ParserBufferSize)
        var doc = parser.parse(ret.text)
        var server_time = doc.get_int("serverTime")
        if server_time == 0:
            raise Error("error server_time=0")

        _ = doc^
        _ = parser^

        return server_time

    fn place_order(
        self,
        symbol: String,
        side: String,
        type_: String,
        position_side: String,
        quantity: Fixed,
        price: Fixed,
        time_in_force: String = "GTC",
        reduce_only: Bool = False,
    ) raises -> OrderInfo:
        """
        symbol: BTCUSDT
        side: SELL, BUY
        type_(type): Order type LIMIT, MARKET, STOP, TAKE_PROFIT, STOP_MARKET, TAKE_PROFIT_MARKET, TRAILING_STOP_MARKET
        position_side(positionSide): BOTH; LONG or SHORT
        time_in_force(timeInForce): FOK or GTX(Post-only)
        (timeInForce):
        GTC - Good Till Cancel
        IOC - Immediate or Cancel
        FOK - Fill or Kill
        GTX - Good Till Crossing
        GTD - Good Till Date
        reduce_only(reduceOnly): true, false
        """
        var query_values = QueryParams()
        query_values["symbol"] = symbol
        query_values["side"] = side
        query_values["type"] = type_
        if position_side != "":
            query_values["positionSide"] = position_side
        if not quantity.is_zero():
            query_values["quantity"] = quantity.to_string()
        if not price.is_zero():
            query_values["price"] = price.to_string()
        query_values["timeInForce"] = time_in_force
        if reduce_only:
            query_values["reduceOnly"] = "true"
        var query_str = query_values.to_string()
        # logd(query_str)

        var ret = self.do_post("/fapi/v1/order", query_str, True)
        # print(ret)
        if ret.status_code != 200:
            raise Error(
                "error status_code="
                + str(ret.status_code)
                + " text="
                + ret.text
            )

        # {"code":-1102,"msg":"Mandatory parameter 'timeinforce' was not sent, was empty/null, or malformed."}
        # {"code":-1102,"msg":"Mandatory parameter 'price' was not sent, was empty/null, or malformed."}
        # {"code":-4061,"msg":"Order's position side does not match user's setting."}
        # {"orderId":237740210409,"symbol":"BTCUSDT","status":"NEW","clientOrderId":"62ayQ4MjyVIaCkvDX00dhh","price":"20000.00","avgPrice":"0.00","origQty":"0.010","executedQty":"0.000","cumQty":"0.000","cumQuote":"0.00000","timeInForce":"GTC","type":"LIMIT","reduceOnly":false,"closePosition":false,"side":"BUY","positionSide":"LONG","stopPrice":"0.00","workingType":"CONTRACT_PRICE","priceProtect":false,"origType":"LIMIT","priceMatch":"NONE","selfTradePreventionMode":"NONE","goodTillDate":0,"updateTime":1704291033033}
        # logd(ret.body)

        var parser = DomParser(ParserBufferSize)
        var doc = parser.parse(ret.text)
        var code = doc.get_int("code")
        if code != 0:
            var msg = doc.get_str("msg")
            raise Error("error code=" + str(code) + ", msg=" + msg)

        var _order_id = doc.get_int("orderId")
        var _order_client_id = doc.get_str("clientOrderId")

        _ = doc^
        _ = parser^

        var order_info = OrderInfo()
        order_info.order_id = _order_id
        order_info.order_client_id = _order_client_id
        return order_info

    fn cancel_order(
        self,
        symbol: String,
        order_id: String = "",
        order_client_id: String = "",
    ) raises -> OrderInfo:
        var query_values = QueryParams()
        query_values["symbol"] = symbol
        if order_id != "":
            query_values["orderId"] = order_id
        if order_client_id != "":
            query_values["origClientOrderId"] = order_client_id
        var query_str = query_values.to_string()
        # logd(query_str)

        var ret = self.do_delete("/fapi/v1/order", query_str, True)
        # print(ret)
        if ret.status_code != 200:
            raise Error(
                "error status_code="
                + str(ret.status_code)
                + " text="
                + str(ret.status_code)
            )

        # {"code":-2015,"msg":"Invalid API-key, IP, or permissions for action, request ip: 100.100.100.100"}
        # {"orderId":237740210409,"symbol":"BTCUSDT","status":"CANCELED","clientOrderId":"62ayQ4MjyVIaCkvDX00dhh","price":"20000.00","avgPrice":"0.00","origQty":"0.010","executedQty":"0.000","cumQty":"0.000","cumQuote":"0.00000","timeInForce":"GTC","type":"LIMIT","reduceOnly":false,"closePosition":false,"side":"BUY","positionSide":"LONG","stopPrice":"0.00","workingType":"CONTRACT_PRICE","priceProtect":false,"origType":"LIMIT","priceMatch":"NONE","selfTradePreventionMode":"NONE","goodTillDate":0,"updateTime":1704339843127}
        # logd(ret.body)

        var parser = DomParser(ParserBufferSize)
        var doc = parser.parse(ret.text)
        var code = doc.get_int("code")
        if code != 0:
            var msg = doc.get_str("msg")
            raise Error("error code=" + str(code) + ", msg=" + msg)

        var _order_id = doc.get_int("orderId")
        var _order_client_id = doc.get_str("clientOrderId")

        _ = doc^
        _ = parser^

        var order_info = OrderInfo()
        order_info.order_id = _order_id
        order_info.order_client_id = _order_client_id
        return order_info

    fn generate_listen_key(
        self,
    ) raises -> String:
        """
        Generate listen key (USER_STREAM)
        """
        var ret = self.do_post("/fapi/v1/listenKey", "", True)
        # print(ret)
        if ret.status_code != 200:
            raise Error(
                "error status_code="
                + str(ret.status_code)
                + " text="
                + ret.text
            )

        logd("text=" + ret.text)

        var parser = DomParser(ParserBufferSize)
        var doc = parser.parse(ret.text)
        var code = doc.get_int("code")
        if code != 0:
            var msg = doc.get_str("msg")
            raise Error("error code=" + str(code) + ", msg=" + msg)

        var listen_key = doc.get_str("listenKey")

        _ = doc^
        _ = parser^

        return listen_key

    fn extend_listen_key(
        self,
    ) raises -> Bool:
        """
        Extend listen key (USER_STREAM)
        """
        var ret = self.do_put("/fapi/v1/listenKey", "", True)
        # print(ret)
        if ret.status_code != 200:
            raise Error(
                "error status_code="
                + str(ret.status_code)
                + " text="
                + ret.text
            )

        logd("text=" + ret.text)
        # {}

        var parser = DomParser(ParserBufferSize)
        var doc = parser.parse(ret.text)
        var code = doc.get_int("code")
        if code != 0:
            var msg = doc.get_str("msg")
            raise Error("error code=" + str(code) + ", msg=" + msg)

        _ = doc^
        _ = parser^

        return True

    fn do_sign(self, inout headers: Headers, data: String) raises -> String:
        var ts_str = "recvWindow=5000&timestamp=" + str(time_ms())
        # var recv_window_str = "5000"
        var payload = data + "&" + ts_str if data != "" else ts_str
        var signature = hmac_sha256_hex(payload, self.secret_key)
        headers["X-MBX-APIKEY"] = self.access_key
        return payload + "&signature=" + signature

    fn do_delete(
        self, path: StringLiteral, param: String, sign: Bool
    ) raises -> HttpResponse:
        var headers = Headers()
        var param_ = self.do_sign(headers, param) if sign else param

        var request_path: String
        if param_ != "":
            request_path = str(path) + "?" + param_
        else:
            request_path = path
        # logd("request_path: " + request_path)
        # logd("param: " + param_)
        return self.client.delete(request_path, headers=headers)

    fn do_get(
        self, path: StringLiteral, param: String, sign: Bool
    ) raises -> HttpResponse:
        var headers = Headers()
        # headers["Connection"] = "Keep-Alive"
        var param_ = self.do_sign(headers, param) if sign else param

        var request_path: String
        if param_ != "":
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
        headers["Content-Type"] = "application/json"
        if sign:
            var body_ = self.do_sign(headers, body)
            # logi("body_=" + body_)
            # return HttpResponse(200, "")
            return self.client.post(path, data=body_, headers=headers)
        else:
            return self.client.post(path, data=body, headers=headers)

    fn do_put(
        self, path: StringLiteral, body: String, sign: Bool
    ) raises -> HttpResponse:
        var headers = Headers()
        headers["Content-Type"] = "application/json"
        if sign:
            var body_ = self.do_sign(headers, body)
            # logi("body_=" + body_)
            # return HttpResponse(200, "")
            return self.client.put(path, data=body_, headers=headers)
        else:
            return self.client.put(path, data=body, headers=headers)
