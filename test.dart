import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'lib/src/api/state.dart';
import 'lib/src/api/table.dart';
import 'lib/src/binary/chunk.dart';
import 'lib/src/constants.dart';
import 'lib/src/operation/arith.dart';
import 'lib/src/operation/math.dart';
import 'lib/src/vm/instruction.dart';
import 'lib/src/vm/vm.dart';

Future<void> main() async {
  //测试读取binary
  final fileBytes =
      await File('luac.out').readAsBytes();

  //print(byteData2String(fileBytes.buffer.asByteData()));
  //listProto(unDump(fileBytes));

  //测试luastack和state
  /*LuaState luaState = newLuaState();
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
  printState(luaState);*/

  //测试lua vm
  //luaMain(unDump(fileBytes));
  
  var ls = newLuaState();
  ls.register('getmetayable', getMetaTab);
  ls.register('setmetatable', setMetaTab);
  ls.load(fileBytes, 'luac.out', 'b');
  print('\noutputs:');
  ls.call(0, 0);
}

int getMetaTab(LuaState ls){
  if(!ls.getMetaTable_(1)) ls.pushNull();
  return 1;
}

int setMetaTab(LuaState ls){
  ls.setMetaTable_(1);
  return 1;
}

/*
void luaMain(ProtoType proto){
  int nRegs = proto.maxStackSize;
  LuaState ls = newLuaState(nRegs + 8, proto);
  ls.setTop(nRegs);
  print('');
  while(true){
    int pc = ls.PC();
    Instruction instruction = Instruction(ls.fetch());
    if(instruction.opCode() != OP_RETURN){
      instruction.execute(LuaVM(ls));
      print('[$pc] ${instruction.opName()} ${state(ls)}');
    }else break;
  }
}

String state(LuaState luaState){
  int top = luaState.getTop();
  List p = [];
  for(int i = 1;i <= top;i++){
    dynamic value = luaState.stack.get(i)?.luaValue;
    p.add(value is LuaTable ? 'table' : value);
  }
  return json.encode(p);
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
*/
