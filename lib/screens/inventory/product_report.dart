// @dart = 2.7
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';
import 'package:pdf/widgets.dart' as pw;

class ProductReport extends StatefulWidget {
  const ProductReport({Key key}) : super(key: key);

  @override
  _ProductReportState createState() => _ProductReportState();
}

class _ProductReportState extends State<ProductReport> {
  bool loadReport = false;
  DateTime now = DateTime.now();
  DioService api = DioService();
  var itemId,
      itemName,
      unit,
      mfr,
      category,
      subCategory,
      salesMan,
      project,
      taxGroup,
      hsnCode,
      rack,
      dropDownTypeOfSupply;
  final controller = ScrollController();
  double offset = 0;
  List<dynamic> resultData = [];
  List<String> typeOfSupplyData = ['GOODS', 'SERVICE'];
  // _JsonDataGridSource jsonDataGridSource;
  List<dynamic> productlist = [];
  var _data;
  @override
  void initState() {
    super.initState();
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
                    pluNo = false;
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
                      _createPDF('Product List').then((value) =>
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => PDFScreen(
                                    pathPDF: value,
                                    subject: 'Product List',
                                  ))));
                    });
                  } else if (menuId == 2) {
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      _createCSV('Product List').then((value) {
                        var text = 'Product List';
                        var subject = 'Product List';
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
          title: const Text('Product List'),
        ),
        body: loadReport ? reportView() : selectData());
  }

  bool pluNo = false;
  reportView() {
    //   controller.addListener(onScroll);
    var statementType = pluNo ? 'Plu_List' : 'Product_List';
    var dataJson = '[' +
        json.encode({
          'statementType': statementType,
          // 'itemId': itemId != null ? itemId['id'] : '0',
          // 'itemName': itemId != null ? itemName['name'] : '0',
          'mfr': mfr != null ? mfr['id'] : '0',
          'category': category != null ? category['id'] : '0',
          'subcategory': subCategory != null ? subCategory['id'] : '0',
          'unit': unit != null ? unit['id'] : '0',
          'taxGroup': taxGroup != null ? taxGroup['id'] : '0',
          'typeOfSupply': dropDownTypeOfSupply ?? '',
          'taxP': taxPController.text.isNotEmpty ? taxPController.text : '0',
          'rLevel':
              reorderController.text.isNotEmpty ? reorderController.text : '0',
          'rack': rack ?? 0,
          'hsn': hsnCode ?? ''
        }) +
        ']';

    return FutureBuilder<List<dynamic>>(
      future: api.getProductReport(dataJson),
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
                    const Center(
                        child: Text(
                      'Product List',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

            // jsonDataGridSource = _JsonDataGridSource(data);
            // return SfDataGrid(
            //   source: jsonDataGridSource,
            //   columns: [
            //     // GridColumn(
            //     //   columnName: 'HSNCODE',
            //     //   width: 80,
            //     //   label: Container(
            //     //     padding: EdgeInsets.all(8),
            //     //     alignment: Alignment.centerLeft,
            //     //     child: Text(
            //     //       'HSNCODE',
            //     //       overflow: TextOverflow.clip,
            //     //       softWrap: true,
            //     //     ),
            //     //   ),
            //     // ),
            //     for (int i = 0; i < col.length; i++)
            //       new GridColumn(
            //           // width:
            //           //     double.tryParse(col[i].toString().length.toString()) *
            //           //         12,
            //           columnName: col[i].toString().toLowerCase(),
            //           label: Container(
            //               padding: EdgeInsets.all(10.0),
            //               alignment: Alignment.center,
            //               child: Text(
            //                 col[i].toString().toUpperCase(),
            //                 // softWrap: false,
            //               )))
            //   ],
            // );

            /******************/
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                      value: pluNo,
                      onChanged: (value) => setState(() {
                            pluNo = value;
                          })),
                  const Text('PLU No'),
                  const SizedBox(
                    width: 20,
                  ),
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
                ],
              ),
              const Divider(),
              // DropdownSearch<dynamic>(
              //   maxHeight: 300,
              //   onFind: (String filter) =>
              //       api.getSalesListData(filter, 'sales_list/ItemCode'),
              //   label: "Select Item Code",
              //   onChanged: (dynamic data) {
              //     itemId = data;
              //   },
              //   showSearchBox: true,
              // ),
              // const Divider(),
              // DropdownSearch<dynamic>(
              //   maxHeight: 300,
              //   onFind: (String filter) =>
              //       api.getSalesListData(filter, 'sales_list/itemName'),
              //   label: "Select Item Name",
              //   onChanged: (dynamic data) {
              //     itemName = data;
              //   },
              //   showSearchBox: true,
              // ),
              // const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/unit'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text('Select Unit')),
                onChanged: (dynamic data) {
                  unit = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/manufacture'),
                dropdownSearchDecoration:
                    const InputDecoration(label: Text("Select Item MFR")),
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
              DropdownButton<String>(
                hint: const Text('Type of Supply'),
                value: dropDownTypeOfSupply,
                items: typeOfSupplyData.map<DropdownMenuItem<String>>((value) {
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
                    api.getSalesListData(filter, 'Product/getHsnCodeList'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Select HSN Code")),
                onChanged: (dynamic data) {
                  hsnCode = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: TextField(
                      controller: taxPController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), label: Text('TAX %')),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp(r'[0-9]'),
                            allow: true, replacementString: '.')
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                      child: TextField(
                    controller: reorderController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text('Reorder')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                  )),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextEditingController taxPController = TextEditingController();
  TextEditingController reorderController = TextEditingController();

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
