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
from base.httpclient import HttpClient, VERB_GET, Headers, StringRefPair, QueryParams
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
from trade.config import load_config
from trade.trade_executor import TradeExecutor


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
    seq_init_net(1)

    logi("初始化返回: " + str(ret))

    seq_init_signal(handle_term)
    seq_init_photon_signal(photon_handle_term)

    let app_config = load_config("config.toml")

    logd("加载配置信息: " + str(app_config))
    # test_bybitws()
    let executor = TradeExecutor(app_config)
    executor.start()

    logi("程序已准备就绪，等待事件中...")
    run_forever()

    _ = executor
