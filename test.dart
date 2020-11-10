import 'dart:convert';
import 'dart:io';
import 'api/state.dart';
import 'binary/chunk.dart';
import 'constants.dart';
import 'operation/arith.dart';
import 'vm/instruction.dart';
import 'vm/vm.dart';

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
  luaMain(unDump(fileBytes));
}

void luaMain(ProtoType proto){
  int nRegs = int.parse(proto.maxStackSize);
  LuaState ls = newLuaState(nRegs + 8, proto);
  ls.setTop(nRegs);
  while(true){
    int pc = ls.PC();
    Instruction instruction = Instruction(ls.fetch());
    if(instruction.opCode() != OP_RETURN){
      instruction.execute(LuaVM(ls));
      print('${pc + 1} ${instruction.opName()}');
    }else break;
  }
}

String state(LuaState luaState){
  int top = luaState.getTop();
  List p = [];
  for(int i = 1;i <= top;i++){
    p.add(luaState.stack.get(i).luaValue);
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
