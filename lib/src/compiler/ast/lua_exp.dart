/*
exp ::=  nil | false | true | Numeral | LiteralString | ‘...’ | functiondef |
	 prefixexp | tableconstructor | exp binop exp | unop exp

prefixexp ::= var | functioncall | ‘(’ exp ‘)’

var ::=  Name | prefixexp ‘[’ exp ‘]’ | prefixexp ‘.’ Name

functioncall ::=  prefixexp args | prefixexp ‘:’ Name args
*/

import 'package:luart/src/compiler/ast/lua_block.dart';

class LuaExp {}

// nil
class LuaNilExp extends LuaExp {
  LuaNilExp({required this.line});
  final int line;
}

// true
class LuaTrueExp extends LuaExp {
  LuaTrueExp({required this.line});
  final int line;
}

// false
class LuaFalseExp extends LuaExp {
  LuaFalseExp({required this.line});
  final int line;
}

// ...
class LuaVarargExp extends LuaExp {
  LuaVarargExp({required this.line});
  final int line;
}

// Numeral
class LuaIntegerExp extends LuaExp {
  LuaIntegerExp({
    required this.line,
    required this.value,
  });
  final int line;
  final int value;
}

class LuaFloatExp extends LuaExp {
  LuaFloatExp({
    required this.line,
    required this.value,
  });
  final int line;
  final double value;
}

// LiteralString
class LuaStringExp extends LuaExp {
  LuaStringExp({
    required this.line,
    required this.value,
  });
  final int line;
  final String value;
}

// unop exp
class LuaUnopExp extends LuaExp {
  LuaUnopExp({
    required this.line,
    required this.op,
    required this.exp,
  });
  final int line; // line of operator
  final int op;
  final LuaExp exp;
}

// exp1 op exp2
class LuaBinopExp extends LuaExp {
  LuaBinopExp({
    required this.line,
    required this.op,
    required this.exp1,
    required this.exp2,
  });
  final int line; // line of operator
  final int op;
  final LuaExp exp1;
  final LuaExp exp2;
}

class LuaConcatExp extends LuaExp {
  LuaConcatExp({
    required this.line,
    required this.exps,
  });
  final int line; // line of last ..
  final List<LuaExp> exps;
}

// tableconstructor ::= ‘{’ [fieldlist] ‘}’
// fieldlist ::= field {fieldsep field} [fieldsep]
// field ::= ‘[’ exp ‘]’ ‘=’ exp | Name ‘=’ exp | exp
// fieldsep ::= ‘,’ | ‘;’
class LuaTableConstructorExp extends LuaExp {
  LuaTableConstructorExp({
    required this.line,
    required this.lastLine,
    required this.keyExps,
    required this.valExps,
  });
  final int line; // line of `{` ?
  final int lastLine; // line of `}`
  final List<LuaExp?> keyExps;
  final List<LuaExp> valExps;
}

// functiondef ::= function funcbody
// funcbody ::= ‘(’ [parlist] ‘)’ block end
// parlist ::= namelist [‘,’ ‘...’] | ‘...’
// namelist ::= Name {‘,’ Name}
class LuaFuncDefExp extends LuaExp {
  LuaFuncDefExp({
    required this.line,
    required this.lastLine,
    required this.parList,
    required this.isVararg,
    required this.block,
  });
  final int line;
  final int lastLine; // line of `end`
  final List<String> parList;
  final bool isVararg;
  final LuaBlock block;
}

/*
prefixexp ::= Name |
              ‘(’ exp ‘)’ |
              prefixexp ‘[’ exp ‘]’ |
              prefixexp ‘.’ Name |
              prefixexp ‘:’ Name args |
              prefixexp args
*/

class LuaNameExp extends LuaExp {
  LuaNameExp({
    required this.line,
    required this.name,
  });
  final int line;
  final String name;
}

class LuaParensExp extends LuaExp {
  LuaParensExp(this.exp);
  final LuaExp exp;
}

class LuaTableAccessExp extends LuaExp {
  LuaTableAccessExp({
    required this.lastLine,
    required this.prefixExp,
    required this.keyExp,
  });
  final int lastLine; // line of `]` ?
  final LuaExp prefixExp;
  final LuaExp keyExp;
}

class LuaFuncCallExp extends LuaExp {
  LuaFuncCallExp({
    required this.line,
    required this.lastLine,
    required this.prefixExp,
    required this.nameExp,
    required this.args,
  });
  final int line; // line of `(` ?
  final int lastLine; // line of ')'
  final LuaExp prefixExp;
  final LuaStringExp? nameExp;
  final List<LuaExp> args;
}
