from base.c import *
from base.mo import *


def hmac_sha256_b64(message: String, secret_key: String) -> String:
    let b_ptr = Pointer[UInt8].alloc(32)
    let secret_key_cstr = to_schar_ptr(secret_key)
    let message_cstr = to_schar_ptr(message)
    let n = seq_hmac_sha256(
        secret_key_cstr,
        len(secret_key),
        message_cstr,
        len(message),
        b_ptr,
    )
    let s_ptr = Pointer[UInt8].alloc(50)
    let s_len = seq_base64_encode(b_ptr, n, s_ptr)
    let s = c_str_to_string(s_ptr, s_len)

    b_ptr.free()
    s_ptr.free()
    secret_key_cstr.free()
    message_cstr.free()

    return s


def hmac_sha256_hex(message: String, secret_key: String) -> String:
    let b_ptr = Pointer[UInt8].alloc(32)
    let secret_key_cstr = to_schar_ptr(secret_key)
    let message_cstr = to_schar_ptr(message)
    let n = seq_hmac_sha256(
        secret_key_cstr,
        len(secret_key),
        message_cstr,
        len(message),
        b_ptr,
    )
    let s_ptr = Pointer[UInt8].alloc(80)
    let s_len = seq_hex_encode(b_ptr, n, s_ptr)
    let s = c_str_to_string(s_ptr, s_len)

    b_ptr.free()
    s_ptr.free()
    secret_key_cstr.free()
    message_cstr.free()

    return s
