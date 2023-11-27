// @dart = 2.9
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
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
import 'package:sheraccerp/service/generate_e_invoice.dart';
import 'package:sheraccerp/service/generate_e_way_bill.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/color_palette.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/dbhelper.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class Sale extends StatefulWidget {
  const Sale({Key key}) : super(key: key);

  @override
  _SaleState createState() => _SaleState();
}

class _SaleState extends State<Sale> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<SalesType> salesTypeDisplay = [];
  dynamic salesData;
  bool _defaultSale = false,
      thisSale = false,
      _isLoading = false,
      isCustomForm = false,
      buttonEvent = false,
      isSerialNoInStockVariant = false;
  // final bool _autoVariantSelect = true;
  DioService api = DioService();
  Size deviceSize;
  var ledgerModel, vehicleData;
  String vehicleName = '';
  StockItem productModel;
  List<CartItem> cartItem = [];
  List<dynamic> otherAmountList = [];
  bool isTax = true,
      blockTaxLedgerOnB2CorBOS = false,
      otherAmountLoaded = false,
      salesmanAsVehicle = false,
      valueMore = false,
      lastRecord = false,
      widgetID = true,
      previewData = false,
      oldBill = false,
      itemCodeVise = false,
      itemStockAll = false,
      isItemRateEditLocked = false,
      isMinimumRate = false,
      isItemDiscountEditLocked = false,
      isItemSerialNo = false,
      keyItemsVariantStock = false,
      enableBarcode = false,
      _isReturnInSales = false,
      productTracking = false,
      isFreeItem = false,
      isStockProductOnlyInSalesQO = false,
      isLockQtyOnlyInSales = false,
      isSalesManWiseLedger = false,
      isEnableProfitlessSalesWarning = false,
      isFreeQty = false,
      gstVerified = false,
      gstValidation = false;
  final List<TextEditingController> _controllers = [];
  DateTime now = DateTime.now();
  String formattedDate;
  double _balance = 0, grandTotal = 0;
  final TextEditingController controllerCashReceived = TextEditingController();
  final TextEditingController controllerNarration = TextEditingController();
  final FocusNode _focusNodeCashReceived = FocusNode();

  int page = 1, pageTotal = 0, totalRecords = 0;
  int saleAccount = 0, acId = 0, decimal = 2;
  List<dynamic> ledgerDisplay = [];
  List<dynamic> _ledger = [];
  List<dynamic> itemDisplay = [];
  List<dynamic> items = [];
  List<LedgerModel> cashBankACList = [];
  int lId = 0, groupId = 0, areaId = 0, routeId = 0;
  var salesManId = 0;
  String labelSerialNo = 'SerialNo';
  String labelSpRate = 'SpRetail';
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

    ledgerScanner = ComSettings.appSettings('bool', 'key-customer-scan', false);
    itemCodeVise = ComSettings.appSettings('bool', 'key-item-by-code', false);
    itemStockAll = ComSettings.appSettings('bool', 'key-item-stock-all', false);
    keyItemsVariantStock =
        ComSettings.appSettings('bool', 'key-items-variant-stock', false);

    if (optionRateTypeList.isEmpty) {
      api.getRateTypeList().then((value) {
        setState(() {
          rateTypeList = value;

          String rateTypeS = salesTypeData != null
              ? salesTypeData.rateType.isNotEmpty
                  ? salesTypeData.rateType
                  : 'MRP'
              : 'MRP';

          rateTypeItem =
              rateTypeList.firstWhere((element) => element.name == rateTypeS);
        });
      });
    } else {
      rateTypeList = optionRateTypeList;

      String rateTypeS = salesTypeData != null
          ? salesTypeData.rateType.isNotEmpty
              ? salesTypeData.rateType
              : 'MRP'
          : 'MRP';

      rateTypeItem = rateTypeList.firstWhere((element) =>
          element.name.toString().toUpperCase() == rateTypeS.toUpperCase());
    }

    api.getLedgerListByType('SelectbankOnly').then((value) {
      List<LedgerModel> _dataTemp = [];
      for (var ledger in value) {
        _dataTemp
            .add(LedgerModel(id: ledger['ledcode'], name: ledger['LedName']));
      }
      setState(() {
        cashBankACList.addAll(_dataTemp);
      });
    });
  }

  CompanyInformation companySettings;
  List<CompanySettings> settings;
  List rateTypeList = [];

  loadSettings() {
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();

    String cashAc =
        ComSettings.getValue('CASH A/C', settings).toString().trim() ?? 'CASH';
    try {
      acId = mainAccount
          .firstWhere((element) => element['LedName'] == cashAc)['LedCode'];
      acId = ComSettings.appSettings('int', 'key-dropdown-default-cash-ac', 0) -
                  1 >
              acId
          ? ComSettings.appSettings(
                  'int', 'key-dropdown-default-cash-ac', acId) -
              1
          : acId;
    } catch (e) {
      e.toString();
      acId = -1;
    }
    taxMethod = companySettings.taxCalculation;
    enableMULTIUNIT = ComSettings.getStatus('ENABLE MULTI-UNIT', settings);
    pRateBasedProfitInSales =
        ComSettings.getStatus('PRATE BASED PROFIT IN SALES', settings);
    negativeStock = ComSettings.getStatus('ALLOW NEGETIVE STOCK', settings);
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    cessOnNetAmount = ComSettings.getStatus('CESS ON NET AMOUNT', settings);
    blockTaxLedgerOnB2CorBOS =
        ComSettings.getStatus('BLOCK B2C BOS SALES TO GST CUSTOMERS', settings);
    enableKeralaFloodCess = false;
    enableBarcode = ComSettings.getStatus('ENABLE BARCODE OPTION', settings);
    isEnableProfitlessSalesWarning =
        ComSettings.getStatus('ENABLE PROFITLESS SALES WARNING', settings);
    useUniqueCodeAsBarcode =
        ComSettings.getStatus('USE UNIQUECODE AS BARCODE', settings);
    useOldBarcode = ComSettings.getStatus('USE OLD BARCODE', settings);
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;
    isItemSerialNo = ComSettings.getStatus('KEY ITEM SERIAL NO', settings);
    labelSerialNo =
        ComSettings.getValue('KEY ITEM SERIAL NO', settings).toString();
    labelSpRate =
        ComSettings.getValue('KEY ITEM SP RATE TITLE', settings).toString();
    labelSerialNo = labelSerialNo.isEmpty ? 'Remark' : labelSerialNo;
    labelSpRate = labelSpRate.isEmpty ? 'SpRetail' : labelSpRate;
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
    isFreeQty = ComSettings.getStatus('KEY FREE QTY IN SALE', settings);
    isStockProductOnlyInSalesQO =
        ComSettings.getStatus('KEY STOCK PRODUCT ONLY IN SALES QO', settings);
    isLockQtyOnlyInSales =
        ComSettings.getStatus('KEY LOCK QTY ONLY IN SALES', settings);
    isSalesManWiseLedger =
        ComSettings.getStatus('KEY SALESMAN WISE LEDGER', settings);
    isSerialNoInStockVariant =
        ComSettings.getStatus('SHOW SERIALNO IN STOCK WINDOW', settings);
    salesmanAsVehicle =
        ComSettings.getStatus('USE SALESMAN AS VEHICLE', settings);
  }

  @override
  Widget build(BuildContext context) {
    _discountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _discountController.text.length));
    _discountPercentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _discountPercentController.text.length));
    _quantityController.selection = TextSelection.fromPosition(
        TextPosition(offset: _quantityController.text.length));
    _rateController.selection = TextSelection.fromPosition(
        TextPosition(offset: _rateController.text.length));
    controllerCashReceived.selection = TextSelection.fromPosition(
        TextPosition(offset: controllerCashReceived.text.length));
    _freeQuantityController.selection = TextSelection.fromPosition(
        TextPosition(offset: _freeQuantityController.text.length));

    deviceSize = MediaQuery.of(context).size;
    final routes =
        ModalRoute.of(context).settings.arguments as Map<String, bool>;
    thisSale = routes['default'];
    taxable = salesTypeData != null ? salesTypeData.tax : taxable;

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
                              'Delete DateTime:$formattedDate $timeIs location:${lId.toString()} ledger:${ledgerModel.id} ' +
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
                                'Edit DateTime:$formattedDate $timeIs location:${lId.toString()} ledger:${ledgerModel.id} ' +
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
                                'SAVE DateTime:$formattedDate $timeIs location:${lId.toString()} ledger:${ledgerModel.id} ' +
                                    CartItem.encodeCartToJson(cartItem)
                                        .toString(),
                                0);
                            saveSale();
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Please add at least one item');
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

        api
            .getPaginationList(
                statement,
                page,
                locationId.toString(),
                salesTypeData.id.toString(),
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

          if (mounted) {
            setState(() {
              isLoadingData = false;
              dataDisplay.addAll(tempList);
              lastRecord = tempList.isNotEmpty ? false : true;
            });
          }
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
    /***Test Data***/
    // row to insert
    Map<String, dynamic> row = {
      DatabaseHelper.columnName: name,
      DatabaseHelper.columnstatus: status
    };
    Carts car = Carts.fromMap(row);
    final id = await dbHelper.insert(car);
  }

  saveSale() async {
    List<CustomerModel> ledger = [];
    ledger.add(CustomerModel(
        address1: ledgerModel.address1 + " " + ledgerModel.address2,
        address2: ledgerModel.address3 + " " + ledgerModel.address4,
        address3: '',
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
        cashReceived: controllerCashReceived.text.isNotEmpty
            ? controllerCashReceived.text
            : '0',
        otherDiscount: '0',
        loadingCharge: '0',
        otherCharges: '0',
        labourCharge: '0',
        discountPer: '0',
        balanceAmount: _balance > 0
            ? _balance.toStringAsFixed(decimal)
            : controllerCashReceived.text.isNotEmpty
                ? grandTotal > 0
                    ? ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? (grandTotal -
                                double.tryParse(controllerCashReceived.text))
                            .toStringAsFixed(decimal)
                        : (grandTotal -
                                double.tryParse(controllerCashReceived.text))
                            .roundToDouble()
                            .toString()
                    : ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? ((totalCartValue) -
                                double.tryParse(controllerCashReceived.text))
                            .toStringAsFixed(decimal)
                        : ((totalCartValue) -
                                double.tryParse(controllerCashReceived.text))
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
        narration:
            controllerNarration.text.isNotEmpty ? controllerNarration.text : '',
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
      var taxType = salesTypeData.tax ? 'T' : 'NT';
      var salesRateTypeId =
          rateTypeItem != null ? rateTypeItem.id.toString() : '1';
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
            'invoiceNo': '0',
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
            'returnAmount': returnAmount,
            'otherAmount': _otherAmountTotal(order.otherAmountData),
            'fyId': currentFinancialYear.id,
            'commissionAccount': commissionAccount ?? 0,
            'commissionAmount': commissionAmountController.text.isEmpty
                ? 0
                : commissionAmountController.text,
            'bankName': bankLedgerName ?? 0,
            'bankAmount': bankAmountController.text.isEmpty
                ? 0
                : bankAmountController.text
          }) +
          ']';

      final body = {'information': ledger, 'data': data, 'particular': items};

      api.addSale(body).then((result) {
        if (CommonService().isNumeric(result) && int.tryParse(result) > 0) {
          final bodyJsonAmount = {
            'statement': 'SalesInsert',
            'entryNo': int.tryParse(result.toString()),
            'data': otherAmount,
            'date': order.dated.toString(),
            'saleFormType': saleFormType,
            'narration': order.narration,
            'location': order.location.toString(),
            'id': order.customerModel[0].id.toString(),
            'fyId': currentFinancialYear.id
          };
          if (salesTypeData.accounts) {
            api.addOtherAmount(bodyJsonAmount).then((ret) {
              if (ret) {
                final bodyJson = {
                  'statement': 'CheckPrint',
                  'entryNo': int.tryParse(result.toString()),
                  'sType': saleFormId.toString(),
                  'grandTotal': ComSettings.appSettings(
                          'bool', 'key-round-off-amount', false)
                      ? grandTotal.toStringAsFixed(decimal)
                      : grandTotal.roundToDouble().toString()
                };
                api.checkBill(bodyJson).then((data) {
                  if (data) {
                    dataDynamic = [
                      {
                        'RealEntryNo': int.tryParse(result.toString()),
                        'EntryNo': int.tryParse(result.toString()),
                        'InvoiceNo': int.tryParse(result.toString()),
                        'Type': saleFormId
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
                          "Dear ${ledgerModel.name},\nYour Sales $billName ${result.toString()}, Dated : $formattedDate for the Amount of ${order.grandTotal}/- \nBalance:$amt /- has been confirmed  \n${companySettings.name}";
                      if (ledgerModel.phone.toString().isNotEmpty) {
                        sendSms(ledgerModel.phone, smsBody);
                      }
                    }
                    if (ComSettings.getStatus('ENABLE SMS OPTION', settings)) {
                      //
                    }
                    clearCart();
                    showMore(context, true);
                  }
                });
              }
            });
          } else {
            final bodyJson = {
              'statement': 'CheckPrint',
              'entryNo': int.tryParse(result.toString()),
              'sType': saleFormId.toString(),
              'grandTotal':
                  ComSettings.appSettings('bool', 'key-round-off-amount', false)
                      ? grandTotal.toStringAsFixed(decimal)
                      : grandTotal.roundToDouble().toString()
            };
            api.checkBill(bodyJson).then((data) {
              if (data) {
                dataDynamic = [
                  {
                    'RealEntryNo': int.tryParse(result.toString()),
                    'EntryNo': int.tryParse(result.toString()),
                    'InvoiceNo': int.tryParse(result.toString()),
                    'Type': saleFormId
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
                      "Dear ${ledgerModel.name},\nYour Sales $billName ${result.toString()}, Dated : $formattedDate for the Amount of ${order.grandTotal}/- \nBalance:$amt /- has been confirmed  \n${companySettings.name}";
                  if (ledgerModel.phone.toString().isNotEmpty) {
                    sendSms(ledgerModel.phone, smsBody);
                  }
                }
                if (ComSettings.getStatus('ENABLE SMS OPTION', settings)) {
                  //
                }
                clearCart();
                showMore(context, true);
              }
            });
          }
          setState(() {
            _isLoading = false;
          });
        } else {
          showErrorDialog(context, result.toString());
        }
      }).catchError((e) {
        showErrorDialog(context, e.toString());
      });
    }
  }

  updateSale() {
    List<CustomerModel> ledger = [];
    ledger.add(CustomerModel(
        address1: ledgerModel.address1,
        address2: ledgerModel.address2,
        address3: ledgerModel.address3,
        address4: ledgerModel.address4,
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
        cashReceived: controllerCashReceived.text.isNotEmpty
            ? controllerCashReceived.text
            : '0',
        otherDiscount: '0',
        loadingCharge: '0',
        otherCharges: '0',
        labourCharge: '0',
        discountPer: '0',
        balanceAmount: _balance > 0
            ? _balance.toStringAsFixed(decimal)
            : controllerCashReceived.text.isNotEmpty
                ? grandTotal > 0
                    ? ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? (grandTotal -
                                double.tryParse(controllerCashReceived.text))
                            .toStringAsFixed(decimal)
                        : (grandTotal -
                                double.tryParse(controllerCashReceived.text))
                            .roundToDouble()
                            .toString()
                    : ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? ((totalCartValue) -
                                double.tryParse(controllerCashReceived.text))
                            .toStringAsFixed(decimal)
                        : ((totalCartValue) -
                                double.tryParse(controllerCashReceived.text))
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
        narration:
            controllerNarration.text.isNotEmpty ? controllerNarration.text : '',
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
      var taxType = salesTypeData.tax ? 'T' : 'NT';
      var salesRateTypeId =
          rateTypeItem != null ? rateTypeItem.id.toString() : '1';
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
            'invoiceNo': dataDynamic[0]['InvoiceNo'].toString(),
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
            'returnAmount': returnAmount,
            'otherAmount': _otherAmountTotal(order.otherAmountData),
            'fyId': currentFinancialYear.id,
            'commissionAccount': commissionAccount ?? 0,
            'commissionAmount': commissionAmountController.text.isEmpty
                ? 0
                : commissionAmountController.text,
            'bankName': bankLedgerName ?? 0,
            'bankAmount': bankAmountController.text.isEmpty
                ? 0
                : bankAmountController.text
          }) +
          ']';

      final body = {'information': ledger, 'data': data, 'particular': items};
      api.editSale(body).then((result) {
        if (CommonService().isNumeric(result) && int.tryParse(result) > 0) {
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
          if (salesTypeData.accounts) {
            api.addOtherAmount(bodyJsonAmount).then((retNotUsed) {
              final bodyJson = {
                'statement': 'CheckPrint',
                'entryNo': dataDynamic[0]['EntryNo'].toString(),
                'sType': dataDynamic[0]['Type'].toString(),
                'grandTotal': ComSettings.appSettings(
                        'bool', 'key-round-off-amount', false)
                    ? grandTotal.toStringAsFixed(decimal)
                    : grandTotal.roundToDouble().toString()
              };
              api.checkBill(bodyJson).then((data) {
                if (data) {
                  clearCart();
                  showMore(context, false);
                }
              });
            });
          } else {
            final bodyJson = {
              'statement': 'CheckPrint',
              'entryNo': dataDynamic[0]['EntryNo'].toString(),
              'sType': dataDynamic[0]['Type'].toString(),
              'grandTotal':
                  ComSettings.appSettings('bool', 'key-round-off-amount', false)
                      ? grandTotal.toStringAsFixed(decimal)
                      : grandTotal.roundToDouble().toString()
            };
            api.checkBill(bodyJson).then((data) {
              if (data) {
                clearCart();
                showMore(context, false);
              }
            });
          }
          setState(() {
            _isLoading = false;
          });
        } else {
          showErrorDialog(context, result.toString());
        }
      }).catchError((e) {
        showErrorDialog(context, e.toString());
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
    api
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
                      Navigator.pushReplacementNamed(
                          context,
                          ComSettings.appSettings(
                                  'bool', 'key-simple-sales', false)
                              ? '/SimpleSale'
                              : '/sales',
                          arguments: {'default': thisSale});
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
          taxable = salesTypeData != null ? salesTypeData.tax : taxable;
          rateTypeItem = rateTypeList.isEmpty
              ? null
              : rateTypeList.firstWhere((element) =>
                  element.name == salesTypeData.rateType.toUpperCase());
        });
      },
    );
  }

  var nameLike = "a";
  selectLedgerWidget() {
    return FutureBuilder<List<dynamic>>(
      future: isSalesManWiseLedger
          ? api.getLedgerBySalesManLike(salesManId, nameLike)
          : api.getCustomerNameListLike(
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
                                  border: OutlineInputBorder(),
                                  label: Text('Search...'),
                                ),
                                onChanged: (text) {
                                  text = text.toLowerCase();
                                  setState(() {
                                    // ledgerDisplay = _ledger.where((item) {
                                    //   var itemName = item.name.toLowerCase();
                                    // return itemName.contains(text);
                                    // }).toList();
                                    nameLike = text.isNotEmpty ? text : 'a';
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
                children: [
                  const SizedBox(height: 20),
                  const Text('No Data Found..'),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          nameLike = nameLike.substring(0, nameLike.length - 1);
                          // nextWidget = nextWidget;
                        });
                      },
                      child: const Text('Select Again'))
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
          api.getCustomerNameListByParent(groupId, areaId, routeId, salesManId),
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
                                  border: OutlineInputBorder(),
                                  label: Text('Search...'),
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
                children: [
                  const SizedBox(height: 20),
                  const Text('No Data Found..'),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          nextWidget = nextWidget;
                        });
                      },
                      child: const Text('Select Again'))
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
          ? api.getCustomerDetailStock(ledgerModel.id)
          : api.getCustomerDetail(ledgerModel.id),
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
                        const Text(
                          'NAME ',
                          style: TextStyle(color: blue),
                        ),
                        InkWell(
                          child: Text(snapshot.data.name,
                              style: const TextStyle(fontSize: 20)),
                          onTap: () {
                            setState(() {
                              nextWidget = 0;
                              nameLike = 'a';
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              label: Text('Customer Name : '),
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
                        salesManVehicle(),
                        ElevatedButton(
                          onPressed: () {
                            customerName = customerName.isEmpty
                                ? snapshot.data.name == 'CASH'
                                    ? 'CASH'
                                    : customerName
                                : customerName;
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
                              foregroundColor: white,
                              backgroundColor: kPrimaryColor,
                              elevation: 0,
                              disabledForegroundColor: grey.withOpacity(0.38),
                              disabledBackgroundColor: grey.withOpacity(0.12)),
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
                        const Text(
                          'Name',
                          style: TextStyle(
                              color: blue, fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          child: Text(snapshot.data.name,
                              style: const TextStyle(fontSize: 20)),
                          onTap: () {
                            setState(() {
                              nextWidget = 0;
                              nameLike = 'a';
                            });
                          },
                        ),
                        salesManVehicle(),
                        Visibility(
                            visible: customerReusableProduct,
                            child: Text('Stock IN :' + snapshot.data.remarks)),
                        const Text(
                          'Address',
                          style: TextStyle(
                              color: blue, fontWeight: FontWeight.bold),
                        ),
                        Text(
                            snapshot.data.address1 +
                                " ," +
                                snapshot.data.address2 +
                                " ," +
                                snapshot.data.address3 +
                                " ," +
                                snapshot.data.address4,
                            style: const TextStyle(fontSize: 18)),
                        snapshot.data.taxNumber.isNotEmpty
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tax No',
                                    style: TextStyle(
                                        color: blue,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(snapshot.data.taxNumber,
                                      style: const TextStyle(fontSize: 18)),
                                  gstValidation
                                      ? const Loading()
                                      : OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              gstValidation = true;
                                              gstVerified = true;
                                              //check
                                              gstValidation = false;
                                              gstVerified = true;
                                            });
                                          },
                                          label: const Text(
                                            'validate',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 10),
                                          ),
                                          icon: Icon(Icons.verified_rounded,
                                              color: gstVerified
                                                  ? Colors.green
                                                  : Colors.red),
                                        )
                                ],
                              )
                            : Text(
                                'Tax No ${snapshot.data.taxNumber}',
                                style: const TextStyle(
                                    color: blue, fontWeight: FontWeight.bold),
                              ),
                        const Text(
                          'Phone',
                          style: TextStyle(
                              color: blue, fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          child: Text(snapshot.data.phone,
                              style: const TextStyle(fontSize: 18)),
                          onDoubleTap: () => callNumber(snapshot.data.phone),
                        ),
                        const Text(
                          'Email',
                          style: TextStyle(
                              color: blue, fontWeight: FontWeight.bold),
                        ),
                        Text(snapshot.data.email,
                            style: const TextStyle(fontSize: 18)),
                        const Text(
                          'Balance',
                          style: TextStyle(
                              color: blue, fontWeight: FontWeight.bold),
                        ),
                        Text(snapshot.data.balance,
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
                                } else if (!blockTaxLedgerOnB2CorBOS) {
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
                                if (blockTaxLedgerOnB2CorBOS) {
                                  if ((salesTypeData.type == 'SALES-BC' ||
                                          salesTypeData.type == 'SALES-BOS') &&
                                      snapshot.data.taxNumber.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Tax Registered Ledger')));
                                    return;
                                  }
                                }
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
                              backgroundColor: kPrimaryDarkColor,
                              foregroundColor: white,
                              disabledBackgroundColor: grey),
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
                              backgroundColor: kPrimaryDarkColor,
                              foregroundColor: white,
                              disabledBackgroundColor: grey),
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

  callNumber(number) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(number);
    } catch (_e) {
      debugPrint(_e);
    }
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
      useUniqueCodeAsBarcode = false,
      useOldBarcode = false,
      isMinimumRatedLock = false;

  bool isItemData = false;
  String itemLike = 'a';
  selectProductWidget() {
    if (salesmanAsVehicle) {
      double squareFeet =
          vehicleData != null ? vehicleData['Salary'].toDouble() : 0;
      if (squareFeet > 0) {
        _quantityController.text = squareFeet.toString();
      }
    }
    if (!itemStockAll) {
      return FutureBuilder<List<StockItem>>(
        future:
            (salesTypeData.type == 'SALES-O' || salesTypeData.type == 'SALES-Q')
                ? isStockProductOnlyInSalesQO
                    ? api.fetchStockProductLike(
                        DateUtil.dateDMY2YMD(formattedDate), itemLike)
                    : api.fetchNoStockProductLike(
                        DateUtil.dateDMY2YMD(formattedDate), itemLike)
                : api.fetchStockProductLike(
                    DateUtil.dateDMY2YMD(formattedDate), itemLike),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.isNotEmpty) {
              var data = snapshot.data;
              // if (!isItemData) {
              itemDisplay = data;
              items = data;
              // }
              return ListView.builder(
                // shrinkWrap: true,
                itemBuilder: (context, index) {
                  return index == 0
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                label: Text('Search...')),
                            onChanged: (text) {
                              text = text.toLowerCase();
                              setState(() {
                                itemLike = text.toLowerCase();

                                //   itemDisplay = items.where((item) {
                                //     // var itemName = itemCodeVise
                                //     //     ? item.code.toString().toLowerCase() +
                                //     //         ' ' +
                                //     //         item.name.toLowerCase()
                                //     //     : item.name.toLowerCase();
                                //     // return itemName.contains(text);
                                //   }).toList();
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      'Qty :${itemDisplay[index - 1].quantity}'),
                                  // TextButton(
                                  //     onPressed: () {
                                  // if (singleProduct) {
                                  //   addProduct(CartItem(
                                  // id: totalAdd Item 1,
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
                  children: [
                    const SizedBox(height: 20),
                    const Text('No Data Found..'),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            itemLike =
                                itemLike.substring(0, itemLike.length - 1);
                            nextWidget = 2;
                          });
                        },
                        child: const Text('Select Again'))
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
    } else {
      setState(() {
        if (items.isNotEmpty) isItemData = true;
      });

      return FutureBuilder<List<StockItem>>(
        future: (salesTypeData.type == 'SALES-O' ||
                salesTypeData.type == 'SALES-Q')
            ? isStockProductOnlyInSalesQO
                ? api.fetchStockProduct(DateUtil.dateDMY2YMD(formattedDate))
                : api.fetchNoStockProduct(DateUtil.dateDMY2YMD(formattedDate))
            : api.fetchStockProduct(DateUtil.dateDMY2YMD(formattedDate)),
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
                                label: Text('Search...')),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      'Qty :${itemDisplay[index - 1].quantity}'),
                                  // TextButton(
                                  //     onPressed: () {
                                  // if (singleProduct) {
                                  //   addProduct(CartItem(
                                  // id: totalAdd Item 1,
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
                  children: [
                    const SizedBox(height: 20),
                    const Text('No Data Found..'),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            itemLike =
                                itemLike.substring(0, itemLike.length - 1);
                            nextWidget = 2;
                          });
                        },
                        child: const Text('Select Again'))
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
  }

  bool isBarcodePicker = false;
  itemDetailWidget() {
    return isBarcodePicker
        ? showBarcodeProduct()
        : (salesTypeData.type == 'SALES-O' || salesTypeData.type == 'SALES-Q')
            ? selectNoStockLedger()
            : productModel.hasVariant
                ? showVariantDialog(productModel.id, productModel.name,
                    productModel.quantity.toString())
                : selectStockLedger();
  }

  showBarcodeProduct() {
    return FutureBuilder(
        future: api.fetchStockProductByBarcode(barcodeValueText),
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
        future: api.fetchStockVariant(productModel.id),
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

  selectNoStockLedger() {
    return FutureBuilder(
        future: api.fetchNoStockVariant(productModel.code),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.length > 0) {
              var d = snapshot.data[0];
              StockProduct data = StockProduct(
                  adCessPer: d['adcessper'].toDouble(),
                  branch: d['Branch'].toDouble(),
                  buyingPrice: d['prate'].toDouble(),
                  buyingPriceReal: d['RealPrate'].toDouble(),
                  cess: d['cess'].toDouble(),
                  cessPer: d['cessper'].toDouble(),
                  hsnCode: d['hsncode'],
                  itemId: d['ItemId'],
                  minimumRate: d['minimumRate'].toDouble(),
                  name: d['itemname'],
                  productId: d['uniquecode'],
                  quantity: (salesTypeData.type == 'SALES-O' ||
                          salesTypeData.type == 'SALES-Q')
                      ? productModel.quantity
                      : d['Qty'].toDouble(),
                  retailPrice: d['retail'].toDouble(),
                  sellingPrice: d['mrp'].toDouble(),
                  spRetailPrice: d['Spretail'].toDouble(),
                  stockValuation: d['stockvaluation'],
                  tax: d['tax'].toDouble(),
                  wholeSalePrice: d['WSrate'].toDouble());
              return showAddMore(context, data);
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
      future: api.fetchStockVariant(id),
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
                          SizedBox(
                            height: deviceSize.height - 100,
                            width: 400.0,
                            child: ListView.builder(
                              // shrinkWrap: true,
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
                                      trailing: isSerialNoInStockVariant
                                          ? Text(
                                              snapshot.data[index].serialNo,
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            )
                                          : const Text(''),
                                      onTap: () {
                                        setState(() {
                                          isVariantSelected = true;
                                          positionID = index;
                                        });
                                      }),
                                );
                              },
                            ),
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
  FocusNode _focusNodeDiscountPer = FocusNode();
  FocusNode _focusNodeDiscount = FocusNode();

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

  calculate(StockProduct product) {
    if (enableMULTIUNIT) {
      if (saleRate > 0) {
        if (_conversion > 0) {
          //var r = 0.0;
          if (_focusNodeRate.hasFocus) {
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
            ? CommonService.getRound(4, (100 * rate) / (100 + taxP + kfcP))
            : CommonService.getRound(
                4, (100 * rate) / (100 + taxP + kfcP + cessPer))
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
      // discount = discountPercent > 0
      // ?
      double.tryParse(_discountController.text);
      // : discount;
    }
    rDisc = taxMethod == 'MINUS'
        ? CommonService.getRound(4, ((discount * 100) / (taxP + 100)))
        : discount;
    gross = CommonService.getRound(decimal, ((rRate * quantity)));
    subTotal = CommonService.getRound(decimal, (gross - rDisc));
    if (taxP > 0) {
      tax = CommonService.getRound(4, ((subTotal * taxP) / 100));
    }
    if (companyTaxMode == 'INDIA') {
      kfc = isKFC ? CommonService.getRound(4, ((subTotal * kfcP) / 100)) : 0;
      double csPer = taxP / 2;
      iGST = 0;
      csGST = CommonService.getRound(4, ((subTotal * csPer) / 100));
    } else if (companyTaxMode == 'GULF') {
      iGST = CommonService.getRound(4, ((subTotal * taxP) / 100));
      csGST = 0;
      kfc = 0;
    } else {
      iGST = 0;
      csGST = 0;
      kfc = 0;
      tax = 0;
    }
    if (cessOnNetAmount) {
      cess = 0;
      adCess = 0;
    } else {
      if (cessPer > 0) {
        cess = CommonService.getRound(4, ((subTotal * cessPer) / 100));
        adCess = CommonService.getRound(4, (quantity * adCessPer));
      } else {
        cess = 0;
        adCess = 0;
      }
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
      } else if (salesTypeData.rateType.toUpperCase() == 'BRANCH') {
        saleRate = product.branch;
      } else {
        saleRate = product.sellingPrice;
      }
    } else {
      if (rateTypeItem.name.toUpperCase() == 'RETAIL') {
        saleRate = product.retailPrice;
      } else if (rateTypeItem.name.toUpperCase() == 'WHOLESALE') {
        saleRate = product.wholeSalePrice;
      } else if (rateTypeItem.name.toUpperCase() == 'BRANCH') {
        saleRate = product.branch;
      } else {
        saleRate = product.sellingPrice;
      }
    }
    if (saleRate > 0 &&
        !_focusNodeRate.hasFocus &&
        _rateController.text.isEmpty) {
      _rateController.text = _conversion > 0
          ? (saleRate * _conversion).toStringAsFixed(decimal)
          : saleRate.toStringAsFixed(decimal);
      rate = _conversion > 0 ? saleRate * _conversion : saleRate;
    }
    uniqueCode = product.productId;
    if (isSerialNoInStockVariant) {
      _serialNoController.text = product.serialNo;
    }
    List<UnitModel> unitListData = [];

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
                            calculate(product);
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
                                    bool profitable = true;
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
                                    if (isEnableProfitlessSalesWarning) {
                                      if (profitPer > 0) {
                                        profitable = true;
                                      } else {
                                        profitable = false;
                                      }
                                    }
                                    if (profitable) {
                                      bool isUnit = true;
                                      if (enableMULTIUNIT) {
                                        if (_dropDownUnit <= 0) {
                                          int united = unitListData != null
                                              ? unitListData.isNotEmpty
                                                  ? unitListData[0].sUnit
                                                  : unitData
                                                      .firstWhere((element) =>
                                                          element.name == 'NOS')
                                                      .id
                                              : 0;
                                          _dropDownUnit = united;
                                          double unitedValue = unitListData !=
                                                  null
                                              ? unitListData.isNotEmpty
                                                  ? unitListData[0].conversion
                                                  : unitData
                                                      .firstWhere((element) =>
                                                          element.name == 'NOS')
                                                      .conversion
                                              : 0;
                                          _conversion = unitedValue;
                                        }
                                        isUnit =
                                            _dropDownUnit > 0 ? true : false;
                                      }
                                      if (isUnit) {
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
                                            stock: product.quantity,
                                            minimumRate: product.minimumRate));
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content:
                                              const Text('Please select SKU'),
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
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: const Text(
                                            'Sorry Non Profitable Rate.'),
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
                                    }
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
                          focusNode: _focusNodeQuantity,
                          // autofocus: true,
                          validator: (value) {
                            if (outOfStock) {
                              return 'No Stock';
                            }
                            return null;
                          },
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                allow: true, replacementString: '.')
                          ],
                          decoration: const InputDecoration(
                              labelText: 'Quantity',
                              hintText: '0.0',
                              border: OutlineInputBorder()),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              bool cartQ = false;
                              setState(() {
                                if (totalItem > 0) {
                                  double cartS = 0, cartQt = 0;
                                  for (var element in cartItem) {
                                    if (element.uniqueCode ==
                                        product.productId) {
                                      cartQt += element.quantity + element.free;
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

                                outOfStock = isLockQtyOnlyInSales
                                    ? (double.tryParse(value) * (unitValue) +
                                                freeQty) >
                                            product.quantity
                                        ? true
                                        : cartQ
                                            ? true
                                            : false
                                    : negativeStock
                                        ? false
                                        : salesTypeData.type == 'SALES-O' ||
                                                salesTypeData.type == 'SALES-Q'
                                            ? isStockProductOnlyInSalesQO
                                                ? (double.tryParse(value) *
                                                                (unitValue) +
                                                            freeQty) >
                                                        product.quantity
                                                    ? true
                                                    : cartQ
                                                        ? true
                                                        : false
                                                : false
                                            : (double.tryParse(value) *
                                                            (unitValue) +
                                                        freeQty) >
                                                    product.quantity
                                                ? true
                                                : cartQ
                                                    ? true
                                                    : false;
                                calculate(product);
                              });
                            }
                          },
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
                            // autofocus: true,
                            validator: (value) {
                              if (outOfStock) {
                                return 'No Stock';
                              }
                              return null;
                            },
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                  allow: true, replacementString: '.')
                            ],
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Free',
                                hintText: '0.0'),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                bool cartQ = false;
                                setState(() {
                                  if (totalItem > 0) {
                                    double cartS = 0, cartQt = 0;
                                    for (var element in cartItem) {
                                      if (element.uniqueCode ==
                                          product.productId) {
                                        cartQt +=
                                            element.quantity + element.free;
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

                                  outOfStock = isLockQtyOnlyInSales
                                      ? ((quantity * unitValue) +
                                                  double.tryParse(value)) >
                                              product.quantity
                                          ? true
                                          : cartQ
                                              ? true
                                              : false
                                      : negativeStock
                                          ? false
                                          : salesTypeData.type == 'SALES-O' ||
                                                  salesTypeData.type ==
                                                      'SALES-Q'
                                              ? isStockProductOnlyInSalesQO
                                                  ? ((quantity * unitValue) +
                                                              double.tryParse(
                                                                  value)) >
                                                          product.quantity
                                                      ? true
                                                      : cartQ
                                                          ? true
                                                          : false
                                                  : false
                                              : ((quantity * unitValue) +
                                                          double.tryParse(
                                                              value)) >
                                                      product.quantity
                                                  ? true
                                                  : cartQ
                                                      ? true
                                                      : false;
                                  calculate(product);
                                });
                              }
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
                              future: api.fetchUnitOf(product.itemId),
                              builder: (BuildContext context,
                                  AsyncSnapshot snapshot) {
                                if (snapshot.hasData) {
                                  unitListData.clear();
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
                                    unitListData.add(UnitModel(
                                        id: snapshot.data[i].id,
                                        itemId: snapshot.data[i].itemId,
                                        conversion: snapshot.data[i].conversion,
                                        name: snapshot.data[i].name,
                                        pUnit: snapshot.data[i].pUnit,
                                        sUnit: snapshot.data[i].sUnit,
                                        unit: snapshot.data[i].unit,
                                        rate: snapshot.data[i].rate));
                                  }
                                }
                                return snapshot.data != null &&
                                        snapshot.data.length > 0
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
                                            bool cartQ = false;
                                            _dropDownUnit = int.tryParse(value);
                                            for (var i = 0;
                                                i < unitListData.length;
                                                i++) {
                                              UnitModel _unit = unitListData[i];
                                              if (_unit.unit ==
                                                  int.tryParse(value)) {
                                                double _rate = _unit.rate ==
                                                        'MRP'
                                                    ? product.sellingPrice
                                                    : _unit.rate == 'WHOLESALE'
                                                        ? product.wholeSalePrice
                                                        : _unit.rate == 'RETAIL'
                                                            ? product
                                                                .retailPrice
                                                            : _unit.rate ==
                                                                    'SPRETAIL'
                                                                ? product
                                                                    .spRetailPrice
                                                                : rateType ==
                                                                        '1'
                                                                    ? product
                                                                        .sellingPrice
                                                                    : rateType ==
                                                                            '2'
                                                                        ? product
                                                                            .retailPrice
                                                                        : rateType ==
                                                                                '3'
                                                                            ? product.wholeSalePrice
                                                                            : rate;
                                                if (_unit.rate.isNotEmpty) {
                                                  rateTypeItem = rateTypeList
                                                      .firstWhere((element) =>
                                                          element.name ==
                                                          _unit.rate);
                                                }
                                                rate = _rate;
                                                saleRate = _rate;
                                                _rateController.text =
                                                    saleRate > 0
                                                        ? saleRate
                                                            .toStringAsFixed(2)
                                                        : '';
                                                _conversion = _unit.conversion;
                                                if (quantity > 0 ||
                                                    freeQty > 0) {
                                                  if (totalItem > 0) {
                                                    double cartS = 0,
                                                        cartQt = 0;
                                                    for (var element
                                                        in cartItem) {
                                                      if (element.uniqueCode ==
                                                          product.productId) {
                                                        cartQt +=
                                                            element.quantity +
                                                                element.free;
                                                        cartS = element.stock;
                                                      }
                                                    }
                                                    if (cartS > 0) {
                                                      if (cartS <
                                                          cartQt +
                                                              quantity +
                                                              freeQty) {
                                                        cartQ = true;
                                                      }
                                                    }
                                                  } else {
                                                    cartQ = false;
                                                  }
                                                  outOfStock =
                                                      isLockQtyOnlyInSales
                                                          ? ((quantity * _conversion) +
                                                                      freeQty) >
                                                                  product
                                                                      .quantity
                                                              ? true
                                                              : cartQ
                                                                  ? true
                                                                  : false
                                                          : negativeStock
                                                              ? false
                                                              : salesTypeData.type ==
                                                                          'SALES-O' ||
                                                                      salesTypeData
                                                                              .type ==
                                                                          'SALES-Q'
                                                                  ? isStockProductOnlyInSalesQO
                                                                      ? ((quantity * _conversion) + freeQty) >
                                                                              product
                                                                                  .quantity
                                                                          ? true
                                                                          : cartQ
                                                                              ? true
                                                                              : false
                                                                      : false
                                                                  : ((quantity * _conversion) +
                                                                              freeQty) >
                                                                          product
                                                                              .quantity
                                                                      ? true
                                                                      : cartQ
                                                                          ? true
                                                                          : false;
                                                }
                                                break;
                                              }
                                            }
                                            calculate(product);
                                          });
                                        },
                                      )
                                    : DropdownButton<String>(
                                        hint: Text(_dropDownUnit > 0
                                            ? UnitSettings.getUnitName(
                                                _dropDownUnit)
                                            : 'SKU'),
                                        items: unitList
                                            .map<DropdownMenuItem<String>>(
                                                (item) {
                                          return DropdownMenuItem<String>(
                                            value: item.key.toString(),
                                            child: Text(item.value),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _dropDownUnit = int.tryParse(value);
                                            // for (var i = 0;
                                            //     i < unitListData.length;
                                            //     i++) {
                                            //   UnitModel _unit = unitListData[i];
                                            //   if (_unit.unit ==
                                            //       int.tryParse(value)) {
                                            //     _conversion = _unit.conversion;
                                            //     break;
                                            //   }
                                            // }
                                            // calculate();
                                          });
                                        },
                                      );
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
                  const Divider(),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: TextField(
                            controller: _rateController,
                            focusNode: _focusNodeRate,
                            readOnly: isItemRateEditLocked,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                  allow: true, replacementString: '.')
                            ],
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Price',
                                hintText: '0.0'),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                if (isMinimumRate) {
                                  double minRate = product.minimumRate ?? 0;
                                  if (double.tryParse(_rateController.text) >=
                                      minRate) {
                                    setState(() {
                                      isMinimumRatedLock = false;
                                      calculate(product);
                                    });
                                  } else {
                                    setState(() {
                                      isMinimumRatedLock = true;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    calculate(product);
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
                                    rate: product.wholeSalePrice),
                                ProductRating(
                                    id: 2,
                                    name: labelSpRate,
                                    rate: product.spRetailPrice),
                                ProductRating(
                                    id: 3, name: 'Branch', rate: product.branch)
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
                                                      calculate(product);
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
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: white),
                                ),
                              ),
                              onTap: () {
                                productTrackingList(product);
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
                  const Divider(),
                  Visibility(
                    visible: !isItemDiscountEditLocked,
                    child: Row(
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
                                calculate(product);
                              });
                            },
                          ),
                        )),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: TextField(
                            focusNode: _focusNodeDiscount,
                            controller: _discountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                  allow: true, replacementString: '.')
                            ],
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Discount',
                                hintText: '0.0'),
                            onChanged: (value) {
                              setState(() {
                                calculate(product);
                              });
                            },
                          ),
                        )),
                      ],
                    ),
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
                  const Divider(),
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
                                          api
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
                                              outOfStock = isLockQtyOnlyInSales
                                                  ? cartItem[index].quantity +
                                                              1 >
                                                          cartItem[index].stock
                                                      ? true
                                                      : cartQ
                                                          ? true
                                                          : false
                                                  : negativeStock
                                                      ? false
                                                      : salesTypeData.type ==
                                                                  'SALES-O' ||
                                                              salesTypeData
                                                                      .type ==
                                                                  'SALES-Q'
                                                          ? isStockProductOnlyInSalesQO
                                                              ? cartItem[index]
                                                                              .quantity +
                                                                          1 >
                                                                      cartItem[
                                                                              index]
                                                                          .stock
                                                                  ? true
                                                                  : cartQ
                                                                      ? true
                                                                      : false
                                                              : false
                                                          : cartItem[index]
                                                                          .quantity +
                                                                      1 >
                                                                  cartItem[
                                                                          index]
                                                                      .stock
                                                              ? true
                                                              : cartQ
                                                                  ? true
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
                                            outOfStock = isLockQtyOnlyInSales
                                                ? ((cartItem[index].quantity *
                                                                    cartItem[index]
                                                                        .unitValue) +
                                                                cartItem[index]
                                                                    .free) +
                                                            1 >
                                                        cartItem[index].stock
                                                    ? true
                                                    : cartQ
                                                        ? true
                                                        : false
                                                : negativeStock
                                                    ? false
                                                    : salesTypeData.type ==
                                                                'SALES-O' ||
                                                            salesTypeData
                                                                    .type ==
                                                                'SALES-Q'
                                                        ? isStockProductOnlyInSalesQO
                                                            ? ((cartItem[index].quantity * cartItem[index].unitValue) +
                                                                            cartItem[index]
                                                                                .free) +
                                                                        1 >
                                                                    cartItem[
                                                                            index]
                                                                        .stock
                                                                ? true
                                                                : cartQ
                                                                    ? true
                                                                    : false
                                                            : false
                                                        : cartItem[index]
                                                                        .quantity +
                                                                    1 >
                                                                cartItem[index]
                                                                    .stock
                                                            ? true
                                                            : cartQ
                                                                ? true
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
                                      api
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
                                          api
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

  productTrackingList(StockProduct product) {
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
                child: productTrackingListData(ledId, product)),
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

  productTrackingListData(ledger, StockProduct product) {
    return FutureBuilder(
        future: api.getProductTracking(product.itemId, ledger),
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
                            rate = data[index]['Rate'].toDouble();
                            saleRate = data[index]['Rate'].toDouble();
                            _rateController.text = saleRate.toStringAsFixed(2);
                            calculate(product);
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
  int returnBillId = 0, commissionAccount = 0, bankAccount = 0;
  var commissionLedgerData, bankLedgerData;
  String bankLedgerName;
  TextEditingController returnEntryNoController = TextEditingController();
  TextEditingController returnAmountController = TextEditingController();
  TextEditingController commissionAmountController = TextEditingController();
  TextEditingController bankAmountController = TextEditingController();

  void addProduct(product) {
    int index = cartItem.indexWhere((i) => i.itemId == product.itemId);

    if (index != -1) {
      updateProduct(product, cartItem[index].quantity + product.quantity);
    } else {
      cartItem.add(product);
      calculateTotal();
    }
  }

  void removeProduct(product) {
    int index = cartItem.indexWhere((i) => i.itemId == product.itemId);
    cartItem[index].quantity = 1;
    cartItem.removeWhere((item) => item.id == product.id);
  }

  void updateProduct(product, qty) {
    int index = cartItem.indexWhere((i) => i.itemId == product.itemId);
    cartItem[index].quantity = qty;

    cartItem[index].gross = CommonService.getRound(
        4, (cartItem[index].rRate * cartItem[index].quantity));
    cartItem[index].net = CommonService.getRound(
        4, (cartItem[index].gross - cartItem[index].rDiscount));
    if (cartItem[index].taxP > 0) {
      cartItem[index].tax = CommonService.getRound(
          4, ((cartItem[index].net * cartItem[index].taxP) / 100));
      if (companyTaxMode == 'INDIA') {
        cartItem[index].fCess = 0; //isKFC
        //     ? CommonService.getRound(decimal, ((cartItem[index].net * kfcPer) / 100))
        //     : 0;
        double csPer = cartItem[index].taxP / 2;
        double csGST =
            CommonService.getRound(4, ((cartItem[index].net * csPer) / 100));
        cartItem[index].sGST = csGST;
        cartItem[index].cGST = csGST;
      } else if (companyTaxMode == 'GULF') {
        cartItem[index].cGST = 0;
        cartItem[index].sGST = 0;
        cartItem[index].iGST = CommonService.getRound(
            4, ((cartItem[index].net * cartItem[index].taxP) / 100));
      } else {
        cartItem[index].cGST = 0;
        cartItem[index].sGST = 0;
        cartItem[index].fCess = 0;
      }
    }
    cartItem[index].total = CommonService.getRound(
        4,
        (cartItem[index].net +
            cartItem[index].cGST +
            cartItem[index].sGST +
            cartItem[index].iGST +
            cartItem[index].cess +
            cartItem[index].fCess +
            cartItem[index].adCess));
    cartItem[index].profitPer = CommonService.getRound(
        4,
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
      bool profitable = true;
      if (isEnableProfitlessSalesWarning) {
        double _total = CommonService.getRound(
            2, (double.tryParse(value) * cartItem[index].quantity));
        profitPer = pRateBasedProfitInSales
            ? CommonService.getRound(
                2,
                (_total -
                    (cartItem[index].pRate *
                        cartItem[index].unitValue *
                        cartItem[index].quantity)))
            : CommonService.getRound(
                decimal,
                (_total -
                    (cartItem[index].rPRate *
                        cartItem[index].unitValue *
                        cartItem[index].quantity)));
        if (profitPer > 0) {
          profitable = true;
        } else {
          profitable = false;
        }
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
        if (profitable) {
          cartItem[index].rate = double.tryParse(value);
          cartItem[index].rRate = taxMethod == 'MINUS'
              ? isKFC
                  ? CommonService.getRound(
                      4,
                      (100 * cartItem[index].rate) /
                          (100 + cartItem[index].taxP + kfcPer))
                  : CommonService.getRound(
                      4,
                      (100 * cartItem[index].rate) /
                          (100 + cartItem[index].taxP))
              : cartItem[index].rate;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Sorry Non Profitable Rate.'),
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
        }
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
            unitValue = element.unitValue;
          }
        }
        if (cartS > 0) {
          if (cartS < cartQt - oldQty + double.tryParse(value)) {
            cartQ = true;
          }
        }
      }
      outOfStock = isLockQtyOnlyInSales
          ? (double.tryParse(value) * (unitValue) + freeQty) >
                  cartItem[index].stock
              ? true
              : cartQ
                  ? true
                  : false
          : negativeStock
              ? false
              : salesTypeData.type == 'SALES-O' ||
                      salesTypeData.type == 'SALES-Q'
                  ? isStockProductOnlyInSalesQO
                      ? (double.tryParse(value) * (unitValue) + freeQty) >
                              cartItem[index].stock
                          ? true
                          : cartQ
                              ? true
                              : false
                      : false
                  : (double.tryParse(value) * (unitValue) + freeQty) >
                          cartItem[index].stock
                      ? true
                      : cartQ
                          ? true
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
        4, (cartItem[index].rRate * cartItem[index].quantity));
    cartItem[index].net = CommonService.getRound(
        4, (cartItem[index].gross - cartItem[index].rDiscount));
    if (cartItem[index].taxP > 0) {
      cartItem[index].tax = CommonService.getRound(
          4, ((cartItem[index].net * cartItem[index].taxP) / 100));
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
            4, ((cartItem[index].net * cartItem[index].taxP) / 100));
      } else {
        cartItem[index].cGST = 0;
        cartItem[index].sGST = 0;
        cartItem[index].fCess = 0;
      }
    }
    cartItem[index].total = CommonService.getRound(
        4,
        (cartItem[index].net +
            cartItem[index].cGST +
            cartItem[index].sGST +
            cartItem[index].iGST +
            cartItem[index].cess +
            cartItem[index].fCess +
            cartItem[index].adCess));
    cartItem[index].profitPer = CommonService.getRound(
        4,
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

            PopupMenuButton<String>(
              icon: const Icon(Icons.settings, color: blue),
              onSelected: (value) {
                if (companyTaxMode == 'INDIA') {
                  setState(() {
                    if (salesData != null) {
                      if (value == 'Generate E-Way Bill') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => GenerateEWaybill(
                                      data: salesData,
                                      type: 'SALES',
                                    )));
                      } else if (value == 'Generate e-Invoice') {
                        if (salesTypeData.eInvoice) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => GenerateE_Invoice(
                                        data: salesData,
                                        type: 'SALES',
                                      )));
                        }
                      } else if (value == 'Edit  e-Invoice') {
                        if (salesTypeData.eInvoice) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => GenerateE_Invoice(
                                        data: salesData,
                                        type: 'SALES',
                                      )));
                        }
                      }
                    }
                  });
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'Generate E-Way Bill',
                  child: Text('Generate E-Way Bill'),
                ),
                const PopupMenuItem<String>(
                  value: 'Generate e-Invoice',
                  child: Text('Generate e-Invoice'),
                ),
                const PopupMenuItem<String>(
                  value: 'Edit  e-Invoice',
                  child: Text('Edit  e-Invoice Details'),
                ),
              ],
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                    "SubTotal : " +
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
                        Text("VAT : ",
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[400])),
                        Text(
                            CommonService.getRound(decimal, taxTotalCartValue)
                                .toStringAsFixed(decimal),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[400])),
                      ],
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Total : ",
                    style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[500])),
                Text(
                    CommonService.getRound(decimal, totalCartValue)
                        .toStringAsFixed(decimal),
                    style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[500])),
              ],
            ),
            Card(
              elevation: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 145,
                    height: 40,
                    child: TextField(
                      controller: controllerCashReceived,
                      focusNode: _focusNodeCashReceived,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp(r'[0-9]'),
                            allow: true, replacementString: '.')
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text('Cash Received'),
                      ),
                      onChanged: (value) {
                        setState(() {
                          balanceCalculate();
                        });
                      },
                    ),
                  ),
                  Text(
                      'Balance : ${ComSettings.appSettings('bool', 'key-round-off-amount', false) ? _balance.toStringAsFixed(decimal) : _balance.roundToDouble().toString()}'),
                ],
              ),
            ),
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
                  Visibility(
                    visible: _isReturnInSales,
                    child: Card(
                      elevation: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const SizedBox(
                            height: 3,
                          ),
                          SizedBox(
                            width: 100,
                            height: 35,
                            child: TextField(
                              controller: returnEntryNoController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Bill No :',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
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
                          const SizedBox(
                            width: 10,
                          ),
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  loadReturnForm = true;
                                });
                              },
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.blue.shade100),
                                // foregroundColor:
                                //     MaterialStateProperty.all(white)
                              ),
                              child: const Text('Return Bill')),
                          const SizedBox(
                            width: 10,
                          ),
                          SizedBox(
                            width: 100,
                            height: 35,
                            child: TextField(
                              controller: returnAmountController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Amount',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
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
                  ),
                  Card(
                    elevation: 2,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            width: deviceSize.width - 125,
                            height: 55,
                            child: DropdownSearch<dynamic>(
                              maxHeight: deviceSize.height - 110,
                              onFind: (String filter) =>
                                  api.getLedgerDataByParent(filter, 0, 0, 0, 0),
                              dropdownSearchDecoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Commission A/C'),
                              onChanged: (dynamic data) {
                                commissionLedgerData = data;
                                commissionAccount = data.id;
                              },
                              showSearchBox: true,
                              selectedItem: commissionLedgerData,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            height: 55,
                            child: TextField(
                              controller: commissionAmountController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Amount',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                    allow: true, replacementString: '.')
                              ],
                            ),
                          ),
                        ]),
                  ),
                  Card(
                    elevation: 2,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            width: deviceSize.width - 125,
                            height: 55,
                            child: DropdownSearch<dynamic>(
                              maxHeight: deviceSize.height - 110,
                              onFind: (String filter) =>
                                  widgetBankAccount(filter),
                              dropdownSearchDecoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Card A/C'),
                              onChanged: (dynamic data) {
                                bankLedgerData = data;
                                bankLedgerName = data.name;
                                bankAccount = data.id;
                              },
                              showSearchBox: true,
                              selectedItem: bankLedgerData,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            height: 55,
                            child: TextField(
                              controller: bankAmountController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Amount',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                    allow: true, replacementString: '.')
                              ],
                              onChanged: (value) {
                                setState(() {
                                  balanceCalculate();
                                });
                              },
                            ),
                          ),
                        ]),
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

                            // List<FocusNode> _focusNodes =
                            //     List<FocusNode>.generate(otherAmountList.length,
                            //         (int ind) => FocusNode());

                            return Card(
                              elevation: 5,
                              child: Row(children: [
                                expandStyle(
                                    2,
                                    Container(
                                        margin: const EdgeInsets.only(left: 2),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                              '${otherAmountList[index]['LedName']} : '),
                                        ))),
                                SizedBox(
                                  height: 35,
                                  width: 100,
                                  child: TextField(
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder()),
                                      controller:
                                          TextEditingController.fromValue(
                                              TextEditingValue(
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
                                      // focusNode: _focusNodes[index],
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter(
                                            RegExp(r'[0-9]'),
                                            allow: true,
                                            replacementString: '.')
                                      ],
                                      onChanged: (String str) {
                                        var cartTotal = totalCartValue;
                                        if (str.isNotEmpty) {
                                          otherAmountList[index]['Amount'] =
                                              double.tryParse(str);
                                          otherAmountList[index]['Percentage'] =
                                              CommonService.getRound(
                                                  decimal,
                                                  ((double.tryParse(str) *
                                                          100) /
                                                      cartTotal));
                                          var netTotal = (cartTotal -
                                                  returnAmount) +
                                              otherAmountList.fold(
                                                  0.0,
                                                  (t, e) =>
                                                      t +
                                                      double.parse(
                                                          e['Symbol'] == '-'
                                                              ? (e['Amount'] *
                                                                      -1)
                                                                  .toString()
                                                              : e['Amount']
                                                                  .toString()));
                                          setState(() {
                                            grandTotal = netTotal;
                                          });
                                        }
                                      },
                                      onSubmitted: (String str) {
                                        var cartTotal = totalCartValue;
                                        if (str.isNotEmpty) {
                                          otherAmountList[index]['Amount'] =
                                              double.tryParse(str);
                                          otherAmountList[index]['Percentage'] =
                                              CommonService.getRound(
                                                  decimal,
                                                  ((double.tryParse(str) *
                                                          100) /
                                                      cartTotal));
                                          var netTotal = (cartTotal -
                                                  returnAmount) +
                                              otherAmountList.fold(
                                                  0.0,
                                                  (t, e) =>
                                                      t +
                                                      double.parse(
                                                          e['Symbol'] == '-'
                                                              ? (e['Amount'] *
                                                                      -1)
                                                                  .toString()
                                                              : e['Amount']
                                                                  .toString()));
                                          setState(() {
                                            grandTotal = netTotal;
                                          });
                                        }
                                      }),
                                )
                              ]),
                            );
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
                        color: Colors.red)),
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
            0.0,
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
                  border: OutlineInputBorder(), labelText: "value"),
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
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: "barcode"),
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

  showMore(context, bool newBill) {
    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
          Navigator.pushReplacementNamed(
              context,
              ComSettings.appSettings('bool', 'key-simple-sales', false)
                  ? '/SimpleSale'
                  : '/sales',
              arguments: {'default': thisSale});
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
        title: newBill ? 'SAVED' : 'EDITED',
        context: context);
  }

  showErrorDialog(context, String msg) {
    debugPrint('error save sales :$msg');
    setState(() {
      _isLoading = false;
      buttonEvent = false;
    });
    SimpleAlertBox(
      context: context,
      title: 'Error',
      buttonText: 'Close',
      infoMessage: msg,
    );
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
    double billTotal = 0, billCash = 0;

    api.fetchSalesInvoice(data['Id'], salesTypeData.id).then((value) {
      if (value != null) {
        salesData = value;
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
        controllerNarration.text = information['Narration'];

        if (apiV != 'v19/') {
          String _bankLedgerName = information['BankName'] != null
              ? information['BankName'].toString()
              : 0;
          double _bankLedgerAmount = information['bankamount'] != null
              ? double.tryParse(information['bankamount'].toString())
              : 0;
          if (_bankLedgerAmount > 0) {
            bankAmountController.text = _bankLedgerAmount.toString();
            bankLedgerData = cashBankACList.firstWhere((element) =>
                element.name.toLowerCase() == _bankLedgerName.toLowerCase());
            bankLedgerName = bankLedgerData.name;
          } else {
            bankAmountController.text = '';
            bankLedgerData = null;
            bankLedgerName = '';
          }

          int _commissionLedgerAc = information['CareOff'] != null
              ? int.tryParse(information['CareOff'].toString())
              : 0;
          double _commissionLedgerAmount = information['CareOffAmount'] != null
              ? double.tryParse(information['CareOffAmount'].toString())
              : 0;

          if (_commissionLedgerAmount > 0) {
            commissionAmountController.text =
                _commissionLedgerAmount.toString();
            commissionAccount = _commissionLedgerAc;
            api.getCustomerDetail(_commissionLedgerAc).then((ledgerData) =>
                commissionLedgerData = LedgerModel(
                    id: _commissionLedgerAc, name: ledgerData.name));
          } else {
            commissionAmountController.text = '';
            commissionLedgerData = null;
            commissionAccount = 0;
          }
        }
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
            taxNumber: information['gstno']);
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
              net: double.tryParse(product['Net'].toString()), //subTotal,
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
          controllerCashReceived.text = billCash.toString();
          _balance = controllerCashReceived.text.isNotEmpty
              ? grandTotal > 0
                  ? grandTotal - double.tryParse(controllerCashReceived.text)
                  : ((totalCartValue) -
                      double.tryParse(controllerCashReceived.text))
              : grandTotal > 0
                  ? grandTotal
                  : totalCartValue;
        }
        if (returnAmount > 0) {
          returnAmountController.text = returnAmount.toString();
          returnEntryNoController.text = returnBillId.toString();
        }
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

  salesManVehicle() {
    return Visibility(
        visible: salesmanAsVehicle,
        child: Row(
          children: [
            // const Text('Vehicle No'),
            SizedBox(
              width: 120,
              // child: Expanded(
              //   child: TextField(
              //     decoration: const InputDecoration(
              //       border: OutlineInputBorder(),
              //       label: Text('No'),
              //     ),
              //     onChanged: (value) {
              //       setState(() {
              //         // customerName =
              //         //     value.isNotEmpty ? value.toUpperCase() : 'CASH';
              //       });
              //     },
              //   ),
              // ),
              child: DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) => getSalesManListData(filter),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: 'V No'),
                onChanged: (dynamic data) {
                  vehicleData = otherRegSalesManList.firstWhere((element) =>
                      element['Auto'].toString() == data.id.toString());
                  vehicleName = vehicleData['Name'];
                },
                showSearchBox: true,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: TextField(
                // enabled: false,
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: Text(vehicleName),
                ),
              ),
            ),
          ],
        ));
  }

  Future<List<dynamic>> getSalesManListData(String filter) async {
    var dd = filter.isEmpty
        ? otherRegSalesManList
        : otherRegSalesManList
            .where((element) => element['Name']
                .toString()
                .toLowerCase()
                .contains(filter.toLowerCase()))
            .toList();
    List<DataJson> dataResult = [];
    for (var data in dd) {
      dataResult.add(DataJson(
          id: data['Auto'],
          name: data['Name'].trim().split(' ')[0].toString()));
    }
    return dataResult;
  }

  showBottom0(BuildContext ctx) {
    showModalBottomSheet(
        isScrollControlled: true,
        elevation: 5,
        context: ctx,
        builder: (ctx) => Padding(
              padding: EdgeInsets.only(
                  top: 15,
                  left: 15,
                  right: 15,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controllerNarration,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Narration...',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Visibility(
                    visible: _isReturnInSales,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: returnEntryNoController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Bill No :',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
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
                        const SizedBox(
                          width: 10,
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
                              border: OutlineInputBorder(),
                              labelText: 'Amount :',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
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
                    // height: deviceSize.height / 6,
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
                                                      decimal,
                                                      ((double.tryParse(str) *
                                                              100) /
                                                          cartTotal));
                                              var netTotal = (cartTotal -
                                                      returnAmount) +
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
            ));

    // child: Column(
    //   mainAxisSize: MainAxisSize.min,
    //   crossAxisAlignment: CrossAxisAlignment.start,
    //   children: [
    //     TextField(
    //       controller: _otherDiscountController,
    //       focusNode: _focusNodeOtherDiscount,
    //       keyboardType:
    //           TextInputType.numberWithOptions(decimal: true),
    //       decoration: InputDecoration(labelText: 'Other Discount'),
    //     ),
    //     TextField(
    //       controller: _otherChargesController,
    //       focusNode: _focusNodeOtherCharges,
    //       keyboardType:
    //           TextInputType.numberWithOptions(decimal: true),
    //       decoration: InputDecoration(labelText: 'Other Charges'),
    //     ),
    //     TextField(
    //       controller: narrationController,
    //       decoration: InputDecoration(labelText: 'Narration'),
    //     ),
    //     const SizedBox(
    //       height: 15,
    //     ),
    //     Text(calculateGrandTotal()),
    //     Center(
    //         child: ElevatedButton(
    //             onPressed: () {
    //               setState(() {
    //                 calculateGrandTotal();
    //               });
    //             },
    //             child: const Text('Submit')))
    //   ],
    // ),
  }

  // var _dropDownBankValue = '';
  // widgetBankAccount() {
  //   return DropdownButton<String>(
  //     hint: Text(_dropDownBankValue.isNotEmpty
  //         ? _dropDownBankValue.split('-')[1]
  //         : 'Select bank account'),
  //     items: cashBankACList.map<DropdownMenuItem<String>>((item) {
  //       return DropdownMenuItem<String>(
  //         value: item.id.toString() + "-" + item.name,
  //         child: Text(item.name),
  //       );
  //     }).toList(),
  //     onChanged: (value) {
  //       setState(() {
  //         _dropDownBankValue = value;
  //         bankLedgerData = value;
  //         bankAccount = int.parse(value.split('-')[0]);
  //         bankLedgerName = value.split('-')[1];
  //       });
  //     },
  //   );
  // }

  Future<List<dynamic>> widgetBankAccount(String filter) async {
    var dd = filter.isEmpty
        ? cashBankACList
        : cashBankACList
            .where((element) => element.name
                .toString()
                .toLowerCase()
                .contains(filter.toLowerCase()))
            .toList();
    List<DataJson> dataResult = [];
    for (var data in dd) {
      dataResult.add(DataJson(id: data.id, name: data.name.trim().toString()));
    }
    return dataResult;
  }

  void balanceCalculate() {
    double cashReceived = controllerCashReceived.text.trim().isNotEmpty
        ? double.tryParse(controllerCashReceived.text)
        : 0;
    double bankAmount = bankAmountController.text.trim().isNotEmpty
        ? double.parse(bankAmountController.text.trim())
        : 0;
    _balance = (cashReceived > 0 || bankAmount > 0)
        ? grandTotal > 0
            ? grandTotal - cashReceived - bankAmount
            : ((totalCartValue) - cashReceived - bankAmount)
        : grandTotal > 0
            ? grandTotal
            : totalCartValue;
  }
}

String _otherAmountTotal(var otherAmountData) {
  var data = otherAmountData;
  var a = data.fold(
      0.0,
      (t, e) =>
          t +
          double.parse(e['Symbol'] == '-'
              ? (e['Amount'] * -1).toString()
              : e['Amount'].toString()));
  return a.toString();
}

class ProductRating {
  int id;
  String name;
  double rate;
  ProductRating({this.id, this.name, this.rate});
}
