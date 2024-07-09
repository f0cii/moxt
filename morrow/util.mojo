from collections.vector import DynamicVector

from .constants import MAX_TIMESTAMP, MAX_TIMESTAMP_MS, MAX_TIMESTAMP_US
from .constants import _DAYS_IN_MONTH, _DAYS_BEFORE_MONTH


fn _is_leap(year: Int) -> Bool:
    "year -> 1 if leap year, else 0."
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)


fn _days_before_year(year: Int) -> Int:
    "year -> number of days before January 1st of year."
    var y = year - 1
    return y * 365 + y // 4 - y // 100 + y // 400


fn _days_in_month(year: Int, month: Int) -> Int:
    "year, month -> number of days in that month in that year."
    if month == 2 and _is_leap(year):
        return 29
    return _DAYS_IN_MONTH[month]


fn _days_before_month(year: Int, month: Int) -> Int:
    "year, month -> number of days in year preceding first day of month."
    if month > 2 and _is_leap(year):
        return _DAYS_BEFORE_MONTH[month] + 1
    return _DAYS_BEFORE_MONTH[month]


@always_inline
fn _ymd2ord(year: Int, month: Int, day: Int) -> Int:
    "year, month, day -> ordinal, considering 01-Jan-0001 as day 1."
    var dim = _days_in_month(year, month)
    return _days_before_year(year) + _days_before_month(year, month) + day


fn normalize_timestamp(timestamp: Float64) raises -> Float64:
    """Normalize millisecond and microsecond timestamps into normal timestamps.
    """
    var timestamp_ = timestamp
    if timestamp_ > MAX_TIMESTAMP:
        if timestamp_ < MAX_TIMESTAMP_MS:
            timestamp_ /= 1000
        elif timestamp_ < MAX_TIMESTAMP_US:
            timestamp_ /= 1_000_000
        else:
            raise Error(
                "The specified timestamp "
                + String(timestamp_)
                + "is too large."
            )
    return timestamp


fn _repeat_string(string: String, n: Int) -> String:
    var result: String = ""
    for _ in range(n):
        result += string
    return result


fn rjust(string: String, width: Int, fillchar: String = " ") -> String:
    var extra = width - len(string)
    return _repeat_string(fillchar, extra) + string


fn rjust(string: Int, width: Int, fillchar: String = " ") -> String:
    return rjust(String(string), width, fillchar)
