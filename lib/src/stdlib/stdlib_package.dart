import 'dart:io';

import 'package:luart/auxlib.dart';
import 'package:luart/luart.dart';
import 'package:luart/src/constants.dart';

int openPackageLib(LuaState ls) {
  final lib = LuaStdlibPackage();
  final funcs = <String, LuaDartFunction>{
    'searchpath': lib.pkgSearchPath,
  };

  ls.newLib(funcs);
  createSearchersTable(ls);
  /* set paths */
  ls.pushString('./?.lua;./?/init.lua');
  ls.setField(-2, 'path');
  /* store config information */
  ls.pushString(
      '$luaDirSep\n$luaPathSep\n$luaPathMark\n$luaExecDir\n$luaIGMark\n');
  ls.setField(-2, 'config');
  /* set field 'loaded' */
  ls.getSubTable(luaRegistryIndex, luaLoadedTable);
  ls.setField(-2, 'loaded');
  /* set field 'preload' */
  ls.getSubTable(luaRegistryIndex, luaPreloadTable);
  ls.setField(-2, 'preload');
  ls.pushGlobalTable();
  ls.pushValue(-2); /* set 'package' as upvalue for next lib */
  ls.setFuncs({'require': lib.pkgRequire}, 1); /* open lib into global table */
  ls.pop(1);
  return 1;
}

void createSearchersTable(LuaState ls) {
  final searchers = [preloadSearcher, luaSearcher];
  /* create 'searchers' table */
  ls.createTable(searchers.length, searchers.length);
  /* fill it with predefined searchers */
  var idx = 0;
  for (final element in searchers) {
    ls.pushValue(-2); /* set 'package' as upvalue for all searchers */
    ls.pushDartClosure(element, 1);
    ls.rawSetI(-2, idx + 1);
    idx++;
  }
  ls.setField(-2, 'searchers'); /* put it in field 'searchers' */
}

int preloadSearcher(LuaState ls) {
  final name = ls.checkString(1);
  ls.getField(luaRegistryIndex, '_PRELOAD');
  if (ls.getField(-1, name) == LuaType.nil) {
    /* not found? */
    ls.pushString("\n\tno field package.preload['$name']");
  }
  return 1;
}

int luaSearcher(LuaState ls) {
  final name = ls.checkString(1);
  ls.getField(1, 'path');
  final path = ls.toDartString(-1);
  if (path == '') {
    ls.error2('package path must be a string');
    return 0;
  }
  final filename = _searchPath(name, path, '.', luaDirSep);
  if (filename == null) {
    ls.pushString('can not find package');
    return 1;
  }

  if (ls.loadFile(filename) == LuaStatus.ok) {
    /* module loaded successfully? */
    ls.pushString(filename); /* will be 2nd argument to module */
    return 2; /* return open function and file name */
  } else {
    return ls.error2(
      "error loading module '%s' from file '%s':\n\t%s",
      [ls.checkString(1), filename, ls.checkString(-1)],
    );
  }
}

String? _searchPath(String name, String path, String sep, String dirSep) {
  if (sep != '') {
    name = name.replaceAll(sep, dirSep);
  }

  final l = path.split(luaPathSep);
  for (var i = 0; i < l.length; i++) {
    l[i] = l[i].replaceAll(luaPathMark, name);
    if (File(l[i]).existsSync()) {
      return l[i];
    }
  }

  return null;
}

void _findLoader(LuaState ls, String name) {
  /* push 'package.searchers' to index 3 in the stack */
  if (ls.getField(1, 'searchers') != LuaType.table) {
    ls.error2("'package.searchers' must be a table");
  }

  /* to build error message */
  var errMsg = "module '$name' not found:";

  /*  iterate over available searchers to find a loader */
  for (var i = 1;; i++) {
    if (ls.rawGetI(3, i) == LuaType.nil) {
      /* no more searchers? */
      ls.pop(1); /* remove nil */
      ls.error2(errMsg); /* create error message */
    }

    ls.pushString(name);
    ls.call(1, 2); /* call it */
    if (ls.isFunction(-2)) {
      /* did it find a loader? */
      return; /* module loader found */
    } else if (ls.isString(-2)) {
      /* searcher returned error message? */
      ls.pop(1); /* remove extra return */
      errMsg += ls.checkString(-1); /* concatenate error message */
    } else {
      ls.pop(2); /* remove both returns */
    }
  }
}

class LuaStdlibPackage {
  // package.searchpath (name, path [, sep [, rep]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-package.searchpath
  // loadlib.c#ll_searchpath
  int pkgSearchPath(LuaState ls) {
    final name = ls.checkString(1);
    final path = ls.checkString(2);
    final sep = ls.optString(3, '.')!;
    final rep = ls.optString(4, luaDirSep)!;
    final filename = _searchPath(name, path, sep, rep);
    if (filename != null) {
      ls.pushString(filename);
      return 1;
    } else {
      ls.pushNil();
      ls.pushString('can not search package');
      return 2;
    }
  }

  // require (modname)
  // http://www.lua.org/manual/5.3/manual.html#pdf-require
  int pkgRequire(LuaState ls) {
    final name = ls.checkString(1);
    ls.setTop(1); /* LOADED table will be at index 2 */
    ls.getField(luaRegistryIndex, luaLoadedTable);
    ls.getField(2, name); /* LOADED[name] */
    if (ls.toBool(-1)) {
      /* is it there? */
      return 1; /* package is already loaded */
    }
    /* else must load package */
    ls.pop(1); /* remove 'getfield' result */
    _findLoader(ls, name);
    ls.pushString(name); /* pass name as argument to module loader */
    ls.insert(-2); /* name is 1st argument (before search data) */
    ls.call(2, 1); /* run loader to load module */
    if (!ls.isNil(-1)) {
      /* non-nil return? */
      ls.setField(2, name); /* LOADED[name] = returned value */
    }
    if (ls.getField(2, name) == LuaType.nil) {
      /* module set no value? */
      ls.pushBool(true); /* use true as result */
      ls.pushValue(-1); /* extra copy to be returned */
      ls.setField(2, name); /* LOADED[name] = true */
    }
    return 1;
  }
}
