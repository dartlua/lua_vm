import '../constants.dart';

class LuaValue extends Object{
  dynamic luaValue;

  LuaValue(dynamic this.luaValue);
}

LuaType typeOf(LuaValue val){
  if(val == null)return LuaType(LUA_TNIL);
  final value = val.luaValue;
  if(value is bool)return LuaType(LUA_TBOOLEAN);
  if(value is int)return LuaType(LUA_TNUMBER);
  if(value is double)return LuaType(LUA_TNUMBER);
  if(value is String)return LuaType(LUA_TSTRING);
  throw TypeError();
}

class LuaType {
  int luaType;
  LuaType(int this.luaType);
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
  if(value is String)return value;
  if(value is int)return value.toString();
  if(value is double)return value.toString();
  if(value is bool)return value ? 'true' : 'false';
  throw TypeError();
}

int convert2Int(LuaValue val){
  dynamic value = val.luaValue;
  if(value is String)return num.parse(value).toInt();
  if(value is double)return value.round();
  if(value is int)return value;
  if(value is bool)return value ? 1 : 0;
  throw TypeError();
}