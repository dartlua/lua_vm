import 'package:luart/luart.dart';
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

  throw TypeError();
}

bool convert2Boolean(Object? v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v == 0 ? false : true;
  return true;
}

double convert2Float(Object value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.parse(value);
  throw TypeError();
}

String? convert2String(Object value) {
  if (value is String) return value;
  if (value is int) return value.toString();
  if (value is double) return value.toString();
  if (value is bool) return value ? 'true' : 'false';
}

int convert2Int(Object value) {
  if (value is String) return num.parse(value).toInt();
  if (value is double) return value.round();
  if (value is int) return value;
  throw TypeError();
}

void setMetatableFor(Object value, LuaTable? metaTable, LuaState luaState) {
  if (value is LuaTable) {
    value.metaTable = metaTable;
    return;
  }
  luaState.registry!.put('_MT${typeOf(value)}', metaTable);
}

LuaTable? getMetaTable(Object val, LuaState luaState) {
  if (val is LuaTable) return val.metaTable;
  final mt = luaState.registry!.get('_MT${typeOf(val)}');
  if (mt != null && mt is LuaTable) return mt.metaTable;
  return null;
}

Object? callMetaMethod(
  Object a,
  Object? b,
  String metaMethod,
  LuaState luaState,
) {
  var mm = getMetafield(a, metaMethod, luaState);
  if (mm == null) {
    if (b != null) {
      mm = getMetafield(b, metaMethod, luaState);
    }
    if (mm == null) {
      return null;
    }
  }

  luaState.stack!.check(4);
  luaState.stack!.push(mm);
  luaState.stack!.push(a);
  luaState.stack!.push(b);
  luaState.call(2, 1);
  return luaState.stack!.pop();
}

Object? getMetafield(Object val, String fieldName, LuaState ls) {
  var mt = getMetaTable(val, ls);
  if (mt != null) return mt.get(fieldName);
  return null;
}
