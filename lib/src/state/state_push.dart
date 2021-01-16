import 'package:luart/luart.dart';
import 'package:luart/src/state/lua_closure.dart';

mixin LuaStatePush implements LuaState {
  @override
  void pushNil() => stack!.push(null);

  @override
  void pushBool(bool b) => stack!.push(b);

  @override
  void pushInt(int i) => stack!.push(i);

  @override
  void pushNumber(double d) => stack!.push(d);

  @override
  void pushString(String s) => stack!.push(s);

  @override
  void pushDartFunction(LuaDartFunction dartFunc) =>
      stack!.push(LuaClosure.fromDartFunction(dartFunc, 0));
}
