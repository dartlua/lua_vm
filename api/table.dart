import 'value.dart';

class LuaTable{
  Map<dynamic, dynamic> map;

  LuaTable(Map<dynamic, dynamic> this.map);

  LuaValue get(LuaValue key) {
    dynamic value = key.luaValue;
    if(value is int) {
      print(value - 1);
      return LuaValue(map[map.keys.elementAt(value - 1)]);
    }
    return LuaValue(map[value]);
  }

  void put(LuaValue key, LuaValue val){
    map[key.luaValue] = val.luaValue;
  }
}

LuaTable newLuaTable(int nArr, int nRec){
  return LuaTable(Map<dynamic, dynamic>());
}