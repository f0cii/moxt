from testing import assert_true, assert_equal
from stdlib_extensions.builtins import dict, HashableInt, HashableStr
import os


fn main() raises:
    var a_dict = dict[HashableInt, Int]()
    a_dict[1] = 100

    assert_equal(a_dict[1], 100)
