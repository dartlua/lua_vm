import 'dart:io';
import 'model/binary_chunk.dart';

Future<void> main() async {
  final fileBytes =
      await File('luac.out').readAsBytes();

  //print(byteData2String(fileBytes.buffer.asByteData()));
  print(unDump(fileBytes));
}
