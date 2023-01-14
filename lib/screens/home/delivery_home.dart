// @dart = 2.9
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/sales_man_settings.dart';
import 'package:sheraccerp/app_settings_page.dart';
import 'package:sheraccerp/models/company_user.dart';
import 'package:sheraccerp/models/other_registrations.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/screens/about_shersoft.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dbhelper.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:intl/intl.dart';

class DeliveryHome extends StatefulWidget {
  const DeliveryHome({Key key}) : super(key: key);

  @override
  State<DeliveryHome> createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends State<DeliveryHome> {
  final CommonService _commonService = CommonService();
  Map<dynamic, dynamic> responseBody;
  String messageTitle = "Empty";
  bool msg = false;
  String notificationAlert = "alert";
  FirebaseInAppMessaging firebaseInAppMessaging = FirebaseInAppMessaging();
  DioService api = DioService();
  ScrollController scrollController;
  bool dialVisible = true, isExpired = false;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    ComSettings().fetchOtherData();
    firebaseInAppMessaging.triggerEvent('on_foreground');
    notify();
    load();
    setToDay = DateFormat('dd-MM-yyyy').format(now);
  }

  notify() async {
    /***Test Data***/
    // final dbHelper = DatabaseHelper.instance;
    // final allRows = await dbHelper.queryAllRows();
    // List<Carts> carts = [];
    // for (var row in allRows) {
    //   carts.add(Carts.fromMap(row));
    // }
    // if (carts.isNotEmpty) {
    //   api.addEvent([
    //     {'data': Carts.encodeCartToJson(carts).toString()}
    //   ]).then((value) {
    //     if (value) {
    //       for (Carts carts in carts) {
    //         _delete(carts.id, dbHelper);
    //       }
    //     }
    //   });
    // }
  }

  void _delete(id, DatabaseHelper dbHelper) async {
    final rowsDeleted = await dbHelper.delete(id);
  }

  void _update(id, name, status, DatabaseHelper dbHelper) async {
    // row to update
    Carts carts = Carts(id, name, status);
    final rowsAffected = await dbHelper.update(carts);
  }

  void setDialVisible(bool value) {
    setState(() {
      dialVisible = value;
    });
  }

  String _regId = "", firm = "", firmCode = "", fId = "";
  load() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      _regId = (pref.getString('regId') ?? "");
      firm = (pref.getString('CompanyName') ?? "");
      firmCode = (pref.getString('CustomerCode') ?? "");
      fId = (pref.getString('fId') ?? "");
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
    final CompanyUser args = ModalRoute.of(context).settings.arguments;
    return Scaffold(
        appBar: AppBar(
          title: const Text("SherAcc"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _handleLogout();
              },
            ),
            IconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          const SalesManSettings()));
                },
                icon: const Icon(Icons.settings))
          ],
          elevation: .1,
        ),
        body: isExpired
            ? _expireWidget(args, context)
            : Center(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Card(
                      elevation: 5,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(50),
                              topRight: Radius.circular(50))),
                      child: TextButton(
                        child: Text('Date : $getToDay',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                fontFamily: 'Poppins')),
                        onPressed: () => _selectDate(),
                      ),
                    ),
                    Card(
                      elevation: 5,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(50),
                              bottomRight: Radius.circular(50))),
                      child: TextButton(
                        child: Text('Hi  ' + args.username,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                fontFamily: 'Poppins')),
                        onPressed: () {
                          //
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Visibility(
                      visible: ComSettings.userControl('SALE ORDER'),
                      child: Card(
                        elevation: 2,
                        shape: const StadiumBorder(
                            side: BorderSide(
                          color: blue,
                          width: 2.0,
                        )),
                        child: TextButton(
                          child: const Text('Sales Order',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Poppins')),
                          onPressed: () {
                            bool sType = true;
                            salesTypeData = salesTypeList.firstWhere(
                                (element) =>
                                    element.name == 'Sales Order Entry');
                            bool isSimpleSales = ComSettings.appSettings(
                                    'bool', 'key-simple-sales', false)
                                ? true
                                : false;
                            args.active == "false"
                                ? _commonService.getTrialPeriod(args.atDate)
                                    ? isSimpleSales
                                        ? Navigator.pushNamed(
                                            context, '/SimpleSale')
                                        : Navigator.pushNamed(context, '/sales',
                                            arguments: {'default': sType})
                                    : _expire(args, context)
                                : isSimpleSales
                                    ? Navigator.pushNamed(
                                        context, '/SimpleSale')
                                    : Navigator.pushNamed(context, '/sales',
                                        arguments: {'default': sType});
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: ComSettings.userControl('SALE'),
                      child: Card(
                        elevation: 2,
                        shape: const StadiumBorder(
                            side: BorderSide(
                          color: blue,
                          width: 2.0,
                        )),
                        child: TextButton(
                          child: const Text('Sale',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Poppins')),
                          onPressed: () {
                            bool sType = true;
                            salesTypeData = ComSettings.appSettings(
                                    'bool', 'key-switch-sales-form-set', false)
                                ? salesTypeList.firstWhere((element) =>
                                    element.name ==
                                    ComSettings.salesFormList(
                                            'key-item-sale-form-', false)[0]
                                        .name)
                                : salesTypeList.firstWhere((element) =>
                                    element.name == 'Sales Estimate Entry');
                            bool isSimpleSales = ComSettings.appSettings(
                                    'bool', 'key-simple-sales', false)
                                ? true
                                : false;
                            args.active == "false"
                                ? _commonService.getTrialPeriod(args.atDate)
                                    ? isSimpleSales
                                        ? Navigator.pushNamed(
                                            context, '/SimpleSale')
                                        : Navigator.pushNamed(context, '/sales',
                                            arguments: {'default': sType})
                                    : _expire(args, context)
                                : isSimpleSales
                                    ? Navigator.pushNamed(
                                        context, '/SimpleSale')
                                    : Navigator.pushNamed(context, '/sales',
                                        arguments: {'default': sType});
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: ComSettings.userControl('RECEIPT'),
                      child: Card(
                        elevation: 5,
                        shape: const StadiumBorder(
                            side: BorderSide(
                          color: blue,
                          width: 2.0,
                        )),
                        child: TextButton(
                          child: const Text('Receipt',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Poppins')),
                          onPressed: () {
                            args.active == "false"
                                ? _commonService.getTrialPeriod(args.atDate)
                                    ? Navigator.pushNamed(context, '/RPVoucher',
                                        arguments: {'voucher': 'Receipt'})
                                    : _expire(args, context)
                                : Navigator.pushNamed(context, '/RPVoucher',
                                    arguments: {'voucher': 'Receipt'});
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: ComSettings.userControl('PAYMENT'),
                      child: Card(
                        elevation: 5,
                        shape: const StadiumBorder(
                            side: BorderSide(
                          color: blue,
                          width: 2.0,
                        )),
                        child: TextButton(
                          child: const Text('Payment',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Poppins')),
                          onPressed: () {
                            args.active == "false"
                                ? _commonService.getTrialPeriod(args.atDate)
                                    ? Navigator.pushNamed(context, '/RPVoucher',
                                        arguments: {'voucher': 'Payment'})
                                    : _expire(args, context)
                                : Navigator.pushNamed(context, '/RPVoucher',
                                    arguments: {'voucher': 'Payment'});
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: ComSettings.userControl('PURCHASE'),
                      child: Card(
                        elevation: 5,
                        shape: const StadiumBorder(
                            side: BorderSide(
                          color: blue,
                          width: 2.0,
                        )),
                        child: TextButton(
                          child: const Text('Purchase',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Poppins')),
                          onPressed: () {
                            Navigator.pushNamed(context, '/purchase');
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: ComSettings.userControl('ORDER LIST'),
                      child: Card(
                        elevation: 2,
                        shape: const StadiumBorder(
                            side: BorderSide(
                          color: blue,
                          width: 2.0,
                        )),
                        child: TextButton(
                          child: const Text('Order List',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Poppins')),
                          onPressed: () {
                            Navigator.pushNamed(context, '/OrderList');
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: ComSettings.userControl('SALE'),
                      child: Card(
                        elevation: 2,
                        shape: const StadiumBorder(
                            side: BorderSide(
                          color: blue,
                          width: 2.0,
                        )),
                        child: TextButton(
                          child: const Text('Bill List',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Poppins')),
                          onPressed: () {
                            Navigator.pushNamed(context, '/BillList');
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: ComSettings.userControl('SALE RETURN'),
                      child: Card(
                        elevation: 2,
                        shape: const StadiumBorder(
                            side: BorderSide(
                          color: blue,
                          width: 2.0,
                        )),
                        child: TextButton(
                          child: const Text('Sales Return',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Poppins')),
                          onPressed: () {
                            Navigator.pushNamed(context, '/salesReturn');
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: ComSettings.userControl('DAMAGE'),
                      child: Card(
                        elevation: 2,
                        shape: const StadiumBorder(
                            side: BorderSide(
                          color: blue,
                          width: 2.0,
                        )),
                        child: TextButton(
                          child: const Text('Damage Entry',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Poppins')),
                          onPressed: () {
                            Navigator.pushNamed(context, '/damageEntry');
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: ComSettings.userControl('LEDGER REPORT'),
                      child: Card(
                        elevation: 2,
                        shape: const StadiumBorder(
                            side: BorderSide(
                          color: blue,
                          width: 2.0,
                        )),
                        child: TextButton(
                          child: const Text('Ledger Report',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Poppins')),
                          onPressed: () {
                            argumentsPass = {'mode': 'ledger'};
                            Navigator.pushNamed(
                              context,
                              '/select_ledger',
                            );
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: ComSettings.userControl('GROUP LIST'),
                      child: Card(
                        elevation: 2,
                        shape: const StadiumBorder(
                            side: BorderSide(
                          color: blue,
                          width: 2.0,
                        )),
                        child: TextButton(
                          child: const Text('Group List',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  fontFamily: 'Poppins')),
                          onPressed: () {
                            argumentsPass = {'mode': 'GroupList'};
                            Navigator.pushNamed(
                              context,
                              '/select_ledger',
                            );
                          },
                        ),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      shape: const StadiumBorder(
                          side: BorderSide(
                        color: blue,
                        width: 2.0,
                      )),
                      child: TextButton(
                        child: const Text('About',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                fontFamily: 'Poppins')),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AboutSherSoft()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ));
  }

  _expire(CompanyUser args, context) {
    setState(() {
      isExpired = true;
    });
  }

  _expireWidget(CompanyUser args, context) {
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

  Future _selectDate() async {
    DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => {setToDay = DateFormat('dd-MM-yyyy').format(picked)});
    }
  }
}
