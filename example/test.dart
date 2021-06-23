import 'dart:io';

import 'package:luart/src/api/lua_state.dart';
import 'package:luart/auxlib.dart';

Future<void> main() async {
  var testFiles = Directory('example').listSync();
  testFiles.removeWhere(
    (ele) => !ele.path.endsWith('.lua')
  );
  for (var file in testFiles) {
    final filePath = file.path;
    final divider = String.fromCharCodes(List.filled(filePath.length + 2, 61));
    var ls = LuaState();
    ls.openLibs();
    ls.loadFile(filePath);
    print('$divider\n $filePath \n$divider');
    ls.call(0, -1);
  }
}
