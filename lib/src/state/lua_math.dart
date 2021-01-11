class LuaMath {
  static int iFloorDiv(int a, int b) => (a / b).floor();

  static double fFloorDiv(double a, double b) => (a / b).floorToDouble();

  static int iMod(int a, int b) => a - iFloorDiv(a, b) * b;

  static double fMod(double a, double b) => a - fFloorDiv(a, b) * b;

  static int shiftLeft(int a, int n) {
    if (n >= 0) return a << n;
    return shiftRight(a, n);
  }

  static int shiftRight(int a, int n) {
    if (n >= 0) return a >> n;
    return shiftLeft(a, n);
  }

  static int? float2Int(double f) {
    final i = f.toInt();

    if (i.toDouble() == f) {
      return i;
    }

    return null;
  }
}
