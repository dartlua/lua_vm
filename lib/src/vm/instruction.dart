import 'package:luart/src/api/lua_vm.dart';
import 'package:luart/src/api/lua_state.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/state/lua_state.dart';
import 'package:luart/src/vm/fpb.dart';
import 'package:luart/src/vm/op_code.dart';


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

  InstructionAB asBx() {
    final operand = abx();
    return InstructionAB(operand.a, operand.b - MAXARG_sBx);
  }

  int ax() => this >> 6;

  String opName() => opCodes[opCode].name;

  int opMode() => opCodes[opCode].opMode;

  int bMode() => opCodes[opCode].argBMode;

  int cMode() => opCodes[opCode].argCMode;

  void execute(LuaStateImpl vm) {
    final action = opCodes[opCode].action;
    if (action != null) {
      action(this, vm);
    } else {
      throw UnsupportedError('Unsupported Operation: ${opName()}');
    }
  }
}

void move(int instruction, LuaVM vm) {
  final operand = instruction.abc();
  vm.copy(operand.b + 1, operand.a + 1);
}

void jmp(int instruction, LuaVM vm) {
  final operand = instruction.asBx();
  vm.stack!.addPC(operand.b);
  if (operand.a != 0) vm.closeClosure(operand.a);
}

void loadNil(int instruction, LuaVM vm) {
  final operand = instruction.abc();
  final a = operand.a + 1;
  final b = operand.b;

  vm.pushNil();
  for (var i = a; i <= a + b; i++) {
    vm.copy(-1, i);
  }
  vm.pop(1);
}

void loadBool(int instruction, LuaVM vm) {
  final operand = instruction.abc();
  vm.pushBool(operand.b != 0);
  vm.replace(operand.a + 1);
  if (operand.c != 0) vm.stack!.addPC(1);
}

void loadK(int instruction, LuaVM vm) {
  final operand = instruction.abx();
  vm.getConst(operand.b);
  vm.replace(operand.a + 1);
}

void loadKx(int instruction, LuaVM vm) {
  final operand = instruction.abx();
  vm.getConst(Instruction(vm.fetch()).ax());
  vm.replace(operand.a + 1);
}

void _binaryArith(int instruction, LuaVM vm, LuaArithOp op) {
  final operand = instruction.abc();
  vm.getRK(operand.b);
  vm.getRK(operand.c);
  vm.arith(op);
  vm.replace(operand.a + 1);
}

void _unaryArith(int instruction, LuaVM vm, LuaArithOp op) {
  final operand = instruction.abc();
  vm.pushValue(operand.b + 1);
  vm.arith(op);
  vm.replace(operand.a + 1);
}

void add(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.add);

void sub(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.sub);

void mul(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.mul);

void mod(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.mod);

void pow(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.pow);

void div(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.div);

void idiv(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.idiv);

void band(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.band);

void bor(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.bor);

void bxor(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.bxor);

void shl(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.shl);

void shr(int inst, LuaVM vm) => _binaryArith(inst, vm, LuaArithOp.shr);

void unm(int inst, LuaVM vm) => _unaryArith(inst, vm, LuaArithOp.unm);

void bnot(int inst, LuaVM vm) => _unaryArith(inst, vm, LuaArithOp.bnot);

void len(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.len(operand.b + 1);
  vm.replace(operand.a + 1);
}

void concat(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  final b = operand.b + 1;
  final c = operand.c + 1;
  final n = c - b + 1;

  vm.checkStack(n);
  for (var i = b; i <= c; i++) {
    vm.pushValue(i);
  }
  vm.concat(n);
  vm.replace(a);
}

void _compare(int inst, LuaVM vm, LuaCompareOp op) {
  final operand = inst.abc();

  vm.getRK(operand.b);
  vm.getRK(operand.c);
  if (vm.compare(-2, -1, op) != (operand.a != 0)) {
    vm.stack!.addPC(1);
  }
  vm.pop(2);
}

void eq(int inst, LuaVM vm) => _compare(inst, vm, LuaCompareOp.eq);

void lt(int inst, LuaVM vm) => _compare(inst, vm, LuaCompareOp.lt);

void le(int inst, LuaVM vm) => _compare(inst, vm, LuaCompareOp.le);

void not(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.pushBool(!vm.toBool(operand.b + 1));
  vm.replace(operand.a + 1);
}

void testSet(int inst, LuaVM vm) {
  final operand = inst.abc();
  final b = operand.b + 1;
  if (vm.toBool(b) == (operand.c != 0)) {
    vm.copy(b, operand.a + 1);
  } else {
    vm.stack!.addPC(1);
  }
}

void test(int inst, LuaVM vm) {
  final operand = inst.abc();
  if (vm.toBool(operand.a + 1) != (operand.c != 0)) {
    vm.stack!.addPC(1);
  }
}

void forPrep(int inst, LuaVM vm) {
  final operand = inst.asBx();
  final a = operand.a + 1;
  vm.pushValue(a);
  vm.pushValue(a + 2);
  vm.arith(LuaArithOp.sub);
  vm.replace(a);
  vm.stack!.addPC(operand.b);
}

void forLoop(int inst, LuaVM vm) {
  final operand = inst.asBx();
  final a = operand.a + 1;
  vm.pushValue(a + 2);
  vm.pushValue(a);
  vm.arith(LuaArithOp.add);
  vm.replace(a);

  final isPositiveStep = vm.toNumber(a + 2) >= 0;
  if (isPositiveStep && vm.compare(a, a + 1, LuaCompareOp.le) ||
      !isPositiveStep && vm.compare(a + 1, a, LuaCompareOp.le)) {
    vm.stack!.addPC(operand.b);
    vm.copy(a, a + 3);
  }
}

void newTable(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.createTable(fb2Int(operand.b), fb2Int(operand.c));
  vm.replace(operand.a + 1);
}

void getTable(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.getRK(operand.c);
  vm.getTable(operand.b + 1);
  vm.replace(operand.a + 1);
}

void setTable(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.getRK(operand.b);
  vm.getRK(operand.c);
  vm.setTable(operand.a + 1);
}

void setList(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  var b = operand.b;
  var c = operand.c;

  if (c > 0) {
    c -= 1;
  } else {
    c = Instruction(vm.fetch()).ax();
  }

  final bIsZero = b == 0;
  if (bIsZero) {
    b = vm.toInt(-1) - a - 1;
    vm.pop(1);
  }

  var idx = c * LFIELDS_PER_FLUSH;
  for (var j = 1; j <= b; j++) {
    idx++;
    vm.pushValue(a + j);
    vm.setI(a, idx);
  }

  if (bIsZero) {
    for (var j = vm.registerCount() + 1;
        j <= vm.getTop();
        j++) {
      idx++;
      vm.pushValue(j);
      vm.setI(a, idx);
    }
    vm.setTop(vm.registerCount());
  }
}

void closure(int inst, LuaVM vm) {
  final operand = inst.abx();
  vm.loadProto(operand.b);
  vm.replace(operand.a + 1);
}

void call(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  final nArgs = _pushFuncAndArgs(a, operand.b, vm);
  vm.call(nArgs, operand.c - 1);
  _popResults(a, operand.c, vm);
}

int _pushFuncAndArgs(int a, int b, LuaVM vm) {
  if (b >= 1) {
    vm.checkStack(b);
    for (var i = a; i < a + b; i++) {
      vm.pushValue(i);
    }
    return b - 1;
  } else {
    _fixStack(a, vm);
    return vm.getTop() - vm.registerCount() - 1;
  }
}

void _fixStack(int a, LuaVM vm) {
  final x = vm.toInt(-1);
  vm.pop(1);
  vm.checkStack(x - a);
  for (var i = a; i < x; i++) {
    vm.pushValue(i);
  }
  vm.rotate(vm.registerCount() + 1, x - a);
}

void _popResults(int a, int c, LuaVM vm) {
  if (c == 1) {
  } else if (c > 1) {
    for (var i = a + c - 2; i >= a; i--) {
      vm.replace(i);
    }
  } else {
    vm.checkStack(1);
    vm.pushInt(a);
  }
}

void return_(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  final b = operand.b;
  if (b == 1) {
  } else if (b > 1) {
    vm.checkStack(b - 1);
    for (var i = a; i <= a + b - 2; i++) {
      vm.pushValue(i);
    }
  } else {
    _fixStack(a, vm);
  }
}

void vararg(int inst, LuaVM vm) {
  final operand = inst.abc();
  final b = operand.b;
  if (b != 1) {
    vm.loadVararg(b - 1);
    _popResults(operand.a + 1, b, vm);
  }
}

void tailCall(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  var nArgs = _pushFuncAndArgs(a, operand.b, vm);
  vm.call(nArgs, -1);
  _popResults(a, 0, vm);
}

void self(int inst, LuaVM vm) {
  final operand = inst.abc();
  final a = operand.a + 1;
  final b = operand.b + 1;
  vm.copy(b, a + 1);
  vm.getRK(operand.c);
  vm.getTable(b);
  vm.replace(a);
}

void getTabUp(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.getRK(operand.c);
  vm.getTable(luaUpvalueIndex(operand.b + 1));
  vm.replace(operand.a + 1);
}

void setTabUp(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.getRK(operand.b);
  vm.getRK(operand.c);
  vm.setTable(luaUpvalueIndex(operand.a + 1));
}

void getUpval(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.copy(luaUpvalueIndex(operand.b + 1), operand.a + 1);
}

void setUpval(int inst, LuaVM vm) {
  final operand = inst.abc();
  vm.copy(operand.a + 1, luaUpvalueIndex(operand.b + 1));
}
