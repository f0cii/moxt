fn format_float(f: Float64, dec_places: Int) -> String:
    # get input number as a string
    let f_str = String(f)
    # use position of the decimal point to determine the number of decimal places
    let int_places = f_str.find(".")
    # build a multiplier to shift the digits before the decimal point
    let mult = 10 ** (dec_places + 1)
    # note the use of an extra power of 10 to get the rounding digit
    # use the multiplier build the integer value of the input number
    let i = Float64(f * mult).cast[DType.int64]().to_int()
    # get the integer value as a string
    let i_str_full = String(i)
    # grab the last digit to be used to adjust/leave the previous digit
    let last_digit = i_str_full[len(i_str_full) - 1]
    # grab the last but one digit in the integer string
    let prev_digit_pos = len(i_str_full) - 1
    var prev_digit = i_str_full[prev_digit_pos - 1]
    # if last digit is >= to 5 then we...
    if ord(last_digit) >= ord(5):
        # ... increment it by 1
        prev_digit = chr(ord(prev_digit) + 1)
    # isolate the unchanging part of integer string
    var i_str_less_2 = i_str_full[0 : len(i_str_full) - 2]
    # grab the integer part of the output float string
    let i_str_int = i_str_full[0:int_places]
    # chop the integer part from the unchanging part of the number
    i_str_less_2 = i_str_less_2[int_places : len(i_str_less_2)]
    # build the output float string
    let i_str_out = i_str_int + "." + i_str_less_2 + prev_digit
    return i_str_out
