import 'package:luart/src/compiler/ast/lua_block.dart';
import 'package:luart/src/compiler/ast/lua_exp.dart';
import 'package:luart/src/compiler/codegen/codegen_exp.dart';
import 'package:luart/src/compiler/codegen/codegen_stat.dart';
import 'package:luart/src/compiler/codegen/lua_func_info.dart';
import 'package:luart/src/compiler/helpers.dart';

void cgBlock(LuaFuncInfo fi, LuaBlock node) {
  for (var stat in node.stats) {
    cgStat(fi, stat);
  }

  final retExps = node.retExps;
  if (retExps != null) {
    cgRetStat(fi, retExps, node.lastLine);
  }
}

void cgRetStat(LuaFuncInfo fi, List<LuaExp> exps, int lastLine) {
  final nExps = exps.length;
  if (nExps == 0) {
    fi.emitReturn(lastLine, 0, 0);
    return;
  }

  if (nExps == 1) {
    final exp = exps[0];
    if (exp is LuaNameExp) {
      final r = fi.slotOfLocVar(exp.name);
      if (r >= 0) {
        fi.emitReturn(lastLine, r, 1);
        return;
      }
    }
    if (exp is LuaFuncCallExp) {
      final r = fi.allocReg();
      cgTailCallExp(fi, exp, r);
      fi.freeReg();
      fi.emitReturn(lastLine, r, -1);
      return;
    }
  }

  final multRet = isVarargOrFuncCall(exps.last);
  for (var i = 0; i < exps.length; i++) {
    final exp = exps[i];
    final r = fi.allocReg();
    if (i == nExps - 1 && multRet) {
      cgExp(fi, exp, r, -1);
    } else {
      cgExp(fi, exp, r, 1);
    }
  }
  fi.freeRegs(nExps);

  final a = fi.usedRegs; // correct?
  if (multRet) {
    fi.emitReturn(lastLine, a, -1);
  } else {
    fi.emitReturn(lastLine, a, nExps);
  }
}
