from python import Python
from collections import Dict
from pathlib.path import Path
from base.fixed import Fixed
from base.moutil import *
from core.env import *
from base.mo import *


@value
struct AppConfig(Stringable):
    var testnet: Bool
    var access_key: String
    var secret_key: String
    var category: String
    var symbols: String
    var depth: Int
    var is_local_based: Bool
    var strategy: String
    var params: Dict[String, String]

    fn __init__(inout self):
        self.testnet = False
        self.access_key = ""
        self.secret_key = ""
        self.category = ""
        self.symbols = ""
        self.depth = 1
        self.is_local_based = True
        self.strategy = ""
        self.params = Dict[String, String]()

    fn __str__(self) -> String:
        var params_str = String("")
        for e in self.params.items():
            if params_str != "":
                params_str += ", "
            params_str += e[].key + "=" + e[].value
        return (
            "<AppConfig: testnet="
            + str(self.testnet)
            + ", access_key="
            + self.access_key
            + ", secret_key="
            + self.secret_key
            + ", is_local_based="
            + str(self.is_local_based)
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
    var py = Python.import_module("builtins")
    var tomli = Python.import_module("tomli")
    var tmp_file = Path(filename)
    var s = tmp_file.read_text()
    var dict = tomli.loads(s)
    var config = AppConfig()
    var config_ref = Reference(config)
    config_ref[].testnet = str_to_bool(str(dict["testnet"]))
    config_ref[].access_key = str(dict["access_key"])
    config_ref[].secret_key = str(dict["secret_key"])
    config_ref[].category = str(dict["category"])
    config_ref[].symbols = str(dict["symbols"])
    # logi("load_config symbols: " + config.symbols)
    config_ref[].depth = strtoi(str(dict["depth"]))
    config_ref[].is_local_based = str_to_bool(str(dict["is_local_based"]))
    config_ref[].strategy = str(dict["strategy"]["name"])
    var params = dict["params"]
    var iterator = py.iter(params)
    var index = 0
    var count = int(params.__len__())
    while index < count:
        var name = py.next(iterator)
        var value = params[name]
        # print(name, value)
        config_ref[].params[str(name)] = str(value)
        index += 1
    return config


fn load_env_config(filename: String) raises -> AppConfig:
    var dict = env_load(filename)
    var config = AppConfig()
    config.testnet = str_to_bool(dict["testnet"])
    config.access_key = dict["access_key"]
    config.secret_key = dict["secret_key"]
    config.category = dict["category"]
    config.symbols = dict["symbols"]
    config.depth = strtoi(dict["depth"])
    return config
