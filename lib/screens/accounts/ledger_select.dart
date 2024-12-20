// @dart = 2.11
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/ledger_parent.dart';
import 'package:sheraccerp/models/other_registrations.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/screens/report_view.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';

class LedgerSelect extends StatefulWidget {
  const LedgerSelect({Key key}) : super(key: key);

  @override
  _LedgerSelectState createState() => _LedgerSelectState();
}

class _LedgerSelectState extends State<LedgerSelect> {
  TextEditingController editingController = TextEditingController();
  List<dynamic> items = [];
  List<dynamic> itemDisplay = [];
  List<DataJson> projectList = [];
  DioService api = DioService();
  bool _loading = true,
      _showQty = false,
      _ob = true,
      _gAll = true,
      isSalesManWiseLedger = false,
      isAdminUser = false,
      isProjectSoftware = false,
      _0b = false;
  var _ledger, _id, locationId, _dropDownBranchId;
  String fromDate,
      toDate,
      sType = 'Summery',
      area = '0',
      route = '0',
      projectId = '0';
  dynamic areaModel, routeModel;
  var statement = '';
  var salesMan = '0';
  var mode = '';
  DateTime now = DateTime.now();
  String radioButtonItem = 'All';
  int rdId = 1, groupId = 0, areaId = 0, routeId = 0;
  String selectedGroupValues = '', selectedStockValue = '';
  dynamic selectedItem;

  List<CompanySettings> settings;
  List<OtherRegistrationModel> otherRegAreaDataList = [];
  List<OtherRegistrationModel> otherRegRouteDataList = [];

  @override
  void initState() {
    super.initState();
    settings = ScopedModel.of<MainModel>(context).getSettings();
    fromDate = DateUtil.datePickerDMY(now);
    toDate = DateUtil.datePickerDMY(now);
    // final arguments = ModalRoute.of(context).settings.arguments as Map;
    Map arguments = argumentsPass;
    if (locationList.isNotEmpty) {
      _dropDownBranchId = locationList
          .where((element) => element.value == defaultLocation)
          .map((e) => e.key)
          .first;
    }

    groupId =
        ComSettings.appSettings('int', 'key-dropdown-default-group-view', 0) -
            1;
    areaId =
        ComSettings.appSettings('int', 'key-dropdown-default-area-view', 0) - 1;
    routeId =
        ComSettings.appSettings('int', 'key-dropdown-default-route-view', 0) -
            1;
    isSalesManWiseLedger =
        ComSettings.getStatus('KEY SALESMAN WISE LEDGER', settings);
    int salesManId = ComSettings.appSettings(
            'int', 'key-dropdown-default-salesman-view', 1) -
        1;

    isAdminUser =
        companyUserData.userType.toUpperCase() == 'ADMIN' ? true : false;
    if (!isAdminUser) {
      locationId = ComSettings.appSettings(
              'int', 'key-dropdown-default-location-view', 2) -
          1;
      salesMan = (ComSettings.appSettings(
                  'int', 'key-dropdown-default-salesman-view', 1) -
              1)
          .toString();
      OtherRegistrationModel otherData = otherRegLocationList.firstWhere(
          (element) => element.id == locationId,
          orElse: () => OtherRegistrationModel(
              add1: '',
              add2: '',
              add3: '',
              description: '',
              email: '',
              id: locationId,
              name: defaultLocation,
              type: ''));
      locationId = DataJson(id: otherData.id, name: otherData.name);
    }

    if (arguments != null) {
      mode = arguments['mode'];
      if (mode == "ledger") {
        _loading = true;
        statement = 'Ledger_Report';
        (isSalesManWiseLedger
                ? api.getLedgerBySalesMan(salesManId)
                : (groupId > 1
                    ? api.getLedgerByGroup(groupId)
                    : api.getLedgerAll()))
            .then((value) {
          setState(() {
            items.addAll(value);
            itemDisplay = items;
          });
        });
      } else if (mode == "billByBill") {
        statement = 'InvoiceWiseBalanceCustomers';
        _loading = false;
      } else if (mode == "DayBook") {
        statement = 'Day_Book';
        _loading = false;
        _ledger = 'CASH';
        _id = 0;
      } else if (mode == "ReceiptList" ||
          mode == 'PaymentList' ||
          mode == 'JournalList') {
        statement = mode;
        _loading = false;
        _ledger = 'CASH';
        _id = 0;
      } else if (mode == "CashBook") {
        statement = 'Ledger_Report';
        _loading = false;
        _ledger = 'CASH';
        _id = 0;
        mode = 'ledger';
        api.getLedger('CASH').then((value) {
          setState(() {
            // items.addAll(value);
            // itemDisplay = items;
            _ledger = value[0]['LedName'];
            _id = value[0]['Ledcode'];
          });
        });
      } else if (mode == "TrialBalance") {
        statement = 'Trial_Balance';
        _loading = false;
        _ledger = 'CASH';
        _id = 0;
      } else if (mode == "CashFlow") {
        api.getLedgerAll().then((value) {
          setState(() {
            items.addAll(value);
            itemDisplay = items;
          });
        });
        statement = 'Cash Flow';
      } else if (mode == "FundFlow") {
        statement = 'Fund Flow';
        _loading = false;
        _ledger = 'CASH';
        _id = 0;
      } else if (mode == "InvoiceWiseBalanceCustomers") {
        statement = 'InvoiceWiseBalanceCustomers';
        _loading = false;
        _ledger = 'CASH';
        _id = 0;
      } else if (mode == "InvoiceWiseBalanceSuppliers") {
        statement = 'InvoiceWiseBalanceSuppliers';
        _loading = false;
        _ledger = 'CASH';
        _id = 0;
      } else if (mode == "GroupList") {
        api.getLedgerGroupAll().then((value) {
          setState(() {
            items.addAll(value);
            itemDisplay = items;
          });
        });
        statement = 'SummeryAll';
        _loading = true;
        _id = 0;
        _ob = false;
      } else if (mode == "LedgerList") {
        _ledger = '';
        statement = 'SummeryAll';
        _loading = false;
        _id = 0;
        _ob = false;
      } else if (mode == "closingReport") {
        statement = 'Closing Report';
        _loading = false;
      } else if (mode == "P&LAccount") {
        statement = 'LAccount';
        _loading = false;
        List<dynamic> groupValues = [
          {'id': '1', 'name': 'Group'},
          {'id': '2', 'name': 'Group & Ledger'}
        ];
        List<dynamic> stockValue = [
          {'id': '1', 'name': 'Prate'},
          {'id': '2', 'name': 'RealPrate'}
        ];
        setState(() {
          items.addAll(groupValues);
          itemDisplay.addAll(stockValue);
          selectedGroupValues = items[0]['name'];
          selectedStockValue = itemDisplay[0]['name'];
        });
      } else if (mode == "BalanceSheet") {
        statement = 'BalanceSheet';
        _loading = false;
        List<dynamic> groupValues = [
          {'id': '1', 'name': 'Group'},
          {'id': '2', 'name': 'Detailed'}
        ];
        List<dynamic> stockValue = [
          {'id': '1', 'name': 'Prate'},
          {'id': '2', 'name': 'RealPrate'}
        ];
        setState(() {
          items.addAll(groupValues);
          itemDisplay.addAll(stockValue);
          selectedGroupValues = items[0]['name'];
          selectedStockValue = itemDisplay[0]['name'];
        });
      } else if (mode == 'Payable') {
        statement = 'ReceivblesCreditOnly';
        _loading = false;
        List<dynamic> groupValues = [
          {'id': '1', 'name': 'Normal'},
          {'id': '2', 'name': 'Invoice Wise'},
          {'id': '3', 'name': 'Detailed'},
          {'id': '4', 'name': 'Due Bill Date'},
          {'id': '5', 'name': 'Due Bills'},
          // {'id': '6', 'name': 'Ageing Report'},
          // {'id': '7', 'name': 'Receipt Wise Invoice Balance'},
          // {'id': '8', 'name': 'Payment Wise Invoice Balance'},
          // {'id': '9', 'name': 'B2B Customer Balance'},
          // {'id': '10', 'name': 'Bill Ageing Creditors'},
          // {'id': '11', 'name': 'Nearly Due Report'},
        ];
        // List<dynamic> stockValue = [
        //   {'id': '13', 'name': 'SUPPLIERS'},
        //   {'id': '9', 'name': 'ACCOUNTS PAYABLE'}
        // ];
        setState(() {
          items.addAll(groupValues);
          selectedGroupValues = items[0]['name'];
        });
        api.getLedgerGroupAll().then((value) {
          setState(() {
            itemDisplay.addAll(value);
            selectedItem = itemDisplay.firstWhere(
                (element) => element.name == 'SUPPLIERS',
                orElse: (() => {'id': 13, 'name': 'SUPPLIERS'}));
            selectedStockValue = selectedItem.name;
          });
        });
      } else if (mode == 'Receivable') {
        statement = 'ReceivblesDebitOnly';
        _loading = false;
        List<dynamic> groupValues = [
          {'id': '1', 'name': 'Normal'},
          {'id': '2', 'name': 'Invoice Wise'},
          {'id': '3', 'name': 'Detailed'},
          {'id': '4', 'name': 'Due Bill Date'},
          {'id': '5', 'name': 'Due Bills'},
          // {'id': '6', 'name': 'Ageing Report'},
          // {'id': '7', 'name': 'Receipt Wise Invoice Balance'},
          // {'id': '8', 'name': 'Payment Wise Invoice Balance'},
          // {'id': '9', 'name': 'B2B Customer Balance'},
          // {'id': '10', 'name': 'Bill Ageing Creditors'},
          // {'id': '11', 'name': 'Nearly Due Report'},
        ];
        setState(() {
          items.addAll(groupValues);
          selectedGroupValues = items[0]['name'];
        });
        api.getLedgerGroupAll().then((value) {
          setState(() {
            itemDisplay.addAll(value);
            selectedItem = itemDisplay.firstWhere(
                (element) => element.name == 'CUSTOMERS',
                orElse: (() => {'id': 12, 'name': 'CUSTOMERS'}));
            selectedStockValue = selectedItem.name;
          });
        });
      } else if (mode == 'selectedLedger') {
        setState(() {
          _loading = false;
          _ledger = arguments['name'];
          _id = arguments['id'];
          _showQty = true;
          mode = 'ledger';
        });
      }
    }

    if (otherRegAreaList.isNotEmpty) {
      otherRegAreaDataList.addAll(otherRegAreaList);
      if (areaId > 1) {
        areaModel = otherRegAreaDataList.firstWhere(
            (element) => element.id == areaId,
            orElse: () => OtherRegistrationModel.emptyData());
      } else {
        otherRegAreaDataList.add(OtherRegistrationModel.emptyData());
        areaModel = otherRegAreaDataList.last;
      }
    }

    if (otherRegRouteList.isNotEmpty) {
      otherRegRouteDataList.addAll(otherRegRouteList);
      if (routeId > 1) {
        areaModel = otherRegRouteDataList.firstWhere(
            (element) => element.id == routeId,
            orElse: () => OtherRegistrationModel.emptyData());
      } else {
        otherRegRouteDataList.add(OtherRegistrationModel.emptyData());
        routeModel = otherRegRouteDataList.last;
      }
    }

    isProjectSoftware = ComSettings.getStatus('PROJECT SOFTWARE', settings);
    if (isProjectSoftware) {
      api.getProject().then((value) {
        projectList = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                });
              },
              icon: const Icon(Icons.clear))
        ],
        title: Text(mode == 'ledger'
            ? 'Ledger Report'
            : mode == 'billByBill'
                ? 'Bill By Bill'
                : mode == 'closingReport'
                    ? 'Closing Report'
                    : mode == 'DayBook'
                        ? 'Day Book'
                        : mode == 'TrialBalance'
                            ? 'Trial Balance'
                            : mode == 'CashFlow'
                                ? 'Cash Flow'
                                : mode == 'FundFlow'
                                    ? 'Fund Flow'
                                    : mode == 'InvoiceWiseBalanceCustomers'
                                        ? 'Invoice Wise Balance Customers'
                                        : mode == 'InvoiceWiseBalanceSuppliers'
                                            ? 'Invoice Wise Balance Suppliers'
                                            : mode == 'GroupList'
                                                ? 'Group List'
                                                : mode == 'LedgerList'
                                                    ? 'Ledger List'
                                                    : mode == 'P&LAccount'
                                                        ? 'P&L Account'
                                                        : mode == 'BalanceSheet'
                                                            ? 'Balance Sheet'
                                                            : mode == 'Payable'
                                                                ? 'Payable'
                                                                : mode ==
                                                                        'Receivable'
                                                                    ? 'Receivable'
                                                                    : mode ==
                                                                            'ReceiptList'
                                                                        ? 'Receipt List'
                                                                        : mode ==
                                                                                'PaymentList'
                                                                            ? 'Payment List'
                                                                            : mode == 'JournalList'
                                                                                ? 'Journal List'
                                                                                : 'Select'),
      ),
      body: _loading ? _loadLedger() : _loadWidget(),
    );
  }

  _loadLedger() {
    return ListView.builder(
      // shrinkWrap: true,
      itemBuilder: (context, index) {
        return index == 0 ? _searchBar() : _listItem(index - 1);
      },
      itemCount: itemDisplay.length + 1,
    );
  }

  var stmtType = 'Closing Report';

  _loadWidget() {
    return mode == "ledger"
        ? Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  _ledger,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Card(
                  elevation: 0.5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text(
                        'From : ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      InkWell(
                        child: Text(
                          fromDate,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                        onTap: () => _selectDate('f'),
                      ),
                      const Text(
                        'To : ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      InkWell(
                        child: Text(
                          toDate,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                        onTap: () => _selectDate('t'),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Text('Opening Balance'),
                    Checkbox(
                      value: _ob,
                      onChanged: (value) {
                        setState(() {
                          _ob = value;
                        });
                      },
                    ),
                    const Text('Show Qty'),
                    Checkbox(
                      value: _showQty,
                      onChanged: (value) {
                        setState(() {
                          _showQty = value;
                        });
                      },
                    )
                  ],
                ),
                // Card(
                //   elevation: 2,
                //   child: DropDownSettingsTile<int>(
                //     title: 'Branch',
                //     settingKey: 'key-dropdown-default-location-view',
                //     values: locationList.isNotEmpty
                //         ? {for (var e in locationList) e.key + 1: e.value}
                //         : {
                //             2: '',
                //           },
                //     selected: 2,
                //     onChange: (value) {
                //       dropDownBranchId = value - 1;
                //     },
                //   ),
                // ),
                Visibility(
                  visible: isAdminUser,
                  child: DropdownSearch<dynamic>(
                    maxHeight: 300,
                    onFind: (String filter) =>
                        api.getSalesListData(filter, 'sales_list/location'),
                    dropdownSearchDecoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text('Select Branch')),
                    onChanged: (dynamic data) {
                      locationId = data;
                    },
                    showSearchBox: true,
                  ),
                ),
                Visibility(
                    visible: !isAdminUser,
                    child: Row(
                      children: [
                        const Text('Default Branch'),
                        Checkbox(
                          value: locationId == null,
                          onChanged: (value) {
                            setState(() {
                              locationId = null;
                            });
                          },
                        )
                      ],
                    )),
                const Divider(),
                projectWidget(),
                TextButton(
                  onPressed: () {
                    statement = _showQty ? 'Ledger_Report_Qty' : statement;
                    List<int> branches = locationId != null
                        ? [locationId.id]
                        : otherRegLocationList.map((e) => e.id).toList();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => ReportView(
                                _id.toString(),
                                (_ob ? '1' : '0'),
                                DateUtil.dateDMY2YMD(fromDate),
                                DateUtil.dateDMY2YMD(toDate),
                                'ledger',
                                _ledger,
                                statement,
                                salesMan,
                                branches,
                                area,
                                route,
                                projectId)));
                  },
                  child: const Text('Show'),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(kPrimaryColor),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                )
              ],
            ),
          )
        : mode == "DayBook"
            ? Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      _ledger,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Card(
                      elevation: 0.5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const Text(
                            'From : ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          InkWell(
                            child: Text(
                              fromDate,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                            onTap: () => _selectDate('f'),
                          ),
                          const Text(
                            'To : ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          InkWell(
                            child: Text(
                              toDate,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                            onTap: () => _selectDate('t'),
                          ),
                        ],
                      ),
                    ),
                    // Card(
                    //   elevation: 2,
                    //   child: DropDownSettingsTile<int>(
                    //     title: 'Branch',
                    //     settingKey: 'key-dropdown-default-location-view',
                    //     values: locationList.isNotEmpty
                    //         ? {for (var e in locationList) e.key + 1: e.value}
                    //         : {
                    //             2: '',
                    //           },
                    //     selected: 2,
                    //     onChange: (value) {

                    //       dropDownBranchId = value - 1;
                    //     },
                    //   ),
                    // ),
                    Visibility(
                      visible: isAdminUser,
                      child: DropdownSearch<dynamic>(
                        maxHeight: 300,
                        onFind: (String filter) =>
                            api.getSalesListData(filter, 'sales_list/location'),
                        dropdownSearchDecoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            label: Text('Select Branch')),
                        onChanged: (dynamic data) {
                          locationId = data;
                        },
                        showSearchBox: true,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) => ReportView(
                                    _id.toString(),
                                    (_ob ? '1' : '0'),
                                    DateUtil.dateDMY2YMD(fromDate),
                                    DateUtil.dateDMY2YMD(toDate),
                                    'Day Book',
                                    _ledger,
                                    statement,
                                    salesMan,
                                    locationId != null
                                        ? [locationId.id]
                                        : [_dropDownBranchId],
                                    area,
                                    route,
                                    '0')));
                      },
                      child: const Text('Show'),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(kPrimaryColor),
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                      ),
                    )
                  ],
                ),
              )
            : mode == "TrialBalance"
                ? Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // Text(
                        //   _ledger,
                        //   style: TextStyle(
                        //       fontWeight: FontWeight.bold, fontSize: 18),
                        // ),
                        Card(
                          elevation: 0.5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              const Text(
                                'From : ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              InkWell(
                                child: Text(
                                  fromDate,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22),
                                ),
                                onTap: () => _selectDate('f'),
                              ),
                              const Text(
                                'To : ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              InkWell(
                                child: Text(
                                  toDate,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22),
                                ),
                                onTap: () => _selectDate('t'),
                              ),
                            ],
                          ),
                        ),
                        // Card(
                        //   elevation: 2,
                        //   child: DropDownSettingsTile<int>(
                        //     title: 'Branch',
                        //     settingKey: 'key-dropdown-default-location-view',
                        //     values: locationList.isNotEmpty
                        //         ? {
                        //             for (var e in locationList)
                        //               e.key + 1: e.value
                        //           }
                        //         : {
                        //             2: '',
                        //           },
                        //     selected: 2,
                        //     onChange: (value) {
                        //       dropDownBranchId = value - 1;
                        //     },
                        //   ),
                        // ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        ReportView(
                                            _id.toString(),
                                            (_ob ? '1' : '0'),
                                            DateUtil.dateDMY2YMD(fromDate),
                                            DateUtil.dateDMY2YMD(toDate),
                                            'Trial Balance',
                                            _ledger,
                                            statement,
                                            salesMan,
                                            locationId != null
                                                ? [locationId.id]
                                                : [_dropDownBranchId],
                                            area,
                                            route,
                                            '0')));
                          },
                          child: const Text('Show'),
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(kPrimaryColor),
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                          ),
                        )
                      ],
                    ),
                  )
                : mode == 'CashFlow'
                    ? Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              _ledger,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Card(
                              elevation: 0.5,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  const Text(
                                    'From : ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  InkWell(
                                    child: Text(
                                      fromDate,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22),
                                    ),
                                    onTap: () => _selectDate('f'),
                                  ),
                                  const Text(
                                    'To : ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  InkWell(
                                    child: Text(
                                      toDate,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22),
                                    ),
                                    onTap: () => _selectDate('t'),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            ReportView(
                                                _id.toString(),
                                                (_ob ? '1' : '0'),
                                                DateUtil.dateDMY2YMD(fromDate),
                                                DateUtil.dateDMY2YMD(toDate),
                                                'Cash Flow',
                                                _ledger,
                                                statement,
                                                salesMan,
                                                locationId != null
                                                    ? [locationId.id]
                                                    : [_dropDownBranchId],
                                                area,
                                                route,
                                                '0')));
                              },
                              child: const Text('Show'),
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        kPrimaryColor),
                                foregroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.white),
                              ),
                            )
                          ],
                        ),
                      )
                    : mode == 'FundFlow'
                        ? Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Card(
                                  elevation: 0.5,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      const Text(
                                        'From : ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      InkWell(
                                        child: Text(
                                          fromDate,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22),
                                        ),
                                        onTap: () => _selectDate('f'),
                                      ),
                                      const Text(
                                        'To : ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      InkWell(
                                        child: Text(
                                          toDate,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22),
                                        ),
                                        onTap: () => _selectDate('t'),
                                      ),
                                    ],
                                  ),
                                ),
                                // Row(
                                //   children: [
                                //     Text('Opening Balance'),
                                //     Checkbox(
                                //       value: _ob,
                                //       onChanged: (value) {
                                //         setState(() {
                                //           _ob = value;
                                //         });
                                //       },
                                //     ),
                                //   ],
                                // ),
                                // Card(
                                //   elevation: 2,
                                //   child: DropDownSettingsTile<int>(
                                //     title: 'Branch',
                                //     settingKey:
                                //         'key-dropdown-default-location-view',
                                //     values: locationList.isNotEmpty
                                //         ? Map.fromIterable(locationList,
                                //             key: (e) => e.key + 1,
                                //             value: (e) => e.value)
                                //         : {
                                //             2: '',
                                //           },
                                //     selected: 2,
                                //     onChange: (value) {
                                //       dropDownBranchId = value - 1;
                                //     },
                                //   ),
                                // ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                ReportView(
                                                    _id.toString(),
                                                    (_ob ? '1' : '0'),
                                                    DateUtil.dateDMY2YMD(
                                                        fromDate),
                                                    DateUtil.dateDMY2YMD(
                                                        toDate),
                                                    'Fund Flow',
                                                    _ledger,
                                                    statement,
                                                    salesMan,
                                                    locationId != null
                                                        ? [locationId.id]
                                                        : [_dropDownBranchId],
                                                    area,
                                                    route,
                                                    '0')));
                                  },
                                  child: const Text('Show'),
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            kPrimaryColor),
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.white),
                                  ),
                                )
                              ],
                            ),
                          )
                        : mode == 'InvoiceWiseBalanceCustomers'
                            ? Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Card(
                                      elevation: 0.5,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          const Text(
                                            'From : ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          InkWell(
                                            child: Text(
                                              fromDate,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 22),
                                            ),
                                            onTap: () => _selectDate('f'),
                                          ),
                                          const Text(
                                            'To : ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          InkWell(
                                            child: Text(
                                              toDate,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 22),
                                            ),
                                            onTap: () => _selectDate('t'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (BuildContext
                                                        context) =>
                                                    ReportView(
                                                        _id.toString(),
                                                        (_ob ? '1' : '0'),
                                                        DateUtil.dateDMY2YMD(
                                                            fromDate),
                                                        DateUtil.dateDMY2YMD(
                                                            toDate),
                                                        'Invoice Wise Balance Customers',
                                                        _ledger,
                                                        statement,
                                                        salesMan,
                                                        locationId != null
                                                            ? [locationId.id]
                                                            : [
                                                                _dropDownBranchId
                                                              ],
                                                        area,
                                                        route,
                                                        '0')));
                                      },
                                      child: const Text('Show'),
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                kPrimaryColor),
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : mode == 'InvoiceWiseBalanceSuppliers'
                                ? Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Card(
                                          elevation: 0.5,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              const Text(
                                                'From : ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              InkWell(
                                                child: Text(
                                                  fromDate,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 22),
                                                ),
                                                onTap: () => _selectDate('f'),
                                              ),
                                              const Text(
                                                'To : ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              InkWell(
                                                child: Text(
                                                  toDate,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 22),
                                                ),
                                                onTap: () => _selectDate('t'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (BuildContext
                                                            context) =>
                                                        ReportView(
                                                            _id.toString(),
                                                            (_ob ? '1' : '0'),
                                                            DateUtil
                                                                .dateDMY2YMD(
                                                                    fromDate),
                                                            DateUtil
                                                                .dateDMY2YMD(
                                                                    toDate),
                                                            'Invoice Wise Balance Suppliers',
                                                            _ledger,
                                                            statement,
                                                            salesMan,
                                                            locationId !=
                                                                    null
                                                                ? [
                                                                    locationId
                                                                        .id
                                                                  ]
                                                                : [
                                                                    _dropDownBranchId
                                                                  ],
                                                            area,
                                                            route,
                                                            '0')));
                                          },
                                          child: const Text('Show'),
                                          style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all<
                                                    Color>(kPrimaryColor),
                                            foregroundColor:
                                                MaterialStateProperty.all<
                                                    Color>(Colors.white),
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                : mode == 'GroupList'
                                    ? Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              _ledger,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ),
                                            Card(
                                              elevation: 0.5,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  const Text(
                                                    'From : ',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                  InkWell(
                                                    child: Text(
                                                      fromDate,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 22),
                                                    ),
                                                    onTap: () =>
                                                        _selectDate('f'),
                                                  ),
                                                  const Text(
                                                    'To : ',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                  InkWell(
                                                    child: Text(
                                                      toDate,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 22),
                                                    ),
                                                    onTap: () =>
                                                        _selectDate('t'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Radio(
                                                  value: 1,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      rdId = 1;
                                                      radioButtonItem = 'All';
                                                      _gAll = true;
                                                      _ob = false;
                                                      _0b = false;
                                                    });
                                                  },
                                                  groupValue: rdId,
                                                ),
                                                const Text('All'),
                                                Radio(
                                                  value: 2,
                                                  groupValue: rdId,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      rdId = 2;
                                                      radioButtonItem =
                                                          'Balance';
                                                      _ob = true;
                                                      _gAll = false;
                                                      _0b = false;
                                                    });
                                                  },
                                                ),
                                                const Text('Balance'),
                                                Radio(
                                                  value: 3,
                                                  groupValue: rdId,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      rdId = 3;
                                                      radioButtonItem =
                                                          '0 Balance';
                                                      _0b = true;
                                                      _gAll = false;
                                                      _ob = false;
                                                    });
                                                  },
                                                ),
                                                const Text('0 Balance'),
                                              ],
                                            ),
                                            Visibility(
                                              visible: isAdminUser,
                                              child: DropdownSearch<dynamic>(
                                                maxHeight: 300,
                                                onFind: (String filter) =>
                                                    api.getSalesListData(filter,
                                                        'sales_list/location'),
                                                dropdownSearchDecoration:
                                                    const InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        label: Text(
                                                            'Select Branch')),
                                                onChanged: (dynamic data) {
                                                  locationId = data;
                                                },
                                                showSearchBox: true,
                                              ),
                                            ),
                                            Card(
                                              elevation: 2,
                                              child: DropdownButton(
                                                icon: const Icon(
                                                    Icons.keyboard_arrow_down),
                                                items: [
                                                  'Summery',
                                                  'Simple',
                                                  'Ledger Model',
                                                  'Summery Area Wise',
                                                  'Group & Ledger',
                                                  'PV/RV Report',
                                                  'Salesman Wise Group List',
                                                  'Group List All Groups',
                                                  'Balance Order By Date',
                                                  'Summery Route Wise',
                                                  'Group Location Wise'
                                                ].map((String items) {
                                                  return DropdownMenuItem(
                                                    value: items,
                                                    child: Text(items),
                                                  );
                                                }).toList(),
                                                value: sType,
                                                onChanged: (value) {
                                                  setState(() {
                                                    sType = value;
                                                    statement = value ==
                                                            'Summery'
                                                        ? 'SummeryAll'
                                                        : value == 'Simple'
                                                            ? 'SimpleGList'
                                                            : value ==
                                                                    'Ledger Model'
                                                                ? 'Ledger_Model'
                                                                : value ==
                                                                        'Summery Area Wise'
                                                                    ? 'SummeryAreaWise'
                                                                    : value ==
                                                                            'Summery Route Wise'
                                                                        ? 'SummeryRouteWise'
                                                                        : value ==
                                                                                'Group & Ledger'
                                                                            ? 'Group_Ledger'
                                                                            : value == 'PV/RV Report'
                                                                                ? 'PV/RV Report'
                                                                                : value == 'Salesman Wise Group List'
                                                                                    ? 'SalesmanGroupList'
                                                                                    : value == 'Group List All Groups'
                                                                                        ? 'GroupListAllGroups'
                                                                                        : value == 'Balance Order By Date'
                                                                                            ? 'Balance Order By Date'
                                                                                            : 'SummeryAll';
                                                  });
                                                },
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                statement = sType == 'Summery'
                                                    ? _gAll
                                                        ? 'SummeryAll'
                                                        : _ob
                                                            ? 'SummeryBalanceOnly'
                                                            : 'SummeryZeroBalanceOnly'
                                                    : statement;
                                                if (sType ==
                                                    'Summery Route Wise') {
                                                  area = route;
                                                }
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (BuildContext
                                                                context) =>
                                                            ReportView(
                                                                _id.toString(),
                                                                (_ob
                                                                    ? '1'
                                                                    : '0'),
                                                                DateUtil
                                                                    .dateDMY2YMD(
                                                                        fromDate),
                                                                DateUtil
                                                                    .dateDMY2YMD(
                                                                        toDate),
                                                                'GroupList',
                                                                _ledger,
                                                                statement,
                                                                salesMan,
                                                                locationId !=
                                                                        null
                                                                    ? [
                                                                        locationId
                                                                            .id
                                                                      ]
                                                                    : [
                                                                        _dropDownBranchId
                                                                      ],
                                                                area,
                                                                route,
                                                                '0')));
                                              },
                                              child: const Text('Show'),
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    MaterialStateProperty.all<
                                                        Color>(kPrimaryColor),
                                                foregroundColor:
                                                    MaterialStateProperty.all<
                                                        Color>(Colors.white),
                                              ),
                                            ),
                                            const Divider(),
                                            Card(
                                              elevation: 5,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  const Text('Select Area'),
                                                  DropdownButton<
                                                      OtherRegistrationModel>(
                                                    icon: const Icon(Icons
                                                        .keyboard_arrow_down),
                                                    items: otherRegAreaDataList
                                                        .map(
                                                            (OtherRegistrationModel
                                                                items) {
                                                      return DropdownMenuItem<
                                                          OtherRegistrationModel>(
                                                        value: items,
                                                        child: Text(items.name),
                                                      );
                                                    }).toList(),
                                                    value: areaModel,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        areaModel = value;
                                                        area =
                                                            value.id.toString();
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Divider(),
                                            Card(
                                              elevation: 5,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  const Text('Select Route'),
                                                  DropdownButton<
                                                      OtherRegistrationModel>(
                                                    icon: const Icon(Icons
                                                        .keyboard_arrow_down),
                                                    items: otherRegRouteDataList
                                                        .map(
                                                            (OtherRegistrationModel
                                                                items) {
                                                      return DropdownMenuItem<
                                                          OtherRegistrationModel>(
                                                        value: items,
                                                        child: Text(items.name),
                                                      );
                                                    }).toList(),
                                                    value: routeModel,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        routeModel = value;
                                                        route =
                                                            value.id.toString();
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Divider(),
                                            Visibility(
                                              visible: isAdminUser,
                                              child: DropdownSearch<dynamic>(
                                                maxHeight: 300,
                                                onFind: (String filter) =>
                                                    api.getSalesListData(filter,
                                                        'sales_list/salesMan'),
                                                dropdownSearchDecoration:
                                                    const InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        label: Text(
                                                            'Select Salesman')),
                                                onChanged: (dynamic data) {
                                                  salesMan = data.id.toString();
                                                },
                                                showSearchBox: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : mode == 'LedgerList'
                                        ? const Center(child: Text('empty'))
                                        : mode == 'closingReport'
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  children: [
                                                    Card(
                                                      elevation: 0.5,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceAround,
                                                        children: [
                                                          const Text(
                                                            'From : ',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16),
                                                          ),
                                                          InkWell(
                                                            child: Text(
                                                              fromDate,
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 22),
                                                            ),
                                                            onTap: () =>
                                                                _selectDate(
                                                                    'f'),
                                                          ),
                                                          const Text(
                                                            'To : ',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16),
                                                          ),
                                                          InkWell(
                                                            child: Text(
                                                              toDate,
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 22),
                                                            ),
                                                            onTap: () =>
                                                                _selectDate(
                                                                    't'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Card(
                                                      elevation: 2,
                                                      child: DropdownButton(
                                                        icon: const Icon(Icons
                                                            .keyboard_arrow_down),
                                                        items: [
                                                          'Closing Report',
                                                          'Style1',
                                                          'Style2',
                                                          'Daily / Monthly',
                                                          'AsperMart'
                                                        ].map((String items) {
                                                          return DropdownMenuItem(
                                                            value: items,
                                                            child: Text(items),
                                                          );
                                                        }).toList(),
                                                        value: stmtType,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            stmtType = value;
                                                            statement = value;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible: isAdminUser,
                                                      child: DropdownSearch<
                                                          dynamic>(
                                                        maxHeight: 300,
                                                        onFind: (String
                                                                filter) =>
                                                            api.getSalesListData(
                                                                filter,
                                                                'sales_list/location'),
                                                        dropdownSearchDecoration:
                                                            const InputDecoration(
                                                                border:
                                                                    OutlineInputBorder(),
                                                                label: Text(
                                                                    'Select Branch')),
                                                        onChanged:
                                                            (dynamic data) {
                                                          locationId = data;
                                                        },
                                                        showSearchBox: true,
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (BuildContext context) => ReportView(
                                                                    '0',
                                                                    (_ob
                                                                        ? '1'
                                                                        : '0'),
                                                                    DateUtil.dateDMY2YMD(
                                                                        fromDate),
                                                                    DateUtil.dateDMY2YMD(
                                                                        toDate),
                                                                    'Closing Report',
                                                                    '',
                                                                    statement,
                                                                    salesMan,
                                                                    locationId !=
                                                                            null
                                                                        ? [
                                                                            locationId.id
                                                                          ]
                                                                        : [
                                                                            _dropDownBranchId
                                                                          ],
                                                                    area,
                                                                    route,
                                                                    '0')));
                                                      },
                                                      child: const Text('Show'),
                                                      style: ButtonStyle(
                                                        backgroundColor:
                                                            MaterialStateProperty
                                                                .all<Color>(
                                                                    kPrimaryColor),
                                                        foregroundColor:
                                                            MaterialStateProperty
                                                                .all<Color>(
                                                                    Colors
                                                                        .white),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              )
                                            : mode == 'P&LAccount'
                                                ? Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Column(
                                                      children: [
                                                        Card(
                                                          elevation: 0.5,
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceAround,
                                                            children: [
                                                              const Text(
                                                                'From : ',
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16),
                                                              ),
                                                              InkWell(
                                                                child: Text(
                                                                  fromDate,
                                                                  style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          22),
                                                                ),
                                                                onTap: () =>
                                                                    _selectDate(
                                                                        'f'),
                                                              ),
                                                              const Text(
                                                                'To : ',
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16),
                                                              ),
                                                              InkWell(
                                                                child: Text(
                                                                  toDate,
                                                                  style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          22),
                                                                ),
                                                                onTap: () =>
                                                                    _selectDate(
                                                                        't'),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Text(
                                                                'Report Type      '),
                                                            const SizedBox(
                                                                width: 10),
                                                            Expanded(
                                                              child:
                                                                  DropdownButton(
                                                                      items: items.map(
                                                                          (dynamic
                                                                              items) {
                                                                        return DropdownMenuItem(
                                                                          value:
                                                                              items['name'],
                                                                          child:
                                                                              Text(items['name'].toString()),
                                                                        );
                                                                      }).toList(),
                                                                      value:
                                                                          selectedGroupValues,
                                                                      onChanged:
                                                                          ((value) {
                                                                        setState(
                                                                            () {
                                                                          selectedGroupValues =
                                                                              value;
                                                                        });
                                                                      })),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Text(
                                                                'Stock Valuation'),
                                                            const SizedBox(
                                                                width: 10),
                                                            Expanded(
                                                              child:
                                                                  DropdownButton(
                                                                      items: itemDisplay.map(
                                                                          (dynamic
                                                                              items) {
                                                                        return DropdownMenuItem(
                                                                          value:
                                                                              items['name'],
                                                                          child:
                                                                              Text(items['name'].toString()),
                                                                        );
                                                                      }).toList(),
                                                                      value:
                                                                          selectedStockValue,
                                                                      onChanged:
                                                                          ((value) {
                                                                        setState(
                                                                            () {
                                                                          selectedStockValue =
                                                                              value;
                                                                        });
                                                                      })),
                                                            ),
                                                          ],
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder: (BuildContext context) => ReportView(
                                                                        '0',
                                                                        (_ob
                                                                            ? '1'
                                                                            : '0'),
                                                                        DateUtil.dateDMY2YMD(
                                                                            fromDate),
                                                                        DateUtil.dateDMY2YMD(
                                                                            toDate),
                                                                        'P&L Account',
                                                                        selectedStockValue,
                                                                        selectedGroupValues,
                                                                        salesMan,
                                                                        locationId !=
                                                                                null
                                                                            ? [
                                                                                locationId.id
                                                                              ]
                                                                            : [
                                                                                _dropDownBranchId
                                                                              ],
                                                                        area,
                                                                        route,
                                                                        '0')));
                                                          },
                                                          child: const Text(
                                                              'Show'),
                                                          style: ButtonStyle(
                                                            backgroundColor:
                                                                MaterialStateProperty
                                                                    .all<Color>(
                                                                        kPrimaryColor),
                                                            foregroundColor:
                                                                MaterialStateProperty
                                                                    .all<Color>(
                                                                        Colors
                                                                            .white),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  )
                                                : mode == 'BalanceSheet'
                                                    ? Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Column(
                                                          children: [
                                                            Card(
                                                              elevation: 0.5,
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceAround,
                                                                children: [
                                                                  const Text(
                                                                    'From : ',
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                  InkWell(
                                                                    child: Text(
                                                                      fromDate,
                                                                      style: const TextStyle(
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              22),
                                                                    ),
                                                                    onTap: () =>
                                                                        _selectDate(
                                                                            'f'),
                                                                  ),
                                                                  const Text(
                                                                    'To : ',
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                  InkWell(
                                                                    child: Text(
                                                                      toDate,
                                                                      style: const TextStyle(
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              22),
                                                                    ),
                                                                    onTap: () =>
                                                                        _selectDate(
                                                                            't'),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Row(
                                                              children: [
                                                                const Text(
                                                                    'Report Type      '),
                                                                const SizedBox(
                                                                    width: 10),
                                                                Expanded(
                                                                  child: DropdownButton(
                                                                      items: items.map((dynamic items) {
                                                                        return DropdownMenuItem(
                                                                          value:
                                                                              items['name'],
                                                                          child:
                                                                              Text(items['name'].toString()),
                                                                        );
                                                                      }).toList(),
                                                                      value: selectedGroupValues,
                                                                      onChanged: ((value) {
                                                                        setState(
                                                                            () {
                                                                          selectedGroupValues =
                                                                              value;
                                                                        });
                                                                      })),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: [
                                                                const Text(
                                                                    'Stock Valuation'),
                                                                const SizedBox(
                                                                    width: 10),
                                                                Expanded(
                                                                  child: DropdownButton(
                                                                      items: itemDisplay.map((dynamic items) {
                                                                        return DropdownMenuItem(
                                                                          value:
                                                                              items['name'],
                                                                          child:
                                                                              Text(items['name'].toString()),
                                                                        );
                                                                      }).toList(),
                                                                      value: selectedStockValue,
                                                                      onChanged: ((value) {
                                                                        setState(
                                                                            () {
                                                                          selectedStockValue =
                                                                              value;
                                                                        });
                                                                      })),
                                                                ),
                                                              ],
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder: (BuildContext context) => ReportView(
                                                                            '0',
                                                                            (_ob
                                                                                ? '1'
                                                                                : '0'),
                                                                            DateUtil.dateDMY2YMD(
                                                                                fromDate),
                                                                            DateUtil.dateDMY2YMD(
                                                                                toDate),
                                                                            'BalanceSheet',
                                                                            selectedStockValue,
                                                                            selectedGroupValues,
                                                                            salesMan,
                                                                            locationId != null
                                                                                ? [
                                                                                    locationId.id
                                                                                  ]
                                                                                : [
                                                                                    _dropDownBranchId
                                                                                  ],
                                                                            area,
                                                                            route,
                                                                            '0')));
                                                              },
                                                              child: const Text(
                                                                  'Show'),
                                                              style:
                                                                  ButtonStyle(
                                                                backgroundColor:
                                                                    MaterialStateProperty.all<
                                                                            Color>(
                                                                        kPrimaryColor),
                                                                foregroundColor:
                                                                    MaterialStateProperty.all<
                                                                            Color>(
                                                                        Colors
                                                                            .white),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      )
                                                    : mode == 'Payable' ||
                                                            mode == 'Receivable'
                                                        ? Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Column(
                                                              children: [
                                                                Card(
                                                                  elevation:
                                                                      0.5,
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceAround,
                                                                    children: [
                                                                      const Text(
                                                                        'From : ',
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontSize: 16),
                                                                      ),
                                                                      InkWell(
                                                                        child:
                                                                            Text(
                                                                          fromDate,
                                                                          style: const TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 22),
                                                                        ),
                                                                        onTap: () =>
                                                                            _selectDate('f'),
                                                                      ),
                                                                      const Text(
                                                                        'To : ',
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontSize: 16),
                                                                      ),
                                                                      InkWell(
                                                                        child:
                                                                            Text(
                                                                          toDate,
                                                                          style: const TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 22),
                                                                        ),
                                                                        onTap: () =>
                                                                            _selectDate('t'),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    const Text(
                                                                        'Report Type'),
                                                                    const SizedBox(
                                                                        width:
                                                                            10),
                                                                    Expanded(
                                                                      child: DropdownButton(
                                                                          items: items.map((dynamic items) {
                                                                            return DropdownMenuItem(
                                                                              value: items['name'],
                                                                              child: Text(items['name'].toString()),
                                                                            );
                                                                          }).toList(),
                                                                          value: selectedGroupValues,
                                                                          onChanged: ((value) {
                                                                            setState(() {
                                                                              selectedGroupValues = value;
                                                                            });
                                                                          })),
                                                                    ),
                                                                  ],
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    const Text(
                                                                        'Group          '),
                                                                    const SizedBox(
                                                                        width:
                                                                            10),
                                                                    itemDisplay
                                                                            .isEmpty
                                                                        ? DropdownButton(
                                                                            items:
                                                                                [
                                                                              LedgerParent(id: 12, name: 'CUSTOMERS'),
                                                                            ].map((dynamic items) {
                                                                              return DropdownMenuItem(
                                                                                value: items,
                                                                                child: Text(items.name.toString()),
                                                                              );
                                                                            }).toList(),
                                                                            value: selectedItem,
                                                                            onChanged: ((value) {
                                                                              setState(() {
                                                                                selectedItem = value;
                                                                              });
                                                                            }))
                                                                        : Expanded(
                                                                            child: DropdownButton(
                                                                                items: itemDisplay.map((dynamic items) {
                                                                                  return DropdownMenuItem(
                                                                                    value: items,
                                                                                    child: Text(items.name.toString()),
                                                                                  );
                                                                                }).toList(),
                                                                                value: selectedItem,
                                                                                onChanged: ((value) {
                                                                                  setState(() {
                                                                                    selectedItem = value;
                                                                                  });
                                                                                })),
                                                                          ),
                                                                  ],
                                                                ),
                                                                DropdownSearch<
                                                                    dynamic>(
                                                                  maxHeight:
                                                                      300,
                                                                  onFind: (String
                                                                          filter) =>
                                                                      api.getSalesListData(
                                                                          filter,
                                                                          'sales_list/customer'),
                                                                  dropdownSearchDecoration: const InputDecoration(
                                                                      border:
                                                                          OutlineInputBorder(),
                                                                      labelText:
                                                                          "Select Customer"),
                                                                  onChanged:
                                                                      (dynamic
                                                                          data) {
                                                                    // _ledger = itemDisplay[index].name;
                                                                    // _id = itemDisplay[index].id;
                                                                    // customer = data;
                                                                    _id =
                                                                        data.id;
                                                                  },
                                                                  showSearchBox:
                                                                      true,
                                                                ),
                                                                const Divider(),
                                                                DropdownSearch<
                                                                    dynamic>(
                                                                  maxHeight:
                                                                      300,
                                                                  onFind: (String
                                                                          filter) =>
                                                                      api.getSalesListData(
                                                                          filter,
                                                                          'sales_list/location'),
                                                                  dropdownSearchDecoration: const InputDecoration(
                                                                      border:
                                                                          OutlineInputBorder(),
                                                                      label: Text(
                                                                          'Select Branch')),
                                                                  onChanged:
                                                                      (dynamic
                                                                          data) {
                                                                    locationId =
                                                                        data;
                                                                  },
                                                                  showSearchBox:
                                                                      true,
                                                                ),
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    statement = mode ==
                                                                            'Payable'
                                                                        ? selectedGroupValues ==
                                                                                'Invoice Wise'
                                                                            ? 'InvoiceWiseBalanceSuppliers'
                                                                            : selectedGroupValues == 'Detailed'
                                                                                ? 'Receivable_Details'
                                                                                : selectedGroupValues == 'Due Bill Date'
                                                                                    ? 'DueBillBalance_Report'
                                                                                    : selectedGroupValues == 'Due Bills'
                                                                                        ? 'DueBills_Receivable'
                                                                                        : selectedGroupValues == 'Ageing Report'
                                                                                            ? 'Receivable_Ageing'
                                                                                            : selectedGroupValues == 'Receipt Wise Invoice Balance'
                                                                                                ? 'ReceiptWiseCustomerbalance'
                                                                                                : selectedGroupValues == 'Payment Wise Invoice Balance'
                                                                                                    ? 'PaymentWiseSupplierbalance'
                                                                                                    : selectedGroupValues == 'B2B Customer Balance'
                                                                                                        ? 'B2B_Customer_Balance'
                                                                                                        : selectedGroupValues == 'Bill Ageing Creditors'
                                                                                                            ? 'Bill_Ageing_Creditors'
                                                                                                            : selectedGroupValues == 'Nearly Due Report'
                                                                                                                ? 'Nearly_Due_Report'
                                                                                                                : 'ReceivblesCreditOnly'
                                                                        : selectedGroupValues == 'Invoice Wise'
                                                                            ? 'InvoiceWiseBalanceCustomers'
                                                                            : selectedGroupValues == 'Detailed'
                                                                                ? 'Receivable_Master_Detail'
                                                                                : selectedGroupValues == 'Due Bill Date'
                                                                                    ? 'DueBillBalance_Report'
                                                                                    : selectedGroupValues == 'Due Bills'
                                                                                        ? 'DueBills_Receivable'
                                                                                        : selectedGroupValues == 'Ageing Report'
                                                                                            ? 'DueBills_Receivable'
                                                                                            : selectedGroupValues == 'Receipt Wise Invoice Balance'
                                                                                                ? 'DueBills_Receivable'
                                                                                                : selectedGroupValues == 'Payment Wise Invoice Balance'
                                                                                                    ? 'DueBills_Receivable'
                                                                                                    : selectedGroupValues == 'B2B Customer Balance'
                                                                                                        ? 'DueBills_Receivable'
                                                                                                        : selectedGroupValues == 'Bill Ageing Creditors'
                                                                                                            ? 'DueBills_Receivable'
                                                                                                            : selectedGroupValues == 'Nearly Due Report'
                                                                                                                ? 'DueBills_Receivable'
                                                                                                                : 'ReceivblesDebitOnly';

                                                                    Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (BuildContext context) => ReportView(
                                                                                selectedGroupValues == 'Due Bills' ? (_id != null ? _id.toString() : '0') : selectedItem.id.toString(),
                                                                                (_ob ? '1' : '0'),
                                                                                DateUtil.dateDMY2YMD(fromDate),
                                                                                DateUtil.dateDMY2YMD(toDate),
                                                                                mode,
                                                                                selectedItem.name,
                                                                                statement,
                                                                                salesMan,
                                                                                locationId != null ? [locationId.id] : [_dropDownBranchId],
                                                                                area,
                                                                                route,
                                                                                _id != null ? _id.toString() : '0')));
                                                                  },
                                                                  child:
                                                                      const Text(
                                                                          'Show'),
                                                                  style:
                                                                      ButtonStyle(
                                                                    backgroundColor:
                                                                        MaterialStateProperty.all<Color>(
                                                                            kPrimaryColor),
                                                                    foregroundColor: MaterialStateProperty.all<
                                                                            Color>(
                                                                        Colors
                                                                            .white),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          )
                                                        : mode == 'PaymentList' ||
                                                                mode ==
                                                                    'ReceiptList'
                                                            ? Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        8.0),
                                                                child: Column(
                                                                  children: [
                                                                    Card(
                                                                      elevation:
                                                                          0.5,
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceAround,
                                                                        children: [
                                                                          const Text(
                                                                            'From : ',
                                                                            style:
                                                                                TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                                          ),
                                                                          InkWell(
                                                                            child:
                                                                                Text(
                                                                              fromDate,
                                                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                                                                            ),
                                                                            onTap: () =>
                                                                                _selectDate('f'),
                                                                          ),
                                                                          const Text(
                                                                            'To : ',
                                                                            style:
                                                                                TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                                          ),
                                                                          InkWell(
                                                                            child:
                                                                                Text(
                                                                              toDate,
                                                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                                                                            ),
                                                                            onTap: () =>
                                                                                _selectDate('t'),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Visibility(
                                                                      visible:
                                                                          isAdminUser,
                                                                      child: DropdownSearch<
                                                                          dynamic>(
                                                                        maxHeight:
                                                                            300,
                                                                        onFind: (String filter) => api.getSalesListData(
                                                                            filter,
                                                                            'sales_list/location'),
                                                                        dropdownSearchDecoration: const InputDecoration(
                                                                            border:
                                                                                OutlineInputBorder(),
                                                                            label:
                                                                                Text('Select Branch')),
                                                                        onChanged:
                                                                            (dynamic
                                                                                data) {
                                                                          locationId =
                                                                              data;
                                                                        },
                                                                        showSearchBox:
                                                                            true,
                                                                      ),
                                                                    ),
                                                                    const Divider(),
                                                                    Card(
                                                                      elevation:
                                                                          5,
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceAround,
                                                                        children: [
                                                                          const Text(
                                                                              'Select Area'),
                                                                          DropdownButton<
                                                                              OtherRegistrationModel>(
                                                                            icon:
                                                                                const Icon(Icons.keyboard_arrow_down),
                                                                            items:
                                                                                otherRegAreaDataList.map((OtherRegistrationModel items) {
                                                                              return DropdownMenuItem<OtherRegistrationModel>(
                                                                                value: items,
                                                                                child: Text(items.name),
                                                                              );
                                                                            }).toList(),
                                                                            value:
                                                                                areaModel,
                                                                            onChanged:
                                                                                (value) {
                                                                              setState(() {
                                                                                areaModel = value;
                                                                                area = value.id.toString();
                                                                              });
                                                                            },
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    const Divider(),
                                                                    Visibility(
                                                                      visible:
                                                                          isAdminUser,
                                                                      child: DropdownSearch<
                                                                          dynamic>(
                                                                        maxHeight:
                                                                            300,
                                                                        onFind: (String filter) => api.getSalesListData(
                                                                            filter,
                                                                            'sales_list/salesMan'),
                                                                        dropdownSearchDecoration: const InputDecoration(
                                                                            border:
                                                                                OutlineInputBorder(),
                                                                            label:
                                                                                Text('Select Salesman')),
                                                                        onChanged:
                                                                            (dynamic
                                                                                data) {
                                                                          salesMan = data
                                                                              .id
                                                                              .toString();
                                                                        },
                                                                        showSearchBox:
                                                                            true,
                                                                      ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.push(
                                                                            context,
                                                                            MaterialPageRoute(builder: (BuildContext context) => ReportView('0', (_ob ? '1' : '0'), DateUtil.dateDMY2YMD(fromDate), DateUtil.dateDMY2YMD(toDate), statement, '', statement, salesMan, locationId != null ? [locationId.id] : [_dropDownBranchId], area, route, '0')));
                                                                      },
                                                                      child: const Text(
                                                                          'Show'),
                                                                      style:
                                                                          ButtonStyle(
                                                                        backgroundColor:
                                                                            MaterialStateProperty.all<Color>(kPrimaryColor),
                                                                        foregroundColor:
                                                                            MaterialStateProperty.all<Color>(Colors.white),
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                              )
                                                            : Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        8.0),
                                                                child: Column(
                                                                  children: [
                                                                    Card(
                                                                      elevation:
                                                                          0.5,
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceAround,
                                                                        children: [
                                                                          const Text(
                                                                            'From : ',
                                                                            style:
                                                                                TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                                          ),
                                                                          InkWell(
                                                                            child:
                                                                                Text(
                                                                              fromDate,
                                                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                                                                            ),
                                                                            onTap: () =>
                                                                                _selectDate('f'),
                                                                          ),
                                                                          const Text(
                                                                            'To : ',
                                                                            style:
                                                                                TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                                          ),
                                                                          InkWell(
                                                                            child:
                                                                                Text(
                                                                              toDate,
                                                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                                                                            ),
                                                                            onTap: () =>
                                                                                _selectDate('t'),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    // Card(
                                                                    //   elevation: 2,
                                                                    //   child:
                                                                    //       DropDownSettingsTile<int>(
                                                                    //     title: 'Branch',
                                                                    //     settingKey:
                                                                    //         'key-dropdown-default-location-view',
                                                                    //     values: locationList
                                                                    //             .isNotEmpty
                                                                    //         ? {
                                                                    //             for (var e
                                                                    //                 in locationList)
                                                                    //               e.key + 1: e.value
                                                                    //           }
                                                                    //         : {
                                                                    //             2: '',
                                                                    //           },
                                                                    //     selected: 2,
                                                                    //     onChange: (value) {
                                                                    //       dropDownBranchId =
                                                                    //           value - 1;
                                                                    //     },
                                                                    //   ),
                                                                    // ),
                                                                    Visibility(
                                                                      visible:
                                                                          isAdminUser,
                                                                      child: DropdownSearch<
                                                                          dynamic>(
                                                                        maxHeight:
                                                                            300,
                                                                        onFind: (String filter) => api.getSalesListData(
                                                                            filter,
                                                                            'sales_list/location'),
                                                                        dropdownSearchDecoration: const InputDecoration(
                                                                            border:
                                                                                OutlineInputBorder(),
                                                                            label:
                                                                                Text('Select Branch')),
                                                                        onChanged:
                                                                            (dynamic
                                                                                data) {
                                                                          locationId =
                                                                              data;
                                                                        },
                                                                        showSearchBox:
                                                                            true,
                                                                      ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.push(
                                                                            context,
                                                                            MaterialPageRoute(builder: (BuildContext context) => ReportView('0', (_ob ? '1' : '0'), DateUtil.dateDMY2YMD(fromDate), DateUtil.dateDMY2YMD(toDate), statement, '', statement, salesMan, locationId != null ? [locationId.id] : [_dropDownBranchId], area, route, '0')));
                                                                      },
                                                                      child: const Text(
                                                                          'Show'),
                                                                      style:
                                                                          ButtonStyle(
                                                                        backgroundColor:
                                                                            MaterialStateProperty.all<Color>(kPrimaryColor),
                                                                        foregroundColor:
                                                                            MaterialStateProperty.all<Color>(Colors.white),
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                              );
  }

  _listItem(index) {
    return InkWell(
      child: Card(
        child: ListTile(
          title: Text(itemDisplay[index].name),
        ),
      ),
      onTap: () {
        setState(() {
          _loading = false;
          _ledger = itemDisplay[index].name;
          _id = itemDisplay[index].id;

          api.getCustomerDetail(_id).then((_data) => tempLedgerData =
              CustomerModel(
                  id: _data.id,
                  name: _ledger,
                  address1: _data.address1,
                  address2: _data.address2,
                  address3: _data.address3,
                  address4: _data.address4,
                  balance: _data.balance,
                  city: _data.city,
                  email: _data.email,
                  phone: _data.phone,
                  route: _data.route,
                  state: _data.state,
                  stateCode: _data.stateCode,
                  taxNumber: _data.taxNumber));
        });
      },
    );
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
            itemDisplay = items.where((item) {
              var itemName = item.name.toString().toLowerCase();
              return itemName.contains(text);
            }).toList();
          });
        },
      ),
    );
  }

  projectWidget() {
    return isProjectSoftware
        ? SizedBox(
            child: DropdownSearch<dynamic>(
              maxHeight: 300,
              onFind: (String filter) => getProjectListData(filter),
              dropdownSearchDecoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Select Project'),
              onChanged: (dynamic data) {
                projectId = data.id.toString();
              },
              showSearchBox: true,
            ),
          )
        : Container();
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
              {fromDate = DateUtil.datePickerDMY(picked)}
            else
              {toDate = DateUtil.datePickerDMY(picked)}
          });
    }
  }

  Future<List<dynamic>> getProjectListData(String filter) async {
    var dd = filter.isEmpty
        ? projectList
        : projectList
            .where((element) => element.name
                .toString()
                .toLowerCase()
                .contains(filter.toLowerCase()))
            .toList();
    List<DataJson> dataResult = [];
    for (var data in dd) {
      dataResult.add(DataJson(id: data.id, name: data.name.trim().toString()));
    }
    return dataResult;
  }
}
