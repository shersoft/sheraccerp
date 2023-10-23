// @dart = 2.11
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';
import 'package:pdf/widgets.dart' as pw;

import '../inventory/sales/sales_list.dart';

class TaxReport extends StatefulWidget {
  const TaxReport({Key key}) : super(key: key);

  @override
  State<TaxReport> createState() => _TaxReportState();
}

class _TaxReportState extends State<TaxReport> {
  String fromDate, toDate, sType = 'Summery';
  var _data;
  DateTime now = DateTime.now();
  DioService api = DioService();
  List<SalesType> salesTypeDataList = [];
  bool loadReport = false, isType = false;
  String title = 'Tax Report';
  int voucherType = 0;
  String valueMonth = '';
  List<String> tableColumn = [];
  List<String> monthList = [
    "",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];
  List<TypeItem> dropdownFormType = [
    TypeItem(0, ''),
    TypeItem(1, "PURCHASE"),
    TypeItem(2, "SALES"),
    TypeItem(3, "SALES RETURN"),
    TypeItem(4, "GENERAL"),
    TypeItem(5, "PURCHASE RETURN")
  ];
  TypeItem voucherTypeData;

  bool valueSalesReturn = false, valuePurchaseReturn = false;

  List<CompanySettings> settings;
  @override
  void initState() {
    super.initState();
    fromDate = DateUtil.datePickerDMY(now);
    toDate = DateUtil.datePickerDMY(now);
    salesTypeDataList = salesTypeList;
    settings = ScopedModel.of<MainModel>(context).getSettings();

    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
  }

  void itemChange(bool val, int index) {
    setState(() {
      salesTypeDataList[index].stock = val;
    });
  }

  List<String> dropdownModelTypeList = [];
  String valueModelType = '';

  void changeSelection() {
    List<String> dropdownModelType = [];
    if (voucherType == 2 && companyTaxMode == "INDIA") {
      dropdownModelType.add("");
      dropdownModelType.add("GSTR1 REPORT");
      dropdownModelType.add("SALES MODEL 1");
      dropdownModelType.add("SALES MODEL 2");
      dropdownModelType.add("HSN WISE");
      dropdownModelType.add("GSTR3B REPORT");
      dropdownModelType.add("SALES MODEL 2 DAILY");
      dropdownModelType.add("b2bs");
      dropdownModelType.add("b2b");
      dropdownModelType.add("b2cs");
      dropdownModelType.add("SALES MODEL 3");
      dropdownModelType.add("SALES MODEL 8");
      dropdownModelType.add("SALES HSN DETAILED");
      dropdownModelType.add("CDNR");
    } else if (voucherType == 1 && companyTaxMode == "INDIA") {
      dropdownModelType.add("");
      dropdownModelType.add("GSTR2 REPORT");
      dropdownModelType.add("PURCHASE MODEL 2");
      dropdownModelType.add("CAPITAL GSTR2 REPORT");
      dropdownModelType.add("EXPENSE GSTR2 REPORT");
    } else if (voucherType == 5 && companyTaxMode == "INDIA") {
      dropdownModelType.add("");
      dropdownModelType.add("PURCHASE RETURN GSTR2 REPORT");
    } else if (voucherType == 3 && companyTaxMode == "INDIA") {
      dropdownModelType.add("");
      dropdownModelType.add("RETURN REPORT");
      dropdownModelType.add("SALES RETURN MODEL 8");
    } else if (voucherType == 4 && companyTaxMode == "INDIA") {
      dropdownModelType.add("");
      dropdownModelType.add("Simple Tax Report");
    } else if (voucherType == 4 && companyTaxMode != "INDIA") {
      dropdownModelType.add("");
      dropdownModelType.add("SIMPLE GCC VAT REPORT");
    }
    if (voucherType == 2) {
      // SqlCommand sqlCommand = new SqlCommand("Sp_SalesList", ConClass.shop);
      // sqlCommand.Parameters.AddWithValue("@StatementType", "SelectSalesType");
      // sqlCommand.CommandType = CommandType.StoredProcedure;
      // DataSet ds = new DataSet();
      // (new SqlDataAdapter(sqlCommand)).Fill(ds);
      // if (ds != null) {
      //   this.dtsetting = new DataTable();
      //   this.dtsetting = ds.Tables[0];
      //   this.dataGridView1.Rows.Clear();
      //   for (int index = 0; index <= ds.Tables[0].Rows.Count - 1; index++) {
      //     this.dataGridView1.Rows.Add();
      //     if (!(ds.Tables[0].Rows[index]["id"].ToString() != "8") ||
      //         !(ds.Tables[0].Rows[index]["id"].ToString() != "6")) {
      //       this.dataGridView1.Rows[index].Cells["Chk_Status"].Value = false;
      //     } else {
      //       this.dataGridView1.Rows[index].Cells["Chk_Status"].Value = true;
      //     }
      //     this.dataGridView1.Rows[index].Cells["Optname"].Value =
      //         ds.Tables[0].Rows[index]["Type"].ToString();
      //     this.dataGridView1.Rows[index].Cells["Optid"].Value =
      //         ds.Tables[0].Rows[index]["id"].ToString();
      //   }
      // }
    }
    if (voucherType == 3) {
      // this.dtsetting = new DataTable();
      // SqlCommand sqlCommand1 = new SqlCommand("Sp_SalesList", ConClass.shop);
      // sqlCommand1.Parameters.AddWithValue(
      //     "@StatementType", "SelectSalesReturnType");
      // sqlCommand1.CommandType = CommandType.StoredProcedure;
      // DataSet ds = new DataSet();
      // (new SqlDataAdapter(sqlCommand1)).Fill(ds);
      // if (ds != null) {
      //   this.dtsetting = ds.Tables[0];
      //   this.dataGridView1.Rows.Clear();
      //   for (int index = 0; index <= ds.Tables[0].Rows.Count - 1; index++) {
      //     this.dataGridView1.Rows.Add();
      //     this.dataGridView1.Rows[index].Cells["Chk_Status"].Value = true;
      //     this.dataGridView1.Rows[index].Cells["Optname"].Value =
      //         ds.Tables[0].Rows[index]["Type"].ToString();
      //     this.dataGridView1.Rows[index].Cells["Optid"].Value =
      //         ds.Tables[0].Rows[index]["id"].ToString();
      //   }
      // }
    }
    setState(() {
      dropdownModelTypeList = dropdownModelType;
      valueModelType = '';
    });
  }

  List<Widget> _getChildren(data) {
    return List<Widget>.generate(
        data.length,
        (index) => CheckboxListTile(
            value: data[index].stock,
            title: Text(data[index].name),
            onChanged: (bool value) {
              itemChange(value, index);
            }));
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
          title: Text(title),
        ),
        body: loadReport ? reportView(title) : selectData(title));
  }

  reportView(title) {
    List<dynamic> dataSType = [];
    if (isType) {
      title = dropdownFormType
          .where((TypeItem element) => element.id == voucherType)
          .map((e) => e.name)
          .first;
    }

    var locationData = [];
    for (var data in locationList) {
      if (data.value.toString().isNotEmpty) {
        locationData.add({'id': data.key});
      }
    }

    String statementType = valueModelType;
    for (var data in salesTypeDataList) {
      if (data.stock) dataSType.add({'id': data.id});
    }

    var dataJson = '[' +
        json.encode({
          'statementType': statementType.isEmpty ? '' : statementType,
          'sDate': fromDate.isEmpty ? '' : formatYMD(fromDate),
          'eDate': toDate.isEmpty ? '' : formatYMD(toDate),
          'salesType': dataSType != null
              ? jsonEncode(dataSType)
              : jsonEncode([
                  {'id': 0}
                ]),
          'salesReturn': valueSalesReturn,
          'purchaseReturn': valuePurchaseReturn,
        }) +
        ']';

    return FutureBuilder<List<dynamic>>(
      future: api.getTaxReport(dataJson),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            var col = data[0].keys.toList();
            _data = data;
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Month : '),
                  DropdownButton(
                    value: valueMonth,
                    items: monthList.map((item) {
                      return DropdownMenuItem<String>(
                        child: Text(item),
                        value: item,
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        valueMonth = value;
                      });
                    },
                  ),
                ],
              ),
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
                        fromDate,
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Voucher '),
                  DropdownButton(
                    value: voucherType,
                    items: dropdownFormType.map((TypeItem item) {
                      return DropdownMenuItem<int>(
                        child: Text(item.name),
                        value: item.id,
                      );
                    }).toList(),
                    onChanged: (value) {
                      voucherType = value;
                      voucherTypeData = dropdownFormType.firstWhere(
                        (element) => element.id == voucherType,
                        orElse: () => TypeItem(0, ''),
                      );
                      changeSelection();
                    },
                  ),
                ],
              ),
              Visibility(
                visible: dropdownModelTypeList.isNotEmpty,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('Select Model '),
                    DropdownButton(
                      value: valueModelType,
                      items: dropdownModelTypeList.map((var item) {
                        return DropdownMenuItem<String>(
                          child: Text(item),
                          value: item,
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          valueModelType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              TextButton(
                onPressed: () {
                  if (voucherTypeData != null && valueModelType.isNotEmpty) {
                    setState(() {
                      loadReport = true;
                      title =
                          '${voucherTypeData.name} From : $fromDate To : $toDate';
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select Model')));
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
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Sales Return'),
                Checkbox(
                  value: valueSalesReturn,
                  onChanged: (value) {
                    setState(() {
                      valueSalesReturn = value;
                    });
                  },
                ),
                const Divider(),
                const Text('Purchase Return'),
                Checkbox(
                  value: valuePurchaseReturn,
                  onChanged: (value) {
                    setState(() {
                      valuePurchaseReturn = value;
                    });
                  },
                ),
                const Divider()
              ]),
              salesTypeDataList.isNotEmpty
                  ? ExpansionTile(
                      title: const Text('Sales Name'),
                      children: _getChildren(salesTypeDataList),
                    )
                  : Container(),
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
        // html.AnchorElement()
        //   ..href =
        //       '${Uri.dataFromString(csv, mimeType: 'text/csv', encoding: utf8)}'
        //   ..download = title
        //   ..style.display = 'none'
        //   ..click();
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
