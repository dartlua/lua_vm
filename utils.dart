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

String hex2String(String hex){
  int len = hex.length ~/ 2;
  String s = '';
  for(int i = 0; i <= len; i++){
    s += String.fromCharCode(int.tryParse(hex.substring(0, 2), radix: 16));
  }
  return s;
}

int hex2Int(String hex){
  return int.parse(hex, radix: 16);
}