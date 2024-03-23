// @dart = 2.11
import 'dart:convert';

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/product_register_model.dart';
import 'package:sheraccerp/models/tax_group_model.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/accounts/ledger.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/com_service.dart';
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
  List<DataJson> productList0 = [];
  bool _isLoading = false,
      isExist = false,
      buttonEvent = false,
      isGoogleTranslator = false;
  DataJson itemId,
      itemName,
      supplier,
      mfr,
      category,
      subCategory,
      brand,
      location = DataJson(id: 1, name: defaultLocation),
      rack,
      unit;
  TaxGroupModel taxGroup;
  List<String> hsnList = [];
  List<String> itemNameList = [];
  List<String> itemCodeList = [];
  List<String> categoryList = [];
  List<DataJson> taxGroupDataList = [];
  List<DataJson> categoryDataList = [];
  List<String> subCategoryList = [];
  List<DataJson> subCategoryDataList = [];
  List<String> unitList = [];
  List<DataJson> unitDataList = [];
  List<String> brandList = [];
  List<DataJson> brandDataList = [];
  List<String> rackList = [];
  List<DataJson> rackDataList = [];
  List<String> mfrList = [];
  List<DataJson> mfrDataList = [];
  List<dynamic> productData = [];
  var pItemCode = '', pItemName = '', pHSNCode = '';
  bool active = true;
  var dropDownStockValuation = 'AVERAGE VALUE', dropDownTypeOfSupply = 'GOODS';
  int dropDownUnit = 0, dropDownUnitPurchase, dropDownUnitSale;
  List<DataJson> unitModel = [];
  List<UnitDetailModel> unitDetail = [];
  String isItemName = '';

  @override
  void initState() {
    categoryDataList
        .addAll(DataJson.fromJsonListX(otherRegistrationList[0]['category']));
    categoryList.addAll(List<String>.from(categoryDataList
        .map((item) => (item.name))
        .toList()
        .map((s) => s)
        .toList()));
    subCategoryDataList.addAll(
        DataJson.fromJsonListX(otherRegistrationList[0]['sub_category']));
    subCategoryList.addAll(List<String>.from(subCategoryDataList
        .map((item) => (item.name))
        .toList()
        .map((s) => s)
        .toList()));
    rackDataList
        .addAll(DataJson.fromJsonListX(otherRegistrationList[0]['rack']));
    rackList.addAll(List<String>.from(rackDataList
        .map((item) => (item.name))
        .toList()
        .map((s) => s)
        .toList()));
    unitDataList
        .addAll(DataJson.fromJsonListX(otherRegistrationList[0]['unit']));
    unitList.addAll(List<String>.from(unitDataList
        .map((item) => (item.name))
        .toList()
        .map((s) => s)
        .toList()));
    brandDataList
        .addAll(DataJson.fromJsonListX(otherRegistrationList[0]['brand']));
    brandList.addAll(List<String>.from(brandDataList
        .map((item) => (item.name))
        .toList()
        .map((s) => s)
        .toList()));
    mfrDataList.addAll(DataJson.fromJsonListX(otherRegistrationList[0]['mfr']));
    mfrList.addAll(List<String>.from(mfrDataList
        .map((item) => (item.name))
        .toList()
        .map((s) => s)
        .toList()));

    api.getProductData().then((value) {
      setState(() {
        productData = value.values.toList();
        if (productData[0].length > 0) {
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
          taxGroupDataList
              .addAll(DataJson.fromJsonList(productData[0]['TaxGroup']));

          // productList.addAll(List<dynamic>.from(productData[0]['ItemName'])
          //     .map((item) => (DataJson(id: item['id'], name: item['name']))));

          unitModel
              .addAll(DataJson.fromJsonListX(otherRegistrationList[0]['unit']));

          dropDownUnitPurchase = unitModel[0].id;
          dropDownUnitSale = unitModel[0].id;
          dropDownUnitData = unitModel[0].id;
          dropDownRateData = rateTypeModelData[0].id;
        }
      });
    });
    api.getProductId().then((value) => {
          setState(() {
            itemCodeController.text = value > 0 ? value.toString() : '';
          })
        });

    super.initState();
    loadSettings();
  }

  CompanyInformation companySettings;
  List<CompanySettings> settings;

  loadSettings() {
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();

    // String cashAc =
    //     ComSettings.getValue('CASH A/C', settings).toString().trim() ?? 'CASH';
    // ComSettings.appSettings('int', 'key-dropdown-default-cash-ac', 0);
    taxMethod = companySettings.taxCalculation;
    isGoogleTranslator =
        ComSettings.getStatus('USE GOOGLE TRANSLATE', settings);
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
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
            icon: const Icon(Icons.clear),
            onPressed: () async {
              setState(() {
                pHSNCode = '';
                pItemCode = '';
                pItemName = '';
                mrpController.text = '';
                retailController.text = '';
                wholeSaleController.text = '';
                spRetailController.text = '';
                branchController.text = '';
                hsnController.text = '';
                itemCodeController.text = '';
                itemNameController.text = '';
                itemLocalNameController.text = '';
                packingController.text = '';
                maxOrderLevelController.text = '';
                reOrderLevelController.text = '';
                cessController.text = '';
                addCessController.text = '';
                isExist = false;
                nextWidget = 0;
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
                          'itemLocalName':
                              itemLocalNameController.text.trim().isNotEmpty
                                  ? itemLocalNameController.text.trim()
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
                          'speedBill': 0,
                          'expiry': 0,
                          'brand': brand != null ? brand.id : 0,
                          'lc': 0.0
                        }) +
                        ']';

                    final body = {'product': data, 'unitDetails': items};
                    var result = await api.editProduct(body);
                    setState(() {
                      _isLoading = false;
                    });
                    if (CommonService().isNumeric(result) &&
                        int.tryParse(result) > 0) {
                      showInSnackBar('Product Edited');
                    } else {
                      showInSnackBar(result.toString());
                    }
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
                          'itemLocalName':
                              itemLocalNameController.text.trim().isNotEmpty
                                  ? itemLocalNameController.text.trim()
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
                          'speedBill': 0,
                          'expiry': 0,
                          'brand': brand != null ? brand.id : 0,
                          'lc': 0.0
                        }) +
                        ']';

                    final body = {'product': data, 'unitDetails': items};
                    var result = await api.addProduct(body);
                    setState(() {
                      _isLoading = false;
                    });
                    if (CommonService().isNumeric(result) &&
                        int.tryParse(result) > 0) {
                      showInSnackBar('Product Saved');
                    } else {
                      showInSnackBar(result.toString());
                    }
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
  GlobalKey<AutoCompleteTextFieldState<String>> keyCategory = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keySubCategory = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyMFR = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyBrand = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyRack = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyUnit = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyItemCode = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyItemName = GlobalKey();
  int nextWidget = 0;
  TextEditingController mrpController = TextEditingController();
  TextEditingController retailController = TextEditingController();
  TextEditingController wholeSaleController = TextEditingController();
  TextEditingController spRetailController = TextEditingController();
  TextEditingController branchController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController subCategoryController = TextEditingController();
  TextEditingController brandController = TextEditingController();
  TextEditingController mfrController = TextEditingController();
  TextEditingController rackController = TextEditingController();
  TextEditingController unitController = TextEditingController();
  TextEditingController hsnController = TextEditingController();

  TextEditingController itemCodeController = TextEditingController();
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemLocalNameController = TextEditingController();
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
                  const SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    child: SimpleAutoCompleteTextField(
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
              const Divider(),
              TextField(
                controller: itemLocalNameController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Item Local Name',
                  suffixIcon: IconButton(
                      onPressed: () {
                        var data = itemNameController.text;
                        if (data.isNotEmpty && isGoogleTranslator) {
                          api.translateText(data.trim()).then(
                              (value) => itemLocalNameController.text = value);
                        }
                      },
                      icon: const Icon(
                        Icons.g_translate,
                        color: kPrimaryColor,
                      )),
                ),
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getTaxGroupData(filter, 'sales_list/taxGroup'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text("TaxGroup")),
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
                        border: OutlineInputBorder(),
                        label: Text('Select Unit')),
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
              // DropdownSearch<dynamic>(
              //   maxHeight: 300,
              //   onFind: (String filter) =>
              //       api.getSalesListData(filter, 'sales_list/manufacture'),
              //   dropdownSearchDecoration: const InputDecoration(
              //       border: OutlineInputBorder(),
              //       label: Text('Select Manufacture')),
              //   onChanged: (dynamic data) {
              //     mfr = data;
              //   },
              //   showSearchBox: true,
              //   selectedItem: mfr,
              // ),
              SimpleAutoCompleteTextField(
                clearOnSubmit: false,
                key: keyMFR,
                suggestions: mfrList,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select Manufacture',
                    labelText: 'Manufacture'),
                textSubmitted: (data) {
                  mfr = mfrDataList.firstWhere(
                    (element) => element.name == data,
                    orElse: () => null,
                  );
                },
                controller: mfrController,
              ),
              const Divider(),
              // DropdownSearch<dynamic>(
              //   maxHeight: 300,
              //   onFind: (String filter) =>
              //       api.getSalesListData(filter, 'sales_list/category'),
              //   dropdownSearchDecoration: const InputDecoration(
              //       border: OutlineInputBorder(),
              //       label: Text('Select Category')),
              //   onChanged: (dynamic data) {
              //     category = data;
              //   },
              //   selectedItem: category,
              //   showSearchBox: true,
              // ),
              SimpleAutoCompleteTextField(
                clearOnSubmit: false,
                key: keyCategory,
                suggestions: categoryList,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select Category',
                    labelText: 'Category'),
                textSubmitted: (data) {
                  category = categoryDataList.firstWhere(
                    (element) => element.name == data,
                    orElse: () => null,
                  );
                },
                controller: categoryController,
              ),
              const Divider(),
              // DropdownSearch<dynamic>(
              //   maxHeight: 300,
              //   onFind: (String filter) =>
              //       api.getSalesListData(filter, 'sales_list/subCategory'),
              //   dropdownSearchDecoration: const InputDecoration(
              //       border: OutlineInputBorder(),
              //       label: Text('Select SubCategory')),
              //   onChanged: (dynamic data) {
              //     subCategory = data;
              //   },
              //   selectedItem: subCategory,
              //   showSearchBox: true,
              // ),
              SimpleAutoCompleteTextField(
                clearOnSubmit: false,
                key: keySubCategory,
                suggestions: subCategoryList,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select SubCategory',
                    labelText: 'SubCategory'),
                textSubmitted: (data) {
                  subCategory = subCategoryDataList.firstWhere(
                    (element) => element.name == data,
                    orElse: () => null,
                  );
                },
                controller: subCategoryController,
              ),
              const Divider(),
              SimpleAutoCompleteTextField(
                clearOnSubmit: false,
                key: keyBrand,
                suggestions: brandList,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select Brand',
                    labelText: 'Brand'),
                textSubmitted: (data) {
                  brand = brandDataList.firstWhere(
                    (element) => element.name == data,
                    orElse: () => null,
                  );
                },
                controller: brandController,
              ),
              const Divider(),
              const Text('Selling Rates'),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: TextFormField(
                    controller: mrpController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
              const Card(
                elevation: 5,
                child: Center(
                    child: Text(
                  'More',
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                )),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: packingController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                    child:
                        // DropdownSearch<dynamic>(
                        //   maxHeight: 300,
                        //   onFind: (String filter) =>
                        //       api.getSalesListData(filter, 'sales_list/rack'),
                        //   dropdownSearchDecoration: const InputDecoration(
                        //       border: OutlineInputBorder(),
                        //       label: Text('Select Rack')),
                        //   onChanged: (dynamic data) {
                        //     rack = data;
                        //   },
                        //   selectedItem: rack,
                        //   showSearchBox: true,
                        //   emptyBuilder: (context, searchEntry) {
                        //     return Center(
                        //       child: ElevatedButton(
                        //           onPressed: () {
                        //             searchEntry = '';
                        //             rack = DataJson(
                        //                 id: -1, name: searchEntry.toUpperCase());
                        //           },
                        //           child: const Text('add new')),
                        //     );
                        //   },
                        // ),

                        SimpleAutoCompleteTextField(
                      clearOnSubmit: false,
                      key: keyRack,
                      suggestions: rackList,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select Rack',
                          labelText: 'Rack'),
                      textSubmitted: (data) {
                        rack = rackDataList.firstWhere(
                          (element) => element.name == data,
                          orElse: () => null,
                        );
                      },
                      controller: rackController,
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: TextFormField(
                    controller: cessController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
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
                        items: rateTypeModelData
                            .map<DropdownMenuItem<String>>((item) {
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                              rateType: rateTypeModelData
                                  .firstWhere((element) =>
                                      element.id == dropDownRateData)
                                  .name,
                              barcode: barcodeController.text,
                              itemId: itemCodeController.text.isNotEmpty
                                  ? int.tryParse(itemCodeController.text)
                                  : 0,
                              unitId: dropDownUnitData,
                              pUnitId: dropDownUnitPurchase,
                              sUnitId: dropDownUnitSale,
                              gatePass: 0));
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
          addData(value);
        }
      }
    });
  }

  void findProductByCode(String itemCode) {
    api.getProductByCode(itemCode).then((value) {
      if (value != null) {
        addData(value);
      }
    });
  }

  addData(ProductRegisterModel value) {
    setState(() {
      productId = value.slno.toString();
      pItemName = value.itemname;
      itemNameController.text = value.itemname;
      itemLocalNameController.text = value.regItemName;
      pHSNCode = value.hsncode;
      hsnController.text = value.hsncode;
      pItemCode = value.itemcode;
      itemCodeController.text = value.itemcode;
      if (value.unitId > 0) {
        unit = unitDataList.firstWhere((element) => element.id == value.unitId,
            orElse: () => DataJson(id: value.unitId, name: ''));
        unitController.text = unit.name;
      }
      if (value.mfrId > 0) {
        mfr = mfrDataList.firstWhere((element) => element.id == value.mfrId,
            orElse: () => DataJson(id: value.mfrId, name: ''));
        mfrController.text = mfr.name;
      }
      if (value.catagoryId > 0) {
        category = categoryDataList.firstWhere(
            (element) => element.id == value.catagoryId,
            orElse: () => DataJson(id: value.catagoryId, name: ''));
        categoryController.text = category.name;
      }
      if (value.subcatagoryId > 0) {
        subCategory = subCategoryDataList.firstWhere(
            (element) => element.id == value.subcatagoryId,
            orElse: () => DataJson(id: value.subcatagoryId, name: ''));
        subCategoryController.text = subCategory.name;
      }
      if (value.brand > 0) {
        brand = brandDataList.firstWhere((element) => element.id == value.brand,
            orElse: () => DataJson(id: value.brand, name: ''));
        brandController.text = brand.name;
      }
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
      if (value.rackId > 0) {
        rack = rackDataList.firstWhere((element) => element.id == value.rackId,
            orElse: () => DataJson(id: value.rackId, name: ''));
        rackController.text = rack.name;
      }
      reOrderLevelController.text = value.reorder.toString();
      maxOrderLevelController.text = value.maxorder.toString();

      isExist = true;
    });

    if (value.taxGroupName.isNotEmpty) {
      api
          .getTaxGroupData(value.tax.toString(), 'sales_list/taxGroup')
          .then((taxData) {
        setState(() {
          taxGroup = taxData
              .firstWhere((element) => element.name == value.taxGroupName);
        });
      });
    }
  }

  final TextEditingController _textFieldController = TextEditingController();

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
            decoration: const InputDecoration(
                border: OutlineInputBorder(), label: Text("Enter New Name")),
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
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Enter New ItemCode")),
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
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Enter New HSN Code")),
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
