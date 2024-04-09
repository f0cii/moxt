from collections.list import List


alias i1 = __mlir_attr.`1: i1`


@always_inline
fn _max(a: Int, b: Int) -> Int:
    return a if a > b else b


fn list_insert[T: CollectionElement](inout l: List[T], i: Int, owned value: T):
    """Inserts a value at the specified index.

    Args:
        l: The list to insert the value into. This list is modified in place.
        i: The index at which to insert the value.
        value: The value to insert.
    """
    debug_assert(-l.size <= i < l.size, "index must be within bounds")

    var normalized_idx = i
    if i < 0:
        normalized_idx += len(l)

    # If the list is full, reallocate with double the current capacity
    if l.size >= l.capacity:
        l._realloc(_max(1, l.capacity * 2))

    # Shift elements to the right of the insertion point
    for i in range(l.size, normalized_idx, -1):
        (l.data + i).emplace_value((l.data + i - 1).take_value())

    # Insert the new value
    (l.data + normalized_idx).emplace_value(value ^)

    # Increment the size of the list
    l.size += 1


# mutability reference
fn list__ref[
    T: CollectionElement, L: MutLifetime
](
    l: Reference[List[T], i1, L].mlir_ref_type,
    i: Int,
) -> Reference[
    T, i1, L
]:
    """Gets a reference to the list element at the given index.

    Args:
        l: The list.
        i: The index of the element.

    Returns:
        An mutability reference to the element at the given index.
    """
    var normalized_idx = i
    if i < 0:
        normalized_idx += Reference(l)[].size

    # Mutability gets set to the local mutability of this
    # pointer value, ie. because we defined it with `let` it's now an
    # "immutable" reference regardless of the mutability of `self`.
    # This means we can't just use `AnyPointer.__refitem__` here
    # because the mutability won't match.
    var base_ptr = Reference(l)[].data
    return __mlir_op.`lit.ref.from_pointer`[
        _type = Reference[T, i1, L].mlir_ref_type
    ]((base_ptr + normalized_idx).value)
