import 'dart:ffi';
import 'dart:typed_data';

import 'reader.dart';

class Header {
  ByteData signature;
  ByteData version;
  ByteData format;
  ByteData luacData;
  ByteData cintSize;
  ByteData sizetSize;
  ByteData instructionSize;
  ByteData luaIntegerSize;
  ByteData luaNumberSize;
  Int64 luacInt;
  double luacNum;
}

class Upvalue {
  String inStack;
  String idx;
}

class LocVar {
  String varName;
  int startPC;
  int endPC;
}

class ProtoType {
  String source;
  Uint32 lineDefined;
  Uint32 lastLineDefined;
  ByteData numParams;
  ByteData isVararg;
  ByteData maxStackSize;
  List<Uint32> code;
  List constants;
  List<Upvalue> upvalues;
  List<ProtoType> protos;
  List<Uint32> lineInfo;
  List<LocVar> locVars;
  List<String> upvaluesName;
}

class BinaryChunk {
  Header header;
  String sizeUpvalues;
  ProtoType mainFunc;
}

ProtoType unDump(String data){
  Reader reader = Reader('');

}
