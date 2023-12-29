import 'package:flutter/material.dart';
import 'package:sheraccerp/models/sales_model.dart';

class SerialNoListWidget extends StatelessWidget {
  SerialNoListWidget({Key? key, required this.serialNOModel}) : super(key: key);
  List<SerialNOModel> serialNOModel;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: serialNOModel.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('data${serialNOModel[index].serialNo}'),
        );
      },
    );
  }
}
