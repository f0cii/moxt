from collections.list import List


@always_inline
fn _max(a: Int, b: Int) -> Int:
    return a if a > b else b


fn list_insert[T: CollectionElement](inout list: List[T], index: Int, owned value: T):
    """Inserts a value at the specified index.

    Args:
        list: The list to insert the value into. This list is modified in place.
        index: The index at which to insert the value.
        value: The value to insert.
    """
    debug_assert(0 <= index <= list.size, "index must be within bounds")

    # If the list is full, reallocate with double the current capacity
    if list.size >= list.capacity:
        list._realloc(_max(1, list.capacity * 2))

    # Shift elements to the right of the insertion point
    for i in range(list.size, index, -1):
        (list.data + i).emplace_value((list.data + i - 1).take_value())

    # Insert the new value
    (list.data + index).emplace_value(value ^)

    # Increment the size of the list
    list.size += 1
