from memory import memcpy


# @value
# @register_passable
# struct Str(Stringable):
#     """
#     A string that is dodgy because it is not null-terminated.
#     https://github.com/igorgue/firedis/blob/main/dodgy.mojo
#     """

#     var data: Pointer[Int8]
#     var size: Int

#     fn __init__(value: StringLiteral) -> Str:
#         var l = len(value)
#         var s = String(value)
#         var p = Pointer[Int8].alloc(l)

#         for i in range(l):
#             p.store(i, s._buffer[i])

#         return Str(p, l)

#     fn __init__(value: String) -> Str:
#         var l = len(value)
#         var p = Pointer[Int8].alloc(l)

#         for i in range(l):
#             p.store(i, value._buffer[i])

#         return Str(p, l)

#     fn __init__(value: StringRef) -> Str:
#         var l = len(value)
#         var s = String(value)
#         var p = Pointer[Int8].alloc(l)

#         for i in range(l):
#             p.store(i, s._buffer[i])

#         return Str(p, l)

#     @always_inline("nodebug")
#     fn __del__(owned self: Self):
#         self.data.free()

#     fn __eq__(self, other: Self) -> Bool:
#         if self.size != other.size:
#             return False

#         for i in range(self.size):
#             if self.data.load(i) != other.data.load(i):
#                 return False

#         return True

#     fn __ne__(self, other: Self) -> Bool:
#         return not self.__eq__(other)

#     fn to_string(self) -> String:
#         var ptr = Pointer[Int8]().alloc(self.size)
#         memcpy(ptr, self.data, self.size)
#         return String(ptr, self.size + 1)

#     fn __str__(self) -> String:
#         return self.to_string()
