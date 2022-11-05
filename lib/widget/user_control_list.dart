// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:sheraccerp/models/form_model.dart';

class UserControlList extends StatelessWidget {
  const UserControlList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      primary: false,
      padding: const EdgeInsets.all(8),
      children: [
        FormModel(title: 'InduceSmile.com', isChecked: false),
        FormModel(title: 'Flutter.io', isChecked: false),
        FormModel(title: 'google.com', isChecked: true),
        FormModel(title: 'youtube.com', isChecked: false),
        FormModel(title: 'yahoo.com', isChecked: false),
        FormModel(title: 'gmail.com', isChecked: false),
      ]
          .map(
            (FormModel item) => CheckboxListTile(
              title: Text(item.title),
              value: item.isChecked,
              onChanged: (bool val) {
                // setState(() => item.isChecked = val);
              },
            ),
          )
          .toList(),
    );
  }
}
