// @dart = 2.11
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/app_settings_page.dart';
import 'package:sheraccerp/models/company_user.dart';
import 'package:sheraccerp/models/other_registrations.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/dash_report/dash_page.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/report.dart';
import 'package:sheraccerp/widget/cash_and_bank.dart';
import 'package:sheraccerp/widget/expense.dart';
import 'package:sheraccerp/widget/more_widget.dart';
import 'package:sheraccerp/widget/receivables_payables.dart';
import 'package:sheraccerp/widget/statement.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome>
    with TickerProviderStateMixin {
  final CommonService _commonService = CommonService();
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

  String _regId = "", firm = "", firmCode = "", fId = "";
  load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _regId = (prefs.getString('regId') ?? "");
      firm = (prefs.getString('CompanyName') ?? "");
      firmCode = (prefs.getString('CustomerCode') ?? "");
      fId = (prefs.getString('fId') ?? "");
    });
  }

  @override
  Widget build(BuildContext context) {
    final CompanyUser args = ModalRoute.of(context).settings.arguments;
    return DefaultTabController(
        length: 8,
        child: Scaffold(
          appBar: AppBar(
            // title: Text("SherAcc"),
            // brightness: Brightness.dark,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  _handleLogout();
                },
              )
            ],
            elevation: .1,
            title: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.dashboard), text: "Today"),
                Tab(icon: Icon(Icons.assessment), text: "Statement"),
                Tab(icon: Icon(Icons.assignment), text: "Expense"),
                Tab(icon: Icon(Icons.assignment_outlined), text: "Cash & Bank"),
                Tab(
                    icon: Icon(Icons.assignment_outlined),
                    text: "Receivable & Payable"),
                Tab(icon: Icon(Icons.assignment_outlined), text: "Report"),
                Tab(
                    icon: Icon(Icons.settings_applications_outlined),
                    text: "Settings"),
                Tab(icon: Icon(Icons.more), text: "Tools"),
              ],
              isScrollable: true,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: TabBarView(
            children: [
              (args.active == "false"
                  ? _commonService.getTrialPeriod(args.atDate)
                      ? const DashPage()
                      : _expire(args, context)
                  : const DashPage()),
              args.active == "false"
                  ? _commonService.getTrialPeriod(args.atDate)
                      ? const Statement()
                      : _expire(args, context)
                  : const Statement(),
              args.active == "false"
                  ? _commonService.getTrialPeriod(args.atDate)
                      ? const Expense()
                      : _expire(args, context)
                  : const Expense(),
              args.active == "false"
                  ? _commonService.getTrialPeriod(args.atDate)
                      ? CashAndBank()
                      : _expire(args, context)
                  : CashAndBank(),
              args.active == "false"
                  ? _commonService.getTrialPeriod(args.atDate)
                      ? ReceivablesAndPayables()
                      : _expire(args, context)
                  : ReceivablesAndPayables(),
              args.active == "false"
                  ? _commonService.getTrialPeriod(args.atDate)
                      ? Report()
                      : _expire(args, context)
                  : Report(),
              const AppSettings(),
              args.userType.toUpperCase() == 'ADMIN'
                  ? const MoreWidget()
                  : const MoreWidget2(),
            ],
          ),
          // floatingActionButton: buildSpeedDial(args),
        ));
  }

  SpeedDial buildSpeedDial(CompanyUser args) {
    return SpeedDial(
      // marginEnd: 18,
      // marginBottom: 20,
      childMargin: const EdgeInsets.only(bottom: 20),
      icon: Icons.add_circle_outline_rounded,
      activeIcon: Icons.highlight_remove_rounded,
      buttonSize: const Size(56.0, 56.0),
      visible: true,
      closeManually: false,
      curve: Curves.bounceIn,
      overlayColor: kPrimaryColor,
      overlayOpacity: 0.5,
      // onOpen: () => print('OPENING DIAL'),
      // onClose: () => print('DIAL CLOSED'),
      tooltip: 'Speed Dial',
      heroTag: 'speed-dial-hero-tag',
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 8.0,
      shape: const CircleBorder(),
      gradientBoxShape: BoxShape.circle,
      // gradient: LinearGradient(
      //   begin: Alignment.topCenter,
      //   end: Alignment.bottomCenter,
      //   colors: [kPrimaryColor, Colors.white10],
      // ),
      children: [
        SpeedDialChild(
          child: const Icon(Icons.shopping_bag),
          // backgroundColor: Colors.red[500],
          label: 'Purchase',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () {
            Navigator.pushNamed(context, '/purchase');
          },
          // onLongPress: () => print('SECOND CHILD LONG PRESS'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.storefront_rounded),
          // backgroundColor: kPrimaryColor[500],
          label: 'Sale',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () {
            var settings = ScopedModel.of<MainModel>(context).getSettings();
            bool sType = ComSettings.getValue('TOOLBAR SALES', settings)
                    .toString()
                    .isNotEmpty
                ? ComSettings.selectSalesType(
                    ComSettings.getValue('TOOLBAR SALES', settings))
                : false;
            args.active == "false"
                ? _commonService.getTrialPeriod(args.atDate)
                    ? Navigator.pushNamed(context, '/sales',
                        arguments: {'default': sType})
                    : _expire(args, context)
                : Navigator.pushNamed(context, '/sales',
                    arguments: {'default': sType});
          },
          // onLongPress: () => print('FIRST CHILD LONG PRESS'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.payment_rounded),
          // backgroundColor: kPrimaryColor[500],
          label: 'Payment',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () {
            args.active == "false"
                ? _commonService.getTrialPeriod(args.atDate)
                    ? Navigator.pushNamed(context, '/RPVoucher',
                        arguments: {'voucher': 'Payment'})
                    : _expire(args, context)
                : Navigator.pushNamed(context, '/RPVoucher',
                    arguments: {'voucher': 'Payment'});
          },
          // onLongPress: () => print('FIRST CHILD LONG PRESS'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.receipt_rounded),
          // backgroundColor: kPrimaryColor[500],
          label: 'Receipt',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () {
            args.active == "false"
                ? _commonService.getTrialPeriod(args.atDate)
                    ? Navigator.pushNamed(context, '/RPVoucher',
                        arguments: {'voucher': 'Receipt'})
                    : _expire(args, context)
                : Navigator.pushNamed(context, '/RPVoucher',
                    arguments: {'voucher': 'Receipt'});
          },
          // onLongPress: () => print('FIRST CHILD LONG PRESS'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.people_rounded),
          // backgroundColor: kPrimaryColor[500],
          label: 'Ledger Report',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () {
            argumentsPass = {'mode': 'ledger'};
            Navigator.pushNamed(
              context,
              '/select_ledger',
            );
          },
          // onLongPress: () => print('FIRST CHILD LONG PRESS'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.keyboard_voice),
          // backgroundColor: Colors.green,
          label: 'Voice',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () => _showDialog(context),
          // onLongPress: () => print('THIRD CHILD LONG PRESS'),
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

  Widget _expire(CompanyUser args, context) {
    return Center(
      child: Card(
        elevation: 10,
        margin: const EdgeInsets.all(10),
        child: Container(
          padding: const EdgeInsets.all(0.0),
          height: 220,
          child: Column(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 100,
                width: 90,
              ),
              Text(
                firm.toUpperCase(),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const Divider(
                height: 1,
              ),
              Text(
                "CustomerId : $fId / $_regId",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 19, color: blue),
              ),
              const Divider(
                height: 1,
              ),
              Text(
                "UserId : ${args.userId}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 19, color: blue),
              ),
              const Divider(
                height: 1,
              ),
              Text(
                "Dear ${args.username}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 19, color: red),
              ),
              const Text(
                'Your trial period expired',
                style: TextStyle(fontWeight: FontWeight.bold, color: red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
