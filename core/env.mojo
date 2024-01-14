from stdlib_extensions.pathlib import Path
from stdlib_extensions.builtins import list, dict, HashableStr
from stdlib_extensions.builtins.string import *
from base.str_utils import str_contains


fn env_loads(s: String) raises -> dict[HashableStr, String]:
    let lines = split(s, "\n")

    var env_dict = dict[HashableStr, String]()
    for i in range(len(lines)):
        let line = lines[i]
        if not str_contains(line, "="):
            continue
        let l_array = split(line, "=")
        if len(l_array) != 2:
            continue
        let key = l_array[0]
        let value = l_array[1]
        env_dict[key] = value

    # for key_value in env_dict.items():
    #     print("[" + str(key_value.key) + "=" + key_value.value + "]")

    return env_dict


fn env_load(filename: String = ".env") raises -> dict[HashableStr, String]:
    let env_file = Path(filename)
    let text = env_file.read_text()
    return env_loads(text)
