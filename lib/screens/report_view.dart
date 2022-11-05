// @dart = 2.9
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share/share.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportView extends StatefulWidget {
  const ReportView(this.id, this.ob, this.sDate, this.eDate, this.type,
      this.name, this.statement, this.salesMan, this.branchId,
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
  final int branchId;

  @override
  _ReportViewState createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  DioService api = DioService();
  final controller = ScrollController();
  double offset = 0;
  var _data;
  List<dynamic> location = [
    {'id': 1}
  ];
  List<dynamic> project = [
    {'id': 0}
  ];

  List<String> tableColumn = [];

  @override
  void initState() {
    controller.addListener(onScroll);
    super.initState();
    location.removeAt(0);
    location.add(({'id': widget.branchId}));
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
                    _createPDF(widget.name +
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
        body: widget.type == 'ledger' ||
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
                                            : widget.type == 'Closing Report'
                                                ? reportViewClosingReport()
                                                : widget.type == 'EmployeeList'
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
                                                                    : const Text(
                                                                        'No Report'));
  }

  reportView() {
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
                        child: Text('Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
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
                        child: Text('Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 12,
                        dataRowHeight: 20,
                        dividerThickness: 1,
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
                        child: Text('Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
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
          'Check_openingbalance': widget.ob ?? 0,
          'location': jsonEncode(location),
          'city': jsonEncode(project),
          'salesMan': 0
        }) +
        ']';
    return FutureBuilder<List<dynamic>>(
      future: api.fetchGroupReport(dataJson),
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
                        child: Text('Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
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
      future: api.getLedgerList('Ledger_List'),
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
    var dataJson = '[' +
        json.encode({
          'statementType': widget.statement.isEmpty ? '' : widget.statement,
          'sDate': widget.sDate.isEmpty ? '' : widget.sDate,
          'eDate': widget.eDate.isEmpty ? '' : widget.eDate,
          'location': location[0]['id'].toString()
        }) +
        ']';
    return FutureBuilder<List<dynamic>>(
      future: api.fetchClosingReport(dataJson),
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
                        child: Text('Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
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
                        child: Text('Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
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
                        child: Text('Date : From ' +
                            DateUtil.dateDMY(widget.sDate) +
                            ' To ' +
                            DateUtil.dateDMY(widget.eDate))),
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
              pw.Text(title,
                  style: pw.TextStyle(
                      color: const PdfColor.fromInt(0),
                      fontSize: 25,
                      fontWeight: pw.FontWeight.bold)),
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
