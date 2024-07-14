from base.fixed import Fixed


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
@register_passable
struct OrderBookLevel(CollectionElement):
    var price: Fixed
    var qty: Fixed


@value
struct OrderBookLite:
    var symbol: String
    var asks: List[OrderBookLevel]
    var bids: List[OrderBookLevel]

    fn __init__(inout self, symbol: String = ""):
        self.symbol = symbol
        self.asks = List[OrderBookLevel]()
        self.bids = List[OrderBookLevel]()