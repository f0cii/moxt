from c import *
from mo import *


def hmac_sha256_b64(message: String, secret_key: String) -> String:
    let b_ptr = Pointer[UInt8].alloc(32)
    let n = seq_hmac_sha256(
        to_schar_ptr(secret_key),
        len(secret_key),
        to_schar_ptr(message),
        len(message),
        b_ptr,
    )
    let s_ptr = Pointer[UInt8].alloc(50)
    let s_len = seq_base64_encode(b_ptr, n, s_ptr)
    return c_str_to_string(s_ptr, s_len)


def hmac_sha256_hex(message: String, secret_key: String) -> String:
    let b_ptr = Pointer[UInt8].alloc(32)
    let n = seq_hmac_sha256(
        to_schar_ptr(secret_key),
        len(secret_key),
        to_schar_ptr(message),
        len(message),
        b_ptr,
    )
    let s_ptr = Pointer[UInt8].alloc(50)
    let s_len = seq_hex_encode(b_ptr, n, s_ptr)
    return c_str_to_string(s_ptr, s_len)
