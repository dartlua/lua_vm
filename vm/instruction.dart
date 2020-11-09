import '../constants.dart';

class Instruction{
  int instruction;

  Instruction(int this.instruction);

  int opCode() => instruction & 0x3f;

  List<int> ABC() => [
    instruction >> 6 & 0xff,
    instruction >> 14 & 0x1ff,
    instruction >> 23 & 0x1ff
  ];

  List<int> ABx() => [
    instruction >> 6 & 0xff,
    instruction >> 14
  ];

  List<int> AsBx() {
    var a = ABx();
    return [a[0], a[1] - MAXARG_sBx];
  }

  int Ax() => instruction >> 6;

  String opName() => opCodes[opCode()].name;

  int opMode() => opCodes[opCode()].opMode;

  int BMode() => opCodes[opCode()].argBMode;

  int CMode() => opCodes[opCode()].argCMode;
}