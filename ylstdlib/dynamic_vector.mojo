from memory.anypointer import AnyPointer
from algorithm.swap import swap

# Reference: https://github.com/mikowals/dynamic_vector.mojo/blob/main/dynamic_vector.mojo
# Added insert method etc

alias i1 = __mlir_type.i1
alias i1_1 = __mlir_attr.`1: i1`
alias i1_0 = __mlir_attr.`0: i1`


struct DynamicVector[T: CollectionElement](Sized, CollectionElement):
    var data: AnyPointer[T]
    var size: Int
    var capacity: Int

    @always_inline
    fn __init__(inout self, *, capacity: Int):
        self.capacity = capacity
        self.data = AnyPointer[T].alloc(capacity)
        self.size = 0

    @always_inline
    fn __del__(owned self):
        for i in range(self.size):
            _ = (self.data + i).take_value()
        self.data.free()

    @always_inline
    fn __copyinit__(inout self, other: Self):
        self.capacity = other.capacity
        self.size = other.size
        self.data = AnyPointer[T].alloc(self.capacity)
        for i in range(self.size):
            var new_value = other[i]
            (self.data + i).emplace_value(new_value)

    @always_inline
    fn __moveinit__(inout self, owned other: Self):
        self.capacity = other.capacity
        self.size = other.size
        self.data = other.data
        other.data = AnyPointer[T]()
        other.size = 0
        other.capacity = 0

    fn insert(inout self, index: Int, value: T):
        # we increase the size of the array before insertion
        self.append(self[len(self) - 1])
        for i in range(len(self) - 2, index, -1):
            self[i] = self[i - 1]
        self[index] = value

    @always_inline
    fn _normalize_index(self, index: Int) -> Int:
        if index < 0:
            return len(self) + index
        else:
            return index

    fn append(inout self, owned value: T):
        if self.size == self.capacity:
            self.reserve(self.capacity * 2)
        self.data[self.size] = value ^
        self.size += 1

    fn push_back(inout self, owned value: T):
        self.append(value ^)

    @always_inline
    fn pop_back(inout self) -> T:
        self.size -= 1
        return (self.data + self.size).take_value()

    # TODO: Check if this can be simplified after #1921 was fixed.
    # Mojo #1921: https://github.com/modularml/mojo/issues/1921#event-12066222345
    fn __refitem__[
        mutability: i1,
        lifetime: AnyLifetime[mutability].type,
    ](
        self: Reference[Self, mutability, lifetime].mlir_ref_type,
        index: Int,
    ) -> Reference[T, mutability, lifetime]:
        return Reference(
            __mlir_op.`lit.ref.from_pointer`[
                _type = Reference[T, mutability, lifetime].mlir_ref_type
            ]((Reference(self)[].data + index).value)
        )

    @always_inline
    fn reserve(inout self, new_capacity: Int):
        if new_capacity <= self.capacity:
            return
        var new_data = AnyPointer[T].alloc(new_capacity)
        for i in range(self.size):
            (self.data + i).move_into(new_data + i)
        self.data.free()
        self.data = new_data
        self.capacity = new_capacity

    @always_inline
    fn resize(inout self, new_size: Int, value: T):
        if new_size > self.size:
            if new_size > self.capacity:
                self.reserve(new_size)
            for _ in range(self.size, new_size):
                self.append(value)
        elif new_size < self.size:
            for i in range(new_size, self.size):
                _ = (self.data + i).take_value()
            self.size = new_size

    @always_inline
    fn clear(inout self):
        for i in range(self.size):
            _ = (self.data + i).take_value()
        self.size = 0

    @always_inline
    fn extend(inout self, owned other: Self):
        self.reserve(self.size + len(other))
        for i in range(len(other)):
            (other.data + i).move_into(self.data + self.size + i)
        self.size += len(other)
        other.size = 0

    @always_inline
    fn reverse(inout self):
        var a = self.data
        var b = self.data + self.size - 1
        while a < b:
            # a[0] and b[0] is using AnyPointer.__refitem__ and automatic dereference
            swap[T](a[0], b[0])
            a = a + 1
            b = b - 1

    @always_inline
    fn __getitem__(
        inout self, _slice: Slice
    ) -> DynamicVectorSlice[T, __lifetime_of(self)]:
        return DynamicVectorSlice[T](Reference(self), _slice)

    @always_inline
    fn __len__(self) -> Int:
        return self.size

    @always_inline
    fn __iter__(
        inout self,
    ) -> _DynamicVectorIter[T, i1_1, __lifetime_of(self)]:
        return _DynamicVectorIter[T, i1_1, __lifetime_of(self)](Reference(self))

    @always_inline
    fn steal_data(inout self) -> AnyPointer[T]:
        var res = self.data
        self.data = AnyPointer[T]()
        self.size = 0
        self.capacity = 0
        return res


# Avoid __init__(Ref, Slice, Size) initializer because we calculate size.
@register_passable
struct DynamicVectorSlice[T: CollectionElement, L: MutLifetime](
    Sized, CollectionElement
):
    var data: Reference[DynamicVector[T], i1_1, L]
    var _slice: Slice
    var size: Int

    @always_inline
    fn __init__(
        inout self,
        data: Reference[DynamicVector[T], i1_1, L],
        _slice: Slice,
    ):
        self.data = data
        self._slice = Self.adapt_slice(_slice, len(data[]))
        self.size = Self.get_size(self._slice.start, self._slice.end, self._slice.step)

    @always_inline
    fn __init__(
        inout self,
        other: Self,
        _slice: Slice,
    ) raises:
        self.data = other.data
        self._slice = Self.adapt_slice(_slice, other._slice, len(other))
        self.size = Self.get_size(self._slice.start, self._slice.end, self._slice.step)

    fn __copyinit__(inout self, other: Self):
        self.data = other.data
        self._slice = other._slice
        self.size = other.size

    @always_inline
    fn __refitem__(self, index: Int) -> Reference[T, i1_1, L]:
        return self.data[].data.__refitem__(
            self._slice.start + index * self._slice.step
        )

    @always_inline
    fn __getitem__(inout self, _slice: Slice) raises -> Self:
        return Self(self, _slice)

    @always_inline
    fn __len__(self) -> Int:
        return self.size

    @always_inline
    fn to_vector(self) raises -> DynamicVector[T]:
        var res = DynamicVector[T](capacity=len(self))
        for i in range(len(self)):
            res.append(self[i])
        return res

    @always_inline
    @staticmethod
    fn adapt_slice(_slice: Slice, dim: Int) -> Slice:
        var res = _slice
        if res.start < 0:
            res.start += dim
        if not _slice._has_end():
            res.end = dim
        if res.end < 0:
            res.end += dim
        if res.end > dim:
            res.end = dim

        if res.end < res.start:
            res.end = res.start

        return res

    @always_inline
    @staticmethod
    fn adapt_slice(_slice: Slice, base_slice: Slice, dim: Int) raises -> Slice:
        var res = Self.adapt_slice(_slice, dim)
        res.start = base_slice.start + res.start * base_slice.step
        if res.start > base_slice.end:
            raise Error(
                String("Slice start value outside base bounds: ")
                + res.start
                + "("
                + base_slice.start
                + " + "
                + res.start
                + " * "
                + base_slice.step
                + ")"
                + " > "
                + base_slice.end
            )
        res.end = math.min(base_slice.end, base_slice.start + res.end * base_slice.step)
        res.step *= base_slice.step

        return res

    @always_inline
    fn __setitem__(
        inout self, _slice: Slice, owned value: DynamicVectorSlice[T]
    ) raises:
        var target_slice = DynamicVectorSlice[T](self, _slice)
        if len(target_slice) != len(value):
            raise Error(
                String("slice assignment size mismatch: received ")
                + len(value)
                + "new values but destination expects "
                + len(target_slice)
            )
        for i in range(len(target_slice)):
            target_slice[i] = value[i]

    @always_inline
    fn __setitem__(inout self, _slice: Slice, owned value: DynamicVector[T]) raises:
        self.__setitem__(
            _slice, DynamicVectorSlice[T](Reference(value), Slice(0, len(value), 1))
        )

    @always_inline
    fn _get_base_offset(self, start: Int, steps: Int, stride: Int = 1) -> Int:
        return self._slice.start + start + steps * self._slice.step * stride

    @always_inline
    fn __iter__(inout self) -> _DynamicVectorSliceIter[T, L]:
        return _DynamicVectorSliceIter[T, L](self)

    @always_inline
    @staticmethod
    fn get_size(start: Int, end: Int, step: Int) -> Int:
        return math.max(0, (end - start + (step - (1 if step > 0 else -1))) // step)

    # Useful print method for debugging
    # Static with T = Int because T might not be Stringable
    @staticmethod
    fn to_string(inout vec: DynamicVectorSlice[Int], name: String) raises -> String:
        var res = String(name + " (size = " + len(vec) + ") [")
        for val in vec:
            res += String(val[]) + ", "

        return res[:-2] + "]"

    # Useful print method for debugging
    # Static with T = String because T might not be Stringable
    @staticmethod
    fn to_string(inout vec: DynamicVectorSlice[String], name: String) raises -> String:
        var res = String(name + " (size = " + len(vec) + ") [")
        for val in vec:
            res += val[] + ", "

        return res[:-2] + "]"


@value
struct _DynamicVectorIter[
    T: CollectionElement, mutability: i1, lifetime: AnyLifetime[mutability].type
](CollectionElement, Sized):
    var index: Int
    var src: Reference[DynamicVector[T], mutability, lifetime]

    @always_inline
    fn __init__(inout self, src: Reference[DynamicVector[T], mutability, lifetime]):
        self.index = 0
        self.src = src

    # TODO: Check if this can be simplified after #1921 was fixed.
    # Mojo #1921: https://github.com/modularml/mojo/issues/1921#event-12066222345
    @always_inline
    fn __next__(inout self) -> Reference[T, mutability, lifetime]:
        var res = Reference(
            __mlir_op.`lit.ref.from_pointer`[
                _type = Reference[T, mutability, lifetime].mlir_ref_type
            ]((self.src[].data + self.index).value)
        )

        self.index += 1
        return res

    @always_inline
    fn __len__(self) -> Int:
        return len(self.src[]) - self.index


@value
struct _DynamicVectorSliceIter[T: CollectionElement, lifetime: MutLifetime](
    CollectionElement, Sized
):
    var index: Int
    var src: DynamicVectorSlice[T, lifetime]

    @always_inline
    fn __init__(inout self, src: DynamicVectorSlice[T, lifetime]):
        self.index = 0
        self.src = src

    @always_inline
    fn __next__(inout self) -> Reference[T, i1_1, lifetime]:
        var res = self.src.__refitem__(self.index)
        self.index += 1
        return res

    @always_inline
    fn __len__(self) -> Int:
        return len(self.src) - self.index
