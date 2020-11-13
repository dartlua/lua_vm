import '../binary/chunk.dart';
import 'state.dart';
import 'value.dart';

class Closure{
  ProtoType proto;
  Function dartFunc;
  List<UpValue> upValues;

  Closure({ProtoType this.proto, Function this.dartFunc});
}

class UpValue{
  LuaValue val;

  UpValue(LuaValue this.val);
}

class DartFunc {
  LuaState luaState;

  DartFunc(LuaState this.luaState);
}

Closure newLuaClosure(ProtoType proto) {
  Closure c = Closure(proto: proto);
  int nUpvalues = c.proto.upvalues.length;
  if(nUpvalues > 0) c.upValues = List<UpValue>();
  return c;
}

Closure newDartClosure(Function dartFunc, int nUpvalues) {
  Closure c = Closure(dartFunc: dartFunc);
  if(nUpvalues > 0) c.upValues = List<UpValue>();
  return c;
}