import '../constants.dart';

class OpCode{
  final int testFlag;
  final int setAFlag;
  final int argBMode;
  final int argCMode;
  final int opMode;
  final String name;

  OpCode(
      this.testFlag,
      this.setAFlag,
      this.argBMode,
      this.argCMode,
      this.opMode,
      this.name);
}

List<OpCode> opCodes = [
  OpCode(0, 1, OpArgR, OpArgN, IABC, 'MOVE'),
  OpCode(0, 1, OpArgK, OpArgN, IABx, 'LOADK'),
  OpCode(0, 1, OpArgN, OpArgN, IABx, 'LOADKX'),
  OpCode(0, 1, OpArgU, OpArgU, IABC, 'LOADBOOL'),
  OpCode(0, 1, OpArgU, OpArgN, IABC, 'LOADNIL'),
  OpCode(0, 1, OpArgU, OpArgN, IABC, 'GETUPVAL'),
  OpCode(0, 1, OpArgU, OpArgK, IABC, 'GETTABUP'),
  OpCode(0, 1, OpArgR, OpArgK, IABC, 'GETTABLE'),
  OpCode(0, 0, OpArgK, OpArgK, IABC, 'SETTABUP'),
  OpCode(0, 0, OpArgU, OpArgN, IABC, 'SETUPVAL'),
  OpCode(0, 0, OpArgK, OpArgK, IABC, 'SETTABLE'),
  OpCode(0, 0, OpArgU, OpArgU, IABC, 'NEWTABLE'),
  OpCode(0, 1, OpArgR, OpArgK, IABC, 'SELF'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'ADD'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'SUB'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'MUL'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'MOD'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'POW'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'DIV'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'IDIV'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'BAND'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'BOR'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'BXOR'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'SHL'),
  OpCode(0, 1, OpArgK, OpArgK, IABC, 'SHR'),
  OpCode(0, 1, OpArgR, OpArgN, IABC, 'UNM'),
  OpCode(0, 1, OpArgR, OpArgN, IABC, 'BNOT'),
  OpCode(0, 1, OpArgR, OpArgN, IABC, 'NOT'),
  OpCode(0, 1, OpArgR, OpArgN, IABC, 'LEN'),
  OpCode(0, 1, OpArgR, OpArgR, IABC, 'CONCAT'),
  OpCode(0, 0, OpArgR, OpArgN, IAsBx, 'JMP'),
  OpCode(1, 0, OpArgK, OpArgK, IABC, 'EQ'),
  OpCode(1, 0, OpArgK, OpArgK, IABC, 'LT'),
  OpCode(1, 0, OpArgK, OpArgK, IABC, 'LE'),
  OpCode(1, 0, OpArgN, OpArgU, IABC, 'TEST'),
  OpCode(1, 1, OpArgR, OpArgU, IABC, 'TESTSET'),
  OpCode(0, 1, OpArgU, OpArgU, IABC, 'CALL'),
  OpCode(0, 1, OpArgU, OpArgU, IABC, 'TALLCALL'),
  OpCode(0, 0, OpArgU, OpArgN, IABC, 'RETURN'),
  OpCode(0, 1, OpArgR, OpArgN, IAsBx, 'FORLOOP'),
  OpCode(0, 1, OpArgR, OpArgN, IAsBx, 'FORPREP'),
  OpCode(0, 0, OpArgN, OpArgU, IABC, 'TFORCALL'),
  OpCode(0, 1, OpArgR, OpArgN, IAsBx, 'TFORLOOP'),
  OpCode(0, 0, OpArgU, OpArgU, IABC, 'SETLIST'),
  OpCode(0, 1, OpArgU, OpArgN, IABx, 'CLOSURE'),
  OpCode(0, 1, OpArgU, OpArgN, IABC, 'VARARG'),
  OpCode(0, 0, OpArgU, OpArgU, IAx, 'EXTRAARG')
];
