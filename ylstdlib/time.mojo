from sys import external_call
from sys.info import os_is_linux, os_is_windows

# Enums used in time.h 's glibc
alias _CLOCK_REALTIME = 0
alias _CLOCK_MONOTONIC = 1 if os_is_linux() else 6
alias _CLOCK_PROCESS_CPUTIME_ID = 2 if os_is_linux() else 12
alias _CLOCK_THREAD_CPUTIME_ID = 3 if os_is_linux() else 16
alias _CLOCK_MONOTONIC_RAW = 4

# Constants
alias _NSEC_PER_USEC = 1000
alias _NSEC_PER_MSEC = 1000000
alias _USEC_PER_MSEC = 1000
alias _MSEC_PER_SEC = 1000
alias _NSEC_PER_SEC = _NSEC_PER_USEC * _USEC_PER_MSEC * _MSEC_PER_SEC

# LARGE_INTEGER in Windows represent a signed 64 bit integer. Internally it
# is implemented as a union of of one 64 bit integer or two 32 bit integers
# for 64/32 bit compilers.
# https://learn.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-large_integer-r1
alias _WINDOWS_LARGE_INTEGER = Int64


@value
@register_passable("trivial")
struct _CTimeSpec(Stringable):
    var tv_sec: Int  # Seconds
    var tv_subsec: Int  # subsecond (nanoseconds on linux and usec on mac)

    fn __init__(inout self):
        self.tv_sec = 0
        self.tv_subsec = 0

    fn as_nanoseconds(self) -> Int:
        @parameter
        if os_is_linux():
            return self.tv_sec * _NSEC_PER_SEC + self.tv_subsec
        else:
            return self.tv_sec * _NSEC_PER_SEC + self.tv_subsec * _NSEC_PER_USEC

    fn __str__(self) -> String:
        return str(self.as_nanoseconds()) + "ns"


@always_inline
fn _clock_gettime(clockid: Int) -> _CTimeSpec:
    """Low-level call to the clock_gettime libc function"""
    var ts = _CTimeSpec()

    # Call libc's clock_gettime.
    _ = external_call["clock_gettime", Int32](Int32(clockid), UnsafePointer.address_of(ts))

    return ts


@always_inline
fn _gettime_as_nsec_unix(clockid: Int) -> Int:
    if os_is_linux():
        var ts = _clock_gettime(clockid)
        return ts.as_nanoseconds()
    else:
        return int(external_call["clock_gettime_nsec_np", Int64](Int32(clockid)))


@always_inline
fn time_ns() -> Int:
    return _gettime_as_nsec_unix(_CLOCK_REALTIME)
