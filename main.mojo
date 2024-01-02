from base.c import *
from base.mo import *
from trade.config import load_config
from trade.trade_executor import TradeExecutor
from trade.base_strategy import *
from trade.grid_strategy import GridStrategy


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
    seq_init_net(1)

    logi("初始化返回: " + str(ret))

    seq_init_signal(handle_term)
    seq_init_photon_signal(photon_handle_term)

    let app_config = load_config("config.toml")

    logd("加载配置信息: " + str(app_config))
    # var strategy = GridStrategy(app_config)
    let strategy = create_strategy[GridStrategy](app_config)
    let executor = TradeExecutor[GridStrategy](app_config, strategy^)
    executor.start()

    logi("程序已准备就绪，等待事件中...")
    run_forever()

    _ = executor ^
