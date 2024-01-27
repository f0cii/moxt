from base.mo import seq_set_global_int, seq_get_global_int


# 定义全局指针的存储Key
alias GLOBAL_INT_KEY_START = 10000
alias TRADE_EXECUTOR_PTR_KEY = GLOBAL_INT_KEY_START + 1
alias WS_ON_CONNECT_WRAPPER_PTR_KEY = GLOBAL_INT_KEY_START + 2
alias WS_ON_HEARTBEAT_WRAPPER_PTR_KEY = GLOBAL_INT_KEY_START + 3
alias WS_ON_MESSAGE_WRAPPER_PTR_KEY = GLOBAL_INT_KEY_START + 4


alias GLOBAL_STRING_KEY_START = 10000
alias CURRENT_STRATEGY_KEY = GLOBAL_STRING_KEY_START + 1


# 设置全局指针
@always_inline
fn set_global_pointer(key: Int, pointer: Int):
    seq_set_global_int(key, pointer)


# 获取全局指针
@always_inline
fn get_global_pointer(key: Int) -> Int:
    return seq_get_global_int(key)
