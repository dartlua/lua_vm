import 'dart:io';

import 'package:luart/auxlib.dart';
import 'package:luart/luart.dart';

bool loadStringWithReturn(LuaState ls, String source) {
  try {
    ls.loadString('return $source', '=stdin');
    return true;
  } catch (e) {
    return false;
  }
}

void repl() {
  final ls = LuaState();
  ls.openLibs();

  print('Luart Repl');

  while (true) {
    stdout.write('> ');

    final line = stdin.readLineSync();
    if (line == null) {
      exit(0);
    }

    try {
      ls.loadString(line, 'stdin');
    } catch (e, st) {
      if (!loadStringWithReturn(ls, line)) {
        print(e);
        print(st);
      }
    }

    ls.pCall(0, -1, 0);

    print(ls.stack!.popN(ls.getTop()).join('\t'));
  }
}

void main() {
  repl();
}
