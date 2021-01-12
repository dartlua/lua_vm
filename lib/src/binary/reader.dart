import 'dart:typed_data';

import 'package:luart/src/binary/chunk.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/utils.dart';

class Reader {
  Uint8List data;

  Reader(this.data);

  ByteData readByte() {
    var b = data.sublist(0, 1).buffer.asByteData(0, 1);
    data = data.sublist(1);
    return b;
  }

  int readUint32() {
    var n = data.sublist(0, 4);
    data = data.sublist(4);
    return n.buffer.asByteData().getUint32(0, Endian.little);
  }

  int readUint64() {
    var n = data.sublist(0, 8);
    data = data.sublist(8);
    return n.buffer.asByteData().getUint64(0, Endian.little);
  }

  int readLuaInteger() => readUint64();

  double readLuaNumber() {
    var n = data.sublist(0, 8);
    data = data.sublist(8);
    return n.buffer.asByteData().getFloat64(0, Endian.little);
  }

  ByteData readBytes(int n) {
    var bytes = data.sublist(0, n).buffer.asByteData(0);
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
    if (byteData2String(readBytes(4)) != LUA_SIGNATURE) {
      return 'not compiled chunk';
    }
    if (byteData2String(readByte()) != LUAC_VERSION) return 'mismatch version';
    if (byteData2String(readByte()) != LUAC_FORMAT) return 'mismatch format';
    if (byteData2String(readBytes(6)) != LUAC_DATA) return 'wrong luac_data';
    if (readByte().getUint8(0) != CINT_SIZE) return 'wrong cint size';
    if (readByte().getUint8(0) != CSIZET_SIZE) return 'wrong csizet size';
    if (readByte().getUint8(0) != INSTRUCTION_SIZE) {
      return 'wrong instruction size';
    }
    if (readByte().getUint8(0) != LUA_INTEGER_SIZE) {
      return 'wrong lua integer size';
    }
    if (readByte().getUint8(0) != LUA_NUMBER_SIZE) return 'wrong lua num size';
    if (readLuaInteger() != LUAC_INT) return 'endianness mismatch';
    if (readLuaNumber() != LUAC_NUM) return 'format mismatch';
    return 'check header: all ok';
  }

  List<int> readCode() {
    var codes = <int>[];
    var len = readUint32();
    print('code len: $len');
    for (var i = 0; i < len; i++) {
      codes.add(readUint32());
    }
    return codes;
  }

  List readConstants() {
    var constants = [];
    var len = readUint32();
    for (var i = 0; i < len; i++) {
      constants.add(readConstant());
    }
    print('constants: $constants');
    return constants;
  }

  dynamic readConstant() {
    var tag = byteData2String(readByte());
    switch (tag) {
      case TAG_NIL:
        return null;
      case TAG_BOOLEAN:
        return byteData2String(readByte()) != '00';
      case TAG_INTEGER:
        return readLuaInteger();
      case TAG_NUMBER:
        return readLuaNumber();
      case TAG_SHORT_STR:
        return readString();
      case TAG_LONG_STR:
        return readString();
      default:
        print('no type tag: $tag');
        throw TypeError();
    }
  }

  List<Upvalue> readUpvalues() {
    var upValues = <Upvalue>[];
    var len = readUint32();
    for (var i = 0; i < len; i++) {
      upValues.add(Upvalue(byte2Int(readByte()), byte2Int(readByte())));
    }
    return upValues;
  }

  List<LuaPrototype> readProtos(String parentSource) {
    var protos = <LuaPrototype>[];
    var len = readUint32();
    for (var i = 0; i < len; i++) {
      protos.add(readProto(parentSource));
    }
    return protos;
  }

  List<int> readLineInfo() {
    var lineInfo = <int>[];
    var len = readUint32();
    for (var i = 0; i < len; i++) {
      lineInfo.add(readUint32());
    }
    return lineInfo;
  }

  List<LocVar> readLocVars() {
    var locVars = <LocVar>[];
    var len = readUint32();
    for (var i = 0; i < len; i++) {
      locVars.add(LocVar(readString(), readUint32(), readUint32()));
    }
    return locVars;
  }

  List<String> readUpvalueNames() {
    var names = <String>[];
    var len = readUint32();
    for (var i = 0; i < len; i++) {
      names.add(readString());
    }
    return names;
  }

  LuaPrototype readProto(String parentSource) {
    var source = readString();
    if (source == '') source = parentSource;
    print('\nsource file: $source');
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
