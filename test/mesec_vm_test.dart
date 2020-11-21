import 'dart:io';

import 'package:mesec/mesec.dart';
import 'package:test/test.dart';

void main() async {
  group('A group of tests', () {
    late LuaState lua;

    setUp(() async {
      lua = newLuaState();
    });

    test('First Test', () async {
      final chunk = await File('test/source/arith_add.luac').readAsBytes();
      lua.load(chunk, 'luac.out', 'b');
      lua.call(0, 1);
      expect(lua.toInt(-1), equals(2));
    });

    test('LuaState.pushInt', () {
      lua.pushInt(1);
      expect(lua.toInt(-1), equals(1));

      lua.pushInt(0xFFFFFFFF);
      expect(lua.toInt(-1), equals(0xFFFFFFFF));
    });

    test('LuaState.pushNumber', () {
      lua.pushNumber(1);
      expect(lua.toNumber(-1), equals(1));

      lua.pushNumber(double.maxFinite);
      expect(lua.toNumber(-1), equals(double.maxFinite));

      lua.pushNumber(double.infinity);
      expect(lua.toNumber(-1), equals(double.infinity));
    });
  });
}
