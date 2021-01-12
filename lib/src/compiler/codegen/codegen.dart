import 'package:luart/src/binary/chunk.dart';
import 'package:luart/src/compiler/ast/lua_block.dart';
import 'package:luart/src/compiler/ast/lua_exp.dart';
import 'package:luart/src/compiler/codegen/codegen_exp.dart';
import 'package:luart/src/compiler/codegen/lua_func_info.dart';
import 'package:luart/src/compiler/codegen/to_proto.dart';

LuaPrototype genProto(LuaBlock chunk) {
  final fd = LuaFuncDefExp(
    line: 0, // is this correct?
    lastLine: chunk.lastLine,
    parList: [],
    isVararg: true,
    block: chunk,
  );

  final fi = LuaFuncInfo(fd);
  fi.addLocVar('_ENV', 0);
  cgFuncDefExp(fi, fd, 0);
  return toProto(fi.subFuncs[0]);
}
