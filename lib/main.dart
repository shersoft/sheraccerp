// @dart = 2.9
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:provider/provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/cache_provider.dart';
import 'package:sheraccerp/landing.dart';
import 'package:sheraccerp/provider/app_provider.dart';
import 'package:sheraccerp/provider/ledger_provider.dart';
import 'package:sheraccerp/provider/product_provider.dart';
import 'package:sheraccerp/provider/purchase_provider.dart';
import 'package:sheraccerp/provider/sales_provider.dart';
import 'package:sheraccerp/provider/stock_provider.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/accounts/journal.dart';
import 'package:sheraccerp/screens/html_previews/invoice_models.dart';
import 'package:sheraccerp/screens/inventory/bill_list.dart';
import 'package:sheraccerp/screens/inventory/inv_r_p_voucher.dart';
import 'package:sheraccerp/screens/home/delivery_home.dart';
import 'package:sheraccerp/screens/home/manager_home.dart';
import 'package:sheraccerp/screens/inventory/order_list.dart';
import 'package:sheraccerp/screens/inventory/product_management.dart';
import 'package:sheraccerp/screens/inventory/purchase/opening_stock.dart';
import 'package:sheraccerp/screens/inventory/purchase/purchase_new.dart';
import 'package:sheraccerp/screens/inventory/purchase/purchase_order.dart';
import 'package:sheraccerp/screens/inventory/purchase/purchase_return.dart';
import 'package:sheraccerp/screens/accounts/r_p_voucher.dart';
import 'package:sheraccerp/screens/home/sales_man_home.dart';
import 'package:sheraccerp/screens/home/admin_home.dart';
import 'package:sheraccerp/screens/inventory/cart_page.dart';
import 'package:sheraccerp/screens/inventory/confirm_order.dart';
import 'package:sheraccerp/screens/inventory/damage_entry.dart';
import 'package:sheraccerp/screens/inventory/damage_report.dart';
import 'package:sheraccerp/screens/dash_report/expense_list.dart';
import 'package:sheraccerp/screens/home/home.dart';
import 'package:sheraccerp/screens/accounts/ledger.dart';
import 'package:sheraccerp/screens/accounts/ledger_select.dart';
import 'package:sheraccerp/screens/login_screen.dart';
import 'package:sheraccerp/screens/home/owner_home.dart';
import 'package:sheraccerp/screens/passcode_authentication.dart';
import 'package:sheraccerp/screens/html_previews/sales_preview.dart';
import 'package:sheraccerp/screens/inventory/product_register.dart';
import 'package:sheraccerp/screens/inventory/product_report.dart';
import 'package:sheraccerp/screens/inventory/purchase/purchase.dart';
import 'package:sheraccerp/screens/inventory/purchase/purchase_list.dart';
import 'package:sheraccerp/screens/report_view.dart';
import 'package:sheraccerp/screens/inventory/sales/sale.dart';
import 'package:sheraccerp/screens/inventory/sales/sales.dart';
import 'package:sheraccerp/screens/inventory/sales/sales_list.dart';
import 'package:sheraccerp/screens/inventory/sales/sales_return.dart';
import 'package:sheraccerp/screens/inventory/sales/sales_return_list.dart';
import 'package:sheraccerp/screens/home/staff_home.dart';
import 'package:sheraccerp/screens/inventory/sales/simple_sale.dart';
import 'package:sheraccerp/screens/inventory/stock_report.dart';
import 'package:sheraccerp/screens/inventory/products_list_page.dart';
import 'package:sheraccerp/screens/inventory/stock_transfer.dart';
import 'package:sheraccerp/screens/user_login_screen.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/add_user_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

ValueNotifier<Color> accentColor = ValueNotifier(kPrimaryColor);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runZonedGuarded(() {
    initSettings().then((_) {
      runApp(MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => AppProvider()),
            ChangeNotifierProvider(create: (context) => LedgerProvider()),
            ChangeNotifierProvider(create: (context) => ProductProvider()),
            ChangeNotifierProvider(create: (context) => StockProvider()),
            ChangeNotifierProvider(create: (context) => SalesProvider()),
            ChangeNotifierProvider(create: (context) => PurchaseProvider()),
          ],
          child: MyApp(
            model: MainModel(),
          )));
    });
  }, (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  });
}

Future<void> initSettings() async {
  await Settings.init(
    cacheProvider: isUsingHive ? HiveCache() : SharePreferenceCache(),
  );

  isDarkTheme = ComSettings.appSettings('int', 'key-dropdown-them-view', 2) == 2
      ? false
      : true;
  _initializeFirebase();
}

Future<void> _initializeFirebase() async {
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  } else {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }
}

class MyApp extends StatelessWidget {
  final MainModel model;
  const MyApp({Key key, @required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainModel>(
        model: model,
        child: ValueListenableBuilder<Color>(
          valueListenable: accentColor,
          builder: (_, color, __) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SherAcc',
            routes: {
              '/': (context) => const Landing(),
              '/login_company': (context) => const LoginScreen(),
              '/login': (context) => const UserLoginScreen(),
              '/register': (context) => const Register(),
              '/home': (context) => const Home(),
              '/admin_home': (context) => const AdminHome(title: 'SherAcc'),
              '/manager_home': (context) => const ManagerHome(title: 'SherAcc'),
              '/staff_home': (context) => const StaffHome(title: 'SherAcc'),
              '/expense_list': (context) => ExpenseList(null, 0),
              '/sales': (context) => const Sale(),
              '/purchase': (context) => const Purchase(),
              '/add_product': (context) => const ProductsListPage(),
              '/cart': (context) => const CartPage(),
              '/check_out': (context) => const ConfirmOrder(),
              '/ledger': (context) => const Ledger(),
              '/preview_show': (context) => const SalesPreviewShow(),
              '/select_ledger': (context) => const LedgerSelect(),
              '/report_view': (context) => const ReportView('0', '0',
                  '2020-01-01', '2020-01-01', 'ledger', '', '', '0', 0),
              '/RPVoucher': (context) => const RPVoucher(),
              '/SalesList': (context) => const SalesList(),
              '/PurchaseList': (context) => const PurchaseList(),
              '/StockReport': (context) => const StockReport(),
              '/salesMan_home': (context) => const SalesManHome(),
              '/delivery_home': (context) => const DeliveryHome(),
              '/product': (context) => const ProductRegister(),
              '/salesReturn': (context) =>
                  const SalesReturn(data: [], fromSale: false),
              '/damageEntry': (context) => const DamageEntry(),
              '/openingStock': (context) => const OpeningStock(),
              '/damageReport': (context) => const DamageReport(),
              '/SalesReturnList': (context) => const SalesReturnList(),
              '/ProductReport': (context) => const ProductReport(),
              '/owner_home': (context) => const OwnerHome(),
              '/passCode_Auth': (context) => const PassCodeAuth(),
              '/SimpleSale': (context) => const SimpleSale(),
              '/OrderList': (context) => const OrderList(),
              '/BillList': (context) => const BillList(),
              '/purchaseReturn': (context) => const PurchaseReturn(),
              '/purchaseOrder': (context) => const PurchaseOrder(),
              '/stockTransfer': (context) => const StockTransfer(),
              '/sale': (context) => const Sales(),
              '/InvRPVoucher': (context) => const InvRPVoucher(),
              '/InvoiceModels': (context) => const InvoiceModels(),
              '/ProductManagement': (context) => ProductManagement(),
              '/journal': (context) => Journal(),
            },
            theme: isDarkTheme
                ? ThemeData(
                    primarySwatch: kPrimaryColor,
                    brightness: Brightness.dark,
                    dividerColor: Colors.white54,
                  )
                : ThemeData(
                    primarySwatch: kPrimaryColor,
                    brightness: Brightness.light,
                    dividerColor: Colors.white54,
                  ),
          ),
        ));
  }
}
