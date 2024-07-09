from collections.optional import Optional
from collections.dict import Dict
from base.fixed import Fixed


trait StringableCollectionElement(CollectionElement, Stringable):
    ...


struct OrderType:
    alias BUY = "BUY"
    alias SELL = "SELL"


@value
@register_passable
struct OrderStatus(Stringable):
    var value: UInt8
    alias empty = OrderStatus(0)  # Empty order
    alias new = OrderStatus(1)  # Create new order
    alias partially_filled = OrderStatus(2)  # Partial filled
    alias filled = OrderStatus(3)  # Complete filled
    alias canceled = OrderStatus(4)  # Cancelled
    alias rejected = OrderStatus(5)  # Order rejected
    alias expired = OrderStatus(6)  # Order expired

    # Method to determine if an order is active
    # Active orders include statuses of "new" and "partially filled"
    fn is_active(self: Self) -> Bool:
        return self.value == 1 or self.value == 2

    # Method to determine if an order is closed
    # Closed orders include statuses of "fully filled", "cancelled", "rejected", and "expired"
    fn is_closed(self: Self) -> Bool:
        return (
            self.value == 3
            or self.value == 4
            or self.value == 5
            or self.value == 6
        )

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
@register_passable
struct PositionIdx(Stringable, Intable):
    var value: UInt8
    alias single_side = PositionIdx(0)  # Unidirectional position
    alias both_side_buy = PositionIdx(
        1
    )  # Bidirectional position on the buy side
    alias both_side_sell = PositionIdx(
        2
    )  # Bidirectional position on the sell side

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
struct Account(Stringable):
    var coin: String  # 账户币种 "USDT"
    var equity: Fixed  # 账户权益
    var wallet_balance: Fixed  # 钱包余额
    var available_to_withdraw: Fixed  # 可提取余额,即可用保证金
    var total_order_margin: Fixed  # 订单初始保证金
    var total_position_margin: Fixed  # 持仓维持保证金
    var unrealised_pnl: Fixed  # 未实现盈亏
    var cum_realised_pnl: Fixed  # 累计已实现盈亏
    var extra: Dict[String, String]

    fn __init__(inout self):
        self.coin = ""
        self.equity = Fixed.zero
        self.wallet_balance = Fixed.zero
        self.available_to_withdraw = Fixed.zero
        self.total_order_margin = Fixed.zero
        self.total_position_margin = Fixed.zero
        self.unrealised_pnl = Fixed.zero
        self.cum_realised_pnl = Fixed.zero
        self.extra = Dict[String, String]()

    fn __init__(
        inout self,
        coin: String,
        equity: Fixed,
        wallet_balance: Fixed,
        available_to_withdraw: Fixed,
        total_order_margin: Fixed,
        total_position_margin: Fixed,
        unrealised_pnl: Fixed,
        cum_realised_pnl: Fixed,
    ):
        self.coin = coin
        self.equity = equity
        self.wallet_balance = wallet_balance
        self.available_to_withdraw = available_to_withdraw
        self.total_order_margin = total_order_margin
        self.total_position_margin = total_position_margin
        self.unrealised_pnl = unrealised_pnl
        self.cum_realised_pnl = cum_realised_pnl
        self.extra = Dict[String, String]()

    fn available_margin(self) -> Fixed:
        """
        可用保证金
        """
        return self.available_to_withdraw

    fn __str__(self) -> String:
        return (
            "<Account: coin="
            + str(self.coin)
            + ", equity="
            + str(self.equity)
            + ", wallet_balance="
            + str(self.wallet_balance)
            + ", available_to_withdraw="
            + str(self.available_to_withdraw)
            + ", total_order_margin="
            + str(self.total_order_margin)
            + ", total_position_margin="
            + str(self.total_position_margin)
            + ", unrealised_pnl="
            + str(self.unrealised_pnl)
        )


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
    var orders: List[PlaceOrderResult]

    fn __init__(inout self, owned orders: List[PlaceOrderResult]):
        self.orders = orders

    fn __str__(self) -> String:
        return (
            "<BatchCancelResult: success="
            + str(True)
            + ", orders="
            + get_list_string(self.orders)
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
    var cancelled_orders: List[CancelOrderResult]

    fn __init__(inout self, owned cancelled_orders: List[CancelOrderResult]):
        self.cancelled_orders = cancelled_orders

    fn __str__(self) -> String:
        return (
            "<BatchCancelResult: success="
            + str(True)
            + ", cancelled_orders="
            + get_list_string(self.cancelled_orders)
            + ">"
        )


fn get_list_string[T: StringableCollectionElement](l: List[T]) -> String:
    var s: String = "["
    for i in range(len(l)):
        var repr = "'" + str(l[i]) + "'"
        if i != len(l) - 1:
            s += repr + ", "
        else:
            s += repr
    s += "]"
    return s
