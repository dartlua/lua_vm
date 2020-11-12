import '../binary/chunk.dart';

class LuaClosure{
  ProtoType proto;

  LuaClosure(ProtoType this.proto);
}

LuaClosure newLuaClosure(ProtoType proto) => LuaClosure(proto);