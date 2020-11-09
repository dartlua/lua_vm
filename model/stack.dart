import 'value.dart';

class LuaStack{
  List<LuaValue> slots;
  int top;

  LuaStack(List<LuaValue> this.slots, int this.top);

  void check(int n){
    int free = slots.length - top;
    slots.fillRange(free, free + n - 1, null);
  }

  void push(LuaValue val){
    if(top == slots.length)throw StackOverflowError();
    slots[top] = val;
    top++;
  }

  LuaValue pop(){
    if(top < 1)throw RangeError('now top value: $top');
    top--;
    var luaValue = slots[top];
    slots[top] = null;
    return luaValue;
  }

  int absIndex(int idx){
    if(idx > 0)return idx;
    return idx + top + 1;
  }

  bool isValid(int idx){
    int absIdx = absIndex(idx);
    return idx > 0 && absIdx <= top;
  }

  LuaValue get(int idx){
    int absIdx = absIndex(idx);
    if(absIdx > 0 && absIdx <= top)return slots[absIdx - 1];
    return null;
  }

  void set(int idx, LuaValue val){
    int absIdx = absIndex(idx);
    if(absIdx > 0 && absIdx <= top) {
      slots[absIdx - 1] = val;
      return;
    }
    throw IndexError(absIdx, slots);
  }
}

LuaStack newLuaStack(int size) => LuaStack(<LuaValue>[], 0);