// ignore_for_file: overridden_fields

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
  LuaCompilerError([String message = 'lua compiler error']) : super(message);
}

class LuaRuntimeError extends LuaError {
  LuaRuntimeError(this.error);

  @override
  final message = 'lua runtime error';

  final Object? error;

  @override
  String toString() {
    return error == null ? 'LuaRuntimeError' : 'LuaRuntimeError: $error';
  }
}
