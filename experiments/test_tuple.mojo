fn main():
    # test Tuple
    let t = Tuple[Int, StringLiteral](199, "b")
    let a_i = t.get[0, Int]()
    print("a_i: " + str(a_i))

    let a = Tuple[Int, Int](3, 5)
    let a_value = a.get[0, Int]()
    print(a_value)
