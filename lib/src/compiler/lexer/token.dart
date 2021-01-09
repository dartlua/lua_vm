class LuaToken {
  LuaToken({
    required this.line,
    required this.kind,
    required this.value,
  });

  final int line;
  final int kind;
  final String value;
}

class LuaTokens {
  static const eof = 0;
  static const vararg = 1; // ...
  static const sepSemi = 2; // ;
  static const sepComma = 3; // ,
  static const sepDot = 4; // .
  static const sepColon = 5; // :
  static const sepLabel = 6; // ::
  static const sepLparen = 7; // (
  static const sepRparen = 8; // )
  static const sepLbrack = 9; // [
  static const sepRbrack = 10; // ]
  static const sepLcurly = 11; // {
  static const sepRcurly = 12; // }
  static const opAssign = 13; // =
  static const opMinus = 14; // - (sub or unm)
  static const opWave = 15; // ~ (bnot or bxor)
  static const opAdd = 16; // +
  static const opMul = 17; // *
  static const opDiv = 18; // /
  static const opIdiv = 19; // //
  static const opPow = 20; // ^
  static const opMod = 21; // %
  static const opBand = 22; // &
  static const opBor = 23; // |
  static const opShr = 24; // >>
  static const opShl = 25; // <<
  static const opConcat = 26; // ..
  static const opLt = 27; // <
  static const opLe = 28; // <=
  static const opGt = 29; // >
  static const opGe = 30; // >=
  static const opEq = 31; // ==
  static const opNe = 32; // ~=
  static const opLen = 33; // #
  static const opAnd = 34; // and
  static const opOr = 35; // or
  static const opNot = 36; // not
  static const kwBreak = 37; // break
  static const kwDo = 38; // do
  static const kwElse = 39; // else
  static const kwElseif = 40; // elseif
  static const kwEnd = 41; // end
  static const kwFalse = 42; // false
  static const kwFor = 43; // for
  static const kwFunction = 44; // function
  static const kwGoto = 45; // goto
  static const kwIf = 46; // if
  static const kwIn = 47; // in
  static const kwLocal = 48; // local
  static const kwNil = 49; // nil
  static const kwRepeat = 50; // repeat
  static const kwReturn = 51; // return
  static const kwThen = 52; // then
  static const kwTrue = 53; // true
  static const kwUntil = 54; // until
  static const kwWhile = 55; // while
  static const identifier = 56; // identifier
  static const number = 57; // number literal
  static const string = 58; // string literal
  static const opUnm = LuaTokens.opMinus; // unary minus
  static const opSub = LuaTokens.opMinus;
  static const opBnot = LuaTokens.opWave;
  static const opBxor = LuaTokens.opWave;
}

const keywords = <String, int>{
  'break': LuaTokens.kwBreak,
  'and': LuaTokens.opAnd,
  'do': LuaTokens.kwDo,
  'else': LuaTokens.kwElse,
  'elseif': LuaTokens.kwElseif,
  'end': LuaTokens.kwEnd,
  'false': LuaTokens.kwFalse,
  'for': LuaTokens.kwFor,
  'function': LuaTokens.kwFunction,
  'goto': LuaTokens.kwGoto,
  'if': LuaTokens.kwIf,
  'in': LuaTokens.kwIn,
  'local': LuaTokens.kwLocal,
  'nil': LuaTokens.kwNil,
  'not': LuaTokens.opNot,
  'or': LuaTokens.opOr,
  'repeat': LuaTokens.kwRepeat,
  'return': LuaTokens.kwReturn,
  'then': LuaTokens.kwThen,
  'true': LuaTokens.kwTrue,
  'until': LuaTokens.kwUntil,
  'while': LuaTokens.kwWhile,
};
