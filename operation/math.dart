int IFloorDiv(int a, int b){
  if(a > 0 && b > 0 || a < 0 && b > 0 || a % b == 0){
    return a ~/ b;
  }
  return (a ~/ b) - 1;
}

double FFloorDiv(double a, double b) => (a / b).floor().toDouble();

int IMod(int a, int b) => a - IFloorDiv(a, b) * b;

double FMod(double a, double b) => a - FFloorDiv(a, b) * b;

int shiftLeft(int a, int n){
  if(n >= 0) return a << n;
  return shiftRight(a, n);
}

int shiftRight(int a, int n){
  if(n >= 0) return a >> n;
  return shiftLeft(a, n);
}

//return [double, bool]
List float2Int(double f){
  int i = f.toInt();
  return [i, i.toDouble() == f];
}

