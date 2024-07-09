from base.httpclient import (
    HttpClient,
    HttpResponse,
    seq_hmac_sha256,
    seq_base64_encode,
    QueryParams,
    Headers,
)

from base.c import *
from base.mo import *
import . okxconsts as c
from .okxconsts import GET, POST
from morrow.morrow import Morrow
from .sign import hmac_sha256_b64


fn get_timestamp() raises -> String:
    # var now = Morrow.now()
    var now = Morrow.utcnow()
    var t = now.isoformat("T", "milliseconds")
    # 2023-12-02T20:35:16.728Z
    # 2023-12-02T20:35:17.974+08:00Z
    return t + "Z"


fn pre_hash(
    timestamp: String,
    method: String,
    request_path: String,
    body: String,
    debug: Bool = True,
) -> String:
    if debug:
        print("body: ", body)
    # return timestamp + str.upper(method) + request_path + body
    return timestamp + method + request_path + body


fn get_header(
    api_key: String,
    sign: String,
    timestamp: String,
    passphrase: String,
    flag: String,
    debug: Bool = True,
) -> Headers:
    var headers = Headers()
    headers[c.CONTENT_TYPE] = c.APPLICATION_JSON
    headers[c.OK_ACCESS_KEY] = api_key
    headers[c.OK_ACCESS_SIGN] = sign
    headers[c.OK_ACCESS_TIMESTAMP] = timestamp
    headers[c.OK_ACCESS_PASSPHRASE] = passphrase
    headers["x-simulated-trading"] = flag
    # if debug:
    #     print('header: ', header)
    return headers^


fn get_header_no_sign(flag: String, debug: Bool = True) -> Headers:
    var headers = Headers()
    headers[c.CONTENT_TYPE] = c.APPLICATION_JSON
    headers["x-simulated-trading"] = flag
    # if debug:
    #     print('headers: ', headers)
    return headers^


struct OkxClient:
    """
    :doc https://www.okx.com/docs-v5/zh/#overview
    https://github.com/okxapi/python-okx/blob/master/okx/client.py
    """

    var API_KEY: String
    var API_SECRET_KEY: String
    var PASSPHRASE: String
    var flag: String
    var debug: Bool
    var client: HttpClient

    fn __init__(
        inout self,
        base_url: StringLiteral = c.API_URL,
        api_key: String = "",
        api_secret_key: String = "",
        passphrase: String = "",
        flag: StringLiteral = "0",
        debug: Bool = True,
    ) raises:
        self.API_KEY = api_key
        self.API_SECRET_KEY = api_secret_key
        self.PASSPHRASE = passphrase
        self.flag = flag
        self.debug = debug
        # super().__init__(base_url)
        self.client = HttpClient(base_url)

    # Get Positions
    fn get_position_risk(
        self, instType: StringLiteral = ""
    ) raises -> HttpResponse:
        var params = QueryParams()
        if instType:
            params["instType"] = instType
        return self._request_with_params(GET, c.POSITION_RISK, params)

    # Get Balance
    fn get_account_balance(
        self, ccy: StringLiteral = ""
    ) raises -> HttpResponse:
        var params = QueryParams()
        if ccy:
            params["ccy"] = ccy
        return self._request_with_params(GET, c.ACCOUNT_INFO, params)

    # Get Positions
    fn get_positions(
        self, instType: StringLiteral = "", instId: StringLiteral = ""
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instType"] = instType
        params["instId"] = instId
        return self._request_with_params(GET, c.POSITION_INFO, params)

    # Get Bills Details (recent 7 days)
    fn get_account_bills(
        self,
        instType: StringLiteral = "",
        ccy: StringLiteral = "",
        mgnMode: StringLiteral = "",
        ctType: StringLiteral = "",
        type_: StringLiteral = "",
        subType: StringLiteral = "",
        after: StringLiteral = "",
        before: StringLiteral = "",
        limit: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instType"] = instType
        params["ccy"] = ccy
        params["mgnMode"] = mgnMode
        params["ctType"] = ctType
        params["type"] = type_
        params["subType"] = subType
        params["after"] = after
        params["before"] = before
        params["limit"] = limit
        return self._request_with_params(GET, c.BILLS_DETAIL, params)

    # Get Bills Details (recent 3 months)
    fn get_account_bills_archive(
        self,
        instType: StringLiteral = "",
        ccy: StringLiteral = "",
        mgnMode: StringLiteral = "",
        ctType: StringLiteral = "",
        type_: StringLiteral = "",
        subType: StringLiteral = "",
        after: StringLiteral = "",
        before: StringLiteral = "",
        limit: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instType"] = instType
        params["ccy"] = ccy
        params["mgnMode"] = mgnMode
        params["ctType"] = ctType
        params["type"] = type_
        params["subType"] = subType
        params["after"] = after
        params["before"] = before
        params["limit"] = limit
        return self._request_with_params(GET, c.BILLS_ARCHIVE, params)

    # Get Account Configuration
    fn get_account_config(self) raises -> HttpResponse:
        return self._request_without_params(GET, c.ACCOUNT_CONFIG)

    # Get Account Configuration
    fn set_position_mode(self, posMode: StringLiteral) raises -> HttpResponse:
        var params = QueryParams()
        params["posMode"] = posMode
        return self._request_with_params(POST, c.POSITION_MODE, params)

    # Get Account Configuration
    fn set_leverage(
        self,
        lever: StringLiteral,
        mgnMode: StringLiteral,
        instId: StringLiteral = "",
        ccy: StringLiteral = "",
        posSide: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["lever"] = lever
        params["mgnMode"] = mgnMode
        params["instId"] = instId
        params["ccy"] = ccy
        params["posSide"] = posSide
        return self._request_with_params(POST, c.SET_LEVERAGE, params)

    # Get Maximum Tradable Size For Instrument
    fn get_max_order_size(
        self,
        instId: StringLiteral,
        tdMode: StringLiteral,
        ccy: StringLiteral = "",
        px: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instId"] = instId
        params["tdMode"] = tdMode
        params["ccy"] = ccy
        params["px"] = px
        return self._request_with_params(GET, c.MAX_TRADE_SIZE, params)

    # Get Maximum Available Tradable Amount
    fn get_max_avail_size(
        self,
        instId: StringLiteral,
        tdMode: StringLiteral,
        ccy: StringLiteral = "",
        reduceOnly: StringLiteral = "",
        unSpotOffset: StringLiteral = "",
        quickMgnType: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instId"] = instId
        params["tdMode"] = tdMode
        params["ccy"] = ccy
        params["reduceOnly"] = reduceOnly
        params["unSpotOffset"] = unSpotOffset
        params["quickMgnType"] = quickMgnType
        return self._request_with_params(GET, c.MAX_AVAIL_SIZE, params)

    # Increase / Decrease margin
    fn adjustment_margin(
        self,
        instId: StringLiteral,
        posSide: StringLiteral,
        type_: StringLiteral,
        amt: StringLiteral,
        loanTrans: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instId"] = instId
        params["posSide"] = posSide
        params["type"] = type_
        params["amt"] = amt
        params["loanTrans"] = loanTrans
        return self._request_with_params(POST, c.ADJUSTMENT_MARGIN, params)

    # Get Leverage
    fn get_leverage(
        self, instId: StringLiteral, mgnMode: StringLiteral
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instId"] = instId
        params["mgnMode"] = mgnMode
        return self._request_with_params(GET, c.GET_LEVERAGE, params)

    # Get the maximum loan of isolated MARGIN
    fn get_max_loan(
        self,
        instId: StringLiteral,
        mgnMode: StringLiteral,
        mgnCcy: StringLiteral,
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instId"] = instId
        params["mgnMode"] = mgnMode
        params["mgnCcy"] = mgnCcy
        return self._request_with_params(GET, c.MAX_LOAN, params)

    # Get Fee Rates
    fn get_fee_rates(
        self,
        instType: StringLiteral,
        instId: StringLiteral = "",
        uly: StringLiteral = "",
        category: StringLiteral = "",
        instFamily: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instType"] = instType
        params["instId"] = instId
        params["uly"] = uly
        params["category"] = category
        params["instFamily"] = instFamily
        return self._request_with_params(GET, c.FEE_RATES, params)

    # Get interest-accrued
    fn get_interest_accrued(
        self,
        instId: StringLiteral = "",
        ccy: StringLiteral = "",
        mgnMode: StringLiteral = "",
        after: StringLiteral = "",
        before: StringLiteral = "",
        limit: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instId"] = instId
        params["ccy"] = ccy
        params["mgnMode"] = mgnMode
        params["after"] = after
        params["before"] = before
        params["limit"] = limit
        return self._request_with_params(GET, c.INTEREST_ACCRUED, params)

    # Get interest-accrued
    fn get_interest_rate(self, ccy: StringLiteral = "") raises -> HttpResponse:
        var params = QueryParams()
        params["ccy"] = ccy
        return self._request_with_params(GET, c.INTEREST_RATE, params)

    # Set Greeks (PA/BS)
    fn set_greeks(self, greeksType: StringLiteral) raises -> HttpResponse:
        var params = QueryParams()
        params["greeksType"] = greeksType
        return self._request_with_params(POST, c.SET_GREEKS, params)

    # Set Isolated Mode
    fn set_isolated_mode(
        self, isoMode: StringLiteral, type_: StringLiteral
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["isoMode"] = isoMode
        params["type"] = type_
        return self._request_with_params(POST, c.ISOLATED_MODE, params)

    # Get Maximum Withdrawals
    fn get_max_withdrawal(self, ccy: StringLiteral = "") raises -> HttpResponse:
        var params = QueryParams()
        params["ccy"] = ccy
        return self._request_with_params(GET, c.MAX_WITHDRAWAL, params)

    # Get borrow repay
    fn borrow_repay(
        self,
        ccy: StringLiteral = "",
        side: StringLiteral = "",
        amt: StringLiteral = "",
        ordId: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["ccy"] = ccy
        params["side"] = side
        params["amt"] = amt
        params["ordId"] = ordId
        return self._request_with_params(POST, c.BORROW_REPAY, params)

    # Get borrow repay history
    fn get_borrow_repay_history(
        self,
        ccy: StringLiteral = "",
        after: StringLiteral = "",
        before: StringLiteral = "",
        limit: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["ccy"] = ccy
        params["after"] = after
        params["before"] = before
        params["limit"] = limit
        return self._request_with_params(GET, c.BORROW_REPAY_HISTORY, params)

    # Get Obtain borrowing rate and limit
    fn get_interest_limits(
        self, type_: StringLiteral = "", ccy: StringLiteral = ""
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["type"] = type_
        params["ccy"] = ccy
        return self._request_with_params(GET, c.INTEREST_LIMITS, params)

    # Get Simulated Margin
    fn get_simulated_margin(
        self,
        instType: StringLiteral = "",
        inclRealPos: Bool = True,
        spotOffsetType: StringLiteral = "",
        simPos: StringLiteral = "[]",
    ) raises -> HttpResponse:
        # todo:
        var params = QueryParams()
        params["instType"] = instType
        params["inclRealPos"] = "true"  # 'true' if inclRealPos 'false'
        params["spotOffsetType"] = spotOffsetType
        params["simPos"] = simPos
        return self._request_with_params(POST, c.SIMULATED_MARGIN, params)

    # Get  Greeks
    fn get_greeks(self, ccy: StringLiteral = "") raises -> HttpResponse:
        var params = QueryParams()
        params["ccy"] = ccy
        return self._request_with_params(GET, c.GREEKS, params)

    # GET /api/v5/account/risk-state
    fn get_account_position_risk(self) raises -> HttpResponse:
        return self._request_without_params(GET, c.ACCOUNT_RISK)

    # GET /api/v5/account/positions-history
    fn get_positions_history(
        self,
        instType: StringLiteral = "",
        instId: StringLiteral = "",
        mgnMode: StringLiteral = "",
        type_: StringLiteral = "",
        posId: StringLiteral = "",
        after: StringLiteral = "",
        before: StringLiteral = "",
        limit: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instType"] = instType
        params["instId"] = instId
        params["mgnMode"] = mgnMode
        params["type"] = type_
        params["posId"] = posId
        params["after"] = after
        params["before"] = before
        params["limit"] = limit
        return self._request_with_params(GET, c.POSITIONS_HISTORY, params)

    # GET /api/v5/account/position-tiers
    fn get_account_position_tiers(
        self,
        instType: StringLiteral = "",
        uly: StringLiteral = "",
        instFamily: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["instType"] = instType
        params["uly"] = uly
        params["instFamily"] = instFamily
        return self._request_with_params(GET, c.GET_PM_LIMIT, params)

    # - Get VIP interest accrued data
    fn get_VIP_interest_accrued_data(
        self,
        ccy: StringLiteral = "",
        ordId: StringLiteral = "",
        after: StringLiteral = "",
        before: StringLiteral = "",
        limit: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["ccy"] = ccy
        params["ordId"] = ordId
        params["after"] = after
        params["before"] = before
        params["limit"] = limit
        return self._request_with_params(
            GET, c.GET_VIP_INTEREST_ACCRUED_DATA, params
        )

    # - Get VIP interest deducted data
    fn get_VIP_interest_deducted_data(
        self,
        ccy: StringLiteral = "",
        ordId: StringLiteral = "",
        after: StringLiteral = "",
        before: StringLiteral = "",
        limit: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["ccy"] = ccy
        params["ordId"] = ordId
        params["after"] = after
        params["before"] = before
        params["limit"] = limit
        return self._request_with_params(
            GET, c.GET_VIP_INTEREST_DEDUCTED_DATA, params
        )

    # - Get VIP loan order list
    fn get_VIP_loan_order_list(
        self,
        ordId: StringLiteral = "",
        state: StringLiteral = "",
        ccy: StringLiteral = "",
        after: StringLiteral = "",
        before: StringLiteral = "",
        limit: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["ordId"] = ordId
        params["state"] = state
        params["ccy"] = ccy
        params["after"] = after
        params["before"] = before
        params["limit"] = limit
        return self._request_with_params(GET, c.GET_VIP_LOAN_ORDER_LIST, params)

    # - Get VIP loan order detail
    fn get_VIP_loan_order_detail(
        self,
        ccy: StringLiteral = "",
        ordId: StringLiteral = "",
        after: StringLiteral = "",
        before: StringLiteral = "",
        limit: StringLiteral = "",
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["ccy"] = ccy
        params["ordId"] = ordId
        params["after"] = after
        params["before"] = before
        params["limit"] = limit
        return self._request_with_params(
            GET, c.GET_VIP_LOAN_ORDER_DETAIL, params
        )

    # - Set risk offset type
    fn set_risk_offset_typel(
        self, type_: StringLiteral = ""
    ) raises -> HttpResponse:
        var params = QueryParams()
        params["type"] = type_
        return self._request_with_params(POST, c.SET_RISK_OFFSET_TYPE, params)

    # - Set auto loan
    fn set_auto_loan(self, autoLoan: StringLiteral = "") raises -> HttpResponse:
        var params = QueryParams()
        params["autoLoan"] = autoLoan
        return self._request_with_params(POST, c.SET_AUTO_LOAN, params)

    # - Activate option
    fn activate_option(self) raises -> HttpResponse:
        return self._request_without_params(POST, c.ACTIVSTE_OPTION)

    fn get_instruments(self, inst_type: StringLiteral) raises:
        """
        https://www.okx.com/docs-v5/zh/#public-data-rest-api-get-instruments
        "SWAP"
        """
        var path = "/api/v5/public/instruments"
        var param = QueryParams()
        param["instType"] = inst_type
        param["uly"] = "ETH-USDT"
        var res = self._request_with_params(c.GET, path, param, "")
        print("-----------------")
        print(res.status_code)
        # print(res.get[1, String]())
        var ss = res.text  # res.get[1, StringRef]()
        print(ss)

    fn _request(
        self,
        method: String,
        request_path: StringLiteral,
        params: QueryParams,
        body: StringLiteral,
    ) raises -> HttpResponse:
        var request_path_ = String(request_path)
        if method == c.GET:
            request_path_ += params.to_string()
        var timestamp = get_timestamp()
        # if self.use_server_time:
        #     timestamp = self._get_timestamp()
        # body = json.dumps(params) if method == c.POST else ""
        # body = params if method == c.POST else ""
        var headers: Headers
        if self.API_KEY != "":
            var pre_hash_str = pre_hash(
                timestamp, method, request_path_, body, self.debug
            )
            var sign_str = hmac_sha256_b64(
                pre_hash_str,
                self.API_SECRET_KEY,
            )
            if self.debug:
                logi("pre_hash_str=" + pre_hash_str)
                logi("request_path_=" + request_path_)
                logi("timestamp=" + timestamp)
                logi("sign_str=" + sign_str)
                logi("PASSPHRASE=" + self.PASSPHRASE)
            headers = get_header(
                self.API_KEY,
                sign_str,
                timestamp,
                self.PASSPHRASE,
                self.flag,
                self.debug,
            )
        else:
            headers = get_header_no_sign(self.flag, self.debug)
        # response = None
        # if self.debug == True:
        #     print('domain:',self.domain)
        #     print('url:',request_path)
        var response: HttpResponse
        if method == c.GET:
            response = self.client.get(request_path_, headers=headers)
        elif method == c.POST:
            response = self.client.post(
                request_path_, data=body, headers=headers
            )
        else:
            response = HttpResponse(200, StringRef(""))
        return response

    fn _request_without_params(
        self,
        method: StringLiteral,
        request_path: StringLiteral,
        body: StringLiteral = "",
    ) raises -> HttpResponse:
        return self._request(method, request_path, QueryParams(), body)

    fn _request_with_params(
        self,
        method: StringLiteral,
        request_path: StringLiteral,
        params: QueryParams,
        body: StringLiteral = "",
    ) raises -> HttpResponse:
        return self._request(method, request_path, params, body)

    # fn _get_timestamp(self) raises -> HttpResponse:
    #     request_path = c.API_URL + c.SERVER_TIMESTAMP_URL
    #     response = self.client.get(request_path)
    #     if response.status_code == 200:
    #         return response.json()['ts']
    #     else:
    #         return ""
