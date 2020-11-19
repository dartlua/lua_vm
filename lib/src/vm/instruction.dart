import '../api/state.dart';
import '../constants.dart';
import '../operation/arith.dart';
import '../operation/fpb.dart';
import 'op_code.dart';
import 'vm.dart';

class InstructionABC {
  InstructionABC(this.a, this.b, this.c);

  final int a;
  final int b;
  final int c;
}

class InstructionAB {
  InstructionAB(this.a, this.b);

  final int a;
  final int b;
}

extension Instruction on int {
  int get opCode => this & 0x3f;

  InstructionABC abc() {
    return InstructionABC(
      this >> 6 & 0xff,
      this >> 23 & 0x1ff,
      this >> 14 & 0x1ff,
    );
  }

  InstructionAB abx() {
    return InstructionAB(this >> 6 & 0xff, this >> 14);
  }

  InstructionAB AsBx() {
    final operand = abx();
    return InstructionAB(operand.a, operand.b - MAXARG_sBx);
  }

  int ax() => this >> 6;

  String opName() => opCodes[opCode].name;

  int opMode() => opCodes[opCode].opMode;

  int bMode() => opCodes[opCode].argBMode;

  int cMode() => opCodes[opCode].argCMode;

  void execute(LuaVM vm) {
    final action = opCodes[opCode].action;
    if (action != null)
      action(this, vm);
    else
      throw UnsupportedError('Unsupported Operation: ${opName()}');
  }
}

void move(int instruction, LuaVM vm) {
  final operand = instruction.abc();
  vm.luaState.copy(operand.b + 1, operand.a + 1);
}

void jmp(int instruction, LuaVM vm) {
  final operand = instruction.AsBx();
  vm.luaState.stack.addPC(operand.b);
  if (operand.a != 0) vm.luaState.closeClosure(operand.a);
}

void loadNil(int instruction, LuaVM vm) {
  final operand = instruction.abc();
  final a = operand.a + 1;
  final b = operand.b;

  vm.luaState.pushNull();
  for (int i = a; i <= a + b; i++) vm.luaState.copy(-1, i);
  vm.luaState.pop(1);
}

void loadBool(int instruction, LuaVM vm) {
  final operand = instruction.abc();
  vm.luaState.pushBool(operand.b != 0);
  vm.luaState.replace(operand.a + 1);
  if (operand.c != 0) vm.luaState.stack.addPC(1);
}

void loadK(int instruction, LuaVM vm) {
  final operand = instruction.abx();
  vm.luaState.getConst(operand.b);
  vm.luaState.replace(operand.a + 1);
}

void loadKx(int instruction, LuaVM vm) {
  final operand = instruction.abx();
  vm.luaState.getConst(Instruction(vm.luaState.fetch()).ax());
  vm.luaState.replace(operand.a + 1);
}

void _binaryArith(int instruction, LuaVM vm, ArithOp op) {
  final operand = instruction.abc();
  vm.luaState.getRK(operand.b);
  vm.luaState.getRK(operand.c);
  vm.luaState.arith(op);
  vm.luaState.replace(operand.a + 1);
}

void _unaryArith(int instruction, LuaVM vm, ArithOp op) {
  final operand = instruction.abc();
  vm.luaState.pushValue(operand.b + 1);
  vm.luaState.arith(op);
  vm.luaState.replace(operand.a + 1);
}

void add(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.add);
void sub(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.sub);
void mul(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.mul);
void mod(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.mod);
void pow(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.pow);
void div(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.div);
void idiv(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.idiv);
void band(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.band);
void bor(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.bor);
void bxor(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.bxor);
void shl(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.shl);
void shr(int inst, LuaVM vm) => _binaryArith(inst, vm, ArithOp.shr);
void unm(int inst, LuaVM vm) => _unaryArith(inst, vm, ArithOp.unm);
void bnot(int inst, LuaVM vm) => _unaryArith(inst, vm, ArithOp.bnot);

void len(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.luaState.len(operand.b + 1);
  vm.luaState.replace(operand.a + 1);
}

void concat(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  final b = operand.b + 1;
  final c = operand.c + 1;
  final n = c - b + 1;

  vm.luaState.checkStack(n);
  for (int i = b; i <= c; i++) vm.luaState.pushValue(i);
  vm.luaState.concat(n);
  vm.luaState.replace(a);
}

void _compare(int inst, LuaVM vm, CompareOp op) {
  final operand = inst.abc();

  vm.luaState.getRK(operand.b);
  vm.luaState.getRK(operand.c);
  if (vm.luaState.compare(-2, -1, op) != (operand.a != 0))
    vm.luaState.stack.addPC(1);
  vm.luaState.pop(2);
}

void eq(int inst, LuaVM vm) => _compare(inst, vm, CompareOp(LUA_OPEQ));
void lt(int inst, LuaVM vm) => _compare(inst, vm, CompareOp(LUA_OPLT));
void le(int inst, LuaVM vm) => _compare(inst, vm, CompareOp(LUA_OPLE));

void not(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.luaState.pushBool(!vm.luaState.toBool(operand.b + 1));
  vm.luaState.replace(operand.a + 1);
}

void testSet(int inst, LuaVM vm) {
  final operand = inst.abc();
  final b = operand.b + 1;
  if (vm.luaState.toBool(b) == (operand.c != 0))
    vm.luaState.copy(b, operand.a + 1);
  else
    vm.luaState.stack.addPC(1);
}

void test(int inst, LuaVM vm) {
  final operand = inst.abc();
  if (vm.luaState.toBool(operand.a + 1) != (operand.c != 0))
    vm.luaState.stack.addPC(1);
}

void forPrep(int inst, LuaVM vm) {
  final operand = inst.AsBx();
  final a = operand.a + 1;
  vm.luaState.pushValue(a);
  vm.luaState.pushValue(a + 2);
  vm.luaState.arith(ArithOp.sub);
  vm.luaState.replace(a);
  vm.luaState.stack.addPC(operand.b);
}

void forLoop(int inst, LuaVM vm) {
  final operand = inst.AsBx();
  final a = operand.a + 1;
  vm.luaState.pushValue(a + 2);
  vm.luaState.pushValue(a);
  vm.luaState.arith(ArithOp.add);
  vm.luaState.replace(a);

  final isPositiveStep = vm.luaState.toNumber(a + 2) >= 0;
  if (isPositiveStep && vm.luaState.compare(a, a + 1, CompareOp(LUA_OPLE)) ||
      !isPositiveStep && vm.luaState.compare(a + 1, a, CompareOp(LUA_OPLE))) {
    vm.luaState.stack.addPC(operand.b);
    vm.luaState.copy(a, a + 3);
  }
}

void newTable(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.luaState.createTable(fb2Int(operand.b), fb2Int(operand.c));
  vm.luaState.replace(operand.a + 1);
}

void getTable(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.luaState.getRK(operand.c);
  vm.luaState.getTable(operand.b + 1);
  vm.luaState.replace(operand.a + 1);
}

void setTable(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.luaState.getRK(operand.b);
  vm.luaState.getRK(operand.c);
  vm.luaState.setTable(operand.a + 1);
}

void setList(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  var b = operand.b;
  var c = operand.c;

  if (c > 0)
    c -= 1;
  else
    c = Instruction(vm.luaState.fetch()).ax();

  final bIsZero = b == 0;
  if (bIsZero) {
    b = vm.luaState.toInt(-1) - a - 1;
    vm.luaState.pop(1);
  }

  var idx = c * LFIELDS_PER_FLUSH;
  for (var j = 1; j <= b; j++) {
    idx++;
    vm.luaState.pushValue(a + j);
    vm.luaState.setI(a, idx);
  }

  if (bIsZero) {
    for (var j = vm.luaState.registerCount() + 1;
        j <= vm.luaState.getTop();
        j++) {
      idx++;
      vm.luaState.pushValue(j);
      vm.luaState.setI(a, idx);
    }
    vm.luaState.setTop(vm.luaState.registerCount());
  }
}

void closure(int inst, LuaVM vm) {
  final operand = inst.abx();
  vm.luaState.loadProto(operand.b);
  vm.luaState.replace(operand.a + 1);
}

void call(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  int nArgs = _pushFuncAndArgs(a, operand.b, vm);
  vm.luaState.call(nArgs, operand.c - 1);
  _popResults(a, operand.c, vm);
}

int _pushFuncAndArgs(int a, int b, LuaVM vm) {
  if (b >= 1) {
    vm.luaState.checkStack(b);
    for (int i = a; i < a + b; i++) vm.luaState.pushValue(i);
    return b - 1;
  } else {
    _fixStack(a, vm);
    return vm.luaState.getTop() - vm.luaState.registerCount() - 1;
  }
}

void _fixStack(int a, LuaVM vm) {
  int x = vm.luaState.toInt(-1);
  vm.luaState.pop(1);
  vm.luaState.checkStack(x - a);
  for (int i = a; i < x; i++) vm.luaState.pushValue(i);
  vm.luaState.rotate(vm.luaState.registerCount() + 1, x - a);
}

void _popResults(int a, int c, LuaVM vm) {
  if (c == 1) {
  } else if (c > 1) {
    for (int i = a + c - 2; i >= a; i--) vm.luaState.replace(i);
  } else {
    vm.luaState.checkStack(1);
    vm.luaState.pushInt(a);
  }
}

void return_(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  final b = operand.b;
  if (b == 1) {
  } else if (b > 1) {
    vm.luaState.checkStack(b - 1);
    for (int i = a; i <= a + b - 2; i++) vm.luaState.pushValue(i);
  } else
    _fixStack(a, vm);
}

void vararg(int inst, LuaVM vm) {
  final operand = inst.abc();
  final b = operand.b;
  if (b != 1) {
    vm.luaState.loadVararg(b - 1);
    _popResults(operand.a + 1, b, vm);
  }
}

void tailCall(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  int nArgs = _pushFuncAndArgs(a, operand.b, vm);
  vm.luaState.call(nArgs, -1);
  _popResults(a, 0, vm);
}

void self(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  final b = operand.b + 1;
  vm.luaState.copy(b, a + 1);
  vm.luaState.getRK(operand.c);
  vm.luaState.getTable(b);
  vm.luaState.replace(a);
}

void getTabUp(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.luaState.getRK(operand.c);
  vm.luaState.getTable(luaUpvalueIndex(operand.b + 1));
  vm.luaState.replace(operand.a + 1);
}

void setTabUp(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.luaState.getRK(operand.b);
  vm.luaState.getRK(operand.c);
  vm.luaState.setTable(luaUpvalueIndex(operand.a + 1));
}

void getUpval(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.luaState.copy(luaUpvalueIndex(operand.b + 1), operand.a + 1);
}

void setUpval(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.luaState.copy(operand.a + 1, luaUpvalueIndex(operand.b + 1));
}
