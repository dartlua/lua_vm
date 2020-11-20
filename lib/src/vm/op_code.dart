import '../constants.dart';
import 'instruction.dart';
import 'vm.dart';

class OpCode {
  final int testFlag;
  final int setAFlag;
  final int argBMode;
  final int argCMode;
  final int opMode;
  final String name;
  final Function(int instruction, LuaVM vm) action;

  OpCode(this.testFlag, this.setAFlag, this.argBMode, this.argCMode,
      this.opMode, this.name, this.action);
}

List<OpCode> opCodes = [
  OpCode(0, 1, OpArgR, OpArgN, IABC, 'MOVE', move),
  OpCode(0, 1, OpArgK, OpArgN, IABx, 'LOADK', loadK),
  OpCode(0, 1, OpArgN, OpArgN, IABx, 'LOADKX', loadKx),
  OpCode(0, 1, OpArgU, OpArgU, IABC, 'LOADBOOL', loadBool),
  OpCode(0, 1, OpArgU, OpArgN, IABC, 'LOADNIL', loadNil),
  OpCode(0, 1, OpArgU, OpArgN, IABC, 'GETUPVAL', getUpval),
  OpCode(0, 1, OpArgU, OpArgK, IABC, 'GETTABUP', getTabUp),
  OpCode(0, 1, OpArgR, OpArgK, IABC, 'GETTABLE', getTable),
  OpCode(0, 0, OpArgK, OpArgK, IABC, 'SETTABUP', setTabUp),
  OpCode(0, 0, OpArgU, OpArgN, IABC, 'SETUPVAL', setUpval),
  OpCode(0, 0, OpArgK, OpArgK, IABC, 'SETTABLE', setTable),
  OpCode(0, 0, OpArgU, OpArgU, IABC, 'NEWTABLE', newTable),
  OpCode(0, 1, OpArgR, OpArgK, IABC, 'SELF', self),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'ADD', add),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'SUB', sub),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'MUL', mul),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'MOD', mod),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'POW', pow),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'DIV', div),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'IDIV', idiv),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'BAND', band),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'BOR', bor),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'BXOR', bxor),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'SHL', shl),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'SHR', shr),
  OpCode(0, 1, OpArgR, OpArgN, IABC, 'UNM', unm),
  OpCode(0, 1, OpArgR, OpArgN, IABC, 'BNOT', bnot),
  OpCode(0, 1, OpArgR, OpArgN, IABC, 'NOT', not),
  OpCode(0, 1, OpArgR, OpArgN, IABC, 'LEN', len),
  OpCode(0, 1, OpArgR, OpArgR, IABC, 'CONCAT', concat),
  OpCode(0, 0, OpArgR, OpArgN, IAsBx, 'JMP', jmp),
  OpCode(1, 0, OpArgK, OpArgK, IABC, 'EQ', eq),
  OpCode(1, 0, OpArgK, OpArgK, IABC, 'LT', lt),
  OpCode(1, 0, OpArgK, OpArgK, IABC, 'LE', le),
  OpCode(1, 0, OpArgN, OpArgU, IABC, 'TEST', test),
  OpCode(1, 1, OpArgR, OpArgU, IABC, 'TESTSET', testSet),
  OpCode(0, 1, OpArgU, OpArgU, IABC, 'CALL', call),
  OpCode(0, 1, OpArgU, OpArgU, IABC, 'TAILCALL', tailCall),
  OpCode(0, 0, OpArgU, OpArgN, IABC, 'RETURN', return_),
  OpCode(0, 1, OpArgR, OpArgN, IAsBx, 'FORLOOP', forLoop),
  OpCode(0, 1, OpArgR, OpArgN, IAsBx, 'FORPREP', forPrep),
  OpCode(0, 0, OpArgN, OpArgU, IABC, 'TFORCALL', null),
  OpCode(0, 1, OpArgR, OpArgN, IAsBx, 'TFORLOOP', null),
  OpCode(0, 0, OpArgU, OpArgU, IABC, 'SETLIST', setList),
  OpCode(0, 1, OpArgU, OpArgN, IABx, 'CLOSURE', closure),
  OpCode(0, 1, OpArgU, OpArgN, IABC, 'VARARG', vararg),
  OpCode(0, 0, OpArgU, OpArgU, IAx, 'EXTRAARG', null)
];
