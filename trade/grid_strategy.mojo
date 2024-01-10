from base.c import *
from base.mo import *
from core.bybitmodel import *
from .config import AppConfig
from .base_strategy import *
from .platform import *


struct GridStrategy(BaseStrategy):
    var platform: Platform

    fn __init__(inout self, config: AppConfig):
        logi("GridStrategy.__init__")
        self.platform = Platform(config)

    fn __moveinit__(inout self, owned existing: Self):
        logi("GridStrategy.__moveinit__")
        self.platform = existing.platform ^

    fn update_orderbook(
        self,
        type_: String,
        inout asks: list[OrderBookLevel],
        inout bids: list[OrderBookLevel],
    ) raises:
        self.platform.update_orderbook(type_, asks, bids)

    fn get_orderbook(self, n: Int) raises -> OrderBookLite:
        return self.platform.get_orderbook(n)

    fn on_init(self) raises:
        logi("GridStrategy.on_init")
        let category = "linear"
        let symbol = "BTCUSDT"

        let exchange_info = self.platform.fetch_exchange_info(category, symbol)
        logi(str(exchange_info))

        print("GridStrategy.on_init done")

    fn on_exit(self) raises:
        logi("GridStrategy.on_exit")

    fn on_tick(self) raises:
        logi("GridStrategy.on_tick")

    fn on_orderbook(self, ob: OrderBookLite) raises:
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

    fn on_order(self, order: OrderInfo) raises:
        logi("GridStrategy.on_order")

    fn on_position(self, position: PositionInfo) raises:
        logi("GridStrategy.on_position")
