@value
struct SimpleList[type_: CollectionElement](Stringable):
    var data: DynamicVector[type_]

    fn __init__(inout self):
        """
        Initialize an empty SimpleList.
        """
        self.data = DynamicVector[type_]()

    fn append(inout self, value: type_):
        """
        Append a value to the end of the SimpleList.
        """
        self.data.push_back(value)

    fn __len__(self) -> Int:
        """
        Return the length (the number of items) in the SimpleList.
        """
        return self.data.__len__()

    fn __getitem__(self, index: Int) raises -> type_:
        """
        Return the item at the given index. Raises an error if the index is out of range.
        """
        if index >= self.__len__():
            raise Error("IndexError: list index out of range")
        return self.data.__getitem__(index)

    fn get(inout self, index: Int, default: type_) -> type_:
        """
        Return the item at the given index, or the default value if the index is out of range.
        """
        if index >= self.__len__():
            return default
        return self.data.__getitem__(index)

    fn foreach(inout self, function: fn (type_) capturing -> None) -> None:
        """
        Apply a function to each item in the SimpleList.
        """
        for i in range(self.data.__len__()):
            function(self.data[i])

    fn map[
        newtype_: CollectionElement
    ](inout self, function: fn (value: type_) capturing -> newtype_) -> SimpleList[
        newtype_
    ]:
        """
        Apply a function to each item in the SimpleList and return a new SimpleList with the results.
        """
        var result = SimpleList[newtype_]()
        for i in range(self.__len__()):
            result.append(function(self.data[i]))
        return result

    fn all(inout self, function: fn (value: type_) capturing -> Bool) -> Bool:
        """
        Return True if the function returns True for all items in the SimpleList, False otherwise.
        """
        for i in range(self.__len__()):
            if not function(self.data[i]):
                return False
        return True

    fn any(inout self, function: fn (value: type_) capturing -> Bool) -> Bool:
        """
        Return True if the function returns True for any item in the SimpleList, False otherwise.
        """
        for i in range(self.__len__()):
            if function(self.data[i]):
                return True
        return False

    fn range(inout self, start: Int, end: Int) raises -> SimpleList[type_]:
        """
        Return a new SimpleList with items from the given start index to the end index.
        """
        var result = SimpleList[type_]()
        for i in range(start, end):
            result.append(self.data[i])
        return result

    fn reduce[
        newtype_: CollectionElement, initial: newtype_
    ](
        inout self,
        function: fn (accumulator: newtype_, value: type_) capturing -> newtype_,
    ) -> newtype_:
        """
        Apply a function of two arguments cumulatively to the items of the SimpleList, from left to right,
        so as to reduce the SimpleList to a single output.
        """
        var result = initial
        for i in range(self.__len__()):
            result = function(result, self.data[i])
        return result

    fn __bool__(self) -> Bool:
        """
        Return True if the SimpleList is not empty, False otherwise.
        """
        return self.data.__len__() > 0

    fn size(self) -> Int:
        """
        Return the number of items in the SimpleList.
        """
        return self.data.__len__()

    fn __str__(self) -> String:
        var s = "<SimpleList: size=" + str(self.size())
        s += "\n"
        # for index in range (self.size()):
        #     let item = self.data.__getitem__(index)
        #     s += str(item)
        s += "\n"
        s += ">"
        return s
        # return (
        #     "<SimpleList: size="
        #     + str(self.time_second)
        #     + " timeNano="
        #     + str(self.time_nano)
        #     + ">"
        # )
