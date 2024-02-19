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
from core.env import env_load
from trade.config import load_config


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
    # @parameter
    fn wrapper(data: c_char_pointer, data_len: Int):
        let s = c_str_to_string(data, data_len)
        logi("get_on_message=" + s)

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
    ws.set_on_connect(on_connect)
    ws.set_on_heartbeat(on_heartbeat)
    ws.set_on_message(on_message)

    # var topics = list[String]()
    # topics.append("orderbook.1.BTCUSDT")
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


fn test_bybitclient() raises:
    let app_config = load_config("config.toml")

    let access_key = app_config.access_key
    let secret_key = app_config.secret_key
    let testnet = app_config.testnet
    var client = BybitClient(
        testnet=testnet, access_key=access_key, secret_key=secret_key
    )

    client.set_verbose(True)

    # Preparation phase
    # let server_time = client.fetch_public_time()
    # logi(str(server_time))
    # _ = seq_photon_thread_sleep_ms(200)

    let category = "linear"
    # let symbol = "BTCUSDT"
    let symbol = "XRPUSDT"

    let exchange_info = client.fetch_exchange_info(category, symbol)
    logi(str(exchange_info))

    # <ExchangeInfo: symbol=BTCUSDT, tick_size=0.10000000000000001, step_size=0.001>

    # let kline = client.fetch_kline(category, symbol, interval="1", limit=5, start=0, end=0)
    # for item in kline:
    #     logi(str(item))

    # test_orderbook_parse_body()
    # let ob = client.fetch_orderbook(category, symbol, 5)
    # logi("-----asks-----")
    # for item in ob.asks:
    #     logi(str(item))

    # logi("-----bids-----")
    # for item in ob.bids:
    #     logi(str(item))

    # let res = client.switch_position_mode(category, symbol, "3")
    # logi("res=" + str(res))
    # retCode=1, retMsg=Open orders exist, so you cannot change position mode

    # let res = client.set_leverage(category, symbol, "10", "10")
    # logi("res=" + str(res))

    let side = "Buy"
    let order_type = "Limit"
    let qty = "0.001"
    let price = "3000"

    # let res = client.place_order(category, symbol, side, order_type, qty, price, position_idx=1)
    # logi("res=" + str(res))
    # retCode=1, retMsg=params error: The number of contracts exceeds minimum limit allowed

    # let res = client.cancel_order(category, symbol, "4d822437-a502-49d6-8aa7-55a602920b3f")
    # logi("res=" + str(res))

    # let res = client.cancel_orders(category, symbol)
    # for item in res:
    #     logi("item=" + str(item))

    # let res = client.fetch_balance("CONTRACT", "USDT")
    # for item in res:
    #     logi("item=" + str(item))

    # let res = client.fetch_orders(category, symbol)
    # for item in res:
    #     logi("item=" + str(item))

    # let res = client.fetch_positions(category, symbol)
    # for item in res:
    #     logi("item=" + str(item))
    # <PositionInfo: symbol=BTCUSDT, position_idx=1, side=Buy, size=0.015, avg_price=40869.30666667, position_value=613.0396, leverage=1.0, mark_price=42191.30, position_mm=0.0000075, position_im=6.130396, take_profit=0.00, stop_loss=0.00, unrealised_pnl=19.8299, cum_realised_pnl=838.09142572, created_time=1682125794703, updated_time=1706790560723>

    # Close position
    # let side = "Buy"
    # let order_type = "Limit"
    # let qty = "0.001"
    # let price = "3000"

    # let res = client.place_order(category, symbol, "Sell", "Market", qty, "", position_idx=1)
    # logi("res=" + str(res))

    logi("Done!!!")

    run_forever()

    _ = client ^


fn test_bybit_perf() raises:
    let app_config = load_config("config.toml")

    let access_key = app_config.access_key
    let secret_key = app_config.secret_key
    let testnet = app_config.testnet
    var client = BybitClient(
        testnet=testnet, access_key=access_key, secret_key=secret_key
    )

    client.set_verbose(True)

    # Preparation phase
    let server_time = client.fetch_public_time()
    logi(str(server_time))
    _ = seq_photon_thread_sleep_ms(200)

    let category = "linear"
    let symbol = "BTCUSDT"

    let side = "Buy"
    let order_type = "Limit"
    let qty = "0.001"
    let price = "10000"

    # Test order placement speed
    let times = 30
    var order_times = list[Int]()  # Record the time taken for each order placement
    var cancel_times = list[Int]()  # Record the time taken for each order cancellation

    let start_time = time_us()

    for i in range(times):
        # logi("i=" + str(i))

        let order_start = time_us()

        let res = client.place_order(
            category, symbol, side, order_type, qty, price, position_idx=1
        )

        let order_end = time_us()

        logi(
            str(i)
            + ":Place order returns="
            + str(res)
            + " Time consumption: "
            + str(order_end - order_start)
            + " us"
        )

        let order_id = res.order_id

        let cancel_start = time_us()

        let res1 = client.cancel_order(category, symbol, order_id)

        let cancel_end = time_us()

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

    let end_time = time_us()

    let total_time = end_time - start_time

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

    _ = client ^


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
    let ret = seq_photon_init_default()
    seq_init_photon_work_pool(2)
    seq_init_log(LOG_LEVEL_DBG, "")
    # seq_init_log(LOG_LEVEL_OFF, "")
    seq_init_net(0)
    # seq_init_net(1)

    logi("Initialization return result: " + str(ret))

    seq_init_signal(handle_term)
    seq_init_photon_signal(photon_handle_term)

    var coc = ObjectContainer[OnConnectWrapper]()
    var hoc = ObjectContainer[OnHeartbeatWrapper]()
    var moc = ObjectContainer[OnMessageWrapper]()

    let coc_ref = Reference(coc).get_unsafe_pointer()
    let hoc_ref = Reference(hoc).get_unsafe_pointer()
    let moc_ref = Reference(moc).get_unsafe_pointer()

    set_global_pointer(WS_ON_CONNECT_WRAPPER_PTR_KEY, coc_ref.__as_index())
    set_global_pointer(WS_ON_HEARTBEAT_WRAPPER_PTR_KEY, hoc_ref.__as_index())
    set_global_pointer(WS_ON_MESSAGE_WRAPPER_PTR_KEY, moc_ref.__as_index())

    # while True:
    # test_httpclient_perf()
    test_bybitclient()
    # test_bybitws()

    logi("The program is prepared and ready, awaiting events...")
    run_forever()

    _ = coc ^
    _ = hoc ^
    _ = moc ^
