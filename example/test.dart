import 'package:luart/src/api/lua_state.dart';
import 'package:luart/auxlib.dart';

Future<void> main() async {
  var exampleDir = 'example/';
  var testFiles = ['ch10.lua', 'ch11.lua', 'ch12.lua', 'ch13.lua'];
  for (var file in testFiles) {
    final filePath = exampleDir + file;
    final divider = String.fromCharCodes(List.filled(filePath.length, 61));
    var ls = LuaState();
    ls.openLibs();
    ls.loadFile(filePath);
    print('$divider $filePath $divider');
    ls.call(0, -1);
  }
}