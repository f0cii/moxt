from stdlib_extensions.pathlib import Path
from stdlib_extensions.builtins import list, dict, HashableStr


fn main() raises:
    let env_file = Path(".env")
    let text = env_file.read_text()
    print(text)

    var d = dict[HashableStr, String]()
    d["abc"] = "abc"
    d["abc3"] = "abcc"
    for key_value in d.items():
        print(key_value.key, key_value.value)
