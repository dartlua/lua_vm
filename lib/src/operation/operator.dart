import 'arith.dart';

class Operator {
  String metaMethod;
  Function? intFunc;
  Function? floatFunc;

  Operator(this.metaMethod, this.intFunc, this.floatFunc);
}

List<Operator> operators = [
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
