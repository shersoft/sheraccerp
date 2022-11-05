import 'package:flutter/material.dart';
import 'package:sheraccerp/models/statement_list_item_model.dart';

class StatementListView extends StatelessWidget {
  final List<StatementListItemModel> listViewModels;

  const StatementListView(this.listViewModels, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listViewModels.length,
      itemBuilder: (context, position) {
        return createViewItem(listViewModels[position], context);
      },
    );
  }

  Widget createViewItem(
      StatementListItemModel listItemModel, BuildContext context) {
    return ListTile(
      title: Card(
          elevation: 5.0,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black)),
            padding: const EdgeInsets.all(1.0),
            margin: const EdgeInsets.all(1.0),
            child: Column(children: [
              Padding(
                  child: Text(
                    listItemModel.eno,
                    // style: new TextStyle(
                    //     fontWeight: FontWeight.bold, fontSize: 20),
                    textAlign: TextAlign.right,
                  ),
                  padding: const EdgeInsets.all(1.0)),
              Row(
                children: [
                  Padding(
                      child: Text(
                        listItemModel.id.toString(),
                        // style: new TextStyle(
                        //     fontWeight: FontWeight.bold, fontSize: 20),
                        textAlign: TextAlign.right,
                      ),
                      padding: const EdgeInsets.all(1.0)),
                  Padding(
                      child: Text(
                        listItemModel.party + '(' + listItemModel.status + ')/',
                        // style: new TextStyle(
                        //     fontWeight: FontWeight.bold, fontSize: 22),
                        textAlign: TextAlign.left,
                      ),
                      padding: const EdgeInsets.all(1.0)),
                  Padding(
                      child: Text(
                        listItemModel.amount,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.right,
                      ),
                      padding: const EdgeInsets.all(1.0)),
                ],
              ),
            ]),
          )),
      onTap: () => _onTapItem(context, listItemModel),
    );
  }

  void _onTapItem(BuildContext context, StatementListItemModel statementItem) {
    //
  }
}
