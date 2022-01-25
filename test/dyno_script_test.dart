import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dyno_script/dyno_script.dart';
import 'package:petitparser/petitparser.dart' as pet;

void main() {
  test('Execution', () {
    final file = File('test/program.dyno');
    String fileData = file.readAsStringSync();
    fileData = fileData.replaceAll(String.fromCharCode(13), '');
    var program = Program.parse(fileData);
    ExecutionState state = ExecutionState();
    state.functions['print'] = (args) {
      for (var item in args) {
        print(item);
      }
    };
    program.execute(state);
    // print(program.mainNode);
  });
  // test('Temp', () {
  //   print(ForStatement.parser.end().parse('for int 0 10 1:'));
  // });
}
