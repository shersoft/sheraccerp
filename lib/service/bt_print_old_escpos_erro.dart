// // @dart = 2.11
// import 'dart:convert';
// import 'dart:typed_data';
//
// import 'package:charset_converter/charset_converter.dart';
// import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
// import 'package:esc_pos_utils/esc_pos_utils.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_settings_screens/flutter_settings_screens.dart';
// import 'package:image/image.dart' as img;
// import 'package:intl/intl.dart';
// import 'package:sheraccerp/models/sales_type.dart';
// import 'package:sheraccerp/shared/constants.dart';
// import 'package:sheraccerp/util/dateUtil.dart';
// import 'package:sheraccerp/util/number_to_word.dart';
//
// class BtPrint extends StatefulWidget {
//   final data;
//   final Uint8List byteImage;
//   const BtPrint(this.data, this.byteImage, {Key key}) : super(key: key);
//
//   @override
//   _BtPrintState createState() => _BtPrintState();
// }
//
// class _BtPrintState extends State<BtPrint> {
//   PrinterBluetoothManager printerManager = PrinterBluetoothManager();
//   List<PrinterBluetooth> _devices = [];
//
//   @override
//   void initState() {
//     super.initState();
//
//     printerManager.scanResults.listen((devices) async {
//       // print('UI: Devices found ${devices.length}');
//       setState(() {
//         _devices = devices;
//       });
//     });
//     if (_devices.isEmpty) {
//       _startScanDevices();
//     }
//   }
//
//   void _startScanDevices() {
//     setState(() {
//       _devices = [];
//     });
//     printerManager.startScan(const Duration(seconds: 2));
//   }
//
//   void _stopScanDevices() {
//     printerManager.stopScan();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Print'),
//       ),
//       body: ListView.builder(
//           itemCount: _devices.length,
//           itemBuilder: (BuildContext context, int index) {
//             return InkWell(
//               onTap: () => _testPrint(_devices[index]),
//               child: Column(
//                 children: <Widget>[
//                   Container(
//                     height: 60,
//                     padding: const EdgeInsets.only(left: 10),
//                     alignment: Alignment.centerLeft,
//                     child: Row(
//                       children: <Widget>[
//                         const Icon(Icons.print),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: <Widget>[
//                               Text(_devices[index].name ?? ''),
//                               Text(_devices[index].address),
//                               Text(
//                                 'Click to print a test receipt',
//                                 style: TextStyle(color: Colors.grey[700]),
//                               ),
//                             ],
//                           ),
//                         )
//                       ],
//                     ),
//                   ),
//                   const Divider(),
//                 ],
//               ),
//             );
//           }),
//       floatingActionButton: StreamBuilder<bool>(
//         stream: printerManager.isScanningStream,
//         initialData: false,
//         builder: (c, snapshot) {
//           if (snapshot.data) {
//             return FloatingActionButton(
//               child: const Icon(Icons.stop),
//               onPressed: _stopScanDevices,
//               backgroundColor: Colors.red,
//             );
//           } else {
//             return FloatingActionButton(
//               child: const Icon(Icons.search),
//               onPressed: _startScanDevices,
//             );
//           }
//         },
//       ),
//     );
//   }
//
//   void _testPrint(PrinterBluetooth printer) async {
//     printerManager.selectPrinter(printer);
//
//     PaperSize paper = printer.type == 3 ? PaperSize.mm80 : PaperSize.mm58;
//
//     // TEST PRINT
//     // final PosPrintResult res =
//     // await printerManager.printTicket(await testTicket(paper));
//
//     // if (widget.byteImage.isNotEmpty) {
//     //   // DEMO RECEIPT
//     //   final PosPrintResult res =
//     //       await printerManager.printTicket(await printImage(paper));
//     //   showDialog(
//     //       context: context,
//     //       builder: (context) => AlertDialog(content: Text(res.msg)));
//     // } else
//     if (widget.data.isNotEmpty) {
//       // DEMO RECEIPT
//       final PosPrintResult res =
//           await printerManager.printTicket(await printData(paper));
//       showDialog(
//           context: context,
//           builder: (context) => AlertDialog(content: Text(res.msg)));
//     } else {
//       // DEMO RECEIPT
//       final PosPrintResult res =
//           await printerManager.printTicket(await demoReceipt(paper));
//       showDialog(
//           context: context,
//           builder: (context) => AlertDialog(content: Text(res.msg)));
//     }
//   }
//
//   Future<Ticket> printImage(PaperSize paper) async {
//     final Ticket ticket = Ticket(paper);
//     // Print image
//     final Uint8List bytes = widget.byteImage;
//     final img.Image image = img.decodeImage(bytes);
//     ticket.image(image);
//     ticket.feed(2);
//     ticket.cut();
//     return ticket;
//   }
//
//   var taxPercentages = '';
//
//   Future<Ticket> printData(PaperSize paper) async {
//
//     final Ticket ticket = Ticket(paper);
//     var bill = widget.data[2];
//     var companySettings = widget.data[0];
//     var settings = widget.data[1];
//     var dataInformation = bill['Information'][0];
//     var dataParticulars = bill['Particulars'];
//     // var dataSerialNO = bill['SerialNO'];
//     // var dataDeliveryNote = bill['DeliveryNote'];
//     var otherAmount = bill['otherAmount'];
//     // header
//     var taxSale = salesTypeData.type == 'SALES-ES'
//         ? false
//         : salesTypeData.type == 'SALES-Q'
//             ? false
//             : salesTypeData.type == 'SALES-O'
//                 ? false
//                 : true;
//     var invoiceHead = salesTypeData.type == 'SALES-ES'
//         ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
//         : salesTypeData.type == 'SALES-Q'
//             ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
//             : salesTypeData.type == 'SALES-O'
//                 ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
//                 : Settings.getValue<String>(
//                     'key-sales-invoice-head', 'INVOICE');
//     bool isQrcodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
//     bool isEsQrCodeKSA =
//         ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
//     int printCopy = Settings.getValue<int>('key-dropdown-print-copy-view', 0);
//     int printerModel =
//         Settings.getValue<int>('key-dropdown-printer-model-view', 0);
//     // for (int pCopy = 0; pCopy <= printCopy; pCopy++) {
//     // if (printerModel == 2) {
//     try {
//       if (taxSale) {
//         ticket.text(
//           companySettings.name'],
//           styles: const PosStyles(
//             align: PosAlign.center,
//             bold: true,
//             // height: PosTextSize.size2,
//             // width: PosTextSize.size2,
//           ),
//         );
//         // if(printCopy==2){
//         //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
//         //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
//         //   ticket.text('عبدالله زهير',containsChinese: false,styles: const PosStyles(align: PosAlign.center,codeTable: ,
//         //       bold: true,));
//         //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
//         //   //   bold: true,));
//         // }
//         // linesAfter: 1);
//         // header1
//         companySettings.add1'].toString().trim().isNotEmpty ??
//             ticket.text(companySettings.add1'],
//                 styles: const PosStyles(align: PosAlign.center));
//         companySettings.add2'].toString().trim().isNotEmpty ??
//             ticket.text(companySettings.add2'],
//                 styles: const PosStyles(align: PosAlign.center));
//         ticket.text(
//             'Tel : ${companySettings.telephone'] + ',' + companySettings.mobile']}',
//             styles: const PosStyles(align: PosAlign.center));
//         ticket.text(
//             companyTaxMode == 'INDIA'
//                 ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
//                 : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
//             styles: const PosStyles(align: PosAlign.center));
//         ticket.text(invoiceHead,
//             styles: const PosStyles(align: PosAlign.center, bold: true));
//         // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
//         //     styles: const PosStyles(align: PosAlign.left));
//         ticket.row([
//           PosColumn(
//               text: 'Invoice No : ${dataInformation['InvoiceNo']}',
//               width: 6,
//               styles: const PosStyles(align: PosAlign.left)),
//           PosColumn(
//               text:
//                   'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
//               width: 6,
//               styles: const PosStyles(align: PosAlign.right)),
//         ]);
//         ticket.text('Bill To : ${dataInformation['ToName']}',
//             styles: const PosStyles(align: PosAlign.left));
//         if (isEsQrCodeKSA) {
//           if (dataInformation['gstno'].toString().trim().isNotEmpty) {
//             ticket.text(
//                 companyTaxMode == 'INDIA'
//                     ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
//                     : 'TRN : ${dataInformation['gstno'].toString().trim()}',
//                 styles: const PosStyles(align: PosAlign.left));
//           }
//         }
//         ticket.hr();
//         ticket.row([
//           PosColumn(text: 'Description', width: 7),
//           PosColumn(text: 'Qty', width: 1),
//           PosColumn(
//               text: 'Price',
//               width: 2,
//               styles: const PosStyles(align: PosAlign.right)),
//           PosColumn(
//               text: 'Total',
//               width: 2,
//               styles: const PosStyles(align: PosAlign.right)),
//         ]);
//         double totalQty = 0, totalRate = 0;
//         for (var i = 0; i < dataParticulars.length; i++) {
//           if (double.tryParse(dataParticulars[i]['igst'].toString()) > 0) {
//             if (taxPercentages
//                 .contains('@' + dataParticulars[i]['igst'].toString() + ' %')) {
//             } else {
//               taxPercentages +=
//                   '@' + dataParticulars[i]['igst'].toString() + ' %,';
//             }
//           }
//           var itemName = paper.width == PaperSize.mm80.width
//               ? dataParticulars[i]['itemname'].toString().trim().length > 26
//                   ? dataParticulars[i]['itemname']
//                       .toString()
//                       .trim()
//                       .characters
//                       .take(26)
//                       .toString()
//                   : dataParticulars[i]['itemname'].toString()
//               : dataParticulars[i]['itemname'].toString().trim().length > 12
//                   ? dataParticulars[i]['itemname']
//                       .toString()
//                       .trim()
//                       .characters
//                       .take(12)
//                       .toString()
//                   : dataParticulars[i]['itemname'].toString();
//           ticket.row([
//             PosColumn(text: itemName, width: 7),
//             PosColumn(
//                 text:
//                     '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
//                 width: 1),
//             PosColumn(
//                 text: '${dataParticulars[i]['Rate']}',
//                 width: 2,
//                 styles: const PosStyles(align: PosAlign.right)),
//             PosColumn(
//                 text: '${dataParticulars[i]['Total']}',
//                 width: 2,
//                 styles: const PosStyles(align: PosAlign.right)),
//           ]);
//           totalQty += dataParticulars[i]['Qty'];
//           totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
//         }
//         ticket.hr();
//         ticket.row([
//           PosColumn(text: 'Total : ', width: 7),
//           PosColumn(text: '$totalQty', width: 1),
//           PosColumn(
//               text: totalRate.toStringAsFixed(2),
//               width: 2,
//               styles: const PosStyles(align: PosAlign.right)),
//           PosColumn(
//               text: '${dataInformation['Total']}',
//               width: 2,
//               styles: const PosStyles(align: PosAlign.right)),
//         ]);
//         ticket.hr();
//         ticket.row([
//           PosColumn(
//               text: 'Total :',
//               width: 6,
//               styles: const PosStyles(
//                 // height: PosTextSize.size1,
//                 // width: PosTextSize.size1,
//                 align: PosAlign.right,
//               )),
//           PosColumn(
//               text: '${dataInformation['NetAmount']}',
//               width: 6,
//               styles: const PosStyles(
//                 align: PosAlign.right,
//                 // height: PosTextSize.size3,
//                 // width: PosTextSize.size2,
//               )),
//         ]);
//         ticket.hr();
//         ticket.row([
//           PosColumn(
//               text: 'Tax : ' + taxPercentages,
//               width: 6,
//               styles: const PosStyles(
//                 // height: PosTextSize.size3,
//                 // width: PosTextSize.size2,
//                 align: PosAlign.right,
//               )),
//           PosColumn(
//               text: (double.tryParse(dataInformation['CGST'].toString()) +
//                       double.tryParse(dataInformation['SGST'].toString()) +
//                       double.tryParse(dataInformation['IGST'].toString()))
//                   .toStringAsFixed(2),
//               width: 6,
//               styles: const PosStyles(
//                 align: PosAlign.right,
//                 // height: PosTextSize.size3,
//                 // width: PosTextSize.size2,
//               )),
//         ]);
//       } else {
//         if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
//           ticket.text(
//             companySettings.name'],
//             styles: const PosStyles(
//               align: PosAlign.center,
//               bold: true,
//               // height: PosTextSize.size2,
//               // width: PosTextSize.size2,
//             ),
//           );
//           // if (printCopy == 2) {
//           //   //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
//           //   //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
//           //   ticket.text('عبدالله زهير');
//           //   //       bold: true,));
//           //   //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
//           //   //   //   bold: true,));
//           // }
//           // linesAfter: 1);
//           // header1
//           companySettings.add1'].toString().trim().isNotEmpty ??
//               ticket.text(companySettings.add1'],
//                   styles: const PosStyles(align: PosAlign.center));
//           companySettings.add2'].toString().trim().isNotEmpty ??
//               ticket.text(companySettings.add2'],
//                   styles: const PosStyles(align: PosAlign.center));
//           ticket.text(
//               'Tel : ${companySettings.telephone'] + ',' + companySettings.mobile']}',
//               styles: const PosStyles(align: PosAlign.center));
//           ticket.text(
//               companyTaxMode == 'INDIA'
//                   ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
//                   : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
//               styles: const PosStyles(align: PosAlign.center));
//           ticket.text(invoiceHead,
//               styles: const PosStyles(align: PosAlign.center, bold: true));
//           // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
//           //     styles: const PosStyles(align: PosAlign.left));
//           ticket.row([
//             PosColumn(
//                 text: 'Invoice No : ${dataInformation['InvoiceNo']}',
//                 width: 6,
//                 styles: const PosStyles(align: PosAlign.left)),
//             PosColumn(
//                 text:
//                     'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
//                 width: 6,
//                 styles: const PosStyles(align: PosAlign.right)),
//           ]);
//         } else {
//           ticket.text(invoiceHead,
//               styles: const PosStyles(align: PosAlign.center, bold: true));
//           // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
//           //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
//           ticket.row([
//             PosColumn(
//                 text: 'Invoice No : ${dataInformation['InvoiceNo']}',
//                 width: 6,
//                 styles: const PosStyles(align: PosAlign.left)),
//             PosColumn(
//                 text:
//                     'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
//                 width: 6,
//                 styles: const PosStyles(align: PosAlign.right)),
//           ]);
//         }
//         ticket.text('Bill To : ${dataInformation['ToName']}',
//             styles: const PosStyles(align: PosAlign.left));
//
//         if (isEsQrCodeKSA) {
//           if (dataInformation['gstno'].toString().trim().isNotEmpty) {
//             ticket.text(
//                 companyTaxMode == 'INDIA'
//                     ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
//                     : 'TRN : ${dataInformation['gstno'].toString().trim()}',
//                 styles: const PosStyles(align: PosAlign.left));
//           }
//         }
//         ticket.hr();
//         ticket.row([
//           PosColumn(text: 'Description', width: 7),
//           PosColumn(text: 'Qty', width: 1),
//           PosColumn(
//               text: 'Price',
//               width: 2,
//               styles: const PosStyles(align: PosAlign.right)),
//           PosColumn(
//               text: 'Total',
//               width: 2,
//               styles: const PosStyles(align: PosAlign.right)),
//         ]);
//         ticket.hr();
//         double totalQty = 0, totalRate = 0;
//         for (var i = 0; i < dataParticulars.length; i++) {
//           var itemName = paper.width == PaperSize.mm80.width
//               ? dataParticulars[i]['itemname'].toString().trim().length > 26
//                   ? dataParticulars[i]['itemname']
//                       .toString()
//                       .trim()
//                       .characters
//                       .take(26)
//                       .toString()
//                   : dataParticulars[i]['itemname'].toString()
//               : dataParticulars[i]['itemname'].toString().trim().length > 12
//                   ? dataParticulars[i]['itemname']
//                       .toString()
//                       .trim()
//                       .characters
//                       .take(12)
//                       .toString()
//                   : dataParticulars[i]['itemname'].toString();
//           ticket.row([
//             PosColumn(text: itemName, width: 7),
//             PosColumn(
//                 text:
//                     '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
//                 width: 1,
//                 styles: const PosStyles(align: PosAlign.right)),
//             PosColumn(
//                 text: double.tryParse(dataParticulars[i]['Rate'].toString())
//                     .toStringAsFixed(2),
//                 width: 2,
//                 styles: const PosStyles(align: PosAlign.right)),
//             PosColumn(
//                 text: double.tryParse(dataParticulars[i]['Total'].toString())
//                     .toStringAsFixed(2),
//                 width: 2,
//                 styles: const PosStyles(align: PosAlign.right)),
//           ]);
//           totalQty += dataParticulars[i]['Qty'];
//           totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
//         }
//         ticket.hr();
//         ticket.row([
//           PosColumn(text: 'Total :- ', width: 7),
//           PosColumn(text: '$totalQty', width: 1),
//           PosColumn(
//               text: totalRate.toStringAsFixed(2),
//               width: 2,
//               styles: const PosStyles(align: PosAlign.right)),
//           PosColumn(
//               text: double.tryParse(dataInformation['Total'].toString())
//                   .toStringAsFixed(2),
//               width: 2,
//               styles: const PosStyles(align: PosAlign.right)),
//         ]);
//         ticket.hr();
//         ticket.row([
//           PosColumn(
//               text: 'Total :',
//               width: 6,
//               styles: const PosStyles(
//                 // height: PosTextSize.size1,
//                 // width: PosTextSize.size1,
//                 align: PosAlign.right,
//               )),
//           PosColumn(
//               text: double.tryParse(dataInformation['Total'].toString())
//                   .toStringAsFixed(2),
//               width: 6,
//               styles: const PosStyles(
//                 align: PosAlign.right,
//                 // height: PosTextSize.size3,
//                 // width: PosTextSize.size2,
//               )),
//         ]);
//       }
//       for (var i = 0; i < otherAmount.length; i++) {
//         if (otherAmount[i]['Amount'].toDouble() > 0) {
//           ticket.hr();
//           ticket.row([
//             PosColumn(
//                 text: '${otherAmount[i]['LedName']} :',
//                 width: 6,
//                 styles: const PosStyles(align: PosAlign.right
//                     // height: PosTextSize.size2,
//                     // width: PosTextSize.size2,
//                     )),
//             PosColumn(
//                 text: double.tryParse(otherAmount[i]['Amount'].toString())
//                     .toStringAsFixed(2),
//                 width: 6,
//                 styles: const PosStyles(
//                   align: PosAlign.right,
//                   // height: PosTextSize.size2,
//                   // width: PosTextSize.size2,
//                 )),
//           ]);
//         }
//       }
//       ticket.hr();
//       ticket.row([
//         PosColumn(
//             text: 'Net Amount :',
//             width: 6,
//             styles: const PosStyles(
//                 // height: PosTextSize.size2, width: PosTextSize.size2,
//                 bold: true,
//                 align: PosAlign.right)),
//         PosColumn(
//             text: double.tryParse(dataInformation['GrandTotal'].toString())
//                 .toStringAsFixed(2),
//             width: 6,
//             styles: const PosStyles(
//                 align: PosAlign.right,
//                 // height: PosTextSize.size2,
//                 // width: PosTextSize.size2,
//                 bold: true)),
//       ]);
//       ticket.hr();
//       ticket.text(
//           'Amount in Words: ${NumberToWord().convert('en', double.tryParse(dataInformation['GrandTotal'].toString()).round())}',
//           linesAfter: 1);
//
//       // ticket.feed(1);
//       ticket.text('${bill['message']}',
//           styles: const PosStyles(align: PosAlign.center));
//
//       if (isQrcodeKSA) {
//         // Print QR Code using native function
//         // bytes += ticket.qrcode('example.com');
//         if (taxSale) {
//           ticket.qrcode(SaudiConversion.getBase64(
//               companySettings.name'],
//               ComSettings.getValue('GST-NO', settings),
//               DateUtil.dateTimeQrDMY(
//                   DateUtil.datedYMD(dataInformation['DDate']) +
//                       ' ' +
//                       DateUtil.timeHMS(dataInformation['BTime'])),
//               double.tryParse(dataInformation['GrandTotal'].toString())
//                   .toStringAsFixed(2),
//               (double.tryParse(dataInformation['CGST'].toString()) +
//                       double.tryParse(dataInformation['SGST'].toString()) +
//                       double.tryParse(dataInformation['IGST'].toString()))
//                   .toStringAsFixed(2)));
//           ticket.feed(
//               ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
//         } else if (isEsQrCodeKSA) {
//           ticket.qrcode(SaudiConversion.getBase64(
//               companySettings.name'],
//               ComSettings.getValue('GST-NO', settings),
//               DateUtil.dateTimeQrDMY(
//                   DateUtil.datedYMD(dataInformation['DDate']) +
//                       ' ' +
//                       DateUtil.timeHMS(dataInformation['BTime'])),
//               double.tryParse(dataInformation['GrandTotal'].toString())
//                   .toStringAsFixed(2),
//               (double.tryParse(dataInformation['CGST'].toString()) +
//                       double.tryParse(dataInformation['SGST'].toString()) +
//                       double.tryParse(dataInformation['IGST'].toString()))
//                   .toStringAsFixed(2)));
//           ticket.feed(
//               ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
//         }
//       } else {
//         ticket
//             .feed(ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
//       }
//       // ticket.cut();
//       // FirebaseCrashlytics.instance
//       //     .setCustomKey('str_key', 'bt print complited');
//       return ticket;
//     } catch (e, s) {
//       FirebaseCrashlytics.instance
//           .recordError(e, s, reason: 'bt print:' + ticket.toString());
//       return ticket;
//     }
//     // } else if (printerModel == 6) {
//     //   try {
//     //     // Print image
//     //     final Uint8List bytes = widget.byteImage;
//     //     final img.Image image = img.decodeImage(bytes);
//     //     ticket.image(image);
//     //     ticket.feed(2);
//     //     ticket.cut();
//     //     return ticket;
//     //   } catch (e, s) {
//     //     FirebaseCrashlytics.instance
//     //         .recordError(e, s, reason: 'bt print:' + ticket.toString());
//     //     return ticket;
//     //   }
//     // }
//     // }
//   }
//
//   Future<Ticket> demoReceipt(PaperSize paper) async {
//     final Ticket ticket = Ticket(paper);
//
//     // Print image
//     // final ByteData data = await rootBundle.load('assets/logo.png');
//     // final Uint8List bytes = data.buffer.asUint8List();
//     // ticket.image(image);
//
//     ticket.text('GROCERYLY',
//         styles: const PosStyles(
//           align: PosAlign.center,
//           height: PosTextSize.size2,
//           width: PosTextSize.size2,
//         ),
//         linesAfter: 1);
//
//     ticket.text('889  Watson Lane',
//         styles: const PosStyles(align: PosAlign.center));
//     ticket.text('New Braunfels, TX',
//         styles: const PosStyles(align: PosAlign.center));
//     ticket.text('Tel: 830-221-1234',
//         styles: const PosStyles(align: PosAlign.center));
//     ticket.text('Web: www.example.com',
//         styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
//
//     ticket.hr();
//     ticket.row([
//       PosColumn(text: 'Qty', width: 1),
//       PosColumn(text: 'Item', width: 7),
//       PosColumn(
//           text: 'Price',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.right)),
//       PosColumn(
//           text: 'Total',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.right)),
//     ]);
//
//     ticket.row([
//       PosColumn(text: '2', width: 1),
//       PosColumn(text: 'ONION RINGS', width: 7),
//       PosColumn(
//           text: '0.99',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.right)),
//       PosColumn(
//           text: '1.98',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.right)),
//     ]);
//     ticket.row([
//       PosColumn(text: '1', width: 1),
//       PosColumn(text: 'PIZZA', width: 7),
//       PosColumn(
//           text: '3.45',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.right)),
//       PosColumn(
//           text: '3.45',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.right)),
//     ]);
//     ticket.row([
//       PosColumn(text: '1', width: 1),
//       PosColumn(text: 'SPRING ROLLS', width: 7),
//       PosColumn(
//           text: '2.99',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.right)),
//       PosColumn(
//           text: '2.99',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.right)),
//     ]);
//     ticket.row([
//       PosColumn(text: '3', width: 1),
//       PosColumn(text: 'CRUNCHY STICKS', width: 7),
//       PosColumn(
//           text: '0.85',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.right)),
//       PosColumn(
//           text: '2.55',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.right)),
//     ]);
//     ticket.hr();
//
//     ticket.row([
//       PosColumn(
//           text: 'TOTAL',
//           width: 6,
//           styles: const PosStyles(
//             height: PosTextSize.size2,
//             width: PosTextSize.size2,
//           )),
//       PosColumn(
//           text: '\$10.97',
//           width: 6,
//           styles: const PosStyles(
//             align: PosAlign.right,
//             height: PosTextSize.size2,
//             width: PosTextSize.size2,
//           )),
//     ]);
//
//     ticket.hr(ch: '=', linesAfter: 1);
//
//     ticket.row([
//       PosColumn(
//           text: 'Cash',
//           width: 7,
//           styles:
//               const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
//       PosColumn(
//           text: '\$15.00',
//           width: 5,
//           styles:
//               const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
//     ]);
//     ticket.row([
//       PosColumn(
//           text: 'Change',
//           width: 7,
//           styles:
//               const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
//       PosColumn(
//           text: '\$4.03',
//           width: 5,
//           styles:
//               const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
//     ]);
//
//     ticket.feed(2);
//     ticket.text('Thank you!',
//         styles: const PosStyles(align: PosAlign.center, bold: true));
//
//     final now = DateTime.now();
//     final formatter = DateFormat('MM/dd/yyyy H:m');
//     final String timestamp = formatter.format(now);
//     ticket.text(timestamp,
//         styles: const PosStyles(align: PosAlign.center), linesAfter: 2);
//
//     // Print QR Code from image
//     // try {
//     //   const String qrData = 'example.com';
//     //   const double qrSize = 200;
//     //   final uiImg = await QrPainter(
//     //     data: qrData,
//     //     version: QrVersions.auto,
//     //     gapless: false,
//     //   ).toImageData(qrSize);
//     //   final dir = await getTemporaryDirectory();
//     //   final pathName = '${dir.path}/qr_tmp.png';
//     //   final qrFile = File(pathName);
//     //   final imgFile = await qrFile.writeAsBytes(uiImg.buffer.asUint8List());
//     //   final img = decodeImage(imgFile.readAsBytesSync());
//
//     //   ticket.image(img);
//     // } catch (e) {
//     //   print(e);
//     // }
//
//     // Print QR Code using native function
//     // ticket.qrcode('example.com');
//
//     ticket.feed(2);
//     ticket.cut();
//     return ticket;
//   }
// }
