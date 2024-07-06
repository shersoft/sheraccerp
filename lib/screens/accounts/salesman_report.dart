import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/option_rate_type.dart';
import 'package:sheraccerp/models/other_registrations.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/inventory/damage_report.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';
import 'package:intl/intl.dart';

class SalesManReport extends StatefulWidget {
  const SalesManReport({Key? key}) : super(key: key);

  @override
  State<SalesManReport> createState() => _SalesManReportState();
}

class _SalesManReportState extends State<SalesManReport> {
  String? fromDate, toDate, sType = 'Summery';
  var _data;
  DateTime now = DateTime.now();
  DioService api = DioService();
  bool loadReport = false;
  String title = '';
  int voucherType = 0, salesMan = 0;
  String valueMonth = '';
  List<String> tableColumn = [];
  List<TypeItem> dropdownFormType = [
    TypeItem(0, ''),
    TypeItem(1, "Employee List"),
    TypeItem(2, "Collection Report"),
    TypeItem(3, "Balance Report"),
    TypeItem(4, "Sales And Receipt Age Wise"),
    TypeItem(5, "All Collection Report"),
    TypeItem(6, "SalesMan Proficiency"),
    TypeItem(7, "PT Based Commision Report"),
    TypeItem(8, "E-Commerce Employee Commision"),
    TypeItem(9, "Total Collection")
  ];
  List<ItemDataModel> areaDataList = [];
  List<CompanySettings>? settings;
  String argPass = '';
  List<ReportDesign> reportDesign = [];

  @override
  void initState() {
    super.initState();
    fromDate = DateUtil.datePickerDMY(now);
    toDate = DateUtil.datePickerDMY(now);
    settings = ScopedModel.of<MainModel>(context).getSettings();

    companyTaxMode = ComSettings.getValue('PACKAGE', settings);

    for (OtherRegistrationModel element in otherRegAreaList) {
      areaDataList
          .add(ItemDataModel(id: element.id, name: element.name, status: true));
    }
    argPass = argumentsPass != null ? argumentsPass : '';
    salesMan = argPass.isEmpty
        ? 0
        : ComSettings.appSettings(
                'int', 'key-dropdown-default-salesman-view', 1) -
            1;
    api.getCityListBySalesMan(salesMan).then(
      (valueResult) {
        if (valueResult.isNotEmpty) {
          areaDataList.clear();
          for (Map element in valueResult) {
            areaDataList.add(ItemDataModel(
                id: element['id'],
                name: (element['name'] ?? ''),
                status: element['id'] == 0 ? false : true));
          }
        }
      },
    );
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
                      _createPDF(
                              title + ' Date :' + fromDate! + ' - ' + toDate!)
                          .then((value) =>
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => PDFScreen(
                                        pathPDF: value,
                                        subject: title +
                                            ' Date :' +
                                            fromDate! +
                                            ' - ' +
                                            toDate!,
                                        text: 'this is ' +
                                            title +
                                            ' Date :' +
                                            fromDate! +
                                            ' - ' +
                                            toDate!,
                                      ))));
                    });
                  } else if (menuId == 2) {
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      _createCSV(
                              title + ' Date :' + fromDate! + ' - ' + toDate!)
                          .then((value) {
                        var text = 'this is ' +
                            title +
                            ' Date :' +
                            fromDate! +
                            ' - ' +
                            toDate!;
                        var subject =
                            title + ' Date :' + fromDate! + ' - ' + toDate!;
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
          title: Text(title),
        ),
        body: loadReport ? reportView(title) : selectData(title));
  }

  reportView(title) {
    List<dynamic> dataSType = [];
    for (var data in areaDataList) {
      if (data.status) dataSType.add({'id': data.id});
    }

    String statementType = voucherType == 1
        ? 'Employee List'
        : voucherType == 2
            ? 'Collection Report'
            : voucherType == 3
                ? 'Balance Report'
                : voucherType == 4
                    ? 'Sales And Receipt Age Wise'
                    : voucherType == 5
                        ? 'All Collection Report'
                        : voucherType == 6
                            ? 'SalesMan Proficiency'
                            : voucherType == 7
                                ? 'PT Based Commision Report'
                                : voucherType == 8
                                    ? 'E-Commerce Employee Commision'
                                    : voucherType == 9
                                        ? 'Total Collection'
                                        : '';

    var dataJson = '[' +
        json.encode({
          'statementType': statementType.isEmpty ? '' : statementType,
          'sDate': fromDate!.isEmpty ? '' : formatYMD(fromDate),
          'eDate': toDate!.isEmpty ? '' : formatYMD(toDate),
          'type': dataSType.isNotEmpty
              ? jsonEncode(dataSType)
              : jsonEncode([
                  {'id': 0}
                ]),
          'salesMan': salesMan,
        }) +
        ']';

    return FutureBuilder<List<dynamic>>(
      future: api.getSalesManReport(dataJson),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isNotEmpty) {
            var data = snapshot.data;
            var filterItems = data;
            for (ReportDesign design in reportDesign) {
              if (!design.visibility) {
                for (var item in filterItems!) {
                  item.remove(design.caption.replaceAll(' ', '').trim());
                }
              }
            }
            // var col = data![0].keys.toList();
            _data = data;
            tableColumn = data![0].keys.toList();
            var col = tableColumn;
            Map<String, dynamic> totalData = {};
            for (int i = 0; i < col.length; i++) {
              var cell = '';
              if (col[i].toLowerCase() == ('collectedamount')) {
                cell = data
                    .fold(
                        0.0,
                        (double a, b) =>
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
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Text(
                      title + ' Date: From ' + fromDate + ' To ' + toDate,
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
                                          // style: TextStyle(fontSize: 6),
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

  selectData(title) {
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
                      ' From : ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    InkWell(
                      child: Text(
                        fromDate!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      onTap: () => _selectDate('f'),
                    ),
                    const Text(
                      ' To : ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    InkWell(
                      child: Text(
                        toDate!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      onTap: () => _selectDate('t'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('Report Type'),
                    DropdownButton(
                      value: voucherType,
                      items: dropdownFormType.map((TypeItem item) {
                        return DropdownMenuItem<int>(
                          child: Text(item.name),
                          value: item.id,
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          voucherType = int.parse(value.toString());
                        });
                        var form = voucherType == 1
                            ? 'Employee List'
                            : voucherType == 2
                                ? 'Collection Report'
                                : voucherType == 3
                                    ? 'Balance Report'
                                    : voucherType == 4
                                        ? 'Sales And Receipt Age Wise'
                                        : voucherType == 5
                                            ? 'All Collection Report'
                                            : voucherType == 6
                                                ? 'SalesMan Proficiency'
                                                : voucherType == 7
                                                    ? 'PT Based Commision Report'
                                                    : voucherType == 8
                                                        ? 'E-Commerce Employee Commision'
                                                        : voucherType == 9
                                                            ? 'Total Collection'
                                                            : '';
                        api
                            .getReportDesignByName(form)
                            .then((value) => reportDesign = value);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              argPass.isEmpty
                  ? DropdownSearch<dynamic>(
                      maxHeight: 300,
                      onFind: (String? filter) =>
                          api.getSalesListData(filter, 'sales_list/salesMan'),
                      dropdownSearchDecoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Select SalesMan"),
                      onChanged: (dynamic data) {
                        salesMan = int.parse(data.id.toString());
                      },
                      showSearchBox: true,
                    )
                  : Container(),
              const Divider(),
              areaDataList.isNotEmpty
                  ? ExpansionTile(
                      title: const Text('Area List'),
                      children: _getChildren(areaDataList),
                    )
                  : Container(),
              const Divider(),
              TextButton(
                onPressed: () {
                  if (voucherType > 0) {
                    setState(() {
                      loadReport = true;
                      title = 'SalesManReport From : $fromDate To : $toDate';
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select Report Type')));
                  }
                },
                child: const Text('Show'),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(kPrimaryColor),
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
                ),
              ),
              const Divider()
            ],
          ),
        ),
      ],
    );
  }

  Future _selectDate(String type) async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    setState(() => {
          if (type == 'f')
            {fromDate = DateFormat('dd-MM-yyyy').format(picked!)}
          else
            {toDate = DateFormat('dd-MM-yyyy').format(picked!)}
        });
  }

  String formatYMD(value) {
    var dateTime = DateFormat("dd-MM-yyyy").parse(value.toString());
    return DateFormat("yyyy-MM-dd").format(dateTime);
  }

  Future<String> _createPDF(String title) async {
    return makePDF(title).then((value) => savePreviewPDF(value, title));
  }

  Future<pw.Document> makePDF(String title) async {
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

  List<Widget> _getChildren(data) {
    return List<Widget>.generate(
        data.length,
        (index) => CheckboxListTile(
            value: data[index].status,
            title: Text(data[index].name),
            onChanged: (bool? value) {
              itemChange(value!, index);
            }));
  }

  void itemChange(bool val, int index) {
    setState(() {
      areaDataList[index].status = val;
    });
  }
}
