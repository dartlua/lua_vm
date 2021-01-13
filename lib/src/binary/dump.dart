import 'dart:io';

import 'package:luart/src/binary/chunk.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/vm/instruction.dart';

void _write(Object? object) {
  stdout.write(object);
}

void _writeln(Object? object) {
  stdout.writeln(object);
}

void dump(LuaPrototype f) {
  printHeader(f);
  printCode(f);
  printDetail(f);
  for (var proto in f.protos) {
    dump(proto);
  }
}

void printHeader(LuaPrototype f) {
  var funcType = 'main';
  if (f.lineDefined > 0) {
    funcType = 'function';
  }

  final isVararg = f.isVararg;
  var varargFlag = '';
  if (isVararg != null && isVararg > 0) {
    varargFlag = '+';
  }

  _writeln('\n$funcType '
      '<${f.source}:${f.lineDefined},${f.lastLineDefined}> '
      '(${f.codes.length} instructions)');

  _writeln('${f.numParams}$varargFlag params, '
      '${f.maxStackSize} slots, '
      '${f.upvalues.length} upvalues, '
      '${f.locVars.length} locals, '
      '${f.constants.length} constants, '
      '${f.protos.length} functions');
}

void printCode(LuaPrototype f) {
  var pc = 0;
  for (var c in f.codes) {
    var line = '-';
    if (f.lineInfo.isNotEmpty) {
      line = f.lineInfo[pc].toString();
    }
    _write('    ${++pc}'.padRight(8));
    _write('    [$line]'.padRight(8));
    _write('    ${c.opName()}'.padRight(20));
    printOperands(c);
    _writeln('');
  }
}

void printOperands(int c) {
  switch (c.opMode()) {
    case IABC:
      final i = c.abc();

      _write(i.a);
      if (c.bMode() != OpArgN) {
        if (i.b > 0xFF) {
          _write(' ${-1 - (i.b & 0xFF)}');
        } else {
          _write(' ${i.b}');
        }
      }
      if (c.cMode() != OpArgN) {
        if (i.c > 0xFF) {
          _write(' ${-1 - (i.c & 0xFF)}');
        } else {
          _write(' ${i.c}');
        }
      }
      break;
    case IABx:
      final i = c.abx();

      _write(i.a);
      if (c.bMode() == OpArgK) {
        _write(' ${-1 - i.b}');
      } else if (c.bMode() == OpArgU) {
        _write(' ${i.b}');
      }
      break;
    case IAsBx:
      final i = c.asbx();
      _write('${i.a} ${i.b}');
      break;
    case IAx:
      final ax = c.ax();
      _write(-1 - ax);
      break;
  }
}

void printDetail(LuaPrototype f) {
  _writeln('constants (${f.constants.length}):');
  var i = 1;
  for (var k in f.constants) {
    _writeln('\t$i\t${constantToString(k)}');
    i++;
  }

  _writeln('locals (${f.locVars.length}):');
  i = 0;
  for (var l in f.locVars) {
    _writeln('\t$i\t${l.varName}\t${l.startPC + 1}\t${l.endPC + 1}');
    i++;
  }

  _writeln('upvalues (${f.upvalues.length}):');
  i = 0;
  for (var u in f.upvalues) {
    _writeln('\t$i\t${upvalName(f, i)}\t${u.inStack}\t${u.idx}');
    i++;
  }
}

String constantToString(Object k) {
  switch (k.runtimeType) {
    case Null:
      return 'nil';
    case bool:
    case double:
    case int:
      return k.toString();
    case String:
      return '"$k"';
    default:
      return '?';
  }
}

String upvalName(LuaPrototype f, int idx) {
  if (f.upvalueNames.isNotEmpty) {
    return f.upvalueNames[idx];
  }
  return '-';
}
