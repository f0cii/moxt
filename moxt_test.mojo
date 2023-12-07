import time
from time import time_function
from memory import unsafe
from mo import *
from c import *
from sj_dom import *
from sj_ondemand import OndemandParser
from far import Far
from ssmap import SSMap
from httpclient import HttpClient, VERB_GET, Headers, StringRefPair, QueryParams
from websocket import WebSocket
from fnv1a import fnv1a64
from stdlib_extensions.time import time_ns

from okxconsts import *
from okxclient import *
from simpletools.simplelist import SimpleList
from testing import assert_equal, assert_true, assert_false
from simpletools.simpletest import MojoTest

from moutil import *
from bybitmodel import *
from sign import hmac_sha256_b64, hmac_sha256_hex
from yyjson import *
from bybitclient import *
from bybitclientjson import *


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


fn test_ct():
    # _ = seq_ct_init()
    # print("1")
    # _ = seq_photon_init()
    # print("2")
    # seq_log_test()
    # print("3")
    # seq_photon_fini()
    # print("4")
    pass


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


# def my_add(borrowed a: Int32, borrowed b: Int32) -> Int32:
#     return a + b + 1


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


# var a = A()


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


# fn test_hashmap():
#     var m = HashMapDict[Int, fnv1a64]()
#     m.put("a", 123)
#     m.debug()
#     print(m.get("a", 0))

#     m.put("b", 12)
#     m.put("c", 345)
#     m.put("a", 111)
#     m.debug()
#     print(m.get("a", 0))
#     print(m.get("b", 0))
#     m.delete("b")
#     print(m.get("b", 0))
#     m.debug()

#     m._rehash()
#     m.debug()
#     print(m.get("a", 0))
#     print(m.get("b", 0))
#     print(m.get("c", 0))

#     m.put("b", 45)
#     m.debug()

#     print(m.get("a", 0))
#     print(m.get("b", 0))
#     print(m.get("c", 0))


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

    let testnet = False
    let private = False
    let category = "linear"
    let host = "stream-testnet.bybit.com" if testnet else "stream.bybit.com"
    let port = "443"
    let path = "/v5/private" if private else "/v5/public/" + category

    let ws = WebSocket(host=host, port=port, path=path)
    ws.connect()
    logi("connect done")
    run_forever()


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

    let api_key = ""
    let api_secret_key = ""
    let passphrase = ""
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
    let access_key = ""
    let secret_key = ""
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


fn run_forever():
    seq_photon_join_current_vcpu_into_workpool(seq_photon_work_pool())


fn main() raises:
    _ = seq_ct_init()
    let ret = seq_photon_init_default()
    seq_init_photon_work_pool(2)

    seq_init_log(LOG_LEVEL_DBG, 1)

    seq_init_net(0)
    # seq_init_net(1)

    logi("ret: " + str(ret))

    logi("init")

    # test_ssmap()
    # test_hashmap()
    # test_hashmap2()
    # test_simplelist()
    # test_far()
    # test_parser(s)
    # test_ondemand_parser()
    # test_httpclient()
    # test_websocket()
    # test_h()
    # test_global_value()
    # test_query_params()
    # test_okx()
    test_bybitclient()
    # test_yyjson()

    # test_identity_pool()
    # test_ondemand_parser_pool()
    # test_res_perf()

    # test_parse_fetch_kline_body()

    # let a = "1000325"
    # let ai = seq_strtoi(a.data()._as_scalar_pointer(), len(a))
    # logi("ai=" + String(ai))

    # let s: String = a
    # let ai1 = strtoi(s)
    # logi("ai1=" + String(ai1))

    # let ii: Int = 10000
    # let iis = to_string_ref(ii)
    # logi("iis=" + String(iis))

    # test_json_parse()

    # 协程运行
    # seq_photon_thread_create_and_migrate_to_work_pool(func1, c_void_pointer.get_null())

    # test_raw(s)

    logi("started")
    run_forever()

    # _ = seq_photon_thread_sleep_s(-1)

    print("Exit.")

    # seq_photon_fini()
