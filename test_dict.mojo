from testing import assert_true, assert_equal
import os


fn test_dict() raises:
    var a_dict = Dict[Int, Int]()
    a_dict[1] = 100

    assert_equal(a_dict[1], 100)

    var b_dict = Dict[Int, String]()
    b_dict[100] = "hello"

    assert_equal(b_dict[100], "hello")

    var c_dict = Dict[String, String]()
    c_dict["a1"] = "hello100"

    assert_equal(c_dict["a1"], "hello100")


fn main() raises:
    test_dict()
