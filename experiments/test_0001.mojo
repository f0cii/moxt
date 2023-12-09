alias a_fun = fn () -> None


fn e_do() -> None:
    print("e_do")


fn e_do1() -> None:
    print("e_do1")


struct Wrap:
    var f: a_fun

    fn __init__(inout self):
        self.f = e_do

    fn set_f(inout self, f: a_fun):
        self.f = f
        print("set_f")

    fn do(self) -> None:
        print("do")
        self.f()
        print("done")


var w = Wrap()


fn do_it() -> None:
    w.do()


# let do_func_ptr: a_fun = e_do()


# 测试集成
fn test_h():
    w.set_f(e_do1)
    do_it()
    # print("11000")
    # do_func_ptr()
    print("11001")


fn main():
    # test_h()
