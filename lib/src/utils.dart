import 'dart:convert';
import 'dart:typed_data';

int parseHexByte(String source, int index) {
  assert(index + 2 <= source.length);
  final digit1 = hexDigitValue(source.codeUnitAt(index));
  final digit2 = hexDigitValue(source.codeUnitAt(index + 1));
  return digit1 * 16 + digit2 - (digit2 & 256);
}

int hexDigitValue(int char) {
  assert(char >= 0 && char <= 0xFFFF);
  const digit0 = 0x30;
  const a = 0x61;
  const f = 0x66;
  final digit = char ^ digit0;
  if (digit <= 9) return digit;
  final letter = char | 0x20;
  if (a <= letter && letter <= f) return letter - (a - 10);
  return -1;
}

ByteData convert2ByteData(String data) {
  return ByteData.sublistView(const Utf8Encoder().convert(data));
}

String hex2String(String hex) {
  final len = hex.length ~/ 2;
  final sb = StringBuffer();
  for (var i = 0; i < len * 2; i += 2) {
    sb.writeCharCode(int.tryParse(hex.substring(i, i + 2), radix: 16)!);
  }
  return sb.toString();
}

int hex2Int(String hex) {
  return int.parse(hex, radix: 16);
}

String uint8List2String(Uint8List uint8list) {
  final sb = StringBuffer();
  for (final element in uint8list) {
    sb.write(element.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

String byteData2String(ByteData b) {
  return uint8List2String(b.buffer.asUint8List());
}

int byte2Int(ByteData b) => b.getInt8(0);

int dayInYear(DateTime time) {
  // see: https://stackoverflow.com/a/8619946
  final now = DateTime.now();
  final start = DateTime(now.year);
  final offset = start.timeZoneOffset - now.timeZoneOffset;
  final diff = now.difference(start) + offset;
  return diff.inDays;
}

/* helper */

/* translate a relative string position: negative means back from end */
int posRelat(int pos, int _len) {
  final _pos = pos;
  if (_pos >= 0) {
    return _pos;
  } else if (-_pos > _len) {
    return 0;
  } else {
    return _len + _pos + 1;
  }
}

RegExp tagPattern = RegExp(r'%[ #+-0]?[0-9]*(\.[0-9]+)?[cdeEfgGioqsuxX%]');

List<String> parseFmtStr(String fmt) {
  if (fmt == '' || !fmt.contains('%')) {
    return [fmt];
  }

  final parsed = List<String>.empty(growable: true);
  while (true) {
    if (fmt == '') {
      break;
    }

    final loc = tagPattern.firstMatch(fmt);
    if (loc == null) {
      parsed.add(fmt);
      break;
    }

    final head = fmt.substring(0, loc.start);
    final tag = fmt.substring(loc.start, loc.end);
    final tail = fmt.substring(loc.end);

    if (head != '') {
      parsed.add(head);
    }
    parsed.add(tag);
    fmt = tail;
  }
  return parsed;
}

TwoResult<int, int> find(String s, String pattern, int init, bool plain) {
  var tail = s;
  int start;
  int end;
  if (init > 1) {
    tail = s.substring(init - 1);
  }

  if (plain) {
    start = tail.indexOf(pattern);
    end = start + pattern.length - 1;
  } else {
    final re = RegExp(replaceFormatter(pattern));
    final loc = re.firstMatch(tail);
    if (loc == null) {
      start = end = -1;
    } else {
      start = loc.start;
      end = loc.end - 1;
    }
  }
  if (start >= 0) {
    start += s.length - tail.length + 1;
    end += s.length - tail.length + 1;
  }

  return TwoResult(start, end);
}

List<RegExpMatch>? match(String s, String pattern, int init) {
  var tail = s;
  if (init > 1) {
    tail = s.substring(init - 1);
  }

  final re = RegExp(replaceFormatter(pattern));
  return re.allMatches(tail).toList();
}

String replaceFormatter(String s) {
  return s.replaceAll('%d', '[0-9]').replaceAll('%a', '[A-z]');
}

class TwoResult<T, U> {
  T a;
  U b;
  TwoResult(this.a, this.b);
}

// todo
// return String, int
TwoResult<String, int> gsub(String s, String pattern, String repl, int n) {
  final re = RegExp(pattern);
  final matches = re.allMatches(s).toList();
  for (var i = 0; i < n && i <= matches.length; i++) {
    s = s.replaceRange(matches[i].start, matches[i].end, repl);
  }
  return TwoResult(s, matches.length < n ? matches.length : n);
}
