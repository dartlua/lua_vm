import 'dart:convert';
import 'dart:typed_data';

import 'package:luart/luart.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/state/lua_value.dart';
import 'package:luart/src/stdlib/stdlib_base.dart';

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

  void openBaseLib() {
    openBase(this);
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
          final tt = getMetafield(idx, '__name', this);
          late String kind;
          if (tt == LuaType.string) {
            kind = checkString(-1);
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
    return checkString(-1);
  }

  void checkType(int idx, LuaType t) {
    if (type(idx) != t) {
      _tagError(idx, t);
    }
  }

  int checkInt(int idx, {int? fallback}) {
    try {
      final i = toInt(idx);
      return i;
    } catch (e) {
      if (fallback != null) {
        return fallback;
      }
      _intError(idx);
    }
  }

  double checkNumber(int idx, {double? fallback}) {
    try {
      final i = toNumber(idx);
      return i;
    } catch (e) {
      if (fallback != null) {
        return fallback;
      }
      _tagError(idx, LuaType.number);
    }
  }

  String checkString(int idx, {String? fallback}) {
    final s = toDartString(idx);
    if (s != null) {
      return s;
    }
    if (fallback != null) {
      return fallback;
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
    if (getMetafield(arg, '__name', this) == LuaType.string) {
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
}
