import 'dart:typed_data';

import 'binchunk/reader.dart';
import 'utils.dart';

void main(){
  //String to hex
  String str = 'L';
  str.codeUnits.forEach((int strInt) => print(strInt.toRadixString(16)));

  //hex to String
  String hex = '4c';
  print(String.fromCharCode(int.tryParse(hex, radix: 16)));

  print(Reader('044c7561').readString());

  print(ByteData.sublistView(convert2ByteData('014c'), 1, 2));
}
