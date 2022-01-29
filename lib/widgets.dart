import 'package:dyno_script/typedef.dart';
import 'package:flutter/material.dart';

class DynoWidget {
  final String name;
  final String description;
  final Map<String, dynamic> knownParameters;

  const DynoWidget(
      {required this.name,
      required this.description,
      required this.build,
      required this.knownParameters});

  final Widget Function(DynoMap data, List<Widget> children) build;

  static Map<String, DynoWidget> widgetList = {
    'text': DynoWidget(
      name: 'Text',
      description: 'Displays Text to the screen',
      build: (data, children) {
        return Text(data['text']);
      },
      knownParameters: {
        'text': null,
      },
    ),
    'container': DynoWidget(
      name: 'Text',
      description: 'Displays Text to the screen',
      build: (data, children) {
        return Container(
          child: children[0],
        );
      },
      knownParameters: {
        'text': null,
      },
    ),
    'column': DynoWidget(
      name: 'Text',
      description: 'Displays Text to the screen',
      build: (data, children) {
        return Column(
          children: children,
        );
      },
      knownParameters: {
        'text': null,
      },
    ),
    'scaffold': DynoWidget(
      name: 'Text',
      description: 'Displays Text to the screen',
      build: (data, children) {
        return Scaffold(
          body: children[0],
        );
      },
      knownParameters: {
        'text': null,
      },
    ),
    'materialApp': DynoWidget(
      name: 'Text',
      description: 'Displays Text to the screen',
      build: (data, children) {
        return MaterialApp(
          home: children[0],
        );
      },
      knownParameters: {
        'text': null,
      },
    ),
  };
}
