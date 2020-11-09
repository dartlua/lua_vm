//for check chunk
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


const LUA_OPADD = 0; // +
const LUA_OPSUB = 1;        // -
const LUA_OPMUL = 2;        // *
const LUA_OPMOD = 3;        // %
const LUA_OPPOW = 4;        // ^
const LUA_OPDIV = 5;        // /
const LUA_OPIDIV = 6;       // //
const LUA_OPBAND = 7;       // &
const LUA_OPBOR = 8;        // |
const LUA_OPBXOR = 9;       // ~
const LUA_OPSHL = 10;        // <<
const LUA_OPSHR = 11;        // >>
const LUA_OPUNM = 12;        // -
const LUA_OPBNOT = 13;       // ~


/* comparison functions */

const LUA_OPEQ = 0; // ==
const LUA_OPLT = 1;       // <
const LUA_OPLE = 2;       // <=
