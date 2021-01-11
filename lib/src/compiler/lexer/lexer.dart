import 'package:luart/luart.dart';
import 'package:luart/src/compiler/lexer/token.dart';

final reNewLine = RegExp('\r\n|\n\r|\n|\r');
final reIdentifier = RegExp(r'^[_\d\w]+');
final reNumber = RegExp(
  r'^0[xX][0-9a-fA-F]*(\.[0-9a-fA-F]*)?([pP][+\-]?[0-9]+)?|^[0-9]*(\.[0-9]*)?([eE][+\-]?[0-9]+)?',
);
final reShortStr = RegExp(
  r'''(^'(\\\\|\\'|\\\n|\\z\s*|[^'\n])*')|(^"(\\\\|\\"|\\\n|\\z\s*|[^"\n])*")''',
);
final reOpeningLongBracket = RegExp(r'^\[=*\[');

final reDecEscapeSeq = RegExp(r'^\\[0-9]{1,3}');
final reHexEscapeSeq = RegExp(r'^\\x[0-9a-fA-F]{2}');
final reUnicodeEscapeSeq = RegExp(r'^\\u\{[0-9a-fA-F]+\}');

class LuaLexer {
  LuaLexer(this.chunk, this.chunkName);

  /// source code
  String chunk;

  /// source name
  final String chunkName;

  /// current line number
  var _line = 1;

  var _nextToken = '';

  var _nextTokenKind = 0;

  var _nextTokenLine = 0;

  int get line {
    return _line;
  }

  int lookAhead() {
    if (_nextTokenLine > 0) {
      return _nextTokenKind;
    }

    final currentLine = _line;
    final token = nextToken();
    _line = currentLine;
    _nextTokenLine = token.line;
    _nextTokenKind = token.kind;
    _nextToken = token.value;
    return token.kind;
  }

  LuaToken nextIdentifier() {
    return nextTokenOfKind(LuaTokens.identifier);
  }

  LuaToken nextTokenOfKind(int kind) {
    final token = nextToken();
    if (token.kind != kind) {
      throw error('syntax error near $token');
    }
    return token;
  }

  LuaToken nextToken() {
    if (_nextTokenLine > 0) {
      _line = _nextTokenLine;
      _nextTokenLine = 0;
      return LuaToken(
        line: _nextTokenLine,
        kind: _nextTokenKind,
        value: _nextToken,
      );
    }

    skipWhiteSpaces();

    if (chunk.isEmpty) {
      return LuaToken(line: line, kind: LuaTokens.eof, value: 'EOF');
    }

    switch (chunk[0]) {
      case ';':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.sepSemi, value: ';');
      case ',':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.sepComma, value: ',');
      case '(':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.sepLparen, value: '(');
      case ')':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.sepRparen, value: ')');
      case ']':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.sepRbrack, value: ']');
      case '{':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.sepLcurly, value: '{');
      case '}':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.sepRcurly, value: '}');
      case '+':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.opAdd, value: '+');
      case '-':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.opMinus, value: '-');
      case '*':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.opMul, value: '*');
      case '^':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.opPow, value: '^');
      case '%':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.opMod, value: '%');
      case '&':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.opBand, value: '&');
      case '|':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.opBor, value: '|');
      case '#':
        next(1);
        return LuaToken(line: _line, kind: LuaTokens.opLen, value: '#');
      case ':':
        if (test('::')) {
          next(2);
          return LuaToken(line: _line, kind: LuaTokens.sepLabel, value: '::');
        } else {
          next(1);
          return LuaToken(line: _line, kind: LuaTokens.sepColon, value: ':');
        }
      case '/':
        if (test('//')) {
          next(2);
          return LuaToken(line: _line, kind: LuaTokens.opIdiv, value: '//');
        } else {
          next(1);
          return LuaToken(line: _line, kind: LuaTokens.opDiv, value: '/');
        }
      case '~':
        if (test('~=')) {
          next(2);
          return LuaToken(line: _line, kind: LuaTokens.opNe, value: '~=');
        } else {
          next(1);
          return LuaToken(line: _line, kind: LuaTokens.opWave, value: '~');
        }
      case '=':
        if (test('==')) {
          next(2);
          return LuaToken(line: _line, kind: LuaTokens.opEq, value: '==');
        } else {
          next(1);
          return LuaToken(line: _line, kind: LuaTokens.opAssign, value: '=');
        }
      case '<':
        if (test('<<')) {
          next(2);
          return LuaToken(line: _line, kind: LuaTokens.opShl, value: '<<');
        } else if (test('<=')) {
          next(2);
          return LuaToken(line: _line, kind: LuaTokens.opLe, value: '<=');
        } else {
          next(1);
          return LuaToken(line: _line, kind: LuaTokens.opLt, value: '<');
        }
      case '>':
        if (test('>>')) {
          next(2);
          return LuaToken(line: _line, kind: LuaTokens.opShr, value: '>>');
        } else if (test('>=')) {
          next(2);
          return LuaToken(line: _line, kind: LuaTokens.opGe, value: '>=');
        } else {
          next(1);
          return LuaToken(line: _line, kind: LuaTokens.opGt, value: '>');
        }
      case '.':
        if (test('...')) {
          next(3);
          return LuaToken(line: _line, kind: LuaTokens.vararg, value: '...');
        } else if (test('..')) {
          next(2);
          return LuaToken(line: _line, kind: LuaTokens.opConcat, value: '..');
        } else if (chunk.length == 1 || !isDigit(chunk)) {
          next(1);
          return LuaToken(line: _line, kind: LuaTokens.sepDot, value: '.');
        }
        break;
      case '[':
        if (test('[[') || test('[=')) {
          return LuaToken(
              line: _line, kind: LuaTokens.string, value: scanLongString());
        } else {
          next(1);
          return LuaToken(line: _line, kind: LuaTokens.sepLbrack, value: '[');
        }
      case "'":
      case '"':
        return LuaToken(
          line: _line,
          kind: LuaTokens.string,
          value: scanShortString(),
        );
    }

    final c = chunk[0];
    if (c == '.' || isDigit(c)) {
      final token = scanNumber();
      return LuaToken(line: _line, kind: LuaTokens.number, value: token);
    }
    if (c == '_' || isLetter(c)) {
      final token = scanIdentifier();
      final keyword = keywords[token];
      if (keyword != null) {
        return LuaToken(line: _line, kind: keyword, value: token);
      } else {
        return LuaToken(line: _line, kind: LuaTokens.identifier, value: token);
      }
    }

    throw error('unexpected symbol near $c');
  }

  void next(int n) {
    chunk = chunk.substring(n);
  }

  bool test(String s) {
    return chunk.startsWith(s);
  }

  LuaCompilerError error(String message) {
    return LuaCompilerError('$chunkName:$line message');
  }

  void skipWhiteSpaces() {
    while (chunk.isNotEmpty) {
      if (test('--')) {
        skipComment();
      } else if (test('\r\n') || test('\n\r')) {
        next(2);
        _line += 1;
      } else if (isNewLine(chunk[0])) {
        next(1);
        _line += 1;
      } else if (isWhiteSpace(chunk[0])) {
        next(1);
      } else {
        break;
      }
    }
  }

  void skipComment() {
    next(2); // skip --

    // long comment ?
    if (test('[')) {
      if (reOpeningLongBracket.hasMatch(chunk)) {
        scanLongString();
        return;
      }
    }

    // short comment
    while (chunk.isNotEmpty && !isNewLine(chunk[0])) {
      next(1);
    }
  }

  String scanIdentifier() {
    return scan(reIdentifier);
  }

  String scanNumber() {
    return scan(reNumber);
  }

  String scan(RegExp re) {
    final match = re.firstMatch(chunk);
    if (match != null) {
      final token = chunk.substring(match.start, match.end);
      next(token.length);
      return token;
    }
    throw error('token expected');
  }

  String scanLongString() {
    final openingLongBracketMatch = reOpeningLongBracket.firstMatch(chunk);
    if (openingLongBracketMatch == null) {
      throw error(
          "invalid long string delimiter near '${chunk.substring(0, 2)}'");
    }

    final openingLongBracket = openingLongBracketMatch.group(0)!;

    final closingLongBracket = openingLongBracket.replaceAll('[', ']');
    final closingLongBracketIdx = chunk.indexOf(closingLongBracket);
    if (closingLongBracketIdx < 0) {
      throw error('unfinished long string or comment');
    }

    var str = chunk.substring(openingLongBracket.length, closingLongBracketIdx);
    next(closingLongBracketIdx + closingLongBracket.length);

    str = str.replaceAll(reNewLine, '\n');
    _line += str.allMatches('\n').length;
    if (str.isNotEmpty && str[0] == '\n') {
      str = str.substring(1);
    }

    return str;
  }

  String scanShortString() {
    final strMatch = reShortStr.firstMatch(chunk);
    if (strMatch != null) {
      var str = strMatch.group(0)!;
      next(str.length);
      str = str.substring(1, str.length - 1);
      if (str.contains(r'\')) {
        _line += reNewLine.allMatches(str).length;
        str = escape(str);
      }
      return str;
    }
    throw error('unfinished string');
  }

  String escape(String str) {
    final buf = StringBuffer();

    while (str.isNotEmpty) {
      if (!str.startsWith(r'\')) {
        buf.writeCharCode(str.codeUnitAt(0));
        str = str.substring(1);
        continue;
      }

      if (str.length == 1) {
        throw error('unfinished string');
      }

      switch (str[1]) {
        case 'a':
          buf.write('\a');
          str = str.substring(2);
          continue;
        case 'b':
          buf.write('\b');
          str = str.substring(2);
          continue;
        case 'f':
          buf.write('\f');
          str = str.substring(2);
          continue;
        case 'n':
        case '\n':
          buf.write('\n');
          str = str.substring(2);
          continue;
        case 'r':
          buf.write('\r');
          str = str.substring(2);
          continue;
        case 't':
          buf.write('\t');
          str = str.substring(2);
          continue;
        case 'v':
          buf.write('\v');
          str = str.substring(2);
          continue;
        case '"':
          buf.write('"');
          str = str.substring(2);
          continue;
        case '\'':
          buf.write('\'');
          str = str.substring(2);
          continue;
        case '\\':
          buf.write('\\');
          str = str.substring(2);
          continue;
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9': // \ddd
          final match = reDecEscapeSeq.firstMatch(str);
          if (match != null) {
            final found = match.group(0)!;
            final digit = int.parse(found.substring(1), radix: 10);
            if (digit <= 0xFF) {
              buf.writeCharCode(digit);
              str = str.substring(found.length);
              continue;
            }
            throw error("decimal escape too large near '$found'");
          }
          break;
        case 'x': // \xXX
          final match = reHexEscapeSeq.firstMatch(str);
          if (match != null) {
            final found = match.group(0)!;
            final digit = int.parse(found.substring(2), radix: 16);
            buf.writeCharCode(digit);
            str = str.substring(found.length);
            continue;
          }
          break;
        case 'u': // \u{XXX}
          final match = reUnicodeEscapeSeq.firstMatch(str);
          if (match != null) {
            final found = match.group(0)!;
            final digit =
                int.tryParse(found.substring(3, found.length - 1), radix: 16);
            if (digit != null && digit <= 0x10FFFF) {
              buf.writeCharCode(digit);
              str = str.substring(found.length);
              continue;
            }
            throw error("UTF-8 value too large near '$found'");
          }
          break;
        case 'z':
          str = str.substring(2);
          while (str.isNotEmpty && isWhiteSpace(str[0])) {
            // todo
            str = str.substring(1);
          }
          continue;
      }
      throw error("invalid escape sequence near '\\${str[1]}'");
    }

    return buf.toString();
  }
}

bool isWhiteSpace(String c) {
  const whiteSpaces = {'\t', '\n', '\v', '\f', '\r', ' '};
  return whiteSpaces.contains(c);
}

bool isNewLine(String c) {
  return c == '\r' || c == '\n';
}

final char0 = '0'.codeUnitAt(0);
final char9 = '9'.codeUnitAt(0);

bool isDigit(String c) {
  final code = c.codeUnitAt(0);
  return code >= char0 && code <= char9;
}

final chara = 'a'.codeUnitAt(0);
final charz = 'z'.codeUnitAt(0);
final charA = 'A'.codeUnitAt(0);
final charZ = 'Z'.codeUnitAt(0);

bool isLetter(String c) {
  final code = c.codeUnitAt(0);
  return code >= chara && code <= charz || code >= charA && code <= charZ;
}
