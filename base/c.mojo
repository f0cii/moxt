from sys.info import sizeof
from sys import external_call
from memory import UnsafePointer

# from sys.intrinsics import external_call, _mlirtype_is_eq
from sys.intrinsics import _mlirtype_is_eq
from memory import memcpy, memset_zero

# Types aliases
alias c_void = UInt8
alias c_char = UInt8

alias c_schar = Int8
alias c_uchar = UInt8
alias c_short = Int16
alias c_ushort = UInt16
alias c_int = Int32
alias c_uint = UInt32
alias c_long = Int64
alias c_ulong = UInt64
alias c_float = Float32
alias c_double = Float64

# Note: `Int` is known to be machine's width
alias c_size_t = Int
alias c_ssize_t = Int

alias ptrdiff_t = Int64
alias intptr_t = Int64
alias uintptr_t = UInt64

alias c_char_pointer = UnsafePointer[c_schar]

alias c_void_pointer = UnsafePointer[c_void]


fn strlen(s: UnsafePointer[c_char]) -> c_size_t:
    """
    :strlen libc POSIX `strlen` function
    Reference: https://man7.org/linux/man-pages/man3/strlen.3p.html
    Fn signature: size_t strlen(const char *s).
    Args:
    s
    Returns:
    .
    """
    return external_call["strlen", c_size_t, UnsafePointer[c_char]](s)


fn strlen(s: UnsafePointer[c_schar]) -> c_size_t:
    """
    :strlen libc POSIX `strlen` function
    Reference: https://man7.org/linux/man-pages/man3/strlen.3p.html
    Fn signature: size_t strlen(const char *s).
    Args:
    s
    Returns:
    .
    """
    return external_call["strlen", c_size_t, UnsafePointer[c_schar]](s)


fn to_char_ptr(s: String) -> UnsafePointer[c_char]:
    """Only ASCII-based strings."""
    var ptr = UnsafePointer[c_char]().alloc(len(s) + 1)
    for i in range(len(s)):
        ptr[i] = ord(s[i])
    ptr[len(s)] = ord("\0")
    return ptr


fn to_schar_ptr(s: String) -> UnsafePointer[c_schar]:
    """Only ASCII-based strings."""
    var ptr = UnsafePointer[c_schar]().alloc(len(s) + 1)
    for i in range(len(s)):
        ptr[i] = ord(s[i])
    ptr[len(s)] = ord("\0")
    return ptr


fn c_str_to_string_raw(s: UnsafePointer[c_char]) -> String:
    return String(s.bitcast[UInt8](), strlen(s))


fn c_str_to_string_raw(s: UnsafePointer[UInt8], n: Int) -> String:
    return String(s, n)


fn c_str_to_string(s: UnsafePointer[c_schar], n: Int) -> String:
    var size = n + 1
    var ptr = UnsafePointer[Int8]().alloc(size)
    memset_zero(ptr.offset(n), 1)
    memcpy(ptr, s, n)
    return String(ptr.bitcast[UInt8](), size)


fn c_str_to_string(s: UnsafePointer[c_char], n: Int) -> String:
    var size = n + 1
    var ptr = UnsafePointer[UInt8]().alloc(size)
    memset_zero(ptr.offset(n), 1)
    memcpy(ptr, s, n)
    return String(ptr, size)


@always_inline
fn str_as_scalar_pointer(s: StringLiteral) -> UnsafePointer[Scalar[DType.int8]]:
    return s.unsafe_cstr_ptr()


@always_inline
fn str_as_scalar_pointer(
    s: String,
) -> UnsafePointer[Scalar[DType.int8]]:
    return s.unsafe_cstr_ptr()
