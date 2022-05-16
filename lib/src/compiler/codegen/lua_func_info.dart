import 'package:luart/luart.dart';
import 'package:luart/src/compiler/ast/lua_exp.dart';
import 'package:luart/src/compiler/lexer/token.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/vm/fpb.dart';

const arithAndBitwiseBinops = <int, int>{
  LuaTokens.opAdd: opAdd,
  LuaTokens.opSub: opSub,
  LuaTokens.opMul: opMul,
  LuaTokens.opMod: opMod,
  LuaTokens.opPow: opPow,
  LuaTokens.opDiv: opDiv,
  LuaTokens.opIdiv: opIDiv,
  LuaTokens.opBand: opBAnd,
  LuaTokens.opBor: opBOr,
  LuaTokens.opBxor: opBXOr,
  LuaTokens.opShl: opShl,
  LuaTokens.opShr: opShr,
};

class LuaUpvalInfo {
  LuaUpvalInfo(this.locVarSlot, this.upvalIndex, this.index);
  int locVarSlot;
  int upvalIndex;
  int index;
}

class LuaLocVarInfo {
  LuaLocVarInfo({
    required this.prev,
    required this.name,
    required this.scopeLv,
    required this.slot,
    required this.startPC,
    required this.endPC,
    this.captured = false,
  });

  LuaLocVarInfo? prev;
  String name;
  int scopeLv;
  int slot;
  int startPC;
  int endPC;
  bool captured;
}

class LuaFuncInfo {
  LuaFuncInfo(LuaFuncDefExp fd, [this.parent])
      : line = fd.line,
        lastLine = fd.lastLine,
        numParams = fd.parList.length,
        isVararg = fd.isVararg;

  final int line;
  final int lastLine;
  final int numParams;
  final bool isVararg;

  LuaFuncInfo? parent;
  List<LuaFuncInfo> subFuncs = [];
  int usedRegs = 0;
  int maxRegs = 0;
  int scopeLv = 0;
  List<LuaLocVarInfo> locVars = [];
  Map<String, LuaLocVarInfo> locNames = {};
  Map<String, LuaUpvalInfo> upvalues = {};
  Map<Object?, int> constants = {};
  List<List<int>?> breaks = [[]];
  List<int> insts = [];
  List<int> lineNums = [];

  /* constants */

  int indexOfConstant(Object? k) {
    final idx = constants[k];
    if (idx != null) {
      return idx;
    }

    final newIdx = constants.length;
    constants[k] = newIdx;

    return newIdx;
  }

  /* registers */

  int allocReg() {
    usedRegs++;

    if (usedRegs >= 255) {
      throw LuaCompilerError('function or expression needs too many registers');
    }

    if (usedRegs > maxRegs) {
      maxRegs = usedRegs;
    }

    return usedRegs - 1;
  }

  void freeReg() {
    if (usedRegs <= 0) {
      throw LuaCompilerError('usedRegs <= 0 !');
    }
    usedRegs--;
  }

  int allocRegs(int n) {
    if (n <= 0) {
      throw LuaCompilerError('n <= 0 !');
    }

    for (var i = 0; i < n; i++) {
      allocReg();
    }
    return usedRegs - n;
  }

  void freeRegs(int n) {
    if (n < 0) {
      throw LuaCompilerError('n < 0 !');
    }

    for (var i = 0; i < n; i++) {
      freeReg();
    }
  }

  /* lexical scope */

  void enterScope(bool breakable) {
    scopeLv++;
    if (breakable) {
      breaks.add(<int>[]);
    } else {
      breaks.add(null);
    }
  }

  void exitScope(int endPC) {
    final pendingBreakJmps = breaks.removeLast() ?? [];

    final a = getJmpArgA();
    for (final pc in pendingBreakJmps) {
      final sBx = this.pc - pc;
      final i = (sBx + maxArgSBx) << 14 | a << 6 | opJmp;
      insts[pc] = i;
    }

    scopeLv--;
    for (final locVar in locNames.values.toList()) {
      if (locVar.scopeLv > scopeLv) {
        // out of scope
        locVar.endPC = endPC;
        removeLocVar(locVar);
      }
    }
  }

  void removeLocVar(LuaLocVarInfo locVar) {
    freeReg();
    final prev = locVar.prev;
    if (prev == null) {
      locNames.remove(locVar.name);
    } else if (prev.scopeLv == locVar.scopeLv) {
      removeLocVar(prev);
    } else {
      locNames[locVar.name] = prev;
    }
  }

  int addLocVar(String name, int startPC) {
    final newVar = LuaLocVarInfo(
      name: name,
      prev: locNames[name],
      scopeLv: scopeLv,
      slot: allocReg(),
      startPC: startPC,
      endPC: 0,
    );

    locVars.add(newVar);
    locNames[name] = newVar;

    return newVar.slot;
  }

  int slotOfLocVar(String name) {
    final locVar = locNames[name];
    if (locVar != null) {
      return locVar.slot;
    }
    return -1;
  }

  void addBreakJmp(int pc) {
    for (var i = scopeLv; i >= 0; i--) {
      if (breaks[i] != null) {
        // breakable
        breaks[i]!.add(pc);
        return;
      }
    }

    throw LuaCompilerError('<break> at line ? not inside a loop!');
  }

  /* upvalues */

  int indexOfUpval(String name) {
    final upval = upvalues[name];
    if (upval != null) {
      return upval.index;
    }

    final parent = this.parent; // for nnbd
    if (parent != null) {
      final locVar = parent.locNames[name];
      if (locVar != null) {
        final idx = upvalues.length;
        upvalues[name] = LuaUpvalInfo(locVar.slot, -1, idx);
        locVar.captured = true;
        return idx;
      }
      final uvIdx = parent.indexOfUpval(name);
      if (uvIdx >= 0) {
        final idx = upvalues.length;
        upvalues[name] = LuaUpvalInfo(-1, uvIdx, idx);
        return idx;
      }
    }
    return -1;
  }

  void closeOpenUpvals(int line) {
    final a = getJmpArgA();
    if (a > 0) {
      emitJmp(line, a, 0);
    }
  }

  int getJmpArgA() {
    var hasCapturedLocVars = false;
    var minSlotOfLocVars = maxRegs;
    for (final locVar in locNames.values) {
      if (locVar.scopeLv == scopeLv) {
        LuaLocVarInfo? v = locVar;
        while (v != null && v.scopeLv == scopeLv) {
          if (v.captured) {
            hasCapturedLocVars = true;
          }
          if (v.slot < minSlotOfLocVars && v.name[0] != '(') {
            minSlotOfLocVars = v.slot;
          }
          v = v.prev;
        }
      }
    }
    if (hasCapturedLocVars) {
      return minSlotOfLocVars + 1;
    } else {
      return 0;
    }
  }

  /* code */

  int get pc {
    return insts.length - 1;
  }

  void fixSbx(int pc, int sBx) {
    var i = insts[pc];
    i = i & 0x3fff; // clear sBx
    i = i | (sBx + maxArgSBx) << 14; // reset sBx
    insts[pc] = i;
  }

  // todo: rename?
  void fixEndPC(String name, int delta) {
    for (var i = locVars.length - 1; i >= 0; i--) {
      final locVar = locVars[i];
      if (locVar.name == name) {
        locVar.endPC += delta;
        return;
      }
    }
  }

  void emitABC(int line, int opcode, int a, int b, int c) {
    final i = b << 23 | c << 14 | a << 6 | opcode;
    insts.add(i);
    lineNums.add(line);
  }

  void emitABx(int line, int opcode, int a, int bx) {
    final i = (bx << 14) | (a << 6) | opcode;
    insts.add(i);
    lineNums.add(line);
  }

  void emitAsBx(int line, int opcode, int a, int b) {
    final i = ((b + maxArgSBx) << 14) | (a << 6) | opcode;
    insts.add(i);
    lineNums.add(line);
  }

  void emitAx(int line, int opcode, int ax) {
    final i = (ax << 6) | opcode;
    insts.add(i);
    lineNums.add(line);
  }

  // r[a] = r[b]
  void emitMove(int line, int a, int b) {
    emitABC(line, opMove, a, b, 0);
  }

  // r[a], r[a+1], ..., r[a+b] = nil
  void emitLoadNil(int line, int a, int n) {
    emitABC(line, opLoadNil, a, n - 1, 0);
  }

  // r[a] = (bool)b; if (c) pc++
  void emitLoadBool(int line, int a, int b, int c) {
    emitABC(line, opLoadBool, a, b, c);
  }

  // r[a] = kst[bx]
  void emitLoadK(int line, int a, Object k) {
    final idx = indexOfConstant(k);
    if (idx < (1 << 18)) {
      emitABx(line, opLoadK, a, idx);
    } else {
      emitABx(line, opLoadKX, a, 0);
      emitAx(line, opExtraArg, idx);
    }
  }

  // r[a], r[a+1], ..., r[a+b-2] = vararg
  void emitVararg(int line, int a, int n) {
    emitABC(line, opVarArg, a, n + 1, 0);
  }

  // r[a] = emitClosure(proto[bx])
  void emitClosure(int line, int a, int bx) {
    emitABx(line, opClosure, a, bx);
  }

  // r[a] = {}
  void emitNewTable(int line, int a, int nArr, int nRec) {
    emitABC(line, opNewTable, a, int2Fb(nArr), int2Fb(nRec));
  }

  // r[a][(c-1)*FPF+i] := r[a+i], 1 <= i <= b
  void emitSetList(int line, int a, int b, int c) {
    emitABC(line, opSetList, a, b, c);
  }

  // r[a] := r[b][rk(c)]
  void emitGetTable(int line, int a, int b, int c) {
    emitABC(line, opGetTable, a, b, c);
  }

  // r[a][rk(b)] = rk(c)
  void emitSetTable(int line, int a, int b, int c) {
    emitABC(line, opSetTable, a, b, c);
  }

  // r[a] = upval[b]
  void emitGetUpval(int line, int a, int b) {
    emitABC(line, opGetUpVal, a, b, 0);
  }

  // upval[b] = r[a]
  void emitSetUpval(int line, int a, int b) {
    emitABC(line, opSetUpVal, a, b, 0);
  }

  // r[a] = upval[b][rk(c)]
  void emitGetTabUp(int line, int a, int b, int c) {
    emitABC(line, opGetTab, a, b, c);
  }

  // upval[a][rk(b)] = rk(c)
  void emitSetTabUp(int line, int a, int b, int c) {
    emitABC(line, opSetTabUp, a, b, c);
  }

  // r[a], ..., r[a+c-2] = r[a](r[a+1], ..., r[a+b-1])
  void emitCall(int line, int a, int nArgs, int nRet) {
    emitABC(line, opCall, a, nArgs + 1, nRet + 1);
  }

  // return r[a](r[a+1], ... ,r[a+b-1])
  void emitTailCall(int line, int a, int nArgs) {
    emitABC(line, opTailCall, a, nArgs + 1, 0);
  }

  // return r[a], ... ,r[a+b-2]
  void emitReturn(int line, int a, int n) {
    emitABC(line, opReturn, a, n + 1, 0);
  }

  // r[a+1] := r[b]; r[a] := r[b][rk(c)]
  void emitSelf(int line, int a, int b, int c) {
    emitABC(line, opSelf, a, b, c);
  }

  // pc+=sBx; if (a) close all upvalues >= r[a - 1]
  int emitJmp(int line, int a, int sBx) {
    emitAsBx(line, opJmp, a, sBx);
    return insts.length - 1;
  }

  // if not (r[a] <=> c) then pc++
  void emitTest(int line, int a, int c) {
    emitABC(line, opTest, a, 0, c);
  }

  // if (r[b] <=> c) then r[a] := r[b] else pc++
  void emitTestSet(int line, int a, int b, int c) {
    emitABC(line, opTestSet, a, b, c);
  }

  int emitForPrep(int line, int a, int sBx) {
    emitAsBx(line, opForPrep, a, sBx);
    return insts.length - 1;
  }

  int emitForLoop(int line, int a, int sBx) {
    emitAsBx(line, opForLoop, a, sBx);
    return insts.length - 1;
  }

  void emitTForCall(int line, int a, int c) {
    emitABC(line, opTForCall, a, 0, c);
  }

  void emitTForLoop(int line, int a, int sBx) {
    emitAsBx(line, opTForLoop, a, sBx);
  }

  // r[a] = op r[b]
  void emitUnaryOp(int line, int op, int a, int b) {
    switch (op) {
      case LuaTokens.opNot:
        emitABC(line, opNot, a, b, 0);
        break;
      case LuaTokens.opBnot:
        emitABC(line, opBNot, a, b, 0);
        break;
      case LuaTokens.opLen:
        emitABC(line, opLen, a, b, 0);
        break;
      case LuaTokens.opUnm:
        emitABC(line, opUnm, a, b, 0);
        break;
    }
  }

  // r[a] = rk[b] op rk[c]
  // arith & bitwise & relational
  void emitBinaryOp(int line, int op, int a, int b, int c) {
    final opcode = arithAndBitwiseBinops[op];
    if (opcode != null) {
      emitABC(line, opcode, a, b, c);
    } else {
      switch (op) {
        case LuaTokens.opEq:
          emitABC(line, opEq, 1, b, c);
          break;
        case LuaTokens.opNe:
          emitABC(line, opEq, 0, b, c);
          break;
        case LuaTokens.opLt:
          emitABC(line, opLt, 1, b, c);
          break;
        case LuaTokens.opGt:
          emitABC(line, opLt, 1, c, b);
          break;
        case LuaTokens.opLe:
          emitABC(line, opLe, 1, b, c);
          break;
        case LuaTokens.opGe:
          emitABC(line, opLe, 1, c, b);
          break;
      }
      emitJmp(line, 0, 1);
      emitLoadBool(line, a, 0, 1);
      emitLoadBool(line, a, 1, 0);
    }
  }
}
