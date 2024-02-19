@value
struct ObjectContainer[T: CollectionElement]:
    var data: AnyPointer[T]
    var offset: Int

    fn __init__(inout self, size: Int = 100):
        self.data = AnyPointer[T].alloc(size)
        self.offset = 0

    fn __copyinit__(inout self, existing: Self):
        # print("ObjectContainer.__copyinit__")
        self.data = existing.data
        self.offset = existing.offset

    fn __moveinit__(inout self, owned existing: Self):
        # print("ObjectContainer.__moveinit__")
        self.data = existing.data
        self.offset = existing.offset
    
    fn emplace(inout self, owned i: T) -> AnyPointer[T]:
        (self.data + self.offset).emplace_value(i)
        let ptr = (self.data + self.offset)
        self.offset += 1
        return ptr

    fn emplace_as_index(inout self, owned i: T) -> Int:
        (self.data + self.offset).emplace_value(i)
        let index = (self.data + self.offset).__as_index()
        self.offset += 1
        return index
    
    fn take(inout self, index: Int) -> T:
        return (self.data + index).take_value()
