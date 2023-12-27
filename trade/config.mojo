from python import Python as py
from stdlib_extensions.pathlib import Path


@value
struct AppConfig(Stringable):
    var testnet: Bool
    var access_key: String
    var secret_key: String
    var category: String
    var symbol: String
    var depth: Int
    var grid_interval: Float64

    fn __init__(inout self):
        self.testnet = False
        self.access_key = ""
        self.secret_key = ""
        self.category = ""
        self.symbol = ""
        self.depth = 1
        self.grid_interval = 0.01

    fn __str__(self) -> String:
        return (
            "<AppConfig: testnet="
            + str(self.testnet)
            + ", access_key="
            + str(self.access_key)
            + ", secret_key="
            + str(self.secret_key)
            + ", category="
            + str(self.category)
            + ", symbol="
            + str(self.symbol)
            + ", depth="
            + str(self.depth)
            + ", grid_interval="
            + str(self.grid_interval)
            + ">"
        )


fn load_config(filename: String) raises -> AppConfig:
    let tomllib = py.import_module("tomllib")
    let tmp_file = Path(filename)
    let s = tmp_file.read_text()

    # print(s)

    let j = tomllib.loads(s)

    var config = AppConfig()
    config.testnet = j["testnet"].__bool__()
    config.access_key = str(j["access_key"])
    config.secret_key = str(j["secret_key"])
    config.category = str(j["category"])
    config.symbol = str(j["symbol"])
    config.depth = int(j["depth"])
    config.grid_interval = j["grid_interval"].to_float64()
    return config
