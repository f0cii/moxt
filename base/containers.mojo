@value
struct ObjectContainer[T: CollectionElement]:
    var data: UnsafePointer[T]
    var offset: Int

    fn __init__(inout self, size: Int = 100):
        self.data = UnsafePointer[T].alloc(size)
        self.offset = 0

    fn __copyinit__(inout self, existing: Self):
        # print("ObjectContainer.__copyinit__")
        self.data = existing.data
        self.offset = existing.offset

    fn __moveinit__(inout self, owned existing: Self):
        # print("ObjectContainer.__moveinit__")
        self.data = existing.data
        self.offset = existing.offset
    
    fn emplace(inout self, owned i: T) -> UnsafePointer[T]:
        initialize_pointee_move(self.data + self.offset, i)
        var ptr = (self.data + self.offset)
        self.offset += 1
        return ptr

    fn emplace_as_index(inout self, owned i: T) -> Int:
        initialize_pointee_move(self.data + self.offset, i)
        var index = int(self.data + self.offset)
        self.offset += 1
        return index
    
    fn take(inout self, index: Int) -> T:
        return move_from_pointee(self.data + index)
