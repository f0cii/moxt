import math
from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr
from base.fixed import Fixed


struct OrderType:
    alias BUY = "BUY"
    alias SELL = "SELL"


struct OrderStatus:
    alias PENDING = "PENDING"
    alias FILLED = "FILLED"
    alias CANCELLED = "CANCELLED"


@value
struct Order:
    var type: String
    var client_order_id: String
    var order_id: String
    var price: Fixed
    var quantity: Fixed
    var filled_qty: Fixed
    var status: String

    fn __init__(inout self):
        self.type = ""
        self.client_order_id = ""
        self.order_id = ""
        self.price = Fixed(0)
        self.quantity = Fixed(0)
        self.filled_qty = Fixed(0)
        self.status = ""


@value
struct GridCell(CollectionElement):
    var level: Int
    var price: Fixed
    var open_cid_l: String
    var close_cid_l: String

    fn __init__(inout self, level: Int, price: Fixed):
        self.level = level
        self.price = price
        self.open_cid_l = ""
        self.close_cid_l = ""


struct GridInfo:
    var grid_interval: Fixed
    var price_range: Fixed
    var tick_size: Fixed
    var base_price: Fixed
    var precision: Int
    var cells: list[GridCell]

    fn __init__(
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
        self.cells = list[GridCell]()
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
            let price = self.get_price_at_level(level)
            let cell = self.new_grid_cell(level, price)
            self.cells.append(cell)

        while self.cells[0].price >= range_low:
            let level = self.cells[0].level - 1
            let price = self.get_price_at_level(level)
            let cell = self.new_grid_cell(level, price)
            self.cells.insert(0, cell)

    fn get_price_at_level(self, level: Int) -> Fixed:
        let offset = level
        let price = math.pow(1.0 + self.grid_interval.to_float(), offset).cast[
            DType.float64
        ]() * self.base_price.to_float()
        let a = math.pow(Float64(10.0), self.precision)
        let rounded = math.round(price * a) / a
        return rounded

    fn get_cell_at_price(self, price: Fixed) -> Int:
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

    fn debug(self) raises:
        for i in range(len(self.cells)):
            print(i, self.cells[i].level, self.cells[i].price)
