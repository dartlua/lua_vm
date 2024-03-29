import 'dart:math' as math;

import 'package:luart/luart.dart';
import 'package:luart/src/state/lua_math.dart';
import 'package:luart/src/state/lua_value.dart';

int iadd(int a, int b) => a + b;

double fadd(double a, double b) => a + b;

int isub(int a, int b) => a - b;

double fsub(double a, double b) => a - b;

int imul(int a, int b) => a * b;

double fmul(double a, double b) => a * b;

int imod(int a, int b) => LuaMath.iMod(a, b);

double fmod(double a, double b) => LuaMath.fMod(a, b);

double pow(double a, double n) => math.pow(a, n) as double;

double div(double a, double b) => a / b;

int iidiv(int a, int b) => LuaMath.iFloorDiv(a, b);

double fidiv(double a, double b) => LuaMath.fFloorDiv(a, b);

int band(int a, int b) => a & b;

int bor(int a, int b) => a | b;

int bxor(int a, int b) => a ^ b;

int bnot(int a, int _) => -(a + 1);

int shl(int a, int n) => LuaMath.shiftLeft(a, n);

int shr(int a, int n) => LuaMath.shiftRight(a, n);

int iunm(int a, int _) => -a;

double funm(double a, double _) => -a;

class Operator {
  final String metaMethod;
  final int Function(int, int)? intFunc;
  final double Function(double, double)? floatFunc;

  const Operator(this.metaMethod, this.intFunc, this.floatFunc);
}

const operators = [
  Operator('__add', iadd, fadd),
  Operator('__sub', isub, fsub),
  Operator('__mul', imul, fmul),
  Operator('__mod', imod, fmod),
  Operator('__pow', null, pow),
  Operator('__div', null, div),
  Operator('__idiv', iidiv, fidiv),
  Operator('__band', band, null),
  Operator('__bor', bor, null),
  Operator('__bxor', bxor, null),
  Operator('__shl', shl, null),
  Operator('__shr', shr, null),
  Operator('__unm', iunm, funm),
  Operator('__bnot', bnot, null)
];

mixin LuaStateArith implements LuaState {
  @override
  void arith(LuaArithOp op) {
    Object? a;
    final b = stack!.pop();
    if (op != LuaArithOp.unm && op != LuaArithOp.bnot) {
      a = stack!.pop();
    } else {
      a = b;
    }

    final operator = operators[op.index];
    final result = _arith(a, b, operator);
    if (result != null) {
      stack!.push(result);
      return;
    }

    final metaMethod = operator.metaMethod;
    final val = callMetaMethod(a, b, metaMethod, this);
    if (val.success) {
      stack!.push(val);
      return;
    }

    throw LuaArithmeticError();
  }
}

num? _arith(Object? a, Object? b, Operator op) {
  if (op.floatFunc == null) {
    final x = convert2Int(a);
    final y = convert2Int(b);
    if (x.success && y.success) return op.intFunc!(x.result, y.result);
  } else {
    if (op.intFunc != null) {
      final x = convert2Int(a);
      final y = convert2Int(b);
      if (x.success && y.success) return op.intFunc!(x.result, y.result);
    }
  }

  final x = convert2Float(a);
  final y = convert2Float(b);
  if (x.success && y.success) return op.floatFunc!(x.result, y.result);
  return null;
}
