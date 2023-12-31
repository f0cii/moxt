from .list_iterator import ListIterator
from memory import memcpy


# @value
# @register_passable("trivial")
# struct Str2:
#     var data: DynamicVector[Int8]

#     fn __init__(value: StringLiteral) -> Str2:
#         let l = len(value)
#         let s = String(value)
#         let p = Pointer[Int8].alloc(l)

#         for i in range(l):
#             p.store(i, s._buffer[i])

#         return Str(p, l)


@value
@register_passable
struct Str(Stringable):
    """
    A string that is dodgy because it is not null-terminated.
    https://github.com/igorgue/firedis/blob/main/dodgy.mojo
    """

    var data: Pointer[Int8]
    var size: Int

    fn __init__(value: StringLiteral) -> Str:
        let l = len(value)
        let s = String(value)
        let p = Pointer[Int8].alloc(l)

        for i in range(l):
            p.store(i, s._buffer[i])

        return Str(p, l)

    fn __init__(value: String) -> Str:
        let l = len(value)
        let p = Pointer[Int8].alloc(l)

        for i in range(l):
            p.store(i, value._buffer[i])

        return Str(p, l)

    fn __init__(value: StringRef) -> Str:
        let l = len(value)
        let s = String(value)
        let p = Pointer[Int8].alloc(l)

        for i in range(l):
            p.store(i, s._buffer[i])

        return Str(p, l)

    @always_inline("nodebug")
    fn __del__(owned self: Self):
        self.data.free()

    fn __eq__(self, other: Self) -> Bool:
        if self.size != other.size:
            return False

        for i in range(self.size):
            if self.data.load(i) != other.data.load(i):
                return False

        return True

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn __iter__(self) -> ListIterator[Int8]:
        return ListIterator[Int8](self.data, self.size)

    fn to_string(self) -> String:
        let ptr = Pointer[Int8]().alloc(self.size)
        memcpy(ptr, self.data, self.size)
        return String(ptr, self.size + 1)

    # fn to_string_ref(self) -> StringRef:
    #     # 返回的StringRef有内存泄漏问题
    #     let ptr = Pointer[Int8]().alloc(self.size)
    #     memcpy(ptr, self.data, self.size)
    #     return StringRef(
    #         ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, self.size
    #     )

    fn __str__(self) -> String:
        return self.to_string()
