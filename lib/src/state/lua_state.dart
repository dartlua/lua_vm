import 'dart:convert';
import 'dart:typed_data';

import 'package:luart/luart.dart';
import 'package:luart/src/api/lua_result.dart';
import 'package:luart/src/api/lua_vm.dart';
import 'package:luart/src/binary/chunk.dart';
import 'package:luart/src/compiler/compiler.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/state/lua_closure.dart';
import 'package:luart/src/state/lua_stack.dart';
import 'package:luart/src/state/lua_table.dart';
import 'package:luart/src/state/lua_value.dart';
import 'package:luart/src/state/state_arith.dart';
import 'package:luart/src/state/state_access.dart';
import 'package:luart/src/state/state_compare.dart';
import 'package:luart/src/state/state_get.dart';
import 'package:luart/src/state/state_misc.dart';
import 'package:luart/src/state/state_push.dart';
import 'package:luart/src/state/state_set.dart';
import 'package:luart/src/state/state_stack.dart';
import 'package:luart/src/state/state_vm.dart';
import 'package:luart/src/vm/instruction.dart';

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
  LuaStack? stack;

  @override
  LuaTable? registry;

  LuaStateImpl() {
    registry = LuaTable(<KV>[]);
    registry!.put(LUA_RIDX_GLOBALS, LuaTable(<KV>[]));
    pushLuaStack(LuaStack(LUA_MINSTACK, this));
  }

  void pushLuaStack(LuaStack newStack) {
    newStack.prev = stack;
    stack = newStack;
  }

  void popLuaStack() {
    final oldStack = stack;
    stack = oldStack!.prev!;
    oldStack.prev = null;
  }

  @override
  int registerCount() => stack!.closure!.proto!.maxStackSize;

  @override
  void loadVararg(int n) {
    if (n < 0) n = stack!.varargs.length;
    stack!.check(n);
    stack!.pushN(stack!.varargs, n);
  }

  @override
  void loadProto(int idx) {
    final subProto = stack!.closure!.proto!.protos[idx];
    final c = LuaClosure.fromLuaProto(subProto);

    var i = 0;
    for (var val in subProto.upvalues) {
      final uvIndex = val.idx;
      if (val.inStack == 1) {
        stack!.openUVs ??= <int, LuaUpValue?>{};

        if (stack!.openUVs!.containsKey(uvIndex)) {
          c.upValues[i] = stack!.openUVs![uvIndex];
        } else {
          c.upValues[i] = stack!.slots[uvIndex];
          stack!.openUVs![uvIndex] = c.upValues[i];
        }
      } else {
        c.upValues[i] = stack!.closure!.upValues[uvIndex];
      }
      i++;
    }
    stack!.push(c);
  }

  @override
  bool isFunction(int idx) {
    final val = stack!.get(idx);
    return val is LuaClosure;
  }

  @override
  bool isDartFunction(int idx) {
    final val = stack!.get(idx)!;
    if (val is LuaClosure) return val.dartFunc != null;
    return false;
  }

  @override
  void pushGlobalTable() => getI(LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);

  @override
  void register(String name, LuaDartFunction dartFunc) {
    pushDartFunction(dartFunc);
    setGlobal(name);
  }

  @override
  void pushDartClosure(LuaDartFunction f, int n) {
    final closure = LuaClosure.fromDartFunction(f, n);
    for (var i = n; i > 0; i--) {
      closure.upValues[n - 1] = stack!.pop();
    }
    stack!.push(closure);
  }

  @override
  void closeClosure(int a) {
    stack!.openUVs!.forEach((key, value) {
      if (key >= a - 1) stack!.openUVs!.remove(key);
    });
  }

  @override
  int rawLen(int idx) {
    final val = stack!.get(idx)!;
    final x = val;
    if (x is String) return x.length;
    if (x is LuaTable) return x.len;
    return 0;
  }

  @override
  LuaStatus load(Uint8List chunk, String chunkName) {
    late LuaPrototype proto;

    if (isBinaryChunk(chunk)) {
      proto = unDump(chunk);
    } else {
      proto = compile(utf8.decode(chunk), chunkName);
    }

    final c = LuaClosure.fromLuaProto(proto);
    stack!.push(c);
    if (proto.upvalues.isNotEmpty) {
      final env = registry!.get(LUA_RIDX_GLOBALS);
      final upEnv = env;
      if (c.upValues.isEmpty) {
        c.upValues.add(upEnv);
      } else {
        c.upValues[0] = upEnv;
      }
    }
    return LuaStatus.ok;
  }

  @override
  void call(int nArgs, int nResults) {
    var value = stack!.get(-(nArgs + 1));
    if (value is LuaResult) {
      value = value.result;
    }

    // if (value == null) {
    //   throw LuaRuntimeError('attempt to call a nil value');
    // }

    if (value is LuaClosure) {
      if (value.proto != null) {
        callLuaClosure(nArgs, nResults, value);
      } else {
        callDartClosure(nArgs, nResults, value);
      }
    } else {
      final mf = getMetaField(value, '__call', this);
      if (mf is LuaClosure) {
        stack!.push(value);
        insert(-(nArgs + 2));
        nArgs++;
      }
    }
  }

  @override
  LuaStatus pCall(int nArgs, int nResults, int msgHandler) {
    final caller = stack!;

    try {
      call(nArgs, nResults);
    } catch (e) {
      if (msgHandler != 0) {
        rethrow;
      }
      while (stack != caller) {
        popLuaStack();
      }
      stack!.push(e);
      return LuaStatus.errRun;
    }
    
    call(nArgs, nResults);
    return LuaStatus.ok;
  }

  void callLuaClosure(int nArgs, int nResults, LuaClosure c) {
    final nRegs = c.proto!.maxStackSize;
    final nParams = c.proto!.numParams;
    final isVararg = c.proto!.isVararg == 1;

    final newStack = LuaStack(nRegs + LUA_MINSTACK, this);
    newStack.closure = c;

    final funcAndArgs = stack!.popN(nArgs + 1);
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
      stack!.check(results.length);
      stack!.pushN(results, nResults);
    }
  }

  void callDartClosure(int nArgs, int nResults, LuaClosure c) {
    final newStack = LuaStack(nArgs + LUA_MINSTACK, this);
    newStack.closure = c;

    if (nArgs > 0) {
      final args = stack!.popN(nArgs);
      newStack.pushN(args, nArgs);
    }
    stack!.pop();

    pushLuaStack(newStack);
    final r = c.dartFunc!(this);
    popLuaStack();

    if (nResults != 0) {
      final results = newStack.popN(r);
      stack!.check(results.length);
      stack!.pushN(results, nResults);
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

int luaUpvalueIndex(int i) => LUA_REGISTRYINDEX - i;
