import 'dart:convert';
import 'dart:typed_data';

int parseHexByte(String source, int index) {
  assert(index + 2 <= source.length);
  int digit1 = hexDigitValue(source.codeUnitAt(index));
  int digit2 = hexDigitValue(source.codeUnitAt(index + 1));
  return digit1 * 16 + digit2 - (digit2 & 256);
}

int hexDigitValue(int char) {
  assert(char >= 0 && char <= 0xFFFF);
  const int digit0 = 0x30;
  const int a = 0x61;
  const int f = 0x66;
  int digit = char ^ digit0;
  if (digit <= 9) return digit;
  int letter = (char | 0x20);
  if (a <= letter && letter <= f) return letter - (a - 10);
  return -1;
}

ByteData convert2ByteData(String data) {
  return ByteData.sublistView(Utf8Encoder().convert(data));
}

String hex2String(String hex) {
  int len = hex.length ~/ 2;
  String s = '';
  for (int i = 0; i < len * 2; i += 2) {
    s += String.fromCharCode(int.tryParse(hex.substring(i, i + 2), radix: 16)!);
  }
  return s;
}

int hex2Int(String hex) {
  return int.parse(hex, radix: 16);
}

String uint8List2String(Uint8List uint8list) {
  String s = '';
  uint8list.forEach((element) {
    s += (element.toRadixString(16).padLeft(2, '0'));
  });
  return s;
}

String byteData2String(ByteData b) {
  return uint8List2String(b.buffer.asUint8List());
}

int byte2Int(ByteData b) => b.getInt8(0);
