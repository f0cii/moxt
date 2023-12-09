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

alias c_char_pointer = Pointer[c_schar]
# alias c_char_any_pointer = AnyPointer[c_schar]

alias c_void_pointer = Pointer[c_void]
# alias c_void_any_pointer = AnyPointer[c_void]


alias any_pointer_simd_int8_to_pointer_simd_int8 = rebind[
    Pointer[SIMD[DType.int8, 1]], AnyPointer[SIMD[DType.int8, 1]]
]


fn strlen(s: Pointer[c_char]) -> c_size_t:
    """
    :strlen libc POSIX `strlen` function
    Reference: https://man7.org/linux/man-pages/man3/strlen.3p.html
    Fn signature: size_t strlen(const char *s).
    Args:
    s
    Returns:
    .
    """
    return external_call["strlen", c_size_t, Pointer[c_char]](s)


fn to_char_ptr(s: String) -> Pointer[c_char]:
    """Only ASCII-based strings."""
    let ptr = Pointer[c_char]().alloc(len(s) + 1)
    for i in range(len(s)):
        ptr.store(i, ord(s[i]))
    ptr.store(len(s), ord("\0"))
    return ptr


fn to_schar_ptr(s: String) -> Pointer[c_schar]:
    """Only ASCII-based strings."""
    let ptr = Pointer[c_schar]().alloc(len(s) + 1)
    for i in range(len(s)):
        ptr.store(i, ord(s[i]))
    ptr.store(len(s), ord("\0"))
    return ptr


fn c_str_to_string(s: Pointer[c_char]) -> String:
    return String(s.bitcast[Int8](), strlen(s))


fn c_str_to_string(s: Pointer[c_schar], n: Int) -> String:
    let size = n + 1
    let ptr = Pointer[Int8]().alloc(size)
    memset_zero(ptr.offset(n), 1)
    memcpy(ptr, s, n)
    return String(ptr, size)


fn c_str_to_string(s: Pointer[c_char], n: Int) -> String:
    let size = n + 1
    let ptr = Pointer[UInt8]().alloc(size)
    memset_zero(ptr.offset(n), 1)
    memcpy(ptr, s, n)
    return String(ptr.bitcast[Int8](), size)


fn c_charptr_to_string(s: Pointer[UInt8], n: Int) -> String:
    return String(s.bitcast[Int8](), n)


fn to_string_ref(s: String) -> StringRef:
    let slen = len(s)
    let ptr = Pointer[Int8]().alloc(slen)

    memcpy(ptr, s._buffer.data.value, slen)

    return StringRef(ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, slen)


fn to_string_ref(data: Pointer[Int8], data_len: Int) -> StringRef:
    let ptr = Pointer[Int8]().alloc(data_len)

    memcpy(ptr, data, data_len)

    return StringRef(ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, data_len)


fn to_string_ref(data: Pointer[UInt8], data_len: Int) -> StringRef:
    let ptr = Pointer[Int8]().alloc(data_len)

    memcpy(ptr, data.bitcast[Int8](), data_len)

    return StringRef(ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, data_len)
