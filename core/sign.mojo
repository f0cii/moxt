from base.c import *
from base.mo import *


def hmac_sha256_b64(message: String, secret_key: String) -> String:
    var b_ptr = Pointer[UInt8].alloc(32)
    var secret_key_cstr = to_schar_ptr(secret_key)
    var message_cstr = to_schar_ptr(message)
    var n = seq_hmac_sha256(
        secret_key_cstr,
        len(secret_key),
        message_cstr,
        len(message),
        b_ptr,
    )
    var s_ptr = Pointer[UInt8].alloc(50)
    var s_len = seq_base64_encode(b_ptr, n, s_ptr)
    var s = c_str_to_string(s_ptr, s_len)

    b_ptr.free()
    s_ptr.free()
    secret_key_cstr.free()
    message_cstr.free()

    return s


def hmac_sha256_hex(message: String, secret_key: String) -> String:
    var b_ptr = Pointer[UInt8].alloc(32)
    var secret_key_cstr = to_schar_ptr(secret_key)
    var message_cstr = to_schar_ptr(message)
    var n = seq_hmac_sha256(
        secret_key_cstr,
        len(secret_key),
        message_cstr,
        len(message),
        b_ptr,
    )
    var s_ptr = Pointer[UInt8].alloc(80)
    var s_len = seq_hex_encode(b_ptr, n, s_ptr)
    var s = c_str_to_string(s_ptr, s_len)

    b_ptr.free()
    s_ptr.free()
    secret_key_cstr.free()
    message_cstr.free()

    return s
