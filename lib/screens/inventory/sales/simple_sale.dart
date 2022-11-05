import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/models/stock_item.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';

class SimpleSale extends StatefulWidget {
  const SimpleSale({Key? key}) : super(key: key);

  @override
  _SimpleSaleState createState() => _SimpleSaleState();
}

class _SimpleSaleState extends State<SimpleSale> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<SalesType> salesTypeDisplay = [];
  bool thisSale = false, isCustomForm = false;
  DioService dio = DioService();
  late Size deviceSize;
  var ledgerModel;
  late StockItem productModel;
  List<CartItem> cartItem = [];
  List<dynamic> otherAmountList = [];
  bool isTax = true,
      otherAmountLoaded = false,
      valueMore = false,
      lastRecord = false,
      widgetID = true,
      previewData = false,
      oldBill = false;
  DateTime now = DateTime.now();
  late String formattedDate;
  double grandTotal = 0;

  int page = 1, pageTotal = 0, totalRecords = 0;
  int saleAccount = 0, acId = 0;
  List<dynamic> ledgerDisplay = [];
  List<dynamic> itemDisplay = [];
  List<dynamic> items = [];
  int lId = 0;
  var salesManId = 0;

  @override
  void initState() {
    super.initState();
    formattedDate = DateUtil.dateDMY(
        now.toString()); //DateFormat('dd-MM-yyyy').format(now);

    isCustomForm =
        ComSettings.appSettings('bool', 'key-switch-sales-form-set', false)
            ? true
            : false;
    if (isCustomForm) {
      salesTypeDisplay =
          ComSettings.salesFormList('key-item-sale-form-', false);
    }

    loadSettings();
    dio.fetchDetailAmount().then((value) {
      otherAmountList = value;
      setState(() {
        otherAmountLoaded = true;
      });
    });
    salesManId = ComSettings.appSettings(
            'int', 'key-dropdown-default-salesman-view', 1) -
        1;
    lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;

    // dio.getSalesAccountList().then((value) {
    //   saleAccount = value;
    // });

    saleAccount = mainAccount.firstWhere(
        (element) => element['LedName'] == 'GENERAL SALES A/C')['LedCode'];
    acId = mainAccount
        .firstWhere((element) => element['LedName'] == 'CASH')['LedCode'];
  }

  loadSettings() {
    CompanyInformation companySettings =
        ScopedModel.of<MainModel>(context).getCompanySettings();
    List<CompanySettings> settings =
        ScopedModel.of<MainModel>(context).getSettings();

    taxMethod = companySettings.taxCalculation;
    enableMULTIUNIT = ComSettings.getStatus('ENABLE MULTI-UNIT', settings);
    pRateBasedProfitInSales =
        ComSettings.getStatus('PRATE BASED PROFIT IN SALES', settings);
    negativeStock = ComSettings.getStatus('ALLOW NEGETIVE STOCK', settings);
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    cessOnNetAmount = ComSettings.getStatus('CESS ON NET AMOUNT', settings);
    enableKeralaFloodCess = false;
    useUNIQUECODEASBARCODE =
        ComSettings.getStatus('USE UNIQUECODE AS BARCODE', settings);
    useOLDBARCODE = ComSettings.getStatus('USE OLD BARCODE', settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Sales"),
          actions: [
            Visibility(
              visible: previewData,
              child: TextButton(
                  child: Text(
                    previewData ? "New " + salesTypeData.name : 'Sales',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[700],
                  ),
                  onPressed: () async {
                    setState(() {
                      widgetID = false;
                    });
                  }),
            ),
          ],
        ),
        body: const Text('HHHHHHHHHHHH'));
  }

  //declare
  bool outOfStock = false,
      enableMULTIUNIT = false,
      pRateBasedProfitInSales = false,
      negativeStock = false,
      cessOnNetAmount = false,
      negativeStockStatus = false,
      enableKeralaFloodCess = false,
      useUNIQUECODEASBARCODE = false,
      useOLDBARCODE = false;
}
