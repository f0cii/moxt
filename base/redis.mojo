from .c import *


@value
struct Redis:
    var p: c_void_pointer

    fn __init__(
        inout self,
        host: String,
        port: Int,
        password: String,
        db: Int,
        timeout_ms: Int = 3 * 1000,
    ):
        self.p = seq_redis_new(host, port, password, db, timeout_ms)

    fn __del__(owned self):
        seq_redis_free(self.p)

    fn set(self, key: String, value: String) -> Bool:
        return seq_redis_set(self.p, key, value)

    fn get(self, key: String) -> String:
        return seq_redis_get(self.p, key)
    
    fn rpush(self, key: String, value: String) -> Int64:
        return seq_redis_rpush(self.p, key, value)


fn test_redis() -> None:
    var redis = Redis("1.94.26.93", 6379, "X3fV!9zP$8yM*2dQ", 0, 3000)
    var ok = redis.set("test_0", "1")
    print(ok)
    var s = redis.get("test_0")
    print(s)


fn test_redis_raw() -> None:
    var redis = seq_redis_new("1.94.26.93", 6379, "X3fV!9zP$8yM*2dQ", 0, 1000)
    var ok = seq_redis_set(redis, "test_0", "1")
    print(ok)
    var s = seq_redis_get(redis, "test_0")
    print(s)
    seq_redis_free(redis)


fn seq_redis_new(
    host: String, port: Int, password: String, db: Int, timeout_ms: Int
) -> c_void_pointer:
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


fn seq_redis_rpush(redis: c_void_pointer, key: String, value: String) -> Int64:
    return external_call[
        "seq_redis_rpush",
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

fn seq_redis_free(redis: c_void_pointer) -> None:
    external_call["seq_redis_free", NoneType](redis)
