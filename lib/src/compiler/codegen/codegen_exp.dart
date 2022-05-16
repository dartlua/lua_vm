// kind of operands
import 'package:luart/luart.dart';
import 'package:luart/src/compiler/ast/lua_exp.dart';
import 'package:luart/src/compiler/codegen/codegen_block.dart';
import 'package:luart/src/compiler/codegen/lua_func_info.dart';
import 'package:luart/src/compiler/helpers.dart';
import 'package:luart/src/compiler/lexer/token.dart';
import 'package:luart/src/constants.dart';

const argConst = 1; // const index
const argReg = 2; // register index
const argUpVal = 4; // upvalue index
const argRK = argReg | argConst;
const argRU = argReg | argUpVal;
const argRUK = argReg | argUpVal | argConst;

// todo: rename to evalExp()?
void cgExp(LuaFuncInfo fi, LuaExp node, int a, int n) {
  if (node is LuaNilExp) {
    return fi.emitLoadNil(node.line, a, n);
  }
  if (node is LuaFalseExp) {
    return fi.emitLoadBool(node.line, a, 0, 0);
  }
  if (node is LuaTrueExp) {
    return fi.emitLoadBool(node.line, a, 1, 0);
  }
  if (node is LuaIntegerExp) {
    return fi.emitLoadK(node.line, a, node.value);
  }
  if (node is LuaFloatExp) {
    return fi.emitLoadK(node.line, a, node.value);
  }
  if (node is LuaStringExp) {
    return fi.emitLoadK(node.line, a, node.value);
  }
  if (node is LuaParensExp) {
    return cgExp(fi, node.exp, a, 1);
  }
  if (node is LuaVarargExp) {
    return cgVarargExp(fi, node, a, n);
  }
  if (node is LuaFuncDefExp) {
    return cgFuncDefExp(fi, node, a);
  }
  if (node is LuaTableConstructorExp) {
    return cgTableConstructorExp(fi, node, a);
  }
  if (node is LuaUnopExp) {
    return cgUnopExp(fi, node, a);
  }
  if (node is LuaBinopExp) {
    return cgBinopExp(fi, node, a);
  }
  if (node is LuaConcatExp) {
    return cgConcatExp(fi, node, a);
  }
  if (node is LuaNameExp) {
    return cgNameExp(fi, node, a);
  }
  if (node is LuaTableAccessExp) {
    return cgTableAccessExp(fi, node, a);
  }
  if (node is LuaFuncCallExp) {
    return cgFuncCallExp(fi, node, a, n);
  }
}

void cgVarargExp(LuaFuncInfo fi, LuaVarargExp node, int a, int n) {
  if (!fi.isVararg) {
    throw LuaCompilerError("cannot use '...' outside a vararg function");
  }
  fi.emitVararg(node.line, a, n);
}

// f[a] := function(args) body end
void cgFuncDefExp(LuaFuncInfo fi, LuaFuncDefExp node, int a) {
  final subFI = LuaFuncInfo(node, fi);
  fi.subFuncs.add(subFI);

  for (final param in node.parList) {
    subFI.addLocVar(param, 0);
  }

  cgBlock(subFI, node.block);
  subFI.exitScope(subFI.pc + 2);
  subFI.emitReturn(node.lastLine, 0, 0);

  final bx = fi.subFuncs.length - 1;
  fi.emitClosure(node.lastLine, a, bx);
}

void cgTableConstructorExp(LuaFuncInfo fi, LuaTableConstructorExp node, int a) {
  var nArr = 0;
  for (final keyExp in node.keyExps) {
    if (keyExp == null) {
      nArr++;
    }
  }
  final nExps = node.keyExps.length;
  final multRet = nExps > 0 && isVarargOrFuncCall(node.valExps[nExps - 1]);

  fi.emitNewTable(node.line, a, nArr, nExps - nArr);

  var arrIdx = 0;
  for (var i = 0; i < node.keyExps.length; i++) {
    final keyExp = node.keyExps[i];
    final valExp = node.valExps[i];

    if (keyExp == null) {
      arrIdx++;
      final tmp = fi.allocReg();
      if (i == nExps - 1 && multRet) {
        cgExp(fi, valExp, tmp, -1);
      } else {
        cgExp(fi, valExp, tmp, 1);
      }

      if (arrIdx % 50 == 0 || arrIdx == nArr) {
        // LFIELDS_PER_FLUSH
        var n = arrIdx % 50;
        if (n == 0) {
          n = 50;
        }
        fi.freeRegs(n);
        final line = lastLineOf(valExp);
        final c = (arrIdx - 1) ~/ 50 + 1; // todo: c > 0xFF
        if (i == nExps - 1 && multRet) {
          fi.emitSetList(line, a, 0, c);
        } else {
          fi.emitSetList(line, a, n, c);
        }
      }

      continue;
    }

    final b = fi.allocReg();
    cgExp(fi, keyExp, b, 1);
    final c = fi.allocReg();
    cgExp(fi, valExp, c, 1);
    fi.freeRegs(2);

    final line = lastLineOf(valExp);
    fi.emitSetTable(line, a, b, c);
  }
}

// r[a] := op exp
void cgUnopExp(LuaFuncInfo fi, LuaUnopExp node, int a) {
  final oldRegs = fi.usedRegs;
  final b = expToOpArg(fi, node.exp, argReg).arg;
  fi.emitUnaryOp(node.line, node.op, a, b);
  fi.usedRegs = oldRegs;
}

// r[a] := exp1 op exp2
void cgBinopExp(LuaFuncInfo fi, LuaBinopExp node, int a) {
  switch (node.op) {
    case LuaTokens.opAnd:
    case LuaTokens.opOr:
      final oldRegs = fi.usedRegs;

      var b = expToOpArg(fi, node.exp1, argReg).arg;
      fi.usedRegs = oldRegs;
      if (node.op == LuaTokens.opAnd) {
        fi.emitTestSet(node.line, a, b, 0);
      } else {
        fi.emitTestSet(node.line, a, b, 1);
      }
      final pcOfJmp = fi.emitJmp(node.line, 0, 0);

      b = expToOpArg(fi, node.exp2, argReg).arg;
      fi.usedRegs = oldRegs;
      fi.emitMove(node.line, a, b);
      fi.fixSbx(pcOfJmp, fi.pc - pcOfJmp);
      break;
    default:
      final oldRegs = fi.usedRegs;
      final b = expToOpArg(fi, node.exp1, argRK).arg;
      final c = expToOpArg(fi, node.exp2, argRK).arg;
      fi.emitBinaryOp(node.line, node.op, a, b, c);
      fi.usedRegs = oldRegs;
  }
}

// r[a] := exp1 .. exp2
void cgConcatExp(LuaFuncInfo fi, LuaConcatExp node, int a) {
  for (final subExp in node.exps) {
    final a = fi.allocReg();
    cgExp(fi, subExp, a, 1);
  }

  final c = fi.usedRegs - 1;
  final b = c - node.exps.length + 1;
  fi.freeRegs(c - b + 1);
  fi.emitABC(node.line, opConcat, a, b, c);
}

// r[a] := name
void cgNameExp(LuaFuncInfo fi, LuaNameExp node, int a) {
  final r = fi.slotOfLocVar(node.name);
  if (r >= 0) {
    fi.emitMove(node.line, a, r);
  } else {
    final idx = fi.indexOfUpval(node.name);
    if (idx >= 0) {
      fi.emitGetUpval(node.line, a, idx);
    } else {
      // x => _ENV['x']
      final taExp = LuaTableAccessExp(
        lastLine: node.line,
        prefixExp: LuaNameExp(line: node.line, name: '_ENV'),
        keyExp: LuaStringExp(line: node.line, value: node.name),
      );
      cgTableAccessExp(fi, taExp, a);
    }
  }
}

// r[a] := prefix[key]
void cgTableAccessExp(LuaFuncInfo fi, LuaTableAccessExp node, int a) {
  final oldRegs = fi.usedRegs;
  final b = expToOpArg(fi, node.prefixExp, argRU);
  final c = expToOpArg(fi, node.keyExp, argRK).arg;
  fi.usedRegs = oldRegs;

  if (b.argKind == argUpVal) {
    fi.emitGetTabUp(node.lastLine, a, b.arg, c);
  } else {
    fi.emitGetTable(node.lastLine, a, b.arg, c);
  }
}

// r[a] := f(args)
void cgFuncCallExp(LuaFuncInfo fi, LuaFuncCallExp node, int a, int n) {
  final nArgs = prepFuncCall(fi, node, a);
  fi.emitCall(node.line, a, nArgs, n);
}

// return f(args)
void cgTailCallExp(LuaFuncInfo fi, LuaFuncCallExp node, int a) {
  final nArgs = prepFuncCall(fi, node, a);
  fi.emitTailCall(node.line, a, nArgs);
}

int prepFuncCall(LuaFuncInfo fi, LuaFuncCallExp node, int a) {
  var nArgs = node.args.length;
  var lastArgIsVarargOrFuncCall = false;

  cgExp(fi, node.prefixExp, a, 1);
  final nameExp = node.nameExp;
  if (nameExp != null) {
    fi.allocReg();
    final c = expToOpArg(fi, nameExp, argRK);
    fi.emitSelf(node.line, a, a, c.arg);
    if (c.argKind == argReg) {
      fi.freeRegs(1);
    }
  }

  for (var i = 0; i < node.args.length; i++) {
    final arg = node.args[i];
    final tmp = fi.allocReg();
    if (i == nArgs - 1 && isVarargOrFuncCall(arg)) {
      lastArgIsVarargOrFuncCall = true;
      cgExp(fi, arg, tmp, -1);
    } else {
      cgExp(fi, arg, tmp, 1);
    }
  }
  fi.freeRegs(nArgs);

  if (node.nameExp != null) {
    fi.freeReg();
    nArgs++;
  }
  if (lastArgIsVarargOrFuncCall) {
    nArgs = -1;
  }

  return nArgs;
}

class _Arg {
  _Arg(this.arg, this.argKind);
  final int arg;
  final int argKind;
}

_Arg expToOpArg(LuaFuncInfo fi, LuaExp node, int argKinds) {
  if (argKinds & argConst > 0) {
    var idx = -1;
    if (node is LuaNilExp) {
      idx = fi.indexOfConstant(null);
    } else if (node is LuaFalseExp) {
      idx = fi.indexOfConstant(false);
    } else if (node is LuaTrueExp) {
      idx = fi.indexOfConstant(true);
    } else if (node is LuaIntegerExp) {
      idx = fi.indexOfConstant(node.value);
    } else if (node is LuaFloatExp) {
      idx = fi.indexOfConstant(node.value);
    } else if (node is LuaStringExp) {
      idx = fi.indexOfConstant(node.value);
    }
    if (idx >= 0 && idx <= 0xFF) {
      return _Arg(0x100 + idx, argConst);
    }
  }

  if (node is LuaNameExp) {
    if (argKinds & argReg > 0) {
      final r = fi.slotOfLocVar(node.name);
      if (r >= 0) {
        return _Arg(r, argReg);
      }
    }
    if (argKinds & argUpVal > 0) {
      final idx = fi.indexOfUpval(node.name);
      if (idx >= 0) {
        return _Arg(idx, argUpVal);
      }
    }
  }

  final a = fi.allocReg();
  cgExp(fi, node, a, 1);
  return _Arg(a, argReg);
}
