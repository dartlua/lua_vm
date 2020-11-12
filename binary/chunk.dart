import 'dart:ffi';
import 'dart:typed_data';

import 'reader.dart';

class Header {
  final ByteData signature;
  final ByteData version;
  final ByteData format;
  final ByteData luacData;
  final ByteData cintSize;
  final ByteData sizetSize;
  final ByteData instructionSize;
  final ByteData luaIntegerSize;
  final ByteData luaNumberSize;
  final Int64 luacInt;
  final double luacNum;

  Header(
      this.signature,
      this.version,
      this.format,
      this.luacData,
      this.cintSize,
      this.sizetSize,
      this.instructionSize,
      this.luaIntegerSize,
      this.luaNumberSize,
      this.luacInt,
      this.luacNum);
}

class Upvalue {
  final String inStack;
  final String idx;

  Upvalue(this.inStack, this.idx);
}

class LocVar {
  final String varName;
  final int startPC;
  final int endPC;

  LocVar(this.varName, this.startPC, this.endPC);
}

class ProtoType {
  final String source;
  final int lineDefined;
  final int lastLineDefined;
  final int numParams;
  final int isVararg;
  final int maxStackSize;
  final List<int> codes;
  final List constants;
  final List<Upvalue> upvalues;
  final List<ProtoType> protos;
  final List<int> lineInfo;
  final List<LocVar> locVars;
  final List<String> upvaluesName;

  ProtoType(
      this.source,
      this.lineDefined,
      this.lastLineDefined,
      this.numParams,
      this.isVararg,
      this.maxStackSize,
      this.codes,
      this.constants,
      this.upvalues,
      this.protos,
      this.lineInfo,
      this.locVars,
      this.upvaluesName);
}

class BinaryChunk {
  final Header header;
  final String sizeUpvalues;
  final ProtoType mainFunc;

  BinaryChunk(this.header, this.sizeUpvalues, this.mainFunc);
}

ProtoType unDump(Uint8List data) {
  Reader reader = Reader(data);
  print(reader.checkHeader());
  reader.readByte();
  return reader.readProto('');
}
