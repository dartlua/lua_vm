import '../constants.dart';
import 'closure.dart';
import 'state.dart';
import 'table.dart';
import 'value.dart';

class LuaStack {
  List<LuaValue> slots;
  int top;
  LuaStack prev;
  Closure closure;
  List<LuaValue> varargs;
  int pc = 0;
  LuaState state;
  Map<int, UpValue> openUVs;

  LuaStack(this.slots, this.top, this.state);

  void addPC(int n) => pc += n;

  void check(int n) {
    var free = slots.length - top;
    slots.fillRange(free, free + n - 1, LuaValue(null));
  }

  void push(LuaValue val) {
    if (top == slots.length) throw StackOverflowError();
    slots[top] = val;
    top++;
  }

  LuaValue pop() {
    if (top < 1) throw RangeError('now top value: $top');
    top--;
    var luaValue = slots[top];
    slots[top] = LuaValue(null);
    return luaValue;
  }

  int absIndex(int idx) {
    if (idx >= 0 || idx <= LUA_REGISTRYINDEX) return idx;
    return idx + top + 1;
  }

  bool isValid(int idx) {
    if (idx < LUA_REGISTRYINDEX) {
      var uvIndex = LUA_REGISTRYINDEX - idx - 1;
      var c = closure;
      return c != null && uvIndex < c.upValues.length;
    }

    if (idx == LUA_REGISTRYINDEX) return true;

    var absIdx = absIndex(idx);
    return absIdx > 0 && absIdx <= top;
  }

  LuaValue get(int idx) {
    if (idx < LUA_REGISTRYINDEX) {
      var uvIndex = LUA_REGISTRYINDEX - idx - 1;
      var c = closure;
      if (c == null || uvIndex >= c.upValues.length) return LuaValue(null);
      return c.upValues[uvIndex].val;
    }

    if (idx == LUA_REGISTRYINDEX) return LuaValue(state.registry);

    final absIdx = absIndex(idx);
    if (absIdx > 0 && absIdx <= top) return slots[absIdx - 1];
    return LuaValue(null);
  }

  void set(int idx, LuaValue val) {
    if (idx < LUA_REGISTRYINDEX) {
      var uvIndex = LUA_REGISTRYINDEX - idx - 1;
      var c = closure;
      if (c != null && uvIndex < c.upValues.length) {
        c.upValues[uvIndex].val = val;
      }
      return;
    }

    if (idx == LUA_REGISTRYINDEX) {
      dynamic table = val.luaValue;
      if (table is LuaTable) {
        state.registry = table;
        return;
      }
      throw ArgumentError('val must be LuaTable');
    }

    var absIdx = absIndex(idx);
    if (absIdx > 0 && absIdx <= top) {
      slots[absIdx - 1] = val;
      return;
    }
    throw StackUnderflowError(); //IndexError(absIdx, slots);
  }

  void reverse(int from, int to) {
    while (from < to) {
      var temp = slots[from];
      slots[from] = slots[to];
      slots[to] = temp;
      from++;
      to--;
    }
  }

  List<LuaValue> popN(int n) {
    var valList = List<LuaValue>(n);
    for (var i = n - 1; i >= 0; i--) {
      valList[i] = pop();
    }
    return valList;
  }

  void pushN(List<LuaValue> valList, int n) {
    var lenVal = valList.length;
    if (n < 0) n = lenVal;
    for (var i = 0; i < n; i++) {
      if (i < lenVal) {
        push(valList[i]);
      } else {
        push(LuaValue(null));
      }
    }
  }
}

LuaStack newLuaStack(int size, LuaState state) =>
    LuaStack(List<LuaValue>(size), 0, state);