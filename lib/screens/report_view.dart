// @dart = 2.9
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';
import 'package:pdf/widgets.dart' as pw;
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;

class ReportView extends StatefulWidget {
  const ReportView(
      this.id,
      this.ob,
      this.sDate,
      this.eDate,
      this.type,
      this.name,
      this.statement,
      this.salesMan,
      this.branchId,
      this.area,
      this.route,
      {Key key})
      : super(key: key);
  final String id;
  final String sDate;
  final String eDate;
  final String ob;
  final String type;
  final String name;
  final String statement;
  final String salesMan;
  final List<int> branchId;
  final String area;
  final String route;

  @override
  _ReportViewState createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  DioService api = DioService();
  final controller = ScrollController();
  double offset = 0;
  var _data;
  List<dynamic> location = [
    {'id': 0}
  ];
  List<dynamic> project = [
    {'id': 0}
  ];

  List<CompanySettings> settings;
  List<ReportDesign> reportDesignList;
  List<ReportDesign> reportDesign;
  CompanyInformation companySettings;
  List<String> tableColumn = [];
  List<String> tableColumnIncome = [];
  List<String> tableColumnExpense = [];
  List<String> tableColumnTotal = [];

  @override
  void initState() {
    controller.addListener(onScroll);
    super.initState();
    location.removeAt(0);
    if (widget.branchId[0] == 0) {
      for (int i = 0; i < otherRegLocationList.length; i++) {
        location.add(({'id': otherRegLocationList[i].id}));
      }
    } else {
      for (int i = 0; i < widget.branchId.length; i++) {
        location.add(({'id': widget.branchId[i]}));
      }
    }
    project = [
      {'id': widget.area}
    ];
    loadSettings();
  }

  var companyTaxNo = '';
  loadSettings() {
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();
    reportDesignList = ScopedModel.of<MainModel>(context).getReportDesign();
    companyTaxNo = ComSettings.getValue('GST-NO', settings);

    var form = widget.type == 'ledger'
        ? 'Ledger Report'
        : widget.statement; //'ReceivblesDebitOnly';
    api.getReportDesignByName(form).then((value) => reportDesign = value);
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

  int menuId = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
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
                  if (menuId == 1) {
                    _createPDF('Ledger Report ' +
                            widget.name +
                            ' Date :' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' - ' +
                            DateUtil.dateDMY(widget.eDate))
                        .then((value) =>
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => PDFScreen(
                                      pathPDF: value,
                                      subject: widget.name +
                                          ' Date :' +
                                          DateUtil.dateDMY(widget.sDate) +
                                          ' - ' +
                                          DateUtil.dateDMY(widget.eDate),
                                      text: 'this is ' +
                                          widget.name +
                                          ' Date :' +
                                          DateUtil.dateDMY(widget.sDate) +
                                          ' - ' +
                                          DateUtil.dateDMY(widget.eDate),
                                    ))));
                  } else if (menuId == 2) {
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      _createCSV(widget.name +
                              ' Date :' +
                              DateUtil.dateDMY(widget.sDate) +
                              ' - ' +
                              DateUtil.dateDMY(widget.eDate))
                          .then((value) {
                        var text = 'this is ' +
                            widget.name +
                            ' Date :' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' - ' +
                            DateUtil.dateDMY(widget.eDate);
                        var subject = widget.name +
                            ' Date :' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' - ' +
                            DateUtil.dateDMY(widget.eDate);
                        List<String> paths = [];
                        paths.add(value);
                        urlFileShare(context, text, subject, paths);
                      });
                    });
                  }
                });
              },
            )
            // IconButton(
            //     icon: const Icon(Icons.share_rounded),
            //     onPressed: () {
            //       setState(
            //         () {
            //           Future.delayed(const Duration(milliseconds: 1000), () {
            //             _createPDF(widget.name +
            //                     ' Date :' +
            //                     DateUtil.dateDMY(widget.sDate) +
            //                     ' - ' +
            //                     DateUtil.dateDMY(widget.eDate))
            //                 .then((value) =>
            //                     Navigator.of(context).push(MaterialPageRoute(
            //                         builder: (_) => PDFScreen(
            //                               pathPDF: value,
            //                               subject: widget.name +
            //                                   ' Date :' +
            //                                   DateUtil.dateDMY(widget.sDate) +
            //                                   ' - ' +
            //                                   DateUtil.dateDMY(widget.eDate),
            //                               text: 'this is ' +
            //                                   widget.name +
            //                                   ' Date :' +
            //                                   DateUtil.dateDMY(widget.sDate) +
            //                                   ' - ' +
            //                                   DateUtil.dateDMY(widget.eDate),
            //                             ))));
            //           });
            //         },
            //       );
            //     }),
          ],
          title: Text(widget.type),
        ),
        body: PinchZoom(
            maxScale: 2.5,
            resetDuration: const Duration(seconds: 2),
            child: (widget.type == 'ledger' ||
                    widget.type == 'Day Book' ||
                    widget.type == 'Trial Balance' ||
                    widget.type == 'Cash Flow' ||
                    widget.type == 'Invoice Wise Balance Customers' ||
                    widget.type == 'Invoice Wise Balance Suppliers'
                ? reportView()
                : widget.type == 'Fund Flow'
                    ? reportViewFundFlow()
                    : widget.type == 'Cheque'
                        ? reportViewBankVouchers()
                        : widget.type == 'User Activity'
                            ? reportViewUserActivity()
                            : widget.type == 'Monthly Sales'
                                ? reportViewMonthlySalesReport(widget.branchId)
                                : widget.type == 'Monthly Purchase'
                                    ? reportViewMonthlyPurchase(widget.branchId)
                                    : widget.type == 'Bill By Bill'
                                        ? reportViewSalesBillByBill()
                                        : widget.type == 'GroupList'
                                            ? reportViewGroupList()
                                            : widget.type == 'LedgerList'
                                                ? reportViewLedgerList()
                                                : widget.type ==
                                                        'Closing Report'
                                                    ? reportViewClosingReport()
                                                    : widget.type ==
                                                            'EmployeeList'
                                                        ? reportViewEmployeeList()
                                                        : widget.type ==
                                                                'CustomerCardList'
                                                            ? reportViewCustomerCardList()
                                                            : widget.type ==
                                                                    'P&L Account'
                                                                ? reportViewProfitAndLossAccount()
                                                                : widget.type ==
                                                                        'BalanceSheet'
                                                                    ? reportViewBalanceSheet()
                                                                    : widget.type ==
                                                                                'Payable' ||
                                                                            widget.type ==
                                                                                'Receivable'
                                                                        ? reportView()
                                                                        : widget.type == 'PaymentList' ||
                                                                                widget.type == 'ReceiptList' ||
                                                                                widget.type == 'JournalList'
                                                                            ? reportVoucherList()
                                                                            : const Text('No Report'))));
  }

  bool classic = false;
  final GlobalKey _globalKey = GlobalKey();
  reportView() {
    if (widget.type != 'ledger') {
      classic = true;
    } else {
      if (MediaQuery.of(context).orientation == Orientation.landscape) {
        classic = true;
      } else {
        classic = false;
      }
    }
    var dataJson = '[' +
        json.encode({
          'statementType': widget.statement.isEmpty ? '' : widget.statement,
          'sDate': widget.sDate.isEmpty ? '' : widget.sDate,
          'eDate': widget.eDate.isEmpty ? '' : widget.eDate,
          'id': widget.id ?? '',
          'Check_openingbalance': widget.ob ?? 0,
          'location': jsonEncode(location),
          'project': jsonEncode(project),
          'salesMan': 0,
          'fyId': currentFinancialYear.id,
        }) +
        ']';
    return FutureBuilder<List<dynamic>>(
      future: api.fetchLedgerReport(dataJson),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            if (widget.statement == 'Ledger_Report_Qty') {
              var filterItems = data;
              for (ReportDesign design in reportDesignList) {
                if (!design.visibility) {
                  for (var item in filterItems) {
                    item.remove(design.caption.trim());
                  }
                }
              }
              // Map<String, dynamic> singleItem = {"type": "P"};
              // filterItems.removeWhere(
              //     (element) => element.keys. =>  == singleItem.keys.first);
              data = filterItems;
            } else {
              var filterItems = data;
              for (ReportDesign design in reportDesign) {
                if (!design.visibility) {
                  for (var item in filterItems) {
                    item.remove(design.caption.replaceAll(' ', '').trim());
                  }
                }
              }
            }
            tableColumn = data[0].keys.toList();
            if (widget.type == 'Invoice Wise Balance Customers' ||
                widget.type == 'Invoice Wise Balance Suppliers' ||
                widget.type == 'Payable' ||
                widget.type == 'Receivable') {
              Map<String, dynamic> totalData = {};
              for (int i = 0; i < tableColumn.length; i++) {
                var cell = '';
                if (tableColumn[i].toLowerCase() == ('debit') ||
                    tableColumn[i].toLowerCase() == ('opbalance') ||
                    tableColumn[i].toLowerCase() == ('credit') ||
                    tableColumn[i].toLowerCase() == ('balance') ||
                    tableColumn[i].toLowerCase() == ('amount') ||
                    tableColumn[i].toLowerCase() == ('total')) {
                  cell = data
                      .fold(
                          0.0,
                          (a, b) =>
                              a +
                              (double.tryParse(b[tableColumn[i]].toString()) ??
                                  0))
                      .toStringAsFixed(2);
                }
                if (i == 0) {
                  cell = 'Total';
                }
                totalData[tableColumn[i]] = cell;
              }
              if (totalData.isNotEmpty) {
                data.add(totalData);
              }
              _data = data;
            } else {
              _data = data;
            }
            return classic
                ? Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      controller: controller,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: Text(widget.name +
                                  ' Date : From ' +
                                  DateUtil.dateDMY(widget.sDate) +
                                  ' To ' +
                                  DateUtil.dateDMY(widget.eDate))),
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
                                            // color: Colors.black,
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
                                                //style: TextStyle(fontSize: 6),
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
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RepaintBoundary(
                      key: _globalKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "ACCOUNT SUMMERY",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  widget.name,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "From  ${widget.sDate}",
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    Text(
                                      "To  ${widget.eDate}",
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 0,
                            ),
                            const Divider(
                              color: Colors.blue,
                            ),
                            Container(
                              height: 20,
                              color: Colors.blue,
                              child: Table(
                                columnWidths: const {
                                  0: FixedColumnWidth(45),
                                  1: FlexColumnWidth(15),
                                  2: FlexColumnWidth(8),
                                  3: FlexColumnWidth(9),
                                  4: FlexColumnWidth(8),
                                },
                                children: [
                                  TableRow(children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          '  Date',
                                          style: TextStyle(
                                              fontSize: 7,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          '  Description',
                                          style: TextStyle(
                                              fontSize: 7,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: const [
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          'Debit',
                                          style: TextStyle(
                                              fontSize: 7,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: const [
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          'Credit',
                                          style: TextStyle(
                                              fontSize: 7,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: const [
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          "Balanace",
                                          style: TextStyle(
                                              fontSize: 7,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ]),
                                ],
                                border: TableBorder.all(
                                    width: 1, color: Colors.blue),
                              ),
                            ),
                            Table(
                              columnWidths: const {
                                0: FixedColumnWidth(45),
                                1: FlexColumnWidth(15),
                                2: FlexColumnWidth(8),
                                3: FlexColumnWidth(9),
                                4: FlexColumnWidth(8),
                              },
                              children: [
                                for (var i = 0; i < data.length; i++)
                                  TableRow(children: [
                                    Center(
                                        child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Text(
                                            // '10/20/2020',
                                            '${data[i]['Date']}',

                                            style: const TextStyle(
                                                fontSize: 6,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    )),
                                    Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Text(
                                        '${data[i]['Particulars']}',
                                        style: const TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${data[i]['Debit']}',
                                            style: const TextStyle(
                                                fontSize: 6,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${data[i]['Credit']}',
                                            style: const TextStyle(
                                                fontSize: 6,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Text(
                                            "${data[i]['Balance']}",
                                            style: const TextStyle(
                                                fontSize: 6,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]),
                              ],
                              border:
                                  TableBorder.all(width: 1, color: Colors.blue),
                            ),
                          ],
                        ),
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
    // FutureBuilder<List<dynamic>>(
    //   future: _data,
    //   builder: (ctx, snapshot) {
    //     if (snapshot.hasData) {
    //       List<Map<String, dynamic>> data = snapshot.data;
    //       // print(data);
    //       return SingleChildScrollView(
    //         scrollDirection: Axis.vertical,
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: <Widget>[
    //             Text(widget.name +
    //                 'Date : From ' +
    //                 widget.sDate +
    //                 ' To ' +
    //                 widget.eDate),
    //             Padding(
    //               padding: EdgeInsets.only(top: 10.0),
    //               child: Center(
    //                 child: SingleChildScrollView(
    //                   scrollDirection: Axis.horizontal,
    //                   child: DataTable(
    //                     sortColumnIndex: 0,
    //                     sortAscending: true,
    //                     columns: [
    //                       DataColumn(
    //                         label: Text(
    //                           'Date',
    //                           style: TextStyle(
    //                             color: Colors.black,
    //                             fontSize: 18.0,
    //                           ),
    //                         ),
    //                         numeric: false,
    //                         tooltip: "Date",
    //                       ),
    //                       DataColumn(
    //                         label: Text(
    //                           'Particulars',
    //                           style: TextStyle(
    //                             color: Colors.black,
    //                             fontSize: 16.0,
    //                           ),
    //                         ),
    //                         numeric: true,
    //                         tooltip: "Particulars",
    //                       ),
    //                       DataColumn(
    //                         label: Text(
    //                           'Voucher',
    //                           style: TextStyle(
    //                             color: Colors.black,
    //                             fontSize: 16.0,
    //                           ),
    //                         ),
    //                         numeric: true,
    //                         tooltip: "Voucher",
    //                       ),
    //                       DataColumn(
    //                         label: Text(
    //                           'EntryNo',
    //                           style: TextStyle(
    //                             color: Colors.black,
    //                             fontSize: 16.0,
    //                           ),
    //                         ),
    //                         numeric: true,
    //                         tooltip: "EntryNo",
    //                       ),
    //                       DataColumn(
    //                         label: Text(
    //                           'Debit',
    //                           style: TextStyle(
    //                             color: Colors.black,
    //                             fontSize: 16.0,
    //                           ),
    //                         ),
    //                         numeric: true,
    //                         tooltip: "Debit",
    //                       ),
    //                       DataColumn(
    //                         label: Text(
    //                           'Credit',
    //                           style: TextStyle(
    //                             color: Colors.black,
    //                             fontSize: 16.0,
    //                           ),
    //                         ),
    //                         numeric: true,
    //                         tooltip: "Credit",
    //                       ),
    //                       DataColumn(
    //                         label: Text(
    //                           'Balance',
    //                           style: TextStyle(
    //                             color: Colors.black,
    //                             fontSize: 16.0,
    //                           ),
    //                         ),
    //                         numeric: true,
    //                         tooltip: "Balance",
    //                       ),
    //                       DataColumn(
    //                         label: Text(
    //                           'Narration',
    //                           style: TextStyle(
    //                             color: Colors.black,
    //                             fontSize: 16.0,
    //                           ),
    //                         ),
    //                         numeric: true,
    //                         tooltip: "Narration",
    //                       ),
    //                     ],
    //                     rows: data
    //                         .map(
    //                           (values) => DataRow(
    //                             cells: [
    //                               DataCell(
    //                                 Container(
    //                                   width: 100,
    //                                   child: Text(
    //                                     values['Date'],
    //                                     softWrap: true,
    //                                     overflow: TextOverflow.ellipsis,
    //                                     style: TextStyle(
    //                                         fontWeight: FontWeight.w600),
    //                                   ),
    //                                 ),
    //                               ),
    //                               DataCell(
    //                                 Container(
    //                                   width: 60.0,
    //                                   child: Center(
    //                                     child: Text(
    //                                       values['Particulars'].toString(),
    //                                       style: TextStyle(
    //                                           fontWeight: FontWeight.bold),
    //                                     ),
    //                                   ),
    //                                 ),
    //                               ),
    //                               DataCell(
    //                                 Container(
    //                                   child: Text(
    //                                     values['Voucher'].toString(),
    //                                     style: TextStyle(
    //                                         fontWeight: FontWeight.bold),
    //                                   ),
    //                                 ),
    //                               ),
    //                               DataCell(
    //                                 Container(
    //                                   child: Text(
    //                                     values['EntryNo'].toString(),
    //                                     style: TextStyle(
    //                                       fontWeight: FontWeight.bold,
    //                                     ),
    //                                     textAlign: TextAlign.right,
    //                                   ),
    //                                 ),
    //                               ),
    //                               DataCell(
    //                                 Container(
    //                                   child: Text(
    //                                     values['Debit'].toString(),
    //                                     style: TextStyle(
    //                                         fontWeight: FontWeight.bold),
    //                                     textAlign: TextAlign.right,
    //                                   ),
    //                                 ),
    //                               ),
    //                               DataCell(
    //                                 Container(
    //                                   child: Text(
    //                                     values['Credit'].toString(),
    //                                     style: TextStyle(
    //                                         fontWeight: FontWeight.bold),
    //                                     textAlign: TextAlign.right,
    //                                   ),
    //                                 ),
    //                               ),
    //                               DataCell(
    //                                 Container(
    //                                   child: Text(
    //                                     values['Balance'].toString(),
    //                                     style: TextStyle(
    //                                         fontWeight: FontWeight.bold),
    //                                     textAlign: TextAlign.right,
    //                                   ),
    //                                 ),
    //                               ),
    //                               DataCell(
    //                                 Container(
    //                                   child: Text(
    //                                     values['Narration'].toString(),
    //                                     style: TextStyle(
    //                                         fontWeight: FontWeight.bold),
    //                                   ),
    //                                 ),
    //                               ),
    //                             ],
    //                           ),
    //                         )
    //                         .toList(),
    //                   ),
    //                 ),
    //               ),
    //             ),
    //             // SizedBox(height: 500),
    //           ],
    //         ),
    //       );
    //     } else if (snapshot.hasError) {
    //       return AlertDialog(
    //         title: Text(
    //           'An Error Occurred!',
    //           textAlign: TextAlign.center,
    //           style: TextStyle(
    //             color: Colors.redAccent,
    //           ),
    //         ),
    //         content: Text(
    //           "${snapshot.error}",
    //           style: TextStyle(
    //             color: Colors.blueAccent,
    //           ),
    //         ),
    //         actions: <Widget>[
    //           TextButton(
    //             child: Text(
    //               'Go Back',
    //               style: TextStyle(
    //                 color: Colors.redAccent,
    //               ),
    //             ),
    //             onPressed: () {
    //               Navigator.of(context).pop();
    //             },
    //           )
    //         ],
    //       );
    //     }
    //     // By default, show a loading spinner.
    //     return Center(
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: <Widget>[
    //           CircularProgressIndicator(),
    //           SizedBox(height: 20),
    //           Text('This may take some time..')
    //         ],
    //       ),
    //     );
    //   },
    // ),
  }

  reportViewFundFlow() {
    var dataJson = '[' +
        json.encode({
          'statementType': widget.statement.isEmpty ? '' : widget.statement,
          'sDate': widget.sDate.isEmpty ? '' : widget.sDate,
          'eDate': widget.eDate.isEmpty ? '' : widget.eDate,
          'id': widget.id ?? '',
          'Check_openingbalance': widget.ob ?? 0,
          'location': jsonEncode(location),
          'project': jsonEncode(project),
          'salesMan': 0
        }) +
        ']';
    return FutureBuilder<List<dynamic>>(
      future: api.fetchLedgerReport(dataJson),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            _data = data;
            tableColumn = data[0].keys.toList();
            int isLastRow = 0;
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                        child: Text(widget.name +
                            ' Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
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
                          for (int i = 0; i < tableColumn.length - 1; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  tableColumn[i],
                                  style: const TextStyle(
                                      // color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                        rows: data
                            .map(
                              (values) => DataRow(
                                color:
                                    MaterialStateProperty.resolveWith((states) {
                                  if (isLastRow == data.length - 1) {
                                    isLastRow++;
                                    return blue;
                                  } else {
                                    isLastRow++;
                                    return white;
                                  }
                                }),
                                cells: [
                                  for (int i = 0; i < values.length - 1; i++)
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
                                          style: TextStyle(
                                              backgroundColor:
                                                  values[tableColumn[3]] == 'H'
                                                      ? red[200]
                                                      : white),
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                          //style: TextStyle(fontSize: 6),
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

  reportViewBankVouchers() {
    return FutureBuilder<List<dynamic>>(
      future: api.fetchBankVouchers(),
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
                controller: controller,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.grey.shade200),
                    border: TableBorder.all(width: 1.0, color: Colors.black),
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
                                  // color: Colors.black,
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
                                      //style: TextStyle(fontSize: 6),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
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

  reportViewUserActivity() {
    return FutureBuilder<List<dynamic>>(
      future: api.fetchEventDetails(widget.sDate),
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
                controller: controller,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.grey.shade200),
                    border: TableBorder.all(width: 1.0, color: Colors.black),
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
                                  // color: Colors.black,
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
                                      //style: TextStyle(fontSize: 6),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
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

  reportViewMonthlySalesReport(var branchId) {
    return FutureBuilder<List<dynamic>>(
      future: api.getMonthlySalesReport(branchId),
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
                controller: controller,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.grey.shade200),
                    border: TableBorder.all(width: 1.0, color: Colors.black),
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
                                  // color: Colors.black,
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
                                      //style: TextStyle(fontSize: 6),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
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

  reportViewMonthlyPurchase(var branchId) {
    return FutureBuilder<List<dynamic>>(
      future: api.getMonthlyPurchaseReport(branchId),
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
                controller: controller,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.grey.shade200),
                    border: TableBorder.all(width: 1.0, color: Colors.black),
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
                                  // color: Colors.black,
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
                                      //style: TextStyle(fontSize: 6),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
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

  reportViewSalesBillByBill() {
    var dataJson = '[' +
        json.encode({
          'statementType': widget.statement.isEmpty ? '' : widget.statement,
          'sDate': widget.sDate.isEmpty ? '' : widget.sDate,
          'eDate': widget.eDate.isEmpty ? '' : widget.eDate,
          'id': widget.id ?? '',
          'Check_openingbalance': widget.ob ?? 0,
          'location': jsonEncode(location),
          'project': jsonEncode(project),
          'salesMan': 0
        }) +
        ']';
    return FutureBuilder<List<dynamic>>(
      future: api.fetchLedgerReport(dataJson),
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
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                        child: Text(widget.name +
                            ' Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
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
                          for (int i = 0; i < tableColumn.length; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  tableColumn[i],
                                  style: const TextStyle(
                                      // color: Colors.black,
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
                                          //style: TextStyle(fontSize: 6),
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

  reportViewGroupList() {
    var dataJson = '[' +
        json.encode({
          'statementType': widget.statement.isEmpty ? '' : widget.statement,
          'sDate': widget.sDate.isEmpty ? '' : widget.sDate,
          'eDate': widget.eDate.isEmpty ? '' : widget.eDate,
          'id': widget.id ?? '',
          'Check_openingBalance': widget.ob ?? 0,
          'location': jsonEncode(location),
          'city': jsonEncode(project),
          'salesMan': widget.salesMan.isNotEmpty ? widget.salesMan : '0',
          'hName': ''
        }) +
        ']';
    return FutureBuilder<List<dynamic>>(
      future: api.fetchGroupReport(dataJson),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            tableColumn = data[0].keys.toList();
            Map<String, dynamic> totalData = {};
            for (int i = 0; i < tableColumn.length; i++) {
              var cell = '';
              if (tableColumn[i].toLowerCase() == ('debit') ||
                  tableColumn[i].toLowerCase() == ('opbalance') ||
                  tableColumn[i].toLowerCase() == ('credit') ||
                  tableColumn[i].toLowerCase() == ('balance') ||
                  tableColumn[i].toLowerCase() == ('total')) {
                cell = data
                    .fold(
                        0.0,
                        (a, b) =>
                            a +
                            (double.tryParse(b[tableColumn[i]].toString()) ??
                                0))
                    .toStringAsFixed(2);
              }
              if (i == 0) {
                cell = 'Total';
              }
              totalData[tableColumn[i]] = cell;
            }
            if (totalData.isNotEmpty) {
              data.add(totalData);
            }
            _data = data;
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                        child: Text(widget.name +
                            ' Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.grey.shade200),
                        border:
                            TableBorder.all(width: 1.0, color: Colors.black),
                        columnSpacing: 12,
                        dataRowHeight: 20,
                        // dividerThickness: 1,
                        headingRowHeight: 30,
                        columns: [
                          for (int i = 0; i < tableColumn.length; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  tableColumn[i],
                                  style: const TextStyle(
                                      // color: Colors.black,
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
                                          //style: TextStyle(fontSize: 6),
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

  reportViewEmployeeList() {
    return FutureBuilder<List<dynamic>>(
      future: api.getEmployeeList(),
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
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                          for (int i = 0; i < tableColumn.length; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  tableColumn[i],
                                  style: const TextStyle(
                                      // color: Colors.black,
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
                                          //style: TextStyle(fontSize: 6),
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

  reportVoucherList() {
    String ledCode = widget.id;
    String location =
        widget.branchId.isNotEmpty ? widget.branchId[0].toString() : '1';
    String groupCode = '0';
    String project = '0';
    String fromDate = widget.sDate.isNotEmpty ? widget.sDate : '2000-01-01';
    String toDate = widget.eDate.isNotEmpty ? widget.eDate : '2000-01-01';
    String sDate = widget.sDate.isNotEmpty ? widget.sDate : '2000-01-01';
    String eDate = widget.eDate.isNotEmpty ? widget.eDate : '2000-01-01';
    String where = '';
    String cashId = '0';
    String salesman = widget.salesMan.isNotEmpty ? widget.salesMan : '0';
    String statement = widget.type == 'PaymentList'
        ? 'PvListSummery'
        : widget.type == 'ReceiptList'
            ? 'RvListSummery'
            : widget.type == 'JournalList'
                ? 'JvList'
                : '';
    String areaId = widget.area.isNotEmpty ? widget.area : '0';
    String routeId = widget.route.isNotEmpty ? widget.route : '0';
    return FutureBuilder<List<dynamic>>(
      future: api.getVoucherList(
          ledCode,
          location,
          groupCode,
          project,
          fromDate,
          toDate,
          sDate,
          eDate,
          where,
          cashId,
          salesman,
          statement,
          areaId,
          routeId),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            tableColumn = data[0].keys.toList();
            Map<String, dynamic> totalData = {};
            for (int i = 0; i < tableColumn.length; i++) {
              var cell = '';
              if (tableColumn[i].toLowerCase() == ('discount') ||
                  tableColumn[i].toLowerCase() == ('amount') ||
                  tableColumn[i].toLowerCase() == ('total')) {
                cell = data
                    .fold(
                        0.0,
                        (a, b) =>
                            a +
                            (double.tryParse(b[tableColumn[i]].toString()) ??
                                0))
                    .toStringAsFixed(2);
              }
              if (i == 0) {
                cell = 'Total';
              }
              totalData[tableColumn[i]] = cell;
            }
            if (totalData.isNotEmpty) {
              data.add(totalData);
            }
            _data = data;
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                          for (int i = 0; i < tableColumn.length; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  tableColumn[i],
                                  style: const TextStyle(
                                      // color: Colors.black,
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
                                          //style: TextStyle(fontSize: 6),
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

  reportViewCustomerCardList() {
    return FutureBuilder<List<dynamic>>(
      future: api.getCustomerCardList(),
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
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                          for (int i = 0; i < tableColumn.length; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  tableColumn[i],
                                  style: const TextStyle(
                                      // color: Colors.black,
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
                                          //style: TextStyle(fontSize: 6),
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

  reportViewLedgerList() {
    return FutureBuilder<List<dynamic>>(
      future: api.getLedgerListByType('Ledger_List'),
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
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                          for (int i = 0; i < tableColumn.length; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  tableColumn[i],
                                  style: const TextStyle(
                                      // color: Colors.black,
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
                                          //style: TextStyle(fontSize: 6),
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

  reportViewClosingReport() {
    var dataJson = {
      'statementType': widget.statement.isEmpty ? '' : widget.statement,
      'sDate': widget.sDate.isEmpty ? '' : widget.sDate,
      'eDate': widget.eDate.isEmpty ? '' : widget.eDate,
      'location': location[0]['id'].toString()
    };
    return FutureBuilder<List<dynamic>>(
      future: widget.statement == 'AsperMart'
          ? api.fetchClosingReportAll(dataJson)
          : api.fetchClosingReport(dataJson),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            _data = data;
            List<dynamic> incomeData = [];
            List<dynamic> expenseData = [];
            List<dynamic> totalData = [];
            List<double> incomeListTotal = [];
            List<dynamic> incomeCollection = [];
            List<double> expenseListTotal = [];
            if (widget.statement == 'AsperMart') {
              List<dynamic> _incomeData = data[7];
              if (_incomeData.isNotEmpty) {
                List<double> listTotal = [];
                Map<String, dynamic> m = {"Particular": "Opening Balance"};
                m.addAll(_incomeData[0]);
                incomeData.add(m);
                Map<String, dynamic> m1 = {"Particular": "Collection"};
                m1.addAll(_incomeData[1]);
                incomeData.add(m1);
                List<String> _tempColumnTotal = _incomeData[0].keys.toList();
                for (int dataIndex = 0;
                    dataIndex < _incomeData.length;
                    dataIndex++) {
                  for (int i = 0; i < _tempColumnTotal.length; i++) {
                    Map _map = _incomeData[dataIndex];
                    var aa = _map[_tempColumnTotal[i].toString()] ?? 0;
                    double a2 = double.tryParse(aa.toString());
                    if (dataIndex == 0) {
                      listTotal.add(a2);
                    } else {
                      double oldItem = listTotal.elementAt(i);
                      listTotal.removeAt(i);
                      listTotal.insert(i, oldItem + a2);
                    }
                  }
                }
                Map<String, dynamic> mTotal = {"Particular": "Total"};
                int index = 0;
                for (var _n in _tempColumnTotal) {
                  mTotal[_n] = listTotal[index];
                  index++;
                }
                incomeData.add(mTotal);

                incomeCollection.add(incomeData.elementAt(1));
                incomeListTotal = listTotal;
              }
              List<dynamic> _expenseData = data[8];
              if (_expenseData.isNotEmpty) {
                List<double> listTotal = [];
                List<String> _tempColumnTotal = _expenseData[0].keys.toList();
                for (int dataIndex = 0;
                    dataIndex < _expenseData.length;
                    dataIndex++) {
                  for (int i = 1; i < _tempColumnTotal.length; i++) {
                    Map _map = _expenseData[dataIndex];
                    var aa = _map[_tempColumnTotal[i].toString()] ?? 0;
                    double a2 = double.tryParse(aa.toString());
                    if (dataIndex == 0) {
                      listTotal.add(a2);
                    } else {
                      double oldItem = listTotal.elementAt(i - 1);
                      listTotal.removeAt(i - 1);
                      listTotal.insert(i - 1, oldItem + a2);
                    }
                  }
                }
                Map<String, dynamic> mTotal = {"LedName": "Total"};

                for (int index = 1; index < _tempColumnTotal.length; index++) {
                  var _n = _tempColumnTotal[index];
                  mTotal[_n] = listTotal[index - 1];
                }
                expenseData = _expenseData;
                expenseData.add(mTotal);

                expenseListTotal = listTotal;
              }
              List<dynamic> _totalData = data[9];
              if (_totalData.isNotEmpty) {
                //todaycoll = incomecolletion row amount - exptotal
                //total = income total - expense total
                List<String> _tempColumnTotal = _totalData[0].keys.toList();
                for (int dataIndex = 0;
                    dataIndex < _totalData.length;
                    dataIndex++) {
                  Map _map = _totalData[dataIndex];

                  if (dataIndex == 0) {
                    Map<String, dynamic> mTotal = {
                      "Particulars": "Today Collection"
                    };
                    for (int index = 1;
                        index < _tempColumnTotal.length;
                        index++) {
                      var _n = _tempColumnTotal[index];
                      Map b0 = incomeCollection[0];
                      double b1 = b0[_n] != null
                          ? double.tryParse(b0[_n].toString())
                          : 0;
                      double b2 = expenseListTotal.isNotEmpty
                          ? expenseListTotal[index - 1]
                          : 0;
                      mTotal[_n] = b1 - b2;
                    }
                    totalData.add(mTotal);
                  } else {
                    Map<String, dynamic> mTotal = {
                      "Particulars": "Total Balance"
                    };
                    for (int index = 1;
                        index < _tempColumnTotal.length;
                        index++) {
                      var _n = _tempColumnTotal[index];
                      mTotal[_n] = incomeListTotal[index - 1] -
                          (expenseListTotal.isNotEmpty
                              ? expenseListTotal[index - 1]
                              : 0);
                    }
                    totalData.add(mTotal);
                  }
                }
                // totalData = _totalData;
              }
              tableColumnIncome =
                  incomeData.isEmpty ? [] : incomeData[0].keys.toList();
              tableColumnExpense =
                  expenseData.isEmpty ? [] : expenseData[0].keys.toList();
              tableColumnTotal =
                  totalData.isEmpty ? [] : totalData[0].keys.toList();
            } else {
              tableColumn = data[0].keys.toList();
            }
            return widget.statement == 'AsperMart'
                ? Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      controller: controller,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                                widget.statement +
                                    ' Closing' +
                                    ' Date : From ' +
                                    DateUtil.dateDMY(widget.sDate) +
                                    ' To ' +
                                    DateUtil.dateDMY(widget.eDate),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Column(
                                children: [
                                  DataTable(
                                    border: TableBorder.all(
                                        width: 1.0,
                                        color: black,
                                        style: BorderStyle.solid),
                                    columnSpacing: 12,
                                    dataRowHeight: 20,
                                    dividerThickness: 1,
                                    headingRowHeight: 1,
                                    columns: const [
                                      DataColumn(
                                        label: Text(''),
                                      ),
                                      DataColumn(
                                        label: Text(''),
                                      ),
                                      DataColumn(
                                        label: Text(''),
                                      ),
                                      DataColumn(
                                        label: Text(''),
                                      ),
                                      DataColumn(
                                        label: Text(''),
                                      ),
                                    ],
                                    rows: [
                                      DataRow(cells: [
                                        const DataCell(Text('Opening Balance',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text(
                                          data[0][0]['Amount'] == null
                                              ? ''
                                              : data[0][0]['Amount'].toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        )),
                                        const DataCell(Text(' ')),
                                        const DataCell(Text('Cash Bank',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text(
                                            data[1][0]['Amount'] == null
                                                ? ''
                                                : data[1][0]['Amount']
                                                    .toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold))),
                                      ]),
                                      const DataRow(cells: [
                                        DataCell(Text('Sales',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text('Purchase',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text('Stock',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text('Receivable',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text('Payable',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                      ]),
                                      DataRow(cells: [
                                        DataCell(Text(
                                            data[2][0][''] == null
                                                ? ''
                                                : data[2][0][''].toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text(
                                            data[3][0]['Amount'] == null
                                                ? ''
                                                : data[3][0]['Amount']
                                                    .toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text(
                                            data[4][0][''] == null
                                                ? ''
                                                : data[4][0][''].toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text(
                                            data[5][0]['Amount'] == null
                                                ? ''
                                                : data[5][0]['Amount']
                                                    .toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text(
                                            data[6][0]['Amount'] == null
                                                ? ''
                                                : data[6][0]['Amount']
                                                    .toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold))),
                                      ]),
                                    ],
                                  ),
                                  const SizedBox(
                                      child: Center(
                                          child: Text('INCOME',
                                              style: TextStyle(
                                                  backgroundColor: blue,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      height: 30,
                                      width: 350),
                                  tableColumnIncome.isEmpty
                                      ? const Center()
                                      : DataTable(
                                          border: TableBorder.all(
                                              width: 1.0,
                                              color: black,
                                              style: BorderStyle.solid),
                                          columnSpacing: 12,
                                          dataRowHeight: 20,
                                          dividerThickness: 1,
                                          headingRowHeight: 30,
                                          columns: [
                                            for (int i = 0;
                                                i < tableColumnIncome.length;
                                                i++)
                                              DataColumn(
                                                label: Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    tableColumnIncome[i],
                                                    style: const TextStyle(
                                                        // color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                          ],
                                          rows: incomeData
                                              .map(
                                                (values) => DataRow(
                                                  cells: [
                                                    for (int i = 0;
                                                        i < values.length;
                                                        i++)
                                                      DataCell(
                                                        Text(
                                                          values[tableColumnIncome[
                                                                      i]] !=
                                                                  null
                                                              ? values[
                                                                      tableColumnIncome[
                                                                          i]]
                                                                  .toString()
                                                              : '',
                                                          softWrap: true,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          //style: TextStyle(fontSize: 6),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              )
                                              .toList(),
                                        ),
                                  const SizedBox(
                                      child: Center(
                                          child: Text('EXPENSE',
                                              style: TextStyle(
                                                  backgroundColor: blue,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      height: 30,
                                      width: 350),
                                  tableColumnExpense.isEmpty
                                      ? const Center()
                                      : DataTable(
                                          border: TableBorder.all(
                                              width: 1.0,
                                              color: black,
                                              style: BorderStyle.solid),
                                          columnSpacing: 12,
                                          dataRowHeight: 20,
                                          dividerThickness: 1,
                                          headingRowHeight: 30,
                                          columns: [
                                            for (int i = 0;
                                                i < tableColumnExpense.length;
                                                i++)
                                              DataColumn(
                                                label: Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    tableColumnExpense[i],
                                                    style: const TextStyle(
                                                        // color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                          ],
                                          rows: expenseData
                                              .map(
                                                (values) => DataRow(
                                                  cells: [
                                                    for (int i = 0;
                                                        i < values.length;
                                                        i++)
                                                      DataCell(
                                                        Text(
                                                          values[tableColumnExpense[
                                                                      i]] !=
                                                                  null
                                                              ? values[
                                                                      tableColumnExpense[
                                                                          i]]
                                                                  .toString()
                                                              : '',
                                                          softWrap: true,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          //style: TextStyle(fontSize: 6),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              )
                                              .toList(),
                                        ),
                                  const SizedBox(
                                      child: Center(
                                          child: Text('TOTAL',
                                              style: TextStyle(
                                                  backgroundColor: blue,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      height: 30,
                                      width: 350),
                                  tableColumnTotal.isEmpty
                                      ? const Center()
                                      : DataTable(
                                          border: TableBorder.all(
                                              width: 1.0,
                                              color: black,
                                              style: BorderStyle.solid),
                                          columnSpacing: 12,
                                          dataRowHeight: 20,
                                          dividerThickness: 1,
                                          headingRowHeight: 30,
                                          columns: [
                                            for (int i = 0;
                                                i < tableColumnTotal.length;
                                                i++)
                                              DataColumn(
                                                label: Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    tableColumnTotal[i],
                                                    style: const TextStyle(
                                                        // color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                          ],
                                          rows: totalData
                                              .map(
                                                (values) => DataRow(
                                                  cells: [
                                                    for (int i = 0;
                                                        i < values.length;
                                                        i++)
                                                      DataCell(
                                                        Text(
                                                          values[tableColumnTotal[
                                                                      i]] !=
                                                                  null
                                                              ? values[
                                                                      tableColumnTotal[
                                                                          i]]
                                                                  .toString()
                                                              : '',
                                                          softWrap: true,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          //style: TextStyle(fontSize: 6),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              )
                                              .toList(),
                                        ),
                                  const SizedBox(
                                      child: Center(
                                          child: Text('',
                                              style: TextStyle(
                                                  backgroundColor: blue,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      height: 30,
                                      width: 350),
                                  DataTable(
                                    border: TableBorder.all(
                                        width: 0.5,
                                        color: grey,
                                        style: BorderStyle.solid),
                                    columnSpacing: 12,
                                    dataRowHeight: 20,
                                    dividerThickness: 1,
                                    headingRowHeight: 1,
                                    columns: const [
                                      DataColumn(
                                        label: Text(''),
                                      ),
                                      DataColumn(
                                        label: Text(''),
                                      ),
                                    ],
                                    rows: [
                                      const DataRow(cells: [
                                        DataCell(Text('Cash in Hand',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text('Bank In Hand',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))),
                                      ]),
                                      DataRow(cells: [
                                        DataCell(Text(
                                          data[10][0]['Amount'] == null
                                              ? ''
                                              : data[10][0]['Amount']
                                                  .toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        )),
                                        DataCell(Text(
                                            data[11][0]['Amount'] == null
                                                ? ''
                                                : data[11][0]['Amount']
                                                    .toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold))),
                                      ]),
                                    ],
                                  ),
                                ],
                              )),
                          // SizedBox(height: 500),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      controller: controller,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: Text(widget.name +
                                  ' Date : From ' +
                                  DateUtil.dateDMY(widget.sDate) +
                                  ' To ' +
                                  DateUtil.dateDMY(widget.eDate))),
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
                                            // color: Colors.black,
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
                                                //style: TextStyle(fontSize: 6),
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

  reportViewProfitAndLossAccount() {
    var dataJson = {
      'statementType': widget.statement.isEmpty ? '' : widget.statement,
      'sDate': widget.sDate.isEmpty ? '' : widget.sDate,
      'eDate': widget.eDate.isEmpty ? '' : widget.eDate,
      'stockValuation': widget.name.isEmpty ? '' : widget.name,
      'code': '',
      'location': widget.branchId[0].toString().isNotEmpty
          ? widget.branchId[0].toString()
          : '1',
      'fyId': currentFinancialYear.id
    };
    return FutureBuilder<List<dynamic>>(
      future: api.fetchProfitAndLossAccount(dataJson),
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
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                        child: Text(widget.name +
                            ' Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
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
                          for (int i = 0; i < tableColumn.length; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  tableColumn[i],
                                  style: const TextStyle(
                                      // color: Colors.black,
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
                                          //style: TextStyle(fontSize: 6),
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

  reportViewBalanceSheet() {
    var dataJson = '[' +
        json.encode({
          'statementType': widget.statement.isEmpty ? '' : widget.statement,
          'sDate': widget.sDate.isEmpty ? '' : widget.sDate,
          'eDate': widget.eDate.isEmpty ? '' : widget.eDate,
          'stockValuation': widget.name.isEmpty ? '' : widget.name,
          'code': ''
        }) +
        ']';
    return FutureBuilder<List<dynamic>>(
      future: api.fetchBalanceSheet(dataJson),
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
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                        child: Text(widget.name +
                            ' Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
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
                          for (int i = 0; i < tableColumn.length; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  tableColumn[i],
                                  style: const TextStyle(
                                      // color: Colors.black,
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
                                          //style: TextStyle(fontSize: 6),
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

  Future<String> _createPDF(String title) async {
    return await makePDF(title).then((value) => savePreviewPDF(value, title));
  }

  Future<pw.Document> makePDF(String title) async {
    // var tableHeaders = [
    //   "Date",
    //   "Particulars",
    //   "Voucher",
    //   "EntryNo",
    //   "Debit",
    //   "Credit",
    //   "Balance",
    //   "Narration"
    // ];
    // tableHeaders=tableColumn;

    var data = _data;
    final pw.Document pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
        // pageFormat: PdfPageFormat.a4,
        maxPages: 100,
        header: (context) => pw.Column(children: [
              pw.Center(
                  child: pw.Column(children: [
                pw.Text(companySettings.name),
                pw.Text(companySettings.add1),
                pw.Text(companySettings.add2),
                pw.Text(companySettings.add3),
                pw.Text(companySettings.mobile),
                pw.Text(companyTaxNo.isNotEmpty
                    ? (companyTaxMode == 'INDIA'
                        ? 'GST NO : $companyTaxNo'
                        : companyTaxMode == 'AFRICA'
                            ? 'NUIT : $companyTaxNo'
                            : companyTaxMode == 'GULF'
                                ? 'TRN : $companyTaxNo'
                                : '')
                    : ''),
              ])),
              pw.Text(title,
                  style: const pw.TextStyle(color: PdfColor.fromInt(0))),

              tempLedgerData != null
                  ? pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.RichText(
                          textAlign: pw.TextAlign.left,
                          text: pw.TextSpan(
                              text: 'Ledger   : ${tempLedgerData.name}\n',
                              children: [
                                pw.TextSpan(
                                    text:
                                        'Address : ${tempLedgerData.address1}\n'),
                                pw.TextSpan(
                                    text:
                                        '                ${tempLedgerData.address2}\n'),
                                pw.TextSpan(
                                    text:
                                        '                ${tempLedgerData.address3}\n'),
                                pw.TextSpan(
                                    text:
                                        'Mobile    : ${tempLedgerData.phone}\n'),
                              ])))
                  : pw.Text(''),
              // if (context.pageNumber > 1) pw.SizedBox(height: 20)
            ]),
        build: (context) => [
              // pw.Container(
              //     child: pw.Padding(
              //         padding: const pw.EdgeInsets.all(1.0),
              //         child: pw.Column(
              //           children: [
              // pw.Header(
              //   text: title,
              //   child: pw.Text('data'),
              // ),
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
                      // pw.Column(
                      //     crossAxisAlignment: pw.CrossAxisAlignment.start,
                      //     mainAxisAlignment: pw.MainAxisAlignment.center,
                      //     children: [
                      //       pw.Padding(
                      //         padding: const pw.EdgeInsets.all(2.0),
                      //         child: pw.Text(data[i]['Particulars'],
                      //             style: const pw.TextStyle(fontSize: 6)),
                      //         // pw.Divider(thickness: 1)
                      //       ),
                      //     ]),
                      // pw.Column(
                      //     crossAxisAlignment: pw.CrossAxisAlignment.start,
                      //     mainAxisAlignment: pw.MainAxisAlignment.center,
                      //     children: [
                      //       pw.Padding(
                      //         padding: const pw.EdgeInsets.all(2.0),
                      //         child: pw.Text('${data[i]['Voucher']}',
                      //             style: const pw.TextStyle(fontSize: 6)),
                      //         // pw.Divider(thickness: 1)
                      //       )
                      //     ]),
                      // pw.Column(
                      //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                      //     mainAxisAlignment: pw.MainAxisAlignment.center,
                      //     children: [
                      //       pw.Padding(
                      //         padding: const pw.EdgeInsets.all(2.0),
                      //         child: pw.Text('${data[i]['EntryNo']}',
                      //             style: const pw.TextStyle(fontSize: 6)),
                      //         // pw.Divider(thickness: 1)
                      //       )
                      //     ]),
                      // pw.Column(
                      //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                      //     mainAxisAlignment: pw.MainAxisAlignment.center,
                      //     children: [
                      //       pw.Padding(
                      //         padding: const pw.EdgeInsets.all(2.0),
                      //         child: pw.Text('${data[i]['Debit']}',
                      //             style: const pw.TextStyle(fontSize: 6)),
                      //         // pw.Divider(thickness: 1)
                      //       )
                      //     ]),
                      // pw.Column(
                      //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                      //     mainAxisAlignment: pw.MainAxisAlignment.center,
                      //     children: [
                      //       pw.Padding(
                      //         padding: const pw.EdgeInsets.all(2.0),
                      //         child: pw.Text('${data[i]['Credit']}',
                      //             style: const pw.TextStyle(fontSize: 6)),
                      //         // pw.Divider(thickness: 1)
                      //       )
                      //     ]),
                      // pw.Column(
                      //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                      //     mainAxisAlignment: pw.MainAxisAlignment.center,
                      //     children: [
                      //       pw.Padding(
                      //         padding: const pw.EdgeInsets.all(2.0),
                      //         child: pw.Text('${data[i]['Balance']}',
                      //             style: const pw.TextStyle(fontSize: 6)),
                      //         // pw.Divider(thickness: 1)
                      //       )
                      //     ]),
                      // pw.Column(
                      //     crossAxisAlignment: pw.CrossAxisAlignment.start,
                      //     mainAxisAlignment: pw.MainAxisAlignment.center,
                      //     children: [
                      //       pw.Padding(
                      //         padding: const pw.EdgeInsets.all(2.0),
                      //         child: pw.Text('${data[i]['Narration']}',
                      //             style: const pw.TextStyle(fontSize: 6)),
                      //         // pw.Divider(thickness: 1)
                      //       )
                      //     ]),
                    ])
                ],
              ),
              // pw.Header(text: ''),
              // pw.Footer(title: pw.Text('add footer message'))
              //   ],
              // )))
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
