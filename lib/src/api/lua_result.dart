class LuaResult {
  dynamic result;
  bool success;

  LuaResult(this.result, this.success);
  LuaResult.int(int this.result, this.success);
  LuaResult.double(double this.result, this.success);
}
