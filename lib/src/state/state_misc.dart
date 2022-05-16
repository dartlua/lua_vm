import 'package:luart/luart.dart';
import 'package:luart/src/compiler/parser/lua_parser.dart';
import 'package:luart/src/state/lua_table.dart';
import 'package:luart/src/state/lua_value.dart';

mixin LuaStateMisc implements LuaState {
  @override
  void len(int idx) {
    final value = stack!.get(idx);
    if (value == null) {
      throw TypeError();
    }
    if (value is bool) {
      throw TypeError();
    }
    if (value is String) {
      stack!.push(value.length);
      return;
    }
    final result = callMetaMethod(value, value, '__len', this);
    if (result.success) {
      stack!.push(result.result);
      return;
    }
    if (value is LuaTable) {
      stack!.push(value.len);
      return;
    }

    throw Exception('get length error');
  }

  @override
  void concat(int n) {
    if (n == 0) {
      stack!.push('');
    } else if (n >= 2) {
      for (var i = 1; i < n; i++) {
        if (isString(-1) && isString(-2)) {
          final s2 = toDartString(-1);
          final s1 = toDartString(-2);
          stack!.pop();
          stack!.pop();
          stack!.push(s1 + s2);
          continue;
        }

        final b = stack!.pop();
        final a = stack!.pop();
        final result = callMetaMethod(a, b, '__concat', this);
        if (result.success) {
          stack!.push(result);
          continue;
        }

        throw Exception('concat error');
      }
    }
  }

  @override
  int error() {
    final e = stack!.pop();
    throw LuaRuntimeError(e);
  }

  @override
  bool stringToNumber(String s) {
    final i = LuaParser.parseInt(s);
    if (i != null) {
      pushInt(i);
      return true;
    }

    final f = LuaParser.parseNumber(s);
    if (f != null) {
      pushNumber(f);
      return true;
    }
    return false;
  }

  @override
  bool next(int idx) {
    final val = stack!.get(idx);
    if (val is LuaTable) {
      final key = stack!.pop();
      final nextKey = val.nextKey(key);
      if (nextKey != null) {
        stack!.push(nextKey);
        stack!.push(val.get(nextKey));
        return true;
      }
      return false;
    }
    throw LuaError('LuaTable expected');
  }
}
