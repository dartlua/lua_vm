import 'dart:io';
import 'dart:typed_data';

import 'package:luart/auxlib.dart';
import 'package:luart/luart.dart';

int openBaseLib(LuaState ls) {
  final defaultBehavior = LuaBaselibBehavior(print: stdout.write);
  final baselib = LuaStdlibBase(defaultBehavior);
  final funcs = <String, LuaDartFunction>{
    'print': baselib.basePrint,
    'assert': baselib.baseAssert,
    'error': baselib.baseError,
    'select': baselib.baseSelect,
    'ipairs': baselib.baseIPairs,
    'pairs':        baselib.basePairs,
    'next':         baselib.baseNext,
    'load':         baselib.baseLoad,
    'loadfile':     baselib.baseLoadFile,
    'dofile':       baselib.baseDoFile,
    'pcall': baselib.basePCall,
    'xpcall':       baselib.baseXPCall,
    'getmetatable': baselib.baseGetMetatable,
    'setmetatable': baselib.baseSetMetatable,
    'rawequal': baselib.baseRawEqual,
    'rawlen': baselib.baseRawLen,
    'rawget': baselib.baseRawGet,
    'rawset': baselib.baseRawSet,
    'type': baselib.baseType,
    'tostring': baselib.baseToString,
    'tonumber': baselib.baseToNumber,
     /* placeholders */
    '_G':       (_) => -1,// todo
    '_VERSION': (_) => -2,// todo
  };

  ls.pushGlobalTable();
  ls.setFuncs(funcs);

  ls.pushValue(-1);
  ls.setField(-2, '_G');

  ls.pushString('Lua 5.3');
  ls.setField(-2, '_VERSION');

  return 1;
}

class LuaBaselibBehavior {
  const LuaBaselibBehavior({required this.print});

  final void Function(String) print;
}

class LuaStdlibBase {
  const LuaStdlibBase(this.behavior);

  final LuaBaselibBehavior behavior;

  // print (···)
  // http://www.lua.org/manual/5.3/manual.html#pdf-print
  // lua-5.3.4/src/lbaselib.c#luaB_print()
  int basePrint(LuaState ls) {
    final n = ls.getTop(); /* number of arguments */
    ls.getGlobal('tostring');
    for (var i = 1; i <= n; i++) {
      ls.pushValue(-1); /* function to be called */
      ls.pushValue(i); /* value to print */
      ls.call(1, 1);
      final s = ls.toDartString(-1); /* get result */
      if (s == null) {
        return ls.errorMessage("'tostring' must return a string to 'print'");
      }
      if (i > 1) {
        behavior.print('\t');
      }
      behavior.print(s);
      ls.pop(1); /* pop result */
    }
    behavior.print('\n');
    return 0;
  }

  // assert (v [, message])
  // http://www.lua.org/manual/5.3/manual.html#pdf-assert
  // lua-5.3.4/src/lbaselib.c#luaB_assert()
  int baseAssert(LuaState ls) {
    if (ls.toBool(1)) {
      /* condition is true? */
      return ls.getTop(); /* return all arguments */
    } else {
      /* error */
      ls.checkAny(1); /* there must be a condition */
      ls.remove(1); /* remove it */
      ls.pushString('assertion failed!'); /* default message */
      ls.setTop(1); /* leave only message (default if no other one) */
      return baseError(ls); /* call 'error' */
    }
  }

  // error (message [, level])
  // http://www.lua.org/manual/5.3/manual.html#pdf-error
  // lua-5.3.4/src/lbaselib.c#luaB_error()
  int baseError(LuaState ls) {
    final level = ls.checkInt(2) ?? 1;
    ls.setTop(1);
    if (ls.type(1) == LuaType.string && level > 0) {
      // ls.where(level) /* add extra information */
      // ls.pushValue(1)
      // ls.concat(2)
    }
    return ls.error();
  }

  // select (index, ···)
  // http://www.lua.org/manual/5.3/manual.html#pdf-select
  // lua-5.3.4/src/lbaselib.c#luaB_select()
  int baseSelect(LuaState ls) {
    final n = ls.getTop();
    if (ls.type(1) == LuaType.string && ls.mustCheckString(1) == '#') {
      ls.pushInt(n - 1);
      return 1;
    } else {
      var i = ls.mustCheckInt(1);
      if (i < 0) {
        i = n + i;
      } else if (i > n) {
        i = n;
      }
      if (i < 1) {
        ls.argError(1, 'index out of range');
      }
      return n - i;
    }
  }

  // ipairs (t)
  // http://www.lua.org/manual/5.3/manual.html#pdf-ipairs
  // lua-5.3.4/src/lbaselib.c#luaB_ipairs()
  int baseIPairs(LuaState ls) {
    ls.checkAny(1);
    ls.pushDartFunction(_iPairsAux); /* iteration function */
    ls.pushValue(1); /* state */
    ls.pushInt(0); /* initial value */
    return 3;
  }

  int _iPairsAux(LuaState ls) {
    final i = ls.mustCheckInt(2) + 1;
    ls.pushInt(i);
    if (ls.getI(1, i) == LuaType.nil) {
      return 1;
    } else {
      return 2;
    }
  }

   // pairs (t)
   // http://www.lua.org/manual/5.3/manual.html#pdf-pairs
   // lua-5.3.4/src/lbaselib.c#luaB_pairs()
   int basePairs(LuaState ls) {
     ls.checkAny(1);
     if (ls.getMetafield(1, '__pairs') == LuaType.nil) { /* no metamethod? */
       ls.pushDartFunction(baseNext); /* will return generator, */
       ls.pushValue(1);             /* state, */
       ls.pushNil();
     } else {
       ls.pushValue(1); /* argument 'self' to metamethod */
       ls.call(1, 3);   /* get 3 values from metamethod */
     }
     return 3;
   }
  
    // next (table [, index])
    // http://www.lua.org/manual/5.3/manual.html#pdf-next
    // lua-5.3.4/src/lbaselib.c#luaB_next()
    int baseNext(LuaState ls) {
      ls.checkType(1, LuaType.table);
      ls.setTop(2); /* create a 2nd argument if there isn't one */
      if (ls.next(1)) {
        return 2;
      } else {
        ls.pushNil();
        return 1;
      }
    }
  
    // load (chunk [, chunkname [, mode [, env]]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-load
  // lua-5.3.4/src/lbaselib.c#luaB_load()
  int baseLoad(LuaState ls) {
  	var chunk = ls.toDartString(1);
  	var mode = ls.optString(3, 'bt');
  	var env = 0; /* 'env' index or 0 if no 'env' */
  	if (!ls.isNone(4)) {
  		env = 4;
  	}
  	if (chunk != null) { /* loading a string? */
  		var chunkName = ls.optString(2, chunk);
  		var status = ls.load(Uint8List.fromList(chunkName!.codeUnits), chunkName);
  	  return loadAux(ls, status, env);
  	} else { /* loading from a reader function */
  		throw LuaError('loading from a reader function'); // todo
  	}
  }
  
  // lua-5.3.4/src/lbaselib.c#load_aux()
  int loadAux(LuaState ls, LuaStatus status, int envIdx) {
  	if (status == LuaStatus.ok) {
  		if (envIdx != 0) { /* 'env' parameter? */
  			throw LuaError('todo');
  		}
  		return 1;
  	} else { /* error (message is on top of the stack) */
  		ls.pushNil();
  		ls.insert(-2); /* put before error message */
  		return 2;      /* return nil plus error message */
  	}
  }
  
  // loadfile ([filename [, mode [, env]]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-loadfile
  // lua-5.3.4/src/lbaselib.c#luaB_loadfile()
  int baseLoadFile(LuaState ls) {
  	var fname = ls.optString(1, '');
  	var mode = ls.optString(1, 'bt');
  	var env = 0; /* 'env' index or 0 if no 'env' */
  	if (!ls.isNone(3)) {
  		env = 3;
  	}
  	var status = ls.loadFileX(fname!, mode!);
  	return loadAux(ls, status, env);
  }
  
  // dofile ([filename])
  // http://www.lua.org/manual/5.3/manual.html#pdf-dofile
  // lua-5.3.4/src/lbaselib.c#luaB_dofile()
  int baseDoFile(LuaState ls) {
  	var fname = ls.optString(1, 'bt');
  	ls.setTop(1);
  	if (ls.loadFile(fname!) != LuaStatus.ok ){
  		return ls.error();
  	}
  	ls.call(0, -1); //LUA_MULTRET
  	return ls.getTop() - 1;
  }
  
    // pcall (f [, arg1, ···])
    // http://www.lua.org/manual/5.3/manual.html#pdf-pcall
    int basePCall(LuaState ls) {
      final nArgs = ls.getTop() - 1;
      final status = ls.pCall(nArgs, -1, 0);
      ls.pushBool(status == LuaStatus.ok);
      ls.insert(1);
      return ls.getTop();
    }
  
    // xpcall (f, msgh [, arg1, ···])
  // http://www.lua.org/manual/5.3/manual.html#pdf-xpcall
  int baseXPCall(LuaState ls) {
  	throw LuaError('todo');
  }
  
  // getmetatable (object)
  // http://www.lua.org/manual/5.3/manual.html#pdf-getmetatable
  // lua-5.3.4/src/lbaselib.c#luaB_getmetatable()
  int baseGetMetatable(LuaState ls) {
  	ls.checkAny(1);
  	if (!ls.getMetatable(1)) {
  		ls.pushNil();
  		return 1; /* no metatable */
  	}
  	ls.getMetafield(1, '__metatable');
  	return 1; /* returns either __metatable field (if present) or metatable */
  }
  
  // setmetatable (table, metatable)
  // http://www.lua.org/manual/5.3/manual.html#pdf-setmetatable
  // lua-5.3.4/src/lbaselib.c#luaB_setmetatable()
  int baseSetMetatable(LuaState ls) {
  	var t = ls.type(2);
  	ls.checkType(1, LuaType.table);
  	ls.argCheck(t == LuaType.nil || t == LuaType.table, 2,
  		'nil or table expected');
  	if (ls.getMetafield(1, '__metatable') != LuaType.nil) {
  		return ls.error2('cannot change a protected metatable');
  	}
  	ls.setTop(2);
  	ls.setMetatable(1);
  	return 1;
  }
  
  // // rawequal (v1, v2)
  // // http://www.lua.org/manual/5.3/manual.html#pdf-rawequal
  // // lua-5.3.4/src/lbaselib.c#luaB_rawequal()
  int baseRawEqual(LuaState ls) {
    ls.checkAny(1);
    ls.checkAny(2);
    ls.pushBool(ls.rawEqual(1, 2));
    return 1;
  }

  // rawlen (v)
  // http://www.lua.org/manual/5.3/manual.html#pdf-rawlen
  // lua-5.3.4/src/lbaselib.c#luaB_rawlen()
  int baseRawLen(LuaState ls) {
    final t = ls.type(1);
    final ok = t == LuaType.table || t == LuaType.string;
    if (!ok) {
      ls.argError(1, 'table or string expected');
    }
    ls.pushInt(ls.rawLen(1));
    return 1;
  }

  // rawget (table, index)
  // http://www.lua.org/manual/5.3/manual.html#pdf-rawget
  // lua-5.3.4/src/lbaselib.c#luaB_rawget()
  int baseRawGet(LuaState ls) {
    ls.checkType(1, LuaType.table);
    ls.checkAny(2);
    ls.setTop(2);
    ls.rawGet(1);
    return 1;
  }

  // rawset (table, index, value)
  // http://www.lua.org/manual/5.3/manual.html#pdf-rawset
  // lua-5.3.4/src/lbaselib.c#luaB_rawset()
  int baseRawSet(LuaState ls) {
    ls.checkType(1, LuaType.table);
    ls.checkAny(2);
    ls.checkAny(3);
    ls.setTop(3);
    ls.rawSet(1);
    return 1;
  }

  // type (v)
  // http://www.lua.org/manual/5.3/manual.html#pdf-type
  // lua-5.3.4/src/lbaselib.c#luaB_type()
  int baseType(LuaState ls) {
    final t = ls.type(1);
    if (t == LuaType.none) {
      ls.argError(1, 'value expected');
    }
    ls.pushString(t.typeName);
    return 1;
  }

  // tostring (v)
  // http://www.lua.org/manual/5.3/manual.html#pdf-tostring
  // lua-5.3.4/src/lbaselib.c#luaB_tostring()
  int baseToString(LuaState ls) {
    ls.checkAny(1);
    ls.toDartStringL(1);
    return 1;
  }

  // tonumber (e [, base])
  // http://www.lua.org/manual/5.3/manual.html#pdf-tonumber
  // lua-5.3.4/src/lbaselib.c#luaB_tonumber()
  int baseToNumber(LuaState ls) {
    if (ls.isNoneOrNil(2)) {
      /* standard conversion? */
      ls.checkAny(1);
      if (ls.type(1) == LuaType.number) {
        /* already a number? */
        ls.setTop(1); /* yes; return it */
        return 1;
      } else {
        final s = ls.toDartString(1);
        if (s != null) {
          if (ls.stringToNumber(s)) {
            return 1; /* successful conversion to number */
          } /* else not a number */
        }
      }
    } else {
      ls.checkType(1, LuaType.string); /* no numbers as strings */
      final s = ls.toDartString(1)!.trim();
      final base = ls.mustCheckInt(2);
      if (base < 2 || base > 36) {
        ls.argError(2, 'base out of range');
      }
      final n = int.tryParse(s, radix: base);
      if (n != null) {
        ls.pushInt(n);
        return 1;
      }
    } /* else not a number */
    ls.pushNil(); /* not a number */
    return 1;
  }
}
