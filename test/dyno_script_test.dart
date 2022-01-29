import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dyno_script/dyno_script.dart';

void main() {
  test('Execution', () {
    final file = File('test/program.dyno');
    String fileData = file.readAsStringSync();
    fileData = fileData.replaceAll(String.fromCharCode(13), '');
    var program = Program.fromText(fileData, initialState: {
      'print': (args) {
        print(args.join(', '));
      },
    });
    program.execute();
    // print(program.mainNode);
  });
  // test('Temp', () {
  //   print(ForStatement.parser.end().parse('for int 0 10 1:'));
  // });
}
