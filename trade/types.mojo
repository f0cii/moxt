from base.fixed import Fixed


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


struct PositionIdx:
    alias SINGLE_SIDE = 0  # 单向持仓
    alias BOTH_SIDE_BUY = 1  # 买侧双向持仓
    alias BOTH_SIDE_SELL = 2  # 卖侧双向持仓


@value
struct Order(CollectionElement, Stringable):
    var type: String
    var client_order_id: String
    var order_id: String
    var price: Fixed
    var quantity: Fixed
    var filled_qty: Fixed
    var status: OrderStatus

    fn __init__(inout self):
        self.type = ""
        self.client_order_id = ""
        self.order_id = ""
        self.price = Fixed(0)
        self.quantity = Fixed(0)
        self.filled_qty = Fixed(0)
        self.status = OrderStatus.empty

    fn __init__(
        inout self,
        type_: String,
        client_order_id: String,
        order_id: String,
        price: Fixed,
        quantity: Fixed,
        filled_qty: Fixed,
        status: OrderStatus,
    ):
        self.type = type_
        self.client_order_id = client_order_id
        self.order_id = order_id
        self.price = price
        self.quantity = quantity
        self.filled_qty = filled_qty
        self.status = status

    fn __str__(self: Self) -> String:
        return (
            "<Order: type="
            + self.type
            + ", client_order_id="
            + self.client_order_id
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
