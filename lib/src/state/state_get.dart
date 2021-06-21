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
    var t = stack!.get(idx);
    var k = stack!.pop();
    return _getTable(t, k, false);
  }

  LuaType _getTable(Object? t, Object? k, bool raw) {
    if (t is LuaTable) {
      final v = t.get(k!);
      if (raw || v != null || !t.hasMetaField('__index')) {
        stack!.push(v);
        return typeOf(v);
      }
    }
    if (!raw) {
      final mf = getMetaField(t, '__index', this);
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
    throw LuaError('$k: called on a nil value');// OR return LuaType.nil;
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
  LuaType rawGet(int idx) {
    final t = stack!.get(idx)!;
    final k = stack!.pop();
    return _getTable(t, k, true);
  }

  @override
  LuaType rawGetI(int idx, int i) {
    final t = stack!.get(idx)!;
    return _getTable(t, i, true);
  }

  @override
  LuaType getGlobal(String name) =>
      _getTable(registry!.get(LUA_RIDX_GLOBALS)!, name, false);
}
