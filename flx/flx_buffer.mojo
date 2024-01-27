from .data_types import StackValue, ValueBitWidth, padding_size, ValueType
from .cache import _CacheStackValue, Key, _CacheStringOrKey
from memory import memcpy, memset_zero
from memory.unsafe import bitcast
from math import max

fn flx_null() -> (DTypePointer[DType.uint8], Int):
    var buffer = FlxBuffer(16)
    buffer.add_null()
    return finish_ignoring_excetion(buffer^)

fn flx(v: Int) -> (DTypePointer[DType.uint8], Int):
    var buffer = FlxBuffer(16)
    buffer.add(v)
    return finish_ignoring_excetion(buffer^)

fn flx[D: DType](v: SIMD[D, 1]) -> (DTypePointer[DType.uint8], Int):
    var buffer = FlxBuffer(16)
    buffer.add(v)
    return finish_ignoring_excetion(buffer^)

fn flx(v: String) -> (DTypePointer[DType.uint8], Int):
    var buffer = FlxBuffer(len(v) + 16)
    buffer.add(v)
    return finish_ignoring_excetion(buffer^)

fn flx_blob(v: DTypePointer[DType.uint8], length: Int) -> (DTypePointer[DType.uint8], Int):
    var buffer = FlxBuffer(length + 32)
    buffer.blob(v, length)
    return finish_ignoring_excetion(buffer^)

fn flx[D: DType](v: DTypePointer[D], length: Int) -> (DTypePointer[DType.uint8], Int):
    var buffer = FlxBuffer(length * sizeof[D]() + 1024)
    buffer.add(v, length)
    return finish_ignoring_excetion(buffer^)

struct FlxBuffer[dedup_string: Bool = True, dedup_key: Bool = True, dedup_keys_vec: Bool = True](Copyable, Movable):
    var _stack: DynamicVector[StackValue]
    var _stack_positions: DynamicVector[Int]
    var _stack_is_vector: DynamicVector[SIMD[DType.bool, 1]]
    var _bytes: DTypePointer[DType.uint8]
    var _size: UInt64
    var _offset: UInt64
    var _finished: Bool
    var _string_cache: _CacheStringOrKey
    var _key_cache: _CacheStringOrKey
    var _keys_vec_cache: _CacheStackValue
    var _reference_cache: _CacheStackValue

    fn __init__(inout self, size: UInt64 = 1 << 11):
        self._size = size
        self._stack = DynamicVector[StackValue]()
        self._stack_positions = DynamicVector[Int]()
        self._stack_is_vector = DynamicVector[SIMD[DType.bool, 1]]()
        self._bytes = DTypePointer[DType.uint8].alloc(size.to_int())
        self._offset = 0
        self._finished = False
        self._string_cache = _CacheStringOrKey()
        self._key_cache = _CacheStringOrKey()
        self._keys_vec_cache = _CacheStackValue()
        self._reference_cache = _CacheStackValue()

    fn __moveinit__(inout self, owned other: Self):
        self._size = other._size
        self._stack = other._stack^
        self._stack_positions = other._stack_positions^
        self._stack_is_vector = other._stack_is_vector^
        self._bytes = other._bytes
        self._offset = other._offset
        self._finished = other._finished
        self._string_cache = other._string_cache^
        self._key_cache = other._key_cache^
        self._keys_vec_cache = other._keys_vec_cache^
        self._reference_cache = other._reference_cache^

    fn __copyinit__(inout self, other: Self):
        self._size = other._size
        self._stack = other._stack
        self._stack_positions = other._stack_positions
        self._stack_is_vector = other._stack_is_vector
        self._bytes = DTypePointer[DType.uint8].alloc(other._size.to_int())
        memcpy(self._bytes, other._bytes, other._offset.to_int())
        self._offset = other._offset
        self._finished = other._finished
        self._string_cache = other._string_cache
        self._key_cache = other._key_cache
        self._keys_vec_cache = other._keys_vec_cache
        self._reference_cache = other._reference_cache
    
    fn __del__(owned self):
        if not self._finished:
            self._bytes.free()

    fn add_null(inout self):
        self._stack.push_back(StackValue.Null)

    fn add[D: DType](inout self, value: SIMD[D, 1]):
        self._stack.push_back(StackValue.of(value))

    fn add(inout self, value: Int):
        self._stack.push_back(StackValue.of(value))

    fn add(inout self, value: String):
        self._add_string[as_key=False](value)

    fn key(inout self, value: String):
        self._add_string[as_key=True](value)

    fn _add_string[as_key: Bool](inout self, value: String):
        let byte_length = len(value)
        let bit_width = ValueBitWidth.of(byte_length)
        let bytes = value._as_ptr().bitcast[DType.uint8]()

        @parameter
        if dedup_string and not as_key:
            let cached_offset = self._string_cache.get((bytes, byte_length), self._bytes)
            if cached_offset != -1:
                self._stack.push_back(StackValue(bitcast[DType.uint8, 8](Int64(cached_offset)), bit_width, ValueType.String))
                return

        @parameter
        if dedup_key and as_key:
            let cached_offset = self._key_cache.get((bytes, byte_length), self._bytes)
            if cached_offset != -1:
                self._stack.push_back(StackValue(bitcast[DType.uint8, 8](Int64(cached_offset)), bit_width, ValueType.Key))
                return
            
        @parameter
        if not as_key:
            let byte_width = self._align(bit_width)
            self._write(byte_length, byte_width)

        let offset = self._offset
        let new_offest = self._new_offset(byte_length)
        memcpy(self._bytes.offset(self._offset.to_int()), bytes, byte_length)
        self._offset = new_offest
        self._write(0)

        @parameter
        if dedup_string and not as_key:
            self._string_cache.put((offset.to_int(), byte_length), self._bytes)
        @parameter
        if dedup_key and as_key:
            self._key_cache.put((offset.to_int(), byte_length), self._bytes)

        @parameter
        if as_key:
            self._stack.push_back(StackValue(bitcast[DType.uint8, 8](offset), bit_width, ValueType.Key))
        else:
            self._stack.push_back(StackValue(bitcast[DType.uint8, 8](offset), bit_width, ValueType.String))
        value._strref_keepalive()
    
    fn blob(inout self, value: DTypePointer[DType.uint8], length: Int):
        let bit_width = ValueBitWidth.of(length)
        let byte_width = self._align(bit_width)
        self._write(length, byte_width)
        let offset = self._offset
        let new_offest = self._new_offset(length)
        memcpy(self._bytes.offset(self._offset.to_int()), value, length)
        self._offset = new_offest
        self._stack.push_back(StackValue(bitcast[DType.uint8, 8](offset), bit_width, ValueType.Blob))

    fn add_indirect[D: DType](inout self, value: SIMD[D, 1]):
        let value_type = ValueType.of[D]()
        if value_type == ValueType.Int or value_type == ValueType.UInt or value_type == ValueType.Float:
            let bit_width = ValueBitWidth.of(value)
            let byte_width = self._align(bit_width)
            let offset = self._offset
            self._write(StackValue.of(value), byte_width)
            self._stack.push_back(StackValue(bitcast[DType.uint8, 8](offset), bit_width, value_type + 5))
        else: 
            self._stack.push_back(StackValue.of(value))

    fn add[D: DType](inout self, value: DTypePointer[D], length: Int):
        let len_bit_width = ValueBitWidth.of(length)
        let elem_bit_width = ValueBitWidth.of(SIMD[D, 1](0))
        if len_bit_width <= elem_bit_width:
            let bit_width = len_bit_width if elem_bit_width < len_bit_width else elem_bit_width
            let byte_width = self._align(bit_width)
            self._write(length, byte_width)
            let offset = self._offset    
            let byte_length = sizeof[D]() * length
            let new_offest = self._new_offset(byte_length)
            memcpy(self._bytes.offset(self._offset.to_int()), value.bitcast[DType.uint8](), byte_length)
            self._offset = new_offest
            self._stack.push_back(StackValue(bitcast[DType.uint8, 8](offset), bit_width, ValueType.of[D]() + ValueType.Vector))
        else:
            self.start_vector()
            for i in range(length):
                self.add[D](value.load(i))
            try:
                self.end()
            except:
                pass

    fn add_referenced(inout self, reference_key: String) raises:
        let key = Key(reference_key._as_ptr().bitcast[DType.uint8](), len(reference_key))
        let stack_value = self._reference_cache.get(key, StackValue.Null)
        key.pointer.free()
        if stack_value.type == ValueType.Null:
            raise "No value for reference key " + reference_key
        self._stack.push_back(stack_value)

    fn start_vector(inout self):
        self._stack_positions.push_back(len(self._stack))
        self._stack_is_vector.push_back(True)

    fn start_map(inout self):
        self._stack_positions.push_back(len(self._stack))
        self._stack_is_vector.push_back(False)

    fn end(inout self, reference_key: String = "") raises:
        let position = self._stack_positions.pop_back()
        let is_vector = self._stack_is_vector.pop_back()
        if is_vector:
            self._end_vector(position)
        else:
            self._sort_keys_and_end_map(position)
        if len(reference_key) > 0:
            let key = Key(reference_key._as_ptr().bitcast[DType.uint8](), len(reference_key))
            self._reference_cache.put(key, self._stack[len(self._stack) - 1])
    
    fn finish(owned self) raises -> (DTypePointer[DType.uint8], Int):
        return self._finish()
    
    fn _finish(inout self) raises -> (DTypePointer[DType.uint8], Int):
        self._finished = True

        while len(self._stack_positions) > 0:
            self.end()

        if len(self._stack) != 1:
            raise "Stack needs to have only one element. Instead of: " + String(len(self._stack))
        
        let value = self._stack.pop_back()
        let byte_width = self._align(value.element_width(self._offset, 0))
        self._write(value, byte_width)
        self._write(value.stored_packed_type())
        self._write(byte_width.cast[DType.uint8]())
        return self._bytes, self._offset.to_int()

    fn _align(inout self, bit_width: ValueBitWidth) -> UInt64:
        let byte_width = 1 << bit_width.value.to_int()
        self._offset += padding_size(self._offset, byte_width)
        return byte_width

    fn _write(inout self, value: StackValue, byte_width: UInt64):
        self._grow_bytes_if_needed(self._offset + byte_width)
        if value.is_offset():
            let rel_offset = self._offset - value.as_uint()
            # Safety check not implemented for now as it is internal call and should be safe
            # if byte_width == 8 or rel_offset < (1 << (byte_width * 8)):
            self._write(rel_offset, byte_width)
        else:
            let new_offset = self._new_offset(byte_width)
            self._bytes.simd_store(self._offset.to_int(), value.to_value(byte_width))
            self._offset = new_offset

    fn _write(inout self, value: UInt64, byte_width: UInt64):
        self._grow_bytes_if_needed(self._offset + byte_width)
        let new_offset = self._new_offset(byte_width)
        self._bytes.simd_store(self._offset.to_int(), bitcast[DType.uint8, 8](value))
        # We write 8 bytes but the offset is still set to byte_width
        self._offset = new_offset

    fn _write(inout self, value: UInt8):
        self._grow_bytes_if_needed(self._offset + 1)
        let new_offset = self._new_offset(1)
        self._bytes.offset(self._offset.to_int()).store(value)
        self._offset = new_offset

    fn _new_offset(inout self, byte_width: UInt64) -> UInt64:
        let new_offset = self._offset + byte_width
        let min_size = self._offset + max(byte_width, 8)
        self._grow_bytes_if_needed(min_size)
        return new_offset

    fn _grow_bytes_if_needed(inout self, min_size: UInt64):
        let prev_size = self._size
        while self._size < min_size:
            self._size <<= 1
        if prev_size < self._size:
            let prev_bytes = self._bytes
            self._bytes = DTypePointer[DType.uint8].alloc(self._size.to_int())
            memcpy(self._bytes, prev_bytes, self._offset.to_int())
            prev_bytes.free()

    fn _end_vector(inout self, position: Int) raises:
        let length = len(self._stack) - position
        let vec = self._create_vector(position, length, 1)
        self._stack.resize(position, StackValue.Null)
        self._stack.push_back(vec)

    fn _sort_keys_and_end_map(inout self, position: Int) raises:
        if (len(self._stack) - position) & 1 == 1:
            raise "The stack needs to hold key value pairs (even number of elements). Check if you combined [key] with [add] method calls properly."
        for i in range(position + 2, len(self._stack), 2):
            let key = self._stack[i]
            let value = self._stack[i + 1]
            var j = i - 2
            while j >= position and self._should_flip(self._stack[j], key):
                self._stack[j + 2] = self._stack[j]
                self._stack[j + 3] = self._stack[j + 1]
                j -= 2
            self._stack[j + 2] = key
            self._stack[j + 3] = value
        self._end_map(position)

    fn _should_flip(self, a: StackValue, b: StackValue) raises -> Bool:
        if a.type != ValueType.Key or b.type != ValueType.Key:
            raise "Stack values are not keys " + String(a.type.value) + " " + String(a.type.value)
        var index = 0
        while True:
            let c1 = self._bytes.load(a.as_uint().to_int() + index)
            let c2 = self._bytes.load(b.as_uint().to_int() + index)
            if c1 < c2:
                return False
            if c1 > c2:
                return True
            if c1 == 0 and c2 == 0:
                return False
            index += 1
    
    fn _end_map(inout self, start: Int) raises:
        let length = (len(self._stack) - start) >> 1
        var keys = StackValue.Null
        @parameter
        if dedup_key and dedup_keys_vec:
            let keys_vec = self._create_keys_vec_value(start, length)
            let cached = self._keys_vec_cache.get(keys_vec, StackValue.Null)
            if cached != StackValue.Null:
                keys = cached
                keys_vec.pointer.free()
            else:
                keys = self._create_vector(start, length, 2)
                self._keys_vec_cache.put(keys_vec, keys)
        else:
            keys = self._create_vector(start, length, 2)
        let map = self._create_vector(start + 1, length, 2, keys)
        self._stack.resize(start, StackValue.Null)
        self._stack.push_back(map)

    fn _create_keys_vec_value(self, start: Int, length: Int) -> Key:
        let size = length * 8
        let result = DTypePointer[DType.uint8].alloc(size)
        var offset = 0
        memset_zero(result, size)
        for i in range(start, len(self._stack), 2):
            result.simd_store(offset, self._stack[i].value)
            offset += 8
        let key = Key(result, size)
        result.free()
        return key

    fn _create_vector(inout self, start: Int, length: Int, step: Int, keys: StackValue = StackValue.Null) raises -> StackValue:
        var bit_width = ValueBitWidth.of(UInt64(length))
        var prefix_elements = 1
        if keys != StackValue.Null:
            prefix_elements += 2
            let keys_bit_width = keys.element_width(self._offset, 0)
            if bit_width < keys_bit_width:
                bit_width = keys_bit_width

        var typed = False
        var vec_elem_type = ValueType.Null
        if length > 0:
            vec_elem_type = self._stack[start].type
            typed = vec_elem_type.is_typed_vector_element()
            if keys != StackValue.Null:
                typed = False
            for i in range(start, len(self._stack), step):
                let elem_bit_width = self._stack[i].element_width(self._offset, i + prefix_elements)
                if bit_width < elem_bit_width:
                    bit_width = elem_bit_width
                if vec_elem_type != self._stack[i].type:
                    typed = False
                if bit_width == ValueBitWidth.width64 and typed == False:
                    break
        let byte_width = self._align(bit_width)
        if keys != StackValue.Null:
            self._write(keys, byte_width)
            self._write((1 << keys.width.value).to_int(), byte_width)
        self._write(UInt64(length), byte_width)
        let offset = self._offset
        for i in range(start, len(self._stack), step):
            self._write(self._stack[i], byte_width)
        if not typed:
            for i in range(start, len(self._stack), step):
                self._write(self._stack[i].stored_packed_type())
            if keys != StackValue.Null:
                return StackValue(bitcast[DType.uint8, 8](offset), bit_width, ValueType.Map)
            return StackValue(bitcast[DType.uint8, 8](offset), bit_width, ValueType.Vector)

        return StackValue(bitcast[DType.uint8, 8](offset), bit_width, ValueType.Vector + vec_elem_type)

fn finish_ignoring_excetion(owned flx: FlxBuffer) -> (DTypePointer[DType.uint8], Int):
    try:
        return flx^.finish()
    except e:
        # should never happen
        print("Unexpected error:", e)
        return DTypePointer[DType.uint8](), -1
