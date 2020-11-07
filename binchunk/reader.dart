import 'dart:typed_data';

import '../constants.dart';
import '../utils.dart';
import 'binary_chunk.dart';

class Reader{
  String data;

  Reader(String this.data);

  String readByte(){
    String b = data.substring(0, 2);
    data = data.substring(2);
    return b;
  }

  int readUint32(){
    int n = hex2Int(this.data.substring(0, 8));
    data = data.substring(8);
    return n;
  }

  int readUint64(){
    int n = hex2Int(data.substring(0, 16));
    data = data.substring(16);
    return n;
  }

  int readLuaInteger(){
    return readUint64();
  }

  double readLuaNumber(){
    return convert2ByteData(data).getFloat64(0, Endian.little);
  }

  String readBytes(int n){
    String bytes = data.substring(0, 2 * n);
    data = data.substring(2 * n);
    return bytes;
  }

  String readString(){
    int size = hex2Int(readByte());
    if(size == 0){
      return '';
    }
    if(size == 255){
      size = readUint64();
    }
    return hex2String(readBytes(size - 1));
  }

  String checkHeader() {
    if (readBytes(4) != LUA_SIGNATURE) return 'not compiled chunk';
    if (readByte() != LUAC_VERSION) return 'mismatch version';
    if (readByte() != LUAC_FORMAT) return 'mismatch format';
    if (readBytes(6) != LUAC_DATA) return 'wrong luac_data';
    if (readByte() != CINT_SIZE) return 'wrong cint size';
    if (readByte() != CSIZET_SIZE) return 'wrong csizet size';
    if (readByte() != INSTRUCTION_SIZE) return 'wrong instruction size';
    if (readByte() != LUA_INTEGER_SIZE) return 'wrong lua integer size';
    if (readByte() != LUA_NUMBER_SIZE) return 'wrong lua num size';
    if (readLuaInteger() != LUAC_INT) return 'endianness mismatch';
    if (readLuaNumber() != LUAC_NUM) return 'float format mismatch';
    return 'all ok';
  }

  List<int> readCode(){
    List<int> codes = [];
    for(int i = 0; i < readUint32(); i++){
      codes[i] = readUint32();
    }
    return codes;
  }

  List readConstants(){
    List constants = [];
    for(int i = 0; i < readUint32(); i++){
      constants[i] = readConstant();
    }
    return constants;
  }

  dynamic readConstant(){
    switch(readByte()){
      case TAG_NIL:
        return null;
      case TAG_BOOLEAN:
        return readByte() != '0';
      case TAG_INTEGER:
        return readLuaInteger();
      case TAG_NUMBER:
        return readLuaNumber();
      case TAG_SHORT_STR:
        return readString();
      case TAG_LONG_STR:
        return readString();
      default:
        throw TypeError();
    }
  }

  List<Upvalue> readUpvalues(){
    List<Upvalue> upValues = [];
    for(int i = 0; i < readUint32(); i++){
      upValues[i] = Upvalue(readByte(), readByte());
    }
    return upValues;
  }

  List<ProtoType> readProtos(String parentSource){
    List<ProtoType> protos = [];
    for(int i = 0; i < readUint32(); i++){
      protos[i] = readProto(parentSource);
    }
    return protos;
  }

  List<int> readLineInfo(){
    List<int> lineInfo = [];
    for(int i = 0; i < readUint32(); i++){
      lineInfo[i] = readUint32();
    }
    return lineInfo;
  }

  List<LocVar> readLocVars(){
    List<LocVar> locVars = [];
    for(int i = 0; i < readUint32(); i++){
      locVars[i] = LocVar(readString(), readUint32(), readUint32());
    }
    return locVars;
  }

  List<String> readUpvalueNames(){
    List<String> names = [];
    for(int i = 0; i < readUint32(); i++){
      names[i] = readString();
    }
    return names;
  }

  ProtoType readProto(String parentSource){
    String source = readString();
    if(source == '')source = parentSource;
    return ProtoType(
        source,
        readUint32(),
        readUint32(),
        readByte(),
        readByte(),
        readByte(),
        readCode(),
        readConstants(),
        readUpvalues(),
        readProtos(source),
        readLineInfo(),
        readLocVars(),
        readUpvalueNames()
    );
  }
}