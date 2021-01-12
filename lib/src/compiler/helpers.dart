import 'package:luart/luart.dart';
import 'package:luart/src/compiler/ast/lua_exp.dart';

bool isVarargOrFuncCall(LuaExp exp) {
  return exp is LuaVarargExp || exp is LuaFuncCallExp;
}

List<LuaExp>? removeTailNils(List<LuaExp> exps) {
  for (var n = exps.length - 1; n >= 0; n--) {
    if (exps[n] is! LuaNilExp) {
      return exps.sublist(0, n + 1);
    }
  }
  return null;
}

int lineOf(LuaExp exp) {
  if (exp is LuaNilExp) {
    return exp.line;
  } else if (exp is LuaTrueExp) {
    return exp.line;
  } else if (exp is LuaFalseExp) {
    return exp.line;
  } else if (exp is LuaIntegerExp) {
    return exp.line;
  } else if (exp is LuaFloatExp) {
    return exp.line;
  } else if (exp is LuaStringExp) {
    return exp.line;
  } else if (exp is LuaVarargExp) {
    return exp.line;
  } else if (exp is LuaNameExp) {
    return exp.line;
  } else if (exp is LuaFuncDefExp) {
    return exp.line;
  } else if (exp is LuaFuncCallExp) {
    return exp.line;
  } else if (exp is LuaTableConstructorExp) {
    return exp.line;
  } else if (exp is LuaUnopExp) {
    return exp.line;
  } else if (exp is LuaTableAccessExp) {
    return lineOf(exp.prefixExp);
  } else if (exp is LuaConcatExp) {
    return lineOf(exp.exps[0]);
  } else if (exp is LuaBinopExp) {
    return lineOf(exp.exp1);
  }
  throw LuaCompilerError('unreachable!');
}

int lastLineOf(LuaExp exp) {
  if (exp is LuaNilExp) {
    return exp.line;
  } else if (exp is LuaTrueExp) {
    return exp.line;
  } else if (exp is LuaFalseExp) {
    return exp.line;
  } else if (exp is LuaIntegerExp) {
    return exp.line;
  } else if (exp is LuaFloatExp) {
    return exp.line;
  } else if (exp is LuaStringExp) {
    return exp.line;
  } else if (exp is LuaVarargExp) {
    return exp.line;
  } else if (exp is LuaNameExp) {
    return exp.line;
  } else if (exp is LuaFuncDefExp) {
    return exp.lastLine;
  } else if (exp is LuaFuncCallExp) {
    return exp.lastLine;
  } else if (exp is LuaTableConstructorExp) {
    return exp.lastLine;
  } else if (exp is LuaTableAccessExp) {
    return exp.lastLine;
  } else if (exp is LuaConcatExp) {
    return lastLineOf(exp.exps[exp.exps.length - 1]);
  } else if (exp is LuaBinopExp) {
    return lastLineOf(exp.exp2);
  } else if (exp is LuaUnopExp) {
    return lastLineOf(exp.exp);
  }
  throw LuaCompilerError('unreachable!');
}
