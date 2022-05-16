import 'package:luart/luart.dart';
import 'package:luart/src/compiler/ast/lua_exp.dart';
import 'package:luart/src/compiler/ast/lua_stat.dart';
import 'package:luart/src/compiler/codegen/codegen_block.dart';
import 'package:luart/src/compiler/codegen/codegen_exp.dart';
import 'package:luart/src/compiler/codegen/lua_func_info.dart';
import 'package:luart/src/compiler/helpers.dart';

void cgStat(LuaFuncInfo fi, LuaStat node) {
  if (node is LuaFuncCallStat) {
    return cgFuncCallStat(fi, node);
  } else if (node is LuaBreakStat) {
    return cgBreakStat(fi, node);
  } else if (node is LuaDoStat) {
    return cgDoStat(fi, node);
  } else if (node is LuaWhileStat) {
    return cgWhileStat(fi, node);
  } else if (node is LuaRepeatStat) {
    return cgRepeatStat(fi, node);
  } else if (node is LuaIfStat) {
    return cgIfStat(fi, node);
  } else if (node is LuaForNumStat) {
    return cgForNumStat(fi, node);
  } else if (node is LuaForInStat) {
    return cgForInStat(fi, node);
  } else if (node is LuaAssignStat) {
    return cgAssignStat(fi, node);
  } else if (node is LuaLocalVarDeclStat) {
    return cgLocalVarDeclStat(fi, node);
  } else if (node is LuaLocalFuncDefStat) {
    return cgLocalFuncDefStat(fi, node);
  } else if (node is LuaLabelStat || node is LuaGotoStat) {
    throw LuaCompilerError('label and goto statements are not supported!');
  }

  throw LuaCompilerError('unknown type of statement: $node');
}

void cgLocalFuncDefStat(LuaFuncInfo fi, LuaLocalFuncDefStat node) {
  final r = fi.addLocVar(node.name, fi.pc + 2);
  cgFuncDefExp(fi, node.exp, r);
}

void cgFuncCallStat(LuaFuncInfo fi, LuaFuncCallStat node) {
  final r = fi.allocReg();
  cgFuncCallExp(fi, node.exp, r, 0);
  fi.freeReg();
}

void cgBreakStat(LuaFuncInfo fi, LuaBreakStat node) {
  final pc = fi.emitJmp(node.line, 0, 0);
  fi.addBreakJmp(pc);
}

void cgDoStat(LuaFuncInfo fi, LuaDoStat node) {
  fi.enterScope(false);
  cgBlock(fi, node.block);
  fi.closeOpenUpvals(node.block.lastLine);
  fi.exitScope(fi.pc + 1);
}

/*
           ______________
          /  false? jmp  |
         /               |
while exp do block end <-'
      ^           \
      |___________/
           jmp
*/
void cgWhileStat(LuaFuncInfo fi, LuaWhileStat node) {
  final pcBeforeExp = fi.pc;

  final oldRegs = fi.usedRegs;
  final a = expToOpArg(fi, node.exp, argReg).arg;
  fi.usedRegs = oldRegs;

  final line = lastLineOf(node.exp);
  fi.emitTest(line, a, 0);
  final pcJmpToEnd = fi.emitJmp(line, 0, 0);

  fi.enterScope(true);
  cgBlock(fi, node.block);
  fi.closeOpenUpvals(node.block.lastLine);
  fi.emitJmp(node.block.lastLine, 0, pcBeforeExp - fi.pc - 1);
  fi.exitScope(fi.pc);

  fi.fixSbx(pcJmpToEnd, fi.pc - pcJmpToEnd);
}

/*
        ______________
       |  false? jmp  |
       V              /
repeat block until exp
*/
void cgRepeatStat(LuaFuncInfo fi, LuaRepeatStat node) {
  fi.enterScope(true);

  final pcBeforeBlock = fi.pc;
  cgBlock(fi, node.block);

  final oldRegs = fi.usedRegs;
  final a = expToOpArg(fi, node.exp, argReg).arg;
  fi.usedRegs = oldRegs;

  final line = lastLineOf(node.exp);
  fi.emitTest(line, a, 0);
  fi.emitJmp(line, fi.getJmpArgA(), pcBeforeBlock - fi.pc - 1);
  fi.closeOpenUpvals(line);

  fi.exitScope(fi.pc + 1);
}

/*
         _________________       _________________       _____________
        / false? jmp      |     / false? jmp      |     / false? jmp  |
       /                  V    /                  V    /              V
if exp1 then block1 elseif exp2 then block2 elseif true then block3 end <-.
                   \                       \                       \      |
                    \_______________________\_______________________\_____|
                    jmp                     jmp                     jmp
*/
void cgIfStat(LuaFuncInfo fi, LuaIfStat node) {
  final pcJmpToEnds = <int>[];
  var pcJmpToNextExp = -1;

  for (var i = 0; i < node.exps.length; i++) {
    final exp = node.exps[i];
    if (pcJmpToNextExp >= 0) {
      fi.fixSbx(pcJmpToNextExp, fi.pc - pcJmpToNextExp);
    }

    final oldRegs = fi.usedRegs;
    final a = expToOpArg(fi, exp, argReg).arg;
    fi.usedRegs = oldRegs;

    final line = lastLineOf(exp);
    fi.emitTest(line, a, 0);
    pcJmpToNextExp = fi.emitJmp(line, 0, 0);

    final block = node.blocks[i];
    fi.enterScope(false);
    cgBlock(fi, block);
    fi.closeOpenUpvals(block.lastLine);
    fi.exitScope(fi.pc + 1);
    if (i < node.exps.length - 1) {
      pcJmpToEnds.add(fi.emitJmp(block.lastLine, 0, 0));
    } else {
      pcJmpToEnds.add(pcJmpToNextExp);
    }
  }

  for (final pc in pcJmpToEnds) {
    fi.fixSbx(pc, fi.pc - pc);
  }
}

void cgForNumStat(LuaFuncInfo fi, LuaForNumStat node) {
  const forIndexVar = '(for index)';
  const forLimitVar = '(for limit)';
  const forStepVar = '(for step)';

  fi.enterScope(true);

  cgLocalVarDeclStat(
    fi,
    LuaLocalVarDeclStat(
      lastLine: 0, // is this correct?
      nameList: <String>[forIndexVar, forLimitVar, forStepVar],
      expList: <LuaExp>[node.initExp, node.limitExp, node.stepExp],
    ),
  );
  fi.addLocVar(node.varName, fi.pc + 2);

  final a = fi.usedRegs - 4;
  final pcForPrep = fi.emitForPrep(node.lineOfDo, a, 0);
  cgBlock(fi, node.block);
  fi.closeOpenUpvals(node.block.lastLine);
  final pcForLoop = fi.emitForLoop(node.lineOfFor, a, 0);

  fi.fixSbx(pcForPrep, pcForLoop - pcForPrep - 1);
  fi.fixSbx(pcForLoop, pcForPrep - pcForLoop);

  fi.exitScope(fi.pc);
  fi.fixEndPC(forIndexVar, 1);
  fi.fixEndPC(forLimitVar, 1);
  fi.fixEndPC(forStepVar, 1);
}

void cgForInStat(LuaFuncInfo fi, LuaForInStat node) {
  const forGeneratorVar = '(for generator)';
  const forStateVar = '(for state)';
  const forControlVar = '(for control)';

  fi.enterScope(true);

  cgLocalVarDeclStat(
    fi,
    LuaLocalVarDeclStat(
      lastLine: 0, // is this correct?
      nameList: <String>[forGeneratorVar, forStateVar, forControlVar],
      expList: node.expList,
    ),
  );
  for (final name in node.nameList) {
    fi.addLocVar(name, fi.pc + 2);
  }

  final pcJmpToTFC = fi.emitJmp(node.lineOfDo, 0, 0);
  cgBlock(fi, node.block);
  fi.closeOpenUpvals(node.block.lastLine);
  fi.fixSbx(pcJmpToTFC, fi.pc - pcJmpToTFC);

  final line = lineOf(node.expList[0]);
  final rGenerator = fi.slotOfLocVar(forGeneratorVar);
  fi.emitTForCall(line, rGenerator, node.nameList.length);
  fi.emitTForLoop(line, rGenerator + 2, pcJmpToTFC - fi.pc - 1);

  fi.exitScope(fi.pc - 1);
  fi.fixEndPC(forGeneratorVar, 2);
  fi.fixEndPC(forStateVar, 2);
  fi.fixEndPC(forControlVar, 2);
}

void cgLocalVarDeclStat(LuaFuncInfo fi, LuaLocalVarDeclStat node) {
  final exps = removeTailNils(node.expList ?? []) ?? [];
  final nExps = exps.length;
  final nNames = node.nameList.length;

  final oldRegs = fi.usedRegs;
  if (nExps == nNames) {
    for (final exp in exps) {
      final a = fi.allocReg();
      cgExp(fi, exp, a, 1);
    }
  } else if (nExps > nNames) {
    for (var i = 0; i < exps.length; i++) {
      final exp = exps[i];
      final a = fi.allocReg();
      if (i == nExps - 1 && isVarargOrFuncCall(exp)) {
        cgExp(fi, exp, a, 0);
      } else {
        cgExp(fi, exp, a, 1);
      }
    }
  } else {
    // nNames > nExps
    var multRet = false;
    for (var i = 0; i < exps.length; i++) {
      final exp = exps[i];
      final a = fi.allocReg();
      if (i == nExps - 1 && isVarargOrFuncCall(exp)) {
        multRet = true;
        final n = nNames - nExps + 1;
        cgExp(fi, exp, a, n);
        fi.allocRegs(n - 1);
      } else {
        cgExp(fi, exp, a, 1);
      }
    }
    if (!multRet) {
      final n = nNames - nExps;
      final a = fi.allocRegs(n);
      fi.emitLoadNil(node.lastLine, a, n);
    }
  }

  fi.usedRegs = oldRegs;
  final startPC = fi.pc + 1;
  for (final name in node.nameList) {
    fi.addLocVar(name, startPC);
  }
}

void cgAssignStat(LuaFuncInfo fi, LuaAssignStat node) {
  final exps = removeTailNils(node.expList) ?? [];
  final nExps = exps.length;
  final nVars = node.varList.length;

  final tRegs = List<int?>.filled(nVars, null);
  final kRegs = List<int?>.filled(nVars, null);
  final vRegs = <int>[];
  final oldRegs = fi.usedRegs;

  for (var i = 0; i < node.varList.length; i++) {
    final exp = node.varList[i];
    if (exp is LuaTableAccessExp) {
      tRegs[i] = fi.allocReg();
      cgExp(fi, exp.prefixExp, tRegs[i]!, 1);
      kRegs[i] = fi.allocReg();
      cgExp(fi, exp.keyExp, kRegs[i]!, 1);
    } else {
      final name = (exp as LuaNameExp).name;
      if (fi.slotOfLocVar(name) < 0 && fi.indexOfUpval(name) < 0) {
        // global var
        kRegs[i] = -1;
        if (fi.indexOfConstant(name) > 0xFF) {
          kRegs[i] = fi.allocReg();
        }
      }
    }
  }
  for (var i = 0; i < nVars; i++) {
    vRegs.add(fi.usedRegs + i);
  }

  if (nExps >= nVars) {
    for (var i = 0; i < exps.length; i++) {
      final exp = exps[i];
      final a = fi.allocReg();
      if (i >= nVars && i == nExps - 1 && isVarargOrFuncCall(exp)) {
        cgExp(fi, exp, a, 0);
      } else {
        cgExp(fi, exp, a, 1);
      }
    }
  } else {
    // nVars > nExps
    var multRet = false;
    for (var i = 0; i < exps.length; i++) {
      final exp = exps[i];
      final a = fi.allocReg();
      if (i == nExps - 1 && isVarargOrFuncCall(exp)) {
        multRet = true;
        final n = nVars - nExps + 1;
        cgExp(fi, exp, a, n);
        fi.allocRegs(n - 1);
      } else {
        cgExp(fi, exp, a, 1);
      }
    }
    if (!multRet) {
      final n = nVars - nExps;
      final a = fi.allocRegs(n);
      fi.emitLoadNil(node.lastLine, a, n);
    }
  }

  final lastLine = node.lastLine;
  for (var i = 0; i < node.varList.length; i++) {
    final exp = node.varList[i];
    if (exp is LuaNameExp) {
      final varName = exp.name;
      var a = fi.slotOfLocVar(varName);
      late int b;
      if (a >= 0) {
        fi.emitMove(lastLine, a, vRegs[i]);
      } else if ((b = fi.indexOfUpval(varName)) >= 0) {
        fi.emitSetUpval(lastLine, vRegs[i], b);
      } else if ((a = fi.slotOfLocVar('_ENV')) >= 0) {
        if (kRegs[i]! < 0) {
          final b = 0x100 + fi.indexOfConstant(varName);
          fi.emitSetTable(lastLine, a, b, vRegs[i]);
        } else {
          fi.emitSetTable(lastLine, a, kRegs[i]!, vRegs[i]);
        }
      } else {
        // global var
        final a = fi.indexOfUpval('_ENV');
        if (kRegs[i]! < 0) {
          final b = 0x100 + fi.indexOfConstant(varName);
          fi.emitSetTabUp(lastLine, a, b, vRegs[i]);
        } else {
          fi.emitSetTabUp(lastLine, a, kRegs[i]!, vRegs[i]);
        }
      }
    } else {
      fi.emitSetTable(lastLine, tRegs[i]!, kRegs[i]!, vRegs[i]);
    }
  }

  // todo
  fi.usedRegs = oldRegs;
}
