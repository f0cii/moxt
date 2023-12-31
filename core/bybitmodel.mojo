from simpletools.simplelist import SimpleList
from base.str_utils import *
from base.str import Str
from base.fixed import Fixed
from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr


alias List = SimpleList


@value
@register_passable
struct ServerTime(Stringable):
    # {"timeSecond":"1696143222","timeNano":"1696143222859435119"}
    var time_second: Int
    var time_nano: Int

    fn __str__(self) -> String:
        return (
            "<ServerTime: timeSecond="
            + str(self.time_second)
            + ", timeNano="
            + str(self.time_nano)
            + ">"
        )


@value
struct ExchangeInfo(Stringable):
    var symbol: String
    var tick_size: Float64  # 价格 0.01
    var step_size: Float64  # 数量 0.001

    fn __str__(self) -> String:
        return (
            "<ExchangeInfo: symbol="
            + str(self.symbol)
            + ", tick_size="
            + str(self.tick_size)
            + ", step_size="
            + str(self.step_size)
            + ">"
        )


@value
@register_passable
struct KlineItem(Stringable, CollectionElement):
    """
    K线的一条记录
    """

    var timestamp: Int
    var open: Float64
    var high: Float64
    var low: Float64
    var close: Float64
    var volume: Float64
    var turnover: Float64
    var confirm: Bool

    fn __init__(
        timestamp: Int,
        open: Float64,
        high: Float64,
        low: Float64,
        close: Float64,
        volume: Float64,
        turnover: Float64,
        confirm: Bool,
    ) -> Self:
        return Self {
            timestamp: timestamp,
            open: open,
            high: high,
            low: low,
            close: close,
            volume: volume,
            turnover: turnover,
            confirm: confirm,
        }

    fn __str__(self) -> String:
        return (
            "<KlineItem: timestamp="
            + str(self.timestamp)
            + ", open="
            + str(self.open)
            + ", high="
            + str(self.high)
            + ", low="
            + str(self.low)
            + ", close="
            + String(self.close)
            + ", volume="
            + str(self.volume)
            + ", turnover="
            + str(self.turnover)
            + ", confirm="
            + str(self.confirm)
            + ">"
        )


@value
@register_passable
struct OrderBookItem(Stringable, CollectionElement):
    """
    订单薄的一条记录
    """

    var price: Float64
    var qty: Float64

    fn __str__(self) -> String:
        return (
            "<OrderBookItem: price="
            + String(self.price)
            + ", qty="
            + String(self.qty)
            + ">"
        )


@value
struct OrderBook(Stringable):
    """
    订单薄
    """

    var asks: List[OrderBookItem]
    var bids: List[OrderBookItem]

    def __init__(inout self, asks: List[OrderBookItem], bids: List[OrderBookItem]):
        self.asks = asks
        self.bids = bids

    fn __str__(self) -> String:
        return (
            "<OrderBook: asks=" + "str(self.asks)" + ", bids=" + "str(self.bids)" + "}>"
        )


@value
struct PositionInfo(Stringable, CollectionElement):
    var position_idx: Int
    # riskId: Int
    var symbol: String
    var side: String  # "None"
    var size: String
    var avg_price: String
    var position_value: String
    # tradeMode: Int    # 0
    # positionStatus: String # Normal
    # autoAddMargin: Int    # 0
    # adlRankIndicator: Int # 0
    var leverage: Float64  # 1
    # positionBalance: String    # 0
    var mark_price: String  # 26515.73
    # liq_price: String           # ""
    # bust_price: String          # "0.00"
    var position_mm: String  # "0"
    var position_im: String  # "0"
    # tpslMode: String           # "Full"
    var take_profit: String  # "0.00"
    var stop_loss: String  # "0.00"
    # trailingStop: String       # "0.00"
    var unrealised_pnl: String  # "0"
    var cum_realised_pnl: String  # "-19.59637027"
    # seq: Int                # 8172241025
    var created_time: String  # "1682125794703"
    var updated_time: String  # "updatedTime"

    fn __init__(inout self):
        self.position_idx = 0
        self.symbol = ""
        self.side = ""
        self.size = ""
        self.avg_price = ""
        self.position_value = ""
        self.leverage = 1
        self.mark_price = ""
        self.position_mm = ""
        self.position_im = ""
        self.take_profit = ""
        self.stop_loss = ""
        self.unrealised_pnl = ""
        self.cum_realised_pnl = ""
        self.created_time = ""
        self.updated_time = ""

    fn __init__(
        inout self,
        position_idx: Int,
        symbol: String,
        side: String,
        size: String,
        avg_price: String,
        position_value: String,
        leverage: Float64,
        mark_price: String,
        position_mm: String,
        position_im: String,
        take_profit: String,
        stop_loss: String,
        unrealised_pnl: String,
        cum_realised_pnl: String,
        created_time: String,
        updated_time: String,
    ):
        self.position_idx = position_idx
        self.symbol = symbol
        self.side = side
        self.size = size
        self.avg_price = avg_price
        self.position_value = position_value
        self.leverage = leverage
        self.mark_price = mark_price
        self.position_mm = position_mm
        self.position_im = position_im
        self.take_profit = take_profit
        self.stop_loss = stop_loss
        self.unrealised_pnl = unrealised_pnl
        self.cum_realised_pnl = cum_realised_pnl
        self.created_time = created_time
        self.updated_time = updated_time

    fn __str__(self) -> String:
        return (
            "<PositionInfo: symbol="
            + str(self.symbol)
            + ", position_idx="
            + str(self.position_idx)
            + ", side="
            + str(self.side)
            + ", size="
            + str(self.size)
            + ", avg_price="
            + str(self.avg_price)
            + ", position_value="
            + str(self.position_value)
            + ", leverage="
            + str(self.leverage)
            + ", mark_price="
            + str(self.mark_price)
            + ", position_mm="
            + str(self.position_mm)
            + ", position_im="
            + str(self.position_im)
            + ", take_profit="
            + str(self.take_profit)
            + ", stop_loss="
            + str(self.stop_loss)
            + ", unrealised_pnl="
            + str(self.unrealised_pnl)
            + ", cum_realised_pnl="
            + str(self.cum_realised_pnl)
            + ", created_time="
            + str(self.created_time)
            + ", updated_time="
            + str(self.updated_time)
            + ">"
        )


@value
struct OrderResponse(Stringable, CollectionElement):
    var order_id: String
    var order_link_id: String

    fn __init__(inout self, order_id: String, order_link_id: String):
        self.order_id = order_id
        self.order_link_id = order_link_id

    fn __str__(self) -> String:
        return (
            "<OrderResponse: order_id="
            + str(self.order_id)
            + ", order_link_id="
            + str(self.order_link_id)
            + ">"
        )


@value
struct BalanceInfo(Stringable, CollectionElement):
    var coin_name: String
    var equity: Float64
    var available_to_withdraw: Float64
    var wallet_balance: Float64
    var total_order_im: Float64
    var total_position_im: Float64

    fn __init__(
        inout self,
        coin_name: String,
        equity: Float64,
        available_to_withdraw: Float64,
        wallet_balance: Float64,
        total_order_im: Float64,
        total_position_im: Float64,
    ):
        self.coin_name = coin_name
        self.equity = equity
        self.available_to_withdraw = available_to_withdraw
        self.wallet_balance = wallet_balance
        self.total_order_im = total_order_im
        self.total_position_im = total_position_im

    fn __str__(self) -> String:
        return (
            "<BalanceInfo: coin_name="
            + str(self.coin_name)
            + " equity="
            + str(self.equity)
            + ", available_to_withdraw="
            + str(self.available_to_withdraw)
            + ", wallet_balance="
            + str(self.wallet_balance)
            + ", total_order_im="
            + str(self.total_order_im)
            + ", total_position_im="
            + str(self.total_position_im)
            + ">"
        )


@value
struct OrderInfo(Stringable, CollectionElement):
    # position_idx:
    # 0 - 单向持仓
    # 1 - 买侧双向持仓
    # 2 - 卖侧双向持仓
    var position_idx: Int  # positionIdx
    var order_id: String  # orderId
    var symbol: String  # BTCUSDT
    var side: String  # Buy/Sell
    var type_: String  # orderType Limit/Market
    var price: Float64
    var qty: Float64
    var cum_exec_qty: Float64  # cumExecQty
    var status: String  # orderStatus
    var created_time: String  # createdTime
    var updated_time: String  # updatedTime
    var avg_price: Float64  # avgPrice
    var cum_exec_fee: Float64  # cumExecFee
    # time_in_force:
    # GTC - Good Till Cancel 成交为止, 一直有效直到被取消
    # IOC - Immediate or Cancel 无法立即成交(吃单)的部分就撤销
    # FOK - Fill or Kill 无法全部立即成交就撤销
    # PostOnly - 只做Maker单, 如果会成为Taker单则取消
    var time_in_force: String  # timeInForce
    var reduce_only: Bool  # reduceOnly
    var order_link_id: String  # orderLinkId

    fn __init__(inout self):
        self.position_idx = 0
        self.order_id = ""
        self.symbol = ""
        self.side = ""
        self.type_ = ""
        self.price = 0
        self.qty = 0
        self.cum_exec_qty = 0
        self.status = ""
        self.created_time = ""
        self.updated_time = ""
        self.avg_price = 0
        self.cum_exec_fee = 0
        self.time_in_force = ""
        self.reduce_only = False
        self.order_link_id = ""

    fn __init__(
        inout self,
        position_idx: Int,
        order_id: String,
        symbol: String,
        side: String,
        type_: String,
        price: Float64,
        qty: Float64,
        cum_exec_qty: Float64,
        status: String,
        created_time: String,
        updated_time: String,
        avg_price: Float64,
        cum_exec_fee: Float64,
        time_in_force: String,
        reduce_only: Bool,
        order_link_id: String,
    ):
        self.position_idx = position_idx
        self.order_id = order_id
        self.symbol = symbol
        self.side = side
        self.type_ = type_
        self.price = price
        self.qty = qty
        self.cum_exec_qty = cum_exec_qty
        self.status = status
        self.created_time = created_time
        self.updated_time = updated_time
        self.avg_price = avg_price
        self.cum_exec_fee = cum_exec_fee
        self.time_in_force = time_in_force
        self.reduce_only = reduce_only
        self.order_link_id = order_link_id

    fn __str__(self) -> String:
        return (
            "<OrderInfo: position_idx="
            + str(self.position_idx)
            + ", order_id="
            + str(self.order_id)
            + ", symbol="
            + str(self.symbol)
            + ", side="
            + str(self.side)
            + ", type="
            + str(self.type_)
            + ", price="
            + str(self.price)
            + ", qty="
            + str(self.qty)
            + ", cum_exec_qty="
            + str(self.cum_exec_qty)
            + ", status="
            + str(self.status)
            + ", created_time="
            + str(self.created_time)
            + ", updated_time="
            + str(self.updated_time)
            + ", avg_price="
            + str(self.avg_price)
            + ", cum_exec_fee="
            + str(self.cum_exec_fee)
            + ", time_in_force="
            + str(self.time_in_force)
            + ", reduce_only="
            + str(self.reduce_only)
            + ", order_link_id="
            + str(self.order_link_id)
            + ">"
        )


@value
@register_passable
struct OrderBookLevel(CollectionElement):
    var price: Fixed
    var qty: Fixed


@value
struct OrderBookLite:
    var asks: list[OrderBookLevel]
    var bids: list[OrderBookLevel]

    fn __init__(inout self):
        self.asks = list[OrderBookLevel]()
        self.bids = list[OrderBookLevel]()
