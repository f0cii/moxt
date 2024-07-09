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
from ylstdlib.time import time_ns
from testing import assert_equal, assert_true, assert_false
from base.moutil import *
from base.globals import *
from core.binancemodel import *
from core.sign import hmac_sha256_b64, hmac_sha256_hex
from base.yyjson import *
from core.binanceclient import *
from core.binancews import BinanceWS
from core.env import env_load


# pip install fastapi uvicorn[standard]
fn test_httpclient_perf():
    # https://api.bybit.com/v3/public/time

    var base_url = "https://api.bybit.com"
    var path = "/v3/public/time"

    # var base_url = "https://pss.bdstatic.com"
    # var path = "/static/superman/js/super_ext-a0b60bd05d.js"

    var client = HttpClient(base_url)
    var headers = Headers()
    headers["a"] = "aaaaaaaaaaaaaaaa"
    headers["b"] = "aaaaaaaaaaaaaaaa"
    var res = client.get(path, headers)
    logd("status_code: " + str(res.status_code))
    logd("text: " + res.text)


fn test_websocket() raises:
    # https://socketsbay.com/test-websockets
    # var base_url = "wss://socketsbay.com/wss/v2/1/demo/"

    # var host = "socketsbay.com"
    # var port = "443"
    # var path = "/wss/v2/1/demo/"

    # wss://echo.websocket.org
    # var host = "echo.websocket.org"
    # var port = "443"
    # var path = "/"

    logd("test_websocket")

    var testnet = False
    var private = False
    var category = "linear"
    var host = "stream-testnet.bybit.com" if testnet else "stream.bybit.com"
    var port = "443"
    var path = "/v5/private" if private else "/v5/public/" + category

    var ws = WebSocket(host=host, port=port, path=path)
    var id = ws.get_id()
    var on_connect = ws.get_on_connect()
    var on_heartbeat = ws.get_on_heartbeat()
    var on_message = ws.get_on_message()
    set_on_connect(id, on_connect^)
    set_on_heartbeat(id, on_heartbeat^)
    set_on_message(id, on_message^)
    ws.connect()
    logi("connect done")
    run_forever()
    _ = ws^


fn get_on_message() -> on_message_callback:
    fn wrapper(msg: String):
        logi("get_on_message=" + msg)

    return wrapper


fn test_binancews() raises:
    logd("test_binancews")
    var env_dict = env_load()

    var access_key = env_dict["BINANCE_API_KEY"]
    var secret_key = env_dict["BINANCE_API_SECRET"]
    logi("access_key=" + access_key)
    logi("secret_key=" + secret_key)
    var ws = BinanceWS(
        is_private=True,
        testnet=False,
        access_key=access_key,
        secret_key=secret_key,
        # topics="btcusdt@depth5",
    )

    var on_connect = ws.get_on_connect()
    var on_heartbeat = ws.get_on_heartbeat()
    var on_message = get_on_message()

    ws.set_on_connect(on_connect)
    ws.set_on_heartbeat(on_heartbeat)
    ws.set_on_message(on_message)

    # var topics = List[String]()
    # topics.append("btcusdt@depth5")
    # ws.set_subscription(topics)
    ws.connect()

    logd("start")

    run_forever()

    _ = ws^


fn sum_int_list(v: List[Int]) raises -> Int:
    var result: Int = 0
    for item in v:
        result += item[]
    return result


fn test_binance_sign() raises:
    # echo -n "symbol=BTCUSDT&side=BUY&type=LIMIT&quantity=1&price=9000&timeInForce=GTC&recvWindow=5000&timestamp=1591702613943" | openssl dgst -sha256 -hmac "2b5eb11e18796d12d88f13dc27dbbd02c2cc51ff7059765ed9821957d82bb4d9"
    # (stdin)= 3c661234138461fcc7a7d8746c6558c9842d4e10870d2ecbedf7777cad694af9
    var s = "symbol=BTCUSDT&side=BUY&type=LIMIT&quantity=1&price=9000&timeInForce=GTC&recvWindow=5000&timestamp=1591702613943"
    var r = hmac_sha256_hex(
        s, "2b5eb11e18796d12d88f13dc27dbbd02c2cc51ff7059765ed9821957d82bb4d9"
    )
    # logi("r=" + r)
    # var ms = time_ms()
    # logi("ms=" + str(ms))
    assert_equal(
        r, "3c661234138461fcc7a7d8746c6558c9842d4e10870d2ecbedf7777cad694af9"
    )


fn test_parse_order_info() raises:
    var s = String(
        '{"orderId":237740210409,"symbol":"BTCUSDT","status":"NEW","clientOrderId":"62ayQ4MjyVIaCkvDX00dhh","price":"20000.00","avgPrice":"0.00","origQty":"0.010","executedQty":"0.000","cumQty":"0.000","cumQuote":"0.00000","timeInForce":"GTC","type":"LIMIT","reduceOnly":false,"closePosition":false,"side":"BUY","positionSide":"LONG","stopPrice":"0.00","workingType":"CONTRACT_PRICE","priceProtect":false,"origType":"LIMIT","priceMatch":"NONE","selfTradePreventionMode":"NONE","goodTillDate":0,"updateTime":1704291033033}'
    )
    var parser = DomParser(1024 * 100)
    var doc = parser.parse(s)
    var code = doc.get_int("code")
    var msg = doc.get_str("msg")

    assert_equal(code, 0)
    assert_equal(msg, "")

    if code != 0 and msg != "":
        raise Error("error code=" + str(code) + ", msg=" + msg)

    var _order_id = doc.get_int("orderId")
    var _order_id2 = doc.get_uint("orderId")
    var _order_client_id = doc.get_str("clientOrderId")

    assert_equal(_order_id, 237740210409)
    assert_equal(_order_id2, 237740210409)

    _ = doc^
    _ = parser^
    _ = s^

    var order_info = OrderInfo()
    order_info.order_id = _order_id
    order_info.order_client_id = _order_client_id

    # logi("order_id: " + str(order_info.order_id))

    assert_equal(order_info.order_id, 237740210409)
    assert_equal(order_info.order_client_id, "62ayQ4MjyVIaCkvDX00dhh")


fn test_binanceclient_public_time() raises:
    var env_dict = env_load()

    var access_key = env_dict["BINANCE_API_KEY"]
    var secret_key = env_dict["BINANCE_API_SECRET"]
    logi("access_key=" + access_key)
    logi("secret_key=" + secret_key)
    var client = BinanceClient(
        testnet=False, access_key=access_key, secret_key=secret_key
    )
    client.set_verbose(True)

    var symbol = "BTCUSDT"

    # _ = client.public_time()

    var side = "BUY"
    var type_ = "LIMIT"
    var position_side = "LONG"
    var quantity = Fixed("0.01")
    var price = Fixed("20000")

    var order_start = time_us()

    # var res = client.place_order(symbol, side, type_, position_side, quantity, price)
    # logi("res=" + str(res))

    # var res = client.cancel_order(symbol, order_id="237740210409")
    # logi("res=" + str(res))

    # Preparation phase
    _ = client.public_time()

    var order_end = time_us()

    logi("Time consumption: " + str(order_end - order_start) + " us")

    # Test order placement speed
    var times = 3
    var order_times = List[
        Int
    ]()  # Record the time taken for each order placement

    var start_time = time_us()

    for i in range(times):
        # logi("i=" + str(i))

        var order_start = time_us()

        _ = client.public_time()

        var order_end = time_us()

        logi(
            str(i)
            + ":public_time"
            # + str(res)
            + " Time consumption: "
            + str(order_end - order_start)
            + " us"
        )

        # var order_id = res.order_id

        order_times.append(int(order_end - order_start))

        _ = seq_photon_thread_sleep_ms(3500)

    var end_time = time_us()

    var total_time = end_time - start_time

    logi("Total time consumed:" + str(total_time) + " us")

    logi(
        "Average time consumed:"
        + str(sum_int_list(order_times) / len(order_times))
        + " us"
    )

    logi("Done!!!")

    run_forever()

    _ = client^


fn test_binanceclient() raises:
    var env_dict = env_load()

    var access_key = env_dict["BINANCE_API_KEY"]
    var secret_key = env_dict["BINANCE_API_SECRET"]
    logi("access_key=" + access_key)
    logi("secret_key=" + secret_key)
    var client = BinanceClient(
        testnet=False, access_key=access_key, secret_key=secret_key
    )

    var symbol = "BTCUSDT"

    # Preparation phase
    _ = client.public_time()

    var side = "BUY"
    var type_ = "LIMIT"
    var position_side = "LONG"
    var quantity = Fixed("0.01")
    var price = Fixed("20000")

    var order_start = time_us()

    var place_order_res = client.place_order(
        symbol, side, type_, position_side, quantity, price
    )
    logi("res=" + str(place_order_res))

    var cancel_order_res = client.cancel_order(symbol, order_id="237740210409")
    logi("res=" + str(cancel_order_res))

    var order_end = time_us()

    logi("Time consumption: " + str(order_end - order_start) + " us")

    # Test order placement speed
    var times = 30
    var order_times = List[
        Int
    ]()  # Record the time taken for each order placement
    var cancel_times = List[
        Int
    ]()  # Record the time taken for each order cancellation

    var start_time = time_us()

    for i in range(times):
        # logi("i=" + str(i))

        var order_start = time_us()

        var res = client.place_order(
            symbol, side, type_, position_side, quantity, price
        )

        var order_end = time_us()

        logi(
            str(i)
            + ":Place order returns="
            + str(res)
            + " Time consumption: "
            + str(order_end - order_start)
            + " us"
        )

        var order_id = res.order_id

        logi("order_id: " + str(order_id))

        var cancel_start = time_us()

        var res1 = client.cancel_order(symbol, order_id=str(order_id))

        var cancel_end = time_us()

        logi(
            str(i)
            + ":Cancel order returns="
            + str(res1)
            + " Time consumption: "
            + str(cancel_end - cancel_start)
            + " us"
        )

        order_times.append(int(order_end - order_start))
        cancel_times.append(int(cancel_end - cancel_start))

        _ = seq_photon_thread_sleep_ms(500)

    var end_time = time_us()

    var total_time = end_time - start_time

    logi("Total time consumed:" + str(total_time) + " us")

    logi(
        "Average time taken for order placement:"
        + str(sum_int_list(order_times) / len(order_times))
        + " us"
    )
    logi(
        "Average time taken for order cancellation:"
        + str(sum_int_list(cancel_times) / len(cancel_times))
        + " us"
    )

    logi("Done!!!")

    run_forever()

    _ = client^


fn test_listen_key() raises:
    var env_dict = env_load()

    var access_key = env_dict["BINANCE_API_KEY"]
    var secret_key = env_dict["BINANCE_API_SECRET"]
    logi("access_key=" + access_key)
    logi("secret_key=" + secret_key)
    var client = BinanceClient(
        testnet=False, access_key=access_key, secret_key=secret_key
    )
    client.set_verbose(True)
    # var res = client.generate_listen_key()
    # logi("res=" + res)

    var res = client.extend_listen_key()
    logi("res=" + str(res))

    # var listen_key = "rioNZjETMWuZLTPkI3HGBZ6FMjJCerqbL5w8FcdWLWLn9LRFPYg79JIwVLPLXOmp"


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
    var ret = seq_photon_init_default()
    seq_init_photon_work_pool(2)
    # seq_init_log(LOG_LEVEL_DBG, "test_binance.log")
    seq_init_log(LOG_LEVEL_DBG, "")
    # seq_init_log(LOG_LEVEL_OFF, "")
    # seq_init_net(0)
    seq_init_net(1)

    logi("Initialization return result: " + str(ret))

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

    logi("The program is prepared and ready, awaiting events...")
    run_forever()
