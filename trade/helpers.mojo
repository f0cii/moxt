from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr
from stdlib_extensions.builtins.string import *
from .types import *


fn safe_split(
    input_string: String, sep: String = " ", owned maxsplit: Int = -1
) -> list[String]:
    try:
        return split(input_string, sep, maxsplit)
    except e:
        return list[String]()


fn convert_bybit_order_status(status: String) -> OrderStatus:
    if status == "Created" or status == "New":
        return OrderStatus.new
    elif status == "Rejected":
        return OrderStatus.rejected
    elif status == "PartiallyFilled":
        return OrderStatus.partially_filled
    elif status == "PartiallyFilledCanceled" or status == "Cancelled":
        return OrderStatus.canceled
    elif status == "Filled":
        return OrderStatus.filled
    else:
        return OrderStatus.empty
