from c import *
from mo import *


@value
struct Far:
    var ptr: c_void_pointer

    fn __init__(inout self):
        self.ptr = seq_far_new()
    
    fn get_int(self, key: StringLiteral) -> Int:
        return seq_far_get_int(self.ptr, key.data()._as_scalar_pointer(), len(key)).to_int()
    
    fn get_float(self, key: StringLiteral) -> Float64:
        return seq_far_get_float(self.ptr, key.data()._as_scalar_pointer(), len(key))
    
    fn get_bool(self, key: StringLiteral) -> Bool:
        return seq_far_get_bool(self.ptr, key.data()._as_scalar_pointer(), len(key))
    
    fn get_str(self, key: StringLiteral) -> String:
        var n: c_size_t = 0
        let c_str = seq_far_get_string(self.ptr, key.data()._as_scalar_pointer(), len(key), Pointer[c_size_t].address_of(n))
        return c_str_to_string(c_str, n)
    
    fn __len__(self) -> Int:
        return seq_far_size(self.ptr)
    
    fn set_int(self, key: StringLiteral, value: Int):
        _ = seq_far_set_int(self.ptr, key.data()._as_scalar_pointer(), len(key), value)
    
    fn set_float(self, key: StringLiteral, value: Float64):
        _ = seq_far_set_float(self.ptr, key.data()._as_scalar_pointer(), len(key), value)
    
    fn set_bool(self, key: StringLiteral, value: Bool):
        _ = seq_far_set_bool(self.ptr, key.data()._as_scalar_pointer(), len(key), value)
    
    fn set_str(self, key: StringLiteral, value: StringLiteral):
        _ = seq_far_set_string(self.ptr, key.data()._as_scalar_pointer(), len(key), value.data()._as_scalar_pointer(), len(value))
    
    fn release(self):
        seq_far_free(self.ptr)