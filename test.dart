import 'dart:io';
import 'binchunk/reader.dart';

Future<void> main() async {
  //String to hex
  String str = 'L';
  str.codeUnits.forEach((int strInt) => print(strInt.toRadixString(16)));

  //hex to String
  String hex = '4c';
  print(String.fromCharCode(int.tryParse(hex, radix: 16)));

  //print(Reader('044c7561').readString());

  final fileBytes =
      await File('luac.out').readAsBytes();

  print(Reader(fileBytes).checkHeader());
}
