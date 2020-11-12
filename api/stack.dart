import '../constants.dart';
import 'closure.dart';
import 'value.dart';

class LuaStack{
  List<LuaValue> slots;
  int top;
  LuaStack prev;
  LuaClosure closure;
  List<LuaValue> varargs;
  int pc = 0;

  LuaStack(List<LuaValue> this.slots, int this.top);

  void addPC(int n) => pc += n;

  void check(int n){
    int free = slots.length - top;
    slots.fillRange(free, free + n - 1, null);
  }

  void push(LuaValue val){
    if(top == slots.length) throw StackOverflowError();
    slots[top] = val;
    top++;
  }

  LuaValue pop(){
    if(top < 1) throw RangeError('now top value: $top');
    top--;
    LuaValue luaValue = slots[top];
    slots[top] = LuaValue(null);
    return luaValue;
  }

  int absIndex(int idx){
    if(idx > 0) return idx;
    return idx + top + 1;
  }

  bool isValid(int idx){
    int absIdx = absIndex(idx);
    return absIdx > 0 && absIdx <= top;
  }

  LuaValue get(int idx){
    int absIdx = absIndex(idx);
    if(absIdx > 0 && absIdx <= top) return slots[absIdx - 1];
    return null;
  }

  void set(int idx, LuaValue val){
    int absIdx = absIndex(idx);
    if(absIdx > 0 && absIdx <= top) {
      slots[absIdx - 1] = val;
      return;
    }
    throw StackUnderflowError();//IndexError(absIdx, slots);
  }

  void reverse(int from, int to){
    while(from < to){
      var temp = slots[from];
      slots[from] = slots[to];
      slots[to] = temp;
      from++;
      to--;
    }
  }

  List<LuaValue> popN(int n){
    List<LuaValue> valList = List<LuaValue>(n);
    for(int i = n - 1; i >= 0; i--) valList[i] = pop();
    return valList;
  }

  void pushN(List<LuaValue> valList, int n){
    int lenVal = valList.length;
    if(n < 0) n = lenVal;
    for(int i = 0; i < n; i++){
      if(i < lenVal) push(valList[i]);
      else push(LuaValue(null));
    }
  }
}

LuaStack newLuaStack(int size) => LuaStack(List<LuaValue>(size), 0);