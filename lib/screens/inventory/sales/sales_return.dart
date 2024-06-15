// @dart = 2.11
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/order.dart';
import 'package:sheraccerp/models/product_register_model.dart';
import 'package:sheraccerp/models/stock_item.dart';
import 'package:sheraccerp/models/stock_product.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/inventory/sales/sale.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/blue_thermal.dart';
import 'package:sheraccerp/service/bt_print.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/components.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/popup_menu_action.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class SalesReturn extends StatefulWidget {
  const SalesReturn({this.fromSale, this.data, Key key}) : super(key: key);
  final bool fromSale;
  final List<dynamic> data;

  @override
  _SalesReturnState createState() => _SalesReturnState();
}

class _SalesReturnState extends State<SalesReturn> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  DioService api = DioService();
  Size deviceSize;
  var ledgerModel;
  dynamic productModel;
  List<CartItem> cartItem = [];
  List<dynamic> otherAmountList = [];
  bool taxable = true;
  bool isTax = true,
      _isCashBill = false,
      otherAmountLoaded = false,
      widgetID = true,
      valueMore = false,
      lastRecord = false,
      previewData = false,
      oldBill = false,
      isItemSerialNo = false,
      keyItemsVariantStock = false,
      buttonEvent = false,
      isFreeItem = false,
      productTracking = false,
      keyEditAndDeleteAdminOnlyDaysBefore = false,
      daysBefore = false,
      isFreeQty = false,
      manualInvoiceNumberInSales = false;
  final List<TextEditingController> _controllers = [];
  DateTime now = DateTime.now();
  String formattedDate;
  final double _balance = 0;
  double grandTotal = 0;
  int page = 1,
      pageTotal = 0,
      totalRecords = 0,
      decimal = 2,
      valueDaysBefore = 0;
  List<dynamic> ledgerDisplay = [];
  List<dynamic> _ledger = [];
  List<ProductPurchaseModel> itemDisplay = [];
  List<ProductPurchaseModel> items = [];
  int saleAccount = 0;
  int lId = 0, groupId = 0, acId = 0;
  var salesManId = 0;
  int saleFormId = 1;
  int printerType = 0, printerDevice = 0, printModel = 2;
  String labelSerialNo = 'SerialNo';
  String labelSpRate = 'SpRetail';
  CartItem cartModel;
  // final TextEditingController invoiceNoController = TextEditingController();
  final TextEditingController controllerNarration = TextEditingController();

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    loadSettings();
    api.fetchDetailAmount().then((value) {
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

    printerType =
        ComSettings.appSettings('int', 'key-dropdown-printer-type-view', 0);
    printerDevice =
        ComSettings.appSettings('int', 'key-dropdown-printer-device-view', 0);
    printModel =
        ComSettings.appSettings('int', "key-dropdown-printer-model-view", 2);
    printLines = ComSettings.billLineValue(
        ComSettings.appSettings('int', "key-dropdown-print-line", 2));

    groupId =
        ComSettings.appSettings('int', 'key-dropdown-default-group-view', 0) -
            1;

    saleAccount = mainAccount.firstWhere(
        (element) => element['LedName'] == 'GENERAL SALES A/C')['LedCode'];

    if (widget.fromSale) {
      setState(() {
        ledgerModel = widget.data[0]['ledger'];
        int refId = widget.data[0]['id'];
        if (refId > 0) {
          fetchSaleReturn(context, refId);
        } else {
          nextWidget = 2;
          widgetID = false;
        }
      });
    }
  }

  CompanyInformation companySettings;
  List<CompanySettings> settings;
  loadSettings() {
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();

    String cashAc =
        ComSettings.getValue('CASH A/C', settings).toString().trim() ?? 'CASH';
    acId = mainAccount
        .firstWhere((element) => element['LedName'] == cashAc)['LedCode'];
    int cashId =
        ComSettings.appSettings('int', 'key-dropdown-default-cash-ac', 0) - 1;
    acId = cashId > 0
        ? mainAccount.firstWhere((element) => element['LedCode'] == cashId,
            orElse: () => {'LedName': cashAc, 'LedCode': acId})['LedCode']
        : acId;

    taxMethod = companySettings.taxCalculation;
    enableMULTIUNIT = ComSettings.getStatus('ENABLE MULTI-UNIT', settings);
    pRateBasedProfitInSales =
        ComSettings.getStatus('PRATE BASED PROFIT IN SALES', settings);
    negativeStock = ComSettings.getStatus('ALLOW NEGETIVE STOCK', settings);
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    cessOnNetAmount = ComSettings.getStatus('CESS ON NET AMOUNT', settings);
    productTracking =
        ComSettings.getStatus('ENABLE PRODUCT TRACKING IN SALES', settings);

    enableKeralaFloodCess = false;
    useUNIQUECODEASBARCODE =
        ComSettings.getStatus('USE UNIQUECODE AS BARCODE', settings);
    useOLDBARCODE = ComSettings.getStatus('USE OLD BARCODE', settings);
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;
    keyItemsVariantStock =
        ComSettings.getStatus('KEY LOCK SALES DISCOUNT', settings);

    isItemSerialNo = ComSettings.getStatus('KEY ITEM SERIAL NO', settings);
    isFreeItem = ComSettings.getStatus('KEY FREE ITEM', settings);
    isFreeQty = ComSettings.getStatus('KEY FREE QTY IN SALE', settings);

    labelSerialNo =
        ComSettings.getValue('KEY ITEM SERIAL NO', settings).toString();
    labelSpRate =
        ComSettings.getValue('KEY ITEM SP RATE TITLE', settings).toString();
    labelSerialNo = labelSerialNo.isEmpty ? 'Remark' : labelSerialNo;
    labelSpRate = labelSpRate.isEmpty ? 'SpRetail' : labelSpRate;

    keyEditAndDeleteAdminOnlyDaysBefore = ComSettings.getStatus(
        'KEY EDIT AND DELETE ADMIN ONLY DAYS BEFORE', settings);
    valueDaysBefore = int.tryParse(ComSettings.getValue(
            'KEY EDIT AND DELETE ADMIN ONLY DAYS BEFORE', settings)
        .toString());
    manualInvoiceNumberInSales =
        ComSettings.getStatus('MANNUAL INVOICE NUMBER IN SALES', settings);

    loadAsset();
  }

  userDateCheck(String date) {
    if (keyEditAndDeleteAdminOnlyDaysBefore) {
      DateTime date1 =
          DateTime.parse(DateFormat('yyyy-MM-dd').format(DateTime.parse(date)));
      DateTime date2 = DateTime.parse(DateFormat('yyyy-MM-dd').format(now));

      if (DateUtil.compareDate(
          date1: date1, date2: date2, days: valueDaysBefore)) {
        if (companyUserData.userType.toUpperCase() != 'ADMIN') {
          daysBefore = true;
        } else {
          daysBefore = false;
        }
      } else {
        daysBefore = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    deviceSize = MediaQuery.of(context).size;
    return widgetID ? widgetPrefix() : widgetSuffix();
  }

  widgetPrefix() {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Sales Return"),
          actions: [
            TextButton(
              child: const Text(
                "New",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue[700],
              ),
              onPressed: () async {
                setState(() {
                  widgetID = false;
                });
              },
              onLongPress: () {
                searchBill(context, 1);
              },
            ),
          ],
        ),
        body: Container(
          child: previousBill(),
        ));
  }

  widgetSuffix() {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Sales Return"),
          actions: [
            Visibility(
              visible: oldBill,
              child: IconButton(
                  color: red,
                  iconSize: 40,
                  onPressed: () {
                    if (buttonEvent) {
                      return;
                    } else {
                      if (totalItem > 0) {
                        if (companyUserData.deleteData) {
                          if (!daysBefore) {
                            setState(() {
                              _isLoading = true;
                            });
                            deleteSale();
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Invoice Date not equal\ncan`t delete');
                            setState(() {
                              buttonEvent = false;
                            });
                          }
                        } else {
                          Fluttertoast.showToast(
                              msg: 'Permission denied\ncan`t delete');
                          setState(() {
                            buttonEvent = false;
                          });
                        }
                      } else {
                        Fluttertoast.showToast(
                            msg: 'Please select atleast one bill');
                        setState(() {
                          buttonEvent = false;
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever)),
            ),
            oldBill
                ? IconButton(
                    color: green,
                    iconSize: 40,
                    onPressed: () {
                      if (buttonEvent) {
                        return;
                      } else {
                        if (totalItem > 0) {
                          if (companyUserData.updateData) {
                            if (!daysBefore) {
                              setState(() {
                                _isLoading = true;
                                buttonEvent = true;
                              });
                              updateSale();
                            } else {
                              Fluttertoast.showToast(
                                  msg: 'Invoice Date not equal\ncan`t edit');
                              setState(() {
                                buttonEvent = false;
                              });
                            }
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Permission denied\ncan`t edit');
                            setState(() {
                              buttonEvent = false;
                            });
                          }
                        } else {
                          Fluttertoast.showToast(
                              msg: 'Please select atleast one bill');
                          setState(() {
                            buttonEvent = false;
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.edit))
                : IconButton(
                    color: blue,
                    iconSize: 40,
                    onPressed: () {
                      if (buttonEvent) {
                        return;
                      } else {
                        if (totalItem > 0) {
                          if (companyUserData.insertData) {
                            setState(() {
                              _isLoading = true;
                              buttonEvent = true;
                            });
                            saveSale();
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Permission denied\ncan`t save');
                            setState(() {
                              buttonEvent = false;
                            });
                          }
                        } else {
                          Fluttertoast.showToast(
                              msg: 'Please add atleast one item');
                          setState(() {
                            buttonEvent = false;
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.save)),
          ],
        ),
        body: ProgressHUD(
            inAsyncCall: _isLoading, opacity: 0.0, child: selectWidget()));
  }

  previousBill() {
    _getMoreData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreData();
      }
    });

    return dataDisplay.isNotEmpty
        ? ListView.builder(
            itemCount: dataDisplay.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == dataDisplay.length) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Opacity(
                      opacity: isLoadingData ? 1.0 : 00,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                );
              } else {
                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(dataDisplay[index]['Name']),
                    subtitle: Text('Date: ' +
                        dataDisplay[index]['Date'] +
                        ' / EntryNo : ' +
                        dataDisplay[index]['Id'].toString()),
                    trailing: Text(
                        'Total : ' + dataDisplay[index]['Total'].toString()),
                    onTap: () {
                      showEditDialog(context, dataDisplay[index]);
                    },
                  ),
                );
              }
            },
            controller: _scrollController,
          )
        : Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No items in Sales Return"),
              IconButton(
                  onPressed: () {
                    searchBill(context, 1);
                  },
                  icon: const Icon(Icons.search)),
              TextButton.icon(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(kPrimaryColor),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                  onPressed: () {
                    setState(() {
                      widgetID = false;
                    });
                  },
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Take New Sales Return'))
            ],
          ));
  }

  final ScrollController _scrollController = ScrollController();
  bool isLoadingData = false;
  List dataDisplay = [];

  void _getMoreData() async {
    if (!lastRecord) {
      if ((dataDisplay.isEmpty || dataDisplay.length < totalRecords) &&
          !isLoadingData) {
        setState(() {
          isLoadingData = true;
        });

        List tempList = [];

        api
            .getPaginationList(
                'SalesReturnList',
                page,
                lId.toString(),
                '1',
                DateUtil.dateYMD(formattedDate),
                salesManId > 0 ? salesManId.toString() : '')
            .then((value) {
          if (value.isEmpty) {
            return;
          }
          final response = value;
          pageTotal = response[1][0]['Filtered'];
          totalRecords = response[1][0]['Total'];
          page++;
          for (int i = 0; i < response[0].length; i++) {
            tempList.add(response[0][i]);
          }

          setState(() {
            isLoadingData = false;
            dataDisplay.addAll(tempList);
            lastRecord = tempList.isNotEmpty ? false : true;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // invoiceNoController.dispose();
    // controllerCashReceived.dispose();
    controllerNarration.dispose();
    _rateController.dispose();
    _discountController.dispose();
    _quantityController.dispose();
    _freeQuantityController.dispose();
    _discountPercentController.dispose();
    _serialNoController.dispose();
    // returnAmountController.dispose();
    // returnEntryNoController.dispose();
    // bankAmountController.dispose();
    // commissionAmountController.dispose();

    super.dispose();
  }

  saveSale() async {
    List<CustomerModel> ledger = [];
    ledger.add(ledgerModel);
    var locationId = lId.toString().trim().isNotEmpty ? lId : 1;

    Order order = Order(
        customerModel: ledger,
        lineItems: cartItem,
        grossValue: totalGrossValue.toString(),
        discount: totalDiscount.toString(),
        rDiscount: totalRDiscount.toString(),
        net: totalNet.toString(),
        cGST: totalCgST.toString(),
        sGST: totalSgST.toString(),
        iGST: totalIgST.toString(),
        cess: totalCess.toString(),
        adCess: totalAdCess.toString(),
        fCess: totalFCess.toString(),
        total: totalCartValue.toString(),
        grandTotal:
            grandTotal > 0 ? grandTotal.toString() : totalCartValue.toString(),
        profit: totalProfit.toString(),
        cashReceived: '0',
        otherDiscount: '0',
        loadingCharge: '0',
        otherCharges: '0',
        labourCharge: '0',
        discountPer: '0',
        balanceAmount: '0',
        creditPeriod: '0',
        narration:
            controllerNarration.text.isNotEmpty ? controllerNarration.text : '',
        takeUser: userIdC.toString(),
        location: locationId.toString(),
        billType: companyTaxMode == 'GULF' ? '2' : '0',
        roundOff: '0',
        salesMan: salesManId.toString(),
        sType: rateType,
        dated: DateUtil.dateYMD(formattedDate),
        cashAC: acId.toString(),
        otherAmountData: otherAmountList);
    if (order.lineItems.isNotEmpty) {
      var jsonLedger = CustomerModel.encodeCustomerToJson(order.customerModel);
      var jsonItem = CartItem.encodeCartToJson(order.lineItems);
      var items = json.encode(jsonItem);
      var ledger = json.encode(jsonLedger);
      var otherAmount = json.encode(order.otherAmountData);
      var taxType = isTax ? 'T' : 'NT';
      var salesRateTypeId = rateType.isNotEmpty ? rateType : '1';
      var saleAccountId = saleAccount > 0 ? saleAccount.toString() : '0';
      var checkKFC = isKFC ? '1' : '0';
      double grandTotal = double.tryParse(order.grandTotal) > 0
          ? (CommonService.getRound(
                  decimal, double.tryParse(order.grandTotal)) +
              CommonService.getRound(
                  decimal, double.tryParse(order.loadingCharge)) +
              CommonService.getRound(
                  decimal, double.tryParse(order.otherCharges)) +
              CommonService.getRound(decimal, double.tryParse(order.adCess)) +
              CommonService.getRound(
                  decimal, double.tryParse(order.labourCharge)) -
              CommonService.getRound(
                  decimal, double.tryParse(order.otherDiscount)))
          : 0;
      double roundOff = 0, different = 0;
      if (!ComSettings.appSettings('bool', 'key-round-off-amount', false)) {
        different = grandTotal - grandTotal.round();
        if (different < 0.5) {
          roundOff = CommonService.getRound(decimal, (different * -1));
        } else {
          roundOff = CommonService.getRound(1, (1 - different));
        }
      }
      var data = '[' +
          json.encode({
            'statement': 'SalesReturnInsert',
            'entryNo': 0,
            'invoiceNo': '0',
            'saleFormId': saleFormId,
            'saleFormType': '',
            'taxType': taxType,
            'date': order.dated,
            'sType': salesRateTypeId,
            'saleAccountId': saleAccountId,
            'grossValue': order.grossValue,
            'discPercent': order.discountPer,
            'discount': order.discount,
            'rDiscount': order.rDiscount,
            'net': order.net,
            'cess': order.cess,
            'total': order.total,
            'profit': order.profit,
            'cGST': order.cGST,
            'sGST': order.sGST,
            'iGST': order.iGST,
            'addCess': order.adCess,
            'fCess': order.fCess,
            'otherDiscount': order.otherDiscount,
            'otherCharges': order.otherCharges,
            'loadingCharge': order.loadingCharge,
            'balanceAmount': ComSettings.appSettings(
                    'bool', 'key-round-off-amount', false)
                ? double.parse(order.balanceAmount).toStringAsFixed(decimal)
                : double.parse(order.balanceAmount).roundToDouble().toString(),
            'labourCharge': order.labourCharge,
            'grandTotal':
                ComSettings.appSettings('bool', 'key-round-off-amount', false)
                    ? grandTotal.toStringAsFixed(decimal)
                    : grandTotal.roundToDouble().toString(),
            'creditPeriod': order.creditPeriod,
            'takeUser': order.takeUser,
            'narration': order.narration,
            'cashReceived': order.cashReceived,
            'cashAC': order.cashAC,
            'check_kFC': checkKFC,
            'salesMan': order.salesMan,
            'location': order.location,
            'roundOff': roundOff,
            'billType': order.billType,
            'returnNo': 0,
            'returnAmount': 0,
            'otherAmount': '0',
            'fyId': currentFinancialYear.id,
            'commissionAccount': 0,
            'commissionAmount': 0,
            'bankName': '',
            'bankAmount': 0
          }) +
          ']';

      final body = {
        'information': ledger,
        'data': data,
        'particular': items,
        'otherAmount': otherAmount,
        'fyId': currentFinancialYear.id
      };

      api.spSale(body).then((value0) {
        setState(() {
          _isLoading = false;
        });
        if (value0 > 0) {
          var data = '[' +
              json.encode({
                'statement': 'SREntryNo',
                'entryNo': 0,
                'invoiceNo': 0,
                'saleFormId': saleFormId,
                'billType': order.billType,
                'returnNo': 0,
                'returnAmount': 0,
                'fyId': currentFinancialYear.id
              }) +
              ']';

          final body1 = {
            'information': ledger,
            'data': data,
            'particular': items,
            'otherAmount': otherAmount
          };
          api.spSale(body1).then((value1) {
            if (widget.fromSale) {
              setReturnBillNo = value1;
              setReturnBillAmount =
                  ComSettings.appSettings('bool', 'key-round-off-amount', false)
                      ? grandTotal
                      : grandTotal.roundToDouble();
            }
            dataDynamic = [
              {
                'RealEntryNo': value1,
                'EntryNo': value1,
                'InvoiceNo': value1.toString(),
                'Type': 1
              }
            ];
            // clearCart();
            showMore(context);
          });
        }
      });
    }
  }

  updateSale() async {
    List<CustomerModel> ledger = [];
    ledger.add(ledgerModel);
    var locationId = lId.toString().trim().isNotEmpty ? lId : 1;

    Order order = Order(
        customerModel: ledger,
        lineItems: cartItem,
        grossValue: totalGrossValue.toString(),
        discount: totalDiscount.toString(),
        rDiscount: totalRDiscount.toString(),
        net: totalNet.toString(),
        cGST: totalCgST.toString(),
        sGST: totalSgST.toString(),
        iGST: totalIgST.toString(),
        cess: totalCess.toString(),
        adCess: totalAdCess.toString(),
        fCess: totalFCess.toString(),
        total: totalCartValue.toString(),
        grandTotal:
            grandTotal > 0 ? grandTotal.toString() : totalCartValue.toString(),
        profit: totalProfit.toString(),
        cashReceived: '0',
        otherDiscount: '0',
        loadingCharge: '0',
        otherCharges: '0',
        labourCharge: '0',
        discountPer: '0',
        balanceAmount: '0',
        creditPeriod: '0',
        narration:
            controllerNarration.text.isNotEmpty ? controllerNarration.text : '',
        takeUser: userIdC.toString(),
        location: locationId.toString(),
        billType: companyTaxMode == 'GULF' ? '2' : '0',
        roundOff: '0',
        salesMan: salesManId.toString(),
        sType: rateType,
        dated: DateUtil.dateYMD(formattedDate),
        cashAC: acId.toString(),
        otherAmountData: otherAmountList);
    if (order.lineItems.isNotEmpty) {
      var jsonLedger = CustomerModel.encodeCustomerToJson(order.customerModel);
      var jsonItem = CartItem.encodeCartToJson(order.lineItems);
      var items = json.encode(jsonItem);
      var ledger = json.encode(jsonLedger);
      var otherAmount = json.encode(order.otherAmountData);
      var taxType = isTax ? 'T' : 'NT';
      var salesRateTypeId = rateType.isNotEmpty ? rateType : '1';
      var saleAccountId = saleAccount > 0 ? saleAccount.toString() : '0';
      var checkKFC = isKFC ? '1' : '0';
      double grandTotal = double.tryParse(order.grandTotal) > 0
          ? (CommonService.getRound(
                  decimal, double.tryParse(order.grandTotal)) +
              CommonService.getRound(
                  decimal, double.tryParse(order.loadingCharge)) +
              CommonService.getRound(
                  decimal, double.tryParse(order.otherCharges)) +
              CommonService.getRound(decimal, double.tryParse(order.adCess)) +
              CommonService.getRound(
                  decimal, double.tryParse(order.labourCharge)) -
              CommonService.getRound(
                  decimal, double.tryParse(order.otherDiscount)))
          : 0;
      double roundOff = 0, different = 0;
      if (!ComSettings.appSettings('bool', 'key-round-off-amount', false)) {
        different = grandTotal - grandTotal.round();
        if (different < 0.5) {
          roundOff = CommonService.getRound(decimal, (different * -1));
        } else {
          roundOff = CommonService.getRound(1, (1 - different));
        }
      }
      var data = '[' +
          json.encode({
            'statement': 'SalesReturnUpdate',
            'entryNo': dataDynamic[0]['EntryNo'],
            'invoiceNo': dataDynamic[0]['InvoiceNo'],
            'saleFormId': saleFormId,
            'saleFormType': '',
            'taxType': taxType,
            'date': order.dated,
            'sType': salesRateTypeId,
            'saleAccountId': saleAccountId,
            'grossValue': order.grossValue,
            'discPercent': order.discountPer,
            'discount': order.discount,
            'rDiscount': order.rDiscount,
            'net': order.net,
            'cess': order.cess,
            'total': order.total,
            'profit': order.profit,
            'cGST': order.cGST,
            'sGST': order.sGST,
            'iGST': order.iGST,
            'addCess': order.adCess,
            'fCess': order.fCess,
            'otherDiscount': order.otherDiscount,
            'otherCharges': order.otherCharges,
            'loadingCharge': order.loadingCharge,
            'balanceAmount': ComSettings.appSettings(
                    'bool', 'key-round-off-amount', false)
                ? double.parse(order.balanceAmount).toStringAsFixed(decimal)
                : double.parse(order.balanceAmount).roundToDouble().toString(),
            'labourCharge': order.labourCharge,
            'grandTotal':
                ComSettings.appSettings('bool', 'key-round-off-amount', false)
                    ? grandTotal.toStringAsFixed(decimal)
                    : grandTotal.roundToDouble().toString(),
            'creditPeriod': order.creditPeriod,
            'takeUser': order.takeUser,
            'narration': order.narration,
            'cashReceived': order.cashReceived,
            'cashAC': order.cashAC,
            'check_kFC': checkKFC,
            'salesMan': order.salesMan,
            'location': order.location,
            'roundOff': roundOff,
            'billType': order.billType,
            'returnNo': 0,
            'returnAmount': 0,
            'fyId': currentFinancialYear.id
          }) +
          ']';

      final body = {
        'information': ledger,
        'data': data,
        'particular': items,
        'otherAmount': otherAmount,
        'fyId': currentFinancialYear.id
      };

      api.spSale(body).then((value) {
        setState(() {
          _isLoading = false;
        });
        if (value > 0) {
          if (widget.fromSale) {
            setReturnBillNo = value;
            setReturnBillAmount =
                ComSettings.appSettings('bool', 'key-round-off-amount', false)
                    ? grandTotal
                    : grandTotal.roundToDouble();
          }
          // clearCart();
          showMore(context);
        }
      });
    }
  }

  deleteSale() {
    var data = '[' +
        json.encode({
          'statement': 'SalesReturnDelete',
          'entryNo': dataDynamic[0]['EntryNo'],
          'invoiceNo': dataDynamic[0]['InvoiceNo'],
          'saleFormId': saleFormId,
          'fyId': currentFinancialYear.id
        }) +
        ']';
    final body = {
      'information': '[{}]',
      'data': data,
      'particular': '[{}]',
      'otherAmount': '[{}]'
    };

    api.spSale(body).then((value) {
      setState(() {
        _isLoading = false;
      });
      if (value > 0) {
        if (widget.fromSale) {
          setReturnBillNo = 0;
          setReturnBillAmount = 0;
        }
        clearCart();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Expanded(
              child: AlertDialog(
                title: const Text('salesReturn Deleted'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/salesReturn');
                    },
                    child: const Text('CANCEL'),
                  )
                ],
              ),
            );
          },
        );
      }
    });
    // dio.deleteSale(dataDynamic[0]['EntryNo'], saleFormId, '').then((value) {
    //   setState(() {
    //     _isLoading = false;
    //   });
    //   if (value) {
    //     clearCart();

    //   }
    // });
  }

  int nextWidget = 0;
  selectWidget() {
    return nextWidget == 0
        ? selectLedgerWidget()
        : nextWidget == 1
            ? selectLedgerDetailWidget()
            : nextWidget == 2
                ? selectProductWidget()
                : nextWidget == 3
                    ? itemDetailWidget()
                    : nextWidget == 4
                        ? cartProduct()
                        : nextWidget == 5
                            ? const Text('No Data 5')
                            : nextWidget == 6
                                ? const Text('No Data 6')
                                : const Text('No Widget');
  }

  bool isData = false;

  selectLedgerWidget() {
    setState(() {
      if (_ledger.isNotEmpty) isData = true;
    });
    return FutureBuilder<List<dynamic>>(
      future: api.getCustomerNameList(),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            if (!isData) {
              ledgerDisplay = data;
              _ledger = data;
            }
            return ListView.builder(
              // shrinkWrap: true,
              itemBuilder: (context, index) {
                return index == 0
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Flexible(
                              child: TextField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Search...',
                                ),
                                onChanged: (text) {
                                  text = text.toLowerCase();
                                  setState(() {
                                    ledgerDisplay = _ledger.where((item) {
                                      var itemName = item.name.toLowerCase();
                                      return itemName.contains(text);
                                    }).toList();
                                  });
                                },
                                autofocus: true,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: kPrimaryColor,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/ledger',
                                    arguments: {'parent': 'CUSTOMERS'});
                              },
                            )
                          ],
                        ),
                      )
                    : InkWell(
                        child: Card(
                          child: ListTile(
                              title: Text(ledgerDisplay[index - 1].name)),
                        ),
                        onTap: () {
                          setState(() {
                            ledgerModel = ledgerDisplay[index - 1];
                            nextWidget = 1;
                            isData = false;
                          });
                        },
                      );
              },
              itemCount: ledgerDisplay.length + 1,
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  SizedBox(height: 20),
                  Text('No Ledger Found..')
                ],
              ),
            );
          }
        } else if (snapshot.hasError) {
          return AlertDialog(
            title: const Text(
              'An Error Occurred!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
              ),
            ),
            content: Text(
              "${snapshot.error}",
              style: const TextStyle(
                color: Colors.blueAccent,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('This may take some time..')
            ],
          ),
        );
      },
    );
  }

  selectLedgerDetailWidget() {
    return FutureBuilder<CustomerModel>(
      future: api.getCustomerDetail(ledgerModel.id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.id != null || snapshot.data.id > 0) {
            return Padding(
              padding: const EdgeInsets.all(35.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    widgetRateType(),
                    const SizedBox(
                      width: 40,
                    ),
                    const Text('Taxable'),
                    Checkbox(
                      value: taxable,
                      onChanged: (value) {
                        setState(() {
                          taxable = value;
                        });
                      },
                    ),
                  ]),
                  Text("Name : " + snapshot.data.name,
                      style: const TextStyle(fontSize: 20)),
                  Text(
                      "Address : " +
                          snapshot.data.address1 +
                          " ," +
                          snapshot.data.address2 +
                          " ," +
                          snapshot.data.address3 +
                          " ," +
                          snapshot.data.address4,
                      style: const TextStyle(fontSize: 18)),
                  Text("Tax No : " + snapshot.data.taxNumber,
                      style: const TextStyle(fontSize: 18)),
                  Text("Phone : " + snapshot.data.phone,
                      style: const TextStyle(fontSize: 18)),
                  Text("Email : " + snapshot.data.email,
                      style: const TextStyle(fontSize: 18)),
                  Text("Balance : " + snapshot.data.balance,
                      style: const TextStyle(fontSize: 18)),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        rateType.isEmpty ? '2' : rateType;
                        ledgerModel = snapshot.data;
                        nextWidget = 2;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        elevation: 0,
                        primary: Colors.red,
                        onPrimary: Colors.white,
                        onSurface: Colors.grey),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const <Widget>[
                          Icon(
                            Icons.shopping_bag,
                            color: Colors.white,
                          ),
                          SizedBox(
                            width: 4.0,
                          ),
                          Text(
                            "Add Product To Cart",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  SizedBox(height: 20),
                  Text('No Data Found..')
                ],
              ),
            );
          }
        } else if (snapshot.hasError) {
          return AlertDialog(
            title: const Text(
              'An Error Occurred!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
              ),
            ),
            content: Text(
              "${snapshot.error}",
              style: const TextStyle(
                color: Colors.blueAccent,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('This may take some time..')
            ],
          ),
        );
      },
    );
  }

  String _dropDownValue = '2-RETAIL';
  widgetRateType() {
    return FutureBuilder(
      future: api.getRateTypeList(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? DropdownButton<String>(
                hint: Text(_dropDownValue.isNotEmpty
                    ? _dropDownValue.split('-')[1]
                    : 'select rate type'),
                items: snapshot.data.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item.id.toString() + "-" + item.name,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _dropDownValue = value;
                    rateType = value.split('-')[0];
                  });
                },
              )
            : Container();
      },
    );
  }

//declare
  bool enableMULTIUNIT = false,
      pRateBasedProfitInSales = false,
      negativeStock = false,
      cessOnNetAmount = false,
      negativeStockStatus = false,
      enableKeralaFloodCess = false,
      useUNIQUECODEASBARCODE = false,
      useOLDBARCODE = false;

  bool isItemData = false;
  selectProductWidget() {
    setState(() {
      if (items.isNotEmpty) isItemData = true;
    });
    return FutureBuilder<List<ProductPurchaseModel>>(
      future: api.fetchAllProductPurchase(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            if (!isItemData) {
              itemDisplay = data;
              items = data;
            }
            return ListView.builder(
              // shrinkWrap: true,
              itemBuilder: (context, index) {
                return index == 0
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Search...'),
                          onChanged: (text) {
                            text = text.toLowerCase();
                            setState(() {
                              itemDisplay = items.where((item) {
                                var itemName = item.itemName.toLowerCase();
                                return itemName.contains(text);
                              }).toList();
                            });
                          },
                          autofocus: true,
                        ),
                      )
                    : InkWell(
                        child: Card(
                          child: ListTile(
                            title: Text(
                                'Name : ${itemDisplay[index - 1].itemName}'),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            productModel = itemDisplay[index - 1];
                            nextWidget = 3;
                            isItemData = false;
                          });
                        },
                      );
              },
              itemCount: itemDisplay.length + 1,
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  SizedBox(height: 20),
                  Text('No Data Found..')
                ],
              ),
            );
          }
        } else if (snapshot.hasError) {
          return AlertDialog(
            title: const Text(
              'An Error Occurred!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
              ),
            ),
            content: Text(
              "${snapshot.error}",
              style: const TextStyle(
                color: Colors.blueAccent,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('This may take some time..')
            ],
          ),
        );
      },
    );
  }

  dynamic productModelPrize;
  itemDetailWidget() {
    int id = editItem ? cartModel.itemId : productModel.slNo;
    int locationId = lId.toString().trim().isNotEmpty ? lId : 1;
    if (editItem) {
      return FutureBuilder<ProductRegisterModel>(
          future: api.getProductById(cartModel.itemId.toString()),
          builder: (context0, snapshot1) {
            if (snapshot1.hasData) {
              var data = snapshot1.data;
              productModel = ProductPurchaseModel(
                  slNo: data.slno,
                  itemCode: data.itemcode,
                  itemName: data.itemname,
                  tax: data.tax,
                  cess: data.cess,
                  cessPer: data.cessper,
                  adCessPer: data.adcessper,
                  stockValuation: data.stockvaluation,
                  typeOfSupply: data.typeofsupply,
                  internationalBarcode: data.internationalbarcode,
                  serialNo: (data.serialno > 0 ? true : false));

              return FutureBuilder(
                  future: api.fetchProductPrizeStock(id, locationId),
                  builder: (context, snapshoNew) {
                    if (snapshoNew.hasData) {
                      if (snapshoNew.data.length > 0) {
                        if (snapshoNew.data.length <= 1) {
                          productModelPrize = snapshoNew.data[0];

                          return showAddMore(context);
                        }
                      } else {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              const Text('Price Data Missing...'),
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      nextWidget = 2;
                                    });
                                  },
                                  child: const Text('Select Product Again'))
                            ],
                          ),
                        );
                      }
                    } else if (snapshoNew.hasError) {
                      return AlertDialog(
                        title: const Text(
                          'An Error Occurred!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent,
                          ),
                        ),
                        content: Text(
                          "${snapshoNew.error}",
                          style: const TextStyle(
                            color: Colors.blueAccent,
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text(
                              'Go Back',
                              style: TextStyle(
                                color: Colors.redAccent,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      );
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const <Widget>[
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text('This may take some time..')
                        ],
                      ),
                    );
                  });
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('This may take some time..')
                ],
              ),
            );
          });
    } else {
      return FutureBuilder(
          future: api.fetchProductPrizeStock(id, locationId),
          builder: (context, snapshoNew) {
            if (snapshoNew.hasData) {
              if (snapshoNew.data.length > 0) {
                if (snapshoNew.data.length <= 1) {
                  productModelPrize = snapshoNew.data[0];

                  return showAddMore(context);
                }
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Text('Price Data Missing...'),
                      TextButton(
                          onPressed: () {
                            setState(() {
                              nextWidget = 2;
                            });
                          },
                          child: const Text('Select Product Again'))
                    ],
                  ),
                );
              }
            } else if (snapshoNew.hasError) {
              return AlertDialog(
                title: const Text(
                  'An Error Occurred!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
                content: Text(
                  "${snapshoNew.error}",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        color: Colors.redAccent,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              );
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('This may take some time..')
                ],
              ),
            );
          });
    }
  }

  bool isVariantSelected = false;
  int positionID = 0;

  clearValue() {
    _quantityController.text = '';
    _freeQuantityController.text = '';
    _rateController.text = '';
    _discountController.text = '';
    _discountPercentController.text = '';
    _serialNoController.text = '';
    taxP = 0;
    tax = 0;
    gross = 0;
    subTotal = 0;
    total = 0;
    quantity = 0;
    rate = 0;
    saleRate = 0;
    discount = 0;
    discountPercent = 0;
    rDisc = 0;
    rRate = 0;
    rateOff = 0;
    kfcP = 0;
    kfc = 0;
    unitValue = 1;
    _conversion = 0;
    freeQty = 0;
    fUnitId = 0;
    fUnitValue = 0;
    cdPer = 0;
    cDisc = 0;
    cess = 0;
    cessPer = 0;
    adCessPer = 0;
    profitPer = 0;
    adCess = 0;
    iGST = 0;
    csGST = 0;
    pRate = 0;
    rPRate = 0;
    uniqueCode = 0;
    _dropDownUnit = 0;
    barcode = 0;
  }

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _freeQuantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _discountPercentController =
      TextEditingController();
  final TextEditingController _serialNoController = TextEditingController();
  FocusNode _focusNodeQuantity = FocusNode();
  FocusNode _focusNodeFreeQuantity = FocusNode();
  FocusNode _focusNodeRate = FocusNode();
  FocusNode _focusNodeDiscount = FocusNode();
  FocusNode _focusNodeDiscountPer = FocusNode();

  final _resetKey = GlobalKey<FormState>();
  String expDate = '2000-01-01';
  int _dropDownUnit = 0, fUnitId = 0, uniqueCode = 0, barcode = 0;

  double taxP = 0,
      tax = 0,
      gross = 0,
      subTotal = 0,
      total = 0,
      quantity = 0,
      rate = 0,
      saleRate = 0,
      discount = 0,
      discountPercent = 0,
      rDisc = 0,
      rRate = 0,
      rateOff = 0,
      kfcP = 0,
      kfc = 0,
      unitValue = 1,
      _conversion = 0,
      freeQty = 0,
      fUnitValue = 0,
      cdPer = 0,
      cDisc = 0,
      cess = 0,
      cessPer = 0,
      adCessPer = 0,
      profitPer = 0,
      adCess = 0,
      iGST = 0,
      csGST = 0,
      pRate = 0,
      rPRate = 0;

  showAddMore(BuildContext context) {
    if (editItem) {
      productModel = productModel == null
          ? ProductPurchaseModel(
              itemName: cartModel.itemName,
              adCessPer: 0,
              cess: cartModel.cess,
              cessPer: cartModel.cess,
              internationalBarcode: '',
              itemCode: cartModel.itemId.toString(),
              serialNo: cartModel.serialNo.isNotEmpty ? true : false,
              slNo: cartModel.itemId,
              stockValuation: '',
              tax: cartModel.tax,
              typeOfSupply: '')
          : productModel;
      pRate = double.tryParse(productModelPrize['prate'].toString());
      rPRate = double.tryParse(productModelPrize['realprate'].toString());
      isTax = taxable;
      taxP = isTax ? double.tryParse(productModel.tax.toString()) : 0;
      cess = isTax ? double.tryParse(productModel.cess.toString()) : 0;
      cessPer = isTax ? double.tryParse(productModel.cessPer.toString()) : 0;
      adCessPer =
          isTax ? double.tryParse(productModel.adCessPer.toString()) : 0;
      kfcP = isTax
          ? enableKeralaFloodCess
              ? kfcPer
              : 0
          : 0;
      if (rateType == 'RETAIL') {
        saleRate = double.tryParse(productModelPrize['retail'].toString());
      } else if (rateType == 'WHOLESALE') {
        saleRate = double.tryParse(productModelPrize['wsrate'].toString());
      } else {
        saleRate = double.tryParse(productModelPrize['mrp'].toString());
      }
      if (saleRate > 0 &&
          !_focusNodeRate.hasFocus &&
          _rateController.text.isEmpty) {
        _rateController.text = saleRate.toStringAsFixed(decimal);
        rate = saleRate;
      }
      uniqueCode = productModelPrize['uniquecode'];
      List<UnitModel> unitList = [];
    } else {
      pRate = double.tryParse(productModelPrize['prate'].toString());
      rPRate = double.tryParse(productModelPrize['realprate'].toString());
      isTax = taxable;
      taxP = isTax ? double.tryParse(productModel.tax.toString()) : 0;
      cess = isTax ? double.tryParse(productModel.cess.toString()) : 0;
      cessPer = isTax ? double.tryParse(productModel.cessPer.toString()) : 0;
      adCessPer =
          isTax ? double.tryParse(productModel.adCessPer.toString()) : 0;
      kfcP = isTax
          ? enableKeralaFloodCess
              ? kfcPer
              : 0
          : 0;
      if (rateType == 'RETAIL') {
        saleRate = double.tryParse(productModelPrize['retail'].toString());
      } else if (rateType == 'WHOLESALE') {
        saleRate = double.tryParse(productModelPrize['wsrate'].toString());
      } else {
        saleRate = double.tryParse(productModelPrize['mrp'].toString());
      }
      if (saleRate > 0 &&
          !_focusNodeRate.hasFocus &&
          _rateController.text.isEmpty) {
        _rateController.text = saleRate.toStringAsFixed(decimal);
        rate = saleRate;
      }
      uniqueCode = productModelPrize['uniquecode'];
      List<UnitModel> unitList = [];
    }
    calculate() {
      if (enableMULTIUNIT) {
        if (saleRate > 0) {
          if (_conversion > 0) {
            if (_focusNodeRate.hasFocus) {
              rate = double.tryParse(_rateController.text);
            } else {
              rate = saleRate * _conversion;
              _rateController.text = rate.toStringAsFixed(decimal);
            }
            pRate = productModelPrize['prate'] * _conversion;
            rPRate = productModelPrize['realprate'] * _conversion;
          } else {
            rate = _rateController.text.isNotEmpty
                ? (double.tryParse(_rateController.text))
                : 0;
          }
        } else {
          rate = _rateController.text.isNotEmpty
              ? (double.tryParse(_rateController.text))
              : 0;
        }
      } else {
        if (_focusNodeRate.hasFocus) {
          rate = double.tryParse(_rateController.text);
        } else if (saleRate > 0) {
          _rateController.text = saleRate.toStringAsFixed(decimal);
          rate = saleRate;
        } else {
          rate = _rateController.text.isNotEmpty
              ? double.tryParse(_rateController.text)
              : 0;
        }
      }
      quantity = _quantityController.text.isNotEmpty
          ? double.tryParse(_quantityController.text)
          : 0;
      freeQty = _freeQuantityController.text.isNotEmpty
          ? double.tryParse(_freeQuantityController.text)
          : 0;
      rRate = taxMethod == 'MINUS'
          ? cessOnNetAmount
              ? CommonService.getRound(
                  4, (100 * rate) / (100 + taxP + kfcP + cessPer))
              : CommonService.getRound(4, (100 * rate) / (100 + taxP + kfcP))
          : rate;
      discount = _discountController.text.isNotEmpty
          ? double.tryParse(_discountController.text)
          : 0;
      double discP = _discountPercentController.text.isNotEmpty
          ? double.tryParse(_discountPercentController.text)
          : 0;
      double disc = _discountController.text.isNotEmpty
          ? double.tryParse(_discountController.text)
          : 0;
      double qt = _quantityController.text.isNotEmpty
          ? double.tryParse(_quantityController.text)
          : 0;
      double sRate = _rateController.text.isNotEmpty
          ? double.tryParse(_rateController.text)
          : 0;
      if (_focusNodeDiscountPer.hasFocus) {
        _discountController.text = _discountPercentController.text.isNotEmpty
            ? (((qt * sRate) * discP) / 100).toStringAsFixed(2)
            : '';
        discount = _discountController.text.isNotEmpty
            ? double.tryParse(_discountController.text)
            : 0;
        discountPercent = double.tryParse(_discountPercentController.text);
      }

      if (_focusNodeDiscount.hasFocus) {
        _discountPercentController.text = _discountController.text.isNotEmpty
            ? ((disc * 100) / (qt * sRate)).toStringAsFixed(2)
            : '';
        discountPercent = _discountController.text.isNotEmpty
            ? double.tryParse(_discountPercentController.text)
            : 0;
        double.tryParse(_discountController.text);
      }
      rDisc = taxMethod == 'MINUS'
          ? CommonService.getRound(
              4,
              ((discount * 100) /
                  (cessOnNetAmount
                      ? (taxP + 100 + cessPer + kfcP)
                      : (taxP + 100 + kfcP))))
          : discount;
      gross = CommonService.getRound(decimal, ((rRate * quantity)));
      subTotal = CommonService.getRound(decimal, (gross - rDisc));
      if (taxP > 0) {
        tax = CommonService.getRound(decimal, ((subTotal * taxP) / 100));
      }
      if (companyTaxMode == 'INDIA') {
        kfc = isKFC
            ? CommonService.getRound(decimal, ((subTotal * kfcP) / 100))
            : 0;
        double csPer = taxP / 2;
        iGST = 0;
        csGST = CommonService.getRound(decimal, ((subTotal * csPer) / 100));
      } else if (companyTaxMode == 'GULF') {
        iGST = CommonService.getRound(decimal, ((subTotal * taxP) / 100));
        csGST = 0;
        kfc = 0;
      } else {
        iGST = 0;
        csGST = 0;
        kfc = 0;
        tax = 0;
      }
      if (cessOnNetAmount) {
        if (cessPer > 0) {
          cess = CommonService.getRound(decimal, ((subTotal * cessPer) / 100));
          adCess = CommonService.getRound(decimal, (quantity * adCessPer));
        } else {
          cess = 0;
          adCess = 0;
        }
      } else {
        cess = 0;
        adCess = 0;
      }
      total = CommonService.getRound(
          2, (subTotal + csGST + csGST + iGST + cess + kfc + adCess));
      if (enableMULTIUNIT && _conversion > 0) {
        profitPer = pRateBasedProfitInSales
            ? CommonService.getRound(2,
                (total - (productModelPrize['prate'] * _conversion * quantity)))
            : CommonService.getRound(
                decimal,
                (total -
                    (productModelPrize['realprate'] * _conversion * quantity)));
      } else {
        profitPer = pRateBasedProfitInSales
            ? CommonService.getRound(
                2, (total - (productModelPrize['prate'] * quantity)))
            : CommonService.getRound(
                2, (total - (productModelPrize['realprate'] * quantity)));
      }
      unitValue = _conversion > 0 ? _conversion : 1;
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          Text(productModel.itemName),
          SingleChildScrollView(
            child: Form(
              key: _resetKey,
              autovalidateMode: AutovalidateMode.always,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Visibility(
                          visible: !editItem,
                          child: MaterialButton(
                            onPressed: () {
                              setState(() {
                                editItem = false;
                                nextWidget = 2;
                                isVariantSelected = false;
                                clearValue();
                              });
                            },
                            child: const Text("BACK"),
                            color: blue[400],
                          ),
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        MaterialButton(
                          onPressed: () {
                            setState(() {
                              editItem = false;
                              isVariantSelected = false;
                              nextWidget = 4;
                              clearValue();
                            });
                          },
                          child: const Text("CANCEL"),
                          color: blue[400],
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        MaterialButton(
                          child: Text(editItem ? 'EDIT' : 'ADD'),
                          color: blue,
                          onPressed: () {
                            setState(() {
                              if (editItem) {
                                cartItem[position].adCess = adCess;
                                cartItem[position].quantity = quantity;
                                cartItem[position].rate = rate;
                                cartItem[position].rRate = rRate;
                                cartItem[position].uniqueCode = uniqueCode;
                                cartItem[position].gross = gross;
                                cartItem[position].discount = discount;
                                cartItem[position].discountPercent =
                                    discountPercent;
                                cartItem[position].rDiscount = rDisc;
                                cartItem[position].fCess = kfc;
                                cartItem[position].serialNo =
                                    _serialNoController.text;
                                cartItem[position].tax = tax;
                                cartItem[position].taxP = taxP;
                                cartItem[position].unitId = _dropDownUnit;
                                cartItem[position].unitValue = unitValue ?? 1;
                                cartItem[position].pRate = pRate;
                                cartItem[position].rPRate = rPRate;
                                cartItem[position].barcode = barcode;
                                cartItem[position].expDate = expDate;
                                cartItem[position].free = freeQty;
                                cartItem[position].fUnitId = fUnitId;
                                cartItem[position].cdPer = cdPer;
                                cartItem[position].cDisc = cDisc;
                                cartItem[position].net = subTotal;
                                cartItem[position].cess = cess;
                                cartItem[position].total = total;
                                cartItem[position].profitPer = profitPer;
                                cartItem[position].fUnitValue = fUnitValue;
                                cartItem[position].adCess = adCess;
                                cartItem[position].iGST = iGST;
                                cartItem[position].cGST = csGST;
                                cartItem[position].sGST = csGST;
                                cartItem[position].stock = 0;
                                editItem = false;
                              } else {
                                addProduct(
                                    CartItem(
                                        id: totalItem + 1,
                                        itemId: int.tryParse(
                                            productModel.slNo.toString()),
                                        itemName:
                                            productModel.itemName.toString(),
                                        quantity: quantity,
                                        rate: rate,
                                        rRate: rRate,
                                        uniqueCode: uniqueCode,
                                        gross: gross,
                                        discount: discount,
                                        discountPercent: discountPercent,
                                        rDiscount: rDisc,
                                        fCess: kfc,
                                        serialNo: _serialNoController.text,
                                        tax: tax,
                                        taxP: taxP,
                                        unitId: _dropDownUnit,
                                        unitValue: unitValue ?? 1,
                                        pRate: pRate,
                                        rPRate: rPRate,
                                        barcode: barcode,
                                        expDate: expDate,
                                        free: freeQty,
                                        fUnitId: fUnitId,
                                        cdPer: cdPer,
                                        cDisc: cDisc,
                                        net: subTotal,
                                        cess: cess,
                                        total: total,
                                        profitPer: profitPer,
                                        fUnitValue: fUnitValue,
                                        adCess: adCess,
                                        iGST: iGST,
                                        cGST: csGST,
                                        sGST: csGST,
                                        minimumRate: 0,
                                        stock: 0),
                                    -1);
                              }
                              if (totalItem > 0) {
                                clearValue();
                                nextWidget = 4;
                              }
                            });
                          },
                        ),
                      ]),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: TextFormField(
                          controller: _quantityController,
                          focusNode: _focusNodeQuantity,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                allow: true, replacementString: '.')
                          ],
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'quantity',
                              hintText: '0.0'),
                          onChanged: (value) {
                            setState(() {
                              calculate();
                            });
                          },
                          autofocus: true,
                        ),
                      )),
                      Visibility(
                        visible: isFreeQty,
                        child: Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: TextFormField(
                            controller: _freeQuantityController,
                            focusNode: _focusNodeFreeQuantity,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                  allow: true, replacementString: '.')
                            ],
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'free qty',
                                hintText: '0.0'),
                            onChanged: (value) {
                              setState(() {
                                calculate();
                              });
                            },
                          ),
                        )),
                      ),
                      Visibility(
                        visible: enableMULTIUNIT,
                        child: Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: FutureBuilder(
                              future: api.fetchUnitOf(int.tryParse(
                                  productModel.itemCode.toString())),
                              builder: (BuildContext context,
                                  AsyncSnapshot snapshot) {
                                if (snapshot.hasData) {
                                  unitList.clear();
                                  for (var i = 0;
                                      i < snapshot.data.length;
                                      i++) {
                                    if (defaultUnitID.toString().isNotEmpty) {
                                      if (snapshot.data[i].id ==
                                          defaultUnitID - 1) {
                                        _dropDownUnit = snapshot.data[i].id;
                                        _conversion =
                                            snapshot.data[i].conversion;
                                      }
                                    }
                                    unitList.add(UnitModel(
                                        id: snapshot.data[i].id,
                                        itemId: snapshot.data[i].itemId,
                                        conversion: snapshot.data[i].conversion,
                                        name: snapshot.data[i].name,
                                        pUnit: snapshot.data[i].pUnit,
                                        sUnit: snapshot.data[i].sUnit,
                                        unit: snapshot.data[i].unit));
                                  }
                                }
                                return snapshot.hasData
                                    ? DropdownButton<String>(
                                        hint: Text(_dropDownUnit > 0
                                            ? UnitSettings.getUnitName(
                                                _dropDownUnit)
                                            : 'Unit'),
                                        items: snapshot.data
                                            .map<DropdownMenuItem<String>>(
                                                (item) {
                                          return DropdownMenuItem<String>(
                                            value: item.id.toString(),
                                            child: Text(item.name),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _dropDownUnit = int.tryParse(value);
                                            for (var i = 0;
                                                i < unitList.length;
                                                i++) {
                                              UnitModel _unit = unitList[i];
                                              if (_unit.unit ==
                                                  int.tryParse(value)) {
                                                _conversion = _unit.conversion;
                                                break;
                                              }
                                            }
                                            calculate();
                                          });
                                        },
                                      )
                                    : Container();
                              },
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: enableMULTIUNIT
                            ? _conversion > 0
                                ? true
                                : false
                            : false,
                        child: Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Text('$_conversion'),
                        )),
                      ),
                    ],
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: TextField(
                            controller: _rateController,
                            focusNode: _focusNodeRate,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                  allow: true, replacementString: '.')
                            ],
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'price',
                                hintText: '0.0'),
                            onChanged: (value) {
                              setState(() {
                                calculate();
                              });
                            },
                          ),
                        )),
                        TextButton.icon(
                            style: ButtonStyle(
                              //   backgroundColor: MaterialStateProperty.all<Color>(
                              //       kPrimaryColor),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  kPrimaryDarkColor),
                              overlayColor: MaterialStateProperty.all<Color>(
                                  kPrimaryDarkColor),
                            ),
                            onPressed: () {
                              List<ProductRating> rateData = [
                                ProductRating(
                                    id: 0,
                                    name: 'MRP',
                                    rate: double.tryParse(
                                        productModelPrize['mrp'].toString())),
                                ProductRating(
                                    id: 1,
                                    name: 'Retail',
                                    rate: double.tryParse(
                                        productModelPrize['retail']
                                            .toString())),
                                ProductRating(
                                    id: 2,
                                    name: 'WsRate',
                                    rate: double.tryParse(
                                        productModelPrize['wsrate']
                                            .toString())),
                                ProductRating(
                                    id: 2,
                                    name: labelSpRate,
                                    rate: double.tryParse(
                                        productModelPrize['spretail']
                                            .toString())),
                                ProductRating(
                                    id: 3,
                                    name: 'Branch',
                                    rate: double.tryParse(
                                        productModelPrize['branch'].toString()))
                              ];
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      scrollable: true,
                                      title: ComSettings.appSettings('bool',
                                              'key-items-prate-sale', false)
                                          ? Column(
                                              children: [
                                                const Text('Select Rate'),
                                                Text(
                                                  'PRate : ${double.tryParse(productModelPrize['prate'].toString())} / RPRate : ${double.tryParse(productModelPrize['realprate'].toString())}',
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                ),
                                              ],
                                            )
                                          : const Text('Select Rate'),
                                      content: SizedBox(
                                        height: 250.0,
                                        width: 400.0,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: rateData.length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return Card(
                                              elevation: 5,
                                              child: ListTile(
                                                  title: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                          rateData[index].name),
                                                      Text(
                                                          ' : ${rateData[index].rate}'),
                                                    ],
                                                  ),
                                                  // subtitle: Text(
                                                  //     'Quantity : ${rateData[index].quantity} Rate ${rateData[index].sellingPrice}'),
                                                  onTap: () {
                                                    Navigator.of(context).pop();
                                                    setState(() {
                                                      rate =
                                                          rateData[index].rate;
                                                      saleRate =
                                                          rateData[index].rate;
                                                      _rateController.text =
                                                          saleRate
                                                              .toStringAsFixed(
                                                                  2);
                                                      calculate();
                                                    });
                                                  }),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  });
                            },
                            icon: const Icon(
                                Icons.arrow_drop_down_circle_outlined),
                            label: const Text('')),
                        Visibility(
                          visible: false, //taxMethod == 'MINUS',
                          child: Text(
                            '$rRate',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        Visibility(
                            visible: productTracking,
                            child: InkWell(
                              child: Container(
                                color: blue,
                                child: const Text(
                                  'Sold',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: white),
                                ),
                              ),
                              onTap: () {
                                productTrackingList(
                                    productModel.slNo.toString());
                              },
                            )),
                      ]),
                  Row(
                    children: [
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: TextField(
                          controller: _discountPercentController,
                          focusNode: _focusNodeDiscountPer,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                allow: true, replacementString: '.')
                          ],
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Discount % ',
                              hintText: '0.0'),
                          onChanged: (value) {
                            setState(() {
                              calculate();
                            });
                          },
                        ),
                      )),
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: TextField(
                          controller: _discountController,
                          focusNode: _focusNodeDiscount,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                allow: true, replacementString: '.')
                          ],
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'discount',
                              hintText: '0.0'),
                          onChanged: (value) {
                            setState(() {
                              calculate();
                            });
                          },
                        ),
                      )),
                    ],
                  ),
                  const Divider(),
                  Visibility(
                    visible: isItemSerialNo,
                    child: Row(
                      children: [
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: TextField(
                            controller: _serialNoController,
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: labelSerialNo.isNotEmpty
                                    ? labelSerialNo
                                    : 'SerialNo'),
                            onChanged: (value) {
                              // setState(() {
                              //   // calculate(product);
                              // });
                            },
                          ),
                        )),
                      ],
                    ),
                  ),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Visibility(
                      visible: isTax,
                      child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Text('Tax % : $taxP')),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text('SubTotal : '),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(subTotal.toStringAsFixed(decimal)),
                    ),
                  ]),
                  Visibility(
                    visible: isTax,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Text('Tax : '),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(tax.toStringAsFixed(decimal)),
                          ),
                        ]),
                  ),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text(
                        'Total : ',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        total.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool editItem = false;
  int position;

  cartProduct() {
    setState(() {
      calculateTotal();
    });
    return Column(
      children: [
        salesHeaderWidget(),
        totalItem > 0
            ? Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cartItem.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: blue.shade100,
                      elevation: 5.0,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              text: TextSpan(
                                  text: '${cartItem[index].itemName}\n',
                                  style: const TextStyle(
                                      color: black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        maxLines: 1,
                                        text: TextSpan(
                                            text: '${cartItem[index].id}/',
                                            style: TextStyle(
                                                color: Colors.blueGrey.shade800,
                                                fontSize: 10.0),
                                            children: [
                                              TextSpan(
                                                  text:
                                                      '${cartItem[index].uniqueCode}/${cartItem[index].itemId}',
                                                  style: const TextStyle(
                                                      fontSize: 10.0,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ]),
                                      ),
                                      RichText(
                                        maxLines: 1,
                                        text: TextSpan(
                                            text: 'Unit: ',
                                            style: TextStyle(
                                                color: Colors.blueGrey.shade800,
                                                fontSize: 12.0),
                                            children: [
                                              TextSpan(
                                                  text:
                                                      '${UnitSettings.getUnitName(cartItem[index].unitId)}\n',
                                                  style: const TextStyle(
                                                      fontSize: 12.0,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ]),
                                      ),
                                    ],
                                  ),
                                ),
                                PlusMinusButtons(
                                  addQuantity: () {
                                    setState(() {
                                      updateProduct(cartItem[index],
                                          cartItem[index].quantity + 1, index);
                                    });
                                  },
                                  deleteQuantity: () {
                                    setState(() {
                                      updateProduct(cartItem[index],
                                          cartItem[index].quantity - 1, index);
                                    });
                                  },
                                  text: cartItem[index].quantity.toString(),
                                ),
                                RichText(
                                  maxLines: 1,
                                  text: TextSpan(
                                      text: 'Rate: ',
                                      style: TextStyle(
                                          color: Colors.blueGrey.shade800,
                                          fontSize: 13.0),
                                      children: [
                                        TextSpan(
                                            text: '${cartItem[index].rate}\n',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.0)),
                                      ]),
                                ),
                                PopUpMenuAction(
                                  onDelete: () {
                                    setState(() {
                                      cartItem.removeAt(index);
                                    });
                                  },
                                  onEdit: () {
                                    setState(() {
                                      editItem = true;
                                      position = index;
                                      cartModel = cartItem.elementAt(position);
                                      _rateController.text =
                                          cartModel.rate.toString();
                                      _quantityController.text =
                                          cartModel.quantity.toString();
                                      _freeQuantityController.text =
                                          cartModel.free.toString();
                                      _discountController.text =
                                          cartModel.discount.toString();
                                      _discountPercentController.text =
                                          cartModel.discountPercent.toString();
                                      _serialNoController.text =
                                          cartModel.serialNo;

                                      nextWidget = 3;
                                    });
                                  },
                                ),
                              ],
                            ),
                            RichText(
                              text: TextSpan(
                                  text: 'Gross:',
                                  style: TextStyle(
                                      color: Colors.blueGrey.shade800,
                                      fontSize: 12.0),
                                  children: [
                                    TextSpan(
                                        text: '${cartItem[index].gross}    ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.0)),
                                    TextSpan(
                                        text: 'Disc:',
                                        style: const TextStyle(fontSize: 12.0),
                                        children: [
                                          TextSpan(
                                              text:
                                                  '${cartItem[index].discountPercent}% ${cartItem[index].discount}    ',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.0)),
                                        ]),
                                    TextSpan(
                                        text: 'Net:',
                                        style: const TextStyle(fontSize: 12.0),
                                        children: [
                                          TextSpan(
                                              text:
                                                  '${cartItem[index].net}    ',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.0)),
                                        ]),
                                    isTax
                                        ? TextSpan(
                                            text:
                                                'Tax:${cartItem[index].taxP}% ',
                                            style:
                                                const TextStyle(fontSize: 12.0),
                                            children: [
                                                TextSpan(
                                                    text:
                                                        '${cartItem[index].tax}    ',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0)),
                                              ])
                                        : const TextSpan(text: ''),
                                    TextSpan(
                                        text: 'Total:',
                                        style: const TextStyle(fontSize: 12.0),
                                        children: [
                                          TextSpan(
                                              text: '${cartItem[index].total}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.0)),
                                        ]),
                                  ]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            : const Center(
                child: Text("No items in Cart"),
              ),
        footerWidget(),
      ],
    );
  }

  void addProduct(product, int index) {
    index = isFreeItem
        ? index
        : cartItem.indexWhere((i) => i.itemId == product.itemId);
    if (index != -1) {
      updateProduct(product, product.quantity + 1, index);
    } else {
      cartItem.add(product);
      calculateTotal();
    }
  }

  void removeProduct(int index) {
    // int index = cartItem.indexWhere((i) => i.id == product.id);
    // cartItem[index].quantity = 1;
    cartItem.removeAt(index);
  }

  void updateProduct(product, qty, int index) {
    // int index = cartItem.indexWhere((i) => i.id == product.id);
    cartItem[index].quantity = qty;

    cartItem[index].gross = CommonService.getRound(
        2, (cartItem[index].rRate * cartItem[index].quantity));
    cartItem[index].net = CommonService.getRound(
        2, (cartItem[index].gross - cartItem[index].rDiscount));
    if (cartItem[index].taxP > 0) {
      cartItem[index].tax = CommonService.getRound(
          2, ((cartItem[index].net * cartItem[index].taxP) / 100));
      if (companyTaxMode == 'INDIA') {
        cartItem[index].fCess = 0; //isKFC
        // ? CommonService.getRound(decimal, ((cartItem[index].net * kfcPer) / 100))
        // : 0;
        double csPer = cartItem[index].taxP / 2;
        double csGST = CommonService.getRound(
            decimal, ((cartItem[index].net * csPer) / 100));
        cartItem[index].sGST = csGST;
        cartItem[index].cGST = csGST;
      } else if (companyTaxMode == 'GULF') {
        cartItem[index].cGST = 0;
        cartItem[index].sGST = 0;
        cartItem[index].iGST = CommonService.getRound(
            2, ((cartItem[index].net * cartItem[index].taxP) / 100));
      } else {
        cartItem[index].cGST = 0;
        cartItem[index].sGST = 0;
        cartItem[index].fCess = 0;
      }
    }
    cartItem[index].total = CommonService.getRound(
        2,
        (cartItem[index].net +
            cartItem[index].cGST +
            cartItem[index].sGST +
            cartItem[index].iGST +
            cartItem[index].cess +
            cartItem[index].fCess +
            cartItem[index].adCess));
    cartItem[index].profitPer = CommonService.getRound(
        2,
        cartItem[index].total -
            cartItem[index].rPRate * cartItem[index].quantity);

    if (cartItem[index].quantity == 0) removeProduct(product);

    calculateTotal();
  }

  void editProduct(String title, String value, int index) {
    // int index = cartItem.indexWhere((i) => i.id == id);
    if (title == 'Edit Rate') {
      cartItem[index].rate = double.tryParse(value);
      // if (cart[index].rRate == 0) {
      //   cart[index].rRate = double.tryParse(value);
      //   isZeroRate = true;
      // } else if (isZeroRate) {
      //   cart[index].rRate = double.tryParse(value);
      // }
      cartItem[index].rRate = taxMethod == 'MINUS'
          ? isKFC
              ? CommonService.getRound(
                  4,
                  (100 * cartItem[index].rate) /
                      (100 + cartItem[index].taxP + kfcPer))
              : CommonService.getRound(4,
                  (100 * cartItem[index].rate) / (100 + cartItem[index].taxP))
          : cartItem[index].rate;
    } else if (title == 'Edit Quantity') {
      // int index = cart.indexWhere((i) => i.id == id);
      cartItem[index].quantity = double.tryParse(value);
    }
    cartItem[index].gross = CommonService.getRound(
        2, (cartItem[index].rRate * cartItem[index].quantity));
    cartItem[index].net = CommonService.getRound(
        2, (cartItem[index].gross - cartItem[index].rDiscount));
    if (cartItem[index].taxP > 0) {
      cartItem[index].tax = CommonService.getRound(
          2, ((cartItem[index].net * cartItem[index].taxP) / 100));
      if (companyTaxMode == 'INDIA') {
        cartItem[index].fCess = 0;
        double csPer = cartItem[index].taxP / 2;
        double csGST = CommonService.getRound(
            decimal, ((cartItem[index].net * csPer) / 100));
        cartItem[index].sGST = csGST;
        cartItem[index].cGST = csGST;
      } else if (companyTaxMode == 'GULF') {
        cartItem[index].cGST = 0;
        cartItem[index].sGST = 0;
        cartItem[index].iGST = CommonService.getRound(
            2, ((cartItem[index].net * cartItem[index].taxP) / 100));
      } else {
        cartItem[index].cGST = 0;
        cartItem[index].sGST = 0;
        cartItem[index].fCess = 0;
      }
    }
    cartItem[index].total = CommonService.getRound(
        2,
        (cartItem[index].net +
            cartItem[index].cGST +
            cartItem[index].sGST +
            cartItem[index].iGST +
            cartItem[index].cess +
            cartItem[index].fCess +
            cartItem[index].adCess));
    cartItem[index].profitPer = CommonService.getRound(
        2,
        cartItem[index].total -
            cartItem[index].rPRate * cartItem[index].quantity);

    calculateTotal();
  }

  salesHeaderWidget() {
    return Center(
        child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(
              width: 10,
            ),
            const Text(
              'Date : ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            InkWell(
              child: Text(
                formattedDate,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              onTap: () => _selectDate(),
            ),
            const SizedBox(
              width: 10,
            ),
            // const Text(
            //   'Cash Bill: ',
            //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            // ),
            // Checkbox(
            //   checkColor: Colors.greenAccent,
            //   activeColor: Colors.red,
            //   value: _isCashBill,
            //   onChanged: (bool value) {
            //     setState(() {
            //       _isCashBill = value;
            //     });
            //   },
            // ),
          ],
        ),
        oldBill
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('EntryNo : ' + dataDynamic[0]['EntryNo'].toString(),
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(
                    width: 10,
                  ),
                  Text('InvoiceNo : ' + dataDynamic[0]['InvoiceNo'].toString(),
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              )
            : Container(),
        ListTile(
          title: Text(ledgerModel.name,
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ledgerModel.address1),
            ],
          ),
        ),
        InkWell(
            child: const SizedBox(
              height: 40,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Text(
                      'Add Item',
                      style: TextStyle(
                          color: blue,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                    ),
                  )),
            ),
            onTap: () {
              setState(() {
                nextWidget = 2;
              });
            }),
      ],
    ));
  }

  footerWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: Colors.blue[50],
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    "SubTotal: " +
                        CommonService.getRound(decimal, totalGrossValue)
                            .toStringAsFixed(decimal),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[300])),
                Text(
                    "Discount : " +
                        CommonService.getRound(decimal, totalDiscount)
                            .toStringAsFixed(decimal),
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[300])),
              ],
            ),
            Visibility(
              visible: isTax,
              child: companyTaxMode == 'INDIA'
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("GST :- ",
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                        Text(
                            "CGST : " +
                                CommonService.getRound(
                                        decimal, taxTotalCartValue / 2)
                                    .toStringAsFixed(decimal),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[400])),
                        Text(
                            "SGST : " +
                                CommonService.getRound(
                                        decimal, taxTotalCartValue / 2)
                                    .toStringAsFixed(decimal),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[400])),
                        Text(
                            "IGST : " +
                                CommonService.getRound(decimal, 0)
                                    .toStringAsFixed(decimal),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[400])),
                        Text(
                            " = " +
                                CommonService.getRound(
                                        decimal, taxTotalCartValue)
                                    .toStringAsFixed(decimal),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[400])),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("VAT: ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[400])),
                        Text(
                            CommonService.getRound(decimal, taxTotalCartValue)
                                .toStringAsFixed(decimal),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[400])),
                      ],
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total: ",
                    style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[500])),
                Text(
                    CommonService.getRound(decimal, totalCartValue)
                        .toStringAsFixed(decimal),
                    style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[500])),
              ],
            ),
            // Card(
            //   elevation: 5,
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //     children: [
            //       Text(
            //           'Balance : ${ComSettings.appSettings('bool', 'key-round-off-amount', false) ? _balance.toStringAsFixed(decimal) : _balance.roundToDouble().toString()}'),
            //       //     const Text('More Details'),
            //       // Switch(
            //       //     value: valueMore,
            //       //     onChanged: (value) {
            //       //       setState(() {
            //       //         valueMore = value;
            //       //       });
            //       //     }),
            //     ],
            //   ),
            // ),
            const Divider(
              height: 2,
            ),
            Visibility(
              visible: valueMore,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: deviceSize.width - 18,
                        height: 35,
                        child: TextField(
                          controller: controllerNarration,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Narration',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: deviceSize.height / 5,
                    child: Container(
                      color: white,
                      child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: otherAmountList.length,
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int index) {
                            _controllers.add(TextEditingController());
                            _controllers[index].text =
                                otherAmountList[index]['Amount'].toString();
                            return Card(
                                elevation: 5,
                                child: Row(children: <Widget>[
                                  expandStyle(
                                      2,
                                      Container(
                                          margin:
                                              const EdgeInsets.only(top: 35),
                                          child: Text(otherAmountList[index]
                                              ['LedName']))),
                                  SizedBox(
                                      height: 35,
                                      width: 100,
                                      child: TextFormField(
                                          decoration: const InputDecoration(
                                              border: OutlineInputBorder()),
                                          controller: TextEditingController
                                              .fromValue(TextEditingValue(
                                                  text: otherAmountList[index]
                                                          ['Amount']
                                                      .toString(),
                                                  selection:
                                                      TextSelection.collapsed(
                                                          offset: otherAmountList[
                                                                      index]
                                                                  ['Amount']
                                                              .toString()
                                                              .length))),
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter(
                                                RegExp(r'[0-9]'),
                                                allow: true,
                                                replacementString: '.')
                                          ],
                                          onFieldSubmitted: (String str) {
                                            var cartTotal = totalCartValue;
                                            if (str.isNotEmpty) {
                                              otherAmountList[index]['Amount'] =
                                                  double.tryParse(str);
                                              otherAmountList[index]
                                                      ['Percentage'] =
                                                  CommonService.getRound(
                                                      2,
                                                      ((double.tryParse(str) *
                                                              100) /
                                                          cartTotal));
                                              var netTotal = cartTotal +
                                                  otherAmountList.fold(
                                                      0.0,
                                                      (t, e) =>
                                                          t +
                                                          double.parse(e[
                                                                      'Symbol'] ==
                                                                  '-'
                                                              ? (e['Amount'] *
                                                                      -1)
                                                                  .toString()
                                                              : e['Amount']
                                                                  .toString()));
                                              setState(() {
                                                grandTotal = netTotal;
                                              });
                                            }
                                          }))
                                ]));
                          }),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      valueMore = valueMore == true ? false : true;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.blue.shade200),
                  ),
                  child: Icon(valueMore
                      ? Icons.keyboard_double_arrow_down_outlined
                      : Icons.keyboard_double_arrow_up_outlined), //Text('More',
                ),
                const Text('GrandTotal : ',
                    style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
                Text(
                    grandTotal > 0
                        ? ComSettings.appSettings(
                                'bool', 'key-round-off-amount', false)
                            ? CommonService.getRound(decimal, grandTotal)
                                .toString()
                            : CommonService.getRound(decimal, grandTotal)
                                .roundToDouble()
                                .toString()
                        : ComSettings.appSettings(
                                'bool', 'key-round-off-amount', false)
                            ? CommonService.getRound(decimal, totalCartValue)
                                .toString()
                            : CommonService.getRound(
                                    2, totalCartValue.roundToDouble())
                                .toString(),
                    style: const TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.red))
              ],
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     const Text('Balance : '),
            //     Text(ComSettings.appSettings(
            //             'bool', 'key-round-off-amount', false)
            //         ? _balance.toStringAsFixed(decimal)
            //         : _balance.roundToDouble().toString()),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  double totalGrossValue = 0;
  double totalDiscount = 0;
  double totalNet = 0;
  double totalCess = 0;
  double totalIgST = 0;
  double totalCgST = 0;
  double totalSgST = 0;
  double totalFCess = 0;
  double totalAdCess = 0;
  double totalRDiscount = 0;
  double taxTotalCartValue = 0;
  double totalCartValue = 0;
  double totalProfit = 0;
  int get totalItem => cartItem.length;

  void clearCart() {
    for (var f in cartItem) {
      f.quantity = 1;
    }
    setState(() {
      cartItem = [];
      calculateTotal();
    });
  }

  void calculateTotal() {
    totalGrossValue = 0;
    totalDiscount = 0;
    totalRDiscount = 0;
    totalNet = 0;
    totalCess = 0;
    totalIgST = 0;
    totalCgST = 0;
    totalSgST = 0;
    totalFCess = 0;
    totalAdCess = 0;
    taxTotalCartValue = 0;
    totalCartValue = 0;
    totalProfit = 0;
    grandTotal = 0;

    for (var f in cartItem) {
      totalGrossValue += f.gross;
      totalDiscount += f.discount;
      totalRDiscount += f.rDiscount;
      totalNet += f.net;
      totalCess += f.cess;
      totalIgST += f.iGST;
      totalCgST += f.cGST;
      totalSgST += f.sGST;
      totalFCess += f.fCess;
      totalAdCess += f.adCess;
      taxTotalCartValue += f.tax;
      totalCartValue += f.total;
      totalProfit += f.profitPer;
    }

    grandTotal = totalCartValue +
        otherAmountList.fold(
            0.0,
            (t, e) =>
                t +
                double.parse(e['Symbol'] == '-'
                    ? (e['Amount'] * -1).toString()
                    : e['Amount'].toString()));
  }

  expandStyle(int flex, Widget child) => Expanded(flex: flex, child: child);

  Future<void> _displayTextInputDialog(
      BuildContext context, String title, String text, int id) async {
    TextEditingController _controller = TextEditingController();
    String valueText;
    _controller.text = ComSettings.getIfInteger(text);
    return showDialog(
      context: context,
      builder: (context) {
        return (StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueText = value;
                });
              },
              controller: _controller,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: "value"),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter(RegExp(r'[0-9]'),
                    allow: true, replacementString: '.')
              ],
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                child: const Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
                child: const Text('OK'),
                onPressed: () {
                  setState(() {
                    editProduct(title, valueText, id);
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        }));
      },
    );
  }

  showMore(context) {
    var form = 'SALES RETURN';
    var title = 'Sales Return';
    var size = "2";
    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/salesReturn');
        },
        onPressedYes: () {
          Navigator.of(context).pop();
          rateType = '1';

          var data = '[' +
              json.encode({
                'statement': 'SalesReturnFind',
                'entryNo': dataDynamic[0]['EntryNo'].toString(),
                'saleFormId': saleFormId,
                'fyId': currentFinancialYear.id
              }) +
              ']';
          final body = {
            'information': '[{}]',
            'data': data,
            'particular': '[{}]',
            'otherAmount': '[{}]'
          };

          // dio
          //     .fetchSalesReturnInvoice(dataDynamic[0]['EntryNo'].toString(), 1)
          //     .then((data) {
          //   if (data != null) {
          //     var dataAll = {
          //       'Information': data['Information'][0],
          //       'Particulars': data['Particulars'],
          //       'otherAmount': data['otherAmount'],
          //       'balance': data['BalanceAmount'].toString()
          //     };
          // var information = data['Information'][0];
          // var particulars = data['Particulars'];
          // var serialNO = value['SerialNO'];
          // var deliveryNoteDetails = value['DeliveryNote'];
          // var message = data['message'];
          // otherAmountList = value['otherAmount'];

          // if (printerType == 2) {
          //   //2: 'Bluetooth',
          //   if (printerDevice == 2) {
          //     //2: 'Default',
          //   } else if (printerDevice == 3) {
          //     //3: 'Line',
          //   } else if (printerDevice == 4) {
          //     //                4: 'Local',
          //   } else if (printerDevice == 5) {
          //     //                5: 'ESC/POS',
          //     printBluetooth(context, title, companySettings, settings,
          //         dataAll, byteImage, size, form);
          //   } else if (printerDevice == 6) {
          //     //                6: 'Thermal',
          //     _selectBtThermalPrint(context, title, companySettings,
          //         settings, dataAll, byteImage, "4");
          //   }
          // }

          // Navigator.of(context).pop();
          Navigator.pushReplacementNamed(context, '/return_preview_show',
              arguments: {'title': 'SalesReturn'});
          //   }
          // });
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage:
            'Do you want to print\nEntryNo : ${dataDynamic[0]['EntryNo']}',
        title: 'SAVED',
        context: context);
  }

  Future _selectDate() async {
    DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => {formattedDate = DateFormat('dd-MM-yyyy').format(picked)});
    }
  }

  showEditDialog(context, dataDynamic) {
    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
        },
        onPressedYes: () {
          Navigator.of(context).pop();
          fetchSaleReturn(context, dataDynamic['Id']);
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage:
            'Do you want to edit or delete\nRefNo:${dataDynamic['Id']}',
        title: 'Update',
        context: context);
  }

  fetchSaleReturn(context, id) {
    rateType = '1';
    double billTotal = 0;

    api.fetchSalesReturnInvoice(id.toString(), 1).then((value) {
      if (value != null) {
        var information = value['Information'][0];
        var particulars = value['Particulars'];
        // var serialNO = value['SerialNO'];
        // var deliveryNoteDetails = value['DeliveryNote'];
        var message = value['message'];
        // otherAmountList = value['otherAmount'];

        formattedDate = DateUtil.dateDMY(information['DDate']);

        dataDynamic = [
          {
            'RealEntryNo': information['RealEntryNo'],
            'EntryNo': information['EntryNo'],
            'InvoiceNo': information['InvoiceNo'],
            'Type': saleFormId
          }
        ];
        billTotal = double.tryParse(information['GrandTotal'].toString());
        controllerNarration.text = information['Narration'];
        CustomerModel cModel = CustomerModel(
            id: information['Customer'],
            name: information['ToName'],
            address1: information['Add1'],
            address2: information['Add2'],
            address3: information['Add3'],
            address4: information['Add4'],
            balance: information['BalanceAmount'].toString(),
            city: '',
            email: '',
            phone: '',
            route: '',
            state: '',
            stateCode: '',
            taxNumber: information['gstno'],
            remarks: '',
            pinNo: '');
        ledgerModel = cModel;
        ScopedModel.of<MainModel>(context).addCustomer(cModel);
        for (var product in particulars) {
          addProduct(
              CartItem(
                  id: totalItem + 1,
                  itemId: product['itemId'],
                  itemName: product['itemname'],
                  quantity: double.tryParse(product['Qty'].toString()),
                  rate: double.tryParse(product['Rate'].toString()),
                  rRate: double.tryParse(product['RealRate'].toString()),
                  uniqueCode: product['UniqueCode'],
                  gross: double.tryParse(product['GrossValue'].toString()),
                  discount: double.tryParse(product['Disc'].toString()),
                  discountPercent:
                      double.tryParse(product['DiscPersent'].toString()),
                  rDiscount: double.tryParse(product['RDisc'].toString()),
                  fCess: double.tryParse(product['Fcess'].toString()),
                  serialNo: product['serialno'].toString(),
                  tax: double.tryParse(product['CGST'].toString()) +
                      double.tryParse(product['SGST'].toString()) +
                      double.tryParse(product['IGST'].toString()),
                  taxP: double.tryParse(product['igst'].toString()),
                  unitId: product['Unit'],
                  unitValue: double.tryParse(product['UnitValue'].toString()),
                  pRate: double.tryParse(product['Prate'].toString()),
                  rPRate: double.tryParse(product['Rprate'].toString()),
                  barcode: product['UniqueCode'],
                  expDate: '2020-01-01',
                  free: double.tryParse(product['freeQty'].toString()),
                  fUnitId: int.tryParse(product['Funit'].toString()),
                  cdPer: 0, //product['']cdPer,
                  cDisc: 0, //product['']cDisc,
                  net: double.tryParse(
                      product['GrossValue'].toString()), //subTotal,
                  cess: double.tryParse(product['cess'].toString()), //cess,
                  total: double.tryParse(product['Total'].toString()), //total,
                  profitPer: 0,
                  fUnitValue: double.tryParse(
                      product['FValue'].toString()), //fUnitValue,
                  adCess:
                      double.tryParse(product['adcess'].toString()), //adCess,
                  iGST: double.tryParse(product['IGST'].toString()),
                  cGST: double.tryParse(product['CGST'].toString()),
                  sGST: double.tryParse(product['SGST'].toString()),
                  minimumRate: 0,
                  stock: 0),
              -1);
        }

        userDateCheck(information['DDate'].toString());
      }

      setState(() {
        widgetID = false;
        grandTotal = billTotal;
        nextWidget = 4;
        oldBill = true;
      });
      // Navigator.pushReplacementNamed(context, '/preview_show',
      // arguments: {'title': 'Sale'});
    });
  }

  Future<void> searchBill(BuildContext context, int type) async {
    TextEditingController _controller = TextEditingController();
    String valueText;
    _controller.text = '';

    return showDialog(
        context: context,
        builder: (BuildContext cx) {
          return AlertDialog(
            title: const Text('Type EntryNo'),
            content: TextField(
              onChanged: (value) {
                valueText = value;
              },
              controller: _controller,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: "EntryNo"),
              keyboardType: const TextInputType.numberWithOptions(),
              inputFormatters: [
                FilteringTextInputFormatter(RegExp(r'[0-9]'),
                    allow: true, replacementString: '.')
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                child: const Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(cx);
                  });
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(cx);
                  if (_controller.text.isNotEmpty) {
                    dataDynamic = [
                      {
                        'Type': type,
                        'InvoiceNo': _controller.text,
                        'EntryNo': int.tryParse(_controller.text) ?? 0,
                        'Id': int.tryParse(_controller.text) ?? 0
                      }
                    ];
                    fetchSaleReturn(context, dataDynamic[0]['Id']);
                  }
                },
              ),
            ],
          );
        });
  }

  Uint8List byteImage;
  loadAsset() async {
    // Test image
    ByteData bytes = await rootBundle.load('assets/logo.png');
    final buffer = bytes.buffer;
    byteImage = Uint8List.view(buffer);
  }

  _selectBtThermalPrint(
      BuildContext context,
      String title,
      CompanyInformation companySettings,
      List<CompanySettings> settings,
      data,
      byteImage,
      size) async {
    var dataAll = [companySettings, settings, data, size, "SALES RETURN"];
    // dataAll.add('Settings[' + settings + ']');b
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BlueThermalPrint(dataAll, byteImage)));
  }

  Future<dynamic> printBluetooth(
      BuildContext context,
      String title,
      CompanyInformation companySettings,
      List<CompanySettings> settings,
      data,
      byteImage,
      size,
      form) async {
    var dataAll = [companySettings, settings, data, size, form];
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => BtPrint(dataAll, byteImage)));
  }

  productTrackingList(String id) {
    var ledId =
        ledgerModel.id.toString().isNotEmpty ? ledgerModel.id.toString() : '0';
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Previous  Sold Price'),
            content: SizedBox(
                width: deviceSize.width - 10,
                height: deviceSize.height - 20,
                child: productTrackingListData(ledId, id)),
            actions: [
              InkWell(
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Close",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  productTrackingListData(ledger, String itemId) {
    return FutureBuilder(
        future: api.getSoldProductTracking(itemId, ledger),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.length > 0) {
              List<dynamic> data = snapshot.data;
              return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      child: ListTile(
                        title: Text(data[index]['Supplier'].toString(),
                            style: const TextStyle(fontSize: 12)),
                        trailing: Text(data[index]['Date'].toString()),
                        subtitle: Text(
                            'Qty : ${data[index]['Qty']} Rate : ${data[index]['Rate']}\n Disc : ${data[index]['Disc']}   ${data[index]['DiscPersent']}%'),
                        onLongPress: () {
                          Navigator.of(context).pop();
                          setState(() {
                            // rate = data[index]['Rate'].toDouble();
                            // saleRate = data[index]['Rate'].toDouble();
                            // _rateController.text = saleRate.toStringAsFixed(2);
                            // calculate();
                          });
                        },
                      ),
                    );
                  });
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(height: 20),
                    Text('Product not sold'),
                    // TextButton(
                    //     onPressed: () {
                    //       setState(() {
                    //         nextWidget = 2;
                    //       });
                    //     },
                    //     child: const Text('Select Product Again'))
                  ],
                ),
              );
            }
          } else if (snapshot.hasError) {
            return AlertDialog(
              title: const Text(
                'An Error Occurred!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
              content: Text(
                "${snapshot.error}",
                style: const TextStyle(
                  color: Colors.blueAccent,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('This may take some time..')
              ],
            ),
          );
        });
  }
}

double _returnBillAmount = 0;
double get getReturnBillAmount => _returnBillAmount;
set setReturnBillAmount(double amount) => _returnBillAmount = amount;
int _returnBillNo = 0;
int get getReturnBillNo => _returnBillNo;
set setReturnBillNo(int no) => _returnBillNo = no;
