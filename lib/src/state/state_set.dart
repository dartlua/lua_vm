import 'package:luart/luart.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/state/lua_closure.dart';
import 'package:luart/src/state/lua_table.dart';
import 'package:luart/src/state/lua_value.dart';

mixin LuaStateSet implements LuaState {
  @override
  void setGlobal(String name) {
    final t = registry!.get(LUA_RIDX_GLOBALS)!;
    final v = stack!.pop();
    _setTable(t, name, v, false);
  }

  @override
  void setTable(int idx) {
    final t = stack!.get(idx)!;
    final v = stack!.pop();
    final k = stack!.pop();
    _setTable(t, k, v, false);
  }

  void _setTable(Object table, Object? k, Object? v, bool raw) {
    if (table is LuaTable) {
      if (raw ||
          table.get(k!) != null ||
          !table.hasMetaField('__newindex')) {
        table.put(k!, v);
        return;
      }
    }

    if (!raw) {
      final mf = getMetafield(table, '__newindex', this);
      if (mf is LuaTable) {
        _setTable(mf, k, v, false);
        return;
      }
      if (mf is LuaClosure) {
        stack!.push(mf);
        stack!.push(table);
        stack!.push(k);
        stack!.push(v);
        call(3, 0);
        return;
      }
    }
    throw TypeError();
  }

  @override
  void rawSet(int idx) {
    final t = stack!.get(idx)!;
    final v = stack!.pop();
    final k = stack!.pop();
    _setTable(t, k, v, true);
  }

  @override
  void rawSetI(int idx, int i) {
    final t = stack!.get(idx)!;
    final v = stack!.pop();
    _setTable(t, i, v, true);
  }

  @override
  void setField(int idx, String k) {
    final t = stack!.get(idx)!;
    final v = stack!.pop();
    _setTable(t, k, v, false);
  }

  @override
  void setI(int idx, int i) {
    final t = stack!.get(idx)!;
    final v = stack!.pop();
    _setTable(t, i, v, false);
  }
}
