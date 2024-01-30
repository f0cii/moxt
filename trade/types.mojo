from collections.optional import Optional
from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr
from base.fixed import Fixed


trait StringableCollectionElement(CollectionElement, Stringable):
    ...


fn list_to_str[T: StringableCollectionElement](input_list: list[T]) -> String:
    try:
        var result: String = "["
        for i in range(len(input_list)):
            let repr = "'" + str(input_list[i]) + "'"
            if i != len(input_list) - 1:
                result += repr + ", "
            else:
                result += repr
        return result + "]"
    except e:
        return ""


struct OrderType:
    alias BUY = "BUY"
    alias SELL = "SELL"


@value
@register_passable("trivial")
struct OrderStatus(Stringable):
    var value: UInt8
    alias empty = OrderStatus(0)  # 空订单
    alias new = OrderStatus(1)  # 新建订单
    alias partially_filled = OrderStatus(2)  # 部分成交
    alias filled = OrderStatus(3)  # 全部成交
    alias canceled = OrderStatus(4)  # 已撤销
    alias rejected = OrderStatus(5)  # 订单被拒绝
    alias expired = OrderStatus(6)  # 订单过期

    # 判断订单是否活跃的方法
    # 活跃订单包括新建、部分成交状态
    fn is_active(self: Self) -> Bool:
        return self.value == 1 or self.value == 2

    # 判断订单是否已关闭的方法
    # 已关闭订单包括全部成交、已撤销、被拒绝、过期状态
    fn is_closed(self: Self) -> Bool:
        return self.value == 3 or self.value == 4 or self.value == 5 or self.value == 6

    fn __eq__(self: Self, rhs: Self) -> Bool:
        return self.value == rhs.value

    fn __ne__(self: Self, rhs: Self) -> Bool:
        return self.value != rhs.value

    fn __str__(self: Self) -> String:
        if self.value == 0:
            return "Empty"
        elif self.value == 1:
            return "New"
        elif self.value == 2:
            return "PartiallyFilled"
        elif self.value == 3:
            return "Filled"
        elif self.value == 4:
            return "Canceled"
        elif self.value == 5:
            return "Rejected"
        elif self.value == 6:
            return "Expired"
        else:
            return "--"


@value
@register_passable("trivial")
struct PositionIdx(Stringable, Intable):
    var value: UInt8
    alias single_side = PositionIdx(0)  # 单向持仓
    alias both_side_buy = PositionIdx(1)  # 买侧双向持仓
    alias both_side_sell = PositionIdx(2)  # 卖侧双向持仓

    fn __eq__(self: Self, rhs: Self) -> Bool:
        return self.value == rhs.value

    fn __ne__(self: Self, rhs: Self) -> Bool:
        return self.value != rhs.value

    fn __int__(self: Self) -> Int:
        return int(self.value)

    fn __str__(self: Self) -> String:
        if self.value == 0:
            return "SingleSide"
        elif self.value == 1:
            return "BothSideBuy"
        elif self.value == 2:
            return "BothSideSell"
        else:
            return "--"


@value
struct Order(CollectionElement, Stringable):
    var symbol: String
    var order_type: String
    var order_client_id: String
    var order_id: String
    var price: Fixed
    var quantity: Fixed
    var filled_qty: Fixed
    var status: OrderStatus

    fn __init__(inout self):
        self.symbol = ""
        self.order_type = ""
        self.order_client_id = ""
        self.order_id = ""
        self.price = Fixed.zero
        self.quantity = Fixed.zero
        self.filled_qty = Fixed.zero
        self.status = OrderStatus.empty

    fn __init__(
        inout self,
        symbol: String,
        order_type: String,
        order_client_id: String,
        order_id: String,
        price: Fixed,
        quantity: Fixed,
        filled_qty: Fixed,
        status: OrderStatus,
    ):
        self.symbol = symbol
        self.order_type = order_type
        self.order_client_id = order_client_id
        self.order_id = order_id
        self.price = price
        self.quantity = quantity
        self.filled_qty = filled_qty
        self.status = status

    fn is_closed(self):
        pass

    fn __str__(self: Self) -> String:
        return (
            "<Order: symbol="
            + self.symbol
            + ", type="
            + self.order_type
            + ", order_client_id="
            + self.order_client_id
            + ", order_id="
            + self.order_id
            + ", price="
            + str(self.price)
            + ", quantity="
            + str(self.quantity)
            + ", filled_qty="
            + str(self.filled_qty)
            + ", status="
            + str(self.status)
            + ">"
        )


@value
struct PlaceOrderResult(StringableCollectionElement):
    var order_id: String
    var order_client_id: String
    var order_detail: Optional[Order]

    fn __init__(inout self, order_id: String, order_client_id: String):
        self.order_id = order_id
        self.order_client_id = order_client_id
        self.order_detail = None

    fn __str__(self) -> String:
        return (
            "<PlaceOrderResult: order_id="
            + str(self.order_id)
            + ", order_client_id="
            + str(self.order_client_id)
            + ">"
        )


@value
struct PlaceOrdersResult(Stringable):
    # var success: Bool
    var orders: list[PlaceOrderResult]
    # var error_message: String

    fn __init__(inout self, owned orders: list[PlaceOrderResult]):
        self.orders = orders

    fn __str__(self) -> String:
        return (
            "<BatchCancelResult: success="
            + str(True)
            + ", orders="
            + list_to_str[PlaceOrderResult](self.orders)
            # + ", error_message="
            # + str(self.error_message)
            + ">"
        )


@value
struct CancelOrderResult(StringableCollectionElement):
    var order_id: String
    var order_client_id: String
    var order_detail: Optional[Order]

    fn __init__(inout self, order_id: String, order_client_id: String):
        self.order_id = order_id
        self.order_client_id = order_client_id
        self.order_detail = None

    fn __str__(self) -> String:
        return (
            "<CancelOrderResult: order_id="
            + str(self.order_id)
            + ", order_client_id="
            + str(self.order_client_id)
            + ">"
        )


@value
struct BatchCancelResult(Stringable):
    # var success: Bool
    var cancelled_orders: list[CancelOrderResult]
    # var error_message: String

    fn __init__(inout self, owned cancelled_orders: list[CancelOrderResult]):
        self.cancelled_orders = cancelled_orders

    fn __str__(self) -> String:
        return (
            "<BatchCancelResult: success="
            + str(True)
            + ", cancelled_orders="
            + list_to_str[CancelOrderResult](self.cancelled_orders)
            # + ", error_message="
            # + str(self.error_message)
            + ">"
        )
