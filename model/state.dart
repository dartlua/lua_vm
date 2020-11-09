import '../constants.dart';
import 'stack.dart';
import 'value.dart';

class LuaState{
  LuaStack stack;

  LuaState(LuaStack this.stack);

  int getTop() => stack.top;

  int absIndex(int idx) => stack.absIndex(idx);

  bool checkStack(int n){
    stack.check(n);
    return true;
  }

  void pop(int n){
    setTop(-n - 1);
  }

  void copy(int fromIdx, int toIdx){
    LuaValue val = stack.get(fromIdx);
    stack.set(toIdx, val);
  }

  void pushValue(int idx){
    LuaValue val = stack.get(idx);
    stack.push(val);
  }

  void replace(int idx){
    LuaValue val = stack.pop();
    stack.set(idx, val);
  }

  void insert(int idx) => rotate(idx, 1);

  void remove(int idx){
    rotate(idx, -1);
    pop(1);
  }

  void rotate(int idx, int n){
    int t = stack.top - 1;
    int p = stack.absIndex(idx) - 1;
    int m;
    if(n >= 0) {
      m = t - n;
    }else{
      m = p - n - 1;
    }
    stack.reverse(p, m);
    stack.reverse(m + 1, t);
    stack.reverse(p, t);
  }

  void setTop(int idx){
    int newTop = stack.absIndex(idx);
    if(newTop < 0)throw StackUnderflowError();
    int n = stack.top - newTop;
    if(n > 0){
      for(int i = 0;i < n;i++){
        stack.pop();
      }
    }else if(n < 0){
      pushNull();//stack.push(null);
    }
  }

  String typeName(LuaType tp){
    switch(tp.luaType){
      case LUA_TNONE:
        return 'no value';
      case LUA_TNIL:
        return 'nil';
      case LUA_TBOOLEAN:
        return 'boolean';
      case LUA_TNUMBER:
        return 'number';
      case LUA_TSTRING:
        return 'string';
      case LUA_TTABLE:
        return 'table';
      case LUA_TFUNCTION:
         return 'function';
      case LUA_TTHREAD:
         return 'thread';
      default:
        return 'userdata';
    }
  }

  LuaType type(int idx){
    if(stack.isValid(idx)){
      LuaValue val = stack.get(idx);
      return typeOf(val);
    }
    return LuaType(LUA_TNONE);
  }

  bool isNone(int idx) => type(idx) == LuaType(LUA_TNONE);
  bool isNull(int idx) => type(idx) == LuaType(LUA_TNIL);
  bool isNoneOrNull(int idx) => type(idx).luaType <= LUA_TNIL;
  bool isBool(int idx) => type(idx) == LuaType(LUA_TBOOLEAN);
  bool isInt(int idx) => stack.get(idx).luaValue is int;
  bool isNumber(int idx) => toNumberX(idx)[1];
  bool isString(int idx) =>
      type(idx) == LuaType(LUA_TSTRING) || type(idx) == LuaType(LUA_TNUMBER);

  bool toBool(int idx) => convert2Boolean(stack.get(idx));

  int toInt(int idx) => toIntX(idx)[0];

  //return [int, bool]
  List toIntX(int idx){
    //todo: 类型转换待商権
    LuaValue val = stack.get(idx);
    dynamic value = val.luaValue;
    if(value is String)return [int.parse(value), true];
    if(value is double)return [value.round(), true];
    if(value is int)return [value, true];
    if(value is bool)return [value ? 1 : 0, true];
    return [0, false];
  }

  double toNumber(int idx) => toNumberX(idx)[0];

  //return [double, bool]
  List toNumberX(int idx){
    LuaValue val = stack.get(idx);
    dynamic value = val.luaValue;
    if(value is double)return [value, true];
    if(value is String)return [double.parse(value), true];
    if(value is int)return [value.roundToDouble(), true];
    if(value is bool)return [value ? 1.toDouble() : 0.toDouble(), true];
    return [0.0, false];
  }

  String toStr(int idx) => toStrX(idx)[0];

  //return [String, bool]
  List toStrX(int idx){
    LuaValue val = stack.get(idx);
    dynamic value = val.luaValue;
    if(value is String)return [value, true];
    if(value is int)return [value.toString(), true];
    if(value is double)return [value.toString(), true];
    if(value is bool)return [value ? 'true' : 'false', true];
    return ['', false];
  }

  void pushNull() => stack.push(null);
  void pushBool(bool b) => stack.push(LuaValue(null));
  void pushInt(int i) => stack.push(LuaValue(i));
  void pushNumber(double d) => stack.push(LuaValue(d));
  void pushString(String s) => stack.push(LuaValue(s));
}

LuaState newLuaState() => LuaState(newLuaStack(20));