import '../binary/chunk.dart';
import 'state.dart';
import 'value.dart';

class Closure {
  Closure({this.proto, this.dartFunc});

  Closure.fromLuaProto(this.proto) {
    final upvalueCount = proto.upvalues.length;
    if (upvalueCount > 0) upValues = <UpValue>[];
  }

  Closure.fromDartFunction(this.dartFunc, int nUpvalues) {
    if (nUpvalues > 0) upValues = <UpValue>[];
  }

  Prototype proto;
  Function dartFunc;
  List<UpValue> upValues;
}

class UpValue {
  LuaValue val;

  UpValue(this.val);
}

class DartFunc {
  LuaState luaState;

  DartFunc(this.luaState);
}
