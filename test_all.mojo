import time
from time import time_function
from memory import unsafe
from base.mo import *
from base.c import *
from base.sj_dom import *
from base.sj_ondemand import OndemandParser
from base.far import Far
from base.fixed import Fixed
from base.ssmap import SSMap
from base.httpclient import HttpClient, VERB_GET, Headers, QueryParams
from base.websocket import *
from fnv1a import fnv1a64
from stdlib_extensions.time import time_ns
from stdlib_extensions.builtins import dict, HashableInt, HashableStr
from core.okxconsts import *
from core.okxclient import *
from testing import assert_equal, assert_true, assert_false
from base.moutil import *
from core.bybitmodel import *
from core.sign import hmac_sha256_b64, hmac_sha256_hex
from base.yyjson import *
from core.bybitclient import *
from core.bybitclientjson import *
from core.bybitws import *
from core.env import load_env


fn test_ondemand_parser():
    let str = '{"retCode":1001,"retMsg":"OK","result":{"category":"linear","list":[],"nextPageCursor":""},"retExtInfo":{},"time":1696236288675}'
    let op = OndemandParser(1000 * 1000)
    let doc = op.parse(str)

    let key = "retCode"
    let ret_code = doc.get_int(key)
    logd(ret_code)

    let key1 = "retMsg"
    let retMsg = doc.get_str(key1)
    logd(retMsg)

    let result = doc.get_object("result")
    let category = result.get_str("category")
    logd("category: " + category)
    let list = result.get_array("list")
    let iter = list.iter()
    while iter.has_value():
        logd("dddd")
        iter.step()

    _ = doc
    _ = op


fn test_ws_auth():
    let s = '{"req_id":"LzIP5BH2aBVLUkmsOzg-q","success":true,"ret_msg":"","op":"auth","conn_id":"cldfn01dcjmj8l28s6sg-ngkux"}'
    let od_parser = OndemandParser(1000 * 100)
    let doc = od_parser.parse(s)
    let op = doc.get_str("op")
    logd("op: " + op)
    let abc = doc.get_str("abc")
    logd("abc: " + abc)
    if abc == "":
        logd("no abc")
    # let ret_code = doc.get_int("retCode")
    # let ret_msg = doc.get_str("retMsg")
    # if ret_code != 0:
    #     return

    # let result = doc.get_object("result")

    # let time_second = atol(result.get_str("timeSecond"))
    # let time_nano = atol(result.get_str("timeNano"))

    _ = doc
    _ = od_parser


fn test_raw():
    let str = '{"retCode":1001,"retMsg":"OK","result":{"category":"linear","list":[],"nextPageCursor":""},"retExtInfo":{},"time":1696236288675}'
    let max_capacity = 1000 * 1000
    let parser = seq_simdjson_ondemand_parser_new(max_capacity)
    let padded_string = seq_simdjson_padded_string_new(
        str.data()._as_scalar_pointer(), len(str)
    )
    let doc = seq_simdjson_ondemand_parser_parse(parser, padded_string)
    # let key: CString = "retCode"
    # let ret_code = seq_simdjson_ondemand_get_int_d(doc, key.data, key.len)
    let key = "retCode"
    let ret_code = seq_simdjson_ondemand_get_int_d(
        doc, key.data()._as_scalar_pointer(), len(key)
    ).to_int()
    print(ret_code)
    seq_simdjson_ondemand_document_free(doc)
    seq_simdjson_padded_string_free(padded_string)
    seq_simdjson_ondemand_parser_free(parser)


fn test_far():
    let f = Far()
    f.set_int("a", 100)
    let a = f.get_int("a")
    logi("a: " + String(a))
    f.set_float("b", 100.10)
    let b = f.get_float("b")
    logi("b: " + String(b))
    f.set_bool("c", True)
    let c = f.get_bool("c")
    logi("c: " + String(c))
    f.set_str("d", "hello")
    let d = f.get_str("d")
    logi("d: " + d)
    f.release()


fn test_fixed():
    let f0 = Fixed()
    logd(str(f0))

    let f1 = Fixed(1)
    logd(str(f1))

    let f2 = Fixed(100)
    logd(str(f2))

    let f3 = Fixed(1.2)
    logd(str(f3))

    let f4 = Fixed("1000.5")
    logd(str(f4))

    let f5 = f2 + f4
    logd(str(f5))

    let f6 = Fixed("1.0999").round_to_fractional(10000000000)
    logd("f6: " + str(f6))

    let f7 = Fixed("1.123456").round(2)
    logd("f7: " + str(f7))

    let f8 = f2 * f4
    logd("f8: " + str(f8))

    let f9 = Fixed("55") / Fixed(2)
    logd("f9: " + str(f9))

    # seq_photon_thread_sleep_ms(10)


struct A:
    var a: Int

    fn __init__(inout self):
        logi("A.__init__")
        self.a = 100

    fn init(inout self):
        logi("A.init")
        self.a = 1000

    fn incr(inout self):
        self.a += 1


fn req(arg: c_void_pointer) raises -> c_void_pointer:
    logi("req")
    # let url: StringLiteral = "https://reqres.in/api/users?page=1"
    let url: StringLiteral = "https://reqres.in/api/users?page=1"
    test_photon_http(url.data()._as_scalar_pointer(), len(url))
    logi("req end")
    return c_void_pointer.get_null()


fn func1(arg: c_void_pointer) raises -> c_void_pointer:
    logi("func1 1000")
    while True:
        let ncpu = seq_photon_workpool_get_vcpu_num(seq_photon_work_pool())
        logi("func1 tick ncpu: " + String(ncpu))
        # a.incr()
        # logi(a.a)

        logi("call start")
        # seq_photon_thread_create_and_migrate_to_work_pool(req, c_void_pointer.get_null())
        # test_1()
        _ = req(c_void_pointer.get_null())
        logi("call end")

        seq_photon_thread_sleep_s(3)

        # try:
        #     logi("call start")
        #     test_photon_http()
        #     logi("call end")
        # except:
        #     logi("error")
    # return c_void_pointer.get_null()


fn test_ssmap():
    var sm = SSMap()
    sm["a"] = "100"
    sm["b"] = "160"
    print(sm.__len__())
    let c = sm["b"]
    print(c)
    print(len(c))
    sm.release()

    var sm1 = SSMap()
    sm1["a"] = "1"
    print(sm1["a"])
    sm1.release()


@value
struct WSSample:
    var a: Int

    fn __init__(inout self):
        self.a = 100

    fn do(inout self, v: Int):
        self.a += v

    fn debug(self):
        print(self.a)


fn test_httpclient():
    # let base_url = "https://www.baidu.com"
    let base_url = "https://api.bybit.com"
    # https://api.bybit.com/v3/public/time
    let client = HttpClient(base_url)
    # let headers = SSMap()
    var headers = Headers()
    headers["a"] = "abc"
    _ = client.get("/v3/public/time", headers)
    _ = client.do_request("/v3/public/time", VERB_GET, headers, "")
    _ = client.do_request("/v3/public/time", VERB_GET, headers, "")
    headers.release()


fn test_websocket() raises:
    # https://socketsbay.com/test-websockets
    # let base_url = "wss://socketsbay.com/wss/v2/1/demo/"

    # let host = "socketsbay.com"
    # let port = "443"
    # let path = "/wss/v2/1/demo/"

    # wss://echo.websocket.org
    # let host = "echo.websocket.org"
    # let port = "443"
    # let path = "/"

    logd("test_websocket")

    let testnet = False
    let private = False
    let category = "linear"
    let host = "stream-testnet.bybit.com" if testnet else "stream.bybit.com"
    let port = "443"
    let path = "/v5/private" if private else "/v5/public/" + category

    let ws = WebSocket(host=host, port=port, path=path)
    let id = ws.get_id()
    var on_connect = ws.get_on_connect()
    let on_connect_ptr = Pointer[on_connect_callback].address_of(
        on_connect
    ).__as_index()
    # print("on_connect_ptr: " + str(aon_connect_ptr))
    var on_heartbeat = ws.get_on_heartbeat()
    let on_heartbeat_ptr = Pointer[on_heartbeat_callback].address_of(
        on_heartbeat
    ).__as_index()
    # print("on_heartbeat_ptr: " + str(on_heartbeat_ptr))
    var on_message = ws.get_on_message()
    let on_message_ptr = Pointer[on_message_callback].address_of(
        on_message
    ).__as_index()
    # print("on_message_ptr: " + str(on_message_ptr))
    set_on_connect(id, on_connect_ptr)
    set_on_heartbeat(id, on_heartbeat_ptr)
    set_on_message(id, on_message_ptr)
    ws.connect()
    logi("connect done")
    run_forever()
    _ = ws


fn get_on_message() -> on_message_callback:
    fn wrapper(data: c_char_pointer, data_len: Int):
        # print("get_on_message")
        # let s = String(data, data_len)
        # logd("get_on_message::on_message: " + s)
        # ok
        logd("get_on_message")
        # let s_ref = to_string_ref(data, data_len)
        # logi("s_ref: " + String(s_ref))

        let s = c_str_to_string(data, data_len)
        logi("s=" + s)

    return wrapper


fn test_bybitws() raises:
    logd("test_bybitws")
    var ws = BybitWS(
        is_private=False,
        testnet=False,
        access_key="",
        secret_key="",
        category="linear",
        topics="orderbook.1.BTCUSDT",
    )

    # let id = ws.get_id()
    var on_connect = ws.get_on_connect()
    var on_heartbeat = ws.get_on_heartbeat()
    var on_message = get_on_message()

    # let on_connect_ptr = Pointer[on_connect_callback].address_of(on_connect).__as_index()
    # let on_heartbeat_ptr = Pointer[on_heartbeat_callback].address_of(on_heartbeat).__as_index()
    # let on_message_ptr = Pointer[on_message_callback].address_of(on_message).__as_index()

    # ws.set_on_connect(on_connect_ptr)
    ws.set_on_connect(Pointer[on_connect_callback].address_of(on_connect))
    ws.set_on_heartbeat(Pointer[on_heartbeat_callback].address_of(on_heartbeat))
    ws.set_on_message(Pointer[on_message_callback].address_of(on_message))

    var topics = list[String]()
    topics.append("orderbook.1.BTCUSDT")
    ws.set_subscription(topics)
    ws.connect()

    logd("start")

    run_forever()

    _ = ws
    # except err:
    #     logi("error: " + str(err))


@value
@register_passable
struct G:
    var i: Int

    fn __init__(i: Int) -> Self:
        logi("G.__init__")
        return Self {
            i: i,
        }

    fn debug(self):
        logi("debug: " + String(self.i))


fn test_global_value():
    var g = G(101)
    let id = 1
    let ptr = set_global_value_ptr[G](id, Pointer[G].address_of(g))
    logi("p0: " + String(ptr))
    var g1 = get_global_value[G](1)
    g1.debug()

    let ptr1 = Pointer[G].address_of(g1).__as_index()
    logi("p1: " + String(ptr1))

    _ = g
    logi("OK")


fn test_query_params() raises:
    var queryParams = QueryParams()
    queryParams["a"] = "hello"
    queryParams["b"] = "100"
    let qstr = queryParams.to_string()
    logi("qstr=" + qstr)

    let a = queryParams
    let astr = a.to_string()
    logi("as=" + astr)


fn test_okx() raises:
    let s = get_timestamp()
    logi(s)

    let a = hmac_sha256_b64(String("abc"), String("abb"))
    logi(a)

    let env_dict = load_env()

    let api_key = env_dict["OKEX_API_KEY"]
    let api_secret_key = env_dict["OKEX_API_SECRET"]
    let passphrase = env_dict["OKEX_API_PASSPHRASE"]
    let b = OkxClient(
        api_key=api_key, api_secret_key=api_secret_key, passphrase=passphrase
    )
    b.get_instruments("SWAP")
    let res = b.get_account_balance()
    let status = res.status
    logi("status: " + str(status))
    let msg = res.body  # .get[1, StringRef]()
    logi("msg: " + str(msg))

    # {"msg":"Request header OK-ACCESS-KEY can not be empty.","code":"50103"}
    # {"msg":"Invalid OK-ACCESS-TIMESTAMP","code":"50112"}
    # {"msg":"Timestamp request expired","code":"50102"}
    # {"msg":"Your IP 185.14.47.178 is not included in your API key's b68428e0-6ea2-4dd8-9de2-af7f6114ecb8 IP whitelist.","code":"50110"}
    # {"msg":"APIKey does not match current environment.","code":"50101"}
    # {"code":"0","data":[{"adjEq":"","borrowFroz":"","details":[],"imr":"","isoEq":"0","mgnRatio":"","mmr":"","notionalUsd":"","ordFroz":"","totalEq":"0","uTime":"1701569386014"}],"msg":""}


fn test_bybitclient() raises:
    let env_dict = load_env()

    let access_key = env_dict["BYBIT_API_KEY"]
    let secret_key = env_dict["BYBIT_API_SECRET"]
    let client = BybitClient(
        testnet=False, access_key=access_key, secret_key=secret_key
    )
    # let server_time = client.fetch_public_time()
    # logi(str(server_time))
    let category = "linear"
    let symbol = "BTCUSDT"

    try:
        # let exchange_info = client.fetch_exchange_info(category, symbol)
        # logi(str(exchange_info))

        # let kline = client.fetch_kline(category, symbol, interval="1", limit=5, start=0, end=0)
        # for index in range(kline.size()):
        #     let item = kline[index]
        #     logi(str(item))

        # test_orderbook_parse_body()
        # let ob = client.fetch_orderbook(category, symbol, 5)
        # logi("-----asks-----")
        # for index in range(ob.asks.size()):
        #     let item = ob.asks[index]
        #     logi(str(item))

        # logi("-----bids-----")
        # for index in range(ob.bids.size()):
        #     let item = ob.bids[index]
        #     logi(str(item))

        # let doc = yyjson_mut_doc()
        # doc.add_str("category", category)
        # doc.add_str("symbol", symbol)
        # doc.add_str("mode", "0")
        # doc.add_int("a", 100)
        # let body_str = doc.mut_write()

        # logi("[" + body_str + "]")

        # sign
        # logi("----------sign-----------")
        # let time_ms_str = "1701825677411" # str(time_ns() / 1e6)
        # let recv_window_str = "15000"
        # let payload = '{"category":"linear","symbol":"BTCUSDT","mode":"0"}'
        # let param_str = time_ms_str + access_key + recv_window_str + payload
        # logi("param_str=" + param_str)
        # let sign_str = hmac_sha256_hex(param_str, secret_key)
        # logi("sign_str=" + sign_str)

        # let res = client.switch_position_mode(category, symbol, "0")
        # logi("res=" + str(res))

        # 测试不通过
        # try:
        #     let res = client.switch_position_mode(category, symbol, "0")
        #     logi("res=" + str(res))
        # except err:
        #     logi("error: " + str(err))

        # let res = client.set_leverage(category, symbol, "10", "10")
        # logi("res=" + str(res))

        let side = "Buy"
        let order_type = "Limit"
        let qty = "0.0001"
        let price = "30000"

        # 测试失败
        # let res = client.place_order(category, symbol, side, order_type, qty, price)
        # logi("res=" + str(res))

        # cancel_order

        # cancel_orders

        # fetch_balance - pass
        # test_fetch_balance_parse_body()
        # let res = client.fetch_balance("CONTRACT", "USDT")
        # for index in range(res.size()):
        #     let item = res[index]
        #     logi("item=" + str(item))

        let res = client.fetch_orders(category, symbol)
        for index in range(res.size()):
            let item = res[index]
            logi("item=" + str(item))
        logi("OK")
    except err:
        logi("error: " + str(err))

    # _ = client
    run_forever()

    _ = client


fn test_yyjson():
    let doc = yyjson_mut_doc()
    doc.add_str("category", "abc")
    doc.add_str("symbol", "ddd")
    doc.add_str("mode", "1")
    let body_str = doc.mut_write()
    logi(body_str)

    let doc_str = '{"category":"abc","symbol":"ddd","mode":"1"}'
    let doc1 = yyjson_doc(doc_str)
    let root = doc1.root()
    # let c = root["category"]
    # let ret_code = c.str()
    let ret_code = root["category"].str()
    # let ret_msg = root["symbol"].str()

    logi("ret_code: " + ret_code)

    _ = doc1
    _ = doc_str


fn a(p: Pointer[UInt8]) -> None:
    _ = p


fn test_res_perf():
    let total = 100  # 00000

    @parameter
    fn test():
        for i in range(total):
            let res = Pointer[UInt8].alloc(1024 * 64)
            res[0] = 0
            a(res)

    let start = time_ns()  # / 1e9
    # let tm = time_function[test]()
    # test()

    for i in range(total):
        let res = Pointer[UInt8].alloc(1024 * 64)
        res[0] = 0
        a(res)

    let end = time_ns()  # / 1e9
    let tm = end - start
    logi("start=" + str(start))
    logi("end=" + str(end))
    logi("tm=" + str(tm))


fn test_add():
    let a = 100
    let b = 200
    let c = seq_add(a, b)
    logi("c=" + str(c))

    # let d = seq_add_with_exception0(a, b)
    # let e = seq_add_with_exception1(a, b)


fn test_json() raises:
    let id = seq_nanoid()
    let yy_doc = yyjson_mut_doc()
    yy_doc.add_str("req_id", id)
    yy_doc.add_str("op", "subscribe")
    var values = list[String]()
    values.append("ab")
    values.append("ab3")
    yy_doc.arr_with_str("args", values)
    let body_str = yy_doc.mut_write()
    logd("send: " + body_str)


fn run_forever():
    seq_photon_join_current_vcpu_into_workpool(seq_photon_work_pool())


fn main() raises:
    _ = seq_ct_init()
    let ret = seq_photon_init_default()
    seq_init_photon_work_pool(2)

    seq_init_log(LOG_LEVEL_DBG, "")

    seq_init_net(1)

    logi("ret: " + str(ret))

    logi("init")

    # seq_test_spdlog()
    # test_ssmap()
    # test_far()
    # test_fixed()
    # test_parser(s)
    # test_ondemand_parser()
    # test_fetch_orders_body_parse()
    # test_httpclient()
    # test_websocket()
    test_bybitws()
    # test_h()
    # test_global_value()
    # test_query_params()
    # test_yyjson()
    # test_okx()

    # test_bybitclient()

    # test_add()

    # test_identity_pool()
    # test_ondemand_parser_pool()
    # test_res_perf()
    # test_parse_fetch_kline_body()
    # test_json_parse()

    # test_ws_auth()
    # test_parse_order()

    # 协程运行
    # seq_photon_thread_create_and_migrate_to_work_pool(func1, c_void_pointer.get_null())

    logi("started")
    run_forever()

    # ws_hold.nop()

    # seq_photon_fini()
