import 'dart:typed_data';

import 'package:luart/src/binary/chunk.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/utils.dart';

class Reader {
  Uint8List data;

  Reader(this.data);

  ByteData readByte() {
    final b = data.sublist(0, 1).buffer.asByteData(0, 1);
    data = data.sublist(1);
    return b;
  }

  int readUint32() {
    final n = data.sublist(0, 4);
    data = data.sublist(4);
    return n.buffer.asByteData().getUint32(0, Endian.little);
  }

  int readUint64() {
    final n = data.sublist(0, 8);
    data = data.sublist(8);
    return n.buffer.asByteData().getUint64(0, Endian.little);
  }

  int readLuaInteger() => readUint64();

  double readLuaNumber() {
    final n = data.sublist(0, 8);
    data = data.sublist(8);
    return n.buffer.asByteData().getFloat64(0, Endian.little);
  }

  ByteData readBytes(int n) {
    final bytes = data.sublist(0, n).buffer.asByteData();
    data = data.sublist(n);
    return bytes;
  }

  String readString() {
    var size = readByte().getInt8(0);
    if (size == 0) {
      return '';
    }
    if (size == 255) {
      size = readUint64();
    }
    return hex2String(byteData2String(readBytes(size - 1)));
  }

  String checkHeader() {
    if (byteData2String(readBytes(4)) != luaSignature) {
      return 'not compiled chunk';
    }
    if (byteData2String(readByte()) != luacVersion) return 'mismatch version';
    if (byteData2String(readByte()) != luacFormat) return 'mismatch format';
    if (byteData2String(readBytes(6)) != luacData) return 'wrong luac_data';
    if (readByte().getUint8(0) != cIntSize) return 'wrong cint size';
    if (readByte().getUint8(0) != cSizetSize) return 'wrong csizet size';
    if (readByte().getUint8(0) != instructionSize) {
      return 'wrong instruction size';
    }
    if (readByte().getUint8(0) != luaIntegerSize) {
      return 'wrong lua integer size';
    }
    if (readByte().getUint8(0) != luaNumberSize) return 'wrong lua num size';
    if (readLuaInteger() != luacInt) return 'endianness mismatch';
    if (readLuaNumber() != luacNum) return 'format mismatch';
    return 'check header: all ok';
  }

  List<int> readCode() {
    final codes = <int>[];
    final len = readUint32();
    for (var i = 0; i < len; i++) {
      codes.add(readUint32());
    }
    return codes;
  }

  List<Object?> readConstants() {
    final constants = <Object?>[];
    final len = readUint32();
    for (var i = 0; i < len; i++) {
      constants.add(readConstant());
    }
    return constants;
  }

  Object? readConstant() {
    final tag = byteData2String(readByte());
    switch (tag) {
      case tagNil:
        return null;
      case tagBoolean:
        return byteData2String(readByte()) != '00';
      case tagInteger:
        return readLuaInteger();
      case tagNumber:
        return readLuaNumber();
      case tagShortStr:
        return readString();
      case tagLongStr:
        return readString();
      default:
        throw TypeError();
    }
  }

  List<Upvalue> readUpvalues() {
    final upValues = <Upvalue>[];
    final len = readUint32();
    for (var i = 0; i < len; i++) {
      upValues.add(Upvalue(byte2Int(readByte()), byte2Int(readByte())));
    }
    return upValues;
  }

  List<LuaPrototype> readProtos(String parentSource) {
    final protos = <LuaPrototype>[];
    final len = readUint32();
    for (var i = 0; i < len; i++) {
      protos.add(readProto(parentSource));
    }
    return protos;
  }

  List<int> readLineInfo() {
    final lineInfo = <int>[];
    final len = readUint32();
    for (var i = 0; i < len; i++) {
      lineInfo.add(readUint32());
    }
    return lineInfo;
  }

  List<LocVar> readLocVars() {
    final locVars = <LocVar>[];
    final len = readUint32();
    for (var i = 0; i < len; i++) {
      locVars.add(LocVar(readString(), readUint32(), readUint32()));
    }
    return locVars;
  }

  List<String> readUpvalueNames() {
    final names = <String>[];
    final len = readUint32();
    for (var i = 0; i < len; i++) {
      names.add(readString());
    }
    return names;
  }

  LuaPrototype readProto(String parentSource) {
    var source = readString();
    if (source == '') source = parentSource;
    return LuaPrototype(
      source: source,
      lineDefined: readUint32(),
      lastLineDefined: readUint32(),
      numParams: byte2Int(readByte()),
      isVararg: byte2Int(readByte()),
      maxStackSize: byte2Int(readByte()),
      codes: readCode(),
      constants: readConstants(),
      upvalues: readUpvalues(),
      protos: readProtos(source),
      lineInfo: readLineInfo(),
      locVars: readLocVars(),
      upvalueNames: readUpvalueNames(),
    );
  }
}
