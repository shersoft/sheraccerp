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
import 'package:sheraccerp/models/stock_item.dart';
import 'package:sheraccerp/models/stock_product.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class DamageEntry extends StatefulWidget {
  const DamageEntry({Key key}) : super(key: key);

  @override
  _DamageEntryState createState() => _DamageEntryState();
}

class _DamageEntryState extends State<DamageEntry> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  DioService dio = DioService();
  Size deviceSize;
  var ledgerModel;
  StockItem productModel;
  List<CartItem> cartItem = [];
  DateTime now = DateTime.now();
  String formattedDate, _narration = '';
  double grandTotal = 0;
  var accountId = '0', creditAccountId = '0';

  bool isTax = true,
      otherAmountLoaded = false,
      enableMULTIUNIT = false,
      pRateBasedProfitInSales = false,
      negativeStock = false,
      cessOnNetAmount = false,
      negativeStockStatus = false,
      enableKeralaFloodCess = false,
      useUNIQUECODEASBARCODE = false,
      useOLDBARCODE = false,
      widgetID = true,
      lastRecord = false,
      keyItemsVariantStock = false;
  int page = 1, pageTotal = 0, totalRecords = 0;
  List<dynamic> ledgerDisplay = [];
  List<dynamic> _ledger = [];
  List<dynamic> itemDisplay = [];
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    loadSettings();
    var da = mainAccount
        .firstWhere((element) => element['lh_name'] == 'PURCHASE A/C');
    creditAccountId = da['LedCode'].toString();
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
    keyItemsVariantStock =
        ComSettings.getStatus('KEY LOCK SALES DISCOUNT', settings);
  }

  @override
  Widget build(BuildContext context) {
    //getLedgerByType
    deviceSize = MediaQuery.of(context).size;
    return widgetID ? widgetPrefix() : widgetSuffix();
  }

  widgetPrefix() {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Damage"),
          actions: [
            TextButton(
                child: const Text(
                  "New",
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
        ),
        body: Container(
          child: previousBill(),
        ));
  }

  widgetSuffix() {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Damage"),
          actions: [
            TextButton(
                child: const Text(
                  "Save",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue[700],
                ),
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  saveSale();
                }),
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
                      // print(dataDisplay[index]);
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
              const Text("No items in Damage"),
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
                  label: const Text('Take New Damage'))
            ],
          ));
  }

  final ScrollController _scrollController = ScrollController();
  bool isLoadingData = false;
  List dataDisplay = [];

  void _getMoreData() async {
    if (!lastRecord) {
      if (dataDisplay.isEmpty ||
          dataDisplay.length < totalRecords) if (!isLoadingData) {
        setState(() {
          isLoadingData = true;
        });

        List tempList = [];
        dio
            .getPaginationList('DamageList', page, '1', '0',
                DateUtil.dateYMD(formattedDate), '0')
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
    super.dispose();
  }

  saveSale() async {
    int lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    accountId = ledgerModel['Ledcode'].toString();
    var locationId = lId.toString().trim().isNotEmpty ? lId : '1';
    var gTotal = grandTotal > 0
        ? ComSettings.appSettings('bool', 'key-round-off-amount', false)
            ? CommonService.getRound(2, grandTotal).toString()
            : CommonService.getRound(2, grandTotal).roundToDouble().toString()
        : ComSettings.appSettings('bool', 'key-round-off-amount', false)
            ? CommonService.getRound(2, totalCartValue).toString()
            : CommonService.getRound(2, totalCartValue.roundToDouble())
                .toString();
    if (double.tryParse(gTotal) > 0) {
      double total = double.tryParse(gTotal);
      var jsonItem = CartItem.encodeCartToJson(cartItem);
      var items = json.encode(jsonItem);

      var data = '[' +
          json.encode({
            'date': DateUtil.dateYMD(formattedDate),
            'accountId': accountId,
            'total':
                ComSettings.appSettings('bool', 'key-round-off-amount', false)
                    ? total.toStringAsFixed(2)
                    : total.roundToDouble().toString(),
            'creditAccount': creditAccountId,
            'location': locationId.toString(),
            'transferStatus': '0',
            'narration': _narration.isNotEmpty ? _narration : ''
          }) +
          ']';

      final body = {'data': data, 'particular': items};
      dio.addDamage(body).then((value) {
        setState(() {
          _isLoading = false;
        });
        if (value) {
          clearCart();
          showMore(context);
        }
      });
    }
  }

  int nextWidget = 0;
  selectWidget() {
    return nextWidget == 0
        ? selectLedgerWidget()
        : nextWidget == 1
            ? selectProductWidget()
            : nextWidget == 2
                ? itemDetailWidget()
                : nextWidget == 3
                    ? cartProduct()
                    : TextButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(kPrimaryColor),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                        ),
                        onPressed: () {
                          setState(() {
                            nextWidget = 0;
                          });
                        },
                        child: const Text('Select again'));
  }

  bool isData = false;

  selectLedgerWidget() {
    setState(() {
      if (_ledger.isNotEmpty) isData = true;
    });
    return FutureBuilder<List<dynamic>>(
      future: dio.getLedgerListByType('SelectExpenceOnly'),
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
                                      var itemName = item.LedName.toLowerCase();
                                      return itemName.contains(text);
                                    }).toList();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    : InkWell(
                        child: Card(
                          child: ListTile(
                              title: Text(ledgerDisplay[index - 1]['LedName'])),
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
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              label: Text('Search...')),
                          onChanged: (text) {
                            text = text.toLowerCase();
                            setState(() {
                              itemDisplay = items.where((item) {
                                var itemName = item.name.toLowerCase();
                                return itemName.contains(text);
                              }).toList();
                            });
                          },
                        ),
                      )
                    : InkWell(
                        child: Card(
                          child: ListTile(
                            title:
                                Text('Name : ${itemDisplay[index - 1].name}'),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Qty :${itemDisplay[index - 1].quantity}'),
                                TextButton(
                                    onPressed: () {
                                      Fluttertoast.showToast(
                                          msg: 'Not Available');
                                    },
                                    child: const Card(child: Text('ADD')))
                              ],
                            ),
                          ),
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

  itemDetailWidget() {
    return productModel.hasVariant
        ? showVariantDialog(productModel.id, productModel.name)
        : selectStockLedger();
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
                  children: <Widget>[
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

  showVariantDialog(int id, String name) {
    return FutureBuilder<List<StockProduct>>(
      future: dio.fetchStockVariantProduct(id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            return keyItemsVariantStock
                ? SizedBox(
                    height: 200.0,
                    width: 400.0,
                    child: ListView(children: [
                      Text(name),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Card(
                            elevation: 5,
                            child: ListTile(
                                title: Text(
                                    'Id: ${snapshot.data[index].productId}'),
                                subtitle: Text(
                                    'Quantity : ${snapshot.data[index].quantity} Rate ${snapshot.data[index].sellingPrice}'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showAddMore(context, snapshot.data[index]);
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
    gross = 0;
    subTotal = 0;
    total = 0;
    quantity = 0;
    rate = 0;
    saleRate = 0;
    rRate = 0;
    rateOff = 0;
    unitValue = 1;
    _conversion = 0;
    pRate = 0;
    rPRate = 0;
    uniqueCode = 0;
    _dropDownUnit = 0;
    barcode = 0;
  }

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  // TextEditingController _discountPercentController = TextEditingController();
  final _resetKey = GlobalKey<FormState>();
  String expDate = '2000-01-01';
  int _dropDownUnit = 0, uniqueCode = 0, barcode = 0;
  bool rateEdited = false;

  double gross = 0,
      subTotal = 0,
      total = 0,
      quantity = 0,
      rate = 0,
      saleRate = 0,
      rRate = 0,
      rateOff = 0,
      unitValue = 1,
      _conversion = 0,
      pRate = 0,
      rPRate = 0;

  showAddMore(BuildContext context, StockProduct product) {
    pRate = product.buyingPrice;
    rPRate = product.buyingPriceReal;
    saleRate = pRate;

    if (saleRate > 0) {
      _rateController.text = taxMethod == 'MINUS'
          ? isTax
              ? saleRate.toString()
              : CommonService.getRound(
                      2, (saleRate * 100) / (100 + product.tax))
                  .toString()
          : saleRate.toString();
    }
    uniqueCode = product.productId;
    List<UnitModel> unitList = [];

    calculate() {
      if (enableMULTIUNIT) {
        if (saleRate > 0) {
          if (_conversion > 0) {
            var r = rateEdited
                ? double.tryParse(_rateController.text)
                : saleRate * _conversion;
            rate = r;
            _rateController.text = r.toStringAsFixed(2);
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
        rate = _rateController.text.isNotEmpty
            ? double.tryParse(_rateController.text)
            : 0;
      }
      quantity = _quantityController.text.isNotEmpty
          ? double.tryParse(_quantityController.text)
          : 0;
      rRate = taxMethod == 'MINUS'
          ? cessOnNetAmount
              ? CommonService.getRound(4, (100 * rate) / (100))
              : CommonService.getRound(4, (100 * rate) / (100))
          : rate;
      gross = CommonService.getRound(2, ((rRate * quantity)));
      subTotal = CommonService.getRound(2, (gross));
      total = CommonService.getRound(2, (subTotal));
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: TextFormField(
                          controller: _quantityController,
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
                            // autofocus: true,
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
                                rateEdited = _rateController.text.isNotEmpty
                                    ? true
                                    : false;
                                calculate();
                              });
                            },
                          ),
                        )),
                        Visibility(
                          visible: taxMethod == 'MINUS',
                          child: Text(
                            '$rRate',
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      ]),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text('SubTotal : '),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(subTotal.toStringAsFixed(2)),
                    ),
                  ]),
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
                        total.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ]),
                  const Divider(),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        MaterialButton(
                          onPressed: () {
                            setState(() {
                              nextWidget = 3;
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
                              addProduct(CartItem(
                                  id: totalItem + 1,
                                  itemId: product.itemId,
                                  itemName: product.name,
                                  quantity: quantity,
                                  rate: rate,
                                  rRate: rRate,
                                  uniqueCode: uniqueCode,
                                  gross: gross,
                                  discount: 0,
                                  discountPercent: 0,
                                  rDiscount: 0,
                                  fCess: 0,
                                  serialNo: '',
                                  tax: 0,
                                  taxP: 0,
                                  unitId: _dropDownUnit,
                                  unitValue: unitValue,
                                  pRate: pRate,
                                  rPRate: rPRate,
                                  barcode: barcode,
                                  expDate: expDate,
                                  free: 0,
                                  fUnitId: 0,
                                  cdPer: 0,
                                  cDisc: 0,
                                  net: subTotal,
                                  cess: 0,
                                  total: total,
                                  profitPer: 0,
                                  fUnitValue: 0,
                                  adCess: 0,
                                  iGST: 0,
                                  cGST: 0,
                                  sGST: 0));
                              if (totalItem > 0) {
                                clearValue();
                                nextWidget = 3;
                              }
                            });
                          },
                        ),
                      ])
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
    return Column(
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
                      title: Text(cartItem[index].itemName),
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
                                  setState(() {
                                    updateProduct(cartItem[index],
                                        cartItem[index].quantity + 1);
                                  });
                                },
                              ),
                            ),
                          ),
                          InkWell(
                            child: Text(cartItem[index].quantity.toString(),
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                            onTap: () {
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
                            child: Text(cartItem[index].rate.toStringAsFixed(2),
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                            onTap: () {
                              _displayTextInputDialog(
                                  context,
                                  'Edit Rate',
                                  cartItem[index].rate > 0
                                      ? double.tryParse(
                                              cartItem[index].rate.toString())
                                          .toString()
                                      : '',
                                  cartItem[index].id);
                            },
                          ),
                          const Text(" = ",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              ((cartItem[index].quantity *
                                          cartItem[index].rate) -
                                      (cartItem[index].discount))
                                  .toStringAsFixed(2),
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
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

  void addProduct(product) {
    int index = cartItem.indexWhere((i) => i.id == product.id);
    // print(index);
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
        cartItem[index].fCess = isKFC
            ? CommonService.getRound(2, ((cartItem[index].net * kfcPer) / 100))
            : 0;
        double csPer = cartItem[index].taxP / 2;
        double csGST =
            CommonService.getRound(2, ((cartItem[index].net * csPer) / 100));
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
        cartItem[index].fCess = isKFC
            ? CommonService.getRound(2, ((cartItem[index].net * kfcPer) / 100))
            : 0;
        double csPer = cartItem[index].taxP / 2;
        double csGST =
            CommonService.getRound(2, ((cartItem[index].net * csPer) / 100));
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
          ],
        ),
        ListTile(
          title: Text(ledgerModel['LedName'],
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
          subtitle: const Text(''),
        ),
        InkWell(
            child: const SizedBox(
              height: 20,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Text(
                      'Item Add',
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
    return Container(
      color: Colors.blue[50],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SubTotal: ",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red[300])),
              Text(
                  CommonService.getRound(2, totalGrossValue).toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red[300])),
            ],
          ),
          Visibility(
            visible: isTax,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Tax: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red[400])),
                Text(
                    CommonService.getRound(2, taxTotalCartValue)
                        .toStringAsFixed(2),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red[400])),
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
              Text(CommonService.getRound(2, totalCartValue).toStringAsFixed(2),
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[500])),
            ],
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
                          ? CommonService.getRound(2, grandTotal).toString()
                          : CommonService.getRound(2, grandTotal)
                              .roundToDouble()
                              .toString()
                      : ComSettings.appSettings(
                              'bool', 'key-round-off-amount', false)
                          ? CommonService.getRound(2, totalCartValue).toString()
                          : CommonService.getRound(
                                  2, totalCartValue.roundToDouble())
                              .toString(),
                  style: const TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red))
            ],
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text('Narration...'),
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
            ],
          ),
        ],
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
                  border: OutlineInputBorder(), label: Text("value")),
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
    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/damageEntry');
        },
        onPressedYes: () {
          Navigator.of(context).pop();
          // Navigator.pushReplacementNamed(context, '/preview_show',
          //     arguments: {'title': 'Sale'});
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage: 'your Damage Bill saved',
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
}
