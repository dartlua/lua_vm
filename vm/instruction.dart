import '../api/state.dart';
import '../constants.dart';
import '../operation/arith.dart';
import '../operation/fpb.dart';
import 'op_code.dart';
import 'vm.dart';

class Instruction{
  int instruction;

  Instruction(int this.instruction);

  int opCode() => instruction & 0x3f;

  List<int> ABC() => [
    instruction >> 6 & 0xff,
    instruction >> 23 & 0x1ff,
    instruction >> 14 & 0x1ff,
  ];

  List<int> ABx() => [
    instruction >> 6 & 0xff,
    instruction >> 14
  ];

  List<int> AsBx() {
    List a = ABx();
    return [a[0], a[1] - MAXARG_sBx];
  }

  int Ax() => instruction >> 6;

  String opName() => opCodes[opCode()].name;

  int opMode() => opCodes[opCode()].opMode;

  int BMode() => opCodes[opCode()].argBMode;

  int CMode() => opCodes[opCode()].argCMode;

  void execute(LuaVM vm){
    Function action = opCodes[opCode()].action;
    if(action != null) action(Instruction(instruction), vm);
    else throw UnsupportedError('Unsupported Operation: ${opName()}');
  }
}

void move(Instruction i, LuaVM vm){
  List l = i.ABC();
  vm.luaState.copy(l[1] + 1, l[0] + 1);
}

void jmp(Instruction i, LuaVM vm){
  List l = i.AsBx();
  vm.luaState.stack.addPC(l[1]);
  if(l[0] != 0) vm.luaState.closeClosure(l[0]);
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
  if(l[2] != 0) vm.luaState.stack.addPC(1);
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
  if(vm.luaState.compare(-2, -1, op) != (l[0] != 0)) vm.luaState.stack.addPC(1);
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
  else vm.luaState.stack.addPC(1);
}

void test(Instruction i, LuaVM vm){
  List l = i.ABC();
  if(vm.luaState.toBool(l[0] + 1) != (l[2] != 0)) vm.luaState.stack.addPC(1);
}

void forPrep(Instruction i, LuaVM vm){
  List l = i.AsBx();
  int a = l[0] + 1;
  vm.luaState.pushValue(a);
  vm.luaState.pushValue(a + 2);
  vm.luaState.arith(ArithOp(LUA_OPSUB));
  vm.luaState.replace(a);
  vm.luaState.stack.addPC(l[1]);
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
    vm.luaState.stack.addPC(l[1]);
    vm.luaState.copy(a, a + 3);
  }
}

void newTable(Instruction i, LuaVM vm){
  List l = i.ABC();
  vm.luaState.createTable(fb2Int(l[1]), fb2Int(l[2]));
  vm.luaState.replace(l[0] + 1);
}

void getTable(Instruction i , LuaVM vm){
  List l = i.ABC();
  vm.luaState.getRK(l[2]);
  vm.luaState.getTable(l[1] + 1);
  vm.luaState.replace(l[0] + 1);
}

void setTable(Instruction i, LuaVM vm){
  List l = i.ABC();
  vm.luaState.getRK(l[1]);
  vm.luaState.getRK(l[2]);
  vm.luaState.setTable(l[0] + 1);
}

void setList(Instruction i, LuaVM vm){
  List l = i.ABC();
  int a = l[0] + 1;
  int b = l[1];
  int c = l[2];

  if(c > 0) c -= 1;
  else c = Instruction(vm.luaState.fetch()).Ax();

  bool bIsZero = b == 0;
  if(bIsZero){
    b = vm.luaState.toInt(-1) - a - 1;
    vm.luaState.pop(1);
  }

  int idx = c * LFIELDS_PER_FLUSH;
  for(int j = 1; j <= b; j++){
    idx++;
    vm.luaState.pushValue(a + j);
    vm.luaState.setI(a, idx);
  }

  if(bIsZero){
    for(int j = vm.luaState.registerCount() + 1; j <= vm.luaState.getTop(); j++){
      idx++;
      vm.luaState.pushValue(j);
      vm.luaState.setI(a, idx);
    }
    vm.luaState.setTop(vm.luaState.registerCount());
  }
}

void closure(Instruction i, LuaVM vm){
  List l = i.ABx();
  vm.luaState.loadProto(l[1]);
  vm.luaState.replace(l[0] + 1);
}

void call(Instruction i, LuaVM vm){
  List l = i.ABC();
  int a = l[0] + 1;
  int nArgs = _pushFuncAndArgs(a, l[1], vm);
  vm.luaState.call(nArgs, l[2] - 1);
  _popResults(a, l[2], vm);
}

int _pushFuncAndArgs(int a, int b, LuaVM vm){
  if(b >= 1){
    vm.luaState.checkStack(b);
    for(int i = a; i < a + b; i++) vm.luaState.pushValue(i);
    return b - 1;
  } else {
    _fixStack(a, vm);
    return vm.luaState.getTop() - vm.luaState.registerCount() - 1;
  }
}

void _fixStack(int a, LuaVM vm){
  int x = vm.luaState.toInt(-1);
  vm.luaState.pop(1);
  vm.luaState.checkStack(x - a);
  for(int i = a; i < x; i++) vm.luaState.pushValue(i);
  vm.luaState.rotate(vm.luaState.registerCount() + 1, x - a);
}

void _popResults(int a, int c, LuaVM vm){
  if(c == 1){}
  else if(c > 1){
    for(int i = a + c - 2; i >= a; i--) vm.luaState.replace(i);
  } else {
    vm.luaState.checkStack(1);
    vm.luaState.pushInt(a);
  }
}

void return_(Instruction i, LuaVM vm){
  List l = i.ABC();
  int a = l[0] + 1;
  int b = l[1];
  if(b == 1){}
  else if(b > 1){
    vm.luaState.checkStack(b - 1);
    for(int i = a; i <= a + b - 2; i++) vm.luaState.pushValue(i);
  } else _fixStack(a, vm);
}

void vararg(Instruction i, LuaVM vm){
  List l = i.ABC();
  int b = l[1];
  if(b != 1){
    vm.luaState.loadVararg(b - 1);
    _popResults(l[0] + 1, b, vm);
  }
}

void tailCall(Instruction i, LuaVM vm){
  List l = i.ABC();
  int a = l[0] + 1;
  int nArgs = _pushFuncAndArgs(a, l[1], vm);
  vm.luaState.call(nArgs, -1);
  _popResults(a, 0, vm);
}

void self(Instruction i, LuaVM vm){
  List l = i.ABC();
  int a = l[0] + 1;
  int b = l[1] + 1;
  vm.luaState.copy(b, a + 1);
  vm.luaState.getRK(l[2]);
  vm.luaState.getTable(b);
  vm.luaState.replace(a);
}

void getTabUp(Instruction i, LuaVM vm){
  List l = i.ABC();
  vm.luaState.getRK(l[2]);
  vm.luaState.getTable(luaUpvalueIndex(l[1] + 1));
  vm.luaState.replace(l[0] + 1);
}

void setTabUp(Instruction i, LuaVM vm){
  List l = i.ABC();
  vm.luaState.getRK(l[1]);
  vm.luaState.getRK(l[2]);
  vm.luaState.setTable(luaUpvalueIndex(l[0] + 1));
}

void getUpval(Instruction i, LuaVM vm){
  List l = i.ABC();
  vm.luaState.copy(luaUpvalueIndex(l[1] + 1), l[0] + 1);
}

void setUpval(Instruction i, LuaVM vm){
  List l = i.ABC();
  vm.luaState.copy(l[0] + 1, luaUpvalueIndex(l[1] + 1));
}