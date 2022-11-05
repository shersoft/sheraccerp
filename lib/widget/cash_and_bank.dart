import 'package:flutter/material.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/widget/loading.dart';

class CashAndBank extends StatelessWidget {
  DioService api = DioService();
  var dropDownBranchId;
  DateTime now = DateTime.now();

  CashAndBank({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String dated = now.year.toString() +
        '-' +
        now.month.toString() +
        '-' +
        now.day.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 1,
          child: Card(
            elevation: 2,
            child: Container(
                alignment: Alignment.center,
                child: const Text(
                  'Cash & Bank',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                )),
          ),
        ),
        Expanded(
          flex: 9,
          child: FutureBuilder(
              future: api.fetchCashBankLedger(dated, dated),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Loading();
                } else {
                  return snapshot.hasData
                      ? Column(
                          children: [
                            Expanded(
                              flex: 10,
                              child: ListView.separated(
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                        color: Colors.black,
                                      ),
                                  shrinkWrap: true,
                                  itemCount: snapshot.data[0].length,
                                  padding: const EdgeInsets.all(0),
                                  itemBuilder:
                                      (BuildContext context, int position) {
                                    return createViewItem(
                                        snapshot.data[0][position], context);
                                  }),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Total : ${snapshot.data[1][0]['total']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ),
                          ],
                        )
                      : Text("${snapshot.error}");
                }
              }),
        )
      ],
    );
  }

  Widget createViewItem(Map<String, dynamic> data, BuildContext context) {
    return ListTile(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Visibility(
              visible: false,
              child: Padding(
                  child: Text(
                    data['slno'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  padding: const EdgeInsets.all(2.0)),
            ),
            Padding(
                child: Text(
                  data['name'],
                  textAlign: TextAlign.justify,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 19),
                  maxLines: 2,
                ),
                padding: const EdgeInsets.all(1.0)),
          ],
        ),
        Padding(
            child: Text(
              '${data['amount']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
              textAlign: TextAlign.right,
            ),
            padding: const EdgeInsets.all(1.0)),
      ]),
      // onTap: () => _onTapItem(context, listItemModel),
    );
  }
}
