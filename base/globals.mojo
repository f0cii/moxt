from base.mo import seq_set_global_int, seq_get_global_int


# Define the storage key for global pointers
alias GLOBAL_INT_KEY_START = 10000
alias TRADE_EXECUTOR_PTR_KEY = GLOBAL_INT_KEY_START + 1
alias WS_ON_CONNECT_WRAPPER_PTR_KEY = GLOBAL_INT_KEY_START + 2
alias WS_ON_HEARTBEAT_WRAPPER_PTR_KEY = GLOBAL_INT_KEY_START + 3
alias WS_ON_MESSAGE_WRAPPER_PTR_KEY = GLOBAL_INT_KEY_START + 4


alias GLOBAL_STRING_KEY_START = 10000
alias CURRENT_STRATEGY_KEY = GLOBAL_STRING_KEY_START + 1


# Set global pointer
@always_inline
fn set_global_pointer(key: Int, pointer: Int):
    seq_set_global_int(key, pointer)


# Get global pointer
@always_inline
fn get_global_pointer(key: Int) -> Int:
    return seq_get_global_int(key)
