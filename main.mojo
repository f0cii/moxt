from sys import argv
from sys.param_env import is_defined, env_get_int, env_get_string
import time
from testing import assert_equal, assert_true, assert_false
from algorithm.functional import parallelize, async_parallelize
from base.containers import ObjectContainer
from base.c import *
from base.mo import *
from base.globals import _GLOBAL
from base.thread import *
from base.websocket import OnConnectWrapper, OnHeartbeatWrapper, OnMessageWrapper
from trade.config import *
from trade.base_strategy import *
from trade.executor import *
from trading_strategies.grid_strategy import GridStrategy
from ylstdlib.twofish import twofish_decrypt


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
        inout self, name: String, description: String, type: String, value: String
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

    fn __init__(inout self, apikeys: List[ApiKey], params: Dict[String, Param], redis: RedisSettings):
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
            value = str(obj.get_float("value"))
        elif type == "bool":
            value = str(obj.get_bool("value"))
        var def_val = obj.get_str("def_val")

        # logi("name=" + name)
        # logi("description=" + description)
        # logi("type=" + type)
        # logi("value=" + value)
        # logi("def_val=" + def_val)

        params[name] = Param(name, description, type, value)

        params_array_iter.step()
    
    var redisSettings = RedisSettings()
    redisSettings.host = redis.get_str("host")
    redisSettings.port = redis.get_int("port")
    redisSettings.password = redis.get_str("pass")
    redisSettings.db = redis.get_int("db")

    _ = doc ^
    _ = dom_parser ^

    return StrategyParams(apikeys, params, redisSettings)


fn parse_strategy_param_to_app_config(
    strategy_param: StrategyParams,
) raises -> AppConfig:
    var app_config = AppConfig()
    if len(strategy_param.apikeys) == 0:
        raise "apikeys is empty"

    var apikey = strategy_param.apikeys[0]
    var params = strategy_param.params

    app_config.access_key = apikey.access_key
    app_config.secret_key = apikey.secret_key
    app_config.testnet = apikey.testnet
    app_config.category = "linear"
    app_config.depth = 1

    if "symbols" not in params:
        raise "symbols is empty"

    app_config.symbols = params["symbols"].value
    for e in params.items():
        app_config.params[e[].key] = e[].value.value

    return app_config


fn run_strategy(app_config: AppConfig) raises:
    var strategy = app_config.strategy
    if strategy == "GridStrategy":
        __run[GridStrategy](app_config)
    elif strategy == "GridStrategy2":
        __run[GridStrategy](app_config)
    else:
        raise "strategy=" + strategy + " is not supported"


fn stop_strategy_now():
    logi("stop_strategy_now")
    var strategy = _GLOBAL()[].current_strategy
    logi("strategy: " + strategy)
    var executor_ptr = _GLOBAL()[].executor_ptr
    logi("executor_ptr: " + str(executor_ptr))

    if strategy == "GridStrategy":
        logi("GridStrategy")
        var executor_ptr_0 = Pointer[Executor[GridStrategy]].__from_index(
            executor_ptr
        )
        executor_ptr_0[].stop_now()
    elif strategy == "GridStrategy2":
        logi("GridStrategy")
        var executor_ptr_0 = Pointer[Executor[GridStrategy]].__from_index(
            executor_ptr
        )
        executor_ptr_0[].stop_now()
    else:
        logw("not support strategy: " + strategy)


fn __run[T: BaseStrategy](app_config: AppConfig) raises:
    var strategy = create_strategy[T](app_config)
    var executor = Executor[T](app_config, strategy ^)

    var executor_ptr = Reference(executor).get_unsafe_pointer()
    _GLOBAL()[].executor_ptr = int(executor_ptr)

    executor.start()

    var ioc = seq_asio_ioc()

    var last_run_time = time.now()
    var current_time = time.now()
    var interval = 10_000_000  # 10ms
    var g = _GLOBAL()
    var log_servie = log.log_service_itf()

    while True:
        if g[].stop_requested_flag:
            logi("Stop flag set, exiting run loop")
            break

        seq_asio_ioc_poll(ioc)

        _ = log_servie[].perform()

        current_time = time.now()
        if current_time - last_run_time >= interval:
            executor.run_once()
            last_run_time = current_time

    # # Cleanup
    # logi("Stopping executor")
    # executor.stop_now()
    # logi("Strategy execution finished")

    # # Set global flag to notify stop safetly
    # set_stopped_flag()


fn signal_handler(signum: Int) -> None:
    logi("handle_exit called, set stop flag")

    _GLOBAL()[].stop_requested_flag = True
    time.sleep(0.5)
    stop_strategy_now()
    _ = log.log_service_itf()[].perform_all()
    # while not get_stopped_flag():
    #     logi("Wating for stop signal in handle_exit...")
    #     time.sleep(0.5)
    time.sleep(0.5)

    logi("exit...")
    _ = exit(0)


fn print_usage():
    print("Usage: ./moxt [options]")
    print("Example: ./moxt -v")
    print("Options:")
    print("  -log-level <string> Set the logging level (default: INFO)")
    print("  -log-file <string> Set the log file name (default: app.log)")
    print("  -c <string> Set the configuration file name (default: config.toml)")


fn main() raises:
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
        return

    # print("log_level=" + log_level)
    # print(config_file)

    _ = seq_ct_init()
    var ret = seq_photon_init_default()
    # seq_init_photon_work_pool(2)

    init_log(log_level, log_file)

    logi("Initialization return result: " + str(ret))

    alias SIGINT = 2
    seq_register_signal_handler(SIGINT, signal_handler)

    var app_config: AppConfig = AppConfig()
    app_config = load_config(config_file)

    logi("Load configuration information: " + str(app_config))

    var g = _GLOBAL()
    g[].current_strategy = app_config.strategy
    g[].algo_id = 0

    run_strategy(app_config)
