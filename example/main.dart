import 'package:dyno_script/dyno_script.dart';
import 'package:flutter/material.dart';

void main() {
  String fileData = '''widget avatar:
  materialApp:
    scaffold:
      column:
        for i in 0..10:
          print('f')
        text:
          text: '33'
        text:
          text: 'ffff'
        text:
          text: 'ffff'
        text:
          text: 'ffff'
        text:
          text: 'ffff'
        text:
          text: 'ffff'
        text:
          text: 'ffff'

runApp(avatar)''';
  fileData = fileData.replaceAll(String.fromCharCode(13), '');
  var program = Program.fromText(fileData, initialState: {
    'print': (args) {
      print(args.join(', '));
    },
    'runApp': (args) {
      runApp(args[0]);
    }
  });
  program.execute();
}
