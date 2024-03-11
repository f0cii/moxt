from collections import Dict, KeyElement


@value
struct StringKey(KeyElement):
    var s: String

    fn __init__(inout self, owned s: String):
        self.s = s ^

    fn __init__(inout self, s: StringLiteral):
        self.s = String(s)

    fn __hash__(self) -> Int:
        var ptr = self.s._buffer.data.value
        return hash(DTypePointer[DType.int8](ptr), len(self.s))

    fn __eq__(self, other: Self) -> Bool:
        return self.s == other.s