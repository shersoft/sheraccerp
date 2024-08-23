// @dart = 2.11
import 'dart:convert';

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:sheraccerp/app_settings_page.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/stock_product.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';

class StockManagement extends StatefulWidget {
  const StockManagement({Key key}) : super(key: key);

  @override
  State<StockManagement> createState() => _StockManagementState();
}

class _StockManagementState extends State<StockManagement> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime now = DateTime.now();
  String formattedDate, _narration = '';
  DioService api = DioService();

  TextEditingController _quantityController = TextEditingController();
  TextEditingController _addQuantityController = TextEditingController();
  TextEditingController _lessQuantityController = TextEditingController();
  TextEditingController _prateController = TextEditingController();
  TextEditingController _rPrateController = TextEditingController();
  TextEditingController _mrpController = TextEditingController();
  TextEditingController _retailController = TextEditingController();
  TextEditingController itemCodeController = TextEditingController();
  TextEditingController itemNameController = TextEditingController();

  List<StockManageCart> cartItem = [];
  GlobalKey<AutoCompleteTextFieldState<String>> keyItemCode = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyItemName = GlobalKey();
  var pItemCode = '', pItemName = '', pHSNCode = '';
  String entryNo = '0';
  bool isItemRateEditLocked = false, isEdit = false, isEditItem = false;

  List<DataJson> unitModel = [];
  List<String> itemNameList = [];
  List<String> itemCodeList = [];
  List<dynamic> productData = [];
  // List<dynamic> hsnList = [];
  List<dynamic> locationData = [];

  bool enableMULTIUNIT = false,
      cessOnNetAmount = false,
      enableKeralaFloodCess = false,
      useUNIQUECODEASBARCODE = false,
      useOLDBARCODE = false,
      buttonEvent = false,
      realPRATEBASEDPROFITPERCENTAGE = false,
      keyItemsVariantStock = false;
  int salesManId = 0, decimal = 2, locationFromId = 0, locationToId = 0;

  @override
  void initState() {
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    api.getProductData().then((value) {
      setState(() {
        productData = value.values.toList();
        // hsnList.addAll(List<String>.from(productData[0]['HSNCode']
        //     .map((item) => (item['name']))
        //     .toList()
        //     .map((s) => s as String)
        //     .toList()));
        itemCodeList.addAll(List<String>.from(productData[0]['ItemCode']
            .map((item) => (item['name']))
            .toList()
            .map((s) => s as String)
            .toList()));
        itemNameList.addAll(List<String>.from(productData[0]['ItemName']
            .map((item) => (item['name']))
            .toList()
            .map((s) => s as String)
            .toList()));
        // productList.addAll(List<dynamic>.from(productData[0]['ItemName'])
        //     .map((item) => (DataJson(id: item['id'], name: item['name']))));

        unitModel.addAll(DataJson.fromJsonList(productData[0]['Unit']));

        // dropDownUnitPurchase = unitModel[0].id;
        // dropDownUnitSale = unitModel[0].id;
        // dropDownUnitData = unitModel[0].id;
        // dropDownRateData = rateTypeModel[0].id;
      });
    });

    super.initState();
    loadSettings();
    api.getStockManageMentId().then((value) => {
          setState(() {
            entryNo = value > 0 ? value.toString() : '';
          })
        });
  }

  int lId = 0;
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
    isItemRateEditLocked =
        ComSettings.getStatus('KEY LOCK SALES RATE', settings);
    lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
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
        locationFromId = lId.toString().trim().isNotEmpty ? lId : 0;
      } catch (ex) {
        debugPrint(ex.message.toString());
      }
    }
  }

  void findProduct(String itemName) {
    api.getProductByName(itemName).then((value) {
      if (value != null) {
        if (value.slno > 0) {
          _slno = value.slno;
          itemCodeController.text = value.itemcode;
          itemNameController.text = value.itemname;
          pItemCode = value.itemcode;
          pItemName = value.itemname;
          addData(pItemCode);
        }
      }
    });
  }

  int _slno = 0;

  void findProductByCode(String itemCode) {
    api.getProductByCode(itemCode).then((value) {
      if (value != null) {
        _slno = value.slno;
        itemCodeController.text = value.itemcode;
        itemNameController.text = value.itemname;
        pItemCode = value.itemcode;
        pItemName = value.itemname;
        addData(pItemCode);
      }
    });
  }

  void findProductById(String id) {
    api.getProductById(id).then((value) {
      if (value != null) {
        _slno = value.slno;
        itemCodeController.text = value.itemcode;
        itemNameController.text = value.itemname;
        pItemCode = value.itemcode;
        pItemName = value.itemname;
        // addData(pItemCode);
      }
    });
  }

  addData(id) {
    selectStockLedger(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: (() {
                  if (cartItem.isNotEmpty) {
                    if (buttonEvent) {
                      return;
                    } else {
                      _updateStockItem();
                    }
                  } else {
                    Fluttertoast.showToast(msg: 'add data');
                  }
                }),
                child: Text(isEdit ? 'Edit' : 'Save'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.navigate_before_rounded),
                onPressed: (() {
                  _previousEntry();
                }),
                label: const Text(''),
              ),
              Text(entryNo),
              ElevatedButton.icon(
                onPressed: (() {
                  _nextEntry();
                }),
                icon: const Icon(Icons.navigate_next_rounded),
                label: const Text(''),
              ),
              ElevatedButton(
                onPressed: isEdit ? _deleteStockItem : null,
                child: const Text('Delete'),
              ),
            ],
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  onTap: () => _selectDate(),
                ),
                const SizedBox(
                  width: 10,
                ),
                const Text(
                  'Branch',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 40,
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
              ],
            ),
          ),
          ElevatedButton(
              onPressed: isEditItem
                  ? null
                  : () {
                      setState(() {
                        nextWidget = 1;
                      });
                    },
              child: const Text('Add New Item')),
          selectWidget()
        ],
      ),
    );
  }

  int nextWidget = 0;
  selectWidget() {
    return nextWidget == 1
        ? detailWidget()
        : nextWidget == 2
            ? allDetailWidget()
            : nextWidget == 3
                ? const Text('No Data')
                : const Text('No Data');
  }

  selectStockLedger(id) {
    api.fetchNoStockVariant(id).then((value) {
      if (value.length == 1) {
        var d = value[0];
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
            quantity: d['Qty'].toDouble(),
            retailPrice: d['retail'].toDouble(),
            sellingPrice: d['mrp'].toDouble(),
            spRetailPrice: d['Spretail'].toDouble(),
            stockValuation: d['stockvaluation'],
            tax: d['tax'].toDouble(),
            wholeSalePrice: d['WSrate'].toDouble());
        fillData(data);
      } else {
        List<StockProduct> dataS = [];
        for (var data in value) {
          dataS.add(StockProduct.fromJson(data));
        }
        showAddMore(context, dataS);
      }
    });
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

  showAddMore(BuildContext context, List<StockProduct> data) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SizedBox(
              width: double.maxFinite,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Expanded(
                    child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      child: ListTile(
                        title: Text(data[index].name),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('Id:${data[index].productId}'),
                            Text('Qty: ${data[index].quantity}'),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        fillData(data[index]);
                      },
                    );
                  },
                ))
              ]),
            ),
          );
        });
  }

  fillData(StockProduct data) {
    _quantityController.text = data.quantity.toString();
    _prateController.text = data.buyingPrice.toString();
    _rPrateController.text = data.buyingPriceReal.toString();
    _mrpController.text = data.sellingPrice.toString();
    _retailController.text = data.retailPrice.toString();
    wholeSale = data.wholeSalePrice;
    spRetailPrice = data.spRetailPrice;
    branch = data.branch;
    barcode = data.productId;
    itemId = data.itemId;
  }

  double wholeSale = 0, spRetailPrice = 0, branch = 0;
  int barcode = 0, itemId = 0;

  void _updateStockItem() {
    var items = cartItem; //json.encode(cartItem);
    var stType = isEdit ? 'Update' : 'Insert';
    var data = [
      {
        'entryNo': entryNo,
        'date': DateUtil.dateYMD(formattedDate),
        'narration': _narration,
        'salesman': salesManId,
        'location': locationFromId,
        'statementType': stType,
        'app': '1',
        'fyId': currentFinancialYear.id
      }
    ];
    var inf = [
      {'fromId': locationFromId}
    ];
    final body = {'information': inf, 'data': data, 'particular': items};
    api.stockManagementUpdate(body).then((value) {
      if (value) {
        Fluttertoast.showToast(msg: isEdit ? 'Edited' : 'Saved');
      } else {
        Fluttertoast.showToast(msg: 'error');
      }
      buttonEvent = false;
    });
  }

  void _nextEntry() {
    entryNo = (int.parse(entryNo) + 1).toString();
    searchEntry();
  }

  void _deleteStockItem() {
    api.stockManagementDelete(entryNo).then((value) {
      setState(() {
        if (value) {
          Fluttertoast.showToast(msg: 'Deleted');
          cartItem.clear();
          clear();
        } else {
          Fluttertoast.showToast(msg: 'error');
        }
      });
    });
  }

  void _previousEntry() {
    entryNo = (int.parse(entryNo) - 1).toString();
    searchEntry();
  }

  searchEntry() {
    cartItem.clear();
    api.stockManagementFind(entryNo).then(
      (value) {
        if (value != null) {
          if (value[0].isNotEmpty) {
            var information = value[0][0]; //info
            var particlars = value[1]; //part
            formattedDate = DateUtil.dateDMY(information['DDate']);
            _narration = information['Narration'];
            salesManId = information['SalesMan'];
            var rId = information['RealEntryNo'];
            var app = information['app'];
            locationFromId = information['Location'];
            for (var items in particlars) {
              cartItem.add(StockManageCart(
                  id: items['ItemName'],
                  itemName: items['name'],
                  barcode: items['Uniquecode'],
                  itemCode: items['itemcode'],
                  itemId: items['ItemName'],
                  pRate: double.parse(items['PRate'].toString()),
                  rPRate: double.parse(items['RealPrate'].toString()),
                  stock: double.parse(items['Stock'].toString()),
                  aQty: double.parse(items['AQty'].toString()),
                  lQty: double.parse(items['LQty'].toString()),
                  mrp: double.parse(items['MRP'].toString()),
                  retail: double.parse(items['Retail'].toString()),
                  wholesale: double.parse(items['WSRate'].toString()),
                  spRetail: double.parse(items['SpRetail'].toString()),
                  branch: double.parse(items['Branch'].toString()),
                  unit: int.parse(items['Unit'].toString()),
                  unitValue: double.parse(items['Unitvalue'].toString()),
                  location: int.parse(items['Location'].toString()),
                  active: int.parse(items['Active'].toString()),
                  reOrderLevel: int.parse(items['ReOrderLevel'].toString()),
                  maxOrderLevel: int.parse(items['MaxOrderLevel'].toString())));
            }
            isEdit = true;
          } else {
            isEdit = false;
          }
        } else {
          isEdit = false;
        }
        setState(() {
          nextWidget = 2;
        });
      },
    );
  }

  detailWidget() {
    return Column(
      children: [
        SimpleAutoCompleteTextField(
          key: keyItemCode,
          controller: itemCodeController,
          clearOnSubmit: false,
          suggestions: itemCodeList,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: 'Item Code'),
          textSubmitted: (data) {
            pItemCode = data;
            if (pItemCode.isNotEmpty) {
              findProductByCode(pItemCode);
            }
          },
        ),
        const SizedBox(
          height: 10,
        ),
        SimpleAutoCompleteTextField(
          key: keyItemName,
          controller: itemNameController,
          clearOnSubmit: false,
          suggestions: itemNameList,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: 'Item Name'),
          textSubmitted: (data) {
            pItemName = data;
            if (pItemName.isNotEmpty) {
              findProduct(pItemName);
            }
          },
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                    labelText: 'Quantity', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: TextField(
                controller: _addQuantityController,
                decoration: const InputDecoration(
                    labelText: 'Add', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: TextField(
                controller: _lessQuantityController,
                decoration: const InputDecoration(
                    labelText: 'Less', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                readOnly: true,
                controller: _prateController,
                decoration: const InputDecoration(
                    labelText: 'Prate', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: TextField(
                readOnly: true,
                controller: _rPrateController,
                decoration: const InputDecoration(
                    labelText: 'RPrate', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                readOnly: true,
                controller: _mrpController,
                decoration: const InputDecoration(
                    labelText: 'MRP', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: TextField(
                readOnly: true,
                controller: _retailController,
                decoration: const InputDecoration(
                    labelText: 'Retail', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        ElevatedButton(
            onPressed: () {
              setState(() {
                isEditItem ? updateProduct() : _addStockItem();
                nextWidget = 2;
              });
            },
            child: const Text('Add'))
      ],
    );
  }

  allDetailWidget() {
    return cartItem.isNotEmpty
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
                      const Text("Qty",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(cartItem[index].stock.toString(),
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      const Text("Add",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(cartItem[index].aQty.toString(),
                          style: const TextStyle(
                              color: Colors.black, fontSize: 12)),
                      const Text("Less",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(cartItem[index].lQty.toString(),
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Card(
                          color: Colors.green[200],
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.black,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                isEditItem = true;
                                _slno = cartItem[index].id;
                                itemCodeController.text =
                                    cartItem[index].itemCode.toString();
                                itemNameController.text =
                                    cartItem[index].itemName;
                                pItemCode = cartItem[index].itemCode.toString();
                                pItemName = cartItem[index].itemName;
                                _addQuantityController.text =
                                    cartItem[index].aQty.toString();
                                _lessQuantityController.text =
                                    cartItem[index].lQty.toString();
                                fillData(StockProduct(
                                    adCessPer: 0,
                                    branch: cartItem[index].branch,
                                    buyingPrice: cartItem[index].pRate,
                                    buyingPriceReal: cartItem[index].rPRate,
                                    cess: 0,
                                    cessPer: 0,
                                    hsnCode: '',
                                    itemId: cartItem[index].itemId,
                                    minimumRate: 0,
                                    name: cartItem[index].itemName,
                                    productId: cartItem[index].id,
                                    quantity: cartItem[index].stock,
                                    retailPrice: cartItem[index].retail,
                                    sellingPrice: cartItem[index].mrp,
                                    spRetailPrice: cartItem[index].spRetail,
                                    stockValuation: '',
                                    tax: 0,
                                    wholeSalePrice: cartItem[index].wholesale));
                                nextWidget = 1;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Card(
                          color: Colors.red[200],
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.black,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                removeProduct(index);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        : const Center(child: Text("No items in Cart"));
  }

  void _addStockItem() {
    String _prate =
        _prateController.text.isNotEmpty ? _prateController.text : '0';
    String _rPrate =
        _rPrateController.text.isNotEmpty ? _rPrateController.text : '0';
    String _qty =
        _quantityController.text.isNotEmpty ? _quantityController.text : '0';
    String _addQty = _addQuantityController.text.isNotEmpty
        ? _addQuantityController.text
        : '0';
    String _lessQty = _lessQuantityController.text.isNotEmpty
        ? _lessQuantityController.text
        : '0';
    String _mrp = _mrpController.text.isNotEmpty ? _mrpController.text : '0';
    String _retail =
        _retailController.text.isNotEmpty ? _retailController.text : '0';
    locationFromId = locationFromId == 0 ? 1 : locationFromId;

    StockManageCart data = StockManageCart(
        id: _slno,
        itemName: pItemName,
        itemCode: pItemCode,
        barcode: barcode,
        itemId: itemId,
        pRate: double.parse(_prate),
        rPRate: double.parse(_rPrate),
        stock: double.parse(_qty),
        aQty: double.parse(_addQty),
        lQty: double.parse(_lessQty),
        mrp: double.parse(_mrp),
        retail: double.parse(_retail),
        wholesale: wholeSale,
        spRetail: spRetailPrice,
        branch: branch,
        unit: 0,
        unitValue: 1,
        location: locationFromId,
        active: 1,
        reOrderLevel: 0,
        maxOrderLevel: 0);
    cartItem.add(data);
    clear();
  }

  void clear() {
    itemCodeController.clear();
    itemNameController.clear();
    _quantityController.clear();
    _addQuantityController.clear();
    _lessQuantityController.clear();
    _prateController.clear();
    _rPrateController.clear();
    _mrpController.clear();
    _retailController.clear();
    _slno = 0;
    pItemCode = '';
    pItemName = '';
    wholeSale = 0;
    spRetailPrice = 0;
    branch = 0;
    barcode = 0;
    itemId = 0;
  }

  void removeProduct(int index) {
    cartItem.removeAt(index);
  }

  void updateProduct() {
    String _prate =
        _prateController.text.isNotEmpty ? _prateController.text : '0';
    String _rPrate =
        _rPrateController.text.isNotEmpty ? _rPrateController.text : '0';
    String _qty =
        _quantityController.text.isNotEmpty ? _quantityController.text : '0';
    String _addQty = _addQuantityController.text.isNotEmpty
        ? _addQuantityController.text
        : '0';
    String _lessQty = _lessQuantityController.text.isNotEmpty
        ? _lessQuantityController.text
        : '0';
    String _mrp = _mrpController.text.isNotEmpty ? _mrpController.text : '0';
    String _retail =
        _retailController.text.isNotEmpty ? _retailController.text : '0';
    locationFromId = locationFromId == 0 ? 1 : locationFromId;

    StockManageCart product = StockManageCart(
        id: _slno,
        itemName: pItemName,
        barcode: barcode,
        itemId: itemId,
        pRate: double.parse(_prate),
        rPRate: double.parse(_rPrate),
        stock: double.parse(_qty),
        aQty: double.parse(_addQty),
        lQty: double.parse(_lessQty),
        mrp: double.parse(_mrp),
        retail: double.parse(_retail),
        wholesale: wholeSale,
        spRetail: spRetailPrice,
        branch: branch,
        unit: 0,
        unitValue: 1,
        location: locationFromId,
        active: 1,
        reOrderLevel: 0,
        maxOrderLevel: 0);

    int index = cartItem.indexWhere((i) => i.id == product.id);
    cartItem[index] = product;
    clear();
    isEditItem = false;
  }
}

class StockManageCart {
  int id;
  String itemName;
  String itemCode;
  int barcode;
  int itemId;
  double pRate;
  double rPRate;
  double stock;
  double aQty;
  double lQty;
  double mrp;
  double retail;
  double wholesale;
  double spRetail;
  double branch;
  int unit;
  double unitValue; //': 1, //unitModel!=null? unitModel.id:0,
  int location; //': locationFromId,
  int active; //': 1,
  int reOrderLevel; //': 0,
  int maxOrderLevel; //': 0
  StockManageCart({
    this.id,
    this.itemName,
    this.itemCode,
    this.barcode,
    this.itemId,
    this.pRate,
    this.rPRate,
    this.stock,
    this.aQty,
    this.lQty,
    this.mrp,
    this.retail,
    this.wholesale,
    this.spRetail,
    this.branch,
    this.unit,
    this.unitValue,
    this.location,
    this.active,
    this.reOrderLevel,
    this.maxOrderLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'itemCode': itemCode,
      'barcode': barcode,
      'itemId': itemId,
      'pRate': pRate,
      'rPRate': rPRate,
      'stock': stock,
      'aQty': aQty,
      'lQty': lQty,
      'mrp': mrp,
      'retail': retail,
      'wholesale': wholesale,
      'spRetail': spRetail,
      'branch': branch,
      'unit': unit,
      'unitValue': unitValue,
      'location': location,
      'active': active,
      'reOrderLevel': reOrderLevel,
      'maxOrderLevel': maxOrderLevel,
    };
  }

  factory StockManageCart.fromMap(Map<String, dynamic> map) {
    return StockManageCart(
      id: map['id']?.toInt() ?? 0,
      itemName: map['itemName'] ?? '',
      itemCode: map['itemCode'] ?? '',
      barcode: map['barcode']?.toInt() ?? 0,
      itemId: map['itemId']?.toInt() ?? 0,
      pRate: map['pRate']?.toDouble() ?? 0.0,
      rPRate: map['rPRate']?.toDouble() ?? 0.0,
      stock: map['stock']?.toDouble() ?? 0.0,
      aQty: map['aQty']?.toDouble() ?? 0.0,
      lQty: map['lQty']?.toDouble() ?? 0.0,
      mrp: map['mrp']?.toDouble() ?? 0.0,
      retail: map['retail']?.toDouble() ?? 0.0,
      wholesale: map['wholesale']?.toDouble() ?? 0.0,
      spRetail: map['spRetail']?.toDouble() ?? 0.0,
      branch: map['branch']?.toDouble() ?? 0.0,
      unit: map['unit']?.toInt() ?? 0,
      unitValue: map['unitValue']?.toDouble() ?? 0.0,
      location: map['location']?.toInt() ?? 0,
      active: map['active']?.toInt() ?? 0,
      reOrderLevel: map['reOrderLevel']?.toInt() ?? 0,
      maxOrderLevel: map['maxOrderLevel']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory StockManageCart.fromJson(String source) =>
      StockManageCart.fromMap(json.decode(source));

  @override
  String toString() {
    return 'StockManageCart(id: $id, itemName: $itemName, itemCode: $itemCode, barcode: $barcode, itemId: $itemId, pRate: $pRate, rPRate: $rPRate, stock: $stock, aQty: $aQty, lQty: $lQty, mrp: $mrp, retail: $retail, wholesale: $wholesale, spRetail: $spRetail, branch: $branch, unit: $unit, unitValue: $unitValue, location: $location, active: $active, reOrderLevel: $reOrderLevel, maxOrderLevel: $maxOrderLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StockManageCart &&
        other.id == id &&
        other.itemName == itemName &&
        other.itemCode == itemCode &&
        other.barcode == barcode &&
        other.itemId == itemId &&
        other.pRate == pRate &&
        other.rPRate == rPRate &&
        other.stock == stock &&
        other.aQty == aQty &&
        other.lQty == lQty &&
        other.mrp == mrp &&
        other.retail == retail &&
        other.wholesale == wholesale &&
        other.spRetail == spRetail &&
        other.branch == branch &&
        other.unit == unit &&
        other.unitValue == unitValue &&
        other.location == location &&
        other.active == active &&
        other.reOrderLevel == reOrderLevel &&
        other.maxOrderLevel == maxOrderLevel;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        itemName.hashCode ^
        itemCode.hashCode ^
        barcode.hashCode ^
        itemId.hashCode ^
        pRate.hashCode ^
        rPRate.hashCode ^
        stock.hashCode ^
        aQty.hashCode ^
        lQty.hashCode ^
        mrp.hashCode ^
        retail.hashCode ^
        wholesale.hashCode ^
        spRetail.hashCode ^
        branch.hashCode ^
        unit.hashCode ^
        unitValue.hashCode ^
        location.hashCode ^
        active.hashCode ^
        reOrderLevel.hashCode ^
        maxOrderLevel.hashCode;
  }
}
