from sys import argv
import time
from testing import assert_equal, assert_true, assert_false
from base.containers import ObjectContainer
from base.c import *
from base.mo import *
from base.globals import *
from base.thread import *
from base.websocket import OnConnectWrapper, OnHeartbeatWrapper, OnMessageWrapper
from trade.config import *
from trade.base_strategy import *
from trade.executor import *
from trading_strategies.dynamic_grid_strategy import DynamicGridStrategy
from trading_strategies.smart_grid_strategy import SmartGridStrategy

# Run operation
alias ACTION_RUN = 1000

# Stop operation
alias ACTION_STOP_NOW = 1001

# Perform tasks operation
alias ACTION_PERFORM_TASKS = 1002


fn execute_executor_action(action: Int, c_ptr: Int):
    var strategy = seq_get_global_string(CURRENT_STRATEGY_KEY)
    if strategy == "DynamicGridStrategy":
        __execute_executor_action[DynamicGridStrategy](c_ptr, action)
    elif strategy == "SmartGridStrategy":
        __execute_executor_action[SmartGridStrategy](c_ptr, action)


fn run(app_config: AppConfig) raises:
    var strategy = seq_get_global_string(CURRENT_STRATEGY_KEY)
    if strategy == "DynamicGridStrategy":
        __run[DynamicGridStrategy](app_config)
    elif strategy == "SmartGridStrategy":
        __run[SmartGridStrategy](app_config)


fn run_forever():
    seq_photon_join_current_vcpu_into_workpool(seq_photon_work_pool())


fn handle_exit():
    execute_executor_action(ACTION_STOP_NOW)
    time.sleep(3)
    logi("exit...")
    _ = exit(0)


fn handle_term(sig: c_int) raises -> None:
    print("handle_term")
    handle_exit()


fn photon_handle_term(sig: c_int) raises -> None:
    print("photon_handle_term")
    handle_exit()


fn __execute_executor_action[T: BaseStrategy](c_ptr: Int, action: Int):
    var executor_ptr = AnyPointer[Executor[T]].__from_index(c_ptr)
    if action == ACTION_RUN:
        __get_address_as_lvalue(executor_ptr.value).run()
    elif action == ACTION_STOP_NOW:
        __get_address_as_lvalue(executor_ptr.value).stop_now()
    elif action == ACTION_PERFORM_TASKS:
        __get_address_as_lvalue(executor_ptr.value).perform_tasks()


fn execute_executor_action(action: Int):
    var c_ptr = get_global_pointer(TRADE_EXECUTOR_PTR_KEY)
    execute_executor_action(action, c_ptr)


fn __executor_run_entry(arg: c_void_pointer) raises -> c_void_pointer:
    var ptr = seq_voidptr_to_int(arg)
    execute_executor_action(ACTION_RUN, ptr)
    return c_void_pointer.get_null()


fn __executor_perform_tasks_entry(arg: c_void_pointer) raises -> c_void_pointer:
    var ptr = seq_voidptr_to_int(arg)
    execute_executor_action(ACTION_PERFORM_TASKS, ptr)
    return c_void_pointer.get_null()


fn __run[T: BaseStrategy](app_config: AppConfig) raises:
    var strategy = create_strategy[T](app_config)
    var executor = Executor[T](app_config, strategy ^)

    executor.start()

    var executor_ptr = Reference(executor).get_unsafe_pointer()
    var executor_ptr_index = int(executor_ptr)
    set_global_pointer(TRADE_EXECUTOR_PTR_KEY, executor_ptr_index)

    var ptr = seq_int_to_voidptr(executor_ptr_index)
    seq_photon_thread_create_and_migrate_to_work_pool(__executor_run_entry, ptr)
    seq_photon_thread_create_and_migrate_to_work_pool(
        __executor_perform_tasks_entry, ptr
    )

    logi("The program is prepared and ready, awaiting events...")
    run_forever()

    logi("Done!!!")

    _ = executor ^


fn print_usage():
    print("Usage: ./moxt [options]")
    print("Example: ./moxt -v")
    print("Options:")
    print("  -log-level <string> Set the logging level (default: INFO)")
    print("  -log-file <string> Set the log file name (default: app.log)")
    print("  -c <string> Set the configuration file name (default: config.toml)")


fn main() raises:
    var host = String("")
    var secret = String("")
    var log_level = String("INF")  # Default log level set to "INF" for "Info"
    var log_file = String(
        ""
    )  # Initialize log file path as empty, meaning logging to stdout by default
    var config_file = String("config.toml")  # Default configuration file name

    @parameter
    fn argparse() raises -> Int:
        var args = argv()
        for i in range(1, len(args), 2):
            if args[i] == "-host":
                host = args[i + 1]
            if args[i] == "-secret":
                secret = args[i + 1]
            if args[i] == "-log-level":
                log_level = args[i + 1]
            if args[i] == "-log-file":
                log_file = args[i + 1]
            if args[i] == "-c":
                config_file = args[i + 1]
            if args[i] == "-v":
                return 2
            if args[i] == "-h":
                print_usage()
                return 0
        return 1

    var res = argparse()
    if res == 0:
        return

    # print("log_level=" + log_level)
    # print(config_file)

    var app_config: AppConfig = AppConfig()
    if host != "" and secret != "":
        print("exit")
        _ = exit(0)
    else:
        app_config = load_config(config_file)

    _ = seq_ct_init()
    var ret = seq_photon_init_default()
    seq_init_photon_work_pool(2)

    init_log(log_level, log_file)
    seq_init_net(0)
    # seq_init_net(1)

    logi("Initialization return result: " + str(ret))

    seq_init_signal(handle_term)
    seq_init_photon_signal(photon_handle_term)

    # Define global object
    var coc = ObjectContainer[OnConnectWrapper]()
    var hoc = ObjectContainer[OnHeartbeatWrapper]()
    var moc = ObjectContainer[OnMessageWrapper]()

    var coc_ref = Reference(coc).get_unsafe_pointer()
    var hoc_ref = Reference(hoc).get_unsafe_pointer()
    var moc_ref = Reference(moc).get_unsafe_pointer()

    set_global_pointer(WS_ON_CONNECT_WRAPPER_PTR_KEY, int(coc_ref))
    set_global_pointer(WS_ON_HEARTBEAT_WRAPPER_PTR_KEY, int(hoc_ref))
    set_global_pointer(WS_ON_MESSAGE_WRAPPER_PTR_KEY, int(moc_ref))

    logi("Load configuration information: " + str(app_config))

    seq_set_global_string(CURRENT_STRATEGY_KEY, app_config.strategy)

    run(app_config)

    _ = coc ^
    _ = hoc ^
    _ = moc ^
