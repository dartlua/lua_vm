import '../constants.dart';

class LuaValue extends Object{
  dynamic luaValue;

  LuaValue(dynamic this.luaValue);
}

LuaType typeOf(LuaValue val){
  final type = val.luaValue;
  if(type == null)return LuaType(LUA_TNIL);
  if(type is bool)return LuaType(LUA_TBOOLEAN);
  if(type is int)return LuaType(LUA_TNUMBER);
  if(type is double)return LuaType(LUA_TNUMBER);
  if(type is String)return LuaType(LUA_TSTRING);
  throw TypeError();
}

class LuaType {
  int luaType;
  LuaType(int this.luaType);
}

bool convert2Boolean(LuaValue val){
  var v = val.luaValue;
  if(v == null)return false;
  if(v is bool)return v;
  return true;
}