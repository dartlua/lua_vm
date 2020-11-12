import '../operation/math.dart';
import 'value.dart';

class LuaTable{
  //todo: fix lua table class
  Map<LuaValue, LuaValue> map;
  List<LuaValue> list;

  LuaTable({Map<LuaValue, LuaValue> this.map, List<LuaValue> this.list});

  LuaValue get(LuaValue key){
    LuaValue _key = _float2Int(key);
    dynamic value = _key.luaValue;
    if(value is int)
      if(value >= 1 && value <= list.length) return list[value - 1];
    return map[value];
  }

  void put(LuaValue key, LuaValue val){
    if(key == null) throw ArgumentError.notNull('key');
    dynamic idx = key.luaValue;
    if(idx is num) if(idx.isNaN) throw ArgumentError('arg key is NaN');
    LuaValue _key = _float2Int(key);
    idx = _key.luaValue;
    if(idx is int && idx >= 1) {
      int listLen = list.length;
      if(idx <= listLen) {
        list[idx - 1] = val;
        if(idx == listLen && val == null) {
          _shrinkList();
        }
        return;
      }
      if(listLen + 1 == idx) {
        map.remove(key);
        if(val != null){
          list.add(val);
          _expandList();
        }
        return;
      }
    }
    if(val != null){
      if(map == null) map = Map<LuaValue, LuaValue>();
      map[key] = val;
    }else map.remove(key);
  }

  void _shrinkList(){
    int len = list.length;
    for(int i = len - 1; i >= 0; i--)
      if(list[i] == null)list.removeRange(i + 1, len);
  }

  void _expandList(){
    for(int idx = list.length + 1; true; idx++){
      if(map.length >= idx){
        LuaValue val = map[map.keys.elementAt(idx)];
        map.remove(val);
        list.add(val);
      }else break;
    }
  }
}

LuaTable newLuaTable(int nArr, int nRec){
  LuaTable t = LuaTable();
  if(nArr > 0) t.list = List<LuaValue>(nArr);
  if(nRec > 0) t.map = Map<LuaValue, LuaValue>();
  return t;
}

LuaValue _float2Int(LuaValue key){
  if(key == null) throw ArgumentError('key can be null');
  dynamic value = key.luaValue;
  if(value is int) return LuaValue(value);
  if(value is double) {
    List l = float2Int(value);
    if(l[1]) return LuaValue(l[0]);
  }
  return key;
}