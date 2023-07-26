// @dart = 2.9
import 'package:flutter/material.dart';
import 'package:sheraccerp/screens/about_shersoft.dart';
import 'package:sheraccerp/screens/report_view.dart';
import 'package:sheraccerp/shared/constants.dart';

class RecordListMenu extends StatelessWidget {
  const RecordListMenu({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: MediaQuery.of(context).size.width > 400
          ? (MediaQuery.of(context).size.width ~/ 250).toInt()
          : (MediaQuery.of(context).size.width ~/ 150).toInt(),
      children: <Widget>[
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Icon(
                    Icons.people,
                    color: Colors.orange[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Ledger List',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => const ReportView(
                        '0',
                        '1',
                        '2000-01-01',
                        '2000-01-01',
                        'LedgerList',
                        '',
                        'Ledger_List',
                        '0',
                        [1],
                        '0',
                        '0')));
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Icon(
                    Icons.people,
                    color: Colors.green[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Employee List',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => const ReportView(
                        '0',
                        '1',
                        '2000-01-01',
                        '2000-01-01',
                        'EmployeeList',
                        '',
                        'Employee List',
                        '0',
                        [1],
                        '0',
                        '0')));
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Icon(
                    Icons.people,
                    color: Colors.blue[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Customer Card List',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => const ReportView(
                        '0',
                        '1',
                        '2000-01-01',
                        '2000-01-01',
                        'CustomerCardList',
                        '',
                        'CustomerCardList',
                        '0',
                        [1],
                        '0',
                        '0')));
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Icon(
                    Icons.info,
                    color: Colors.red[500],
                    size: 90.0,
                  ),
                  const Text(
                    'About',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AboutSherSoft()),
            );
          },
        ),
      ],
    );
  }

  void _showDialog(BuildContext context) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 50.0,
                width: 50.0,
              ),
              const Text("SherAcc Alert"),
            ],
          ),
          content: const Text("Not Available. \nwe will update next time"),
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
