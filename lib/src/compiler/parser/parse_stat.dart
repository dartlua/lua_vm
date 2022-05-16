import 'package:luart/luart.dart';
import 'package:luart/src/compiler/ast/lua_block.dart';
import 'package:luart/src/compiler/ast/lua_exp.dart';
import 'package:luart/src/compiler/ast/lua_stat.dart';
import 'package:luart/src/compiler/lexer/lexer.dart';
import 'package:luart/src/compiler/lexer/token.dart';
import 'package:luart/src/compiler/parser/parse_block.dart';
import 'package:luart/src/compiler/parser/parse_exp.dart';
import 'package:luart/src/compiler/parser/parse_prefix_exp.dart';

final _statEmpty = LuaEmptyStat();

/*
stat ::=  ‘;’
	| break
	| ‘::’ Name ‘::’
	| goto Name
	| do block end
	| while exp do block end
	| repeat block until exp
	| if exp then block {elseif exp then block} [else block] end
	| for Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end
	| for namelist in explist do block end
	| function funcname funcbody
	| local function Name funcbody
	| local namelist [‘=’ explist]
	| varlist ‘=’ explist
	| functioncall
*/
LuaStat parseStat(LuaLexer lexer) {
  switch (lexer.lookAhead()) {
    case LuaTokens.sepSemi:
      return parseEmptyStat(lexer);
    case LuaTokens.kwBreak:
      return parseBreakStat(lexer);
    case LuaTokens.sepLabel:
      return parseLabelStat(lexer);
    case LuaTokens.kwGoto:
      return parseGotoStat(lexer);
    case LuaTokens.kwDo:
      return parseDoStat(lexer);
    case LuaTokens.kwWhile:
      return parseWhileStat(lexer);
    case LuaTokens.kwRepeat:
      return parseRepeatStat(lexer);
    case LuaTokens.kwIf:
      return parseIfStat(lexer);
    case LuaTokens.kwFor:
      return parseForStat(lexer);
    case LuaTokens.kwFunction:
      return parseFuncDefStat(lexer);
    case LuaTokens.kwLocal:
      return parseLocalAssignOrFuncDefStat(lexer);
    default:
      return parseAssignOrFuncCallStat(lexer);
  }
}

// ;
LuaEmptyStat parseEmptyStat(LuaLexer lexer) {
  lexer.nextTokenOfKind(LuaTokens.sepSemi);
  return _statEmpty;
}

// break
LuaBreakStat parseBreakStat(LuaLexer lexer) {
  lexer.nextTokenOfKind(LuaTokens.kwBreak);
  return LuaBreakStat(line: lexer.line);
}

// ‘::’ Name ‘::’
LuaLabelStat parseLabelStat(LuaLexer lexer) {
  lexer.nextTokenOfKind(LuaTokens.sepLabel); // ::
  final name = lexer.nextIdentifier().value; // name
  lexer.nextTokenOfKind(LuaTokens.sepLabel); // ::
  return LuaLabelStat(name: name);
}

// goto Name
LuaGotoStat parseGotoStat(LuaLexer lexer) {
  lexer.nextTokenOfKind(LuaTokens.kwGoto); // goto
  final name = lexer.nextIdentifier().value; // name
  return LuaGotoStat(name: name);
}

// do block end
LuaDoStat parseDoStat(LuaLexer lexer) {
  lexer.nextTokenOfKind(LuaTokens.kwDo); // do
  final block = parseBlock(lexer); // block
  lexer.nextTokenOfKind(LuaTokens.kwEnd); // end
  return LuaDoStat(block: block);
}

// while exp do block end
LuaWhileStat parseWhileStat(LuaLexer lexer) {
  lexer.nextTokenOfKind(LuaTokens.kwWhile); // while
  final exp = parseExp(lexer); // exp
  lexer.nextTokenOfKind(LuaTokens.kwDo); // do
  final block = parseBlock(lexer); // block
  lexer.nextTokenOfKind(LuaTokens.kwEnd); // end
  return LuaWhileStat(exp: exp, block: block);
}

// repeat block until exp
LuaRepeatStat parseRepeatStat(LuaLexer lexer) {
  lexer.nextTokenOfKind(LuaTokens.kwRepeat); // repeat
  final block = parseBlock(lexer); // block
  lexer.nextTokenOfKind(LuaTokens.kwUntil); // until
  final exp = parseExp(lexer); // exp
  return LuaRepeatStat(block: block, exp: exp);
}

// if exp then block {elseif exp then block} [else block] end
LuaIfStat parseIfStat(LuaLexer lexer) {
  final exps = <LuaExp>[];
  final blocks = <LuaBlock>[];

  lexer.nextTokenOfKind(LuaTokens.kwIf); // if
  exps.add(parseExp(lexer)); // exp
  lexer.nextTokenOfKind(LuaTokens.kwThen); // then
  blocks.add(parseBlock(lexer)); // block

  while (lexer.lookAhead() == LuaTokens.kwElseif) {
    lexer.nextToken(); // elseif
    exps.add(parseExp(lexer)); // exp
    lexer.nextTokenOfKind(LuaTokens.kwThen); // then
    blocks.add(parseBlock(lexer)); // block
  }

  // else block => elseif true then block
  if (lexer.lookAhead() == LuaTokens.kwElse) {
    lexer.nextToken(); // else
    exps.add(LuaTrueExp(line: lexer.line)); //
    blocks.add(parseBlock(lexer)); // block
  }

  lexer.nextTokenOfKind(LuaTokens.kwEnd); // end
  return LuaIfStat(exps: exps, blocks: blocks);
}

// for Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end
// for namelist in explist do block end
LuaStat parseForStat(LuaLexer lexer) {
  final lineOfFor = lexer.nextTokenOfKind(LuaTokens.kwFor).line;
  final name = lexer.nextIdentifier().value;
  if (lexer.lookAhead() == LuaTokens.opAssign) {
    return _finishForNumStat(lexer, lineOfFor, name);
  } else {
    return _finishForInStat(lexer, name);
  }
}

// for Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end
LuaForNumStat _finishForNumStat(LuaLexer lexer, int lineOfFor, String varName) {
  lexer.nextTokenOfKind(LuaTokens.opAssign); // for name =
  final initExp = parseExp(lexer); // exp
  lexer.nextTokenOfKind(LuaTokens.sepComma); // ,
  final limitExp = parseExp(lexer); // exp

  late LuaExp stepExp;
  if (lexer.lookAhead() == LuaTokens.sepComma) {
    lexer.nextToken(); // ,
    stepExp = parseExp(lexer); // exp
  } else {
    stepExp = LuaIntegerExp(line: lexer.line, value: 1);
  }

  final lineOfDo = lexer.nextTokenOfKind(LuaTokens.kwDo).line; // do
  final block = parseBlock(lexer); // block
  lexer.nextTokenOfKind(LuaTokens.kwEnd); // end

  return LuaForNumStat(
    lineOfFor: lineOfFor,
    lineOfDo: lineOfDo,
    varName: varName,
    initExp: initExp,
    limitExp: limitExp,
    stepExp: stepExp,
    block: block,
  );
}

// for namelist in explist do block end
// namelist ::= Name {‘,’ Name}
// explist ::= exp {‘,’ exp}
LuaForInStat _finishForInStat(LuaLexer lexer, String name0) {
  final nameList = _finishNameList(lexer, name0); // for namelist
  lexer.nextTokenOfKind(LuaTokens.kwIn); // in
  final expList = parseExpList(lexer); // explist
  final lineOfDo = lexer.nextTokenOfKind(LuaTokens.kwDo).line; // do
  final block = parseBlock(lexer); // block
  lexer.nextTokenOfKind(LuaTokens.kwEnd); // end
  return LuaForInStat(
    lineOfDo: lineOfDo,
    nameList: nameList,
    expList: expList,
    block: block,
  );
}

// namelist ::= Name {‘,’ Name}
List<String> _finishNameList(LuaLexer lexer, String name0) {
  final names = <String>[name0];
  while (lexer.lookAhead() == LuaTokens.sepComma) {
    lexer.nextToken(); // ,
    final name = lexer.nextIdentifier().value; // Name
    names.add(name);
  }
  return names;
}

// local function Name funcbody
// local namelist [‘=’ explist]
LuaStat parseLocalAssignOrFuncDefStat(LuaLexer lexer) {
  lexer.nextTokenOfKind(LuaTokens.kwLocal);
  if (lexer.lookAhead() == LuaTokens.kwFunction) {
    return _finishLocalFuncDefStat(lexer);
  } else {
    return _finishLocalVarDeclStat(lexer);
  }
}

/*
http://www.lua.org/manual/5.3/manual.html#3.4.11

function f() end          =>  f = function() end
function t.a.b.c.f() end  =>  t.a.b.c.f = function() end
function t.a.b.c:f() end  =>  t.a.b.c.f = function(self) end
local function f() end    =>  local f; f = function() end

The statement `local function f () body end`
translates to `local f; f = function () body end`
not to `local f = function () body end`
(This only makes a difference when the body of the function
 contains references to f.)
*/
// local function Name funcbody
LuaLocalFuncDefStat _finishLocalFuncDefStat(LuaLexer lexer) {
  lexer.nextTokenOfKind(LuaTokens.kwFunction); // local function
  final name = lexer.nextIdentifier().value; // name
  final fdExp = parseFuncDefExp(lexer); // funcbody
  return LuaLocalFuncDefStat(name: name, exp: fdExp);
}

// local namelist [‘=’ explist]
LuaLocalVarDeclStat _finishLocalVarDeclStat(LuaLexer lexer) {
  final name0 = lexer.nextIdentifier().value; // local Name
  final nameList = _finishNameList(lexer, name0); // { , Name }
  List<LuaExp>? expList;
  if (lexer.lookAhead() == LuaTokens.opAssign) {
    lexer.nextToken(); // ==
    expList = parseExpList(lexer); // explist
  }
  final lastLine = lexer.line;
  return LuaLocalVarDeclStat(
    lastLine: lastLine,
    nameList: nameList,
    expList: expList,
  );
}

// varlist ‘=’ explist
// functioncall
LuaStat parseAssignOrFuncCallStat(LuaLexer lexer) {
  final prefixExp = parsePrefixExp(lexer);
  if (prefixExp is LuaFuncCallExp) {
    return LuaFuncCallStat(exp: prefixExp);
  } else {
    return parseAssignStat(lexer, prefixExp);
  }
}

// varlist ‘=’ explist |
LuaAssignStat parseAssignStat(LuaLexer lexer, LuaExp var0) {
  final varList = _finishVarList(lexer, var0); // varlist
  lexer.nextTokenOfKind(LuaTokens.opAssign); // =
  final expList = parseExpList(lexer); // explist
  final lastLine = lexer.line;
  return LuaAssignStat(
    lastLine: lastLine,
    varList: varList,
    expList: expList,
  );
}

// varlist ::= var {‘,’ var}
List<LuaExp> _finishVarList(LuaLexer lexer, LuaExp var0) {
  final vars = <LuaExp>[_checkVar(lexer, var0)]; // var
  while (lexer.lookAhead() == LuaTokens.sepComma) {
    //)
    lexer.nextToken(); // ,
    final exp = parsePrefixExp(lexer); // var
    vars.add(_checkVar(lexer, exp)); //
  } // }
  return vars;
}

// var ::=  Name | prefixexp ‘[’ exp ‘]’ | prefixexp ‘.’ Name
LuaExp _checkVar(LuaLexer lexer, LuaExp exp) {
  switch (exp.runtimeType) {
    case LuaNameExp:
    case LuaTableAccessExp:
      return exp;
  }
  lexer.nextTokenOfKind(-1); // trigger error
  throw LuaCompilerError('unreachable!');
}

// function funcname funcbody
// funcname ::= Name {‘.’ Name} [‘:’ Name]
// funcbody ::= ‘(’ [parlist] ‘)’ block end
// parlist ::= namelist [‘,’ ‘...’] | ‘...’
// namelist ::= Name {‘,’ Name}
LuaAssignStat parseFuncDefStat(LuaLexer lexer) {
  lexer.nextTokenOfKind(LuaTokens.kwFunction); // function
  final funcName = _parseFuncName(lexer); // funcname

  final fdExp = parseFuncDefExp(lexer); // funcbody
  if (funcName.hasColon) {
    fdExp.parList.insert(0, 'self'); // insert self
  }

  return LuaAssignStat(
    lastLine: fdExp.line,
    varList: <LuaExp>[funcName.exp],
    expList: <LuaExp>[fdExp],
  );
}

class _FuncName {
  _FuncName(this.exp, this.hasColon);
  final LuaExp exp;
  final bool hasColon;
}

// funcname ::= Name {‘.’ Name} [‘:’ Name]
_FuncName _parseFuncName(LuaLexer lexer) {
  late LuaExp exp;
  var hasColon = false;

  final ident = lexer.nextIdentifier();
  exp = LuaNameExp(line: ident.line, name: ident.value);

  while (lexer.lookAhead() == LuaTokens.sepDot) {
    lexer.nextToken();
    final ident = lexer.nextIdentifier();
    final idx = LuaStringExp(line: ident.line, value: ident.value);
    exp = LuaTableAccessExp(lastLine: ident.line, prefixExp: exp, keyExp: idx);
  }

  if (lexer.lookAhead() == LuaTokens.sepColon) {
    lexer.nextToken();
    final ident = lexer.nextIdentifier();
    final idx = LuaStringExp(line: ident.line, value: ident.value);
    exp = LuaTableAccessExp(lastLine: ident.line, prefixExp: exp, keyExp: idx);
    hasColon = true;
  }

  return _FuncName(exp, hasColon);
}
