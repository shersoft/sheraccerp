// @dart = 2.11
import 'dart:convert';

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:sheraccerp/models/product_register_model.dart';
import 'package:sheraccerp/models/tax_group_model.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/screens/accounts/ledger.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/util/show_confirm_alert_box.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class ProductRegister extends StatefulWidget {
  const ProductRegister({Key key}) : super(key: key);

  @override
  _ProductRegisterState createState() => _ProductRegisterState();
}

class _ProductRegisterState extends State<ProductRegister> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DioService api = DioService();
  DataJson productModel;
  Size deviceSize;
  String productId = '';
  List<DataJson> productList = [];
  bool _isLoading = false, isExist = false, buttonEvent = false;
  DataJson itemId,
      itemName,
      supplier,
      mfr,
      category,
      subCategory,
      location = DataJson(id: 1, name: defaultLocation),
      rack,
      unit;
  TaxGroupModel taxGroup;
  List<String> hsnList = [];
  List<String> itemNameList = [];
  List<String> itemCodeList = [];
  List<dynamic> productData = [];
  List<String> stockValuationData = ['AVERAGE VALUE', 'LAST PRATE', 'REAL'];
  List<String> typeOfSupplyData = ['GOODS', 'SERVICE'];
  var pItemCode = '', pItemName = '', pHSNCode = '';
  bool active = true;
  var dropDownStockValuation = 'AVERAGE VALUE', dropDownTypeOfSupply = 'GOODS';
  int dropDownUnit = 0, dropDownUnitPurchase, dropDownUnitSale;
  List<DataJson> unitModel = [];
  List<DataJson> rateTypeModel = [];
  List<UnitDetailModel> unitDetail = [];
  String _result;
  String isItemName = '';

  @override
  void initState() {
    api.getProductData().then((value) {
      setState(() {
        productData = value.values.toList();
        hsnList.addAll(List<String>.from(productData[0]['HSNCode']
            .map((item) => (item['name']))
            .toList()
            .map((s) => s as String)
            .toList()));
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

        unitModel.addAll(DataJson.fromJsonList(productData[0]['Unit']));
        rateTypeModel = [
          DataJson(id: 0, name: ''),
          DataJson(id: 1, name: 'MRP'),
          DataJson(id: 2, name: 'RETAIL'),
          DataJson(id: 3, name: 'WHOLESALE'),
          DataJson(id: 4, name: 'SPRATE'),
          DataJson(id: 5, name: 'BRANCH')
        ];
        dropDownUnitPurchase = unitModel[0].id;
        dropDownUnitSale = unitModel[0].id;
        dropDownUnitData = unitModel[0].id;
        dropDownRateData = rateTypeModel[0].id;
      });
    });
    api.getProductId().then((value) => {
          setState(() {
            itemCodeController.text = value > 0 ? value.toString() : '';
          })
        });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final routes =
        ModalRoute.of(context).settings.arguments as Map<String, String>;
    isItemName = routes != null ? routes['name'].toString() : '';
    if (isItemName.isNotEmpty) {
      pItemName = isItemName;
      findProduct(pItemName);
    }
    deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              // var result = await showSearch<List<DataJson>>(
              //   context: context,
              //   delegate: CustomDelegateProduct(productList),
              // );

              setState(() {
                // _result = result[0].name;
                // pItemName = _result;
                // productId = result[0].id.toString();
                if (pItemName.isNotEmpty) {
                  findProduct(pItemName);
                }
              });
            },
          ),
          Visibility(
            visible: isExist,
            child: IconButton(
                color: red,
                iconSize: 40,
                onPressed: () async {
                  if (buttonEvent) {
                    return;
                  } else {
                    if (companyUserData.deleteData) {
                      if (productId.isNotEmpty) {
                        setState(() {
                          _isLoading = true;
                        });
                        bool _state = await api.deleteProduct(productId);
                        setState(() {
                          _isLoading = false;
                        });
                        _state
                            ? showInSnackBar('Product Deleted')
                            : showInSnackBar('Error');
                      } else {
                        showInSnackBar('Select product');
                        setState(() {
                          buttonEvent = false;
                        });
                      }
                    } else {
                      showInSnackBar('Permission denied\ncan`t delete');
                      setState(() {
                        buttonEvent = false;
                      });
                    }
                  }
                },
                icon: const Icon(Icons.delete_forever)),
          ),
          isExist
              ? IconButton(
                  color: green,
                  iconSize: 40,
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    var jsonItem = UnitDetailModel.encodeCartToJson(unitDetail);
                    var items = json.encode(jsonItem);
                    var data = '[' +
                        json.encode({
                          'id': productId.isNotEmpty ? productId : '0',
                          'hsnCode': hsnController.text.trim().isNotEmpty
                              ? hsnController.text.trim()
                              : '',
                          'itemCode': itemCodeController.text.trim().isNotEmpty
                              ? itemCodeController.text.trim()
                              : '',
                          'itemName': itemNameController.text.trim().isNotEmpty
                              ? itemNameController.text.trim()
                              : '',
                          'categoryId': category != null ? category.id : 0,
                          'mfrId': mfr != null ? mfr.id : 0,
                          'subCategoryId':
                              subCategory != null ? subCategory.id : 0,
                          'unitId': unit != null ? unit.id : 0,
                          'rackId': rack != null ? rack.id : 0,
                          'packing': packingController.text.trim().isNotEmpty
                              ? packingController.text.trim()
                              : 0,
                          'reOrder':
                              reOrderLevelController.text.trim().isNotEmpty
                                  ? reOrderLevelController.text.trim()
                                  : 0,
                          'maxOrder':
                              maxOrderLevelController.text.trim().isNotEmpty
                                  ? maxOrderLevelController.text.trim()
                                  : 0,
                          'taxGroupId': taxGroup != null ? taxGroup.id : 0,
                          'tax': taxGroup != null ? taxGroup.gst : 0,
                          'cess': cessController.text.trim().isNotEmpty
                              ? double.tryParse(cessController.text.trim()) > 0
                                  ? 1
                                  : 0
                              : 0,
                          'cessPer': cessController.text.trim().isNotEmpty
                              ? double.tryParse(cessController.text.trim()) > 0
                                  ? double.tryParse(cessController.text.trim())
                                  : 0
                              : 0,
                          'addCessPer': addCessController.text.trim().isNotEmpty
                              ? double.tryParse(addCessController.text.trim()) >
                                      0
                                  ? double.tryParse(
                                      addCessController.text.trim())
                                  : 0
                              : 0,
                          'mrp': mrpController.text.trim().isNotEmpty
                              ? double.tryParse(mrpController.text.trim()) > 0
                                  ? double.tryParse(mrpController.text.trim())
                                  : 0
                              : 0,
                          'retail': retailController.text.trim().isNotEmpty
                              ? double.tryParse(retailController.text.trim()) >
                                      0
                                  ? double.tryParse(
                                      retailController.text.trim())
                                  : 0
                              : 0,
                          'wsRate': wholeSaleController.text.trim().isNotEmpty
                              ? double.tryParse(
                                          wholeSaleController.text.trim()) >
                                      0
                                  ? double.tryParse(
                                      wholeSaleController.text.trim())
                                  : 0
                              : 0,
                          'spRetail': spRetailController.text.trim().isNotEmpty
                              ? double.tryParse(
                                          spRetailController.text.trim()) >
                                      0
                                  ? double.tryParse(
                                      spRetailController.text.trim())
                                  : 0
                              : 0,
                          'branch': branchController.text.trim().isNotEmpty
                              ? double.tryParse(branchController.text.trim()) >
                                      0
                                  ? double.tryParse(
                                      branchController.text.trim())
                                  : 0
                              : 0,
                          'stockValuation': dropDownStockValuation,
                          'typeOfSupply': dropDownTypeOfSupply,
                          'negative': 0,
                          'active': active ? 1 : 0,
                          'bom': 0,
                          'serialNo': 0,
                          'user': 0,
                        }) +
                        ']';

                    final body = {'product': data, 'unitDetails': items};
                    bool _state = await api.editProduct(body);
                    setState(() {
                      _isLoading = false;
                    });
                    _state
                        ? showInSnackBar('Product Edited')
                        : showInSnackBar('Error');
                  },
                  icon: const Icon(Icons.edit))
              : IconButton(
                  color: white,
                  iconSize: 40,
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    var jsonItem = UnitDetailModel.encodeCartToJson(unitDetail);
                    var items = json.encode(jsonItem);
                    var data = '[' +
                        json.encode({
                          'id': productId.isNotEmpty ? productId : '0',
                          'hsnCode': hsnController.text.trim().isNotEmpty
                              ? hsnController.text.trim()
                              : '',
                          'itemCode': itemCodeController.text.trim().isNotEmpty
                              ? itemCodeController.text.trim()
                              : '',
                          'itemName': itemNameController.text.trim().isNotEmpty
                              ? itemNameController.text.trim()
                              : '',
                          'categoryId': category != null ? category.id : 0,
                          'mfrId': mfr != null ? mfr.id : 0,
                          'subCategoryId':
                              subCategory != null ? subCategory.id : 0,
                          'unitId': unit != null ? unit.id : 0,
                          'rackId': rack != null ? rack.id : 0,
                          'packing': packingController.text.trim().isNotEmpty
                              ? packingController.text.trim()
                              : 0,
                          'reOrder':
                              reOrderLevelController.text.trim().isNotEmpty
                                  ? reOrderLevelController.text.trim()
                                  : 0,
                          'maxOrder':
                              maxOrderLevelController.text.trim().isNotEmpty
                                  ? maxOrderLevelController.text.trim()
                                  : 0,
                          'taxGroupId': taxGroup != null ? taxGroup.id : 0,
                          'tax': taxGroup != null ? taxGroup.gst : 0,
                          'cess': cessController.text.trim().isNotEmpty
                              ? double.tryParse(cessController.text.trim()) > 0
                                  ? 1
                                  : 0
                              : 0,
                          'cessPer': cessController.text.trim().isNotEmpty
                              ? double.tryParse(cessController.text.trim()) > 0
                                  ? double.tryParse(cessController.text.trim())
                                  : 0
                              : 0,
                          'addCessPer': addCessController.text.trim().isNotEmpty
                              ? double.tryParse(addCessController.text.trim()) >
                                      0
                                  ? double.tryParse(
                                      addCessController.text.trim())
                                  : 0
                              : 0,
                          'mrp': mrpController.text.trim().isNotEmpty
                              ? double.tryParse(mrpController.text.trim()) > 0
                                  ? double.tryParse(mrpController.text.trim())
                                  : 0
                              : 0,
                          'retail': retailController.text.trim().isNotEmpty
                              ? double.tryParse(retailController.text.trim()) >
                                      0
                                  ? double.tryParse(
                                      retailController.text.trim())
                                  : 0
                              : 0,
                          'wsRate': wholeSaleController.text.trim().isNotEmpty
                              ? double.tryParse(
                                          wholeSaleController.text.trim()) >
                                      0
                                  ? double.tryParse(
                                      wholeSaleController.text.trim())
                                  : 0
                              : 0,
                          'spRetail': spRetailController.text.trim().isNotEmpty
                              ? double.tryParse(
                                          spRetailController.text.trim()) >
                                      0
                                  ? double.tryParse(
                                      spRetailController.text.trim())
                                  : 0
                              : 0,
                          'branch': branchController.text.trim().isNotEmpty
                              ? double.tryParse(branchController.text.trim()) >
                                      0
                                  ? double.tryParse(
                                      branchController.text.trim())
                                  : 0
                              : 0,
                          'stockValuation': dropDownStockValuation,
                          'typeOfSupply': dropDownTypeOfSupply,
                          'negative': 0,
                          'active': active ? 1 : 0,
                          'bom': 0,
                          'serialNo': 0,
                          'user': 0,
                        }) +
                        ']';

                    final body = {'product': data, 'unitDetails': items};
                    bool _state = await api.addProduct(body);
                    setState(() {
                      _isLoading = false;
                    });
                    _state
                        ? showInSnackBar('Product Saved')
                        : showInSnackBar('Error');
                  },
                  icon: const Icon(Icons.save)),
        ],
        title: const Text('Product Register'),
      ),
      body: ProgressHUD(
          inAsyncCall: _isLoading, opacity: 0.0, child: formWidget()),
    );
  }

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  GlobalKey<AutoCompleteTextFieldState<String>> keyHsn = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyItemCode = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyItemName = GlobalKey();
  int nextWidget = 0;
  TextEditingController mrpController = TextEditingController();
  TextEditingController retailController = TextEditingController();
  TextEditingController wholeSaleController = TextEditingController();
  TextEditingController spRetailController = TextEditingController();
  TextEditingController branchController = TextEditingController();
  TextEditingController hsnController = TextEditingController();

  TextEditingController itemCodeController = TextEditingController();
  TextEditingController itemNameController = TextEditingController();
  TextEditingController packingController = TextEditingController();
  TextEditingController maxOrderLevelController = TextEditingController();
  TextEditingController reOrderLevelController = TextEditingController();
  TextEditingController cessController = TextEditingController();
  TextEditingController addCessController = TextEditingController();

  formWidget() {
    return nextWidget == 0
        ? ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: SimpleAutoCompleteTextField(
                      clearOnSubmit: false,
                      key: keyHsn,
                      suggestions: hsnList,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), labelText: 'HSN Code'),
                      textSubmitted: (data) {
                        pHSNCode = data;
                      },
                      controller: hsnController,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.settings, color: blue),
                    onSelected: (value) {
                      // Handle menu item selection
                      setState(() {
                        // Perform actions based on the selected value
                        if (value == 'ReName ItemCode') {
                          if (pItemCode.isNotEmpty) {
                            _reNameCodeDialog(context);
                          }
                        } else if (value == 'ReName ItemName') {
                          if (pItemName.isNotEmpty) {
                            _reNameNameDialog(context);
                          }
                        }
                      });
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'ReName ItemCode',
                        child: Text('ReName ItemCode'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'ReName ItemName',
                        child: Text('ReName ItemName'),
                      ),
                      // const PopupMenuItem<String>(
                      //   value: 'Update HSN Code',
                      //   child: Text('Update HSN Code'),
                      // ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              SimpleAutoCompleteTextField(
                key: keyItemCode,
                controller: itemCodeController,
                clearOnSubmit: false,
                suggestions: itemCodeList,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Item Code'),
                textSubmitted: (data) {
                  pItemCode = data;
                },
              ),
              const Divider(),
              SimpleAutoCompleteTextField(
                key: keyItemName,
                controller: itemNameController,
                clearOnSubmit: false,
                suggestions: itemNameList,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Item Name'),
                textSubmitted: (data) {
                  pItemName = data;
                },
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getTaxGroupData(filter, 'sales_list/taxGroup'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "TaxGroup"),
                onChanged: (dynamic data) {
                  taxGroup = data;
                },
                showSearchBox: true,
                selectedItem: taxGroup,
              ),
              const Divider(),
              ListTile(
                  title: DropdownSearch<dynamic>(
                    maxHeight: 300,
                    onFind: (String filter) =>
                        api.getSalesListData(filter, 'sales_list/unit'),
                    dropdownSearchDecoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: 'Select Unit'),
                    onChanged: (dynamic data) {
                      unit = data;
                    },
                    showSearchBox: true,
                    selectedItem: unit,
                  ),
                  trailing: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: white,
                        backgroundColor: blue,
                      ),
                      onPressed: () {
                        setState(() {
                          nextWidget = 1;
                        });
                      },
                      child: const Text('Details'))),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/manufacture'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select Manufacture'),
                onChanged: (dynamic data) {
                  mfr = data;
                },
                showSearchBox: true,
                selectedItem: mfr,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/category'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Select Category'),
                onChanged: (dynamic data) {
                  category = data;
                },
                selectedItem: category,
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/subCategory'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select SubCategory'),
                onChanged: (dynamic data) {
                  subCategory = data;
                },
                selectedItem: subCategory,
                showSearchBox: true,
              ),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: TextFormField(
                    controller: cessController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    decoration: const InputDecoration(
                      labelText: 'CESS',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: TextFormField(
                    controller: addCessController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    decoration: const InputDecoration(
                      labelText: 'ADD CESS',
                      border: OutlineInputBorder(),
                    ),
                  ),
                )
              ]),
              const Divider(),
              const Text('Selling Rates'),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: TextFormField(
                    controller: mrpController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    decoration: const InputDecoration(
                      labelText: 'MRP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                    child: Card(
                  elevation: 2,
                  child: CheckboxListTile(
                    title: const Text('Active'),
                    onChanged: (bool value) {
                      setState(() {
                        active = value;
                      });
                    },
                    value: active,
                  ),
                ))
              ]),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextField(
                      controller: wholeSaleController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp(r'[0-9]'),
                            allow: true, replacementString: '.')
                      ],
                      decoration: const InputDecoration(
                        labelText: 'WholeSale',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: TextField(
                      controller: retailController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp(r'[0-9]'),
                            allow: true, replacementString: '.')
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Retail',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: TextField(
                    controller: spRetailController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    decoration: const InputDecoration(
                      labelText: 'SP Retail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: TextField(
                    controller: branchController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Branch',
                      border: OutlineInputBorder(),
                    ),
                  ),
                )
              ]),
              const Divider(),
              Column(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Expanded(
                          child: Text('Stock Valuation'),
                        ),
                        Expanded(
                          child: Text('Type of Supply'),
                        ),
                      ]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          hint: const Text('Stock Valuation'),
                          value: dropDownStockValuation,
                          items: stockValuationData
                              .map<DropdownMenuItem<String>>((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              dropDownStockValuation = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: DropdownButton<String>(
                          hint: const Text('Type of Supply'),
                          value: dropDownTypeOfSupply,
                          items: typeOfSupplyData
                              .map<DropdownMenuItem<String>>((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              dropDownTypeOfSupply = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              const Text('More'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: packingController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp(r'[0-9]'),
                            allow: true, replacementString: '.')
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Packing',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: DropdownSearch<dynamic>(
                      maxHeight: 300,
                      onFind: (String filter) =>
                          api.getSalesListData(filter, 'sales_list/rack'),
                      dropdownSearchDecoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select Rack'),
                      onChanged: (dynamic data) {
                        rack = data;
                      },
                      selectedItem: rack,
                      showSearchBox: true,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextField(
                      controller: reOrderLevelController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp(r'[0-9]'),
                            allow: true, replacementString: '.')
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Reorder Level',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: TextField(
                      controller: maxOrderLevelController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp(r'[0-9]'),
                            allow: true, replacementString: '.')
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Max Order Level',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        : Column(children: [
            const Center(child: Text('Unit Details')),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Expanded(child: Text('Purchase')),
                  Expanded(
                    child: DropdownButton<String>(
                      hint: const Text('SKU'),
                      value: dropDownUnitPurchase.toString(),
                      items: unitModel.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item.id.toString(),
                          child: Text(item.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          dropDownUnitPurchase = int.tryParse(value);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 3,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Expanded(child: Text('Sales')),
                  Expanded(
                    child: DropdownButton<String>(
                      hint: const Text('SKU'),
                      value: dropDownUnitSale.toString(),
                      items: unitModel.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item.id.toString(),
                          child: Text(item.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          dropDownUnitSale = int.tryParse(value);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 5,
            ),
            Card(
              margin: const EdgeInsets.all(10),
              elevation: 5,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          hint: const Text('SKU'),
                          value: dropDownUnitData.toString(),
                          items:
                              unitModel.map<DropdownMenuItem<String>>((item) {
                            return DropdownMenuItem<String>(
                              value: item.id.toString(),
                              child: Text(item.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              dropDownUnitData = int.tryParse(value);
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: conversionController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                allow: true, replacementString: '.')
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Conversion',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 2,
                  ),
                  Row(children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: dropDownRateData.toString(),
                        hint: const Text('Rate'),
                        items:
                            rateTypeModel.map<DropdownMenuItem<String>>((item) {
                          return DropdownMenuItem<String>(
                            value: item.id.toString(),
                            child: Text(item.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            dropDownRateData = int.tryParse(value);
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: barcodeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter(RegExp(r'[0-9]'),
                              allow: true)
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ]),
                  TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: white,
                        backgroundColor: blue,
                      ),
                      onPressed: () {
                        setState(() {
                          unitDetail.add(UnitDetailModel(
                              id: unitDetail.length + 1,
                              conversion:
                                  double.tryParse(conversionController.text),
                              name: unitModel
                                  .firstWhere((element) =>
                                      element.id == dropDownUnitData)
                                  .name,
                              rateType: rateTypeModel
                                  .firstWhere((element) =>
                                      element.id == dropDownRateData)
                                  .name,
                              barcode: barcodeController.text,
                              itemId: itemCodeController.text.isNotEmpty
                                  ? int.tryParse(itemCodeController.text)
                                  : 0,
                              unitId: dropDownUnitData,
                              pUnitId: dropDownUnitPurchase,
                              sUnitId: dropDownUnitSale));
                        });
                      },
                      child: const Text('Add Unit')),
                ],
              ),
            ),
            Expanded(
              child: unitListData(),
            ),
            TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: white,
                  backgroundColor: blue,
                ),
                onPressed: () {
                  setState(() {
                    nextWidget = 0;
                  });
                },
                child: const Text('OK')),
          ]);
  }

  TextEditingController conversionController = TextEditingController();
  TextEditingController barcodeController = TextEditingController();
  int dropDownUnitData, dropDownRateData;

  unitListData() {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(),
      padding: const EdgeInsets.all(8),
      itemCount: unitDetail.length,
      itemBuilder: (BuildContext context, int index) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(unitDetail[index].id.toString() +
                    ' , ' +
                    unitDetail[index].name +
                    ' , ' +
                    unitDetail[index].conversion.toString() +
                    ' , ' +
                    unitDetail[index].rateType +
                    ' , Barcode:' +
                    unitDetail[index].barcode),
                TextButton.icon(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(kPrimaryColor),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                    onPressed: () {
                      setState(() {
                        unitDetail.removeAt(index);
                      });
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: red,
                    ),
                    label: const Text(''))
              ],
            ),
          ],
        );
      },
    );
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
    showConfirmAlertBox(context, 'Product Register', value);
  }

  void findProduct(String pItemName) {
    api.getProductByName(pItemName).then((value) {
      if (value != null) {
        if (value.slno > 0) {
          setState(() {
            itemNameController.text = value.itemname;
            productId = value.slno.toString();
            pHSNCode = value.hsncode;
            hsnController.text = value.hsncode;
            pItemCode = value.itemcode;
            itemCodeController.text = value.itemcode;
            unit = DataJson(id: value.unitId, name: '');
            mfr = DataJson(id: value.unitId, name: '');
            category = DataJson(id: value.unitId, name: '');
            subCategory = DataJson(id: value.unitId, name: '');
            cessController.text = value.cess.toString();
            addCessController.text = value.adcessper.toString();
            mrpController.text = value.mrp.toString();
            active = value.active == 1 ? true : false;
            wholeSaleController.text = value.wsrate.toString();
            retailController.text = value.retail.toString();
            spRetailController.text = value.sprate.toString();
            branchController.text = value.branch.toString();
            dropDownStockValuation = value.stockvaluation.trim().toUpperCase();
            dropDownTypeOfSupply = value.typeofsupply.trim().toUpperCase();
            packingController.text = value.packing.toString();
            rack = DataJson(id: value.rackId, name: '');
            reOrderLevelController.text = value.reorder.toString();
            maxOrderLevelController.text = value.maxorder.toString();

            isExist = true;
          });

          api
              .getTaxGroupData(value.tax.toString(), 'sales_list/taxGroup')
              .then((taxData) {
            setState(() {
              taxGroup = taxData
                  .firstWhere((element) => element.name == value.taxGroupName);
            });
          });

          // api.getSalesListData('filter', 'sales_list/unit');
        }
      }
    });
  }

  void findProductByCode(String pItemName) {
    api.getProductByName(pItemName).then((value) {
      if (value != null) {
        if (value.slno > 0) {
          setState(() {
            itemNameController.text = value.itemname;
            productId = value.slno.toString();
            pHSNCode = value.hsncode;
            hsnController.text = value.hsncode;
            pItemCode = value.itemcode;
            itemCodeController.text = value.itemcode;
            unit = DataJson(id: value.unitId, name: '');
            mfr = DataJson(id: value.unitId, name: '');
            category = DataJson(id: value.unitId, name: '');
            subCategory = DataJson(id: value.unitId, name: '');
            cessController.text = value.cess.toString();
            addCessController.text = value.adcessper.toString();
            mrpController.text = value.mrp.toString();
            active = value.active == 1 ? true : false;
            wholeSaleController.text = value.wsrate.toString();
            retailController.text = value.retail.toString();
            spRetailController.text = value.sprate.toString();
            branchController.text = value.branch.toString();
            dropDownStockValuation = value.stockvaluation.trim().toUpperCase();
            dropDownTypeOfSupply = value.typeofsupply.trim().toUpperCase();
            packingController.text = value.packing.toString();
            rack = DataJson(id: value.rackId, name: '');
            reOrderLevelController.text = value.reorder.toString();
            maxOrderLevelController.text = value.maxorder.toString();

            isExist = true;
          });

          api
              .getTaxGroupData(value.tax.toString(), 'sales_list/taxGroup')
              .then((taxData) {
            setState(() {
              taxGroup = taxData
                  .firstWhere((element) => element.name == value.taxGroupName);
            });
          });

          // api.getSalesListData('filter', 'sales_list/unit');
        }
      }
    });
  }

  TextEditingController _textFieldController = TextEditingController();

  _reNameNameDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'ReName $pItemName',
            style: const TextStyle(fontSize: 12),
          ),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: "Enter New Name"),
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _isLoading = true;
                });
                var body = {
                  'new': _textFieldController.text,
                  'old': pItemName,
                  'Statement': 'ReNameItemName'
                };
                bool _state = await api.renameProduct(body);
                _state
                    ? showInSnackBar('Product Name Renamed')
                    : showInSnackBar('Error');
                if (_state) {
                  itemNameController.text = _textFieldController.text;
                  pItemName = _textFieldController.text;
                  _textFieldController.text = '';
                }
                setState(() {
                  _isLoading = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  _reNameCodeDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'ReName $pItemCode',
            style: const TextStyle(fontSize: 12),
          ),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: "Enter New ItemCode"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _isLoading = true;
                });
                var body = {
                  'new': _textFieldController.text,
                  'old': pItemCode,
                  'Statement': 'ReNameItemcode'
                };
                bool _state = await api.renameProduct(body);
                _state
                    ? showInSnackBar('Product Code Renamed')
                    : showInSnackBar('Error');
                if (_state) {
                  itemCodeController.text = _textFieldController.text;
                  pItemCode = _textFieldController.text;
                  _textFieldController.text = '';
                }
                setState(() {
                  _isLoading = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  _reNameHSNDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ReName HSN'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: "Enter New HSN Code"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                var body = {'': ''};
                bool _state = await api.renameProduct(body);
                _state
                    ? showInSnackBar('Product Saved')
                    : showInSnackBar('Error');
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class CustomDelegateProduct extends SearchDelegate<List<DataJson>> {
  List<DataJson> data;
  CustomDelegateProduct(this.data);

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.chevron_left),
      onPressed: () => close(context, []));

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) {
    List<DataJson> listToShow;
    if (query.isNotEmpty) {
      listToShow = data
          .where((e) =>
              e.name.toLowerCase().contains(query.toLowerCase()) &&
              e.name.toLowerCase().startsWith(query.toLowerCase()))
          .toList();
    } else {
      listToShow = data;
    }
    return ListView.builder(
      itemCount: listToShow.length,
      itemBuilder: (_, i) {
        var noun = listToShow[i];
        return ListTile(
          title: Text(noun.name),
          onTap: () => close(context, [noun]),
        );
      },
    );
  }
}
