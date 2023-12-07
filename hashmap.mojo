from memory import memset_zero, memcpy

# Reference: https://github.com/mzaks/mojo-hash/blob/main/hashmap/hashmap.mojo


struct HashMapDict[V: CollectionElement, hash: fn (StringRef) -> UInt64]:
    var keys: DynamicVector[StringRef]
    var values: DynamicVector[V]
    var key_map: DTypePointer[DType.uint32]
    var deleted_mask: DTypePointer[DType.uint8]
    var count: Int
    var capacity: Int

    fn __init__(inout self):
        self.count = 0
        self.capacity = 16
        self.keys = DynamicVector[StringRef](self.capacity)
        self.values = DynamicVector[V](self.capacity)
        self.key_map = DTypePointer[DType.uint32].alloc(self.capacity)
        self.deleted_mask = DTypePointer[DType.uint8].alloc(self.capacity >> 3)
        memset_zero(self.key_map, self.capacity)
        memset_zero(self.deleted_mask, self.capacity >> 3)

    fn put(inout self, key: StringLiteral, value: V):
        if self.count / self.capacity >= 0.8:
            self._rehash()

        self._put(key, value, -1)

    @always_inline
    fn _is_deleted(self, index: Int) -> Bool:
        let offset = index // 8
        let bit_index = index & 7
        return self.deleted_mask.offset(offset).load() & (1 << bit_index) != 0

    @always_inline
    fn _deleted(self, index: Int):
        let offset = index // 8
        let bit_index = index & 7
        let p = self.deleted_mask.offset(offset)
        let mask = p.load()
        p.store(mask | (1 << bit_index))

    @always_inline
    fn _not_deleted(self, index: Int):
        let offset = index // 8
        let bit_index = index & 7
        let p = self.deleted_mask.offset(offset)
        let mask = p.load()
        p.store(mask & ~(1 << bit_index))

    fn _rehash(inout self):
        let old_mask_capacity = self.capacity >> 3
        self.key_map.free()
        self.capacity <<= 1
        let mask_capacity = self.capacity >> 3
        self.key_map = DTypePointer[DType.uint32].alloc(self.capacity)
        memset_zero(self.key_map, self.capacity)

        let _deleted_mask = DTypePointer[DType.uint8].alloc(mask_capacity)
        memset_zero(_deleted_mask, mask_capacity)
        memcpy(_deleted_mask, self.deleted_mask, old_mask_capacity)
        self.deleted_mask.free()
        self.deleted_mask = _deleted_mask

        for i in range(len(self.keys)):
            self._put(self.keys[i], self.values[i], i + 1)

    fn _put(inout self, key: StringRef, value: V, rehash_index: Int):
        let key_hash = hash(key)
        let modulo_mask = self.capacity - 1
        var key_map_index = (key_hash & modulo_mask).to_int()
        while True:
            let key_index = self.key_map.offset(key_map_index).load().to_int()
            if key_index == 0:
                let new_key_index: Int
                if rehash_index == -1:
                    self.keys.push_back(key)
                    self.values.push_back(value)
                    self.count += 1
                    new_key_index = len(self.keys)
                else:
                    new_key_index = rehash_index
                self.key_map.offset(key_map_index).store(UInt32(new_key_index))
                return

            let other_key = self.keys[key_index - 1]
            if other_key == key:
                self.values[key_index - 1] = value
                if self._is_deleted(key_index - 1):
                    self.count += 1
                    self._not_deleted(key_index - 1)
                return

            key_map_index = (key_map_index + 1) & modulo_mask

    fn get(self, key: StringLiteral, default: V) -> V:
        let key_hash = hash(key)
        let modulo_mask = self.capacity - 1
        var key_map_index = (key_hash & modulo_mask).to_int()
        while True:
            let key_index = self.key_map.offset(key_map_index).load().to_int()
            if key_index == 0:
                return default
            let other_key = self.keys[key_index - 1]
            if other_key == key:
                if self._is_deleted(key_index - 1):
                    return default
                return self.values[key_index - 1]
            key_map_index = (key_map_index + 1) & modulo_mask

    fn delete(inout self, key: StringLiteral):
        let key_hash = hash(key)
        let modulo_mask = self.capacity - 1
        var key_map_index = (key_hash & modulo_mask).to_int()
        while True:
            let key_index = self.key_map.offset(key_map_index).load().to_int()
            if key_index == 0:
                return
            let other_key = self.keys[key_index - 1]
            if other_key == key:
                self.count -= 1
                return self._deleted(key_index - 1)
            key_map_index = (key_map_index + 1) & modulo_mask

    fn debug(self):
        print("HashMapDict", "count:", self.count, "capacity:", self.capacity)
        print_no_newline("Keys:")
        for i in range(len(self.keys)):
            print_no_newline(self.keys[i])
            print_no_newline(", ")
        print_no_newline("\n")
        print_no_newline("Key map:")
        for i in range(self.capacity):
            print_no_newline(self.key_map.offset(i).load())
            print_no_newline(", ")
        print_no_newline("\n")
        print_no_newline("Deleted mask:")
        for i in range(self.capacity >> 3):
            let mask = self.deleted_mask.offset(i).load()
            for j in range(8):
                print_no_newline((mask >> j) & 1)
            print_no_newline(" ")
        print_no_newline("\n")
