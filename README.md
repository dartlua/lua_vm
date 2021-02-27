![Banner](https://github.com/dartlua/lua_vm/raw/main/img/top_banner.png)
![Lua](https://img.shields.io/badge/Lua-5.3-green)

# Lua-Dart
With this project, you can run or compile Lua script on your device.(iOS Android Web)
You can write UI in Flutter and handle backend data by LuaDart.

# TODO
- [x] Read and parse Lua binary.
- [x] Lua VM include Lua Stack, State and etc..
- [x] A complete Lua VM.
- [x] Execute Lua script.
- [x] Compiler on device.
- [ ] Standard library.

# Known Issue
First of all, try `dart bin/luart.dart` to enter Luart REPL Terminal to understand which commands are not available.
- Different date format.(eg: LuaDart: 2021-02-25 17:40:06.368250)
- Temporarily, `os.getenv()` is unavailable on web. Unable to use `os.execute()` and `os.setlocale()` on all.
- string.format() can't format `%q`.(LuaDart replace `%q` with `%s` by default)
- Formatter match, eg: can't use `string.find("Deadline is 30/05/1999, firm", "%d%d/%d%d/%d%d%d%d")` to match date

# Contributor
Welcome everyone to contribute to this project.

# License
```
All Contributors 2021
Apache License 2.0
```
