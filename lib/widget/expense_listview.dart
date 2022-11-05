// @dart = 2.7
import 'package:flutter/material.dart';
import 'package:sheraccerp/models/expense_list_item_model.dart';

class ExpenseListView extends StatelessWidget {
  final List<ExpenseListItemModel> listViewModels;
  var branchId;

  ExpenseListView({Key key, this.listViewModels, this.branchId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        separatorBuilder: (context, index) => const Divider(
              color: Colors.black,
            ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: listViewModels.length,
        padding: const EdgeInsets.all(15.0),
        itemBuilder: (context, position) {
          return createViewItem(listViewModels[position], context);
        });
  }

  Widget createViewItem(
      ExpenseListItemModel listItemModel, BuildContext context) {
    return ListTile(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Visibility(
            visible: false,
            child: Padding(
                child: Text(
                  listItemModel.eno,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                  textAlign: TextAlign.right,
                ),
                padding: const EdgeInsets.all(1.0))),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: Text(
                listItemModel.id.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
            Text(
              listItemModel.party,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
            ),
            const Spacer(),
            Text(
              listItemModel.amount,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ]),
      // onTap: () => _onTapItem(context, listItemModel),
    );
  }

  // void _onTapItem(BuildContext context, ExpenseListItemModel expenseItem) {
  //   Navigator.of(context).push(
  //       MaterialPageRoute(builder: (_) => ExpenseList(expenseItem, branchId)));
  // }
}
