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
import 'package:share/share.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';

class StockReport extends StatefulWidget {
  const StockReport({Key key}) : super(key: key);

  @override
  _StockReportState createState() => _StockReportState();
}

class _StockReportState extends State<StockReport> {
  String fromDate;
  String toDate;
  var _data;
  int menuId = 0;
  bool loadReport = false;
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
  String title = '';
  List<String> tableColumn = [];

  @override
  void initState() {
    super.initState();
    fromDate = DateFormat('dd-MM-yyyy').format(now);
    toDate = DateFormat('dd-MM-yyyy').format(now);
    dropdownValueStockMinus = minusStockList.first;
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
    var statementType =
        title == 'Stock' ? 'SimpleSummery' : 'StockLedger_Summery';
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
    var dataJson = title == 'Stock'
        ? '[' +
            json.encode({
              'statementType': statementType.isEmpty ? '' : statementType,
              'date': fromDate.isEmpty ? '' : formatYMD(fromDate),
              'minus': dropdownValueStockMinus != null
                  ? dropdownValueStockMinus.id.toString()
                  : '',
              "sDate": fromDate,
              "eDate": toDate,
              "location": _location,
              "itemCode": _itemCode,
              "itemName": _itemName,
              "mfr": _mfr,
              "category": _category,
              "subCategory": _subCategory,
              "rack": _rack,
              "taxGroup": _taxGroup,
              "supplier": _supplier,
              'unitId': unit != null ? unit.id.toString() : '0',
            }) +
            ']'
        : '[' +
            json.encode({
              'statementType': statementType.isEmpty ? '' : statementType,
              'date': fromDate.isEmpty ? '' : formatYMD(fromDate),
              'minus': dropdownValueStockMinus != null
                  ? dropdownValueStockMinus.id.toString()
                  : '',
              "sDate": fromDate,
              "eDate": toDate,
              "location": _location,
              "itemCode": _itemCode,
              "itemName": _itemName,
              "mfr": _mfr,
              "category": _category,
              "subCategory": _subCategory,
              "rack": _rack,
              "taxGroup": _taxGroup,
              "supplier": _supplier,
              'unitId': unit != null ? unit.id.toString() : 0,
            }) +
            ']';

    return FutureBuilder<List<dynamic>>(
      future: api.getStockReport(dataJson),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            _data = data;
            tableColumn = data[0].keys.toList();
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                        child:
                            Text('Date: From ' + fromDate + ' To ' + toDate)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 12,
                        dataRowHeight: 20,
                        dividerThickness: 1,
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
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/location'),
                dropdownSearchDecoration: InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Select Branch'),
                onChanged: (dynamic data) {
                  location = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
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
              const Divider(),
              dropDownStockMinus(),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/ItemCode'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Select Item Code'),
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
                    border: OutlineInputBorder(), hintText: 'Select Item Name'),
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
                    border: OutlineInputBorder(), hintText: 'Select Item MFR'),
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
                    border: OutlineInputBorder(), hintText: 'Select Category'),
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
                    hintText: 'Select SubCategory'),
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
                    border: OutlineInputBorder(), hintText: "Select Rack"),
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
                    border: OutlineInputBorder(), hintText: "Select TaxGroup"),
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
                    border: OutlineInputBorder(), hintText: "Select Supplier"),
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
                    border: OutlineInputBorder(), hintText: "Select Unit"),
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
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/location'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Select Branch"),
                onChanged: (dynamic data) {
                  location = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
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
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/ItemCode'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Select Item Code"),
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
                    border: OutlineInputBorder(), hintText: "Select Item Name"),
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
                    border: OutlineInputBorder(), hintText: "Select Item MFR"),
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
                    border: OutlineInputBorder(), hintText: "Select Category"),
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
                    hintText: "Select SubCategory"),
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
                    border: OutlineInputBorder(), hintText: "Select Rack"),
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
                    border: OutlineInputBorder(), hintText: "Select TaxGroup"),
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
                    border: OutlineInputBorder(), hintText: "Select Supplier"),
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
    DataJson(id: 1, name: 'INCLUDE MINUS STOCK')
  ];

  dropDownStockMinus() {
    return Row(
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
          items:
              minusStockList.map<DropdownMenuItem<DataJson>>((DataJson value) {
            return DropdownMenuItem<DataJson>(
              value: value,
              child: Text(value.name),
            );
          }).toList(),
        ),
      ],
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
