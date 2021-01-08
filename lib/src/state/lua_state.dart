import 'dart:typed_data';

import 'package:lua_vm/lua_vm.dart';
import 'package:lua_vm/src/api/lua_vm.dart';
import 'package:lua_vm/src/state/state_arith.dart';
import 'package:lua_vm/src/state/state_access.dart';
import 'package:lua_vm/src/state/state_compare.dart';
import 'package:lua_vm/src/state/state_get.dart';
import 'package:lua_vm/src/state/state_misc.dart';
import 'package:lua_vm/src/state/state_push.dart';
import 'package:lua_vm/src/state/state_set.dart';
import 'package:lua_vm/src/state/state_stack.dart';
import 'package:lua_vm/src/state/state_vm.dart';

import '../binary/chunk.dart';
import '../constants.dart';
import '../vm/instruction.dart';
import 'lua_closure.dart';
import 'lua_stack.dart';
import 'lua_table.dart';
import 'lua_value.dart';

class LuaStateImpl
    with
        LuaStateVm,
        LuaStateArith,
        LuaStateAccess,
        LuaStateCompare,
        LuaStateGet,
        LuaStateMisc,
        LuaStateStack,
        LuaStateSet,
        LuaStatePush
    implements LuaState, LuaVM {
  @override
  late LuaStack stack;

  @override
  late LuaTable registry;

  LuaStateImpl() {
    registry = newLuaTable(0, 0);
    registry.put(LUA_RIDX_GLOBALS, newLuaTable(0, 0));
    stack = LuaStack(LUA_MINSTACK, this);
    // pushLuaStack(LuaStack(LUA_MINSTACK, this));
  }

  @override
  void setMetatable(int idx) {
    final val = stack.get(idx);
    final mtVal = stack.pop();
    if (mtVal == null) {
      setMetatableFor(val!, null, this);
    } else if (mtVal is LuaTable) {
      setMetatableFor(val!, mtVal, this);
    } else {
      throw TypeError();
    }
  }

  void pushLuaStack(LuaStack newStack) {
    newStack.prev = stack;
    stack = newStack;
  }

  void popLuaStack() {
    final oldStack = stack;
    stack = oldStack.prev!;
    oldStack.prev = null;
  }

  @override
  int registerCount() => stack.closure!.proto!.maxStackSize;

  @override
  void loadVararg(int n) {
    if (n < 0) n = stack.varargs.length;
    stack.check(n);
    stack.pushN(stack.varargs, n);
  }

  @override
  void loadProto(int idx) {
    final subProto = stack.closure!.proto!.protos[idx];
    final c = LuaClosure.fromLuaProto(subProto);
    stack.push(c);

    var i = 0;
    for (var val in subProto.upvalues) {
      final uvIndex = val.idx;
      if (val.inStack == 1) {
        stack.openUVs ??= <int, LuaUpValue?>{};

        if (i == 0 && c.upValues.isEmpty) {
          c.upValues.add(LuaUpValue(stack.slots[uvIndex]));
        } else {
          c.upValues[i] = stack.openUVs![uvIndex];
        }

        if (!stack.openUVs!.containsKey(uvIndex)) {
          stack.openUVs![uvIndex] = c.upValues[i];
        }
      } else {
        if (i == 0 && c.upValues.isEmpty) {
          c.upValues.add(stack.closure!.upValues[uvIndex]);
        } else {
          c.upValues[i] = stack.closure!.upValues[uvIndex];
        }
      }
      i++;
    }
  }

  @override
  bool isFunction(int idx) {
    final val = stack.get(idx)!;
    return val is LuaClosure;
  }

  @override
  bool isDartFunctiontion(int idx) {
    final val = stack.get(idx)!;
    if (val is LuaClosure) return val.dartFunc != null;
    return false;
  }

  @override
  DartFunction? toDartFunctiontion(int idx) {
    final val = stack.get(idx)!;
    if (val is LuaClosure) return val.dartFunc;
    return null;
  }

  @override
  void pushGlobalTable() => getI(LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);

  @override
  void register(String name, DartFunction dartFunc) {
    pushDartFunction(dartFunc);
    setGlobal(name);
  }

  @override
  void pushDartClosure(DartFunction f, int n) {
    final closure = LuaClosure.fromDartFunctiontion(f, n);
    for (var i = n; i > 0; i--) {
      closure.upValues[n - 1] = LuaUpValue(stack.pop());
    }
    stack.push(closure);
  }

  @override
  void closeClosure(int a) {
    stack.openUVs!.forEach((key, value) {
      if (key >= a - 1) stack.openUVs!.remove(key);
    });
  }

  int rawLen(int idx) {
    final val = stack.get(idx)!;
    final x = val;
    if (x is String) return x.length;
    if (x is LuaTable) return x.len();
    return 0;
  }

  @override
  void load(Uint8List chunk, String chunkName, String mode) {
    final proto = unDump(chunk);
    final c = LuaClosure.fromLuaProto(proto);
    stack.push(c);
    if (proto.upvalues.isNotEmpty) {
      final env = registry.get(LUA_RIDX_GLOBALS);
      if (c.upValues.isEmpty) c.upValues.add(null);
      c.upValues[0] = LuaUpValue(env);
    }
  }

  @override
  void call(int nArgs, int nResults) {
    final value = stack.get(-(nArgs + 1))!;
    if (value is LuaClosure) {
      if (value.proto != null) {
        callLuaClosure(nArgs, nResults, value);
      } else {
        callDartClosure(nArgs, nResults, value);
      }
    } else {
      final mf = getMetafield(value, '__call', this);
      if (mf is LuaClosure) {
        stack.push(value);
        insert(-(nArgs + 2));
        nArgs++;
      }
    }
  }

  void callLuaClosure(int nArgs, int nResults, LuaClosure c) {
    final nRegs = c.proto!.maxStackSize;
    final nParams = c.proto!.numParams;
    final isVararg = c.proto!.isVararg == 1;

    final newStack = LuaStack(nRegs + LUA_MINSTACK, this);
    newStack.closure = c;

    final funcAndArgs = stack.popN(nArgs + 1);
    newStack.pushN(funcAndArgs.sublist(1), nParams);
    newStack.top = nRegs;
    if (nArgs > nParams && isVararg) {
      newStack.varargs = funcAndArgs.sublist(nParams + 1);
    }

    pushLuaStack(newStack);
    runLuaClosure();
    popLuaStack();

    if (nResults != 0) {
      final results = newStack.popN(newStack.top - nRegs);
      stack.check(results.length);
      stack.pushN(results, nResults);
    }
  }

  void callDartClosure(int nArgs, int nResults, LuaClosure c) {
    final newStack = LuaStack(nArgs + LUA_MINSTACK, this);
    newStack.closure = c;

    if (nArgs > 0) {
      final args = stack.popN(nArgs);
      newStack.pushN(args, nArgs);
    }
    stack.pop();

    pushLuaStack(newStack);
    final r = c.dartFunc!(this);
    popLuaStack();

    if (nResults != 0) {
      final results = newStack.popN(r);
      stack.check(results.length);
      stack.pushN(results, nResults);
    }
  }

  void runLuaClosure() {
    while (true) {
      final instruction = fetch();
      instruction.execute(this);
      if (instruction.opCode == OP_RETURN) break;
    }
  }
}

// LuaState newLuaState() {
//   var registry = newLuaTable(0, 0);
//   registry.put(LUA_RIDX_GLOBALS, Object(newLuaTable(0, 0)));
//   var ls = LuaState(registry: registry);
//   ls.pushLuaStack(LuaStack(LUA_MINSTACK, ls));
//   return ls;
// }

int luaUpvalueIndex(int i) => LUA_REGISTRYINDEX - i;
