import 'package:luart/luart.dart';
import 'package:luart/src/constants.dart';
import 'package:luart/src/state/lua_closure.dart';
import 'package:luart/src/state/lua_table.dart';


class LuaStack {
  List<Object?> slots;
  int top;
  LuaStack? prev;
  LuaClosure? closure;
  late List<Object?> varargs;
  int pc = 0;
  LuaState state;
  Map<int, LuaUpValue?>? openUVs;

  LuaStack(int size, this.state)
      : slots = List<Object?>.filled(size, null, growable: true),
        top = 0;

  void addPC(int n) {
    pc += n;
  }

  void check(int n) {
    for (var free = slots.length - top; free < n; free++) {
      slots.add(null);
    }
  }

  void push(Object? val) {
    if (top == slots.length) throw StackOverflowError();
    slots[top] = val;
    top++;
  }

  Object? pop() {
    if (top < 1) throw RangeError('now top value: $top');
    top--;
    final luaValue = slots[top];
    slots[top] = null;
    return luaValue;
  }

  int absIndex(int idx) {
    if (idx >= 0 || idx <= LUA_REGISTRYINDEX) return idx;
    return idx + top + 1;
  }

  bool isValid(int idx) {
    if (idx < LUA_REGISTRYINDEX) {
      final uvIndex = LUA_REGISTRYINDEX - idx - 1;
      final c = closure;
      return c != null && uvIndex < c.upValues.length;
    }

    if (idx == LUA_REGISTRYINDEX) return true;

    final absIdx = absIndex(idx);
    return absIdx > 0 && absIdx <= top;
  }

  Object? get(int idx) {
    if (idx < LUA_REGISTRYINDEX) {
      final uvIndex = LUA_REGISTRYINDEX - idx - 1;
      final c = closure;
      if (c == null || uvIndex >= c.upValues.length) return null;
      return c.upValues[uvIndex]!.value;
    }

    if (idx == LUA_REGISTRYINDEX) return state.registry;

    final absIdx = absIndex(idx);
    if (absIdx > 0 && absIdx <= top) return slots[absIdx - 1];
    return null;
  }

  void set(int idx, Object? value) {
    if (idx < LUA_REGISTRYINDEX) {
      final uvIndex = LUA_REGISTRYINDEX - idx - 1;
      if (closure != null && uvIndex < closure!.upValues.length) {
        closure!.upValues[uvIndex]!.value = value;
      }
      return;
    }

    if (idx == LUA_REGISTRYINDEX) {
      if (value is LuaTable) {
        state.registry = value;
        return;
      }
      throw ArgumentError('val must be LuaTable');
    }

    var absIdx = absIndex(idx);
    if (absIdx > 0 && absIdx <= top) {
      slots[absIdx - 1] = value;
      return;
    }
    throw StackUnderflowError(); //IndexError(absIdx, slots);
  }

  void reverse(int from, int to) {
    while (from < to) {
      final temp = slots[from];
      slots[from] = slots[to];
      slots[to] = temp;
      from++;
      to--;
    }
  }

  List<Object?> popN(int n) {
    final valList = List<Object?>.filled(n, null);
    for (var i = n - 1; i >= 0; i--) {
      valList[i] = pop();
    }
    return valList;
  }

  void pushN(List<Object?> valList, int n) {
    final lenVal = valList.length;
    if (n < 0) n = lenVal;
    for (var i = 0; i < n; i++) {
      if (i < lenVal) {
        push(valList[i]);
      } else {
        push(null);
      }
    }
  }
}