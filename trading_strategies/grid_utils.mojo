import math
from stdlib_extensions.builtins import dict, list, HashableInt, HashableStr
from base.fixed import Fixed
from base.mo import *
from trade.types import *


fn append_string_to_list_if_not_empty(inout l: list[String], s: String):
    if s == "":
        return
    l.append(s)


@value
struct GridCellInfo(CollectionElement, Stringable):
    var level: Int
    var price: Fixed

    var long_open_cid: String  # 订单Client Id
    var long_open_status: OrderStatus  # 订单状态
    var long_open_quantity: Fixed  # 挂单数量
    var long_entry_price: Fixed  # 入场价格记录
    var long_tp_cid: String  # 止盈单Client Id
    var long_tp_status: OrderStatus  # 止盈单状态
    var long_sl_cid: String  # 止损单Client Id
    var long_sl_status: OrderStatus  # 止损单状态

    var short_open_cid: String
    var short_open_status: OrderStatus
    var short_open_quantity: Fixed
    var short_entry_price: Fixed
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
        self.long_entry_price = Fixed(0)
        self.long_tp_cid = ""
        self.long_tp_status = OrderStatus.empty
        self.long_sl_cid = ""
        self.long_sl_status = OrderStatus.empty

        self.short_open_cid = ""
        self.short_open_status = OrderStatus.empty
        self.short_open_quantity = Fixed(0)
        self.short_entry_price = Fixed(0)
        self.short_tp_cid = ""
        self.short_tp_status = OrderStatus.empty
        self.short_sl_cid = ""
        self.short_sl_status = OrderStatus.empty

    fn reset_long_side(inout self) -> list[String]:
        var cid_list = list[String]()

        append_string_to_list_if_not_empty(cid_list, self.long_open_cid)
        append_string_to_list_if_not_empty(cid_list, self.long_tp_cid)
        append_string_to_list_if_not_empty(cid_list, self.long_sl_cid)

        self.long_open_cid = ""
        self.long_open_status = OrderStatus.empty
        self.long_open_quantity = Fixed(0)
        self.long_entry_price = Fixed(0)
        self.long_tp_cid = ""
        self.long_tp_status = OrderStatus.empty
        self.long_sl_cid = ""
        self.long_sl_status = OrderStatus.empty

        return cid_list

    fn reset_short_side(inout self) -> list[String]:
        var cid_list = list[String]()

        append_string_to_list_if_not_empty(cid_list, self.short_open_cid)
        append_string_to_list_if_not_empty(cid_list, self.short_tp_cid)
        append_string_to_list_if_not_empty(cid_list, self.short_sl_cid)

        self.short_open_cid = ""
        self.short_open_status = OrderStatus.empty
        self.short_open_quantity = Fixed(0)
        self.short_entry_price = Fixed(0)
        self.short_tp_cid = ""
        self.short_tp_status = OrderStatus.empty
        self.short_sl_cid = ""
        self.short_sl_status = OrderStatus.empty

        return cid_list

    fn set_long_open_cid(inout self, cid: String):
        self.long_open_cid = cid

    fn set_long_open_status(inout self, status: OrderStatus):
        self.long_open_status = status

    fn set_long_open_quantity(inout self, new_quantity: Fixed):
        self.long_open_quantity = new_quantity

    fn set_long_entry_price(inout self, price: Fixed):
        self.long_entry_price = price

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

    fn set_short_entry_price(inout self, price: Fixed):
        self.short_entry_price = price

    fn set_short_tp_cid(inout self, cid: String):
        self.short_tp_cid = cid

    fn set_short_tp_status(inout self, status: OrderStatus):
        self.short_tp_status = status

    fn set_short_sl_cid(inout self, cid: String):
        self.short_sl_cid = cid

    fn set_short_sl_status(inout self, status: OrderStatus):
        self.short_sl_status = status

    fn calculate_profit_percentage(
        self, ask: Fixed, bid: Fixed, position_idx: PositionIdx
    ) -> Float64:
        """
        计算盈利率
        """
        # 使用入场价格计算浮动盈利
        var entry_price = Fixed(0)
        var entry_quantity = Fixed(0)
        var profit = Float64(0.0)
        if position_idx == PositionIdx.both_side_buy:
            entry_price = self.long_entry_price
            entry_quantity = self.long_open_quantity
            let current_price = ask
            profit = (
                current_price.to_float() - entry_price.to_float()
            ) * entry_quantity.to_float()
        else:
            entry_price = self.short_entry_price
            entry_quantity = self.short_open_quantity
            let current_price = bid
            profit = (
                entry_price.to_float() - current_price.to_float()
            ) * entry_quantity.to_float()

        let entry_value = entry_price * entry_quantity
        if entry_price.is_zero():
            return 0.0

        let profit_percentage = profit / entry_value.to_float()
        return profit_percentage

    fn calculate_profit_amount(
        self, ask: Fixed, bid: Fixed, position_idx: PositionIdx
    ) -> Float64:
        """
        计算盈利额
        """
        # 使用入场价格计算浮动盈利
        var entry_price = Fixed(0)
        var entry_quantity = Fixed(0)
        var profit = Float64(0.0)
        if position_idx == PositionIdx.both_side_buy:
            entry_price = self.long_entry_price
            entry_quantity = self.long_open_quantity
            let current_price = ask            
            profit = (
                current_price.to_float() - entry_price.to_float()
            ) * entry_quantity.to_float()
        else:
            entry_price = self.short_entry_price
            entry_quantity = self.short_open_quantity
            let current_price = bid
            profit = (
                entry_price.to_float() - current_price.to_float()
            ) * entry_quantity.to_float()

        return profit

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
    var cells: list[GridCellInfo]

    fn __init__(inout self):
        self.grid_interval = Fixed(0)
        self.price_range = Fixed(0)
        self.tick_size = Fixed(0)
        self.base_price = Fixed(0)
        self.precision = 0
        self.cells = list[GridCellInfo]()

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
        self.cells.append(GridCellInfo(0, base_price))
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

    fn new_grid_cell(self, level: Int, price: Fixed) -> GridCellInfo:
        return GridCellInfo(level, price)

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
