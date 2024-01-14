from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr
from base.c import *
from base.mo import *
from base.fixed import Fixed
from core.bybitmodel import *
from .config import AppConfig
from .types import *


trait DefaultConstructible:
    fn __init__(inout self):
        ...


trait StrategyConstructible:
    fn __init__(inout self, config: AppConfig):
        ...


trait BaseStrategy(StrategyConstructible, Movable):
    fn on_init(inout self) raises:
        ...

    fn on_exit(inout self) raises:
        ...

    # 临时放到策略类，因为mojo的Pointer还不支持AnyType，目前只支持AnyRegType
    fn on_update_orderbook(
        inout self,
        type_: String,
        inout asks: list[OrderBookLevel],
        inout bids: list[OrderBookLevel],
    ) raises:
        ...

    fn on_update_order(inout self, order: Order) raises:
        ...

    fn get_orderbook(self, n: Int) raises -> OrderBookLite:
        ...

    fn on_tick(inout self) raises:
        ...

    fn on_orderbook(inout self, ob: OrderBookLite) raises:
        ...

    fn on_order(inout self, order: Order) raises:
        ...

    fn on_position(inout self, position: PositionInfo) raises:
        ...


fn create_strategy[T: BaseStrategy](config: AppConfig) -> T:
    return T(config)
