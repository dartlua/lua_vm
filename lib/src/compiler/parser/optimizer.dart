import 'dart:math' as math;

import 'package:luart/src/compiler/ast/lua_exp.dart';
import 'package:luart/src/compiler/lexer/token.dart';
import 'package:luart/src/state/lua_math.dart';

LuaExp optimizeLogicalOr(LuaBinopExp exp) {
  if (isTrue(exp.exp1)) {
    return exp.exp1; // true or x => true
  }
  if (isFalse(exp.exp1) && !isVarargOrFuncCall(exp.exp2)) {
    return exp.exp2; // false or x => x
  }
  return exp;
}

LuaExp optimizeLogicalAnd(LuaBinopExp exp) {
  if (isFalse(exp.exp1)) {
    return exp.exp1; // false and x => false
  }
  if (isTrue(exp.exp1) && !isVarargOrFuncCall(exp.exp2)) {
    return exp.exp2; // true and x => x
  }
  return exp;
}

LuaExp optimizeBitwiseBinaryOp(LuaBinopExp exp) {
  final i = castToInt(exp);
  final j = castToInt(exp);
  if (i != null && j != null) {
    switch (exp.op) {
      case LuaTokens.opBand:
        return LuaIntegerExp(line: exp.line, value: i & j);
      case LuaTokens.opBor:
        return LuaIntegerExp(line: exp.line, value: i | j);
      case LuaTokens.opBxor:
        return LuaIntegerExp(line: exp.line, value: i ^ j);
      case LuaTokens.opShl:
        return LuaIntegerExp(line: exp.line, value: LuaMath.shiftLeft(i, j));
      case LuaTokens.opShr:
        return LuaIntegerExp(line: exp.line, value: LuaMath.shiftRight(i, j));
    }
  }
  return exp;
}

LuaExp optimizeArithBinaryOp(LuaBinopExp exp) {
  final exp1 = exp.exp1;
  final exp2 = exp.exp2;
  if (exp1 is LuaIntegerExp && exp2 is LuaIntegerExp) {
    final x = exp1.value;
    final y = exp2.value;
    switch (exp.op) {
      case LuaTokens.opAdd:
        return LuaIntegerExp(line: exp.line, value: x + y);
      case LuaTokens.opSub:
        return LuaIntegerExp(line: exp.line, value: x - y);
      case LuaTokens.opMul:
        return LuaIntegerExp(line: exp.line, value: x * y);
      case LuaTokens.opIdiv:
        if (y != 0) {
          return LuaIntegerExp(line: exp.line, value: LuaMath.iFloorDiv(x, y));
        }
        break;
      case LuaTokens.opMod:
        if (y != 0) {
          return LuaIntegerExp(line: exp.line, value: LuaMath.iMod(x, y));
        }
        break;
    }
  }

  final f = castToFloat(exp.exp1);
  final g = castToFloat(exp.exp2);
  if (f != null && g != null) {
    switch (exp.op) {
      case LuaTokens.opAdd:
        return LuaFloatExp(line: exp.line, value: f + g);
      case LuaTokens.opSub:
        return LuaFloatExp(line: exp.line, value: f - g);
      case LuaTokens.opMul:
        return LuaFloatExp(line: exp.line, value: f * g);
      case LuaTokens.opDiv:
        if (g != 0) {
          return LuaFloatExp(line: exp.line, value: f / g);
        }
        break;
      case LuaTokens.opIdiv:
        if (g != 0) {
          return LuaFloatExp(line: exp.line, value: LuaMath.fFloorDiv(f, g));
        }
        break;
      case LuaTokens.opMod:
        if (g != 0) {
          return LuaFloatExp(line: exp.line, value: LuaMath.fMod(f, g));
        }
        break;
      case LuaTokens.opPow:
        return LuaFloatExp(line: exp.line, value: math.pow(f, g).toDouble());
    }
  }
  return exp;
}

LuaExp optimizePow(LuaExp exp) {
  if (exp is LuaBinopExp) {
    if (exp.op == LuaTokens.opPow) {
      exp = LuaBinopExp(
        line: exp.line,
        op: exp.op,
        exp1: exp.exp1,
        exp2: optimizePow(exp.exp2),
      );
    }
    return optimizeArithBinaryOp(exp);
  }
  return exp;
}

LuaExp optimizeUnaryOp(LuaUnopExp exp) {
  switch (exp.op) {
    case LuaTokens.opUnm:
      return optimizeUnm(exp);
    case LuaTokens.opNot:
      return optimizeNot(exp);
    case LuaTokens.opBnot:
      return optimizeBnot(exp);
    default:
      return exp;
  }
}

LuaExp optimizeUnm(LuaUnopExp exp) {
  final exp1 = exp.exp;

  if (exp1 is LuaIntegerExp) {
    return LuaIntegerExp(line: exp.line, value: -exp1.value);
  }

  if (exp1 is LuaFloatExp) {
    if (exp1.value != 0) {
      return LuaFloatExp(line: exp.line, value: -exp1.value);
    }
  }

  return exp;
}

LuaExp optimizeNot(LuaUnopExp exp) {
  final exp1 = exp.exp;

  switch (exp1.runtimeType) {
    // false
    case LuaNilExp:
    case LuaFalseExp:
      return LuaTrueExp(line: exp.line);
    // true
    case LuaTrueExp:
    case LuaIntegerExp:
    case LuaFloatExp:
    case LuaStringExp:
      return LuaFalseExp(line: exp.line);
    default:
      return exp;
  }
}

LuaExp optimizeBnot(LuaUnopExp exp) {
  final exp1 = exp.exp;

  if (exp1 is LuaIntegerExp) {
    return LuaIntegerExp(line: exp.line, value: ~exp1.value);
  }

  if (exp1 is LuaFloatExp) {
    final i = LuaMath.float2Int(exp1.value);
    if (i != null) {
      return LuaIntegerExp(line: exp.line, value: ~i);
    }
  }

  return exp;
}

bool isFalse(LuaExp exp) {
  return exp is LuaFalseExp || exp is LuaNilExp;
}

bool isTrue(LuaExp exp) {
  return exp is LuaTrueExp ||
      exp is LuaIntegerExp ||
      exp is LuaFloatExp ||
      exp is LuaStringExp;
}

// todo
bool isVarargOrFuncCall(LuaExp exp) {
  return exp is LuaVarargExp || exp is LuaFuncCallExp;
}

int? castToInt(LuaExp exp) {
  if (exp is LuaIntegerExp) {
    return exp.value;
  }

  if (exp is LuaFloatExp) {
    return exp.value.toInt();
  }

  return null;
}

double? castToFloat(LuaExp exp) {
  if (exp is LuaIntegerExp) {
    return exp.value.toDouble();
  }

  if (exp is LuaFloatExp) {
    return exp.value;
  }

  return null;
}
