import 'package:luart/luart.dart';
import 'package:luart/src/binary/chunk.dart';


class LuaClosure {
  LuaClosure({this.proto, this.dartFunc});

  LuaClosure.fromLuaProto(this.proto) {
    final upvalueCount = proto!.upvalues.length;
    if (upvalueCount > 0) upValues = <LuaUpValue>[];
  }

  LuaClosure.fromDartFunction(this.dartFunc, int nUpvalues) {
    if (nUpvalues > 0) upValues = <LuaUpValue>[];
  }

  LuaPrototype? proto;
  LuaDartFunction? dartFunc;
  late List<LuaUpValue?> upValues;
}

class LuaUpValue {
  Object? value;

  LuaUpValue(this.value);
}
