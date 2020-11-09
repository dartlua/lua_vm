import 'arith.dart';

class Operator{
  Function intFunc;
  Function floatFunc;
  Operator(Function this.intFunc, Function this.floatFunc);
}

List<Operator> operators = [
  Operator(iadd, fadd),
  Operator(isub, fsub),
  Operator(imul, fmul),
  Operator(imod, fmod),
  Operator(null, pow),
  Operator(null, div),
  Operator(iidiv, fidiv),
  Operator(band, null),
  Operator(bor, null),
  Operator(bxor, null),
  Operator(shl, null),
  Operator(shr, null),
  Operator(iunm, funm),
  Operator(bnot, null)
];