from collections.dict import Dict
from pathlib.path import Path


fn env_loads(s: String) raises -> Dict[String, String]:
    var lines = s.split("\n")

    var env_dict = Dict[String, String]()
    for i in range(len(lines)):
        var line = lines[i]
        if "=" not in line:
            continue
        var l_list = line.split("=")
        if len(l_list) != 2:
            continue
        var key = l_list[0]
        var value = l_list[1]
        env_dict[key] = value

    return env_dict


fn env_load(filename: String = ".env") raises -> Dict[String, String]:
    var env_file = Path(filename)
    var text = env_file.read_text()
    return env_loads(text)
