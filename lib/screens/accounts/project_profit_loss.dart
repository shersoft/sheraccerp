// @dart = 2.11
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/other_registrations.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/report_view.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';
import 'package:pdf/widgets.dart' as pw;

class ProjectProfitLoss extends StatefulWidget {
  const ProjectProfitLoss({Key key}) : super(key: key);

  @override
  State<ProjectProfitLoss> createState() => _ProjectProfitLossState();
}

class _ProjectProfitLossState extends State<ProjectProfitLoss> {
  List<dynamic> items = [];
  List<dynamic> itemDisplay = [];
  List<String> tableColumn = [];
  DioService api = DioService();
  bool loadReport = false, isAdminUser = false;
  var ledgerId, projectId, employeeId;
  String fromDate, toDate, sType = 'Summery';
  var statement = '';
  var salesMan = '0';
  DateTime now = DateTime.now();
  String selectedReportType = '';
  var _data;

  List<CompanySettings> settings;

  @override
  void initState() {
    super.initState();
    settings = ScopedModel.of<MainModel>(context).getSettings();
    fromDate = DateUtil.datePickerDMY(now);
    toDate = DateUtil.datePickerDMY(now);

    isAdminUser =
        companyUserData.userType.toUpperCase() == 'ADMIN' ? true : false;
    if (!isAdminUser) {
      salesMan = (ComSettings.appSettings(
                  'int', 'key-dropdown-default-salesman-view', 1) -
              1)
          .toString();
    }

    statement = 'Summery';
    List<dynamic> groupValues = [
      {'id': '1', 'name': 'Summery'},
      {'id': '2', 'name': 'Project List'},
      {'id': '3', 'name': 'Detailed'},
      {'id': '4', 'name': 'Short Summery'},
      {'id': '5', 'name': 'Bill List'},
      {'id': '6', 'name': 'Employee Expence'},
      {'id': '7', 'name': 'Employee Monthly Turnover List (Above 15% )'},
      {'id': '8', 'name': 'Employee Monthly Turnover List (Below 15% )'},
      {'id': '9', 'name': 'Detailed Summery'},
    ];
    items.addAll(groupValues);
    selectedReportType = items[0]['name'];
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
                icon: const Icon(Icons.clear)),
            Visibility(
                visible: loadReport,
                child: PopupMenuButton(
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
                      if (menuId == 1) {
                        Future.delayed(const Duration(milliseconds: 1000), () {
                          _createPDF(' Date :' + fromDate + ' - ' + toDate)
                              .then((value) =>
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => PDFScreen(
                                            pathPDF: value,
                                            subject: ' Date :' +
                                                fromDate +
                                                ' - ' +
                                                toDate,
                                            text: ' Date :' +
                                                fromDate +
                                                ' - ' +
                                                toDate,
                                          ))));
                        });
                      } else if (menuId == 2) {
                        Future.delayed(const Duration(milliseconds: 1000), () {
                          _createCSV(' Date :' + fromDate + ' - ' + toDate)
                              .then((value) {
                            var text = 'Date :' + fromDate + ' - ' + toDate;
                            var subject = ' Date :' + fromDate + ' - ' + toDate;
                            List<String> paths = [];
                            paths.add(value);
                            urlFileShare(context, text, subject, paths);
                          });
                        });
                      }
                    });
                  },
                ))
          ],
          title: const Text('Project Profit Loss'),
        ),
        body: loadReport ? reportView() : selectData());
  }

  reportView() {
    String statementType = selectedReportType == 'Summery'
        ? 'Summery'
        : selectedReportType == 'Project List'
            ? 'Project List'
            : selectedReportType == 'Detailed'
                ? 'Detailed'
                : selectedReportType == 'Short Summery'
                    ? 'Short Summery'
                    : selectedReportType == 'Bill List'
                        ? 'Summery'
                        : selectedReportType == 'Employee Expence'
                            ? 'Employee Expence'
                            : selectedReportType ==
                                    'Employee Monthly Turnover List (Above 15% )'
                                ? 'Employee Monthly Turnover List (Above 15% )'
                                : selectedReportType ==
                                        'Employee Monthly Turnover List (Below 15% )'
                                    ? 'Employee Monthly Turnover List (Below 15% )'
                                    : selectedReportType == 'Detailed Summery'
                                        ? 'Detailed Summery'
                                        : 'Summery';
    var dataJson = {
      'statementType': statementType.isEmpty ? '' : statementType,
      'sDate': fromDate.isEmpty ? '' : DateUtil.dateYMD(fromDate),
      'eDate': toDate.isEmpty ? '' : DateUtil.dateYMD(toDate),
      'projectId': projectId ?? '0',
      'parentCode': 0,
      'mnth': 0,
      'mnth1': 0,
      'yr': 0,
      'yr1': 0,
      'salesMan': salesMan,
      'fyId': currentFinancialYear.id,
      'customer': ledgerId ?? '0'
    };
    return PinchZoom(
        maxScale: 2.5,
        resetDuration: const Duration(seconds: 2),
        child: fetchData(dataJson));
  }

  fetchData(queryParm) {
    return FutureBuilder<List<dynamic>>(
      future: api.fetchProjectReport(queryParm),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            _data = data;
            var col = data[0].keys.toList();
            tableColumn = data[0].keys.toList();
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Text(
                      ' Date: From ' + fromDate + ' To ' + toDate,
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
                                        child: InkWell(
                                          child: Text(
                                            values[col[i]] != null
                                                ? values[col[i]].toString()
                                                : '',
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            // style: TextStyle(fontSize: 6),
                                          ),
                                          onLongPress: () {
                                            if (col[i] == 'EntryNo') {
                                              var no = values[col[i]];
                                              dataDynamic = [
                                                {
                                                  'RealEntryNo':
                                                      int.tryParse(no),
                                                  'EntryNo': int.tryParse(no),
                                                  'Id': int.tryParse(no),
                                                  'InvoiceNo': '0',
                                                  'Type': '0'
                                                }
                                              ];
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    )
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
              Row(
                children: [
                  const Text('Report Type :'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton(
                        items: items.map((dynamic items) {
                          return DropdownMenuItem(
                            value: items['name'],
                            child: Text(items['name'].toString()),
                          );
                        }).toList(),
                        value: selectedReportType,
                        onChanged: ((value) {
                          setState(() {
                            selectedReportType = value;
                          });
                        })),
                  ),
                ],
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) => api.getProject(),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Select Project'),
                onChanged: (dynamic data) {
                  projectId = data.id;
                },
                showSearchBox: true,
              ),
              const Divider(),
              Visibility(
                visible: isAdminUser,
                child: DropdownSearch<dynamic>(
                  maxHeight: 300,
                  onFind: (String filter) =>
                      api.getSalesListData(filter, 'sales_list/salesMan'),
                  dropdownSearchDecoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Select Salesman')),
                  onChanged: (dynamic data) {
                    salesMan = data.id.toString();
                  },
                  showSearchBox: true,
                ),
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/customer'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: "Select Customer"),
                onChanged: (dynamic data) {
                  ledgerId = data.id;
                },
                showSearchBox: true,
              ),
              const Divider(),
              Visibility(
                visible: isAdminUser,
                child: DropdownSearch<dynamic>(
                  maxHeight: 300,
                  onFind: (String filter) =>
                      api.getSalesListData(filter, 'sales_list/salesMan'),
                  dropdownSearchDecoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Select Employee')),
                  onChanged: (dynamic data) {
                    employeeId = data.id;
                  },
                  showSearchBox: true,
                ),
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
              )
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
              {fromDate = DateUtil.datePickerDMY(picked)}
            else
              {toDate = DateUtil.datePickerDMY(picked)}
          });
    }
  }

  Future<String> _createPDF(String title) async {
    return await makePDF(title).then((value) => savePreviewPDF(value, title));
  }

  Future<pw.Document> makePDF(String title) async {
    var data = _data;
    final pw.Document pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
        // pageFormat: PdfPageFormat.a4,
        maxPages: 100,
        header: (context) => pw.Column(children: [
              pw.Text(title,
                  style: const pw.TextStyle(color: PdfColor.fromInt(0))),
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
                  ]),
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
    title = title.replaceAll(RegExp(r'[^\w\s]+'), '');
    if (kIsWeb) {
      try {
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..style.display = 'none'
        //   ..download = '$title.pdf';
        // html.document.body.children.add(anchor);
        // anchor.click();
        // html.document.body.children.remove(anchor);
        // html.Url.revokeObjectUrl(url);
        return '';
      } catch (ex) {
        ex.toString();
      }
      return '';
    } else {
      var output = await getTemporaryDirectory();
      final file = File('${output.path}/' + title + '.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path.toString();
    }
  }

  Future<String> _createCSV(String title) async {
    return _generateCsvFile(title)
        .then((value) => savePreviewCSV(value, title));
  }

  Future<String> _generateCsvFile(String title) async {
    var dataList = _data;
    List<List<dynamic>> rows = [];
    tableColumn = dataList[0].keys.toList();
    List<dynamic> row = [];
    for (var columnName in tableColumn) {
      row.add(columnName.toString());
    }
    rows.add(row);

    for (var i = 0; i < dataList.length; i++) {
      List<dynamic> row1 = [];
      for (var columnName in tableColumn) {
        row1.add(dataList[i][columnName].toString());
      }
      rows.add(row1);
    }
    return const ListToCsvConverter().convert(rows);
  }

  Future<String> savePreviewCSV(var csv, var title) async {
    title = title.replaceAll(RegExp(r'[^\w\s]+'), '');
    if (kIsWeb) {
      try {
        // final bytes = utf8.encode(csv);
        // final blob = html.Blob([bytes], 'application/csv');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..style.display = 'none'
        //   ..download = '$title.csv';
        // html.document.body.children.add(anchor);
        // anchor.click();
        // html.document.body.children.remove(anchor);
        // html.Url.revokeObjectUrl(url);
        return '';
      } catch (ex) {
        ex.toString();
      }
      return '';
    } else {
      var output = await getTemporaryDirectory();
      final file = File('${output.path}/' + title + '.csv');
      await file.writeAsString(csv);
      return file.path.toString();
    }
  }

  Future<void> urlFileShare(BuildContext context, String text, String subject,
      List<String> paths) async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    if (paths.isNotEmpty) {
      List<XFile> files = [];
      for (String value in paths) {
        files.add(XFile(value));
      }
      await Share.shareXFiles(files,
          text: text,
          subject: subject,
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
    }
  }
}
