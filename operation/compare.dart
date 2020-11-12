import '../api/value.dart';

bool eq_(LuaValue a, LuaValue b){
  if(a == null) return b == null;
  dynamic aa = a.luaValue;
  dynamic bb = b.luaValue;
  if(aa is bool) return aa == bb;
  if(aa is String) return aa == bb;
  if(aa is int) return bb is int ? aa == bb : aa.toDouble() == bb;
  if(aa is double) return bb is double ? aa == bb : aa == bb.toDouble();
  return a == b;
}

bool lt_(LuaValue a, LuaValue b){
  dynamic aa = a.luaValue;
  dynamic bb = b.luaValue;
  if(aa is String)
    return aa.compareTo(bb is String ? bb : bb.toString()) == -1 ? true : false;
  if(aa is int) return bb is int ? aa < bb : aa.toDouble() < bb;
  if(aa is double) return bb is double ? aa < bb : aa < bb.toDouble();
  throw UnsupportedError('Unsupported comparison between '
      '${aa.runtimeType} and ${bb.runtimeType}');
}

bool le_(LuaValue a, LuaValue b){
  dynamic aa = a.luaValue;
  dynamic bb = b.luaValue;
  if(aa is String)
    return aa.compareTo(bb is String ? bb : bb.toString()) < 1 ? true : false;
  if(aa is int) return bb is int ? aa <= bb : aa.toDouble() <= bb;
  if(aa is double) return bb is double ? aa <= bb : aa <= bb.toDouble();
  throw UnsupportedError('Unsupported comparison between '
      '${aa.runtimeType} and ${bb.runtimeType}');
}