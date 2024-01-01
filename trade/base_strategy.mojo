from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr
from base.c import *
from base.mo import *
from base.fixed import Fixed
from core.bybitmodel import *
from .config import AppConfig


trait DefaultConstructible:
    fn __init__(inout self):
        ...


trait StrategyConstructible:
    fn __init__(inout self, config: AppConfig):
        ...


trait BaseStrategy(DefaultConstructible, StrategyConstructible, Movable):
    fn on_init(self):
        ...

    fn on_exit(self):
        ...

    # 临时放到策略类，因为mojo的Pointer还不支持AnyType，目前只支持AnyRegType
    fn update_orderbook(
        self,
        type_: String,
        inout asks: list[OrderBookLevel],
        inout bids: list[OrderBookLevel],
    ):
        ...

    fn get_orderbook(self, n: Int) -> OrderBookLite:
        ...

    fn on_tick(self):
        ...

    fn on_orderbook(self, ob: OrderBookLite):
        ...

    fn on_order(self, order: OrderInfo):
        ...

    fn on_position(self, position: PositionInfo):
        ...


fn create_strategy[T: BaseStrategy](config: AppConfig) -> T:
    return T(config)
