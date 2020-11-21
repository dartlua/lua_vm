import 'dart:typed_data';

import '../binary/chunk.dart';
import '../constants.dart';
import '../operation/arith.dart';
import '../operation/operator.dart';
import '../operation/compare.dart';
import '../vm/instruction.dart';
import '../vm/vm.dart';
import 'closure.dart';
import 'stack.dart';
import 'table.dart';
import 'value.dart';

class LuaState {
  LuaStack? stack;
  LuaTable? registry;

  LuaState({this.stack, this.registry});

  int getTop() => stack!.top;

  int fetch() {
    int i = stack!.closure!.proto!.codes[stack!.pc];
    stack!.addPC(1);
    return i;
  }

  void getConst(int idx) =>
      stack!.push(LuaValue(stack!.closure!.proto!.constants[idx]));

  void getRK(int rk) => rk > 0xff ? getConst(rk & 0xff) : pushValue(rk + 1);

  int absIndex(int idx) => stack!.absIndex(idx);

  bool checkStack(int n) {
    stack!.check(n);
    return true;
  }

  void pop(int n) => setTop(-n - 1);

  void copy(int fromIdx, int toIdx) => stack!.set(toIdx, stack!.get(fromIdx));

  void pushValue(int idx) => stack!.push(stack!.get(idx));

  void replace(int idx) => stack!.set(idx, stack!.pop());

  void insert(int idx) => rotate(idx, 1);

  void remove(int idx) {
    rotate(idx, -1);
    pop(1);
  }

  void rotate(int idx, int n) {
    int t = stack!.top - 1;
    int p = stack!.absIndex(idx) - 1;
    int m;
    if (n >= 0) {
      m = t - n;
    } else {
      m = p - n - 1;
    }
    stack!.reverse(p, m);
    stack!.reverse(m + 1, t);
    stack!.reverse(p, t);
  }

  void setTop(int idx) {
    int newTop = stack!.absIndex(idx);
    if (newTop < 0) throw StackUnderflowError();
    int n = stack!.top - newTop;
    if (n > 0)
      for (int i = 0; i < n; i++) stack!.pop();
    else if (n < 0) for (int i = 0; i > n; i--) pushNull();
  }

  String typeName(LuaType luaType) {
    switch (luaType) {
      case LuaType.none:
        return 'no value';
      case LuaType.nil:
        return 'nil';
      case LuaType.boolean:
        return 'boolean';
      case LuaType.number:
        return 'number';
      case LuaType.string:
        return 'string';
      case LuaType.table:
        return 'table';
      case LuaType.function:
        return 'function';
      case LuaType.thread:
        return 'thread';
      default:
        return 'userdata';
    }
  }

  LuaType type(int idx) {
    if (stack!.isValid(idx)) {
      LuaValue? val = stack!.get(idx);
      return typeOf(val);
    }
    return LuaType.none;
  }

  bool isNone(int idx) => type(idx) == LuaType.none;
  bool isNull(int idx) => type(idx) == LuaType.nil;
  bool isNoneOrNull(int idx) => type(idx).index <= LuaType.nil.index;
  bool isBool(int idx) => type(idx) == LuaType.boolean;
  bool isInt(int idx) => stack!.get(idx)!.luaValue is int;
  bool isNumber(int idx) => stack!.get(idx)!.luaValue is double;
  bool isString(int idx) =>
      type(idx) == LuaType.string || type(idx) == LuaType.number;

  bool toBool(int idx) => convert2Boolean(stack!.get(idx)!);

  int toInt(int idx) => convert2Int(stack!.get(idx)!);

  double toNumber(int idx) => convert2Float(stack!.get(idx)!);

  String toStr(int idx) => convert2String(stack!.get(idx)!);

  void pushNull() => stack!.push(LuaValue(null));
  void pushBool(bool b) => stack!.push(LuaValue(b));
  void pushInt(int i) => stack!.push(LuaValue(i));
  void pushNumber(double d) => stack!.push(LuaValue(d));
  void pushString(String s) => stack!.push(LuaValue(s));

  void arith(ArithOp op) {
    LuaValue? a;
    LuaValue? b;
    b = stack!.pop();
    if (op != ArithOp.unm && op != ArithOp.bnot) {
      a = stack!.pop();
    } else {
      a = b;
    }

    Operator operator = operators[op.index];
    LuaValue result = _arith(a, b, operator);
    if (result.luaValue != null) {
      stack!.push(result);
      return;
    }

    String metaMethod = operator.metaMethod;
    LuaValue val = callMetaMethod(a!, b, metaMethod, nowLuaState())!;
    if (val.luaValue != null) {
      stack!.push(val);
      return;
    }

    throw UnsupportedError('Unsupported arith');
  }

  bool compare(int idx1, int idx2, CompareOp op) {
    if (!stack!.isValid(idx1) || !stack!.isValid(idx2)) return false;
    LuaValue? a = stack!.get(idx1);
    LuaValue? b = stack!.get(idx2);
    LuaState ls = nowLuaState();
    switch (op.compareOp) {
      case LUA_OPEQ:
        return eq_(a!, b!, ls);
      case LUA_OPLT:
        return lt_(a!, b!, ls);
      case LUA_OPLE:
        return le_(a!, b!, ls);
      default:
        throw UnsupportedError('Unsupported Compare Operation');
    }
  }

  void len(int idx) {
    LuaValue val = stack!.get(idx)!;
    dynamic value = val.luaValue;
    if (value == null) {
      throw TypeError();
    }
    if (value is bool) {
      throw TypeError();
    }
    if (value is String) {
      stack!.push(LuaValue(value.length));
      return;
    }
    LuaValue result = callMetaMethod(val, val, '__len', nowLuaState())!;
    if (result.luaValue != null) {
      stack!.push(result);
      return;
    }
    if (value is LuaTable) {
      if (value.list != null) {
        int count = 0;
        for (int i = 0; i < value.list.length; i++)
          if (value.list[i]!.value != null) count++;
        stack!.push(LuaValue(count));
        return;
      }
    }

    throw Exception('get length error');
  }

  void concat(int n) {
    if (n == 0)
      stack!.push(LuaValue(''));
    else if (n >= 2) {
      for (int i = 1; i < n; i++) {
        if (isString(-1) && isString(-2)) {
          String s2 = toStr(-1);
          String s1 = toStr(-2);
          stack!.pop();
          stack!.pop();
          stack!.push(LuaValue(s1 + s2));
          continue;
        }

        LuaValue? b = stack!.pop();
        LuaValue a = stack!.pop()!;
        LuaValue result = callMetaMethod(a, b, '__concat', nowLuaState())!;
        if (result.luaValue != null) {
          stack!.push(result);
          continue;
        }

        throw Exception('concat error');
      }
    }
  }

  void createTable(int nArr, int nRec) {
    stack!.push(LuaValue(newLuaTable(nArr, nRec)));
  }

  void newTable() {
    createTable(0, 0);
  }

  LuaType getTable(int idx) {
    LuaValue t = stack!.get(idx)!;
    LuaValue? k = stack!.pop();
    return _getTable(t, k, false);
  }

  LuaType _getTable(LuaValue t, LuaValue? k, bool raw) {
    dynamic value = t.luaValue;
    if (value is LuaTable) {
      LuaValue v = value.get(k!);
      if (raw || v.luaValue != null || !value.hasMetaField('__index')) {
        stack!.push(v);
        return typeOf(v);
      }
    }
    if (!raw) {
      LuaValue metaField = getMetaField(t, '__index', nowLuaState());
      dynamic x = metaField.luaValue;
      if (x != null) {
        if (x is LuaTable) return _getTable(metaField, k, false);
        if (x is Closure) {
          stack!.push(metaField);
          stack!.push(t);
          stack!.push(k);
          call(2, 1);
          return typeOf(stack!.get(-1));
        }
      }
    }
    throw TypeError();
  }

  LuaType getField(int idx, String k) {
    LuaValue t = stack!.get(idx)!;
    return _getTable(t, LuaValue(k), false);
  }

  LuaType getI(int idx, int i) {
    LuaValue t = stack!.get(idx)!;
    return _getTable(t, LuaValue(i), false);
  }

  void setTable(int idx) {
    LuaValue t = stack!.get(idx)!;
    LuaValue? v = stack!.pop();
    LuaValue? k = stack!.pop();
    _setTable(t, k, v, false);
  }

  void _setTable(LuaValue t, LuaValue? k, LuaValue? v, bool raw) {
    dynamic table = t.luaValue;
    if (table is LuaTable) {
      if (raw ||
          table.get(k!).luaValue != null ||
          !table.hasMetaField('__newindex')) {
        table.put(k!, v);
        return;
      }
    }

    if (!raw) {
      LuaValue mf = getMetaField(t, '__newindex', nowLuaState());
      dynamic x = mf.luaValue;
      if (x is LuaTable) {
        _setTable(mf, k, v, false);
        return;
      }
      if (x is Closure) {
        stack!.push(mf);
        stack!.push(t);
        stack!.push(k);
        stack!.push(v);
        call(3, 0);
        return;
      }
    }
    throw TypeError();
  }

  void setField(int idx, String k) {
    LuaValue t = stack!.get(idx)!;
    LuaValue? v = stack!.pop();
    _setTable(t, LuaValue(k), v, false);
  }

  void setI(int idx, int i) {
    LuaValue t = stack!.get(idx)!;
    LuaValue? v = stack!.pop();
    _setTable(t, LuaValue(i), v, false);
  }

  void pushLuaStack(LuaStack newStack) {
    newStack.prev = stack;
    stack = newStack;
  }

  void popLuaStack() {
    var _stack = stack;
    stack = _stack!.prev!;
    _stack.prev = null;
  }

  int load(Uint8List chunk, String chunkName, String mode) {
    final proto = unDump(chunk);
    final c = Closure.fromLuaProto(proto);
    stack!.push(LuaValue(c));
    if (proto.upvalues.length > 0) {
      LuaValue env = registry!.get(LuaValue(LUA_RIDX_GLOBALS));
      if (c.upValues.isEmpty) c.upValues.add(null);
      c.upValues[0] = UpValue(env);
    }
    return 0;
  }

  void call(int nArgs, int nResults) {
    LuaValue val = stack!.get(-(nArgs + 1))!;
    dynamic value = val.luaValue;
    if (value is Closure) {
      if (value.proto != null) {
        callLuaClosure(nArgs, nResults, value);
      } else {
        callDartClosure(nArgs, nResults, value);
      }
    } else {
      LuaValue mf = getMetaField(val, '__call', nowLuaState());
      if (mf.luaValue is Closure) {
        stack!.push(val);
        insert(-(nArgs + 2));
        nArgs++;
      }
    }
    ;
  }

  void callLuaClosure(int nArgs, int nResults, Closure c) {
    int nRegs = c.proto!.maxStackSize;
    int nParams = c.proto!.numParams;
    bool isVararg = c.proto!.isVararg == 1;

    LuaStack newStack = newLuaStack(nRegs + 20, stack!.state);
    newStack.closure = c;

    List<LuaValue?> funcAndArgs = stack!.popN(nArgs + 1);
    newStack.pushN(funcAndArgs.sublist(1), nParams);
    newStack.top = nRegs;
    if (nArgs > nParams && isVararg)
      newStack.varargs = funcAndArgs.sublist(nParams + 1);

    pushLuaStack(newStack);
    runLuaClosure();
    popLuaStack();

    if (nResults != 0) {
      List<LuaValue?> results = newStack.popN(newStack.top - nRegs);
      stack!.check(results.length);
      stack!.pushN(results, nResults);
    }
  }

  void callDartClosure(int nArgs, int nResults, Closure c) {
    LuaStack newStack = newLuaStack(nArgs + 20, stack!.state);
    newStack.closure = c;

    List<LuaValue?> args = stack!.popN(nArgs);
    newStack.pushN(args, nArgs);
    stack!.pop();

    pushLuaStack(newStack);
    int? r = c.dartFunc!(LuaState(stack: stack));
    popLuaStack();

    if (nResults != 0) {
      List<LuaValue?> results = newStack.popN(r!);
      stack!.check(results.length);
      stack!.pushN(results, nResults);
    }
  }

  void runLuaClosure() {
    while (true) {
      final instruction = fetch();
      instruction.execute(LuaVM(LuaState(stack: stack)));
      if (instruction.opCode == OP_RETURN) break;
    }
  }

  int registerCount() => stack!.closure!.proto!.maxStackSize;

  void loadVararg(int n) {
    if (n < 0) n = stack!.varargs.length;
    stack!.check(n);
    stack!.pushN(stack!.varargs, n);
  }

  void loadProto(int idx) {
    Prototype subProto = stack!.closure!.proto!.protos[idx];
    Closure c = Closure.fromLuaProto(subProto);
    stack!.push(LuaValue(c));

    int i = 0;
    for (Upvalue val in subProto.upvalues) {
      int uvIndex = val.idx;
      if (val.inStack == 1) {
        if (stack!.openUVs == null) stack!.openUVs = Map<int, UpValue?>();

        if (i == 0 && c.upValues.isEmpty)
          c.upValues.add(UpValue(stack!.slots[uvIndex]));
        else
          c.upValues[i] = stack!.openUVs![uvIndex];

        if (!stack!.openUVs!.containsKey(uvIndex))
          stack!.openUVs![uvIndex] = c.upValues[i];
      } else {
        if (i == 0 && c.upValues.isEmpty)
          c.upValues.add(stack!.closure!.upValues[uvIndex]);
        else
          c.upValues[i] = stack!.closure!.upValues[uvIndex];
      }
      i++;
    }
  }

  void pushDartFunc(Function dartFunc) =>
      stack!.push(LuaValue(Closure.fromDartFunction(dartFunc, 0)));

  bool isDartFunc(int idx) {
    LuaValue val = stack!.get(idx)!;
    if (val.luaValue is Closure) return val.luaValue.dartFunc != null;
    return false;
  }

  DartFunc? toDartFunc(int idx) {
    LuaValue val = stack!.get(idx)!;
    if (val.luaValue is Closure) return val.luaValue.dartFunc;
    return null;
  }

  void pushGlobalTable() => getI(LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);

  LuaType getGlobal(String name) => _getTable(
      registry!.get(LuaValue(LUA_RIDX_GLOBALS)), LuaValue(name), false);

  void setGlobal(String name) {
    LuaValue t = registry!.get(LuaValue(LUA_RIDX_GLOBALS));
    LuaValue? v = stack!.pop();
    _setTable(t, LuaValue(name), v, false);
  }

  void register(String name, Function dartFunc) {
    pushDartFunc(dartFunc);
    setGlobal(name);
  }

  void pushDartClosure(Function f, int n) {
    final closure = Closure.fromDartFunction(f, n);
    for (var i = n; i > 0; i--) {
      closure.upValues[n - 1] = UpValue(stack!.pop());
    }
    stack!.push(LuaValue(closure));
  }

  void closeClosure(int a) {
    stack!.openUVs!.forEach((key, value) {
      if (key >= a - 1) stack!.openUVs!.remove(key);
    });
  }

  LuaState nowLuaState() => LuaState(stack: stack, registry: registry);

  bool getMetaTable_(int idx) {
    LuaValue val = stack!.get(idx)!;
    LuaTable? mt = getMetaTable(val, nowLuaState());
    if (mt != null) {
      stack!.push(LuaValue(mt));
      return true;
    }
    return false;
  }

  void setMetaTable_(int idx) {
    LuaValue? val = stack!.get(idx);
    LuaValue mtVal = stack!.pop()!;
    if (mtVal.luaValue == null)
      setMetaTable(val!, null, nowLuaState());
    else if (mtVal.luaValue is LuaTable)
      setMetaTable(val!, mtVal.luaValue, nowLuaState());
    else
      throw TypeError();
  }
}

LuaValue _arith(LuaValue? a, LuaValue? b, Operator op) {
  if (op.floatFunc == null) {
    return LuaValue(op.intFunc!(convert2Int(a!), convert2Int(b!)));
  }
  if (op.intFunc != null) {
    return LuaValue(op.intFunc!(convert2Int(a!), convert2Int(b!)));
  }
  return LuaValue(op.floatFunc!(convert2Float(a!), convert2Float(b!)));
}

LuaState newLuaState() {
  LuaTable registry = newLuaTable(0, 0);
  registry.put(LuaValue(LUA_RIDX_GLOBALS), LuaValue(newLuaTable(0, 0)));
  LuaState ls = LuaState(registry: registry);
  ls.pushLuaStack(newLuaStack(LUA_MINSTACK, ls));
  return ls;
}

int luaUpvalueIndex(int i) => LUA_REGISTRYINDEX - i;
