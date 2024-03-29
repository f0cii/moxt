fn main():
    # test Tuple
    var t = Tuple[Int, StringLiteral](199, "b")
    var a_i = t.get[0, Int]()
    print("a_i: " + str(a_i))

    var a = Tuple[Int, Int](3, 5)
    var a_value = a.get[0, Int]()
    print(a_value)
