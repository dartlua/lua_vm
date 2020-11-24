import 'math.dart';
import 'dart:math' as math;

enum ArithOp {
  add,
  sub,
  mul,
  mod,
  pow,
  div,
  idiv,
  band,
  bor,
  bxor,
  shl,
  shr,
  unm,
  bnot,
}

class CompareOp {
  int compareOp;

  CompareOp(int this.compareOp);
}

int iadd(int a, int b) => a + b;

double fadd(double a, double b) => a + b;

int isub(int a, int b) => a - b;

double fsub(double a, double b) => a - b;

int imul(int a, int b) => a * b;

double fmul(double a, double b) => a * b;

int imod(int a, int b) => IMod(a, b);

double fmod(double a, double b) => FMod(a, b);

double pow(double a, double n) => math.pow(a, n) as double;

double div(double a, double b) => a / b;

int iidiv(int a, int b) => IFloorDiv(a, b);

double fidiv(double a, double b) => FFloorDiv(a, b);

int band(int a, int b) => a & b;

int bor(int a, int b) => a | b;

int bxor(int a, int b) => a ^ b;

int bnot(int a, int _) => -(a + 1);

int shl(int a, int n) => shiftLeft(a, n);

int shr(int a, int n) => shiftRight(a, n);

int iunm(int a, int _) => -a;

double funm(double a, double _) => -a;
