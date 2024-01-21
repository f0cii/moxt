from python import Python
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
    var strategy: String
    var params: dict[HashableStr, String]

    fn __init__(inout self):
        self.testnet = False
        self.access_key = ""
        self.secret_key = ""
        self.category = ""
        self.symbols = ""
        self.depth = 1
        self.strategy = ""
        self.params = dict[HashableStr, String]()

    fn __str__(self) -> String:
        var params_str = String("")
        for key_value in self.params.items():
            if params_str != "":
                params_str += ", "
            params_str += str(key_value.key) + "=" + key_value.value
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
            + ", strategy="
            + self.strategy
            + ", params=["
            + params_str
            + "]>"
        )


fn load_config(filename: String) raises -> AppConfig:
    let py = Python.import_module("builtins")
    let tomli = Python.import_module("tomli")
    let tmp_file = Path(filename)
    let s = tmp_file.read_text()
    let dict = tomli.loads(s)
    var config = AppConfig()
    config.testnet = str_to_bool(str(dict["testnet"]))
    config.access_key = str(dict["access_key"])
    config.secret_key = str(dict["secret_key"])
    config.category = str(dict["category"])
    config.symbols = str(dict["symbols"])
    config.depth = strtoi(str(dict["depth"]))
    config.strategy = str(dict["strategy"]["name"])
    let params = dict["params"]
    let iterator = py.iter(params)
    var index = 0
    let count = int(params.__len__())
    while index < count:
        let name = py.next(iterator)
        let value = params[name]
        # print(name, value)
        config.params[str(name)] = str(value)
        index += 1
    return config


fn load_env_config(filename: String) raises -> AppConfig:
    let dict = env_load(filename)
    var config = AppConfig()
    config.testnet = str_to_bool(dict["testnet"])
    config.access_key = dict["access_key"]
    config.secret_key = dict["secret_key"]
    config.category = dict["category"]
    config.symbols = dict["symbols"]
    config.depth = strtoi(dict["depth"])
    return config
