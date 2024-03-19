import 'dart:async';
import 'dart:convert';
// import 'dart:html' as html;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_sunmi_printer/flutter_sunmi_printer.dart';
import 'package:image/image.dart' as images;
import 'package:json_table/json_table.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sunmi_printer_service/sunmi_printer_service.dart' as sum_mi;
import 'package:sunmi_printer_service/sunmi_printer_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/rp_model.dart';
import 'package:sheraccerp/models/sales_bill.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/bt_print.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/invoice.dart';
import 'package:sheraccerp/util/number_to_word.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';

class RVPreviewShow extends StatefulWidget {
  String title = '';
  dynamic dataAll;
  RVPreviewShow({Key? key, required this.title, this.dataAll})
      : super(key: key);

  @override
  State<RVPreviewShow> createState() => _RVPreviewShowState();
}

class _RVPreviewShowState extends State<RVPreviewShow> {
  final GlobalKey _globalKey = GlobalKey();
  DioService api = DioService();
  late RPModel rvModel;
  late List<JsonTableColumn> columns;
  late CompanyInformation companySettings;
  late List<CompanySettings> settings;
  late Uint8List byteImage;
  int decimal = 2;
  int eNo = 0;
  dynamic data;
  bool _isLoading = true;
  var bill = {}, dataParticulars = [];
  String invoiceHead = '', form = '';
  double oldBalance = 0, balance = 0;

  Future<Uint8List> _capturePng() async {
    late Uint8List pngBytes;
    try {
      // print('inside');
      RenderRepaintBoundary? boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes1 = byteData!.buffer.asUint8List();
      pngBytes = resizeImage(pngBytes1);
      // var bs64 = base64Encode(pngBytes);
      // print(pngBytes);
      // print(bs64);
      // setState(() {});
      // return pngBytes;
    } catch (e) {
      debugPrint(e.toString());
    }
    return pngBytes;
  }

  Uint8List resizeImage(Uint8List data) {
    Uint8List resizedData = data;
    images.Image? img = images.decodeImage(data);
    // images.Image img1 = images.fill(0);
    images.Image? resized = images.copyResize(img!, width: 500, height: 500);
    resizedData = images.encodePng(resized) as Uint8List;
    return resizedData;
  }

  @override
  void initState() {
    super.initState();
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();

    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    decimal = (ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2)!;
    columns = [
      JsonTableColumn("particulars", label: "Particulars"),
      JsonTableColumn("Amount", label: "Amount")
    ];

    var title = widget.title;
    var value = widget.dataAll;
    if (value != null) {
      setState(() {
        data = value;
        // dataInformation = value['Information'][0];
        // customerBalance = dataInformation['Balance'].toString();
        // dataParticularsAll = value['Particulars'];

        bill = widget.dataAll[0][0];
        form = widget.dataAll[1];
        eNo = int.tryParse(bill['entryNo'].toString()) ?? 0;
        dataParticulars = jsonDecode(bill['particular']);
        // dataParticulars = bill['particular'];
        // var ledgerName = bill['name'];//oldBalance: 897823.00 Cr
        var bal = bill['oldBalance'].toString().split(' ');
        if (bal[1] == 'Dr') {
          oldBalance = double.tryParse(bal[0].toString()) ?? 0;
          balance = oldBalance - bill['total'];
        } else {
          oldBalance = (double.tryParse(bal[0].toString())! * (-1));
          balance = oldBalance - bill['total'];
        }
        invoiceHead = form == 'RECEIPT'
            ? Settings.getValue<String>('key-receipt-voucher-head', 'RECEIPT')
                    .isNotEmpty
                ? Settings.getValue<String>(
                    'key-receipt-voucher-head', 'RECEIPT')
                : 'Receipt Invoice'
            : Settings.getValue<String>('key-payment-voucher-head', 'PAYMENT')
                    .isNotEmpty
                ? Settings.getValue<String>(
                    'key-payment-voucher-head', 'PAYMENT')
                : 'Payment Invoice';

        _isLoading = false;

        _createPDF(title + '_ref_$eNo', companySettings, settings, bill,
                dataParticulars, invoiceHead, form, dataParticulars)
            .then((value) => pdfPath = value);
      });
    }
  }

  Future<void> requestBluetoothPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
    ].request();

    if (statuses[Permission.bluetooth] == PermissionStatus.granted) {
      debugPrint('Permission Granted');
    } else if (statuses[Permission.bluetooth] == PermissionStatus.denied) {
      debugPrint('Permission denied');
    } else if (statuses[Permission.bluetooth] ==
        PermissionStatus.permanentlyDenied) {
      debugPrint('Permission Permanently Denied');
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    var title = widget.title;
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () {
                  setState(
                    () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PDFScreen(
                                pathPDF: pdfPath,
                                subject: title,
                                text: 'this is ' + title,
                              )));
                    },
                  );
                }),
            IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  argumentsPass = {
                    'mode': 'selectedLedger',
                    'name': bill['name'],
                    'id': dataParticulars[0]['Ledid']
                  };
                  Navigator.pushNamed(
                    context,
                    '/select_ledger',
                  );
                }),
            // IconButton(
            //     icon: const Icon(Icons.picture_in_picture),
            //     onPressed: () {
            //       sample image for test
            //       _capturePng().then((value) async {
            //         // Path tempDir = await getTemporaryDirectzory();
            //         var tempDir = await getTemporaryDirectory();
            //         var path = '${tempDir.path}/image.png';
            //         var iss = await File(path).exists();
            //         if (iss)
            //           OpenFile.open(path);
            //         File files = await File(path).create();
            //         await files.writeAsBytesSync(value);
            //       });
            //     }),
            IconButton(
                icon: const Icon(Icons.print),
                onPressed: () {
                  _capturePng().then((value) => {
                        setState(() {
                          byteImage = value;

                          askPrintDevice(
                              context,
                              title + '_ref_${bill['entryNo']}',
                              companySettings,
                              settings,
                              data,
                              byteImage,
                              '');
                        })
                      });
                })
          ],
        ),
        body: eNo > 0
            ? previewWidget(
                context,
                _isLoading,
                companySettings,
                bill,
                settings,
                dataParticulars,
                invoiceHead,
                form,
                oldBalance,
                balance)
            // webView()
            : const Center(child: Text('Not Found')));
  }

  Future<ui.Image> loadImage(Uint8List img) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  var pdfPath = '';
  generatepdfWidget(title) {
    // return Container(child: pw.PdfPreview(
    //     maxPageWidth: 700,
    //     build: (format) => examples[_tab].builder(format, _data),
    //     actions: actions,
    //     onPrinted: _showPrintedToast,
    //     onShared: _showSharedToast,
    //   ),);

    // Navigator.of(context).push(MaterialPageRoute(
    //     builder: (_) => PDFScreen(
    //           pathPDF: value,
    //           subject: title,
    //           text: 'this is ' + title,
    //         )));
  }

  webView() {
    return _isLoading
        ? const Loading()
        : Column(children: [
            Expanded(
                child: RepaintBoundary(
              key: _globalKey,
              child: WebView(
                  initialUrl: '',
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (contr) {
                    debugPrint(bill.toString());
                    String dataHtml = '''
                      <html>
                          <body>
                      <style>
                      .total-value {
                          font-size:14px;font-weight: bold
                      }
                      .total-value1 {
                          font-size:16px;font-weight: bold
                      }
                      .total-line{
                        font-size:14px;font-weight: bold
                      }
                      table.tableA{
                        border-collapse: collapse;
                      }
                      table.tableA td, 
                      table.tableA th {
                          border: 1px solid black;
                          padding: 10px;
                        }
                      </style>
                      <h2 align="center" >${companySettings.name}</h2>
                            <table align="center" width="100%" >
                              <tr><td width="16.7%" align="center">${companySettings.add1}</td></tr>
                              <tr><td width="16.7%" align="center">${companySettings.add2}</td></tr>
                              <tr><td width="16.7%" align="center">Tel : ${companySettings.telephone + ',' + companySettings.mobile}</td></tr>
                              <tr><td width="16.7%" align="center">${companyTaxMode == 'INDIA' ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}' : 'TRN : ${ComSettings.getValue('GST-NO', settings)}'}</td></tr>
                            </table>
                      <table width="100%">
                            <tr>
                    <th align="center"><u>$invoiceHead</u></th>
                            </tr>
                          </table>
                          <br>
                          <table width="100%">
                    <tr>
                    <td align="left">VoucherNo : ${bill['entryNo']}<td align="right">Date : ${DateUtil.dateDMY(bill['date'])}
                    
                    </tr>
                          </table>
                          
                          <table id="items" class="tableA">
                      <tr>
                          <th width="64%" align="center"><b>Particulars</b></th>
                          <th width="8%" align="center"><b>Amount</b></th>
                          <th width="10%" align="center"><b>Discount</b></th>
                          <th width="10%" align="center"><b>Total</b></th>
                      </tr>
        <tr class="item-row">
        <td width="64%" align="left">${bill['name']}<br />${dataParticulars[0]['narration'].toString()}</td>
        <td width="6%" align="right">${double.tryParse(dataParticulars[0]['amount'].toString())!.toStringAsFixed(decimal)}</td>
        <td width="10%" align="right">${double.tryParse(dataParticulars[0]['discount'].toString())!.toStringAsFixed(decimal)}</td>
        <td width="10%" align="right">${double.tryParse(dataParticulars[0]['total'].toString())!.toStringAsFixed(decimal)}</td>
      </tr>
                          </table>
                          <table width="100%">
                                         <tr>
                         <td style="font-size:10px;"> Amount in Words: ${NumberToWord().convertDouble('en', double.tryParse(bill['total'].toString()))}</td>
                         
                       </tr>
                       </table>
                       <br>
                           <table width="100%" >
                           <tr>
                       <td style="font-size:10px;" align="left"> Old Balance : ${oldBalance.toStringAsFixed(decimal)}</td>
                       <td style="font-size:10px;" align="right"> Balance : ${balance.toStringAsFixed(decimal)}</td>
                       </tr>
                           </table>
                           <br>
                           <table align="center" width="80%" >
                       <tr>
                         <td width="16.7%" align="center" style="font-size:9px;">${bill['message'].toString().isNotEmpty ? bill['message'].toString().isNotEmpty : 'Thank you'}</td>
                       </tr>
                           </table>
                        
                            </body>
                        </html>
                        ''';
                    contr.loadUrl(Uri.dataFromString(dataHtml,
                            mimeType: 'text/html', encoding: utf8)
                        .toString());
                  }),
            )),
          ]);
  }

  String uint8ListTob64(Uint8List uint8list) {
    String base64String = base64Encode(uint8list);
    String header = "data:image/png;base64,";
    return header + base64String;
  }

  // showData() {
  //   var invoiceHead = salesTypeData.type == 'SALES-ES'
  //       ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
  //       : salesTypeData.type == 'SALES-Q'
  //           ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
  //           : salesTypeData.type == 'SALES-O'
  //               ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
  //               : Settings.getValue<String>(
  //                   'key-sales-invoice-head', 'INVOICE');
  //   return _isLoading
  //       ? const Loading()
  //       : taxSale
  //           ? SingleChildScrollView(
  //               padding: const EdgeInsets.all(2.0),
  //               child: Padding(
  //                 padding: const EdgeInsets.all(5.0),
  //                 child: Column(
  //                   children: [
  //                     Text(invoiceHead,
  //                         style: const TextStyle(
  //                             color: Colors.black,
  //                             fontSize: 25,
  //                             fontWeight: FontWeight.bold)),
  //                     /*company*/
  //                     Row(
  //                       children: [
  //                         Text(companySettings.name,
  //                             style: const TextStyle(
  //                                 color: Colors.black,
  //                                 fontSize: 22,
  //                                 fontWeight: FontWeight.bold)),
  //                       ],
  //                     ),
  //                     Row(
  //                       children: [
  //                         Text(companySettings.add1 +
  //                             ',' +
  //                             companySettings.add2),
  //                       ],
  //                     ),
  //                     Row(
  //                       children: [
  //                         Text(companySettings.telephone +
  //                             ',' +
  //                             companySettings.mobile),
  //                       ],
  //                     ),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(ComSettings.getValue('GST-NO', settings)),
  //                         Text('Date : ' +
  //                             DateUtil.dateDMY(dataInformation['DDate'])),
  //                       ],
  //                     ),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(companySettings.pin),
  //                         Text('Voucher: ' + dataInformation['InvoiceNo']),
  //                       ],
  //                     ),
  //                     /*customer*/
  //                     const Text(' '),
  //                     Row(
  //                       children: [
  //                         const Text('BILL To :- ',
  //                             style: TextStyle(
  //                                 color: Colors.black,
  //                                 // fontSize: 19,
  //                                 fontWeight: FontWeight.bold)),
  //                         Text(dataInformation['ToName'],
  //                             style: const TextStyle(
  //                                 color: Colors.black,
  //                                 // fontSize: 19,
  //                                 fontWeight: FontWeight.bold))
  //                       ],
  //                     ),
  //                     Row(
  //                       children: [
  //                         Text((dataInformation['Add1'] +
  //                             ',' +
  //                             dataInformation['Add2'])),
  //                       ],
  //                     ),
  //                     companyTaxMode == 'INDIA'
  //                         ? Row(
  //                             children: [
  //                               Text(dataInformation['Add4']),
  //                             ],
  //                           )
  //                         : Row(
  //                             children: [
  //                               Text('T-No :${dataInformation['gstno']}'),
  //                             ],
  //                           ),
  //                     Row(
  //                       children: [
  //                         Text(dataInformation['Add3']),
  //                       ],
  //                     ),
  //                     JsonTable(
  //                       dataParticulars,
  //                       columns:
  //                           companyTaxMode == 'INDIA' ? columnsGST : columnsVAT,
  //                       // showColumnToggle: true,
  //                       allowRowHighlight: true,
  //                       rowHighlightColor: Colors.yellow[500].withOpacity(0.7),
  //                       // paginationRowCount: 4,
  //                       onRowSelect: (index, map) {
  //                         // print(index);
  //                         // print(map);
  //                       },
  //                     ),
  //                     const SizedBox(
  //                       height: 40.0,
  //                     ),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.end,
  //                       children: [
  //                         Text('SUB TOTAL : ${dataInformation['GrossValue']}'),
  //                       ],
  //                     ),
  //                     companyTaxMode == 'INDIA'
  //                         ? Row(
  //                             mainAxisAlignment: MainAxisAlignment.end,
  //                             children: [
  //                               Text(
  //                                   'CGST : ${dataInformation['CGST']} SGST : ${dataInformation['SGST']} = ${(dataInformation['CGST'] + dataInformation['SGST'])}'),
  //                             ],
  //                           )
  //                         : Row(
  //                             mainAxisAlignment: MainAxisAlignment.end,
  //                             children: [
  //                               Text('VAT : ${dataInformation['IGST']}'),
  //                             ],
  //                           ),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.end,
  //                       children: [
  //                         Text('TOTAL : ${dataInformation['GrandTotal']}'),
  //                       ],
  //                     ),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.end,
  //                       children: [
  //                         Text('PAID : ${dataInformation['CashReceived']}'),
  //                       ],
  //                     ),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.end,
  //                       children: [
  //                         Text('TOTAL DUE : ${dataInformation['GrandTotal']}',
  //                             style: const TextStyle(
  //                                 color: Colors.black,
  //                                 fontSize: 19,
  //                                 fontWeight: FontWeight.bold)),
  //                       ],
  //                     ),
  //                     Text(data['message'])
  //                   ],
  //                 ),
  //               ))
  //           : SingleChildScrollView(
  //               padding: const EdgeInsets.all(2.0),
  //               child: Padding(
  //                 padding: const EdgeInsets.all(5.0),
  //                 child: Column(
  //                   children: [
  //                     Text(invoiceHead,
  //                         style: const TextStyle(
  //                             color: Colors.black,
  //                             fontSize: 25,
  //                             fontWeight: FontWeight.bold)),
  //                     // /*company*/
  //                     // Row(
  //                     //   children: [
  //                     //     Text(companySettings.name'],
  //                     //         style: TextStyle(
  //                     //             color: Colors.black,
  //                     //             fontSize: 22,
  //                     //             fontWeight: FontWeight.bold)),
  //                     //   ],
  //                     // ),
  //                     // Row(
  //                     //   children: [
  //                     //     Text(companySettings.add1'] +
  //                     //         ',' +
  //                     //         companySettings.add2']),
  //                     //   ],
  //                     // ),
  //                     // Row(
  //                     //   children: [
  //                     //     Text(companySettings.telephone'] +
  //                     //         ',' +
  //                     //         companySettings.mobile']),
  //                     //   ],
  //                     // ),
  //                     // Row(
  //                     //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     //   children: [
  //                     //     Text(Settings.getValue('GST-NO', settings)),
  //                     //     Text('Date : ' + DateUtil.dateDMY(dataInformation['DDate'])),
  //                     //   ],
  //                     // ),
  //                     // Row(
  //                     //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     //   children: [
  //                     //     Text(companySettings.pin']),
  //                     //     Text('Voucher: ' + dataInformation['InvoiceNo']),
  //                     //   ],
  //                     // ),
  //                     /*customer*/
  //                     // Container(child: Text(' ')
  //                     // ),
  //                     Row(
  //                       children: [
  //                         const Text('BILL To :- ',
  //                             style: TextStyle(
  //                                 color: Colors.black,
  //                                 // fontSize: 19,
  //                                 fontWeight: FontWeight.bold)),
  //                         Text(dataInformation['ToName'],
  //                             style: const TextStyle(
  //                                 color: Colors.black,
  //                                 // fontSize: 19,
  //                                 fontWeight: FontWeight.bold))
  //                       ],
  //                     ),
  //                     Row(
  //                       children: [
  //                         Text((dataInformation['Add1'] +
  //                             ',' +
  //                             dataInformation['Add2'])),
  //                       ],
  //                     ),
  //                     JsonTable(
  //                       dataParticulars,
  //                       columns: columns,
  //                       // showColumnToggle: true,
  //                       allowRowHighlight: true,
  //                       rowHighlightColor: Colors.yellow[500].withOpacity(0.7),
  //                       // paginationRowCount: 4,
  //                       onRowSelect: (index, map) {
  //                         // print(index);
  //                         // print(map);
  //                       },
  //                     ),
  //                     const SizedBox(
  //                       height: 40.0,
  //                     ),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.end,
  //                       children: [
  //                         Text('SUB TOTAL : ${dataInformation['GrossValue']}'),
  //                       ],
  //                     ),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.end,
  //                       children: [
  //                         Text('TOTAL : ${dataInformation['GrandTotal']}'),
  //                       ],
  //                     ),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.end,
  //                       children: [
  //                         Text('PAID : ${dataInformation['CashReceived']}'),
  //                       ],
  //                     ),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.end,
  //                       children: [
  //                         Text('TOTAL DUE : ${dataInformation['GrandTotal']}',
  //                             style: const TextStyle(
  //                                 color: Colors.black,
  //                                 fontSize: 19,
  //                                 fontWeight: FontWeight.bold)),
  //                       ],
  //                     ),
  //                     Text(data['message'])
  //                   ],
  //                 ),
  //               ));
  // }

  // _item() {
  //   var str = '';
  //   for (var i = 0; i < dataParticulars.length; i++) {
  //     str += '''
  //     </tr>
  //       <tr class="item-row">
  //       <td width="64%" align="left">${dataParticulars[i]['itemname']}</td>
  //       <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
  //       <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Rate'].toString()).toStringAsFixed(decimal)}</td>
  //       <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
  //     </tr>
  //     ''';
  //     totalQty += double.tryParse(dataParticulars[i]['Qty'].toString());
  //     totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
  //   }
  //   return str;
  // }

  Future<Uint8List> _captureQr() async {
    // print('inside');
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    var pngBytes = byteData!.buffer.asUint8List();
    var bs64 = base64Encode(pngBytes);
    // print(pngBytes);
    // print(bs64);
    setState(() {});
    return pngBytes;
  }
}

previewWidget(
    context,
    bool isLoading,
    CompanyInformation companySettings,
    Map bill,
    List<CompanySettings> settings,
    dataParticulars,
    invoiceHead,
    form,
    oldBalance,
    balance) {
  invoiceHead = form == 'RECEIPT'
      ? Settings.getValue<String>('key-receipt-voucher-head', 'RECEIPT')
              .isNotEmpty
          ? Settings.getValue<String>('key-receipt-voucher-head', 'RECEIPT')
          : 'Receipt voucher'.toUpperCase()
      : Settings.getValue<String>('key-payment-voucher-head', 'PAYMENT')
              .isNotEmpty
          ? Settings.getValue<String>('key-payment-voucher-head', 'PAYMENT')
          : 'Payment voucher'.toUpperCase();

  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: isLoading
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    strokeWidth: 5,
                    color: Colors.grey,
                    backgroundColor: Colors.red,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Loading",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  )
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    " ${companySettings.name}",
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 7.0, top: 5),
                    child: Column(
                      children: [
                        Visibility(
                          visible: companySettings.mobile.isNotEmpty,
                          child: Text(
                            companySettings.mobile,
                            style: const TextStyle(fontSize: 8),
                          ),
                        ),
                        Visibility(
                          visible: companySettings.add1.isNotEmpty,
                          child: Text(
                            companySettings.add1,
                            style: const TextStyle(fontSize: 8),
                          ),
                        ),
                        Visibility(
                          visible: companySettings.add2.isNotEmpty,
                          child: Text(
                            companySettings.add2,
                            style: const TextStyle(fontSize: 8),
                          ),
                        ),
                        Visibility(
                          visible: companySettings.email.isNotEmpty,
                          child: Text(
                            companySettings.email,
                            style: const TextStyle(fontSize: 8),
                          ),
                        ),
                        companyTaxMode == 'INDIA'
                            ? Text(
                                'GST No : ${ComSettings.getValue('GST-NO', settings)}',
                                style: const TextStyle(
                                    fontSize: 8, fontWeight: FontWeight.bold),
                              )
                            : Text(
                                "TRN : ${ComSettings.getValue('GST-NO', settings)}",
                                style: const TextStyle(
                                    fontSize: 8, fontWeight: FontWeight.bold),
                              )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "No: ${bill["entryNo"]}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      Column(
                        children: [
                          Text(
                            "Date: ${DateUtil.dateDMY(bill['date'])}",
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  form == 'RECEIPT'
                      ? const Text(
                          "RECEIPT VOUCHER",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        )
                      : const Text(
                          "PAYMENT VOUCHER",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                  const SizedBox(
                    height: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                              width: 130,
                              child: form == 'RECEIPT'
                                  ? const Text(
                                      "Recieved With Thanks From",
                                      style: TextStyle(fontSize: 10),
                                    )
                                  : const Text(
                                      "Paid To",
                                      style: TextStyle(fontSize: 10),
                                    )),
                          const SizedBox(
                            width: 20,
                          ),
                          Text(
                            "${bill["name"]}",
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 130,
                            child: Text(
                              "the sumof rupees",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: Text(
                              NumberToWord().convertDouble('en',
                                  double.tryParse(bill['total'].toString())),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: const [
                          SizedBox(
                            width: 130,
                            child: Text(
                              "By Cash/Cheque/DD No",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            "",
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 130,
                            child: Text(
                              "towards",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Text(
                            dataParticulars[0]['narration'].toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        height: 40,
                        width: 180,
                        decoration: BoxDecoration(border: Border.all()),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 50,
                              color: Colors.black,
                            ),
                            Text(
                              "${bill["total"].toStringAsFixed(2)} ",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "All Cheque/DD are subject to realisation",
                            style: TextStyle(fontSize: 8),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Visibility(
                            visible: oldBalance <= 0 && balance <= 0,
                            child: Column(
                              children: const [
                                SizedBox(
                                  height: 50,
                                ),
                                Text(
                                  "Receiver Signature   ",
                                  style: TextStyle(fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Visibility(
                        visible: oldBalance > 0 || balance > 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          height: 50,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(border: Border.all()),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 100,
                                        child: Text(
                                          "Old Balance    :",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      Text(
                                        "${oldBalance.toStringAsFixed(2)}",
                                        style: const TextStyle(fontSize: 11),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const SizedBox(
                                        width: 100,
                                        child: Text(
                                          "Balance           :",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      Text(
                                        "${balance.toStringAsFixed(2)}",
                                        style: const TextStyle(fontSize: 11),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: const [
                                  Text(
                                    "Receiver Signature   ",
                                    style: TextStyle(fontSize: 8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${bill['message']}",
                    style: const TextStyle(fontSize: 10),
                  )
                ],
              ),
            ),
    ),
  );
}

askPrintDevice(
    BuildContext context,
    String title,
    CompanyInformation companySettings,
    List<CompanySettings> settings,
    var data,
    Uint8List byteImage,
    var customerModel) {
  int printerType =
      ComSettings.appSettings('int', 'key-dropdown-printer-type-view', 0);
  int printerDevice =
      ComSettings.appSettings('int', 'key-dropdown-printer-device-view', 0);

  if (printerType == 2) {
    //2: 'Bluetooth',
    if (printerDevice == 2) {
      //2: 'Default',
    } else if (printerDevice == 3) {
      //3: 'Line',
    } else if (printerDevice == 4) {
      //                4: 'Local',
    } else if (printerDevice == 5) {
      //                5: 'ESC/POS',
      _showPrinterSize(
          context, title, companySettings, settings, data, byteImage);
    } else if (printerDevice == 6) {
      //                6: 'Thermal',
    } else if (printerDevice == 7) {
      //                7: 'RP_80',
    } else if (printerDevice == 8) {
      //                8: 'SEWOO',
    } else if (printerDevice == 9) {
      //                9: 'ESYPOS',
    } else if (printerDevice == 10) {
      //                10: 'CIONTEK',
    } else if (printerDevice == 11) {
      //                11: 'SUNMI_V1',
      printSunmiV1([companySettings, settings, data]);
    } else if (printerDevice == 12) {
      //                12: 'SUNMI_V2',
      printSunmiV2([companySettings, settings, data]);
    } else if (printerDevice == 13) {
      //13: 'Other',
    }
  } else if (printerType == 3) {
    // 3: 'Cloud',
    //
  } else if (printerType == 4) {
    // 4: 'Document',
    printDocument(title, companySettings, settings, data, customerModel);
  } else if (printerType == 5) {
    // 5: 'POS',
    if (printerDevice == 2) {
      //2: 'Default',
    } else if (printerDevice == 3) {
      //3: 'Line',
    } else if (printerDevice == 4) {
      //                4: 'Local',
    } else if (printerDevice == 5) {
      //                5: 'ESC/POS',
      _showPrinterSize(
          context, title, companySettings, settings, data, byteImage);
    } else if (printerDevice == 6) {
      //                6: 'Thermal',
    } else if (printerDevice == 7) {
      //                7: 'RP_80',
    } else if (printerDevice == 8) {
      //                8: 'SEWOO',
    } else if (printerDevice == 9) {
      //                9: 'ESYPOS',
    } else if (printerDevice == 10) {
      //                10: 'CIONTEK',
    } else if (printerDevice == 11) {
      //                11: 'SUNMI_V1',
      printSunmiV1([companySettings, settings, data]);
    } else if (printerDevice == 12) {
      //                12: 'SUNMI_V2',
      printSunmiV2([companySettings, settings, data]);
    } else if (printerDevice == 13) {
      //13: 'Other',
    }
  } else if (printerType == 6) {
    // 6: 'TCP',
    //
  } else if (printerType == 7) {
    // 7: 'WiFi',
    //
  } else if (printerType == 8) {
    // 8: 'USB,
    //
  } else {
    printDocument(title, companySettings, settings, data, customerModel);
  }
}

List<String> newDataList = ["2", "3", "4"];

_showPrinterSize(BuildContext context, title, companySettings, settings, data,
    byteImage) async {
  _asyncSimpleDialog(context).then((value) => printBluetooth(
      context, title, companySettings, settings, data, byteImage, value));
}

Future<String?> _asyncSimpleDialog(BuildContext context) async {
  return await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Printer Size'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, newDataList[0]);
              },
              child: const Text('2'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, newDataList[1]);
              },
              child: const Text('3'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, newDataList[2]);
              },
              child: const Text('4'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, newDataList[3]);
              },
              child: const Text('5'),
            ),
          ],
        );
      });
}

Future<String?> askPrintMethod(
    BuildContext context,
    String title,
    var companySettings,
    var settings,
    var data,
    Uint8List byteImage,
    var customerModel) async {
  List<String> colorList = [
    'Pdf Document',
    'TCP',
    'Bluetooth',
    'WiFi',
    'Thermal',
    'Other'
  ];
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Print Type'),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: colorList.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(colorList[index]),
                  onTap: () {
                    Navigator.pop(context, colorList[index]);
                    if (colorList[index] == 'Pdf Document') {
                      printDocument(title, companySettings, settings, data,
                          customerModel);
                    } else if (colorList[index] == 'Bluetooth') {
                      _showPrinterSize(context, title, companySettings,
                          settings, data, byteImage);
                    }
                  },
                );
              },
            ),
          ),
        );
      });
}

Future<dynamic> printBluetooth(
    BuildContext context,
    String title,
    CompanyInformation companySettings,
    List<CompanySettings> settings,
    data,
    byteImage,
    size) async {
  var dataAll = [companySettings, settings, data, size, "SALE"];
  // dataAll.add('Settings[' + settings + ']');b
  Navigator.push(
      context, MaterialPageRoute(builder: (_) => BtPrint(dataAll, byteImage)));
}

// Future<dynamic> printBluetooth(
//     String title, companySettings, settings, data) async {
//   final profile = await CapabilityProfile.load();
//   final generator = Generator(PaperSize.mm80, profile);
//   List<int> bytes = [];
//
//   var dataInformation = data['Information'][0];
//   var dataParticulars = data['Particulars'];
//   var dataSerialNO = data['SerialNO'];
//   var dataDeliveryNote = data['DeliveryNote'];
//
//   var taxSale = salesTypeData.type == 'SALES-ES'
//       ? false
//       : salesTypeData.type == 'SALES-Q'
//           ? false
//           : salesTypeData.type == 'SALES-O'
//               ? false
//               : true;
// var invoiceHead = salesTypeData.type == 'SALES-ES'
//         ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
//         : salesTypeData.type == 'SALES-Q'
//             ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
//             : salesTypeData.type == 'SALES-O'
//                 ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
//                 : Settings.getValue<String>(
//                     'key-sales-invoice-head', 'INVOICE');
//
//   String DateUtil.dateDMY(value) {
//     var dateTime = DateFormat("yyyy-MM-dd").parse(value.toString());
//     return DateFormat("d MMM yyyy").format(dateTime);
//   }
//
//   bytes += generator.text(invoiceHead,
//       styles: PosStyles(underline: true, bold: true, align: PosAlign.center),
//       linesAfter: 1);
//   bytes += generator.text(companySettings.name']);
//   bytes +=
//       generator.text(companySettings.add1'] + ',' + companySettings.add2']);
//   // bytes += generator.text('Special 2: blåbærgrød', styles: PosStyles(codeTable: 'CP1252'));
//   bytes += generator
//       .text(companySettings.telephone'] + ',' + companySettings.mobile']);
//   bytes += generator.text(Settings.getValue('GST-NO', settings));
//   bytes += generator.text('Date : ' + DateUtil.dateDMY(dataInformation['DDate']));
//   bytes += generator.text('Voucher: ' + dataInformation['InvoiceNo']);
//   bytes += generator.text('BILL To :- ' + dataInformation['ToName']);
//   bytes +=
//       generator.text((dataInformation['Add1'] + ',' + dataInformation['Add2']));
//   bytes += generator.text('------------------------------');
//   bytes += generator.row([
//     PosColumn(
//       text: 'No',
//       width: 1,
//       styles: PosStyles(align: PosAlign.center),
//     ),
//     PosColumn(
//       text: 'Description',
//       width: 6,
//       styles: PosStyles(align: PosAlign.center),
//     ),
//     PosColumn(
//       text: 'Price',
//       width: 1,
//       styles: PosStyles(align: PosAlign.center),
//     ),
//     PosColumn(
//       text: 'Qty',
//       width: 1,
//       styles: PosStyles(align: PosAlign.center),
//     ),
//     PosColumn(
//       text: 'Vat',
//       width: 1,
//       styles: PosStyles(align: PosAlign.center),
//     ),
//     PosColumn(
//       text: 'Total',
//       width: 2,
//       styles: PosStyles(align: PosAlign.center),
//     ),
//   ]);
//   for (var i = 0; i < dataParticulars.length; i++) {
//     // dataParticulars
//     bytes += generator.row([
//       PosColumn(
//         text: '${dataParticulars[i]['slno']}',
//         width: 1,
//         styles: PosStyles(align: PosAlign.right),
//       ),
//       PosColumn(
//         text: dataParticulars[i]['itemname'],
//         width: 6,
//         styles: PosStyles(align: PosAlign.center),
//       ),
//       PosColumn(
//         text: '${dataParticulars[i]['RealRate']}',
//         width: 1,
//         styles: PosStyles(align: PosAlign.right),
//       ),
//       PosColumn(
//         text: '${dataParticulars[i]['Qty']}',
//         width: 1,
//         styles: PosStyles(align: PosAlign.right),
//       ),
//       PosColumn(
//         text: '${dataParticulars[i]['CGST']}',
//         width: 1,
//         styles: PosStyles(align: PosAlign.right),
//       ),
//       PosColumn(
//         text: '${dataParticulars[i]['Total']}',
//         width: 2,
//         styles: PosStyles(align: PosAlign.right),
//       ),
//     ]);
//   }
//   bytes += generator.text('------------------------------');
//   bytes += generator.text('SUB TOTAL : ${dataInformation['GrossValue']}',
//       styles: PosStyles(align: PosAlign.right));
//   bytes += generator.text('VAT : ${dataInformation['IGST']}',
//       styles: PosStyles(align: PosAlign.right));
//   bytes += generator.text('TOTAL : ${dataInformation['GrandTotal']}',
//       styles: PosStyles(align: PosAlign.right));
//   bytes += generator.text('PAID : ${dataInformation['CashReceived']}',
//       styles: PosStyles(align: PosAlign.right));
//   bytes += generator.text('TOTAL DUE : ${dataInformation['GrandTotal']}',
//       styles: PosStyles(align: PosAlign.right, bold: true));
//   // bytes += generator.text('PAID : ${dataInformation['CashReceived']}',
//   // styles: PosStyles(align: PosAlign.right));
//   bytes += generator.text(data['message'],
//       styles: PosStyles(align: PosAlign.center));
//
//   bytes += generator.feed(2);
//   bytes += generator.cut();
// }

void printSunmiV1(dataAll) async {
  var firm = dataAll[0];
  var settings = dataAll[1];
  var bill = dataAll[2];
  var inf = bill['Information'][0];
  var det = bill['Particulars'];
  var serialNo = bill['SerialNO'];
  var deliveryNote = bill['DeliveryNote'];
  var otherAmount = bill['otherAmount'];

  // var invoiceHead = salesTypeData.type == 'SALES-ES'
  //     ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
  //     : salesTypeData.type == 'SALES-Q'
  //         ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
  //         : salesTypeData.type == 'SALES-O'
  //             ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
  //             : Settings.getValue<String>('key-sales-invoice-head', 'INVOICE');
  // bool isQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
  // bool isEsQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
  // int printCopy = Settings.getValue<int>('key-dropdown-print-copy-view', 0);
  // int printerModel =
  //     Settings.getValue<int>('key-dropdown-printer-model-view', 0);

  // bool result = await SunmiPrinterService.init();
  // if (result) {
  //   if (taxSale) {
  //     await SPrinter.setAlign(sum_mi.Align.center);
  //     await SPrinter.setFontSize(30);
  //     await SPrinter.text(firm['name']);
  //     await SPrinter.setFontSize(26);
  //     await SPrinter.lineWrap();
  //     await SPrinter.text(firm['add1']);
  //     await SPrinter.text('Tel : ${firm['telephone'] + ',' + firm['mobile']}');
  //     await SPrinter.lineWrap();
  //     await SPrinter.text(companyTaxMode == 'INDIA'
  //         ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
  //         : 'TRN : ${ComSettings.getValue('GST-NO', settings)}');
  //     await SPrinter.lineWrap();
  //     await SPrinter.text(invoiceHead);
  //     await SPrinter.setFontSize(24);
  //     await SPrinter.columnsText(
  //       [
  //         'VoucherNo : ${inf['InvoiceNo']}',
  //         'Date : ${DateUtil.dateDMY(inf['DDate']) + ' ' + DateUtil.timeHMSA(inf['BTime'])}'
  //       ],
  //       width: [18, 19],
  //       align: [1, 1],
  //     );
  //     await SPrinter.lineWrap();
  //     await SPrinter.text('Bill To : ${inf['ToName']}');
  //     await SPrinter.setAlign(sum_mi.Align.left);
  //     await SPrinter.setFontSize(20);
  //     if (inf['gstno'].toString().trim().isNotEmpty) {
  //       await SPrinter.text(companyTaxMode == 'INDIA'
  //           ? 'GSTNO : ${inf['gstno'].toString().trim()}'
  //           : 'TRN : ${inf['gstno'].toString().trim()}');
  //     }
  //     await SPrinter.lineWrap();
  //     await SPrinter.setAlign(sum_mi.Align.left);
  //     await SPrinter.setFontSize(20);
  //     //'column'
  //     await SPrinter.columnsText(
  //       ["Description", "Qty", "Price", "Total"],
  //       width: [16, 5, 8, 8],
  //       align: [1, 1, 1, 1],
  //     );
  //     await SPrinter.setFontSize(20);
  //     await SPrinter.lineWrap();
  //     await SPrinter.setFontSize(20);
  //     for (var i = 0; i < det.length; i++) {
  //       await SPrinter.columnsText([
  //         det[i]['itemname'],
  //         det[i]['Qty'].toString(),
  //         det[i]['Rate'].toString(),
  //         det[i]['Total'].toString()
  //       ], width: [
  //         12,
  //         4,
  //         8,
  //         8
  //       ], align: [
  //         0,
  //         2,
  //         2,
  //         2
  //       ]);
  //     }
  //   } else {
  //     if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
  //       await SPrinter.setAlign(sum_mi.Align.center);
  //       await SPrinter.setFontSize(30);
  //       await SPrinter.text(firm['name']);
  //       await SPrinter.setFontSize(26);
  //       await SPrinter.lineWrap();
  //       await SPrinter.text(firm['add1']);
  //       await SPrinter.text(
  //           'Tel : ${firm['telephone'] + ',' + firm['mobile']}');
  //       await SPrinter.lineWrap();
  //       await SPrinter.text(companyTaxMode == 'INDIA'
  //           ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
  //           : 'TRN : ${ComSettings.getValue('GST-NO', settings)}');
  //       await SPrinter.lineWrap();
  //       await SPrinter.text(invoiceHead);
  //       await SPrinter.setFontSize(24);
  //       await SPrinter.columnsText(
  //         [
  //           'VoucherNo : ${inf['InvoiceNo']}',
  //           'Date : ${DateUtil.dateDMY(inf['DDate']) + ' ' + DateUtil.timeHMSA(inf['BTime'])}'
  //         ],
  //         width: [18, 19],
  //         align: [1, 1],
  //       );
  //     } else {
  //       await SPrinter.setAlign(sum_mi.Align.center);
  //       await SPrinter.setFontSize(26);
  //       await SPrinter.text(invoiceHead);
  //       await SPrinter.setFontSize(24);
  //       await SPrinter.columnsText(
  //         [
  //           'VoucherNo : ${inf['InvoiceNo']}',
  //           'Date : ${DateUtil.dateDMY(inf['DDate']) + ' ' + DateUtil.timeHMSA(inf['BTime'])}'
  //         ],
  //         width: [18, 19],
  //         align: [1, 1],
  //       );
  //     }
  //     await SPrinter.lineWrap();
  //     await SPrinter.text('Bill To : ${inf['ToName']}');
  //     await SPrinter.setAlign(sum_mi.Align.left);
  //     await SPrinter.setFontSize(20);
  //     if (isEsQrCodeKSA) {
  //       if (inf['gstno'].toString().trim().isNotEmpty) {
  //         await SPrinter.text(companyTaxMode == 'INDIA'
  //             ? 'GSTNO : ${inf['gstno'].toString().trim()}'
  //             : 'TRN : ${inf['gstno'].toString().trim()}');
  //       }
  //     }
  //     await SPrinter.lineWrap();
  //     await SPrinter.setAlign(sum_mi.Align.left);
  //     await SPrinter.setFontSize(20);
  //     //'column'
  //     await SPrinter.columnsText(
  //       ["Description", "Qty", "Price", "Total"],
  //       width: [16, 5, 8, 8],
  //       align: [1, 1, 1, 1],
  //     );
  //     await SPrinter.setFontSize(20);
  //     await SPrinter.lineWrap();
  //     await SPrinter.setFontSize(20);
  //     for (var i = 0; i < det.length; i++) {
  //       await SPrinter.columnsText([
  //         det[i]['itemname'],
  //         det[i]['Qty'].toString(),
  //         det[i]['Rate'].toString(),
  //         det[i]['Total'].toString()
  //       ], width: [
  //         12,
  //         4,
  //         8,
  //         8
  //       ], align: [
  //         0,
  //         2,
  //         2,
  //         2
  //       ]);
  //     }
  //   }
  //   for (var i = 0; i < otherAmount.length; i++) {
  //     if (otherAmount[i]['Amount'].toDouble() > 0) {
  //       await SPrinter.lineWrap();
  //       await SPrinter.columnsText(
  //         ['${otherAmount[i]['LedName']} :', '${otherAmount[i]['Amount']}'],
  //         width: [16, 16],
  //         align: [0, 2],
  //       );
  //     }
  //   }
  //   await SPrinter.lineWrap();
  //   await SPrinter.setAlign(sum_mi.Align.right);
  //   await SPrinter.setFontSize(27);
  //   await SPrinter.columnsText(
  //     [
  //       "Net Amount :",
  //       double.tryParse(inf['GrandTotal'].toString()).toStringAsFixed(2)
  //     ],
  //     width: [16, 16],
  //     align: [0, 2],
  //   );
  //   await SPrinter.lineWrap();
  //   await SPrinter.setFontSize(22);
  //   var balance = (double.tryParse(inf['Balance'].toString()) -
  //               double.tryParse(inf['GrandTotal'].toString())) >
  //           0
  //       ? (double.tryParse(inf['Balance'].toString()) -
  //               double.tryParse(inf['GrandTotal'].toString()))
  //           .toString()
  //       : '0';
  //   await SPrinter.lineWrap();
  //   await SPrinter.text(
  //       'Received : ${inf['CashReceived']} / Balance : ${(double.tryParse(balance)) + (double.tryParse(inf['GrandTotal'].toString()) - double.tryParse(inf['CashReceived'].toString()))}');
  //   await SPrinter.lineWrap();
  //   await SPrinter.setAlign(sum_mi.Align.center);
  //   await SPrinter.setFontSize(20);
  //   await SPrinter.text(bill['message']);
  //   await SPrinter.lineWrap();
  //   if (isQrCodeKSA) {
  //     if (taxSale) {
  //       await SPrinter.qrCode(SaudiConversion.getBase64(
  //           settings.name,
  //           ComSettings.getValue('GST-NO', settings),
  //           DateUtil.dateTimeQrDMY(DateUtil.datedYMD(inf['DDate']) +
  //               ' ' +
  //               DateUtil.timeHMS(inf['BTime'])),
  //           double.tryParse(inf['GrandTotal'].toString()).toStringAsFixed(2),
  //           (double.tryParse(inf['CGST'].toString()) +
  //                   double.tryParse(inf['SGST'].toString()) +
  //                   double.tryParse(inf['IGST'].toString()))
  //               .toStringAsFixed(2)));
  //     }
  //   } else if (isEsQrCodeKSA) {
  //     await SPrinter.qrCode(SaudiConversion.getBase64(
  //         settings.name,
  //         ComSettings.getValue('GST-NO', settings),
  //         DateUtil.dateTimeQrDMY(DateUtil.datedYMD(inf['DDate']) +
  //             ' ' +
  //             DateUtil.timeHMS(inf['BTime'])),
  //         double.tryParse(inf['GrandTotal'].toString()).toStringAsFixed(2),
  //         (double.tryParse(inf['CGST'].toString()) +
  //                 double.tryParse(inf['SGST'].toString()) +
  //                 double.tryParse(inf['IGST'].toString()))
  //             .toStringAsFixed(2)));
  //   }
  //   await SPrinter.lineWrap(3);
  // }
}

void printSunmiV2(dataAll) async {
  var firm = dataAll[0];
  var setting = dataAll[1];
  var bill = dataAll[2];
  var inf = bill['Information'][0];
  var det = bill['Particulars'];
  var serialNo = bill['SerialNO'];
  var deliveryNote = bill['DeliveryNote'];
  var otherAmount = bill['otherAmount'];

  SunmiPrinter.hr();
  SunmiPrinter.text(
    firm['name'],
    styles: const SunmiStyles(
        bold: true,
        underline: true,
        align: SunmiAlign.center,
        size: SunmiSize.md),
  );
  SunmiPrinter.text(
    'center',
    styles: const SunmiStyles(
        bold: true, underline: true, align: SunmiAlign.center),
  );
  SunmiPrinter.text(
    firm['add1'],
    styles: const SunmiStyles(align: SunmiAlign.center),
  );
  SunmiPrinter.text(
    'Tel : ${firm['telephone'] + ',' + firm['mobile']}',
    styles: const SunmiStyles(align: SunmiAlign.center),
  );
  SunmiPrinter.emptyLines(1);
  await SPrinter.text(companyTaxMode == 'INDIA'
      ? 'GSTNO : ${ComSettings.getValue('GST-NO', setting)}'
      : 'TRN : ${ComSettings.getValue('GST-NO', setting)}');
  await SPrinter.lineWrap();
  await SPrinter.setFontSize(24);
  await SPrinter.text('VoucherNo : ${inf['InvoiceNo']}');
  await SPrinter.lineWrap();
  await SPrinter.text('Bill To : ${inf['ToName']}');
  await SPrinter.setAlign(sum_mi.Align.left);
  // await SPrinter.setAlign(sum_mi.Align.center);
  await SPrinter.setFontSize(20);
  await SPrinter.lineWrap();
  await SPrinter.setAlign(sum_mi.Align.left);
  await SPrinter.setFontSize(20);
  //'column'
  await SPrinter.columnsText(
    ["Description", "Qty", "Price", "Total"],
    width: [16, 5, 8, 8],
    align: [1, 1, 1, 1],
  );
  await SPrinter.setFontSize(20);
  await SPrinter.lineWrap();
  await SPrinter.setFontSize(20);
  for (var i = 0; i < det.length; i++) {
    await SPrinter.columnsText([
      det[i]['itemname'],
      det[i]['Qty'].toString(),
      det[i]['Rate'].toString(),
      det[i]['Total'].toString()
    ], width: [
      12,
      4,
      8,
      8
    ], align: [
      0,
      2,
      2,
      2
    ]);
  }
  await SPrinter.lineWrap();
  await SPrinter.setAlign(sum_mi.Align.right);
  await SPrinter.setFontSize(27);
  await SPrinter.text("GrandTotal : " + inf['GrandTotal'].toString());
  await SPrinter.lineWrap();
  await SPrinter.setFontSize(22);
  var balance = (double.tryParse(inf['Balance'].toString())! -
              double.tryParse(inf['GrandTotal'].toString())!) >
          0
      ? (double.tryParse(inf['Balance'].toString())! -
              double.tryParse(inf['GrandTotal'].toString())!)
          .toString()
      : '0';
  await SPrinter.lineWrap();
  // await SPrinter.columnsText([
  //   'Received : ${inf['CashReceived']}'
  //       'Balance : ${(double.tryParse(balance)) + (double.tryParse(inf['GrandTotal'].toString()) - double.tryParse(inf['CashReceived'].toString()))}',
  // ], width: [
  //   16,
  //   16
  // ], align: [
  //   0,
  //   2
  // ]);
  await SPrinter.text(
      'Received : ${inf['CashReceived']} / Balance : ${(double.tryParse(balance))! + (double.tryParse(inf['GrandTotal'].toString())! - double.tryParse(inf['CashReceived'].toString())!)}');
  await SPrinter.lineWrap();
  await SPrinter.setAlign(sum_mi.Align.center);
  await SPrinter.setFontSize(20);
  await SPrinter.text(bill['message']);
  await SPrinter.lineWrap(3);
}

void printSunmiV2Test(dataAll) async {
  var bill = dataAll[2];
  var dataInformation = bill['Information'][0];
  var dataParticulars = bill['Particulars'];
  var dataSerialNO = bill['SerialNO'];
  var dataDeliveryNote = bill['DeliveryNote'];
  var otherAmount = bill['otherAmount'];
  // Test regular text
  SunmiPrinter.hr();
  SunmiPrinter.text(
    'Test Sunmi Printer',
    styles: const SunmiStyles(align: SunmiAlign.center),
  );
  SunmiPrinter.hr();

  // Test align
  SunmiPrinter.text(
    'left',
    styles: const SunmiStyles(bold: true, underline: true),
  );
  SunmiPrinter.text(
    'center',
    styles: const SunmiStyles(
        bold: true, underline: true, align: SunmiAlign.center),
  );
  SunmiPrinter.text(
    'right',
    styles:
        const SunmiStyles(bold: true, underline: true, align: SunmiAlign.right),
  );

  // Test text size
  SunmiPrinter.text('Extra small text',
      styles: const SunmiStyles(size: SunmiSize.xs));
  SunmiPrinter.text('Medium text',
      styles: const SunmiStyles(size: SunmiSize.md));
  SunmiPrinter.text('Large text',
      styles: const SunmiStyles(size: SunmiSize.lg));
  SunmiPrinter.text('Extra large text',
      styles: const SunmiStyles(size: SunmiSize.xl));

  // Test row
  SunmiPrinter.row(
    cols: [
      SunmiCol(text: 'col1', width: 4),
      SunmiCol(text: 'col2', width: 4, align: SunmiAlign.center),
      SunmiCol(text: 'col3', width: 4, align: SunmiAlign.right),
    ],
  );

  // Test image
  ByteData bytes = await rootBundle.load('assets/logo.png');
  final buffer = bytes.buffer;
  final imgData = base64.encode(Uint8List.view(buffer));
  SunmiPrinter.image(imgData);

  SunmiPrinter.emptyLines(3);
}

Future<String> _createPDF(
    String title,
    CompanyInformation companySettings,
    List<CompanySettings> settings,
    var information,
    var particular,
    String invoiceHead,
    form,
    dataParticulars) async {
  return makePDF(title, companySettings, settings, information, particular,
          invoiceHead, form, dataParticulars)
      .then((value) => savePreviewPDF(value, title));
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
      // html.document.body!.children.add(anchor);
      // anchor.click();
      // html.document.body!.children.remove(anchor);
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

Future<pw.Document> makePDF(
    String title,
    CompanyInformation companySettings,
    List<CompanySettings> settings,
    var information,
    var particular,
    String invoiceHead,
    form,
    dataParticulars) async {
  double oldBalance = 0, balance = 0, a = 0;
  var bill = information;
  dataParticulars = jsonDecode(bill['particular']);
  //  var dataParticulars = bill['Particulars'];
  var bal = information['oldBalance'].toString().split(' ');
  if (bal[1] == 'Dr') {
    oldBalance = double.tryParse(bal[0].toString()) ?? 0;
    balance = oldBalance - information['total'];
  } else {
    oldBalance = (double.tryParse(bal[0].toString())! * (-1));
    balance = oldBalance - information['total'];
  }
  final pdf = pw.Document();

  // pdf.addPage(pw.MultiPage(
  //     /*company*/
  //     header: (context) => pw.Column(children: [
  //           pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
  //             pw.Expanded(
  //                 child: pw.Column(children: [
  //               pw.Container(
  //                   height: 80,
  //                   padding: const pw.EdgeInsets.all(8),
  //                   alignment: pw.Alignment.center,
  //                   child: pw.RichText(
  //                       textAlign: pw.TextAlign.center,
  //                       text: pw.TextSpan(
  //                           text: '${companySettings.name}\n',
  //                           style: pw.TextStyle(
  //                             // color: _darkColor,
  //                             fontWeight: pw.FontWeight.bold,
  //                             fontSize: 15,
  //                           ),
  //                           children: [
  //                             const pw.TextSpan(
  //                               text: '\n',
  //                               style: pw.TextStyle(
  //                                 fontSize: 5,
  //                               ),
  //                             ),
  //                             pw.TextSpan(
  //                                 text: companySettings.add2.toString().isEmpty
  //                                     ? companySettings.add1
  //                                     : companySettings.add1 +
  //                                         '\n' +
  //                                         companySettings.add2,
  //                                 style: pw.TextStyle(
  //                                   fontWeight: pw.FontWeight.bold,
  //                                   fontSize: 10,
  //                                 ),
  //                                 children: [
  //                                   companySettings.telephone
  //                                           .toString()
  //                                           .isNotEmpty
  //                                       ? pw.TextSpan(
  //                                           text: companySettings.telephone,
  //                                           children: [
  //                                               companySettings.mobile
  //                                                       .toString()
  //                                                       .isNotEmpty
  //                                                   ? pw.TextSpan(
  //                                                       text: ', ' +
  //                                                           companySettings
  //                                                               .mobile)
  //                                                   : const pw.TextSpan(
  //                                                       text: ' '),
  //                                             ])
  //                                       : const pw.TextSpan(
  //                                           text: '\n',
  //                                           style: pw.TextStyle(
  //                                             fontSize: 5,
  //                                           ),
  //                                         ),
  //                                 ]),
  //                           ]))),
  //               pw.Container(
  //                   height: 80,
  //                   padding: const pw.EdgeInsets.all(8),
  //                   alignment: pw.Alignment.center,
  //                   child: pw.Text(invoiceHead,
  //                       style: pw.TextStyle(
  //                           fontWeight: pw.FontWeight.bold,
  //                           fontSize: 15,
  //                           decoration: pw.TextDecoration.underline))),
  //               pw.Container(
  //                 padding: const pw.EdgeInsets.all(10),
  //                 alignment: pw.Alignment.center,
  //                 height: 10,
  //                 child: pw.GridView(
  //                   crossAxisCount: 2,
  //                   children: [
  //                     pw.Text('VoucherNo : ${information['entryNo']}',
  //                         style: pw.TextStyle(
  //                           fontWeight: pw.FontWeight.bold,
  //                           fontSize: 10,
  //                         ),
  //                         textAlign: pw.TextAlign.left),
  //                     pw.Text('Date : ' + DateUtil.dateDMY(information['date']),
  //                         style: pw.TextStyle(
  //                           fontWeight: pw.FontWeight.bold,
  //                           fontSize: 10,
  //                         ),
  //                         textAlign: pw.TextAlign.right),
  //                   ],
  //                 ),
  //               ),
  //               pw.SizedBox(
  //                 height: 5,
  //               ),
  //             ])),
  //           ]),
  //           if (context.pageNumber > 1) pw.SizedBox(height: 20)
  //         ]),
  //     build: (context) => [
  //           /*customer*/
  //           pw.Table(
  //             border: pw.TableBorder.all(width: 0.2),
  //             defaultColumnWidth: const pw.IntrinsicColumnWidth(),
  //             children: [
  //               pw.TableRow(children: [
  //                 pw.Column(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.center,
  //                     mainAxisAlignment: pw.MainAxisAlignment.center,
  //                     children: [
  //                       pw.Text('Particulars',
  //                           style: pw.TextStyle(
  //                               fontSize: 9, fontWeight: pw.FontWeight.bold)),
  //                       // pw.Divider(thickness: 1)
  //                     ]),
  //                 pw.Column(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.center,
  //                     mainAxisAlignment: pw.MainAxisAlignment.center,
  //                     children: [
  //                       pw.Text('Amount',
  //                           style: pw.TextStyle(
  //                               fontSize: 9, fontWeight: pw.FontWeight.bold)),
  //                       // pw.Divider(thickness: 1)
  //                     ]),
  //                 pw.Column(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.center,
  //                     mainAxisAlignment: pw.MainAxisAlignment.center,
  //                     children: [
  //                       pw.Text('Discount',
  //                           style: pw.TextStyle(
  //                               fontSize: 9, fontWeight: pw.FontWeight.bold)),
  //                       // pw.Divider(thickness: 1)
  //                     ]),
  //                 pw.Column(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.center,
  //                     mainAxisAlignment: pw.MainAxisAlignment.center,
  //                     children: [
  //                       pw.Text('Total',
  //                           style: pw.TextStyle(
  //                               fontSize: 9, fontWeight: pw.FontWeight.bold)),
  //                       // pw.Divider(thickness: 1)
  //                     ]),
  //               ]),
  //               // dataParticulars
  //               pw.TableRow(children: [
  //                 pw.Column(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                     mainAxisAlignment: pw.MainAxisAlignment.center,
  //                     children: [
  //                       pw.Padding(
  //                         padding: const pw.EdgeInsets.all(2.0),
  //                         child: pw.Text(
  //                             information['name'] +
  //                                 "\n" +
  //                                 particular[0]['narration'].toString(),
  //                             style: const pw.TextStyle(fontSize: 9)),
  //                         // pw.Divider(thickness: 1)
  //                       ),
  //                     ]),
  //                 pw.Column(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                     mainAxisAlignment: pw.MainAxisAlignment.center,
  //                     children: [
  //                       pw.Padding(
  //                         padding: const pw.EdgeInsets.all(2.0),
  //                         child: pw.Text(
  //                             double.tryParse(
  //                                     particular[0]['amount'].toString())!
  //                                 .toStringAsFixed(2),
  //                             style: const pw.TextStyle(fontSize: 9)),
  //                         // pw.Divider(thickness: 1)
  //                       )
  //                     ]),
  //                 pw.Column(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                     mainAxisAlignment: pw.MainAxisAlignment.center,
  //                     children: [
  //                       pw.Padding(
  //                         padding: const pw.EdgeInsets.all(2.0),
  //                         child: pw.Text(
  //                             double.tryParse(
  //                                     particular[0]['discount'].toString())!
  //                                 .toStringAsFixed(2),
  //                             style: const pw.TextStyle(fontSize: 9)),
  //                         // pw.Divider(thickness: 1)
  //                       )
  //                     ]),
  //                 pw.Column(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                     mainAxisAlignment: pw.MainAxisAlignment.center,
  //                     children: [
  //                       pw.Padding(
  //                         padding: const pw.EdgeInsets.all(2.0),
  //                         child: pw.Text(
  //                             double.tryParse(
  //                                     particular[0]['total'].toString())!
  //                                 .toStringAsFixed(2),
  //                             style: const pw.TextStyle(fontSize: 9)),
  //                         // pw.Divider(thickness: 1)
  //                       )
  //                     ]),
  //               ])
  //             ],
  //           ),
  //           pw.Container(
  //               alignment: pw.Alignment.center,
  //               child: pw.Text(
  //                 ' Amount in Words: ${NumberToWord().convertDouble('en', double.tryParse(information['total'].toString()))}',
  //               )),
  //           pw.Column(children: [
  //             pw.Row(
  //               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //               children: [
  //                 pw.Text(' Old Balance : ${oldBalance.toStringAsFixed(2)}',
  //                     style: pw.TextStyle(
  //                       fontWeight: pw.FontWeight.bold,
  //                       fontSize: 10,
  //                     ),
  //                     textAlign: pw.TextAlign.left),
  //                 pw.Text(' Balance : ${balance.toStringAsFixed(2)}',
  //                     style: pw.TextStyle(
  //                       fontWeight: pw.FontWeight.bold,
  //                       fontSize: 10,
  //                     ),
  //                     textAlign: pw.TextAlign.right),
  //               ],
  //             )
  //           ]),
  //           pw.SizedBox(
  //             height: 40.0,
  //           ),
  //           pw.Container(
  //               alignment: pw.Alignment.center,
  //               child: pw.Text(
  //                   information['message'].toString().isNotEmpty
  //                       ? information['message'].toString()
  //                       : 'Thank you',
  //                   textAlign: pw.TextAlign.center))
  //         ],
  //     footer: _buildFooter));
  pdf.addPage(pw.MultiPage(
      maxPages: 100,
      pageFormat: pw.PdfPageFormat.a4,
      build: (pw.Context context) {
        List<pw.Widget> widgets = [
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  " ${companySettings.name}",
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 7.0, top: 5),
                  child: pw.Column(
                    children: [
                      companySettings.mobile.isNotEmpty
                          ? pw.Text(
                              companySettings.mobile,
                              style: const pw.TextStyle(fontSize: 8),
                            )
                          : pw.Container(),
                      companySettings.add1.isNotEmpty
                          ? pw.Text(
                              companySettings.add1,
                              style: const pw.TextStyle(fontSize: 8),
                            )
                          : pw.Container(),
                      companySettings.add2.isNotEmpty
                          ? pw.Text(
                              companySettings.add2,
                              style: const pw.TextStyle(fontSize: 8),
                            )
                          : pw.Container(),
                      companySettings.email.isNotEmpty
                          ? pw.Text(
                              companySettings.email,
                              style: const pw.TextStyle(fontSize: 8),
                            )
                          : pw.Container(),
                      companyTaxMode == 'INDIA'
                          ? pw.Text(
                              'GST No : ${ComSettings.getValue('GST-NO', settings)}',
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold),
                            )
                          : pw.Text(
                              "TRN : ${ComSettings.getValue('GST-NO', settings)}",
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold),
                            )
                    ],
                  ),
                ),
                pw.SizedBox(
                  height: 30,
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "No: ${bill["entryNo"]}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          "Date: ${DateUtil.dateDMY(bill['date'])}",
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(
                  height: 10,
                ),
                form == 'RECEIPT'
                    ? pw.Text("RECEIPT VOUCHER",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: pw.PdfColor.fromInt(0xFF000000),
                        ))
                    : pw.Text("PAYMENT VOUCHER",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: pw.PdfColor.fromInt(0xFF000000),
                        )),
                pw.SizedBox(
                  height: 10,
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.SizedBox(
                            width: 180,
                            child: form == 'RECEIPT'
                                ? pw.Text(
                                    "Recieved With Thanks From",
                                    style: pw.TextStyle(fontSize: 10),
                                  )
                                : pw.Text(
                                    "Paid To",
                                    style: pw.TextStyle(fontSize: 10),
                                  )),
                        pw.SizedBox(
                          width: 20,
                        ),
                        pw.Text(
                          "${bill["name"]}",
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 180,
                          child: pw.Text(
                            "the sumof rupees",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.SizedBox(
                          width: 20,
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            NumberToWord().convertDouble('en',
                                double.tryParse(bill['total'].toString())),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 180,
                          child: pw.Text(
                            "By Cash/Cheque/DD No",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.SizedBox(
                          width: 20,
                        ),
                        pw.Text(
                          "",
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 180,
                          child: pw.Text(
                            "towards",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.SizedBox(
                          width: 20,
                        ),
                        pw.Text(
                          dataParticulars[0]['narration'].toString(),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(
                      height: 10,
                    ),
                    pw.Container(
                      height: 40,
                      width: 180,
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Container(
                              width: 50,
                              color: const PdfColor.fromInt(0xFF000000)),
                          pw.Text(
                            "${bill["total"].toStringAsFixed(2)} ",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(
                      height: 15,
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "All Cheque/DD are subject to realisation",
                          style: pw.TextStyle(fontSize: 8),
                        ),
                        pw.SizedBox(
                          height: 15,
                        ),
                        oldBalance <= 0 && balance <= 0
                            ? pw.Column(
                                children: [
                                  pw.SizedBox(
                                    height: 50,
                                  ),
                                  pw.Text(
                                    "Receiver Signature   ",
                                    style: pw.TextStyle(fontSize: 8),
                                  ),
                                ],
                              )
                            : pw.Container(),
                      ],
                    ),
                    oldBalance > 0 || balance > 0
                        ? pw.Container(
                            padding: pw.EdgeInsets.symmetric(horizontal: 10),
                            height: 50,
                            width: double.infinity,
                            decoration:
                                pw.BoxDecoration(border: pw.Border.all()),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Row(
                                      children: [
                                        pw.SizedBox(
                                          width: 100,
                                          child: pw.Text(
                                            "Old Balance    :",
                                            style: pw.TextStyle(fontSize: 11),
                                          ),
                                        ),
                                        pw.Text(
                                          "${oldBalance.toStringAsFixed(2)}",
                                          style: pw.TextStyle(fontSize: 11),
                                        )
                                      ],
                                    ),
                                    pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.end,
                                      children: [
                                        pw.SizedBox(
                                          width: 100,
                                          child: pw.Text(
                                            "Balance           :",
                                            style: pw.TextStyle(fontSize: 11),
                                          ),
                                        ),
                                        pw.Text(
                                          "${balance.toStringAsFixed(2)}",
                                          style: pw.TextStyle(fontSize: 11),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                pw.Column(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Text(
                                      "Receiver Signature   ",
                                      style: pw.TextStyle(fontSize: 8),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : pw.Container(),
                  ],
                ),
                pw.SizedBox(
                  height: 5,
                ),
                pw.Text(
                  "${bill['message']}",
                  style: pw.TextStyle(fontSize: 10),
                )
              ],
            ),
          ),
        ];
        return widgets;
      }));

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

Future<String> printDocument(String title, CompanyInformation companySettings,
    List<CompanySettings> settings, var data, var customerBalance) async {
  // return makePDF(title, companySettings, settings, data, customerBalance)
  return '';
  //     .then((value) => savePrintPDF(value));
  // Printing.layoutPdf(
  //   // [onLayout] will be called multiple times
  //   // when the user changes the printer or printer settings
  //   onLayout: (PdfPageFormat format) {
  //     // Any valid Pdf document can be returned here as a list of int
  //     return buildPdf(format);
  //   },
  // );
}

Future<String> savePrintPDF(pw.Document pdf) async {
  // await Printing.layoutPdf(
  //     onLayout: (PdfPageFormat format) async => pdf.save());
  return 'printing';
}

typedef LayoutCallbackWithData = Future<Uint8List> Function(
    PdfPageFormat pageFormat, CustomData data);
