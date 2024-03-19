// @dart = 2.11
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/product_register_model.dart';
import 'package:sheraccerp/models/sales_model.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/util/show_confirm_alert_box.dart';
import 'package:sheraccerp/widget/components.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/popup_menu_action.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class Purchase extends StatefulWidget {
  final bool oldPurchase;
  const Purchase({Key key, @required this.oldPurchase}) : super(key: key);

  @override
  _PurchaseState createState() => _PurchaseState();
}

class _PurchaseState extends State<Purchase> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DioService api = DioService();
  CustomerModel ledgerModel, accountModel;
  DataJson ledgerDataModel, accountDataModel;
  CartItemP cartModel;
  ProductPurchaseModel productModel;
  List<dynamic> purchaseAccountList = [];
  DateTime now = DateTime.now();
  String formattedDate, invDate = '';
  double _balance = 0;
  List<dynamic> otherAmountList = [];
  bool isTax = true,
      _isCashBill = false,
      otherAmountLoaded = false,
      valueMore = false,
      _isLoading = false,
      widgetID = true,
      gstVerified = false,
      gstValidation = false,
      oldBill = false,
      lastRecord = false,
      isItemSerialNo = false,
      isFreeQty = false,
      isFreeItem = false,
      realPRateBasedProfitPercentage = false,
      mrpBasedProfit = false,
      isQuantityBasedSerialNo = false,
      isAccountLedger = false;
  List<CartItemP> cartItem = [];
  int page = 1, pageTotal = 0, totalRecords = 0, _dropDownUnit = 0;
  List<ProductPurchaseModel> itemDisplay = [];
  List<ProductPurchaseModel> items = [];
  List<SerialNOModel> serialNoData = [];
  bool enableMULTIUNIT = false,
      cessOnNetAmount = false,
      enableKeralaFloodCess = false,
      useUniqueCodeAaBarcode = false,
      useOldBarcode = false,
      buttonEvent = false,
      enableBarcode = false;
  int locationId = 1, salesManId = 0, decimal = 2;
  String labelSerialNo = 'SerialNo';

  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool ledgerScanner = false, productScanner = false, serialNoScanner = false;

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    invDate = DateFormat('dd-MM-yyyy').format(now);
    api.getPurchaseAC().then((value) {
      setState(() {
        purchaseAccountList.addAll(value);
      });
    });
    loadSettings();
    setCursorPosition();
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
    useUniqueCodeAaBarcode =
        ComSettings.getStatus('USE UNIQUECODE AS BARCODE', settings);
    useOldBarcode = ComSettings.getStatus('USE OLD BARCODE', settings);
    realPRateBasedProfitPercentage =
        ComSettings.getStatus('REAL PRATE BASED PROFIT PERCENTAGE', settings);
    mrpBasedProfit = ComSettings.getStatus('ENABLE MRP BASED PROFIT', settings);
    enableBarcode = ComSettings.getStatus('ENABLE BARCODE OPTION', settings);
    isItemSerialNo = ComSettings.getStatus('KEY ITEM SERIAL NO', settings);
    labelSerialNo =
        ComSettings.getValue('KEY ITEM SERIAL NO', settings).toString();
    labelSerialNo = labelSerialNo.isEmpty ? 'Remark' : labelSerialNo;
    salesManId = ComSettings.appSettings(
            'int', 'key-dropdown-default-salesman-view', 1) -
        1;
    locationId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;

    isFreeItem = ComSettings.getStatus('KEY FREE ITEM', settings);
    isFreeQty = ComSettings.getStatus('KEY FREE QTY IN PURCHASE', settings);
    isQuantityBasedSerialNo =
        ComSettings.getStatus('ENABLE QUANTITY BASED SERIAL NO', settings);
    if (widget.oldPurchase != null && widget.oldPurchase) {
      _isLoading = true;
      fetchPurchase(context, dataDynamic[0]);
      _isLoading = false;
    }
  }

  setCursorPosition() {
    // controllerQuantity.text = '';
    focusNodeQuantity.addListener(
      () {
        controllerQuantity.selection = TextSelection.fromPosition(
            TextPosition(offset: controllerQuantity.text.length));
      },
    );
    focusNodeRate.addListener(
      () {
        controllerRate.selection = TextSelection.fromPosition(
            TextPosition(offset: controllerRate.text.length));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: widgetID ? widgetPrefix() : widgetSuffix());
  }

  Future<bool> _onWillPop() async {
    if (nextWidget == 4) {
      return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Back'),
              content: const Text('Select Item Again?'),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      nextWidget = 3;
                      clearValue();
                    });
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Select'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          )) ??
          false;
    } else {
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
  }

  widgetSuffix() {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      appBar: AppBar(
        actions: [
          Visibility(
            visible: oldBill,
            child: IconButton(
                color: red,
                iconSize: 40,
                onPressed: () {
                  if (cartItem.isNotEmpty) {
                    setState(() {
                      _isLoading = true;
                    });
                    delete(context);
                  } else {
                    showInSnackBar('No items found on bill');
                  }
                },
                icon: const Icon(Icons.delete_forever)),
          ),
          oldBill
              ? IconButton(
                  color: green,
                  iconSize: 40,
                  onPressed: () async {
                    if (cartItem.isNotEmpty) {
                      if (buttonEvent) {
                        return;
                      } else {
                        if (companyUserData.updateData) {
                          setState(() {
                            _isLoading = true;
                            buttonEvent = true;
                          });
                          var inf = '[' +
                              json.encode({
                                'id': ledgerModel.id,
                                'name': ledgerModel.name,
                                'invNo': invNoController.text.isNotEmpty
                                    ? invNoController.text
                                    : '0',
                                'invDate': DateUtil.dateYMD(invDate)
                              }) +
                              ']';
                          var jsonItem = CartItemP.encodeCartToJson(cartItem);
                          var items = json.encode(jsonItem);
                          var stType = 'P_Update';
                          var data = '[' +
                              json.encode({
                                'entryNo': dataDynamic[0]['EntryNo'],
                                'date': DateUtil.dateYMD(formattedDate),
                                'grossValue': totalGrossValue,
                                'discount': totalDiscount,
                                'net': totalNet,
                                'cess': totalCess,
                                'total': totalCartTotal,
                                'otherCharges':
                                    _otherChargesController.text.isNotEmpty
                                        ? _otherChargesController.text
                                        : '0',
                                'otherDiscount':
                                    _otherDiscountController.text.isNotEmpty
                                        ? _otherDiscountController.text
                                        : '0',
                                'grandTotal': calculateGrandTotal(),
                                'taxType': isTax ? 'T' : 'N.T',
                                'purchaseAccount': purchaseAccountList[0]['id'],
                                'narration': _narrationController.text,
                                'type': 'P',
                                'cashPaid': cashPaidController.text.isNotEmpty
                                    ? cashPaidController.text
                                    : '0',
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
                            'particular': items,
                            'serialNoData': json.encode(
                                SerialNOModel.encodedToJson(serialNoData)),
                          };
                          bool _state = await api.addPurchase(body);
                          setState(() {
                            _isLoading = false;
                          });
                          if (_state) {
                            cartItem.clear();
                            showMore(context, 'Edited');
                          } else {
                            showInSnackBar('Error enter data correctly');
                            setState(() {
                              buttonEvent = false;
                            });
                          }
                        } else {
                          showInSnackBar('Permission denied\ncan`t edit');
                          setState(() {
                            buttonEvent = false;
                          });
                        }
                      }
                    } else {
                      showInSnackBar('Please add at least one item');
                    }
                  },
                  icon: const Icon(Icons.edit))
              : IconButton(
                  // color: w,
                  iconSize: 40,
                  onPressed: () async {
                    if (cartItem.isNotEmpty) {
                      if (buttonEvent) {
                        return;
                      } else {
                        if (companyUserData.insertData) {
                          setState(() {
                            _isLoading = true;
                            buttonEvent = true;
                          });
                          var inf = '[' +
                              json.encode({
                                'id': ledgerModel.id,
                                'name': ledgerModel.name,
                                'invNo': invNoController.text.isNotEmpty
                                    ? invNoController.text
                                    : '0',
                                'invDate': DateUtil.dateYMD(invDate)
                              }) +
                              ']';
                          var jsonItem = CartItemP.encodeCartToJson(cartItem);
                          var items = json.encode(jsonItem);
                          var stType = 'P_Insert';
                          var data = '[' +
                              json.encode({
                                'date': DateUtil.dateYMD(formattedDate),
                                'grossValue': totalGrossValue,
                                'discount': totalDiscount,
                                'net': totalNet,
                                'cess': totalCess,
                                'total': totalCartTotal,
                                'otherCharges':
                                    _otherChargesController.text.isNotEmpty
                                        ? _otherChargesController.text
                                        : '0',
                                'otherDiscount':
                                    _otherDiscountController.text.isNotEmpty
                                        ? _otherDiscountController.text
                                        : '0',
                                'grandTotal': calculateGrandTotal(),
                                'taxType': isTax ? 'T' : 'N.T',
                                'purchaseAccount': purchaseAccountList[0]['id'],
                                'narration': _narrationController.text,
                                'type': 'P',
                                'cashPaid': cashPaidController.text.isNotEmpty
                                    ? cashPaidController.text
                                    : '0',
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
                            'particular': items,
                            'serialNoData': json.encode(
                                SerialNOModel.encodedToJson(serialNoData)),
                          };
                          bool _state = await api.addPurchase(body);
                          setState(() {
                            _isLoading = false;
                          });
                          if (_state) {
                            cartItem.clear();
                            showMore(context, 'Saved');
                          } else {
                            showInSnackBar('Error enter data correctly');
                            setState(() {
                              buttonEvent = false;
                            });
                          }
                        } else {
                          showInSnackBar('Permission denied\ncan`t save');
                          setState(() {
                            buttonEvent = false;
                          });
                        }
                      }
                    } else {
                      showInSnackBar('Please add at least one item');
                    }
                  },
                  icon: const Icon(Icons.save)),
        ],
        title: const Text('Purchase'),
      ),
      body: ProgressHUD(
          inAsyncCall: _isLoading, opacity: 0.0, child: selectWidget()),
    );
  }

  widgetPrefix() {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        key: _scaffoldKey,
        appBar: AppBar(
          actions: [
            TextButton(
              child: const Text(
                " New ",
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
                searchBill(context);
              },
            ),
          ],
          title: const Text('Purchase'),
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
        var statement = 'PurchaseList';

        api
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
    focusNodeQuantity.dispose();
    focusNodeFreeQuantity.dispose();
    focusNodeRate.dispose();
    focusNodeDiscountPer.dispose();
    focusNodeDiscount.dispose();
    focusNodeMrp.dispose();
    focusNodeRetail.dispose();
    focusNodeWholeSale.dispose();
    focusNodeBranch.dispose();
    focusNodeSerialNo.dispose();
    controllerBranch.dispose();
    controllerDiscount.dispose();
    controllerDiscountPer.dispose();
    controllerFreeQuantity.dispose();
    controllerMrp.dispose();
    controllerQuantity.dispose();
    controllerRate.dispose();
    controllerRetail.dispose();
    controllerSerialNo.dispose();
    controllerWholeSale.dispose();
    cashPaidController.dispose();
    invNoController.dispose();
    newSerialNoController.dispose();

    super.dispose();
  }

  int nextWidget = 0;
  Widget selectWidget() {
    return nextWidget == 0
        ? baseWidget()
        : nextWidget == 1
            ? selectLedgerWidget()
            : nextWidget == 2
                ? selectLedgerDetailWidget()
                : nextWidget == 3
                    ? selectProductWidget()
                    : nextWidget == 4
                        ? itemDetails()
                        : nextWidget == 5
                            ? baseWidget()
                            : nextWidget == 10
                                ? serialNoWidget()
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
              const Text("No items in Purchase"),
              IconButton(
                  onPressed: () {
                    searchBill(context);
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
                  label: const Text('Take New Purchase'))
            ],
          ));
  }

  var nameLike = "a";
  selectLedgerWidget() {
    return FutureBuilder<List<dynamic>>(
      future: api.getSupplierListData(nameLike),
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
                            Flexible(
                              child: TextField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  label: Text('Search...'),
                                ),
                                onChanged: (text) {
                                  text = text.toLowerCase();
                                  setState(() {
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
                                    arguments: {'parent': 'SUPPLIERS'});
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
                            ledgerDataModel = data[index - 1];
                            nextWidget = 2;
                          });
                        },
                      );
              },
              itemCount: data.length + 1,
            );
          } else {
            return ListView(
              children: [
                Padding(
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
                              arguments: {'parent': 'SUPPLIERS'});
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('No Ledger Found..'),
                TextButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(kPrimaryColor),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                    onPressed: () {
                      setState(() {
                        nextWidget = 1;
                        nameLike = 'a';
                      });
                    },
                    child: const Text('Select again'))
              ],
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

    //   return FutureBuilder<List<dynamic>>(
    //     future: dio.getSalesListData('', 'sales_list/supplier'),
    //     builder: (ctx, snapshot) {
    //       if (snapshot.hasData) {
    //         if (snapshot.data.isNotEmpty) {
    //           var data = snapshot.data;
    //           if (!isData) {
    //             ledgerDisplay = data;
    //             _ledger = data;
    //           }
    //           return ListView.builder(
    //             // shrinkWrap: true,
    //             itemBuilder: (context, index) {
    //               return index == 0
    //                   ? Padding(
    //                       padding: const EdgeInsets.all(8.0),
    //                       child: Row(
    //                         children: [
    //                           Flexible(
    //                             child: TextField(
    //                               decoration: const InputDecoration(
    //                                 border: OutlineInputBorder(),label: Text( 'Search...'),
    //                               ),
    //                               onChanged: (text) {
    //                                 text = text.toLowerCase();
    //                                 setState(() {
    //                                   ledgerDisplay = _ledger.where((item) {
    //                                     var itemName = item.name.toLowerCase();
    //                                     return itemName.contains(text);
    //                                   }).toList();
    //                                 });
    //                               },
    //                             ),
    //                           ),
    //                           IconButton(
    //                             icon: const Icon(
    //                               Icons.add_circle,
    //                               color: kPrimaryColor,
    //                             ),
    //                             onPressed: () {
    //                               isData = false;
    //                               Navigator.pushNamed(context, '/ledger',
    //                                   arguments: {'parent': 'SUPPLIERS'});
    //                             },
    //                           )
    //                         ],
    //                       ),
    //                     )
    //                   : InkWell(
    //                       child: Card(
    //                         child: ListTile(
    //                             title: Text(ledgerDisplay[index - 1].name)),
    //                       ),
    //                       onTap: () {
    //                         setState(() {
    //                           ledgerModel = ledgerDisplay[index - 1];
    //                           nextWidget = 2;
    //                           isData = false;
    //                         });
    //                       },
    //                     );
    //             },
    //             itemCount: ledgerDisplay.length + 1,
    //           );
    //         } else {
    //           return Center(
    //             child: Column(
    //               mainAxisAlignment: MainAxisAlignment.center,
    //               children: const [SizedBox(height: 20), Text('No Data Found..')],
    //             ),
    //           );
    //         }
    //       } else if (snapshot.hasError) {
    //         return AlertDialog(
    //           title: const Text(
    //             'An Error Occurred!',
    //             textAlign: TextAlign.center,
    //             style: TextStyle(
    //               color: Colors.redAccent,
    //             ),
    //           ),
    //           content: Text(
    //             "${snapshot.error}",
    //             style: const TextStyle(
    //               color: Colors.blueAccent,
    //             ),
    //           ),
    //           actions: <Widget>[
    //             TextButton(
    //               child: const Text(
    //                 'Go Back',
    //                 style: TextStyle(
    //                   color: Colors.redAccent,
    //                 ),
    //               ),
    //               onPressed: () {
    //                 Navigator.of(context).pop();
    //               },
    //             )
    //           ],
    //         );
    //       }
    //       return Center(
    //         child: Column(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: const [
    //             CircularProgressIndicator(),
    //             SizedBox(height: 20),
    //             Text('This may take some time..')
    //           ],
    //         ),
    //       );
    //     },
    //   );
    // }
  }

  selectLedgerDetailWidget() {
    return FutureBuilder<CustomerModel>(
      future: api.getCustomerDetail(ledgerDataModel.id),
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
                          const SizedBox(
                            width: 40,
                          ),
                          const Text('Taxable'),
                          Checkbox(
                            value: taxablePurchase,
                            onChanged: (value) {
                              setState(() {
                                taxablePurchase = value;
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
                              nextWidget = 1;
                              nameLike = 'a';
                            });
                          },
                        ),
                        // Expanded(
                        //   child: TextField(
                        //     decoration: const InputDecoration(
                        //       border: OutlineInputBorder(),
                        //       label: Text('Supplier Name : '),
                        //     ),
                        //     onChanged: (value) {
                        //       setState(() {
                        //         supplierName = value.isNotEmpty
                        //             ? value.toUpperCase()
                        //             : 'CASH';
                        //       });
                        //     },
                        //   ),
                        // ),
                        doneButtonWidget(snapshot.data)
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const SizedBox(
                            width: 40,
                          ),
                          const Text('Taxable'),
                          Checkbox(
                            value: taxablePurchase,
                            onChanged: (value) {
                              setState(() {
                                taxablePurchase = value;
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
                              nextWidget = 1;
                              nameLike = 'a';
                            });
                          },
                        ),
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
                        doneButtonWidget(snapshot.data),
                        Visibility(
                          visible: false,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //       builder: (context) => PreviousBill(
                              //             ledger: ledgerModel.id.toString(),
                              //           )),
                              // );
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

  bool isItemData = false, isBarcodePicker = false;
  selectProductWidget() {
    setState(() {
      if (items.isNotEmpty) isItemData = true;
    });
    return isBarcodePicker
        ? showBarcodeProduct()
        : FutureBuilder<List<ProductPurchaseModel>>(
            future: api.fetchAllProductPurchase(),
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
                                    title:
                                        Text(itemDisplay[index - 1].itemName)),
                              ),
                              onTap: () {
                                setState(() {
                                  productModel = itemDisplay[index - 1];
                                  nextWidget = 4;
                                  isItemData = false;
                                });
                              },
                            );
                    },
                    itemCount: itemDisplay.length + 1,
                  );
                } else {
                  return ListView(children: [
                    Padding(
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
                                    var itemName = item.itemName.toLowerCase();
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
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(height: 20),
                          Text('No Data Item..')
                        ],
                      ),
                    ),
                  ]);
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

  // var itemLike = "a";
  // selectProductWidget() {
  //   return FutureBuilder<List<dynamic>>(
  //     future: dio.fetchProductPurchaseListLike(itemLike),
  //     builder: (ctx, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.done) {
  //         if (snapshot.hasData) {
  //           if (snapshot.data.isNotEmpty) {
  //             var data = snapshot.data;
  //             return ListView.builder(
  //               // shrinkWrap: true,
  //               itemBuilder: (context, index) {
  //                 return index == 0
  //                     ? Padding(
  //                         padding: const EdgeInsets.all(8.0),
  //                         child: Row(
  //                           children: [
  //                             Flexible(
  //                               child: TextField(
  //                                 decoration: const InputDecoration(
  //                                   border: OutlineInputBorder(),label: Text()'Search...'),
  //                                 ),
  //                                 onChanged: (text) {
  //                                   text = text.toLowerCase();
  //                                   setState(() {
  //                                     itemLike = text.isNotEmpty ? text : 'a';
  //                                   });
  //                                 },
  //                               ),
  //                             ),
  //                             IconButton(
  //                               icon: const Icon(
  //                                 Icons.add_circle,
  //                                 color: kPrimaryColor,
  //                               ),
  //                               onPressed: () {
  //                                 Navigator.pushNamed(context, '/product');
  //                               },
  //                             )
  //                           ],
  //                         ),
  //                       )
  //                     : InkWell(
  //                         child: Card(
  //                           child: ListTile(
  //                               title: Text(data[index - 1]['itemname'])),
  //                         ),
  //                         onTap: () {
  //                           setState(() {
  //                             productModel = data[index - 1];
  //                             nextWidget = 4;
  //                           });
  //                         },
  //                       );
  //               },
  //               itemCount: data.length + 1,
  //             );
  //           } else {
  //             return Center(
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: const [
  //                   SizedBox(height: 20),
  //                   Text('No Data Found..')
  //                 ],
  //               ),
  //             );
  //           }
  //         } else if (snapshot.hasError) {
  //           return AlertDialog(
  //             title: const Text(
  //               'An Error Occurred!',
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 color: Colors.redAccent,
  //               ),
  //             ),
  //             content: Text(
  //               "${snapshot.error}",
  //               style: const TextStyle(
  //                 color: Colors.blueAccent,
  //               ),
  //             ),
  //             actions: <Widget>[
  //               TextButton(
  //                 child: const Text(
  //                   'Go Back',
  //                   style: TextStyle(
  //                     color: Colors.redAccent,
  //                   ),
  //                 ),
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //               )
  //             ],
  //           );
  //         }
  //       }
  //       return Center(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: const [
  //             CircularProgressIndicator(),
  //             SizedBox(height: 20),
  //             Text('This may take some time..')
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  itemDetails() {
    int id = editItem ? cartModel.itemId : productModel.slNo;
    return itemFetchPrice(id);
    // return id > 0 ? itemFetchPrice(id) : itemFetchPrice(id);
  }

  bool lockItemDetails = false;

  itemFetchPrice(var id) {
    return lockItemDetails
        ? itemDetailWidget()
        : FutureBuilder(
            future: api.fetchProductPrize(id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data.length > 0) {
                    productModelPrize = snapshot.data[0];
                    lockItemDetails = true;
                    return itemDetailWidget();
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          const Text('Item Data Missing...'),
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  nextWidget = 3;
                                });
                              },
                              child: const Text('Select Product Again'))
                        ],
                      ),
                    );
                  }
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

  TextEditingController controllerQuantity = TextEditingController();
  TextEditingController controllerFreeQuantity = TextEditingController();
  TextEditingController controllerRate = TextEditingController();
  TextEditingController controllerDiscountPer = TextEditingController();
  TextEditingController controllerDiscount = TextEditingController();
  TextEditingController controllerMrp = TextEditingController();
  TextEditingController controllerMrpPercentage = TextEditingController();
  TextEditingController controllerRetail = TextEditingController();
  TextEditingController controllerRetailPercentage = TextEditingController();
  TextEditingController controllerSPRetail = TextEditingController();
  TextEditingController controllerSPRetailPercentage = TextEditingController();
  TextEditingController controllerWholeSale = TextEditingController();
  TextEditingController controllerWholeSalePercentage = TextEditingController();
  TextEditingController controllerBranch = TextEditingController();
  TextEditingController controllerBranchPercentage = TextEditingController();
  TextEditingController controllerSerialNo = TextEditingController();
  TextEditingController controllerGross = TextEditingController();
  TextEditingController controllerTotal = TextEditingController();
  FocusNode focusNodeQuantity = FocusNode();
  FocusNode focusNodeFreeQuantity = FocusNode();
  FocusNode focusNodeRate = FocusNode();
  FocusNode focusNodeDiscountPer = FocusNode();
  FocusNode focusNodeDiscount = FocusNode();
  FocusNode focusNodeMrp = FocusNode();
  FocusNode focusNodeMrpPercentage = FocusNode();
  FocusNode focusNodeRetail = FocusNode();
  FocusNode focusNodeRetailPercentage = FocusNode();
  FocusNode focusNodeSPRetail = FocusNode();
  FocusNode focusNodeSPRetailPercentage = FocusNode();
  FocusNode focusNodeWholeSale = FocusNode();
  FocusNode focusNodeWholeSalePercentage = FocusNode();
  FocusNode focusNodeBranch = FocusNode();
  FocusNode focusNodeBranchPercentage = FocusNode();
  FocusNode focusNodeSerialNo = FocusNode();
  FocusNode focusNodeGross = FocusNode();
  FocusNode focusNodeTotal = FocusNode();

  double quantity = 0,
      freeQuantity = 0,
      pRate = 0,
      grossTotal = 0,
      discount = 0,
      discountPer = 0,
      net = 0,
      tax = 0,
      total = 0,
      mrp = 0,
      retail = 0,
      spRetail = 0,
      wholeSale = 0,
      branch = 0,
      taxP = 0,
      rPRate = 0,
      rateOff = 0,
      kfcP = 0,
      fCess = 0,
      unitValue = 1,
      conversion = 0,
      fUnitValue = 0,
      cdPer = 0,
      cDisc = 0,
      cess = 0,
      cessPer = 0,
      adCessPer = 0,
      adCess = 0,
      iGST = 0,
      csGST = 0,
      expense = 0,
      mrpPercentage = 0,
      wholeSalePercentage = 0,
      retailPercentage = 0,
      spRetailPercentage = 0,
      branchPercentage = 0,
      _conversion = 0;
  String expDate = '1900-01-01', serialNo = '';
  DataJson unit;
  int uniqueCode = 0,
      fUnitId = 0,
      barcode = 0,
      brandId = 0,
      colorId = 0,
      companyId = 0,
      estUniqueCode = 0,
      expenseQty = 0,
      sizeValue = 0;
  bool editableRate = false,
      editableQuantity = false,
      editableFreeQuantity = false,
      editableDiscount = false,
      editableDiscountP = false;
  dynamic productModelPrize = [
    {'mrp': 0},
    {'retail': 0},
    {'wsrate': 0},
    {'spretail': 0},
    {'branch': 0},
    {'serialno': ''},
    {'prate': 0},
    {'realprate': 0},
    {'uniquecode': 0}
  ];

  itemDetailWidget() {
    if (editItem) {
      taxP = isTax ? cartItem.elementAt(position).taxP : 0;
      kfcP = isTax
          ? double.tryParse(cartItem.elementAt(position).fCess.toString())
          : 0;
      // adCessPer = isTax ? double.tryParse(productModel['adcessper'].toString());
      // cessPer = isTax ? double.tryParse(productModel['cessper'].toString());
      defaultUnitID = cartItem[position].unitId;
      uniqueCode = cartItem[position].uniqueCode;

      calculateTotal();
    } else {
      adCessPer = isTax ? productModel.adCessPer : 0;
      cessPer = isTax ? productModel.cessPer : 0;
      taxP = isTax ? productModel.tax : 0;
      kfcP =
          isTax ? 0 : 0; //double.tryParse(productModel['KFC'].toString()) : 0;
      pRate = double.tryParse(productModelPrize['prate'].toString());
      if (pRate > 0 && !editableRate) {
        controllerRate.text = pRate.toString();
      }
      if (double.tryParse(productModelPrize['realprate'].toString()) > 0) {
        rPRate = double.tryParse(productModelPrize['realprate'].toString());
      }
      mrp = double.tryParse(productModelPrize['mrp'].toString());
      if (mrp > 0 && !focusNodeMrp.hasFocus) {
        controllerMrp.text = mrp.toString();
      }
      retail = double.tryParse(productModelPrize['retail'].toString());
      if (retail > 0 && !focusNodeRetail.hasFocus) {
        controllerRetail.text = retail.toString();
      }
      wholeSale = double.tryParse(productModelPrize['wsrate'].toString());
      if (wholeSale > 0 && !focusNodeWholeSale.hasFocus) {
        controllerWholeSale.text = wholeSale.toString();
      }
      spRetail = double.tryParse(productModelPrize['spretail'].toString());
      branch = double.tryParse(productModelPrize['branch'].toString());
      if (branch > 0 && !focusNodeBranch.hasFocus) {
        controllerBranch.text = branch.toString();
      }
    }

    calculate() {
      quantity = controllerQuantity.text.isNotEmpty
          ? double.tryParse(controllerQuantity.text)
          : 0;
      freeQuantity = controllerFreeQuantity.text.isNotEmpty
          ? double.tryParse(controllerFreeQuantity.text)
          : 0;
      pRate = controllerRate.text.isNotEmpty
          ? double.tryParse(controllerRate.text)
          : 0;
      discount = controllerDiscount.text.isNotEmpty
          ? double.tryParse(controllerDiscount.text)
          : 0;
      double discP = controllerDiscountPer.text.isNotEmpty
          ? double.tryParse(controllerDiscountPer.text)
          : 0;
      double disc = controllerDiscount.text.isNotEmpty
          ? double.tryParse(controllerDiscount.text)
          : 0;
      double qt = controllerQuantity.text.isNotEmpty
          ? double.tryParse(controllerQuantity.text)
          : 0;
      double rate = controllerRate.text.isNotEmpty
          ? double.tryParse(controllerRate.text)
          : 0;

      rPRate = taxMethod == 'MINUS'
          ? cessOnNetAmount
              ? CommonService.getRound(
                  4, (100 * pRate) / (100 + taxP + kfcP + cessPer))
              : CommonService.getRound(4, (100 * pRate) / (100 + taxP + kfcP))
          : pRate;

      if (focusNodeDiscountPer.hasFocus) {
        controllerDiscount.text = controllerDiscountPer.text.isNotEmpty
            ? (((qt * rate) * discP) / 100).toStringAsFixed(2)
            : '';
        discount = controllerDiscount.text.isNotEmpty
            ? double.tryParse(controllerDiscount.text)
            : 0;
        discountPer = double.tryParse(controllerDiscountPer.text);
      }

      if (focusNodeDiscount.hasFocus) {
        controllerDiscountPer.text = controllerDiscount.text.isNotEmpty
            ? ((disc * 100) / (qt * rate)).toStringAsFixed(2)
            : '';
        discountPer = controllerDiscount.text.isNotEmpty
            ? double.tryParse(controllerDiscount.text)
            : 0;
        double.tryParse(controllerDiscount.text);
      }

      grossTotal = CommonService.getRound(decimal, (pRate * quantity));
      net = CommonService.getRound(decimal, (grossTotal - discount));
      if (taxP > 0) {
        tax = CommonService.getRound(decimal, ((net * taxP) / 100));
      }
      if (companyTaxMode == 'INDIA') {
        double csPer = taxP / 2;
        iGST = 0;
        csGST = CommonService.getRound(decimal, ((grossTotal * csPer) / 100));
      } else if (companyTaxMode == 'GULF') {
        iGST = CommonService.getRound(decimal, ((grossTotal * taxP) / 100));
        csGST = 0;
      } else {
        iGST = 0;
        csGST = 0;
        tax = 0;
      }
      total = CommonService.getRound(
          decimal, (net + csGST + csGST + iGST + cess + adCess));
      if (mrp > 0) {
        mrpPercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(decimal, (((mrp - rPRate) * 100) / rPRate))
            : CommonService.getRound(decimal, (((mrp - pRate) * 100) / pRate));
      }
      if (retail > 0) {
        retailPercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((retail - rPRate) * 100) / rPRate))
            : CommonService.getRound(
                decimal, (((retail - pRate) * 100) / pRate));
      }
      if (wholeSale > 0) {
        wholeSalePercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((wholeSale - rPRate) * 100) / rPRate))
            : CommonService.getRound(
                decimal, (((wholeSale - pRate) * 100) / pRate));
      }
      if (spRetail > 0) {
        spRetailPercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((spRetail - rPRate) * 100) / rPRate))
            : CommonService.getRound(
                decimal, (((spRetail - pRate) * 100) / pRate));
      }
      if (branch > 0) {
        branchPercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((branch - rPRate) * 100) / rPRate))
            : CommonService.getRound(
                decimal, (((branch - pRate) * 100) / pRate));
      }
      serialNo =
          controllerSerialNo.text.isNotEmpty ? controllerSerialNo.text : '';

      unitValue = _conversion > 0 ? _conversion : 1;
    }

    calculateRate() {
      mrp = controllerMrp.text.isNotEmpty
          ? double.tryParse(controllerMrp.text)
          : 0;
      mrpPercentage = controllerMrpPercentage.text.isNotEmpty
          ? double.tryParse(controllerMrpPercentage.text)
          : 0;
      retail = controllerRetail.text.isNotEmpty
          ? double.tryParse(controllerRetail.text)
          : 0;
      retailPercentage = controllerRetailPercentage.text.isNotEmpty
          ? double.tryParse(controllerRetailPercentage.text)
          : 0;
      spRetail = controllerSPRetail.text.isNotEmpty
          ? double.tryParse(controllerSPRetail.text)
          : 0;
      spRetailPercentage = controllerSPRetailPercentage.text.isNotEmpty
          ? double.tryParse(controllerSPRetailPercentage.text)
          : 0;
      wholeSale = controllerWholeSale.text.isNotEmpty
          ? double.tryParse(controllerWholeSale.text)
          : 0;
      wholeSalePercentage = controllerWholeSalePercentage.text.isNotEmpty
          ? double.tryParse(controllerWholeSalePercentage.text)
          : 0;
      branch = controllerBranch.text.isNotEmpty
          ? double.tryParse(controllerBranch.text)
          : 0;
      branchPercentage = controllerBranchPercentage.text.isNotEmpty
          ? double.tryParse(controllerBranchPercentage.text)
          : 0;
      pRate = controllerRate.text.isNotEmpty
          ? double.tryParse(controllerRate.text)
          : 0;
      if (mrp > 0) {
        if (focusNodeMrp.hasFocus) {
          double _num = 0;
          controllerMrpPercentage.text = mrpPercentage.toStringAsFixed(2);
          if (mrpBasedProfit && mrp > 0) {
            _num = CommonService.getRound(2, ((mrp - pRate) / mrp * 100));
            controllerMrpPercentage.text = _num.toStringAsFixed(2);
          } else if (realPRateBasedProfitPercentage && rPRate > 0) {
            _num = CommonService.getRound(2, ((mrp - rPRate) * 100) / rPRate);
            controllerMrpPercentage.text = _num.toStringAsFixed(2);
          } else if (pRate > 0) {
            _num = CommonService.getRound(2, ((mrp - pRate) * 100) / pRate);
            controllerMrpPercentage.text = _num.toStringAsFixed(2);
          }
          if (mrpBasedProfit) {
            int di = int.parse(mrpPercentage.toStringAsFixed(2));
            api.getOtherDataDiscountByName(di.toString()).then((value) {
              List<dynamic> dtDisc = [];
              if (dtDisc.isNotEmpty) {
                controllerRetailPercentage.text = dtDisc[0][0].toString();
              } else {
                controllerRetailPercentage.text = '';
              }
            });
          }
        }
      }
      if (focusNodeMrpPercentage.hasFocus) {
        mrpPercentage = controllerMrpPercentage.text.isNotEmpty
            ? double.tryParse(controllerMrpPercentage.text)
            : 0;
        if (realPRateBasedProfitPercentage) {
          mrp = CommonService.getRound(
              2, (rPRate + rPRate * mrpPercentage / 100));
          controllerMrp.text = mrp.toStringAsFixed(2);
        } else if (mrpBasedProfit) {
          // textboxValue = WsPer;
          // string ptp = textboxValue.ToString();
          // textboxValue = (mrp * ptp) / 100;
          // string str = textboxValue.ToString();
          // textboxValue = mrp - str;
          // this.txtWsrate.Text = str;
        } else {
          mrp =
              CommonService.getRound(2, (pRate + pRate * mrpPercentage / 100));
          controllerMrp.text = mrp.toString();
          controllerRetail.text = controllerRetail.text.isEmpty
              ? mrp.toString()
              : controllerRetail.text;
          controllerWholeSale.text = controllerWholeSale.text.isEmpty
              ? mrp.toString()
              : controllerWholeSale.text;
          controllerSPRetail.text = controllerSPRetail.text.isEmpty
              ? mrp.toString()
              : controllerSPRetail.text;
          controllerBranch.text = controllerBranch.text.isEmpty
              ? mrp.toString()
              : controllerBranch.text;
        }
      }
      if (retail > 0) {
        retailPercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(2, (((retail - rPRate) * 100) / rPRate))
            : CommonService.getRound(2, (((retail - pRate) * 100) / pRate));
        if (focusNodeRetail.hasFocus) {
          controllerRetailPercentage.text = retailPercentage.toStringAsFixed(2);
        }
      }
      if (wholeSale > 0) {
        wholeSalePercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(2, (((wholeSale - rPRate) * 100) / rPRate))
            : CommonService.getRound(2, (((wholeSale - pRate) * 100) / pRate));
        if (focusNodeWholeSale.hasFocus) {
          controllerWholeSalePercentage.text =
              wholeSalePercentage.toStringAsFixed(2);
        }
      }
      if (spRetail > 0) {
        spRetailPercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(2, (((spRetail - rPRate) * 100) / rPRate))
            : CommonService.getRound(2, (((spRetail - pRate) * 100) / pRate));
        if (focusNodeSPRetail.hasFocus) {
          controllerSPRetailPercentage.text =
              spRetailPercentage.toStringAsFixed(2);
        }
      }
      if (branch > 0) {
        branchPercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(2, (((branch - rPRate) * 100) / rPRate))
            : CommonService.getRound(2, (((branch - pRate) * 100) / pRate));
        if (focusNodeBranch.hasFocus) {
          controllerBranchPercentage.text = branchPercentage.toStringAsFixed(2);
        }
      }
    }

    List<UnitModel> unitListData = [];
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    editItem
                        ? cartItem.elementAt(position).itemName
                        : productModel.itemName,
                    style: const TextStyle(color: Colors.red))),
            Row(
              children: [
                Expanded(
                    child: MaterialButton(
                  onPressed: () {
                    setState(() {
                      editItem = false;
                      nextWidget = 3;
                      clearValue();
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
                      editItem = false;
                      nextWidget = 5;
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
                    if (isFreeItem) {
                      setState(() {
                        unit ??= DataJson(id: 0, name: '');
                        pRate = controllerRate.text.isNotEmpty
                            ? double.tryParse(controllerRate.text)
                            : pRate;
                        discount = controllerDiscount.text.isNotEmpty
                            ? double.tryParse(controllerDiscount.text)
                            : discount;
                        discountPer = controllerDiscountPer.text.isNotEmpty
                            ? double.tryParse(controllerDiscountPer.text)
                            : discountPer;
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
                        freeQuantity = controllerFreeQuantity.text.isNotEmpty
                            ? double.tryParse(controllerFreeQuantity.text)
                            : freeQuantity;
                        serialNo = controllerSerialNo.text.isNotEmpty
                            ? controllerFreeQuantity.text
                            : '';

                        if (editItem) {
                          cartItem[position].adCess = adCess;
                          cartItem[position].barcode = barcode;
                          cartItem[position].branch = branch;
                          cartItem[position].branchPer = branchPercentage;
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
                          cartItem[position].free = freeQuantity;
                          cartItem[position].gross = grossTotal;
                          cartItem[position].iGST = iGST;
                          // cartItem[position].id = cartItem.length + 1;
                          // cartItem[position].itemId = productModel['slno'];
                          // cartItem[position].itemName = productModel['itemname'];
                          // cartItem[position].location = locationId;
                          cartItem[position].mrp = mrp;
                          cartItem[position].mrpPer = mrpPercentage;
                          cartItem[position].net = net;
                          cartItem[position].profitPer = mrpPercentage;
                          cartItem[position].quantity = quantity;
                          cartItem[position].rRate = rPRate;
                          cartItem[position].rate = pRate;
                          cartItem[position].retail = retail;
                          cartItem[position].retailPer = retailPercentage;
                          cartItem[position].sGST = csGST;
                          cartItem[position].serialNo = serialNo;
                          cartItem[position].spRetail = spRetail;
                          cartItem[position].spRetailPer = spRetailPercentage;
                          cartItem[position].tax = tax;
                          cartItem[position].taxP = taxP;
                          cartItem[position].total = total;
                          cartItem[position].uniqueCode = uniqueCode;
                          cartItem[position].unitId = unit.id;
                          cartItem[position].unitName = unit.name;
                          cartItem[position].unitValue = unitValue;
                          cartItem[position].wholesale = wholeSale;
                          cartItem[position].wholesalePer = wholeSalePercentage;
                          cartItem[position].brand = brandId;
                          cartItem[position].color = colorId;
                          cartItem[position].company = companyId;
                          cartItem[position].estUniqueCode = estUniqueCode;
                          cartItem[position].expenseQty = expenseQty;
                          cartItem[position].size = sizeValue;
                        } else {
                          cartItem.add(CartItemP(
                              adCess: adCess,
                              barcode: barcode,
                              branch: branch,
                              branchPer: branchPercentage,
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
                              free: freeQuantity,
                              gross: grossTotal,
                              iGST: iGST,
                              id: cartItem.length + 1,
                              itemId: productModel.slNo,
                              itemName: productModel.itemName,
                              location: locationId,
                              mrp: mrp,
                              mrpPer: mrpPercentage,
                              net: net,
                              profitPer: mrpPercentage,
                              quantity: quantity,
                              rRate: rPRate,
                              rate: pRate,
                              retail: retail,
                              retailPer: retailPercentage,
                              sGST: csGST,
                              serialNo: serialNo,
                              spRetail: spRetail,
                              spRetailPer: spRetailPercentage,
                              tax: tax,
                              taxP: taxP,
                              total: total,
                              uniqueCode: uniqueCode,
                              unitId: unit.id,
                              unitName: unit.name,
                              unitValue: unitValue,
                              wholesale: wholeSale,
                              wholesalePer: wholeSalePercentage,
                              brand: brandId,
                              color: colorId,
                              company: companyId,
                              estUniqueCode: estUniqueCode,
                              expenseQty: expenseQty,
                              size: sizeValue));
                        }

                        if (cartItem.isNotEmpty) {
                          editItem = false;
                          nextWidget = 5;
                          clearValue();
                        }
                      });
                    } else if (total > 0) {
                      setState(() {
                        unit ??= DataJson(id: 0, name: '');
                        pRate = controllerRate.text.isNotEmpty
                            ? double.tryParse(controllerRate.text)
                            : pRate;
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
                        freeQuantity = controllerFreeQuantity.text.isNotEmpty
                            ? double.tryParse(controllerFreeQuantity.text)
                            : freeQuantity;

                        if (editItem) {
                          cartItem[position].adCess = adCess;
                          cartItem[position].barcode = barcode;
                          cartItem[position].branch = branch;
                          cartItem[position].branchPer = branchPercentage;
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
                          cartItem[position].free = freeQuantity;
                          cartItem[position].gross = grossTotal;
                          cartItem[position].iGST = iGST;
                          // cartItem[position].id = cartItem.length + 1;
                          // cartItem[position].itemId = productModel['slno'];
                          // cartItem[position].itemName = productModel['itemname'];
                          // cartItem[position].location = locationId;
                          cartItem[position].mrp = mrp;
                          cartItem[position].mrpPer = mrpPercentage;
                          cartItem[position].net = net;
                          cartItem[position].profitPer = mrpPercentage;
                          cartItem[position].quantity = quantity;
                          cartItem[position].rRate = rPRate;
                          cartItem[position].rate = pRate;
                          cartItem[position].retail = retail;
                          cartItem[position].retailPer = retailPercentage;
                          cartItem[position].sGST = csGST;
                          cartItem[position].serialNo = serialNo;
                          cartItem[position].spRetail = spRetail;
                          cartItem[position].spRetailPer = spRetailPercentage;
                          cartItem[position].tax = tax;
                          cartItem[position].taxP = taxP;
                          cartItem[position].total = total;
                          cartItem[position].uniqueCode = uniqueCode;
                          cartItem[position].unitId = unit.id;
                          cartItem[position].unitName = unit.name;
                          cartItem[position].unitValue = unitValue;
                          cartItem[position].wholesale = wholeSale;
                          cartItem[position].wholesalePer = wholeSalePercentage;
                        } else {
                          cartItem.add(CartItemP(
                              adCess: adCess,
                              barcode: barcode,
                              branch: branch,
                              branchPer: branchPercentage,
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
                              free: freeQuantity,
                              gross: grossTotal,
                              iGST: iGST,
                              id: cartItem.length + 1,
                              itemId: productModel.slNo,
                              itemName: productModel.itemName,
                              location: locationId,
                              mrp: mrp,
                              mrpPer: mrpPercentage,
                              net: net,
                              profitPer: mrpPercentage,
                              quantity: quantity,
                              rRate: rPRate,
                              rate: pRate,
                              retail: retail,
                              retailPer: retailPercentage,
                              sGST: csGST,
                              serialNo: serialNo,
                              spRetail: spRetail,
                              spRetailPer: spRetailPercentage,
                              tax: tax,
                              taxP: taxP,
                              total: total,
                              uniqueCode: uniqueCode,
                              unitId: unit.id,
                              unitName: unit.name,
                              unitValue: unitValue,
                              wholesale: wholeSale,
                              wholesalePer: wholeSalePercentage,
                              brand: brandId,
                              color: colorId,
                              company: companyId,
                              estUniqueCode: estUniqueCode,
                              expenseQty: expenseQty,
                              size: sizeValue));
                        }
                        if (cartItem.isNotEmpty) {
                          editItem = false;
                          nextWidget = 5;
                          clearValue();
                        }
                      });
                    } else {
                      if (!isFreeItem) {
                        if (quantity <= 0) {
                          showWarningAlertBox(context, 'Fill data quantity',
                              '0 quantity not allowed');
                        } else if (pRate <= 0) {
                          showWarningAlertBox(
                              context, 'Fill data rate', '0 rate not allowed');
                        } else {
                          showWarningAlertBox(
                              context, 'Fill data rate', '0 rate not allowed');
                        }
                      }
                    }
                  },
                  child: Text(editItem ? "Edit" : "Add"),
                  color: blue,
                )),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    textAlign: TextAlign.right,
                    controller: controllerQuantity,
                    focusNode: focusNodeQuantity,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('Quantity')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        editableQuantity = true;
                        quantity = double.tryParse(value);
                        calculate();
                      });
                    },
                  ),
                ),
                Visibility(
                  visible: isFreeQty,
                  child: Expanded(
                    child: TextField(
                      controller: controllerFreeQuantity,
                      focusNode: focusNodeFreeQuantity,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text('Free Qty')),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp(r'[0-9]'),
                            allow: true, replacementString: '.')
                      ],
                      onChanged: (value) {
                        setState(() {
                          editableFreeQuantity = true;
                          freeQuantity = double.tryParse(value);
                          calculate();
                        });
                      },
                    ),
                  ),
                ),
                Visibility(
                  visible: enableMULTIUNIT,
                  child: Expanded(
                    child: Card(
                      color: blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: FutureBuilder(
                          future: api.fetchUnitOf(editItem
                              ? cartItem[position].itemId
                              : productModel.slNo),
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.hasData) {
                              unitListData.clear();
                              for (var i = 0; i < snapshot.data.length; i++) {
                                if (defaultUnitID.toString().isNotEmpty) {
                                  if (snapshot.data[i].id ==
                                      defaultUnitID - 1) {
                                    _dropDownUnit = snapshot.data[i].id;
                                    _conversion = snapshot.data[i].conversion;
                                    unit = DataJson(
                                        id: snapshot.data[i].id,
                                        name: snapshot.data[i].name);
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
                                    rate: snapshot.data[i].pRate));
                              }
                            }
                            return snapshot.data != null &&
                                    snapshot.data.length > 0
                                ? DropdownButton<String>(
                                    hint: Text(_dropDownUnit > 0
                                        ? UnitSettings.getUnitName(
                                            _dropDownUnit)
                                        : 'Unit'),
                                    items: snapshot.data
                                        .map<DropdownMenuItem<String>>((item) {
                                      return DropdownMenuItem<String>(
                                        value: item.id.toString(),
                                        child: Text(item.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _dropDownUnit = int.tryParse(value);
                                        // for (var i = 0;
                                        //     i < unitListData.length;
                                        //     i++) {
                                        UnitModel _unit =
                                            unitListData.firstWhere((element) =>
                                                element.id == _dropDownUnit);
                                        // if (_unit.unit == int.tryParse(value)) {
                                        // if (_unit.rate.isNotEmpty) {
                                        // rateTypeItem = rateTypeList
                                        //     .firstWhere((element) =>
                                        //         element.name ==
                                        //         _unit.rate);
                                        // }
                                        _conversion = _unit.conversion;
                                        unit = DataJson(
                                            id: _unit.id, name: _unit.name);
                                        // break;
                                        // }
                                        // }
                                        calculate();
                                      });
                                    },
                                  )
                                : DropdownButton<String>(
                                    hint: Text(_dropDownUnit > 0
                                        ? UnitSettings.getUnitName(
                                            _dropDownUnit)
                                        : 'Unit'),
                                    items: unitList
                                        .map<DropdownMenuItem<String>>((item) {
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
                                        unit = DataJson(
                                            id: _dropDownUnit,
                                            name: UnitSettings.getUnitName(
                                                _dropDownUnit));
                                      });
                                    },
                                  );
                          },
                        ),
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
            const Divider(height: 5),
            Visibility(
              visible: isItemSerialNo,
              child: Row(
                children: [
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: TextField(
                      controller: controllerSerialNo,
                      focusNode: focusNodeSerialNo,
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText:
                              isItemSerialNo ? labelSerialNo : 'SerialNo'),
                      onChanged: (value) {
                        setState(() {
                          calculate();
                        });
                      },
                    ),
                  )),
                  Visibility(
                      visible: editItem
                          ? (isQuantityBasedSerialNo)
                          : (isQuantityBasedSerialNo && productModel.serialNo),
                      child: ElevatedButton(
                        child:
                            Text(editItem ? 'Edit SerialNo' : 'Add SerialNo'),
                        onPressed: () {
                          if (controllerQuantity.text.isNotEmpty) {
                            setState(() {
                              nextWidget = 10;
                            });
                          }
                        },
                      )),
                ],
              ),
            ),
            const Divider(height: 5),
            // DropdownSearch<dynamic>(
            //   maxHeight: 300,
            //   onFind: (String filter) =>
            //       dio.getSalesListData(filter, 'sales_list/unit'),
            //   dropdownSearchDecoration: const InputDecoration(
            //       border: OutlineInputBorder(), label: Text('Select Unit')),
            //   onChanged: (dynamic data) {
            //     unit = data;
            //     calculate();
            //   },
            //   showSearchBox: true,
            // ),
            Row(
              children: [
                Expanded(
                  // height: 50,
                  // width: 100,
                  child: TextField(
                    controller: controllerRate,
                    focusNode: focusNodeRate,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('P Rate')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        editableRate = true;
                        pRate = double.tryParse(value);
                        calculate();
                      });
                    },
                  ),
                ),
                Card(
                  color: blue.shade50,
                  child: SizedBox(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text('Gross ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        VerticalDivider(
                          width: 10,
                          thickness: 1,
                          color: grey.shade400,
                        ),
                        InkWell(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                              side: const BorderSide(
                                  style: BorderStyle.solid,
                                  width: 1,
                                  strokeAlign: StrokeAlign.outside),
                            ),
                            child: SizedBox(
                                height: 50,
                                width: 100,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    grossTotal.toStringAsFixed(decimal),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    textAlign: TextAlign.right,
                                  ),
                                )),
                          ),
                          onTap: () {
                            controllerGross.text =
                                grossTotal.toStringAsFixed(decimal);
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    TextField(
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter(
                                            RegExp(r'[0-9]'),
                                            allow: true,
                                            replacementString: '.')
                                      ],
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Gross Amount',
                                          labelText: 'Enter gross amount'),
                                      controller: controllerGross,
                                      autofocus: true,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        setState(() {
                                          calculateGross(controllerGross.text);
                                        });
                                      },
                                      child: const Text("Done"),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // const Divider(),
            // const SizedBox(
            //   height: 5,
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Disc'),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              height: 40,
                              width: 70,
                              child: TextField(
                                controller: controllerDiscountPer,
                                focusNode: focusNodeDiscountPer,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    label: Text(' % ')),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                      allow: true, replacementString: '.')
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    editableDiscountP = true;
                                    discountPer = double.tryParse(value);
                                    calculate();
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              width: 100,
                              child: TextField(
                                controller: controllerDiscount,
                                focusNode: focusNodeDiscount,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    label: Text('Discount')),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                      allow: true, replacementString: '.')
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    editableDiscount = true;
                                    discount = double.tryParse(value);
                                    calculate();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: firebaseGrey,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Net             ',
                              textAlign: TextAlign.start,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          VerticalDivider(
                            width: 30,
                            thickness: 1,
                            color: grey.shade400,
                          ),
                          const SizedBox(
                            width: 3,
                          ),
                          Text(net.toStringAsFixed(decimal),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Visibility(
              visible: isTax,
              child: Card(
                color: firebaseGrey,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                            '${(companyTaxMode == 'INDIA' ? 'GST' : companyTaxMode == 'GULF' ? 'VAT' : 'Tax')} ${taxP.toStringAsFixed(0)} % ',
                            textAlign: TextAlign.start,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        VerticalDivider(
                          width: 50,
                          thickness: 0.8,
                          color: grey.shade400,
                        ),
                        Text(tax.toStringAsFixed(decimal),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Card(
              color: blue.shade50,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Total              ',
                        textAlign: TextAlign.start,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      VerticalDivider(
                        width: 10,
                        thickness: 0.8,
                        color: grey.shade400,
                      ),
                      InkWell(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: const BorderSide(
                                style: BorderStyle.solid,
                                width: 1,
                                strokeAlign: StrokeAlign.outside),
                          ),
                          child: SizedBox(
                            height: 50,
                            width: 100,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                total.toStringAsFixed(decimal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ),
                        onTap: () {
                          controllerTotal.text = total.toStringAsFixed(decimal);
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) => Padding(
                              padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom),
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),
                                  TextField(
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter(
                                          RegExp(r'[0-9]'),
                                          allow: true,
                                          replacementString: '.')
                                    ],
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Total Amount',
                                        labelText: 'Enter total amount'),
                                    controller: controllerTotal,
                                    autofocus: true,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      setState(() {
                                        calculateTotalValue(
                                            controllerTotal.text);
                                      });
                                    },
                                    child: const Text("Done"),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text('MRP',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              height: 30,
                              width: 75,
                              child: TextField(
                                controller: controllerMrpPercentage,
                                focusNode: focusNodeMrpPercentage,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    label: Text('%')),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                      allow: true, replacementString: '.')
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    mrpPercentage = double.tryParse(value);
                                    calculateRate();
                                  });
                                },
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                              width: 100,
                              child: TextField(
                                controller: controllerMrp,
                                focusNode: focusNodeMrp,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    label: Text('MRP')),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text('Retail',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              height: 30,
                              width: 75,
                              child: TextField(
                                controller: controllerRetailPercentage,
                                focusNode: focusNodeRetailPercentage,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    label: Text('%')),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                      allow: true, replacementString: '.')
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    retailPercentage = double.tryParse(value);
                                    calculateRate();
                                  });
                                },
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                              width: 100,
                              child: TextField(
                                controller: controllerRetail,
                                focusNode: focusNodeRetail,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    label: Text('Retail')),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 3),
                            child: Text('WholeSale',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                height: 30,
                                width: 75,
                                child: TextField(
                                  controller: controllerWholeSalePercentage,
                                  focusNode: focusNodeWholeSalePercentage,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      label: Text('%')),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter(
                                        RegExp(r'[0-9]'),
                                        allow: true,
                                        replacementString: '.')
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      wholeSalePercentage =
                                          double.tryParse(value);
                                      calculateRate();
                                    });
                                  },
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                width: 100,
                                child: TextField(
                                  controller: controllerWholeSale,
                                  focusNode: focusNodeWholeSale,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      label: Text('WholeSale')),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter(
                                        RegExp(r'[0-9]'),
                                        allow: true,
                                        replacementString: '.')
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      wholeSale = double.tryParse(value);
                                      calculateRate();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ]),
                  ),
                ),
                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 3),
                            child: Text('Branch',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                height: 30,
                                width: 75,
                                child: TextField(
                                  controller: controllerBranchPercentage,
                                  focusNode: focusNodeBranchPercentage,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      label: Text('%')),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter(
                                        RegExp(r'[0-9]'),
                                        allow: true,
                                        replacementString: '.')
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      branchPercentage = double.tryParse(value);
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
                                  focusNode: focusNodeBranch,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      label: Text('Branch')),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter(
                                        RegExp(r'[0-9]'),
                                        allow: true,
                                        replacementString: '.')
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      branch = double.tryParse(value);
                                      calculateRate();
                                    });
                                  },
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ]),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('Special Retail',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            height: 40,
                            width: 120,
                            child: TextField(
                              controller: controllerSPRetailPercentage,
                              focusNode: focusNodeSPRetailPercentage,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  label: Text(' % ')),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                    allow: true, replacementString: '.')
                              ],
                              onChanged: (value) {
                                setState(() {
                                  branchPercentage = double.tryParse(value);
                                  calculateRate();
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            width: 120,
                            child: TextField(
                              controller: controllerSPRetail,
                              focusNode: focusNodeSPRetail,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  label: Text('Special Retail')),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
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
                    ]),
              ),
            )
          ],
        ),
      ),
    );
  }

  calculateGross(String grossValue) {
    quantity = controllerQuantity.text.isNotEmpty
        ? double.tryParse(controllerQuantity.text)
        : 0;
    if (quantity > 0 || grossValue.isNotEmpty) {
      pRate = controllerRate.text.isNotEmpty
          ? double.tryParse(controllerRate.text)
          : 0;
      grossTotal = double.parse(grossValue);
      pRate = grossTotal / quantity;
      controllerRate.text = pRate.toStringAsFixed(2);
      rPRate = taxMethod == 'MINUS'
          ? cessOnNetAmount
              ? CommonService.getRound(
                  4, (100 * pRate) / (100 + taxP + kfcP + cessPer))
              : CommonService.getRound(4, (100 * pRate) / (100 + taxP + kfcP))
          : pRate;

      net = CommonService.getRound(decimal, (grossTotal - discount));
      if (taxP > 0) {
        tax = CommonService.getRound(decimal, ((net * taxP) / 100));
      }
      if (companyTaxMode == 'INDIA') {
        double csPer = taxP / 2;
        iGST = 0;
        csGST = CommonService.getRound(decimal, ((grossTotal * csPer) / 100));
      } else if (companyTaxMode == 'GULF') {
        iGST = CommonService.getRound(decimal, ((grossTotal * taxP) / 100));
        csGST = 0;
      } else {
        iGST = 0;
        csGST = 0;
        tax = 0;
      }
      total = CommonService.getRound(
          decimal, (net + csGST + csGST + iGST + cess + adCess));
      if (mrp > 0) {
        mrpPercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(decimal, (((mrp - rPRate) * 100) / rPRate))
            : CommonService.getRound(decimal, (((mrp - pRate) * 100) / pRate));
      }
      if (retail > 0) {
        retailPercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((retail - rPRate) * 100) / rPRate))
            : CommonService.getRound(
                decimal, (((retail - pRate) * 100) / pRate));
      }
      if (wholeSale > 0) {
        wholeSalePercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((wholeSale - rPRate) * 100) / rPRate))
            : CommonService.getRound(
                decimal, (((wholeSale - pRate) * 100) / pRate));
      }
      if (spRetail > 0) {
        spRetailPercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((spRetail - rPRate) * 100) / rPRate))
            : CommonService.getRound(
                decimal, (((spRetail - pRate) * 100) / pRate));
      }
      if (branch > 0) {
        branchPercentage = realPRateBasedProfitPercentage
            ? CommonService.getRound(
                decimal, (((branch - rPRate) * 100) / rPRate))
            : CommonService.getRound(
                decimal, (((branch - pRate) * 100) / pRate));
      }
      serialNo =
          controllerSerialNo.text.isNotEmpty ? controllerSerialNo.text : '';

      unitValue = _conversion > 0 ? _conversion : 1;
    }
  }

  calculateTotalValue(totalValue) {
    quantity = controllerQuantity.text.isNotEmpty
        ? double.tryParse(controllerQuantity.text)
        : 0;
    if (quantity > 0 || totalValue.isNotEmpty) {
      pRate = controllerRate.text.isNotEmpty
          ? double.tryParse(controllerRate.text)
          : 0;
      double totalAmount = double.parse(totalValue);
      grossTotal =
          CommonService.getRound(2, ((totalAmount * 100) / (100 + taxP)));

      if (controllerDiscount.text.isNotEmpty) {
        discount = double.parse(controllerDiscount.text);
      } else if (controllerDiscountPer.text.isNotEmpty) {
        discountPer = double.parse(controllerDiscountPer.text);
      }

      double _totalValue = grossTotal;
      String tak1 = _totalValue.toStringAsFixed(2);
      _totalValue = CommonService.getRound(2, double.parse(tak1) + discount);
      grossTotal = _totalValue;
      tak1 = _totalValue.toStringAsFixed(2);
      _totalValue = double.parse(tak1) / (quantity);
      controllerRate.text = _totalValue.toStringAsFixed(2);
      pRate = controllerRate.text.isNotEmpty
          ? double.tryParse(controllerRate.text)
          : 0;

      // String textTotal =
      //     ((grossTotal + discount) / discount).toStringAsFixed(2);
      // pRate = double.parse(textTotal);
      // controllerRate.text = pRate.toStringAsFixed(2);

      freeQuantity = controllerFreeQuantity.text.isNotEmpty
          ? double.tryParse(controllerFreeQuantity.text)
          : 0;

      discount = controllerDiscount.text.isNotEmpty
          ? double.tryParse(controllerDiscount.text)
          : 0;
      double discP = controllerDiscountPer.text.isNotEmpty
          ? double.tryParse(controllerDiscountPer.text)
          : 0;
      double disc = controllerDiscount.text.isNotEmpty
          ? double.tryParse(controllerDiscount.text)
          : 0;
      double qt = controllerQuantity.text.isNotEmpty
          ? double.tryParse(controllerQuantity.text)
          : 0;

      rPRate = taxMethod == 'MINUS'
          ? cessOnNetAmount
              ? CommonService.getRound(
                  4, (100 * pRate) / (100 + taxP + kfcP + cessPer))
              : CommonService.getRound(4, (100 * pRate) / (100 + taxP + kfcP))
          : pRate;

      if (disc > 0) {
        discountPer =
            double.parse(((disc * 100) / (qt * pRate)).toStringAsFixed(2));
        controllerDiscountPer.text = discountPer.toStringAsFixed(2);
        discount = disc;
      }

      net = CommonService.getRound(decimal, (grossTotal - discount));
      if (taxP > 0) {
        tax = CommonService.getRound(decimal, ((net * taxP) / 100));
      }
      if (companyTaxMode == 'INDIA') {
        double csPer = taxP / 2;
        iGST = 0;
        csGST = CommonService.getRound(decimal, ((grossTotal * csPer) / 100));
      } else if (companyTaxMode == 'GULF') {
        iGST = CommonService.getRound(decimal, ((grossTotal * taxP) / 100));
        csGST = 0;
      } else {
        iGST = 0;
        csGST = 0;
        tax = 0;
      }
      total = CommonService.getRound(
          decimal, (net + csGST + csGST + iGST + cess + adCess));
      unitValue = _conversion > 0 ? _conversion : 1;
    }
  }

  bool editItem = false;
  int position;

  baseWidget() {
    return Stack(
      children: [
        Align(
            alignment: Alignment.topCenter,
            child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: purchaseContentWidget())),
        const Divider(
          height: 2.0,
          thickness: 2,
        ),
        Align(alignment: Alignment.bottomCenter, child: footerWidget()),
      ],
    );
  }

  String entryNo = '', dropDownType = 'Purchase';
  purchaseContentWidget() {
    return Column(
      children: [
        Column(
          children: [
            Card(
              child: SizedBox(
                height: 38,
                // width: MediaQuery.of(context).size.width / 2 * 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Bill No',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        entryNo.isEmpty
                            ? const Icon(Icons.arrow_drop_down_rounded)
                            : Text(
                                entryNo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                      ],
                    ),
                    const VerticalDivider(width: 1, color: black),
                    Column(
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        InkWell(
                          child: Text(
                            formattedDate,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onTap: () => _selectDate('f'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: SizedBox(
                height: 38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Invoice No',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        InkWell(
                          child: invNoController.text.isEmpty
                              ? const Icon(Icons.arrow_drop_down_rounded)
                              : Text(invNoController.text,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    TextField(
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Supplier Invoice No',
                                          labelText:
                                              'Enter supplier invoice no'),
                                      controller: invNoController,
                                      autofocus: true,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        setState(() {});
                                      },
                                      child: const Text("Done"),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1, color: black),
                    Column(
                      children: [
                        const Text(
                          'Invoice Date',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        InkWell(
                          child: Text(
                            invDate,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onTap: () => _selectDate('t'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: SizedBox(
                height: 38,
                width: MediaQuery.of(context).size.width * 1,
                child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        isAccountLedger = true;
                        nextWidget = 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Column(
                        children: [
                          const Text('Select Cash / Supplier',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: grey)),
                          Visibility(
                            visible: accountModel != null,
                            child: Text(
                                accountModel != null ? accountModel.name : '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(width: 2, color: blue),
                    )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: SizedBox(
                height: 38,
                width: MediaQuery.of(context).size.width * 1,
                child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        isAccountLedger = false;
                        nextWidget = 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Column(
                        children: [
                          const Text('Select Supplier Name',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: grey,
                                  fontSize: 10)),
                          Visibility(
                            visible: ledgerModel != null,
                            child: Text(
                                ledgerModel != null ? ledgerModel.name : '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(width: 2, color: blue),
                    )),
              ),
            ),
            Card(
              child: SizedBox(
                height: 38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text(
                      'Type : ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    DropdownButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      items: [
                        "Purchase",
                        "InterState",
                        "Composite",
                        "UnRegistered Dealer",
                        "Branch Transfer",
                        "Imports"
                      ].map((String items) {
                        return DropdownMenuItem(
                          value: items,
                          child: Text(items),
                        );
                      }).toList(),
                      value: dropDownType,
                      onChanged: (value) {
                        setState(() {
                          dropDownType = value;
                        });
                      },
                    ),
                    // const Text(
                    //   'Date : ',
                    //   style: TextStyle(fontWeight: FontWeight.bold),
                    // ),
                    // InkWell(
                    //   child: Text(
                    //     formattedDate,
                    //     style: const TextStyle(fontWeight: FontWeight.bold),
                    //   ),
                    //   onTap: () => _selectDate('f'),
                    // ),
                    const Text(
                      'Tax:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                    const Visibility(
                      visible: false,
                      child: Text(
                        'Cash:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Visibility(
                      visible: false,
                      child: Checkbox(
                        checkColor: Colors.greenAccent,
                        activeColor: Colors.red,
                        value: _isCashBill,
                        onChanged: (bool value) {
                          setState(() {
                            _isCashBill = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Card(
            //     child: SizedBox(
            //         height: 38,
            //         child: Row(
            //             mainAxisAlignment: MainAxisAlignment.spaceAround,
            //             children: []))),
            // ListTile(
            //   title: Text(ledgerModel.name,
            //       style: const TextStyle(
            //           fontWeight: FontWeight.bold, color: Colors.red)),
            // ),
          ],
        ),
        totalItem > 0 ? Container() : addItemButtonWidget(),
        Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: totalItem > 0
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
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
                                                  text:
                                                      '${cartItem[index].id}/',
                                                  style: TextStyle(
                                                      color: Colors
                                                          .blueGrey.shade800,
                                                      fontSize: 10.0),
                                                  children: [
                                                    TextSpan(
                                                        text:
                                                            '${cartItem[index].uniqueCode}/${cartItem[index].itemId}',
                                                        style: const TextStyle(
                                                            fontSize: 10.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ]),
                                            ),
                                            RichText(
                                              maxLines: 1,
                                              text: TextSpan(
                                                  text: 'Unit: ',
                                                  style: TextStyle(
                                                      color: Colors
                                                          .blueGrey.shade800,
                                                      fontSize: 12.0),
                                                  children: [
                                                    TextSpan(
                                                        text:
                                                            '${UnitSettings.getUnitName(cartItem[index].unitId)}\n',
                                                        style: const TextStyle(
                                                            fontSize: 12.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PlusMinusButtons(
                                        addQuantity: () {
                                          setState(() {
                                            updateProduct(
                                                cartItem[index],
                                                cartItem[index].quantity + 1,
                                                index);
                                          });
                                        },
                                        deleteQuantity: () {
                                          setState(() {
                                            updateProduct(
                                                cartItem[index],
                                                cartItem[index].quantity - 1,
                                                index);
                                          });
                                        },
                                        text:
                                            cartItem[index].quantity.toString(),
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
                                                  text:
                                                      '${cartItem[index].rate}\n',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                            cartModel =
                                                cartItem.elementAt(position);
                                            controllerRate.text =
                                                cartModel.rate.toString();
                                            controllerQuantity.text =
                                                cartModel.quantity.toString();
                                            controllerBranch.text =
                                                cartModel.branch.toString();
                                            controllerDiscount.text =
                                                cartModel.discount.toString();
                                            controllerDiscountPer.text =
                                                cartModel.discountPercent
                                                    .toString();
                                            controllerFreeQuantity.text =
                                                cartModel.free.toString();
                                            controllerMrp.text =
                                                cartModel.mrp.toString();
                                            controllerRetail.text =
                                                cartModel.retail.toString();
                                            controllerSerialNo.text =
                                                cartModel.serialNo.toString();
                                            controllerWholeSale.text =
                                                cartModel.wholesale.toString();
                                            // controller.text = cartModel..toString();

                                            nextWidget = 4;
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
                                              text:
                                                  '${cartItem[index].gross}    ',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.0)),
                                          TextSpan(
                                              text: 'Disc:',
                                              style: const TextStyle(
                                                  fontSize: 12.0),
                                              children: [
                                                TextSpan(
                                                    text:
                                                        '${cartItem[index].discountPercent}% ${cartItem[index].discount}    ',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0)),
                                              ]),
                                          TextSpan(
                                              text: 'Net:',
                                              style: const TextStyle(
                                                  fontSize: 12.0),
                                              children: [
                                                TextSpan(
                                                    text:
                                                        '${cartItem[index].net}    ',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0)),
                                              ]),
                                          isTax
                                              ? TextSpan(
                                                  text:
                                                      'Tax:${cartItem[index].taxP}% ',
                                                  style: const TextStyle(
                                                      fontSize: 12.0),
                                                  children: [
                                                      TextSpan(
                                                          text:
                                                              '${cartItem[index].tax}    ',
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      12.0)),
                                                    ])
                                              : const TextSpan(text: ''),
                                          TextSpan(
                                              text: 'Total:',
                                              style: const TextStyle(
                                                  fontSize: 12.0),
                                              children: [
                                                TextSpan(
                                                    text:
                                                        '${cartItem[index].total}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
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
                  : SizedBox(
                      height: 100,
                      child: Center(
                        child: Card(
                            child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "No item in cart",
                            style: TextStyle(
                                color: red.shade400,
                                fontWeight: FontWeight.bold),
                          ),
                        )),
                      ),
                    ),
            )),
        totalItem > 0 ? addItemButtonWidget() : Container(),
        const Divider(
          height: 2,
          thickness: 2,
        ),
      ],
    );
  }

  TextEditingController cashPaidController = TextEditingController();
  TextEditingController invNoController = TextEditingController();
  TextEditingController newSerialNoController = TextEditingController();
  final TextEditingController _otherDiscountController =
      TextEditingController();
  final TextEditingController _otherChargesController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final FocusNode _focusNodeOtherCharges = FocusNode();
  final FocusNode _focusNodeOtherDiscount = FocusNode();

  footerWidget() {
    calculateTotal();
    return SizedBox(
      height: 110,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            Card(
              color: blue.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showBottom(context);
                    },
                    child: const Text('More',
                        style: TextStyle(
                            fontSize: 20.0, fontWeight: FontWeight.bold)),
                  ),
                  const Text('GrandTotal : ',
                      style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.red)),
                  Text(calculateGrandTotal(),
                      style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.red))
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: SizedBox(
                    // width: 30,
                    height: 40,
                    child: TextField(
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp(r'[0-9]'),
                            allow: true, replacementString: '.')
                      ],
                      decoration: const InputDecoration(
                        label: Text('Cash Paid: '),
                        border: OutlineInputBorder(),
                      ),
                      controller: cashPaidController,
                      onChanged: (value) {
                        setState(() {
                          _balance = double.tryParse(value) > 0
                              ? totalCartTotal > 0
                                  ? totalCartTotal - double.tryParse(value)
                                  : 0
                              : totalCartTotal > 0
                                  ? totalCartTotal
                                  : 0;
                        });
                      },
                    ),
                  ),
                ),
                const Text('Balance : '),
                Text(ComSettings.appSettings(
                        'bool', 'key-round-off-amount', false)
                    ? _balance.toStringAsFixed(2)
                    : _balance.roundToDouble().toString()),
              ],
            ),
          ],
        ),
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
      totalProfit = 0,
      grandTotal = 0;
  int get totalItem => cartItem.length;

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
    grandTotal = 0;
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
    controllerSerialNo.text = '';
    controllerRate.text = '';
    controllerDiscountPer.text = '';
    controllerDiscount.text = '';
    controllerBranch.text = '';
    controllerMrp.text = '';
    controllerMrpPercentage.text = '';
    controllerRetail.text = '';
    controllerRetailPercentage.text = '';
    controllerWholeSale.text = '';
    controllerWholeSalePercentage.text = '';
    controllerBranch.text = '';
    controllerBranchPercentage.text = '';
    controllerSPRetail.text = '';
    controllerSPRetailPercentage.text = '';
    editableQuantity = false;
    editableRate = false;
    editableDiscount = false;
    editableDiscountP = false;
    quantity = 0;
    freeQuantity = 0;
    pRate = 0;
    grossTotal = 0;
    discount = 0;
    discountPer = 0;
    net = 0;
    tax = 0;
    total = 0;
    mrp = 0;
    retail = 0;
    wholeSale = 0;
    branch = 0;
    taxP = 0;
    rPRate = 0;
    rateOff = 0;
    kfcP = 0;
    fCess = 0;
    unitValue = 1;
    conversion = 0;
    fUnitValue = 0;
    cdPer = 0;
    cDisc = 0;
    cess = 0;
    cessPer = 0;
    adCessPer = 0;
    adCess = 0;
    iGST = 0;
    csGST = 0;
    expense = 0;
    mrpPercentage = 0;
    wholeSalePercentage = 0;
    retailPercentage = 0;
    spRetail = 0;
    spRetailPercentage = 0;
    branchPercentage = 0;
    _conversion = 0;
  }

  Future _selectDate(String type) async {
    DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => {
            if (type == 'f')
              {formattedDate = DateFormat('dd-MM-yyyy').format(picked)}
            else
              {invDate = DateFormat('dd-MM-yyyy').format(picked)}
          });
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

    api.fetchPurchaseInvoiceSp(data['Id'], 'P_Find').then((value) {
      if (value != null) {
        var information = value['Information'][0];
        var particulars = value['Particulars'];
        if (value['SerialNO'] != null) {
          serialNoData = SerialNOModel.fromJsonList(value['SerialNO']);
        }
        // var deliveryNoteDetails = value['DeliveryNote'];
        if (value['otherAmount'] != null) {
          otherAmountList = value['otherAmount'];
        }

        formattedDate = DateUtil.dateDMY(information['DDate']);
        invDate = DateUtil.dateDMY(information['InvDate']);

        dataDynamic = [
          {
            'RealEntryNo': information['EntryNo'],
            'EntryNo': information['EntryNo'],
            'InvoiceNo': information['Sup_Inv'],
            'Type': '0'
          }
        ];
        billCash = double.tryParse(information['CashPaid'].toString());
        _otherDiscountController.text = information['OtherDiscount'].toString();
        _otherChargesController.text = information['OtherCharges'].toString();
        billTotal = double.tryParse(information['GrandTotal'].toString());
        narration = information['Narration'];
        DataJson cModel =
            DataJson(id: information['Supplier'], name: information['FromSup']);
        ledgerModel = CustomerModel(
            address1: '',
            address2: '',
            address3: '',
            address4: '',
            balance: '0',
            city: '',
            email: '',
            id: cModel.id,
            name: cModel.name,
            phone: '',
            pinNo: '',
            remarks: '',
            route: '',
            state: '',
            stateCode: '',
            taxNumber: '');
        cartItem.clear();
        for (var product in particulars) {
          cartItem.add(CartItemP(
            adCess: double.tryParse(product['adcess'].toString()),
            barcode: barcode,
            branch: double.tryParse(product['Branch'].toString()),
            branchPer: double.tryParse(product['branchp'].toString()),
            cDisc: double.tryParse(product['cdisc'].toString()),
            cGST: double.tryParse(product['CGST'].toString()),
            cdPer: double.tryParse(product['cdiscper'].toString()),
            cess: double.tryParse(product['cess'].toString()),
            discount: double.tryParse(product['Disc'].toString()),
            discountPercent: double.tryParse(product['DiscPersent'].toString()),
            expDate: product['expDate'],
            expense: double.tryParse(product['Expenses'].toString()),
            fCess: double.tryParse(product['Fcess'].toString()),
            fUnitId: int.tryParse(product['Funit'].toString()),
            fUnitValue: double.tryParse(product['FValue'].toString()),
            free: double.tryParse(product['freeQty'].toString()),
            gross: double.tryParse(product['GrossValue'].toString()),
            iGST: double.tryParse(product['IGST'].toString()),
            id: cartItem.length + 1,
            itemId: product['ItemId'],
            itemName: product['ProductName'],
            location: int.tryParse(product['Location'].toString()),
            mrp: double.tryParse(product['Mrp'].toString()),
            mrpPer: double.tryParse(product['Profit'].toString()),
            net: double.tryParse(product['Net'].toString()),
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
            tax: double.tryParse(product['SGST'].toString()) +
                double.tryParse(product['CGST'].toString()) +
                double.tryParse(product['IGST'].toString()),
            taxP: double.tryParse(product['tax'].toString()),
            total: double.tryParse(product['Total'].toString()),
            uniqueCode: product['UniqueCode'],
            unitId: product['Unit'],
            unitName: '',
            unitValue: double.tryParse(product['UnitValue'].toString()),
            wholesale: double.tryParse(product['WSrate'].toString()),
            wholesalePer: double.tryParse(product['wsalesp'].toString()),
            brand: int.tryParse(product['Brand'].toString()),
            size: int.tryParse(product['Size'].toString()),
            color: int.tryParse(product['color'].toString()),
            company: int.tryParse(product['company'].toString()),
            estUniqueCode: int.tryParse(product['EstUniquecode'].toString()),
            expenseQty: int.tryParse(product['Expense_Qty'].toString()),
          ));
        }
      }

      setState(() {
        widgetID = false;
        if (billCash > 0) {
          cashPaidController.text = billCash.toStringAsFixed(decimal);
        }
        _narrationController.text = narration;
        nextWidget = 5;
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
    api.deletePurchase(dataDynamic[0]['EntryNo'], 'P_Delete').then((value) {
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
                title: const Text('Purchase Deleted'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/purchase');
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

  showBottom(BuildContext ctx) {
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
                  TextField(
                    controller: _otherDiscountController,
                    focusNode: _focusNodeOtherDiscount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Other Discount'),
                  ),
                  TextField(
                    controller: _otherChargesController,
                    focusNode: _focusNodeOtherCharges,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Other Charges'),
                  ),
                  TextField(
                    controller: _narrationController,
                    decoration: const InputDecoration(labelText: 'Narration'),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Text(calculateGrandTotal()),
                  Center(
                      child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              calculateGrandTotal();
                            });
                          },
                          child: const Text('Submit')))
                ],
              ),
            ));
  }

  String calculateGrandTotal() {
    String grandTotal = totalCartTotal > 0
        ? ComSettings.appSettings('bool', 'key-round-off-amount', false)
            ? CommonService.getRound(decimal, totalCartTotal).toString()
            : CommonService.getRound(decimal, totalCartTotal)
                .roundToDouble()
                .toString()
        : ComSettings.appSettings('bool', 'key-round-off-amount', false)
            ? CommonService.getRound(decimal, totalCartTotal).toString()
            : CommonService.getRound(decimal, totalCartTotal.roundToDouble())
                .toString();
    double otherCharges = 0, otherDiscount = 0;
    otherCharges = _otherChargesController.text.isNotEmpty
        ? double.parse(_otherChargesController.text)
        : 0.0;
    otherDiscount = _otherDiscountController.text.isNotEmpty
        ? double.parse(_otherDiscountController.text)
        : 0.0;
    grandTotal = ((double.parse(grandTotal) + otherCharges) - otherDiscount)
        .toStringAsFixed(2);
    return grandTotal;
  }

  serialNoWidget() {
    int gId = 0;
    if (editItem) {
      gId = cartItem[position].id;
    } else {
      gId = cartItem.length + 1;
    }
    return Container(
      padding: const EdgeInsets.all(5.0),
      child: Column(children: [
        Row(
          children: [
            const Text(
              'SerialNo',
              style: TextStyle(fontSize: 25),
            ),
            Expanded(
                child: MaterialButton(
              onPressed: () {
                int qtyTotal = int.parse(controllerQuantity.text.split('.')[0]);

                if (qtyTotal == serialNoData.length) {
                  setState(() {
                    nextWidget = 4;
                  });
                } else {
                  showInSnackBar('Quantity not equal\nAdd more serialNo');
                }
              },
              child: const Text("OK"),
              color: blue[400],
            )),
          ],
        ),
        const Divider(),
        Row(
          children: [
            Expanded(
              child: TextField(
                  controller: newSerialNoController,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.document_scanner),
                      onPressed: () {
                        scanSerialNumber();
                      },
                    ),
                    label: const Text('Type SerialNo'),
                    border: const OutlineInputBorder(),
                  )),
            ),
            IconButton(
                onPressed: () {
                  int qtyTotal =
                      int.parse(controllerQuantity.text.split('.')[0]);
                  if (qtyTotal == serialNoData.length) {
                    showInSnackBar('qty already full');
                  } else {
                    if (newSerialNoController.text.isNotEmpty) {
                      bool serialNoIn = false;
                      serialNoIn = serialNoData
                              .firstWhere(
                                (element) =>
                                    element.serialNo
                                        .toString()
                                        .trim()
                                        .toLowerCase() ==
                                    newSerialNoController.text
                                        .trim()
                                        .toLowerCase(),
                                orElse: () => SerialNOModel.emptyData(),
                              )
                              .serialNo
                              .isNotEmpty
                          ? true
                          : false;
                      if (!serialNoIn) {
                        setState(() {
                          serialNoData.add(SerialNOModel(
                              entryNo: 0,
                              gId: gId,
                              itemName: editItem
                                  ? cartItem[position].itemId
                                  : productModel.slNo,
                              serialNo: newSerialNoController.text,
                              slNo: serialNoData.length + 1,
                              tType: 'P',
                              uniqueCode: editItem
                                  ? cartItem[position].uniqueCode
                                  : 0));
                        });
                      } else {
                        showInSnackBar('already exists');
                      }
                    }
                  }
                },
                icon: const Icon(Icons.add))
          ],
        ),
        const Divider(),
        Expanded(
            child: ListView.builder(
                itemCount: serialNoData.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onDoubleTap: () {
                      setState(() {
                        serialNoData.removeAt(index);
                      });
                    },
                    child: Card(
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child:
                            Center(child: Text(serialNoData[index].serialNo)),
                      ),
                    ),
                  );
                }))
      ]),
    );
  }

  callNumber(number) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(number);
    } catch (_e) {
      debugPrint(_e);
    }
  }

  Future<void> searchBill(BuildContext context) async {
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
                        'Type': '0',
                        'InvoiceNo': _controller.text,
                        'EntryNo': int.tryParse(_controller.text) ?? 0,
                        'Id': int.tryParse(_controller.text) ?? 0
                      }
                    ];
                    fetchPurchase(context, dataDynamic[0]);
                  }
                },
              ),
            ],
          );
        });
  }

  void updateProduct(CartItemP item, double qty, int index) {
    cartItem[index].quantity = qty;

    cartItem[index].gross = CommonService.getRound(
        2, (cartItem[index].rRate * cartItem[index].quantity));
    cartItem[index].net = CommonService.getRound(
        2, (cartItem[index].gross - cartItem[index].discount));
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
            cartItem[index].rRate * cartItem[index].quantity);

    calculateTotal();
  }

  doneButtonWidget(CustomerModel data) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          // supplierName = supplierName.isEmpty
          //     ? snapshot.data.name == 'CASH'
          //         ? 'CASH'
          //         : supplierName
          //     : supplierName;
          if (isAccountLedger) {
            isAccountLedger = false;
            accountModel = CustomerModel(
                id: data.id,
                name: data.name,
                address1: data.address1,
                address2: data.address2,
                address3: data.address3,
                address4: data.address4,
                balance: data.balance,
                city: data.city,
                email: data.email,
                phone: data.phone,
                route: data.route,
                state: data.state,
                stateCode: data.stateCode,
                taxNumber: data.taxNumber);
            ledgerModel ??= accountModel;
          } else {
            ledgerModel = CustomerModel(
                id: data.id,
                name: data.name,
                address1: data.address1,
                address2: data.address2,
                address3: data.address3,
                address4: data.address4,
                balance: data.balance,
                city: data.city,
                email: data.email,
                phone: data.phone,
                route: data.route,
                state: data.state,
                stateCode: data.stateCode,
                taxNumber: data.taxNumber);
            accountModel ??= ledgerModel;
          }
          nextWidget = 0;
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
            // Icon(
            //   Icons.shopping_bag,
            //   color: white,
            // ),
            // SizedBox(
            //   width: 4.0,
            // ),
            Text(
              "Done",
              style: TextStyle(color: white),
            ),
          ],
        ),
      ),
    );
  }

  addItemButtonWidget() {
    return Card(
      color: blue.shade50,
      child: SizedBox(
        height: 38,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
                visible: enableBarcode,
                child: IconButton(
                  icon: const Icon(
                    Icons.document_scanner,
                    color: kPrimaryColor,
                  ),
                  onPressed: () {
                    scanBarcode();
                  },
                )),
            const SizedBox(
              width: 10,
            ),
            const Icon(Icons.add_circle_rounded, color: kPrimaryColor),
            const SizedBox(
              width: 10,
            ),
            InkWell(
                child: const Text(
                  'Add Item',
                  style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  setState(() {
                    nextWidget = 3;
                  });
                }),
          ],
        ),
      ),
    );
  }

  scannerWidget() {
    return Column(
      children: <Widget>[
        Expanded(flex: 4, child: _buildQrViewLedger(context)),
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

  scanBarcode() {
    return Column(
      children: <Widget>[
        Expanded(flex: 4, child: _buildQrViewProduct(context)),
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

  scanSerialNumber() {
    return Column(
      children: <Widget>[
        Expanded(flex: 4, child: _buildQrViewSerialNo(context)),
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

  Widget _buildQrViewLedger(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreatedLedger,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreatedLedger(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        var _id = result.code.isNotEmpty
            ? int.tryParse(result.code.replaceAll('http://', ''))
            : 0;
        ledgerDataModel = DataJson(id: _id, name: 'A');
        nextWidget = 2;
      });
    });
  }

  Widget _buildQrViewProduct(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreatedProduct,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  String barcodeValueText = '0';
  void _onQRViewCreatedProduct(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        productScanner = false;
        var _id = result.code.isNotEmpty
            ? int.tryParse(result.code.replaceAll('http://', ''))
            : 0;
        barcodeValueText = _id.toString();
        isBarcodePicker = true;
        nextWidget = 3;
      });
    });
  }

  showBarcodeProduct() {
    return FutureBuilder(
        future: api.fetchStockProductByBarcode(barcodeValueText),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.length > 0) {
              // return showAddMore(context, snapshot.data[0]);
              setState(() {
                productModel = itemDisplay[0];
                nextWidget = 4;
                isItemData = false;
              });
              return Container();
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

  Widget _buildQrViewSerialNo(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreatedSerialNo,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreatedSerialNo(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        productScanner = false;
        var _id = result.code.isNotEmpty
            ? int.tryParse(result.code.replaceAll('http://', ''))
            : 0;
        barcodeValueText = _id.toString();
        isBarcodePicker = true;
        nextWidget = 3;
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
}

showMore(context, purchaseState) {
  ConfirmAlertBox(
      buttonColorForNo: Colors.white,
      buttonColorForYes: Colors.green,
      icon: Icons.check,
      onPressedYes: () {
        Navigator.of(context).pop();
        Navigator.pushReplacementNamed(context, '/purchase');
      },
      // buttonTextForNo: 'No',
      buttonTextForYes: 'OK',
      infoMessage: 'Purchase $purchaseState',
      title: 'SAVED',
      context: context);
}

bool taxablePurchase = true;
