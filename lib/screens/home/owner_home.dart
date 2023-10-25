// @dart = 2.11
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/sales_man_settings.dart';
import 'package:sheraccerp/app_settings_page.dart';
import 'package:sheraccerp/models/other_registrations.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';

class OwnerHome extends StatefulWidget {
  const OwnerHome({Key key}) : super(key: key);

  @override
  _OwnerHomeState createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<OwnerHome> {
  Map<dynamic, dynamic> responseBody;
  String messageTitle = "Empty";
  bool msg = false;
  String notificationAlert = "alert";
  // FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  FirebaseInAppMessaging firebaseInAppMessaging = FirebaseInAppMessaging();
  DioService api = DioService();
  ScrollController scrollController;
  bool dialVisible = true;

  @override
  void initState() {
    super.initState();
    ComSettings().fetchOtherData();
    firebaseInAppMessaging.triggerEvent('on_foreground');

    // _firebaseMessaging.configure(
    //   onMessage: (message) async {
    //     setState(() {
    //       messageTitle = message["notification"]["title"];
    //       notificationAlert = "New Notification Alert";
    //       msg = true;
    //     });
    //   },
    //   onResume: (message) async {
    //     setState(() {
    //       messageTitle = message["data"]["title"];
    //       notificationAlert = "Application opened from Notification";
    //     });
    //   },
    // );
    notify();
    load();
  }

  String regId = "", firm = "", firmCode = "", fId = "";
  load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      regId = (prefs.getString('regId') ?? "");
      firm = (prefs.getString('CompanyName') ?? "");
      firmCode = (prefs.getString('CustomerCode') ?? "");
      fId = (prefs.getString('fId') ?? "");
      // /**Web only**/
      // setApiV = (pref.getString('apiV') ?? "v13");
    });
  }

  notify() async {
    // var token = await _firebaseMessaging.getToken();
    // print("Instance ID: " + token);
    //             showDialog(
    // context: context, builder: (BuildContext context) => CustomDialog());
    // showFancyCustomDialog(context);
    // if (msg) {
    //   showDialog(
    //       context: context,
    //       builder: (BuildContext context) => CustomAlertDialog(
    //             title: messageTitle,
    //             message: notificationAlert,
    //           ));
    // }
  }

  void setDialVisible(bool value) {
    setState(() {
      dialVisible = value;
    });
  }

  void _handleLogout() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              pref.remove('userId');
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', ModalRoute.withName('/login'));
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("SherAcc"),
          // brightness: Brightness.dark,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _handleLogout();
              },
            ),
            IconButton(
                onPressed: () {
                  // Navigator.pushNamed(context, '/salesManList');
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          const SalesManSettings()));
                },
                icon: const Icon(Icons.settings))
          ],
          elevation: .1,
        ),
        body:
            // );
// }

            // @override
            // Widget build(BuildContext context) {
            GridView.count(
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
                        Icons.auto_stories,
                        color: Colors.blue[300],
                        size: 90.0,
                      ),
                      const Text('Day Book', //note actually
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
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
            // GestureDetector(
            //   child: Card(
            //     elevation: 5.0,
            //     child: Container(
            //       padding: const EdgeInsets.all(0),
            //       child: Column(
            //         mainAxisAlignment: MainAxisAlignment.spaceAround,
            //         children: <Widget>[
            //           new Icon(
            //             Icons.account_balance_rounded,
            //             color: Colors.red[300],
            //             size: 90.0,
            //           ),
            //           Text(
            //             'Trial Balance',
            //             style: TextStyle(
            //                 color: Colors.black, fontWeight: FontWeight.bold),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            //   onTap: () {
            //     argumentsPass = {'mode': 'TrialBalance'};
            //     Navigator.pushNamed(
            //       context,
            //       '/select_ledger',
            //     );
            //   },
            // ),
            // GestureDetector(
            //   child: Card(
            //     elevation: 5.0,
            //     child: Container(
            //       padding: const EdgeInsets.all(0),
            //       child: Column(
            //         mainAxisAlignment: MainAxisAlignment.spaceAround,
            //         children: <Widget>[
            //           new Icon(
            //             Icons.show_chart_rounded,
            //             color: Colors.green[300],
            //             size: 90.0,
            //           ),
            //           Text(
            //             'Cash Flow',
            //             style: TextStyle(
            //                 color: Colors.black, fontWeight: FontWeight.bold),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            //   onTap: () {
            //     argumentsPass = {'mode': 'CashFlow'};
            //     Navigator.pushNamed(
            //       context,
            //       '/select_ledger',
            //     );
            //   },
            // ),
            GestureDetector(
              child: Card(
                elevation: 5.0,
                child: Container(
                  padding: const EdgeInsets.all(0),
                  child: Column(
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
                    children: <Widget>[
                      Icon(
                        Icons.read_more,
                        color: Colors.pink[300],
                        size: 90.0,
                      ),
                      const Text(
                        'More',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              onTap: () {
                _showDialog(context);
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
              },
            ),
          ],
        ));
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
