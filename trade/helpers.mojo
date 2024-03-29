from .types import *
from core.bybitmodel import OrderInfo


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


fn convert_bybit_order(order: OrderInfo) -> Order:
    var order_ = Order(
        symbol=order.symbol,
        order_type=order.type_,
        order_client_id=order.order_link_id,
        order_id=order.order_id,
        price=Fixed(order.price),
        quantity=Fixed(order.qty),
        filled_qty=Fixed(order.cum_exec_qty),
        status=convert_bybit_order_status(order.status),
    )
    return order_
