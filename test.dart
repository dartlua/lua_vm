import 'dart:convert';
import 'dart:io';
import 'api/state.dart';
import 'binary/chunk.dart';
import 'constants.dart';
import 'operation/arith.dart';

Future<void> main() async {
  final fileBytes =
      await File('luac.out').readAsBytes();

  //print(byteData2String(fileBytes.buffer.asByteData()));
  //listProto(unDump(fileBytes));
  LuaState luaState = newLuaState();
  luaState.pushInt(1);
  luaState.pushString('2.0');
  luaState.pushString('3.0');
  luaState.pushNumber(4.0);
  printState(luaState);

  luaState.arith(ArithOp(LUA_OPADD));
  printState(luaState);
  luaState.arith(ArithOp(LUA_OPBNOT));
  printState(luaState);
  luaState.len(2);
  printState(luaState);
  luaState.concat(3);
  printState(luaState);
  luaState.pushBool(luaState.compare(1, 2, CompareOp(LUA_OPEQ)));
  printState(luaState);
}

void printState(LuaState luaState){
  int top = luaState.getTop();
  List p = [];
  for(int i = 1;i <= top;i++){
    p.add(luaState.stack.get(i).luaValue);
    /*
    switch(t.luaType){
      case LUA_TBOOLEAN:
        p.add(luaState.toBool(i));
        break;
      case LUA_TNUMBER:
        p.add(luaState.stack.get(i));
        break;
      case LUA_TSTRING:
        p.add(luaState.toStr(i));
        break;
      default:
        p.add(luaState.typeName(t));
    }*/
  }
  print(json.encode(p));
}

void listProto(ProtoType protoType){
  printHeader(protoType);
  for(var i in protoType.protos){
    listProto(i);
  }
}

void printHeader(ProtoType p) {
  String funcType = 'main';
  if(p.lineDefined > 0)funcType = 'function';
  print('\n$funcType <${p.source}, ${p.lineDefined}, ${p.lastLineDefined}>, (${p.codes.length} instructions)');
}
