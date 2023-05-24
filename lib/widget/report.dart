// @dart = 2.7
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:sheraccerp/screens/report_view.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';

// ignore: must_be_immutable
class Report extends StatelessWidget {
  DioService api = DioService();
  DataJson location;

  Report({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(5),
      crossAxisSpacing: 0,
      mainAxisSpacing: 0,
      crossAxisCount: 2,
      children: <Widget>[
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Image.asset('assets/icons/ic_dashboard.png'),
                  const Text(
                    'Closing Report',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            argumentsPass = {'mode': 'closingReport'};
            Navigator.pushNamed(context, '/select_ledger');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Image.asset(
                    'assets/icons/task.png',
                    height: 85,
                    width: 90,
                  ),
                  const Text(
                    'Sales Daily',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/SalesList',
                arguments: {'title': 'Daily'});
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
                  Image.asset('assets/icons/ic_vieworder.png'),
                  const Text(
                    'Sales BillWise',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/SalesList',
                arguments: {'title': 'BillWise'});
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
                  Image.asset('assets/icons/ic_stockr.png'),
                  const Text('Sales ItemWise',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/SalesList',
                arguments: {'title': 'ItemWise'});
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
                  Image.asset('assets/icons/ic_pendingbill.png'),
                  const Text(
                    'Bill By Bill',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            // Navigator.push(
            //     context,
            //     new MaterialPageRoute(
            //         builder: (BuildContext context) =>
            //             new LedgerSelect(), 'billByBill'));
            argumentsPass = {'mode': 'billByBill'};
            Navigator.pushNamed(context, '/select_ledger');
          },
        ),
        GestureDetector(
            child: Card(
              elevation: 5.0,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    Image.asset('assets/icons/ic_msales.png'),
                    const Text(
                      'Monthly Sales',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              monthlyReport(context, 'Monthly Sales');
            }),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  Image.asset('assets/icons/ic_mpurchase.png'),
                  const Text(
                    'Monthly Purchase',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            monthlyReport(context, 'Monthly Purchase');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  Image.asset('assets/icons/ic_cheque.png'),
                  const Text(
                    'Cheque', //'Cheque Returns',
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
                    builder: (BuildContext context) => const ReportView('0',
                        '1', '', '', 'Cheque', '', '', '', [0], '0', '0')));
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  Image.asset('assets/icons/ic_user.png'),
                  const Text(
                    'User Activity',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () async {
            DateTime picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100));
            if (picked != null) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => ReportView(
                          '0',
                          '1',
                          DateUtil.datePickerYMD(picked),
                          '',
                          'User Activity',
                          '',
                          '',
                          '',
                          [0],
                          '0',
                          '0')));
            }
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
                  Image.asset('assets/icons/ic_pending.png'),
                  const Text(
                    'Pending FCS',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            // Navigator.pushNamed(context, '/ledger',
            //     arguments: {'parent': 'SUPPLIERS'});
            _showDialog(context);
          },
        ),
      ],
    );
  }

  monthlyReport(BuildContext context, var reportName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return (StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(reportName),
            content: DropdownSearch<dynamic>(
              maxHeight: 300,
              onFind: (String filter) =>
                  api.getSalesListData(filter, 'sales_list/location'),
              dropdownSearchDecoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: "Select Branch"),
              onChanged: (dynamic data) {
                location = data;
              },
              showSearchBox: true,
            ),
            actions: [
              TextButton(
                child: const Text("CANCEL"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("SHOW"),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => ReportView(
                              '0',
                              '1',
                              '',
                              '',
                              reportName,
                              '',
                              '',
                              '',
                              location != null ? [location.id] : [0],
                              '0',
                              '0')));
                },
              ),
            ],
          );
        }));
      },
    );
  }

  void _showDialog(BuildContext context) {
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
          actions: [
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
