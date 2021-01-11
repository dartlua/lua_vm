import 'package:luart/src/compiler/ast/lua_block.dart';
import 'package:luart/src/compiler/ast/lua_exp.dart';
import 'package:luart/src/compiler/ast/lua_stat.dart';
import 'package:luart/src/compiler/lexer/lexer.dart';
import 'package:luart/src/compiler/lexer/token.dart';
import 'package:luart/src/compiler/parser/parse_exp.dart';
import 'package:luart/src/compiler/parser/parse_stat.dart';

// block ::= {stat} [retstat]
LuaBlock parseBlock(LuaLexer lexer) {
  return LuaBlock(
    stats: parseStats(lexer),
    retExps: parseRetExps(lexer),
    lastLine: lexer.line,
  );
}

List<LuaStat> parseStats(LuaLexer lexer) {
  final stats = <LuaStat>[];
  while (!_isReturnOrBlockEnd(lexer.lookAhead())) {
    final stat = parseStat(lexer);
    if (stat is! LuaEmptyStat) {
      stats.add(stat);
    }
  }
  return stats;
}

bool _isReturnOrBlockEnd(int tokenKind) {
  const tokens = <int>{
    LuaTokens.kwReturn,
    LuaTokens.eof,
    LuaTokens.kwEnd,
    LuaTokens.kwElse,
    LuaTokens.kwElseif,
    LuaTokens.kwUntil
  };
  return tokens.contains(tokenKind);
}

// retstat ::= return [explist] [‘;’]
// explist ::= exp {‘,’ exp}
List<LuaExp>? parseRetExps(LuaLexer lexer) {
  if (lexer.lookAhead() != LuaTokens.kwReturn) {
    return null;
  }

  lexer.nextToken();

  switch (lexer.lookAhead()) {
    case LuaTokens.eof:
    case LuaTokens.kwEnd:
    case LuaTokens.kwElse:
    case LuaTokens.kwElseif:
    case LuaTokens.kwUntil:
      return <LuaExp>[];
    case LuaTokens.sepSemi:
      lexer.nextToken();
      return <LuaExp>[];
    default:
      final exps = parseExpList(lexer);
      if (lexer.lookAhead() == LuaTokens.sepSemi) {
        lexer.nextToken();
      }
      return exps;
  }
}
