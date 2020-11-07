import 'dart:convert';
import 'dart:typed_data';

import '../utils.dart';

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
    return ByteData.sublistView(Utf8Encoder().convert(data)).getFloat64(0, Endian.little);
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
}