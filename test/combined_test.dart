import 'dart:io';

import 'package:luart/auxlib.dart';
import 'package:luart/luart.dart';
import 'package:luart/src/stdlib/stdlib_base.dart';
import 'package:test/test.dart';

const sourceDir = 'test/source';

void main() async {
  final testFiles = Directory(sourceDir).listSync();
  testFiles.removeWhere(
    (ele) => !ele.path.endsWith('.lua'),
  );
  testFiles.removeWhere(
    (ele) => !File('${ele.path}.txt').existsSync(),
  );

  group('a series of lua files', () {
    for (final file in testFiles) {
      final filePath = file.path;

      test(filePath, () async {
        var output = '';
        final ls = LuaState();
        ls.openLibs();
        ls.loadFile(filePath);

        // collect print output for comparing with actual output
        ls.register('print', LuaStdlibBase(LuaBaselibBehavior(print: (s) => output = '$output$s')).basePrint);

        ls.call(0, -1);
        expect(output, equals(File('$filePath.txt').readAsStringSync().replaceAll(RegExp('  +'), '\t')));
      });
    }
  });
}
