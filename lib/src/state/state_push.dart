import 'package:lua_vm/lua_vm.dart';
import 'package:lua_vm/src/state/lua_closure.dart';

mixin LuaStatePush implements LuaState {
  @override
  void pushNil() => stack.push(null);

  @override
  void pushBool(bool b) => stack.push(b);

  @override
  void pushInt(int i) => stack.push(i);

  @override
  void pushNumber(double d) => stack.push(d);

  @override
  void pushString(String s) => stack.push(s);

  @override
  void pushDartFunction(DartFunction dartFunc) =>
      stack.push(LuaClosure.fromDartFunctiontion(dartFunc, 0));
}
