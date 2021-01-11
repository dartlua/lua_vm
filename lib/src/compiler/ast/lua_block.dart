// block ::= {stat} [retstat]
// retstat ::= return [explist] [‘;’]
// explist ::= exp {‘,’ exp}
import 'package:luart/src/compiler/ast/lua_exp.dart';
import 'package:luart/src/compiler/ast/lua_stat.dart';

class LuaBlock {
  LuaBlock({
    required this.lastLine,
    required this.stats,
    required this.retExps,
  });

  final int lastLine;
  final List<LuaStat> stats;
  final List<LuaExp>? retExps;
}
