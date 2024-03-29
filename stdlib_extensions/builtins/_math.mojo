fn divmod(a: Int, b: Int) -> Tuple[Int, Int]:
    return a // b, a % b


fn divmod(a: Int64, b: Int64) -> Tuple[Int64, Int64]:
    return a // b, a % b


fn round(number: Float64) -> Int:
    var floor = number // 1
    var remainder = number - floor
    if remainder > 0.5:
        return int(floor + 1)
    elif remainder < 0.5:
        return int(floor)
    else:
        # rounding to the nearest even number
        if floor % 2 == 0:
            return int(floor)
        else:
            return int(floor + 1)


fn abs(number: Float64) -> Float64:
    if number < 0:
        return -number
    else:
        return number


fn abs(number: Float32) -> Float32:
    if number < 0:
        return -number
    else:
        return number


fn abs(number: Int) -> Int:
    if number < 0:
        return -number
    else:
        return number
