import 'package:luart/luart.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/state/lua_closure.dart';
import 'package:luart/src/state/lua_table.dart';
import 'package:luart/src/state/lua_value.dart';

mixin LuaStateGet implements LuaState {
  @override
  void createTable(int nArr, int nRec) {
    stack!.push(LuaTable(<KV>[]));
  }

  @override
  void newTable() {
    createTable(0, 0);
  }

  @override
  LuaType getTable(int idx) {
    var t = stack!.get(idx)!;
    var k = stack!.pop();
    return _getTable(t, k, false);
  }

  LuaType _getTable(Object t, Object? k, bool raw) {
    final tbl = t;
    if (tbl is LuaTable) {
      final v = tbl.get(k!);
      if (raw || v != null || !tbl.hasMetaField('__index')) {
        stack!.push(v);
        return typeOf(v);
      }
    }
    if (!raw) {
      final mf = getMetafield(t, '__index', this);
      if (mf != null) {
        if (mf is LuaTable) return _getTable(mf, k, false);
        if (mf is LuaClosure) {
          stack!.push(mf);
          stack!.push(t);
          stack!.push(k);
          call(2, 1);
          return typeOf(stack!.get(-1));
        }
      }
    }
    throw TypeError();
  }

  @override
  LuaType getField(int idx, String k) {
    final t = stack!.get(idx)!;
    return _getTable(t, k, false);
  }

  @override
  LuaType getI(int idx, int i) {
    final t = stack!.get(idx)!;
    return _getTable(t, i, false);
  }

  @override
  bool getMetatable(int idx) {
    final val = stack!.get(idx)!;
    final mt = getMetaTable(val, this);
    if (mt != null) {
      stack!.push(mt);
      return true;
    }
    return false;
  }

  @override
  LuaType getGlobal(String name) =>
      _getTable(registry!.get(LUA_RIDX_GLOBALS)!, name, false);
}
