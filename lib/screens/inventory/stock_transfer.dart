// @dart = 2.11
import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/app_settings_page.dart';
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/stock_item.dart';
import 'package:sheraccerp/models/stock_product.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/popup_menu_action.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class StockTransfer extends StatefulWidget {
  const StockTransfer({Key key}) : super(key: key);

  @override
  State<StockTransfer> createState() => _StockTransferState();
}

class _StockTransferState extends State<StockTransfer> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DioService dio = DioService();
  Size deviceSize;
  StockItem productModel;
  DateTime now = DateTime.now();
  String formattedDate, _narration = '';
  bool valueMore = false,
      _isLoading = false,
      widgetID = true,
      oldBill = false,
      lastRecord = false,
      buttonEvent = false;
  List<CartItemST> cartItem = [];
  int page = 1, pageTotal = 0, totalRecords = 0;
  List<dynamic> itemDisplay = [];
  List<dynamic> items = [];
  List<dynamic> locationData = [];
  bool enableMULTIUNIT = false,
      cessOnNetAmount = false,
      enableKeralaFloodCess = false,
      useUNIQUECODEASBARCODE = false,
      useOLDBARCODE = false,
      realPRATEBASEDPROFITPERCENTAGE = false,
      keyItemsVariantStock = false;
  int salesManId = 0, decimal = 2, locationFromId = 0, locationToId = 0;

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('dd-MM-yyyy').format(now);
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
    useUNIQUECODEASBARCODE =
        ComSettings.getStatus('USE UNIQUECODE AS BARCODE', settings);
    useOLDBARCODE = ComSettings.getStatus('USE OLD BARCODE', settings);
    realPRATEBASEDPROFITPERCENTAGE =
        ComSettings.getStatus('REAL PRATE BASED PROFIT PERCENTAGE', settings);

    salesManId = ComSettings.appSettings(
            'int', 'key-dropdown-default-salesman-view', 1) -
        1;
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;
    keyItemsVariantStock =
        ComSettings.getStatus('KEY LOCK SALES DISCOUNT', settings);

    locationData.clear();
    if (locationList.isNotEmpty) {
      locationData = locationList;
      try {
        if (locationList
                .where((element) => element.value == '')
                .map((e) => e.key)
                .first ==
            1) {
          locationData.removeAt(0);
          locationData.insert(
              0, AppSettingsMap(key: 0, value: 'Select Branch'));
        }
      } catch (ex) {
        debugPrint(ex.message.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            content: const Text('Do you want to exit Stock Transfer'),
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
                      setState(() {
                        _isLoading = true;
                        buttonEvent = true;
                      });
                      var inf = '[' +
                          json.encode({
                            'fromId': locationFromId,
                            'toId': locationToId
                          }) +
                          ']';
                      var jsonItem = CartItemST.encodeCartToJson(cartItem);
                      var items = json.encode(jsonItem);
                      var stType = 'Update';
                      var data = '[' +
                          json.encode({
                            'entryNo': dataDynamic[0]['EntryNo'],
                            'date': DateUtil.dateYMD(formattedDate),
                            'total': totalCartTotal,
                            'narration': _narration,
                            'Salesman': salesManId,
                            'location': '0',
                            'statementtype': stType,
                            'fyId': currentFinancialYear.id
                          }) +
                          ']';

                      final body = {
                        'information': inf,
                        'data': data,
                        'particular': items
                      };
                      bool _state = await dio.stockTransfer(body);
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
                    }
                  },
                  icon: const Icon(Icons.edit))
              : IconButton(
                  color: blue,
                  iconSize: 40,
                  onPressed: () async {
                    if (buttonEvent) {
                      return;
                    } else {
                      setState(() {
                        _isLoading = true;
                        buttonEvent = true;
                      });
                      var inf = '[' +
                          json.encode({
                            'fromId': locationFromId,
                            'toId': locationToId
                          }) +
                          ']';
                      var jsonItem = CartItemST.encodeCartToJson(cartItem);
                      var items = json.encode(jsonItem);
                      var stType = 'Insert';
                      var data = '[' +
                          json.encode({
                            'date': DateUtil.dateYMD(formattedDate),
                            'total': totalCartTotal,
                            'narration': _narration,
                            'Salesman': salesManId,
                            'location': '0',
                            'statementtype': stType,
                            'fyId': currentFinancialYear.id
                          }) +
                          ']';

                      final body = {
                        'information': inf,
                        'data': data,
                        'particular': items
                      };
                      bool _state = await dio.stockTransfer(body);
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
                    }
                  },
                  icon: const Icon(Icons.save)),
        ],
        title: const Text('Stock Transfer'),
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
          title: const Text('Stock Transfer'),
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
        var statement = 'StockTransferList';

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
    super.dispose();
  }

  int nextWidget = 0;
  Widget selectWidget() {
    return nextWidget == 0
        ? purchaseHeaderWidget()
        : nextWidget == 1
            ? selectProductWidget()
            : nextWidget == 2
                ? itemDetailWidget()
                : nextWidget == 3
                    ? cartProduct()
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
                    title: Text(dataDisplay[index]['StockFrom'] +
                        ' >>> ' +
                        dataDisplay[index]['StockTo']),
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
              const Text("No items in Stock Transfer"),
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
                  label: const Text('Take New Stock Transfer'))
            ],
          ));
  }

  bool isData = false;

  purchaseHeaderWidget() {
    return Center(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
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
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text(
                    'From',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 100,
                      width: 130,
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<int>(
                              hint: const Text('Select Branch'),
                              value: locationFromId,
                              items: locationData
                                  .map<DropdownMenuItem<int>>((value) {
                                return DropdownMenuItem<int>(
                                  value: value.key,
                                  child: Text(value.value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  locationFromId = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.forward),
                  const Text(
                    'To',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 100,
                      width: 130,
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<int>(
                              hint: const Text('Select Branch'),
                              value: locationToId,
                              items: locationData
                                  .map<DropdownMenuItem<int>>((value) {
                                return DropdownMenuItem<int>(
                                  value: value.key,
                                  child: Text(value.value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  locationToId = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
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
                nextWidget = 1;
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
    return FutureBuilder<List<StockItem>>(
      future: dio.fetchStockProductByLocation(
          locationFromId.toString(), DateUtil.dateDMY2YMD(formattedDate)),
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
                        child: SizedBox(
                          height: 40,
                          width: 200,
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
                                        var itemName = item.name.toLowerCase();
                                        return itemName.contains(text);
                                      }).toList();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : InkWell(
                        child: Card(
                          child: ListTile(
                            title: Text(itemDisplay[index - 1].name),
                            trailing:
                                Text('Qty :${itemDisplay[index - 1].quantity}'),
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

  itemDetailWidget() {
    keyItemsVariantStock = productModel.hasVariant;
    return productModel.hasVariant
        ? showVariantDialog(productModel.id, productModel.name,
            productModel.quantity.toString())
        : selectStockLedger();
  }

  selectStockLedger() {
    return FutureBuilder(
        future: dio.fetchStockVariant(productModel.id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.length > 0) {
              return itemDetails(snapshot.data[0]);
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
                            nextWidget = 1;
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
  showVariantDialog(int id, String name, String quantity) {
    return FutureBuilder<List<StockProduct>>(
      future: dio.fetchStockVariant(id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            return isVariantSelected
                ? itemDetails(snapshot.data[positionID])
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
                    : itemDetails(snapshot.data[0]);
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

  TextEditingController controllerQuantity = TextEditingController();
  TextEditingController controllerRate = TextEditingController();
  TextEditingController controllerDiscountPer = TextEditingController();
  TextEditingController controllerDiscount = TextEditingController();
  TextEditingController controllerMrp = TextEditingController();
  TextEditingController controllerRetail = TextEditingController();
  TextEditingController controllerWholeSale = TextEditingController();
  TextEditingController controllerBranch = TextEditingController();

  double quantity = 0,
      rate = 0,
      subTotal = 0,
      mrp = 0,
      retail = 0,
      wholeSale = 0,
      spRetail = 0,
      branch = 0,
      rRate = 0,
      rateOff = 0,
      unitValue = 1;
  String expDate = '1900-01-01', serialNo = '';
  int uniqueCode = 0, stUniqueCode = 0, fUnitId = 0, barcode = 0;
  bool editableMrp = false,
      editableRetail = false,
      editableWSale = false,
      editableBranch = false,
      editableRate = false,
      editableQuantity = false,
      editableDiscount = false,
      editableDiscountP = false,
      autoVariantSelect = false;

  itemDetails(StockProduct product) {
    if (editItem) {
      quantity = cartItem[position].quantity;
      uniqueCode = cartItem[position].uniqueCode;
      if (quantity > 0 && !editableQuantity) {
        controllerQuantity.text = quantity.toString();
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

      subTotal = cartItem.elementAt(position).gross;
    } else {
      uniqueCode = product.productId;
      rate = double.tryParse(product.buyingPrice.toString());
      if (rate > 0 && !editableRate) {
        controllerRate.text = rate.toString();
      }
      if (double.tryParse(product.buyingPriceReal.toString()) > 0) {
        rRate = double.tryParse(product.buyingPriceReal.toString());
      }
      mrp = double.tryParse(product.sellingPrice.toString());
      if (mrp > 0 && !editableMrp) {
        controllerMrp.text = mrp.toString();
      }
      retail = double.tryParse(product.retailPrice.toString());
      if (retail > 0 && !editableRetail) {
        controllerRetail.text = retail.toString();
      }
      wholeSale = double.tryParse(product.wholeSalePrice.toString());
      if (wholeSale > 0 && !editableWSale) {
        controllerWholeSale.text = wholeSale.toString();
      }
      spRetail = double.tryParse(product.spRetailPrice.toString());
      branch = double.tryParse(product.branch.toString());
      if (branch > 0 && !editableBranch) {
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
      rRate = taxMethod == 'MINUS'
          ? CommonService.getRound(decimal, (100 * rate) / (100))
          : rate;
      subTotal = CommonService.getRound(decimal, (rate * quantity));
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
                    'Item : ${editItem ? cartItem.elementAt(position).itemName : product.name}')),
            Row(
              children: [
                Expanded(
                    child: MaterialButton(
                  onPressed: () {
                    setState(() {
                      editItem = false;
                      nextWidget = 1;
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
                    bool cartQ = false;
                    setState(() {
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

                      if (product.quantity >= quantity) {
                        double cartS = 0, cartQt = 0;
                        for (var element in cartItem) {
                          if (element.uniqueCode == product.productId) {
                            cartQt += element.quantity;
                            cartS = element.stock;
                          }
                        }
                        if (cartS > 0) {
                          if (cartS < cartQt + quantity) {
                            cartQ = true;
                          }
                        }

                        if (cartQ) {
                          showInSnackBar('Available Qty is ${cartS - cartQt}');
                          isVariantSelected = false;
                        } else {
                          if (editItem) {
                            cartItem[position].barcode = barcode;
                            cartItem[position].branch = branch;
                            cartItem[position].gross = subTotal;
                            cartItem[position].mrp = mrp;
                            cartItem[position].quantity = quantity;
                            cartItem[position].rRate = rRate;
                            cartItem[position].rate = rate;
                            cartItem[position].retail = retail;
                            cartItem[position].serialNo = serialNo;
                            cartItem[position].spRetail = spRetail;
                            cartItem[position].uniqueCode = uniqueCode;
                            cartItem[position].unitValue = unitValue;
                            cartItem[position].wholesale = wholeSale;
                            cartItem[position].stUniqueCode = stUniqueCode;
                          } else {
                            cartItem.add(CartItemST(
                                barcode: barcode,
                                branch: branch,
                                gross: subTotal,
                                id: cartItem.length + 1,
                                itemId: product.itemId,
                                itemName: product.name,
                                mrp: mrp,
                                quantity: quantity,
                                rRate: rRate,
                                rate: rate,
                                retail: retail,
                                serialNo: serialNo,
                                spRetail: spRetail,
                                uniqueCode: uniqueCode,
                                unitId: 0,
                                unitName: '',
                                unitValue: unitValue,
                                wholesale: wholeSale,
                                stUniqueCode: stUniqueCode,
                                stock: product.quantity));
                          }
                          if (cartItem.isNotEmpty) {
                            nextWidget = 3;
                            editItem = false;
                            isVariantSelected = false;
                            clearValue();
                          }
                        }
                      } else {
                        showInSnackBar('Available Qty is ${product.quantity}');
                        isVariantSelected = false;
                      }
                    });
                  },
                  child: Text(editItem ? "Edit" : "Add"),
                  color: blue,
                )),
              ],
            ),
            const Divider(),
            TextField(
              controller: controllerQuantity,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                label: Text('Available Quantity is ${product.quantity}'),
              ),
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
            const Divider(),
            TextField(
              controller: controllerRate,
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
                SizedBox(
                  height: 30,
                  width: 100,
                  child: TextField(
                    controller: controllerMrp,
                    textAlign: TextAlign.right,
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
                  height: 30,
                  width: 100,
                  child: TextField(
                    controller: controllerRetail,
                    textAlign: TextAlign.right,
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
                    textAlign: TextAlign.right,
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
                  height: 30,
                  width: 100,
                  child: TextField(
                    controller: controllerBranch,
                    textAlign: TextAlign.right,
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
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  totalCartTotal.toStringAsFixed(decimal),
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
                      productModel = StockItem(
                          code: cartItem[index].itemId.toString(),
                          hasVariant: false,
                          id: cartItem[index].id,
                          name: cartItem[index].itemName,
                          quantity: cartItem[index].quantity);
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

  footerWidget() {
    calculateTotal();
    return Container(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Total : ',
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

  double taxTotalCartValue = 0, totalCartTotal = 0;
  calculateTotal() {
    taxTotalCartValue = 0;
    totalCartTotal = 0;
    for (var f in cartItem) {
      totalCartTotal += f.gross;
    }
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
    editableQuantity = false;
    editableMrp = false;
    editableRetail = false;
    editableWSale = false;
    editableBranch = false;
    editableRate = false;
    editableDiscount = false;
    editableDiscountP = false;
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
    String narration = '';

    api.fetchStockTransfer(data['Id'], 'Pr_Find').then((value) {
      if (value != null) {
        var information = value[0][0];
        var particulars = value[1];
        // var serialNO = value[2];
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
        narration = information['Narration'];
        locationFromId = information['Fromname'];
        locationToId = information['Toname'];
        cartItem.clear();
        for (var product in particulars) {
          double _gross = (double.tryParse(product['Rate'].toString()) *
              double.tryParse(product['Qty'].toString()));
          cartItem.add(CartItemST(
              barcode: barcode,
              branch: double.tryParse(product['Branch'].toString()),
              gross: _gross,
              id: cartItem.length + 1,
              itemId: int.parse(product['ItemName'].toString()),
              itemName: product['ProductName'].toString(),
              mrp: double.tryParse(product['MRP'].toString()),
              quantity: double.tryParse(product['Qty'].toString()),
              rRate: double.tryParse(product['RealPrate'].toString()),
              rate: double.tryParse(product['Rate'].toString()),
              retail: double.tryParse(product['Retail'].toString()),
              serialNo: '',
              spRetail: double.tryParse(product['SpRetail'].toString()),
              uniqueCode: product['Uniquecode'],
              unitId: product['Unit'],
              unitName: '',
              unitValue: double.tryParse(product['Unitvalue'].toString()),
              wholesale: double.tryParse(product['WsRate'].toString()),
              stUniqueCode: product['StockUniquecode'],
              stock: 0));
        }
      }

      setState(() {
        widgetID = false;
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
    dio.deleteStockTransfer(dataDynamic[0]['EntryNo'], 'Delete').then((value) {
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
                title: const Text('Stock Transfer Deleted'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/stockTransfer');
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

showMore(context, purchaseState) {
  ConfirmAlertBox(
      buttonColorForNo: Colors.white,
      buttonColorForYes: Colors.green,
      icon: Icons.check,
      onPressedYes: () {
        Navigator.of(context).pop();
        Navigator.pushReplacementNamed(context, '/stockTransfer');
      },
      // buttonTextForNo: 'No',
      buttonTextForYes: 'OK',
      infoMessage: 'Stock Transfer $purchaseState',
      title: 'SAVED',
      context: context);
}
