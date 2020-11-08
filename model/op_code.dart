class OpCode{
  final int testFlag;
  final int setAFlag;
  final int argBMode;
  final int argCMode;
  final int opMode;
  final String name;

  OpCode(
      this.testFlag,
      this.setAFlag,
      this.argBMode,
      this.argCMode,
      this.opMode,
      this.name);
}