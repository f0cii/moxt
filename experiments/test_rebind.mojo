fn main():
    var a: Int = 100
    var b = rebind[Int64, Int](a)
    print(b)
