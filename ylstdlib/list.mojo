from collections.vector import DynamicVector
from stdlib_extensions._utils import custom_debug_assert


trait ListElement(CollectionElement, Stringable):
    ...


struct ListRefIter[T: ListElement]:
    var data: list[T]
    var idx: Int

    fn __init__(inout self, data: list[T]):
        self.idx = -1
        self.data = data

    fn __len__(self) -> Int:
        return len(self.data) - self.idx - 1

    # fn __next__(inout self) -> T:
    #     self.idx += 1
    #     return self.data[self.idx]

    fn __next__(inout self) raises -> AnyPointer[T]:
        self.idx += 1
        return self.data.unsafe_get(self.idx)


@value
struct List[T: ListElement](Sized, Movable, Stringable):
    var _internal_vector: DynamicVector[T]

    fn __init__(inout self):
        self._internal_vector = DynamicVector[T]()

    fn __init__(inout self, owned value: DynamicVector[T]):
        self._internal_vector = value

    @staticmethod
    fn from_values(*values: T) -> list[T]:
        var result = list[T]()
        for value in values:
            result.append(value[])
        return result

    @always_inline
    fn _normalize_index(self, index: Int) -> Int:
        if index < 0:
            return len(self) + index
        else:
            return index

    fn append(inout self, value: T):
        self._internal_vector.push_back(value)

    fn clear(inout self):
        self._internal_vector.clear()

    fn copy(self) -> list[T]:
        return list(self._internal_vector)

    fn extend(inout self, other: list[T]):
        for i in range(len(other)):
            self.append(other[i])

    fn pop(inout self, index: Int = -1) -> T:
        custom_debug_assert(
            index < len(self._internal_vector), "list index out of range"
        )
        var new_index = self._normalize_index(index)
        var element = self[new_index]
        for i in range(new_index, len(self) - 1):
            self[i] = self[i + 1]
        self._internal_vector.resize(len(self._internal_vector) - 1, element)
        return element

    fn reverse(inout self):
        for i in range(len(self) // 2):
            var mirror_i = len(self) - 1 - i
            var tmp = self[i]
            self[i] = self[mirror_i]
            self[mirror_i] = tmp

    fn insert(inout self, key: Int, value: T):
        var index = self._normalize_index(key)
        if index >= len(self):
            self.append(value)
            return
        # we increase the size of the array before insertion
        self.append(self[-1])
        for i in range(len(self) - 2, index, -1):
            self[i] = self[i - 1]
        self[key] = value

    @always_inline
    fn unsafe_get(self, index: Int) -> AnyPointer[T]:
        return self._internal_vector.data + index

    @always_inline
    fn __getitem__(self, index: Int) -> T:
        custom_debug_assert(
            index < len(self._internal_vector), "list index out of range"
        )
        return self._internal_vector[self._normalize_index(index)]

    @always_inline
    fn __getitem__(self: Self, limits: Slice) -> Self:
        var new_list: Self = Self()
        for i in range(limits.start, limits.end, limits.step):
            new_list.append(self[i])
        return new_list

    @always_inline
    fn __setitem__(inout self, key: Int, value: T):
        custom_debug_assert(key < len(self._internal_vector), "list index out of range")
        self._internal_vector[self._normalize_index(key)] = value

    @always_inline
    fn __len__(self) -> Int:
        return len(self._internal_vector)

    fn __iter__(self: Self) -> ListRefIter[T]:
        return ListRefIter(self)

    @staticmethod
    fn from_string(input_value: String) -> list[String]:
        var result = list[String]()
        for i in range(len(input_value)):
            result.append(input_value[i])
        return result

    fn __str__(self) -> String:
        var result: String = "["
        for i in range(len(self)):
            var repr = str((self._internal_vector.data + i)[])
            if i != len(self) - 1:
                result += repr + ", "
            else:
                result += repr
        return result + "]"
