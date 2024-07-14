from sys import argv
import sys
from sys.param_env import is_defined, env_get_int, env_get_string
import time
from base.globals import _GLOBAL
from trade.config import *
from strategies.runner import *


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
    # seq_init_photon_work_pool(1)

    init_log(log_level, log_file)

    # seq_init_net(0)
    # seq_init_net(1)

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
