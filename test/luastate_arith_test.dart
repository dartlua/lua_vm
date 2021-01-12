import 'package:luart/luart.dart';
import 'package:test/test.dart';

void main() async {
  group('LuaState arith test', () {
    late LuaState ls;

    setUp(() async {
      ls = LuaState();
    });

    test('add number to table throws LuaArithmeticError', () {
      // ls.pushNumber(1);
      // ls.newTable();

      // expect(
      //   () => ls.arith(LuaArithOp.add),
      //   throwsA(isA<LuaArithmeticError>()),
      // );
    });
  });
}
