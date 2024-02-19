from base.fixed import Fixed
from base.moutil import time_ms
from base.mo import *


struct LocalPosition:
    """
    Virtual position management
    """

    var open_time_ms: Int
    var qty: Fixed
    var avg_price: Fixed

    fn __init__(inout self):
        self.open_time_ms = 0
        self.qty = Fixed.zero
        self.avg_price = Fixed.zero

    fn reset(inout self):
        self.open_time_ms = 0
        self.qty = Fixed.zero
        self.avg_price = Fixed.zero

    fn add(inout self, qty: Fixed, price: Fixed) raises:
        if qty < Fixed.zero or price.is_zero():
            raise Error("[Position.add] parameter error")

        if self.open_time_ms == 0:
            self.open_time_ms = int(time_ms())

        if self.qty.is_zero():
            self.qty = qty
            self.avg_price = price
            self.log_position_change()
            return

        let origin_qty = self.qty
        let origin_avg_price = self.avg_price

        let total_new = qty * price
        let total_original = origin_qty * origin_avg_price
        let total = total_new + total_original
        let total_qty = self.qty + qty

        self.qty = total_qty
        self.avg_price = total / total_qty
        self.log_position_change()

    fn reduce(inout self, qty: Fixed, price: Fixed) raises:
        if qty < Fixed.zero or price.is_zero():
            raise Error("[Position.reduce] parameter error")

        if self.qty.is_zero() or qty > self.qty:
            raise Error("[Position.reduce] insufficient quantity")

        let origin_qty = self.qty
        let origin_avg_price = self.avg_price

        let total_original = origin_qty * origin_avg_price
        let total_reduce = qty * price
        let total_qty = self.qty - qty

        if total_qty.is_zero():
            self.reset()
        else:
            let total_remaining = total_original - total_reduce
            self.qty = total_qty
            self.avg_price = total_remaining / total_qty

        self.log_position_change()

    fn log_position_change(self):
        logi("Change in position " + str(self.qty) + " @ " + str(self.avg_price))
