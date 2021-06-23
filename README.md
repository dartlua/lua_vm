![Banner](https://github.com/dartlua/lua_vm/raw/main/img/top_banner.png)
![Lua](https://img.shields.io/badge/Lua-5.3-green)

# Luart
With this project, you can run or compile Lua script on your device(iOS Android Web).  
You can write UI in Flutter and handle backend data by Luart.

# TODO
- [x] Read and parse Lua binary.
- [x] A complete Lua VM include Lua Stack, State and etc...
- [x] Execute Lua script.
- [x] Compiler on device.
- [x] Standard library.

# Test
- run `dart example/test.dart`
- run `dart test`

# Known Issue
First of all, try `dart bin/luart.dart` to enter Luart REPL Terminal to understand which commands are not available.
|function|description|eg.|will fix?|platform|
|:-|:-|:-|:-|:-|
|`os.date()`|different format|2021-02-25 17:40:06.368250|will fix|all|
|`os.getenv()`|unavailable on web|no eg.|will fix|web|
|`os.execute()`|unavailable|no eg.|may not fix|all|
|`os.setlocale()`|unavailable|no eg.|may not fix|all|
|`string.format()`| can't format `%q`.Will replace `%q` with `%s` by default.|`string.format("%q", "One\nTwo")` equals to `string.format("%s", "One\nTwo")`|may fix|all|
|~~`string.format()`~~|~~Formatter match(like `%d`) can't use~~|~~stdin:`string.find("Deadline is 30/05/1999, firm", "%d%d/%d%d/%d%d%d%d")`output:`nil`~~|fixed|~~all~~|
|coroutine|not implement|no eg.|will add|all|

# Thanks
Especially thanks [luago](https://github.com/zxh0/luago-book)

# License
```
All Contributors 2021
Apache License 2.0
```
