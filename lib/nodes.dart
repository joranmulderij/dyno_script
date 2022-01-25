import 'dyno_script.dart';

class Node {
  Statement? statement;
  List<Node> children = [];
  bool get isBlock => children.isNotEmpty;

  Node(this.statement);

  int addLines(List<Line> lines, int expectedIndent) {
    for (var i = 0; i < lines.length; i++) {
      Line line = lines[i];
      if (line.indent == expectedIndent) {
        children.add(Node(line.statement));
      } else if (line.indent == expectedIndent + 1) {
        i += children.last.addLines(lines.sublist(i), line.indent);
      } else if (line.indent < expectedIndent) {
        return i;
      }
    }
    return lines.length;
  }

  void execute(ExecutionState state) {
    if (statement != null) {
      statement!.execute(state, children: children);
    }
  }

  @override
  String toString() {
    return 'Node{statement: $statement, children: $children}';
  }
}

// enum NodeType {
//   main,
//   function,
//   ifStatement,
//   whileStatement,
//   forStatement,
// }
