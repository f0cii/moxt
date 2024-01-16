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
    var client_order_id: String
    var order_id: String
    var price: Fixed
    var quantity: Fixed
    var filled_qty: Fixed
    var status: OrderStatus

    fn __init__(inout self):
        self.symbol = ""
        self.order_type = ""
        self.client_order_id = ""
        self.order_id = ""
        self.price = Fixed(0)
        self.quantity = Fixed(0)
        self.filled_qty = Fixed(0)
        self.status = OrderStatus.empty

    fn __init__(
        inout self,
        symbol: String,
        order_type: String,
        client_order_id: String,
        order_id: String,
        price: Fixed,
        quantity: Fixed,
        filled_qty: Fixed,
        status: OrderStatus,
    ):
        self.symbol = symbol
        self.order_type = order_type
        self.client_order_id = client_order_id
        self.order_id = order_id
        self.price = price
        self.quantity = quantity
        self.filled_qty = filled_qty
        self.status = status

    fn __str__(self: Self) -> String:
        return (
            "<Order: symbol="
            + self.symbol
            + ", type="
            + self.order_type
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
