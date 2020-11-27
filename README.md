![dart](https://github.com/dartlua/lua_vm/workflows/dart/badge.svg)

# Lua-Dart
A Dart project which aims to provide better Lua experience
 (such as hot fix) in Dart.  
With this project,
you can execute Lua binary on your device to implement extra function.

Such as hot fix:  
On your device, Load Lua binary from your server,
execute this binary to login website A and get cookie of it.  
After website A change its login workflow or api,
You no need to publish a new version of your app,
Just update Lua script on your server.


# Feature
- All platform support.(iOS Android Web)
- Execute compiled binary to save compile time on device.
- No platform specific code.
- Pure. Only for execute Lua script.

# TODO
- [x] Read Lua binary.
- [x] Parse binary.
- [x] A simple prototype of Lua VM include Lua Stack, State and etc..
- [ ] A complete Lua VM.
- [ ] Ability to execute Lua script.
- [ ] Compiler on device.
- [ ] Standard library.

# Contributor
Welcome everyone to contribute to this project.

# License
```
LollipopKit 2020
Apache License 2.0
```
