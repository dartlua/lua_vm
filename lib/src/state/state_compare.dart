import 'package:luart/luart.dart';
import 'package:luart/src/state/lua_table.dart';
import 'package:luart/src/state/lua_value.dart';

mixin LuaStateCompare implements LuaState {
  @override
  bool rawEqual(int idx1, int idx2) {
    if (!stack!.isValid(idx1) || !stack!.isValid(idx2)) return false;
    final a = stack!.get(idx1)!;
    final b = stack!.get(idx2)!;
    return _eq(a, b, null);
  }

  @override
  bool compare(int idx1, int idx2, LuaCompareOp op) {
    if (!stack!.isValid(idx1) || !stack!.isValid(idx2)) return false;
    final a = stack!.get(idx1);
    final b = stack!.get(idx2);
    switch (op) {
      case LuaCompareOp.eq:
        return _eq(a, b, this);
      case LuaCompareOp.lt:
        return _lt(a, b, this);
      case LuaCompareOp.le:
        return _le(a, b, this);
      default:
        throw UnsupportedError('Unsupported Compare Operation');
    }
  }
}

bool _eq(Object? a, Object? b, LuaState? ls) {
  if (a == null) return b == null;
  if (a is LuaTable && b is LuaTable && a != b) {
    final result = callMetaMethod(a, b, '__eq', ls!);
    if (result != null) return convert2Boolean(result);
  }
  return a == b;
}

bool _lt(Object? a, Object? b, LuaState ls) {
  if (a is String) {
    return a.compareTo(b is String ? b : b.toString()) == -1 ? true : false;
  }
  if (a is num && b is num) return a < b;
  final result = callMetaMethod(a, b, '__lt', ls);
  if (result != null) return convert2Boolean(result);
  throw UnsupportedError('Unsupported comparison between '
      '${a.runtimeType} and ${b.runtimeType}');
}

bool _le(Object? a, Object? b, LuaState ls) {
  if (a is String) {
    return a.compareTo(b is String ? b : b.toString()) < 1 ? true : false;
  }
  if (a is num && b is num) {
    return a <= b;
  }

  var result = callMetaMethod(a, b, '__le', ls);
  if (result != null) return convert2Boolean(result);

  result = callMetaMethod(a, b, '__lt', ls);
  if (result != null) return !convert2Boolean(result);
  throw UnsupportedError('Unsupported comparison between '
      '${a.runtimeType} and ${a.runtimeType}');
}
