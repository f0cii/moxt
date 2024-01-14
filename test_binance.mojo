import time
from time import time_function
from memory import unsafe
from base.mo import *
from base.c import *
from base.sj_dom import *
from base.sj_ondemand import OndemandParser
from base.fixed import Fixed
from base.httpclient import HttpClient, VERB_GET, Headers, QueryParams
from base.websocket import *
from stdlib_extensions.time import time_ns
from stdlib_extensions.builtins import dict, HashableInt, HashableStr
from testing import assert_equal, assert_true, assert_false
from base.moutil import *
from core.binancemodel import *
from core.sign import hmac_sha256_b64, hmac_sha256_hex
from base.yyjson import *
from core.binanceclient import *
from core.binancews import BinanceWS
from core.env import env_load


# pip install fastapi uvicorn[standard]
fn test_httpclient_perf():
    # https://api.bybit.com/v3/public/time

    let base_url = "https://api.bybit.com"
    let path = "/v3/public/time"

    # let base_url = "https://pss.bdstatic.com"
    # let path = "/static/superman/js/super_ext-a0b60bd05d.js"

    let client = HttpClient(base_url)
    # let headers = SSMap()
    var headers = Headers()
    headers["a"] = "aaaaaaaaaaaaaaaa"
    headers["b"] = "aaaaaaaaaaaaaaaa"
    let res = client.get(path, headers)
    logd("status: " + str(res.status))
    logd("body: " + res.body)


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
    _ = ws ^


fn get_on_message() -> on_message_callback:
    @parameter
    fn wrapper(data: c_char_pointer, data_len: Int):
        let s = c_str_to_string(data, data_len)
        logi("get_on_message=" + s)

    return wrapper


fn test_binancews() raises:
    logd("test_binancews")
    let env_dict = env_load()

    let access_key = env_dict["BINANCE_API_KEY"]
    let secret_key = env_dict["BINANCE_API_SECRET"]
    logi("access_key=" + access_key)
    logi("secret_key=" + secret_key)
    let ws = BinanceWS(
        is_private=True,
        testnet=False,
        access_key=access_key,
        secret_key=secret_key,
        # topics="btcusdt@depth5",
    )

    var on_connect = ws.get_on_connect()
    var on_heartbeat = ws.get_on_heartbeat()
    var on_message = get_on_message()

    ws.set_on_connect(Pointer[on_connect_callback].address_of(on_connect))
    ws.set_on_heartbeat(Pointer[on_heartbeat_callback].address_of(on_heartbeat))
    ws.set_on_message(Pointer[on_message_callback].address_of(on_message))

    # var topics = list[String]()
    # topics.append("btcusdt@depth5")
    # ws.set_subscription(topics)
    ws.connect()

    logd("start")

    run_forever()

    _ = ws ^


fn sum_int_list(v: list[Int]) raises -> Int:
    var result: Int = 0
    for item in v:
        result += item
    return result


fn test_binance_sign() raises:
    # echo -n "symbol=BTCUSDT&side=BUY&type=LIMIT&quantity=1&price=9000&timeInForce=GTC&recvWindow=5000&timestamp=1591702613943" | openssl dgst -sha256 -hmac "2b5eb11e18796d12d88f13dc27dbbd02c2cc51ff7059765ed9821957d82bb4d9"
    # (stdin)= 3c661234138461fcc7a7d8746c6558c9842d4e10870d2ecbedf7777cad694af9
    let s = "symbol=BTCUSDT&side=BUY&type=LIMIT&quantity=1&price=9000&timeInForce=GTC&recvWindow=5000&timestamp=1591702613943"
    let r = hmac_sha256_hex(
        s, "2b5eb11e18796d12d88f13dc27dbbd02c2cc51ff7059765ed9821957d82bb4d9"
    )
    # logi("r=" + r)
    # let ms = time_ms()
    # logi("ms=" + str(ms))
    assert_equal(r, "3c661234138461fcc7a7d8746c6558c9842d4e10870d2ecbedf7777cad694af9")


fn test_parse_order_info() raises:
    let s = '{"orderId":237740210409,"symbol":"BTCUSDT","status":"NEW","clientOrderId":"62ayQ4MjyVIaCkvDX00dhh","price":"20000.00","avgPrice":"0.00","origQty":"0.010","executedQty":"0.000","cumQty":"0.000","cumQuote":"0.00000","timeInForce":"GTC","type":"LIMIT","reduceOnly":false,"closePosition":false,"side":"BUY","positionSide":"LONG","stopPrice":"0.00","workingType":"CONTRACT_PRICE","priceProtect":false,"origType":"LIMIT","priceMatch":"NONE","selfTradePreventionMode":"NONE","goodTillDate":0,"updateTime":1704291033033}'
    let parser = DomParser(1024 * 100)
    let doc = parser.parse(s)
    let code = doc.get_int("code")
    let msg = doc.get_str("msg")

    assert_equal(code, 0)
    assert_equal(msg, "")

    if code != 0 and msg != "":
        raise Error("error code=" + str(code) + ", msg=" + msg)

    let _order_id = doc.get_int("orderId")
    let _order_id2 = doc.get_uint("orderId")
    let _client_order_id = doc.get_str("clientOrderId")

    assert_equal(_order_id, 237740210409)
    assert_equal(_order_id2, 237740210409)

    _ = doc ^
    _ = parser ^

    var order_info = OrderInfo()
    order_info.order_id = _order_id
    order_info.client_order_id = _client_order_id

    # logi("order_id: " + str(order_info.order_id))

    assert_equal(order_info.order_id, 237740210409)
    assert_equal(order_info.client_order_id, "62ayQ4MjyVIaCkvDX00dhh")


fn test_binanceclient_public_time() raises:
    let env_dict = env_load()

    let access_key = env_dict["BINANCE_API_KEY"]
    let secret_key = env_dict["BINANCE_API_SECRET"]
    logi("access_key=" + access_key)
    logi("secret_key=" + secret_key)
    var client = BinanceClient(
        testnet=False, access_key=access_key, secret_key=secret_key
    )
    client.set_verbose(True)

    let symbol = "BTCUSDT"

    # _ = client.public_time()

    let side = "BUY"
    let type_ = "LIMIT"
    let position_side = "LONG"
    let quantity = Fixed("0.01")
    let price = Fixed("20000")

    let order_start = time_us()

    # let res = client.place_order(symbol, side, type_, position_side, quantity, price)
    # logi("res=" + str(res))

    # let res = client.cancel_order(symbol, order_id="237740210409")
    # logi("res=" + str(res))

    # 预热
    _ = client.public_time()

    let order_end = time_us()

    logi("耗时: " + str(order_end - order_start) + " us")

    # 测试下单速度
    let times = 3
    var order_times = list[Int]()  # 记录每次下单耗时
    # var cancel_times = list[Int]()  # 记录每次撤单耗时

    let start_time = time_us()  # 记录开始时间

    for i in range(times):
        # logi("i=" + str(i))

        let order_start = time_us()

        _ = client.public_time()

        let order_end = time_us()

        logi(
            str(i)
            + ":public_time"
            # + str(res)
            + " 耗时: "
            + str(order_end - order_start)
            + " us"
        )

        # let order_id = res.order_id

        order_times.append(int(order_end - order_start))

        _ = seq_photon_thread_sleep_ms(3500)

    let end_time = time_us()  # 记录结束时间

    let total_time = end_time - start_time

    logi("总耗时:" + str(total_time) + " us")

    logi("平均耗时:" + str(sum_int_list(order_times) / len(order_times)) + " us")

    logi("Done!!!")

    run_forever()

    _ = client ^


fn test_binanceclient() raises:
    let env_dict = env_load()

    let access_key = env_dict["BINANCE_API_KEY"]
    let secret_key = env_dict["BINANCE_API_SECRET"]
    logi("access_key=" + access_key)
    logi("secret_key=" + secret_key)
    let client = BinanceClient(
        testnet=False, access_key=access_key, secret_key=secret_key
    )

    let symbol = "BTCUSDT"

    # 预热
    _ = client.public_time()

    let side = "BUY"
    let type_ = "LIMIT"
    let position_side = "LONG"
    let quantity = Fixed("0.01")
    let price = Fixed("20000")

    let order_start = time_us()

    # let res = client.place_order(symbol, side, type_, position_side, quantity, price)
    # logi("res=" + str(res))

    # let res = client.cancel_order(symbol, order_id="237740210409")
    # logi("res=" + str(res))

    let order_end = time_us()

    logi("耗时: " + str(order_end - order_start) + " us")

    # 测试下单速度
    let times = 30
    var order_times = list[Int]()  # 记录每次下单耗时
    var cancel_times = list[Int]()  # 记录每次撤单耗时

    let start_time = time_us()  # 记录开始时间

    for i in range(times):
        # logi("i=" + str(i))

        let order_start = time_us()

        let res = client.place_order(
            symbol, side, type_, position_side, quantity, price
        )

        let order_end = time_us()

        logi(
            str(i)
            + ":下单返回="
            + str(res)
            + " 耗时: "
            + str(order_end - order_start)
            + " us"
        )

        let order_id = res.order_id

        logi("order_id: " + str(order_id))

        let cancel_start = time_us()

        let res1 = client.cancel_order(symbol, order_id=order_id)

        let cancel_end = time_us()

        logi(
            str(i)
            + ":撤单返回="
            + str(res1)
            + " 耗时: "
            + str(cancel_end - cancel_start)
            + " us"
        )

        order_times.append(int(order_end - order_start))
        cancel_times.append(int(cancel_end - cancel_start))

        _ = seq_photon_thread_sleep_ms(500)

    let end_time = time_us()  # 记录结束时间

    let total_time = end_time - start_time

    logi("总耗时:" + str(total_time) + " us")

    logi("平均下单耗时:" + str(sum_int_list(order_times) / len(order_times)) + " us")
    logi("平均撤单耗时:" + str(sum_int_list(cancel_times) / len(cancel_times)) + " us")

    logi("Done!!!")

    run_forever()

    _ = client ^


fn test_listen_key() raises:
    let env_dict = env_load()

    let access_key = env_dict["BINANCE_API_KEY"]
    let secret_key = env_dict["BINANCE_API_SECRET"]
    logi("access_key=" + access_key)
    logi("secret_key=" + secret_key)
    var client = BinanceClient(
        testnet=False, access_key=access_key, secret_key=secret_key
    )
    client.set_verbose(True)
    # let res = client.generate_listen_key()
    # logi("res=" + res)

    let res = client.extend_listen_key()
    logi("res=" + str(res))

    # let listen_key = "rioNZjETMWuZLTPkI3HGBZ6FMjJCerqbL5w8FcdWLWLn9LRFPYg79JIwVLPLXOmp"


fn run_forever():
    seq_photon_join_current_vcpu_into_workpool(seq_photon_work_pool())


fn handle_term(sig: c_int) raises -> None:
    print("handle_term")
    _ = exit(0)


fn photon_handle_term(sig: c_int) raises -> None:
    print("photon_handle_term")
    _ = exit(0)


fn main() raises:
    _ = seq_ct_init()
    seq_photon_set_log_output(0)
    let ret = seq_photon_init_default()
    seq_init_photon_work_pool(2)
    # seq_init_log(LOG_LEVEL_DBG, "test_binance.log")
    seq_init_log(LOG_LEVEL_DBG, "")
    # seq_init_log(LOG_LEVEL_OFF, "")
    # seq_init_net(0)
    seq_init_net(1)

    logi("初始化返回: " + str(ret))

    seq_init_signal(handle_term)
    seq_init_photon_signal(photon_handle_term)

    # while True:
    # test_httpclient_perf()
    # test_binance_sign()
    # test_parse_order_info()
    # test_binanceclient_public_time()
    test_binanceclient()
    # test_binancews()
    # test_listen_key()

    logi("程序已准备就绪，等待事件中...")
    run_forever()
