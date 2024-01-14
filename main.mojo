import time
from base.c import *
from base.mo import *
from base.thread import *
from trade.config import load_config
from trade.trade_executor import *
from trade.base_strategy import *
from trade.grid_strategy import GridStrategy

alias MyExecutor = TradeExecutor[GridStrategy]
alias UseTradeExecutorFunction = fn (executor: MyExecutor) -> None


fn run_forever():
    seq_photon_join_current_vcpu_into_workpool(seq_photon_work_pool())


# fn __co_trade_executor_exit(executor: MyExecutor):
#     logd("__co_trade_executor_exit")
#     executor.stop_now()


fn handle_exit():
    let executor_ptr_index = get_gloabl_trade_executor_ptr()
    let executor_ptr = AnyPointer[MyExecutor].__from_index(executor_ptr_index)
    __get_address_as_lvalue(executor_ptr.value).stop_now()
    time.sleep(3)
    logi("exit...")
    _ = exit(0)


fn handle_term(sig: c_int) raises -> None:
    print("handle_term")
    handle_exit()


fn photon_handle_term(sig: c_int) raises -> None:
    print("photon_handle_term")
    handle_exit()


fn use_gloabl_trade_executor[use: UseTradeExecutorFunction]():
    let ptr = seq_retrieve_object_address(gloabl_trade_executor_ptr_key)
    let p = AnyPointer[MyExecutor].__from_index(ptr)
    use(__get_address_as_lvalue(p.value))


fn __timer_entry(arg: c_void_pointer) raises -> c_void_pointer:
    let ptr = seq_voidptr_to_int(arg)
    let executor_ptr = AnyPointer[MyExecutor].__from_index(ptr)
    __get_address_as_lvalue(executor_ptr.value).run()
    return c_void_pointer.get_null()


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

    let app_config = load_config(".env")

    logi("加载配置信息: " + str(app_config))
    # var strategy = GridStrategy(app_config)
    let strategy = create_strategy[GridStrategy](app_config)
    var executor = TradeExecutor[GridStrategy](app_config, strategy ^)
    executor.start()
    let executor_ptr = executor._get_ptr[MyExecutor]()
    let executor_ptr_index = executor_ptr.__as_index()
    set_gloabl_trade_executor_ptr(executor_ptr_index)

    let ptr = seq_int_to_voidptr(executor_ptr_index)
    seq_photon_thread_create_and_migrate_to_work_pool(__timer_entry, ptr)

    logi("程序已准备就绪，等待事件中...")
    run_forever()

    logi("Done!!!")

    _ = executor ^
