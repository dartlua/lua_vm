import 'package:luart/src/binary/chunk.dart';
import 'package:luart/src/compiler/codegen/codegen.dart';
import 'package:luart/src/compiler/parser/lua_parser.dart';

LuaPrototype compile(String chunk, String chunkName) {
  final ast = LuaParser.parse(chunk, chunkName);
  final proto = genProto(ast);
  _setSource(proto, chunkName);
  return proto;
}

void _setSource(LuaPrototype proto, String chunkName) {
  proto.source = chunkName;
  for (final f in proto.protos) {
    _setSource(f, chunkName);
  }
}
