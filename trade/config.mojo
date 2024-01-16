# from python import Python as py
from stdlib_extensions.pathlib import Path
from base.fixed import Fixed
from base.moutil import *
from core.env import *


@value
struct AppConfig(Stringable):
    var testnet: Bool
    var access_key: String
    var secret_key: String
    var category: String
    var symbols: String
    var depth: Int
    var grid_interval: Fixed
    var order_qty: Fixed

    fn __init__(inout self):
        self.testnet = False
        self.access_key = ""
        self.secret_key = ""
        self.category = ""
        self.symbols = ""
        self.depth = 1
        self.grid_interval = Fixed("0.01")
        self.order_qty = Fixed("0.0")

    fn __str__(self) -> String:
        return (
            "<AppConfig: testnet="
            + str(self.testnet)
            + ", access_key="
            + self.access_key
            + ", secret_key="
            + self.secret_key
            + ", category="
            + self.category
            + ", symbols="
            + self.symbols
            + ", depth="
            + str(self.depth)
            + ", grid_interval="
            + str(self.grid_interval)
            + ", order_qty="
            + str(self.order_qty)
            + ">"
        )


fn load_toml_config(filename: String) raises -> AppConfig:
    # let tomllib = py.import_module("tomllib")
    # let tmp_file = Path(filename)
    # let s = tmp_file.read_text()
    # let j = tomllib.loads(s)
    return AppConfig()


fn load_config(filename: String) raises -> AppConfig:
    let dict = env_load(filename)
    var config = AppConfig()
    config.testnet = str_to_bool(dict["testnet"])
    config.access_key = dict["access_key"]
    config.secret_key = dict["secret_key"]
    config.category = dict["category"]
    config.symbols = dict["symbols"]
    config.depth = strtoi(dict["depth"])
    config.grid_interval = Fixed(dict["grid_interval"])
    config.order_qty = Fixed(dict["order_qty"])
    return config
