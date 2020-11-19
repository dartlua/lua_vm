import 'closure.dart';
import 'state.dart';
import 'table.dart';

class LuaValue extends Object{
  dynamic luaValue;

  LuaValue(this.luaValue);
}

LuaType typeOf(LuaValue val){
  if(val == null) return LuaType.nil;
  final value = val.luaValue;
  if(value == null) return LuaType.nil;
  if(value is Closure) return LuaType.function;
  if(value is bool) return LuaType.boolean;
  if(value is int) return LuaType.number;
  if(value is double) return LuaType.number;
  if(value is String) return LuaType.string;
  if(value is LuaTable) return LuaType.table;
  throw TypeError();
}

enum LuaType {
  none,
  nil,
  boolean,
  lightuserdata,
  number,
  string,
  table,
  function,
  userdata,
  thread,
}

bool convert2Boolean(LuaValue val){
  dynamic v = val.luaValue;
  if(v == null) return false;
  if(v is bool) return v;
  if(v is int) return v == 0 ? false : true;
  return true;
}

double convert2Float(LuaValue val){
  dynamic value = val.luaValue;
  if(value is double) return value;
  if(value is int) return value.toDouble();
  if(value is String) return double.parse(value);
  if(value is bool) return value ? 1.0 : 0.0;
  throw TypeError();
}

String convert2String(LuaValue val){
  dynamic value = val.luaValue;
  if(value is String) return value;
  if(value is int) return value.toString();
  if(value is double) return value.toString();
  if(value is bool) return value ? 'true' : 'false';
  throw TypeError();
}

int convert2Int(LuaValue val){
  dynamic value = val.luaValue;
  if(value is String) return num.parse(value).toInt();
  if(value is double) return value.round();
  if(value is int) return value;
  if(value is bool) return value ? 1 : 0;
  throw TypeError();
}

void setMetaTable(LuaValue val, LuaTable metaTable, LuaState luaState){
  dynamic table = val.luaValue;
  if(table is LuaTable){
    table.metaTable = metaTable;
    return;
  }
  luaState.registry.put(LuaValue('_MT${typeOf(val)}'), LuaValue(metaTable));
}

LuaTable getMetaTable(LuaValue val, LuaState luaState){
  dynamic t = val.luaValue;
  if(t is LuaTable) return t.metaTable;
  LuaTable mt = luaState.registry.get(LuaValue('_MT${typeOf(val)}')).luaValue;
  if(mt != null) return mt.metaTable;
  return null;
}

LuaValue callMetaMethod(LuaValue a, LuaValue b, String metaMethod, LuaState luaState){
  var mm = getMetaField(a, metaMethod, luaState);
  if(mm.luaValue == null) {
    mm = getMetaField(b, metaMethod, luaState);
    if(mm.luaValue == null) {
      return LuaValue(null);
    }
  }

  luaState.stack.check(4);
  luaState.stack.push(mm);
  luaState.stack.push(a);
  luaState.stack.push(b);
  luaState.call(2, 1);
  return luaState.stack.pop();
}

LuaValue getMetaField(LuaValue val, String fieldName, LuaState ls){
  var mt = getMetaTable(val, ls);
  if(mt != null) return mt.get(LuaValue(fieldName));
  return LuaValue(null);
}