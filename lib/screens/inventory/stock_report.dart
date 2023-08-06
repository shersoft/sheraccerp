// @dart = 2.11
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';

class StockReport extends StatefulWidget {
  const StockReport({Key key}) : super(key: key);

  @override
  _StockReportState createState() => _StockReportState();
}

class _StockReportState extends State<StockReport> {
  bool isPageMode = true;
  String fromDate;
  String toDate;
  var _data;
  int menuId = 0;
  bool loadReport = false;
  bool stockValuation = false;
  DateTime now = DateTime.now();
  DioService api = DioService();
  DataJson itemId,
      itemName,
      supplier,
      mfr,
      category,
      subCategory,
      location,
      rack,
      unit,
      taxGroup;
  final controller = ScrollController();
  double offset = 0;
  List<dynamic> resultData = [];
  DataJson dropdownValueStockMinus;
  DataJson dropdownValueReportType;
  DataJson dropdownValueLedgerReportType;
  String title = '';
  List<String> tableColumn = [];

  @override
  void initState() {
    super.initState();
    fromDate = DateFormat('dd-MM-yyyy').format(now);
    toDate = DateFormat('dd-MM-yyyy').format(now);
    dropdownValueStockMinus = minusStockList.first;
    dropdownValueReportType = reportTypeList.first;
    dropdownValueLedgerReportType = reportTypeLedgerList.first;
    location = DataJson(id: 1, name: defaultLocation);
  }

  @override
  Widget build(BuildContext context) {
    return loadReport
        ? Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        loadReport = false;
                        location = DataJson(id: 1, name: defaultLocation);
                        itemId = null;
                        itemName = null;
                        supplier = null;
                        mfr = null;
                        category = null;
                        subCategory = null;
                        rack = null;
                        taxGroup = null;
                      });
                    }),
                PopupMenuButton(
                  icon: const Icon(Icons.share_rounded),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      child: Text('PDF'),
                      value: 1,
                    ),
                    const PopupMenuItem(
                      child: Text('CSV'),
                      value: 2,
                    ),
                  ],
                  onSelected: (menuId) {
                    setState(() {
                      // debugPrint(menuId.toString());
                      if (menuId == 1) {
                        Future.delayed(const Duration(milliseconds: 1000), () {
                          _createPDF(
                                  title + ' Date :' + fromDate + ' - ' + toDate)
                              .then((value) =>
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => PDFScreen(
                                            pathPDF: value,
                                            subject: title +
                                                ' Date :' +
                                                fromDate +
                                                ' - ' +
                                                toDate,
                                            text: 'this is ' +
                                                title +
                                                ' Date :' +
                                                fromDate +
                                                ' - ' +
                                                toDate,
                                          ))));
                        });
                      } else if (menuId == 2) {
                        Future.delayed(const Duration(milliseconds: 1000), () {
                          _createCSV(
                                  title + ' Date :' + fromDate + ' - ' + toDate)
                              .then((value) {
                            var text = 'this is ' +
                                title +
                                ' Date :' +
                                fromDate +
                                ' - ' +
                                toDate;
                            var subject =
                                title + ' Date :' + fromDate + ' - ' + toDate;
                            List<String> paths = [];
                            paths.add(value);
                            urlFileShare(context, text, subject, paths);
                          });
                        });
                      }
                    });
                  },
                )
              ],
              title: Text(title + ' Report'),
            ),
            body: reportView(title))
        : SafeArea(
            child: DefaultTabController(
                length: 2,
                initialIndex: 0,
                child: Scaffold(
                  backgroundColor: white,
                  body: Column(
                    children: [
                      const TabBar(
                        labelColor: black,
                        indicatorColor: blue,
                        labelPadding: EdgeInsets.all(0),
                        labelStyle:
                            TextStyle(fontSize: 19, fontFamily: 'Poppins'),
                        tabs: [
                          Tab(
                            // icon: Icon(Icons.camera),
                            text: "Stock",
                          ),
                          Tab(text: "Stock Ledger"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            selectStock(),
                            selectStockLedger(),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          );
  }

  reportView(title) {
    var statementType = title == 'Stock'
        ? stockValuation
            ? 'LastRate_StockValuation'
            : dropdownValueReportType.id == reportTypeList[0].id
                ? 'SimpleSummery'
                : dropdownValueReportType.id == reportTypeList[1].id
                    ? 'Stock Profit'
                    : dropdownValueReportType.id == reportTypeList[2].id
                        ? 'Category_Wise'
                        : dropdownValueReportType.id == reportTypeList[3].id
                            ? 'ZeroStockItems'
                            : dropdownValueReportType.id == reportTypeList[4].id
                                ? 'Stock_Ageing'
                                : dropdownValueReportType.id ==
                                        reportTypeList[5].id
                                    ? 'LocationComparison'
                                    : dropdownValueReportType.id ==
                                            reportTypeList[6].id
                                        ? 'SerialNo Report'
                                        : dropdownValueReportType.id ==
                                                reportTypeList[7].id
                                            ? 'ReOrderLevelList'
                                            : 'SimpleSummery'
        : dropdownValueLedgerReportType.id == reportTypeLedgerList[0].id
            ? 'StockLedger_Summery'
            : dropdownValueLedgerReportType.id == reportTypeLedgerList[1].id
                ? 'StockLedger_BatchWise'
                : dropdownValueLedgerReportType.id == reportTypeLedgerList[2].id
                    ? 'StockLedger_Summery_Daily'
                    : dropdownValueLedgerReportType.id ==
                            reportTypeLedgerList[6].id
                        ? 'StockLedger_Wop'
                        : 'StockLedger_Summery';
    var _location = '',
        _itemCode = '',
        _itemName = '',
        _supplier = '',
        _mfr = '',
        _category = '',
        _subCategory = '',
        _rack = '',
        _taxGroup = '';
    if (location != null) {
      _location = location.id.toString() ?? '0';
    }
    if (itemId != null) {
      _itemCode = itemId.id.toString() ?? '';
    }
    if (itemName != null) {
      _itemName = itemName.name.toString() ?? '';
    }
    if (supplier != null) {
      _supplier = supplier.id.toString() ?? '';
    }
    if (mfr != null) {
      _mfr = mfr.id.toString() ?? '';
    }
    if (category != null) {
      _category = category.id.toString() ?? '';
    }
    if (subCategory != null) {
      _subCategory = subCategory.id.toString() ?? '';
    }
    if (rack != null) {
      _rack = rack.id.toString() ?? '';
    }
    if (taxGroup != null) {
      _taxGroup = taxGroup.id.toString() ?? '';
    }
    var stockMovingType = '';
    if (title == 'Stock') {
      stockMovingType = '';
    } else {
      stockMovingType = dropdownValueLedgerReportType.id ==
              reportTypeLedgerList[3].id
          ? 'FAST MOVING ITEMS'
          : dropdownValueLedgerReportType.id == reportTypeLedgerList[4].id
              ? 'SLOW MOVING ITEMS'
              : dropdownValueLedgerReportType.id == reportTypeLedgerList[5].id
                  ? 'NON MOVING ITEMS'
                  : '';
    }
    var dataJson = title == 'Stock'
        ? {
            'statementType': statementType.isEmpty ? '' : statementType,
            'date': fromDate.isEmpty ? '' : formatYMD(fromDate),
            'minus': dropdownValueStockMinus != null
                ? dropdownValueStockMinus.id.toString()
                : '',
            "sDate": fromDate.isEmpty ? '' : formatYMD(fromDate),
            "eDate": toDate.isEmpty ? '' : formatYMD(toDate),
            "location": _location,
            "uniqueCode": 0,
            "itemId": 0,
            "itemCode": _itemCode,
            "itemName": _itemName,
            "mfr": _mfr,
            "category": _category,
            "subCategory": _subCategory,
            "rack": _rack,
            "taxGroup": _taxGroup,
            "supplier": _supplier,
            'unitId': unit != null ? unit.id.toString() : '0',
            "itemMovingType": stockMovingType
          }
        : {
            'statementType': statementType.isEmpty ? '' : statementType,
            'date': fromDate.isEmpty ? '' : formatYMD(fromDate),
            'minus': dropdownValueStockMinus != null
                ? dropdownValueStockMinus.id.toString()
                : '',
            "sDate": fromDate.isEmpty ? '' : formatYMD(fromDate),
            "eDate": toDate.isEmpty ? '' : formatYMD(toDate),
            "location": _location,
            "uniqueCode": 0,
            "itemId": 0,
            "itemCode": _itemCode,
            "itemName": _itemName,
            "mfr": _mfr,
            "category": _category,
            "subCategory": _subCategory,
            "rack": _rack,
            "taxGroup": _taxGroup,
            "supplier": _supplier,
            'unitId': unit != null ? unit.id.toString() : 0,
            "itemMovingType": stockMovingType
          };

    return FutureBuilder<List<dynamic>>(
      future: title == 'Stock'
          ? api.getStockReport(dataJson)
          : api.getStockLedgerReport(dataJson),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            tableColumn = data[0].keys.toList();
            var col = tableColumn;
            Map<String, dynamic> totalData = {};
            for (int i = 0; i < col.length; i++) {
              var cell = '';
              if (col[i].toLowerCase() == ('realprate') ||
                  col[i].toLowerCase() == ('mrp') ||
                  col[i].toLowerCase() == ('retail') ||
                  col[i].toLowerCase() == ('wsrate') ||
                  col[i].toLowerCase() == ('wholsale') ||
                  col[i].toLowerCase() == ('spretail') ||
                  col[i].toLowerCase() == ('branch') ||
                  col[i].toLowerCase() == ('qty') ||
                  col[i].toLowerCase() == ('free') ||
                  col[i].toLowerCase() == ('freeqty') ||
                  col[i].toLowerCase() == ('rate') ||
                  col[i].toLowerCase() == ('prate') ||
                  col[i].toLowerCase() == ('srate') ||
                  col[i].toLowerCase() == ('profit') ||
                  col[i].toLowerCase() == ('total') ||
                  col[i].toLowerCase() == ('amount') ||
                  col[i].toLowerCase() == ('mrpamount') ||
                  col[i].toLowerCase() == ('openingstock') ||
                  col[i].toLowerCase() == ('openingstockentry') ||
                  col[i].toLowerCase() == ('purchase') ||
                  col[i].toLowerCase() == ('unrpurchase') ||
                  col[i].toLowerCase() == ('sales') ||
                  col[i].toLowerCase() == ('sreturn') ||
                  col[i].toLowerCase() == ('preturn') ||
                  col[i].toLowerCase() == ('damage') ||
                  col[i].toLowerCase() == ('btr') ||
                  col[i].toLowerCase() == ('replacement') ||
                  col[i].toLowerCase() == ('rawmaterial') ||
                  col[i].toLowerCase() == ('stocktransfer-') ||
                  col[i].toLowerCase() == ('stocktransfer+') ||
                  col[i].toLowerCase() == ('stockadj+') ||
                  col[i].toLowerCase() == ('stockadj-') ||
                  col[i].toLowerCase() == ('netqty') ||
                  col[i].toLowerCase() == ('btr') ||
                  col[i].toLowerCase() == ('rpamount')) {
                cell = data
                    .fold(
                        0.0,
                        (a, b) =>
                            a +
                            (b[col[i]] != null
                                ? b[col[i]] == ''
                                    ? 0
                                    : double.parse(b[col[i]].toString())
                                : 0))
                    .toStringAsFixed(2);
              }
              if (i == 0) {
                cell = 'Total';
              }
              totalData[col[i]] = cell;
            }
            if (totalData.isNotEmpty) {
              data.add(totalData);
            }
            _data = data;

            return isPageMode
                ? SingleChildScrollView(
                    child: PaginatedDataTable(
                    header: Text(
                      'Date: From ' + fromDate + ' To ' + toDate,
                      style: const TextStyle(fontSize: 18),
                    ),
                    rowsPerPage: 100,
                    horizontalMargin: 10,
                    columnSpacing: 10,
                    showFirstLastButtons: true,
                    arrowHeadColor: black,
                    // columnSpacing: 100,
                    // horizontalMargin: 10,
                    dataRowHeight: 20,
                    headingRowHeight: 30,
                    showCheckboxColumn: true,
                    columns: [
                      for (int i = 0; i < col.length; i++)
                        DataColumn(
                          label: Align(
                            alignment: Alignment.center,
                            child: Text(
                              col[i],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                    source: DTS(context, _data),
                  ))
                : Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                              child: Text(
                                  'Date: From ' + fromDate + ' To ' + toDate)),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.grey.shade200),
                              border: TableBorder.all(
                                  width: 1.0, color: Colors.black),
                              columnSpacing: 12,
                              dataRowHeight: 20,
                              headingRowHeight: 30,
                              columns: [
                                for (int i = 0; i < tableColumn.length; i++)
                                  DataColumn(
                                    label: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        tableColumn[i],
                                        style: const TextStyle(
                                            // fontSize: 10.0,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                              rows: data
                                  .map(
                                    (values) => DataRow(
                                      cells: [
                                        for (int i = 0; i < values.length; i++)
                                          DataCell(
                                            Align(
                                              alignment: ComSettings.oKNumeric(
                                                values[tableColumn[i]] != null
                                                    ? values[tableColumn[i]]
                                                        .toString()
                                                    : '',
                                              )
                                                  ? Alignment.centerRight
                                                  : Alignment.centerLeft,
                                              child: Text(
                                                values[tableColumn[i]] != null
                                                    ? values[tableColumn[i]]
                                                        .toString()
                                                    : '',
                                                softWrap: true,
                                                overflow: TextOverflow.ellipsis,
                                                // style: TextStyle(fontSize: 6),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          // SizedBox(height: 500),
                        ],
                      ),
                    ),
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
        // By default, show a loading spinner.
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

  selectStock() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                elevation: 0.5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text(
                      'Date : ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    InkWell(
                      child: Text(
                        fromDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      onTap: () => _selectDate('f'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              dropDownReportType(),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/location'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text('Select Branch')),
                onChanged: (dynamic data) {
                  location = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        title = 'Stock';
                        loadReport = true;
                      });
                    },
                    child: const Text('Show'),
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(kPrimaryColor),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                  ),
                  const Text('Page'),
                  Checkbox(
                    value: isPageMode,
                    onChanged: (value) {
                      setState(() {
                        isPageMode = value;
                      });
                    },
                  )
                ],
              ),
              const Divider(),
              stockMethod(),
              const Divider(),
              dropDownStockMinus(),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/ItemCode'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Select Item Code')),
                onChanged: (dynamic data) {
                  itemId = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/itemName'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Select Item Name')),
                onChanged: (dynamic data) {
                  itemName = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/manufacture'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Select Item MFR')),
                onChanged: (dynamic data) {
                  mfr = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/category'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Select Category')),
                onChanged: (dynamic data) {
                  category = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/subCategory'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Select SubCategory')),
                onChanged: (dynamic data) {
                  subCategory = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/rack'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text("Select Rack")),
                onChanged: (dynamic data) {
                  rack = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/taxGroup'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Select TaxGroup")),
                onChanged: (dynamic data) {
                  taxGroup = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/supplier'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Select Supplier")),
                onChanged: (dynamic data) {
                  supplier = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/unit'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text("Select Unit")),
                onChanged: (dynamic data) {
                  unit = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
            ],
          ),
        ),
      ],
    );
  }

  selectStockLedger() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                elevation: 0.5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text(
                      'From : ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    InkWell(
                      child: Text(
                        fromDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      onTap: () => _selectDate('f'),
                    ),
                    const Text(
                      'To : ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    InkWell(
                      child: Text(
                        toDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      onTap: () => _selectDate('t'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              dropDownLedgerReportType(),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/location'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text("Select Branch")),
                onChanged: (dynamic data) {
                  location = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        title = 'Stock Ledger';
                        loadReport = true;
                      });
                    },
                    child: const Text('Show'),
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(kPrimaryColor),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                  ),
                  const Text('Page'),
                  Checkbox(
                    value: isPageMode,
                    onChanged: (value) {
                      setState(() {
                        isPageMode = value;
                      });
                    },
                  )
                ],
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/ItemCode'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Select Item Code")),
                onChanged: (dynamic data) {
                  itemId = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/itemName'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Select Item Name")),
                onChanged: (dynamic data) {
                  itemName = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/manufacture'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Select Item MFR")),
                onChanged: (dynamic data) {
                  mfr = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/category'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Select Category")),
                onChanged: (dynamic data) {
                  category = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/subCategory'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Select SubCategory")),
                onChanged: (dynamic data) {
                  subCategory = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/rack'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text("Select Rack")),
                onChanged: (dynamic data) {
                  rack = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/taxGroup'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Select TaxGroup")),
                onChanged: (dynamic data) {
                  taxGroup = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/supplier'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Select Supplier")),
                onChanged: (dynamic data) {
                  supplier = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
            ],
          ),
        ),
      ],
    );
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
              {fromDate = DateFormat('dd-MM-yyyy').format(picked)}
            else
              {toDate = DateFormat('dd-MM-yyyy').format(picked)}
          });
    }
  }

  List<DataJson> minusStockList = [
    DataJson(id: 2, name: 'AVOID MINUS STOCK'),
    DataJson(id: 0, name: 'ONLY MINUS STOCK'),
    DataJson(id: 1, name: 'INCLUDE MINUS STOCK'),
    DataJson(id: 3, name: 'ONLY ZERO STOCK'),
    DataJson(id: 4, name: 'PLUS & MINUS STOCK'),
  ];

  List<DataJson> reportTypeList = [
    DataJson(id: 0, name: 'Simple'),
    DataJson(id: 1, name: 'Stock Profit'),
    DataJson(id: 2, name: 'Category Wise'),
    DataJson(id: 3, name: 'Zero Stock Items'),
    DataJson(id: 4, name: 'Stock Ageing'),
    DataJson(id: 5, name: 'Location Comparison'),
    DataJson(id: 6, name: 'SerialNo Report'),
    DataJson(id: 7, name: 'Below Reorder'),
  ];

  List<DataJson> reportTypeLedgerList = [
    DataJson(id: 0, name: 'Detailed'),
    DataJson(id: 1, name: 'Batch Wise'),
    DataJson(id: 2, name: 'Daily'),
    DataJson(id: 3, name: 'Fast Moving Items'),
    DataJson(id: 4, name: 'Slow Moving Items'),
    DataJson(id: 5, name: 'Non Moving Items'),
    DataJson(id: 6, name: 'Summary w/o UNP'),
  ];

  dropDownLedgerReportType() {
    return Card(
      elevation: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text('Report Type'),
          DropdownButton<DataJson>(
            value: dropdownValueLedgerReportType,
            icon: const Icon(Icons.arrow_drop_down),
            onChanged: (DataJson data) {
              setState(() {
                dropdownValueLedgerReportType = data;
              });
            },
            items: reportTypeLedgerList
                .map<DropdownMenuItem<DataJson>>((DataJson value) {
              return DropdownMenuItem<DataJson>(
                value: value,
                child: Text(value.name),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  dropDownReportType() {
    return Card(
      elevation: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text('Report Type'),
          DropdownButton<DataJson>(
            value: dropdownValueReportType,
            icon: const Icon(Icons.arrow_drop_down),
            onChanged: (DataJson data) {
              setState(() {
                dropdownValueReportType = data;
              });
            },
            items: reportTypeList
                .map<DropdownMenuItem<DataJson>>((DataJson value) {
              return DropdownMenuItem<DataJson>(
                value: value,
                child: Text(value.name),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  dropDownStockMinus() {
    return Card(
      elevation: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text('Minus Stock'),
          DropdownButton<DataJson>(
            value: dropdownValueStockMinus,
            icon: const Icon(Icons.arrow_drop_down),
            onChanged: (DataJson data) {
              setState(() {
                dropdownValueStockMinus = data;
              });
            },
            items: minusStockList
                .map<DropdownMenuItem<DataJson>>((DataJson value) {
              return DropdownMenuItem<DataJson>(
                value: value,
                child: Text(value.name),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  stockMethod() {
    return Card(
      elevation: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text('Stock Valuation Last P-Rate'),
          Checkbox(
            value: stockValuation,
            onChanged: (value) {
              setState(() {
                stockValuation = value;
              });
            },
          )
        ],
      ),
    );
  }

  String formatYMD(value) {
    var dateTime = DateFormat("dd-MM-yyyy").parse(value.toString());
    return DateFormat("yyyy-MM-dd").format(dateTime);
  }

  Future<String> _createPDF(String title) async {
    return makePDF(title).then((value) => savePreviewPDF(value, title));
  }

  Future<pw.Document> makePDF(String title) async {
    var tableHeaders = [
      "Date",
      "Particulars",
      "Voucher",
      "EntryNo",
      "Debit",
      "Credit",
      "Balance",
      "Narration"
    ];

    var data = _data;
    final pw.Document pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
        // pageFormat: PdfPageFormat.a4,
        maxPages: 100,
        header: (context) => pw.Column(children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      color: const PdfColor.fromInt(0),
                      fontSize: 25,
                      fontWeight: pw.FontWeight.bold)),
            ]),
        build: (context) => [
              pw.Table(
                border: pw.TableBorder.all(width: 0.2),
                children: [
                  pw.TableRow(children: [
                    for (int k = 0; k < tableColumn.length; k++)
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(tableColumn[k],
                                style: const pw.TextStyle(fontSize: 6)),
                            // pw.Divider(thickness: 1)
                          ]),
                    // pw.Column(
                    //     crossAxisAlignment: pw.CrossAxisAlignment.center,
                    //     mainAxisAlignment: pw.MainAxisAlignment.center,
                    //     children: [
                    //       pw.Text(tableHeaders[0],
                    //           style: const pw.TextStyle(fontSize: 6)),
                    //       // pw.Divider(thickness: 1)
                    //     ]),
                    // pw.Column(
                    //     crossAxisAlignment: pw.CrossAxisAlignment.center,
                    //     mainAxisAlignment: pw.MainAxisAlignment.center,
                    //     children: [
                    //       pw.Text(tableHeaders[1],
                    //           style: const pw.TextStyle(fontSize: 6)),
                    //       // pw.Divider(thickness: 1)
                    //     ]),
                    // pw.Column(
                    //     crossAxisAlignment: pw.CrossAxisAlignment.center,
                    //     mainAxisAlignment: pw.MainAxisAlignment.center,
                    //     children: [
                    //       pw.Text(tableHeaders[2],
                    //           style: const pw.TextStyle(fontSize: 6)),
                    //       // pw.Divider(thickness: 1)
                    //     ]),
                    // pw.Column(
                    //     crossAxisAlignment: pw.CrossAxisAlignment.center,
                    //     mainAxisAlignment: pw.MainAxisAlignment.center,
                    //     children: [
                    //       pw.Text(tableHeaders[3],
                    //           style: const pw.TextStyle(fontSize: 6)),
                    //       // pw.Divider(thickness: 1)
                    //     ]),
                    // pw.Column(
                    //     crossAxisAlignment: pw.CrossAxisAlignment.center,
                    //     mainAxisAlignment: pw.MainAxisAlignment.center,
                    //     children: [
                    //       pw.Text(tableHeaders[4],
                    //           style: const pw.TextStyle(fontSize: 6)),
                    //       // pw.Divider(thickness: 1)
                    //     ]),
                    // pw.Column(
                    //     crossAxisAlignment: pw.CrossAxisAlignment.center,
                    //     mainAxisAlignment: pw.MainAxisAlignment.center,
                    //     children: [
                    //       pw.Text(tableHeaders[5],
                    //           style: const pw.TextStyle(fontSize: 6)),
                    //       // pw.Divider(thickness: 1)
                    //     ]),
                    // pw.Column(
                    //     crossAxisAlignment: pw.CrossAxisAlignment.center,
                    //     mainAxisAlignment: pw.MainAxisAlignment.center,
                    //     children: [
                    //       pw.Text(tableHeaders[6],
                    //           style: const pw.TextStyle(fontSize: 6)),
                    //       // pw.Divider(thickness: 1)
                    //     ]),
                    // pw.Column(
                    //     crossAxisAlignment: pw.CrossAxisAlignment.center,
                    //     mainAxisAlignment: pw.MainAxisAlignment.center,
                    //     children: [
                    //       pw.Text(tableHeaders[7],
                    //           style: const pw.TextStyle(fontSize: 6)),
                    //       // pw.Divider(thickness: 1)
                    //     ]),
                  ]),
                  //   for (var i = 0; i < data.length; i++)
                  //     pw.TableRow(children: [
                  //       pw.Column(
                  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
                  //           mainAxisAlignment: pw.MainAxisAlignment.center,
                  //           children: [
                  //             pw.Padding(
                  //               padding: const pw.EdgeInsets.all(2.0),
                  //               child: pw.Text(data[i]['Date'],
                  //                   style: const pw.TextStyle(fontSize: 6)),
                  //               // pw.Divider(thickness: 1)
                  //             ),
                  //           ]),
                  //       pw.Column(
                  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
                  //           mainAxisAlignment: pw.MainAxisAlignment.center,
                  //           children: [
                  //             pw.Padding(
                  //               padding: const pw.EdgeInsets.all(2.0),
                  //               child: pw.Text(data[i]['Particulars'],
                  //                   style: const pw.TextStyle(fontSize: 6)),
                  //               // pw.Divider(thickness: 1)
                  //             ),
                  //           ]),
                  //       pw.Column(
                  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
                  //           mainAxisAlignment: pw.MainAxisAlignment.center,
                  //           children: [
                  //             pw.Padding(
                  //               padding: const pw.EdgeInsets.all(2.0),
                  //               child: pw.Text('${data[i]['Voucher']}',
                  //                   style: const pw.TextStyle(fontSize: 6)),
                  //               // pw.Divider(thickness: 1)
                  //             )
                  //           ]),
                  //       pw.Column(
                  //           crossAxisAlignment: pw.CrossAxisAlignment.end,
                  //           mainAxisAlignment: pw.MainAxisAlignment.center,
                  //           children: [
                  //             pw.Padding(
                  //               padding: const pw.EdgeInsets.all(2.0),
                  //               child: pw.Text('${data[i]['EntryNo']}',
                  //                   style: const pw.TextStyle(fontSize: 6)),
                  //               // pw.Divider(thickness: 1)
                  //             )
                  //           ]),
                  //       pw.Column(
                  //           crossAxisAlignment: pw.CrossAxisAlignment.end,
                  //           mainAxisAlignment: pw.MainAxisAlignment.center,
                  //           children: [
                  //             pw.Padding(
                  //               padding: const pw.EdgeInsets.all(2.0),
                  //               child: pw.Text('${data[i]['Debit']}',
                  //                   style: const pw.TextStyle(fontSize: 6)),
                  //               // pw.Divider(thickness: 1)
                  //             )
                  //           ]),
                  //       pw.Column(
                  //           crossAxisAlignment: pw.CrossAxisAlignment.end,
                  //           mainAxisAlignment: pw.MainAxisAlignment.center,
                  //           children: [
                  //             pw.Padding(
                  //               padding: const pw.EdgeInsets.all(2.0),
                  //               child: pw.Text('${data[i]['Credit']}',
                  //                   style: const pw.TextStyle(fontSize: 6)),
                  //               // pw.Divider(thickness: 1)
                  //             )
                  //           ]),
                  //       pw.Column(
                  //           crossAxisAlignment: pw.CrossAxisAlignment.end,
                  //           mainAxisAlignment: pw.MainAxisAlignment.center,
                  //           children: [
                  //             pw.Padding(
                  //               padding: const pw.EdgeInsets.all(2.0),
                  //               child: pw.Text('${data[i]['Balance']}',
                  //                   style: const pw.TextStyle(fontSize: 6)),
                  //               // pw.Divider(thickness: 1)
                  //             )
                  //           ]),
                  //       pw.Column(
                  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
                  //           mainAxisAlignment: pw.MainAxisAlignment.center,
                  //           children: [
                  //             pw.Padding(
                  //               padding: const pw.EdgeInsets.all(2.0),
                  //               child: pw.Text('${data[i]['Narration']}',
                  //                   style: const pw.TextStyle(fontSize: 6)),
                  //               // pw.Divider(thickness: 1)
                  //             )
                  //           ]),
                  //     ])
                  for (var i = 0; i < data.length; i++)
                    pw.TableRow(children: [
                      for (int l = 0; l < tableColumn.length; l++)
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                    data[i][tableColumn[l]].toString() ?? '',
                                    style: const pw.TextStyle(fontSize: 6)),
                                // pw.Divider(thickness: 1)
                              ),
                            ]),
                    ])
                ],
              ),
            ],
        footer: _buildFooter));

    return pdf;
  }

  pw.Widget _buildFooter(pw.Context context) {
    debugPrint('Page ${context.pageNumber}/${context.pagesCount}');
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(),
        pw.Text(
          'Page ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.red,
          ),
        ),
      ],
    );
  }

  Future<String> savePreviewPDF(pw.Document pdf, var title) async {
    var output = await getTemporaryDirectory();
    title = title.replaceAll(new RegExp(r'[^\w\s]+'), '');
    final file = File('${output.path}/' + title + '.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path.toString();
  }

  Future<String> _createCSV(String title) async {
    return _generateCsvFile(title)
        .then((value) => savePreviewCSV(value, title));
  }

  Future<String> _generateCsvFile(String title) async {
    var dataList = _data;
    List<List<dynamic>> rows = [];
    var col = dataList[0].keys.toList();
    List<dynamic> row = [];
    for (var columnName in col) {
      row.add(columnName.toString());
    }
    rows.add(row);

    for (var i = 0; i < dataList.length; i++) {
      List<dynamic> row1 = [];
      for (var columnName in col) {
        row1.add(dataList[i][columnName].toString());
      }
      rows.add(row1);
    }
    return const ListToCsvConverter().convert(rows);
  }

  Future<String> savePreviewCSV(var csv, var title) async {
    var output = await getTemporaryDirectory();
    title = title.replaceAll(new RegExp(r'[^\w\s]+'), '');
    final file = File('${output.path}/' + title + '.csv');
    await file.writeAsString(csv);
    return file.path.toString();
  }

  Future<void> urlFileShare(
      BuildContext context, String text, String subject, var paths) async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    if (paths.isNotEmpty) {
      await Share.shareFiles(paths,
          text: text,
          subject: subject,
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
    }
  }
}

class DTS extends DataTableSource {
  final List<dynamic> data;
  final BuildContext context;

  DTS(this.context, this.data);
  @override
  DataRow getRow(int index) {
    final tableColumn = data[0].keys.toList();
    final values = data[index];
    return DataRow.byIndex(index: index, cells: [
      for (int i = 0; i < values.length; i++)
        DataCell(
          Align(
            alignment: ComSettings.oKNumeric(
              values[tableColumn[i]] != null
                  ? values[tableColumn[i]].toString()
                  : '',
            )
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(
              values[tableColumn[i]] != null
                  ? values[tableColumn[i]].toString()
                  : '',
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              // style: TextStyle(fontSize: 6),
            ),
          ),
        ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
