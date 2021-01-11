import 'package:luart/src/compiler/ast/lua_exp.dart';
import 'package:luart/src/compiler/lexer/lexer.dart';
import 'package:luart/src/compiler/lexer/token.dart';
import 'package:luart/src/compiler/parser/parse_exp.dart';

// prefixexp ::= var | functioncall | ‘(’ exp ‘)’
// var ::=  Name | prefixexp ‘[’ exp ‘]’ | prefixexp ‘.’ Name
// functioncall ::=  prefixexp args | prefixexp ‘:’ Name args

/*
prefixexp ::= Name
	| ‘(’ exp ‘)’
	| prefixexp ‘[’ exp ‘]’
	| prefixexp ‘.’ Name
	| prefixexp [‘:’ Name] args
*/

LuaExp parsePrefixExp(LuaLexer lexer) {
	late LuaExp exp;
	if (lexer.lookAhead() == LuaTokens.identifier) {
		final ident = lexer.nextIdentifier(); // Name
		exp = LuaNameExp(line: ident.line, name: ident.value);
	} else { // ‘(’ exp ‘)’
		exp = parseParensExp(lexer);
	}
	return _finishPrefixExp(lexer, exp);
}

LuaExp parseParensExp(LuaLexer lexer) {
	lexer.nextTokenOfKind(LuaTokens.sepLparen); // (
	final exp = parseExp(lexer);                  // exp
	lexer.nextTokenOfKind(LuaTokens.sepRparen); // )

	switch (exp.runtimeType) {
    case LuaVarargExp:
    case LuaFuncCallExp:
    case LuaNameExp:
    case LuaTableAccessExp:
		return LuaParensExp(exp);
	}

	// no need to keep parens
	return exp;
}

LuaExp _finishPrefixExp(LuaLexer lexer, LuaExp exp) {
	while(true) {
		switch (lexer.lookAhead()) {
		case LuaTokens.sepLbrack: // prefixexp ‘[’ exp ‘]’
			lexer.nextToken();                       // ‘[’
			final keyExp = parseExp(lexer);               // exp
			lexer.nextTokenOfKind(LuaTokens.sepRbrack); // ‘]’
			exp = LuaTableAccessExp(lastLine: lexer.line, prefixExp: exp, keyExp: keyExp);
      break;
		case LuaTokens.sepDot: // prefixexp ‘.’ Name
			lexer.nextToken();                    // ‘.’
			final ident = lexer.nextIdentifier(); // Name
			final keyExp = LuaStringExp(line: ident.line, value: ident.value);
			exp = LuaTableAccessExp(lastLine: lexer.line, prefixExp: exp, keyExp: keyExp);
      break;
		case LuaTokens.sepColon: // prefixexp ‘:’ Name args
    case LuaTokens.sepLparen:
    case LuaTokens.sepLcurly:
    case LuaTokens.string: // prefixexp args
			exp = _finishFuncCallExp(lexer, exp);
      break;
		default:
			return exp;
		}
	}
}

// functioncall ::=  prefixexp args | prefixexp ‘:’ Name args
LuaFuncCallExp _finishFuncCallExp(LuaLexer lexer,LuaExp prefixExp ) {
	final nameExp = _parseNameExp(lexer);
	final line = lexer.line; // todo
	final args = _parseArgs(lexer);
	final lastLine = lexer.line;
	return LuaFuncCallExp(line: line, lastLine: lastLine, prefixExp: prefixExp, nameExp: nameExp, args: args);
}

LuaStringExp? _parseNameExp(LuaLexer lexer) {
	if (lexer.lookAhead() == LuaTokens.sepColon) {
		lexer.nextToken();
		final ident = lexer.nextIdentifier();
			return  LuaStringExp(line: ident.line, value: ident.value);
	}
	return null;
}

// args ::=  ‘(’ [explist] ‘)’ | tableconstructor | LiteralString
List<LuaExp> _parseArgs(LuaLexer lexer) {
  var args = <LuaExp>[];
	switch (lexer.lookAhead()) {
	case LuaTokens.sepLparen: // ‘(’ [explist] ‘)’
		lexer.nextToken(); // LuaTokens.sepLparen
		if (lexer.lookAhead() != LuaTokens.sepRparen) {
			args = parseExpList(lexer);
		}
		lexer.nextTokenOfKind(LuaTokens.sepRparen);
    break;
	case LuaTokens.sepLcurly: // ‘{’ [fieldlist] ‘}’
		args = <LuaExp>[parseTableConstructorExp(lexer)];
    break;
	default: // LiteralString
		final token = lexer.nextTokenOfKind(LuaTokens.string);
		args = <LuaExp>[LuaStringExp(line: token.line, value: token.value)];
	}
	return args;
}
