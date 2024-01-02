from sys.info import sizeof
from sys.intrinsics import external_call, _mlirtype_is_eq
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


# @always_inline("nodebug")
# fn external_call6[
#     callee: StringLiteral,
#     type: AnyType,
#     T0: AnyType,
#     T1: AnyType,
#     T2: AnyType,
#     T3: AnyType,
#     T4: AnyType,
#     T5: AnyType,
# ](arg0: T0, arg1: T1, arg2: T2, arg3: T3, arg4: T4, arg5: T5) -> type:
#     """Call an external function.

#     Parameters:
#       callee: The name of the external function.
#       type: The return type.
#       T0: The first argument type.
#       T1: The second argument type.
#       T2: The third argument type.
#       T3: The fourth argument type.
#       T4: The fifth argument type.
#       T5: The fifth argument type.

#     Args:
#       arg0: The first argument.
#       arg1: The second argument.
#       arg2: The third argument.
#       arg3: The fourth argument.
#       arg4: The fifth argument.
#       arg5: The fifth argument.

#     Returns:
#       The external call result.
#     """

#     @parameter
#     if _mlirtype_is_eq[type, NoneType]():
#         __mlir_op.`pop.external_call`[func : callee.value, _type:None](
#             arg0, arg1, arg2, arg3, arg4, arg5
#         )
#         return rebind[type](None)
#     else:
#         return __mlir_op.`pop.external_call`[func : callee.value, _type:type](
#             arg0, arg1, arg2, arg3, arg4, arg5
#         )


# @always_inline("nodebug")
# fn external_call7[
#     callee: StringLiteral,
#     type: AnyType,
#     T0: AnyType,
#     T1: AnyType,
#     T2: AnyType,
#     T3: AnyType,
#     T4: AnyType,
#     T5: AnyType,
#     T6: AnyType,
# ](arg0: T0, arg1: T1, arg2: T2, arg3: T3, arg4: T4, arg5: T5, arg6: T6) -> type:
#     """Call an external function.

#     Parameters:
#       callee: The name of the external function.
#       type: The return type.
#       T0: The first argument type.
#       T1: The second argument type.
#       T2: The third argument type.
#       T3: The fourth argument type.
#       T4: The fifth argument type.
#       T5: The sixth argument type.
#       T6: The seventh argument type.

#     Args:
#       arg0: The first argument.
#       arg1: The second argument.
#       arg2: The third argument.
#       arg3: The fourth argument.
#       arg4: The fifth argument.
#       arg5: The sixth argument.
#       arg6: The seventh argument.

#     Returns:
#       The external call result.
#     """

#     @parameter
#     if _mlirtype_is_eq[type, NoneType]():
#         __mlir_op.`pop.external_call`[func : callee.value, _type:None](
#             arg0, arg1, arg2, arg3, arg4, arg5, arg6
#         )
#         return rebind[type](None)
#     else:
#         return __mlir_op.`pop.external_call`[func : callee.value, _type:type](
#             arg0, arg1, arg2, arg3, arg4, arg5, arg6
#         )


# @always_inline("nodebug")
# fn external_call8[
#     callee: StringLiteral,
#     type: AnyType,
#     T0: AnyType,
#     T1: AnyType,
#     T2: AnyType,
#     T3: AnyType,
#     T4: AnyType,
#     T5: AnyType,
#     T6: AnyType,
#     T7: AnyType,
# ](
#     arg0: T0, arg1: T1, arg2: T2, arg3: T3, arg4: T4, arg5: T5, arg6: T6, arg7: T7
# ) -> type:
#     """Call an external function.

#     Parameters:
#       callee: The name of the external function.
#       type: The return type.
#       T0: The first argument type.
#       T1: The second argument type.
#       T2: The third argument type.
#       T3: The fourth argument type.
#       T4: The fifth argument type.
#       T5: The sixth argument type.
#       T6: The seventh argument type.
#       T7: The seventh argument type.

#     Args:
#       arg0: The first argument.
#       arg1: The second argument.
#       arg2: The third argument.
#       arg3: The fourth argument.
#       arg4: The fifth argument.
#       arg5: The sixth argument.
#       arg6: The seventh argument.
#       arg7: The seventh argument.

#     Returns:
#       The external call result.
#     """

#     @parameter
#     if _mlirtype_is_eq[type, NoneType]():
#         __mlir_op.`pop.external_call`[func : callee.value, _type:None](
#             arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7
#         )
#         return rebind[type](None)
#     else:
#         return __mlir_op.`pop.external_call`[func : callee.value, _type:type](
#             arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7
#         )


# @always_inline("nodebug")
# fn external_call9[
#     callee: StringLiteral,
#     type: AnyRegType,
#     T0: AnyRegType,
#     T1: AnyRegType,
#     T2: AnyRegType,
#     T3: AnyRegType,
#     T4: AnyRegType,
#     T5: AnyRegType,
#     T6: AnyRegType,
#     T7: AnyRegType,
#     T8: AnyRegType,
# ](
#     arg0: T0,
#     arg1: T1,
#     arg2: T2,
#     arg3: T3,
#     arg4: T4,
#     arg5: T5,
#     arg6: T6,
#     arg7: T7,
#     arg8: T8,
# ) -> type:
#     """Call an external function.

#     Parameters:
#       callee: The name of the external function.
#       type: The return type.
#       T0: The first argument type.
#       T1: The second argument type.
#       T2: The third argument type.
#       T3: The fourth argument type.
#       T4: The fifth argument type.
#       T5: The sixth argument type.
#       T6: The seventh argument type.
#       T7: The seventh argument type.
#       T8: The seventh argument type.

#     Args:
#       arg0: The first argument.
#       arg1: The second argument.
#       arg2: The third argument.
#       arg3: The fourth argument.
#       arg4: The fifth argument.
#       arg5: The sixth argument.
#       arg6: The seventh argument.
#       arg7: The seventh argument.
#       arg8: The seventh argument.

#     Returns:
#       The external call result.
#     """

#     @parameter
#     if _mlirtype_is_eq[type, NoneType]():
#         __mlir_op.`pop.external_call`[func : callee.value, _type:None](
#             arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8
#         )
#         return rebind[type](None)
#     else:
#         return __mlir_op.`pop.external_call`[func : callee.value, _type:type](
#             arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8
#         )


fn exit(status: Int32) -> UInt8:
    return external_call["exit", UInt8, Int32](status)


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


fn c_str_to_string_raw(s: Pointer[c_char]) -> String:
    return String(s.bitcast[Int8](), strlen(s))


fn c_str_to_string_raw(s: Pointer[UInt8], n: Int) -> String:
    return String(s.bitcast[Int8](), n)


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


fn to_string_ref(s: String) -> StringRef:
    let slen = len(s)
    let ptr = Pointer[Int8]().alloc(slen)
    memcpy(ptr, s._buffer.data.value, slen)
    let s_ref = StringRef(ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, slen)
    return s_ref


fn to_string_ref(data: Pointer[Int8], data_len: Int) -> StringRef:
    let ptr = Pointer[Int8]().alloc(data_len)
    memcpy(ptr, data, data_len)
    return StringRef(ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, data_len)


fn to_string_ref(data: Pointer[UInt8], data_len: Int) -> StringRef:
    let ptr = Pointer[Int8]().alloc(data_len)
    memcpy(ptr, data.bitcast[Int8](), data_len)
    return StringRef(ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, data_len)
