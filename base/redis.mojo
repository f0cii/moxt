from .c import *


fn test_redis() -> None:
    var redis = seq_redis_new("1.94.26.93", "X3fV!9zP$8yM*2dQ", 0, 1000)
    var ok = seq_redis_set(redis, "test_0", "1")
    print(ok)
    var s = seq_redis_get(redis, "test_0")
    print(s)
    seq_redis_free(redis)


fn seq_redis_new(
    host: String, password: String, db: Int, timeout_ms: Int
) -> c_void_pointer:
    var port = 6379
    return __mlir_op.`pop.external_call`[
        func = "seq_redis_new".value, _type=c_void_pointer
    ](
        host._buffer.data.value,
        len(host),
        port,
        password._buffer.data.value,
        len(password),
        db,
        timeout_ms,
    )


fn seq_redis_set(redis: c_void_pointer, key: String, value: String) -> Bool:
    return external_call[
        "seq_redis_set",
        Bool,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        c_char_pointer,
        c_size_t,
    ](
        redis,
        key._buffer.data.value,
        len(key),
        value._buffer.data.value,
        len(value),
    )


fn seq_redis_get(redis: c_void_pointer, key: String) -> String:
    var value_data = Pointer[UInt8].alloc(1024)
    var value_len = c_size_t(0)
    var ok = external_call[
        "seq_redis_get",
        Bool,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](
        redis,
        key._buffer.data.value,
        len(key),
        value_data,
        Pointer[c_size_t].address_of(value_len),
    )
    if ok:
        var s = c_str_to_string(value_data, value_len)
        value_data.free()
        return s
    else:
        value_data.free()
        return ""


fn seq_redis_free(redis: c_void_pointer) -> None:
    external_call["seq_redis_free", NoneType](redis)
