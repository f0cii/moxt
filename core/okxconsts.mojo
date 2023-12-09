# http header
alias API_URL = "https://www.okx.com"

alias CONTENT_TYPE = "Content-Type"
alias OK_ACCESS_KEY = "OK-ACCESS-KEY"
alias OK_ACCESS_SIGN = "OK-ACCESS-SIGN"
alias OK_ACCESS_TIMESTAMP = "OK-ACCESS-TIMESTAMP"
alias OK_ACCESS_PASSPHRASE = "OK-ACCESS-PASSPHRASE"

alias ACEEPT = "Accept"
alias COOKIE = "Cookie"
alias LOCALE = "Locale="

alias APPLICATION_JSON = "application/json"

alias GET = "GET"
alias POST = "POST"

alias SERVER_TIMESTAMP_URL = "/api/v5/public/time"

# account-complete-testcomplete
alias POSITION_RISK = "/api/v5/account/account-position-risk"
alias ACCOUNT_INFO = "/api/v5/account/balance"
alias POSITION_INFO = "/api/v5/account/positions"
alias BILLS_DETAIL = "/api/v5/account/bills"
alias BILLS_ARCHIVE = "/api/v5/account/bills-archive"
alias ACCOUNT_CONFIG = "/api/v5/account/config"
alias POSITION_MODE = "/api/v5/account/set-position-mode"
alias SET_LEVERAGE = "/api/v5/account/set-leverage"
alias MAX_TRADE_SIZE = "/api/v5/account/max-size"
alias MAX_AVAIL_SIZE = "/api/v5/account/max-avail-size"
alias ADJUSTMENT_MARGIN = "/api/v5/account/position/margin-balance"
alias GET_LEVERAGE = "/api/v5/account/leverage-info"
alias MAX_LOAN = "/api/v5/account/max-loan"
alias FEE_RATES = "/api/v5/account/trade-fee"
alias INTEREST_ACCRUED = "/api/v5/account/interest-accrued"
alias INTEREST_RATE = "/api/v5/account/interest-rate"
alias SET_GREEKS = "/api/v5/account/set-greeks"
alias ISOLATED_MODE = "/api/v5/account/set-isolated-mode"
alias MAX_WITHDRAWAL = "/api/v5/account/max-withdrawal"
alias ACCOUNT_RISK = "/api/v5/account/risk-state"  # need add
alias BORROW_REPAY = "/api/v5/account/borrow-repay"
alias BORROW_REPAY_HISTORY = "/api/v5/account/borrow-repay-history"
alias INTEREST_LIMITS = "/api/v5/account/interest-limits"
alias SIMULATED_MARGIN = "/api/v5/account/simulated_margin"
alias GREEKS = "/api/v5/account/greeks"
alias POSITIONS_HISTORY = "/api/v5/account/positions-history"  # need add
alias GET_PM_LIMIT = "/api/v5/account/position-tiers"  # need add
alias GET_VIP_INTEREST_ACCRUED_DATA = "/api/v5/account/vip-interest-accrued"
alias GET_VIP_INTEREST_DEDUCTED_DATA = "/api/v5/account/vip-interest-deducted"
alias GET_VIP_LOAN_ORDER_LIST = "/api/v5/account/vip-loan-order-list"
alias GET_VIP_LOAN_ORDER_DETAIL = "/api/v5/account/vip-loan-order-detail"
alias SET_RISK_OFFSET_TYPE = "/api/v5/account/set-riskOffset-type"
alias SET_AUTO_LOAN = "/api/v5/account/set-auto-loan"
alias ACTIVSTE_OPTION = "/api/v5/account/activate-option"

# funding-complete-testcomplete
alias DEPOSIT_ADDRESS = "/api/v5/asset/deposit-address"
alias GET_BALANCES = "/api/v5/asset/balances"
alias FUNDS_TRANSFER = "/api/v5/asset/transfer"
alias TRANSFER_STATE = "/api/v5/asset/transfer-state"
alias WITHDRAWAL_COIN = "/api/v5/asset/withdrawal"
alias DEPOSIT_HISTORIY = "/api/v5/asset/deposit-history"
alias CURRENCY_INFO = "/api/v5/asset/currencies"
alias PURCHASE_REDEMPT = "/api/v5/asset/purchase_redempt"
alias BILLS_INFO = "/api/v5/asset/bills"
alias DEPOSIT_LIGHTNING = "/api/v5/asset/deposit-lightning"
alias WITHDRAWAL_LIGHTNING = "/api/v5/asset/withdrawal-lightning"
alias CANCEL_WITHDRAWAL = "/api/v5/asset/cancel-withdrawal"  # need add
alias WITHDRAWAL_HISTORIY = "/api/v5/asset/withdrawal-history"
alias CONVERT_DUST_ASSETS = "/api/v5/asset/convert-dust-assets"  # need add
alias ASSET_VALUATION = "/api/v5/asset/asset-valuation"  # need add
alias SET_LENDING_RATE = "/api/v5/asset/set-lending-rate"
alias LENDING_HISTORY = "/api/v5/asset/lending-history"
alias LENDING_RATE_HISTORY = "/api/v5/asset/lending-rate-history"
alias LENDING_RATE_SUMMARY = "/api/v5/asset/lending-rate-summary"
alias GET_SAVING_BALANCE = "/api/v5/asset/saving-balance"  # need to add
alias GET_WITHDRAWAL_HISTORY = "/api/v5/asset/withdrawal-history"
alias GET_NON_TRADABLE_ASSETS = "/api/v5/asset/non-tradable-assets"
alias GET_DEPOSIT_WITHDrAW_STATUS = "/api/v5/asset/deposit-withdraw-status"


# Market Data-Complete-testComplete
alias TICKERS_INFO = "/api/v5/market/tickers"
alias TICKER_INFO = "/api/v5/market/ticker"
alias INDEX_TICKERS = "/api/v5/market/index-tickers"
alias ORDER_BOOKS = "/api/v5/market/books"
alias MARKET_CANDLES = "/api/v5/market/candles"
alias HISTORY_CANDLES = "/api/v5/market/history-candles"
alias INDEX_CANSLES = "/api/v5/market/index-candles"
alias MARKPRICE_CANDLES = "/api/v5/market/mark-price-candles"
alias MARKET_TRADES = "/api/v5/market/trades"
alias VOLUMNE = "/api/v5/market/platform-24-volume"
alias ORACLE = "/api/v5/market/open-oracle"  # need to update? if it is open oracle
alias INDEX_COMPONENTS = "/api/v5/market/index-components"  # need to add
alias EXCHANGE_RATE = "/api/v5/market/exchange-rate"  # need to add
alias HISTORY_TRADES = "/api/v5/market/history-trades"  # need to add
alias BLOCK_TICKERS = "/api/v5/market/block-tickers"  # need to add
alias BLOCK_TICKER = "/api/v5/market/block-ticker"  # need to add
alias BLOCK_TRADES = "/api/v5/market/block-trades"  # need to add
alias GET_ORDER_LITE_BOOK = "/api/v5/market/books-lite"
alias GET_OPTION_INSTRUMENT_FAMILY_TRADES = "/api/v5/market/option/instrument-family-trades"

# Public Data-Complete-testComplete
alias INSTRUMENT_INFO = "/api/v5/public/instruments"
alias DELIVERY_EXERCISE = "/api/v5/public/delivery-exercise-history"
alias OPEN_INTEREST = "/api/v5/public/open-interest"
alias FUNDING_RATE = "/api/v5/public/funding-rate"
alias FUNDING_RATE_HISTORY = "/api/v5/public/funding-rate-history"
alias PRICE_LIMIT = "/api/v5/public/price-limit"
alias OPT_SUMMARY = "/api/v5/public/opt-summary"
alias ESTIMATED_PRICE = "/api/v5/public/estimated-price"
alias DICCOUNT_INTETEST_INFO = "/api/v5/public/discount-rate-interest-free-quota"
alias SYSTEM_TIME = "/api/v5/public/time"
alias LIQUIDATION_ORDERS = "/api/v5/public/liquidation-orders"
alias MARK_PRICE = "/api/v5/public/mark-price"
alias TIER = "/api/v5/public/position-tiers"
alias INTEREST_LOAN = "/api/v5/public/interest-rate-loan-quota"  # need to add
alias UNDERLYING = "/api/v5/public/underlying"  # need to add
alias VIP_INTEREST_RATE_LOAN_QUOTA = "/api/v5/public/vip-interest-rate-loan-quota"  # need to add
alias INSURANCE_FUND = "/api/v5/public/insurance-fund"  # need to add
alias CONVERT_CONTRACT_COIN = "/api/v5/public/convert-contract-coin"  # need to add
alias GET_OPTION_TICKBANDS = "/api/v5/public/instrument-tick-bands"
alias GET_OPTION_TRADES = "/api/v5/public/option-trades"

# TRADING DATA-COMPLETE
alias SUPPORT_COIN = "/api/v5/rubik/stat/trading-data/support-coin"
alias TAKER_VOLUME = "/api/v5/rubik/stat/taker-volume"
alias MARGIN_LENDING_RATIO = "/api/v5/rubik/stat/margin/loan-ratio"
alias LONG_SHORT_RATIO = "/api/v5/rubik/stat/contracts/long-short-account-ratio"
alias CONTRACTS_INTEREST_VOLUME = "/api/v5/rubik/stat/contracts/open-interest-volume"
alias OPTIONS_INTEREST_VOLUME = "/api/v5/rubik/stat/option/open-interest-volume"
alias PUT_CALL_RATIO = "/api/v5/rubik/stat/option/open-interest-volume-ratio"
alias OPEN_INTEREST_VOLUME_EXPIRY = "/api/v5/rubik/stat/option/open-interest-volume-expiry"
alias INTEREST_VOLUME_STRIKE = "/api/v5/rubik/stat/option/open-interest-volume-strike"
alias TAKER_FLOW = "/api/v5/rubik/stat/option/taker-block-volume"

# TRADE-Complete
alias PLACR_ORDER = "/api/v5/trade/order"
alias BATCH_ORDERS = "/api/v5/trade/batch-orders"
alias CANAEL_ORDER = "/api/v5/trade/cancel-order"
alias CANAEL_BATCH_ORDERS = "/api/v5/trade/cancel-batch-orders"
alias AMEND_ORDER = "/api/v5/trade/amend-order"
alias AMEND_BATCH_ORDER = "/api/v5/trade/amend-batch-orders"
alias CLOSE_POSITION = "/api/v5/trade/close-position"
alias ORDER_INFO = "/api/v5/trade/order"
alias ORDERS_PENDING = "/api/v5/trade/orders-pending"
alias ORDERS_HISTORY = "/api/v5/trade/orders-history"
alias ORDERS_HISTORY_ARCHIVE = "/api/v5/trade/orders-history-archive"
alias ORDER_FILLS = "/api/v5/trade/fills"
alias ORDERS_FILLS_HISTORY = "/api/v5/trade/fills-history"
alias PLACE_ALGO_ORDER = "/api/v5/trade/order-algo"
alias CANCEL_ALGOS = "/api/v5/trade/cancel-algos"
alias Cancel_Advance_Algos = "/api/v5/trade/cancel-advance-algos"
alias ORDERS_ALGO_OENDING = "/api/v5/trade/orders-algo-pending"
alias ORDERS_ALGO_HISTORY = "/api/v5/trade/orders-algo-history"
alias GET_ALGO_ORDER_DETAILS = "/api/v5/trade/order-algo"
alias AMEND_ALGO_ORDER = "/api/v5/trade/amend-algos"

alias EASY_CONVERT_CURRENCY_LIST = "/api/v5/trade/easy-convert-currency-list"
alias EASY_CONVERT = "/api/v5/trade/easy-convert"
alias CONVERT_EASY_HISTORY = "/api/v5/trade/easy-convert-history"
alias ONE_CLICK_REPAY_SUPPORT = "/api/v5/trade/one-click-repay-currency-list"
alias ONE_CLICK_REPAY = "/api/v5/trade/one-click-repay"
alias ONE_CLICK_REPAY_HISTORY = "/api/v5/trade/one-click-repay-history"

# SubAccount-complete-testwriteComplete
alias BALANCE = "/api/v5/account/subaccount/balances"
alias BILLs = "/api/v5/asset/subaccount/bills"
alias RESET = "/api/v5/users/subaccount/modify-apikey"
alias VIEW_LIST = "/api/v5/users/subaccount/list"
alias SUBACCOUNT_TRANSFER = "/api/v5/asset/subaccount/transfer"
alias ENTRUST_SUBACCOUNT_LIST = "/api/v5/users/entrust-subaccount-list"  # need to add
alias SET_TRSNSFER_OUT = "/api/v5/users/subaccount/set-transfer-out"  # need to add
alias GET_ASSET_SUBACCOUNT_BALANCE = "/api/v5/asset/subaccount/balances"  # need to add
alias GET_THE_USER_AFFILIATE_REBATE = "/api/v5/users/partner/if-rebate"
alias SET_SUB_ACCOUNTS_VIP_LOAN = "/api/v5/account/subaccount/set-loan-allocation"
alias GET_SUB_ACCOUNT_BORROW_INTEREST_AND_LIMIT = "/api/v5/account/subaccount/interest-limits"

# Broker-all need to implmented-completed
alias BROKER_INFO = "/api/v5/broker/nd/info"
alias CREATE_SUBACCOUNT = "/api/v5/broker/nd/create-subaccount"
alias DELETE_SUBACCOUNT = "/api/v5/broker/nd/delete-subaccount"
alias SUBACCOUNT_INFO = "/api/v5/broker/nd/subaccount-info"
alias SET_SUBACCOUNT_LEVEL = "/api/v5/broker/nd/set-subaccount-level"
alias SET_SUBACCOUNT_FEE_REAT = "/api/v5/broker/nd/set-subaccount-fee-rate"
alias SUBACCOUNT_DEPOSIT_ADDRESS = "/api/v5/asset/broker/nd/subaccount-deposit-address"
alias SUBACCOUNT_DEPOSIT_HISTORY = "/api/v5/asset/broker/nd/subaccount-deposit-history"
alias REBATE_DAILY = "/api/v5/broker/nd/rebate-daily"
alias ND_CREAET_APIKEY = "/api/v5/broker/nd/subaccount/apikey"
alias ND_SELECT_APIKEY = "/api/v5/broker/nd/subaccount/apikey"
alias ND_MODIFY_APIKEY = "/api/v5/broker/nd/subaccount/modify-apikey"
alias ND_DELETE_APIKEY = "/api/v5/broker/nd/subaccount/delete-apikey"
alias GET_REBATE_PER_ORDERS = "/api/v5/broker/nd/rebate-per-orders"
alias REBATE_PER_ORDERS = "/api/v5/broker/nd/rebate-per-orders"
alias MODIFY_SUBACCOUNT_DEPOSIT_ADDRESS = "/api/v5/asset/broker/nd/modify-subaccount-deposit-address"
alias GET_SUBACCOUNT_DEPOSIT = "/api/v5/asset/broker/nd/subaccount-deposit-address"

# Convert-Complete
alias GET_CURRENCIES = "/api/v5/asset/convert/currencies"
alias GET_CURRENCY_PAIR = "/api/v5/asset/convert/currency-pair"
alias ESTIMATE_QUOTE = "/api/v5/asset/convert/estimate-quote"
alias CONVERT_TRADE = "/api/v5/asset/convert/trade"
alias CONVERT_HISTORY = "/api/v5/asset/convert/history"

# FDBroker -completed
alias FD_GET_REBATE_PER_ORDERS = "/api/v5/broker/fd/rebate-per-orders"
alias FD_REBATE_PER_ORDERS = "/api/v5/broker/fd/rebate-per-orders"

# Rfq/BlcokTrading-completed
alias COUNTERPARTIES = "/api/v5/rfq/counterparties"
alias CREATE_RFQ = "/api/v5/rfq/create-rfq"
alias CANCEL_RFQ = "/api/v5/rfq/cancel-rfq"
alias CANCEL_BATCH_RFQS = "/api/v5/rfq/cancel-batch-rfqs"
alias CANCEL_ALL_RSQS = "/api/v5/rfq/cancel-all-rfqs"
alias EXECUTE_QUOTE = "/api/v5/rfq/execute-quote"
alias CREATE_QUOTE = "/api/v5/rfq/create-quote"
alias CANCEL_QUOTE = "/api/v5/rfq/cancel-quote"
alias CANCEL_BATCH_QUOTES = "/api/v5/rfq/cancel-batch-quotes"
alias CANCEL_ALL_QUOTES = "/api/v5/rfq/cancel-all-quotes"
alias GET_RFQS = "/api/v5/rfq/rfqs"
alias GET_QUOTES = "/api/v5/rfq/quotes"
alias GET_RFQ_TRADES = "/api/v5/rfq/trades"
alias GET_PUBLIC_TRADES = "/api/v5/rfq/public-trades"
alias MMP_RESET = "/api/v5/rfq/mmp-reset"
alias MARKER_INSTRUMENT_SETTING = "/api/v5/rfq/maker-instrument-settings"

# tradingBot-Grid-complete-testcomplete
alias GRID_ORDER_ALGO = "/api/v5/tradingBot/grid/order-algo"
alias GRID_AMEND_ORDER_ALGO = "/api/v5/tradingBot/grid/amend-order-algo"
alias GRID_STOP_ORDER_ALGO = "/api/v5/tradingBot/grid/stop-order-algo"
alias GRID_ORDERS_ALGO_PENDING = "/api/v5/tradingBot/grid/orders-algo-pending"
alias GRID_ORDERS_ALGO_HISTORY = "/api/v5/tradingBot/grid/orders-algo-history"
alias GRID_ORDERS_ALGO_DETAILS = "/api/v5/tradingBot/grid/orders-algo-details"
alias GRID_SUB_ORDERS = "/api/v5/tradingBot/grid/sub-orders"
alias GRID_POSITIONS = "/api/v5/tradingBot/grid/positions"
alias GRID_WITHDRAW_INCOME = "/api/v5/tradingBot/grid/withdraw-income"
# --------need to add:
alias GRID_COMPUTE_MARIGIN_BALANCE = "/api/v5/tradingBot/grid/compute-margin-balance"
alias GRID_MARGIN_BALANCE = "/api/v5/tradingBot/grid/margin-balance"
alias GRID_AI_PARAM = "/api/v5/tradingBot/grid/ai-param"
alias PLACE_RECURRING_BUY_ORDER = "/api/v5/tradingBot/recurring/order-algo"
alias AMEND_RECURRING_BUY_ORDER = "/api/v5/tradingBot/recurring/amend-order-algo"
alias STOP_RECURRING_BUY_ORDER = "/api/v5/tradingBot/recurring/stop-order-algo"
alias GET_RECURRING_BUY_ORDER_LIST = "/api/v5/tradingBot/recurring/orders-algo-pending"
alias GET_RECURRING_BUY_ORDER_HISTORY = "/api/v5/tradingBot/recurring/orders-algo-history"
alias GET_RECURRING_BUY_ORDER_DETAILS = "/api/v5/tradingBot/recurring/orders-algo-details"
alias GET_RECURRING_BUY_SUB_ORDERS = "/api/v5/tradingBot/recurring/sub-orders"

# stacking - all need to implement-testcomplete
alias STACK_DEFI_OFFERS = "/api/v5/finance/staking-defi/offers"
alias STACK_DEFI_PURCHASE = "/api/v5/finance/staking-defi/purchase"
alias STACK_DEFI_REDEEM = "/api/v5/finance/staking-defi/redeem"
alias STACK_DEFI_CANCEL = "/api/v5/finance/staking-defi/cancel"
alias STACK_DEFI_ORDERS_ACTIVITY = "/api/v5/finance/staking-defi/orders-active"
alias STACK_DEFI_ORDERS_HISTORY = "/api/v5/finance/staking-defi/orders-history"
alias STACK_GET_SAVING_BALANCE = "/api/v5/finance/savings/balance"
alias STACK_SAVING_PURCHASE_REDEMPTION = "/api/v5/finance/savings/purchase-redempt"
alias STACK_SET_LENDING_RATE = "/api/v5/finance/savings/set-lending-rate"
alias STACK_GET_LENDING_HISTORY = "/api/v5/finance/savings/lending-history"
alias STACK_GET_PUBLIC_BORROW_INFO = "/api/v5/finance/savings/lending-rate-summary"
alias STACK_GET_PUBLIC_BORROW_HISTORY = "/api/v5/finance/savings/lending-rate-history"

# status-complete
alias STATUS = "/api/v5/system/status"

# Copy Trading
alias GET_EXISTING_LEADING_POSITIONS = "/api/v5/copytrading/current-subpositions"
alias GET_LEADING_POSITIONS_HISTORY = "/api/v5/copytrading/subpositions-history"
alias PLACE_LEADING_STOP_ORDER = "/api/v5/copytrading/algo-order"
alias CLOSE_LEADING_POSITIONS = "/api/v5/copytrading/close-subposition"
alias GET_LEADING_POSITIONS = "/api/v5/copytrading/instruments"
alias AMEND_EXISTING_LEADING_POSITIONS = "/api/v5/copytrading/set-instruments"
alias GET_PROFIT_SHARING_DETAILS = "/api/v5/copytrading/profit-sharing-details"
alias GET_TOTAL_PROFIT_SHARING = "/api/v5/copytrading/total-profit-sharing"
alias GET_UNREALIZED_PROFIT_SHARING_DETAILS = "/api/v5/copytrading/unrealized-profit-sharing-details"

# Spread Trading˚
alias SPREAD_PLACE_ORDER = "/api/v5/sprd/order"
alias SPREAD_CANAEL_ORDER = "/api/v5/sprd/cancel-order"
alias SPREAD_CANAEL_ALL_ORDERS = "/api/v5/sprd/mass-cancel"
alias SPREAD_GET_ORDER_DETAILS = "/api/v5/sprd/order"
alias SPREAD_GET_ACTIVE_ORDERS = "/api/v5/sprd/orders-pending"
alias SPREAD_GET_ORDERS = "/api/v5/sprd/orders-history"
alias SPREAD_GET_TRADES = "/api/v5/sprd/trades"
alias SPREAD_GET_SPREADS = "/api/v5/sprd/spreads"
alias SPREAD_GET_ORDER_BOOK = "/api/v5/sprd/books"
alias SPREAD_GET_TICKER = "/api/v5/sprd/ticker"
alias SPREAD_GET_PUBLIC_TRADES = "/api/v5/sprd/public-trades"
