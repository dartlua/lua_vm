import 'package:luart/src/compiler/ast/lua_block.dart';
import 'package:luart/src/compiler/lexer/lexer.dart';
import 'package:luart/src/compiler/lexer/token.dart';
import 'package:luart/src/compiler/parser/parse_block.dart';

class LuaParser {
  static LuaBlock parse(String chunk, String chunkName) {
    final lexer = LuaLexer(chunk, chunkName);
    final block = parseBlock(lexer);
    lexer.nextTokenOfKind(LuaTokens.eof);
    return block;
  }
}
