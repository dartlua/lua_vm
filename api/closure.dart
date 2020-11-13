import '../binary/chunk.dart';
import 'state.dart';

class Closure{
  ProtoType proto;
  Function dartFunc;

  Closure({ProtoType this.proto, Function this.dartFunc});
}

class DartFunc {
  LuaState luaState;

  DartFunc(LuaState this.luaState);
}

Closure newLuaClosure(ProtoType proto) => Closure(proto: proto);
Closure newDartClosure(Function dartFunc) => Closure(dartFunc: dartFunc);