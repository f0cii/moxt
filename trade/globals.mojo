from base.mo import *


alias gloabl_trade_executor_ptr_key = 10000


fn set_gloabl_trade_executor_ptr(ptr: Int):
    seq_store_object_address(gloabl_trade_executor_ptr_key, ptr)


fn get_gloabl_trade_executor_ptr() -> Int:
    return seq_retrieve_object_address(gloabl_trade_executor_ptr_key)
