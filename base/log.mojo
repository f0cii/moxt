from sys.ffi import _get_global
from collections.optional import Optional
from collections.dict import Dict
from utils.variant import Variant
from .mo import seq_snowflake_id
from .sonic import SonicDocument, SonicNode
from .redis import Redis
from .thread import LockfreeQueue, lockfree_queue_itf
from .c import *
from .mo import *
from .fixed import Fixed
from ylstdlib.time import time_ns


alias Args = Variant[String, Int, Float64, Bool]
alias LOG_QUEUE = "_LOG_QUEUE"


# 记录交易事件日志
fn log_event(
    event_type: String,
    grid_level: Int,
    order_type: String,
    order_price: Fixed,
    order_quantity: Fixed,
    extra_info: Optional[Dict[String, Args]] = None,
):
    log_itf["MAIN"]()[]._write_event_log(
        event_type=event_type,
        grid_level=grid_level,
        order_type=order_type,
        order_price=order_price,
        order_quantity=order_quantity,
        extra_info=extra_info,
    )


fn debug(message: String, context: Optional[Dict[String, Args]] = None):
    log_itf["MAIN"]()[].debug(message, context)
    # logd(message)


fn info(message: String, context: Optional[Dict[String, Args]] = None):
    log_itf["MAIN"]()[].info(message, context)
    # logi(message)


fn warn(message: String, context: Optional[Dict[String, Args]] = None):
    log_itf["MAIN"]()[].warn(message, context)
    # logw(message)


fn error(message: String, context: Optional[Dict[String, Args]] = None):
    log_itf["MAIN"]()[].error(message, context)
    # loge(message)


@value
struct LogInterface:
    var algo_id: Int
    var q: UnsafePointer[LockfreeQueue]

    fn __init__(inout self):
        self.algo_id = 0
        self.q = lockfree_queue_itf[LOG_QUEUE]()

    fn set_alog_id(inout self, algo_id: Int):
        self.algo_id = algo_id

    fn debug(
        self, message: String, context: Optional[Dict[String, Args]] = None
    ):
        self._write_log("DEBUG", message, context)

    fn info(
        self, message: String, context: Optional[Dict[String, Args]] = None
    ):
        self._write_log("INFO", message, context)

    fn warn(
        self, message: String, context: Optional[Dict[String, Args]] = None
    ):
        self._write_log("WARNING", message, context)

    fn error(
        self, message: String, context: Optional[Dict[String, Args]] = None
    ):
        self._write_log("ERROR", message, context)

    fn _write_log(
        self,
        level: String,
        message: String,
        context: Optional[Dict[String, Args]] = None,
    ):
        if self.algo_id == 0:
            return

        try:
            var doc = SonicDocument()
            doc.set_object()
            var seq_id = int(seq_snowflake_id())

            # 2024-03-27 14:10:05.034
            # var formatted_time = "2024-04-01 12:00:00.100"

            # print(s)
            doc.add_string("type", "algo_log")
            doc.add_int("algo_id", self.algo_id)
            doc.add_int("seq_id", seq_id)
            doc.add_int("timestamp", time_ns())
            doc.add_string("logger", "trading_engine")
            doc.add_string("level", level)
            doc.add_string("message", message)
            var node = SonicNode(doc)
            node.set_object()
            # node.add_string("type", "BUY")
            if context:
                for e in context.value().items():
                    var value_ref = Reference(e[].value)
                    if value_ref[].isa[String]():
                        var value = value_ref[][String]
                        node.add_string(e[].key, value)
                    elif value_ref[].isa[Int]():
                        var value = value_ref[][Int]
                        node.add_int(e[].key, value)
                    elif value_ref[].isa[Float64]():
                        var value = value_ref[][Float64]
                        node.add_float(e[].key, value)
                    elif value_ref[].isa[Bool]():
                        var value = value_ref[][Bool]
                        node.add_bool(e[].key, value)
            doc.add_node("context", node)

            var doc_str = doc.to_string()
            # logi(doc_str)
            _ = self.q[].push(doc_str)
            # _ = redis.rpush("q_moxtflow_log", doc_str)
        except e:
            print(str(e))

    fn _write_event_log(
        self,
        event_type: String,
        grid_level: Int,
        order_type: String,
        order_price: Fixed,
        order_quantity: Fixed,
        extra_info: Optional[Dict[String, Args]] = None,
    ):
        try:
            var seq_id = int(seq_snowflake_id())

            var doc = SonicDocument()
            doc.set_object()
            doc.add_string("type", "event_log")
            doc.add_int("algo_id", self.algo_id)
            doc.add_int("seq_id", seq_id)
            doc.add_int("timestamp", time_ns())
            doc.add_string("event_type", event_type)
            doc.add_int("grid_level", grid_level)
            doc.add_string("order_type", order_type)
            doc.add_string("order_price", str(order_price))
            doc.add_string("order_quantity", str(order_quantity))
            var extra_info_node = SonicNode(doc)
            extra_info_node.set_object()

            if extra_info:
                for e in extra_info.value().items():
                    var value_ref = Reference(e[].value)
                    if value_ref[].isa[String]():
                        var value = value_ref[][String]
                        extra_info_node.add_string(e[].key, value)
                    elif value_ref[].isa[Int]():
                        var value = value_ref[][Int]
                        extra_info_node.add_int(e[].key, value)
                    elif value_ref[].isa[Float64]():
                        var value = value_ref[][Float64]
                        extra_info_node.add_float(e[].key, value)
                    elif value_ref[].isa[Bool]():
                        var value = value_ref[][Bool]
                        extra_info_node.add_bool(e[].key, value)
            doc.add_node("extra_info", extra_info_node)

            var doc_str = doc.to_string()
            # logi(doc_str)
            _ = self.q[].push(doc_str)
        except e:
            print(str(e))


fn log_itf[name: StringLiteral]() -> UnsafePointer[LogInterface]:
    var ptr = _get_global["_LOG:" + name, _init_log, _destroy_log]()
    return ptr.bitcast[LogInterface]()


fn _init_log(payload: UnsafePointer[NoneType]) -> UnsafePointer[NoneType]:
    var ptr = UnsafePointer[LogInterface].alloc(1)
    ptr.init_pointee_move(LogInterface())
    return ptr.bitcast[NoneType]()


fn _destroy_log(p: UnsafePointer[NoneType]):
    p.free()


@value
struct LogService:
    var redis: UnsafePointer[Redis]
    var q: UnsafePointer[LockfreeQueue]

    fn __init__(inout self):
        self.redis = UnsafePointer[Redis].alloc(1)
        self.q = lockfree_queue_itf[LOG_QUEUE]()

    fn init(inout self, host: String, port: Int, password: String, db: Int):
        logi(
            "init log service host="
            + host
            + " port="
            + str(port)
            + " db="
            + str(db)
        )
        logi("init log service password=" + password)
        self.redis.init_pointee_move(Redis(host, port, password, db, 3000))

    fn perform(self) -> Int:
        var e = self.q[].pop()
        if e:
            var s = e.value()
            # logi("log perform s=" + s)
            _ = self.redis[].rpush("q_moxtflow_log", s)
            return 1
        else:
            return 0

    fn perform_all(self):
        while True:
            var n = self.perform()
            if n == 0:
                return


fn log_service_itf() -> UnsafePointer[LogService]:
    var ptr = _get_global[
        "_LOG_SERVICE", _init_log_service, _destroy_log_service
    ]()
    return ptr.bitcast[LogService]()


fn _init_log_service(
    payload: UnsafePointer[NoneType],
) -> UnsafePointer[NoneType]:
    var ptr = UnsafePointer[LogService].alloc(1)
    # ptr[] = LogService()
    ptr.init_pointee_move(LogService())
    return ptr.bitcast[NoneType]()


fn _destroy_log_service(p: UnsafePointer[NoneType]):
    p.free()
