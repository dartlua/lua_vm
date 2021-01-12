

import 'package:luart/src/binary/chunk.dart';
import 'package:luart/src/compiler/codegen/codegen.dart';
import 'package:luart/src/compiler/parser/lua_parser.dart';

LuaPrototype compile(String chunk, String chunkName) {
	final ast = LuaParser.parse(chunk, chunkName);
	final proto = genProto(ast);
	setSource(proto, chunkName);
	return proto;
}

void setSource(LuaPrototype proto, String chunkName) {
	proto.source = chunkName;
	for (var f in proto.protos) {
		setSource(f, chunkName);
	}
}
