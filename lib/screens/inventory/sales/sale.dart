// @dart = 2.9
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/models/option_rate_type.dart';
import 'package:sheraccerp/models/order.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/models/stock_item.dart';
import 'package:sheraccerp/models/stock_product.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/inventory/sales/previous_bill.dart';
import 'package:sheraccerp/screens/inventory/sales/sales_return.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/color_palette.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/dbhelper.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class Sale extends StatefulWidget {
  const Sale({Key key}) : super(key: key);

  @override
  _SaleState createState() => _SaleState();
}

class _SaleState extends State<Sale> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<SalesType> salesTypeDisplay = [];
  bool _defaultSale = false,
      thisSale = false,
      _isLoading = false,
      isCustomForm = false,
      buttonEvent = false;
  // final bool _autoVariantSelect = true;
  DioService dio = DioService();
  Size deviceSize;
  var ledgerModel;
  StockItem productModel;
  List<CartItem> cartItem = [];
  List<dynamic> otherAmountList = [];
  bool isTax = true,
      otherAmountLoaded = false,
      valueMore = false,
      lastRecord = false,
      widgetID = true,
      previewData = false,
      oldBill = false,
      itemCodeVise = false,
      isItemRateEditLocked = false,
      isMinimumRate = false,
      isItemDiscountEditLocked = false,
      isItemSerialNo = false,
      keyItemsVariantStock = false,
      enableBarcode = false,
      _isReturnInSales = false,
      productTracking = false,
      isFreeItem = false;
  final List<TextEditingController> _controllers = [];
  DateTime now = DateTime.now();
  String formattedDate, _narration = '';
  double _balance = 0, grandTotal = 0;
  final TextEditingController _controllerCashReceived = TextEditingController();

  int page = 1, pageTotal = 0, totalRecords = 0;
  int saleAccount = 0, acId = 0, decimal = 2;
  List<dynamic> ledgerDisplay = [];
  List<dynamic> _ledger = [];
  List<dynamic> itemDisplay = [];
  List<dynamic> items = [];
  int lId = 0, groupId = 0, areaId = 0, routeId = 0;
  var salesManId = 0;
  bool ledgerScanner = false, productScanner = false, loadScanner = false;

  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

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

    groupId =
        ComSettings.appSettings('int', 'key-dropdown-default-group-view', 0) -
            1;
    areaId =
        ComSettings.appSettings('int', 'key-dropdown-default-area-view', 0) - 1;
    routeId =
        ComSettings.appSettings('int', 'key-dropdown-default-route-view', 0) -
            1;

    saleAccount = mainAccount.firstWhere(
        (element) => element['LedName'] == 'GENERAL SALES A/C')['LedCode'];
    acId = mainAccount
        .firstWhere((element) => element['LedName'] == 'CASH')['LedCode'];
    acId = ComSettings.appSettings('int', 'key-dropdown-default-cash-ac', 0) -
                1 >
            acId
        ? ComSettings.appSettings('int', 'key-dropdown-default-cash-ac', acId) -
            1
        : acId;

    ledgerScanner = ComSettings.appSettings('bool', 'key-customer-scan', false);
    itemCodeVise = ComSettings.appSettings('bool', 'key-item-by-code', false);
    keyItemsVariantStock =
        ComSettings.appSettings('bool', 'key-items-variant-stock', false);

    dio.getRateTypeList().then((value) {
      setState(() {
        rateTypeList = value;

        String rateTypeS =
            salesTypeData.rateType.isNotEmpty ? salesTypeData.rateType : 'MRP';

        rateTypeItem =
            rateTypeList.firstWhere((element) => element.name == rateTypeS);
      });
    });
  }

  CompanyInformation companySettings;
  List<CompanySettings> settings;
  List rateTypeList = [];

  loadSettings() {
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();

    taxMethod = companySettings.taxCalculation;
    enableMULTIUNIT = ComSettings.getStatus('ENABLE MULTI-UNIT', settings);
    pRateBasedProfitInSales =
        ComSettings.getStatus('PRATE BASED PROFIT IN SALES', settings);
    negativeStock = ComSettings.getStatus('ALLOW NEGETIVE STOCK', settings);
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    cessOnNetAmount = ComSettings.getStatus('CESS ON NET AMOUNT', settings);
    enableKeralaFloodCess = false;
    enableBarcode = ComSettings.getStatus('ENABLE BARCODE OPTION', settings);
    useUNIQUECODEASBARCODE =
        ComSettings.getStatus('USE UNIQUECODE AS BARCODE', settings);
    useOLDBARCODE = ComSettings.getStatus('USE OLD BARCODE', settings);
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;
    isItemSerialNo = ComSettings.getStatus('KEY ITEM SERIAL NO', settings);
    isItemDiscountEditLocked =
        ComSettings.getStatus('KEY LOCK SALES DISCOUNT', settings);
    isItemRateEditLocked =
        ComSettings.getStatus('KEY LOCK SALES RATE', settings);
    isMinimumRate =
        ComSettings.getStatus('KEY LOCK MINIMUM SALES RATE', settings);
    _isReturnInSales = ComSettings.getStatus('SALES-RETURN IN SALES', settings);
    productTracking =
        ComSettings.getStatus('ENABLE PRODUCT TRACKING IN SALES', settings);
    isFreeItem = ComSettings.getStatus('KEY FREE ITEM', settings);
  }

  @override
  Widget build(BuildContext context) {
    deviceSize = MediaQuery.of(context).size;
    final routes =
        ModalRoute.of(context).settings.arguments as Map<String, bool>;
    thisSale = routes['default'];
    taxable = salesTypeData != null
        ? salesTypeData.type == 'SALES-ES'
            ? false
            : true
        : taxable;

    return WillPopScope(
        onWillPop: _onWillPop,
        child: widgetID ? widgetPrefix(thisSale) : widgetSuffix(thisSale));
  }

  Future<bool> _onWillPop() async {
    if (nextWidget == 3) {
      return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Back'),
              content: const Text('Select Item Again?'),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      nextWidget = 2;
                      clearValue();
                    });
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Select'),
                ),
              ],
            ),
          )) ??
          false;
    } else if (loadReturnForm) {
      setState(() {
        loadReturnForm = false;
        returnBillId = getReturnBillNo != null
            ? getReturnBillNo > 0
                ? getReturnBillNo
                : 0
            : 0;
        returnEntryNoController.text = getReturnBillNo != null
            ? getReturnBillNo > 0
                ? getReturnBillNo.toString()
                : ''
            : '';
        returnAmount = getReturnBillAmount != null
            ? getReturnBillAmount > 0
                ? getReturnBillAmount
                : 0
            : 0;
        returnAmountController.text = getReturnBillAmount != null
            ? getReturnBillAmount > 0
                ? getReturnBillAmount.toString()
                : ''
            : '';
        if (returnAmount > 0) {
          grandTotal = grandTotal - returnAmount;
        }
      });
    } else {
      return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Are you sure?'),
              content: const Text('Do you want to exit Sale'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          )) ??
          false;
    }
  }

  widgetSuffix(thisSale) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Sales"),
          actions: [
            Visibility(
              visible: enableBarcode,
              child: IconButton(
                  onPressed: () {
                    searchProductBarcode();
                  },
                  icon: const Icon(Icons.document_scanner)),
            ),
            Visibility(
              visible: oldBill,
              child: IconButton(
                  color: red,
                  iconSize: 40,
                  onPressed: () {
                    if (buttonEvent) {
                      return;
                    } else {
                      if (companyUserData.deleteData) {
                        if (totalItem > 0) {
                          setState(() {
                            _isLoading = true;
                            buttonEvent = true;
                          });
                          _insert(
                              'Delete DateTime:' +
                                  formattedDate +
                                  _time +
                                  ' location:' +
                                  lId.toString() +
                                  ' ' +
                                  CartItem.encodeCartToJson(cartItem)
                                      .toString(),
                              0);
                          deleteSale(context);
                        } else {
                          Fluttertoast.showToast(
                              msg: 'Please select atleast one bill');
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
                        if (companyUserData.updateData) {
                          if (totalItem > 0) {
                            setState(() {
                              _isLoading = true;
                              buttonEvent = true;
                            });
                            _insert(
                                'Edit DateTime:' +
                                    formattedDate +
                                    _time +
                                    ' location:' +
                                    lId.toString() +
                                    ' ' +
                                    CartItem.encodeCartToJson(cartItem)
                                        .toString(),
                                0);
                            updateSale();
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Please select atleast one bill');
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
                      }
                    },
                    icon: const Icon(Icons.edit))
                : IconButton(
                    color: white,
                    iconSize: 40,
                    onPressed: () {
                      if (buttonEvent) {
                        return;
                      } else {
                        if (companyUserData.insertData) {
                          if (totalItem > 0) {
                            setState(() {
                              _isLoading = true;
                              buttonEvent = true;
                            });
                            _insert(
                                'SAVE DateTime:' +
                                    formattedDate +
                                    _time +
                                    ' location:' +
                                    lId.toString() +
                                    ' ' +
                                    CartItem.encodeCartToJson(cartItem)
                                        .toString(),
                                0);
                            saveSale();
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Please add atleast one item');
                            setState(() {
                              buttonEvent = false;
                            });
                          }
                        } else {
                          Fluttertoast.showToast(
                              msg: 'Permission denied\ncan`t save');
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

  widgetPrefix(thisSale) {
    setState(() {
      if (thisSale) {
        previewData = true;
      }
    });
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
        body: thisSale
            ? Container(
                child: previousBill(),
              )
            : _defaultSale
                ? Container(
                    child: previousBill(),
                  )
                : previewData
                    ? Container(
                        child: previousBill(),
                      )
                    : Container(child: selectSalesType()));
  }

  final ScrollController _scrollController = ScrollController();
  bool isLoadingData = false;
  List dataDisplay = [];

  void _getMoreData() async {
    if (!lastRecord) {
      if (dataDisplay.isEmpty ||
          // ignore: curly_braces_in_flow_control_structures
          dataDisplay.length < totalRecords) if (!isLoadingData) {
        setState(() {
          isLoadingData = true;
        });

        List tempList = [];
        var statement = 'SalesList';
        var locationId =
            lId.toString().trim().isNotEmpty ? lId : salesTypeData.location;

        dio
            .getPaginationList(
                statement,
                page,
                locationId.toString(),
                salesTypeData.id.toString(),
                DateUtil.dateYMD(formattedDate),
                salesManId.toString())
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
    if (controller != null) {
      controller.dispose();
    }
    super.dispose();
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
                return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    height: 80,
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 5),
                          blurRadius: 6,
                          color: const Color(0xff000000).withOpacity(0.06),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dataDisplay[index]['Name'],
                                  // maxLines: 1,
                                  style: const TextStyle(
                                    // fontFamily: "Nunito",
                                    // fontSize: 16,
                                    color: ColorPalette.timberGreen,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Date :${dataDisplay[index]['Date']}',
                                      maxLines: 1,
                                      style: TextStyle(
                                        // fontFamily: "Nunito",
                                        fontSize: 12,
                                        color: ColorPalette.timberGreen
                                            .withOpacity(0.44),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 5,
                                        top: 2,
                                        right: 5,
                                      ),
                                      child: Icon(
                                        Icons.circle,
                                        size: 5,
                                        color: ColorPalette.timberGreen
                                            .withOpacity(0.44),
                                      ),
                                    ),
                                    Text(
                                      'EntryNo :${dataDisplay[index]['Id'].toString()}',
                                      maxLines: 1,
                                      style: TextStyle(
                                        // fontFamily: "Nunito",
                                        fontSize: 12,
                                        color: ColorPalette.timberGreen
                                            .withOpacity(0.44),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              showEditDialog(context, dataDisplay[index]);
                            },
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    // fontFamily: "Nunito",
                                    fontSize: 14,
                                    color: ColorPalette.nileBlue,
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                        '${dataDisplay[index]['Total'].toStringAsFixed(decimal)}'),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              showDetails(context, dataDisplay[index]);
                            },
                          ),
                        ),
                      ],
                    ));
                // return Card(
                //   elevation: 3,
                //   clipBehavior: Clip.hardEdge,
                //   margin: EdgeInsets.all(2),
                //   child: ListTile(
                //     title: Text(dataDisplay[index]['Name']),
                //     subtitle: Text('Date: ' +
                //         dataDisplay[index]['Date'] +
                //         ' / EntryNo : ' +
                //         dataDisplay[index]['Id'].toString()),
                //     trailing: Text(
                //         'Total : ' + dataDisplay[index]['Total'].toString()),
                //     onTap: () {
                //       if (userRole == 'SALESMAN') {
                //         showEditDialog(context, dataDisplay[index]);
                //       } else {
                //         showEditDialog(context, dataDisplay[index]);
                //       }
                //     },
                //   ),
                // );

              }
            },
            controller: _scrollController,
          )
        : Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("No items in " + salesTypeData.name),
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
                  label: Text('Take New ' + salesTypeData.name))
            ],
          ));
  }

  void _insert(name, status) async {
    //
  }

  saveSale() async {
    List<CustomerModel> ledger = [];
    // ledger.add(ledgerModel);
    ledger.add(CustomerModel(
        address1: ledgerModel.address1 + " " + ledgerModel.address2,
        address2: ledgerModel.address3 + " " + ledgerModel.address4,
        address3: ledgerModel.taxNumber,
        address4: ledgerModel.taxNumber,
        balance: ledgerModel.balance,
        city: ledgerModel.city,
        email: ledgerModel.email,
        id: ledgerModel.id,
        name: ledgerModel.name,
        phone: ledgerModel.phone,
        remarks: ledgerModel.remarks,
        route: ledgerModel.route,
        state: ledgerModel.state,
        stateCode: ledgerModel.stateCode,
        taxNumber: ledgerModel.taxNumber));

    var locationId =
        lId.toString().trim().isNotEmpty ? lId : salesTypeData.location;

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
        cashReceived: _controllerCashReceived.text.isNotEmpty
            ? _controllerCashReceived.text
            : '0',
        otherDiscount: '0',
        loadingCharge: '0',
        otherCharges: '0',
        labourCharge: '0',
        discountPer: '0',
        balanceAmount: _balance > 0
            ? _balance.toStringAsFixed(decimal)
            : _controllerCashReceived.text.isNotEmpty
                ? grandTotal > 0
                    ? ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? (grandTotal -
                                double.tryParse(_controllerCashReceived.text))
                            .toStringAsFixed(decimal)
                        : (grandTotal -
                                double.tryParse(_controllerCashReceived.text))
                            .roundToDouble()
                            .toString()
                    : ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? ((totalCartValue) -
                                double.tryParse(_controllerCashReceived.text))
                            .toStringAsFixed(decimal)
                        : ((totalCartValue) -
                                double.tryParse(_controllerCashReceived.text))
                            .roundToDouble()
                            .toString()
                : grandTotal > 0
                    ? ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? grandTotal.toStringAsFixed(decimal)
                        : grandTotal.roundToDouble().toString()
                    : ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? totalCartValue.toStringAsFixed(decimal)
                        : totalCartValue.roundToDouble().toString(),
        creditPeriod: '0',
        narration: _narration.isNotEmpty ? _narration : '',
        takeUser: userIdC.toString(),
        location: locationId.toString(),
        billType: companyTaxMode == 'GULF' ? '2' : '0',
        roundOff: '0',
        salesMan: salesManId.toString(),
        sType: salesTypeData.rateType,
        dated: DateUtil.dateYMD(formattedDate),
        cashAC: acId.toString(),
        otherAmountData: otherAmountList);
    if (order.lineItems.isNotEmpty) {
      var jsonLedger = CustomerModel.encodeCustomerToJson(order.customerModel);
      var jsonItem = CartItem.encodeCartToJson(order.lineItems);
      var items = json.encode(jsonItem);
      var ledger = json.encode(jsonLedger);
      var otherAmount = json.encode(order.otherAmountData);
      var saleFormId = salesTypeData.id;
      var saleFormType = salesTypeData.type;
      var taxType = salesTypeData.type == 'SALES-ES'
          ? isTax
              ? 'T'
              : 'NT'
          : salesTypeData.type == 'SALES-Q'
              ? isTax
                  ? 'T'
                  : 'NT'
              : salesTypeData.type == 'SALES-O'
                  ? isTax
                      ? 'T'
                      : 'NT'
                  : 'T';
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
            'statement': 'SalesInsert',
            'entryNo': 0,
            'invoiceNo': 0,
            'saleFormId': saleFormId,
            'saleFormType': saleFormType,
            'taxType': taxType,
            'date': order.dated,
            'time': '1900-01-01 ' +
                DateFormat("H:m:s:S")
                    .format(DateTime.now())
                    .toString(), //1900-01-01 19:27:23.930
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
            'returnNo': returnBillId,
            'returnAmount': returnAmount
          }) +
          ']';

      final body = {'information': ledger, 'data': data, 'particular': items};

      dio.addSale(body).then((value) {
        if (value > 0) {
          final bodyJsonAmount = {
            'statement': 'SalesInsert',
            'entryNo': value.toString(),
            'data': otherAmount,
            'date': order.dated.toString(),
            'saleFormType': saleFormType,
            'narration': order.narration,
            'location': order.location.toString(),
            'id': order.customerModel[0].id.toString()
          };
          dio.addOtherAmount(bodyJsonAmount).then((ret) {
            if (ret) {
              final bodyJson = {
                'statement': 'CheckPrint',
                'entryNo': value.toString(),
                'sType': salesRateTypeId,
                'grandTotal': ComSettings.appSettings(
                        'bool', 'key-round-off-amount', false)
                    ? grandTotal.toStringAsFixed(decimal)
                    : grandTotal.roundToDouble().toString()
              };
              dio.checkBill(bodyJson).then((data) {
                if (data) {
                  dataDynamic = [
                    {
                      'RealEntryNo': value,
                      'EntryNo': value,
                      'InvoiceNo': value.toString(),
                      'Type': salesTypeData.id
                    }
                  ];
                  if (ComSettings.appSettings(
                      'bool', 'key-sms-customer', false)) {
                    var billName = salesTypeData.name == "Sales Order Entry"
                        ? "Order"
                        : "Bill";
                    var ob = ledgerModel.balance.toString().split(' ');
                    var ob1 = ob[0];
                    var ob2 = ob[1];
                    var amt = salesTypeData.name == "Sales Order Entry"
                        ? ledgerModel.balance
                        : ob2 == 'Dr'
                            ? double.tryParse(ob1) +
                                double.tryParse(order.balanceAmount)
                            : double.tryParse(order.balanceAmount) -
                                double.tryParse(ob1);
                    String smsBody =
                        "Dear ${ledgerModel.name},\nYour Sales $billName ${value.toString()}, Dated : $formattedDate for the Amount of ${order.grandTotal}/- \nBalance:$amt /- has been confirmed  \n${companySettings.name}";
                    if (ledgerModel.phone.toString().isNotEmpty) {
                      sendSms(ledgerModel.phone, smsBody);
                    }
                  }
                  clearCart();
                  showMore(context);
                }
              });
            }
          });
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  updateSale() {
    List<CustomerModel> ledger = [];
    ledger.add(CustomerModel(
        address1: ledgerModel.address1 + " " + ledgerModel.address2,
        address2: ledgerModel.address3 + " " + ledgerModel.address4,
        address3: ledgerModel.taxNumber,
        address4: ledgerModel.taxNumber,
        balance: ledgerModel.balance,
        city: ledgerModel.city,
        email: ledgerModel.email,
        id: ledgerModel.id,
        name: ledgerModel.name,
        phone: ledgerModel.phone,
        remarks: ledgerModel.remarks,
        route: ledgerModel.route,
        state: ledgerModel.state,
        stateCode: ledgerModel.stateCode,
        taxNumber: ledgerModel.taxNumber));

    var locationId =
        lId.toString().trim().isNotEmpty ? lId : salesTypeData.location;

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
        cashReceived: _controllerCashReceived.text.isNotEmpty
            ? _controllerCashReceived.text
            : '0',
        otherDiscount: '0',
        loadingCharge: '0',
        otherCharges: '0',
        labourCharge: '0',
        discountPer: '0',
        balanceAmount: _balance > 0
            ? _balance.toStringAsFixed(decimal)
            : _controllerCashReceived.text.isNotEmpty
                ? grandTotal > 0
                    ? ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? (grandTotal -
                                double.tryParse(_controllerCashReceived.text))
                            .toStringAsFixed(decimal)
                        : (grandTotal -
                                double.tryParse(_controllerCashReceived.text))
                            .roundToDouble()
                            .toString()
                    : ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? ((totalCartValue) -
                                double.tryParse(_controllerCashReceived.text))
                            .toStringAsFixed(decimal)
                        : ((totalCartValue) -
                                double.tryParse(_controllerCashReceived.text))
                            .roundToDouble()
                            .toString()
                : grandTotal > 0
                    ? ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? grandTotal.toStringAsFixed(decimal)
                        : grandTotal.roundToDouble().toString()
                    : ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? totalCartValue.toStringAsFixed(decimal)
                        : totalCartValue.roundToDouble().toString(),
        creditPeriod: '0',
        narration: _narration.isNotEmpty ? _narration : '',
        takeUser: userIdC.toString(),
        location: locationId.toString(),
        billType: companyTaxMode == 'GULF' ? '2' : '0',
        roundOff: '0',
        salesMan: salesManId.toString(),
        sType: salesTypeData.rateType,
        dated: DateUtil.dateYMD(formattedDate),
        cashAC: acId.toString(),
        otherAmountData: otherAmountList);
    if (order.lineItems.isNotEmpty) {
      var jsonLedger = CustomerModel.encodeCustomerToJson(order.customerModel);
      var jsonItem = CartItem.encodeCartToJson(order.lineItems);
      var items = json.encode(jsonItem);
      var ledger = json.encode(jsonLedger);
      var otherAmount = json.encode(order.otherAmountData);
      var saleFormId = salesTypeData.id;
      var saleFormType = salesTypeData.type;
      var taxType = salesTypeData.type == 'SALES-ES'
          ? isTax
              ? 'T'
              : 'NT'
          : salesTypeData.type == 'SALES-Q'
              ? isTax
                  ? 'T'
                  : 'NT'
              : salesTypeData.type == 'SALES-O'
                  ? isTax
                      ? 'T'
                      : 'NT'
                  : 'T';
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
            'statement': 'SalesUpdate',
            'entryNo': dataDynamic[0]['EntryNo'],
            'invoiceNo': dataDynamic[0]['InvoiceNo'],
            'saleFormId': saleFormId,
            'saleFormType': saleFormType,
            'taxType': taxType,
            'date': order.dated,
            'time': '1900-01-01 ' +
                DateFormat("H:m:s:S")
                    .format(DateTime.now())
                    .toString(), //1900-01-01 19:27:23.930
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
            'returnNo': returnBillId,
            'returnAmount': returnAmount
          }) +
          ']';

      final body = {'information': ledger, 'data': data, 'particular': items};
      dio.editSale(body).then((value) {
        if (value > 0) {
          final bodyJsonAmount = {
            'statement': 'SalesUpdate',
            'entryNo': dataDynamic[0]['EntryNo'].toString(),
            'data': otherAmount,
            'date': order.dated.toString(),
            'saleFormType': saleFormType,
            'narration': order.narration,
            'location': order.location.toString(),
            'id': order.customerModel[0].id.toString()
          };
          dio.addOtherAmount(bodyJsonAmount).then((ret) {
            if (ret) {
              final bodyJson = {
                'statement': 'CheckPrint',
                'entryNo': dataDynamic[0]['EntryNo'].toString(),
                'sType': salesRateTypeId,
                'grandTotal': ComSettings.appSettings(
                        'bool', 'key-round-off-amount', false)
                    ? grandTotal.toStringAsFixed(decimal)
                    : grandTotal.roundToDouble().toString()
              };
              dio.checkBill(bodyJson).then((data) {
                if (data) {
                  clearCart();
                  showMore(context);
                }
              });
            }
          });
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  deleteSale(context) {
    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
          setState(() {
            _isLoading = false;
          });
        },
        onPressedYes: () {
          Navigator.of(context).pop();
          deleteSaleData();
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage: 'Do you want to Delete',
        title: 'Delete Bill',
        context: context);
  }

  deleteSaleData() {
    dio
        .deleteSale(
            dataDynamic[0]['EntryNo'], salesTypeData.id, salesTypeData.type)
        .then((value) {
      setState(() {
        _isLoading = false;
      });
      if (value) {
        setState(() {
          buttonEvent = false;
        });
        clearCart();
        cartItem.clear();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Expanded(
              child: AlertDialog(
                title: const Text('Sale Deleted'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/sales',
                          arguments: {'default': false});
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
  }

  int nextWidget = 0;
  selectWidget() {
    return nextWidget == 0
        ? loadScanner
            ? scannerWidget()
            : selectLedgerWidget()
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

  selectSalesType() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: isCustomForm ? salesTypeDisplay.length : salesTypeList.length,
      itemBuilder: (context, index) {
        return _listSalesTypItem(index);
      },
    );
  }

  _listSalesTypItem(index) {
    return InkWell(
      child: Card(
        child: ListTile(
            title: Text(isCustomForm
                ? salesTypeDisplay[index].name
                : salesTypeList[index].name)),
      ),
      onTap: () {
        setState(() {
          salesTypeData =
              isCustomForm ? salesTypeDisplay[index] : salesTypeList[index];
          previewData = true;
          taxable = salesTypeData != null
              ? salesTypeData.type == 'SALES-ES'
                  ? false
                  : true
              : taxable;
          rateTypeItem = rateTypeList
              .firstWhere((element) => element.name == salesTypeData.rateType);
        });
      },
    );
  }

  var nameLike = "ca";
  selectLedgerWidget() {
    return FutureBuilder<List<dynamic>>(
      future: dio.getCustomerNameListLike(
          groupId, areaId, routeId, salesManId, nameLike),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            return ListView.builder(
              // shrinkWrap: true,
              itemBuilder: (context, index) {
                return index == 0
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Visibility(
                                visible: ledgerScanner,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.qr_code,
                                    color: kPrimaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      loadScanner = true;
                                    });
                                  },
                                )),
                            Flexible(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search...',
                                ),
                                onChanged: (text) {
                                  text = text.toLowerCase();
                                  setState(() {
                                    // ledgerDisplay = _ledger.where((item) {
                                    //   var itemName = item.name.toLowerCase();
                                    // return itemName.contains(text);
                                    // }).toList();
                                    nameLike = text.isNotEmpty ? text : 'ca';
                                  });
                                },
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
                          child: ListTile(title: Text(data[index - 1].name)),
                        ),
                        onTap: () {
                          setState(() {
                            ledgerModel = data[index - 1];
                            nextWidget = 1;
                            isData = false;
                          });
                        },
                      );
              },
              itemCount: data.length + 1,
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

  bool isData = false;

  selectLedgerWidgetOld() {
    setState(() {
      if (_ledger.isNotEmpty) isData = true;
    });
    return FutureBuilder<List<dynamic>>(
      future:
          dio.getCustomerNameListByParent(groupId, areaId, routeId, salesManId),
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
                            Visibility(
                                visible: ledgerScanner,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.qr_code,
                                    color: kPrimaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      loadScanner = true;
                                      // Navigator.of(context)
                                      //     .push(MaterialPageRoute(
                                      //   builder: (context) => QRViewExample(),
                                      // ));
                                    });
                                  },
                                )),
                            Flexible(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search...',
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

  scannerWidget() {
    return Column(
      children: <Widget>[
        Expanded(flex: 4, child: _buildQrView(context)),
        Expanded(
          flex: 1,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                if (result != null)
                  Text(
                      'Barcode Type: ${describeEnum(result.format)}   Data: ${result.code}')
                else
                  const Text('Scan a code'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                          onPressed: () async {
                            await controller?.toggleFlash();
                            setState(() {});
                          },
                          child: FutureBuilder(
                            future: controller?.getFlashStatus(),
                            builder: (context, snapshot) {
                              return Text('Flash: ${snapshot.data}');
                            },
                          )),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                          onPressed: () async {
                            await controller?.flipCamera();
                            setState(() {});
                          },
                          child: FutureBuilder(
                            future: controller?.getCameraInfo(),
                            builder: (context, snapshot) {
                              if (snapshot.data != null) {
                                return Text(
                                    'Camera facing ${describeEnum(snapshot.data)}');
                              } else {
                                return const Text('loading');
                              }
                            },
                          )),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () async {
                          await controller?.pauseCamera();
                        },
                        child:
                            const Text('pause', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () async {
                          await controller?.resumeCamera();
                        },
                        child: const Text('resume',
                            style: TextStyle(fontSize: 20)),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  String customerName = '';
  bool customerReusableProduct =
      ComSettings.appSettings('bool', 'key-customer-reusable-product', false)
          ? true
          : false;
  selectLedgerDetailWidget() {
    return FutureBuilder<CustomerModel>(
      future: customerReusableProduct
          ? dio.getCustomerDetailStock(ledgerModel.id)
          : dio.getCustomerDetail(ledgerModel.id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.id != null || snapshot.data.id > 0) {
            return Padding(
              padding: const EdgeInsets.all(35.0),
              child: snapshot.data.name == 'CASH'
                  ? Column(
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
                        InkWell(
                          child: Text("Name : " + snapshot.data.name,
                              style: const TextStyle(fontSize: 20)),
                          onTap: () {
                            setState(() {
                              nextWidget = 0;
                              nameLike = 'ca';
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Customer Name : ',
                            ),
                            onChanged: (value) {
                              setState(() {
                                customerName = value.isNotEmpty
                                    ? value.toUpperCase()
                                    : 'CASH';
                              });
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (salesTypeData.rateType.isNotEmpty) {
                                rateType = salesTypeData.id.toString();
                              }
                              ledgerModel = CustomerModel(
                                  id: snapshot.data.id,
                                  name: customerName,
                                  address1: snapshot.data.address1,
                                  address2: snapshot.data.address2,
                                  address3: snapshot.data.address3,
                                  address4: snapshot.data.address4,
                                  balance: snapshot.data.balance,
                                  city: snapshot.data.city,
                                  email: snapshot.data.email,
                                  phone: snapshot.data.phone,
                                  route: snapshot.data.route,
                                  state: snapshot.data.state,
                                  stateCode: snapshot.data.stateCode,
                                  taxNumber: snapshot.data.taxNumber);
                              nextWidget = 2;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              elevation: 0,
                              primary: kPrimaryColor,
                              onPrimary: white,
                              onSurface: grey),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const <Widget>[
                                Icon(
                                  Icons.shopping_bag,
                                  color: white,
                                ),
                                SizedBox(
                                  width: 4.0,
                                ),
                                Text(
                                  "Add Product To Cart",
                                  style: TextStyle(color: white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
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
                        InkWell(
                          child: Text("Name : " + snapshot.data.name,
                              style: const TextStyle(fontSize: 20)),
                          onTap: () {
                            setState(() {
                              nextWidget = 0;
                              nameLike = 'ca';
                            });
                          },
                        ),
                        Visibility(
                            visible: customerReusableProduct,
                            child: Text('Stock IN :' + snapshot.data.remarks)),
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
                              if (salesTypeData.type == 'SALES-BB') {
                                if (snapshot.data.taxNumber.isNotEmpty) {
                                  if (salesTypeData.rateType.isNotEmpty) {
                                    rateType = salesTypeData.id.toString();
                                  }
                                  ledgerModel = snapshot.data;
                                  nextWidget = 2;
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'B2B Invoice not allow without a TAX number')));
                                }
                              } else {
                                if (salesTypeData.rateType.isNotEmpty) {
                                  rateType = salesTypeData.id.toString();
                                }
                                ledgerModel = snapshot.data;
                                nextWidget = 2;
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              elevation: 0,
                              primary: kPrimaryDarkColor,
                              onPrimary: white,
                              onSurface: grey),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const <Widget>[
                                Icon(
                                  Icons.shopping_bag,
                                  color: white,
                                ),
                                SizedBox(
                                  width: 4.0,
                                ),
                                Text(
                                  "Add Product To Cart",
                                  style: TextStyle(color: white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PreviousBill(
                                        ledger: ledgerModel.id.toString(),
                                      )),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              elevation: 0,
                              primary: kPrimaryDarkColor,
                              onPrimary: white,
                              onSurface: grey),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const <Widget>[
                                Icon(
                                  Icons.view_list,
                                  color: white,
                                ),
                                SizedBox(
                                  width: 4.0,
                                ),
                                Text(
                                  "Previous Bill",
                                  style: TextStyle(color: white),
                                ),
                              ],
                            ),
                          ),
                        )
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

  OptionRateType rateTypeItem;

  widgetRateType() {
    return DropdownButton<OptionRateType>(
      hint: const Text('select rate type'),
      items: rateTypeList.map((item) {
        return DropdownMenuItem<OptionRateType>(
          value: item,
          child: Text(item.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          rateType = value.name;
          rateTypeItem = value;
        });
      },
      value: rateTypeItem,
    );
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
      useOLDBARCODE = false,
      isMinimumRatedLock = false;

  bool isItemData = false;
  selectProductWidget() {
    setState(() {
      if (items.isNotEmpty) isItemData = true;
    });
    return FutureBuilder<List<StockItem>>(
      future: dio.fetchStockProduct(DateUtil.dateDMY2YMD(formattedDate)),
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
                          decoration:
                              const InputDecoration(hintText: 'Search...'),
                          onChanged: (text) {
                            text = text.toLowerCase();
                            setState(() {
                              itemDisplay = items.where((item) {
                                var itemName = itemCodeVise
                                    ? item.code.toString().toLowerCase() +
                                        ' ' +
                                        item.name.toLowerCase()
                                    : item.name.toLowerCase();
                                return itemName.contains(text);
                              }).toList();
                            });
                          },
                        ),
                      )
                    : InkWell(
                        child: Card(
                          child: ListTile(
                            title: Text(
                                'Name : ${itemCodeVise ? itemDisplay[index - 1].code.toString() + ' ' + itemDisplay[index - 1].name : itemDisplay[index - 1].name}'),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Qty :${itemDisplay[index - 1].quantity}'),
                                // TextButton(
                                //     onPressed: () {
                                // if (singleProduct) {
                                //   addProduct(CartItem(
                                // id: totalItem + 1,
                                // itemId: product.itemId,
                                // itemName: product.name,
                                // quantity: 1,
                                // rate: rate,
                                // rRate: rRate,
                                // uniqueCode: uniqueCode,
                                // gross: gross,
                                // discount: discount,
                                // discountPercent: discountPercent,
                                // rDiscount: rDisc,
                                // fCess: kfc,
                                // serialNo: '',
                                // tax: tax,
                                // taxP: taxP,
                                // unitId: _dropDownUnit,
                                // unitValue: unitValue,
                                // pRate: pRate,
                                // rPRate: rPRate,
                                // barcode: barcode,
                                // expDate: expDate,
                                // free: free,
                                // fUnitId: fUnitId,
                                // cdPer: cdPer,
                                // cDisc: cDisc,
                                // net: subTotal,
                                // cess: cess,
                                // total: total,
                                // profitPer: profitPer,
                                // fUnitValue: fUnitValue,
                                // adCess: adCess,
                                // iGST: iGST,
                                // cGST: csGST,
                                // sGST: csGST));
                                // } else {
                                // Fluttertoast.showToast(
                                // msg: 'this is not Completed');
                                // }
                                // },
                                // child: const Card(
                                //     child: Text(' + ',
                                //         style: TextStyle(
                                //             fontSize: 25, color: blue))))
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            productModel = itemDisplay[index - 1];
                            nextWidget = 3;
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
                children: const [SizedBox(height: 20), Text('No Data Found..')],
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

  bool isBarcodePicker = false;
  itemDetailWidget() {
    return isBarcodePicker
        ? showBarcodeProduct()
        : productModel.hasVariant
            ? showVariantDialog(productModel.id, productModel.name,
                productModel.quantity.toString())
            : selectStockLedger();
  }

  showBarcodeProduct() {
    return FutureBuilder(
        future: dio.fetchStockProductByBarcode(barcodeValueText),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.length > 0) {
              return showAddMore(context, snapshot.data[0]);
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text('Barcode not found...'),
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

  selectStockLedger() {
    return FutureBuilder(
        future: dio.fetchStockVariant(productModel.id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.length > 0) {
              return showAddMore(context, snapshot.data[0]);
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text('Stock Ledger Data Missing...'),
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

  bool isVariantSelected = false;
  int positionID = 0;
  // List<StockProduct> _autoStockVariant = [];
  // double _stockVariantQuantity = 0;
  showVariantDialog(int id, String name, String quantity) {
    // _stockVariantQuantity = double.tryParse(quantity);
    return FutureBuilder<List<StockProduct>>(
      future: dio.fetchStockVariant(id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            // _autoStockVariant.clear();
            // _autoStockVariant = _autoVariantSelect ? snapshot.data : [];
            return isVariantSelected
                ? showAddMore(context, snapshot.data[positionID])
                : keyItemsVariantStock
                    ? SizedBox(
                        height: deviceSize.height - 20,
                        width: 400.0,
                        child: ListView(children: [
                          Center(child: Text(name + ' / ' + quantity)),
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: snapshot.data.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                elevation: 5,
                                child: ListTile(
                                    title: Text(
                                        'Id: ${snapshot.data[index].productId} / Quantity : ${snapshot.data[index].quantity} '),
                                    subtitle: Text(ComSettings.appSettings(
                                            'bool',
                                            'key-item-sale-retail',
                                            false)
                                        ? 'Mrp : ${snapshot.data[index].sellingPrice} / Retail : ${snapshot.data[index].retailPrice}'
                                        : 'Rate : ${snapshot.data[index].sellingPrice}'),
                                    onTap: () {
                                      setState(() {
                                        isVariantSelected = true;
                                        positionID = index;
                                      });
                                    }),
                              );
                            },
                          ),
                        ]),
                      )
                    : showAddMore(context, snapshot.data[0]);
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

  clearValue() {
    _quantityController.text = '';
    _rateController.text = '';
    _discountController.text = '';
    rateEdited = false;
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
    free = 0;
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
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _discountPercentController =
      TextEditingController();
  final TextEditingController _serialNoController = TextEditingController();
  final _resetKey = GlobalKey<FormState>();
  String expDate = '2000-01-01';
  int _dropDownUnit = 0, fUnitId = 0, uniqueCode = 0, barcode = 0;
  bool rateEdited = false;

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
      free = 0,
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

  showAddMore(BuildContext context, StockProduct product) {
    pRate = product.buyingPrice;
    rPRate = product.buyingPriceReal;
    isTax = taxable;
    taxP = isTax ? product.tax : 0;
    cess = isTax ? product.cess : 0;
    cessPer = isTax ? product.cessPer : 0;
    adCessPer = isTax ? product.adCessPer : 0;
    kfcP = isTax
        ? enableKeralaFloodCess
            ? kfcPer
            : 0
        : 0;
    if (rateTypeItem == null) {
      if (salesTypeData.rateType.toUpperCase() == 'RETAIL') {
        saleRate = product.retailPrice;
      } else if (salesTypeData.rateType.toUpperCase() == 'WHOLESALE') {
        saleRate = product.wholeSalePrice;
      } else {
        saleRate = product.sellingPrice;
      }
    } else {
      if (rateTypeItem.name.toUpperCase() == 'RETAIL') {
        saleRate = product.retailPrice;
      } else if (rateTypeItem.name.toUpperCase() == 'WHOLESALE') {
        saleRate = product.wholeSalePrice;
      } else {
        saleRate = product.sellingPrice;
      }
    }
    if (saleRate > 0 && !rateEdited && _rateController.text.isEmpty) {
      _rateController.text = _conversion > 0
          ? (saleRate * _conversion).toStringAsFixed(decimal)
          : saleRate.toStringAsFixed(decimal);
      rate = _conversion > 0 ? saleRate * _conversion : saleRate;
    }
    uniqueCode = product.productId;
    List<UnitModel> unitList = [];

    calculate() {
      if (enableMULTIUNIT) {
        if (saleRate > 0) {
          if (_conversion > 0) {
            //var r = 0.0;
            if (rateEdited) {
              rate = double.tryParse(_rateController.text);
              // rate = double.tryParse(_rateController.text) * _conversion;
            } else {
              //r = (saleRate * _conversion);
              rate = saleRate * _conversion;
              _rateController.text = rate.toStringAsFixed(decimal);
            }
            //rate = r;
            // _rateController.text = r.toStringAsFixed(decimal);
            pRate = product.buyingPrice * _conversion;
            rPRate = product.buyingPriceReal * _conversion;
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
        if (rateEdited) {
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
      double qt = _quantityController.text.isNotEmpty
          ? double.tryParse(_quantityController.text)
          : 0;
      double sRate = _rateController.text.isNotEmpty
          ? double.tryParse(_rateController.text)
          : 0;
      _discountController.text = _discountPercentController.text.isNotEmpty
          ? (((qt * sRate) * discP) / 100).toStringAsFixed(decimal)
          : '';
      discountPercent = _discountPercentController.text.isNotEmpty
          ? double.tryParse(_discountPercentController.text)
          : 0;
      discount = discountPercent > 0
          ? double.tryParse(_discountController.text)
          : discount;
      rDisc = taxMethod == 'MINUS'
          ? CommonService.getRound(4, ((discount * 100) / (taxP + 100)))
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
            ? CommonService.getRound(
                2, (total - (product.buyingPrice * _conversion * quantity)))
            : CommonService.getRound(decimal,
                (total - (product.buyingPriceReal * _conversion * quantity)));
      } else {
        profitPer = pRateBasedProfitInSales
            ? CommonService.getRound(
                2, (total - (product.buyingPrice * quantity)))
            : CommonService.getRound(
                2, (total - (product.buyingPriceReal * quantity)));
      }
      unitValue = _conversion > 0 ? _conversion : 1;
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          Text(product.name),
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
                        MaterialButton(
                          onPressed: () {
                            setState(() {
                              nextWidget = 2;
                              isVariantSelected = false;
                              clearValue();
                            });
                          },
                          child: const Text("BACK"),
                          color: blue[400],
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        MaterialButton(
                          onPressed: () {
                            setState(() {
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
                          child: const Text("ADD"),
                          color: blue,
                          onPressed: () {
                            setState(() {
                              isVariantSelected = false;
                              if (quantity > 0 || isFreeItem) {
                                if (outOfStock) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: const Text(
                                        'Sorry stock not available.'),
                                    duration: const Duration(seconds: 3),
                                    action: SnackBarAction(
                                      label: 'Click',
                                      onPressed: () {
                                        // print('Action is clicked');
                                      },
                                      textColor: Colors.white,
                                      disabledTextColor: Colors.grey,
                                    ),
                                    backgroundColor: Colors.red,
                                  ));
                                } else {
                                  if (isMinimumRatedLock) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content:
                                          const Text('Sorry rate is limited.'),
                                      duration: const Duration(seconds: 1),
                                      action: SnackBarAction(
                                        label: 'Click',
                                        onPressed: () {
                                          // print('Action is clicked');
                                        },
                                        textColor: Colors.white,
                                        disabledTextColor: Colors.grey,
                                      ),
                                      backgroundColor: Colors.red,
                                    ));
                                  } else {
                                    // if (_autoVariantSelect) {
                                    //   double qty = 0;
                                    //   for (StockProduct product
                                    //       in _autoStockVariant) {
                                    //     if (qty == quantity) {
                                    //       break;
                                    //     }
                                    //     qty += product.quantity;
                                    //     addProduct(CartItem(
                                    //         id: totalItem + 1,
                                    //         itemId: product.itemId,
                                    //         itemName: product.name,
                                    //         quantity: product.quantity,
                                    //         rate: rate,
                                    //         rRate: rRate,
                                    //         uniqueCode: product.productId,
                                    //         gross: gross,
                                    //         discount: discount,
                                    //         discountPercent: discountPercent,
                                    //         rDiscount: rDisc,
                                    //         fCess: kfc,
                                    //         serialNo: '',
                                    //         tax: tax,
                                    //         taxP: taxP,
                                    //         unitId: _dropDownUnit,
                                    //         unitValue: unitValue,
                                    //         pRate: pRate,
                                    //         rPRate: rPRate,
                                    //         barcode: barcode,
                                    //         expDate: expDate,
                                    //         free: free,
                                    //         fUnitId: fUnitId,
                                    //         cdPer: cdPer,
                                    //         cDisc: cDisc,
                                    //         net: subTotal,
                                    //         cess: cess,
                                    //         total: total,
                                    //         profitPer: profitPer,
                                    //         fUnitValue: fUnitValue,
                                    //         adCess: adCess,
                                    //         iGST: iGST,
                                    //         cGST: csGST,
                                    //         sGST: csGST,
                                    //         stock: product.quantity));
                                    //   }
                                    // } else {
                                    addProduct(CartItem(
                                        id: totalItem + 1,
                                        itemId: product.itemId,
                                        itemName: product.name,
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
                                        unitValue: unitValue,
                                        pRate: pRate,
                                        rPRate: rPRate,
                                        barcode: barcode,
                                        expDate: expDate,
                                        free: free,
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
                                        stock: product.quantity,
                                        minimumRate: product.minimumRate));
                                    // }
                                  }
                                }
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
                          // autofocus: true,
                          validator: (value) {
                            if (outOfStock) {
                              return 'No Stock';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                allow: true, replacementString: '.')
                          ],
                          decoration: const InputDecoration(
                              labelText: 'Quantity', hintText: '0.0'),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              bool cartQ = false;
                              setState(() {
                                if (totalItem > 0) {
                                  double cartS = 0, cartQt = 0;
                                  for (var element in cartItem) {
                                    if (element.itemId == product.itemId) {
                                      cartQt += element.quantity;
                                      cartS = element.stock;
                                    }
                                  }
                                  if (cartS > 0) {
                                    if (cartS <
                                        cartQt + double.tryParse(value)) {
                                      cartQ = true;
                                    }
                                  }
                                }

                                outOfStock = negativeStock
                                    ? false
                                    : salesTypeData.stock
                                        ? double.tryParse(value) >
                                                product.quantity
                                            ? true
                                            : cartQ
                                                ? true
                                                : false
                                        : false;
                                calculate();
                              });
                            }
                          },
                        ),
                      )),
                      Visibility(
                        visible: enableMULTIUNIT,
                        child: Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: FutureBuilder(
                              future: dio.fetchUnitOf(product.itemId),
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
                                            : 'SKU'),
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
                            readOnly: isItemRateEditLocked,
                            // autofocus: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                  allow: true, replacementString: '.')
                            ],
                            decoration: const InputDecoration(
                                labelText: 'Price', hintText: '0.0'),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                if (isMinimumRate) {
                                  double minRate = product.minimumRate ?? 0;
                                  if (double.tryParse(_rateController.text) >=
                                      minRate) {
                                    setState(() {
                                      rateEdited = true;
                                      isMinimumRatedLock = false;
                                      calculate();
                                    });
                                  } else {
                                    setState(() {
                                      isMinimumRatedLock = true;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    rateEdited = true;
                                    calculate();
                                  });
                                }
                              }
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
                                    rate: product.sellingPrice),
                                ProductRating(
                                    id: 1,
                                    name: 'Retail',
                                    rate: product.retailPrice),
                                ProductRating(
                                    id: 2,
                                    name: 'WsRate',
                                    rate: product.wholeSalePrice)
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
                                                  'PRate : ${product.buyingPrice} / RPRate : ${product.buyingPriceReal}',
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                ),
                                              ],
                                            )
                                          : const Text('Select Rate'),
                                      content: SizedBox(
                                        height: 200.0,
                                        width: 400.0,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: rateData.length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return Card(
                                              elevation: 5,
                                              child: ListTile(
                                                  title: Text(rateData[index]
                                                          .name +
                                                      ' : ${rateData[index].rate}'),
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
                            visible: productTracking,
                            child: InkWell(
                              child: Container(
                                color: blue,
                                child: const Text(
                                  'Sold',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: white),
                                ),
                              ),
                              onTap: () {
                                productTrackingList(product.itemId);
                              },
                            )),
                        Visibility(
                          visible: false, //taxMethod == 'MINUS',
                          child: Text(
                            '$rRate',
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      ]),
                  Visibility(
                    visible: !isItemDiscountEditLocked,
                    child: Row(
                      children: [
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: TextField(
                            controller: _discountPercentController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                  allow: true, replacementString: '.')
                            ],
                            decoration: const InputDecoration(
                                labelText: ' % ', hintText: '0.0'),
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
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                  allow: true, replacementString: '.')
                            ],
                            decoration: const InputDecoration(
                                labelText: 'Discount', hintText: '0.0'),
                            onChanged: (value) {
                              setState(() {
                                calculate();
                              });
                            },
                          ),
                        )),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: isItemSerialNo,
                    child: Row(
                      children: [
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: TextField(
                            controller: _serialNoController,
                            decoration:
                                const InputDecoration(labelText: 'SerialNo'),
                            onChanged: (value) {
                              setState(() {
                                calculate();
                              });
                            },
                          ),
                        )),
                      ],
                    ),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Visibility(
                      visible: isTax,
                      child: Expanded(
                          child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text('Tax % : $taxP'))),
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
                        total.toStringAsFixed(decimal),
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

  cartProduct() {
    setState(() {
      calculateTotal();
    });
    return loadReturnForm
        ? salesReturnForm()
        : Column(
            children: [
              salesHeaderWidget(),
              totalItem > 0
                  ? Expanded(
                      child: ListView.separated(
                        itemCount: cartItem.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const Divider(),
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: InkWell(
                              child: Text(cartItem[index].itemName),
                              onDoubleTap: () {
                                setState(() {
                                  removeProduct(cartItem[index]);
                                });
                              },
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: Card(
                                    color: Colors.green[200],
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.black,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        if (oldBill) {
                                          dio
                                              .getStockOf(
                                                  cartItem[index].itemId)
                                              .then((value) {
                                            cartItem[index].stock = value;
                                            setState(() {
                                              bool cartQ = false;
                                              if (totalItem > 0) {
                                                double cartS = 0, cartQt = 0;
                                                for (var element in cartItem) {
                                                  if (element.itemId ==
                                                      cartItem[index].itemId) {
                                                    cartQt += element.quantity;
                                                    cartS = element.stock;
                                                  }
                                                }
                                                cartS = oldBill ? value : cartS;
                                                if (cartS > 0) {
                                                  if (cartS < cartQt + 1) {
                                                    cartQ = true;
                                                  }
                                                }
                                              }
                                              outOfStock = negativeStock
                                                  ? false
                                                  : salesTypeData.stock
                                                      ? cartItem[index]
                                                                      .quantity +
                                                                  1 >
                                                              cartItem[index]
                                                                  .stock
                                                          ? true
                                                          : cartQ
                                                              ? true
                                                              : false
                                                      : false;
                                              if (outOfStock) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content: const Text(
                                                      'Sorry stock not available.'),
                                                  duration: const Duration(
                                                      seconds: 10),
                                                  action: SnackBarAction(
                                                    label: 'Click',
                                                    onPressed: () {
                                                      // print('Action is clicked');
                                                    },
                                                    textColor: Colors.white,
                                                    disabledTextColor:
                                                        Colors.grey,
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ));
                                              } else {
                                                updateProduct(
                                                    cartItem[index],
                                                    cartItem[index].quantity +
                                                        1);
                                              }
                                            });
                                          });
                                        } else {
                                          setState(() {
                                            bool cartQ = false;
                                            if (totalItem > 0) {
                                              double cartS = 0, cartQt = 0;
                                              for (var element in cartItem) {
                                                if (element.itemId ==
                                                    cartItem[index].itemId) {
                                                  cartQt += element.quantity;
                                                  cartS = element.stock;
                                                }
                                              }
                                              // cartS = oldBill?:cartS;
                                              if (cartS > 0) {
                                                if (cartS < cartQt + 1) {
                                                  cartQ = true;
                                                }
                                              }
                                            }
                                            outOfStock = negativeStock
                                                ? false
                                                : salesTypeData.stock
                                                    ? cartItem[index].quantity +
                                                                1 >
                                                            cartItem[index]
                                                                .stock
                                                        ? true
                                                        : cartQ
                                                            ? true
                                                            : false
                                                    : false;
                                            if (outOfStock) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: const Text(
                                                    'Sorry stock not available.'),
                                                duration:
                                                    const Duration(seconds: 10),
                                                action: SnackBarAction(
                                                  label: 'Click',
                                                  onPressed: () {
                                                    // print('Action is clicked');
                                                  },
                                                  textColor: Colors.white,
                                                  disabledTextColor:
                                                      Colors.grey,
                                                ),
                                                backgroundColor: Colors.red,
                                              ));
                                            } else {
                                              updateProduct(cartItem[index],
                                                  cartItem[index].quantity + 1);
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                InkWell(
                                  child: Text(
                                      cartItem[index].quantity.toString(),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                  onTap: () {
                                    if (oldBill) {
                                      dio
                                          .getStockOf(cartItem[index].itemId)
                                          .then((value) {
                                        cartItem[index].stock = value;
                                        _displayTextInputDialog(
                                            context,
                                            'Edit Quantity',
                                            cartItem[index].quantity > 0
                                                ? double.tryParse(
                                                        cartItem[index]
                                                            .quantity
                                                            .toString())
                                                    .toString()
                                                : '',
                                            cartItem[index].id);
                                      });
                                    } else {
                                      _displayTextInputDialog(
                                          context,
                                          'Edit Quantity',
                                          cartItem[index].quantity > 0
                                              ? double.tryParse(cartItem[index]
                                                      .quantity
                                                      .toString())
                                                  .toString()
                                              : '',
                                          cartItem[index].id);
                                    }
                                  },
                                ),
                                SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: Card(
                                    color: Colors.red[200],
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.remove,
                                        color: Colors.black,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          updateProduct(cartItem[index],
                                              cartItem[index].quantity - 1);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                    cartItem[index].unitId > 0
                                        ? '(' +
                                            UnitSettings.getUnitName(
                                                cartItem[index].unitId) +
                                            ')'
                                        : " x ",
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 12)),
                                InkWell(
                                  child: Text(
                                      cartItem[index]
                                          .rate
                                          .toStringAsFixed(decimal),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                  onTap: () {
                                    if (isItemRateEditLocked) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: const Text(
                                            'Sorry edit not available.'),
                                        duration: const Duration(seconds: 2),
                                        action: SnackBarAction(
                                          label: 'Click',
                                          onPressed: () {
                                            // print('Action is clicked');
                                          },
                                          textColor: Colors.white,
                                          disabledTextColor: Colors.grey,
                                        ),
                                        backgroundColor: Colors.red,
                                      ));
                                    } else {
                                      if (isMinimumRate) {
                                        if (oldBill) {
                                          dio
                                              .getMinimumRateOf(
                                                  cartItem[index].itemId)
                                              .then(((value) {
                                            cartItem[index].minimumRate = value;
                                            _displayTextInputDialog(
                                                context,
                                                'Edit Rate',
                                                cartItem[index].rate > 0
                                                    ? double.tryParse(
                                                            cartItem[index]
                                                                .rate
                                                                .toString())
                                                        .toString()
                                                    : '',
                                                cartItem[index].id);
                                          }));
                                        } else {
                                          _displayTextInputDialog(
                                              context,
                                              'Edit Rate',
                                              cartItem[index].rate > 0
                                                  ? double.tryParse(
                                                          cartItem[index]
                                                              .rate
                                                              .toString())
                                                      .toString()
                                                  : '',
                                              cartItem[index].id);
                                        }
                                      } else {
                                        _displayTextInputDialog(
                                            context,
                                            'Edit Rate',
                                            cartItem[index].rate > 0
                                                ? double.tryParse(
                                                        cartItem[index]
                                                            .rate
                                                            .toString())
                                                    .toString()
                                                : '',
                                            cartItem[index].id);
                                      }
                                    }
                                  },
                                ),
                                const Text(" = ",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold)),
                                InkWell(
                                  child: Text(
                                      ((cartItem[index].quantity *
                                                  cartItem[index].rate) -
                                              (cartItem[index].discount))
                                          .toStringAsFixed(decimal),
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20)),
                                  onDoubleTap: () {
                                    setState(() {
                                      removeProduct(cartItem[index]);
                                    });
                                  },
                                ),
                              ],
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

  productTrackingList(id) {
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
                child: productTrackingListData(id, ledId)),
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

  productTrackingListData(id, ledger) {
    return FutureBuilder(
        future: dio.getProductTracking(id, ledger),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.length > 0) {
              List<dynamic> data = snapshot.data;
              return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(data[index]['Supplier'].toString(),
                          style: const TextStyle(fontSize: 12)),
                      trailing: Text(data[index]['Date'].toString()),
                      subtitle: Text(
                          'Qty : ${data[index]['Qty']} Rate : ${data[index]['Rate']}\n Disc : ${data[index]['Disc']}   ${data[index]['DiscPersent']}%'),
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

    // return ListView.builder(
    //   itemCount: 150,
    //   itemBuilder: (BuildContext context, int index) {
    //     return ListTile(
    //       title: Text(index.toString()),
    //     );
    //   },
    // );
  }

  salesReturnForm() {
    int _id = oldBill
        ? returnBillId > 0
            ? returnBillId
            : 0
        : 0;
    var data = [
      {'ledger': ledgerModel, 'id': _id}
    ];
    return SalesReturn(
      fromSale: true,
      data: data,
    );
  }

  bool loadReturnForm = false;
  double returnAmount = 0;
  int returnBillId = 0;
  TextEditingController returnEntryNoController = TextEditingController();
  TextEditingController returnAmountController = TextEditingController();

  void addProduct(product) {
    int index = cartItem.indexWhere((i) => i.id == product.id);

    if (index != -1) {
      updateProduct(product, product.quantity + 1);
    } else {
      cartItem.add(product);
      calculateTotal();
    }
  }

  void removeProduct(product) {
    int index = cartItem.indexWhere((i) => i.id == product.id);
    cartItem[index].quantity = 1;
    cartItem.removeWhere((item) => item.id == product.id);
  }

  void updateProduct(product, qty) {
    int index = cartItem.indexWhere((i) => i.id == product.id);
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
        //     ? CommonService.getRound(decimal, ((cartItem[index].net * kfcPer) / 100))
        //     : 0;
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

  void editProduct(String title, String value, int id) {
    int index = cartItem.indexWhere((i) => i.id == id);
    if (title == 'Edit Rate') {
      bool lockRate = false;
      if (isMinimumRate) {
        lockRate = double.tryParse(value) >= cartItem[index].minimumRate
            ? false
            : true;
      }
      if (lockRate) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Sorry rate is limited.'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Click',
            onPressed: () {
              // print('Action is clicked');
            },
            textColor: Colors.white,
            disabledTextColor: Colors.grey,
          ),
          backgroundColor: Colors.red,
        ));
      } else {
        cartItem[index].rate = double.tryParse(value);
        cartItem[index].rRate = taxMethod == 'MINUS'
            ? isKFC
                ? CommonService.getRound(
                    4,
                    (100 * cartItem[index].rate) /
                        (100 + cartItem[index].taxP + kfcPer))
                : CommonService.getRound(4,
                    (100 * cartItem[index].rate) / (100 + cartItem[index].taxP))
            : cartItem[index].rate;
      }
    } else if (title == 'Edit Quantity') {
      bool cartQ = false;
      if (totalItem > 0) {
        double cartS = 0, cartQt = 0;
        double oldQty = cartItem[index].quantity;
        for (var element in cartItem) {
          if (element.itemId == cartItem[index].itemId) {
            cartQt += element.quantity;
            cartS = element.stock;
          }
        }
        if (cartS > 0) {
          if (cartS < cartQt - oldQty + double.tryParse(value)) {
            cartQ = true;
          }
        }
      }
      outOfStock = negativeStock
          ? false
          : salesTypeData.stock
              ? double.tryParse(value) > cartItem[index].stock
                  ? true
                  : cartQ
                      ? true
                      : false
              : false;
      if (outOfStock) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Sorry stock not available.'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Click',
            onPressed: () {
              // print('Action is clicked');
            },
            textColor: Colors.white,
            disabledTextColor: Colors.grey,
          ),
          backgroundColor: Colors.red,
        ));
      } else {
        cartItem[index].quantity = double.tryParse(value);
      }
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
                  color: Colors.red, fontWeight: FontWeight.bold)),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ledgerModel.address1),
            ],
          ),
        ),
        InkWell(
            child: const SizedBox(
              height: 26,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Text(
                      'Item +',
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
                Text("SubTotal : ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red[300])),
                Text(
                    CommonService.getRound(decimal, totalGrossValue)
                        .toStringAsFixed(decimal),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red[300])),
              ],
            ),
            Visibility(
              visible: isTax,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Tax : ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red[400])),
                  Text(
                      CommonService.getRound(decimal, taxTotalCartValue)
                          .toStringAsFixed(decimal),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red[400])),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total : ",
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controllerCashReceived,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Cash Received : ',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _balance = _controllerCashReceived.text.isNotEmpty
                            ? grandTotal > 0
                                ? grandTotal -
                                    double.tryParse(
                                        _controllerCashReceived.text)
                                : ((totalCartValue) -
                                    double.tryParse(
                                        _controllerCashReceived.text))
                            : grandTotal > 0
                                ? grandTotal
                                : totalCartValue;
                      });
                    },
                  ),
                ),
                const Text('Balance : '),
                Text(ComSettings.appSettings(
                        'bool', 'key-round-off-amount', false)
                    ? _balance.toStringAsFixed(decimal)
                    : _balance.roundToDouble().toString()),
              ],
            ),
            Card(
              elevation: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('More Details'),
                  Switch(
                      value: valueMore,
                      onChanged: (value) {
                        setState(() {
                          valueMore = value;
                        });
                      }),
                ],
              ),
            ),
            Visibility(
              visible: valueMore,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Narration...',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _narration = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: _isReturnInSales,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: returnEntryNoController,
                            decoration: const InputDecoration(
                              hintText: 'Bill No :',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                  allow: true)
                            ],
                            onChanged: (value) {
                              setState(() {
                                returnBillId = int.tryParse(value);
                              });
                            },
                          ),
                        ),
                        TextButton(
                            onPressed: () {
                              setState(() {
                                loadReturnForm = true;
                              });
                            },
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    kPrimaryDarkColor),
                                foregroundColor:
                                    MaterialStateProperty.all(white)),
                            child: const Text('Return Bill')),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: TextField(
                            controller: returnAmountController,
                            decoration: const InputDecoration(
                              hintText: 'Amount :',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                  allow: true, replacementString: '.')
                            ],
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  returnAmount = double.tryParse(value);
                                  grandTotal = grandTotal - returnAmount;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: deviceSize.height / 6,
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
                            return Container(
                                padding: const EdgeInsets.only(
                                    top: 0, right: 10, left: 10),
                                child: Row(children: <Widget>[
                                  expandStyle(
                                      2,
                                      Container(
                                          margin:
                                              const EdgeInsets.only(top: 35),
                                          child: Text(otherAmountList[index]
                                              ['LedName']))),
                                  expandStyle(
                                      1,
                                      TextFormField(
                                          controller: TextEditingController
                                              .fromValue(TextEditingValue(
                                                  text: otherAmountList[index]
                                                          ['Amount']
                                                      .toString(),
                                                  selection: TextSelection(
                                                      baseOffset: 0,
                                                      extentOffset:
                                                          otherAmountList[index]
                                                                  ['Amount']
                                                              .toString()
                                                              .length))),
                                          keyboardType: TextInputType.number,
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
                                                      decimal,
                                                      ((double.tryParse(str) *
                                                              100) /
                                                          cartTotal));
                                              var netTotal = (cartTotal -
                                                      returnAmount) +
                                                  otherAmountList.fold(
                                                      0,
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
                            ? CommonService.getRound(
                                    decimal, totalCartValue - returnAmount)
                                .toString()
                            : CommonService.getRound(
                                    decimal,
                                    (totalCartValue - returnAmount)
                                        .roundToDouble())
                                .toString(),
                    style: const TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.red))
              ],
            ),
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
    grandTotal = (totalCartValue - returnAmount) +
        otherAmountList.fold(
            0,
            (t, e) =>
                t +
                double.parse(e['Symbol'] == '-'
                    ? (e['Amount'] * -1).toString()
                    : e['Amount'].toString()));
  }

  expandStyle(int flex, Widget child) => Expanded(flex: flex, child: child);

  Future<void> _removeItemDialog(BuildContext context, int index) async {
    return showDialog(
      context: context,
      builder: (context) {
        return (StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Do you want to remove?'),
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
                    updateProduct(cartItem[index],
                        cartItem[index].quantity - cartItem[index].quantity);
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

  String get _time => DateFormat("H:m:s:S").format(DateTime.now()).toString();

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
              decoration: const InputDecoration(hintText: "value"),
              keyboardType: TextInputType.number,
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

  String barcodeValueText = '0';

  searchProductBarcode() {
    return showDialog(
      context: context,
      builder: (context) {
        return (StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Type Barcode'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  barcodeValueText = value;
                });
              },
              decoration: const InputDecoration(hintText: "barcode"),
              keyboardType: TextInputType.number,
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
                  Navigator.pop(context);
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
                    isBarcodePicker = true;
                    nextWidget = 3;
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
    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
          Navigator.pushReplacementNamed(context, '/sales',
              arguments: {'default': false});
        },
        onPressedYes: () {
          Navigator.of(context).pop();
          Navigator.pushReplacementNamed(context, '/preview_show',
              arguments: {'title': 'Sale'});
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage:
            'Do you want to Preview\nEntryNo : ${dataDynamic[0]['EntryNo']}',
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
          fetchSale(context, dataDynamic);
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage:
            'Do you want to edit or delete\nRefNo:${dataDynamic['Id']}',
        title: 'Update',
        context: context);
  }

  showDetails(context, data) {
    dataDynamic = [
      {
        'RealEntryNo': data['Id'],
        'EntryNo': data['Id'],
        'InvoiceNo': data['Id'],
        'Type': salesTypeData.id
      }
    ];
    Navigator.pushReplacementNamed(context, '/preview_show',
        arguments: {'title': 'Sale'});
  }

  fetchSale(context, data) {
    rateType = salesTypeData.id.toString();
    DioService api = DioService();
    double billTotal = 0, billCash = 0;
    String narration = ' ';

    api.fetchSalesInvoice(data['Id'], salesTypeData.id).then((value) {
      if (value != null) {
        var information = value['Information'][0];
        var particulars = value['Particulars'];
        // var serialNO = value['SerialNO'];
        // var deliveryNoteDetails = value['DeliveryNote'];
        otherAmountList = value['otherAmount'];

        formattedDate = DateUtil.dateDMY(information['DDate']);

        dataDynamic = [
          {
            'RealEntryNo': information['RealEntryNo'],
            'EntryNo': information['EntryNo'],
            'InvoiceNo': information['InvoiceNo'],
            'Type': salesTypeData.id
          }
        ];
        billCash = double.tryParse(information['CashReceived'].toString());
        billTotal = double.tryParse(information['GrandTotal'].toString());
        returnAmount = double.tryParse(information['ReturnAmount'].toString());
        returnBillId = information['ReturnNo'];
        narration = information['Narration'];
        CustomerModel cModel = CustomerModel(
            id: information['Customer'],
            name: information['ToName'],
            address1: information['Add1'],
            address2: information['Add2'],
            address3: information['Add3'],
            address4: information['Add4'],
            balance: information['Balance'].toString(),
            city: '',
            email: '',
            phone: '',
            route: '',
            state: '',
            stateCode: '',
            taxNumber: '');
        ledgerModel = cModel;
        ScopedModel.of<MainModel>(context).addCustomer(cModel);
        for (var product in particulars) {
          addProduct(CartItem(
              stock: 0,
              minimumRate: 0,
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
              taxP: 0,
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
              net:
                  double.tryParse(product['GrossValue'].toString()), //subTotal,
              cess: double.tryParse(product['cess'].toString()), //cess,
              total: double.tryParse(product['Total'].toString()), //total,
              profitPer: 0, //product['']profitPer,
              fUnitValue:
                  double.tryParse(product['FValue'].toString()), //fUnitValue,
              adCess: double.tryParse(product['adcess'].toString()), //adCess,
              iGST: double.tryParse(product['IGST'].toString()),
              cGST: double.tryParse(product['CGST'].toString()),
              sGST: double.tryParse(product['SGST'].toString())));
        }
      }

      setState(() {
        widgetID = false;
        grandTotal = billTotal - returnAmount;
        if (billCash > 0) {
          _controllerCashReceived.text = billCash.toString();
          _balance = _controllerCashReceived.text.isNotEmpty
              ? grandTotal > 0
                  ? grandTotal - double.tryParse(_controllerCashReceived.text)
                  : ((totalCartValue) -
                      double.tryParse(_controllerCashReceived.text))
              : grandTotal > 0
                  ? grandTotal
                  : totalCartValue;
        }
        if (returnAmount > 0) {
          returnAmountController.text = returnAmount.toString();
          returnEntryNoController.text = returnBillId.toString();
        }
        _narration = narration;
        nextWidget = 4;
        oldBill = true;
      });
      // Navigator.pushReplacementNamed(context, '/preview_show',
      // arguments: {'title': 'Sale'});
    });
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        loadScanner = false;
        var _id = result.code.isNotEmpty
            ? int.tryParse(result.code.replaceAll('http://', ''))
            : 0;
        ledgerModel = LedgerModel(id: _id, name: 'A');
        nextWidget = 1;
        isData = false;
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    // log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  static const platform = MethodChannel('sherAccChannel');

  Future<void> sendSms(number, msg) async {
    debugPrint("SendSMS");
    try {
      final String result = await platform.invokeMethod(
          'sendSMS', <String, dynamic>{"phone": number, "msg": msg});
      debugPrint(result);
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
  }
}

class ProductRating {
  int id;
  String name;
  double rate;
  ProductRating({this.id, this.name, this.rate});
}
