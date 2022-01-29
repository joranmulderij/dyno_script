import 'dyno_script.dart';

class Node {
  Statement? statement;
  List<Node> children = [];
  final Map<String, dynamic> _variables = {};

  Node(this.statement);

  // Map<String, dynamic> get recursiveVariables {
  //   assert(statement is AssingStatement || statement is WidgetCreateStatement);
  //   print(_variables);
  //   Map<String, dynamic> variables = {};
  //   for (var child in children) {
  //     variables.addAll(child.recursiveVariables);
  //   }
  //   variables.addAll(_variables);
  //   return variables;
  // }

  int addLines(List<Line> lines, int expectedIndent) {
    for (var i = 0; i < lines.length; i++) {
      Line line = lines[i];
      if (line.indent == expectedIndent) {
        // if (statement is WidgetCreateStatement) {
        //   children.add(WidgetNode(line.statement as WidgetCreateStatement));
        // } else {
        //   children.add(Node(line.statement));
        // }
        children.add(Node(line.statement));
      } else if (line.indent == expectedIndent + 1) {
        i += children.last.addLines(lines.sublist(i), line.indent);
      } else if (line.indent < expectedIndent) {
        return i - 1;
      }
    }
    return lines.length;
  }

  void execute(StateInteractor stateInteractor) {
    if (statement != null) {
      statement!.execute(
        StateInteractor(
          getVariable: (name) {
            if (_variables.containsKey(name)) {
              return _variables[name];
            } else {
              return stateInteractor.getVariable(name);
            }
          },
          setVariable: (name, value, {calledByParent = false}) {
            if (stateInteractor.getVariable(name) == null &&
                children.isNotEmpty &&
                calledByParent) {
              _variables[name] = value;
            } else {
              stateInteractor.setVariable(name, value, calledByParent: true);
            }
          },
        ),
        children: children,
      );
    }
  }

  @override
  String toString() {
    return 'Node{statement: $statement, children: $children}';
  }
}

// class WidgetNode extends Node {
//   WidgetNode(WidgetCreateStatement statement) : super(statement);
// }

class StateInteractor {
  dynamic Function(String) getVariable;
  void Function(String, dynamic, {bool calledByParent}) setVariable;

  StateInteractor({required this.getVariable, required this.setVariable});

  dynamic operator [](String name) => getVariable(name);
  operator []=(String n, dynamic v) => setVariable(n, v);
}
