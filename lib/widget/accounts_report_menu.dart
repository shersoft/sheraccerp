import 'package:flutter/material.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';

class AccountsReportMenu extends StatelessWidget {
  const AccountsReportMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 2,
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
                    Icons.menu_book_rounded,
                    color: Colors.amber[200],
                    size: 90.0,
                  ),
                  const Text(
                    'Ledger Report',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'ledger'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
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
                    color: Colors.pink[300],
                    size: 90.0,
                  ),
                  const Text(
                    'Group List',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'GroupList'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
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
                    Icons.auto_stories,
                    color: Colors.green[300],
                    size: 90.0,
                  ),
                  const Text('Cash Book',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'CashBook'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
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
                    Icons.auto_stories,
                    color: Colors.blue[300],
                    size: 90.0,
                  ),
                  const Text('Day Book',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'DayBook'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
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
                    Icons.account_balance_rounded,
                    color: Colors.red[300],
                    size: 90.0,
                  ),
                  const Text(
                    'Trial Balance',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'TrialBalance'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
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
                    Icons.account_balance_rounded,
                    color: Colors.blue[300],
                    size: 90.0,
                  ),
                  const Text(
                    'Balance Sheet',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'BalanceSheet'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Image.asset('assets/icons/ic_report.png'),
                  const Text(
                    'P&L Account',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'P&LAccount'};
            Navigator.pushNamed(context, '/select_ledger');
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
                    Icons.balance_rounded,
                    color: Colors.blue[300],
                    size: 90.0,
                  ),
                  const Text(
                    'Balance Report',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'BalanceReport'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
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
                    Icons.show_chart_rounded,
                    color: Colors.green[300],
                    size: 90.0,
                  ),
                  const Text(
                    'Cash Flow',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'CashFlow'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
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
                    Icons.trending_up_rounded,
                    color: Colors.red[300],
                    size: 90.0,
                  ),
                  const Text(
                    'Fund Flow',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            // _showDialog(context);
            argumentsPass = {'mode': 'FundFlow'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
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
                    Icons.call_made_rounded,
                    color: Colors.cyan[300],
                    size: 90.0,
                  ),
                  const Text(
                    'Payable',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'Payable'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
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
                    Icons.call_received_rounded,
                    color: Colors.brown[200],
                    size: 90.0,
                  ),
                  const Text(
                    'Receivable',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'Receivable'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
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
                    Icons.ballot_rounded,
                    color: kPrimaryColor[300],
                    size: 90.0,
                  ),
                  const Text(
                    'Invoice \nBalance Customers',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'InvoiceWiseBalanceCustomers'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
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
                    Icons.ballot_rounded,
                    color: Colors.purple[300],
                    size: 90.0,
                  ),
                  const Text(
                    'Invoice\nBalance Suppliers',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'InvoiceWiseBalanceSuppliers'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
          },
        ),
        //Ledger_ReportProject
        //ReceivblesDebitOnly,
        //ReceivblesCreditOnly
        //ReceivblesDebitOnlySalesman
        //ReceivblesCreditOnlySalesman
        //Cash Book Projection
        //Trial_G_l
        //Trial_G
        //Custom Summary
        //Ledger_Report_Qty
        //ShowBills
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
