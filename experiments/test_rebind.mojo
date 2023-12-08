fn main():
    let a: Int = 100
    let b = rebind[Int64, Int](a)
    print(b)

    let c = rebind[Int]("100")
    print(c)