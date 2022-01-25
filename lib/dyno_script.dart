library dyno_script;

import 'nodes.dart';
import 'package:petitparser/petitparser.dart';

class ParserState {
  int indentation = 2;
}

class Program {
  Node mainNode;

  Program(this.mainNode);

  static Program parse(String input) {
    Node main = Node(MainStatement());
    List<String> linesStr = input.split('\n');
    List<Line> lines = [];
    ParserState parserState = ParserState();

    for (var lineStr in linesStr) {
      Line? line = Line.parseFromString(lineStr, parserState);
      if (line != null) {
        lines.add(line);
      }
    }
    main.addLines(lines, 0);
    return Program(main);
  }

  void execute(ExecutionState state) {
    mainNode.execute(state);
  }
}

class UnexpectedIndent implements Exception {
  final String message;
  UnexpectedIndent(this.message);

  @override
  String toString() {
    return 'Exception: $message';
  }
}

class ParserException implements Exception {
  final String message;
  ParserException(this.message);
}

class VariableName {
  String name;

  VariableName(this.name);

  static final Parser<String> parser =
      letter().seq(letter().or(digit()).or(char('_')).star()).flatten();
}

class Line {
  int indent;
  String text;
  Statement statement;

  Line(this.indent, this.text, this.statement);

  execute(ExecutionState state) {
    return statement.execute(state);
  }

  static Line? parseFromString(String input, ParserState parserState) {
    int indent = 0;
    bool inIndent = true;
    String text = '';
    Statement? statement;

    for (var i = 0; i < input.length; i++) {
      if (input[i] != ' ') {
        inIndent = false;
        text += input[i];
      } else if (inIndent) {
        indent++;
      } else {
        text += input[i];
      }
    }

    if (text.isNotEmpty) {
      statement = Statement.parseFromString(text);
    }
    if (indent % parserState.indentation != 0) {
      throw UnexpectedIndent(
          'Expected the indentation of the line to be a multiple of ${parserState.indentation}. Got $indent');
    } else {
      indent ~/= parserState.indentation;
    }
    if (statement == null) {
      return null;
    }
    return Line(indent, text, statement);
  }
}

typedef DynoFunction = Function(List<dynamic>);

class ExecutionState {
  Map<String, dynamic> variables = {};
  Map<String, DynoFunction> functions = {};
}

abstract class Statement {
  execute(ExecutionState state, {List<Node> children = const []});

  static Statement parseFromString(String input) {
    final List<Parser<Statement>> statementParsers = [
      AssingStatement.parser,
      ExpressionStatement.parser,
      ForStatement.parser,
    ];
    for (Parser<Statement> parser in statementParsers) {
      final result = parser.end().parse(input);
      if (result.isSuccess) {
        return result.value;
      }
    }
    throw ParserException('Could not parse the statement.');
    // AssingStatement? assingStatement = AssingStatement.tryParse(input);
    // if (assingStatement != null) {
    //   return assingStatement;
    // }
    // ExpressionStatement? expressionStatement =
    //     ExpressionStatement.tryParse(input);
    // if (expressionStatement != null) {
    //   return expressionStatement;
    // }
    // ForStatement? forStatement = ForStatement.tryParse(input);
    // if (forStatement != null) {
    //   return forStatement;
    // }
  }
}

class MainStatement implements Statement {
  @override
  execute(ExecutionState state, {List<Node>? children}) {
    for (var line in children!) {
      line.execute(state);
    }
  }
}

class AssingStatement implements Statement {
  String variable;
  Expression expression;

  AssingStatement(this.variable, this.expression);

  static Parser<Statement> get parser =>
      (VariableName.parser & char('=') & ExpressionGrammar.parser)
          .map((parsed) {
        return AssingStatement(parsed[0], parsed[2]);
      });

  @override
  execute(ExecutionState state, {List<Node>? children}) {
    state.variables[variable] = expression.evaluate(state);
    return null;
  }
}

class FunctionStatement implements Statement {
  @override
  void execute(ExecutionState state, {List<Node>? children}) {}
}

class ExpressionStatement implements Statement {
  Expression expression;

  ExpressionStatement(this.expression);

  static Parser<Statement> get parser =>
      ExpressionGrammar.parser.map((value) => ExpressionStatement(value));

  @override
  void execute(ExecutionState state, {List<Node>? children}) {
    expression.evaluate(state);
  }
}

class ForStatement implements Statement {
  String variable;
  Expression start;
  Expression end;
  Expression step;

  ForStatement(this.variable, this.start, this.end, this.step);

  static Parser<Statement> get parser => (string('for') &
          char(' ') &
          VariableName.parser &
          char(' ') &
          string('in') &
          char(' ') &
          ExpressionGrammar.parser &
          string('..') &
          ExpressionGrammar.parser &
          (string(' step ') & ExpressionGrammar.parser).optional() &
          char(':'))
      .map((value) => ForStatement(value[2], value[6], value[8],
          value.length > 10 ? value[9][1] : IntegerExpression(1)));

  @override
  void execute(ExecutionState state, {List<Node>? children}) {
    var startValue = start.evaluate(state);
    var endValue = end.evaluate(state);
    var stepValue = step.evaluate(state);
    assert(startValue is int);
    assert(endValue is int);
    assert(stepValue is int);
    assert(startValue <= endValue);
    assert(stepValue > 0);
    for (var i = startValue; i < endValue; i += stepValue) {
      state.variables[variable] = i;
      if (children != null) {
        for (var statement in children.map((e) => e.statement!)) {
          statement.execute(state);
        }
      }
    }
  }
}

// An expression is never in an evaluated state, but can be evaluated at runtime.
abstract class Expression {
  dynamic evaluate(ExecutionState state);
}

class ExpressionGrammar extends GrammarDefinition {
  static Parser<Expression> parser = ExpressionGrammar().build<Expression>();

  @override
  Parser start() {
    return ref0(fullExpression).cast<Expression>();
  }

  Parser<Expression> fullExpression() {
    return (ref0(_function) |
            ref0(_double) |
            ref0(_integer) |
            ref0(_variable) |
            ref0(_string) |
            ref0(_parans))
        .map((value) => value as Expression);
  }

  Parser<Expression> _function() => (VariableName.parser &
          char('(') &
          ref0(fullExpression) &
          (char(',') & ref0(fullExpression)).star() &
          char(')'))
      .map((value) => FunctionExpression(
          value[0], [value[2], ...value[3].map((e) => e[1])]));
  Parser<Expression> _integer() => digit()
      .plus()
      .flatten()
      .map((value) => IntegerExpression(int.parse(value)));
  Parser<Expression> _double() =>
      (digit().star() & char('.').optional() & digit().plus())
          .flatten()
          .map((value) => DoubleExpression(double.parse(value)));
  Parser<Expression> _parans() => (char('(') & ref0(fullExpression) & char(')'))
      .map((value) => value[1] as Expression);
  Parser<Expression> _variable() =>
      VariableName.parser.map((value) => VariableExpression(value));
  Parser<Expression> _string() => ((char('"') &
              char('"').neg().or(string(r'\"')).star() &
              char('"')) |
          (char("'") & char("'").neg().or(string(r"\'")).star() & char("'")))
      .map((value) => StringExpression(value[1].join()
        ..replaceAll(r"\'", "'")
        ..replaceAll(r'\"', '"')));
}

// class ExpressionGrammar extends GrammarDefinition {
//   @override
//   Parser<Expression> start() {
//     return ref0(parser);
//   }

//   Parser<Expression> parser() {
//     final builder = ExpressionBuilder();
//     builder.group()
//       ..primitive(ref0(_singleExpression))
//       ..wrapper(char('('), char(')'), (String l, dynamic a, String r) => a);
//     // builder.group().prefix(char('-'), (String op, num a) => -a);
//     // builder.group().prefix(char('~'), (String op, dynamic a) => ~a);
//     // builder.group().right(
//     //     char('^'), (num a, String op, num b) => math.pow(a, b));
//     for (Operator op in Operator.operators) {
//       builder.group().left(string(op.symbol),
//           (Expression a, String _, Expression b) => op.getExpression(a, b));
//     }
//     return ref0(() => builder.build().map((value) => value as Expression));
//   }

// }

class Operator {
  final String symbol;
  final Expression Function(Expression, Expression) getExpression;
  final dynamic Function(dynamic, dynamic) getValue;
  const Operator(this.symbol, this.getExpression, this.getValue);

  static List<Operator> operators = [
    Operator(
      '+',
      (a, b) => OperatorExpression(a, operators[0], b),
      (a, b) => a + b,
    ),
    Operator(
      '-',
      (a, b) => OperatorExpression(a, operators[1], b),
      (a, b) => a - b,
    ),
    Operator(
      '*',
      (a, b) => OperatorExpression(a, operators[2], b),
      (a, b) => a * b,
    ),
    Operator(
      '/',
      (a, b) => OperatorExpression(a, operators[3], b),
      (a, b) => a / b,
    ),
  ];
}

class OperatorExpression extends Expression {
  final Expression left;
  final Operator op;
  final Expression right;

  OperatorExpression(this.left, this.op, this.right);

  @override
  dynamic evaluate(ExecutionState state) {
    return op.getValue(left.evaluate(state), right.evaluate(state));
  }
}

class IntegerExpression extends Expression {
  final int value;

  IntegerExpression(this.value);

  @override
  dynamic evaluate(ExecutionState state) {
    return value;
  }

  @override
  String toString() {
    return value.toString();
  }
}

class DoubleExpression extends Expression {
  final double value;

  DoubleExpression(this.value);

  @override
  dynamic evaluate(ExecutionState state) {
    return value;
  }

  @override
  String toString() {
    return value.toString();
  }
}

class StringExpression extends Expression {
  final String value;

  StringExpression(this.value);

  @override
  dynamic evaluate(ExecutionState state) {
    return value;
  }

  @override
  String toString() {
    return value;
  }
}

class VariableExpression extends Expression {
  final String variable;

  VariableExpression(this.variable);

  @override
  dynamic evaluate(ExecutionState state) {
    return state.variables[variable];
  }
}

class FunctionExpression extends Expression {
  final String name;
  final List<Expression> arguments;

  FunctionExpression(this.name, this.arguments);

  @override
  dynamic evaluate(ExecutionState state) {
    return state.functions[name]
        ?.call(arguments.map((e) => e.evaluate(state)).toList());
  }
}

class Constants {
  static const List<String> reservedKeywords = [
    'if',
    'else',
    'while',
    'for',
    'true',
    'false',
    'null',
    'this',
    'return',
  ];
}
