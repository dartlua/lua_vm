import '../binary/chunk.dart';
import 'state.dart';
import 'value.dart';

class Closure{
  ProtoType proto;
  Function dartFunc;
  List<Upvalue> upValues;

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

Closure newLuaClosure(ProtoType proto) => Closure(proto: proto);
Closure newDartClosure(Function dartFunc) => Closure(dartFunc: dartFunc);