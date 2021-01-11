/*
stat ::=  ‘;’ |
	 varlist ‘=’ explist |
	 functioncall |
	 label |
	 break |
	 goto Name |
	 do block end |
	 while exp do block end |
	 repeat block until exp |
	 if exp then block {elseif exp then block} [else block] end |
	 for Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end |
	 for namelist in explist do block end |
	 function funcname funcbody |
	 local function Name funcbody |
	 local namelist [‘=’ explist]
*/
import 'package:luart/src/compiler/ast/lua_block.dart';
import 'package:luart/src/compiler/ast/lua_exp.dart';

class LuaStat {}

class LuaEmptyStat extends LuaStat {} // ‘;’

class LuaBreakStat extends LuaStat {
  LuaBreakStat({
    required this.line,
  });
  final int line;
} // break

class LuaLabelStat extends LuaStat {
  LuaLabelStat({
    required this.name,
  });
  final String name;
} // ‘::’ Name ‘::’

class LuaGotoStat extends LuaStat {
  LuaGotoStat({
    required this.name,
  });
  final String name;
} // goto Name

class LuaDoStat extends LuaStat {
  LuaDoStat({
    required this.block,
  });
  final LuaBlock block;
} // do block end

class LuaFuncCallStat extends LuaStat {
  LuaFuncCallStat({
    required this.exp,
  });
  final LuaFuncCallExp exp;
} // functioncall

// if exp then block {elseif exp then block} [else block] end
class LuaIfStat extends LuaStat {
  LuaIfStat({
    required this.exps,
    required this.blocks,
  });
  final List<LuaExp> exps;
  final List<LuaBlock> blocks;
}

// while exp do block end
class LuaWhileStat extends LuaStat {
  LuaWhileStat({
    required this.exp,
    required this.block,
  });
  final LuaExp exp;
  final LuaBlock block;
}

// repeat block until exp
class LuaRepeatStat extends LuaStat {
  LuaRepeatStat({
    required this.block,
    required this.exp,
  });
  final LuaBlock block;
  final LuaExp exp;
}

// for Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end
class LuaForNumStat extends LuaStat {
  LuaForNumStat({
    required this.lineOfFor,
    required this.lineOfDo,
    required this.varName,
    required this.initExp,
    required this.limitExp,
    required this.stepExp,
    required this.block,
  });
  final int lineOfFor;
  final int lineOfDo;
  final String varName;
  final LuaExp initExp;
  final LuaExp limitExp;
  final LuaExp stepExp;
  final LuaBlock block;
}

// for namelist in explist do block end
// namelist ::= Name {‘,’ Name}
// explist ::= exp {‘,’ exp}
class LuaForInStat extends LuaStat {
  LuaForInStat({
    required this.lineOfDo,
    required this.nameList,
    required this.expList,
    required this.block,
  });
  final int lineOfDo;
  final List<String> nameList;
  final List<LuaExp> expList;
  final LuaBlock block;
}

// varlist ‘=’ explist
// varlist ::= var {‘,’ var}
// var ::=  Name | prefixexp ‘[’ exp ‘]’ | prefixexp ‘.’ Name
class LuaAssignStat extends LuaStat {
  LuaAssignStat({
    required this.lastLine,
    required this.varList,
    required this.expList,
  });
  final int lastLine;
  final List<LuaExp> varList;
  final List<LuaExp> expList;
}

// local namelist [‘=’ explist]
// namelist ::= Name {‘,’ Name}
// explist ::= exp {‘,’ exp}
class LuaLocalVarDeclStat extends LuaStat {
  LuaLocalVarDeclStat({
    required this.lastLine,
    required this.nameList,
    required this.expList,
  });
  final int lastLine;
  final List<String> nameList;
  final List<LuaExp>? expList;
}

// local function Name funcbody
class LuaLocalFuncDefStat extends LuaStat {
  LuaLocalFuncDefStat({
    required this.name,
    required this.exp,
  });
  final String name;
  final LuaFuncDefExp exp;
}
