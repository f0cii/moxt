# https://github.com/modularml/mojo/issues/1393

var glob = True
var gstr = String("hello")


fn get_glob() -> Bool:
    return glob


fn set_glob(v: Bool) -> None:
    glob = v


fn get_gstr() -> String:
    let a = gstr
    print(a)
    return a


fn set_gstr(v: String) -> None:
    gstr = v


fn main():
    set_glob(True)
    set_glob(False)
    print(get_glob())
    # set_gstr("hello f0cci")
    let s = get_gstr()
    print("10000")
    print(s)
