import 'package:luart/luart.dart';
import 'package:luart/src/compiler/ast/lua_exp.dart';
import 'package:luart/src/compiler/lexer/lexer.dart';
import 'package:luart/src/compiler/lexer/token.dart';
import 'package:luart/src/compiler/parser/optimizer.dart';
import 'package:luart/src/compiler/parser/parse_block.dart';
import 'package:luart/src/compiler/parser/parse_prefix_exp.dart';

// explist ::= exp {‘,’ exp}
List<LuaExp> parseExpList(LuaLexer lexer) {
  final exps = <LuaExp>[];
  exps.add(parseExp(lexer));
  while (lexer.lookAhead() == LuaTokens.sepComma) {
    lexer.nextToken();
    exps.add(parseExp(lexer));
  }
  return exps;
}

/*
exp ::=  nil | false | true | Numeral | LiteralString | ‘...’ | functiondef |
	 prefixexp | tableconstructor | exp binop exp | unop exp
*/
/*
exp   ::= exp12
exp12 ::= exp11 {or exp11}
exp11 ::= exp10 {and exp10}
exp10 ::= exp9 {(‘<’ | ‘>’ | ‘<=’ | ‘>=’ | ‘~=’ | ‘==’) exp9}
exp9  ::= exp8 {‘|’ exp8}
exp8  ::= exp7 {‘~’ exp7}
exp7  ::= exp6 {‘&’ exp6}
exp6  ::= exp5 {(‘<<’ | ‘>>’) exp5}
exp5  ::= exp4 {‘..’ exp4}
exp4  ::= exp3 {(‘+’ | ‘-’) exp3}
exp3  ::= exp2 {(‘*’ | ‘/’ | ‘//’ | ‘%’) exp2}
exp2  ::= {(‘not’ | ‘#’ | ‘-’ | ‘~’)} exp1
exp1  ::= exp0 {‘^’ exp2}
exp0  ::= nil | false | true | Numeral | LiteralString
		| ‘...’ | functiondef | prefixexp | tableconstructor
*/
LuaExp parseExp(LuaLexer lexer) {
  return parseExp12(lexer);
}

// x or y
LuaExp parseExp12(LuaLexer lexer) {
  var exp = parseExp11(lexer);
  while (lexer.lookAhead() == LuaTokens.opOr) {
    final token = lexer.nextToken();
    final lor = LuaBinopExp(
      line: token.line,
      op: token.kind,
      exp1: exp,
      exp2: parseExp11(lexer),
    );
    exp = optimizeLogicalOr(lor);
  }
  return exp;
}

// x and y
LuaExp parseExp11(LuaLexer lexer) {
  var exp = parseExp10(lexer);
  while (lexer.lookAhead() == LuaTokens.opAnd) {
    final token = lexer.nextToken();
    final land = LuaBinopExp(
      line: token.line,
      op: token.kind,
      exp1: exp,
      exp2: parseExp10(lexer),
    );
    exp = optimizeLogicalAnd(land);
  }
  return exp;
}

// compare
LuaExp parseExp10(LuaLexer lexer) {
  var exp = parseExp9(lexer);
  while (true) {
    switch (lexer.lookAhead()) {
      case LuaTokens.opLt:
      case LuaTokens.opGt:
      case LuaTokens.opNe:
      case LuaTokens.opLe:
      case LuaTokens.opGe:
      case LuaTokens.opEq:
        final token = lexer.nextToken();
        exp = LuaBinopExp(
          line: token.line,
          op: token.kind,
          exp1: exp,
          exp2: parseExp9(lexer),
        );
        break;
      default:
        return exp;
    }
  }
}

// x | y
LuaExp parseExp9(LuaLexer lexer) {
  var exp = parseExp8(lexer);
  while (lexer.lookAhead() == LuaTokens.opBor) {
    final token = lexer.nextToken();
    final bor = LuaBinopExp(
      line: token.line,
      op: token.kind,
      exp1: exp,
      exp2: parseExp8(lexer),
    );
    exp = optimizeBitwiseBinaryOp(bor);
  }
  return exp;
}

// x ~ y
LuaExp parseExp8(LuaLexer lexer) {
  var exp = parseExp7(lexer);
  while (lexer.lookAhead() == LuaTokens.opBxor) {
    final token = lexer.nextToken();
    final bxor = LuaBinopExp(
      line: token.line,
      op: token.kind,
      exp1: exp,
      exp2: parseExp7(lexer),
    );
    exp = optimizeBitwiseBinaryOp(bxor);
  }
  return exp;
}

// x & y
LuaExp parseExp7(LuaLexer lexer) {
  var exp = parseExp6(lexer);
  while (lexer.lookAhead() == LuaTokens.opBand) {
    final token = lexer.nextToken();
    final band = LuaBinopExp(
      line: token.line,
      op: token.kind,
      exp1: exp,
      exp2: parseExp6(lexer),
    );
    exp = optimizeBitwiseBinaryOp(band);
  }
  return exp;
}

// shift
LuaExp parseExp6(LuaLexer lexer) {
  var exp = parseExp5(lexer);
  while (true) {
    switch (lexer.lookAhead()) {
      case LuaTokens.opShl:
      case LuaTokens.opShr:
        final token = lexer.nextToken();
        final shx = LuaBinopExp(
          line: token.line,
          op: token.kind,
          exp1: exp,
          exp2: parseExp5(lexer),
        );
        exp = optimizeBitwiseBinaryOp(shx);
        break;
      default:
        return exp;
    }
  }
}

// a .. b
LuaExp parseExp5(LuaLexer lexer) {
  var exp = parseExp4(lexer);
  if (lexer.lookAhead() != LuaTokens.opConcat) {
    return exp;
  }

  var line = 0;
  final exps = <LuaExp>[exp];
  while (lexer.lookAhead() == LuaTokens.opConcat) {
    line = lexer.nextToken().line;
    exps.add(parseExp4(lexer));
  }
  return LuaConcatExp(line: line, exps: exps);
}

// x +/- y
LuaExp parseExp4(LuaLexer lexer) {
  var exp = parseExp3(lexer);
  while (true) {
    switch (lexer.lookAhead()) {
      case LuaTokens.opAdd:
      case LuaTokens.opSub:
        final token = lexer.nextToken();
        final arith = LuaBinopExp(
          line: token.line,
          op: token.kind,
          exp1: exp,
          exp2: parseExp3(lexer),
        );
        exp = optimizeArithBinaryOp(arith);
        break;
      default:
        return exp;
    }
  }
}

// *, %, /, //
LuaExp parseExp3(LuaLexer lexer) {
  var exp = parseExp2(lexer);
  while (true) {
    switch (lexer.lookAhead()) {
      case LuaTokens.opMul:
      case LuaTokens.opMod:
      case LuaTokens.opDiv:
      case LuaTokens.opIdiv:
        final token = lexer.nextToken();
        final arith = LuaBinopExp(
          line: token.line,
          op: token.kind,
          exp1: exp,
          exp2: parseExp2(lexer),
        );
        exp = optimizeArithBinaryOp(arith);
        break;
      default:
        return exp;
    }
  }
}

// unary
LuaExp parseExp2(LuaLexer lexer) {
  switch (lexer.lookAhead()) {
    case LuaTokens.opUnm:
    case LuaTokens.opBnot:
    case LuaTokens.opLen:
    case LuaTokens.opNot:
      final token = lexer.nextToken();
      final exp = LuaUnopExp(
        line: token.line,
        op: token.kind,
        exp: parseExp2(lexer),
      );
      return optimizeUnaryOp(exp);
  }
  return parseExp1(lexer);
}

// x ^ y
LuaExp parseExp1(LuaLexer lexer) {
  // pow is right associative
  var exp = parseExp0(lexer);
  if (lexer.lookAhead() == LuaTokens.opPow) {
    final token = lexer.nextToken();
    exp = LuaBinopExp(
      line: token.line,
      op: token.kind,
      exp1: exp,
      exp2: parseExp2(lexer),
    );
  }
  return optimizePow(exp);
}

LuaExp parseExp0(LuaLexer lexer) {
  switch (lexer.lookAhead()) {
    case LuaTokens.vararg: // ...
      final token = lexer.nextToken();
      return LuaVarargExp(line: token.line);
    case LuaTokens.kwNil: // nil
      final token = lexer.nextToken();
      return LuaNilExp(line: token.line);
    case LuaTokens.kwTrue: // true
      final token = lexer.nextToken();
      return LuaTrueExp(line: token.line);
    case LuaTokens.kwFalse: // false
      final token = lexer.nextToken();
      return LuaFalseExp(line: token.line);
    case LuaTokens.string: // LiteralString
      final token = lexer.nextToken();
      return LuaStringExp(line: token.line, value: token.value);
    case LuaTokens.number: // Numeral
      return parseNumberExp(lexer);
    case LuaTokens.sepLcurly: // tableconstructor
      return parseTableConstructorExp(lexer);
    case LuaTokens.kwFunction: // functiondef
      lexer.nextToken();
      return parseFuncDefExp(lexer);
    default: // prefixexp
      return parsePrefixExp(lexer);
  }
}

LuaExp parseNumberExp(LuaLexer lexer) {
  final token = lexer.nextToken();

  final intValue = int.tryParse(token.value);
  if (intValue != null) {
    return LuaIntegerExp(line: token.line, value: intValue);
  }

  final doubleValue = double.tryParse(token.value);
  if (doubleValue != null) {
    return LuaFloatExp(line: token.line, value: doubleValue);
  }

  throw LuaCompilerError('not a number: $token');
}

// functiondef ::= function funcbody
// funcbody ::= ‘(’ [parlist] ‘)’ block end
LuaFuncDefExp parseFuncDefExp(LuaLexer lexer) {
  final line = lexer.line; // function
  lexer.nextTokenOfKind(LuaTokens.sepLparen); // (
  final parList = _parseParList(lexer); // [parlist]
  lexer.nextTokenOfKind(LuaTokens.sepRparen); // )
  final block = parseBlock(lexer); // block
  final lastLine = lexer.nextTokenOfKind(LuaTokens.kwEnd).line; // end
  return LuaFuncDefExp(
    line: line,
    lastLine: lastLine,
    parList: parList.names,
    isVararg: parList.isVararg,
    block: block,
  );
}

class _ParList {
  _ParList(this.names, this.isVararg);
  final List<String> names;
  final bool isVararg;
}

// [parlist]
// parlist ::= namelist [‘,’ ‘...’] | ‘...’
_ParList _parseParList(LuaLexer lexer) {
  switch (lexer.lookAhead()) {
    case LuaTokens.sepRparen:
      return _ParList([], false);
    case LuaTokens.vararg:
      lexer.nextToken();
      return _ParList([], true);
  }

  final name = lexer.nextIdentifier().value;
  final names = <String>[name];
  while (lexer.lookAhead() == LuaTokens.sepComma) {
    lexer.nextToken();
    if (lexer.lookAhead() == LuaTokens.identifier) {
      final name = lexer.nextIdentifier().value;
      names.add(name);
    } else {
      lexer.nextTokenOfKind(LuaTokens.vararg);
      return _ParList(names, true);
    }
  }
  return _ParList(names, false);
}

// tableconstructor ::= ‘{’ [fieldlist] ‘}’
LuaTableConstructorExp parseTableConstructorExp(LuaLexer lexer) {
  final line = lexer.line;
  lexer.nextTokenOfKind(LuaTokens.sepLcurly); // {
  final fieldList = _parseFieldList(lexer); // [fieldlist]
  lexer.nextTokenOfKind(LuaTokens.sepRcurly); // }
  final lastLine = lexer.line;
  return LuaTableConstructorExp(
    line: line,
    lastLine: lastLine,
    keyExps: fieldList.keyExps,
    valExps: fieldList.valExps,
  );
}

class _FieldList {
  _FieldList(this.keyExps, this.valExps);
  final List<LuaExp?> keyExps;
  final List<LuaExp> valExps;
}

// fieldlist ::= field {fieldsep field} [fieldsep]
_FieldList _parseFieldList(LuaLexer lexer) {
  final ks = <LuaExp?>[];
  final vs = <LuaExp>[];

  if (lexer.lookAhead() != LuaTokens.sepRcurly) {
    final field = _parseField(lexer);
    ks.add(field.key);
    vs.add(field.val);

    while (_isFieldSep(lexer.lookAhead())) {
      lexer.nextToken();
      if (lexer.lookAhead() != LuaTokens.sepRcurly) {
        final field = _parseField(lexer);
        ks.add(field.key);
        vs.add(field.val);
      } else {
        break;
      }
    }
  }
  return _FieldList(ks, vs);
}

// fieldsep ::= ‘,’ | ‘;’
bool _isFieldSep(int tokenKind) {
  return tokenKind == LuaTokens.sepComma || tokenKind == LuaTokens.sepSemi;
}

class _Field {
  _Field(this.key, this.val);
  LuaExp? key;
  LuaExp val;
}

// field ::= ‘[’ exp ‘]’ ‘=’ exp | Name ‘=’ exp | exp
_Field _parseField(LuaLexer lexer) {
  if (lexer.lookAhead() == LuaTokens.sepLbrack) {
    lexer.nextToken(); // [;
    final k = parseExp(lexer); // exp
    lexer.nextTokenOfKind(LuaTokens.sepRbrack); // ]
    lexer.nextTokenOfKind(LuaTokens.opAssign); // =
    final v = parseExp(lexer); // exp
    return _Field(k, v);
  }

  final exp = parseExp(lexer);
  if (exp is LuaNameExp) {
    if (lexer.lookAhead() == LuaTokens.opAssign) {
      // Name ‘=’ exp => ‘[’ LiteralString ‘]’ = exp
      lexer.nextToken();
      final k = LuaStringExp(line: exp.line, value: exp.name);
      final v = parseExp(lexer);
      return _Field(k, v);
    }
  }

  return _Field(null, exp);
}
