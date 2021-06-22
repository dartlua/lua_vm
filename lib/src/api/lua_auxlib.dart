import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:luart/luart.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/state/lua_value.dart';
import 'package:luart/src/stdlib/stdlib_base.dart';
import 'package:luart/src/stdlib/stdlib_math.dart';
import 'package:luart/src/stdlib/stdlib_os.dart';
import 'package:luart/src/stdlib/stdlib_package.dart';
import 'package:luart/src/stdlib/stdlib_string.dart';
import 'package:luart/src/stdlib/stdlib_table.dart';
import 'package:luart/src/stdlib/stdlib_utf8.dart';
import 'package:sprintf/sprintf.dart';

extension LuaAuxlib on LuaState {
  void loadString(String source, [String chunkName = 'source']) {
    load(Uint8List.fromList(utf8.encode(source)), chunkName);
  }

  bool doString(String source) {
    loadString(source);
    return pCall(0, LUA_MULTRET, 0) != LuaStatus.ok;
  }

  void _intError(int arg) {
    if (isNumber(arg)) {
      argError(arg, 'number has no integer representation');
    } else {
      _tagError(arg, LuaType.number);
    }
  }

  void _tagError(int arg, LuaType tag) {
    typeError(arg, tag.typeName);
  }

  int typeError(int arg, String tname) {
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

  int argError(int arg, String msg) {
    return error2('bad argument #$arg ($msg)');
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

  // [-0, +(0|1), e]
  // http://www.lua.org/manual/5.3/manual.html#luaL_callmeta
  bool callMeta(int obj, String event) {
    obj = absIndex(obj);
    if (getMetafield(obj, event) == LuaType.nil) {
      /* no metafield? */
      return false;
    }

    pushValue(obj);
    call(1, 1);
    return true;
  }

  // [-0, +1, e]
  // http://www.lua.org/manual/5.3/manual.html#luaL_tolstring
  String toDartStringL(int idx) {
    final val = stack!.get(idx);
    if (val is LuaError) {
      pushString(val.toString());
    } else if (callMetaMethod(idx, null, '__tostring', this).success) {
      /* metafield? */
      if (!isString(-1)) {
        error2("'__tostring' must return a string");
      }
    } else {
      switch (type(idx)) {
        case LuaType.number:
        case LuaType.string:
          pushValue(idx);
          break;
        case LuaType.boolean:
          if (toBool(idx)) {
            pushString('true');
          } else {
            pushString('false');
          }
          break;
        case LuaType.nil:
          pushString('nil');
          break;
        default:
          final tt = getMetafield(idx, '__name'); /* try name */
          var kind;
          if (tt == LuaType.string) {
            kind = checkString(-1);
          } else {
            kind = typeName(idx);
          }

          pushString(kind);
          if (tt != LuaType.nil) {
            remove(-2); /* remove '__name' */
          }
      }
    }
    return checkString(-1) ?? '';
  }

  // [-0, +0, v]
  // http://www.lua.org/manual/5.3/manual.html#luaL_checkany
  void checkAny(int arg) {
    if (type(arg) == LuaType.none) {
      argError(arg, 'value expected');
    }
  }

  void checkType(int idx, LuaType t) {
    if (type(idx) != t) {
      _tagError(idx, t);
    }
  }

  int checkInt(int idx) {
    final result = convert2Int(stack!.get(idx));
    if (!result.success) {
      _intError(idx);
    }
    return result.result;
  }

  double checkNumber(int idx) {
    final result = convert2Float(stack!.get(idx));
    if (!result.success) {
      _tagError(idx, LuaType.number);
    }
    return result.result;
  }

  String? checkString(int idx) {
    final result = toDartString(idx);
    if (result == null) {
      _tagError(idx, LuaType.string);
    }
    return result;
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
      '_G': openBaseLib,
      'math': openMathLib,
      'table': openTableLib,
      'string': openStringLib,
      'utf8': openUTF8Lib,
      'os': openOsLib,
      'package': openPackageLib,
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
    if (!toBool(-1)) {
      /* package not already loaded? */
      pop(1); /* remove field */
      pushDartFunction(openf);
      pushString(modname); /* argument to open function */
      call(1, 1); /* call 'openf' to open module */
      pushValue(-1); /* make copy of module (call result) */
      setField(-3, modname); /* _LOADED[modname] = module */
    }
    remove(-2); /* remove _LOADED table */
    if (global) {
      pushValue(-1); /* copy of module */
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
    pushValue(-1); /* copy to be left at top */
    setField(idx, fname); /* assign new table to field */
    return false; /* false, because did not find table there */
  }

  LuaType getMetafield(int obj, String event) {
    if (!getMetatable(obj)) {
      /* no metatable? */
      return LuaType.nil;
    }

    pushString(event);
    var tt = rawGet(-2);
    if (tt == LuaType.nil) {
      /* is metafield nil? */
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
    var data = File(filename).readAsBytesSync();
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
  int error2(String fmt, [List? args]) {
    if (args == null) {
      pushString(fmt);
    } else {
      pushString(sprintf(fmt, args));
    }
    return error();
  }

  int optInt(int arg, int def) {
    if (isNoneOrNil(arg)) {
      return def;
    }
    return checkInt(arg);
  }

  double optNumber(int arg, double def) {
    if (isNoneOrNil(arg)) {
      return def;
    }
    return checkNumber(arg);
  }

  // [-0, +0, v]
  // http://www.lua.org/manual/5.3/manual.html#luaL_optstring
  String? optString(int arg, String def) {
    if (isNoneOrNil(arg)) return def;
    return checkString(arg);
  }

  // [-0, +0, v]
  // http://www.lua.org/manual/5.3/manual.html#luaL_checkstack
  void checkStack2(int sz, String msg) {
    if (!checkStack(sz)) {
      if (msg != '') {
        error2('stack overflow (%s)', [msg]);
      } else {
        error2('stack overflow');
      }
    }
  }
}
