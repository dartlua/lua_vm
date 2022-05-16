import 'package:luart/src/api/lua_vm.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/vm/instruction.dart';

class OpCode {
  final int testFlag;
  final int setAFlag;
  final int argBMode;
  final int argCMode;
  final int opMode;
  final String name;
  final Function(int instruction, LuaVM vm)? action;

  OpCode(
    this.testFlag,
    this.setAFlag,
    this.argBMode,
    this.argCMode,
    this.opMode,
    this.name,
    this.action,
  );
}

List<OpCode> opCodes = [
  OpCode(0, 1, opArgR, opArgN, iABC, 'MOVE', move),
  OpCode(0, 1, opArgK, opArgN, iABx, 'LOADK', loadK),
  OpCode(0, 1, opArgN, opArgN, iABx, 'LOADKX', loadKx),
  OpCode(0, 1, opArgU, opArgU, iABC, 'LOADBOOL', loadBool),
  OpCode(0, 1, opArgU, opArgN, iABC, 'LOADNIL', loadNil),
  OpCode(0, 1, opArgU, opArgN, iABC, 'GETUPVAL', getUpval),
  OpCode(0, 1, opArgU, opArgK, iABC, 'GETTABUP', getTabUp),
  OpCode(0, 1, opArgR, opArgK, iABC, 'GETTABLE', getTable),
  OpCode(0, 0, opArgK, opArgK, iABC, 'SETTABUP', setTabUp),
  OpCode(0, 0, opArgU, opArgN, iABC, 'SETUPVAL', setUpval),
  OpCode(0, 0, opArgK, opArgK, iABC, 'SETTABLE', setTable),
  OpCode(0, 0, opArgU, opArgU, iABC, 'NEWTABLE', newTable),
  OpCode(0, 1, opArgR, opArgK, iABC, 'SELF', self),
  OpCode(0, 1, opArgK, opArgK, iABC, 'ADD', add),
  OpCode(0, 1, opArgK, opArgK, iABC, 'SUB', sub),
  OpCode(0, 1, opArgK, opArgK, iABC, 'MUL', mul),
  OpCode(0, 1, opArgK, opArgK, iABC, 'MOD', mod),
  OpCode(0, 1, opArgK, opArgK, iABC, 'POW', pow),
  OpCode(0, 1, opArgK, opArgK, iABC, 'DIV', div),
  OpCode(0, 1, opArgK, opArgK, iABC, 'IDIV', idiv),
  OpCode(0, 1, opArgK, opArgK, iABC, 'BAND', band),
  OpCode(0, 1, opArgK, opArgK, iABC, 'BOR', bor),
  OpCode(0, 1, opArgK, opArgK, iABC, 'BXOR', bxor),
  OpCode(0, 1, opArgK, opArgK, iABC, 'SHL', shl),
  OpCode(0, 1, opArgK, opArgK, iABC, 'SHR', shr),
  OpCode(0, 1, opArgR, opArgN, iABC, 'UNM', unm),
  OpCode(0, 1, opArgR, opArgN, iABC, 'BNOT', bnot),
  OpCode(0, 1, opArgR, opArgN, iABC, 'NOT', not),
  OpCode(0, 1, opArgR, opArgN, iABC, 'LEN', len),
  OpCode(0, 1, opArgR, opArgR, iABC, 'CONCAT', concat),
  OpCode(0, 0, opArgR, opArgN, iAsBx, 'JMP', jmp),
  OpCode(1, 0, opArgK, opArgK, iABC, 'EQ', eq),
  OpCode(1, 0, opArgK, opArgK, iABC, 'LT', lt),
  OpCode(1, 0, opArgK, opArgK, iABC, 'LE', le),
  OpCode(1, 0, opArgN, opArgU, iABC, 'TEST', test),
  OpCode(1, 1, opArgR, opArgU, iABC, 'TESTSET', testSet),
  OpCode(0, 1, opArgU, opArgU, iABC, 'CALL', call),
  OpCode(0, 1, opArgU, opArgU, iABC, 'TAILCALL', tailCall),
  OpCode(0, 0, opArgU, opArgN, iABC, 'RETURN', return_),
  OpCode(0, 1, opArgR, opArgN, iAsBx, 'FORLOOP', forLoop),
  OpCode(0, 1, opArgR, opArgN, iAsBx, 'FORPREP', forPrep),
  OpCode(0, 0, opArgN, opArgU, iABC, 'TFORCALL', tForCall),
  OpCode(0, 1, opArgR, opArgN, iAsBx, 'TFORLOOP', tForLoop),
  OpCode(0, 0, opArgU, opArgU, iABC, 'SETLIST', setList),
  OpCode(0, 1, opArgU, opArgN, iABx, 'CLOSURE', closure),
  OpCode(0, 1, opArgU, opArgN, iABC, 'VARARG', vararg),
  OpCode(0, 0, opArgU, opArgU, iAx, 'EXTRAARG', null)
];
