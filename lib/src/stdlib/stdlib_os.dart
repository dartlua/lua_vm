// import 'dart:io';

import 'package:luart/auxlib.dart';
import 'package:luart/luart.dart';
import 'package:luart/src/utils.dart';

int openOsLib(LuaState ls) {
  final lib = LuaStdlibOs();
  final funcs = <String, LuaDartFunction>{
    'clock': lib.clock,
    'difftime': lib.diffTime,
    'time': lib.time,
    'date': lib.date,
    // 'remove':    lib.remove,
    // 'rename':    lib.rename,
    // 'tmpname':   lib.tmpName,
    // 'getenv':    lib.getEnv,
    // 'execute':   lib.execute,
    // 'exit':      lib.exit,
    // 'setlocale': lib.setLocale,
  };

  ls.newLib(funcs);
  return 1;
}

class LuaLibOsBehavior {}

class LuaStdlibOs {
  final startupTime = DateTime.now().microsecondsSinceEpoch;
  // os.clock ()
  // http://www.lua.org/manual/5.3/manual.html#pdf-os.clock
  // lua-5.3.4/src/loslib.c#os_clock()
  int clock(LuaState ls) {
    final c = (DateTime.now().microsecondsSinceEpoch - startupTime) / 1000000;
    ls.pushNumber(c);
    return 1;
  }

  // os.difftime (t2, t1)
  // http://www.lua.org/manual/5.3/manual.html#pdf-os.difftime
  // lua-5.3.4/src/loslib.c#os_difftime()
  int diffTime(LuaState ls) {
    final t2 = ls.mustCheckInt(1);
    final t1 = ls.mustCheckInt(2);
    ls.pushInt(t2 - t1);
    return 1;
  }

  // os.time ([table])
  // http://www.lua.org/manual/5.3/manual.html#pdf-os.time
  // lua-5.3.4/src/loslib.c#os_time()
  int time(LuaState ls) {
    if (ls.isNoneOrNil(1)) {
      /* called without args? */
      final t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      ls.pushInt(t);
    } else {
      ls.checkType(1, LuaType.table);
      final sec = _getField(ls, 'sec', 0);
      final min = _getField(ls, 'min', 0);
      final hour = _getField(ls, 'hour', 12);
      final day = _getField(ls, 'day', -1);
      final month = _getField(ls, 'month', -1);
      final year = _getField(ls, 'year', -1);

      final t =
          DateTime(year, month, day, hour, min, sec).millisecondsSinceEpoch ~/
              1000;
      ls.pushInt(t);
    }
    return 1;
  }

  // lua-5.3.4/src/loslib.c#getfield()
  int _getField(LuaState ls, String key, int dft) {
    final t = ls.getField(-1, key); /* get field and its type */
    var res = ls.checkInt(-1);
    if (res == null) {
      /* field is not an integer? */
      if (t != LuaType.nil) {
        /* some other value? */
        return ls.errorMessage("field '$key' is not an integer");
      } else if (dft < 0) {
        /* absent field; no default? */
        return ls.errorMessage("field '$key' missing in date table");
      }
      res = dft;
    }
    ls.pop(1);
    return res;
  }

  // os.date ([format [, time]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-os.date
  // lua-5.3.4/src/loslib.c#os_date()
  int date(LuaState ls) {
    var format = ls.checkString(1) ?? '%c';

    late DateTime t;

    if (ls.isInt(2)) {
      final seconds = ls.toInt(2);
      t = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    } else {
      t = DateTime.now();
    }

    if (format != '' && format[0] == '!') {
      /* UTC? */
      format = format.substring(1); /* skip '!' */
      t = t.toUtc();
    }

    if (format == '*t') {
      ls.createTable(0, 9); /* 9 = number of fields */
      _setField(ls, 'sec', t.second);
      _setField(ls, 'min', t.minute);
      _setField(ls, 'hour', t.hour);
      _setField(ls, 'day', t.day);
      _setField(ls, 'month', t.month);
      _setField(ls, 'year', t.year);
      _setField(ls, 'wday', t.weekday + 1);
      _setField(ls, 'yday', dayInYear(t));
    } else if (format == '%c') {
      ls.pushString(format); // TODO
    } else {
      ls.pushString(format); // TODO
    }

    return 1;
  }

  void _setField(LuaState ls, String key, int value) {
    ls.pushInt(value);
    ls.setField(-2, key);
  }

  // os.remove (filename)
  // http://www.lua.org/manual/5.3/manual.html#pdf-os.remove
  // int remove(LuaState ls) {
  //   final filename = ls.mustCheckString(1);
  //   try {
  //     File(filename).deleteSync();
  //     ls.pushBool(true);
  //     return 1;
  //   } catch (e) {
  //     ls.pushNil();
  //     ls.pushString(e.toString());
  //     return 2;
  //   }
  // }

  // os.rename (oldname, newname)
  // http://www.lua.org/manual/5.3/manual.html#pdf-os.rename
  // int rename(LuaState ls) {
  //   final oldName = ls.mustCheckString(1);
  //   final newName = ls.mustCheckString(2);
  //   try {
  //     File(oldName).renameSync(newName);
  //     ls.pushBool(true);
  //     return 1;
  //   } catch (e) {
  //     ls.pushNil();
  //     ls.pushString(e.toString());
  //     return 2;
  //   }
  // }

  // os.tmpname ()
  // http://www.lua.org/manual/5.3/manual.html#pdf-os.tmpname
  // int tmpName(LuaState ls) {
  //   Directory.systemTemp
  // }

  // os.getenv (varname)
  // http://www.lua.org/manual/5.3/manual.html#pdf-os.getenv
  // lua-5.3.4/src/loslib.c#os_getenv()
  // int getEnv(LuaState ls) {
  //   final key = ls.mustCheckString(1);
  //   final val = Platform.environment[key];
  //   if (val != null) {
  //     ls.pushString(val);
  //   } else {
  //     ls.pushNil();
  //   }
  //   return 1;
  // }

  // os.execute ([command])
  // http://www.lua.org/manual/5.3/manual.html#pdf-os.execute
  // int execute(LuaState ls) {
  //   // TODO
  // }

  // os.exit ([code [, close]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-os.exit
  // lua-5.3.4/src/loslib.c#os_exit()
  // int osExit(LuaState ls) {
  //   if (ls.isBool(1)) {
  //     if (ls.toBool(1)) {
  //       exit(0);
  //     } else {
  //       exit(1);// todo
  //     }
  //   } else {
  //     final code = ls.checkInt(1) ?? 1;
  //     exit(code);
  //   }
  // }

  // os.setlocale (locale [, category])
  // http://www.lua.org/manual/5.3/manual.html#pdf-os.setlocale
  // int setLocale(LuaState ls) {
  //   // TODO
  // }
}
