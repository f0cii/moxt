from python.python import Python, PythonObject


# pip install twofish


fn twofish_encrypt(text: String, key: String) raises -> String:
    var twofish = Python.import_module("twofish")
    var binascii = Python.import_module("binascii")
    var key_ = binascii.a2b_hex(key)
    var T = twofish.Twofish(key_)
    var text_bytes = PythonObject(text).encode("utf-8")
    var x = T.encrypt(text_bytes)
    var x_hex = binascii.b2a_hex(x).decode("utf-8")
    return str(x_hex)


fn twofish_decrypt(hex_text: String, key: String) raises -> String:
    var twofish = Python.import_module("twofish")
    var binascii = Python.import_module("binascii")
    var key_ = binascii.a2b_hex(PythonObject(key))
    var T = twofish.Twofish(key_)
    var py_hex_text = PythonObject(hex_text)
    var bytes = binascii.a2b_hex(py_hex_text)
    var x = T.decrypt(bytes).decode()
    return str(x)


fn test_twofish_raw() raises:
    var twofish = Python.import_module("twofish")
    var binascii = Python.import_module("binascii")
    var key_str = "0c6d6db61905400fee1f39e7fa26be87"
    var key = binascii.a2b_hex(key_str)
    print(key)
    var T = twofish.Twofish(key)
    var text = PythonObject("YELLOWSUBMARINES")
    var text_bytes = text.encode("utf-8")
    var x = T.encrypt(text_bytes)
    print(x)
    var x_hex = binascii.b2a_hex(x)
    print(x_hex.decode())
    var y = T.decrypt(x).decode()
    print(str(y))


# fn test_twofish() raises:
#     var key = "0c6d6db61905400fee1f39e7fa26be87"
#     var text = "YELLOWSUBMARINES"
#     var v = twofish_encrypt(text, key)

#     print(v)

#     var c_text = twofish_decrypt(v, key)
#     print(c_text)


# fn main() raises:
#     # test_twofish_raw()
#     test_twofish()
