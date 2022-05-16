// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as path;

Stream<File> scanLuaSources() async* {
  await for (final file in Directory('test/source').list()) {
    if (file is File && file.path.endsWith('.lua')) {
      yield file;
    }
  }
}

Future<void> compileSource(List<File> files) async {
  for (final file in files) {
    final filename = path.basenameWithoutExtension(file.path);
    const cmd = 'luac';
    final args = ['-o', 'test/source/$filename.luac', file.path];
    print('$cmd ${args.join(' ')}');
    await Process.run('luac', args);
  }
}

void main() async {
  final luaSources = await scanLuaSources().toList();
  await compileSource(luaSources);
}
