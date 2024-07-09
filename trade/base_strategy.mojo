from base.c import *
from base.mo import *
from base.fixed import Fixed
from core.bybitmodel import PositionInfo, OrderBookLite
from .config import AppConfig
from .types import Order
from .platform import Platform


trait BaseStrategy(Movable):
    fn __init__(inout self, config: AppConfig) raises:
        ...

    fn setup(inout self, platform: UnsafePointer[Platform]) raises:
        ...

    fn on_init(inout self) raises:
        ...

    fn on_exit(inout self) raises:
        ...

    fn on_tick(inout self) raises:
        ...

    fn on_orderbook(inout self, ob: OrderBookLite) raises:
        ...

    fn on_order(inout self, order: Order) raises:
        ...

    fn on_position(inout self, position: PositionInfo) raises:
        ...
