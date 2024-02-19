from base.str_utils import *
from base.str import Str
from base.fixed import Fixed
from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr


@value
struct OrderInfo(Stringable, CollectionElement):
    """
        {
        "orderId": 237740210409,
        "symbol": "BTCUSDT",
        "status": "NEW",
        "clientOrderId": "62ayQ4MjyVIaCkvDX00dhh",
        "price": "20000.00",
        "avgPrice": "0.00",
        "origQty": "0.010",
        "executedQty": "0.000",
        "cumQty": "0.000",
        "cumQuote": "0.00000",
        "timeInForce": "GTC",
        "type": "LIMIT",
        "reduceOnly": false,
        "closePosition": false,
        "side": "BUY",
        "positionSide": "LONG",
        "stopPrice": "0.00",
        "workingType": "CONTRACT_PRICE",
        "priceProtect": false,
        "origType": "LIMIT",
        "priceMatch": "NONE",
        "selfTradePreventionMode": "NONE",
        "goodTillDate": 0,
        "updateTime": 1704291033033
    }
    status: NEW, PARTIALLY_FILLED, FILLED, CANCELED, REJECTED, EXPIRED, EXPIRED_IN_MATCH
    """

    var order_id: Int  # orderId
    var symbol: String  # BTCUSDT
    var status: String  # orderStatus
    var order_client_id: String  # clientOrderId
    var price: String  # price
    var avg_price: String  # avgPrice
    var orig_qty: String  # origQty
    var executed_qty: String  # executedQty
    var cum_qty: String  # cumQty
    var cum_quote: String  # cumQuote
    var time_in_force: String  # timeInForce
    var type_: String  # type LIMIT
    var reduce_only: Bool  # reduceOnly
    var close_position: Bool  # closePosition
    var side: String  # BUY/SELL
    var position_side: String  # positionSide LONG
    var stop_price: String  # stopPrice
    var working_type: String  # workingType CONTRACT_PRICE
    var price_protect: Bool  # priceProtect
    var orig_type: String  # origType LIMIT
    var price_match: String  # priceMatch NONE
    var self_trade_prevention_mode: String  # selfTradePreventionMode NONE
    var good_till_date: Int  # goodTillDate
    var update_time: Int  # updateTime

    fn __init__(inout self):
        self.order_id = 0
        self.symbol = ""
        self.status = ""
        self.order_client_id = ""
        self.price = ""
        self.avg_price = ""
        self.orig_qty = ""
        self.executed_qty = ""
        self.cum_qty = ""
        self.cum_quote = ""
        self.time_in_force = ""
        self.type_ = ""
        self.reduce_only = False
        self.close_position = False
        self.side = ""
        self.position_side = ""
        self.stop_price = ""
        self.working_type = ""
        self.price_protect = False
        self.orig_type = ""
        self.price_match = ""
        self.self_trade_prevention_mode = ""
        self.good_till_date = 0
        self.update_time = 0

    fn __str__(self) -> String:
        return (
            "<OrderInfo: order_id="
            + str(self.order_id)
            + ", symbol="
            + str(self.symbol)
            + ", status="
            + str(self.status)
            + ", order_client_id="
            + str(self.order_client_id)
            + ", price="
            + str(self.price)
            + ", avg_price="
            + str(self.avg_price)
            + ", orig_qty="
            + str(self.orig_qty)
            + ", executed_qty="
            + str(self.executed_qty)
            + ", ..."
            + ">"
        )
