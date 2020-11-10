import '../constants.dart';
import '../operation/arith.dart';
import 'op_code.dart';
import 'vm.dart';

class Instruction{
  int instruction;

  Instruction(int this.instruction);

  int opCode() => instruction & 0x3f;

  List<int> ABC() => [
    instruction >> 6 & 0xff,
    instruction >> 14 & 0x1ff,
    instruction >> 23 & 0x1ff
  ];

  List<int> ABx() => [
    instruction >> 6 & 0xff,
    instruction >> 14
  ];

  List<int> AsBx() {
    var a = ABx();
    return [a[0], a[1] - MAXARG_sBx];
  }

  int Ax() => instruction >> 6;

  String opName() => opCodes[opCode()].name;

  int opMode() => opCodes[opCode()].opMode;

  int BMode() => opCodes[opCode()].argBMode;

  int CMode() => opCodes[opCode()].argCMode;

  void execute(LuaVM vm){
    Function action = opCodes[opCode()].action;
    print(opCode());
    if(action != null) action(Instruction(instruction), vm);
    else throw UnsupportedError('unsupported Operation: ${opName()}');
  }
}

void move(Instruction i, LuaVM vm){
  List l = i.ABC();
  int a = l[0] + 1;
  int b = l[1] + 1;
  vm.luaState.copy(b, a);
}

void jmp(Instruction i, LuaVM vm){
  List l = i.AsBx();
  vm.luaState.addPC(l[1]);
  if(l[0] != 0) throw UnsupportedError('todo!');
}

void loadNil(Instruction i, LuaVM vm){
  List l = i.ABC();
  int a = l[0] + 1;
  int b = l[1];

  vm.luaState.pushNull();
  for(int i = a; i <= a + b; i++) vm.luaState.copy(-1, i);
  vm.luaState.pop(1);
}

void loadBool(Instruction i , LuaVM vm){
  List l = i.ABC();
  vm.luaState.pushBool(l[1] != 0);
  vm.luaState.replace(l[0] + 1);
  if(l[2] != 0) vm.luaState.addPC(1);
}

void loadK(Instruction i, LuaVM vm){
  List l = i.ABx();
  vm.luaState.getConst(l[1]);
  vm.luaState.replace(l[0] + 1);
}

void loadKx(Instruction i, LuaVM vm){
  List l = i.ABx();
  vm.luaState.getConst(Instruction(vm.luaState.fetch()).Ax());
  vm.luaState.replace(l[0] + 1);
}

void _binaryArith(Instruction i, LuaVM vm, ArithOp op){
  List l = i.ABC();
  vm.luaState.getRK(l[1]);
  vm.luaState.getRK(l[2]);
  vm.luaState.arith(op);
  vm.luaState.replace(l[0] + 1);
}

void _unaryArith(Instruction i, LuaVM vm, ArithOp op){
  List l = i.ABC();
  vm.luaState.pushValue(l[1] + 1);
  vm.luaState.arith(op);
  vm.luaState.replace(l[0] + 1);
}

void add(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPADD));
void sub(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPSUB));
void mul(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPMUL));
void mod(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPMOD));
void pow(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPPOW));
void div(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPDIV));
void idiv(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPIDIV));
void band(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPBAND));
void bor(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPBOR));
void bxor(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPBXOR));
void shl(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPSHL));
void shr(Instruction i, LuaVM vm) => _binaryArith(i, vm, ArithOp(LUA_OPSHR));
void unm(Instruction i, LuaVM vm) => _unaryArith(i, vm, ArithOp(LUA_OPUNM));
void bnot(Instruction i, LuaVM vm) => _unaryArith(i, vm, ArithOp(LUA_OPBNOT));

void len(Instruction i, LuaVM vm){
  List l = i.ABC();
  vm.luaState.len(l[1] + 1);
  vm.luaState.replace(l[0] + 1);
}

void concat(Instruction i, LuaVM vm){
  List l = i.ABC();
  int a = l[0] + 1;
  int b = l[1] + 1;
  int c = l[2] + 1;
  int n = c - b + 1;
  
  vm.luaState.checkStack(n);
  for(int i = b; i <= c; i++) vm.luaState.pushValue(i);
  vm.luaState.concat(n);
  vm.luaState.replace(a);
}

void _compare(Instruction i , LuaVM vm, CompareOp op){
  List l = i.ABC();
  
  vm.luaState.getRK(l[1]);
  vm.luaState.getRK(l[2]);
  if(vm.luaState.compare(-2, -1, op) != (l[0] != 0)) vm.luaState.addPC(1);
  vm.luaState.pop(2);
}

void eq(Instruction i, LuaVM vm) => _compare(i, vm, CompareOp(LUA_OPEQ));
void lt(Instruction i, LuaVM vm) => _compare(i, vm, CompareOp(LUA_OPLT));
void le(Instruction i, LuaVM vm) => _compare(i ,vm, CompareOp(LUA_OPLE));

void not(Instruction i, LuaVM vm){
  List l = i.ABC();
  vm.luaState.pushBool(!vm.luaState.toBool(l[1] + 1));
  vm.luaState.replace(l[0] + 1);
}

void testSet(Instruction i , LuaVM vm){
  List l = i.ABC();
  int b = l[1] + 1;
  if(vm.luaState.toBool(b) == (l[2] != 0))
    vm.luaState.copy(b, l[0] + 1);
  else vm.luaState.addPC(1);
}

void test(Instruction i, LuaVM vm){
  List l = i.ABC();
  if(vm.luaState.toBool(l[0] + 1) != (l[2] != 0)) vm.luaState.addPC(1);
}

void forPrep(Instruction i, LuaVM vm){
  List l = i.AsBx();
  int a = l[0] + 1;
  vm.luaState.pushValue(a);
  vm.luaState.pushValue(a + 2);
  vm.luaState.arith(ArithOp(LUA_OPSUB));
  vm.luaState.replace(a);
  vm.luaState.addPC(l[1]);
}

void forLoop(Instruction i, LuaVM vm){
  List l = i.AsBx();
  int a = l[0] + 1;
  vm.luaState.pushValue(a + 2);
  vm.luaState.pushValue(a);
  vm.luaState.arith(ArithOp(LUA_OPADD));
  vm.luaState.replace(a);

  bool isPositiveStep = vm.luaState.toNumber(a + 2) >= 0;
  if(isPositiveStep && vm.luaState.compare(a, a + 1, CompareOp(LUA_OPLE))
      || !isPositiveStep && vm.luaState.compare(a + 1, a, CompareOp(LUA_OPLE))){
    vm.luaState.addPC(l[1]);
    vm.luaState.copy(a, a + 3);
  }
}