from base.c import *
from base.mo import *
from .config import AppConfig
from .base_strategy import *
from .data_handler import *


struct GridStrategy(BaseStrategy):
    var _dataHandler: DataHandler

    fn __init__(inout self):
        self._dataHandler = DataHandler()

    fn __init__(inout self, config: AppConfig):
        self._dataHandler = DataHandler()

    fn __moveinit__(inout self, owned existing: Self):
        logi("GridStrategy.__moveinit__")
        self._dataHandler = existing._dataHandler ^

    fn update_orderbook(
        self,
        type_: String,
        inout asks: list[OrderBookLevel],
        inout bids: list[OrderBookLevel],
    ):
        self._dataHandler.update_orderbook(type_, asks, bids)

    fn get_orderbook(self, n: Int) -> OrderBookLite:
        return self._dataHandler.get_orderbook(n)

    fn on_init(self):
        pass

    fn on_exit(self):
        pass

    fn on_tick(self):
        pass

    fn on_orderbook(self, ob: OrderBookLite):
        try:
            if len(ob.asks) > 0 and len(ob.bids) > 0:
                logi(
                    "GridStrategy.on_orderbook ask="
                    + str(ob.asks[0].qty)
                    + "@"
                    + str(ob.asks[0].price)
                    + " bid="
                    + str(ob.bids[0].qty)
                    + "@"
                    + str(ob.bids[0].price)
                )
            else:
                logi(
                    "GridStrategy.on_orderbook len(asks)="
                    + str(len(ob.asks))
                    + " len(bids)="
                    + str(len(ob.bids))
                )
        except err:
            loge("on_orderbook error: " + str(err))

    fn on_order(self, order: OrderInfo):
        pass

    fn on_position(self, position: PositionInfo):
        pass
