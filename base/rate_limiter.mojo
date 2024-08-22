from .c import *
from .mo import *


fn seq_new_crate_limiter(
    max_count: c_int, window_size: UInt64
) -> c_void_pointer:
    return external_call[
        "seq_new_crate_limiter", c_void_pointer, c_int, UInt64
    ](max_count, window_size)


fn seq_crate_limiter_allow_and_record_request(ptr: c_void_pointer) -> Bool:
    return external_call[
        "seq_crate_limiter_allow_and_record_request", Bool, c_void_pointer
    ](ptr)


fn seq_delete_crate_limiter(ptr: c_void_pointer) -> None:
    external_call["seq_delete_crate_limiter", NoneType, c_void_pointer](ptr)


@value
struct RateLimiter:
    var _ptr: c_void_pointer

    fn __init__(inout self, max_count: Int, window_size: UInt64):
        self._ptr = seq_new_crate_limiter(max_count, window_size)

    fn __del__(owned self: Self):
        if self._ptr == c_void_pointer():
            return
        seq_delete_crate_limiter(self._ptr)
        self._ptr = c_void_pointer()

    fn allow_and_record_request(self) -> Bool:
        return seq_crate_limiter_allow_and_record_request(self._ptr)
