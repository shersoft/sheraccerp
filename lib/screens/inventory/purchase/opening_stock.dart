// @dart = 2.11

import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/product_register_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/util/show_confirm_alert_box.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/popup_menu_action.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class OpeningStock extends StatefulWidget {
  const OpeningStock({Key key}) : super(key: key);

  @override
  _OpeningStockState createState() => _OpeningStockState();
}

class _OpeningStockState extends State<OpeningStock> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DioService dio = DioService();
  Size deviceSize;
  var ledgerModel, productModelPrize;
  ProductPurchaseModel productModel;
  List<dynamic> purchaseAccountList = [];
  DateTime now = DateTime.now();
  String formattedDate, _narration = '';
  bool isTax = true,
      valueMore = false,
      _isLoading = false,
      widgetID = true,
      oldBill = false,
      lastRecord = false,
      realPRateBasedProfitPercentage = false,
      buttonEvent = false;
  List<CartItemOP> cartItem = [];
  int page = 1, pageTotal = 0, totalRecords = 0;
  List<ProductPurchaseModel> itemDisplay = [];
  List<ProductPurchaseModel> items = [];
  List<dynamic> ledgerDisplay = [];
  List<dynamic> _ledger = [];
  bool enableMULTIUNIT = false,
      cessOnNetAmount = false,
      enableKeralaFloodCess = false,
      useUniqueCodeAsBarcode = false,
      useOldBarcode = false;
  int locationId = 1, salesManId = 0, decimal = 2;

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    dio.getStockAC().then((value) {
      setState(() {
        purchaseAccountList.addAll(value);
      });
    });
    loadSettings();
  }

  loadSettings() {
    CompanyInformation companySettings =
        ScopedModel.of<MainModel>(context).getCompanySettings();
    List<CompanySettings> settings =
        ScopedModel.of<MainModel>(context).getSettings();

    taxMethod = companySettings.taxCalculation;
    enableMULTIUNIT = ComSettings.getStatus('ENABLE MULTI-UNIT', settings);
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    cessOnNetAmount = ComSettings.getStatus('CESS ON NET AMOUNT', settings);
    enableKeralaFloodCess = false;
    useUniqueCodeAsBarcode =
        ComSettings.getStatus('USE UNIQUECODE AS BARCODE', settings);
    useOldBarcode = ComSettings.getStatus('USE OLD BARCODE', settings);
    realPRateBasedProfitPercentage =
        ComSettings.getStatus('REAL PRATE BASED PROFIT PERCENTAGE', settings);

    salesManId = ComSettings.appSettings(
            'int', 'key-dropdown-default-salesman-view', 1) -
        1;
    locationId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;
  }

  @override
  Widget build(BuildContext context) {
    controllerBranch.selection = TextSelection.fromPosition(
        TextPosition(offset: controllerBranch.text.length));

    controllerDiscount.selection = TextSelection.fromPosition(
        TextPosition(offset: controllerDiscount.text.length));
    controllerDiscountPer.selection = TextSelection.fromPosition(
        TextPosition(offset: controllerDiscountPer.text.length));
    controllerMrp.selection = TextSelection.fromPosition(
        TextPosition(offset: controllerMrp.text.length));
    controllerQuantity.selection = TextSelection.fromPosition(
        TextPosition(offset: controllerQuantity.text.length));
    controllerRate.selection = TextSelection.fromPosition(
        TextPosition(offset: controllerRate.text.length));
    controllerRetail.selection = TextSelection.fromPosition(
        TextPosition(offset: controllerRetail.text.length));
    controllerWholeSale.selection = TextSelection.fromPosition(
        TextPosition(offset: controllerWholeSale.text.length));

    deviceSize = MediaQuery.of(context).size;
    return WillPopScope(
        onWillPop: _onWillPop,
        child: widgetID ? widgetPrefix() : widgetSuffix());
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit Purchase'),
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

  widgetSuffix() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
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
                    if (cartItem.isNotEmpty) {
                      setState(() {
                        _isLoading = true;
                        buttonEvent = true;
                      });
                      delete(context);
                    } else {
                      showInSnackBar('No items found on bill');
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
                  onPressed: () async {
                    if (buttonEvent) {
                      return;
                    } else {
                      if (totalCartTotal > 0) {
                        setState(() {
                          _isLoading = true;
                          buttonEvent = true;
                        });
                        var inf = '[' +
                            json.encode({
                              'id': '0',
                              'name': '',
                              'invNo': '0',
                              'invDate': ''
                            }) +
                            ']';
                        var jsonItem = CartItemOP.encodeCartToJson(cartItem);
                        var items = json.encode(jsonItem);
                        var stType = 'OP_Update';
                        var data = '[' +
                            json.encode({
                              'entryNo': dataDynamic[0]['EntryNo'],
                              'date': DateUtil.dateYMD(formattedDate),
                              'grossValue': totalGrossValue,
                              'discount': totalDiscount,
                              'net': totalNet,
                              'cess': totalCess,
                              'total': totalCartTotal,
                              'otherCharges': 0,
                              'otherDiscount': 0,
                              'grandTotal': totalCartTotal,
                              'taxType': isTax ? 'T' : 'N.T',
                              'purchaseAccount': purchaseAccountList[0]['id'],
                              'narration': _narration,
                              'type': 'OP',
                              'cashPaid': '0',
                              'igst': totalIgST,
                              'cgst': totalCgST,
                              'sgst': totalSgST,
                              'fCess': totalFCess,
                              'adCess': totalAdCess,
                              'Salesman': salesManId,
                              'location': locationId,
                              'statementtype': stType,
                              'fyId': currentFinancialYear.id,
                            }) +
                            ']';

                        final body = {
                          'information': inf,
                          'data': data,
                          'particular': items
                        };
                        bool _state = await dio.addOpeningStock(body);
                        setState(() {
                          _isLoading = false;
                        });
                        if (_state) {
                          cartItem.clear();
                          showConfirmAlertBox(
                              context, 'Open Stock', 'Opening Stock Edited');
                        } else {
                          showInSnackBar('Error enter data correctly');
                          setState(() {
                            buttonEvent = false;
                          });
                        }
                      } else {
                        showInSnackBar('Please Add Product');
                      }
                    }
                  },
                  icon: const Icon(Icons.edit))
              : IconButton(
                  color: blue,
                  iconSize: 40,
                  onPressed: () async {
                    if (totalCartTotal > 0) {
                      if (buttonEvent) {
                        setState(() {
                          buttonEvent = false;
                        });

                        return;
                      } else {
                        setState(() {
                          _isLoading = true;
                          buttonEvent = true;
                        });
                        var inf = '[' +
                            json.encode({
                              'id': '0',
                              'name': '',
                              'invNo': '0',
                              'invDate': ''
                            }) +
                            ']';
                        var jsonItem = CartItemOP.encodeCartToJson(cartItem);
                        var items = json.encode(jsonItem);
                        var stType = 'Op_Insert';
                        var data = '[' +
                            json.encode({
                              'date': DateUtil.dateYMD(formattedDate),
                              'grossValue': totalGrossValue,
                              'discount': totalDiscount,
                              'net': totalNet,
                              'cess': totalCess,
                              'total': totalCartTotal,
                              'otherCharges': 0,
                              'otherDiscount': 0,
                              'grandTotal': totalCartTotal,
                              'taxType': isTax ? 'T' : 'N.T',
                              'purchaseAccount': purchaseAccountList[0]['id'],
                              'narration': _narration,
                              'type': 'OP',
                              'cashPaid': '0',
                              'igst': totalIgST,
                              'cgst': totalCgST,
                              'sgst': totalSgST,
                              'fCess': totalFCess,
                              'adCess': totalAdCess,
                              'Salesman': salesManId,
                              'location': locationId,
                              'statementtype': stType,
                              'fyId': currentFinancialYear.id,
                              'entryNo': 0,
                            }) +
                            ']';

                        final body = {
                          'information': inf,
                          'data': data,
                          'particular': items
                        };
                        bool _state = await dio.addOpeningStock(body);
                        setState(() {
                          _isLoading = false;
                        });
                        if (_state) {
                          cartItem.clear();
                          showConfirmAlertBox(
                              context, 'Open Stock', 'Opening Stock Saved');
                        } else {
                          showInSnackBar('Error enter data correctly');
                          setState(() {
                            buttonEvent = false;
                          });
                        }
                      }
                    } else {
                      showInSnackBar('Please Add Product');
                    }
                  },
                  icon: const Icon(Icons.save)),
        ],
        title: const Text('Opening Stock'),
      ),
      body: ProgressHUD(
          inAsyncCall: _isLoading, opacity: 0.0, child: selectWidget()),
    );
  }

  widgetPrefix() {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          actions: [
            TextButton(
                child: const Text(
                  " New ",
                  style: TextStyle(
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
          ],
          title: const Text('Opening Stock'),
        ),
        body: Container(
          child: previousBill(),
        ));
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
        var statement = 'OpeningStockList';

        dio
            .getPaginationList(statement, page, '1', '0',
                DateUtil.dateYMD(formattedDate), salesManId.toString())
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
    _focusNodeQuantity.dispose();
    _focusNodeBranch.dispose();
    _focusNodeDiscount.dispose();
    _focusNodeDiscountPer.dispose();
    _focusNodeMrp.dispose();
    _focusNodeRate.dispose();
    _focusNodeRetail.dispose();
    _focusNodeWholeSale.dispose();
    super.dispose();
  }

  int nextWidget = 0;
  Widget selectWidget() {
    return nextWidget == 0
        ? purchaseHeaderWidget()
        : nextWidget == 1
            ? selectProductWidget()
            : nextWidget == 2
                ? itemDetails()
                : nextWidget == 3
                    ? cartProduct()
                    : nextWidget == 4
                        ? selectLedgerWidget()
                        : Container(
                            padding: const EdgeInsets.all(2.0),
                            child: const Text('No Widget'),
                          );
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
                        dataDisplay[index]['DDate'] +
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
              const Text("No items in Cart"),
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
                  label: const Text('Take New Opening Stock'))
            ],
          ));
  }

  bool isData = false;

  selectLedgerWidget() {
    setState(() {
      if (_ledger.isNotEmpty) isData = true;
    });
    return FutureBuilder<List<dynamic>>(
      future: dio.getSalesListData('', 'sales_list/supplier'),
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
                                isData = false;
                                Navigator.pushNamed(context, '/ledger',
                                    arguments: {'parent': 'SUPPLIERS'});
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
                            nextWidget = 2;
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
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('This may take some time..')
            ],
          ),
        );
      },
    );
  }

  purchaseHeaderWidget() {
    return Center(
        child: Column(
      children: [
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text(
                  'Date : ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                InkWell(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _selectDate(),
                ),
                const Text(
                  'Tax:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Checkbox(
                  checkColor: Colors.greenAccent,
                  activeColor: Colors.red,
                  value: isTax,
                  onChanged: (bool value) {
                    setState(() {
                      isTax = value;
                    });
                  },
                ),
              ],
            ),
            ListTile(
              title: Text(
                  purchaseAccountList.isNotEmpty
                      ? purchaseAccountList[0]['name']
                      : '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        InkWell(
            child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Text(
                    'Item Add',
                    style: TextStyle(
                        color: blue, fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                )),
            onTap: () {
              setState(() {
                clearValue();
                editItem = false;
                nextWidget = 1;
                ledgerModel = null;
              });
            }),
      ],
    ));
  }

  bool isItemData = false;
  selectProductWidget() {
    setState(() {
      if (items.isNotEmpty) isItemData = true;
    });
    return FutureBuilder<List<ProductPurchaseModel>>(
      future: dio.fetchAllProductPurchase(),
      builder: (ctx, snapshot) {
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
                        child: Row(
                          children: [
                            Flexible(
                              child: TextField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  label: Text('Search...'),
                                ),
                                onChanged: (text) {
                                  text = text.toLowerCase();
                                  setState(() {
                                    itemDisplay = items.where((item) {
                                      var itemName =
                                          item.itemName.toLowerCase();
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
                                setState(() {
                                  items = [];
                                  itemDisplay = [];
                                  isItemData = false;
                                });
                                Navigator.pushNamed(context, '/product');
                              },
                            )
                          ],
                        ),
                      )
                    : InkWell(
                        child: Card(
                          child: ListTile(
                              title: Text(itemDisplay[index - 1].itemName)),
                        ),
                        onTap: () {
                          setState(() {
                            productModel = itemDisplay[index - 1];
                            nextWidget = 2;
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
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('This may take some time..')
            ],
          ),
        );
      },
    );
  }

  bool _isPrize = false;
  itemDetails() {
    int id = productModel.slNo;
    dio.fetchProductPrize(id).then((value) {
      productModelPrize = value[0];
      setState(() {
        _isPrize = true;
      });
    });

    return _isPrize ? itemDetailWidget() : const Loading();
  }

  TextEditingController controllerQuantity = TextEditingController();
  TextEditingController controllerRate = TextEditingController();
  TextEditingController controllerDiscountPer = TextEditingController();
  TextEditingController controllerDiscount = TextEditingController();
  TextEditingController controllerMrp = TextEditingController();
  TextEditingController controllerRetail = TextEditingController();
  TextEditingController controllerWholeSale = TextEditingController();
  TextEditingController controllerBranch = TextEditingController();
  FocusNode _focusNodeQuantity = FocusNode();
  FocusNode _focusNodeRate = FocusNode();
  FocusNode _focusNodeDiscountPer = FocusNode();
  FocusNode _focusNodeDiscount = FocusNode();
  FocusNode _focusNodeMrp = FocusNode();
  FocusNode _focusNodeRetail = FocusNode();
  FocusNode _focusNodeWholeSale = FocusNode();
  FocusNode _focusNodeBranch = FocusNode();

  double quantity = 0,
      rate = 0,
      subTotal = 0,
      discount = 0,
      discountPer = 0,
      net = 0,
      tax = 0,
      total = 0,
      mrp = 0,
      retail = 0,
      wholeSale = 0,
      branch = 0,
      taxP = 0,
      rDisc = 0,
      rRate = 0,
      rateOff = 0,
      kfcP = 0,
      fCess = 0,
      unitValue = 1,
      conversion = 0,
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
      expense = 0,
      mrpPer = 0,
      wholesalePer = 0,
      retailPer = 0,
      spRetail = 0,
      spRetailPer = 0,
      branchPer = 0;
  String expDate = '1900-01-01', serialNo = '';
  var unit;
  int uniqueCode = 0, fUnitId = 0, barcode = 0;

  itemDetailWidget() {
    if (editItem) {
      taxP = cartItem.elementAt(position).taxP;
      // kfcP = double.tryParse(productModel['KFC'].toString());
      ledgerModel = DataJson(
          id: cartItem.elementAt(position).supplierId,
          name: cartItem.elementAt(position).supplier);
      quantity = cartItem[position].quantity;
      if (quantity > 0 && !_focusNodeQuantity.hasFocus) {
        controllerQuantity.text = quantity.toString();
      }
      rate = cartItem.elementAt(position).rate;
      if (rate > 0 && !_focusNodeRate.hasFocus) {
        controllerRate.text = rate.toString();
      }
      if (cartItem.elementAt(position).rRate > 0) {
        rRate = cartItem.elementAt(position).rRate;
      }
      mrp = cartItem.elementAt(position).mrp;
      if (mrp > 0 && !_focusNodeMrp.hasFocus) {
        controllerMrp.text = mrp.toString();
      }
      retail = cartItem.elementAt(position).retail;
      if (retail > 0 && !_focusNodeRetail.hasFocus) {
        controllerRetail.text = retail.toString();
      }
      wholeSale = cartItem.elementAt(position).wholesale;
      if (wholeSale > 0 && !_focusNodeWholeSale.hasFocus) {
        controllerWholeSale.text = wholeSale.toString();
      }
      spRetail = cartItem.elementAt(position).spRetail;
      branch = cartItem.elementAt(position).branch;
      if (branch > 0 && !_focusNodeBranch.hasFocus) {
        controllerBranch.text = branch.toString();
      }
      discount = cartItem.elementAt(position).discount;
      if (discount > 0 && !_focusNodeDiscount.hasFocus) {
        controllerDiscount.text = discount.toString();
      }
      discountPer = cartItem.elementAt(position).discountPercent;
      if (discountPer > 0 && !_focusNodeDiscountPer.hasFocus) {
        controllerDiscountPer.text = discountPer.toString();
      }
      subTotal = cartItem.elementAt(position).gross;
      net = cartItem.elementAt(position).net;
      if (taxP > 0) {
        tax = cartItem.elementAt(position).tax;
        iGST = cartItem.elementAt(position).iGST;
        csGST = cartItem.elementAt(position).cGST;
      } else {
        iGST = 0;
        csGST = 0;
        tax = 0;
      }
      total = cartItem.elementAt(position).total;
    } else {
      adCessPer = productModel.adCessPer;
      cessPer = productModel.cessPer;
      taxP = productModel.tax;
      kfcP = 0; //double.tryParse(productModel['KFC'].toString());
      rate = double.tryParse(productModelPrize['prate'].toString());
      if (rate > 0 && !_focusNodeRate.hasFocus) {
        controllerRate.text = rate.toString();
      }
      if (double.tryParse(productModelPrize['realprate'].toString()) > 0) {
        rRate = double.tryParse(productModelPrize['realprate'].toString());
      }
      mrp = double.tryParse(productModelPrize['mrp'].toString());
      if (mrp > 0 && !_focusNodeMrp.hasFocus) {
        controllerMrp.text = mrp.toString();
      }
      retail = double.tryParse(productModelPrize['retail'].toString());
      if (retail > 0 && !_focusNodeRetail.hasFocus) {
        controllerRetail.text = retail.toString();
      }
      wholeSale = double.tryParse(productModelPrize['wsrate'].toString());
      if (wholeSale > 0 && !_focusNodeWholeSale.hasFocus) {
        controllerWholeSale.text = wholeSale.toString();
      }
      spRetail = double.tryParse(productModelPrize['spretail'].toString());
      branch = double.tryParse(productModelPrize['branch'].toString());
      if (branch > 0 && !_focusNodeBranch.hasFocus) {
        controllerBranch.text = branch.toString();
      }
    }

    calculate() {
      quantity = controllerQuantity.text.isNotEmpty
          ? double.tryParse(controllerQuantity.text)
          : 0;
      rate = controllerRate.text.isNotEmpty
          ? double.tryParse(controllerRate.text)
          : 0;
      discount = controllerDiscount.text.isNotEmpty
          ? double.tryParse(controllerDiscount.text)
          : 0;
      discountPer = controllerDiscountPer.text.isNotEmpty
          ? double.tryParse(controllerDiscountPer.text)
          : 0;
      rRate = taxMethod == 'MINUS'
          ? CommonService.getRound(decimal, (100 * rate) / (100 + taxP))
          : rate;
      rDisc = taxMethod == 'MINUS'
          ? CommonService.getRound(decimal, ((discount * 100) / (taxP + 100)))
          : discount;
      subTotal = CommonService.getRound(decimal, (rate * quantity));
      net = CommonService.getRound(decimal, (subTotal - discount));
      if (taxP > 0) {
        tax = CommonService.getRound(decimal, ((subTotal * taxP) / 100));
      }
      if (companyTaxMode == 'INDIA') {
        double csPer = taxP / 2;
        iGST = 0;
        csGST = CommonService.getRound(decimal, ((subTotal * csPer) / 100));
      } else if (companyTaxMode == 'GULF') {
        iGST = CommonService.getRound(decimal, ((subTotal * taxP) / 100));
        csGST = 0;
      } else {
        iGST = 0;
        csGST = 0;
        tax = 0;
      }
      total = CommonService.getRound(
          decimal, (net + csGST + csGST + iGST + cess + adCess));
      // total = net + tax;
      if (mrp > 0) {
        profitPer = realPRateBasedProfitPercentage
            ? CommonService.getRound(decimal, (((mrp - rRate) * 100) / rRate))
            : CommonService.getRound(decimal, (((mrp - rate) * 100) / rate));
      }
      if (retail > 0) {
        retailPer = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((retail - rRate) * 100) / rRate))
            : CommonService.getRound(decimal, (((retail - rate) * 100) / rate));
      }
      if (wholeSale > 0) {
        wholesalePer = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((wholeSale - rRate) * 100) / rRate))
            : CommonService.getRound(
                decimal, (((wholeSale - rate) * 100) / rate));
      }
      if (spRetail > 0) {
        spRetailPer = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((spRetail - rRate) * 100) / rRate))
            : CommonService.getRound(
                decimal, (((spRetail - rate) * 100) / rate));
      }
      if (branch > 0) {
        branchPer = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((branch - rRate) * 100) / rRate))
            : CommonService.getRound(decimal, (((branch - rate) * 100) / rate));
      }

      // unitValue = _conversion > 0 ? _conversion : 1;
    }

    calculateRate() {
      mrp = controllerMrp.text.isNotEmpty
          ? double.tryParse(controllerMrp.text)
          : 0;
      retail = controllerRetail.text.isNotEmpty
          ? double.tryParse(controllerRetail.text)
          : 0;
      wholeSale = controllerWholeSale.text.isNotEmpty
          ? double.tryParse(controllerWholeSale.text)
          : 0;
      branch = controllerBranch.text.isNotEmpty
          ? double.tryParse(controllerBranch.text)
          : 0;
      rate = controllerRate.text.isNotEmpty
          ? double.tryParse(controllerRate.text)
          : 0;
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Item : ${editItem ? cartItem.elementAt(position).itemName : productModel.itemName}')),
            Row(
              children: [
                Expanded(
                    child: MaterialButton(
                  onPressed: () {
                    setState(() {
                      nextWidget = 1;
                      editItem = false;
                    });
                  },
                  child: const Text("Back"),
                  color: blue[400],
                )),
                const SizedBox(
                  width: 2,
                ),
                Expanded(
                    child: MaterialButton(
                  onPressed: () {
                    setState(() {
                      nextWidget = 3;
                      clearValue();
                    });
                  },
                  child: const Text("Cancel"),
                  color: blue[400],
                )),
                const SizedBox(
                  width: 2,
                ),
                Expanded(
                    child: MaterialButton(
                  onPressed: () {
                    setState(() {
                      unit ??= DataJson(id: 0, name: '');
                      rate = controllerRate.text.isNotEmpty
                          ? double.tryParse(controllerRate.text)
                          : rate;
                      mrp = controllerMrp.text.isNotEmpty
                          ? double.tryParse(controllerMrp.text)
                          : mrp;
                      retail = controllerRetail.text.isNotEmpty
                          ? double.tryParse(controllerRetail.text)
                          : retail;
                      wholeSale = controllerWholeSale.text.isNotEmpty
                          ? double.tryParse(controllerWholeSale.text)
                          : wholeSale;
                      // spRetail = controllerSPRetail.text.length>0? double.tryParse(controllerSPRetail.text):spRetail;
                      branch = controllerBranch.text.isNotEmpty
                          ? double.tryParse(controllerBranch.text)
                          : branch;
                      quantity = controllerQuantity.text.isNotEmpty
                          ? double.tryParse(controllerQuantity.text)
                          : quantity;

                      if (editItem) {
                        cartItem[position].adCess = adCess;
                        cartItem[position].barcode = barcode;
                        cartItem[position].branch = branch;
                        cartItem[position].branchPer = branchPer;
                        cartItem[position].cDisc = cDisc;
                        cartItem[position].cGST = csGST;
                        cartItem[position].cdPer = cdPer;
                        cartItem[position].cess = cess;
                        cartItem[position].discount = discount;
                        cartItem[position].discountPercent = discountPer;
                        // cartItem[position].expDate = expDate;
                        // cartItem[position].expense = expense;
                        cartItem[position].fCess = fCess;
                        cartItem[position].fUnitId = fUnitId;
                        cartItem[position].fUnitValue = fUnitValue;
                        cartItem[position].free = free;
                        cartItem[position].gross = subTotal;
                        cartItem[position].iGST = iGST;
                        // cartItem[position].id = cartItem.length + 1;
                        // cartItem[position].itemId = productModel['slno'];
                        // cartItem[position].itemName = productModel['itemname'];
                        // cartItem[position].location = locationId;
                        cartItem[position].mrp = mrp;
                        cartItem[position].mrpPer = mrpPer;
                        cartItem[position].net = net;
                        cartItem[position].profitPer = profitPer;
                        cartItem[position].quantity = quantity;
                        cartItem[position].rRate = rRate;
                        cartItem[position].rate = rate;
                        cartItem[position].retail = retail;
                        cartItem[position].retailPer = retailPer;
                        cartItem[position].sGST = csGST;
                        cartItem[position].serialNo = serialNo;
                        cartItem[position].spRetail = spRetail;
                        cartItem[position].spRetailPer = spRetailPer;
                        cartItem[position].tax = tax;
                        cartItem[position].taxP = taxP;
                        cartItem[position].total = total;
                        cartItem[position].uniqueCode = uniqueCode;
                        // cartItem[position].unitId = unit.id;
                        // cartItem[position].unitName = unit.name;
                        cartItem[position].unitValue = unitValue;
                        cartItem[position].wholesale = wholeSale;
                        cartItem[position].wholesalePer = wholesalePer;
                        if (ledgerModel != null) {
                          cartItem[position].supplierId = ledgerModel.id;
                          cartItem[position].supplier = ledgerModel.name;
                        }
                      } else {
                        cartItem.add(CartItemOP(
                            adCess: adCess,
                            barcode: barcode,
                            branch: branch,
                            branchPer: branchPer,
                            cDisc: cDisc,
                            cGST: csGST,
                            cdPer: cdPer,
                            cess: cess,
                            discount: discount,
                            discountPercent: discountPer,
                            expDate: expDate,
                            expense: expense,
                            fCess: fCess,
                            fUnitId: fUnitId,
                            fUnitValue: fUnitValue,
                            free: free,
                            gross: subTotal,
                            iGST: iGST,
                            id: cartItem.length + 1,
                            itemId: productModel.slNo,
                            itemName: productModel.itemName,
                            location: locationId,
                            mrp: mrp,
                            mrpPer: mrpPer,
                            net: net,
                            profitPer: profitPer,
                            quantity: quantity,
                            rRate: rRate,
                            rate: rate,
                            retail: retail,
                            retailPer: retailPer,
                            sGST: csGST,
                            serialNo: serialNo,
                            spRetail: spRetail,
                            spRetailPer: spRetailPer,
                            tax: tax,
                            taxP: taxP,
                            total: total,
                            uniqueCode: uniqueCode,
                            unitId: unit.id,
                            unitName: unit.name,
                            unitValue: unitValue,
                            wholesale: wholeSale,
                            wholesalePer: wholesalePer,
                            supplierId:
                                ledgerModel != null ? ledgerModel.id : 0,
                            supplier:
                                ledgerModel != null ? ledgerModel.name : ''));
                      }
                      if (cartItem.isNotEmpty) {
                        nextWidget = 3;
                        clearValue();
                        editItem = false;
                      }
                    });
                  },
                  child: Text(editItem ? "Edit" : "Add"),
                  color: blue,
                )),
              ],
            ),
            InkWell(
              child: SizedBox(
                width: deviceSize.width,
                height: 70,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 10,
                    child: Center(
                        child: Text(
                      ledgerModel != null
                          ? 'Supplier : ${ledgerModel.name}'
                          : 'Select Supplier',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                  ),
                ),
              ),
              onTap: () {
                setState(() {
                  nextWidget = 4;
                });
              },
            ),
            TextField(
              controller: controllerQuantity,
              focusNode: _focusNodeQuantity,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), label: Text('Quantity')),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              inputFormatters: [
                FilteringTextInputFormatter(RegExp(r'[0-9]'),
                    allow: true, replacementString: '.')
              ],
              onChanged: (value) {
                setState(() {
                  quantity = double.tryParse(value);
                  calculate();
                });
              },
            ),
            const Divider(),
            DropdownSearch<dynamic>(
              maxHeight: 300,
              onFind: (String filter) =>
                  dio.getSalesListData(filter, 'sales_list/unit'),
              dropdownSearchDecoration: const InputDecoration(
                  border: OutlineInputBorder(), label: Text('Select Unit')),
              onChanged: (dynamic data) {
                unit = data;
                calculate();
              },
              showSearchBox: true,
            ),
            const Divider(),
            TextField(
              controller: controllerRate,
              focusNode: _focusNodeRate,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), label: Text('P Rate')),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              inputFormatters: [
                FilteringTextInputFormatter(RegExp(r'[0-9]'),
                    allow: true, replacementString: '.')
              ],
              onChanged: (value) {
                setState(() {
                  rate = double.tryParse(value);
                  calculate();
                });
              },
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text('Subtotal :'),
                Text(subTotal.toStringAsFixed(decimal)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text('Discount'),
                SizedBox(
                  height: 30,
                  width: 50,
                  child: TextField(
                    controller: controllerDiscountPer,
                    focusNode: _focusNodeDiscountPer,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text(' % ')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        discountPer = double.tryParse(value);
                        calculate();
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 30,
                  width: 100,
                  child: TextField(
                    controller: controllerDiscount,
                    focusNode: _focusNodeDiscount,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('discount')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        discount = double.tryParse(value);
                        calculate();
                      });
                    },
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: 30,
                  width: 100,
                  child: TextField(
                    controller: controllerMrp,
                    focusNode: _focusNodeMrp,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('MRP')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        mrp = double.tryParse(value);
                        calculateRate();
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 30,
                  width: 100,
                  child: TextField(
                    controller: controllerRetail,
                    focusNode: _focusNodeRetail,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('Retail')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        retail = double.tryParse(value);
                        calculateRate();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 2,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: 30,
                  width: 100,
                  child: TextField(
                    controller: controllerWholeSale,
                    focusNode: _focusNodeWholeSale,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('WholeSale')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        wholeSale = double.tryParse(value);
                        calculateRate();
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 30,
                  width: 100,
                  child: TextField(
                    controller: controllerBranch,
                    focusNode: _focusNodeBranch,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('Branch')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        branch = double.tryParse(value);
                        calculateRate();
                      });
                    },
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net :'),
                Text(net.toStringAsFixed(decimal)),
              ],
            ),
            Visibility(
              visible: isTax,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isTax ? 'Tax ${taxP.toStringAsFixed(0)} % : ' : 'Tax :'),
                  Text(tax.toStringAsFixed(decimal)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  total.toStringAsFixed(decimal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool editItem = false;
  int position;

  cartProduct() {
    return Column(
      children: [
        purchaseHeaderWidget(),
        const Divider(
          height: 2.0,
          thickness: 2,
        ),
        Expanded(
          child: ListView.separated(
            itemCount: cartItem.length,
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(cartItem[index].itemName),
                subtitle: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Q:${cartItem[index].quantity}'),
                        Text(cartItem[index].unitName),
                        Text(
                            'R:${CommonService.getRound(decimal, cartItem[index].rate)}'),
                        Text(
                            ' = ${CommonService.getRound(decimal, cartItem[index].gross)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        cartItem[index].discount > 0
                            ? Text(
                                ' discount ${CommonService.getRound(decimal, cartItem[index].discount)}')
                            : Container(),
                        isTax
                            ? Text('Tax ${cartItem[index].tax}')
                            : Container(),
                        Text(
                          'total = ${CommonService.getRound(decimal, cartItem[index].total)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopUpMenuAction(
                  onDelete: () {
                    setState(() {
                      cartItem.removeAt(index);
                    });
                  },
                  onEdit: () {
                    setState(() {
                      editItem = true;
                      position = index;
                      nextWidget = 2;
                    });
                  },
                ),
              );
            },
          ),
        ),
        const Divider(
          height: 2,
          thickness: 2,
        ),
        footerWidget(),
      ],
    );
  }

  // TextEditingController cashPaidController = TextEditingController();
  footerWidget() {
    calculateTotal();
    return Container(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('GrandTotal : ',
                  style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
              Text(
                  totalCartTotal > 0
                      ? ComSettings.appSettings(
                              'bool', 'key-round-off-amount', false)
                          ? CommonService.getRound(decimal, totalCartTotal)
                              .toString()
                          : CommonService.getRound(decimal, totalCartTotal)
                              .roundToDouble()
                              .toString()
                      : ComSettings.appSettings(
                              'bool', 'key-round-off-amount', false)
                          ? CommonService.getRound(decimal, totalCartTotal)
                              .toString()
                          : CommonService.getRound(
                                  decimal, totalCartTotal.roundToDouble())
                              .toString(),
                  style: const TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red))
            ],
          ),
          const Divider(
            height: 1,
            thickness: 1,
          ),
        ],
      ),
    );
  }

  double totalGrossValue = 0,
      totalDiscount = 0,
      totalNet = 0,
      totalCess = 0,
      totalIgST = 0,
      totalCgST = 0,
      totalSgST = 0,
      totalFCess = 0,
      totalAdCess = 0,
      taxTotalCartValue = 0,
      totalCartTotal = 0,
      totalProfit = 0;
  calculateTotal() {
    totalGrossValue = 0;
    totalDiscount = 0;
    totalNet = 0;
    totalCess = 0;
    totalIgST = 0;
    totalCgST = 0;
    totalSgST = 0;
    totalFCess = 0;
    totalAdCess = 0;
    taxTotalCartValue = 0;
    totalCartTotal = 0;
    totalProfit = 0;
    for (var f in cartItem) {
      totalGrossValue += f.gross;
      totalDiscount += f.discount;
      totalNet += f.net;
      totalCess += f.cess;
      totalIgST += f.iGST;
      totalCgST += f.cGST;
      totalSgST += f.sGST;
      totalFCess += f.fCess;
      totalAdCess += f.adCess;
      taxTotalCartValue += f.tax;
      totalCartTotal += f.total;
      totalProfit += f.profitPer;
    }
    // totalCartValue =
    //     ComSettings.appSettings('bool', 'key-round-off-amount', false)
    //         ? totalCartValue
    //         : totalCartValue.roundToDouble();
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  clearValue() {
    controllerQuantity.text = '';
    controllerRate.text = '';
    controllerDiscountPer.text = '';
    controllerDiscount.text = '';
    controllerBranch.text = '';
    controllerMrp.text = '';
    controllerRetail.text = '';
    controllerWholeSale.text = '';
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
          fetchPurchase(context, dataDynamic);
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage:
            'Do you want to edit or delete\nRefNo:${dataDynamic['Id']}',
        title: 'Update',
        context: context);
  }

  fetchPurchase(context, data) {
    DioService api = DioService();
    double billTotal = 0, billCash = 0;
    String narration = ' ';

    api.fetchPurchaseInvoiceSp(data['Id'], 'OP_Find').then((value) {
      if (value != null) {
        var information = value['Information'][0];
        var particulars = value['Particulars'];
        // var serialNO = value['SerialNO'];
        // var deliveryNoteDetails = value['DeliveryNote'];

        formattedDate = DateUtil.dateDMY(information['DDate']);

        dataDynamic = [
          {
            'RealEntryNo': information['EntryNo'],
            'EntryNo': information['EntryNo'],
            'InvoiceNo': information['Sup_Inv'],
            'Type': '0'
          }
        ];

        billTotal = double.tryParse(information['GrandTotal'].toString());
        narration = information['Narration'];
        cartItem.clear();
        for (var product in particulars) {
          cartItem.add(CartItemOP(
              adCess: double.tryParse(product['adcess'].toString()),
              barcode: barcode,
              branch: double.tryParse(product['Branch'].toString()),
              branchPer: double.tryParse(product['branchp'].toString()),
              cDisc: double.tryParse(product['cdisc'].toString()),
              cGST: double.tryParse(product['CGST'].toString()),
              cdPer: double.tryParse(product['cdiscper'].toString()),
              cess: double.tryParse(product['cess'].toString()),
              discount: double.tryParse(product['Disc'].toString()),
              discountPercent:
                  double.tryParse(product['DiscPersent'].toString()),
              expDate: product['expDate'],
              expense: double.tryParse(product['Expenses'].toString()),
              fCess: double.tryParse(product['Fcess'].toString()),
              fUnitId: int.tryParse(product['Funit'].toString()),
              fUnitValue: double.tryParse(product['FValue'].toString()),
              free: double.tryParse(product['freeQty'].toString()),
              gross: double.tryParse(product['Total'].toString()),
              iGST: double.tryParse(product['IGST'].toString()),
              id: cartItem.length + 1,
              itemId: product['ItemId'],
              itemName: product['ProductName'],
              location: int.tryParse(product['Location'].toString()),
              mrp: double.tryParse(product['Mrp'].toString()),
              mrpPer: double.tryParse(product['Profit'].toString()),
              net: double.tryParse(product['Total'].toString()),
              profitPer: double.tryParse(product['Profit'].toString()),
              quantity: double.tryParse(product['Qty'].toString()),
              rRate: double.tryParse(product['RealPrate'].toString()),
              rate: double.tryParse(product['PRate'].toString()),
              retail: double.tryParse(product['Retail'].toString()),
              retailPer: double.tryParse(product['retailp'].toString()) ?? 0,
              sGST: double.tryParse(product['SGST'].toString()),
              serialNo: product['serialno'],
              spRetail: double.tryParse(product['Spretail'].toString()),
              spRetailPer: double.tryParse(product['spretailp'].toString()),
              tax: double.tryParse(product['IGST'].toString()),
              taxP: double.tryParse(product['tax'].toString()),
              total: double.tryParse(product['Total'].toString()),
              uniqueCode: product['UniqueCode'],
              unitId: product['Unit'],
              unitName: '',
              unitValue: double.tryParse(product['UnitValue'].toString()),
              wholesale: double.tryParse(product['WSrate'].toString()),
              wholesalePer: double.tryParse(product['wsalesp'].toString()),
              supplierId: product['Supplier'],
              supplier: product['LedName']));
        }
      }

      setState(() {
        widgetID = false;
        if (billCash > 0) {
          //
        }
        _narration = narration;
        nextWidget = 3;
        oldBill = true;
      });
    });
  }

  delete(context) {
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
          deleteData();
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage: 'Do you want to Delete',
        title: 'Delete Bill',
        context: context);
  }

  deleteData() {
    dio.deletePurchase(dataDynamic[0]['EntryNo'], 'OP_Delete').then((value) {
      setState(() {
        _isLoading = false;
      });
      if (value) {
        cartItem.clear();
        clearValue();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Expanded(
              child: AlertDialog(
                title: const Text('Opening Stock Deleted'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/openingStock');
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
}
