from base.c import *
from base.mo import *
from base.fixed import Fixed
from core.bybitmodel import *
from .config import AppConfig
from .types import *
from .platform import Platform


trait DefaultConstructible:
    fn __init__(inout self) raises:
        ...


trait StrategyConstructible:
    fn __init__(inout self, config: AppConfig) raises:
        ...


trait BaseStrategy(StrategyConstructible, Movable):
    fn setup(inout self) raises:
        ...

    fn on_init(inout self) raises:
        ...

    fn on_exit(inout self) raises:
        ...
    
    fn get_platform_pointer(inout self) -> Pointer[Platform]:
        ...

    fn on_tick(inout self) raises:
        ...

    fn on_orderbook(inout self, ob: OrderBookLite) raises:
        ...

    fn on_order(inout self, order: Order) raises:
        ...

    fn on_position(inout self, position: PositionInfo) raises:
        ...


fn create_strategy[T: BaseStrategy](config: AppConfig) raises -> T:
    return T(config)
