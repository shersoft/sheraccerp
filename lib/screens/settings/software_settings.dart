import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/inventory/sales/sales_form_register.dart';
import 'package:sheraccerp/screens/inventory/sales/sales_other_detail_register.dart';
import 'package:sheraccerp/screens/settings/sms_settings.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';

import '../../widget/loading.dart';

class SoftwareSettings extends StatefulWidget {
  const SoftwareSettings({Key? key}) : super(key: key);

  @override
  State<SoftwareSettings> createState() => _SoftwareSettingsState();
}

class _SoftwareSettingsState extends State<SoftwareSettings> {
  List<CompanySettings> _settingsList = [];
  List<CompanySettings> settingsData = [];
  List<CompanySettings> settingsDisplayList = [];
  DioService dio = DioService();
  late CompanyInformation _companySettings;
  List<CompanySettings> _settings = [];
  String toolBarSale = '',
      toolBarSaleId = '0',
      cashAC = '',
      stockValue = '',
      defaultLocation = '',
      decimalPoint = '',
      boxColor = '',
      toolBarColor = '',
      backhand = '',
      keySerialNoTitle = '',
      keyEWayApi = '',
      keyItemSPTitle = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    settingsDisplayList = [];
    _settingsList = [];

    _companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    _settings = ScopedModel.of<MainModel>(context).getSettings();

    toolBarSaleId =
        ComSettings.getValue('TOOLBAR SALES', _settings).toString().trim() ??
            '1';
    toolBarSaleId = ComSettings.oKNumeric(toolBarSaleId) ? toolBarSaleId : '1';
    cashAC =
        ComSettings.getValue('CASH A/C', _settings).toString().trim() ?? 'CASH';
    controllerCashAc.text = cashAC;
    decimalPoint =
        ComSettings.getValue('DECIMAL', _settings).toString().trim() ?? '2';
    controllerDecimalPoint.text = decimalPoint;
    boxColor = ComSettings.getValue('BOXCOLOR', _settings).toString().trim() ??
        '-8323200';
    stockValue =
        ComSettings.getValue('STOCK METHODE', _settings).toString().trim() ??
            'AVERAGE VALUE';
    controllerStockValuation.text = stockValue;
    defaultLocation =
        ComSettings.getValue('DEFAULT LOCATION', _settings).toString().trim() ??
            'SHOP';
    controllerDefaultLocation.text = defaultLocation;
    toolBarColor =
        ComSettings.getValue('TOOLBARCOLOR', _settings).toString().trim() ??
            '16777215';
    toolBarColor = toolBarColor.isEmpty ? '16777215' : toolBarColor;
    keySerialNoTitle = ComSettings.getValue('KEY ITEM SERIAL NO', _settings)
            .toString()
            .trim() ??
        '';
    keyEWayApi = ComSettings.getValue('KEY EWAYBILLAPI OWNER', _settings)
            .toString()
            .trim() ??
        'SHERSOFT';
    keyItemSPTitle = ComSettings.getValue('KEY ITEM SP RATE TITLE', _settings)
            .toString()
            .trim() ??
        '';

    load();
  }

  List<String> cashListDisplay = [];
  List<String> locationListDisplay = [];
  List<String> saleTypeListDisplay = [];
  FocusNode focusNodeKeySerialNoTitle = FocusNode();
  FocusNode focusNodeKeyEWayApi = FocusNode();
  FocusNode focusNodeKeyItemSPTitle = FocusNode();
  SalesType? currentType;

  @override
  void dispose() {
    focusNodeKeyEWayApi.dispose();
    focusNodeKeyItemSPTitle.dispose();
    focusNodeKeySerialNoTitle.dispose();
    controllerKeyEWayApi.removeListener(controllerKeyEWayApiListener);
    controllerKeyItemSPTitle.removeListener(controllerKeyItemSPTitleListener);
    controllerKeySerialNoTitle
        .removeListener(controllerKeySerialNoTitleListener);
    super.dispose();
  }

  load() {
    if (_settings.isNotEmpty && _settings.first.id > 0) {
      setState(() {
        _settingsList.addAll(_settings);
        settingsData = _settingsList;
        settingsDisplayList = _settingsList;
      });
    } else {
      dio.getSoftwareSettings().then((value) {
        setState(() {
          _settingsList.addAll(value);
          settingsData = _settingsList;
          settingsDisplayList = _settingsList;
        });
      });
    }
    if (cashAccount.isNotEmpty) {
      List<dynamic> listData = cashAccount;
      setState(() {
        cashListDisplay.addAll(List<String>.from(listData
            .map((item) => (item.value))
            .toList()
            .map((s) => s)
            .toList()));
        cashListDisplay.remove("");
      });
    }
    if (salesTypeList.isNotEmpty) {
      toolBarSale = salesTypeList
          .firstWhere((element) => element.id.toString() == toolBarSaleId)
          .type;
      controllerToolBarSales.text = toolBarSale;
      currentType = salesTypeList
          .firstWhere((element) => element.id.toString() == toolBarSaleId);
      setState(() {
        saleTypeListDisplay.addAll(List<String>.from(salesTypeList
            .map((item) => (item.type))
            .toList()
            .map((s) => s)
            .toList()));
      });
    }
    if (locationList.isNotEmpty) {
      List<dynamic> listData = locationList;
      setState(() {
        locationListDisplay.addAll(List<String>.from(listData
            .map((item) => (item.value))
            .toList()
            .map((s) => s)
            .toList()));
        locationListDisplay.remove("");
      });
    }

    controllerKeyEWayApi.addListener(controllerKeyEWayApiListener);
    controllerKeyItemSPTitle.addListener(controllerKeyItemSPTitleListener);
    controllerKeySerialNoTitle.addListener(controllerKeySerialNoTitleListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  settingsDisplayList = _settingsList;
                });
              },
              icon: const Icon(Icons.filter_alt)),
          IconButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  saveData();
                });
              },
              icon: const Icon(Icons.save)),
        ], title: const Text('General')),
        body: _settingsList.isEmpty ? const Loading() : loadData());
  }

  TextEditingController controllerCashAc = TextEditingController();
  TextEditingController controllerToolBarSales = TextEditingController();
  TextEditingController controllerStockValuation = TextEditingController();
  TextEditingController controllerDefaultLocation = TextEditingController();
  TextEditingController controllerDecimalPoint = TextEditingController();
  TextEditingController controllerKeyItemSPTitle = TextEditingController();
  TextEditingController controllerKeyEWayApi =
      TextEditingController(text: 'SHERSOFT');
  TextEditingController controllerKeySerialNoTitle = TextEditingController();
  TextEditingController controllerHeadOfficeDB = TextEditingController();
  TextEditingController controllerDecimalPointOnReports =
      TextEditingController(text: "2");

  GlobalKey<AutoCompleteTextFieldState<String>> keyCashAc = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keySalesType = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyStockType = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyLocationType = GlobalKey();

  loadData() {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: blue,
              automaticallyImplyLeading: false,
              flexibleSpace: const TabBar(
                indicatorWeight: 5,
                tabs: [
                  Tab(text: "Options", icon: Icon(Icons.check_box)),
                  Tab(text: "Value", icon: Icon(Icons.edit_note)),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                    flex: 1,
                    child: TabBarView(children: [
                      Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: ListView.builder(
                            itemCount: settingsDisplayList.length,
                            itemBuilder: (BuildContext context, int index) {
                              return index == 0
                                  ? _searchBar()
                                  : _listItem(index - 1);
                            }),
                      ),
                      Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: ListView(children: [
                            const Divider(),
                            // SizedBox(
                            //   height: 40,
                            //   child: Card(
                            //     elevation: 5,
                            //     child: Row(
                            //       mainAxisAlignment:
                            //           MainAxisAlignment.spaceEvenly,
                            //       children: [
                            //         const Text('Select Color '),
                            //         Text(boxColor),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            Card(
                              elevation: 5,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Text('Company Cash A/C        '),
                                  Expanded(
                                      child: SizedBox(
                                    height: 40,
                                    child: SimpleAutoCompleteTextField(
                                      key: keyCashAc,
                                      controller: controllerCashAc,
                                      clearOnSubmit: false,
                                      suggestions: cashListDisplay,
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Select Cash A/C'),
                                      textSubmitted: (data) {
                                        setState(() {
                                          cashAC = data;
                                        });
                                      },
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            Card(
                              elevation: 5,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Text('ToolBar Sales                  '),
                                  Expanded(
                                      child: SizedBox(
                                    height: 40,
                                    child: SimpleAutoCompleteTextField(
                                      key: keySalesType,
                                      controller: controllerToolBarSales,
                                      clearOnSubmit: false,
                                      suggestions: salesTypeList
                                          .map((e) => e.type)
                                          .toList(),
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Select Sale'),
                                      textSubmitted: (data) {
                                        setState(() {
                                          toolBarSale = data;
                                          toolBarSaleId = salesTypeList
                                              .firstWhere(
                                                  (element) =>
                                                      element.type.toString() ==
                                                      toolBarSale,
                                                  orElse: () => currentType)
                                              .id
                                              .toString();
                                        });
                                      },
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            Card(
                              elevation: 5,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Text('Stock Valuation               '),
                                  Expanded(
                                      child: SizedBox(
                                    height: 40,
                                    child: SimpleAutoCompleteTextField(
                                      key: keyStockType,
                                      controller: controllerStockValuation,
                                      clearOnSubmit: false,
                                      suggestions: stockValuationData,
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Select Stock Value'),
                                      textSubmitted: (data) {
                                        setState(() {
                                          stockValue = data;
                                        });
                                      },
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            Card(
                              elevation: 5,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Text('Default Location              '),
                                  Expanded(
                                      child: SizedBox(
                                    height: 40,
                                    child: SimpleAutoCompleteTextField(
                                      key: keyLocationType,
                                      controller: controllerDefaultLocation,
                                      clearOnSubmit: false,
                                      suggestions: locationListDisplay,
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Select Location'),
                                      textSubmitted: (data) {
                                        setState(() {
                                          defaultLocation = data;
                                        });
                                      },
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            Card(
                              elevation: 5,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Text('Decimal Point                  '),
                                  Expanded(
                                      child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: controllerDecimalPoint,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(),
                                      decoration: const InputDecoration(
                                          labelText: 'Select Decimal',
                                          border: OutlineInputBorder()),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            Card(
                              elevation: 5,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Text(
                                      'SerialNoTitle                    '),
                                  Expanded(
                                      child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      focusNode: focusNodeKeySerialNoTitle,
                                      controller: controllerKeySerialNoTitle,
                                      decoration: const InputDecoration(
                                          labelText: 'SerialNo Title',
                                          border: OutlineInputBorder()),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            Card(
                              elevation: 5,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Text('EWayApi Owner               '),
                                  Expanded(
                                      child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      focusNode: focusNodeKeyEWayApi,
                                      controller: controllerKeyEWayApi,
                                      decoration: const InputDecoration(
                                          labelText: 'API Owner',
                                          border: OutlineInputBorder()),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            Card(
                              elevation: 5,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Text('ItemSpecialRateTitle      '),
                                  Expanded(
                                      child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      focusNode: focusNodeKeyItemSPTitle,
                                      controller: controllerKeyItemSPTitle,
                                      decoration: const InputDecoration(
                                          labelText: 'SpecialRateTitle',
                                          border: OutlineInputBorder()),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            Card(
                              elevation: 5,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Text('HeadOffice DB                 '),
                                  Expanded(
                                      child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: controllerHeadOfficeDB,
                                      decoration: const InputDecoration(
                                          labelText: 'Select DB',
                                          border: OutlineInputBorder()),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            Card(
                              elevation: 5,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Text('Decimal Point On Report '),
                                  Expanded(
                                      child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      keyboardType: const TextInputType
                                          .numberWithOptions(),
                                      controller:
                                          controllerDecimalPointOnReports,
                                      decoration: const InputDecoration(
                                          labelText: 'Select Decimal',
                                          border: OutlineInputBorder()),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            // SizedBox(
                            //   height: 40,
                            //   child: Card(
                            //     elevation: 5,
                            //     child: Row(
                            //       mainAxisAlignment:
                            //           MainAxisAlignment.spaceEvenly,
                            //       children: [
                            //         const Text('Toolbar Color '),
                            //         Text(toolBarColor),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            ElevatedButton(
                                onPressed: () {
                                  var _pass = '';
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(
                                                20.0,
                                              ),
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.only(
                                            top: 10.0,
                                          ),
                                          title: const Text(
                                            "Enter Password",
                                            style: TextStyle(fontSize: 24.0),
                                          ),
                                          content: SizedBox(
                                            height: 400,
                                            child: SingleChildScrollView(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Text(
                                                      "Enter Your Password",
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: TextField(
                                                      decoration:
                                                          const InputDecoration(
                                                              border:
                                                                  OutlineInputBorder(),
                                                              hintText:
                                                                  'Enter password',
                                                              labelText:
                                                                  'password'),
                                                      obscureText: true,
                                                      onChanged: (value) =>
                                                          _pass = value,
                                                    ),
                                                  ),
                                                  Container(
                                                    width: double.infinity,
                                                    height: 60,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        if (_pass ==
                                                            softwarePassword) {
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context).push(
                                                              MaterialPageRoute(
                                                                  builder: (BuildContext
                                                                          context) =>
                                                                      const SalesFormRegister()));
                                                        } else {
                                                          Fluttertoast.showToast(
                                                              msg:
                                                                  'incorrect password');
                                                          Navigator.of(context)
                                                              .pop();
                                                        }
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.black,
                                                        // fixedSize: Size(250, 50),
                                                      ),
                                                      child: const Text(
                                                        "Submit",
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      });
                                },
                                child: const Text('Sales Forms Register')),
                            ElevatedButton(
                                onPressed: () {
                                  var _pass = '';
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(
                                                20.0,
                                              ),
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.only(
                                            top: 10.0,
                                          ),
                                          title: const Text(
                                            "Enter Password",
                                            style: TextStyle(fontSize: 24.0),
                                          ),
                                          content: SizedBox(
                                            height: 400,
                                            child: SingleChildScrollView(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Text(
                                                      "Enter Your Password",
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: TextField(
                                                      decoration:
                                                          const InputDecoration(
                                                              border:
                                                                  OutlineInputBorder(),
                                                              hintText:
                                                                  'Enter password',
                                                              labelText:
                                                                  'password'),
                                                      obscureText: true,
                                                      onChanged: (value) =>
                                                          _pass = value,
                                                    ),
                                                  ),
                                                  Container(
                                                    width: double.infinity,
                                                    height: 60,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        if (_pass ==
                                                            softwarePassword) {
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context).push(
                                                              MaterialPageRoute(
                                                                  builder: (BuildContext
                                                                          context) =>
                                                                      const SalesOtherDetailRegister()));
                                                        } else {
                                                          Fluttertoast.showToast(
                                                              msg:
                                                                  'incorrect password');
                                                          Navigator.of(context)
                                                              .pop();
                                                        }
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.black,
                                                        // fixedSize: Size(250, 50),
                                                      ),
                                                      child: const Text(
                                                        "Submit",
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      });
                                },
                                child:
                                    const Text('Sales OtherDetails Register')),
                            ElevatedButton(
                                onPressed: () {
                                  var _pass = '';
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(
                                                20.0,
                                              ),
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.only(
                                            top: 10.0,
                                          ),
                                          title: const Text(
                                            "Enter Password",
                                            style: TextStyle(fontSize: 24.0),
                                          ),
                                          content: SizedBox(
                                            height: 400,
                                            child: SingleChildScrollView(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Text(
                                                      "Enter Your Password",
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: TextField(
                                                      decoration:
                                                          const InputDecoration(
                                                              border:
                                                                  OutlineInputBorder(),
                                                              hintText:
                                                                  'Enter password',
                                                              labelText:
                                                                  'password'),
                                                      obscureText: true,
                                                      onChanged: (value) =>
                                                          _pass = value,
                                                    ),
                                                  ),
                                                  Container(
                                                    width: double.infinity,
                                                    height: 60,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        if (_pass ==
                                                            softwarePassword) {
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context).push(
                                                              MaterialPageRoute(
                                                                  builder: (BuildContext
                                                                          context) =>
                                                                      const SmsSettings()));
                                                        } else {
                                                          Fluttertoast.showToast(
                                                              msg:
                                                                  'incorrect password');
                                                          Navigator.of(context)
                                                              .pop();
                                                        }
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.black,
                                                        // fixedSize: Size(250, 50),
                                                      ),
                                                      child: const Text(
                                                        "Submit",
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      });
                                },
                                child: const Text('SMS Settings')),
                          ])),
                    ])),
              ],
            )));
  }

  _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: const InputDecoration(
            border: OutlineInputBorder(), label: Text('Search...')),
        onChanged: (text) {
          text = text.toLowerCase();
          setState(() {
            settingsDisplayList = _settingsList.where((item) {
              var itemName = item.name.toString().toLowerCase();
              return itemName.contains(text);
            }).toList();
          });
        },
      ),
    );
  }

  _listItem(int index) {
    CompanySettings item = settingsDisplayList[index];
    return item.name == 'ALLOW NEGETIVE STOCK'
        ? Container()
        : Card(
            elevation: 2,
            child: Column(children: [
              CheckboxListTile(
                title: Text(item.name),
                value: item.status == 1 ? true : false,
                onChanged: (bool? val) {
                  {
                    setState(() => item.status = val != null
                        ? val
                            ? 1
                            : 0
                        : 0);
                    updateItem(item);
                  }
                },
              ),
            ]),
          );
  }

  updateItem(CompanySettings item) {
    int index = settingsData.indexWhere((element) => element.name == item.name);
    settingsData[index] = item;
  }

  saveData() {
    final body = {
      'toolBarSale': toolBarSaleId,
      'cashAC': cashAC,
      'stockValue': stockValue,
      'defaultLocation': defaultLocation,
      'decimalPoint': decimalPoint,
      'boxColor': boxColor,
      'toolBarColor': toolBarColor,
      'backhand': backhand,
      'data': settingsData
    };
    dio.updateGeneralSetting(body).then((value) {
      if (value) {
        ScopedModel.of<MainModel>(context).setSettings(settingsData);
        showInSnackBar('Settings Saved');
      } else {
        showInSnackBar('Error');
      }
    });
    dio.updateGeneralSettingMobile({
      "keySerialNo": controllerKeySerialNoTitle.text,
      "keyEWayApi": controllerKeyEWayApi.text.toString().toUpperCase(),
      "keyItemSP": controllerKeyItemSPTitle.text
    });
  }

  void showInSnackBar(String value) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  void controllerKeyEWayApiListener() {
    if (controllerKeyEWayApi.text.isNotEmpty) {
      var key = 'KEY EWAYBILLAPI OWNER';
      var value = controllerKeyEWayApi.text.toString();
      var itemExist =
          settingsData.where((element) => element.name.toUpperCase() == key);

      CompanySettings item = settingsData.firstWhere(
          (element) => element.name.toUpperCase() == key,
          orElse: () =>
              CompanySettings(id: 0, name: key, status: 0, value: ''));
      item.value = value;
      if (item.id > 0) {
        updateItem(item);
      } else {
        if (itemExist.isNotEmpty) {
          updateItem(item);
        } else {
          settingsData.add(item);
        }
      }
    }
  }

  void controllerKeyItemSPTitleListener() {
    if (controllerKeyItemSPTitle.text.isNotEmpty) {
      var key = 'KEY ITEM SP RATE TITLE';
      var value = controllerKeyEWayApi.text.toString();
      var itemExist =
          settingsData.where((element) => element.name.toUpperCase() == key);

      CompanySettings item = settingsData.firstWhere(
          (element) => element.name.toUpperCase() == key,
          orElse: () =>
              CompanySettings(id: 0, name: key, status: 0, value: ''));
      item.value = value;
      if (item.id > 0) {
        updateItem(item);
      } else {
        if (itemExist.isNotEmpty) {
          updateItem(item);
        } else {
          settingsData.add(item);
        }
      }
    }
  }

  void controllerKeySerialNoTitleListener() {
    if (controllerKeySerialNoTitle.text.isNotEmpty) {
      var key = 'KEY ITEM SERIAL NO';
      var value = controllerKeySerialNoTitle.text.toString();
      var itemExist =
          settingsData.where((element) => element.name.toUpperCase() == key);

      CompanySettings item = settingsData.firstWhere(
          (element) => element.name.toUpperCase() == key,
          orElse: () =>
              CompanySettings(id: 0, name: key, status: 0, value: ''));
      item.value = value;
      if (item.id > 0) {
        updateItem(item);
      } else {
        if (itemExist.isNotEmpty) {
          updateItem(item);
        } else {
          settingsData.add(item);
        }
      }
    }
  }
}
