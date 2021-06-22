import 'package:luart/auxlib.dart';
import 'package:luart/luart.dart';
import 'package:luart/src/constants.dart';

int openTableLib(LuaState ls) {
  final lib = LuaStdlibTable();
  final funcs = <String, LuaDartFunction>{
    'move': lib.tabMove,
    'insert': lib.tabInsert,
    'remove': lib.tabRemove,
    'sort': lib.tabSort,
    'concat': lib.tabConcat,
    'pack': lib.tabPack,
    'unpack': lib.tabUnpack,
  };

  ls.newLib(funcs);
  return 1;
}

class LuaLibTableBehavior {}

class LuaStdlibTable {
  int tabMove(LuaState ls) {
    final f = ls.checkInt(2);
    final e = ls.checkInt(3);
    final t = ls.checkInt(4);
    var tt = 1; /* destination table */
    if (!ls.isNoneOrNil(5)) {
      tt = 5;
    }
    _checkTab(ls, 1, TAB_R);
    _checkTab(ls, tt, TAB_W);
    if (e >= f) {
      /* otherwise, nothing to move */
      int n, i;
      ls.argCheck(
          f > 0 || e < LUA_MAXINTEGER + f, 3, 'too many elements to move');
      n = e - f + 1; /* number of elements to move */
      ls.argCheck(t <= LUA_MAXINTEGER - n + 1, 4, 'destination wrap around');
      if (t > e || t <= f || (tt != 1 && !ls.compare(1, tt, LuaCompareOp.eq))) {
        for (i = 0; i < n; i++) {
          ls.getI(1, f + i);
          ls.setI(tt, t + i);
        }
      } else {
        for (i = n - 1; i >= 0; i--) {
          ls.getI(1, f + i);
          ls.setI(tt, t + i);
        }
      }
    }
    ls.pushValue(tt); /* return destination table */
    return 1;
  }

  // table.insert (list, [pos,] value)
  // http://www.lua.org/manual/5.3/manual.html#pdf-table.insert
  // lua-5.3.4/src/ltablib.c#tinsert()
  int tabInsert(LuaState ls) {
    final e = _auxGetN(ls, 1, TAB_RW) + 1; /* first empty element */
    var pos; /* where to insert new element */
    switch (ls.getTop()) {
      case 2: /* called with only 2 arguments */
        pos = e;
        break; /* insert new element at the end */
      case 3:
        pos = ls.checkInt(2); /* 2nd argument is the position */
        ls.argCheck(1 <= pos && pos <= e, 2, 'position out of bounds');
        for (var i = e; i > pos; i--) {
          /* move up elements */
          ls.getI(1, i - 1);
          ls.setI(1, i); /* t[i] = t[i - 1] */
        }
        break;
      default:
        return ls.error2("wrong number of arguments to 'insert'");
    }
    ls.setI(1, pos); /* t[pos] = v */
    return 0;
  }

  // table.remove (list [, pos])
  // http://www.lua.org/manual/5.3/manual.html#pdf-table.remove
  // lua-5.3.4/src/ltablib.c#tremove()
  int tabRemove(LuaState ls) {
    final size = _auxGetN(ls, 1, TAB_RW);
    var pos = ls.optInt(2, size);
    if (pos != size) {
      /* validate 'pos' if given */
      ls.argCheck(1 <= pos && pos <= size + 1, 1, 'position out of bounds');
    }
    ls.getI(1, pos); /* result = t[pos] */
    for (; pos < size; pos++) {
      ls.getI(1, pos + 1);
      ls.setI(1, pos); /* t[pos] = t[pos + 1] */
    }
    ls.pushNil();
    ls.setI(1, pos); /* t[pos] = nil */
    return 1;
  }

  // table.concat (list [, sep [, i [, j]]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-table.concat
  // lua-5.3.4/src/ltablib.c#tconcat()
  int tabConcat(LuaState ls) {
    final tabLen = _auxGetN(ls, 1, TAB_R);
    final sep = ls.optString(2, '');
    final i = ls.optInt(3, 1);
    final j = ls.optInt(4, tabLen);

    if (i > j) {
      ls.pushString('');
      return 1;
    }

    final buf = List.filled(j - i + 1, '');
    for (var k = i; k > 0 && k <= j; k++) {
      ls.getI(1, k);
      if (!ls.isString(-1)) {
        ls.error2("invalid value (%s) at index %d in table for 'concat'",
            [ls.type(-1).typeName, i]);
      }
      buf[k - i] = ls.toDartString(-1)!;
      ls.pop(1);
    }
    ls.pushString(buf.join(sep!));

    return 1;
  }

  int _auxGetN(LuaState ls, int n, int w) {
    _checkTab(ls, n, w | TAB_L);
    return ls.rawLen(n);
  }

  /*
  ** Check that 'arg' either is a table or can behave like one (that is,
  ** has a metatable with the required metamethods)
   */
  void _checkTab(LuaState ls, int arg, int what) {
    if (ls.type(arg) != LuaType.table) {
      /* is it not a table? */
      final n = 1; /* number of elements to pop */
      if (ls.getMetatable(arg) && /* must have metatable */
          (what & TAB_R != 0 || _checkField(ls, '__index', n)) &&
          (what & TAB_W != 0 || _checkField(ls, '__newindex', n)) &&
          (what & TAB_L != 0 || _checkField(ls, '__len', n))) {
        ls.pop(n); /* pop metatable and tested metamethods */
      } else {
        ls.checkType(arg, LuaType.table); /* force an error */
      }
    }
  }

  bool _checkField(LuaState ls, String key, int n) {
    ls.pushString(key);
    n++;
    return ls.rawGet(-n) != LuaType.nil;
  }

  /* Pack/unpack */

  // table.pack (···)
  // http://www.lua.org/manual/5.3/manual.html#pdf-table.pack
  // lua-5.3.4/src/ltablib.c#pack()
  int tabPack(LuaState ls) {
    final n = ls.getTop(); /* number of elements to pack */
    ls.createTable(n, 1); /* create result table */
    ls.insert(1); /* put it at index 1 */
    for (var i = n; i >= 1; i--) {
      /* assign elements */
      ls.setI(1, i);
    }
    ls.pushInt(n);
    ls.setField(1, 'n'); /* t.n = number of elements */
    return 1; /* return table */
  }

  // table.unpack (list [, i [, j]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-table.unpack
  // lua-5.3.4/src/ltablib.c#unpack()
  int tabUnpack(LuaState ls) {
    var i = ls.optInt(2, 1);
    final e = ls.optInt(3, ls.rawLen(1));
    if (i > e) {
      /* empty range */
      return 0;
    }

    final n = e - i + 1;
    if (n <= 0 || n >= MAX_LEN || !ls.checkStack(n)) {
      return ls.error2('too many results to unpack');
    }

    for (; i < e; i++) {
      /* push arg[i..e - 1] (to avoid overflows) */
      ls.getI(1, i);
    }
    ls.getI(1, e); /* push last element */
    return n;
  }

  /* sort */

  // table.sort (list [, comp])
  // http://www.lua.org/manual/5.3/manual.html#pdf-table.sort
  int tabSort(LuaState w) {
    w.argCheck(w.rawLen(1) < MAX_LEN, 1, 'array too big');
    final n = w.rawLen(1);
    w.quickSort(w, 0, n, maxDepth(n));
    return 0;
  }
}

extension TableSort on LuaState {
  bool less(int i, int j) {
    if (isFunction(2)) {
      // cmp is given
      pushValue(2);
      getI(1, i + 1);
      getI(1, j + 1);
      call(2, 1);
      final b = toBool(-1);
      pop(1);
      return b;
    } else {
      // cmp is missing
      getI(1, i + 1);
      getI(1, j + 1);
      final b = compare(-2, -1, LuaCompareOp.lt);
      pop(2);
      return b;
    }
  }

  void swap(int i, int j) {
    getI(1, i + 1);
    getI(1, j + 1);
    setI(1, i + 1);
    setI(1, j + 1);
  }

  void quickSort(LuaState data, int a, int b, int maxDepth) {
    while (b - a > 12) {
      // Use ShellSort for slices <= 12 elements
      if (maxDepth == 0) {
        heapSort(data, a, b);
        return;
      }
      maxDepth--;
      final result = doPivot(data, a, b);
      var mlo = result.a;
      var mhi = result.b;
      // Avoiding recursion on the larger subproblem guarantees
      // a stack depth of at most lg(b-a).
      if (mlo - a < b - mhi) {
        quickSort(data, a, mlo, maxDepth);
        a = mhi; // i.e., quickSort(data, mhi, b)
      } else {
        quickSort(data, mhi, b, maxDepth);
        b = mlo; // i.e., quickSort(data, a, mlo)
      }
    }
    if (b - a > 1) {
      // Do ShellSort pass with gap 6
      // It could be written in this simplified form cause b-a <= 12
      for (var i = a + 6; i < b; i++) {
        if (data.less(i, i - 6)) {
          data.swap(i, i - 6);
        }
      }
      insertionSort(data, a, b);
    }
  }
}

class PivotResult {
  int a;
  int b;
  PivotResult(this.a, this.b);
}

PivotResult doPivot(LuaState data, int lo, int hi) {
  final m = (lo + hi) >> 1; // Written like this to avoid integer overflow.
  if (hi - lo > 40) {
    // Tukey's ``Ninther,'' median of three medians of three.
    final s = ((hi - lo) / 8).ceil();
    medianOfThree(data, lo, lo + s, lo + 2 * s);
    medianOfThree(data, m, m - s, m + s);
    medianOfThree(data, hi - 1, hi - 1 - s, hi - 1 - 2 * s);
  }
  medianOfThree(data, lo, m, hi - 1);

  // Invariants are:
  //	data[lo] = pivot (set up by ChoosePivot)
  //	data[lo < i < a] < pivot
  //	data[a <= i < b] <= pivot
  //	data[b <= i < c] unexamined
  //	data[c <= i < hi-1] > pivot
  //	data[hi-1] >= pivot
  var pivot = lo;
  var a = lo + 1;
  var c = hi - 1;

  for (; a < c && data.less(a, pivot); a++) {}
  var b = a;
  while (true) {
    for (; b < c && !data.less(pivot, b); b++) {
      // data[b] <= pivot
    }
    for (; b < c && data.less(pivot, c - 1); c--) {
      // data[c-1] > pivot
    }
    if (b >= c) {
      break;
    }
    // data[b] > pivot; data[c-1] <= pivot
    data.swap(b, c - 1);
    b++;
    c--;
  }
  // If hi-c<3 then there are duplicates (by property of median of nine).
  // Let's be a bit more conservative, and set border to 5.
  var protect = hi - c < 5;
  if (!protect && hi - c < (hi - lo) / 4) {
    // Lets test some points for equality to pivot
    var dups = 0;
    if (!data.less(pivot, hi - 1)) {
      // data[hi-1] = pivot
      data.swap(c, hi - 1);
      c++;
      dups++;
    }
    if (!data.less(b - 1, pivot)) {
      // data[b-1] = pivot
      b--;
      dups++;
    }
    // m-lo = (hi-lo)/2 > 6
    // b-lo > (hi-lo)*3/4-1 > 8
    // ==> m < b ==> data[m] <= pivot
    if (!data.less(m, pivot)) {
      // data[m] = pivot
      data.swap(m, b - 1);
      b--;
      dups++;
    }
    // if at least 2 points are equal to pivot, assume skewed distribution
    protect = dups > 1;
  }
  if (protect) {
    // Protect against a lot of duplicates
    // Add invariant:
    //	data[a <= i < b] unexamined
    //	data[b <= i < c] = pivot
    while (true) {
      for (; a < b && !data.less(b - 1, pivot); b--) {
        // data[b] == pivot
      }
      for (; a < b && data.less(a, pivot); a++) {
        // data[a] < pivot
      }
      if (a >= b) {
        break;
      }
      // data[a] == pivot; data[b-1] < pivot
      data.swap(a, b - 1);
      a++;
      b--;
    }
  }
  // Swap pivot into middle
  data.swap(pivot, b - 1);
  return PivotResult(b - 1, c);
}

void medianOfThree(LuaState data, int m1, int m0, int m2) {
  // sort 3 elements
  if (data.less(m1, m0)) {
    data.swap(m1, m0);
  }
  // data[m0] <= data[m1]
  if (data.less(m2, m1)) {
    data.swap(m2, m1);
    // data[m0] <= data[m2] && data[m1] < data[m2]
    if (data.less(m1, m0)) {
      data.swap(m1, m0);
    }
  }
  // now data[m0] <= data[m1] <= data[m2]
}

int maxDepth(int n) {
  var depth = 0;
  for (var i = n; i > 0; i >>= 1) {
    depth++;
  }
  return depth * 2;
}

void heapSort(LuaState data, int a, int b) {
  final first = a;
  final lo = 0;
  final hi = b - a;

  // Build heap with greatest element at top.
  for (var i = ((hi - 1) / 2).ceil(); i >= 0; i--) {
    siftDown(data, i, hi, first);
  }

  // Pop elements, largest first, into end of data.
  for (var i = hi - 1; i >= 0; i--) {
    data.swap(first, first + i);
    siftDown(data, lo, i, first);
  }
}

void insertionSort(LuaState data, int a, int b) {
  for (var i = a + 1; i < b; i++) {
    for (var j = i; j > a && data.less(j, j - 1); j--) {
      data.swap(j, j - 1);
    }
  }
}

void siftDown(LuaState data, int lo, int hi, int first) {
  var root = lo;
  while (true) {
    var child = 2 * root + 1;
    if (child >= hi) {
      break;
    }
    if (child + 1 < hi && data.less(first + child, first + child + 1)) {
      child++;
    }
    if (!data.less(first + root, first + child)) {
      return;
    }
    data.swap(first + root, first + child);
    root = child;
  }
}
