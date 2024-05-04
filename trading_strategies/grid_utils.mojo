import math
from ylstdlib import *
from collections.list import List
from base.fixed import Fixed
from base.mo import *
from trade.types import *

# from ylstdlib import MutLifetime, i1


fn append_string_to_list_if_not_empty(inout l: List[String], s: String):
    if s == "":
        return
    l.append(s)


@value
struct GridCellInfo(CollectionElement):
    var level: Int
    var price: Fixed

    var long_open_cid: String  # Order client ID
    var long_open_status: OrderStatus  # Order status
    var long_open_quantity: Fixed  # Quantity of open orders
    var long_entry_price: Fixed  # Entry price
    var long_filled_qty: Fixed  # Filled quantity
    var long_tp_cid: String  # Take-profit order Client ID
    var long_tp_status: OrderStatus  # Take-profit order status
    var long_sl_cid: String  # Stop-loss order Client ID
    var long_sl_status: OrderStatus  # Stop-loss order status

    var short_open_cid: String
    var short_open_status: OrderStatus
    var short_open_quantity: Fixed
    var short_entry_price: Fixed
    var short_filled_qty: Fixed
    var short_tp_cid: String
    var short_tp_status: OrderStatus
    var short_sl_cid: String
    var short_sl_status: OrderStatus

    fn __init__(inout self, level: Int, price: Fixed):
        self.level = level
        self.price = price

        self.long_open_cid = ""
        self.long_open_status = OrderStatus.empty
        self.long_open_quantity = Fixed.zero
        self.long_entry_price = Fixed.zero
        self.long_filled_qty = Fixed.zero
        self.long_tp_cid = ""
        self.long_tp_status = OrderStatus.empty
        self.long_sl_cid = ""
        self.long_sl_status = OrderStatus.empty

        self.short_open_cid = ""
        self.short_open_status = OrderStatus.empty
        self.short_open_quantity = Fixed.zero
        self.short_entry_price = Fixed.zero
        self.short_filled_qty = Fixed.zero
        self.short_tp_cid = ""
        self.short_tp_status = OrderStatus.empty
        self.short_sl_cid = ""
        self.short_sl_status = OrderStatus.empty

    fn reset_long_side(inout self) -> List[String]:
        var cid_list = List[String]()

        append_string_to_list_if_not_empty(cid_list, self.long_open_cid)
        append_string_to_list_if_not_empty(cid_list, self.long_tp_cid)
        append_string_to_list_if_not_empty(cid_list, self.long_sl_cid)

        self.long_open_cid = ""
        self.long_open_status = OrderStatus.empty
        self.long_open_quantity = Fixed.zero
        self.long_entry_price = Fixed.zero
        self.long_filled_qty = Fixed.zero
        self.long_tp_cid = ""
        self.long_tp_status = OrderStatus.empty
        self.long_sl_cid = ""
        self.long_sl_status = OrderStatus.empty

        return cid_list

    fn reset_short_side(inout self) -> List[String]:
        var cid_list = List[String]()

        append_string_to_list_if_not_empty(cid_list, self.short_open_cid)
        append_string_to_list_if_not_empty(cid_list, self.short_tp_cid)
        append_string_to_list_if_not_empty(cid_list, self.short_sl_cid)

        self.short_open_cid = ""
        self.short_open_status = OrderStatus.empty
        self.short_open_quantity = Fixed.zero
        self.short_entry_price = Fixed.zero
        self.short_filled_qty = Fixed.zero
        self.short_tp_cid = ""
        self.short_tp_status = OrderStatus.empty
        self.short_sl_cid = ""
        self.short_sl_status = OrderStatus.empty

        return cid_list

    fn calculate_profit_percentage(
        self, ask: Fixed, bid: Fixed, position_idx: PositionIdx
    ) -> Fixed:
        """
        Calculate profit margin
        """
        # Calculate floating profit using entry price
        var entry_price = Fixed.zero
        var entry_quantity = Fixed.zero
        var profit = Fixed(0.0)
        if position_idx == PositionIdx.both_side_buy:
            entry_price = self.long_entry_price
            entry_quantity = self.long_open_quantity
            var current_price = ask
            profit = (current_price - entry_price) * entry_quantity
        else:
            entry_price = self.short_entry_price
            entry_quantity = self.short_open_quantity
            var current_price = bid
            profit = (entry_price - current_price) * entry_quantity

        var entry_value = entry_price * entry_quantity
        if entry_price.is_zero():
            return 0.0

        var profit_percentage = profit / entry_value
        return profit_percentage

    fn calculate_profit_amount(
        self, ask: Fixed, bid: Fixed, position_idx: PositionIdx
    ) -> Float64:
        """
        Calculate profit amount
        """
        # Calculate floating profit using entry price
        var entry_price = Fixed.zero
        var entry_quantity = Fixed.zero
        var profit = Float64(0.0)
        if position_idx == PositionIdx.both_side_buy:
            entry_price = self.long_entry_price
            entry_quantity = self.long_open_quantity
            var current_price = ask
            profit = (
                current_price.to_float() - entry_price.to_float()
            ) * entry_quantity.to_float()
        else:
            entry_price = self.short_entry_price
            entry_quantity = self.short_open_quantity
            var current_price = bid
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
    var cells: List[GridCellInfo]

    fn __init__(inout self):
        self.grid_interval = Fixed.zero
        self.price_range = Fixed.zero
        self.tick_size = Fixed.zero
        self.base_price = Fixed.zero
        self.precision = 0
        self.cells = List[GridCellInfo](capacity=8)

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
        var x = self.price_range + Fixed(1)
        var range_high = current_price * x
        var range_low = current_price / x

        if (
            self.cells[0].price <= range_low
            and self.cells[-1].price >= range_high
        ):
            return

        while self.cells[-1].price <= range_high:
            var level = self.cells[-1].level + 1
            var price = self.get_price_by_level(level)
            var cell = self.new_grid_cell(level, price)
            self.cells.append(cell)

        while self.cells[0].price >= range_low:
            var level = self.cells[0].level - 1
            var price = self.get_price_by_level(level)
            var cell = self.new_grid_cell(level, price)
            self.cells.insert(0, cell)

    fn get_price_by_level(self, level: Int) -> Fixed:
        var offset = level
        var price = math.pow(1.0 + self.grid_interval.to_float(), offset).cast[
            DType.float64
        ]() * self.base_price.to_float()
        # var a = math.pow(Float64(10.0), self.precision)
        # var rounded = math.round(price * a) / a
        return Fixed(price).round(self.precision)

    fn get_cell_level_by_price(self, price: Fixed) -> Int:
        var offset = math.log(
            price.to_float() / self.base_price.to_float()
        ) / math.log(1 + self.grid_interval.to_float())
        return int(math.round(offset))

    fn new_grid_cell(self, level: Int, price: Fixed) -> GridCellInfo:
        return GridCellInfo(level, price)

    fn reset(inout self) raises:
        self.cells.clear()
        self.cells.append(self.new_grid_cell(0, self.base_price))
        self.update(self.base_price)

    # fn cell_mut_ref[
    #     L: MutLifetime
    # ](inout self, i: Int) -> Reference[GridCellInfo, i1, L]:
    #     """Gets a reference to the list element at the given index.

    #     Args:
    #         i: The index of the element.

    #     Returns:
    #         An mutability reference to the element at the given index.
    #     """
    #     var normalized_idx = i
    #     if i < 0:
    #         normalized_idx += Reference(self.cells)[].size

    #     # Mutability gets set to the local mutability of this
    #     # pointer value, ie. because we defined it with `let` it's now an
    #     # "immutable" reference regardless of the mutability of `self`.
    #     # This means we can't just use `UnsafePointer.__refitem__` here
    #     # because the mutability won't match.
    #     var base_ptr = Reference(self.cells)[].data
    #     return __mlir_op.`lit.ref.from_pointer`[
    #         _type = Reference[GridCellInfo, i1, L]._mlir_type
    #     ]((base_ptr + normalized_idx).value)

    fn __str__(self) -> String:
        var result: String = "["
        var n = len(self.cells)
        for i in range(n):
            var cell = self.cells[i]
            var repr = str(cell.level) + "," + str(cell.price)
            if i != n - 1:
                result += repr + ", "
            else:
                result += repr
        return result + "]"
