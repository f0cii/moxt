import sys.ffi
from memory import memcpy, memset_zero
from time import time_function
from .c import *

# typedef void (*task_entry)(void *arg);
alias task_entry = fn (c_void_pointer) raises -> c_void_pointer


fn seq_ct_init() -> Int:
    return external_call["seq_ct_init", Int]()


fn seq_voidptr_to_int(p: c_void_pointer) -> Int:
    return external_call["seq_voidptr_to_int", Int, c_void_pointer](p)


fn seq_int_to_voidptr(i: Int) -> c_void_pointer:
    return external_call["seq_int_to_voidptr", c_void_pointer, Int](i)


# 读取全局对象地址值
fn seq_store_object_address(id: Int, ptr: Int) -> None:
    return external_call["seq_store_object_address", NoneType, Int, Int](id, ptr)


# 存储全局对象地址值
fn seq_retrieve_object_address(id: Int) -> Int:
    return external_call["seq_retrieve_object_address", Int, Int](id)


fn seq_init_photon_work_pool(pool_size: Int) -> None:
    external_call["seq_init_photon_work_pool", NoneType, Int](pool_size)


fn seq_photon_work_pool() -> c_void_pointer:
    return external_call["seq_photon_work_pool", c_void_pointer]()


fn seq_photon_thread_create_and_migrate_to_work_pool(
    entry: task_entry, arg: c_void_pointer
) -> None:
    external_call[
        "seq_photon_thread_create_and_migrate_to_work_pool",
        NoneType,
        task_entry,
        c_void_pointer,
    ](entry, arg)


# void seq_photon_set_log_output(uint8_t mode)
fn seq_photon_set_log_output(mode: UInt8) -> None:
    external_call["seq_photon_set_log_output", NoneType, UInt8](mode)


fn seq_photon_init_default() -> Int:
    return external_call["seq_photon_init_default", Int]()


fn seq_nanoid() -> String:
    let result = Pointer[Int8].alloc(32)
    let n = external_call["seq_nanoid", c_size_t, c_char_pointer](result)
    return c_str_to_string(result, n)


let LOG_LEVEL_DBG: UInt8 = 0
let LOG_LEVEL_INF: UInt8 = 1
let LOG_LEVEL_WRN: UInt8 = 2
let LOG_LEVEL_ERR: UInt8 = 3
let LOG_LEVEL_OFF: UInt8 = 4


# 初始化日志
fn seq_init_log(level: UInt8, filename: String) -> None:
    external_call["seq_init_log", NoneType, UInt8, Pointer[c_schar], c_int](
        level, filename._buffer.data.value, len(filename)
    )


fn seq_logd(s: Pointer[c_schar], length: c_int):
    external_call["seq_logvd", NoneType, Pointer[c_schar], c_int](s, length)


fn seq_logi(s: Pointer[c_schar], length: c_int):
    external_call["seq_logvi", NoneType, Pointer[c_schar], c_int](s, length)


fn seq_logw(s: Pointer[c_schar], length: c_int):
    external_call["seq_logvw", NoneType, Pointer[c_schar], c_int](s, length)


fn seq_loge(s: Pointer[c_schar], length: c_int):
    external_call["seq_logve", NoneType, Pointer[c_schar], c_int](s, length)


@always_inline
fn logd(s: String):
    seq_logd(s._buffer.data.value, len(s))


@always_inline
fn logi(s: String):
    seq_logi(s._buffer.data.value, len(s))


@always_inline
fn logw(s: String):
    seq_logw(s._buffer.data.value, len(s))


@always_inline
fn loge(s: String):
    seq_loge(s._buffer.data.value, len(s))


# type: 0-STD_THREAD 1-PHOTON
fn seq_init_net(type_: Int) -> None:
    external_call["seq_init_net", NoneType, Int](type_)


# SEQ_FUNC ondemand::parser *
# seq_simdjson_ondemand_parser_new(size_t max_capacity);
fn seq_simdjson_ondemand_parser_new(max_capacity: c_size_t) -> c_void_pointer:
    return external_call["seq_simdjson_ondemand_parser_new", c_void_pointer, c_size_t](
        max_capacity
    )


# SEQ_FUNC padded_string *
# seq_simdjson_padded_string_new(const char *s, size_t len);
fn seq_simdjson_padded_string_new(s: c_char_pointer, len: c_size_t) -> c_void_pointer:
    return external_call[
        "seq_simdjson_padded_string_new",
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](s, len)


# SEQ_FUNC ondemand::document *
# seq_simdjson_ondemand_parser_parse(ondemand::parser *parser,
#                                    padded_string *data);
fn seq_simdjson_ondemand_parser_parse(
    parser: c_void_pointer, data: c_void_pointer
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_parser_parse",
        c_void_pointer,
        c_void_pointer,
        c_void_pointer,
    ](parser, data)


# const char *
# seq_simdjson_ondemand_get_string_d(ondemand ::document *p,
#                                    const char *key, size_t len, size_t *n)
fn seq_simdjson_ondemand_get_string_d(
    p: c_void_pointer,
    key: c_char_pointer,
    len: c_size_t,
    n: Pointer[c_size_t],
) -> c_char_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_string_d",
        c_char_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Pointer[c_size_t],
    ](p, key, len, n)


fn seq_simdjson_ondemand_get_string_v(
    p: c_void_pointer,
    key: c_char_pointer,
    len: c_size_t,
    n: Pointer[c_size_t],
) -> c_char_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_string_v",
        c_char_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Pointer[c_size_t],
    ](p, key, len, n)


fn seq_simdjson_ondemand_get_string_o(
    p: c_void_pointer,
    key: c_char_pointer,
    len: c_size_t,
    n: Pointer[c_size_t],
) -> c_char_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_string_o",
        c_char_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Pointer[c_size_t],
    ](p, key, len, n)


# int64_t seq_simdjson_ondemand_get_int_d(
#  ondemand::document *doc, const char *key, size_t len)
# from base.c import LIBRARY.seq_simdjson_ondemand_get_int_d(cobj, cobj, int) -> int
fn seq_simdjson_ondemand_get_int_d(
    doc: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_long:
    return external_call[
        "seq_simdjson_ondemand_get_int_d",
        c_long,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](doc, key, len)


fn seq_simdjson_ondemand_get_uint_d(
    doc: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_long:
    return external_call[
        "seq_simdjson_ondemand_get_uint_d",
        c_long,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](doc, key, len)


fn seq_simdjson_ondemand_get_float_d(
    doc: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_double:
    return external_call[
        "seq_simdjson_ondemand_get_float_d",
        c_double,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](doc, key, len)


fn seq_simdjson_ondemand_get_bool_d(
    doc: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> Bool:
    return external_call[
        "seq_simdjson_ondemand_get_bool_d",
        Bool,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](doc, key, len)


# int64_t seq_simdjson_ondemand_get_int_v(
#  ondemand::value *value, const char *key, size_t len)
fn seq_simdjson_ondemand_get_int_v(
    value: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_long:
    return external_call[
        "seq_simdjson_ondemand_get_int_v",
        c_long,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](value, key, len)


fn seq_simdjson_ondemand_get_uint_v(
    value: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_long:
    return external_call[
        "seq_simdjson_ondemand_get_uint_v",
        c_long,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](value, key, len)


fn seq_simdjson_ondemand_get_float_v(
    value: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_double:
    return external_call[
        "seq_simdjson_ondemand_get_float_v",
        c_double,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](value, key, len)


fn seq_simdjson_ondemand_get_bool_v(
    value: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> Bool:
    return external_call[
        "seq_simdjson_ondemand_get_bool_v",
        Bool,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](value, key, len)


# int64_t seq_simdjson_ondemand_int_v(ondemand ::value *p)
fn seq_simdjson_ondemand_int_v(p: c_void_pointer) -> c_long:
    return external_call["seq_simdjson_ondemand_int_v", c_long, c_void_pointer](p)


fn seq_simdjson_ondemand_uint_v(p: c_void_pointer) -> c_long:
    return external_call["seq_simdjson_ondemand_uint_v", c_long, c_void_pointer](p)


fn seq_simdjson_ondemand_float_v(p: c_void_pointer) -> c_double:
    return external_call["seq_simdjson_ondemand_float_v", c_double, c_void_pointer](p)


fn seq_simdjson_ondemand_bool_v(p: c_void_pointer) -> Bool:
    return external_call["seq_simdjson_ondemand_bool_v", Bool, c_void_pointer](p)


# const char *
# seq_simdjson_ondemand_string_v(ondemand ::value *p, size_t *n)
fn seq_simdjson_ondemand_string_v(
    p: c_void_pointer, n: Pointer[c_size_t]
) -> c_char_pointer:
    return external_call[
        "seq_simdjson_ondemand_string_v",
        c_char_pointer,
        c_void_pointer,
        Pointer[c_size_t],
    ](p, n)


# SEQ_FUNC ondemand::object *seq_simdjson_ondemand_object_v(
#                                                           ondemand::value *p);
fn seq_simdjson_ondemand_object_v(p: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_object_v", c_void_pointer, c_void_pointer
    ](p)


# SEQ_FUNC ondemand::array *seq_simdjson_ondemand_array_v(
#                                                         ondemand::value *p);
fn seq_simdjson_ondemand_array_v(p: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_array_v", c_void_pointer, c_void_pointer
    ](p)


# int64_t seq_simdjson_ondemand_get_int_o(
#                                                    ondemand ::object *p,
#                                                    const char *key,
#                                                    size_t len)
fn seq_simdjson_ondemand_get_int_o(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_long:
    return external_call[
        "seq_simdjson_ondemand_get_int_o",
        c_long,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_ondemand_get_uint_o(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_long:
    return external_call[
        "seq_simdjson_ondemand_get_uint_o",
        c_long,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_ondemand_get_float_o(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_double:
    return external_call[
        "seq_simdjson_ondemand_get_float_o",
        c_double,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_ondemand_get_bool_o(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> Bool:
    return external_call[
        "seq_simdjson_ondemand_get_bool_o",
        Bool,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


# void *seq_simdjson_ondemand_get_value_d(
#                                                    ondemand ::document *doc,
#                                                    const char *key,
#                                                    size_t len)
fn seq_simdjson_ondemand_get_value_d(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_value_d",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_ondemand_get_object_d(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_object_d",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_ondemand_get_array_d(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_array_d",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


# void *seq_simdjson_ondemand_get_value_v(
#                                                    ondemand ::value *value,
#                                                    const char *key,
#                                                    size_t len)
fn seq_simdjson_ondemand_get_value_v(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_value_v",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_ondemand_get_object_v(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_object_v",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_ondemand_get_array_v(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_array_v",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


# void *seq_simdjson_ondemand_get_value_o(
#                                                    ondemand ::object *p,
#                                                    const char *key,
#                                                    size_t len)
fn seq_simdjson_ondemand_get_value_o(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_value_o",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_ondemand_get_object_o(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_object_o",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


fn seq_simdjson_ondemand_get_array_o(
    p: c_void_pointer, key: c_char_pointer, len: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_get_array_o",
        c_void_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
    ](p, key, len)


# void seq_simdjson_ondemand_parser_free(ondemand::parser *p)
fn seq_simdjson_ondemand_parser_free(p: c_void_pointer) -> None:
    external_call["seq_simdjson_ondemand_parser_free", NoneType, c_void_pointer](p)


fn seq_simdjson_padded_string_free(p: c_void_pointer) -> None:
    external_call["seq_simdjson_padded_string_free", NoneType, c_void_pointer](p)


fn seq_simdjson_ondemand_document_free(p: c_void_pointer) -> None:
    external_call["seq_simdjson_ondemand_document_free", NoneType, c_void_pointer](p)


fn seq_simdjson_ondemand_value_free(p: c_void_pointer) -> None:
    external_call["seq_simdjson_ondemand_value_free", NoneType, c_void_pointer](p)


fn seq_simdjson_ondemand_object_free(p: c_void_pointer) -> None:
    external_call["seq_simdjson_ondemand_object_free", NoneType, c_void_pointer](p)


fn seq_simdjson_ondemand_array_free(p: c_void_pointer) -> None:
    external_call["seq_simdjson_ondemand_array_free", NoneType, c_void_pointer](p)


# ########## ondemand array ##########
# SEQ_FUNC size_t seq_simdjson_ondemand_array_count_elements(
#                                                            ondemand::array *p);
fn seq_simdjson_ondemand_array_count_elements(p: c_void_pointer) -> c_size_t:
    return external_call[
        "seq_simdjson_ondemand_array_count_elements",
        c_size_t,
        c_void_pointer,
    ](p)


# SEQ_FUNC ondemand::value *
# seq_simdjson_ondemand_array_at(ondemand::array *p, size_t index);
fn seq_simdjson_ondemand_array_at(p: c_void_pointer, index: c_size_t) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_array_at",
        c_void_pointer,
        c_void_pointer,
        c_size_t,
    ](p, index)


# SEQ_FUNC ondemand::object *
# seq_simdjson_ondemand_array_at_obj(ondemand::array *p,
#                                    size_t index);
fn seq_simdjson_ondemand_array_at_obj(
    p: c_void_pointer, index: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_array_at_obj",
        c_void_pointer,
        c_void_pointer,
        c_size_t,
    ](p, index)


# SEQ_FUNC ondemand::array *
# seq_simdjson_ondemand_array_at_arr(ondemand::array *p,
#                                    size_t index);
fn seq_simdjson_ondemand_array_at_arr(
    p: c_void_pointer, index: c_size_t
) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_array_at_arr",
        c_void_pointer,
        c_void_pointer,
        c_size_t,
    ](p, index)


# int64_t seq_simdjson_ondemand_array_at_int(
#                                                       ondemand ::array *p,
#                                                       size_t index);
fn seq_simdjson_ondemand_array_at_int(p: c_void_pointer, index: c_size_t) -> c_long:
    return external_call[
        "seq_simdjson_ondemand_array_at_int",
        c_long,
        c_void_pointer,
        c_size_t,
    ](p, index)


fn seq_simdjson_ondemand_array_at_uint(p: c_void_pointer, index: c_size_t) -> c_long:
    return external_call[
        "seq_simdjson_ondemand_array_at_uint",
        c_long,
        c_void_pointer,
        c_size_t,
    ](p, index)


fn seq_simdjson_ondemand_array_at_float(p: c_void_pointer, index: c_size_t) -> c_double:
    return external_call[
        "seq_simdjson_ondemand_array_at_float",
        c_double,
        c_void_pointer,
        c_size_t,
    ](p, index)


fn seq_simdjson_ondemand_array_at_bool(p: c_void_pointer, index: c_size_t) -> Bool:
    return external_call[
        "seq_simdjson_ondemand_array_at_bool",
        Bool,
        c_void_pointer,
        c_size_t,
    ](p, index)


# SEQ_FUNC const char *seq_simdjson_ondemand_array_at_str(
#                                                         ondemand::array *p,
#                                                         size_t index,
#                                                         size_t *n);
fn seq_simdjson_ondemand_array_at_str(
    p: c_void_pointer, index: c_size_t, n: Pointer[c_size_t]
) -> c_char_pointer:
    return external_call[
        "seq_simdjson_ondemand_array_at_str",
        c_char_pointer,
        c_void_pointer,
        c_size_t,
        Pointer[c_size_t],
    ](p, index, n)


# SEQ_FUNC int64_t seq_simdjson_ondemand_value_type(ondemand::value *p);
fn seq_simdjson_ondemand_value_type(p: c_void_pointer) -> c_long:
    return external_call["seq_simdjson_ondemand_value_type", c_long, c_void_pointer](p)


# SEQ_FUNC ondemand::value *
# seq_simdjson_ondemand_array_iter_get(
#                                      ondemand::array_iterator *self)
fn seq_simdjson_ondemand_array_iter_get(p: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_array_iter_get",
        c_void_pointer,
        c_void_pointer,
    ](p)


# int64_t
# seq_simdjson_ondemand_array_iter_get_int(
#                                          ondemand ::array_iterator *self);
fn seq_simdjson_ondemand_array_iter_get_int(p: c_void_pointer) -> c_long:
    return external_call[
        "seq_simdjson_ondemand_array_iter_get_int",
        c_long,
        c_void_pointer,
    ](p)


fn seq_simdjson_ondemand_array_iter_get_uint(p: c_void_pointer) -> c_long:
    return external_call[
        "seq_simdjson_ondemand_array_iter_get_uint",
        c_long,
        c_void_pointer,
    ](p)


fn seq_simdjson_ondemand_array_iter_get_float(p: c_void_pointer) -> c_double:
    return external_call[
        "seq_simdjson_ondemand_array_iter_get_float",
        c_double,
        c_void_pointer,
    ](p)


fn seq_simdjson_ondemand_array_iter_get_bool(p: c_void_pointer) -> Bool:
    return external_call[
        "seq_simdjson_ondemand_array_iter_get_bool",
        Bool,
        c_void_pointer,
    ](p)


# const char *seq_simdjson_ondemand_array_iter_get_str(
#     ondemand::array_iterator *self, size_t *n);
fn seq_simdjson_ondemand_array_iter_get_str(
    p: c_void_pointer, n: Pointer[c_size_t]
) -> c_char_pointer:
    return external_call[
        "seq_simdjson_ondemand_array_iter_get_str",
        c_char_pointer,
        c_void_pointer,
        Pointer[c_size_t],
    ](p, n)


# ondemand::object *seq_simdjson_ondemand_array_iter_get_obj(
#     ondemand::array_iterator *self);
fn seq_simdjson_ondemand_array_iter_get_obj(p: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_array_iter_get_obj",
        c_void_pointer,
        c_void_pointer,
    ](p)


# SEQ_FUNC ondemand::array *seq_simdjson_ondemand_array_iter_get_arr(
#     ondemand::array_iterator *self);
fn seq_simdjson_ondemand_array_iter_get_arr(p: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_array_iter_get_arr",
        c_void_pointer,
        c_void_pointer,
    ](p)


# SEQ_FUNC ondemand::array_iterator *
# seq_simdjson_ondemand_array_begin(ondemand::array *p);
fn seq_simdjson_ondemand_array_begin(p: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_array_begin",
        c_void_pointer,
        c_void_pointer,
    ](p)


# SEQ_FUNC ondemand::array_iterator *
# seq_simdjson_ondemand_array_end(ondemand::array *p);
fn seq_simdjson_ondemand_array_end(p: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_simdjson_ondemand_array_end",
        c_void_pointer,
        c_void_pointer,
    ](p)


# SEQ_FUNC bool
# seq_simdjson_ondemand_array_iter_not_equal(ondemand::array_iterator *lhs,
#                                            ondemand::array_iterator *rhs);
fn seq_simdjson_ondemand_array_iter_not_equal(
    lhs: c_void_pointer, rhs: c_void_pointer
) -> Bool:
    return external_call[
        "seq_simdjson_ondemand_array_iter_not_equal",
        Bool,
        c_void_pointer,
        c_void_pointer,
    ](lhs, rhs)


# SEQ_FUNC void
# seq_simdjson_ondemand_array_iter_step(ondemand::array_iterator *self);
fn seq_simdjson_ondemand_array_iter_step(it: c_void_pointer) -> None:
    return external_call[
        "seq_simdjson_ondemand_array_iter_step", NoneType, c_void_pointer
    ](it)


# SEQ_FUNC void
# seq_simdjson_ondemand_array_iter_free(ondemand::array_iterator *p)
fn seq_simdjson_ondemand_array_iter_free(it: c_void_pointer) -> None:
    return external_call[
        "seq_simdjson_ondemand_array_iter_free",
        NoneType,
        c_void_pointer,
    ](it)


# SEQ_FUNC int seq_photon_init();
# alias fn_seq_photon_init = fn () -> Int  # c_int
fn seq_photon_init() -> Int:  # c_int
    return external_call["seq_photon_init", Int]()


# SEQ_FUNC void seq_photon_fini();
fn seq_photon_fini() -> None:
    external_call["seq_photon_fini", NoneType]()


# SEQ_FUNC photon::WorkPool *seq_photon_workpool_new(size_t pool_size);
fn seq_photon_workpool_new(pool_size: c_size_t) -> c_void_pointer:
    return external_call["seq_photon_workpool_new", c_void_pointer, c_size_t](pool_size)


# SEQ_FUNC void seq_photon_workpool_free(photon::WorkPool *pool);
fn seq_photon_workpool_free(pool: c_void_pointer) -> None:
    external_call["seq_photon_workpool_free", NoneType, c_void_pointer](pool)


fn seq_photon_join_current_vcpu_into_workpool(pool: c_void_pointer) -> None:
    external_call[
        "seq_photon_join_current_vcpu_into_workpool", NoneType, c_void_pointer
    ](pool)


fn seq_photon_workpool_get_vcpu_num(pool: c_void_pointer) -> Int:
    return external_call["seq_photon_workpool_get_vcpu_num", c_int, c_void_pointer](
        pool
    ).to_int()


# SEQ_FUNC void seq_photon_workpool_async_call(photon::WorkPool *pool,
#                                              task_entry entry, void *arg);
fn seq_photon_workpool_async_call(
    pool: c_void_pointer, entry: task_entry, arg: c_void_pointer
) -> None:
    external_call[
        "seq_photon_workpool_async_call",
        NoneType,
        c_void_pointer,
        task_entry,
        c_void_pointer,
    ](pool, entry, arg)


# SEQ_FUNC void seq_photon_workpool_async_call_with_cb(photon::WorkPool *pool,
#                                                      task_entry entry,
#                                                      void *arg,
#                                                      task_callback cb);
fn seq_photon_workpool_async_call_with_cb(
    pool: c_void_pointer, entry: task_entry, arg: c_void_pointer, cb: c_void_pointer
) -> None:
    external_call[
        "seq_photon_workpool_async_call_with_cb",
        NoneType,
        c_void_pointer,
        task_entry,
        c_void_pointer,
        c_void_pointer,
    ](pool, entry, arg, cb)


# SEQ_FUNC void seq_photon_workpool_call(photon::WorkPool *pool, task_entry entry,
#                                        void *arg);
fn seq_photon_workpool_call(
    pool: c_void_pointer, entry: task_entry, arg: c_void_pointer
) -> None:
    external_call[
        "seq_photon_workpool_call", NoneType, c_void_pointer, task_entry, c_void_pointer
    ](pool, entry, arg)


# SEQ_FUNC void seq_photon_workpool_call_with_cb(photon::WorkPool *pool,
#                                                task_entry entry, void *arg,
#                                                task_callback cb);
fn seq_photon_workpool_call_with_cb(
    pool: c_void_pointer, entry: task_entry, arg: c_void_pointer, cb: c_void_pointer
) -> None:
    external_call[
        "seq_photon_workpool_call_with_cb",
        NoneType,
        c_void_pointer,
        task_entry,
        c_void_pointer,
        c_void_pointer,
    ](pool, entry, arg, cb)


# SEQ_FUNC void seq_photon_thread_yield();
fn seq_photon_thread_yield() -> None:
    external_call["seq_photon_thread_yield", NoneType]()


fn seq_photon_thread_sleep_s(seconds: UInt64) -> None:
    external_call["seq_photon_thread_sleep_s", NoneType, UInt64](seconds)


fn seq_photon_thread_sleep_ms(mseconds: UInt64) -> c_int:
    return external_call["seq_photon_thread_sleep_ms", c_int, UInt64](mseconds)


fn seq_photon_thread_sleep_us(useconds: UInt64) -> c_int:
    return external_call["seq_photon_thread_sleep_us", c_int, UInt64](useconds)


# SEQ_FUNC FuncArgResult *seq_far_new();
fn seq_far_new() -> c_void_pointer:
    return external_call["seq_far_new", c_void_pointer]()


# SEQ_FUNC void seq_far_free(FuncArgResult *p);
fn seq_far_free(p: c_void_pointer) -> None:
    external_call["seq_far_free", NoneType, c_void_pointer](p)


# SEQ_FUNC size_t seq_far_size(FuncArgResult *p);
fn seq_far_size(p: c_void_pointer) -> c_size_t:
    return external_call["seq_far_size", c_size_t, c_void_pointer](p)


# SEQ_FUNC bool seq_far_set_int(FuncArgResult *p, const char *key, size_t key_len,
#                               int64_t value);
fn seq_far_set_int(
    p: c_void_pointer, key: c_char_pointer, key_len: c_size_t, value: Int64
) -> Bool:
    return external_call[
        "seq_far_set_int", Bool, c_void_pointer, c_char_pointer, c_size_t, Int64
    ](p, key, key_len, value)


# SEQ_FUNC bool seq_far_set_float(FuncArgResult *p, const char *key,
#                                  size_t key_len, double value);
fn seq_far_set_float(
    p: c_void_pointer, key: c_char_pointer, key_len: c_size_t, value: c_double
) -> Bool:
    return external_call[
        "seq_far_set_float", Bool, c_void_pointer, c_char_pointer, c_size_t, c_double
    ](p, key, key_len, value)


# SEQ_FUNC bool seq_far_set_bool(FuncArgResult *p, const char *key,
#                                size_t key_len, bool value);
fn seq_far_set_bool(
    p: c_void_pointer, key: c_char_pointer, key_len: c_size_t, value: Bool
) -> Bool:
    return external_call[
        "seq_far_set_bool", Bool, c_void_pointer, c_char_pointer, c_size_t, Bool
    ](p, key, key_len, value)


# SEQ_FUNC bool seq_far_set_string(FuncArgResult *p, const char *key,
#                                  size_t key_len, const char *value,
#                                  size_t value_len);
fn seq_far_set_string(
    p: c_void_pointer,
    key: c_char_pointer,
    key_len: c_size_t,
    value: c_char_pointer,
    value_len: c_size_t,
) -> Bool:
    return external_call[
        "seq_far_set_string",
        Bool,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        c_char_pointer,
        c_size_t,
    ](p, key, key_len, value, value_len)


# SEQ_FUNC int64_t seq_far_get_int(FuncArgResult *p, const char *key,
#                                    size_t key_len);
fn seq_far_get_int(p: c_void_pointer, key: c_char_pointer, key_len: c_size_t) -> Int64:
    return external_call[
        "seq_far_get_int", Int64, c_void_pointer, c_char_pointer, c_size_t
    ](p, key, key_len)


# SEQ_FUNC double seq_far_get_float(FuncArgResult *p, const char *key,
#                                    size_t key_len);
fn seq_far_get_float(
    p: c_void_pointer, key: c_char_pointer, key_len: c_size_t
) -> c_double:
    return external_call[
        "seq_far_get_float", c_double, c_void_pointer, c_char_pointer, c_size_t
    ](p, key, key_len)


# SEQ_FUNC bool seq_far_get_bool(FuncArgResult *p, const char *key,
#                                size_t key_len);
fn seq_far_get_bool(p: c_void_pointer, key: c_char_pointer, key_len: c_size_t) -> Bool:
    return external_call[
        "seq_far_get_bool", Bool, c_void_pointer, c_char_pointer, c_size_t
    ](p, key, key_len)


# SEQ_FUNC const char *seq_far_get_string(FuncArgResult *p, const char *key,
#                                         size_t key_len, size_t *n);
fn seq_far_get_string(
    p: c_void_pointer, key: c_char_pointer, key_len: c_size_t, n: Pointer[c_size_t]
) -> c_char_pointer:
    return external_call[
        "seq_far_get_string",
        c_char_pointer,
        c_void_pointer,
        c_char_pointer,
        c_size_t,
        Pointer[c_size_t],
    ](p, key, key_len, n)


fn seq_log_test() -> None:
    external_call["seq_log_test", NoneType]()


# const char* target, size_t len
fn test_photon_http(target: c_char_pointer, len: c_size_t) -> None:
    external_call["test_photon_http", NoneType, c_char_pointer, c_size_t](target, len)


fn test_1() -> None:
    external_call["test_1", NoneType]()


alias tlsv12 = 15
alias tlsv12_client = 16
alias tlsv13 = 18
alias tlsv13_client = 19


# SEQ_FUNC Client* seq_client_new(const char* baseUrl, size_t baseUrl_len, int64_t method);
fn seq_client_new(
    base_url: c_char_pointer, base_url_len: Int, method: Int = tlsv12_client
) -> c_void_pointer:
    return external_call["seq_cclient_new", c_void_pointer, c_char_pointer, Int, Int](
        base_url, base_url_len, method
    )


# SEQ_FUNC void seq_client_free(Client* client);
fn seq_client_free(client: c_void_pointer) -> None:
    external_call["seq_cclient_free", NoneType, c_void_pointer](client)


# SEQ_FUNC int64_t seq_cclient_do_request(
#     CClient *client, const char *path, size_t path_len, int64_t verb,
#     std::map<std::string, std::string> *headers, const char *body,
#     size_t body_len, char *res, size_t *n);
fn seq_cclient_do_request(
    client: c_void_pointer,
    path: c_char_pointer,
    path_len: c_size_t,
    verb: Int,
    headers: c_void_pointer,
    body: c_char_pointer,
    body_len: c_size_t,
    res: c_void_pointer,
    n: Pointer[c_size_t],
    verbose: Bool = False,
) -> Int:
    return __mlir_op.`pop.external_call`[
        func = "seq_cclient_do_request".value, _type=Int
    ](client, path, path_len, verb, headers, body, body_len, res, n, verbose)


# SEQ_FUNC void seq_c_free(char *res);
fn seq_c_free(res: c_void_pointer) -> None:
    external_call["seq_c_free", NoneType, c_void_pointer](res)


# SEQ_FUNC size_t seq_hmac_sha256(const char *secretKey, size_t secretKey_len,
#                               const char *message, size_t message_len,
#                               uint8_t *result);
fn seq_hmac_sha256(
    key: Pointer[c_schar],
    key_len: c_size_t,
    message: Pointer[c_schar],
    message_len: c_size_t,
    result: c_void_pointer,
) -> c_size_t:
    return external_call[
        "seq_hmac_sha256",
        c_size_t,
        Pointer[c_schar],
        c_size_t,
        Pointer[c_schar],
        c_size_t,
        c_void_pointer,
    ](key, key_len, message, message_len, result)


# SEQ_FUNC size_t seq_base64_encode(const uint8_t *input, size_t n, void *result);
fn seq_base64_encode(input: c_void_pointer, n: c_size_t, result: c_void_pointer) -> Int:
    return external_call[
        "seq_base64_encode", Int, c_void_pointer, c_size_t, c_void_pointer
    ](input, n, result)


fn seq_hex_encode(input: c_void_pointer, n: c_size_t, result: c_void_pointer) -> Int:
    return external_call[
        "seq_hex_encode", Int, c_void_pointer, c_size_t, c_void_pointer
    ](input, n, result)


# SEQ_FUNC void seq_test_hmac_sha256(const char *secretKey, size_t secretKey_len,
#                                    const char *message, size_t message_len)
fn seq_test_hmac_sha256(
    key: c_char_pointer,
    key_len: c_size_t,
    message: c_char_pointer,
    message_len: c_size_t,
) -> None:
    external_call[
        "seq_test_hmac_sha256",
        NoneType,
        c_char_pointer,
        c_size_t,
        c_char_pointer,
        c_size_t,
    ](key, key_len, message, message_len)


# SEQ_FUNC void seq_test_hmac_sha256_2()
fn seq_test_hmac_sha256_2() -> None:
    external_call["seq_test_hmac_sha256_2", NoneType]()


# SEQ_FUNC std::map<std::string, std::string> *seq_ssmap_new();
fn seq_ssmap_new() -> c_void_pointer:
    return external_call["seq_ssmap_new", c_void_pointer]()


# SEQ_FUNC void seq_ssmap_free(std::map<std::string, std::string> *p);
fn seq_ssmap_free(p: c_void_pointer) -> None:
    external_call["seq_ssmap_free", NoneType, c_void_pointer](p)


# SEQ_FUNC bool seq_ssmap_set(std::map<std::string, std::string> *p,
#                             const char *name, const char *value);
fn seq_ssmap_set(
    p: c_void_pointer, name: c_char_pointer, value: c_char_pointer
) -> None:
    _ = external_call[
        "seq_ssmap_set", Bool, c_void_pointer, c_char_pointer, c_char_pointer
    ](p, name, value)


# SEQ_FUNC const char *seq_ssmap_get(std::map<std::string, std::string> *p,
#                                    const char *name, size_t *n)
fn seq_ssmap_get(
    p: c_void_pointer, name: c_char_pointer, n: Pointer[c_size_t]
) -> c_char_pointer:
    return external_call[
        "seq_ssmap_get",
        c_char_pointer,
        c_void_pointer,
        c_char_pointer,
        Pointer[c_size_t],
    ](p, name, n)


# SEQ_FUNC size_t seq_ssmap_size(std::map<std::string, std::string> *p);
fn seq_ssmap_size(p: c_void_pointer) -> c_size_t:
    return external_call["seq_ssmap_size", c_size_t, c_void_pointer](p)


fn seq_websocket_new(
    host: c_char_pointer, port: c_char_pointer, path: c_char_pointer, tls_version: Int
) -> c_void_pointer:
    return external_call[
        "seq_websocket_new",
        c_void_pointer,
        c_char_pointer,
        c_char_pointer,
        c_char_pointer,
        Int,
    ](host, port, path, tls_version)


fn seq_websocket_delete(p: c_void_pointer) -> None:
    external_call["seq_websocket_delete", NoneType, c_void_pointer](p)


fn seq_websocket_connect(p: c_void_pointer) -> None:
    external_call["seq_websocket_connect", NoneType, c_void_pointer](p)


fn seq_websocket_disconnect(p: c_void_pointer) -> None:
    external_call["seq_websocket_disconnect", NoneType, c_void_pointer](p)


fn seq_websocket_send(p: c_void_pointer, text: c_char_pointer, len: c_size_t) -> None:
    external_call[
        "seq_websocket_send", NoneType, c_void_pointer, c_char_pointer, c_size_t
    ](p, text, len)


alias OnConnectCallback = fn (c_void_pointer) raises -> None
alias OnHeartbeatCallback = fn (c_void_pointer) raises -> None
alias OnMessageCallback = fn (c_void_pointer, c_char_pointer, c_size_t) raises -> None


fn seq_websocket_set_on_connect(p: c_void_pointer, cb: OnConnectCallback) -> None:
    external_call[
        "seq_websocket_set_on_connect", NoneType, c_void_pointer, OnConnectCallback
    ](p, cb)


fn seq_websocket_set_on_heartbeat(p: c_void_pointer, cb: OnHeartbeatCallback) -> None:
    external_call[
        "seq_websocket_set_on_heartbeat", NoneType, c_void_pointer, OnHeartbeatCallback
    ](p, cb)


fn seq_websocket_set_on_message(p: c_void_pointer, cb: OnMessageCallback) -> None:
    external_call[
        "seq_websocket_set_on_message", NoneType, c_void_pointer, OnMessageCallback
    ](p, cb)


fn seq_strtoi(s: c_char_pointer, s_len: c_size_t) -> Int:
    return external_call["seq_strtoi", Int, c_char_pointer, c_size_t](s, s_len)


fn seq_strtod(s: c_char_pointer, s_len: c_size_t) -> Float64:
    return external_call["seq_strtod", Float64, c_char_pointer, c_size_t](s, s_len)


fn test_identity_pool() -> None:
    return external_call["test_identity_pool", NoneType]()


fn seq_test_spdlog() -> None:
    return external_call["seq_test_spdlog", NoneType]()


fn test_ondemand_parser_pool() -> None:
    return external_call["test_ondemand_parser_pool", NoneType]()


fn seq_add(a: Int, b: Int) -> Int:
    return external_call["seq_add", Int, Int, Int](a, b)


fn seq_add_with_exception0(a: Int, b: Int) -> Int:
    return external_call["seq_add_with_exception0", Int, Int, Int](a, b)


fn seq_add_with_exception1(a: Int, b: Int) -> Int:
    return external_call["seq_add_with_exception1", Int, Int, Int](a, b)


# typedef void (*signal_handle_t)(int sig);
alias signal_handle_t = fn (c_int) raises -> None


# SEQ_FUNC void seq_init_signal(signal_handle_t handle);
fn seq_init_signal(callback: signal_handle_t) -> None:
    return external_call["seq_init_signal", NoneType, signal_handle_t](callback)


# SEQ_FUNC void seq_init_photon_signal(signal_handle_t handle);
fn seq_init_photon_signal(callback: signal_handle_t) -> None:
    return external_call["seq_init_photon_signal", NoneType, signal_handle_t](callback)


fn seq_skiplist_new(is_forward: Bool) -> c_void_pointer:
    return external_call["seq_skiplist_new", c_void_pointer, Bool](is_forward)


fn seq_skiplist_free(list: c_void_pointer) -> None:
    external_call["seq_skiplist_free", NoneType, c_void_pointer](list)


fn seq_skiplist_insert(
    list: c_void_pointer, key: Int64, value: Int64, update_if_exists: Bool
) -> Bool:
    return external_call[
        "seq_skiplist_insert", Bool, c_void_pointer, Int64, Int64, Bool
    ](list, key, value, update_if_exists)


fn seq_skiplist_remove(list: c_void_pointer, key: Int64) -> Int64:
    return external_call["seq_skiplist_remove", Int64, c_void_pointer, Int64](list, key)


fn seq_skiplist_search(list: c_void_pointer, key: Int64) -> Int64:
    return external_call["seq_skiplist_search", Int64, c_void_pointer, Int64](list, key)


fn seq_skiplist_dump(list: c_void_pointer) -> None:
    return external_call["seq_skiplist_dump", NoneType, c_void_pointer](list)


fn seq_skiplist_begin(list: c_void_pointer) -> c_void_pointer:
    return external_call["seq_skiplist_begin", c_void_pointer, c_void_pointer](list)


fn seq_skiplist_end(list: c_void_pointer) -> c_void_pointer:
    return external_call["seq_skiplist_end", c_void_pointer, c_void_pointer](list)


fn seq_skiplist_next(list: c_void_pointer, node: c_void_pointer) -> c_void_pointer:
    return external_call[
        "seq_skiplist_next", c_void_pointer, c_void_pointer, c_void_pointer
    ](list, node)


fn seq_skiplist_node_value(
    node: c_void_pointer, key: Pointer[Int64], value: Pointer[Int64]
) -> None:
    external_call[
        "seq_skiplist_node_value",
        NoneType,
        c_void_pointer,
        Pointer[Int64],
        Pointer[Int64],
    ](node, key, value)


fn seq_test_sonic_cpp() -> None:
    external_call[
        "seq_test_sonic_cpp",
        NoneType,
    ]()


fn seq_test_sonic_cpp_wrap() -> None:
    external_call[
        "seq_test_sonic_cpp_wrap",
        NoneType,
    ]()
