fn main():
    # test Tuple
    let t = Tuple[Int, StringLiteral](199, "b")
    let a_i = t.get[0, Int]()
    logi("a_i: " + String(a_i))
