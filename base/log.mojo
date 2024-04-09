from sys.ffi import _get_global
from collections.optional import Optional
from utils.variant import Variant
from base.mo import seq_snowflake_id
from base.sonic import SonicDocument, SonicNode
from base.redis import Redis
from base.thread import LockfreeQueue, lockfree_queue_itf
from base.c import *
from base.mo import *
from morrow import Morrow


alias Args = Variant[String, Int, Float64, Bool]
alias LOG_QUEUE = "_LOG_QUEUE"


fn debug(message: String, context: Optional[Dict[String, Args]] = None):
    log_itf["MAIN"]()[].debug(message, context)


fn info(message: String, context: Optional[Dict[String, Args]] = None):
    log_itf["MAIN"]()[].info(message, context)


fn warn(message: String, context: Optional[Dict[String, Args]] = None):
    log_itf["MAIN"]()[].warn(message, context)


fn error(message: String, context: Optional[Dict[String, Args]] = None):
    log_itf["MAIN"]()[].error(message, context)


@value
struct LogInterface:
    var algo_id: Int
    var q: Pointer[LockfreeQueue]

    fn __init__(inout self):
        self.algo_id = 0
        self.q = lockfree_queue_itf[LOG_QUEUE]()

    fn set_alog_id(inout self, algo_id: Int):
        self.algo_id = algo_id

    fn debug(self, message: String, context: Optional[Dict[String, Args]] = None):
        self._write_log("DEBUG", message, context)

    fn info(self, message: String, context: Optional[Dict[String, Args]] = None):
        self._write_log("INFO", message, context)

    fn warn(self, message: String, context: Optional[Dict[String, Args]] = None):
        self._write_log("WARNING", message, context)

    fn error(self, message: String, context: Optional[Dict[String, Args]] = None):
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
            var now = Morrow.now()
            var formatted_time = now.format("YYYY-MM-DD HH:mm:ss.SSSSSSSSS")
            # print(s)
            doc.add_int("algo_id", self.algo_id)
            doc.add_int("seq_id", seq_id)
            doc.add_string("timestamp", formatted_time)
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
                        var value = value_ref[].get[String]()[]
                        node.add_string(e[].key, value)
                    elif value_ref[].isa[Int]():
                        var value = value_ref[].get[Int]()[]
                        node.add_int(e[].key, value)
                    elif value_ref[].isa[Float64]():
                        var value = value_ref[].get[Float64]()[]
                        node.add_float(e[].key, value)
                    elif value_ref[].isa[Bool]():
                        var value = value_ref[].get[Bool]()[]
                        node.add_bool(e[].key, value)
            doc.add_node("context", node)

            var doc_str = doc.to_string()
            # print(doc_str)
            _ = self.q[].push(doc_str)
            # _ = redis.rpush("q_moxtflow_log", doc_str)
        except e:
            print(str(e))


fn log_itf[name: StringLiteral]() -> Pointer[LogInterface]:
    var ptr = _get_global["_LOG:" + name, _init_log, _destroy_log]()
    return ptr.bitcast[LogInterface]()


fn _init_log(payload: Pointer[NoneType]) -> Pointer[NoneType]:
    var ptr = Pointer[LogInterface].alloc(1)
    ptr[] = LogInterface()
    return ptr.bitcast[NoneType]()


fn _destroy_log(p: Pointer[NoneType]):
    p.free()


struct LogService:
    var redis: AnyPointer[Redis]
    var q: Pointer[LockfreeQueue]

    fn __init__(inout self):
        self.redis = AnyPointer[Redis].alloc(1)
        self.q = lockfree_queue_itf[LOG_QUEUE]()
    
    fn init(inout self, host: String, port: Int, password: String, db: Int):
        logi("init log service host=" + host + " port=" + str(port) + " db=" + str(db))
        # logi("init log service password=" + password)
        self.redis.emplace_value(Redis(host, port, password, db, 3000))

    fn perform(self) -> Int:
        var e = self.q[].pop()
        if e:
            var s = e.value()
            logi("log perform s=" + s)
            _ = self.redis[].rpush("q_moxtflow_log", s)
            return 1
        else:
            return 0

    fn perform_all(self):
        while True:
            var n = self.perform()
            if n == 0:
                return


fn log_service_itf() -> Pointer[LogService]:
    var ptr = _get_global["_LOG_SERVICE", _init_log_service, _destroy_log_service]()
    return ptr.bitcast[LogService]()


fn _init_log_service(payload: Pointer[NoneType]) -> Pointer[NoneType]:
    var ptr = Pointer[LogService].alloc(1)
    ptr[] = LogService()
    return ptr.bitcast[NoneType]()


fn _destroy_log_service(p: Pointer[NoneType]):
    p.free()