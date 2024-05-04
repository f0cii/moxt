from collections.list import List


alias i1 = __mlir_attr.`1: i1`


@always_inline
fn _max(a: Int, b: Int) -> Int:
    return a if a > b else b
