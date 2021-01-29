import 'dart:math' as math;

import 'package:luart/auxlib.dart';
import 'package:luart/src/api/lua_state.dart';

class LuaStdlibMath {
  var _rand = math.Random();

  /* pseudo-random numbers */

  // math.random ([m [, n]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.random
  // lua-5.3.4/src/lmathlib.c#math_random()
  int random(LuaState ls) {
    late final int low, up;

    switch (ls.getTop()) {
      /* check number of arguments */
      case 0: /* no arguments */
        ls.pushNumber(_rand.nextDouble()); /* Number between 0 and 1 */
        return 1;
      case 1: /* only upper limit */
        low = 1;
        up = ls.mustCheckInt(1);
        break;
      case 2: /* lower and upper limits */
        low = ls.mustCheckInt(1);
        up = ls.mustCheckInt(2);
        break;
      default:
        return ls.errorMessage('wrong number of arguments');
    }

    /* random integer in the interval [low, up] */
    if (low > up) {
      ls.argError(1, 'interval is empty');
    }

    if (up - low + 1 > (1 << 32)) {
      ls.argError(1, 'interval too large');
    }

    ls.pushInt(low + _rand.nextInt(up - low + 1));

    return 1;
  }

  // math.randomseed (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.randomseed
  // lua-5.3.4/src/lmathlib.c#math_randomseed()
  int randomSeed(LuaState ls) {
    final x = ls.mustCheckNumber(1);
    _rand = math.Random(x.toInt());
    return 0;
  }

  /* max & min */

  // math.max (x, ···)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.max
  // lua-5.3.4/src/lmathlib.c#math_max()
  int max(LuaState ls) {
    final n = ls.getTop(); /* number of arguments */
    if (n < 1) {
      ls.argError(1, 'value expected');
    }

    var imax = 1; /* index of current maximum value */
    for (var i = 2; i <= n; i++) {
      if (ls.compare(imax, i, LuaCompareOp.lt)) {
        imax = i;
      }
    }

    ls.pushValue(imax);
    return 1;
  }

  // math.min (x, ···)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.min
  // lua-5.3.4/src/lmathlib.c#math_min()
  int min(LuaState ls) {
    final n = ls.getTop(); /* number of arguments */
    if (n < 1) {
      ls.argError(1, 'value expected');
    }

    var imin = 1; /* index of current minimum value */
    for (var i = 2; i <= n; i++) {
      if (ls.compare(i, imin, LuaCompareOp.lt)) {
        imin = i;
      }
    }

    ls.pushValue(imin);
    return 1;
  }

  /* exponentiation and logarithms */

  // math.exp (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.exp
  // lua-5.3.4/src/lmathlib.c#math_exp()
  int exp(LuaState ls) {
    final x = ls.mustCheckNumber(1);
    ls.pushNumber(math.exp(x));
    return 1;
  }

  // math.log (x [, base])
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.log
  // lua-5.3.4/src/lmathlib.c#math_log()
  int log(LuaState ls) {
    final x = ls.mustCheckNumber(1);

    late final double res;

    if (ls.isNoneOrNil(2)) {
      res = math.log(x);
    } else {
      final base = ls.toNumber(2);
      res = math.log(x) / math.log(base);
    }

    ls.pushNumber(res);
    return 1;
  }

  /* trigonometric functions */

  // math.deg (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.deg
  // lua-5.3.4/src/lmathlib.c#math_deg()
  int deg(LuaState ls) {
    final x = ls.mustCheckNumber(1);
    ls.pushNumber(x * 180 / math.pi);
    return 1;
  }

  // math.rad (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.rad
  // lua-5.3.4/src/lmathlib.c#math_rad()
  int rad(LuaState ls) {
    final x = ls.mustCheckNumber(1);
    ls.pushNumber(x * math.pi / 180);
    return 1;
  }

  // math.sin (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.sin
  // lua-5.3.4/src/lmathlib.c#math_sin()
  int sin(LuaState ls) {
    final x = ls.mustCheckNumber(1);
    ls.pushNumber(math.sin(x));
    return 1;
  }

  // math.cos (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.cos
  // lua-5.3.4/src/lmathlib.c#math_cos()
  int cos(LuaState ls) {
    final x = ls.mustCheckNumber(1);
    ls.pushNumber(math.cos(x));
    return 1;
  }

  // math.tan (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.tan
  // lua-5.3.4/src/lmathlib.c#math_tan()
  int tan(LuaState ls) {
    final x = ls.mustCheckNumber(1);
    ls.pushNumber(math.tan(x));
    return 1;
  }

  // math.asin (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.asin
  // lua-5.3.4/src/lmathlib.c#math_asin()
  int asin(LuaState ls) {
    final x = ls.mustCheckNumber(1);
    ls.pushNumber(math.asin(x));
    return 1;
  }

  // math.acos (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.acos
  // lua-5.3.4/src/lmathlib.c#math_acos()
  int acos(LuaState ls) {
    final x = ls.mustCheckNumber(1);
    ls.pushNumber(math.acos(x));
    return 1;
  }

  // math.atan (y [, x])
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.atan
  // lua-5.3.4/src/lmathlib.c#math_atan()
  int atan(LuaState ls) {
    final y = ls.mustCheckNumber(1);
    final x = ls.checkNumber(2) ?? 1.0;
    ls.pushNumber(math.atan2(y, x));
    return 1;
  }

  /* rounding functions */

  // math.ceil (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.ceil
  // lua-5.3.4/src/lmathlib.c#math_ceil()
  int ceil(LuaState ls) {
    if (ls.isInt(1)) {
      ls.setTop(1); /* integer is its own ceil */
    } else {
      final x = ls.mustCheckNumber(1);
      ls.pushInt(x.ceil());
    }
    return 1;
  }

  // math.floor (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.floor
  // lua-5.3.4/src/lmathlib.c#math_floor()
  int floor(LuaState ls) {
    if (ls.isInt(1)) {
      ls.setTop(1); /* integer is its own floor */
    } else {
      final x = ls.mustCheckNumber(1);
      ls.pushInt(x.floor());
    }
    return 1;
  }

  /* others */

  // math.fmod (x, y)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.fmod
  // lua-5.3.4/src/lmathlib.c#math_fmod()
  int fmod(LuaState ls) {
    if (ls.isInt(1) && ls.isInt(2)) {
      final d = ls.toInt(2);
      if (d + 1 <= 1) {
        /* special cases: -1 or 0 */
        if (d == 0) {
          ls.argError(2, 'zero');
        }
        ls.pushInt(0); /* avoid overflow with 0x80000... / -1 */
      } else {
        ls.pushInt(ls.toInt(1) % d);
      }
    } else {
      final x = ls.mustCheckNumber(1);
      final y = ls.mustCheckNumber(2);
      ls.pushNumber(x - (x ~/ y) * y);
    }

    return 1;
  }

  // math.modf (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.modf
  // lua-5.3.4/src/lmathlib.c#math_modf()
  int modf(LuaState ls) {
    if (ls.isInt(1)) {
      ls.setTop(1); /* number is its own integer part */
      ls.pushNumber(0); /* no fractional part */
    } else {
      final x = ls.mustCheckNumber(1);
      ls.pushInt(x.truncate());
      if (x.isInfinite) {
        ls.pushNumber(0);
      } else {
        ls.pushNumber(x - x.truncate());
      }
    }

    return 2;
  }

  // math.abs (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.abs
  // lua-5.3.4/src/lmathlib.c#math_abs()
  int abs(LuaState ls) {
    if (ls.isInt(1)) {
      final x = ls.toInt(1);
      if (x < 0) {
        ls.pushInt(-x);
      }
    } else {
      final x = ls.mustCheckNumber(1);
      ls.pushNumber(x.abs());
    }
    return 1;
  }

  // math.sqrt (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.sqrt
  // lua-5.3.4/src/lmathlib.c#math_sqrt()
  int sqrt(LuaState ls) {
    final x = ls.mustCheckNumber(1);
    ls.pushNumber(math.sqrt(x));
    return 1;
  }

  // math.ult (m, n)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.ult
  // lua-5.3.4/src/lmathlib.c#math_ult()
  int ult(LuaState ls) {
    final m = ls.mustCheckInt(1);
    final n = ls.mustCheckInt(2);
    // is this ok?
    ls.pushBool(m.toUnsigned(m.bitLength) < n.toUnsigned(n.bitLength));
    return 1;
  }

  // math.tointeger (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.tointeger
  // lua-5.3.4/src/lmathlib.c#math_toint()
  int toInteger(LuaState ls) {
    try {
      final i = ls.toInt(1);
      ls.pushInt(i);
    } catch (e) {
      ls.checkAny(1);
      ls.pushNil(); /* value is not convertible to integer */
    }
    return 1;
  }

  // math.type (x)
  // http://www.lua.org/manual/5.3/manual.html#pdf-math.type
  // lua-5.3.4/src/lmathlib.c#math_type()
  int type(LuaState ls) {
    if (ls.type(1) == LuaType.number) {
      if (ls.isInt(1)) {
        ls.pushString('integer');
      } else {
        ls.pushString('float');
      }
    } else {
      ls.checkAny(1);
      ls.pushNil();
    }
    return 1;
  }
}

int openMathLib(LuaState ls) {
  final mathlib = LuaStdlibMath();
  final funcs = <String, LuaDartFunction>{
    'random': mathlib.random,
    'randomseed': mathlib.randomSeed,
    'max': mathlib.max,
    'min': mathlib.min,
    'exp': mathlib.exp,
    'log': mathlib.log,
    'deg': mathlib.deg,
    'rad': mathlib.rad,
    'sin': mathlib.sin,
    'cos': mathlib.cos,
    'tan': mathlib.tan,
    'asin': mathlib.asin,
    'acos': mathlib.acos,
    'atan': mathlib.atan,
    'ceil': mathlib.ceil,
    'floor': mathlib.floor,
    'fmod': mathlib.fmod,
    'modf': mathlib.modf,
    'abs': mathlib.abs,
    'sqrt': mathlib.sqrt,
    'ult': mathlib.ult,
    'tointeger': mathlib.toInteger,
    'type': mathlib.type,
    /* placeholders */
    // "pi":         nil,
    // "huge":       nil,
    // "maxinteger": nil,
    // "mininteger": nil,
  };

  // From https://github.com/dart-lang/sdk/issues/41717
  final minInt =
      (double.infinity is int) ? -double.infinity as int : (-1 << 63);
  final maxInt = (double.infinity is int) ? double.infinity as int : ~minInt;

  ls.newLib(funcs);
  ls.pushNumber(math.pi);
  ls.setField(-2, 'pi');
  ls.pushNumber(double.infinity);
  ls.setField(-2, 'huge');
  ls.pushInt(maxInt);
  ls.setField(-2, 'maxinteger');
  ls.pushInt(minInt);
  ls.setField(-2, 'mininteger');

  return 1;
}
