// ignore_for_file: avoid_print

import 'dart:io';

import 'package:luart/auxlib.dart';
import 'package:luart/src/api/lua_state.dart';

Future<void> main() async {
  final testFiles = Directory('example').listSync();
  testFiles.removeWhere(
    (ele) => !ele.path.endsWith('.lua'),
  );
  for (final file in testFiles) {
    final filePath = file.path;
    final divider = String.fromCharCodes(List.filled(filePath.length + 2, 61));
    final ls = LuaState();
    ls.openLibs();
    ls.loadFile(filePath);
    print('$divider\n $filePath \n$divider');
    ls.call(0, -1);
  }
}
