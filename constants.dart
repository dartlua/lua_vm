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
const OP_MOVE = 0;
const OP_LOADK = 1;
const OP_LOADKX = 2;
const OP_LOADBOOL = 3;
const OP_LOADNIL = 4;
const OP_GETUPVAL = 5;
const OP_GETTABUP = 6;
const OP_GETTABLE = 7;
const OP_SETTABUP = 8;
const OP_SETUPVAL = 9;
const OP_SETTABLE = 10;
const OP_NEWTABLE = 11;
const OP_SELF = 12;
const OP_ADD = 13;
const OP_SUB = 14;
const OP_MUL = 15;
const OP_MOD = 16;
const OP_POW = 17;
const OP_DIV = 18;
const OP_IDIV = 19;
const OP_BAND = 20;
const OP_BOR = 21;
const OP_BXOR = 22;
const OP_SHL = 23;
const OP_SHR = 24;
const OP_UNM = 25;
const OP_BNOT = 26;
const OP_NOT = 27;
const OP_LEN = 28;
const OP_CONCAT = 29;
const OP_JMP = 30;
const OP_EQ = 31;
const OP_LT = 32;
const OP_LE = 33;
const OP_TEST = 34;
const OP_TESTSET = 35;
const OP_CALL = 36;
const OP_TAILCALL = 37;
const OP_RETURN = 38;
const OP_FORLOOP = 39;
const OP_FORPREP = 40;
const OP_TFORCALL = 41;
const OP_TFORLOOP = 42;
const OP_SETLIST = 43;
const OP_CLOSURE = 44;
const OP_VARARG = 45;
const OP_EXTRAARG = 46;

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


const LUA_OPADD = 0;        // +
const LUA_OPSUB = 1;        // -
const LUA_OPMUL = 2;        // *
const LUA_OPMOD = 3;        // %
const LUA_OPPOW = 4;        // ^
const LUA_OPDIV = 5;        // /
const LUA_OPIDIV = 6;       // //
const LUA_OPBAND = 7;       // &
const LUA_OPBOR = 8;        // |
const LUA_OPBXOR = 9;       // ~
const LUA_OPSHL = 10;       // <<
const LUA_OPSHR = 11;       // >>
const LUA_OPUNM = 12;       // -
const LUA_OPBNOT = 13;      // ~


/* comparison functions */
const LUA_OPEQ = 0; // ==
const LUA_OPLT = 1; // <
const LUA_OPLE = 2; // <=
