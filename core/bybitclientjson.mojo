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
from .sign import hmac_sha256_b64
from stdlib_extensions.time import time_ns


fn test_json_parse() raises:
    let body = '{"retCode":0,"retMsg":"OK","result":{"category":"linear","list":[{"symbol":"BTCUSDT","contractType":"LinearPerpetual","status":"Trading","baseCoin":"BTC","quoteCoin":"USDT","launchTime":"1585526400000","deliveryTime":"0","deliveryFeeRate":"","priceScale":"2","leverageFilter":{"minLeverage":"1","maxLeverage":"100.00","leverageStep":"0.01"},"priceFilter":{"minPrice":"0.10","maxPrice":"199999.80","tickSize":"0.10"},"lotSizeFilter":{"maxOrderQty":"100.000","minOrderQty":"0.001","qtyStep":"0.001","postOnlyMaxOrderQty":"1000.000"},"unifiedMarginTrade":true,"fundingInterval":480,"settleCoin":"USDT","copyTrading":"normalOnly"}],"nextPageCursor":""},"retExtInfo":{},"time":1696236288675}'

    let tick_size: Float64 = 0
    let stepSize: Float64 = 0

    let od_parser = OndemandParser(1000 * 100)
    let doc = od_parser.parse(body)
    let ret_code = doc.get_int("retCode")
    let ret_msg = doc.get_str("retMsg")
    if ret_code != 0:
        raise "error retCode=" + String(ret_code) + ", retMsg=" + String(ret_msg)

    let result = doc.get_object("result")
    let result_list = result.get_array("list")

    if result_list.__len__() == 0:
        raise "error list length is 0"

    let list_iter = result_list.iter()
    while list_iter.has_value():
        let obj = list_iter.get()
        let symbol_ = obj.get_str("symbol")

        let priceFilter = obj.get_object("priceFilter")
        let tick_size = strtod(priceFilter.get_str("tickSize"))
        let lotSizeFilter = obj.get_object("lotSizeFilter")
        let stepSize = strtod(lotSizeFilter.get_str("qtyStep"))

        logi("stepSize: " + String(stepSize))
        _ = obj

        list_iter.step()

    _ = list_iter
    _ = result_list
    _ = result
    _ = doc
    _ = od_parser


fn test_parse_fetch_kline_body() raises:
    let body = '{"retCode":0,"retMsg":"OK","result":{"symbol":"BTCUSDT","category":"linear","list":[["1687589640000","30709.9","30710.4","30709.9","30710.3","3.655","112245.7381"],["1687589580000","30707.9","30710","30704.7","30709.9","21.984","675041.8648"],["1687589520000","30708","30714.7","30705","30707.9","33.378","1025097.6459"],["1687589460000","30689.9","30710.3","30689.9","30708","51.984","1595858.2778"],["1687589400000","30678.6","30690.9","30678.5","30689.9","38.747","1188886.4093"]]},"retExtInfo":{},"time":1687589659062}'

    var res = list[KlineItem]()
    let dom_parser = DomParser(1000 * 100)
    let doc = dom_parser.parse(body)
    let ret_code = doc.get_int("retCode")
    let ret_msg = doc.get_str("retMsg")
    if ret_code != 0:
        raise "error retCode=" + str(ret_code) + ", retMsg=" + ret_msg

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

        list_iter.step()

    _ = doc
    _ = dom_parser

    for index in range(len(res)):
        let item = res[index]
        logi(str(item))


fn test_orderbook_parse_body() raises:
    let body = '{"result":{"a":[["30604.8","174.267"],["30648.6","0.002"],["30649.1","0.001"],["30650","1.119"],["30650.3","0.01"],["30650.8","0.001"],["30651.6","0.001"],["30652","0.001"],["30652.4","0.062"],["30652.5","0.001"]],"b":[["30598.7","142.31"],["30578.2","0.004"],["30575.3","0.001"],["30571.8","0.001"],["30571.1","0.002"],["30568.5","0.002"],["30566.6","0.005"],["30565.6","0.01"],["30565.5","0.061"],["30563","0.001"]],"s":"BTCUSDT","ts":1689132447413,"u":5223166},"retCode":0,"retExtInfo":{},"retMsg":"OK","time":1689132448224}'

    var asks = list[OrderBookItem]()
    var bids = list[OrderBookItem]()

    let dom_parser = DomParser(1000 * 100)
    let doc = dom_parser.parse(body)
    let ret_code = doc.get_int("retCode")
    let ret_msg = doc.get_str("retMsg")
    if ret_code != 0:
        raise "error retCode=" + str(ret_code) + ", retMsg=" + ret_msg

    let result = doc.get_object("result")
    let a_list = result.get_array("a")

    let list_iter_a = a_list.iter()

    while list_iter_a.has_element():
        let obj = list_iter_a.get()
        let i_arr_list = obj.array()

        let price = strtod(i_arr_list.at_str(0))
        let qty = strtod(i_arr_list.at_str(1))

        asks.append(OrderBookItem(price, qty))

        list_iter_a.step()

    let b_list = result.get_array("b")

    let list_iter_b = b_list.iter()

    while list_iter_b.has_element():
        let obj = list_iter_b.get()
        let i_arr_list = obj.array()

        let price = strtod(i_arr_list.at_str(0))
        let qty = strtod(i_arr_list.at_str(1))

        bids.append(OrderBookItem(price, qty))

        list_iter_b.step()

    let ob = OrderBook(asks, bids)

    _ = doc
    _ = dom_parser

    logi("-----asks-----")
    for index in range(len(ob.asks)):
        let item = ob.asks[index]
        logi(str(item))

    logi("-----bids-----")
    for index in range(len(ob.bids)):
        let item = ob.bids[index]
        logi(str(item))


fn test_fetch_balance_parse_body() raises:
    let body = '{"retCode":0,"retMsg":"OK","result":{"list":[{"accountType":"CONTRACT","accountIMRate":"","accountMMRate":"","totalEquity":"","totalWalletBalance":"","totalMarginBalance":"","totalAvailableBalance":"","totalPerpUPL":"","totalInitialMargin":"","totalMaintenanceMargin":"","accountLTV":"","coin":[{"coin":"USDT","equity":"100.0954887","usdValue":"","walletBalance":"100.0954887","borrowAmount":"","availableToBorrow":"","availableToWithdraw":"100.0954887","accruedInterest":"","totalOrderIM":"0","totalPositionIM":"0","totalPositionMM":"","unrealisedPnl":"0","cumRealisedPnl":"1.0954887"}]}]},"retExtInfo":{},"time":1701876547097}'

    let coin = "USDT"

    let parser = OndemandParser(1000 * 100)
    let doc = parser.parse(body)

    let ret_code = doc.get_int("retCode")
    let ret_msg = doc.get_str("retMsg")
    if ret_code != 0:
        raise Error("error retCode=" + str(ret_code) + ", retMsg=" + ret_msg)

    let result_list = doc.get_object("result").get_array("list")
    let list_iter = result_list.iter()

    while list_iter.has_value():
        let obj = list_iter.get()
        let account_type = obj.get_str("accountType")
        logi("account_type=" + account_type)
        if account_type == "CONTRACT":
            let coin_list = obj.get_array("coin")
            let coin_iter = coin_list.iter()
            while coin_iter.has_value():
                let coin_obj = coin_iter.get()
                let coin_name = coin_obj.get_str("coin")
                logi("coin_name: " + coin_name)
                if coin_name != coin:
                    continue
                let equity = strtod(coin_obj.get_str("equity"))
                let available_to_withdraw = strtod(
                    coin_obj.get_str("availableToWithdraw")
                )
                let wallet_balance = strtod(coin_obj.get_str("walletBalance"))
                let total_order_im = strtod(coin_obj.get_str("totalOrderIM"))
                let total_position_im = strtod(coin_obj.get_str("totalPositionIM"))
                coin_iter.step()
        elif account_type == "SPOT":
            pass

        list_iter.step()

    _ = doc
    _ = parser


fn test_fetch_orders_body_parse() raises:
    let body = String(
        '{"retCode":0,"retMsg":"OK","result":{"list":[],"nextPageCursor":"","category":"linear"},"retExtInfo":{},"time":1702103872882}'
    )
    var res = list[OrderInfo]()
    logd("300000")

    let parser = DomParser(1024 * 64)
    let doc = parser.parse(body)

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

    _ = result
    _ = result_list
    _ = doc
    _ = parser

    for index in range(len(res)):
        let item = res[index]
        logi(str(item))

    logi("OK")
