//for check chunk
import 'vm/op_code.dart';

const LUA_SIGNATURE = '1b4c7561'; //\x1bLua
const LUAC_VERSION = '53';
const LUAC_FORMAT = '00';
const LUAC_DATA = '19930d0a1a0a'; //\x19\x93\r\n\x1a\n
const CINT_SIZE = 4;
const CSIZET_SIZE = 8;
const INSTRUCTION_SIZE = 4;
const LUA_INTEGER_SIZE = 8;
const LUA_NUMBER_SIZE = 8;
const LUAC_INT = 22136; //0x7856
const LUAC_NUM = 370.5;
const TAG_NIL = '00';
const TAG_BOOLEAN = '01';
const TAG_NUMBER = '03';
const TAG_INTEGER = '13';
const TAG_SHORT_STR = '04';
const TAG_LONG_STR = '14';

//operation code
const MOVE = 0;
const LOADK = 1;
const LOADKX = 2;
const LOADBOOL = 3;
const LOADNIL = 4;
const GETUPVAL = 5;
const GETTABUP = 6;
const GETTABLE = 7;
const SETTABUP = 8;
const SETUPVAL = 9;
const SETTABLE = 10;
const NEWTABLE = 11;
const SELF = 12;
const ADD = 13;
const SUB = 14;
const MUL = 15;
const MOD = 16;
const POW = 17;
const DIV = 18;
const IDIV = 19;
const BAND = 20;
const BOR = 21;
const BXOR = 22;
const SHL = 23;
const SHR = 24;
const UNM = 25;
const BNOT = 26;
const NOT = 27;
const LEN = 28;
const CONCAT = 29;
const JMP = 30;
const EQ = 31;
const LT = 32;
const LE = 33;
const TEST = 34;
const TESTSET = 35;
const CALL = 36;
const TAILCALL = 37;
const RETURN = 38;
const FORLOOP = 39;
const FORPREP = 40;
const TFORCALL = 41;
const TFORLOOP = 42;
const SETLIST = 43;
const CLOSURE = 44;
const VARARG = 45;
const EXTRAARG = 46;

// OpMode
const IABC = 0;
const IABx = 1;
const IAsBx = 2;
const IAx = 3;

// OpArg
const OpArgN = 0;
const OpArgU = 1;
const OpArgR = 2;
const OpArgK = 3;

//OpCodes (model/op_code.dart)
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

//MAXARG
const MAXARG_Bx = 1 << 18 - 1;
const MAXARG_sBx = MAXARG_Bx >> 1;

//LUA_TYPE
const LUA_TNONE = -1;
const LUA_TNIL = 0;
const LUA_TBOOLEAN = 1;
const LUA_TLIGHTUSERDATA = 2;
const LUA_TNUMBER = 3;
const LUA_TSTRING = 4;
const LUA_TTABLE = 5;
const LUA_TFUNCTION = 6;
const LUA_TUSERDATA = 7;
const LUA_TTHREAD = 8;

class StackUnderflowError implements Error {
  @pragma("vm:entry-point")
  const StackUnderflowError();
  String toString() => "Stack Underflow";

  StackTrace get stackTrace => null;
}