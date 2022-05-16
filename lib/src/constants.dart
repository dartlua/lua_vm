//for check chunk
const luaSignature = '1b4c7561'; //\x1bLua
const luacVersion = '53';
const luacFormat = '00';
const luacData = '19930d0a1a0a'; //\x19\x93\r\n\x1a\n
const cIntSize = 4;
const cSizetSize = 8;
const instructionSize = 4;
const luaIntegerSize = 8;
const luaNumberSize = 8;
const luacInt = 22136; //0x7856
const luacNum = 370.5;
const tagNil = '00';
const tagBoolean = '01';
const tagNumber = '03';
const tagInteger = '13';
const tagShortStr = '04';
const tagLongStr = '14';

//operation code
const opMove = 0;
const opLoadK = 1;
const opLoadKX = 2;
const opLoadBool = 3;
const opLoadNil = 4;
const opGetUpVal = 5;
const opGetTab = 6;
const opGetTable = 7;
const opSetTabUp = 8;
const opSetUpVal = 9;
const opSetTable = 10;
const opNewTable = 11;
const opSelf = 12;
const opAdd = 13;
const opSub = 14;
const opMul = 15;
const opMod = 16;
const opPow = 17;
const opDiv = 18;
const opIDiv = 19;
const opBAnd = 20;
const opBOr = 21;
const opBXOr = 22;
const opShl = 23;
const opShr = 24;
const opUnm = 25;
const opBNot = 26;
const opNot = 27;
const opLen = 28;
const opConcat = 29;
const opJmp = 30;
const opEq = 31;
const opLt = 32;
const opLe = 33;
const opTest = 34;
const opTestSet = 35;
const opCall = 36;
const opTailCall = 37;
const opReturn = 38;
const opForLoop = 39;
const opForPrep = 40;
const opTForCall = 41;
const opTForLoop = 42;
const opSetList = 43;
const opClosure = 44;
const opVarArg = 45;
const opExtraArg = 46;

// OpMode
const iABC = 0;
const iABx = 1;
const iAsBx = 2;
const iAx = 3;

// OpArg
const opArgN = 0;
const opArgU = 1;
const opArgR = 2;
const opArgK = 3;

//MAXARG
const int maxArgBx = (1 << 18) - 1; // 262143;
const int maxArgSBx = maxArgBx >> 1; // 131071

class StackUnderflowError implements Error {
  @pragma('vm:entry-point')
  const StackUnderflowError();

  @override
  String toString() => 'Stack Underflow';

  @override
  StackTrace? get stackTrace => null;
}

/* comparison functions */
const luaOpEq = 0; // ==
const luaOpLt = 1; // <
const luaOpLe = 2; // <=

const lFieldsPerFlush = 50;

const luaMinStack = 20;
const luaIMaxStack = 1000000;
const luaRegistryIndex = -luaIMaxStack - 1000;
const luaRIdxGlobals = 2;
const luaMultRet = -1;
const tabR = 1; /* read */
const tabW = 2; /* write */
const tabL = 4; /* length */
const tabRW = tabR | tabW; /* read/write */
const luaMaxInteger = 9223372036854775807;
const maxLen = 1000000;
const maxUnicode = 1114111;
const utf8Pattern = r'[\x00-\x7F\xC2-\xF4][\x80-\xB F]*';
/* key, in the registry, for table of loaded modules */
const luaLoadedTable = '_LOADED';
/* key, in the registry, for table of preloaded loaders */
const luaPreloadTable = '_PRELOAD';
const luaDirSep = '/';
const luaPathSep = ';';
const luaPathMark = '?';
const luaExecDir = '!';
const luaIGMark = '-';
