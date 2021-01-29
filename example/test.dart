import 'dart:io';
import 'package:luart/src/api/lua_state.dart';

Future<void> main() async {
  //测试调用方法
  var fileBytes = await File('example/ch10.out').readAsBytes();
  var ls = LuaState();
  ls.register('print', print_);
  ls.load(fileBytes, 'luac.out');
  print('');
  ls.call(0, 0);

  fileBytes = await File('example/ch11.out').readAsBytes();
  ls = LuaState();
  ls.register('print', print_);
  ls.register('getmetayable', getMetaTab);
  ls.register('setmetatable', setMetaTab);
  ls.load(fileBytes, 'luac.out');
  print('\noutputs:');
  ls.call(0, 0);

  fileBytes = await File('example/ch12.out').readAsBytes();
  ls = LuaState();
  ls.register('print', print_);
  ls.register('getmetayable', getMetaTab);
  ls.register('setmetatable', setMetaTab);
  ls.register('next', next);
  ls.register('pairs', pairs);
  ls.register('ipairs', iPairs);
  ls.load(fileBytes, 'luac.out');
  print('\noutputs:');
  ls.call(0, 0);

  fileBytes = await File('example/ch13.out').readAsBytes();
  ls = LuaState();
  ls.register('print', print_);
  ls.register('error', error);
	ls.register('pcall', pCall);
	ls.load(fileBytes, 'ch13.lua');
	ls.call(0, 0);
}

int error(LuaState ls) {
	return ls.error();
}

int pCall(LuaState ls) {
	final nArgs = ls.getTop() - 1;
	final status = ls.pCall(nArgs, -1, 0);
	ls.pushBool(status == LuaStatus.ok);
	ls.insert(1);
	return ls.getTop();
}

int next(LuaState ls) {
  ls.setTop(2); /* create a 2nd argument if there isn't one */
  if (ls.next(1)) {
    return 2;
  } else {
    ls.pushNil();
    return 1;
  }
}

int pairs(LuaState ls) {
  ls.pushDartFunction(next); /* will return generator, */
  ls.pushValue(1);         /* state, */
  ls.pushNil();
  return 3;
}

int iPairs(LuaState ls) {
  ls.pushDartFunction(_iPairsAux); /* iteration function */
  ls.pushValue(1);               /* state */
  ls.pushInt(0);             /* initial value */
  return 3;
}

int _iPairsAux(LuaState ls) {
  var i = ls.toInt(2) + 1;
  ls.pushInt(i);
  if (ls.getI(1, i) == LuaType.nil) {
    return 1;
  } else {
    return 2;
  }
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
  }
  return 0;
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
