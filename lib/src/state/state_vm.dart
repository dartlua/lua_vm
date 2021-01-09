import 'package:luart/luart.dart';

mixin LuaStateVm implements LuaState {
  int get pc => stack!.pc;

  void addPC(int n) => stack!.addPC(n);
}
