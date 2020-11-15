import '../api/state.dart';
import '../api/table.dart';
import '../api/value.dart';

bool eq_(LuaValue a, LuaValue b, LuaState ls){
  dynamic aa = a.luaValue;
  dynamic bb = b.luaValue;
  if(aa == null) return bb == null;
  if(aa is bool) return aa == bb;
  if(aa is String) return aa == bb;
  if(aa is int) return bb is int ? aa == bb : aa.toDouble() == bb;
  if(aa is double) return bb is double ? aa == bb : aa == bb.toDouble();
  if(aa is LuaTable && bb is LuaTable && aa != bb && ls != null) {
    LuaValue result = callMetaMethod(a, b, '__eq', ls);
    if(result.luaValue != null) return convert2Boolean(result);
  }
  return a == b;
}

bool lt_(LuaValue a, LuaValue b, LuaState ls){
  dynamic aa = a.luaValue;
  dynamic bb = b.luaValue;
  if(aa is String)
    return aa.compareTo(bb is String ? bb : bb.toString()) == -1 ? true : false;
  if(aa is int) return bb is int ? aa < bb : aa.toDouble() < bb;
  if(aa is double) return bb is double ? aa < bb : aa < bb.toDouble();
  LuaValue result = callMetaMethod(a, b, '__lt', ls);
  if(result.luaValue != null) return convert2Boolean(result);
  throw UnsupportedError('Unsupported comparison between '
      '${aa.runtimeType} and ${bb.runtimeType}');
}

bool le_(LuaValue a, LuaValue b, LuaState ls){
  dynamic aa = a.luaValue;
  dynamic bb = b.luaValue;
  if(aa is String)
    return aa.compareTo(bb is String ? bb : bb.toString()) < 1 ? true : false;
  if(aa is int) return bb is int ? aa <= bb : aa.toDouble() <= bb;
  if(aa is double) return bb is double ? aa <= bb : aa <= bb.toDouble();

  LuaValue result = callMetaMethod(a, b, '__le', ls);
  if(result.luaValue != null) return convert2Boolean(result);

  result = callMetaMethod(a, b, '__lt', ls);
  if(result.luaValue != null) return !convert2Boolean(result);
  throw UnsupportedError('Unsupported comparison between '
      '${aa.runtimeType} and ${bb.runtimeType}');
}