struct ListIterator[T: AnyRegType]:
    """
    https://github.com/Moosems/Mojo-Types/blob/main/types/array/array.mojo
    """

    var storage: Pointer[T]
    var offset: Int
    var max: Int

    fn __init__(inout self, storage: Pointer[T], max: Int):
        self.offset = 0
        self.max = max
        self.storage = storage

    fn __len__(self) -> Int:
        return self.max - self.offset

    fn __next__(inout self) -> T:
        let ret = self.storage.load(self.offset)
        self.offset += 1
        return ret
