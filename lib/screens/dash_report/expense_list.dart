// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/models/expense_list_item_model.dart';
import 'package:sheraccerp/service/api_dio.dart';

class ExpenseList extends StatefulWidget {
  final ExpenseListItemModel ledger;
  var branchId;
  ExpenseList(this.ledger, this.branchId, {Key key}) : super(key: key);
  @override
  _ExpenseListState createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  DateTime now = DateTime.now();
  String formattedDate;
  List<ListItem> item = [];
  List<ListItem> tempData = [];
  DioService api = DioService();
  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('yyyy-MM-dd').format(now);
    tempData.add(ListItem(
        id: 1,
        eno: '101',
        date: '2020-01-01',
        name: 'Ledger Name 1',
        account: 'Account 1',
        amount: '100',
        balance: '10'));
    _fetchData(widget.branchId);
  }

  Future _fetchData(var branchId) async {
    api
        .fetchExpenseLedger(
            formattedDate, formattedDate, widget.ledger.id, branchId)
        .then((value) {
      setState(() {
        for (var data in value) {
          item.add(ListItem.fromJson(data));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ledger Report')),
      body: Column(
        children: [
          Card(
            elevation: 10,
            margin: const EdgeInsets.all(10),
            shadowColor: Colors.black,
            child: Column(
              children: [
                Text(
                  widget.ledger.party,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Column(
                  children: const [
                    Text('Opening',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('0.00',
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: const [
                          Text('UnCleared',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('0.00',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: const [
                          Text('Closing',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('0.00',
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10.0,
          ),
          item.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: item.length,
                  itemBuilder: (context, position) {
                    return createViewItem(item[position], context);
                  },
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tempData.length,
                  itemBuilder: (context, position) {
                    return createViewItem(tempData[position], context);
                  },
                ),
        ],
      ),
    );
  }

  Widget createViewItem(ListItem listItemModel, BuildContext context) {
    return ListTile(
      title: Card(
          elevation: 5.0,
          child: Container(
            padding: const EdgeInsets.all(1.0),
            margin: const EdgeInsets.all(1.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  child: Text(listItemModel.date,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  padding: const EdgeInsets.all(1.0)),
              Row(
                children: [
                  Padding(
                      child: Text(
                        listItemModel.eno,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                      padding: const EdgeInsets.all(1.0)),
                  Padding(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(listItemModel.account,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20)),
                          Text(listItemModel.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                      padding: const EdgeInsets.all(5.0)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                      child: Text('Debit : ' + listItemModel.amount,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      padding: const EdgeInsets.all(5.0)),
                  Padding(
                      child: Text('Balance : ' + listItemModel.balance,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      padding: const EdgeInsets.all(5.0)),
                ],
              )
            ]),
          )),
      onTap: () => _onTapItem(context, listItemModel),
    );
  }

  void _onTapItem(BuildContext context, ListItem statementItem) {
    //
  }
}

class ListItem {
  int id;
  String date;
  String eno;
  String account;
  String name;
  String amount;
  String balance;

  ListItem(
      {this.id,
      this.date,
      this.eno,
      this.account,
      this.name,
      this.amount,
      this.balance});

  Map<String, dynamic> toJson() => {
        "id": id,
        "date": date,
        "eno": eno,
        "account": account,
        "name": name,
        "amount": amount,
        "balance": balance
      };

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
        id: int.tryParse(json['id']),
        date: json['date'],
        eno: json['entryNo'].toString(),
        account: json['account'],
        name: json['name'],
        amount: json['amount'],
        balance: json['balance']);
  }
}
