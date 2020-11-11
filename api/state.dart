import '../binary/chunk.dart';
import '../constants.dart';
import '../operation/arith.dart';
import '../operation/operator.dart';
import '../operation/compare.dart';
import '../state/stack.dart';
import 'table.dart';
import 'value.dart';

class LuaState{
  LuaStack stack;
  ProtoType proto;
  int pc;

  LuaState(LuaStack this.stack, ProtoType this.proto, int this.pc);

  int getTop() => stack.top;

  int PC() => pc;

  void addPC(int n) => pc += n;

  int fetch(){
    int i = proto.codes[pc];
    pc++;
    return i;
  }

  void getConst(int idx) => stack.push(LuaValue(proto.constants[idx]));

  void getRK(int rk) => rk > 0xff ? getConst(rk & 0xff) : pushValue(rk + 1);

  int absIndex(int idx) => stack.absIndex(idx);

  bool checkStack(int n){
    stack.check(n);
    return true;
  }

  void pop(int n) => setTop(-n - 1);

  void copy(int fromIdx, int toIdx) => stack.set(toIdx, stack.get(fromIdx));

  void pushValue(int idx) => stack.push(stack.get(idx));

  void replace(int idx) => stack.set(idx, stack.pop());

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
    if(newTop < 0) throw StackUnderflowError();
    int n = stack.top - newTop;
    if(n > 0) for(int i = 0;i < n;i++) stack.pop();
    else if(n < 0) for(int i = 0;i > n;i--) pushNull();
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
  bool isNumber(int idx) => stack.get(idx).luaValue is double;
  bool isString(int idx) =>
      type(idx).luaType == LUA_TSTRING || type(idx).luaType == LUA_TNUMBER;

  bool toBool(int idx) => convert2Boolean(stack.get(idx));

  int toInt(int idx) => convert2Int(stack.get(idx));

  double toNumber(int idx) => convert2Float(stack.get(idx));

  String toStr(int idx) => convert2String(stack.get(idx));

  void pushNull() => stack.push(null);
  void pushBool(bool b) => stack.push(LuaValue(b));
  void pushInt(int i) => stack.push(LuaValue(i));
  void pushNumber(double d) => stack.push(LuaValue(d));
  void pushString(String s) => stack.push(LuaValue(s));

  void arith(ArithOp op){
    LuaValue a;
    LuaValue b;
    b = stack.pop();
    if(op.arithOp != LUA_OPUNM && op.arithOp != LUA_OPBNOT){
      a = stack.pop();
    }else{
      a = b;
    }

    Operator operator = operators[op.arithOp];
    LuaValue result = _arith(a, b , operator);
    if(result != null) stack.push(result);
    else throw UnsupportedError('unsupported arith!');
  }

  bool compare(int idx1, int idx2, CompareOp op){
    LuaValue a = stack.get(idx1);
    LuaValue b = stack.get(idx2);
    switch(op.compareOp){
      case LUA_OPEQ:
        return eq(a, b);
      case LUA_OPLT:
        return lt(a, b);
      case LUA_OPLE:
        return le(a, b);
      default:
        throw UnsupportedError('Unsupported Compare Operation');
    }
  }

  void len(int idx){
    LuaValue val = stack.get(idx);
    if(val == null){
      throw TypeError();
    }
    dynamic value = val.luaValue;
    if(value is bool){
      throw TypeError();
    }
    if(value is List || value is Map){
      stack.push(LuaValue(value.length));
    }
    stack.push(LuaValue(value.toString().length));
  }

  void concat(int n){
    if(n == 0) stack.push(LuaValue(''));
    else if(n >= 2){
      for(int i = 1;i < n;i++){
        if(isString(-1) && isString(-2)){
          String s2 = toStr(-1);
          String s1 = toStr(-2);
          stack.pop();
          stack.pop();
          stack.push(LuaValue(s1 + s2));
          continue;
        }
      }
    }
  }

  void createTable(int nArr, int nRec){
    stack.push(LuaValue(newLuaTable(nArr, nRec)));
  }

  void newTable(){
    createTable(0, 0);
  }

  LuaType getTable(int idx){
    LuaValue t = stack.get(idx);
    LuaValue k = stack.pop();
    return _getTable(t, k);
  }

  LuaType _getTable(LuaValue t, LuaValue k){
    dynamic value = t.luaValue;
    if(value is LuaTable){
      LuaValue v = value.get(k);
      stack.push(v);
      return typeOf(v);
    }
    throw TypeError();
  }

  LuaType getField(int idx, String k){
    LuaValue t = stack.get(idx);
    return _getTable(t, LuaValue(k));
  }

  LuaType getI(int idx, int i){
    LuaValue t = stack.get(idx);
    return _getTable(t, LuaValue(i));
  }

  void setTable(int idx){
    LuaValue t = stack.get(idx);
    LuaValue v = stack.pop();
    LuaValue k = stack.pop();
    _setTable(t, k ,v);
  }

  void _setTable(LuaValue t, LuaValue k, LuaValue v){
    dynamic table = t.luaValue;
    if(table is LuaTable){
      table.put(k, v);
      return;
    }
    throw TypeError();
  }

  void setField(int idx, String k){
    LuaValue t = stack.get(idx);
    LuaValue v = stack.pop();
    _setTable(t, LuaValue(k) ,v);
  }

  void setI(int idx, int i){
    LuaValue t = stack.get(idx);
    LuaValue v = stack.pop();
    _setTable(t, LuaValue(i), v);
  }
}

LuaValue _arith(LuaValue a, LuaValue b, Operator op){
  if(op.floatFunc == null) return LuaValue(op.intFunc(convert2Int(a), convert2Int(b)));
  if(op.intFunc != null) return LuaValue(op.intFunc(convert2Int(a), convert2Int(b)));
  return LuaValue(op.floatFunc(convert2Float(a), convert2Float(b)));
}

LuaState newLuaState(int stackSize, ProtoType proto) =>
    LuaState(newLuaStack(stackSize), proto, 0);