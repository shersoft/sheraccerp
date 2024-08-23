// @dart = 2.7

import 'dart:convert';
import 'dart:io';
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;

import 'package:csv/csv.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/models/voucher_type_model.dart';
import 'package:sheraccerp/screens/inventory/purchase/purchase.dart';
import 'package:sheraccerp/screens/inventory/sales/sales_list.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheraccerp/widget/loading.dart';
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
  List<TypeItem> dropdownItemsType = [
    TypeItem(1, 'Daily'),
    TypeItem(2, 'Summery'),
    TypeItem(3, 'ItemWise'),
    TypeItem(4, 'Capital Summery'),
    TypeItem(5, 'Expense Summery'),
    TypeItem(6, 'ItemWise Comparison Stock Rate')
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
                    itemId = DataJson(id: 0, name: '');
                    itemName = DataJson(id: 0, name: '');
                    supplier = DataJson(id: 0, name: '');
                    mfr = DataJson(id: 0, name: '');
                    category = DataJson(id: 0, name: '');
                    subCategory = DataJson(id: 0, name: '');
                    locationId = DataJson(id: 0, name: '');
                    salesMan = DataJson(id: 0, name: '');
                    project = DataJson(id: 0, name: '');
                    taxGroup = DataJson(id: 0, name: '');
                    title = '';
                    reportType = {'Summery', 'ItemWise'};
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
    List<dynamic> dataPType = [];

    for (VoucherType element in voucherTypeList) {
      if (element.voucher.toLowerCase() == 'purchase') {
        dataPType.add({'id': element.id});
      }
    }

    statement = dropdownItemsType
        .where((TypeItem element) => element.id == valueType)
        .map((e) => e.name)
        .first;
    var statementType = '';
    if (formType == 'Purchase') {
      statementType = statement == 'Summery'
          ? 'P_Summery'
          : statement == 'ItemWise'
              ? 'P_ItemWise'
              : statement == 'Capital Summery'
                  ? 'Capital_Summery'
                  : statement == 'Expense Summery'
                      ? 'Expense_Summery'
                      : statement == 'ItemWise Comparison Stock Rate'
                          ? 'ItemWise Comparison Stock Rate'
                          : 'P_Summery';
    } else if (formType == 'All') {
      statementType = 'All_Summery';
    } else if (formType == 'Purchase Return') {
      statementType = statement == 'Summery'
          ? 'Pr_Summery'
          : statement == 'ItemWise'
              ? 'Pr_ItemWise'
              : statement == 'Capital Summery'
                  ? 'Capital_Summery'
                  : statement == 'Expense Summery'
                      ? 'Expense_Summery'
                      : statement == 'ItemWise Comparison Stock Rate'
                          ? 'ItemWise Comparison Stock Rate'
                          : 'Pr_Summery';
    } else if (formType == 'Purchase Order') {
      statementType = statement == 'Summery'
          ? 'PO_Summery'
          : statement == 'ItemWise'
              ? 'PO_ItemWise'
              : statement == 'Capital Summery'
                  ? 'Capital_Summery'
                  : statement == 'Expense Summery'
                      ? 'Expense_Summery'
                      : statement == 'ItemWise Comparison Stock Rate'
                          ? 'ItemWise Comparison Stock Rate'
                          : 'PO_Summery';
    } else if (formType == 'UnR-Purchase') {
      statementType = statement == 'Summery'
          ? 'UnP_Summery'
          : statement == 'ItemWise'
              ? 'UnP_ItemWise'
              : statement == 'Capital Summery'
                  ? 'Capital_Summery'
                  : statement == 'Expense Summery'
                      ? 'Expense_Summery'
                      : statement == 'ItemWise Comparison Stock Rate'
                          ? 'ItemWise Comparison Stock Rate'
                          : 'UnP_Summery';
    }
    var sDate = fromDate.isEmpty ? '2021-01-011' : formatYMD(fromDate);
    var eDate = toDate.isEmpty ? '2021-01-011' : formatYMD(toDate);
    var itemsId = itemId != null ? itemId.id : '0';
    var supplierId = supplier != null ? supplier.id : '0';
    var mfrId = mfr != null ? mfr.id : '0';
    var categoryId = category != null ? category.id : '0';
    var subcategoryId = subCategory != null ? subCategory.id : '0';
    var locationsId = locationId != null ? locationId.id : '1';
    var projectId = project != null ? project.id : '0';
    var salesManId = salesMan != null ? salesMan.id : '0';
    var taxGroupId = taxGroup != null ? taxGroup.id : '0';
    var pType = purchaseType == 'Purchase'
        ? 'P'
        : purchaseType == 'InterState'
            ? 'I'
            : purchaseType == 'InterState'
                ? 'I'
                : purchaseType == 'Composite'
                    ? 'C'
                    : purchaseType == 'Branch Transfer'
                        ? 'BT'
                        : purchaseType == 'Imports'
                            ? 'Im'
                            : purchaseType == 'UnRegistered Dealer'
                                ? 'U'
                                : purchaseType == 'VAT Purchase'
                                    ? 'VP'
                                    : '';

    if (statement == 'Daily') {
      return _purchaseListData(
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
          taxGroupId,
          dataPType);
    } else {
      var dataJson = '[' +
          json.encode({
            'sDate': sDate,
            'eDate': eDate,
            'branchId': locationsId,
            'statementType': statementType,
            'supplierId': supplierId,
            'project': projectId,
            'itemId': itemsId,
            'mfr': mfrId,
            'category': categoryId,
            'subcategory': subcategoryId,
            'salesman': salesManId,
            'taxGroup': taxGroupId,
            'type': pType,
            'taxType': taxType,
            'purchaseType': dataPType != null
                ? jsonEncode(dataPType)
                : jsonEncode({'id': 0}),
          }) +
          ']';

      return FutureBuilder<List<dynamic>>(
        future: api.getPurchaseReport(dataJson),
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
                                          child: InkWell(
                                            child: Text(
                                              values[col[i]] != null
                                                  ? values[col[i]].toString()
                                                  : '',
                                              softWrap: true,
                                              overflow: TextOverflow.ellipsis,
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
                                                showEditDialog(
                                                    context,
                                                    int.tryParse(
                                                        no.toString()));
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
  }

  String formType = 'Purchase';
  String purchaseType = '';
  String taxType = '';

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
              Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('Purchase Form : '),
                    DropdownButton(
                      value: formType,
                      items: [
                        'Purchase',
                        'All',
                        'Purchase Return',
                        'Purchase Order',
                        'UnR-Purchase'
                      ].map((String item) {
                        return DropdownMenuItem<String>(
                          child: Text(item),
                          value: item,
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          formType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              // const Divider(),
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
                    border: OutlineInputBorder(), label: Text('Select Branch')),
                onChanged: (dynamic data) {
                  locationId = data;
                },
                showSearchBox: true,
              ),
              // Divider(),
              Card(
                child: Row(
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
              // const Divider(),
              Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('Purchase Type : '),
                    DropdownButton(
                      value: purchaseType,
                      items: [
                        '',
                        'Purchase',
                        'InterState',
                        'Composite',
                        'UnRegistered Dealer',
                        'Branch Transfer'
                            'Imports'
                      ].map((String item) {
                        return DropdownMenuItem<String>(
                          child: Text(item),
                          value: item,
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          purchaseType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
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
                  itemId = data;
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
                    label: Text('Select Supplier')),
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
                    api.getSalesListData(filter, 'sales_list/salesMan'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Select SalesMan')),
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
                    border: OutlineInputBorder(),
                    label: Text('Select Project')),
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
                    border: OutlineInputBorder(),
                    label: Text('Select TaxGroup')),
                onChanged: (dynamic data) {
                  taxGroup = data;
                },
                showSearchBox: true,
              ),
              // const Divider(),
              Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('Tax Type : '),
                    DropdownButton(
                      value: taxType,
                      items: ['', 'T', 'NT'].map((String item) {
                        return DropdownMenuItem<String>(
                          child: Text(item),
                          value: item,
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          taxType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
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
    title = title.replaceAll(new RegExp(r'[^\w\s]+'), '');
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
    title = title.replaceAll(new RegExp(r'[^\w\s]+'), '');
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

  final ScrollController _scrollController = ScrollController();
  bool isLoadingData = false, valueMore = false, lastRecord = false;
  // final _scaffoldKey = GlobalKey<ScaffoldState>();
  int page = 1, pageTotal = 0, totalRecords = 0;

  void _getMoreData(
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
      taxGroupId,
      purchaseType) async {
    if (!lastRecord) {
      if ((dataDisplay.isEmpty || dataDisplay.length < totalRecords) &&
          !isLoadingData) {
        setState(() {
          isLoadingData = true;
        });

        List tempList = [];
        var dataJsonS = '[' +
            json.encode({
              'statementType': 'PurchaseList',
              'sDate': sDate.isEmpty ? '' : sDate,
              'eDate': eDate.isEmpty ? '' : eDate,
              'itemId': int.tryParse(itemsId.toString()),
              'customerId': int.tryParse(supplierId.toString()),
              'supplierId': int.tryParse(supplierId.toString()),
              'mfr': int.tryParse(mfrId.toString()),
              'category': int.tryParse(categoryId.toString()),
              'subcategory': int.tryParse(subcategoryId.toString()),
              'location': int.tryParse(locationsId.toString()),
              'project': int.tryParse(projectId.toString()),
              'salesman': int.tryParse(salesManId.toString()),
              'salesType': purchaseType != null
                  ? jsonEncode(purchaseType)
                  : jsonEncode({'id': 0}),
              "page": page,
              'areaId': 0,
              'groupId': 0,
              'taxGroup': 0
            }) +
            ']';
        api.getListPageReport(dataJsonS).then((value) {
          final response = value;
          if (response.isNotEmpty) {
            pageTotal = response[1][0]['Filtered'];
            totalRecords = response[1][0]['Total'];
            page++;
            for (int i = 0; i < response[0].length; i++) {
              tempList.add(response[0][i]);
            }

            dataDisplay.addAll(tempList);
            dataDisplayHead.addAll(response[1]);
            lastRecord = tempList.isNotEmpty ? false : true;
          } else {
            dataDisplay = [];
            dataDisplayHead = [];
            lastRecord = tempList.isNotEmpty ? false : true;
          }
          isLoadingData = false;

          setState(() {});
        });
      }
    }
  }

  List dataDisplay = [];
  List dataDisplayHead = [];

  _purchaseListData(
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
      taxGroupId,
      purchaseType) {
    _getMoreData(
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
        taxGroupId,
        purchaseType);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreData(
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
            taxGroupId,
            purchaseType);
      }
    });

    return isLoadingData
        ? const Loading()
        : Column(
            children: [
              dataDisplay.isEmpty
                  ? const Center(child: Text('No Data'))
                  : Container(
                      decoration: BoxDecoration(
                          color: blue[200],
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20.0),
                              bottomRight: Radius.circular(20.0))),
                      child: Column(
                        children: [
                          Center(
                              child: Text(
                            ' Date: ' + fromDate + ' - ' + toDate,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                          Text(
                            'Total Purchase Invoice : ' +
                                (dataDisplayHead[0]['Filtered']).toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                'Cash:' +
                                    dataDisplayHead[0]['CashPaid']
                                        .toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Bank:' +
                                    dataDisplayHead[0]['BankAmount']
                                        .toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                'Total : ' +
                                    dataDisplayHead[0]['GrandTotal']
                                        .toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Balance:' +
                                    dataDisplayHead[0]['Balance']
                                        .toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      )),
              Expanded(
                child: ListView.builder(
                  itemCount: dataDisplay.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (dataDisplay.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Opacity(
                            opacity: isLoadingData ? 1.0 : 00,
                            child: const CircularProgressIndicator(),
                          ),
                        ),
                      );
                    } else {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Stack(
                            children: <Widget>[
                              Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: const LinearGradient(
                                      colors: [
                                        Color(0xff6DC8F3),
                                        Color(0xff73A1F9)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xff73A1F9),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                top: 0,
                                child: CustomPaint(
                                  size: const Size(100, 150),
                                  painter: CustomCardShapePainter(
                                      24,
                                      const Color(0xff6DC8F3),
                                      const Color(0xff73A1F9)),
                                ),
                              ),
                              Positioned.fill(
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: InkWell(
                                          onTap: () {
                                            int _id = int.tryParse(
                                                dataDisplay[index]['Type']
                                                    .toString());
                                            // SalesType sData = salesTypeDataList
                                            //     .where((element) => element.id == _id)
                                            //     .first;
                                            // salesTypeData = SalesType(
                                            //     id: sData.id,
                                            //     accounts: sData.accounts,
                                            //     location: locationId != null
                                            //         ? locationId.id
                                            //         : sData.location,
                                            //     name: sData.name,
                                            //     rateType: sData.rateType,
                                            //     stock: sData.stock,
                                            //     type: sData.type,
                                            //     eInvoice: sData.eInvoice,
                                            //     sColor: sData.sColor,
                                            //     tax: sData.tax);
                                            dataDynamic = [
                                              {'Id': _id}
                                            ];
                                            dataDynamic = [
                                              {
                                                'RealEntryNo': int.tryParse(
                                                    dataDisplay[index]['Id']
                                                        .toString()),
                                                'EntryNo': int.tryParse(
                                                    dataDisplay[index]['Id']
                                                        .toString()),
                                                'Id': int.tryParse(
                                                    dataDisplay[index]['Id']
                                                        .toString()),
                                                'InvoiceNo': int.tryParse(
                                                    dataDisplay[index]
                                                            ['Invoice']
                                                        .toString()),
                                                'Type': _id.toString()
                                              }
                                            ];
                                            showEditDialog(
                                                context,
                                                int.tryParse(dataDisplay[index]
                                                        ['Id']
                                                    .toString()));
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                dataDisplay[index]['FromSup']
                                                    .toString(),
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                              Text(
                                                'Invoice : ' +
                                                    dataDisplay[index]['Id']
                                                        .toString(),
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                'Date     : ' +
                                                    dataDisplay[index]['Date']
                                                        .toString(),
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Bill          : ',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Cash     : ',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Balance : ',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () {
                                        int _id = int.tryParse(
                                            dataDisplay[index]['Type']
                                                .toString());
                                        // SalesType sData = salesTypeDataList
                                        //     .where((element) => element.id == _id)
                                        //     .first;
                                        // salesTypeData = SalesType(
                                        //     id: sData.id,
                                        //     accounts: sData.accounts,
                                        //     location: locationId != null
                                        //         ? locationId.id
                                        //         : sData.location,
                                        //     name: sData.name,
                                        //     rateType: sData.rateType,
                                        //     stock: sData.stock,
                                        //     type: sData.type,
                                        //     eInvoice: sData.eInvoice,
                                        //     sColor: sData.sColor,
                                        //     tax: sData.tax);
                                        showDetails(
                                            context, dataDisplay[index], _id);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: <Widget>[
                                            Text(
                                              dataDisplay[index]['Total']
                                                  .toStringAsFixed(2),
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                            Text(
                                              dataDisplay[index]['Cash']
                                                  .toStringAsFixed(2),
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                            Text(
                                              dataDisplay[index]['Balance']
                                                  .toStringAsFixed(2),
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  controller: _scrollController,
                ),
              ),
            ],
          );
  }

  showDetails(context, data, sType) {
    dataDynamic = [
      {
        'RealEntryNo': int.tryParse(data['Id'].toString()),
        'EntryNo': int.tryParse(data['Id'].toString()),
        'InvoiceNo': int.tryParse(data['Id'].toString()),
        'Type': '0'
      }
    ];
    Navigator.pushReplacementNamed(context, '/purchasePreviewShow',
        arguments: {'title': 'Purchase'});
  }

  showEditDialog(context, int _id) {
    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
        },
        onPressedYes: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const Purchase(
                    oldPurchase: true,
                  )));
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage: 'Do you want to edit or delete\nRefNo:$_id',
        title: 'Update',
        context: context);
  }
}

class TypeItem {
  int id;
  String name;
  TypeItem(this.id, this.name);
}
