import time
from memory import unsafe
from testing import assert_equal, assert_true, assert_false
from ylstdlib.time import time_ns
from ylstdlib import *

from base.mo import *
from base.c import *
from base.str_cache import *
from base.sj_dom import *
from base.sj_ondemand import OndemandParser
from base.sonic import *
from base.far import Far
from base.fixed import Fixed
from base.ssmap import SSMap
from base.httpclient import HttpClient, VERB_GET, Headers, QueryParams
from base.websocket import *
from base.moutil import *
from base.thread import *
from base.ti import *
from core.bybitmodel import *
from core.bybitclient import *
from core.bybitclientjson import *
from core.bybitws import *
from core.models import *
from trade.pos import LocalPosition
from trade.config import *
from trade.platform import Platform


fn test_c_str() raises:
    var s = String("100000001")
    var c_str = to_char_ptr(s)
    assert_true(c_str != UnsafePointer[c_char]())


fn test_decimal_places() raises:
    var dp = decimal_places(0.003)
    assert_equal(dp, 3)


fn test_fixed() raises:
    var f1 = Fixed("1.0")
    assert_equal(str(f1), "1")
    var f1_23456 = Fixed("1.23456")
    assert_equal(str(f1_23456), "1.23456")

    assert_true(Fixed(100) == Fixed(100))
    assert_true(Fixed(100) != Fixed(50))
    assert_true(Fixed(100) < Fixed(150))
    assert_true(Fixed(100) <= Fixed(150))
    assert_true(Fixed(100) > Fixed(80))
    assert_true(Fixed(100) >= Fixed(100))

    var f001 = Fixed("0.01")
    var f00a_copy = f001
    assert_equal(str(f00a_copy), "0.01")

    assert_equal(str(Fixed.zero), "0")

    assert_equal(str(Fixed(0)), "0")

    assert_equal(str(Fixed(-0.123)), "-0.123")
    assert_equal(str(Fixed(-10.123)), "-10.123")
    assert_equal(str(Fixed(-10.1)), "-10.1")

    assert_equal(str(Fixed("-10.123456789123")), "-10.123456789123")
    assert_equal(Fixed("-10.123"), Fixed(-10.123))

    assert_true(Fixed(100) > Fixed(-100))
    assert_true(Fixed(0) > Fixed(-100))
    assert_true(Fixed(100) > Fixed(0))
    assert_true(Fixed(-0.1) < Fixed(0))

    assert_true(-Fixed(-0.1) == Fixed(0.1))

    var a0_1 = Fixed("0.10000000000000001")
    assert_true(a0_1 == Fixed(0.1))


fn test_hmac_sha256_b64() raises:
    var a = hmac_sha256_b64(String("abc"), String("abb"))
    var b = hmac_sha256_hex(String("abc"), String("abb"))
    assert_equal(a, "Aolc8wCK4JXl64kBgxh3ANIFu6jXCC6bbfKYplV4Z+A=")
    assert_equal(b, "02895cf3008ae095e5eb890183187700d205bba8d7082e9b6df298a6557867e0")


# fn test_lockfree_queue() raises:
#     var df_cb = FlxMap().add("a", 7).add("b", 8).add("c", "hello").finish()

#     var ptr = df_cb.get[0, DTypePointer[DType.uint8]]()
    
#     var v = iovec(df_cb)

#     var q = LockfreeQueue()
#     var v_ptr = Pointer[iovec].address_of(v)
#     var ok = q.push(v_ptr)
#     # logi("ok=" + str(ok))
#     var v2 = iovec()
#     var ok2 = q.pop(Pointer[iovec].address_of(v2))
#     # logi("ok2=" + str(ok2))
#     if v.iov_base != v2.iov_base:
#         assert_true(False)
#     if v.iov_len != v2.iov_len:
#         assert_true(False)

#     var df_cb1 = v2.to_data()
    
#     var value = FlxValue(df_cb1)
#     var a = value["a"].int()
#     var c = value["c"].string()
#     assert_equal(a, 7)
#     assert_equal(c, "hello")

#     ptr.free()


fn test_str_cache() raises:
    var sc = MyStringCache()
    var res = sc.set_string("Hello")
    var s = c_str_to_string(res.data, res.len)
    # logi("s=" + s)
    assert_equal(s, "Hello")


fn test_query_values() raises:
    var qp = QueryParams()
    qp["category"] = "BTCUSDT"
    var s = qp.to_string()


fn test_sonic_raw() raises:
    var doc = seq_sonic_json_document_new()
    var alloc = seq_sonic_json_document_get_allocator(doc)
    seq_sonic_json_document_set_object(doc)
    var key = String("a")
    var value = String("12345")
    seq_sonic_json_document_add_string(doc, alloc, str_as_scalar_pointer(key), len(key), str_as_scalar_pointer(value), len(value))
    
    var result = UnsafePointer[c_schar].alloc(1024)
    var n = seq_sonic_json_document_to_string(doc, result)
    var result_str = c_str_to_string(result, n)
    result.free()
    assert_equal(result_str, '{"a":"12345"}')
    seq_sonic_json_document_free(doc)

    key._strref_keepalive()
    value._strref_keepalive()


fn test_sonic() raises:
    var doc = SonicDocument()
    doc.set_object()
    var v = "12345"
    doc.add_string("a", v)
    var s = doc.to_string()
    assert_equal(s, '{"a":"12345"}')
    _ = doc ^


fn test_subscribe_message() raises:
    var id = "SYFjgKDMWl-xdy_Gn-A0_"
    var _subscription_topics_str = String("orderbook.1.BTCUSDT")
    var yy_doc = yyjson_mut_doc()
    yy_doc.add_str("req_id", id)
    yy_doc.add_str("op", "subscribe")
    var values = List[String]()
    var topics = _subscription_topics_str.split(",")
    for topic in topics:
        values.append(topic[])
    yy_doc.arr_with_str("args", values)
    var body_str = yy_doc.mut_write()
    # logi("send: " + body_str)
    assert_true(body_str != "")
    # assert_equal(body_str, '{"req_id":"SYFjgKDMWl-xdy_Gn-A0_","op":"subscribe"}')
    assert_equal(body_str, '{"req_id":"SYFjgKDMWl-xdy_Gn-A0_","op":"subscribe","args":["orderbook.1.BTCUSDT"]}')


fn test_order_info() raises:
    var orders = List[OrderInfo]()

    var order_info =
        OrderInfo(1, String("cf7a63a5-4c78-40f5-be9e-393645bb7339"), String("BTCUSDT"), String("Buy"), String("Limit"), 10000.0, 0.01,
                0, String("New"), String("1702776926299"), String("1702776926303"),
                0, 0, String("GTC"), False, "")
    orders.append(order_info)

    assert_equal(len(orders), 1)

    assert_equal(order_info.order_id, "cf7a63a5-4c78-40f5-be9e-393645bb7339")
    assert_equal(order_info.symbol, "BTCUSDT")
    assert_equal(order_info.side , "Buy")
    assert_equal(order_info.type_, "Limit")
    assert_equal(order_info.price, 10000.0)
    assert_equal(order_info.qty, 0.01)
    assert_equal(order_info.cum_exec_qty, 0.0)
    assert_equal(order_info.status, "New")
    assert_equal(order_info.created_time, "1702776926299")
    assert_equal(order_info.updated_time, "1702776926303")
    assert_equal(order_info.avg_price, 0.0)
    assert_equal(order_info.cum_exec_fee, 0.0)
    assert_equal(order_info.time_in_force, "GTC")
    assert_equal(order_info.reduce_only, False)
    assert_equal(order_info.order_link_id, "")


fn test_base() raises:
    var s = String('{"retCode":1001,"retMsg":"OK","result":{"category":"linear","list":[],"nextPageCursor":""},"retExtInfo":{},"time":1696236288675}')
    var op = OndemandParser(1000 * 1000)
    var doc = op.parse(s)

    var key = "retCode"
    var ret_code = doc.get_int(key)
    assert_equal(ret_code, 1001)

    var key1 = "retMsg"
    var retMsg = doc.get_str(key1)
    assert_equal(retMsg, "OK")

    var result = doc.get_object("result")
    var category = result.get_str("category")

    assert_equal(category, "linear")

    var list = result.get_array("list")
    var iter = list.iter()
    while iter.has_value():
        iter.step()

    _ = doc ^
    _ = op ^


fn test_parse_order() raises:
    var s = String('{"topic":"order","id":"0305b86c-e2ac-437d-89dc-3caff6c13c9e","creationTime":1702776926306,"data":[{"avgPrice":"","blockTradeId":"","cancelType":"UNKNOWN","category":"linear","closeOnTrigger":false,"createdTime":"1702776926299","cumExecFee":"0","cumExecQty":"0","cumExecValue":"0","leavesQty":"0.01","leavesValue":"100","orderId":"cf7a63a5-4c78-40f5-be9e-393645bb7339","orderIv":"","isLeverage":"","lastPriceOnCreated":"42184.00","orderStatus":"New","orderLinkId":"","orderType":"Limit","positionIdx":1,"price":"10000.00","qty":"0.01","reduceOnly":false,"rejectReason":"EC_NoError","side":"Buy","slTriggerBy":"UNKNOWN","stopLoss":"0.00","stopOrderType":"UNKNOWN","symbol":"BTCUSDT","takeProfit":"0.00","timeInForce":"GTC","tpTriggerBy":"UNKNOWN","triggerBy":"UNKNOWN","triggerDirection":0,"triggerPrice":"0.00","updatedTime":"1702776926303","placeType":"","smpType":"None","smpGroup":0,"smpOrderId":"","tpslMode":"UNKNOWN","createType":"CreateByUser","tpLimitPrice":"","slLimitPrice":""}]}')
    var op = OndemandParser(1000 * 1000)
    var doc = op.parse(s)

    var data = doc.get_array("data")

    assert_equal(len(data), 1)

    var orders = List[OrderInfo]()

    var iter = data.iter()
    while iter.has_value():
        var item = iter.get_object()
        var posIdx = item.get_int("positionIdx")
        var orderId = item.get_str("orderId")
        var sym = item.get_str("symbol")
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

        var order_info0 =
            OrderInfo(posIdx, orderId, sym, side, orderType, price, qty,
                    cumExecQty, orderStatus, createdTime, updatedTime,
                    avgPrice, cumExecFee, tif, reduceOnly, orderLinkId)
        orders.append(order_info0)

        iter.step()

    _ = data ^
    _ = doc ^
    _ = op ^

    assert_equal(len(orders), 1)

    var order_info = orders[0]

    assert_equal(order_info.order_id, "cf7a63a5-4c78-40f5-be9e-393645bb7339")
    assert_equal(order_info.symbol, "BTCUSDT")
    assert_equal(order_info.side, "Buy")
    assert_equal(order_info.type_, "Limit")
    assert_equal(order_info.price, 10000.0)  # ok
    assert_equal(order_info.qty, 0.01)
    assert_equal(order_info.cum_exec_qty, 0.0)
    assert_equal(order_info.status, "New")
    assert_equal(order_info.created_time, "1702776926299")
    assert_equal(order_info.updated_time, "1702776926303")
    assert_equal(order_info.avg_price, 0.0)
    assert_equal(order_info.cum_exec_fee, 0.0)
    assert_equal(order_info.time_in_force, "GTC")
    assert_equal(order_info.reduce_only, False)
    assert_equal(order_info.order_link_id, "")


fn test_parse_position() raises:
    var s = String('{"topic":"position","id":"d890e61f-141f-4994-a26d-eafc002ac342","creationTime":1702780274788,"data":[{"bustPrice":"0.10","category":"linear","createdTime":"1682125794703","cumRealisedPnl":"849.94008886","entryPrice":"42182.55","leverage":"1","liqPrice":"","markPrice":"42056.10","positionBalance":"846.18","positionIdx":1,"positionMM":"0.00001","positionIM":"8.43651","positionStatus":"Normal","positionValue":"843.651","riskId":1,"riskLimitValue":"2000000","side":"Buy","size":"0.02","stopLoss":"0.00","symbol":"BTCUSDT","takeProfit":"0.00","tpslMode":"Full","tradeMode":0,"autoAddMargin":0,"trailingStop":"0.00","unrealisedPnl":"-2.529","updatedTime":"1702780274785","adlRankIndicator":2,"seq":8793822126,"isReduceOnly":false,"mmrSysUpdateTime":"","leverageSysUpdatedTime":""},{"bustPrice":"0.00","category":"linear","createdTime":"1682125794703","cumRealisedPnl":"-60.88336213","entryPrice":"0","leverage":"1","liqPrice":"","markPrice":"42056.10","positionBalance":"0","positionIdx":2,"positionMM":"0","positionIM":"0","positionStatus":"Normal","positionValue":"0","riskId":1,"riskLimitValue":"2000000","side":"None","size":"0","stopLoss":"0.00","symbol":"BTCUSDT","takeProfit":"0.00","tpslMode":"Full","tradeMode":0,"autoAddMargin":0,"trailingStop":"0.00","unrealisedPnl":"0","updatedTime":"1702780274785","adlRankIndicator":0,"seq":8793673384,"isReduceOnly":false,"mmrSysUpdateTime":"","leverageSysUpdatedTime":""}]}')
    var op = OndemandParser(1000 * 1000)
    var doc = op.parse(s)

    var data = doc.get_array("data")

    assert_equal(len(data), 2)

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
        var leverage = item.get_float("leverage")
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
        # logd("postion_info: " + str(position_info))
        iter.step()

    _ = data ^
    _ = doc ^
    _ = op ^

    assert_equal(len(positions), 2)

    var pos0 = positions[0]
    var pos1 = positions[1]

    assert_equal(pos0.position_idx, 1)
    assert_equal(pos0.symbol, "BTCUSDT")
    assert_equal(pos0.side, "Buy")

    assert_equal(pos1.position_idx, 2)
    assert_equal(pos1.symbol, "BTCUSDT")
    assert_equal(pos1.side, "None")


fn test_parse_orderbook() raises:
    var s = String('{"topic":"orderbook.1.BTCUSDT","type":"snapshot","ts":1702645020909,"data":{"s":"BTCUSDT","b":[["42663.50","0.910"]],"a":[["42663.60","11.446"]],"u":2768099,"seq":108881526829},"cts":1702645020906}')
    var parser = DomParser(1000 * 100)
    var doc = parser.parse(s)

    # var op = doc.get_str("op")
    # assert_equal(op, "")

    var topic = doc.get_str("topic")
    assert_equal(topic, "orderbook.1.BTCUSDT")

    var data = doc.get_object("data")

    var a = data.get_array("a")
    var a_iter = a.iter()

    var orderbook = OrderBookLite()

    while a_iter.has_element():
        var obj = a_iter.get()
        var i_arr_list = obj.array()
        var price = i_arr_list.at_str(0)
        var qty = i_arr_list.at_str(1)
        # # logd("price: " + str(price))
        # # logd("qty: " + str(qty))
        orderbook.asks.append(OrderBookLevel(Fixed(price), Fixed(qty)))
        _ = obj ^
        a_iter.step()

    _ = a ^

    var b = data.get_array("b")
    var b_iter = b.iter()

    while b_iter.has_element():
        var obj = b_iter.get()
        var i_arr_list = obj.array()
        var price = i_arr_list.at_str(0)
        var qty = i_arr_list.at_str(1)
        # # logd("price: " + str(price))
        # # logd("qty: " + str(qty))
        orderbook.bids.append(OrderBookLevel(Fixed(price), Fixed(qty)))
        _ = obj ^
        b_iter.step()

    _ = b ^
    _ = data ^

    _ = doc ^
    _ = parser ^

    assert_equal(len(orderbook.asks), 1)
    assert_equal(len(orderbook.bids), 1)

    var p = Fixed("1.0")
    var ps = str(p)

    for i in orderbook.asks:
        # logd("price: " + str(i.price) + " qty: " + str(i.qty))
        pass


fn test_app_config() raises:
    var app_config = load_config("config.example.toml")
    assert_equal(app_config.testnet, True)
    assert_equal(app_config.category, "linear")
    assert_equal(app_config.symbols, "BTCUSDT")
    assert_equal(app_config.depth, 1)


fn test_platform() raises:
    var asks_ = seq_skiplist_new(True)
    seq_skiplist_free(asks_)

    var app_config = AppConfig()
    app_config.symbols = "BTCUSDT"
    var platform = Platform(app_config)
    # var platform_ = platform ^
    platform.setup()
    var asks = List[OrderBookLevel]()
    var bids = List[OrderBookLevel]()
    # {"topic":"orderbook.1.BTCUSDT","type":"snapshot","ts":1704262157072,"data":{"s":"BTCUSDT","b":[["45195.00","7.794"]],"a":[["45195.10","3.567"]],"u":11104722,"seq":114545691619},"cts":1704262157070}
    asks.append(OrderBookLevel(Fixed("45195.10"), Fixed("3.567")))
    bids.append(OrderBookLevel(Fixed("45195.00"), Fixed("7.794")))
    for i in range(100):
        platform.on_update_orderbook("BTCUSDT", "snapshot", asks, bids)
    
    platform.free()


fn test_orderbook() raises:
    # var s = '{"topic":"orderbook.1.BTCUSDT","type":"delta","ts":1703836880546,"data":{"s":"BTCUSDT","b":[],"a":[["42356.10","51.549"]],"u":327868,"seq":8817611928},"cts":1703836880544}'
    # var s = '{"success":true,"ret_msg":"pong","conn_id":"d87b8332-6029-4e42-93e2-103e65c35517","req_id":"8_Abvtu2BNj5OKB_Wye_l","op":"ping"}'
    var s = String('{"topic":"orderbook.1.BTCUSDT","type":"delta","ts":1703838824626,"data":{"s":"BTCUSDT","b":[["42440.40","90.668"]],"a":[],"u":329020,"seq":8817654104},"cts":1703838824623}')
    var parser = DomParser(100 * 1024)
    var doc = parser.parse(s)
    var topic = doc.get_str("topic")

    if "orderbook." in topic:
        logd("topic")


fn test_parse_orderbook_bids() raises:
    var s = String('{"topic":"orderbook.1.BTCUSDT","type":"delta","ts":1703838824626,"data":{"s":"BTCUSDT","b":[["42440.40","90.668"]],"a":[],"u":329020,"seq":8817654104},"cts":1703838824623}')
    var dom_parser = DomParser(1000 * 100)
    var doc = dom_parser.parse(s)

    var op = doc.get_str("op")
    assert_equal(op, "")

    var topic = doc.get_str("topic")
    assert_equal(topic, "orderbook.1.BTCUSDT")

    var data = doc.get_object("data")

    var a = data.get_array("a")
    var a_iter = a.iter()

    var orderbook = OrderBookLite("BTCUSDT")

    while a_iter.has_element():
        var obj = a_iter.get()
        var i_arr_list = obj.array()
        var price = i_arr_list.at_str(0)
        var qty = i_arr_list.at_str(1)
        # logd("price: " + str(price))
        # logd("qty: " + str(qty))
        orderbook.asks.append(OrderBookLevel(Fixed(price), Fixed(qty)))
        a_iter.step()

    var b = data.get_array("b")
    var b_iter = b.iter()

    while b_iter.has_element():
        var obj = b_iter.get()
        var i_arr_list = obj.array()
        var price = i_arr_list.at_str(0)
        var qty = i_arr_list.at_str(1)
        # logd("price: " + str(price))
        # logd("qty: " + str(qty))
        orderbook.bids.append(OrderBookLevel(Fixed(price), Fixed(qty)))
        b_iter.step()

    _ = data ^

    _ = doc ^
    _ = dom_parser ^
    _ = s ^

    assert_equal(len(orderbook.asks), 0)
    assert_equal(len(orderbook.bids), 1)

    for i in orderbook.asks:
        logd("price: " + str(i[].price) + " qty: " + str(i[].qty))

    
fn test_ti() raises:
    var info = seq_ti_get_first_indicator()
    while True:
        var is_valided = seq_ti_is_valid_indicator(info)
        if not is_valided:
            break
        
        # var info_ = info.value[]
        # var info_ = move_from_pointee(info)
        var input_names = info[].input_names()
        # var input_names_str = list_to_str(input_names)
        # logi("input_names_str=" + input_names_str)
        var option_names = info[].option_names()
        # var option_names_str = list_to_str(option_names)
        # logi("option_names_str=" + option_names_str)
        var output_names = info[].output_names()
        # var output_names_str = list_to_str(output_names)
        # logi("output_names_str=" + output_names_str)
        info = seq_ti_get_next_indicator(info)


# fn test_ti3() raises:
#     var data_in = Pointer[Float64].alloc(10)
#     # 5, 8, 12, 11, 9, 8, 7, 10, 11, 13
#     data_in.store(0, 5)
#     data_in.store(1, 8)
#     data_in.store(2, 12)
#     data_in.store(3, 11)
#     data_in.store(4, 9)
#     data_in.store(5, 8)
#     data_in.store(6, 7)
#     data_in.store(7, 10)
#     data_in.store(8, 11)
#     data_in.store(9, 13)
#     var options = Pointer[Float64].alloc(1)
#     options.store(0, 3)
#     var data_out = Pointer[Float64].alloc(10)
#     var inputs = Pointer[Pointer[Float64]].alloc(1)
#     inputs.store(0, data_in)
#     var outputs = Pointer[Pointer[Float64]].alloc(1)
#     outputs.store(0, data_out)
#     seq_test_ti3(inputs, 10, options, outputs)

#     data_in.free()
#     data_out.free()
#     options.free()
#     inputs.free()
#     outputs.free()


fn test_ti_call() raises:
    var s = String("sma")
    var info = seq_ti_find_indicator(str_as_scalar_pointer(s))
    assert_equal(seq_ti_is_valid_indicator(info), True)

    var input_length: c_int = 10

    var data_in = UnsafePointer[Float64].alloc(int(input_length))
    data_in[0] = 5
    data_in[1] = 8
    data_in[2] = 12
    data_in[3] = 11
    data_in[4] = 9
    data_in[5] = 8
    data_in[6] = 7
    data_in[7] = 10
    data_in[8] = 11
    data_in[9] = 13
    var options = UnsafePointer[Float64].alloc(1)
    options[0] = 3
    
    var inputs = UnsafePointer[UnsafePointer[Float64]].alloc(1)
    inputs[0] = data_in
    
    var start = seq_ti_indicator_start(info, options)
    var output_length = input_length - start

    var outputs = UnsafePointer[UnsafePointer[Float64]].alloc(1)
    var data_out = UnsafePointer[Float64].alloc(int(output_length))
    outputs[0] = data_out
    var ok = seq_ti_indicator_run(info, input_length, inputs, options, outputs)
    assert_equal(ok, True)

    data_in.free()
    data_out.free()
    options.free()
    inputs.free()
    outputs.free()


fn test_ti_call_at_index() raises:
    var info = seq_ti_indicator_at_index(72)
    assert_equal(seq_ti_is_valid_indicator(info), True)

    var input_length: c_int = 10

    var data_in = UnsafePointer[Float64].alloc(int(input_length))
    data_in[0] = 5
    data_in[1] = 8
    data_in[2] = 12
    data_in[3] = 11
    data_in[4] = 9
    data_in[5] = 8
    data_in[6] = 7
    data_in[7] = 10
    data_in[8] = 11
    data_in[9] = 13
    var options = UnsafePointer[Float64].alloc(1)
    options[0] = 3
    
    var inputs = UnsafePointer[UnsafePointer[Float64]].alloc(1)
    inputs[0] = data_in
    
    var start = seq_ti_indicator_start(info, options)
    var output_length = input_length - start

    var outputs = UnsafePointer[UnsafePointer[Float64]].alloc(1)
    var data_out = UnsafePointer[Float64].alloc(int(output_length))
    outputs[0] = data_out
    var ok = seq_ti_indicator_run(info, input_length, inputs, options, outputs)
    assert_equal(ok, True)

    data_in.free()
    data_out.free()
    options.free()
    inputs.free()
    outputs.free()


fn test_ti_call_at_index2() raises:
    var info = seq_ti_indicator_at_index(72)
    assert_equal(seq_ti_is_valid_indicator(info), True)

    var input_length: c_int = 10

    var data_in = List[Float64](capacity=int(input_length))
    data_in.append(5)
    data_in.append(8)
    data_in.append(12)
    data_in.append(11)
    data_in.append(9)
    data_in.append(8)
    data_in.append(7)
    data_in.append(10)
    data_in.append(11)
    data_in.append(13)

    var options = List[Float64](capacity=1)
    options.append(3)
    assert_equal(len(options), 1)
    
    var inputs = UnsafePointer[UnsafePointer[Float64]].alloc(1)
    inputs[0] = data_in.data
    
    var start = seq_ti_indicator_start(info, options.data)
    var output_length = int(input_length - start)

    var outputs = UnsafePointer[UnsafePointer[Float64]].alloc(1)
    var data_out = List[Float64](capacity=output_length)
    data_out.resize(output_length, 0.0)
    outputs[0] = data_out.data
    var ok = seq_ti_indicator_run(info, input_length, inputs, options.data, outputs)
    assert_equal(ok, True)

    for i in range(output_length):
        var f: Float64 = data_out[i]
        # logi("i=" + str(i))
        # logi("i=" + str(i) + " x=" + str(f))

    inputs.free()
    # options.free()
    outputs.free()
    _ = options ^


fn test_sma() raises:
    var input_length = 10
    var real = Series(capacity=input_length)
    real.append(5.0)
    real.append(8.0)
    real.append(12.0)
    real.append(11.0)
    real.append(9.0)
    real.append(8.0)
    real.append(7.0)
    real.append(10.0)
    real.append(11.0)
    real.append(13.0)
    var outputs = Outputs()
    ti_sma(input_length, real, outputs, 3)
    var result = outputs[0]
    for i in range (len(result)):
        print(i, result[i])
    

fn test_queue() raises:
    var q = Queue[Int](10)
    q.enqueue(100)
    q.enqueue(101)
    q.enqueue(102)
    var a100 = q.dequeue()
    assert_equal(a100.value(), 100)
    var a101 = q.dequeue()
    assert_equal(a101.value(), 101)
    var a102 = q.dequeue()
    assert_equal(a102.value(), 102)
    var a103 = q.dequeue()
    assert_equal(a103.__bool__(), False)


fn test_httpget() raises:
    var client = HttpClient("https://www.baidu.com")
    var headers = Headers()
    headers["abc"] = "abc"
    var res = client.get("/", headers)
    print(res.status_code)
    print(res.text)


fn test_local_position() raises:
    var lp = LocalPosition()
    lp.add(100, 3000)


fn test_atomic_bool() raises:
    var b = AtomicBool(False)
    var b_value = b.load()
    assert_true(b_value == False)
    b.store(True)
    b_value = b.load()
    assert_true(b_value == True)


fn run_forever():
    seq_photon_join_current_vcpu_into_workpool(seq_photon_work_pool())


fn main() raises:
    _ = seq_ct_init()
    var ret = seq_photon_init_default()
    # seq_init_photon_work_pool(1)

    var n = 1
    n = 1
    # n = 1000000000000
    if n == 1:
        seq_init_log(LOG_LEVEL_DBG, "")
    else:
        seq_init_log(LOG_LEVEL_INF, "")
    
    seq_test_sonic_cpp()
    logi("seq_test_sonic_cpp_wrap")
    seq_test_sonic_cpp_wrap()
    logi("seq_test_sonic_cpp_wrap done")

    test_platform()
    
    test_ti()
    test_ti_call()
    test_ti_call_at_index()
    test_ti_call_at_index2()
    test_fixed()
    test_queue()
    # test_httpget()
    test_atomic_bool()


    for i in range (n):
        # test_str()
        test_c_str()
        test_decimal_places()
        test_fixed()
        test_hmac_sha256_b64()
        # test_lockfree_queue()

        test_str_cache()
        test_query_values()
        test_sonic_raw()
        test_sonic()
        test_subscribe_message()
        test_base()
        test_order_info()

        test_parse_order()
        test_parse_position()
        test_parse_orderbook()
        test_app_config()
        test_orderbook()
        test_parse_orderbook_bids()
        # test_ti()
        test_ti_call()
        test_ti_call_at_index()
        test_ti_call_at_index2()
        # test_ti_indicator()
        test_sma()
        test_atomic_bool()

    logi("Done!!!")
    # run_forever()
