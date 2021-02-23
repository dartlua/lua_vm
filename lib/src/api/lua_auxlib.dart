import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:luart/luart.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/state/lua_value.dart';
import 'package:luart/src/stdlib/stdlib_base.dart';
import 'package:luart/src/stdlib/stdlib_math.dart';
import 'package:luart/src/stdlib/stdlib_os.dart';

extension LuaAuxlib on LuaState {
  void loadString(String source, [String chunkName = 'source']) {
    load(Uint8List.fromList(utf8.encode(source)), chunkName);
  }

  bool doString(String source) {
    loadString(source);
    return pCall(0, LUA_MULTRET, 0) != LuaStatus.ok;
  }

  Never argError(int arg, String msg) {
    // bad argument #arg to 'funcname' (extramsg)
    errorMessage('bad argument #$arg ($msg)');
  }

  Never errorMessage(Object? message) {
    pushString(message.toString());
    error();
  }

  void setFuncs(Map<String, LuaDartFunction> funcs, [int upvalues = 0]) {
    if (!checkStack(upvalues)) {
      throw LuaError('too many upvalues');
    }

    for (var func in funcs.entries) {
      for (var i = 0; i < upvalues; i++) {
        pushValue(-upvalues);
      }
      pushDartClosure(func.value, upvalues);
      setField(-(upvalues + 2), func.key);
    }
    pop(upvalues);
  }

  // [-0, +0, v]
  // http://www.lua.org/manual/5.3/manual.html#luaL_checkany
  void checkAny(int arg) {
    if (type(arg) == LuaType.none) {
      LuaError('value expected');
    }
  }

  // [-0, +1, e]
  // http://www.lua.org/manual/5.3/manual.html#luaL_tolstring
  String toDartStringL(int idx) {
    if (callMetaMethod(idx, null, '__tostring', this) != null) {
      /* metafield? */
      if (!isString(-1)) {
        ;
        throw LuaError("'__tostring' must return a string");
      }
    } else {
      switch (type(idx)) {
        case LuaType.string:
          pushValue(idx);
          break;
        case LuaType.number:
        case LuaType.boolean:
          pushString(toDartString(idx)!);
          break;
        case LuaType.nil:
          pushString('nil');
          break;
        default:
          final tt = getMetaField(idx, '__name', this);
          late String kind;
          if (tt == LuaType.string) {
            kind = mustCheckString(-1);
          } else {
            kind = typeName(idx);
          }

          pushString(
            kind, /* toPointer(idx) */
          );
          if (tt != LuaType.nil) {
            remove(-2) /* remove '__name' */;
          }
      }
    }
    return mustCheckString(-1);
  }

  void checkType(int idx, LuaType t) {
    if (type(idx) != t) {
      _tagError(idx, t);
    }
  }

  int? checkInt(int idx) {
    try {
      final i = toInt(idx);
      return i;
    } catch (e) {
      return null;
    }
  }

  double? checkNumber(int idx) {
    try {
      final i = toNumber(idx);
      return i;
    } catch (e) {
      return null;
    }
  }

  String? checkString(int idx) {
    return toDartString(idx);
  }

  // [-0, +0, v]
  // http://www.lua.org/manual/5.3/manual.html#luaL_optstring
  String? optString(int arg, String def) {
  	if (isNoneOrNil(arg)) return def;
  	return checkString(arg);
  }

  int mustCheckInt(int idx) {
    final result = checkInt(idx);
    if (result != null) {
      return result;
    }
    _intError(idx);
  }

  double mustCheckNumber(int idx) {
    final result = checkNumber(idx);
    if (result != null) {
      return result;
    }
    _tagError(idx, LuaType.number);
  }

  String mustCheckString(int idx) {
    final result = checkString(idx);
    if (result != null) {
      return result;
    }
    _tagError(idx, LuaType.string);
  }

  Never _intError(int arg) {
    if (isNumber(arg)) {
      argError(arg, 'number has no integer representation');
    } else {
      _tagError(arg, LuaType.number);
    }
  }

  Never _tagError(int arg, LuaType tag) {
    typeError(arg, tag.typeName);
  }

  Never typeError(int arg, String tname) {
    late String typeArg; /* name for the type of the actual argument */
    if (getMetaField(arg, '__name', this) == LuaType.string) {
      typeArg = toDartString(-1)!; /* use the given type name */
    } else if (type(arg) == LuaType.lightuserdata) {
      typeArg = 'light userdata'; /* special name for messages */
    } else {
      typeArg = type(arg).typeName; /* standard name */
    }
    final msg = tname + ' expected, got ' + typeArg;
    pushString(msg);
    return argError(arg, msg);
  }

  // [-0, +1, m]
  // http://www.lua.org/manual/5.3/manual.html#luaL_newlib
  void newLib(Map<String, LuaDartFunction> funcs) {
    createTable(0, funcs.length);
    setFuncs(funcs, 0);
  }

  // [-0, +0, e]
  // http://www.lua.org/manual/5.3/manual.html#luaL_openlibs
  void openLibs() {
    final libs = <String, LuaDartFunction>{
      '_G':        openBaseLib,
      'math':      openMathLib,
      // 'table':     openTableLib,
      // 'string':    openStringLib,
      // 'utf8':      openUTF8Lib,
      'os':        openOsLib,
      // 'package':   openPackageLib,
      // 'coroutine': openCoroutineLib,
    };

    for (var lib in libs.entries) {
      requireF(lib.key, lib.value, global: true);
      pop(1);
    }
  }

  // [-0, +1, e]
  // http://www.lua.org/manual/5.3/manual.html#luaL_requiref
  void requireF(String modname, LuaDartFunction openf, {bool global = true}) {
    getSubTable(LUA_REGISTRYINDEX, '_LOADED');
    getField(-1, modname); /* LOADED[modname] */
    if (!toBool(-1)) {   /* package not already loaded? */
      pop(1); /* remove field */
      pushDartFunction(openf);
      pushString(modname);   /* argument to open function */
      call(1, 1);            /* call 'openf' to open module */
      pushValue(-1);         /* make copy of module (call result) */
      setField(-3, modname); /* _LOADED[modname] = module */
    }
    remove(-2); /* remove _LOADED table */
    if (global) {
      pushValue(-1);      /* copy of module */
      setGlobal(modname); /* _G[modname] = module */
    }
  }

  // [-0, +1, e]
  // http://www.lua.org/manual/5.3/manual.html#luaL_getsubtable
  bool getSubTable(int idx, String fname) {
    if (getField(idx, fname) == LuaType.table) {
      return true; /* table already there */
    }
    pop(1); /* remove previous result */
    idx = stack!.absIndex(idx);
    newTable();
    pushValue(-1);        /* copy to be left at top */
    setField(idx, fname); /* assign new table to field */
    return false;              /* false, because did not find table there */
  }

  LuaType getMetafield(int obj, String event) {
  	if (!getMetatable(obj)) { /* no metatable? */
  		return LuaType.nil;
  	}
  
  	pushString(event);
  	var tt = rawGet(-2);
  	if (tt == LuaType.nil) { /* is metafield nil? */
  		pop(2); /* remove metatable and metafield */
  	} else {
  		remove(-2); /* remove only metatable */
  	}
  	return tt; /* return metafield type */
  }

  // [-0, +1, m]
  // http://www.lua.org/manual/5.3/manual.html#luaL_loadfile
  LuaStatus loadFile(String filename) {
  	return loadFileX(filename, 'bt');
  }
  
  // [-0, +1, m]
  // http://www.lua.org/manual/5.3/manual.html#luaL_loadfilex
  LuaStatus loadFileX(String filename, String mode) {
    var data = File('example/ch10.out').readAsBytesSync();
  	return load(data, '@' + filename);
  }

  // [-0, +0, v]
  // http://www.lua.org/manual/5.3/manual.html#luaL_argcheck
  void argCheck(bool cond, int arg, String extraMsg) {
  	if (!cond) {
  		argError(arg, extraMsg);
  	}
  }

  // [-0, +0, v]
  // http://www.lua.org/manual/5.3/manual.html#luaL_error
  int error2(String fmt, {Object? a}) {
	  pushString(fmt); // todo
	  return error();
  }
}
