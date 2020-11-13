import 'value.dart';

class LuaTable{
  List<KV> list;

  LuaTable(List<KV> this.list);

  LuaValue get(LuaValue key) {
    dynamic value = key.luaValue;
    if(value is int) return LuaValue(list[value - 1].value);
    return LuaValue(list.elementAt(list.indexWhere((e) => e.key == value)).value);
  }

  void put(LuaValue key, LuaValue val){
    dynamic value = key.luaValue;
    if(value is int) {
      fillListWithNull(value);
      list[value - 1] = KV(value, val.luaValue);
      return;
    }
    int len = list.length;
    fillListWithNull(len);
    list[len] = KV(value, val.luaValue);
  }

  void fillListWithNull(int idx){
    if(list.isEmpty) list.insert(0, null);
    for(int i = 0; i < idx - 1; i++)
      if(list.elementAt(i) == null) list.insert(i, null);
  }
}

class KV{
  dynamic key;
  dynamic value;

  KV(dynamic this.key, dynamic this.value);
}

LuaTable newLuaTable(int nArr, int nRec){
  return LuaTable(List<KV>());
}