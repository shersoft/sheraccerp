// @dart = 2.11
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/company.dart';
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
import 'package:sheraccerp/widget/popup_menu_action.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class Purchase extends StatefulWidget {
  const Purchase({Key key}) : super(key: key);

  @override
  _PurchaseState createState() => _PurchaseState();
}

class _PurchaseState extends State<Purchase> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DioService dio = DioService();
  var ledgerModel, cartModel;
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
      oldBill = false,
      lastRecord = false,
      isItemSerialNo = false,
      isFreeQty = false,
      realPRateBasedProfitPercentage = false,
      isQuantityBasedSerialNo = false;
  List<CartItemP> cartItem = [];
  int page = 1, pageTotal = 0, totalRecords = 0, _dropDownUnit = 0;
  List<ProductPurchaseModel> itemDisplay = [];
  List<ProductPurchaseModel> items = [];
  final List<dynamic> _ledger = [];
  List<SerialNOModel> serialNoData = [];
  bool enableMULTIUNIT = false,
      cessOnNetAmount = false,
      enableKeralaFloodCess = false,
      useUniqueCodeAaBarcode = false,
      useOldBarcode = false,
      buttonEvent = false;
  int locationId = 1, salesManId = 0, decimal = 2;
  String labelSerialNo = 'SerialNo';

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    invDate = DateFormat('dd-MM-yyyy').format(now);
    dio.getPurchaseAC().then((value) {
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

    isFreeQty = ComSettings.getStatus('KEY FREE QTY IN PURCHASE', settings);
    isQuantityBasedSerialNo =
        ComSettings.getStatus('ENABLE QUANTITY BASED SERIAL NO', settings);
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
                          bool _state = await dio.addPurchase(body);
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
                  color: blue,
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
                          bool _state = await dio.addPurchase(body);
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

  final bool _showBottomSheet = false;

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
        ? selectLedgerWidget()
        : nextWidget == 1
            ? purchaseHeaderWidget()
            : nextWidget == 2
                ? selectProductWidget()
                : nextWidget == 3
                    ? itemDetails()
                    : nextWidget == 4
                        ? cartProduct()
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
      future: dio.getSupplierListData(nameLike),
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
                            ledgerModel = data[index - 1];
                            nextWidget = 1;
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
                          nextWidget = 0;
                          nameLike = 'a';
                        });
                      },
                      child: const Text('Select again'))
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
    //                           nextWidget = 1;
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

  purchaseHeaderWidget() {
    return Center(
        child: Column(
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                return Column(
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
                          onTap: () => _selectDate('f'),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Text('Inv.No:'),
                        SizedBox(
                          width: 100,
                          height: 20,
                          child: TextField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            controller: invNoController,
                            // onChanged: (value) {
                            //   setState(() {
                            //     invNoController.text = value;
                            //   });
                            // },
                          ),
                        ),
                        const Text('Inv.Date:'),
                        InkWell(
                          child: Text(invDate),
                          onTap: () => _selectDate('t'),
                        ),
                      ],
                    ),
                    ListTile(
                      title: Text(ledgerModel.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                    ),
                  ],
                );
              }),
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
        // SizedBox(
        //   height: _deviceSize.height / 6,
        //   child: Container(child: Text('xz')),
        // ),
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
  //                             nextWidget = 3;
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
            future: dio.fetchProductPrize(id),
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
                                  nextWidget = 2;
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
  TextEditingController controllerRetail = TextEditingController();
  TextEditingController controllerWholeSale = TextEditingController();
  TextEditingController controllerBranch = TextEditingController();
  TextEditingController controllerSerialNo = TextEditingController();
  FocusNode focusNodeQuantity = FocusNode();
  FocusNode focusNodeFreeQuantity = FocusNode();
  FocusNode focusNodeRate = FocusNode();
  FocusNode focusNodeDiscountPer = FocusNode();
  FocusNode focusNodeDiscount = FocusNode();
  FocusNode focusNodeMrp = FocusNode();
  FocusNode focusNodeRetail = FocusNode();
  FocusNode focusNodeWholeSale = FocusNode();
  FocusNode focusNodeBranch = FocusNode();
  FocusNode focusNodeSerialNo = FocusNode();

  double quantity = 0,
      freeQuantity = 0,
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
      branchPer = 0,
      _conversion = 0;
  String expDate = '1900-01-01', serialNo = '';
  DataJson unit;
  int uniqueCode = 0, fUnitId = 0, barcode = 0;
  bool editableMrp = false,
      editableRetail = false,
      editableWSale = false,
      editableBranch = false,
      editableRate = false,
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
      // adCessPer = double.tryParse(productModel['adcessper'].toString());
      // cessPer = double.tryParse(productModel['cessper'].toString());
      taxP = isTax ? cartItem.elementAt(position).taxP : 0;
      // kfcP = double.tryParse(productModel['KFC'].toString());
      quantity = cartItem[position].quantity;
      defaultUnitID = cartItem[position].unitId;

      if (quantity > 0 && !editableQuantity) {
        controllerQuantity.text = quantity.toString();
      }
      freeQuantity = cartItem[position].free;
      if (freeQuantity > 0 && !editableFreeQuantity) {
        controllerFreeQuantity.text = freeQuantity.toString();
      }
      rate = cartItem.elementAt(position).rate;
      if (rate > 0 && !editableRate) {
        controllerRate.text = rate.toString();
      }
      if (cartItem.elementAt(position).rRate > 0) {
        rRate = cartItem.elementAt(position).rRate;
      }
      mrp = cartItem.elementAt(position).mrp;
      if (mrp > 0 && !editableMrp) {
        controllerMrp.text = mrp.toString();
      }
      retail = cartItem.elementAt(position).retail;
      if (retail > 0 && !editableRetail) {
        controllerRetail.text = retail.toString();
      }
      wholeSale = cartItem.elementAt(position).wholesale;
      if (wholeSale > 0 && !editableWSale) {
        controllerWholeSale.text = wholeSale.toString();
      }
      spRetail = cartItem.elementAt(position).spRetail;
      branch = cartItem.elementAt(position).branch;
      if (branch > 0 && !editableBranch) {
        controllerBranch.text = branch.toString();
      }
      discount = cartItem.elementAt(position).discount;
      if (discount > 0 && !editableDiscount) {
        controllerDiscount.text = discount.toString();
      }
      discountPer = cartItem.elementAt(position).discountPercent;
      if (discountPer > 0 && !editableDiscountP) {
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
      serialNo = cartItem.elementAt(position).serialNo;
      if (serialNo.isNotEmpty) {
        controllerSerialNo.text = serialNo.toString();
      }
    } else {
      adCessPer = isTax ? productModel.adCessPer : 0;
      cessPer = isTax ? productModel.cessPer : 0;
      taxP = isTax ? productModel.tax : 0;
      kfcP =
          isTax ? 0 : 0; //double.tryParse(productModel['KFC'].toString()) : 0;
      rate = double.tryParse(productModelPrize['prate'].toString());
      if (rate > 0 && !editableRate) {
        controllerRate.text = rate.toString();
      }
      if (double.tryParse(productModelPrize['realprate'].toString()) > 0) {
        rRate = double.tryParse(productModelPrize['realprate'].toString());
      }
      mrp = double.tryParse(productModelPrize['mrp'].toString());
      if (mrp > 0 && !editableMrp) {
        controllerMrp.text = mrp.toString();
      }
      retail = double.tryParse(productModelPrize['retail'].toString());
      if (retail > 0 && !editableRetail) {
        controllerRetail.text = retail.toString();
      }
      wholeSale = double.tryParse(productModelPrize['wsrate'].toString());
      if (wholeSale > 0 && !editableWSale) {
        controllerWholeSale.text = wholeSale.toString();
      }
      spRetail = double.tryParse(productModelPrize['spretail'].toString());
      branch = double.tryParse(productModelPrize['branch'].toString());
      if (branch > 0 && !editableBranch) {
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
      rate = controllerRate.text.isNotEmpty
          ? double.tryParse(controllerRate.text)
          : 0;
      discount = controllerDiscount.text.isNotEmpty
          ? double.tryParse(controllerDiscount.text)
          : 0;
      discountPer = controllerDiscountPer.text.isNotEmpty
          ? double.tryParse(controllerDiscountPer.text)
          : 0;
      // rRate = taxMethod == 'MINUS'
      //     ? CommonService.getRound(decimal, (total / quantity))
      //     : rate;
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
      serialNo =
          controllerSerialNo.text.isNotEmpty ? controllerSerialNo.text : '';

      unitValue = _conversion > 0 ? _conversion : 1;
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

    List<UnitModel> unitListData = [];
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Item : ${editItem ? cartItem.elementAt(position).itemName : productModel.itemName}',
                    style: const TextStyle(color: Colors.red))),
            Row(
              children: [
                Expanded(
                    child: MaterialButton(
                  onPressed: () {
                    setState(() {
                      editItem = false;
                      nextWidget = 2;
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
                      nextWidget = 4;
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
                    if (total > 0) {
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
                        freeQuantity = controllerFreeQuantity.text.isNotEmpty
                            ? double.tryParse(controllerFreeQuantity.text)
                            : freeQuantity;

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
                          cartItem[position].free = freeQuantity;
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
                          cartItem[position].unitId = unit.id;
                          cartItem[position].unitName = unit.name;
                          cartItem[position].unitValue = unitValue;
                          cartItem[position].wholesale = wholeSale;
                          cartItem[position].wholesalePer = wholesalePer;
                        } else {
                          cartItem.add(CartItemP(
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
                              free: freeQuantity,
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
                              wholesalePer: wholesalePer));
                        }
                        if (cartItem.isNotEmpty) {
                          editItem = false;
                          nextWidget = 4;
                          clearValue();
                        }
                      });
                    } else {
                      if (quantity <= 0) {
                        showWarningAlertBox(context, 'Fill data quantity',
                            '0 quantity not allowed');
                      } else if (rate <= 0) {
                        showWarningAlertBox(
                            context, 'Fill data rate', '0 rate not allowed');
                      } else {
                        showWarningAlertBox(
                            context, 'Fill data rate', '0 rate not allowed');
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
                    visible: (isQuantityBasedSerialNo && productModel.serialNo),
                    child: ElevatedButton(
                      child: const Text('Add SerialNo'),
                      onPressed: () {
                        if (controllerQuantity.text.isNotEmpty) {
                          setState(() {
                            nextWidget = 10;
                          });
                        }
                      },
                    )),
                Visibility(
                  visible: isFreeQty,
                  child: Expanded(
                    child: TextField(
                      controller: controllerFreeQuantity,
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
                      controller: controllerSerialNo,
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
                ],
              ),
            ),
            const Divider(),
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Visibility(
                visible: enableMULTIUNIT,
                child: Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: FutureBuilder(
                      future: dio.fetchUnitOf(editItem
                          ? cartItem[position].itemId
                          : productModel.slNo),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          unitListData.clear();
                          for (var i = 0; i < snapshot.data.length; i++) {
                            if (defaultUnitID.toString().isNotEmpty) {
                              if (snapshot.data[i].id == defaultUnitID - 1) {
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
                                rate: snapshot.data[i].rate));
                          }
                        }
                        return snapshot.data != null && snapshot.data.length > 0
                            ? DropdownButton<String>(
                                hint: Text(_dropDownUnit > 0
                                    ? UnitSettings.getUnitName(_dropDownUnit)
                                    : 'SKU'),
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
                                    UnitModel _unit = unitListData.firstWhere(
                                        (element) =>
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
                                    ? UnitSettings.getUnitName(_dropDownUnit)
                                    : 'SKU'),
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
            ]),
            const Divider(),
            TextField(
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
                  rate = double.tryParse(value);
                  calculate();
                });
              },
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text('Subtotal :'),
                Text(subTotal.toStringAsFixed(decimal)),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text('Discount'),
                SizedBox(
                  height: 40,
                  width: 50,
                  child: TextField(
                    controller: controllerDiscountPer,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text(' % ')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('Discount')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  height: 40,
                  width: 100,
                  child: TextField(
                    controller: controllerMrp,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('MRP')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        editableMrp = true;
                        mrp = double.tryParse(value);
                        calculateRate();
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: 100,
                  child: TextField(
                    controller: controllerRetail,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('Retail')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        editableRetail = true;
                        retail = double.tryParse(value);
                        calculateRate();
                      });
                    },
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
                SizedBox(
                  height: 40,
                  width: 100,
                  child: TextField(
                    controller: controllerWholeSale,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('WholeSale')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        editableWSale = true;
                        wholeSale = double.tryParse(value);
                        calculateRate();
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: 100,
                  child: TextField(
                    controller: controllerBranch,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('Branch')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    onChanged: (value) {
                      setState(() {
                        editableBranch = true;
                        branch = double.tryParse(value);
                        calculateRate();
                      });
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Net :'),
                const SizedBox(
                  width: 3,
                ),
                Text(net.toStringAsFixed(decimal)),
              ],
            ),
            Visibility(
              visible: isTax,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(isTax ? 'Tax ${taxP.toStringAsFixed(0)} % : ' : 'Tax :'),
                  const SizedBox(
                    width: 3,
                  ),
                  Text(tax.toStringAsFixed(decimal)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Total :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  width: 3,
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
        totalItem > 0
            ? Expanded(
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
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
                            cartModel = cartItem.elementAt(position);
                            nextWidget = 3;
                          });
                        },
                      ),
                      // SizedBox(
                      //   width: 15,
                      //   height: 30,
                      //   child: IconButton(
                      //       onPressed: () {
                      //         return PopUpMenuAction(
                      //           onDelete: removeItem(index),
                      //           onEdit: editItem(index),
                      //         );
                      //       },
                      //       icon: Icon(Icons.more_vert)),
                      // ),
                    );
                  },
                ),
              )
            : const Center(
                child: Text("No items in Cart"),
              ),
        const Divider(
          height: 2,
          thickness: 2,
        ),
        footerWidget(),
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
    return Container(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  showBottom(context);
                },
                child: const Text('More',
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
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
              Text(
                  ComSettings.appSettings('bool', 'key-round-off-amount', false)
                      ? _balance.toStringAsFixed(2)
                      : _balance.roundToDouble().toString()),
            ],
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
    controllerRetail.text = '';
    controllerWholeSale.text = '';
    editableQuantity = false;
    editableMrp = false;
    editableRetail = false;
    editableWSale = false;
    editableBranch = false;
    editableRate = false;
    editableDiscount = false;
    editableDiscountP = false;
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

    api.fetchPurchaseInvoice(data['Id'], 'P_Find').then((value) {
      if (value != null) {
        var information = value['Information'][0];
        var particulars = value['Particulars'];
        // var serialNO = value['SerialNO'];
        // var deliveryNoteDetails = value['DeliveryNote'];
        otherAmountList = value['otherAmount'];

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
        ledgerModel = cModel;
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
              discountPercent:
                  double.tryParse(product['DiscPersent'].toString()),
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
              wholesalePer: double.tryParse(product['wsalesp'].toString())));
        }
      }

      setState(() {
        widgetID = false;
        if (billCash > 0) {
          cashPaidController.text = billCash.toStringAsFixed(decimal);
        }
        _narrationController.text = narration;
        nextWidget = 4;
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
    dio.deletePurchase(dataDynamic[0]['EntryNo'], 'P_Delete').then((value) {
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
                int qtyTotal = int.parse(controllerQuantity.text);

                if (qtyTotal == serialNoData.length) {
                  setState(() {
                    nextWidget = 3;
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
                  decoration: const InputDecoration(
                    label: Text('Type SerialNo'),
                    border: OutlineInputBorder(),
                  )),
            ),
            IconButton(
                onPressed: () {
                  int qtyTotal = int.parse(controllerQuantity.text);
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
                              gId: serialNoData.length + 1,
                              itemName: productModel.slNo,
                              serialNo: newSerialNoController.text,
                              slNo: 0,
                              tType: 'P',
                              uniqueCode: 0));
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
