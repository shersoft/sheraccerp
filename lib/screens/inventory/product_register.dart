// @dart = 2.11
import 'dart:convert';

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:sheraccerp/models/tax_group_model.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
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
  var productModel;
  Size deviceSize;
  bool _isLoading = false;
  DataJson itemId,
      itemName,
      supplier,
      mfr,
      category,
      subCategory,
      location = DataJson(id: 1, name: 'SHOP'),
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
    deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        actions: [
          TextButton(
              child: const Text(
                "Save",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue[700],
              ),
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });

                var jsonItem = UnitDetailModel.encodeCartToJson(unitDetail);
                var items = json.encode(jsonItem);
                var data = '[' +
                    json.encode({
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
                      'subCategoryId': subCategory != null ? subCategory.id : 0,
                      'unitId': unit != null ? unit.id : 0,
                      'rackId': rack != null ? rack.id : 0,
                      'packing': packingController.text.trim().isNotEmpty
                          ? packingController.text.trim()
                          : 0,
                      'reOrder': reOrderLevelController.text.trim().isNotEmpty
                          ? reOrderLevelController.text.trim()
                          : 0,
                      'maxOrder': maxOrderLevelController.text.trim().isNotEmpty
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
                          ? double.tryParse(addCessController.text.trim()) > 0
                              ? double.tryParse(addCessController.text.trim())
                              : 0
                          : 0,
                      'mrp': mrpController.text.trim().isNotEmpty
                          ? double.tryParse(mrpController.text.trim()) > 0
                              ? double.tryParse(mrpController.text.trim())
                              : 0
                          : 0,
                      'retail': retailController.text.trim().isNotEmpty
                          ? double.tryParse(retailController.text.trim()) > 0
                              ? double.tryParse(retailController.text.trim())
                              : 0
                          : 0,
                      'wsRate': wholeSaleController.text.trim().isNotEmpty
                          ? double.tryParse(wholeSaleController.text.trim()) > 0
                              ? double.tryParse(wholeSaleController.text.trim())
                              : 0
                          : 0,
                      'spRetail': spRetailController.text.trim().isNotEmpty
                          ? double.tryParse(spRetailController.text.trim()) > 0
                              ? double.tryParse(spRetailController.text.trim())
                              : 0
                          : 0,
                      'branch': branchController.text.trim().isNotEmpty
                          ? double.tryParse(branchController.text.trim()) > 0
                              ? double.tryParse(branchController.text.trim())
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
              }),
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
              SimpleAutoCompleteTextField(
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
              const Divider(
                height: 2,
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
                },
              ),
              const Divider(
                height: 2,
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
                },
              ),
              const Divider(
                height: 2,
              ),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getTaxGroupData(filter, 'sales_list/taxGroup'),
                dropdownSearchDecoration:
                    const InputDecoration(hintText: "TaxGroup"),
                onChanged: (dynamic data) {
                  taxGroup = data;
                },
                showSearchBox: true,
                selectedItem: taxGroup,
              ),
              const Divider(
                height: 2,
              ),
              ListTile(
                  title: DropdownSearch<dynamic>(
                    maxHeight: 300,
                    onFind: (String filter) =>
                        api.getSalesListData(filter, 'sales_list/unit'),
                    dropdownSearchDecoration:
                        const InputDecoration(hintText: 'Select Unit'),
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
              const Divider(
                height: 2,
              ),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/manufacture'),
                dropdownSearchDecoration:
                    const InputDecoration(hintText: 'Select Manufacture'),
                onChanged: (dynamic data) {
                  mfr = data;
                },
                showSearchBox: true,
                selectedItem: mfr,
              ),
              const Divider(
                height: 2,
              ),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/category'),
                dropdownSearchDecoration:
                    const InputDecoration(hintText: 'Select Category'),
                onChanged: (dynamic data) {
                  category = data;
                },
                selectedItem: category,
                showSearchBox: true,
              ),
              const Divider(
                height: 2,
              ),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/subCategory'),
                dropdownSearchDecoration:
                    const InputDecoration(hintText: 'Select SubCategory'),
                onChanged: (dynamic data) {
                  subCategory = data;
                },
                selectedItem: subCategory,
                showSearchBox: true,
              ),
              const Divider(
                height: 2,
              ),
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
              const Divider(
                height: 2,
              ),
              const Text('Selling Rates'),
              const Divider(
                height: 2,
              ),
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
              const Divider(
                height: 2,
              ),
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
              const Divider(
                height: 2,
              ),
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
              const Divider(
                height: 2,
              ),
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
              const Divider(
                height: 2,
              ),
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
                      dropdownSearchDecoration:
                          const InputDecoration(hintText: 'Select Rack'),
                      onChanged: (dynamic data) {
                        rack = data;
                      },
                      selectedItem: rack,
                      showSearchBox: true,
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 2,
              ),
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
}
