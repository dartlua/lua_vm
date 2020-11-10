import '../api/value.dart';

bool eq(LuaValue a, LuaValue b){
  dynamic aa = a.luaValue;
  dynamic bb = b.luaValue;
  if(aa == null) return b == null;
  if(aa is bool) return aa == bb;
  if(aa is String) return aa == bb;
  if(aa is int) bb is int ? aa == bb : aa.toDouble() == bb;
  if(aa is double) bb is double ? aa == bb : aa == bb.toDouble();
  return a == b;
}

bool lt(LuaValue a, LuaValue b){
  dynamic aa = a.luaValue;
  dynamic bb = b.luaValue;
  if(aa is String) bb is String
      ? (aa.compareTo(bb) == -1 ? true : false)
      : throw UnsupportedError('Unsupported comparision between String and ${bb.runtimeType}');
  if(aa is int) bb is int ? aa < bb : aa.toDouble() < bb;
  if(aa is double) bb is double ? aa < bb : aa < bb.toDouble();
  throw UnsupportedError('Unsupported comparison between '
      '${aa.runtimeType} and ${bb.runtimeType}');
}

bool le(LuaValue a, LuaValue b){
  dynamic aa = a.luaValue;
  dynamic bb = b.luaValue;
  if(aa is String) bb is String
      ? (aa.compareTo(bb) < 1 ? true : false)
      : throw UnsupportedError('Unsupported comparision between String and ${bb.runtimeType}');
  if(aa is int) bb is int ? aa <= bb : aa.toDouble() <= bb;
  if(aa is double) bb is double ? aa <= bb : aa <= bb.toDouble();
  throw UnsupportedError('Unsupported comparison between '
      '${aa.runtimeType} and ${bb.runtimeType}');
}