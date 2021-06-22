import 'dart:typed_data';

import 'package:luart/src/api/lua_result.dart';
import 'package:luart/src/state/lua_stack.dart';
import 'package:luart/src/state/lua_table.dart';
import 'package:luart/src/state/lua_state.dart';

enum LuaArithOp {
  add,
  sub,
  mul,
  mod,
  pow,
  div,
  idiv,
  band,
  bor,
  bxor,
  shl,
  shr,
  unm,
  bnot,
}

enum LuaCompareOp {
  eq, // ==
  lt, // <
  le, // <=
}

enum LuaType {
  none,
  nil,
  boolean,
  lightuserdata,
  number,
  string,
  table,
  function,
  userdata,
  thread,
}

extension LuaTypeX on LuaType {
  String get typeName {
    switch (this) {
      case LuaType.none:
        return 'no value';
      case LuaType.nil:
        return 'nil';
      case LuaType.boolean:
        return 'boolean';
      case LuaType.number:
        return 'number';
      case LuaType.string:
        return 'string';
      case LuaType.table:
        return 'table';
      case LuaType.function:
        return 'function';
      case LuaType.thread:
        return 'thread';
      default:
        return 'userdata';
    }
  }
}

enum LuaStatus {
	ok,
	isYield,
	errRun,
	errSyntax,
	errMem,
	errGcmm,
	errErr,
	errFile,
}

typedef LuaDartFunction = int Function(LuaState);

abstract class LuaState {
  factory LuaState() = LuaStateImpl;

  LuaTable? get registry;

  LuaStack? get stack;

  set registry(LuaTable? luaTable);

  /// Returns the index of the top element in the stack. Because indices start
  /// at 1, this result is equal to the number of elements in the stack; in
  /// particular, 0 means an empty stack.
  int getTop();

  /// Converts the acceptable index [idx] into an equivalent absolute index
  /// (that is, one that does not depend on the stack top).
  int absIndex(int idx);

  /// Ensures that the stack has space for at least n extra slots (that is, that
  /// you can safely push up to [n] values into it). It returns false if it
  /// cannot fulfill the request, either because it would cause the stack to be
  /// larger than a fixed maximum size (typically at least several thousand
  /// elements) or because it cannot allocate memory for the extra space. This
  /// function never shrinks the stack; if the stack already has space for the
  /// extra slots, it is left unchanged.
  bool checkStack(int n);

  /// Get a instruction code from the top of stack
  int fetch();

  /// Pops n elements from the stack.
  void pop(int n);

  /// Copies the element at index [fromIdx] into the valid index [toIdx],
  /// replacing the value at that position. Values at other positions are not
  /// affected.
  void copy(int fromIdx, int toIdx);

  /// Pushes a copy of the element at the given index onto the stack.
  void pushValue(int idx);

  /// Moves the top element into the given valid index without
  /// shifting any element (therefore replacing the value at that given index),
  /// and then pops the top element.
  void replace(int idx);

  /// Moves the top element into the given valid index, shifting up the elements
  /// above this index to open space. This function cannot be called with a
  /// pseudo-index, because a pseudo-index is not an actual stack position.
  void insert(int idx);

  /// Removes the element at the given valid index, shifting down the elements
  /// above this index to fill the gap. This function cannot be called with a
  /// pseudo-index, because a pseudo-index is not an actual stack position.
  void remove(int idx);

  /// Rotates the stack elements between the valid index idx and the top of the
  /// stack. The elements are rotated [n] positions in the direction of the top,
  /// for a positive n, or -n positions in the direction of the bottom, for a
  /// negative n. The absolute value of n must not be greater than the size of
  /// the slice being rotated. This function cannot be called with a
  /// pseudo-index, because a pseudo-index is not an actual stack position.
  void rotate(int idx, int n);

  /// Accepts any index, or 0, and sets the stack top to this index. If the new
  /// top is larger than the old one, then the new elements are filled with nil.
  /// If index is 0, then all stack elements are removed.
  void setTop(int idx);

  /// Exchange values between different threads of the same state.
  /// This function pops [n] values from the stack from, and pushes them onto
  /// the stack [to].
  // void xMove(LuaState to, int n);

  /** access functions (stack -> Dart) **/

  /// Returns the type name of the value in the given valid index
  String typeName(int idx);

  /// Returns the type of the value in the given valid index, or [LuaType.none]
  /// for a non-valid (but acceptable) index.
  LuaType type(int idx);

  /// Returns [true] if the given index is not valid, and [false] otherwise.
  bool isNone(int idx);

  /// Returns [true] if the value at the given index is nil, and [false]
  /// otherwise.
  bool isNil(int idx);

  /// Returns [true] if the given index is not valid or if the value at this
  /// index is nil, and [false] otherwise.
  bool isNoneOrNil(int idx);

  /// Returns [true] if the value at the given index is a boolean, and [false]
  /// otherwise.
  bool isBool(int idx);

  /// Returns [true] if the value at the given index is an integer (that is, the
  /// value is a number and is represented as an integer), and [false] otherwise.
  bool isInt(int idx);

  /// Returns [true] if the value at the given index is a number or a string
  /// convertible to a number, and [false] otherwise.
  bool isNumber(int idx);

  /// Returns [true] if the value at the given index is a string or a number
  /// (which is always convertible to a string), and [false] otherwise.
  bool isString(int idx);

  /// Returns [true] if the value at the given index is a table, and [false]
  /// otherwise.
  bool isTable(int idx);

  /// Returns [true] if the value at the given index is a thread, and [false]
  /// otherwise.
  // bool isThread(int idx);

  /// Returns [true] if the value at the given index is a function
  /// (either Dart or Lua), and [false] otherwise.
  bool isFunction(int idx);

  /// Returns [true] if the value at the given index is a Dart function, and
  /// [false] otherwise.
  bool isDartFunction(int idx);

  /// Converts the Lua value at the given index to a Dart bool value. Like all
  /// tests in Lua, [toBool] returns [true] for any Lua value different from
  /// false and nil; otherwise it returns false. (If you want to accept only
  /// actual boolean values, use [isBoolean] to test the value's type.)
  bool toBool(int idx);

  /// Converts the Lua value at the given index to a Dart integer. The Lua value
  /// must be an integer, or a number or string convertible to an integer;
  /// otherwise, a [TypeError] is thrown.
  int toInt(int idx);
  LuaResult toIntX(int idx);

  /// Converts the Lua value at the given index to a Dart double. The Lua value
  /// must be an number, or a number or string convertible to an number;
  /// otherwise, a [TypeError] is thrown.
  double toNumber(int idx);
  LuaResult toNumberX(int idx);

  /// Converts the Lua value at the given index to a Dart string. The Lua value
  /// must be a string or a number; otherwise, [null] is returned.
  String? toDartString(int idx);

  /// Converts a value at the given index to a Dart function. That value must be
  /// a Dart function; otherwise, returns [null].
  LuaDartFunction? toDartFunction(int idx);

  // LuaState toThread(int idx) ;
  // dynamic toPointer(int idx);

  int rawLen(int idx);

  // /* push functions (Dart -> stack) */

  /// Pushes a nil value onto the stack.
  void pushNil();

  /// Pushes a bool value onto the stack.
  void pushBool(bool b);

  /// Pushes a int value onto the stack.
  void pushInt(int n);

  /// Pushes a double value onto the stack.
  void pushNumber(double n);

  /// Pushes a String value onto the stack.
  void pushString(String s);

  /// Pushes a Dart function onto the stack. This function receives a pointer to
  /// a Dart function and pushes onto the stack a Lua value of type function
  /// that, when called, invokes the corresponding dart function.
  ///
  /// Any function to be callable by Lua must follow the correct protocol to
  /// receive its parameters and return its results.
  void pushDartFunction(LuaDartFunction f);

  /// Pushes a new Dart closure onto the stack.
  void pushDartClosure(LuaDartFunction f, int n);

  /// Pushes the global environment onto the stack.
  void pushGlobalTable();

  // void pushThread()

  // /* Comparison and arithmetic functions */

  ///  Performs an arithmetic or bitwise operation over the two values (or one,
  /// in the case of negations) at the top of the stack, with the value at the
  /// top being the second operand, pops these values, and pushes the result of
  /// the operation. The function follows the semantics of the corresponding Lua
  /// operator (that is, it may call metamethods).
  ///
  /// [LuaArithOp.add]: performs addition (+)
  /// [LuaArithOp.sub]: performs subtraction (-)
  /// [LuaArithOp.mul]: performs multiplication (*)
  /// [LuaArithOp.div]: performs float division (/)
  /// [LuaArithOp.idiv]: performs floor division (//)
  /// [LuaArithOp.mod]: performs modulo (%)
  /// [LuaArithOp.pow]: performs exponentiation (^)
  /// [LuaArithOp.unm]: performs mathematical negation (unary -)
  /// [LuaArithOp.bnot]: performs bitwise NOT (~)
  /// [LuaArithOp.band]: performs bitwise AND (&)
  /// [LuaArithOp.bor]: performs bitwise OR (|)
  /// [LuaArithOp.bxor]: performs bitwise exclusive OR (~)
  /// [LuaArithOp.shl]: performs left shift (<<)
  /// [LuaArithOp.shr]: performs right shift (>>)
  void arith(LuaArithOp operation);

  /// Compares two Lua values. Returns true if the value at index index1
  /// satisfies op when compared with the value at index index2, following the
  /// semantics of the corresponding Lua operator (that is, it may call
  /// metamethods). Otherwise returns false. Also returns false if any of the
  /// indices is not valid.
  ///
  /// The value of op must be one of the following constants:
  ///
  /// [LuaCompareOp.eq]: compares for equality (==)
  /// [LuaCompareOp.lt]: compares for less than (<)
  /// [LuaCompareOp.le]: compares for less or equal (<=)
  bool compare(int idx1, int idx2, LuaCompareOp op);

  /// Returns [true] if the two values in indices [index1] and [index2] are
  /// primitively equal (that is, without calling the __eq metamethod).
  /// Otherwise returns [false]. Also returns [false] if any of the indices are
  /// not valid.
  bool rawEqual(int index1, int index2);

  // /* get functions (Dart -> stack) */

  /// Creates a new empty table and pushes it onto the stack. It is equivalent
  /// to createTable(0, 0).
  void newTable();

  /// Creates a new empty table and pushes it onto the stack. Parameter [nArr]
  /// is a hint for how many elements the table will have as a sequence;
  /// parameter [nRec] is a hint for how many other elements the table will
  /// have. Lua may use these hints to preallocate memory for the new table.
  /// This preallocation is useful for performance when you know in advance how
  /// many elements the table will have. Otherwise you can use the method
  /// [newTable].
  void createTable(int nArr, int nRec);

  /// Pushes onto the stack the value t[k], where t is the value at the given
  /// index and k is the value at the top of the stack.
  ///
  /// This function pops the key from the stack, pushing the resulting value in
  /// its place. As in Lua, this function may trigger a metamethod for the
  /// "index" event
  LuaType getTable(int idx);

  /// Pushes onto the stack the value t[key], where t is the value at the given
  /// index. As in Lua, this function may trigger a metamethod for the "index"
  /// event.
  ///
  /// Returns the type of the pushed value.
  LuaType getField(int idx, String key);

  /// Pushes onto the stack the value t[i], where t is the value at the given
  /// index. As in Lua, this function may trigger a metamethod for the "index"
  /// event.
  ///
  /// Returns the type of the pushed value.
  LuaType getI(int idx, int i);

  /// Similar to [getTable], but does a raw access (i.e., without metamethods).
  LuaType rawGet(int idx);

  /// Pushes onto the stack the value t[n], where t is the table at the given
  /// index. The access is raw, that is, it does not invoke the __index
  /// metamethod.
  ///
  /// Returns the type of the pushed value.
  LuaType rawGetI(int idx, int i);

  /// Pushes onto the stack the metatable associated with name tname in the
  /// registry ([null] if there is no metatable associated with that name).
  /// Returns the type of the pushed value.
  // bool getMetatable(int idx) ;

  /// Pushes onto the stack the value of the global [name]. Returns the type of
  /// that value.
  LuaType getGlobal(String name);

  /* set functions (stack -> Dart) */

  /// Does the equivalent to t[k] = v, where t is the value at the given index,
  /// v is the value at the top of the stack, and k is the value just below the
  /// top.
  ///
  /// This function pops both the key and the value from the stack. As in Lua,
  /// this function may trigger a metamethod for the "newindex" eventß.
  void setTable(int idx);

  /// Does the equivalent to t[k] = v, where t is the value at the given index
  /// and v is the value at the top of the stack.
  ///
  /// This function pops the value from the stack. As in Lua, this function may
  /// trigger a metamethod for the "newindex" event.
  void setField(int idx, String k);

  /// Does the equivalent to t[i] = v, where t is the value at the given index
  /// and v is the value at the top of the stack.
  ///
  /// This function pops the value from the stack. As in Lua, this function may
  /// trigger a metamethod for the "newindex" event (see §2.4).
  void setI(int idx, int i);

  /// Similar to setTable, but does a raw assignment (i.e., without
  /// metamethods).
  void rawSet(int idx);

  /// Does the equivalent of t[i] = v, where t is the table at the given index
  /// and v is the value at the top of the stack.
  ///
  /// This function pops the value from the stack. The assignment is raw, that
  /// is, it does not invoke the __newindex metamethod.
  void rawSetI(int idx, int i);

  /// Pops a table from the stack and sets it as the new metatable for the value
  /// at the given index.
  void setMetatable(int idx);

  /// Get a table from stack.
  bool getMetatable(int idx);

  /// Pops a value from the stack and sets it as the new value of global name.
  void setGlobal(String name);

  /// Sets the Dart function f as the new value of global name. `register(name,
  /// f)` is equivalent to `state.pushDartFunction(f); state.setGlobal(name);`
  void register(String name, LuaDartFunction f);

  /* 'load' and 'call' functions (load and run Lua code) */

  /// Loads a Lua chunk without running it. If there are no errors, [load]
  /// pushes the compiled chunk as a Lua function on top of the stack.
  LuaStatus load(Uint8List chunk, String chunkName);

  /// Calls a function.
  ///
  /// To call a function you must use the following protocol: first, the
  /// function to be called is pushed onto the stack; then, the arguments to the
  /// function are pushed in direct order; that is, the first argument is pushed
  /// first. Finally you call [state.call()]; nArgs is the number of arguments
  /// that you pushed onto the stack. All arguments and the function value are
  /// popped from the stack when the function is called. The function results
  /// are pushed onto the stack when the function returns. The number of results
  /// is adjusted to nResults, unless nResults is LUA_MULTRET. In this case, all
  /// results from the function are pushed; Lua takes care that the returned
  /// values fit into the stack space, but it does not ensure any extra space in
  /// the stack. The function results are pushed onto the stack in direct order
  /// (the first result is pushed first), so that after the call the last result
  /// is on the top of the stack.
  ///
  /// Any error inside the called function is propagated upwards (with a
  /// longjmp).
  ///
  /// The following example shows how the host program can do the equivalent to
  /// this Lua code:
  ///
  /// ```
  /// a = f("how", t.x, 14)
  /// ```
  ///
  /// Here it is in Dart:
  ///
  /// ```
  /// state.getGlobal("f");                  /* function to be called */
  /// state.pushString("how");                        /* 1st argument */
  /// state.getGlobal("t");                    /* table to be indexed */
  /// state.getField(-1, "x");        /* push result of t.x (2nd arg) */
  /// state.remove(-2);                  /* remove 't' from the stack */
  /// state.pushInt(14);                              /* 3rd argument */
  /// state.call(3, 1);     /* call 'f' with 3 arguments and 1 result */
  /// state.setGlobal("a");                         /* set global 'a' */
  /// ```
  ///
  /// Note that the code above is balanced: at its end, the stack is back to its
  /// original configuration. This is considered good programming practice.
  void call(int nArgs, int nResults);

  /// Calls a function in protected mode.
  ///
  /// Both [nArgs] and [nResults] have the same meaning as in [call]. If there
  /// are no errors during the call, [pCall] behaves exactly like [call].
  /// However, if there is any error, [pCall] catches it, pushes a single value
  /// on the stack (the error object), and returns an error code. Like [call],
  /// [pCall] always removes the function and its arguments from the stack.
  ///
  /// If [msgHandler] is 0, then the error object returned on the stack is
  /// exactly the original error object. Otherwise, [msgHandler] is the stack
  /// index of a message handler. (This index cannot be a pseudo-index.) In case
  /// of runtime errors, this function will be called with the error object and
  /// its return value will be the object returned on the stack by [pCall].
  ///
  /// Typically, the message handler is used to add more debug information to
  /// the error object, such as a stack traceback. Such information cannot be
  /// gathered after the return of [pCall], since by then the stack has unwound.
  ///
  /// The [pCall] function returns one of the following constants (defined in
  /// lua.h):
  /// ```
  /// LuaStatus.ok (0): success.
  /// LuaStatus.errRun: a runtime error.
  /// LuaStatus.errMem: memory allocation error. For such errors, Lua does not call the message handler.
  /// LuaStatus.errErr: error while running the message handler.
  /// LuaStatus.errGcmm: error while running a __gc metamethod. For such errors, Lua does not call the message handler (as this kind of error typically has no relation with the function being called).
  /// ```
  LuaStatus pCall(int nArgs, int nResults, int msgHandler);

  /* miscellaneous functions */

  /// Returns the length of the value at the given index. It is equivalent to
  /// the '#' operator in Lua and may trigger a metamethod for the "length"
  /// event. The result is pushed on the stack.
  void len(int idx);

  /// Concatenates the [n] values at the top of the stack, pops them, and leaves
  /// the result at the top. If n is 1, the result is the single value on the
  /// stack (that is, the function does nothing); if n is 0, the result is the
  /// empty string. Concatenation is performed following the usual semantics of
  /// Lua.
  void concat(int n);

  /// Pops a key from the stack, and pushes a key–value pair from the table at
  /// the given index (the "next" pair after the given key). If there are no
  /// more elements in the table, then [next] returns false (and pushes
  /// nothing).
  // bool next(int idx);

  /// Generates a Lua error, using the value at the top of the stack as the
  /// error object. This function does a long jump, and therefore never returns
  int error();

  /// Converts [s] to a number, pushes that number into the stack. The
  /// conversion can result in an integer or a float, according to the lexical
  /// conventions of Lua. The string may have leading and trailing spaces and a
  /// sign. If the string is not a valid numeral, returns false and pushes
  /// nothing.
  bool stringToNumber(String s);

  bool next(int idx);

  /* coroutine functions */

  // LuaState newThread();
  // int resume(LuaState from, int nArgs);
  // int yield(int nResults);
  // int status();
  // bool isYieldable();
  // bool getStack(); // debug
}
