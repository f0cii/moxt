from sys.ffi import _get_global
from memory import unsafe
from collections.optional import Optional
from .c import *
from .mo import *
from .moutil import *


alias timer_entry_t = fn () raises -> UInt64
alias timed_closure_entry_t = fn (Int) raises -> UInt64


fn seq_atomic_bool_new(
    b: Bool,
) -> c_void_pointer:
    return external_call[
        "seq_atomic_bool_new",
        c_void_pointer,
        Bool,
    ](b)


fn seq_atomic_bool_free(
    p: c_void_pointer,
) -> None:
    external_call["seq_atomic_bool_free", NoneType, c_void_pointer](p)


fn seq_atomic_bool_load(
    p: c_void_pointer,
) -> Bool:
    return external_call["seq_atomic_bool_load", Bool, c_void_pointer](p)


fn seq_atomic_bool_store(
    p: c_void_pointer,
    v: Bool,
) -> None:
    external_call["seq_atomic_bool_store", NoneType, c_void_pointer, Bool](p, v)


fn seq_atomic_int64_new(
    i: Int64,
) -> c_void_pointer:
    return external_call[
        "seq_atomic_int64_new",
        c_void_pointer,
        Int64,
    ](i)


fn seq_atomic_int64_free(
    p: c_void_pointer,
) -> None:
    external_call["seq_atomic_int64_free", NoneType, c_void_pointer](p)


fn seq_atomic_int64_load(
    p: c_void_pointer,
) -> Int64:
    return external_call["seq_atomic_int64_load", Int64, c_void_pointer](p)


fn seq_atomic_int64_store(
    p: c_void_pointer,
    i: Int64,
) -> None:
    external_call["seq_atomic_int64_store", NoneType, c_void_pointer, Int64](
        p, i
    )


# SEQ_FUNC TimedClosureExecutor *
# seq_photon_timed_closure_executor_new(uint64_t default_timeout,
#                                       timed_closure_entry entry,
#                                       int64_t closurePtr, bool repeating);
fn seq_photon_timed_closure_executor_new(
    default_timeout: UInt64,
    entry: timed_closure_entry_t,
    closure_ptr: Int64,
    repeating: Bool,
) -> c_void_pointer:
    return external_call[
        "seq_photon_timed_closure_executor_new",
        c_void_pointer,
        UInt64,
        timed_closure_entry_t,
        Int64,
        Bool,
    ](default_timeout, entry, closure_ptr, repeating)


# SEQ_FUNC void
# seq_photon_timed_closure_executor_free(TimedClosureExecutor *executor);
fn seq_photon_timed_closure_executor_free(executor: c_void_pointer) -> None:
    external_call[
        "seq_photon_timed_closure_executor_free", NoneType, c_void_pointer
    ](executor)


# SEQ_FUNC photon::Timer *
# seq_photon_timed_closure_executor_get_timer(TimedClosureExecutor *executor);
fn seq_photon_timed_closure_executor_get_timer(
    executor: c_void_pointer,
) -> c_void_pointer:
    return external_call[
        "seq_photon_timed_closure_executor_get_timer",
        c_void_pointer,
        c_void_pointer,
    ](executor)


# SEQ_FUNC photon::Timer *seq_photon_timer_new(uint64_t default_timeout,
#                                              timer_entry entry, bool repeating);
fn seq_photon_timer_new(
    default_timeout: UInt64, entry: timer_entry_t, repeating: Bool
) -> c_void_pointer:
    return external_call[
        "seq_photon_timer_new", c_void_pointer, UInt64, timer_entry_t, Bool
    ](default_timeout, entry, repeating)


# SEQ_FUNC int seq_photon_timer_reset(photon::Timer *timer, uint64_t new_timeout);
fn seq_photon_timer_reset(timer: c_void_pointer, new_timeout: UInt64) -> c_int:
    return external_call[
        "seq_photon_timer_reset", c_int, c_void_pointer, UInt64
    ](timer, new_timeout)


# SEQ_FUNC int seq_photon_timer_cancel(photon::Timer *timer);
fn seq_photon_timer_cancel(timer: c_void_pointer) -> c_int:
    return external_call["seq_photon_timer_cancel", c_int, c_void_pointer](
        timer
    )


# SEQ_FUNC int seq_photon_timer_stop(photon::Timer *timer);
fn seq_photon_timer_stop(timer: c_void_pointer) -> c_int:
    return external_call["seq_photon_timer_stop", c_int, c_void_pointer](timer)


# SEQ_FUNC photon::mutex *seq_photon_mutex_new() { return new photon::mutex(); }
fn seq_photon_mutex_new() -> c_void_pointer:
    return external_call["seq_photon_mutex_new", c_void_pointer]()


# SEQ_FUNC void seq_photon_mutex_free(photon::mutex *mu) { delete mu; }
fn seq_photon_mutex_free(mu: c_void_pointer) -> None:
    external_call["seq_photon_mutex_free", NoneType, c_void_pointer](mu)


# SEQ_FUNC int seq_photon_mutex_lock(photon::mutex *mu, uint64_t timeout) {
#     return mu->lock(timeout);
# }
fn seq_photon_mutex_lock(mu: c_void_pointer, timeout: UInt64) -> c_int:
    return external_call[
        "seq_photon_mutex_lock", c_int, c_void_pointer, UInt64
    ](mu, timeout)


# SEQ_FUNC int seq_photon_mutex_try_lock(photon::mutex *mu) {
#     return mu->try_lock();
# }
fn seq_photon_mutex_try_lock(mu: c_void_pointer) -> c_int:
    return external_call["seq_photon_mutex_try_lock", c_int, c_void_pointer](mu)


# SEQ_FUNC void seq_photon_mutex_unlock(photon::mutex *mu) { mu->unlock(); }
fn seq_photon_mutex_unlock(mu: c_void_pointer) -> None:
    external_call["seq_photon_mutex_unlock", NoneType, c_void_pointer](mu)


# SEQ_FUNC photon::spinlock *seq_photon_spinlock_new() {
#     return new photon::spinlock();
# }
fn seq_photon_spinlock_new() -> c_void_pointer:
    return external_call["seq_photon_spinlock_new", c_void_pointer]()


# SEQ_FUNC void seq_photon_spinlock_free(photon::spinlock *lock) { delete lock; }
fn seq_photon_spinlock_free(lock: c_void_pointer) -> None:
    external_call["seq_photon_spinlock_free", NoneType, c_void_pointer](lock)


# SEQ_FUNC int seq_photon_spinlock_lock(photon::spinlock *lock) {
#     return lock->lock();
# }
fn seq_photon_spinlock_lock(lock: c_void_pointer) -> c_int:
    return external_call["seq_photon_spinlock_lock", c_int, c_void_pointer](
        lock
    )


# SEQ_FUNC int seq_photon_spinlock_try_lock(photon::spinlock *lock) {
#     return lock->try_lock();
# }
fn seq_photon_spinlock_try_lock(lock: c_void_pointer) -> c_int:
    return external_call["seq_photon_spinlock_try_lock", c_int, c_void_pointer](
        lock
    )


# SEQ_FUNC void seq_photon_spinlock_unlock(photon::spinlock *lock) {
#     lock->unlock();
# }
fn seq_photon_spinlock_unlock(lock: c_void_pointer) -> None:
    external_call["seq_photon_spinlock_unlock", NoneType, c_void_pointer](lock)


# SEQ_FUNC photon::condition_variable *seq_photon_condition_variable_new() {
#     return new photon::condition_variable();
# }
fn seq_photon_condition_variable_new() -> c_void_pointer:
    return external_call["seq_photon_condition_variable_new", c_void_pointer]()


# SEQ_FUNC void
# seq_photon_condition_variable_free(photon::condition_variable *cond) {
#     delete cond;
# }
fn seq_photon_condition_variable_free(cond: c_void_pointer) -> None:
    external_call[
        "seq_photon_condition_variable_free", NoneType, c_void_pointer
    ](cond)


# SEQ_FUNC int
# seq_photon_condition_variable_wait_no_lock(photon::condition_variable *cond,
#                                            uint64_t timeout) {
#     return cond->wait_no_lock(timeout);
# }
fn seq_photon_condition_variable_wait_no_lock(
    cond: c_void_pointer, timeout: UInt64
) -> c_int:
    return external_call[
        "seq_photon_condition_variable_wait_no_lock",
        c_int,
        c_void_pointer,
        UInt64,
    ](cond, timeout)


# SEQ_FUNC photon::thread *
# seq_photon_condition_variable_notify_one(photon::condition_variable *cond) {
#     return cond->notify_one();
# }
fn seq_photon_condition_variable_notify_one(
    cond: c_void_pointer,
) -> c_void_pointer:
    return external_call[
        "seq_photon_condition_variable_notify_one",
        c_void_pointer,
        c_void_pointer,
    ](cond)


# SEQ_FUNC int
# seq_photon_condition_variable_notify_all(photon::condition_variable *cond) {
#     return cond->notify_all();
# }
fn seq_photon_condition_variable_notify_all(cond: c_void_pointer) -> c_int:
    return external_call[
        "seq_photon_condition_variable_notify_all", c_int, c_void_pointer
    ](cond)


# SEQ_FUNC photon::semaphore *seq_photon_semaphore_new() {
#     return new photon::semaphore();
# }
fn seq_photon_semaphore_new() -> c_void_pointer:
    return external_call["seq_photon_semaphore_new", c_void_pointer]()


# SEQ_FUNC void seq_photon_semaphore_free(photon::semaphore *sem) { delete sem; }
fn seq_photon_semaphore_free(sem: c_void_pointer) -> None:
    external_call["seq_photon_semaphore_free", NoneType, c_void_pointer](sem)


# SEQ_FUNC int seq_photon_semaphore_wait(photon::semaphore *sem, uint64_t count,
#                                        uint64_t timeout) {
#     return sem->wait(count, timeout);
# }
fn seq_photon_semaphore_wait(
    sem: c_void_pointer, count: UInt64, timeout: UInt64
) -> c_int:
    return external_call[
        "seq_photon_semaphore_wait", c_int, c_void_pointer, UInt64, UInt64
    ](sem, count, timeout)


# SEQ_FUNC int seq_photon_semaphore_signal(photon::semaphore *sem,
#                                          uint64_t count) {
#     return sem->signal(count);
# }
fn seq_photon_semaphore_signal(sem: c_void_pointer, count: UInt64) -> c_int:
    return external_call[
        "seq_photon_semaphore_signal", c_int, c_void_pointer, UInt64
    ](sem, count)


# SEQ_FUNC uint64_t seq_photon_semaphore_count(photon::semaphore *sem) {
#     return sem->count();
# }
fn seq_photon_semaphore_count(sem: c_void_pointer) -> UInt64:
    return external_call["seq_photon_semaphore_count", UInt64, c_void_pointer](
        sem
    )


# SEQ_FUNC photon::rwlock *seq_photon_rwlock_new() {
#     return new photon::rwlock();
# }
fn seq_photon_rwlock_new() -> c_void_pointer:
    return external_call["seq_photon_rwlock_new", c_void_pointer]()


# SEQ_FUNC void seq_photon_rwlock_free(photon::rwlock *rwlock) { delete rwlock; }
fn seq_photon_rwlock_free(rwlock: c_void_pointer) -> None:
    external_call["seq_photon_rwlock_free", NoneType, c_void_pointer](rwlock)


# // mode: RLOCK / WLOCK
# // constexpr int RLOCK=0x1000;
# // constexpr int WLOCK=0x2000;
# SEQ_FUNC int seq_photon_rwlock_lock(photon::rwlock *rwlock, int mode,
#                                     uint64_t timeout) {
#     return rwlock->lock(mode, timeout);
# }
alias RLOCK: c_int = 0x1000
alias WLOCK: c_int = 0x2000


fn seq_photon_rwlock_lock(
    rwlock: c_void_pointer, mode: c_int, timeout: UInt64
) -> c_int:
    return external_call[
        "seq_photon_rwlock_lock", c_int, c_void_pointer, c_int, UInt64
    ](rwlock, mode, timeout)


# SEQ_FUNC int seq_photon_rwlock_unlock(photon::rwlock *rwlock) {
#     return rwlock->unlock();
# }
fn seq_photon_rwlock_unlock(rwlock: c_void_pointer) -> c_int:
    return external_call["seq_photon_rwlock_unlock", c_int, c_void_pointer](
        rwlock
    )


# Create queue
fn seq_lockfree_queue_new() -> c_void_pointer:
    return external_call["seq_lockfree_queue_new", c_void_pointer]()


# Destroy queue
fn seq_lockfree_queue_free(q: c_void_pointer) -> None:
    external_call["seq_lockfree_queue_free", NoneType, c_void_pointer](q)


# Enqueue operation
fn seq_lockfree_queue_push_data(
    q: c_void_pointer, data: UnsafePointer[UInt8], data_len: c_size_t
) -> Bool:
    return external_call[
        "seq_lockfree_queue_push_data",
        Bool,
        c_void_pointer,
        UnsafePointer[UInt8],
        c_size_t,
    ](q, data, data_len)


# Dequeue operation
fn seq_lockfree_queue_pop_data(
    q: c_void_pointer,
    output: UnsafePointer[UInt8],
    len: UnsafePointer[c_size_t],
) -> Bool:
    return external_call[
        "seq_lockfree_queue_pop_data",
        Bool,
        c_void_pointer,
        UnsafePointer[UInt8],
        UnsafePointer[c_size_t],
    ](q, output, len)


# Get current thread id
fn seq_thread_id() -> Int64:
    return external_call["seq_thread_id", Int64]()


struct AtomicBool:
    var p: c_void_pointer

    fn __init__(inout self, b: Bool = False):
        self.p = seq_atomic_bool_new(b)

    fn __del__(owned self):
        seq_atomic_bool_free(self.p)

    fn load(self) -> Bool:
        return seq_atomic_bool_load(self.p)

    fn store(self, b: Bool):
        seq_atomic_bool_store(self.p, b)


struct AtomicInt64:
    var p: c_void_pointer

    fn __init__(inout self, i: Int64 = 0):
        self.p = seq_atomic_int64_new(i)

    fn __del__(owned self):
        seq_atomic_int64_free(self.p)

    fn load(self) -> Int64:
        return seq_atomic_int64_load(self.p)

    fn store(self, i: Int64):
        seq_atomic_int64_store(self.p, i)


@value
struct RWLock:
    var ptr: c_void_pointer

    fn __init__(inout self):
        self.ptr = seq_photon_rwlock_new()

    fn __init__(inout self, ptr: c_void_pointer):
        self.ptr = ptr

    fn __init__(inout self, ptr: Int):
        self.ptr = seq_int_to_voidptr(ptr)

    fn ptr_to_int(self) -> Int:
        return seq_voidptr_to_int(self.ptr)

    fn lock(self):
        _ = seq_photon_rwlock_lock(self.ptr, WLOCK, -1)

    fn unlock(self):
        _ = seq_photon_rwlock_unlock(self.ptr)

    fn free(self):
        seq_photon_rwlock_free(self.ptr)


alias sleep = seq_photon_thread_sleep_s
alias sleep_ms = seq_photon_thread_sleep_ms
alias sleep_us = seq_photon_thread_sleep_us

alias on_timer_callback = fn () escaping -> UInt64
alias on_timer = fn () -> UInt64


fn on_tc_timer(ptr: Int) raises -> UInt64:
    # print("on_tc_timer ptr=" + str(ptr))
    # var _timer_callback = unsafe.bitcast[on_timer_callback](ptr).load()
    # var ret = _timer_callback()
    # print("on_tc_timer done")
    # return ret
    return 0


@value
struct TimedClosureExecutor:
    var _ptr: UnsafePointer[c_void_pointer]

    fn __init__(inout self):
        self._ptr = UnsafePointer[c_void_pointer].alloc(1)

    fn start(
        self,
        default_timeout: UInt64,
        callback: UnsafePointer[on_timer_callback],
        repeating: Bool = True,
    ):
        var callback_ptr = int(callback)
        var ptr = seq_photon_timed_closure_executor_new(
            default_timeout, on_tc_timer, callback_ptr, repeating
        )
        self._ptr[0] = ptr

    fn __del__(owned self):
        logi("TimedClosureExecutor.__del__")
        self.free()

    fn free(owned self):
        # logi("TimedClosureExecutor.free")
        var ptr = self._ptr[0]
        seq_photon_timed_closure_executor_free(ptr)
        self._ptr[0] = c_void_pointer()


@value
struct Semaphore:
    var ptr: c_void_pointer

    fn __init__(inout self):
        self.ptr = seq_photon_semaphore_new()

    fn __init__(inout self, ptr: c_void_pointer):
        self.ptr = ptr

    fn __init__(inout self, ptr: Int):
        self.ptr = seq_int_to_voidptr(ptr)

    fn ptr_to_int(self) -> Int:
        return seq_voidptr_to_int(self.ptr)

    fn __del__(owned self):
        pass

    fn wait(self, count: UInt64, timeout: UInt64 = -1) -> Int:
        return int(seq_photon_semaphore_wait(self.ptr, count, timeout))

    fn signal(self, count: UInt64) -> Int:
        return int(seq_photon_semaphore_signal(self.ptr, count))

    fn count(self) -> UInt64:
        return seq_photon_semaphore_count(self.ptr)

    fn free(self):
        seq_photon_semaphore_free(self.ptr)


# @register_passable
@value
struct ConditionVariable:
    var ptr: c_void_pointer

    fn __init__(inout self):
        logd("ConditionVariable.__init__")
        self.ptr = seq_photon_condition_variable_new()

    fn __init__(inout self, ptr: c_void_pointer):
        logd("ConditionVariable.__init__")
        self.ptr = ptr

    fn __init__(inout self, ptr: Int):
        logd("ConditionVariable.__init__")
        self.ptr = seq_int_to_voidptr(ptr)

    fn ptr_to_int(self) -> Int:
        return seq_voidptr_to_int(self.ptr)

    fn __del__(owned self):
        pass

    fn wait_no_lock(self, timeout: UInt64 = -1) -> Int:
        logd("ConditionVariable.wait_no_lock")
        var ret = seq_photon_condition_variable_wait_no_lock(self.ptr, timeout)
        return int(ret)

    fn notify_one(self):
        logd("ConditionVariable.notify_one")
        _ = seq_photon_condition_variable_notify_one(self.ptr)

    fn notify_all(self):
        logd("ConditionVariable.notify_all")
        _ = seq_photon_condition_variable_notify_all(self.ptr)

    fn free(self):
        seq_photon_condition_variable_free(self.ptr)


@value
struct LockfreeQueue:
    var ptr: c_void_pointer

    fn __init__(inout self):
        self.ptr = seq_lockfree_queue_new()

    fn __moveinit__(inout self, owned existing: Self):
        self.ptr = existing.ptr
        existing.ptr = c_void_pointer()

    fn free(owned self):
        if self.ptr != c_void_pointer():
            seq_lockfree_queue_free(self.ptr)

    fn push(self, data: UnsafePointer[UInt8], data_len: Int) -> Bool:
        return seq_lockfree_queue_push_data(self.ptr, data, data_len)

    fn pop(
        self, data: UnsafePointer[UInt8], data_len: UnsafePointer[Int]
    ) -> Bool:
        return seq_lockfree_queue_pop_data(self.ptr, data, data_len)

    fn push(self, s: String) -> Bool:
        var c_ptr = s._buffer.data
        var ok = self.push(c_ptr, len(s))
        s._strref_keepalive()
        return ok

    fn pop(self) -> Optional[String]:
        var buff = UnsafePointer[UInt8].alloc(1024 * 100)
        var n: Int = 0
        var ok = self.pop(buff, UnsafePointer[Int].address_of(n))
        if not ok:
            buff.free()
            return None
        else:
            var s = c_str_to_string(buff, n)
            buff.free()
            return s


fn lockfree_queue_itf[name: StringLiteral]() -> UnsafePointer[LockfreeQueue]:
    var ptr = _get_global[
        "LockfreeQueue:" + name, _init_lockfree_queue, _destroy_lockfree_queue
    ]()
    # return UnsafePointer[LockfreeQueue](address=int(ptr))
    return ptr.bitcast[LockfreeQueue]()


fn _init_lockfree_queue(
    payload: UnsafePointer[NoneType],
) -> UnsafePointer[NoneType]:
    var ptr = UnsafePointer[LockfreeQueue].alloc(1)
    ptr.init_pointee_move(LockfreeQueue())
    return ptr.bitcast[NoneType]()


fn _destroy_lockfree_queue(p: UnsafePointer[NoneType]):
    p.free()
