import 'dart:io';
import 'api/state.dart';
import 'api/value.dart';
import 'binary/chunk.dart';
import 'constants.dart';

Future<void> main() async {
  final fileBytes =
      await File('luac.out').readAsBytes();

  //print(byteData2String(fileBytes.buffer.asByteData()));
  //listProto(unDump(fileBytes));
  LuaState luaState = newLuaState();
  luaState.pushInt(2);
  luaState.pushNull();
  printState(luaState);
  luaState.pushBool(true);
  printState(luaState);
  luaState.pushString('1231');
  printState(luaState);
  luaState.pushInt(22);
  printState(luaState);
}

void printState(LuaState luaState){
  int top = luaState.getTop();
  List p = [];
  for(int i = 1;i <= top;i++){
    LuaType t = luaState.type(i);
    switch(t.luaType){
      case LUA_TBOOLEAN:
        p.add(luaState.toBool(i));
        break;
      case LUA_TNUMBER:
        p.add(luaState.toNumber(i));
        break;
      case LUA_TSTRING:
        p.add(luaState.toStr(i));
        break;
      default:
        p.add(luaState.typeName(t));
    }
  }
  print(p);
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
