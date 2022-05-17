import 'package:luart/luart.dart';
import 'package:luart/src/api/lua_result.dart';
import 'package:luart/src/state/lua_closure.dart';
import 'package:luart/src/state/lua_table.dart';

// class Object extends Object {
//   dynamic luaValue;

//   Object(this);
// }

LuaType typeOf(Object? value) {
  if (value == null) return LuaType.nil;

  if (value is LuaClosure) return LuaType.function;
  if (value is bool) return LuaType.boolean;
  if (value is int) return LuaType.number;
  if (value is double) return LuaType.number;
  if (value is String) return LuaType.string;
  if (value is LuaTable) return LuaType.table;
  if (value is LuaError) return LuaType.string;
  if (value is LuaState) return LuaType.thread;
  if (value is LuaResult) return typeOf(value.result);

  throw Exception('Unsupported type: ${value.runtimeType}');
}

bool convert2Boolean(Object? v) {
  if (v == null) return false;
  if (v is bool) return v;
  return true;
}

LuaResult<double> convert2Float(Object? value) {
  if (value is double) return LuaResult<double>(value, true);
  if (value is int) return LuaResult<double>(value.toDouble(), true);
  if (value is String) return LuaResult<double>(double.parse(value), true);
  return LuaResult<double>(0, false);
}

LuaResult<String> convert2String(Object? value) {
  switch (value.runtimeType) {
    case String:
      return LuaResult(value! as String, true);
    case int:
    case double:
      return LuaResult(value!.toString(), true);
    default:
      return LuaResult('', false);
  }
}

LuaResult<int> convert2Int(Object? value) {
  if (value is String) return LuaResult(num.parse(value).toInt(), true);
  if (value is double) {
    final ceil = value.ceil();
    return LuaResult(ceil, ceil.floorToDouble() == value);
  }
  if (value is int) return LuaResult<int>(value, true);
  return LuaResult(0, false);
}

void setMetaTableFor(Object value, LuaTable? metaTable, LuaState luaState) {
  if (value is LuaTable) {
    value.metaTable = metaTable;
    return;
  }
  luaState.registry!.put('_MT${typeOf(value)}', metaTable);
}

LuaTable? getMetaTable(Object? val, LuaState luaState) {
  if (val is LuaTable) return val.metaTable;
  final mt = luaState.registry!.get('_MT${typeOf(val)}');
  if (mt != null && mt is LuaTable) return mt;
  return null;
}

LuaResult callMetaMethod(
  Object? a,
  Object? b,
  String metaMethod,
  LuaState luaState,
) {
  var mm = getMetaField(a, metaMethod, luaState);
  if (mm == null) {
    mm = getMetaField(b, metaMethod, luaState);
    if (mm == null) {
      return LuaResult(null, false);
    }
  }

  luaState.stack!.check(4);
  luaState.stack!.push(mm);
  luaState.stack!.push(a);
  luaState.stack!.push(b);
  luaState.call(2, 1);
  return LuaResult(luaState.stack!.pop(), true);
}

Object? getMetaField(Object? val, String fieldName, LuaState ls) {
  final mt = getMetaTable(val, ls);
  if (mt != null) return mt.get(fieldName);
  return null;
}
