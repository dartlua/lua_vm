int IFloorDiv(int a, int b) => (a / b).floor();

double FFloorDiv(double a, double b) => (a / b).floorToDouble();

int IMod(int a, int b) => a - IFloorDiv(a, b) * b;

double FMod(double a, double b) => a - FFloorDiv(a, b) * b;

int shiftLeft(int a, int n) {
  if (n >= 0) return a << n;
  return shiftRight(a, n);
}

int shiftRight(int a, int n) {
  if (n >= 0) return a >> n;
  return shiftLeft(a, n);
}

//return [int, bool]
List float2Int(double f) {
  var i = f.toInt();
  return [i, i.toDouble() == f];
}
