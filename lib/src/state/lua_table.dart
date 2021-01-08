class LuaTable {
  List<KV> list;
  LuaTable? metaTable;

  LuaTable(this.list);

  @override
  String toString() => 'Table<$list, $metaTable>';

  Object? get(Object key) {
    dynamic value = key;
    if (value is int) return list[value - 1].value;
    var index = list.indexWhere((e) => e.key == value);
    return index == -1 ? null : list.elementAt(index).value;
  }

  void put(Object key, Object? val) {
    if (key is int) {
      fillListWithNull(key);
      list[key - 1] = KV(key, val!);
      return;
    }
    list.add(KV(key, val!));
  }

  void fillListWithNull(int count) {
    if (list.isEmpty) list.insert(0, nullKV());
    for (var i = 1; i < count; i++) {
      if (i < list.length) {
        if (list.elementAt(i) != nullKV()) {
          continue;
        }
      }
      list.insert(i, nullKV());
    }
  }

  bool hasMetaField(String fieldName) =>
      metaTable != null && metaTable!.get(fieldName) != null;

  KV nullKV() => KV(null, null);

  int len() {
    var count = 0;
    for (var i = 0; i < list.length; i++) {
      if (list[i].value != null) {
        count++;
      }
    }
    return count;
  }
}

class KV {
  dynamic key;
  dynamic value;

  KV(this.key, this.value);

  @override
  String toString() => ' {$key: $value}';
}

LuaTable newLuaTable(int nArr, int nRec) {
  return LuaTable(<KV>[]);
}
