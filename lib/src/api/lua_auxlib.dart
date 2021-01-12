import 'dart:convert';
import 'dart:typed_data';

import 'package:luart/luart.dart';
import 'package:luart/src/constants.dart';

extension LuaAuxlib on LuaState {
  void loadString(String source) {
    load(Uint8List.fromList(utf8.encode(source)), 'source');
  }

  bool doString(String source) {
    loadString(source);
    return pCall(0, LUA_MULTRET, 0) != LuaStatus.ok;
  }
}
