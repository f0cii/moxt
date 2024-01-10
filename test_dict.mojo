from testing import assert_true, assert_equal
from stdlib_extensions.builtins import dict, HashableInt, HashableStr
import os


fn main() raises:
    var a_dict = dict[HashableInt, Int]()
    a_dict[1] = 100

    assert_equal(a_dict[1], 100)

    var b_dict = dict[HashableInt, String]()
    b_dict[100] = "hello"

    assert_equal(b_dict[100], "hello")

    var c_dict = dict[HashableStr, String]()
    c_dict["a1"] = "hello100"

    assert_equal(c_dict["a1"], "hello100")
