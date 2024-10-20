from sys import external_call
from sys import argv
import sys
from sys.param_env import is_defined, env_get_int, env_get_string
import time
from testing import assert_equal, assert_true, assert_false
from algorithm.functional import parallelize, sync_parallelize
from base.c import *
from base.mo import *
from base.globals import _GLOBAL
from base.thread import *
from base.websocket import (
    on_connect_callback,
    on_heartbeat_callback,
    on_message_callback,
)
from trade.config import *
from trade.base_strategy import *
from trade.executor import *
from .grid_strategy import GridStrategy
from .grid_strategy_pm import GridStrategyPM
from trade.backend_interactor import BackendInteractor
from ylstdlib.twofish import twofish_decrypt
import base.log
from sys import num_physical_cores, num_logical_cores, num_performance_cores
from memory.unsafe import bitcast


@value
struct ApiKey(CollectionElement, Stringable):
    var access_key: String
    var secret_key: String
    var testnet: Bool

    fn __str__(self) -> String:
        return self.access_key + ":" + self.secret_key + ":" + str(self.testnet)


@value
struct RedisSettings:
    var host: String
    var port: Int
    var password: String
    var db: Int

    fn __init__(inout self):
        self.host = ""
        self.port = 6379
        self.password = ""
        self.db = 0


@value
struct Param(CollectionElement, Stringable):
    var name: String
    var description: String
    var type: String
    var value: String

    fn __init__(
        inout self,
        name: String,
        description: String,
        type: String,
        value: String,
    ):
        self.name = name
        self.description = ""
        self.type = type
        self.value = value

    fn __str__(self) -> String:
        return self.name + "=" + self.value


@value
struct StrategyParams(CollectionElement, Stringable):
    var apikeys: List[ApiKey]
    var params: Dict[String, Param]
    var redis: RedisSettings

    fn __init__(
        inout self,
        apikeys: List[ApiKey],
        params: Dict[String, Param],
        redis: RedisSettings,
    ):
        self.apikeys = apikeys
        self.params = params
        self.redis = redis

    fn __init__(inout self):
        self.apikeys = List[ApiKey]()
        self.params = Dict[String, Param]()
        self.redis = RedisSettings()

    fn __str__(self) -> String:
        var result = String("")
        for apikey in self.apikeys:
            result += apikey[].access_key + ":" + apikey[].secret_key + "\n"
        for e in self.params.items():
            result += e[].key + "=" + e[].value.value + "\n"
        result += "\n"
        return result


fn parse_strategy_param(param_str: String) raises -> StrategyParams:
    var dom_parser = DomParser(1000 * 100)
    var doc = dom_parser.parse(param_str)
    var code = doc.get_int("code")
    var message = doc.get_str("message")
    if code != 0:
        raise "error code=" + str(code) + ", message=" + message

    var result = doc.get_object("result")
    var apikeys_array = result.get_array("apikeys")
    var params_array = result.get_array("params")
    var redis = result.get_object("redis")

    var apikeys = List[ApiKey]()
    var params = Dict[String, Param]()
    var apikeys_array_iter = apikeys_array.iter()

    while apikeys_array_iter.has_element():
        var obj = apikeys_array_iter.get()
        # "id": "2m2f7Nb2iZN",
        # "uid": "2kvBETEGfXv",
        # "label": "testnet-001",
        # "name": "bybit",
        # "access_key": "ab",
        # "secret_key": "bc",
        # "testnet": 1,
        # "created_at": "2024-03-05T08:18:26.367051+08:00",
        # "updated_at": "2024-03-16T10:30:19.599758+08:00",
        # "status": 1

        var id = obj.get_str("id")
        var uid = obj.get_str("uid")
        var label = obj.get_str("label")
        var name = obj.get_str("name")
        var access_key = obj.get_str("access_key")
        var secret_key = obj.get_str("secret_key")
        var testnet = obj.get_int("testnet") == 1

        logi("id=" + id)
        logi("uid=" + uid)
        logi("label=" + label)
        logi("name=" + name)
        logi("access_key=" + access_key)
        logi("secret_key=" + secret_key)

        apikeys.append(ApiKey(access_key, secret_key, testnet))

        apikeys_array_iter.step()

    var params_array_iter = params_array.iter()

    while params_array_iter.has_element():
        var obj = params_array_iter.get()
        # {
        #     "name": "s",
        #     "description": "s",
        #     "type": "string",
        #     "value": "s100",
        #     "def_val": "s100"
        # }

        var name = obj.get_str("name")
        var description = obj.get_str("description")
        var type = obj.get_str("type")
        var value = String("")
        if type == "string":
            value = obj.get_str("value")
        elif type == "int":
            value = str(obj.get_int("value"))
        elif type == "float":
            value = str(Fixed(obj.get_float("value")))
        elif type == "bool":
            value = str(obj.get_bool("value"))
        var def_val = obj.get_str("def_val")

        # logi("name=" + name)
        # logi("description=" + description)
        # logi("type=" + type)
        # logi("value=" + value)
        # logi("def_val=" + def_val)

        var param = Param(name, description, type, value)
        # logi("param " + name + "=" + value)
        params[name] = param

        params_array_iter.step()

    var redisSettings = RedisSettings()
    redisSettings.host = redis.get_str("host")
    redisSettings.port = redis.get_int("port")
    redisSettings.password = redis.get_str("pass")
    redisSettings.db = redis.get_int("db")

    _ = doc^
    _ = dom_parser^

    return StrategyParams(apikeys, params, redisSettings)


fn parse_strategy_param_to_app_config(
    strategy_param: StrategyParams,
) raises -> AppConfig:
    if len(strategy_param.apikeys) == 0:
        raise "apikeys is empty"

    var apikey = strategy_param.apikeys[0]
    var params = strategy_param.params

    if "symbols" not in params:
        raise "symbols is empty"

    var app_config = AppConfig()
    var app_config_ref = UnsafePointer[AppConfig].address_of(app_config)

    app_config_ref[].access_key = apikey.access_key
    app_config_ref[].secret_key = apikey.secret_key
    app_config_ref[].testnet = apikey.testnet
    app_config_ref[].depth = 1
    app_config_ref[].category = params["category"].value  # "linear"

    var symbols = params["symbols"].value

    app_config_ref[].symbols = symbols
    for e in params.items():
        # logi(e[].key + "=" + e[].value.value)
        app_config_ref[].params[e[].key] = e[].value.value

    return app_config


fn run_strategy(app_config: AppConfig) raises:
    var i_num_physical_cores = num_physical_cores()
    var i_num_logical_cores = num_logical_cores()
    var i_num_performance_cores = num_performance_cores()
    logi("i_num_physical_cores=" + str(i_num_physical_cores))
    logi("i_num_logical_cores=" + str(i_num_logical_cores))
    logi("i_num_performance_cores=" + str(i_num_performance_cores))
    if (
        i_num_physical_cores < 2
        or i_num_logical_cores < 2
        or i_num_performance_cores < 2
    ):
        raise "i_num_physical_cores=" + str(
            i_num_physical_cores
        ) + " i_num_logical_cores=" + str(
            i_num_logical_cores
        ) + " i_num_performance_cores=" + str(
            i_num_performance_cores
        ) + " is not enough"

    var strategy = app_config.strategy
    if strategy == "GridStrategy":
        var strategy = GridStrategy(app_config)
        var executor = Executor[GridStrategy](app_config, strategy^)
        __run_strategy[GridStrategy](executor)
        _ = executor^
    elif strategy == "GridStrategyPM":
        var strategy = GridStrategyPM(app_config)
        var executor = Executor[GridStrategyPM](app_config, strategy^)
        __run_strategy[GridStrategyPM](executor)
        _ = executor^
    else:
        raise "strategy=" + strategy + " is not supported"


fn __run_strategy[T: BaseStrategy](inout executor: Executor[T]) raises:
    var executor_ptr = int(UnsafePointer.address_of(executor))
    _GLOBAL()[].executor_ptr = executor_ptr

    logi("starting...")
    executor.start()
    logi("started")

    executor.run_once()

    var log_servie = log.log_service_itf()

    # parallelize
    # https://stackoverflow.com/questions/76562547/vectorize-vs-parallelize-in-mojo
    var g = _GLOBAL()
    var last_run_time = time.now()
    var interval = 10_000_000  # 10ms
    var current_time = time.now()
    var ioc = seq_asio_ioc()
    var err_count = 0
    while not g[].stop_requested_flag:
        seq_asio_ioc_poll(ioc)
        _ = log_servie[].perform()
        current_time = time.now()
        if current_time - last_run_time >= interval:
            try:
                executor.run_once()
                err_count = 0
            except e:
                if str(e) == str(TooManyPendingRequestsError):
                    err_count = 0
                else:
                    loge("run_once error: " + str(e))
                    err_count += 1

            if err_count >= 5:
                loge("run_once error too many times, stop")
                break
            last_run_time = current_time
        # _ = sleep_us(1000 * 10)
        time.sleep(0.01)

    logi("Executor stopping...")

    var stop_flag = False

    @parameter
    fn run_loop(n: Int) -> None:
        logi("task " + str(n) + " thread id: " + str(seq_thread_id()))
        _ = seq_photon_init_default()
        if n == 0:
            var ioc = seq_asio_ioc()
            while not stop_flag:
                # logi("task 0 loop")
                seq_asio_ioc_poll(ioc)
                # logi("task 0 loop end")
                time.sleep(0.001)
        elif n == 1:
            executor.stop_now()
            # var ptr = get_executor_ptr[T]()
            # ptr[].stop_now()
            stop_flag = True

    parallelize[run_loop](2)

    logi("Strategy execution finished")

    _ = log_servie[].perform_all()

    logi("run_strategy finished")


fn signal_handler(signum: Int) -> None:
    logi("handle_exit: " + str(signum))
    _GLOBAL()[].stop_requested_flag = True
