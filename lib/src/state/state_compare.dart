import 'package:lua_vm/lua_vm.dart';
import 'package:lua_vm/src/state/lua_table.dart';
import 'package:lua_vm/src/state/lua_value.dart';

mixin LuaStateCompare implements LuaState {
  @override
  bool rawEqual(int idx1, int idx2) {
    if (!stack.isValid(idx1) || !stack.isValid(idx2)) return false;
    final a = stack.get(idx1)!;
    final b = stack.get(idx2)!;
    return eq_(a, b, this);
  }

  @override
  bool compare(int idx1, int idx2, LuaCompareOp op) {
    if (!stack.isValid(idx1) || !stack.isValid(idx2)) return false;
    var a = stack.get(idx1);
    var b = stack.get(idx2);
    LuaState ls = this;
    switch (op) {
      case LuaCompareOp.eq:
        return eq_(a!, b!, ls);
      case LuaCompareOp.lt:
        return lt_(a!, b!, ls);
      case LuaCompareOp.le:
        return le_(a!, b!, ls);
      default:
        throw UnsupportedError('Unsupported Compare Operation');
    }
  }
}

bool eq_(Object a, Object b, LuaState ls) {
  dynamic aa = a;
  dynamic bb = b;
  if (aa == null) return bb == null;
  if (aa is bool) return aa == bb;
  if (aa is String) return aa == bb;
  if (aa is int) return bb is int ? aa == bb : aa.toDouble() == bb;
  if (aa is double) return bb is double ? aa == bb : aa == bb.toDouble();
  if (aa is LuaTable && bb is LuaTable && aa != bb && ls != null) {
    final result = callMetaMethod(a, b, '__eq', ls);
    if (result != null) return convert2Boolean(result);
  }
  return a == b;
}

bool lt_(Object a, Object b, LuaState ls) {
  dynamic aa = a;
  dynamic bb = b;
  if (aa is String) {
    return aa.compareTo(bb is String ? bb : bb.toString()) == -1 ? true : false;
  }
  if (aa is int) return bb is int ? aa < bb : aa.toDouble() < bb;
  if (aa is double) return bb is double ? aa < bb : aa < bb.toDouble();
  var result = callMetaMethod(a, b, '__lt', ls);
  if (result != null) return convert2Boolean(result);
  throw UnsupportedError('Unsupported comparison between '
      '${aa.runtimeType} and ${bb.runtimeType}');
}

bool le_(dynamic a, dynamic b, LuaState ls) {
  if (a is String) {
    return a.compareTo(b is String ? b : b.toString()) < 1 ? true : false;
  }
  if (a is int) {
    return b is int ? a <= b : a.toDouble() <= b;
  }
  if (a is double) {
    return b is double ? a <= b : a <= b.toDouble();
  }

  var result = callMetaMethod(a, b, '__le', ls);
  if (result != null) return convert2Boolean(result);

  result = callMetaMethod(a, b, '__lt', ls);
  if (result != null) return !convert2Boolean(result);
  throw UnsupportedError('Unsupported comparison between '
      '${a.runtimeType} and ${a.runtimeType}');
}
