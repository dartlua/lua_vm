import 'package:lua_vm/lua_vm.dart';

import '../binary/chunk.dart';

class LuaClosure {
  LuaClosure({this.proto, this.dartFunc});

  LuaClosure.fromLuaProto(this.proto) {
    final upvalueCount = proto!.upvalues.length;
    if (upvalueCount > 0) upValues = <LuaUpValue>[];
  }

  LuaClosure.fromDartFunctiontion(this.dartFunc, int nUpvalues) {
    if (nUpvalues > 0) upValues = <LuaUpValue>[];
  }

  Prototype? proto;
  DartFunction? dartFunc;
  late List<LuaUpValue?> upValues;
}

class LuaUpValue {
  Object? value;

  LuaUpValue(this.value);
}
