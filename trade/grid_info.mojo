import math
from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr
from base.fixed import Fixed
from base.mo import *
from .types import *


@value
struct GridCell(CollectionElement, Stringable):
    var level: Int
    var price: Fixed

    var long_open_cid: String  # ¶©µ¥Client Id
    var long_open_status: OrderStatus  # ¶©µ¥×´Ì¬
    var long_open_quantity: Fixed  # ¼ÇÂ¼¹Òµ¥ÊýÁ¿
    var long_tp_cid: String  # Ö¹Ó¯µ¥Client Id
    var long_tp_status: OrderStatus  # Ö¹Ó¯µ¥×´Ì¬
    var long_sl_cid: String  # Ö¹Ëðµ¥Client Id
    var long_sl_status: OrderStatus  # Ö¹Ëðµ¥×´Ì¬

    var short_open_cid: String
    var short_open_status: OrderStatus
    var short_open_quantity: Fixed
    var short_tp_cid: String
    var short_tp_status: OrderStatus
    var short_sl_cid: String
    var short_sl_status: OrderStatus

    fn __init__(inout self, level: Int, price: Fixed):
        self.level = level
        self.price = price

        self.long_open_cid = ""
        self.long_open_status = OrderStatus.empty
        self.long_open_quantity = Fixed(0)
        self.long_tp_cid = ""
        self.long_tp_status = OrderStatus.empty
        self.long_sl_cid = ""
        self.long_sl_status = OrderStatus.empty

        self.short_open_cid = ""
        self.short_open_status = OrderStatus.empty
        self.short_open_quantity = Fixed(0)
        self.short_tp_cid = ""
        self.short_tp_status = OrderStatus.empty
        self.short_sl_cid = ""
        self.short_sl_status = OrderStatus.empty

    fn set_long_open_cid(inout self, cid: String):
        self.long_open_cid = cid

    fn set_long_open_status(inout self, status: OrderStatus):
        self.long_open_status = status

    fn set_long_open_quantity(inout self, new_quantity: Fixed):
        self.long_open_quantity = new_quantity

    fn set_long_tp_cid(inout self, cid: String):
        self.long_tp_cid = cid

    fn set_long_tp_status(inout self, status: OrderStatus):
        self.long_tp_status = status

    fn set_long_sl_cid(inout self, cid: String):
        self.long_sl_cid = cid

    fn set_long_sl_status(inout self, status: OrderStatus):
        self.long_sl_status = status

    fn set_short_open_cid(inout self, cid: String):
        self.short_open_cid = cid

    fn set_short_open_status(inout self, status: OrderStatus):
        self.short_open_status = status

    fn set_short_open_quantity(inout self, new_quantity: Fixed):
        self.short_open_quantity = new_quantity

    fn set_short_tp_cid(inout self, cid: String):
        self.short_tp_cid = cid

    fn set_short_tp_status(inout self, status: OrderStatus):
        self.short_tp_status = status

    fn set_short_sl_cid(inout self, cid: String):
        self.short_sl_cid = cid

    fn set_short_sl_status(inout self, status: OrderStatus):
        self.short_sl_status = status

    fn __str__(self: Self) -> String:
        return (
            "<GridCell: level="
            + str(self.level)
            + ", price="
            + str(self.price)
            + ", long_open_cid="
            + self.long_open_cid
            + ", long_open_status="
            + str(self.long_open_status)
            + ", long_open_quantity="
            + str(self.long_open_quantity)
            + ", long_tp_cid="
            + self.long_tp_cid
            + ", long_tp_status="
            + str(self.long_tp_status)
            + ", long_sl_cid="
            + self.long_sl_cid
            + ", long_sl_status="
            + str(self.long_sl_status)
            + ", short_open_cid="
            + self.short_open_cid
            + ", short_open_status="
            + str(self.short_open_status)
            + ", short_open_quantity="
            + str(self.short_open_quantity)
            + ", short_tp_cid="
            + self.short_tp_cid
            + ", short_tp_status="
            + str(self.short_tp_status)
            + ", short_sl_cid="
            + self.short_sl_cid
            + ", short_sl_status="
            + str(self.short_sl_status)
            + ">"
        )


@value
struct GridInfo(Stringable):
    var grid_interval: Fixed
    var price_range: Fixed
    var tick_size: Fixed
    var base_price: Fixed
    var precision: Int
    var cells: list[GridCell]

    fn __init__(inout self):
        self.grid_interval = Fixed(0)
        self.price_range = Fixed(0)
        self.tick_size = Fixed(0)
        self.base_price = Fixed(0)
        self.precision = 0
        self.cells = list[GridCell]()

    fn setup(
        inout self,
        grid_interval: Fixed,
        price_range: Fixed,
        tick_size: Fixed,
        base_price: Fixed,
        precision: Int,
    ) raises:
        self.grid_interval = grid_interval
        self.price_range = price_range
        self.tick_size = tick_size
        self.base_price = base_price
        self.precision = precision
        self.cells.append(GridCell(0, base_price))
        self.update(base_price)

    fn update(inout self, current_price: Fixed) raises:
        let x = self.price_range + Fixed(1)
        let range_high = current_price * x
        let range_low = current_price / x

        if self.cells[0].price <= range_low and self.cells[-1].price >= range_high:
            return

        while self.cells[-1].price <= range_high:
            let level = self.cells[-1].level + 1
            let price = self.get_price_by_level(level)
            let cell = self.new_grid_cell(level, price)
            self.cells.append(cell)

        while self.cells[0].price >= range_low:
            let level = self.cells[0].level - 1
            let price = self.get_price_by_level(level)
            let cell = self.new_grid_cell(level, price)
            self.cells.insert(0, cell)

    fn get_price_by_level(self, level: Int) -> Fixed:
        let offset = level
        let price = math.pow(1.0 + self.grid_interval.to_float(), offset).cast[
            DType.float64
        ]() * self.base_price.to_float()
        let a = math.pow(Float64(10.0), self.precision)
        let rounded = math.round(price * a) / a
        return rounded

    fn get_cell_level_by_price(self, price: Fixed) -> Int:
        let offset = math.log(price.to_float() / self.base_price.to_float()) / math.log(
            1 + self.grid_interval.to_float()
        )
        return math.round(offset).to_int()

    fn new_grid_cell(self, level: Int, price: Fixed) -> GridCell:
        return GridCell(level, price)

    fn reset(inout self) raises:
        self.cells.clear()
        self.cells.append(self.new_grid_cell(0, self.base_price))
        self.update(self.base_price)

    fn __str__(self) -> String:
        var result: String = "["
        try:
            let n = len(self.cells)
            for i in range(n):
                let cell = self.cells[i]
                let repr = str(cell.level) + "," + str(cell.price)
                if i != n - 1:
                    result += repr + ", "
                else:
                    result += repr
        except e:
            pass
        return result + "]"
