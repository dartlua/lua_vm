import 'package:luart/auxlib.dart';
import 'package:luart/luart.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/utils.dart';

int openUTF8Lib(LuaState ls) {
  final lib = LuaStdlibUTF8();
  final funcs = <String, LuaDartFunction>{
    'len':       lib.utfLen,
	  'offset':    lib.utfByteOffset,
	  'codepoint': lib.utfCodePoint,
	  'char':      lib.utfChar,
	  'codes':     lib.utfIterCodes,
	  /* placeholders */
	  // 'charpattern': nil,
  };

  ls.newLib(funcs);
  ls.pushString(UTF8PATT);
	ls.setField(-2, 'charpattern');
	return 1;
}

class LuaLibUTF8Behavior {}

class LuaStdlibUTF8 {
  // utf8.len (s [, i [, j]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-utf8.len
  // lua-5.3.4/src/lutf8lib.c#utflen()
  int utfLen(LuaState ls) {
  	final s = ls.checkString(1)!;
  	final sLen = s.length;
  	final i = posRelat(ls.optInt(2, 1), sLen);
  	final j = posRelat(ls.optInt(3, -1), sLen);
  	ls.argCheck(1 <= i && i <= sLen+1, 2,
  		'initial position out of string');
  	ls.argCheck(j <= sLen, 3,
  		'final position out of string');
  
  	if (i > j) {
  		ls.pushInt(0);
  	} else {
  		final n = (s.substring(i-1, j)).runes.length;
  		ls.pushInt(n);
  	}
  
  	return 1;
  }
  
  // utf8.offset (s, n [, i])
  // http://www.lua.org/manual/5.3/manual.html#pdf-utf8.offset
 int utfByteOffset(LuaState ls) {
  	final s = ls.checkString(1)!;
  	final sLen = s.length;
  	var n = ls.checkInt(2)!;
  	var i = 1;
  	if (n < 0) {
  		i = sLen + 1;
  	}
  	i = posRelat(ls.optInt(3, i), sLen);
  	ls.argCheck(1 <= i && i <= sLen+1, 3, 'position out of range');
  	i--;
  
  	if (n == 0) {
  		/* find beginning of current byte sequence */
  		while (i > 0 && _isCont(s.codeUnitAt(i))) {
  			i--;
  		}
  	} else {
  		if (i < sLen && _isCont(s.codeUnitAt(i))) {
  			ls.error2('initial position is a continuation byte');
  		}
  		if (n < 0) {
  			while (n < 0 && i > 0) { /* move back */
  				while (true) { /* find beginning of previous character */
  					i--;
  					if (!(i > 0 && _isCont(s.codeUnitAt(i)))) {
  						break;
  					}
  				}
  				n++;
  			}
  		} else {
  			n--; /* do not move for 1st character */
  			while (n > 0 && i < sLen) {
  				while (true) { /* find beginning of next character */
  					i++;
  					if (i >= sLen || !_isCont(s[i].codeUnitAt(0))) {
  						break; /* (cannot pass final '\0') */
  					}
  				}
  				n--;
  			}
  		}
  	}
  	if (n == 0) { /* did it find given character? */
  		ls.pushInt(i + 1);
  	} else { /* no such character */
  		ls.pushNil();
  	}
  	return 1;
  }
  
  // utf8.codepoint (s [, i [, j]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-utf8.codepoint
  // lua-5.3.4/src/lutf8lib.c#codepoint()
  int utfCodePoint(LuaState ls) {
  	var s = ls.checkString(1)!;
  	final sLen = s.length;
  	var i = posRelat(ls.optInt(2, 1), sLen);
  	final j = posRelat(ls.optInt(3, i), sLen);
  
  	ls.argCheck(i >= 1, 2, 'out of range');
  	ls.argCheck(j <= sLen, 3, 'out of range');
  	if (i > j) {
  		return 0; /* empty interval; return no values */
  	}
  	if (j-i >= LUA_MAXINTEGER) { /* (lua_Integer -> int) overflow? */
  		return ls.error2('string slice too long');
  	}
  	var n = j - i + 1;
  	ls.checkStack2(n, 'string slice too long');
  
  	n = 0;
  	s = s.substring(i-1);
  	while (i <= j) {
  		var code = Runes(s).first;
  		ls.pushInt(code);
  		n++;
  		i++;
  		s = s.substring(1);
  	}
  	return n;
  }
  
  // utf8.char (···)
  // http://www.lua.org/manual/5.3/manual.html#pdf-utf8.char
  // lua-5.3.4/src/lutf8lib.c#utfchar()
  int utfChar(LuaState ls) {
  	final n = ls.getTop(); /* number of arguments */
  	var codePoints = List.filled(n, 0);
  
  	for (var i = 1; i <= n; i++) {
  		final cp = ls.checkInt(i)!;
  		ls.argCheck(0 <= cp && cp <= MAX_UNICODE, i, 'value out of range');
  		codePoints[i-1] = cp;
  	}
  
  	ls.pushString(String.fromCharCodes(codePoints));
  	return 1;
  }
  
  // utf8.codes (s)
  // http://www.lua.org/manual/5.3/manual.html#pdf-utf8.codes
  int utfIterCodes(LuaState ls) {
  	ls.checkString(1);
  	ls.pushDartFunction(_iterAux);
  	ls.pushValue(1);
  	ls.pushInt(0);
  	return 3;
  }
  
  int _iterAux(LuaState ls) {
  	final s = ls.checkString(1)!;
  	final sLen = s.length;
  	var n = ls.toInt(2) - 1;
  	if (n < 0) { /* first iteration? */
  		n = 0; /* start from here */
  	} else if (n < sLen) {
  		n++; /* skip current byte */
  		while (n < sLen && _isCont(s.codeUnitAt(n))) {
  			n++;
  		} /* and its continuations */
  	}
  	if (n >= sLen) {
  		return 0; /* no more codepoints */
  	} else {
  		final code = s.substring(n).codeUnits[0];
  		ls.pushInt(n + 1);
  		ls.pushInt(code);
  		return 2;
  	}
  }
  
  bool _isCont(int b) {
  	return b&0xC0 == 0x80;
  }
}