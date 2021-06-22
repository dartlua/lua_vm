import 'package:luart/luart.dart';
import 'package:luart/src/constants.dart';

mixin LuaStateStack implements LuaState {
  @override
  int getTop() => stack!.top;

  @override
  int fetch() {
    final i = stack!.closure!.proto!.codes[stack!.pc];
    stack!.addPC(1);
    return i;
  }

  void getConst(int idx) => stack!.push(stack!.closure!.proto!.constants[idx]);

  void getRK(int rk) => rk > 0xff ? getConst(rk & 0xff) : pushValue(rk + 1);

  @override
  int absIndex(int idx) => stack!.absIndex(idx);

  @override
  bool checkStack(int n) {
    stack!.check(n);
    return true;
  }

  @override
  void pop(int n) => setTop(-n - 1);

  @override
  void copy(int fromIdx, int toIdx) => stack!.set(toIdx, stack!.get(fromIdx));

  @override
  void pushValue(int idx) => stack!.push(stack!.get(idx));

  @override
  void replace(int idx) => stack!.set(idx, stack!.pop());

  @override
  void insert(int idx) => rotate(idx, 1);

  @override
  void remove(int idx) {
    rotate(idx, -1);
    pop(1);
  }

  @override
  void rotate(int idx, int n) {
    final t = stack!.top - 1;
    final p = stack!.absIndex(idx) - 1;
    late int m;
    if (n >= 0) {
      m = t - n;
    } else {
      m = p - n - 1;
    }
    stack!.reverse(p, m);
    stack!.reverse(m + 1, t);
    stack!.reverse(p, t);
  }

  @override
  void setTop(int idx) {
    final newTop = stack!.absIndex(idx);
    if (newTop < 0) throw StackUnderflowError();
    final n = stack!.top - newTop;
    if (n > 0) {
      for (var i = 0; i < n; i++) {
        stack!.pop();
      }
    } else if (n < 0) {
      for (var i = 0; i > n; i--) {
        pushNil();
      }
    }
  }
}
