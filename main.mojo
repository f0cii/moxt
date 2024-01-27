import time
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

# 运行操作
alias ACTION_RUN = 1000

# 停止操作
alias ACTION_STOP_NOW = 1001

# 执行任务操作
alias ACTION_PERFORM_TASKS = 1002


fn execute_executor_action(action: Int, c_ptr: Int):
    let strategy = seq_get_global_string(CURRENT_STRATEGY_KEY)
    if strategy == "DynamicGridStrategy":
        __execute_executor_action[DynamicGridStrategy](c_ptr, action)
    elif strategy == "SmartGridStrategy":
        __execute_executor_action[SmartGridStrategy](c_ptr, action)


fn run(app_config: AppConfig) raises:
    let strategy = seq_get_global_string(CURRENT_STRATEGY_KEY)
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
    let executor_ptr = AnyPointer[Executor[T]].__from_index(c_ptr)
    if action == ACTION_RUN:
        __get_address_as_lvalue(executor_ptr.value).run()
    elif action == ACTION_STOP_NOW:
        __get_address_as_lvalue(executor_ptr.value).stop_now()
    elif action == ACTION_PERFORM_TASKS:
        __get_address_as_lvalue(executor_ptr.value).perform_tasks()


fn execute_executor_action(action: Int):
    let c_ptr = get_global_pointer(TRADE_EXECUTOR_PTR_KEY)
    execute_executor_action(action, c_ptr)


fn __executor_run_entry(arg: c_void_pointer) raises -> c_void_pointer:
    let ptr = seq_voidptr_to_int(arg)
    execute_executor_action(ACTION_RUN, ptr)
    return c_void_pointer.get_null()


fn __executor_perform_tasks_entry(arg: c_void_pointer) raises -> c_void_pointer:
    let ptr = seq_voidptr_to_int(arg)
    execute_executor_action(ACTION_PERFORM_TASKS, ptr)
    return c_void_pointer.get_null()


fn __run[T: BaseStrategy](app_config: AppConfig) raises:
    let strategy = create_strategy[T](app_config)
    var executor = Executor[T](app_config, strategy ^)

    executor.start()

    # let executor_ptr = executor._get_ptr[Executor[T]]()
    # let executor_ptr_index = executor_ptr.__as_index()
    let executor_ptr = Reference(executor).get_unsafe_pointer()
    let executor_ptr_index = executor_ptr.__as_index()
    set_global_pointer(TRADE_EXECUTOR_PTR_KEY, executor_ptr_index)

    let ptr = seq_int_to_voidptr(executor_ptr_index)
    seq_photon_thread_create_and_migrate_to_work_pool(__executor_run_entry, ptr)
    seq_photon_thread_create_and_migrate_to_work_pool(
        __executor_perform_tasks_entry, ptr
    )

    logi("程序已准备就绪，等待事件中...")
    run_forever()

    logi("Done!!!")

    _ = executor ^


fn main() raises:
    _ = seq_ct_init()
    let ret = seq_photon_init_default()
    seq_init_photon_work_pool(2)
    seq_init_log(LOG_LEVEL_DBG, "")
    # seq_init_log(LOG_LEVEL_INF, "")
    # seq_init_log(LOG_LEVEL_OFF, "")
    seq_init_net(0)
    # seq_init_net(1)

    logi("初始化返回: " + str(ret))

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

    let app_config = load_config("config.toml")

    logi("加载配置信息: " + str(app_config))

    seq_set_global_string(CURRENT_STRATEGY_KEY, app_config.strategy)

    # for key_value in app_config.params.items():
    #     logi(str(key_value.key))
    #     logi(key_value.value)

    run(app_config)

    _ = coc ^
    _ = hoc ^
    _ = moc ^
