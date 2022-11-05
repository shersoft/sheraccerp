// @dart = 2.11
import 'package:flutter/material.dart';

class PopUpMenuAction extends StatelessWidget {
  VoidCallback onDelete;
  VoidCallback onEdit;

  PopUpMenuAction({Key key, this.onDelete, this.onEdit}) : super(key: key);

  void showMenuSelection(String value) {
    switch (value) {
      case 'Delete':
        onDelete();
        break;
      case 'Edit':
        onEdit();
        break;
      // Other cases for other menu options
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert),
      onSelected: showMenuSelection,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
            value: 'Edit',
            child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
        const PopupMenuItem<String>(
            value: 'Delete',
            child: ListTile(leading: Icon(Icons.delete), title: Text('Delete')))
      ],
    );
  }
}
