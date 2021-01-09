class LuaError {
  LuaError([this.message = 'lua error']);

  final String message;

  @override
  String toString() => message;
}

class LuaVmError extends LuaError {
  @override
  final message = 'lua vm error';
}

class LuaArithmeticError extends LuaVmError {
  @override
  final message = 'lua arithmetic error';
}

class LuaCompilerError extends LuaError {
  LuaCompilerError(
    this.chunkName,
    this.line, [
    String message = 'lua compiler error',
  ]) : super(message);

  final String chunkName;
  final int line;

  @override
  String toString() => '$chunkName:$line $message';
}
