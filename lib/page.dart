import 'package:flutter/material.dart';

class Students extends StatefulWidget {
  const Students({Key? key}) : super(key: key);

  @override
  _StudentsState createState() => _StudentsState();
}

class _StudentsState extends State<Students> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text('NAME : SAFVAN P'),
        Text('CLASS : 10th'),
        Text('NAME : SAFVAN P'),
        Text('NAME : SAFVAN P'),
        Text('NAME : SAFVAN P'),
        Text('NAME : SAFVAN P'),
        Text('NAME : SAFVAN P'),
        Text('NAME : SAFVAN P'),
        Text('NAME : SAFVAN P'),
      ],
    );
  }
}
