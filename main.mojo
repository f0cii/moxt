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
from trading_strategies.grid_strategy import GridStrategy
from trade.backend_interactor import BackendInteractor
from ylstdlib.twofish import twofish_decrypt
import base.log
from sys import num_physical_cores, num_logical_cores, num_performance_cores
from memory.unsafe import Pointer, bitcast


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
    var app_config_ref = Reference(app_config)

    app_config_ref[].access_key = apikey.access_key
    app_config_ref[].secret_key = apikey.secret_key
    app_config_ref[].testnet = apikey.testnet
    app_config_ref[].category = "linear"
    app_config_ref[].depth = 1

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
    # elif strategy == "GridPrintMoneyStrategy":
    #     var strategy = GridPrintMoneyStrategy(app_config)
    #     var executor = Executor[GridPrintMoneyStrategy](app_config, strategy^)
    #     __run_strategy[GridPrintMoneyStrategy](executor)
    #     _ = executor^
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
    while not g[].stop_requested_flag:
        seq_asio_ioc_poll(ioc)
        _ = log_servie[].perform()
        current_time = time.now()
        if current_time - last_run_time >= interval:
            executor.run_once()
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


fn print_usage():
    print("Usage: ./moxt [options]")
    print("Example: ./moxt -v")
    print("Options:")
    print("  -log-level <string> Set the logging level (default: INFO)")
    print("  -log-file <string> Set the log file name (default: app.log)")
    print(
        "  -c <string> Set the configuration file name (default: config.toml)"
    )


fn main() raises:
    # var mojo_version = String("")
    # var version = String(
    #     "1.0.0"
    # )  # Initialize version number with default value
    # var build_time = String(
    #     "--"
    # )  # Initialize build time with default placeholder
    # var build_version = String(
    #     "--"
    # )  # Initialize Git commit hash with default placeholder

    # if is_defined["MOJO_VERSION"]():
    #     mojo_version = env_get_string["MOJO_VERSION"]()
    #     mojo_version = mojo_version.replace("_", " ")
    # # Check and update version number if VERSION is defined in the environment
    # if is_defined["VERSION"]():
    #     version = env_get_string["VERSION"]()
    # # Check and update build time if BUILD_TIME is defined in the environment
    # if is_defined["BUILD_TIME"]():
    #     build_time = env_get_string["BUILD_TIME"]()
    # # Check and update build version (Git commit hash) if BUILD_VERSION is defined
    # if is_defined["BUILD_VERSION"]():
    #     build_version = env_get_string["BUILD_VERSION"]()

    var host = String("")
    var token = String("")
    var id = String("")
    var sid = String("")
    var algo = String("")
    var log_level = String("DBG")  # Default log level set to "INF" for "Info"
    var log_file = String(
        ""
    )  # Initialize log file path as empty, meaning logging to stdout by default
    var config_file = String("config.toml")  # Default configuration file name
    var test = False

    @parameter
    fn argparse() raises -> Int:
        var args = argv()
        for i in range(1, len(args), 2):
            if args[i] == "-host":
                host = args[i + 1]
            if args[i] == "-token":
                token = args[i + 1]
            if args[i] == "-id":
                id = args[i + 1]
            if args[i] == "-sid":
                sid = args[i + 1]
            if args[i] == "-algo":
                algo = args[i + 1]
            if args[i] == "-log-level":
                log_level = args[i + 1]
            if args[i] == "-log-file":
                log_file = args[i + 1]
            if args[i] == "-c":
                config_file = args[i + 1]
            if args[i] == "-test":
                test = True
            if args[i] == "-v":
                return 2
            if args[i] == "-h":
                print_usage()
                return 0
        return 1

    var res = argparse()
    if res == 0:
        return
    if test:
        return
    if res == 2:
        # print("Mojo version: " + mojo_version)
        # print("App version: " + version)
        # print("Build time: " + build_time)
        # print("Build version (git hash): " + build_version)
        return

    # print("log_level=" + log_level)
    # print(config_file)

    _ = seq_ct_init()
    var ret = seq_photon_init_default()
    # seq_init_photon_work_pool(1)

    init_log(log_level, log_file)

    # seq_init_net(0)
    # seq_init_net(1)

    logi("Initialization return result: " + str(ret))

    alias SIGINT = 2
    seq_register_signal_handler(SIGINT, signal_handler)

    if host != "" and token != "":
        # logi("Mojo version: " + mojo_version)
        # logi("App version: " + version)
        # logi("Build time: " + build_time)
        # logi("Build version (git hash): " + build_version)

        # "http://1.94.26.93"
        var backend_url = "http://" + host if "http://" not in host else host
        logi(backend_url)
        var bi = BackendInteractor(backend_url)
        # var username = ""
        # var password = ""
        # var login_res = bi.login(username, password)
        # var bot_id = id # "2m3snT6YMHo"
        # var token = ""

        logi("token=" + token)
        logi("id=" + id)
        logi("sid=" + sid)
        logi("algo=" + algo)

        var res = bi.get_bot_params(sid, token)
        print(res)
        var strategy_param = parse_strategy_param(res)

        var app_config = parse_strategy_param_to_app_config(strategy_param)
        app_config.strategy = algo
        logi("Load configuration information: " + str(app_config))

        var g = _GLOBAL()
        g[].current_strategy = app_config.strategy
        g[].algo_id = atol(sid)

        # 初始化日志
        var key = "0c6d6db61905400fee1f39e7fa26be87"
        var redis_pass = twofish_decrypt(strategy_param.redis.password, key)
        logi("redis_pass=" + redis_pass)
        log.log_service_itf()[].init(
            strategy_param.redis.host,
            strategy_param.redis.port,
            redis_pass,
            strategy_param.redis.db,
        )

        run_strategy(app_config)
    else:
        var app_config: AppConfig = AppConfig()
        app_config = load_config(config_file)

        logi("Load configuration information: " + str(app_config))

        var g = _GLOBAL()
        g[].current_strategy = app_config.strategy
        g[].algo_id = 0

        run_strategy(app_config)
