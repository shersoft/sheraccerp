// // @dart = 2.9
// import 'dart:typed_data';
// import 'package:esc_pos_utils/esc_pos_utils.dart';
// import 'package:image/image.dart' as img;
// import 'package:intl/intl.dart';
// import 'package:flutter/services.dart';
// import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
// import 'package:flutter/material.dart';
//
// class PrintSettings extends StatefulWidget {
//   const PrintSettings({Key key}) : super(key: key);
//
//   @override
//   _PrintSettingsState createState() => _PrintSettingsState();
// }
//
// class _PrintSettingsState extends State<PrintSettings> {
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
//   }
//
//   void _startScanDevices() {
//     setState(() {
//       _devices = [];
//     });
//     printerManager.startScan(const Duration(seconds: 4));
//   }
//
//   void _stopScanDevices() {
//     printerManager.stopScan();
//   }
//
//   Future<Ticket> demoReceipt(PaperSize paper) async {
//     final Ticket ticket = Ticket(paper);
//
//     // Print image
//     // final ByteData data = await rootBundle.load('assets/logo.png');
//     // final Uint8List bytes = data.buffer.asUint8List();
//     // final img.Image image = img.decodeImage(bytes);
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
//
//   Future<Ticket> testTicket(PaperSize paper) async {
//     final Ticket ticket = Ticket(paper);
//
//     ticket.text(
//         'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
//     ticket.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
//         styles: const PosStyles(codeTable: PosCodeTable.westEur));
//     ticket.text('Special 2: blåbærgrød',
//         styles: const PosStyles(codeTable: PosCodeTable.westEur));
//
//     ticket.text('Bold text', styles: const PosStyles(bold: true));
//     ticket.text('Reverse text', styles: const PosStyles(reverse: true));
//     ticket.text('Underlined text',
//         styles: const PosStyles(underline: true), linesAfter: 1);
//     ticket.text('Align left', styles: const PosStyles(align: PosAlign.left));
//     ticket.text('Align center',
//         styles: const PosStyles(align: PosAlign.center));
//     ticket.text('Align right',
//         styles: const PosStyles(align: PosAlign.right), linesAfter: 1);
//
//     ticket.row([
//       PosColumn(
//         text: 'col3',
//         width: 3,
//         styles: const PosStyles(align: PosAlign.center, underline: true),
//       ),
//       PosColumn(
//         text: 'col6',
//         width: 6,
//         styles: const PosStyles(align: PosAlign.center, underline: true),
//       ),
//       PosColumn(
//         text: 'col3',
//         width: 3,
//         styles: const PosStyles(align: PosAlign.center, underline: true),
//       ),
//     ]);
//
//     ticket.text('Text size 200%',
//         styles: const PosStyles(
//           height: PosTextSize.size2,
//           width: PosTextSize.size2,
//         ));
//
//     // Print image
//     final ByteData data = await rootBundle.load('assets/logo.png');
//     final Uint8List bytes = data.buffer.asUint8List();
//     final img.Image image = img.decodeImage(bytes);
//     ticket.image(image);
//     // Print image using alternative commands
//     // ticket.imageRaster(image);
//     // ticket.imageRaster(image, imageFn: PosImageFn.graphics);
//
//     // Print barcode
//     final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
//     ticket.barcode(Barcode.upcA(barData));
//
//     // Print mixed (chinese + latin) text. Only for printers supporting Kanji mode
//     // ticket.text(
//     //   'hello ! 中文字 # world @ éphémère &',
//     //   styles: PosStyles(codeTable: PosCodeTable.westEur),
//     //   containsChinese: true,
//     // );
//
//     ticket.feed(2);
//
//     ticket.cut();
//     return ticket;
//   }
//
//   void _testPrint(PrinterBluetooth printer) async {
//     printerManager.selectPrinter(printer);
//
//     const PaperSize paper = PaperSize.mm80;
//
//     // TEST PRINT
//     // final PosPrintResult res =
//     // await printerManager.printTicket(await testTicket(paper));
//
//     // DEMO RECEIPT
//     final PosPrintResult res =
//         await printerManager.printTicket(await demoReceipt(paper));
//
//     showDialog(
//         context: context,
//         builder: (context) => AlertDialog(content: Text(res.msg)));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Test Print'),
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
// }
