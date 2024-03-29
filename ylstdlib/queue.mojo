from testing import assert_true
from collections.list import List
from collections.optional import Optional
from math import max

alias IndexError = Error("IndexError")


@value
struct Queue[T: CollectionElement](Sized):
    var items: List[T]
    var begin: Int

    fn __init__(inout self):
        self.items = List[T]()
        self.begin = 0

    fn __init__(inout self, capacity: Int):
        self.items = List[T](capacity=capacity)
        self.begin = 0

    @always_inline
    fn __len__(self) -> Int:
        return len(self.items) - self.begin

    @always_inline
    fn enqueue(inout self, item: T):
        self.items.append(item)

    @always_inline
    fn front(self) -> T:  # Note: The return value can't be a reference, yet.
        return self.items[self.begin]

    @always_inline
    fn remove_front(inout self):
        # assert_true(len(self) > 0)
        if len(self) == 0:
            return
        self.begin += 1
        if self.begin == len(self.items):
            # reached the end of the underlying vector, reset state.
            self.items.clear()
            self.begin = 0

    @always_inline
    fn dequeue(inout self) -> Optional[T]:
        if len(self) == 0:
            return Optional[T](None)
        var item = self.items[self.begin]
        self.remove_front()
        return item
