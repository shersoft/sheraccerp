// @dart = 2.11
import 'dart:convert';

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/app_settings_page.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/stock_product.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:intl/intl.dart';
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

  List<StockItemS> stockList = [];
  GlobalKey<AutoCompleteTextFieldState<String>> keyItemCode = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyItemName = GlobalKey();
  var pItemCode = '', pItemName = '', pHSNCode = '';
  String entryNo = '0';
  bool isEdit = false;

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

  void findProduct(String pItemName) {
    api.getProductByName(pItemName).then((value) {
      if (value != null) {
        if (value.slno > 0) {
          itemCodeController.text = value.itemcode;
          itemNameController.text = value.itemname;
          pItemCode = value.itemcode;
          pItemName = value.itemname;
          addData(pItemCode);
        }
      }
    });
  }

  void findProductByCode(String itemCode) {
    api.getProductByCode(itemCode).then((value) {
      if (value != null) {
        itemCodeController.text = value.itemcode;
        itemNameController.text = value.itemname;
        pItemCode = value.itemcode;
        pItemName = value.itemname;
        addData(pItemCode);
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: (() {
                    if (_addQuantityController.text.isNotEmpty ||
                        _lessQuantityController.text.isNotEmpty) {
                      _updateStockItem();
                    } else {
                      Fluttertoast.showToast(msg: 'add data');
                    }
                  }),
                  child: const Text('Save'),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.navigate_before_rounded),
                  onPressed: (() {
                    _nextEntry();
                  }),
                  label: const Text(''),
                ),
                Text(entryNo),
                ElevatedButton.icon(
                  onPressed: (() {
                    _previousEntry();
                  }),
                  icon: Icon(Icons.navigate_next_rounded),
                  label: const Text(''),
                ),
                ElevatedButton(
                  onPressed: _deleteStockItem,
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
                ],
              ),
            ),
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
                    keyboardType: TextInputType.number,
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
                    keyboardType: TextInputType.number,
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
                    keyboardType: TextInputType.number,
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
                    keyboardType: TextInputType.number,
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
                    keyboardType: TextInputType.number,
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
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  selectStockLedger(id) {
    List<StockProduct> listData = [];
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

  void _addStockItem() {
    // Implement logic to add the new stock item to the stock listing
    // You can store the stock item in a list or database.
    // For simplicity, let's assume you have a List<StockItem> named 'stockList'.

    // Create a new StockItem object with the entered information
    StockItemS newStockItem = StockItemS(
      name: itemNameController.text,
      quantity: int.parse(_quantityController.text),
      price: double.parse(_prateController.text),
      supplier: _retailController.text,
      // Add any other relevant details
    );

    // Add the new stock item to the list
    stockList.add(newStockItem);

    // Clear the text fields after submission
    itemCodeController.clear();
    itemNameController.clear();
    _quantityController.clear();
    _prateController.clear();
    _rPrateController.clear();
    _mrpController.clear();
    _retailController.clear();

    // Show a success message or navigate back to the stock listing screen
    // You can use a Snackbar or a Dialog to display the success message.
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
                            Text('Id:${data[0].productId}'),
                            Text('Qty: ${data[0].quantity}'),
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
    var items = json.encode([
      {
        'barcode': barcode,
        'itemId': itemId,
        'pRate': double.parse(_prate),
        'rPRate': double.parse(_rPrate),
        'stock': double.parse(_qty),
        'aQty': double.parse(_addQty),
        'lQty': double.parse(_lessQty),
        'mrp': double.parse(_mrp),
        'retail': double.parse(_retail),
        'wholesale': wholeSale,
        'spRetail': spRetailPrice,
        'branch': branch,
        'unit': 0, //unit,
        'unitValue': 1, //unitModel!=null? unitModel.id:0,
        'location': locationFromId,
        'active': 1,
        'reOrderLevel': 0,
        'maxOrderLevel': 0
      }
    ]);
    var stType = isEdit ? 'Update' : 'Insert';
    var data = '[' +
        json.encode({
          'entryNo': entryNo,
          'date': DateUtil.dateYMD(formattedDate),
          'narration': _narration,
          'salesman': salesManId,
          'location': locationFromId,
          'statementType': stType,
          'fyId': currentFinancialYear.id
        }) +
        ']';
    var inf = '[' + json.encode({'fromId': locationFromId}) + ']';
    final body = {'information': inf, 'data': data, 'particular': items};
    api.stockManagementUpdate(body).then((value) {
      if (value) {
        Fluttertoast.showToast(msg: isEdit ? 'Edited' : 'Saved');
      } else {
        Fluttertoast.showToast(msg: 'error');
      }
    });
  }

  void _nextEntry() {}

  void _deleteStockItem() {}

  void _previousEntry() {}
}

class StockItemS {
  String name;
  int quantity;
  double price;
  String supplier;
  StockItemS({
    this.name,
    this.quantity,
    this.price,
    this.supplier,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'supplier': supplier,
    };
  }

  factory StockItemS.fromMap(Map<String, dynamic> map) {
    return StockItemS(
      name: map['name'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      price: map['price']?.toDouble() ?? 0.0,
      supplier: map['supplier'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory StockItemS.fromJson(String source) =>
      StockItemS.fromMap(json.decode(source));
}
