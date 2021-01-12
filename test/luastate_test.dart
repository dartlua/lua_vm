import 'dart:io';

import 'package:luart/auxlib.dart';
import 'package:luart/luart.dart';
import 'package:test/test.dart';

void main() async {
  group('A group of tests', () {
    late LuaState ls;

    setUp(() async {
      ls = LuaState();
    });

    test('First Test', () async {
      final chunk = await File('test/source/arith_add.luac').readAsBytes();
      ls.load(chunk, 'luac.out');
      ls.call(0, 1);
      expect(ls.toInt(-1), equals(2));
    });

    test('LuaState.pushInt', () {
      ls.pushInt(1);
      expect(ls.toInt(-1), equals(1));

      ls.pushInt(0xFFFFFFFF);
      expect(ls.toInt(-1), equals(0xFFFFFFFF));
    });

    test('LuaState.pushNumber', () {
      ls.pushNumber(1);
      expect(ls.toNumber(-1), equals(1));

      ls.pushNumber(double.maxFinite);
      expect(ls.toNumber(-1), equals(double.maxFinite));

      ls.pushNumber(double.infinity);
      expect(ls.toNumber(-1), equals(double.infinity));
    });

    test('compile source code', () {
      ls.doString('return 1 + 2');
      expect(ls.isInt(-1), isTrue);
      expect(ls.toInt(-1), equals(3));
    });

    test('call function in source code', () {
      var nArgs;
      var arg;

      int _func(LuaState ls) {
        nArgs = ls.getTop();
        arg = ls.stack!.get(1);
        return 0;
      }

      ls.register('print', _func);
      ls.doString('print "hello world"');

      expect(nArgs, equals(1));
      expect(arg, equals('hello world'));
    });
  });
}
