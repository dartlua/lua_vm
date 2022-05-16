import 'package:luart/src/binary/chunk.dart';
import 'package:luart/src/compiler/codegen/lua_func_info.dart';

LuaPrototype toProto(LuaFuncInfo fi) {
  final proto = LuaPrototype(
    lineDefined: fi.line,
    lastLineDefined: fi.lastLine,
    numParams: fi.numParams,
    maxStackSize: fi.maxRegs,
    codes: fi.insts,
    constants: getConstants(fi),
    upvalues: getUpvalues(fi),
    protos: toProtos(fi.subFuncs),
    lineInfo: fi.lineNums,
    locVars: getLocVars(fi),
    upvalueNames: getUpvalueNames(fi),
  );

  if (fi.line == 0) {
    proto.lastLineDefined = 0;
  }
  if (proto.maxStackSize < 2) {
    proto.maxStackSize = 2; // todo
  }
  if (fi.isVararg) {
    proto.isVararg = 1; // todo
  }

  return proto;
}

List<LuaPrototype> toProtos(List<LuaFuncInfo> fis) {
  return fis.map(toProto).toList();
}

List<Object?> getConstants(LuaFuncInfo fi) {
  final consts = List<Object?>.filled(fi.constants.length, null);
  for (final entry in fi.constants.entries) {
    consts[entry.value] = entry.key;
  }
  return consts;
}

List<LocVar> getLocVars(LuaFuncInfo fi) {
  final locVars = <LocVar>[];
  for (final locVar in fi.locVars) {
    locVars.add(
      LocVar(
        locVar.name,
        locVar.startPC,
        locVar.endPC,
      ),
    );
  }
  return locVars;
}

List<Upvalue> getUpvalues(LuaFuncInfo fi) {
  final upvals = List<Upvalue?>.filled(fi.upvalues.length, null);
  for (final uv in fi.upvalues.values) {
    if (uv.locVarSlot >= 0) {
      // instack
      upvals[uv.index] = Upvalue(1, uv.locVarSlot);
    } else {
      upvals[uv.index] = Upvalue(0, uv.upvalIndex);
    }
  }
  return upvals.cast();
}

List<String> getUpvalueNames(LuaFuncInfo fi) {
  final names = List<String?>.filled(fi.upvalues.length, null);
  for (final entry in fi.upvalues.entries) {
    names[entry.value.index] = entry.key;
  }
  return names.cast();
}
