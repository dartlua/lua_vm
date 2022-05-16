// ignore_for_file: avoid_print

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

  print('Luart Repl (Lua5.3)');

  String? line;
  var blockLines = '';
  var startCount = 0;
  var endCount = 0;

  while (true) {
    stdout.write('> ');

    line = stdin.readLineSync();
    if (line == null) exit(0);
    if (line.contains(RegExp('function .*|for .* do'))) {
      startCount++;
    }
    if (line.endsWith('end')) {
      blockLines += '$line ';
      endCount++;
    }

    final isBlock = startCount == endCount;
    if (!isBlock) {
      blockLines += '$line ';
      continue;
    }

    try {
      var cmd = blockLines == '' ? line : blockLines;
      if (cmd.contains('==') || !cmd.contains(RegExp('=|return |print(.*)'))) {
        cmd = 'print($cmd)';
      }
      ls.loadString(cmd, 'stdin');
      blockLines = '';
    } catch (e, st) {
      if (loadStringWithReturn(ls, line)) {
        print(e);
        print(st);
      }
    }

    ls.pCall(0, -1, 0);
  }
}

void run(String file) {
  final ls = LuaState();
  ls.openLibs();
  try {
    ls.loadFile(file);
  } catch (e) {
    print(e);
  }

  ls.pCall(0, -1, 0);
}

void main(List<String> args) {
  if (args.isNotEmpty) {
    if (args.length == 2) {
      if (args[0] == 'run') {
        run(args[1]);
        return;
      }
    }
    print('unknown arg: [${args[0]}]');
    return;
  }
  repl();
}
