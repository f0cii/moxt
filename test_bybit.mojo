import time
from time import time_function
from memory import unsafe
from base.mo import *
from base.c import *
from base.thread import *
from base.sj_dom import *
from base.sj_ondemand import OndemandParser
from base.fixed import Fixed
from base.httpclient import HttpClient, VERB_GET, Headers, QueryParams
from base.websocket import *
from ylstdlib.time import time_ns
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

    var base_url = "https://api.bybit.com"
    var path = "/v3/public/time"

    # var base_url = "https://pss.bdstatic.com"
    # var path = "/static/superman/js/super_ext-a0b60bd05d.js"

    var client = HttpClient(base_url)
    # var headers = SSMap()
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
    var on_connect_ptr = int(Pointer[on_connect_callback].address_of(
        on_connect
    ))
    # print("on_connect_ptr: " + str(aon_connect_ptr))
    var on_heartbeat = ws.get_on_heartbeat()
    var on_heartbeat_ptr = int(Pointer[on_heartbeat_callback].address_of(
        on_heartbeat
    ))
    # print("on_heartbeat_ptr: " + str(on_heartbeat_ptr))
    var on_message = ws.get_on_message()
    var on_message_ptr = int(Pointer[on_message_callback].address_of(
        on_message
    ))
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
        var s = c_str_to_string(data, data_len)
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

    # var id = ws.get_id()
    var on_connect = ws.get_on_connect()
    var on_heartbeat = ws.get_on_heartbeat()
    var on_message = get_on_message()

    # var on_connect_ptr = Pointer[on_connect_callback].address_of(on_connect).__as_index()
    # var on_heartbeat_ptr = Pointer[on_heartbeat_callback].address_of(on_heartbeat).__as_index()
    # var on_message_ptr = Pointer[on_message_callback].address_of(on_message).__as_index()

    # ws.set_on_connect(on_connect_ptr)
    ws.set_on_connect(on_connect)
    ws.set_on_heartbeat(on_heartbeat)
    ws.set_on_message(on_message)

    # var topics = List[String]()
    # topics.append("orderbook.1.BTCUSDT")
    # ws.set_subscription(topics)
    ws.connect()

    logd("start")
    perform_ioc_poll()

    # run_forever()

    _ = ws ^


fn sum_int_list(v: List[Int]) raises -> Int:
    var result: Int = 0
    for item in v:
        result += item[]
    return result


fn test_bybitclient() raises:
    var app_config = load_config("config.toml")

    var access_key = app_config.access_key
    var secret_key = app_config.secret_key
    var testnet = app_config.testnet
    var client = BybitClient(
        testnet=testnet, access_key=access_key, secret_key=secret_key
    )

    client.set_verbose(True)

    # Preparation phase
    var server_time = client.fetch_public_time()
    logi(str(server_time))
    # _ = seq_photon_thread_sleep_ms(200)

    var category = "linear"
    # var symbol = "BTCUSDT"
    var symbol = "XRPUSDT"

    var exchange_info = client.fetch_exchange_info(category, symbol)
    logi(str(exchange_info))

    # <ExchangeInfo: symbol=BTCUSDT, tick_size=0.10000000000000001, step_size=0.001>

    var kline = client.fetch_kline(category, symbol, interval="1", limit=5, start=0, end=0)
    for item in kline:
        logi(str(item[]))

    # test_orderbook_parse_body()
    var ob = client.fetch_orderbook(category, symbol, 5)
    logi("-----asks-----")
    for item in ob.asks:
        logi(str(item[]))

    logi("-----bids-----")
    for item in ob.bids:
        logi(str(item[]))

    var switch_position_mode_res = client.switch_position_mode(category, symbol, "3")
    logi("res=" + str(switch_position_mode_res))
    # retCode=1, retMsg=Open orders exist, so you cannot change position mode

    # var set_leverage_res = client.set_leverage(category, symbol, "10", "10")
    # logi("res=" + str(set_leverage_res))

    # var side = "Buy"
    # var order_type = "Limit"
    # var qty = "0.001"
    # var price = "3000"

    # var place_order_res = client.place_order(category, symbol, side, order_type, qty, price, position_idx=1)
    # logi("res=" + str(place_order_res))
    # # retCode=1, retMsg=params error: The number of contracts exceeds minimum limit allowed

    # var cancel_order_res = client.cancel_order(category, symbol, "4d822437-a502-49d6-8aa7-55a602920b3f")
    # logi("res=" + str(cancel_order_res))

    # var cancel_orders_res = client.cancel_orders(category, symbol)
    # for item in cancel_orders_res:
    #     logi("item=" + str(item))

    # var fetch_balance_res = client.fetch_balance("CONTRACT", "USDT")
    # for item in fetch_balance_res:
    #     logi("item=" + str(item))

    # var fetch_orders_res = client.fetch_orders(category, symbol)
    # for item in fetch_orders_res:
    #     logi("item=" + str(item))

    # var fetch_positions_res = client.fetch_positions(category, symbol)
    # for item in fetch_positions_res:
    #     logi("item=" + str(item))
    # <PositionInfo: symbol=BTCUSDT, position_idx=1, side=Buy, size=0.015, avg_price=40869.30666667, position_value=613.0396, leverage=1.0, mark_price=42191.30, position_mm=0.0000075, position_im=6.130396, take_profit=0.00, stop_loss=0.00, unrealised_pnl=19.8299, cum_realised_pnl=838.09142572, created_time=1682125794703, updated_time=1706790560723>

    # Close position
    # var side = "Buy"
    # var order_type = "Limit"
    # var qty = "0.001"
    # var price = "3000"

    # var res = client.place_order(category, symbol, "Sell", "Market", qty, "", position_idx=1)
    # logi("res=" + str(res))

    logi("Done!!!")

    run_forever()

    _ = client ^


fn test_bybit_perf() raises:
    var app_config = load_config("config.toml")

    var access_key = app_config.access_key
    var secret_key = app_config.secret_key
    var testnet = app_config.testnet
    var client = BybitClient(
        testnet=testnet, access_key=access_key, secret_key=secret_key
    )

    client.set_verbose(True)

    # Preparation phase
    var server_time = client.fetch_public_time()
    logi(str(server_time))
    _ = seq_photon_thread_sleep_ms(200)

    var category = "linear"
    var symbol = "BTCUSDT"

    var side = "Buy"
    var order_type = "Limit"
    var qty = "0.001"
    var price = "10000"

    # Test order placement speed
    var times = 30
    var order_times = List[Int]()  # Record the time taken for each order placement
    var cancel_times = List[Int]()  # Record the time taken for each order cancellation

    var start_time = time_us()

    for i in range(times):
        # logi("i=" + str(i))

        var order_start = time_us()

        var res = client.place_order(
            category, symbol, side, order_type, qty, price, position_idx=1
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

        var cancel_start = time_us()

        var res1 = client.cancel_order(category, symbol, order_id)

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

    _ = client ^


fn run_forever():
    seq_photon_join_current_vcpu_into_workpool(seq_photon_work_pool())


fn handle_term(sig: c_int) raises -> None:
    print("handle_term")
    _ = exit(0)


fn photon_handle_term(sig: c_int) raises -> None:
    print("photon_handle_term")
    _ = exit(0)


fn perform_ioc_poll() -> None:
    var ioc = seq_asio_ioc()
    while True:
        seq_asio_ioc_poll(ioc)
        sleep(0.001)


fn main() raises:
    _ = seq_ct_init()
    var ret = seq_photon_init_default()
    seq_init_photon_work_pool(2)
    seq_init_log(LOG_LEVEL_DBG, "")
    # seq_init_log(LOG_LEVEL_OFF, "")
    # seq_init_net(0)
    # seq_init_net(1)

    logi("Initialization return result: " + str(ret))

    seq_init_signal(handle_term)
    seq_init_photon_signal(photon_handle_term)

    var coc = ObjectContainer[OnConnectWrapper]()
    var hoc = ObjectContainer[OnHeartbeatWrapper]()
    var moc = ObjectContainer[OnMessageWrapper]()

    var coc_ref = Reference(coc).get_unsafe_pointer()
    var hoc_ref = Reference(hoc).get_unsafe_pointer()
    var moc_ref = Reference(moc).get_unsafe_pointer()

    set_global_pointer(WS_ON_CONNECT_WRAPPER_PTR_KEY, int(coc_ref))
    set_global_pointer(WS_ON_HEARTBEAT_WRAPPER_PTR_KEY, int(hoc_ref))
    set_global_pointer(WS_ON_MESSAGE_WRAPPER_PTR_KEY, int(moc_ref))

    # while True:
    # test_httpclient_perf()
    # test_bybitclient()
    # test_bybitws()

    var ns = time_ns()
    logi("ns=" + str(ns))
    var expires = str(int(ns / 1e6 + 5000))
    logi("expires=" + expires)

    # logi("The program is prepared and ready, awaiting events...")
    # run_forever()

    _ = coc ^
    _ = hoc ^
    _ = moc ^
