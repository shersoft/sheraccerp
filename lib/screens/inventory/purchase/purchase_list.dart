// @dart = 2.7

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

class PurchaseList extends StatefulWidget {
  const PurchaseList({Key key}) : super(key: key);

  @override
  _PurchaseListState createState() => _PurchaseListState();
}

class _PurchaseListState extends State<PurchaseList> {
  String fromDate;
  String toDate;
  var _data;
  int menuId = 0;
  bool loadReport = false;
  DateTime now = DateTime.now();
  List<dynamic> purchaseTypeList = [
    {'id': 0, 'name': 'All'},
    {'id': 1, 'name': 'Purchase'},
    {'id': 2, 'name': 'Return'},
    {'id': 3, 'name': 'Order'}
  ];
  List<TypeItem> dropdownItemsType = [
    TypeItem(1, 'All Summary'),
    TypeItem(2, 'Purchase Summary'),
    TypeItem(3, 'Return Summary'),
    TypeItem(4, 'Order Summary'),
    TypeItem(5, 'ItemWise'),
    TypeItem(6, 'Return ItemWise'),
    TypeItem(7, 'Order ItemWise'),
    TypeItem(8, 'UnRegistered Summery'),
    TypeItem(9, 'UnRegistered ItemWise')
  ];
  int valueType = 1;
  DioService api = DioService();
  var itemId,
      itemName,
      supplier,
      mfr,
      category,
      subCategory,
      locationId,
      salesMan,
      project,
      taxGroup,
      title = '',
      reportType = {'Summery', 'ItemWise'};
  final controller = ScrollController();
  double offset = 0;
  List<dynamic> resultData = [];

  @override
  void initState() {
    super.initState();
    fromDate = DateFormat('dd-MM-yyyy').format(now);
    toDate = DateFormat('dd-MM-yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {
                    loadReport = false;
                  });
                },
                icon: const Icon(Icons.filter_alt)),
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
                      _createPDF(title + ' Date :' + fromDate + ' - ' + toDate)
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
                      _createCSV(title + ' Date :' + fromDate + ' - ' + toDate)
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
          title: const Text('Purchase Report'),
        ),
        body: loadReport ? reportView(title) : selectData());
  }

  reportView(statement) {
    controller.addListener(onScroll);
    // List<dynamic> dataSType = [];
    // for (var data in purchaseTypeList) {
    // if (data['name']) dataSType.add({'id': data['id']});
    // }

    statement = dropdownItemsType
        .where((TypeItem element) => element.id == valueType)
        .map((e) => e.name)
        .first;
    var statementType = statement == 'All Summary'
        ? 'All_Summery'
        : statement == 'Purchase Summary'
            ? 'P_Summery'
            : statement == 'Return Summary'
                ? 'Pr_Summery'
                : statement == 'Order Summary'
                    ? 'PO_Summery'
                    : statement == 'ItemWise'
                        ? 'P_ItemWise'
                        : statement == 'Return ItemWise'
                            ? 'Pr_ItemWise'
                            : statement == 'Order ItemWise'
                                ? 'PO_ItemWise'
                                : statement == 'UnRegistered Summery'
                                    ? 'UnP_Summery'
                                    : statement == 'UnRegistered ItemWise'
                                        ? 'UnP_ItemWise'
                                        : 'All_Summery';
    var sDate = fromDate.isEmpty ? '2021-01-011' : formatYMD(fromDate);
    var eDate = toDate.isEmpty ? '2021-01-011' : formatYMD(toDate);
    var itemsId = itemId != null ? itemId['id'] : '0';
    var supplierId = supplier != null ? supplier['id'] : '0';
    var mfrId = mfr != null ? mfr['id'] : '0';
    var categoryId = category != null ? category['id'] : '0';
    var subcategoryId = subCategory != null ? subCategory['id'] : '0';
    var locationsId = locationId != null ? locationId.id : '0';
    var projectId = project != null ? project['id'] : '0';
    var salesManId = salesMan != null ? salesMan['id'] : '0';
    var taxGroupId = taxGroup != null ? taxGroup['id'] : '0';

    return FutureBuilder<List<dynamic>>(
      future: api.getPurchaseReport(
          locationsId,
          statementType,
          sDate,
          eDate,
          supplierId,
          projectId,
          itemsId,
          mfrId,
          categoryId,
          subcategoryId,
          salesManId,
          taxGroupId),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            _data = data;
            var col = data[0].keys.toList();
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                        child: Text(
                      statement + ' Date: From ' + fromDate + ' To ' + toDate,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.grey.shade200),
                        border:
                            TableBorder.all(width: 1.0, color: Colors.black),
                        columnSpacing: 12,
                        dataRowHeight: 20,
                        headingRowHeight: 30,
                        columns: [
                          for (int i = 0; i < col.length; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  col[i],
                                  style: const TextStyle(
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
                                          values[col[i]] != null
                                              ? values[col[i]].toString()
                                              : '',
                                        )
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Text(
                                          values[col[i]] != null
                                              ? values[col[i]].toString()
                                              : '',
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
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
        // By default, show a loading spinner.
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

  selectData() {
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
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              const Divider(),
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
              //       debugPrint('key-dropdown-default-location-view: $value');
              //       dropDownBranchId = value - 1;
              //     },
              //   ),
              // ),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/location'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Select Branch'),
                onChanged: (dynamic data) {
                  locationId = data;
                },
                showSearchBox: true,
              ),
              // Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Type : '),
                  DropdownButton(
                    value: valueType,
                    items: dropdownItemsType.map((TypeItem item) {
                      return DropdownMenuItem<int>(
                        child: Text(item.name),
                        value: item.id,
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        valueType = value;
                      });
                    },
                  ),
                ],
              ),
              // Divider(),
              TextButton(
                onPressed: () {
                  setState(() {
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
                    api.getSalesListData(filter, 'sales_list/supplier'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Select Supplier'),
                onChanged: (dynamic data) {
                  supplier = data;
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
                    api.getSalesListData(filter, 'sales_list/salesMan'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Select SalesMan'),
                onChanged: (dynamic data) {
                  salesMan = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/project'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Select Project'),
                onChanged: (dynamic data) {
                  project = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/taxGroup'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Select TaxGroup'),
                onChanged: (dynamic data) {
                  taxGroup = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              // Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              //   for (var data in purchaseTypeList)
              //     Row(children: [
              //       Radio(
              //         value: data['id'],
              //         groupValue: purchaseTypeListID,
              //         onChanged: (value) {
              //           setState(() {
              //             purchaseTypeListID = value;
              //           });
              //         },
              //       ),
              //       Text(data['name']),
              //     ]),
              // ]),
            ],
          ),
        ),
      ],
    );
  }

  int purchaseTypeListID = 0;

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

  String formatYMD(value) {
    var dateTime = DateFormat("dd-MM-yyyy").parse(value.toString());
    return DateFormat("yyyy-MM-dd").format(dateTime);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onScroll() {
    setState(() {
      offset = (controller.hasClients) ? controller.offset : 0;
    });
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
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(tableHeaders[0],
                              style: const pw.TextStyle(fontSize: 6)),
                          // pw.Divider(thickness: 1)
                        ]),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(tableHeaders[1],
                              style: const pw.TextStyle(fontSize: 6)),
                          // pw.Divider(thickness: 1)
                        ]),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(tableHeaders[2],
                              style: const pw.TextStyle(fontSize: 6)),
                          // pw.Divider(thickness: 1)
                        ]),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(tableHeaders[3],
                              style: const pw.TextStyle(fontSize: 6)),
                          // pw.Divider(thickness: 1)
                        ]),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(tableHeaders[4],
                              style: const pw.TextStyle(fontSize: 6)),
                          // pw.Divider(thickness: 1)
                        ]),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(tableHeaders[5],
                              style: const pw.TextStyle(fontSize: 6)),
                          // pw.Divider(thickness: 1)
                        ]),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(tableHeaders[6],
                              style: const pw.TextStyle(fontSize: 6)),
                          // pw.Divider(thickness: 1)
                        ]),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(tableHeaders[7],
                              style: const pw.TextStyle(fontSize: 6)),
                          // pw.Divider(thickness: 1)
                        ]),
                  ]),
                  for (var i = 0; i < data.length; i++)
                    pw.TableRow(children: [
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text(data[i]['Date'],
                                  style: const pw.TextStyle(fontSize: 6)),
                              // pw.Divider(thickness: 1)
                            ),
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text(data[i]['Particulars'],
                                  style: const pw.TextStyle(fontSize: 6)),
                              // pw.Divider(thickness: 1)
                            ),
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text('${data[i]['Voucher']}',
                                  style: const pw.TextStyle(fontSize: 6)),
                              // pw.Divider(thickness: 1)
                            )
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text('${data[i]['EntryNo']}',
                                  style: const pw.TextStyle(fontSize: 6)),
                              // pw.Divider(thickness: 1)
                            )
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text('${data[i]['Debit']}',
                                  style: const pw.TextStyle(fontSize: 6)),
                              // pw.Divider(thickness: 1)
                            )
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text('${data[i]['Credit']}',
                                  style: const pw.TextStyle(fontSize: 6)),
                              // pw.Divider(thickness: 1)
                            )
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text('${data[i]['Balance']}',
                                  style: const pw.TextStyle(fontSize: 6)),
                              // pw.Divider(thickness: 1)
                            )
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text('${data[i]['Narration']}',
                                  style: const pw.TextStyle(fontSize: 6)),
                              // pw.Divider(thickness: 1)
                            )
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

class TypeItem {
  int id;
  String name;
  TypeItem(this.id, this.name);
}
