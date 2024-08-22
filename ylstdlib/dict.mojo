from collections.dict import Dict, DictEntry


fn reap_value[
    K: KeyElement, V: CollectionElement
](owned v: DictEntry[K, V]) -> V:
    """Take the value from an owned entry.

    Returns:
        The value of the entry.
    """
    __mlir_op.`lit.ownership.mark_destroyed`(__get_mvalue_as_litref(v))
    return v.value^


fn dict_pop[
    K: KeyElement, V: CollectionElement
](inout dict: Dict[K, V], key: K) raises -> V:
    """Remove a value from the dictionary by key.

    Args:
        dict: The dictionary to remove from.
        key: The key to remove from the dictionary.

    Returns:
        The value associated with the key, if it was in the dictionary.
        Raises otherwise.

    Raises:
        "KeyError" if the key was not present in the dictionary.
    """
    var hash = hash(key)
    var found: Bool
    var slot: Int
    var index: Int
    found, slot, index = dict._find_index(hash, key)
    if found:
        dict._set_index(slot, dict.REMOVED)
        var entry = Reference(dict._entries[index])
        debug_assert(entry[].__bool__(), "entry in index must be full")
        var entry_value = entry[].unsafe_take()
        entry[] = None
        dict.size -= 1
        # return entry_value^.reap_value()
        return reap_value(entry_value^)
    raise "KeyError"