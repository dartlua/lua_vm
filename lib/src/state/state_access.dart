import 'package:luart/luart.dart';
import 'package:luart/src/api/lua_vm.dart';
import 'package:luart/src/state/lua_value.dart';

mixin LuaStateAccess implements LuaVM {
  @override
  String typeName(LuaType luaType) {
    switch (luaType) {
      case LuaType.none:
        return 'no value';
      case LuaType.nil:
        return 'nil';
      case LuaType.boolean:
        return 'boolean';
      case LuaType.number:
        return 'number';
      case LuaType.string:
        return 'string';
      case LuaType.table:
        return 'table';
      case LuaType.function:
        return 'function';
      case LuaType.thread:
        return 'thread';
      default:
        return 'userdata';
    }
  }

  @override
  LuaType type(int idx) {
    if (stack.isValid(idx)) {
      var val = stack.get(idx);
      return typeOf(val);
    }
    return LuaType.none;
  }

  @override
  bool isNone(int idx) => type(idx) == LuaType.none;

  @override
  bool isNil(int idx) => type(idx) == LuaType.nil;

  @override
  bool isNoneOrNil(int idx) => type(idx).index <= LuaType.nil.index;

  @override
  bool isBool(int idx) => type(idx) == LuaType.boolean;

  @override
  bool isInt(int idx) => stack.get(idx)! is int;

  @override
  bool isNumber(int idx) => stack.get(idx)! is double;

  @override
  bool isTable(int idx) => type(idx) == LuaType.table;

  @override
  bool isString(int idx) =>
      type(idx) == LuaType.string || type(idx) == LuaType.number;

  @override
  bool toBool(int idx) => convert2Boolean(stack.get(idx)!);

  @override
  int toInt(int idx) => convert2Int(stack.get(idx)!);

  @override
  double toNumber(int idx) => convert2Float(stack.get(idx)!);

  @override
  String toStr(int idx) => convert2String(stack.get(idx)!);
}
