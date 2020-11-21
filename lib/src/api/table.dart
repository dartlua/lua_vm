import 'value.dart';

class LuaTable {
  List<KV?> list;
  LuaTable? metaTable;

  LuaTable(this.list);

  LuaValue get(LuaValue key) {
    dynamic value = key.luaValue;
    if (value is int) return LuaValue(list[value - 1]!.value);
    int index = list.indexWhere((e) => e!.key == value);
    return LuaValue(index == -1 ? null : list.elementAt(index)!.value);
  }

  void put(LuaValue key, LuaValue? val) {
    dynamic value = key.luaValue;
    if (value is int) {
      fillListWithNull(value);
      list[value - 1] = KV(value, val!.luaValue);
      return;
    }
    list.add(KV(value, val!.luaValue));
  }

  void fillListWithNull(int count) {
    if (list.isEmpty) list.insert(0, null);
    for (var i = 0; i < count; i++) {
      if (list.elementAt(i) != null) continue;
      list.insert(i + 1, null);
    }
  }

  bool hasMetaField(String fieldName) =>
      metaTable != null && metaTable!.get(LuaValue(fieldName)).luaValue != null;
}

class KV {
  dynamic key;
  dynamic value;

  KV(dynamic this.key, dynamic this.value);

  String toString() => ' {$key: $value}';
}

LuaTable newLuaTable(int nArr, int nRec) {
  return LuaTable(<KV?>[]);
}
