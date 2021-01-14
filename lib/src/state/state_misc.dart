import 'package:luart/luart.dart';
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
    if (result != null) {
      stack!.push(result);
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
          final s2 = toStr(-1);
          final s1 = toStr(-2);
          stack!.pop();
          stack!.pop();
          stack!.push(s1 + s2);
          continue;
        }

        final b = stack!.pop();
        final a = stack!.pop()!;
        final result = callMetaMethod(a, b, '__concat', this);
        if (result != null) {
          stack!.push(result);
          continue;
        }

        throw Exception('concat error');
      }
    }
  }
}
