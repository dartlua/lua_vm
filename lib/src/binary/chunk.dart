import 'dart:ffi';
import 'dart:typed_data';

import 'package:luart/src/binary/reader.dart';

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
    this.luacNum,
  );
}

class Upvalue {
  final int inStack;
  final int idx;

  Upvalue(this.inStack, this.idx);
}

class LocVar {
  final String varName;
  final int startPC;
  final int endPC;

  LocVar(this.varName, this.startPC, this.endPC);
}

class LuaPrototype {
  String? source;
  int lineDefined;
  int lastLineDefined;
  int numParams;
  int? isVararg;
  int maxStackSize;
  List<int> codes;
  List constants;
  List<Upvalue> upvalues;
  List<LuaPrototype> protos;
  List<int> lineInfo;
  List<LocVar> locVars;
  List<String> upvalueNames;

  LuaPrototype({
    this.source,
    required this.lineDefined,
    required this.lastLineDefined,
    required this.numParams,
    this.isVararg,
    required this.maxStackSize,
    required this.codes,
    required this.constants,
    required this.upvalues,
    required this.protos,
    required this.lineInfo,
    required this.locVars,
    required this.upvalueNames,
  });
}

class BinaryChunk {
  final Header header;
  final String sizeUpvalues;
  final LuaPrototype mainFunc;

  BinaryChunk(this.header, this.sizeUpvalues, this.mainFunc);
}

bool isBinaryChunk(List<int> data) {
  return data.length > 4 && _listEqual(data.sublist(0, 4), '\x1bLua'.codeUnits);
}

LuaPrototype unDump(Uint8List data) {
  var reader = Reader(data);
  print(reader.checkHeader());
  reader.readByte();
  return reader.readProto('');
}

bool _listEqual<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}
