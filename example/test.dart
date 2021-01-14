import 'dart:io';
import 'package:luart/src/api/lua_state.dart';

Future<void> main() async {
  //测试调用方法
  final fileBytes = await File('luac10.out').readAsBytes();
  var ls = LuaState();
  ls.register('print', print_);
  ls.load(fileBytes, 'luac.out');
  print('');
  ls.call(0, 0);

  final fileBytes11 = await File('luac11.out').readAsBytes();
  ls = LuaState();
  ls.register('getmetayable', getMetaTab);
  ls.register('setmetatable', setMetaTab);
  ls.load(fileBytes11, 'luac.out');
  print('\noutputs:');
  ls.call(0, 0);
}

int getMetaTab(LuaState ls){
  if(!ls.getMetatable(1)) ls.pushNil();
  return 1;
}

int setMetaTab(LuaState ls){
  ls.setMetatable(1);
  return 1;
}

int print_(LuaState ls){
  var nArgs = ls.getTop();
  for(var i = 1; i <= nArgs; i++){
    print(ls.stack!.get(i));
    if(i < nArgs) print('\t');
  }
  return 0;
}

// int getMetaTab(LuaState ls) {
//   if (!ls.getMetaTable_(1)) ls.pushNull();
//   return 1;
// }

// int setMetaTab(LuaState ls) {
//   ls.setMetaTable_(1);
//   return 1;
// }

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
    dynamic value = luaState.stack.get(i)?;
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
