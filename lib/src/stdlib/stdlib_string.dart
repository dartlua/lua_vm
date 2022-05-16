import 'package:luart/auxlib.dart';
import 'package:luart/luart.dart';
import 'package:luart/src/utils.dart';
import 'package:sprintf/sprintf.dart';

int openStringLib(LuaState ls) {
  final lib = LuaStdlibString();
  final funcs = <String, LuaDartFunction>{
    'len': lib.strLen,
    'rep': lib.strRep,
    'reverse': lib.strReverse,
    'lower': lib.strLower,
    'upper': lib.strUpper,
    'sub': lib.strSub,
    'byte': lib.strByte,
    'char': lib.strChar,
    'dump': lib.strDump,
    'format': lib.strFormat,
    'packsize': lib.strPackSize,
    'pack': lib.strPack,
    'unpack': lib.strUnpack,
    'find': lib.strFind,
    'match': lib.strMatch,
    'gsub': lib.strGsub,
    'gmatch': lib.strGmatch,
  };

  ls.newLib(funcs);
  return 1;
}

class LuaLibStringBehavior {}

class LuaStdlibString {
  void createMetatable(LuaState ls) {
    ls.createTable(0, 1); /* table to be metatable for strings */
    ls.pushString('dummy'); /* dummy string */
    ls.pushValue(-2); /* copy table */
    ls.setMetatable(-2); /* set table as metatable for strings */
    ls.pop(1); /* pop dummy string */
    ls.pushValue(-2); /* get string library */
    ls.setField(-2, '__index'); /* metatable.__index = string */
    ls.pop(1); /* pop metatable */
  }

  /* Basic String Functions */

  // string.len (s)
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.len
  // lua-5.3.4/src/lstrlib.c#str_len()
  int strLen(LuaState ls) {
    final s = ls.checkString(1);
    ls.pushInt(s.length);
    return 1;
  }

  // string.rep (s, n [, sep])
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.rep
  // lua-5.3.4/src/lstrlib.c#str_rep()
  int strRep(LuaState ls) {
    final s = ls.checkString(1);
    final n = ls.checkInt(2);
    final sep = ls.optString(3, '');

    if (n <= 0) {
      ls.pushString('');
    } else if (n == 1) {
      ls.pushString(s);
    } else {
      final a = List.filled(n, '');
      for (var i = 0; i < n; i++) {
        a[i] = s;
      }
      ls.pushString(a.join(sep!));
    }

    return 1;
  }

  // string.reverse (s)
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.reverse
  // lua-5.3.4/src/lstrlib.c#str_reverse()
  int strReverse(LuaState ls) {
    final s = ls.checkString(1);
    final strLen = s.length;
    if (strLen > 1) {
      ls.pushString(s.split('').reversed.join());
    }

    return 1;
  }

  // string.lower (s)
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.lower
  // lua-5.3.4/src/lstrlib.c#str_lower()
  int strLower(LuaState ls) {
    final s = ls.checkString(1);
    ls.pushString(s.toLowerCase());
    return 1;
  }

  // string.upper (s)
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.upper
  // lua-5.3.4/src/lstrlib.c#str_upper()
  int strUpper(LuaState ls) {
    final s = ls.checkString(1);
    ls.pushString(s.toUpperCase());
    return 1;
  }

  // string.sub (s, i [, j])
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.sub
  // lua-5.3.4/src/lstrlib.c#str_sub()
  int strSub(LuaState ls) {
    final s = ls.checkString(1);
    final sLen = s.length;
    var i = posRelat(ls.checkInt(2), sLen);
    var j = posRelat(ls.optInt(3, -1), sLen);

    if (i < 1) {
      i = 1;
    }
    if (j > sLen) {
      j = sLen;
    }

    if (i <= j) {
      ls.pushString(s.substring(i - 1, j));
    } else {
      ls.pushString('');
    }

    return 1;
  }

  // string.byte (s [, i [, j]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.byte
  // lua-5.3.4/src/lstrlib.c#str_byte()
  int strByte(LuaState ls) {
    final s = ls.checkString(1);
    final sLen = s.length;
    var i = posRelat(ls.optInt(2, 1), sLen);
    var j = posRelat(ls.optInt(3, i), sLen);

    if (i < 1) {
      i = 1;
    }
    if (j > sLen) {
      j = sLen;
    }

    if (i > j) {
      return 0; /* empty interval; return no values */
    }
    //if (j - i >= INT_MAX) { /* arithmetic overflow? */
    //  return ls.Error2("string slice too long")
    //}

    final n = j - i + 1;
    ls.checkStack2(n, 'string slice too long');

    for (var k = 0; k < n; k++) {
      ls.pushInt(s.codeUnitAt(i + k - 1));
    }
    return n;
  }

  // string.char (···)
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.char
  // lua-5.3.4/src/lstrlib.c#str_char()
  int strChar(LuaState ls) {
    final nArgs = ls.getTop();

    final s = List.filled(nArgs, 0); //todo
    for (var i = 1; i <= nArgs; i++) {
      final c = ls.checkInt(i);
      ls.argCheck(c == c, i, 'value out of range');
      s[i - 1] = c;
    }

    ls.pushString(String.fromCharCodes(s));
    return 1;
  }

  // string.dump (function [, strip])
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.dump
  // lua-5.3.4/src/lstrlib.c#str_dump()
  int strDump(LuaState ls) {
    // strip := ls.ToBoolean(2)
    // ls.CheckType(1, LUA_TFUNCTION)
    // ls.SetTop(1)
    // ls.PushString(string(ls.Dump(strip)))
    // return 1
    throw LuaError('todo: strDump!');
  }

  /* PACK/UNPACK */

  // string.packsize (fmt)
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.packsize
  int strPackSize(LuaState ls) {
    final fmt = ls.checkString(1);
    if (fmt == 'j') {
      ls.pushInt(8); // todo
    } else {
      throw LuaError('todo: strPackSize!');
    }
    return 1;
  }

  // string.pack (fmt, v1, v2, ···)
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.pack
  int strPack(LuaState ls) {
    throw LuaError('todo: strPack!');
  }

  // string.unpack (fmt, s [, pos])
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.unpack
  int strUnpack(LuaState ls) {
    throw LuaError('todo: strUnpack!');
  }

  /* STRING FORMAT */

  // string.format (formatstring, ···)
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.format
  int strFormat(LuaState ls) {
    final fmtStr = ls.checkString(1);
    if (fmtStr.length <= 1 || !fmtStr.contains('%')) {
      ls.pushString(fmtStr);
      return 1;
    }

    var argIdx = 1;
    final arr = parseFmtStr(fmtStr);
    for (var i = 0; i < arr.length; i++) {
      var s = arr[i];
      if (s[0] == '%') {
        if (s == '%%') {
          arr[i] = '%';
        } else {
          if (s == '%q') s = '%s';
          argIdx += 1;
          arr[i] = _fmtArg(s, ls, argIdx);
        }
      }
    }

    ls.pushString(arr.join());
    return 1;
  }

  String _fmtArg(String tag, LuaState ls, int argIdx) {
    switch (tag[tag.length - 1]) {
      // specifier
      case 'c': // character
        return ls.toInt(argIdx).toRadixString(16);
      case 'i':
        final tag2 = '${tag.substring(0, tag.length - 1)}d'; // %i -> %d
        return sprintf(tag2, [ls.toInt(argIdx)]);
      case 'd': // integer, octal
        return sprintf(tag, [ls.toInt(argIdx)]);
      case 'o':
        return sprintf(tag, [ls.toInt(argIdx)]);
      case 'u': // unsigned integer
        final tag2 = '${tag.substring(0, tag.length - 1)}d'; // %u -> %d
        return sprintf(tag2, [ls.toInt(argIdx)]);
      case 'x': // hex integer
        return sprintf(tag, [ls.toInt(argIdx)]);
      case 'X':
        return sprintf(tag, [ls.toInt(argIdx)]);
      case 'f': // float
        return sprintf(tag, [ls.toNumber(argIdx)]);
      case 's': // string
        return sprintf(tag, [ls.toDartString(argIdx)]);
      case 'q':
        return sprintf(tag, [ls.toDartString(argIdx)]);
      case 'e':
        return sprintf(tag, [ls.toNumber(argIdx)]);
      default:
        throw LuaError('todo');
    }
  }

  /* PATTERN MATCHING */

  // string.find (s, pattern [, init [, plain]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.find
  int strFind(LuaState ls) {
    final s = ls.checkString(1);
    final sLen = s.length;
    final pattern = ls.checkString(2);
    var init = posRelat(ls.optInt(3, 1), sLen);
    if (init < 1) {
      init = 1;
    } else if (init > sLen + 1) {
      /* start after string's end? */
      ls.pushNil();
      return 1;
    }
    final plain = ls.toBool(4);

    final result = find(s, pattern, init, plain);
    final start = result.a;
    final end = result.b;

    if (start < 0) {
      ls.pushNil();
      return 1;
    }
    ls.pushInt(start);
    ls.pushInt(end);
    return 2;
  }

  // string.match (s, pattern [, init])
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.match
  int strMatch(LuaState ls) {
    final s = ls.checkString(1);
    final sLen = s.length;
    final pattern = ls.checkString(2);
    var init = posRelat(ls.optInt(3, 1), sLen);
    if (init < 1) {
      init = 1;
    } else if (init > sLen + 1) {
      /* start after string's end? */
      ls.pushNil();
      return 1;
    }

    final captures = match(s, pattern, init);

    if (captures == null) {
      ls.pushNil();
      return 1;
    } else {
      for (var i = 0; i < captures.length; i += 2) {
        final capture = s.substring(captures[i].start, captures[i].end);
        ls.pushString(capture);
      }
      return (captures.length / 2).ceil();
    }
  }

  // string.gsub (s, pattern, repl [, n])
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.gsub
  int strGsub(LuaState ls) {
    final s = ls.checkString(1);
    final pattern = ls.checkString(2);
    final repl = ls.checkString(3); // todo
    final n = ls.optInt(4, -1);

    final r = gsub(s, pattern, repl, n);
    final newStr = r.a;
    final nMatches = r.b;
    ls.pushString(newStr);
    ls.pushInt(nMatches);
    return 2;
  }

  // string.gmatch (s, pattern)
  // http://www.lua.org/manual/5.3/manual.html#pdf-string.gmatch
  int strGmatch(LuaState ls) {
    var s = ls.checkString(1);
    final pattern = ls.checkString(2);
    // TODO: convert to func, not var
    // ignore: prefer_function_declarations_over_variables
    final gmatchAux = (_) {
      final captures = match(s, pattern, 1)!;
      if (captures.isNotEmpty) {
        for (var i = 0; i < captures.length; i++) {
          final capture = s.substring(captures[i].start, captures[i].end);
          ls.pushString(capture);
        }
        s = s.substring(captures.first.end);
        return captures.length;
      }
      return 0;
    };
    ls.pushDartFunction(gmatchAux);
    return 1;
  }
}
