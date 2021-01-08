import 'package:lua_vm/lua_vm.dart';

abstract class LuaVM with LuaState {
  int get pc;

  void addPC(int n);

  int fetch();

  void getConst(int idx);

  void getRK(int rk);

  int registerCount();

  void loadVararg(int n);

  void loadProto(int idx);

  void closeClosure(int a);
}
