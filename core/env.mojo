from stdlib_extensions.pathlib import Path
from stdlib_extensions.builtins import list, dict, HashableStr
from stdlib_extensions.builtins.string import *
from base.str_utils import str_contains


alias StringDict = dict[HashableStr, String]


fn load_env(filename: StringLiteral = ".env") raises -> StringDict:
    let env_file = Path(filename)
    let text = env_file.read_text()

    let lines = split(text, "\n")

    var env_dict = StringDict()
    for line in lines:
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
