// @dart = 2.11
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/util/dateUtil.dart';
// import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart' hide Image;
// import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:flutter/services.dart';
import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/service/network_printer.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/number_to_word.dart';
import 'package:wifi/wifi.dart';

class TCPPrinter extends StatefulWidget {
  final data;
  final Uint8List byteImage;

  const TCPPrinter(this.data, this.byteImage, {Key key}) : super(key: key);

  @override
  State<TCPPrinter> createState() => _TCPPrinterState();
}

class _TCPPrinterState extends State<TCPPrinter> {
  String localIp = '';
  List<String> devices = [];
  bool isDiscovering = false;
  int found = -1;
  TextEditingController portController = TextEditingController(text: '9100');
  var companyTaxMode = '';
  int printModel = 2;

  void discover(BuildContext ctx) async {
    setState(() {
      isDiscovering = true;
      devices.clear();
      found = -1;
    });

    String ip;
    try {
      ip = await Wifi.ip;
      debugPrint('local ip:\t$ip');
    } catch (e) {
      final snackBar = const SnackBar(
          content: Text('WiFi is not connected', textAlign: TextAlign.center));
      ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
      return;
    }
    setState(() {
      localIp = ip;
    });

    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    int port = 9100;
    try {
      port = int.parse(portController.text);
    } catch (e) {
      portController.text = port.toString();
    }
    debugPrint('subnet:\t$subnet, port:\t$port');

    final stream = NetworkAnalyzer.discover2(subnet, port);

    stream.listen((NetworkAddress addr) {
      if (addr.exists) {
        debugPrint('Found device: ${addr.ip}');
        setState(() {
          devices.add(addr.ip);
          found = devices.length;
        });
      }
    })
      ..onDone(() {
        setState(() {
          isDiscovering = false;
          found = devices.length;
        });
      })
      ..onError((dynamic e) {
        final snackBar = const SnackBar(
            content: Text('Unexpected exception', textAlign: TextAlign.center));
        ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Printers'),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                TextField(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: 'Port',
                  ),
                ),
                const SizedBox(height: 10),
                Text('Local ip: $localIp',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 15),
                ElevatedButton(
                    child: Text(isDiscovering ? 'Discovering...' : 'Discover'),
                    onPressed: isDiscovering ? null : () => discover(context)),
                const SizedBox(height: 15),
                found >= 0
                    ? Text('Found: $found device(s)',
                        style: const TextStyle(fontSize: 16))
                    : Container(),
                Expanded(
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (BuildContext context, int index) {
                      return InkWell(
                        onTap: () => setPrint(devices[index], context),
                        child: Column(
                          children: <Widget>[
                            Container(
                              height: 60,
                              padding: const EdgeInsets.only(left: 10),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.print),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          '${devices[index]}:${portController.text}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          'Click to print a test receipt',
                                          style: TextStyle(
                                              color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                            const Divider(),
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> printDemoReceipt(NetworkPrinter printer) async {
    // Print image
    final ByteData data = await rootBundle.load('assets/logo1.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final Image image = decodeImage(bytes);
    printer.image(image);

    printer.text('GROCERYLY',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    printer.text('889  Watson Lane',
        styles: const PosStyles(align: PosAlign.center));
    printer.text('New Braunfels, TX',
        styles: const PosStyles(align: PosAlign.center));
    printer.text('Tel: 830-221-1234',
        styles: const PosStyles(align: PosAlign.center));
    printer.text('Web: www.example.com',
        styles: const PosStyles(align: PosAlign.center), linesAfter: 1);

    printer.hr();
    printer.row([
      PosColumn(text: 'Qty', width: 1),
      PosColumn(text: 'Item', width: 7),
      PosColumn(
          text: 'Price',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: 'Total',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    printer.row([
      PosColumn(text: '2', width: 1),
      PosColumn(text: 'ONION RINGS', width: 7),
      PosColumn(
          text: '0.99',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '1.98',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    printer.row([
      PosColumn(text: '1', width: 1),
      PosColumn(text: 'PIZZA', width: 7),
      PosColumn(
          text: '3.45',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '3.45',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    printer.row([
      PosColumn(text: '1', width: 1),
      PosColumn(text: 'SPRING ROLLS', width: 7),
      PosColumn(
          text: '2.99',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '2.99',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    printer.row([
      PosColumn(text: '3', width: 1),
      PosColumn(text: 'CRUNCHY STICKS', width: 7),
      PosColumn(
          text: '0.85',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: '2.55',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    printer.hr();

    printer.row([
      PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )),
      PosColumn(
          text: '\$10.97',
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )),
    ]);

    printer.hr(ch: '=', linesAfter: 1);

    printer.row([
      PosColumn(
          text: 'Cash',
          width: 8,
          styles:
              const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
      PosColumn(
          text: '\$15.00',
          width: 4,
          styles:
              const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
    ]);
    printer.row([
      PosColumn(
          text: 'Change',
          width: 8,
          styles:
              const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
      PosColumn(
          text: '\$4.03',
          width: 4,
          styles:
              const PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
    ]);

    printer.feed(2);
    printer.text('Thank you!',
        styles: const PosStyles(align: PosAlign.center, bold: true));

    final now = DateTime.now();
    final formatter = DateFormat('MM/dd/yyyy H:m');
    final String timestamp = formatter.format(now);
    printer.text(timestamp,
        styles: const PosStyles(align: PosAlign.center), linesAfter: 2);

    // Print QR Code from image
    // try {
    //   const String qrData = 'example.com';
    //   const double qrSize = 200;
    //   final uiImg = await QrPainter(
    //     data: qrData,
    //     version: QrVersions.auto,
    //     gapless: false,
    //   ).toImageData(qrSize);
    //   final dir = await getTemporaryDirectory();
    //   final pathName = '${dir.path}/qr_tmp.png';
    //   final qrFile = File(pathName);
    //   final imgFile = await qrFile.writeAsBytes(uiImg.buffer.asUint8List());
    //   final img = decodeImage(imgFile.readAsBytesSync());

    //   printer.image(img);
    // } catch (e) {
    //   debugPrint(e);
    // }

    // Print QR Code using native function
    // printer.qrcode('example.com');

    printer.feed(1);
    printer.cut();
  }

  void testPrint(String printerIp, BuildContext ctx) async {
    // TODO Don't forget to choose printer's paper size
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);

    final PosPrintResult res = await printer.connect(printerIp, port: 9100);

    if (res == PosPrintResult.success) {
      // DEMO RECEIPT
      await printDemoReceipt(printer);
      // TEST PRINT
      // await testReceipt(printer);
      printer.disconnect();
    }

    final snackBar =
        SnackBar(content: Text(res.msg, textAlign: TextAlign.center));
    ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
  }

  void setPrint(String printerIp, BuildContext context) async {
    debugPrint(printerIp);

    var printerSize = widget.data[3];
    PaperSize paper = PaperSize.mm80;
    // if (printerSize == "3") {
    //   paper = PaperSize.mm58;
    // } else if (printerSize == "4") {
    //   paper = PaperSize.mm80;
    // } else {
    //   paper = PaperSize.mm58;
    // }

    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);

    final PosPrintResult res = await printer.connect(printerIp, port: 9100);

    if (res == PosPrintResult.success) {
      if (widget.data.isNotEmpty) {
        printModel = ComSettings.appSettings(
            'int', "key-dropdown-printer-model-view", 2);
        if (widget.data[4] == 'SALE') {
          await (printModel == 3
              ? salesVatData(printer, paper)
              : printModel == 4
                  ? salesGSTData(printer, paper)
                  : printModel == 5
                      ? salesVat1Data(printer, paper)
                      : salesDefaultData(printer, paper));
          showDialog(
              context: context,
              builder: (context) => AlertDialog(content: Text(res.msg)));
        } else if (widget.data[4] == 'SALES RETURN') {
          await salesReturnData(printer, paper);
          showDialog(
              context: context,
              builder: (context) => AlertDialog(content: Text(res.msg)));
        } else if (widget.data[4] == 'RECEIPT') {
          await receiptData(printer, paper);
          showDialog(
              context: context,
              builder: (context) => AlertDialog(content: Text(res.msg)));
        } else if (widget.data[4] == 'PAYMENT') {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(content: Text(res.msg)));
        }
      } else {
        await testData(printer, paper);
        showDialog(
            context: context,
            builder: (context) => AlertDialog(content: Text(res.msg)));
      }

      printer.disconnect();
    }

    final snackBar =
        SnackBar(content: Text(res.msg, textAlign: TextAlign.center));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> printImage(NetworkPrinter printer) async {
    // Print image
    final Uint8List bytess = widget.byteImage;
    final Image image = decodeImage(bytess);
    printer.image(image);
  }

  var taxPercentages = '';
  List<dynamic> taxableData = [];

  Future<void> salesVatData(NetworkPrinter printer, PaperSize paper) async {
    var bill = widget.data[2];
    var printerSize = widget.data[3];
    CompanyInformation companySettings = widget.data[0];
    List<CompanySettings> settings = widget.data[1];
    var dataInformation = bill['Information'][0];
    var dataParticulars = bill['Particulars'];
    // var dataSerialNO = bill['SerialNO'];
    // var dataDeliveryNote = bill['DeliveryNote'];
    var otherAmount = bill['otherAmount'];
    var ledgerName = mainAccount
        .firstWhere(
          (element) =>
              element['LedCode'].toString() ==
              dataInformation['Customer'].toString(),
          orElse: () => {'LedName': dataInformation['ToName']},
        )['LedName']
        .toString();
    // header
    var taxSale = salesTypeData.type == 'SALES-ES'
        ? false
        : salesTypeData.type == 'SALES-Q'
            ? false
            : salesTypeData.type == 'SALES-O'
                ? false
                : true;
    var invoiceHead = salesTypeData.type == 'SALES-ES'
        ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
        : salesTypeData.type == 'SALES-Q'
            ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
            : salesTypeData.type == 'SALES-O'
                ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
                : Settings.getValue<String>(
                    'key-sales-invoice-head', 'INVOICE');
    bool isQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
    bool isEsQrCodeKSA =
        ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
    int printCopy = Settings.getValue<int>('key-dropdown-print-copy-view', 0);
    int printerModel =
        Settings.getValue<int>('key-dropdown-printer-model-view', 0);
    // for (int pCopy = 0; pCopy <= printCopy; pCopy++) {
    if (printerSize == "2") {
      try {
        if (taxSale) {
          printer.text(
            companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              // height: PosTextSize.size2,
              // width: PosTextSize.size2,
            ),
          );
          companySettings.add1.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add1,
                  styles: const PosStyles(align: PosAlign.center, bold: true)));
          companySettings.add2.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add2,
                  styles: const PosStyles(align: PosAlign.center, bold: true)));
          printer.text(
              'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          printer.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          printer.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          printer.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text:
                    'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.text('Bill To : ',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          printer.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              printer.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left, bold: true));
            }
          }
          printer.hr();
          printer.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          printer.row([
            PosColumn(
                text: '   ',
                width: 2,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: 'Qty',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Price',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Total',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            if (double.tryParse(dataParticulars[i]['igst'].toString()) > 0) {
              if (taxPercentages.contains(
                  '@' + dataParticulars[i]['igst'].toString() + ' %')) {
              } else {
                taxPercentages +=
                    '@' + dataParticulars[i]['igst'].toString() + ' %,';
              }
            }
            var itemName = dataParticulars[i]['itemname'].toString();
            printer.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            printer.row([
              PosColumn(text: '', width: 2),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 1),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total : ',
                width: 5,
                styles: const PosStyles(bold: true)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(bold: true)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 2,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size1,
                    // width: PosTextSize.size1,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: '${dataInformation['NetAmount']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Tax : ' + taxPercentages,
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
        } else {
          if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
            printer.text(
              companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            printer.text(
              '',
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            // if (printCopy == 2) {
            //   //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
            //   //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
            //   ticket.text('عبدالله زهير');
            //   //       bold: true,));
            //   //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
            //   //   //   bold: true,));
            // }
            // linesAfter: 1);
            // header1
            companySettings.add1.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add1,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add2,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            printer.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            printer.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          } else {
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            printer.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          }
          printer.hr();

          printer.text('Bill To :',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          printer.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              printer.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left, bold: true));
            }
          }
          printer.hr();
          printer.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          printer.row([
            PosColumn(text: ' ', width: 1),
            PosColumn(
                text: 'Qty', width: 3, styles: const PosStyles(bold: true)),
            PosColumn(
                text: 'Price',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Total',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            printer.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            printer.row([
              PosColumn(text: '', width: 1),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 3,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Rate'].toString())
                      .toStringAsFixed(2),
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Total'].toString())
                      .toStringAsFixed(2),
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Sub =',
                width: 3,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size1,
                    // width: PosTextSize.size1,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
        }
        for (var i = 0; i < otherAmount.length; i++) {
          if (otherAmount[i]['Amount'].toDouble() > 0) {
            printer.hr();
            printer.row([
              PosColumn(
                  text: '${otherAmount[i]['LedName']} :',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      )),
              PosColumn(
                  text: double.tryParse(otherAmount[i]['Amount'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                  )),
            ]);
          }
        }
        // printer.hr();
        // printer.text(
        //     'Amount in Words: ${NumberToWord().convertToDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
        //     linesAfter: 1);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Net Amount :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size2, width: PosTextSize.size2,
                    bold: true,
                    align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                    bold: true)),
          ]);
        } else {
          if (ledgerName != 'CASH') {
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Old Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataInformation['Balance'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Net Amount :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text:
                      double.tryParse(dataInformation['GrandTotal'].toString())
                          .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Cash Received :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(
                          dataInformation['CashReceived'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: (double.tryParse(
                              dataInformation['Balance'].toString()) +
                          (double.tryParse(
                                  dataInformation['GrandTotal'].toString()) -
                              double.tryParse(
                                  dataInformation['CashReceived'].toString())))
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          } else {
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Net Amount :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text:
                      double.tryParse(dataInformation['GrandTotal'].toString())
                          .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          }
        }

        // ticket.feed(1);
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        if (isQrCodeKSA) {
          // Print QR Code using native function
          // printer.qrcode('example.com');
          if (taxSale) {
            printer.qrcode(SaudiConversion.getBase64(
                companySettings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(
                    DateUtil.datedYMD(dataInformation['DDate']) +
                        ' ' +
                        DateUtil.timeHMS(dataInformation['BTime'])),
                double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2)));
            printer.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          } else if (isEsQrCodeKSA) {
            printer.qrcode(SaudiConversion.getBase64(
                companySettings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(
                    DateUtil.datedYMD(dataInformation['DDate']) +
                        ' ' +
                        DateUtil.timeHMS(dataInformation['BTime'])),
                double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2)));
            printer.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          }
        } else {
          printer.feed(
              ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        }
        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    } else {
      try {
        if (taxSale) {
          printer.text(companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size2,
              ),
              linesAfter: 1);

          // if(printCopy==2){
          //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
          //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
          //   ticket.text('عبدالله زهير',containsChinese: false,styles: const PosStyles(align: PosAlign.center,codeTable: ,
          //       bold: true,));
          //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
          //   //   bold: true,));
          // }
          // linesAfter: 1);
          // header1
          companySettings.add1.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add1,
                  styles: const PosStyles(align: PosAlign.center)));
          companySettings.add2.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add2,
                  styles: const PosStyles(align: PosAlign.center)));
          printer.text(
              'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center));
          printer.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center));
          printer.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 12,
                styles: const PosStyles(align: PosAlign.left)),
          ]);
          printer.row([
            PosColumn(
                text:
                    'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                width: 12,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          printer.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left));
          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              printer.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left));
            }
          }
          printer.hr();
          printer.row([
            PosColumn(text: 'Description', width: 7),
            PosColumn(text: 'Qty', width: 1),
            PosColumn(
                text: 'Price',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Total',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            if (double.tryParse(dataParticulars[i]['igst'].toString()) > 0) {
              if (taxPercentages.contains(
                  '@' + dataParticulars[i]['igst'].toString() + ' %')) {
              } else {
                taxPercentages +=
                    '@' + dataParticulars[i]['igst'].toString() + ' %,';
              }
            }
            var itemName = paper.width == PaperSize.mm80.width
                ? dataParticulars[i]['itemname'].toString().trim().length > 26
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(26)
                        .toString()
                    : dataParticulars[i]['itemname'].toString()
                : dataParticulars[i]['itemname'].toString().trim().length > 12
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(12)
                        .toString()
                    : dataParticulars[i]['itemname'].toString();
            printer.row([
              PosColumn(text: itemName, width: 7),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 1),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(text: 'Total : ', width: 7),
            PosColumn(text: '$totalQty', width: 1),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                  // height: PosTextSize.size1,
                  // width: PosTextSize.size1,
                  align: PosAlign.right,
                )),
            PosColumn(
                text: '${dataInformation['NetAmount']}',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size3,
                  // width: PosTextSize.size2,
                )),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Tax : ' + taxPercentages,
                width: 6,
                styles: const PosStyles(
                  // height: PosTextSize.size3,
                  // width: PosTextSize.size2,
                  align: PosAlign.right,
                )),
            PosColumn(
                text: (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size3,
                  // width: PosTextSize.size2,
                )),
          ]);
        } else {
          if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
            printer.text(companySettings.name,
                styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                ),
                linesAfter: 1);
            // if (printCopy == 2) {
            //   //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
            //   //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
            //   ticket.text('عبدالله زهير');
            //   //       bold: true,));
            //   //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
            //   //   //   bold: true,));
            // }
            // linesAfter: 1);
            // header1
            companySettings.add1.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add1,
                    styles: const PosStyles(align: PosAlign.center)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add2,
                    styles: const PosStyles(align: PosAlign.center)));
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
            printer.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center));
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.left)),
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
          } else {
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.left)),
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
          }
          printer.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              printer.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left));
            }
          }
          printer.hr();
          printer.row([
            PosColumn(text: 'Description', width: 7),
            PosColumn(text: 'Qty', width: 1),
            PosColumn(
                text: 'Price',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Total',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = paper.width == PaperSize.mm80.width
                ? dataParticulars[i]['itemname'].toString().trim().length > 26
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(26)
                        .toString()
                    : dataParticulars[i]['itemname'].toString()
                : dataParticulars[i]['itemname'].toString().trim().length > 12
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(12)
                        .toString()
                    : dataParticulars[i]['itemname'].toString();
            printer.row([
              PosColumn(text: itemName, width: 7),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 1,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Rate'].toString())
                      .toStringAsFixed(2),
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Total'].toString())
                      .toStringAsFixed(2),
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Sub =',
                width: 2,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: '$totalQty',
                width: 3,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 4,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                  // height: PosTextSize.size1,
                  // width: PosTextSize.size1,
                  align: PosAlign.right,
                )),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size3,
                  // width: PosTextSize.size2,
                )),
          ]);
        }
        for (var i = 0; i < otherAmount.length; i++) {
          if (otherAmount[i]['Amount'].toDouble() > 0) {
            printer.hr();
            printer.row([
              PosColumn(
                  text: '${otherAmount[i]['LedName']} :',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      )),
              PosColumn(
                  text: double.tryParse(otherAmount[i]['Amount'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                  )),
            ]);
          }
        }
        printer.hr();
        printer.row([
          PosColumn(
              text: 'Net Amount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text: double.tryParse(dataInformation['GrandTotal'].toString())
                  .toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        printer.hr();
        printer.text(
            'Amount in Words: ${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
            linesAfter: 1);

        // ticket.feed(1);
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        if (isQrCodeKSA) {
          // Print QR Code using native function
          // printer.qrcode('example.com');
          if (taxSale) {
            printer.qrcode(SaudiConversion.getBase64(
                companySettings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(
                    DateUtil.datedYMD(dataInformation['DDate']) +
                        ' ' +
                        DateUtil.timeHMS(dataInformation['BTime'])),
                double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2)));
            printer.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          } else if (isEsQrCodeKSA) {
            printer.qrcode(SaudiConversion.getBase64(
                companySettings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(
                    DateUtil.datedYMD(dataInformation['DDate']) +
                        ' ' +
                        DateUtil.timeHMS(dataInformation['BTime'])),
                double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2)));
            printer.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          }
        } else {
          printer.feed(
              ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        }
        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    }
  }

  Future<void> salesVat1Data(NetworkPrinter printer, PaperSize paper) async {
    var bill = widget.data[2];
    var printerSize = widget.data[3];
    CompanyInformation companySettings = widget.data[0];
    List<CompanySettings> settings = widget.data[1];
    var dataInformation = bill['Information'][0];
    var dataParticulars = bill['Particulars'];
    // var dataSerialNO = bill['SerialNO'];
    // var dataDeliveryNote = bill['DeliveryNote'];
    var otherAmount = bill['otherAmount'];
    var ledgerName = mainAccount
        .firstWhere(
          (element) =>
              element['LedCode'].toString() ==
              dataInformation['Customer'].toString(),
          orElse: () => {'LedName': dataInformation['ToName']},
        )['LedName']
        .toString();
    // header
    var taxSale = salesTypeData.type == 'SALES-ES'
        ? false
        : salesTypeData.type == 'SALES-Q'
            ? false
            : salesTypeData.type == 'SALES-O'
                ? false
                : true;
    var invoiceHead = salesTypeData.type == 'SALES-ES'
        ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
        : salesTypeData.type == 'SALES-Q'
            ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
            : salesTypeData.type == 'SALES-O'
                ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
                : Settings.getValue<String>(
                    'key-sales-invoice-head', 'INVOICE');
    bool isQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
    bool isEsQrCodeKSA =
        ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
    int printCopy = Settings.getValue<int>('key-dropdown-print-copy-view', 0);
    int printerModel =
        Settings.getValue<int>('key-dropdown-printer-model-view', 0);
    // for (int pCopy = 0; pCopy <= printCopy; pCopy++) {
    if (printerSize == "2") {
      try {
        if (taxSale) {
          printer.text(companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size2,
              ),
              linesAfter: 1);
          companySettings.add1.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add1,
                  styles: const PosStyles(align: PosAlign.center, bold: true)));
          companySettings.add2.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add2,
                  styles: const PosStyles(align: PosAlign.center, bold: true)));
          printer.text(
              'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          printer.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          printer.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          printer.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text:
                    'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.text('Bill To : ',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          printer.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              printer.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left, bold: true));
            }
          }
          printer.hr();
          printer.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          printer.row([
            PosColumn(
                text: '   ',
                width: 2,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: 'Qty',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Price',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Total',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            if (double.tryParse(dataParticulars[i]['igst'].toString()) > 0) {
              if (taxPercentages.contains(
                  '@' + dataParticulars[i]['igst'].toString() + ' %')) {
              } else {
                taxPercentages +=
                    '@' + dataParticulars[i]['igst'].toString() + ' %,';
              }
            }
            var itemName = dataParticulars[i]['itemname'].toString();
            printer.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            printer.row([
              PosColumn(text: '', width: 2),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 1),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total : ',
                width: 5,
                styles: const PosStyles(bold: true)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(bold: true)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 2,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size1,
                    // width: PosTextSize.size1,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: '${dataInformation['NetAmount']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Tax : ' + taxPercentages,
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
        } else {
          if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
            printer.text(companySettings.name,
                styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                ),
                linesAfter: 1);
            printer.text(
              '',
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            // if (printCopy == 2) {
            //   //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
            //   //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
            //   ticket.text('عبدالله زهير');
            //   //       bold: true,));
            //   //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
            //   //   //   bold: true,));
            // }
            // linesAfter: 1);
            // header1
            companySettings.add1.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add1,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add2,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            printer.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            printer.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          } else {
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            printer.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          }
          printer.hr();

          printer.text('Bill To :',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          printer.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              printer.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left, bold: true));
            }
          }
          printer.hr();
          printer.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          printer.row([
            PosColumn(text: ' ', width: 1),
            PosColumn(
                text: 'Qty', width: 3, styles: const PosStyles(bold: true)),
            PosColumn(
                text: 'Price',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Total',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            printer.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            printer.row([
              PosColumn(text: '', width: 1),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 3,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Rate'].toString())
                      .toStringAsFixed(2),
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Total'].toString())
                      .toStringAsFixed(2),
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Sub =',
                width: 3,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size1,
                    // width: PosTextSize.size1,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
        }
        for (var i = 0; i < otherAmount.length; i++) {
          if (otherAmount[i]['Amount'].toDouble() > 0) {
            printer.hr();
            printer.row([
              PosColumn(
                  text: '${otherAmount[i]['LedName']} :',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      )),
              PosColumn(
                  text: double.tryParse(otherAmount[i]['Amount'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                  )),
            ]);
          }
        }
        // printer.hr();
        // printer.text(
        //     'Amount in Words: ${NumberToWord().convert('en', double.tryParse(dataInformation['GrandTotal'].toString()).round())}',
        //     linesAfter: 1);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Net Amount :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size2, width: PosTextSize.size2,
                    bold: true,
                    align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                    bold: true)),
          ]);
        } else {
          if (ledgerName != 'CASH') {
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Old Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataInformation['Balance'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Net Amount :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text:
                      double.tryParse(dataInformation['GrandTotal'].toString())
                          .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Cash Received :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(
                          dataInformation['CashReceived'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: (double.tryParse(
                              dataInformation['Balance'].toString()) +
                          (double.tryParse(
                                  dataInformation['GrandTotal'].toString()) -
                              double.tryParse(
                                  dataInformation['CashReceived'].toString())))
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          } else {
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Net Amount :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text:
                      double.tryParse(dataInformation['GrandTotal'].toString())
                          .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          }
        }

        // ticket.feed(1);
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    } else {
      try {
        if (taxSale) {
          printer.text(companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size2,
              ),
              linesAfter: 1);

          companySettings.add1.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add1,
                  styles: const PosStyles(align: PosAlign.center)));
          companySettings.add2.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add2,
                  styles: const PosStyles(align: PosAlign.center)));
          printer.text(
              'Phone No: ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center));
          printer.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO: ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN NO: ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center));
          printer.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Voucher No:${dataInformation['InvoiceNo']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: '',
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.row([
            PosColumn(
                text:
                    'Ordering Date:${DateUtil.dateDMY(dataInformation['DDate'])}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: 'Contact:',
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.row([
            PosColumn(
                text: 'Party Name:${dataInformation['ToName']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text:
                    'Party Balance:${double.tryParse(dataInformation['Balance'].toString()) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO:${dataInformation['gstno'].toString().trim()}'
                  : 'Party TRNNO:${dataInformation['gstno'].toString().trim()}',
              styles: const PosStyles(align: PosAlign.left));
          printer.hr();
          printer.row([
            PosColumn(text: 'Slno', width: 1),
            PosColumn(text: 'Item Des', width: 2),
            PosColumn(text: 'Qty(UOM)', width: 2),
            PosColumn(
                text: 'Rate',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Taxable',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Tax Amt',
                width: 1,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Net Amt',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            printer.row([
              PosColumn(
                  text: '${i + 1}',
                  width: 1,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: itemName,
                  width: 11,
                  styles: const PosStyles(align: PosAlign.left)),
            ]);
            printer.row([
              PosColumn(text: '', width: 1),
              PosColumn(text: '', width: 1),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 3),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: '${dataParticulars[i]['RealRate']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: '${dataParticulars[i]['IGST']}',
                  width: 1,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Gross Total:',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
            PosColumn(
                text: '${dataInformation['NetAmount']}',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
          ]);
          printer.row([
            PosColumn(
                text: 'VAT:',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
            PosColumn(
                text: (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
          ]);
          printer.row([
            PosColumn(
                text: 'Discount:',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
            PosColumn(
                text: '${dataInformation['OtherDiscount']}',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
          ]);
          printer.row([
            PosColumn(
                text: 'NET TOTAL:',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
            PosColumn(
                text: '${dataInformation['GrandTotal']}',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
          ]);
        } else {
          if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
            printer.text(companySettings.name,
                styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                ),
                linesAfter: 1);

            companySettings.add1.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add1,
                    styles: const PosStyles(align: PosAlign.center)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add2,
                    styles: const PosStyles(align: PosAlign.center)));
            printer.text(
                'Phone No: ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
            printer.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO: ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN NO: ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center));
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          } else {
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          printer.row([
            PosColumn(
                text: 'Voucher No:${dataInformation['InvoiceNo']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: '',
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.row([
            PosColumn(
                text:
                    'Ordering Date:${DateUtil.dateDMY(dataInformation['DDate'])}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: 'Contact:',
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.row([
            PosColumn(
                text: 'Party Name:${dataInformation['ToName']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text:
                    'Party Balance:${double.tryParse(dataInformation['Balance'].toString()) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO:${dataInformation['gstno'].toString().trim()}'
                  : 'Party TRNNO:${dataInformation['gstno'].toString().trim()}',
              styles: const PosStyles(align: PosAlign.left));
          printer.hr();
          printer.row([
            PosColumn(text: 'Slno', width: 1),
            PosColumn(text: 'Item Des', width: 2),
            PosColumn(text: 'Qty(UOM)', width: 2),
            PosColumn(
                text: 'Rate',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Taxable',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Tax Amt',
                width: 1,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Net Amt',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            printer.row([
              PosColumn(
                  text: '${i + 1}',
                  width: 1,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: itemName,
                  width: 11,
                  styles: const PosStyles(align: PosAlign.left)),
            ]);
            printer.row([
              PosColumn(text: '', width: 1),
              PosColumn(text: '', width: 1),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 3),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: '${dataParticulars[i]['RealRate']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: '${dataParticulars[i]['IGST']}',
                  width: 1,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Gross Total:',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
            PosColumn(
                text: '${dataInformation['NetAmount']}',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
          ]);
          printer.row([
            PosColumn(
                text: 'VAT:',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
            PosColumn(
                text: (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
          ]);
          printer.row([
            PosColumn(
                text: 'Discount:',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
            PosColumn(
                text: '${dataInformation['OtherDiscount']}',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
          ]);
          printer.row([
            PosColumn(
                text: 'NET TOTAL:',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
            PosColumn(
                text: '${dataInformation['GrandTotal']}',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
          ]);
        }

        printer.hr();
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        printer
            .feed(ComSettings.appSettings('int', 'key-dropdown-print-line', 1));

        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    }
  }

  Future<void> salesGSTData(NetworkPrinter printer, PaperSize paper) async {
    var bill = widget.data[2];
    var printerSize = widget.data[3];
    CompanyInformation companySettings = widget.data[0];
    List<CompanySettings> settings = widget.data[1];
    var dataInformation = bill['Information'][0];
    var dataParticulars = bill['Particulars'];
    // var dataSerialNO = bill['SerialNO'];
    // var dataDeliveryNote = bill['DeliveryNote'];
    var otherAmount = bill['otherAmount'];
    var ledgerName = mainAccount
        .firstWhere(
          (element) =>
              element['LedCode'].toString() ==
              dataInformation['Customer'].toString(),
          orElse: () => {'LedName': dataInformation['ToName']},
        )['LedName']
        .toString();
    // header
    var taxSale = salesTypeData.tax;
    var invoiceHead = salesTypeData.type == 'SALES-ES'
        ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
        : salesTypeData.type == 'SALES-Q'
            ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
            : salesTypeData.type == 'SALES-O'
                ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
                : Settings.getValue<String>(
                    'key-sales-invoice-head', 'INVOICE');
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    bool isQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
    bool disablePrintBalance =
        ComSettings.getStatus('key-print-balance', settings);
    bool isEsQrCodeKSA =
        ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
    int printCopy = Settings.getValue<int>('key-dropdown-print-copy-view', 0);
    int printerModel =
        Settings.getValue<int>('key-dropdown-printer-model-view', 0);
    // for (int pCopy = 0; pCopy <= printCopy; pCopy++) {
    if (taxSale) {
      _taxableData(dataParticulars);
    }
    if (printerSize == "2") {
      try {
        if (taxSale) {
          printer.text(companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size2,
              ),
              linesAfter: 1);
          if (companySettings.add1.toString().trim().isNotEmpty) {
            printer.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add2.toString().trim().isNotEmpty) {
            printer.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add3.toString().trim().isNotEmpty) {
            printer.text(companySettings.add3,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add4.toString().trim().isNotEmpty) {
            printer.text(companySettings.add4,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.telephone.toString().trim().isNotEmpty ||
              companySettings.mobile.toString().trim().isNotEmpty) {
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
          }
          printer.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          printer.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          printer.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text:
                    'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.text('Bill To : ',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          printer.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          //not acceptable if (isEsQrCodeKSA) {
          if (dataInformation['gstno'].toString().trim().isNotEmpty) {
            printer.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                    : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                styles: const PosStyles(align: PosAlign.left, bold: true));
          }
          // }
          printer.hr();
          printer.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          printer.row([
            PosColumn(
                text: '   ',
                width: 2,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: 'Qty',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Price',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Total',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            if (double.tryParse(dataParticulars[i]['igst'].toString()) > 0) {
              taxPercentages = dataParticulars[i]['igst'].toString() + ' %';
              // if (taxPercentages.contains(
              //     '@' + dataParticulars[i]['igst'].toString() + ' %')) {
            } else {
              taxPercentages = '0 %';
            }
            // }
            var itemName = dataParticulars[i]['itemname'].toString();
            printer.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            printer.row([
              PosColumn(text: '', width: 2),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 1),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total : ',
                width: 5,
                styles: const PosStyles(bold: true)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(bold: true)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 2,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size1,
                    // width: PosTextSize.size1,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: '${dataInformation['NetAmount']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Tax : ' + taxPercentages,
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
        } else {
          if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
            printer.text(companySettings.name,
                styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                ),
                linesAfter: 1);
            printer.text(
              '',
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            // if (printCopy == 2) {
            //   //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
            //   //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
            //   ticket.text('عبدالله زهير');
            //   //       bold: true,));
            //   //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
            //   //   //   bold: true,));
            // }
            // linesAfter: 1);
            // header1
            companySettings.add1.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add1,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add2,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            printer.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            printer.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          } else {
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            printer.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          }
          printer.hr();

          printer.text('Bill To :',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          printer.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              printer.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left, bold: true));
            }
          }
          printer.hr();
          printer.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          printer.row([
            PosColumn(text: ' ', width: 1),
            PosColumn(
                text: 'Qty', width: 3, styles: const PosStyles(bold: true)),
            PosColumn(
                text: 'Price',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Total',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            printer.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            printer.row([
              PosColumn(text: '', width: 1),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 3,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Rate'].toString())
                      .toStringAsFixed(2),
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Total'].toString())
                      .toStringAsFixed(2),
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Sub =',
                width: 3,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size1,
                    // width: PosTextSize.size1,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
        }
        for (var i = 0; i < otherAmount.length; i++) {
          if (otherAmount[i]['Amount'].toDouble() > 0) {
            printer.hr();
            printer.row([
              PosColumn(
                  text: '${otherAmount[i]['LedName']} :',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      )),
              PosColumn(
                  text: double.tryParse(otherAmount[i]['Amount'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                  )),
            ]);
          }
        }
        // printer.hr();
        // printer.text(
        //     'Amount in Words: ${NumberToWord().convert('en', double.tryParse(dataInformation['GrandTotal'].toString()).round())}',
        //     linesAfter: 1);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Net Amount :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size2, width: PosTextSize.size2,
                    bold: true,
                    align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                    bold: true)),
          ]);
        } else {
          if (ledgerName != 'CASH') {
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Old Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataInformation['Balance'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Net Amount :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text:
                      double.tryParse(dataInformation['GrandTotal'].toString())
                          .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Cash Received :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(
                          dataInformation['CashReceived'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: (double.tryParse(
                              dataInformation['Balance'].toString()) +
                          (double.tryParse(
                                  dataInformation['GrandTotal'].toString()) -
                              double.tryParse(
                                  dataInformation['CashReceived'].toString())))
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          } else {
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Net Amount :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text:
                      double.tryParse(dataInformation['GrandTotal'].toString())
                          .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          }
        }

        // ticket.feed(1);
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        if (isQrCodeKSA) {
          // Print QR Code using native function
          // printer.qrcode('example.com');
          if (taxSale) {
            printer.qrcode(SaudiConversion.getBase64(
                companySettings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(
                    DateUtil.datedYMD(dataInformation['DDate']) +
                        ' ' +
                        DateUtil.timeHMS(dataInformation['BTime'])),
                double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2)));
            printer.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          } else if (isEsQrCodeKSA) {
            printer.qrcode(SaudiConversion.getBase64(
                companySettings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(
                    DateUtil.datedYMD(dataInformation['DDate']) +
                        ' ' +
                        DateUtil.timeHMS(dataInformation['BTime'])),
                double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2)));
            printer.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          }
        } else {
          printer.feed(
              ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        }
        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    } else {
      try {
        if (taxSale) {
          printer.text(companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size2,
              ),
              linesAfter: 1);

          // if(printCopy==2){
          //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
          //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
          //   ticket.text('عبدالله زهير',containsChinese: false,styles: const PosStyles(align: PosAlign.center,codeTable: ,
          //       bold: true,));
          //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
          //   //   bold: true,));
          // }
          // linesAfter: 1);
          // header1
          if (companySettings.add1.toString().trim().isNotEmpty) {
            printer.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add2.toString().trim().isNotEmpty) {
            printer.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add3.toString().trim().isNotEmpty) {
            printer.text(companySettings.add3,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add4.toString().trim().isNotEmpty) {
            printer.text(companySettings.add4,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.telephone.toString().trim().isNotEmpty ||
              companySettings.mobile.toString().trim().isNotEmpty) {
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
          }
          printer.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center));
          printer.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 12,
                styles: const PosStyles(align: PosAlign.left)),
          ]);
          printer.row([
            PosColumn(
                text:
                    'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                width: 12,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          printer.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left));
          //don't use it if (isEsQrCodeKSA) {
          if (dataInformation['gstno'].toString().trim().isNotEmpty) {
            printer.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                    : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                styles: const PosStyles(align: PosAlign.left));
          }
          // }
          printer.hr();
          printer.row([
            PosColumn(text: 'Description', width: 7),
            PosColumn(text: 'Qty', width: 1),
            PosColumn(
                text: 'Price',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Total',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            if (double.tryParse(dataParticulars[i]['igst'].toString()) > 0) {
              // if (taxPercentages.contains(
              //     '@' + dataParticulars[i]['igst'].toString() + ' %')) {
              // } else {
              taxPercentages =
                  '@ ' + dataParticulars[i]['igst'].toString() + ' %';
              // }
            } else {
              taxPercentages =
                  '@ ' + dataParticulars[i]['igst'].toString() + ' %';
            }
            var itemName = paper.width == PaperSize.mm80.width
                ? dataParticulars[i]['itemname'].toString().trim().length > 26
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(26)
                        .toString()
                    : dataParticulars[i]['itemname'].toString()
                : dataParticulars[i]['itemname'].toString().trim().length > 12
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(12)
                        .toString()
                    : dataParticulars[i]['itemname'].toString();
            printer.row([
              PosColumn(
                  text: itemName,
                  width: 7,
                  styles:
                      const PosStyles(height: PosTextSize.size1, bold: true)),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + '' + dataParticulars[i]['unitName'] + '' : dataParticulars[i]['Qty']}',
                  width: 1,
                  styles:
                      const PosStyles(height: PosTextSize.size1, bold: true)),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 2,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      height: PosTextSize.size1,
                      bold: true)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 2,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      height: PosTextSize.size1,
                      bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
            //hsn gst o vat
            // printer.hr();
            printer.row(companyTaxMode == 'INDIA'
                ? [
                    PosColumn(
                        text: '${dataParticulars[i]['hsncode']}', width: 4),
                    PosColumn(text: taxPercentages, width: 4),
                    PosColumn(
                        text: double.tryParse(
                                    dataParticulars[i]['cess'].toString()) >
                                0
                            ? 'Cess : ${dataParticulars[i]['cess']}'
                            : '',
                        width: 4),
                    // PosColumn(
                    //     text: 'CGST : ${dataParticulars[i]['CGST']}', width: 2),
                    // PosColumn(
                    //     text: 'SGST : ${dataParticulars[i]['SGST']}', width: 2),
                    // PosColumn(
                    //     text:
                    //         '= ${double.tryParse(dataParticulars[i]['CGST'].toString()) + double.tryParse(dataParticulars[i]['SGST'].toString()) + double.tryParse(dataParticulars[i]['cess'].toString())}',
                    //     width: 2,
                    //     styles: const PosStyles(align: PosAlign.right)),
                  ]
                : [
                    PosColumn(
                        text: 'HSN : ${dataParticulars[i]['hsncode']}',
                        width: 6),
                    PosColumn(text: '$taxPercentages% ', width: 6),
                    // PosColumn(
                    //     text: 'Vat : ${dataParticulars[i]['IGST']}',
                    //     width: 5,
                    //     styles: const PosStyles(align: PosAlign.right)),
                  ]);
          }
          printer.hr();
          printer.row([
            PosColumn(text: 'Total ', width: 3),
            PosColumn(text: '$totalQty', width: 3),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 3,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          // printer.row([
          //   PosColumn(
          //       text: 'Total :',
          //       width: 6,
          //       styles: const PosStyles(
          //         // height: PosTextSize.size1,
          //         // width: PosTextSize.size1,
          //         align: PosAlign.right,
          //       )),
          //   PosColumn(
          //       text: '${dataInformation['NetAmount']}',
          //       width: 6,
          //       styles: const PosStyles(
          //         align: PosAlign.right,
          //         // height: PosTextSize.size3,
          //         // width: PosTextSize.size2,
          //       )),
          // ]);
          // printer.hr();
          // printer.row([
          //   PosColumn(
          //       text: 'Tax : ' + taxPercentages,
          //       width: 6,
          //       styles: const PosStyles(
          //         // height: PosTextSize.size3,
          //         // width: PosTextSize.size2,
          //         align: PosAlign.right,
          //       )),
          //   PosColumn(
          //       text: (double.tryParse(dataInformation['CGST'].toString()) +
          //               double.tryParse(dataInformation['SGST'].toString()) +
          //               double.tryParse(dataInformation['cess'].toString()) +
          //               double.tryParse(dataInformation['IGST'].toString()))
          //           .toStringAsFixed(2),
          //       width: 6,
          //       styles: const PosStyles(
          //         align: PosAlign.right,
          //         // height: PosTextSize.size3,
          //         // width: PosTextSize.size2,
          //       )),
          // ]);
        } else {
          if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
            printer.text(companySettings.name,
                styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                ),
                linesAfter: 1);
            // if (printCopy == 2) {
            //   //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
            //   //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
            //   ticket.text('عبدالله زهير');
            //   //       bold: true,));
            //   //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
            //   //   //   bold: true,));
            // }
            // linesAfter: 1);
            // header1
            companySettings.add1.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add1,
                    styles: const PosStyles(align: PosAlign.center)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add2,
                    styles: const PosStyles(align: PosAlign.center)));
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
            printer.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center));
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.left)),
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
          } else {
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.left)),
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
          }
          printer.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              printer.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left));
            }
          }
          printer.hr();
          printer.row([
            PosColumn(text: 'Description', width: 7),
            PosColumn(text: 'Qty', width: 1),
            PosColumn(
                text: 'Price',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Total',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = paper.width == PaperSize.mm80.width
                ? dataParticulars[i]['itemname'].toString().trim().length > 26
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(26)
                        .toString()
                    : dataParticulars[i]['itemname'].toString()
                : dataParticulars[i]['itemname'].toString().trim().length > 12
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(12)
                        .toString()
                    : dataParticulars[i]['itemname'].toString();
            printer.row([
              PosColumn(text: itemName, width: 7),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + '' + dataParticulars[i]['unitName'] + '' : dataParticulars[i]['Qty']}',
                  width: 1,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Rate'].toString())
                      .toStringAsFixed(2),
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Total'].toString())
                      .toStringAsFixed(2),
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Sub =',
                width: 2,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: '$totalQty',
                width: 3,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 4,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                  // height: PosTextSize.size1,
                  // width: PosTextSize.size1,
                  align: PosAlign.right,
                )),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size3,
                  // width: PosTextSize.size2,
                )),
          ]);
        }
        for (var i = 0; i < otherAmount.length; i++) {
          if (otherAmount[i]['Amount'].toDouble() > 0) {
            printer.hr();
            printer.row([
              PosColumn(
                  text: '${otherAmount[i]['LedName']} :',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      )),
              PosColumn(
                  text: double.tryParse(otherAmount[i]['Amount'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                  )),
            ]);
          }
        }
        printer.hr();
        printer.row([
          PosColumn(
              text: 'Net Amount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text: double.tryParse(dataInformation['GrandTotal'].toString())
                  .toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        printer.hr();
        printer.text(
            'Amount in Words: ${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
            linesAfter: 1);

        if (taxSale) {
          printer.hr();
          companyTaxMode == 'INDIA'
              ? printer.row([
                  PosColumn(
                      text: 'GST %',
                      width: 3,
                      styles: const PosStyles(align: PosAlign.center)),
                  PosColumn(
                      text: 'Taxable',
                      width: 3,
                      styles: const PosStyles(align: PosAlign.center)),
                  PosColumn(
                      text: 'CGST Amt',
                      width: 3,
                      styles: const PosStyles(align: PosAlign.center)),
                  PosColumn(
                      text: 'SGST Amt',
                      width: 3,
                      styles: const PosStyles(align: PosAlign.center)),
                ])
              : printer.row([
                  PosColumn(
                      text: 'VAT %',
                      width: 4,
                      styles: const PosStyles(align: PosAlign.center)),
                  PosColumn(
                      text: 'Taxable',
                      width: 4,
                      styles: const PosStyles(align: PosAlign.center)),
                  PosColumn(
                      text: 'Vat Amt',
                      width: 4,
                      styles: const PosStyles(align: PosAlign.center)),
                ]);
          printer.hr();
          for (var i = 0; i < taxableData.length; i++) {
            companyTaxMode == 'INDIA'
                ? printer.row([
                    PosColumn(
                        text: '${taxableData[i]['tax'].toString()} %',
                        width: 3,
                        styles: const PosStyles(align: PosAlign.right)),
                    PosColumn(
                        text: '${taxableData[i]['taxable'].toStringAsFixed(2)}',
                        width: 3,
                        styles: const PosStyles(align: PosAlign.right)),
                    PosColumn(
                        text: '${taxableData[i]['CGST'].toStringAsFixed(2)}',
                        width: 3,
                        styles: const PosStyles(align: PosAlign.right)),
                    PosColumn(
                        text: '${taxableData[i]['SGST'].toStringAsFixed(2)}',
                        width: 3,
                        styles: const PosStyles(align: PosAlign.right)),
                  ])
                : printer.row([
                    PosColumn(
                        text: '${taxableData[i]['tax'].toString()} %',
                        width: 4,
                        styles: const PosStyles(align: PosAlign.right)),
                    PosColumn(
                        text: '${taxableData[i]['taxable'].toStringAsFixed(2)}',
                        width: 4,
                        styles: const PosStyles(align: PosAlign.right)),
                    PosColumn(
                        text: '${taxableData[i]['IGST'].toStringAsFixed(2)}',
                        width: 4,
                        styles: const PosStyles(align: PosAlign.right)),
                  ]);
            printer.hr();
          }
        }
        if (Settings.getValue<bool>('key-print-balance', false)) {
          //
        } else {
          printer.row([
            PosColumn(
                text: 'CashReceived : ',
                width: 6,
                styles: const PosStyles(align: PosAlign.center)),
            PosColumn(
                text: '${dataInformation['CashReceived']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.center)),
          ]);
          printer.row([
            PosColumn(
                text: 'Old Balance : ${dataInformation['Balance']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.center)),
            PosColumn(
                text:
                    'Balance : ${(double.tryParse(dataInformation['Balance'].toString())) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))}',
                width: 6,
                styles: const PosStyles(align: PosAlign.center)),
          ]);
        }

        // ticket.feed(1);
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        if (isQrCodeKSA) {
          // Print QR Code using native function
          // printer.qrcode('example.com');
          if (taxSale) {
            printer.qrcode(SaudiConversion.getBase64(
                companySettings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(
                    DateUtil.datedYMD(dataInformation['DDate']) +
                        ' ' +
                        DateUtil.timeHMS(dataInformation['BTime'])),
                double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2)));
            printer.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          } else if (isEsQrCodeKSA) {
            printer.qrcode(SaudiConversion.getBase64(
                companySettings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(
                    DateUtil.datedYMD(dataInformation['DDate']) +
                        ' ' +
                        DateUtil.timeHMS(dataInformation['BTime'])),
                double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2)));
            printer.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          }
        } else {
          printer.feed(
              ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        }
        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    }
    // } else if (printerModel == 6) {
    //   try {
    //     // Print image
    //     final Uint8List bytes = widget.byteImage;
    //     final img.Image image = img.decodeImage(bytes);
    //     ticket.image(image);
    //     ticket.feed(2);
    //     ticket.cut();
    //     return ticket;
    //   } catch (e, s) {
    //     FirebaseCrashlytics.instance
    //         .recordError(e, s, reason: 'tcp print:' + ticket.toString());
    //     return ticket;
    //   }
    // }
    // }
  }

  Future<void> salesDefaultData(NetworkPrinter printer, PaperSize paper) async {
    var bill = widget.data[2];
    var printerSize = widget.data[3];
    CompanyInformation companySettings = widget.data[0];
    List<CompanySettings> settings = widget.data[1];
    var dataInformation = bill['Information'][0];
    var dataParticulars = bill['Particulars'];
    // var dataSerialNO = bill['SerialNO'];
    // var dataDeliveryNote = bill['DeliveryNote'];
    var dataBankLedger = bill['bankLedger'];
    var otherAmount = bill['otherAmount'];
    var ledgerName = mainAccount
        .firstWhere(
          (element) =>
              element['LedCode'].toString() ==
              dataInformation['Customer'].toString(),
          orElse: () => {'LedName': dataInformation['ToName']},
        )['LedName']
        .toString();
    // header
    var taxSale = salesTypeData.tax;
    var invoiceHead = salesTypeData.type == 'SALES-ES'
        ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
        : salesTypeData.type == 'SALES-Q'
            ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
            : salesTypeData.type == 'SALES-O'
                ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
                : Settings.getValue<String>(
                    'key-sales-invoice-head', 'INVOICE');
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    bool isQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
    bool disablePrintBalance =
        ComSettings.getStatus('key-print-balance', settings);
    bool isEsQrCodeKSA =
        ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
    int printCopy = Settings.getValue<int>('key-dropdown-print-copy-view', 0);
    int printerModel =
        Settings.getValue<int>('key-dropdown-printer-model-view', 0);
    // for (int pCopy = 0; pCopy <= printCopy; pCopy++) {
    // if (taxSale) {
    //   _taxableData(dataParticulars);
    // }
    if (printerSize == "2") {
      try {
        if (taxSale) {
          printer.text(companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size2,
              ),
              linesAfter: 1);
          if (companySettings.add1.toString().trim().isNotEmpty) {
            printer.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add2.toString().trim().isNotEmpty) {
            printer.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add3.toString().trim().isNotEmpty) {
            printer.text(companySettings.add3,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add4.toString().trim().isNotEmpty) {
            printer.text(companySettings.add4,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.telephone.toString().trim().isNotEmpty ||
              companySettings.mobile.toString().trim().isNotEmpty) {
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
          }
          // printer.text(
          //     companyTaxMode == 'INDIA'
          //         ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
          //         : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
          //     styles: const PosStyles(align: PosAlign.center, bold: true));
          printer.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          printer.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text:
                    'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.text('Bill To : ',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          printer.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          //not acceptable if (isEsQrCodeKSA) {
          // if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //   printer.text(
          //       companyTaxMode == 'INDIA'
          //           ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //           : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //       styles: const PosStyles(align: PosAlign.left, bold: true));
          // }
          // }
          printer.hr();
          printer.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          printer.row([
            PosColumn(
                text: '   ',
                width: 2,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: 'Qty',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Price',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Total',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            if (double.tryParse(dataParticulars[i]['igst'].toString()) > 0) {
              taxPercentages = dataParticulars[i]['igst'].toString() + ' %';
              // if (taxPercentages.contains(
              //     '@' + dataParticulars[i]['igst'].toString() + ' %')) {
            } else {
              taxPercentages = '0 %';
            }
            // }
            var itemName = dataParticulars[i]['itemname'].toString();
            printer.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            printer.row([
              PosColumn(text: '', width: 2),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 1),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total : ',
                width: 5,
                styles: const PosStyles(bold: true)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(bold: true)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 2,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size1,
                    // width: PosTextSize.size1,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: '${dataInformation['NetAmount']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
          printer.hr();
          // printer.row([
          //   PosColumn(
          //       text: 'Tax : ' + taxPercentages,
          //       width: 6,
          //       styles: const PosStyles(
          //           // height: PosTextSize.size3,
          //           // width: PosTextSize.size2,
          //           align: PosAlign.right,
          //           bold: true)),
          //   PosColumn(
          //       text: (double.tryParse(dataInformation['CGST'].toString()) +
          //               double.tryParse(dataInformation['SGST'].toString()) +
          //               double.tryParse(dataInformation['IGST'].toString()))
          //           .toStringAsFixed(2),
          //       width: 6,
          //       styles: const PosStyles(align: PosAlign.right, bold: true
          //           // height: PosTextSize.size3,
          //           // width: PosTextSize.size2,
          //           )),
          // ]);
        } else {
          if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
            printer.text(companySettings.name,
                styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                ),
                linesAfter: 1);
            printer.text(
              '',
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            companySettings.add1.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add1,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add2,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // printer.text(
            //     companyTaxMode == 'INDIA'
            //         ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
            //         : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
            //     styles: const PosStyles(align: PosAlign.center, bold: true));
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            printer.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          } else {
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            printer.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          }
          printer.hr();

          printer.text('Bill To :',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          printer.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          // if (isEsQrCodeKSA) {
          //   if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //     printer.text(
          //         companyTaxMode == 'INDIA'
          //             ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //             : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //         styles: const PosStyles(align: PosAlign.left, bold: true));
          //   }
          // }
          printer.hr();
          printer.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          printer.row([
            PosColumn(text: ' ', width: 1),
            PosColumn(
                text: 'Qty', width: 3, styles: const PosStyles(bold: true)),
            PosColumn(
                text: 'Price',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Total',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            printer.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            printer.row([
              PosColumn(text: '', width: 1),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 3,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Rate'].toString())
                      .toStringAsFixed(2),
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Total'].toString())
                      .toStringAsFixed(2),
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Sub =',
                width: 3,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size1,
                    // width: PosTextSize.size1,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
        }
        for (var i = 0; i < otherAmount.length; i++) {
          if (otherAmount[i]['Amount'].toDouble() > 0) {
            printer.hr();
            printer.row([
              PosColumn(
                  text: '${otherAmount[i]['LedName']} :',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      )),
              PosColumn(
                  text: double.tryParse(otherAmount[i]['Amount'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                  )),
            ]);
          }
        }
        // printer.hr();
        // printer.text(
        //     'Amount in Words: ${NumberToWord().convert('en', double.tryParse(dataInformation['GrandTotal'].toString()).round())}',
        //     linesAfter: 1);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Net Amount :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size2, width: PosTextSize.size2,
                    bold: true,
                    align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                    bold: true)),
          ]);
        } else {
          if (ledgerName != 'CASH') {
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Old Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataInformation['Balance'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Net Amount :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text:
                      double.tryParse(dataInformation['GrandTotal'].toString())
                          .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Cash Received :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(
                          dataInformation['CashReceived'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: (double.tryParse(
                              dataInformation['Balance'].toString()) +
                          (double.tryParse(
                                  dataInformation['GrandTotal'].toString()) -
                              double.tryParse(
                                  dataInformation['CashReceived'].toString())))
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          } else {
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Net Amount :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text:
                      double.tryParse(dataInformation['GrandTotal'].toString())
                          .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          }
        }
        if (Settings.getValue<bool>('key-print-bank-details', false)) {
          printer.hr();
          printer.text('${dataBankLedger['name']}',
              styles: const PosStyles(align: PosAlign.left));
          printer.text('ACC NO : ${dataBankLedger['account']}',
              styles: const PosStyles(align: PosAlign.left));
          printer.text('IFSC CODE : ${dataBankLedger['ifsc']}',
              styles: const PosStyles(align: PosAlign.left));
          printer.text('Branch : ${dataBankLedger['branch']}',
              styles: const PosStyles(align: PosAlign.left));
          printer.hr();
        }

        // ticket.feed(1);
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));
        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    } else {
      try {
        if (taxSale) {
          printer.text(companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size2,
              ),
              linesAfter: 1);

          if (companySettings.add1.toString().trim().isNotEmpty) {
            printer.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add2.toString().trim().isNotEmpty) {
            printer.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add3.toString().trim().isNotEmpty) {
            printer.text(companySettings.add3,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add4.toString().trim().isNotEmpty) {
            printer.text(companySettings.add4,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.telephone.toString().trim().isNotEmpty ||
              companySettings.mobile.toString().trim().isNotEmpty) {
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
          }
          String taxNo = ComSettings.getValue('GST-NO', settings);
          if (taxNo.isNotEmpty) {
            printer.text(
                companyTaxMode == 'INDIA' ? 'GSTNO : $taxNo' : 'TRN : $taxNo',
                styles: const PosStyles(align: PosAlign.center));
          }
          printer.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 5,
                styles: const PosStyles(align: PosAlign.left)),
            // ]);
            // printer.row([
            PosColumn(
                text:
                    'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                width: 7,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          printer.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left));
          //don't use it if (isEsQrCodeKSA) {
          // if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //   printer.text(
          //       companyTaxMode == 'INDIA'
          //           ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //           : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //       styles: const PosStyles(align: PosAlign.left));
          // }
          // }
          printer.hr();
          printer.row([
            PosColumn(text: 'Description', width: 7),
            PosColumn(text: 'Qty', width: 1),
            PosColumn(
                text: 'Price',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Total',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = paper.width == PaperSize.mm80.width
                ? dataParticulars[i]['itemname'].toString().trim().length > 26
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(26)
                        .toString()
                    : dataParticulars[i]['itemname'].toString()
                : dataParticulars[i]['itemname'].toString().trim().length > 12
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(12)
                        .toString()
                    : dataParticulars[i]['itemname'].toString();
            printer.row([
              PosColumn(text: itemName, width: 7),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + '' + dataParticulars[i]['unitName'] + '' : dataParticulars[i]['Qty']}',
                  width: 1,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Rate'].toString())
                      .toStringAsFixed(2),
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Total'].toString())
                      .toStringAsFixed(2),
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(text: 'Total ', width: 3),
            PosColumn(text: '$totalQty', width: 3),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 3,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
        } else {
          if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
            printer.text(companySettings.name,
                styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                ),
                linesAfter: 1);
            companySettings.add1.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add1,
                    styles: const PosStyles(align: PosAlign.center)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add2,
                    styles: const PosStyles(align: PosAlign.center)));
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));

            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.left)),
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
          } else {
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.left)),
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
          }
          printer.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              printer.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left));
            }
          }
          printer.hr();
          printer.row([
            PosColumn(text: 'Description', width: 7),
            PosColumn(text: 'Qty', width: 1),
            PosColumn(
                text: 'Price',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Total',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = paper.width == PaperSize.mm80.width
                ? dataParticulars[i]['itemname'].toString().trim().length > 26
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(26)
                        .toString()
                    : dataParticulars[i]['itemname'].toString()
                : dataParticulars[i]['itemname'].toString().trim().length > 12
                    ? dataParticulars[i]['itemname']
                        .toString()
                        .trim()
                        .characters
                        .take(12)
                        .toString()
                    : dataParticulars[i]['itemname'].toString();
            printer.row([
              PosColumn(text: itemName, width: 7),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + '' + dataParticulars[i]['unitName'] + '' : dataParticulars[i]['Qty']}',
                  width: 1,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Rate'].toString())
                      .toStringAsFixed(2),
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Total'].toString())
                      .toStringAsFixed(2),
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Sub =',
                width: 2,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: '$totalQty',
                width: 3,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 4,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                )),
          ]);
        }
        for (var i = 0; i < otherAmount.length; i++) {
          if (otherAmount[i]['Amount'].toDouble() > 0) {
            printer.hr();
            printer.row([
              PosColumn(
                  text: '${otherAmount[i]['LedName']} :',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      )),
              PosColumn(
                  text: double.tryParse(otherAmount[i]['Amount'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                  )),
            ]);
          }
        }
        if (otherAmount.length > 0) {
          printer.hr();
        }
        printer.row([
          PosColumn(
              text: 'Net Amount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text: double.tryParse(dataInformation['GrandTotal'].toString())
                  .toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        printer.hr();
        printer.text(
            'Amount in Words: ${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
            linesAfter: 1);

        if (Settings.getValue<bool>('key-print-balance', false)) {
          //
        } else {
          printer.text('CashReceived : ${dataInformation['CashReceived']}',
              styles: const PosStyles(align: PosAlign.left));
          printer.text('Old Balance : ${dataInformation['Balance']}',
              styles: const PosStyles(align: PosAlign.left));
          printer.text(
              'Balance : ${(double.tryParse(dataInformation['Balance'].toString())) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))}',
              styles: const PosStyles(align: PosAlign.left));
        }
        if (Settings.getValue<bool>('key-print-bank-details', false)) {
          printer.hr();
          printer.text('${dataBankLedger['name']}',
              styles: const PosStyles(align: PosAlign.left));
          printer.text('ACC NO : ${dataBankLedger['account']}',
              styles: const PosStyles(align: PosAlign.left));
          printer.text('IFSC CODE : ${dataBankLedger['ifsc']}',
              styles: const PosStyles(align: PosAlign.left));
          printer.text('Branch : ${dataBankLedger['branch']}',
              styles: const PosStyles(align: PosAlign.left));
          printer.hr();
        }

        // ticket.feed(1);
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        if (isQrCodeKSA) {
          // Print QR Code using native function
          // printer.qrcode('example.com');
          if (taxSale) {
            printer.qrcode(SaudiConversion.getBase64(
                companySettings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(
                    DateUtil.datedYMD(dataInformation['DDate']) +
                        ' ' +
                        DateUtil.timeHMS(dataInformation['BTime'])),
                double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2)));
            printer.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          } else if (isEsQrCodeKSA) {
            printer.qrcode(SaudiConversion.getBase64(
                companySettings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(
                    DateUtil.datedYMD(dataInformation['DDate']) +
                        ' ' +
                        DateUtil.timeHMS(dataInformation['BTime'])),
                double.tryParse(dataInformation['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2)));
            printer.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          }
        } else {
          printer.feed(
              ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        }

        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    }
  }

  _taxableData(data) async {
    List<dynamic> newData = [];
    for (int i = 0; i < data.length; i++) {
      if (newData.isNotEmpty) {
        var index =
            newData.indexWhere((element) => element['tax'] == data[i]['igst']);
        if (index >= 0) {
          var element = newData[index];
          var oldItem = newData.elementAt(index);
          newData.removeAt(index);
          var newItem = {
            'tax': element['tax'],
            'taxable': oldItem['taxable'] + data[i]['GrossValue'],
            'CGST': oldItem['CGST'] + data[i]['CGST'],
            'SGST': oldItem['SGST'] + data[i]['SGST'],
            'IGST': oldItem['IGST'] + data[i]['IGST']
          };
          newData.insert(index, newItem);
        } else {
          newData.add(addTaxableJson(data[i]));
        }
      } else {
        newData.add(addTaxableJson(data[i]));
      }
    }
    taxableData = newData;
  }

  addTaxableJson(data) {
    return {
      'tax': data['igst'],
      'taxable': data['GrossValue'],
      'CGST': data['CGST'],
      'SGST': data['SGST'],
      'IGST': data['IGST']
    };
  }

  Future<void> salesReturnData(NetworkPrinter printer, PaperSize paper) async {
    var bill = widget.data[2];
    var printerSize = widget.data[3];
    CompanyInformation companySettings = widget.data[0];
    List<CompanySettings> settings = widget.data[1];
    var dataInformation = bill['Information'];
    var dataParticulars = bill['Particulars'];
    // var dataSerialNO = bill['SerialNO'];,
    // var dataDeliveryNote = bill['DeliveryNote'];
    // var otherAmount = bill['otherAmount'];
    var BalanceAmount = bill['balance'] == 'null'
        ? '0'
        : bill['balance'].toString().split(' ')[0].toString();
    var ledgerName = mainAccount
        .firstWhere(
          (element) =>
              element['LedCode'].toString() ==
              dataInformation['Customer'].toString(),
          orElse: () => {'LedName': dataInformation['ToName']},
        )['LedName']
        .toString();
    // header
    var taxSale = false;
    // salesTypeData.type == 'SALES-ES'
    //     ? false
    //     : salesTypeData.type == 'SALES-Q'
    //         ? false
    //         : salesTypeData.type == 'SALES-O'
    //             ? false
    //             : true;
    var invoiceHead =
        Settings.getValue<String>('key-sales-return-head', 'Sales Return');
    bool isQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
    bool isEsQrCodeKSA =
        ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
    int printCopy = Settings.getValue<int>('key-dropdown-print-copy-view', 0);
    int printerModel =
        Settings.getValue<int>('key-dropdown-printer-model-view', 0);
    // for (int pCopy = 0; pCopy <= printCopy; pCopy++) {
    if (printerSize == "2") {
      try {
        if (taxSale) {
          printer.text(companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size2,
              ),
              linesAfter: 1);
          companySettings.add1.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add1,
                  styles: const PosStyles(align: PosAlign.center, bold: true)));
          companySettings.add2.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add2,
                  styles: const PosStyles(align: PosAlign.center, bold: true)));
          printer.text(
              'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          printer.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          printer.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          printer.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: 'Date : ${DateUtil.dateDMY(dataInformation['DDate'])}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.text('Bill To : ',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          printer.text('${dataInformation['Toname']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          // if (isEsQrCodeKSA) {
          //   if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //     printer.text(
          //         companyTaxMode == 'INDIA'
          //             ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //             : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //         styles: const PosStyles(align: PosAlign.left, bold: true));
          //   }
          // }
          printer.hr();
          printer.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          printer.row([
            PosColumn(
                text: '   ',
                width: 2,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: 'Qty',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Price',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Total',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            if (double.tryParse(dataParticulars[i]['IGST'].toString()) > 0) {
              if (taxPercentages.contains(
                  '@' + dataParticulars[i]['IGST'].toString() + ' %')) {
              } else {
                taxPercentages +=
                    '@' + dataParticulars[i]['IGST'].toString() + ' %,';
              }
            }
            var itemName = dataParticulars[i]['ProductName'].toString();
            printer.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            printer.row([
              PosColumn(text: '', width: 2),
              PosColumn(text: dataParticulars[i]['Qty'].toString(), width: 2),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total : ',
                width: 5,
                styles: const PosStyles(bold: true)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(bold: true)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 2,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size1,
                    // width: PosTextSize.size1,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Tax : ' + taxPercentages,
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
        } else {
          if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
            printer.text(companySettings.name,
                styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                ),
                linesAfter: 1);
            printer.text(
              '',
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            // if (printCopy == 2) {
            //   //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
            //   //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
            //   ticket.text('عبدالله زهير');
            //   //       bold: true,));
            //   //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
            //   //   //   bold: true,));
            // }
            // linesAfter: 1);
            // header1
            companySettings.add1.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add1,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add2,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            printer.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            printer.row([
              PosColumn(
                  text: 'Date : ${DateUtil.dateDMY(dataInformation['DDate'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          } else {
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            printer.row([
              PosColumn(
                  text: 'Date : ${DateUtil.dateDMY(dataInformation['DDate'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          }
          printer.hr();

          printer.text('Bill To :',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          printer.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          // if (isEsQrCodeKSA) {
          //   if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //     printer.text(
          //         companyTaxMode == 'INDIA'
          //             ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //             : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //         styles: const PosStyles(align: PosAlign.left, bold: true));
          //   }
          // }
          printer.hr();
          printer.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          printer.row([
            PosColumn(text: ' ', width: 1),
            PosColumn(
                text: 'Qty', width: 3, styles: const PosStyles(bold: true)),
            PosColumn(
                text: 'Price',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: 'Total',
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            printer.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            printer.row([
              PosColumn(text: '', width: 1),
              PosColumn(
                  text: '${dataParticulars[i]['Qty']}',
                  width: 3,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Rate'].toString())
                      .toStringAsFixed(2),
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Total'].toString())
                      .toStringAsFixed(2),
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Sub =',
                width: 3,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size1,
                    // width: PosTextSize.size1,
                    align: PosAlign.right,
                    bold: true)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true
                    // height: PosTextSize.size3,
                    // width: PosTextSize.size2,
                    )),
          ]);
        }
        // for (var i = 0; i < otherAmount.length; i++) {
        //   if (otherAmount[i]['Amount'].toDouble() > 0) {
        //     printer.hr();
        //     printer.row([
        //       PosColumn(
        //           text: '${otherAmount[i]['LedName']} :',
        //           width: 6,
        //           styles: const PosStyles(align: PosAlign.right
        //               // height: PosTextSize.size2,
        //               // width: PosTextSize.size2,
        //               )),
        //       PosColumn(
        //           text: double.tryParse(otherAmount[i]['Amount'].toString())
        //               .toStringAsFixed(2),
        //           width: 6,
        //           styles: const PosStyles(
        //             align: PosAlign.right,
        //             // height: PosTextSize.size2,
        //             // width: PosTextSize.size2,
        //           )),
        //     ]);
        //   }
        // }
        // printer.hr();
        // printer.text(
        //     'Amount in Words: ${NumberToWord().convert('en', double.tryParse(dataInformation['GrandTotal'].toString()).round())}',
        //     linesAfter: 1);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Net Amount :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size2, width: PosTextSize.size2,
                    bold: true,
                    align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(dataInformation['NetAmount'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                    bold: true)),
          ]);
        } else {
          if (ledgerName != 'CASH') {
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Old Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(BalanceAmount.toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Net Amount :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text:
                      double.tryParse(dataInformation['GrandTotal'].toString())
                          .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
            printer.hr();
            // printer.row([
            //   PosColumn(
            //       text: 'Balance :',
            //       width: 6,
            //       styles: const PosStyles(
            //           // height: PosTextSize.size2, width: PosTextSize.size2,
            //           bold: true,
            //           align: PosAlign.right)),
            //   PosColumn(
            //       text: (double.tryParse(BalanceAmount) +
            //               (double.tryParse(
            //                   dataInformation['GrandTotal'].toString())))
            //           .toStringAsFixed(2),
            //       width: 6,
            //       styles: const PosStyles(
            //           align: PosAlign.right,
            //           // height: PosTextSize.size2,
            //           // width: PosTextSize.size2,
            //           bold: true)),
            // ]);
          } else {
            printer.hr();
            printer.row([
              PosColumn(
                  text: 'Net Amount :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text:
                      double.tryParse(dataInformation['GrandTotal'].toString())
                          .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          }
        }

        // ticket.feed(1);
        printer.text('Have a nice day',
            styles: const PosStyles(align: PosAlign.center));

        // if (isQrCodeKSA) {
        //   // Print QR Code using native function
        //   // printer.qrcode('example.com');
        //   if (taxSale) {
        //     printer.qrcode(SaudiConversion.getBase64(
        //         companySettings.name,
        //         ComSettings.getValue('GST-NO', settings),
        //         DateUtil.dateTimeQrDMY(
        //             DateUtil.datedYMD(dataInformation['DDate']) +
        //                 ' ' +
        //                 DateUtil.timeHMS(dataInformation['BTime'])),
        //         double.tryParse(dataInformation['GrandTotal'].toString())
        //             .toStringAsFixed(2),
        //         (double.tryParse(dataInformation['CGST'].toString()) +
        //                 double.tryParse(dataInformation['SGST'].toString()) +
        //                 double.tryParse(dataInformation['IGST'].toString()))
        //             .toStringAsFixed(2)));
        //     printer.feed(
        //         ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        //   } else if (isEsQrCodeKSA) {
        //     printer.qrcode(SaudiConversion.getBase64(
        //         companySettings.name,
        //         ComSettings.getValue('GST-NO', settings),
        //         DateUtil.dateTimeQrDMY(
        //             DateUtil.datedYMD(dataInformation['DDate']) +
        //                 ' ' +
        //                 DateUtil.timeHMS(dataInformation['BTime'])),
        //         double.tryParse(dataInformation['GrandTotal'].toString())
        //             .toStringAsFixed(2),
        //         (double.tryParse(dataInformation['CGST'].toString()) +
        //                 double.tryParse(dataInformation['SGST'].toString()) +
        //                 double.tryParse(dataInformation['IGST'].toString()))
        //             .toStringAsFixed(2)));
        //     printer.feed(
        //         ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        //   }
        // } else {
        //   printer.feed(
        //       ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        // }
        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    } else {
      try {
        if (taxSale) {
          printer.text(companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size2,
              ),
              linesAfter: 1);

          // if(printCopy==2){
          //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
          //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
          //   ticket.text('عبدالله زهير',containsChinese: false,styles: const PosStyles(align: PosAlign.center,codeTable: ,
          //       bold: true,));
          //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
          //   //   bold: true,));
          // }
          // linesAfter: 1);
          // header1
          companySettings.add1.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add1,
                  styles: const PosStyles(align: PosAlign.center)));
          companySettings.add2.toString().trim().isNotEmpty ??
              (printer.text(companySettings.add2,
                  styles: const PosStyles(align: PosAlign.center)));
          printer.text(
              'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center));
          printer.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center));
          printer.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 12,
                styles: const PosStyles(align: PosAlign.left)),
          ]);
          printer.row([
            PosColumn(
                text: 'Date : ${DateUtil.dateDMY(dataInformation['DDate'])}',
                width: 12,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          printer.text('Bill To : ${dataInformation['Toname']}',
              styles: const PosStyles(align: PosAlign.left));
          // if (isEsQrCodeKSA) {
          //   if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //     printer.text(
          //         companyTaxMode == 'INDIA'
          //             ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //             : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //         styles: const PosStyles(align: PosAlign.left));
          //   }
          // }
          printer.hr();
          printer.row([
            PosColumn(text: 'Description', width: 7),
            PosColumn(text: 'Qty', width: 1),
            PosColumn(
                text: 'Price',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Total',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            if (double.tryParse(dataParticulars[i]['IGST'].toString()) > 0) {
              if (taxPercentages.contains(
                  '@' + dataParticulars[i]['IGST'].toString() + ' %')) {
              } else {
                taxPercentages +=
                    '@' + dataParticulars[i]['IGST'].toString() + ' %,';
              }
            }
            var itemName = paper.width == PaperSize.mm80.width
                ? dataParticulars[i]['ProductName'].toString().trim().length >
                        26
                    ? dataParticulars[i]['ProductName']
                        .toString()
                        .trim()
                        .characters
                        .take(26)
                        .toString()
                    : dataParticulars[i]['ProductName'].toString()
                : dataParticulars[i]['ProductName'].toString().trim().length >
                        12
                    ? dataParticulars[i]['ProductName']
                        .toString()
                        .trim()
                        .characters
                        .take(12)
                        .toString()
                    : dataParticulars[i]['ProductName'].toString();
            printer.row([
              PosColumn(text: itemName, width: 7),
              PosColumn(text: '${dataParticulars[i]['Qty']}', width: 1),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(text: 'Total : ', width: 7),
            PosColumn(text: '$totalQty', width: 1),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                  // height: PosTextSize.size1,
                  // width: PosTextSize.size1,
                  align: PosAlign.right,
                )),
            PosColumn(
                text: '${dataInformation['NetAmount']}',
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size3,
                  // width: PosTextSize.size2,
                )),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Tax : ' + taxPercentages,
                width: 6,
                styles: const PosStyles(
                  // height: PosTextSize.size3,
                  // width: PosTextSize.size2,
                  align: PosAlign.right,
                )),
            PosColumn(
                text: (double.tryParse(dataInformation['CGST'].toString()) +
                        double.tryParse(dataInformation['SGST'].toString()) +
                        double.tryParse(dataInformation['IGST'].toString()))
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size3,
                  // width: PosTextSize.size2,
                )),
          ]);
        } else {
          if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
            printer.text(companySettings.name,
                styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                ),
                linesAfter: 1);
            // if (printCopy == 2) {
            //   //   Uint8List encArabic = await CharsetConverter.encode("windows-1256", "اهلا");charset.178
            //   //   ticket.textEncoded(encArabic, styles: PosStyles(codeTable: PosCodeTable.arabic));
            //   ticket.text('عبدالله زهير');
            //   //       bold: true,));
            //   //   // ticket.textEncoded(utf8.encode('عبدالله زهير'),styles: const PosStyles(align: PosAlign.center,
            //   //   //   bold: true,));
            // }
            // linesAfter: 1);
            // header1
            companySettings.add1.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add1,
                    styles: const PosStyles(align: PosAlign.center)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (printer.text(companySettings.add2,
                    styles: const PosStyles(align: PosAlign.center)));
            printer.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
            printer.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center));
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.left)),
              PosColumn(
                  text: 'Date : ${DateUtil.dateDMY(dataInformation['DDate'])}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
          } else {
            printer.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            printer.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.left)),
              PosColumn(
                  text: 'Date : ${DateUtil.dateDMY(dataInformation['DDate'])}',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
          }
          printer.text('Bill To : ${dataInformation['Toname']}',
              styles: const PosStyles(align: PosAlign.left));

          // if (isEsQrCodeKSA) {
          //   if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //     printer.text(
          //         companyTaxMode == 'INDIA'
          //             ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //             : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //         styles: const PosStyles(align: PosAlign.left));
          //   }
          // }
          printer.hr();
          printer.row([
            PosColumn(text: 'Description', width: 7),
            PosColumn(text: 'Qty', width: 1),
            PosColumn(
                text: 'Price',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Total',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = paper.width == PaperSize.mm80.width
                ? dataParticulars[i]['ProductName'].toString().trim().length >
                        26
                    ? dataParticulars[i]['ProductName']
                        .toString()
                        .trim()
                        .characters
                        .take(26)
                        .toString()
                    : dataParticulars[i]['ProductName'].toString()
                : dataParticulars[i]['ProductName'].toString().trim().length >
                        12
                    ? dataParticulars[i]['ProductName']
                        .toString()
                        .trim()
                        .characters
                        .take(12)
                        .toString()
                    : dataParticulars[i]['ProductName'].toString();
            printer.row([
              PosColumn(text: itemName, width: 7),
              PosColumn(
                  text: '${dataParticulars[i]['Qty']}',
                  width: 1,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Rate'].toString())
                      .toStringAsFixed(2),
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Total'].toString())
                      .toStringAsFixed(2),
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Sub =',
                width: 2,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: '$totalQty',
                width: 3,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 4,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          printer.hr();
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                  // height: PosTextSize.size1,
                  // width: PosTextSize.size1,
                  align: PosAlign.right,
                )),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size3,
                  // width: PosTextSize.size2,
                )),
          ]);
        }

        printer.hr();
        printer.row([
          PosColumn(
              text: 'Net Amount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text: double.tryParse(dataInformation['GrandTotal'].toString())
                  .toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        printer.hr();
        printer.text(
            'Amount in Words: ${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
            linesAfter: 1);

        // ticket.feed(1);
        printer.text('Have a nice day',
            styles: const PosStyles(align: PosAlign.center));

        // if (isQrCodeKSA) {
        //   // Print QR Code using native function
        //   // printer.qrcode('example.com');
        //   if (taxSale) {
        //     printer.qrcode(SaudiConversion.getBase64(
        //         companySettings.name,
        //         ComSettings.getValue('GST-NO', settings),
        //         DateUtil.dateTimeQrDMY(
        //             DateUtil.datedYMD(dataInformation['DDate']) +
        //                 ' ' +
        //                 DateUtil.timeHMS(dataInformation['BTime'])),
        //         double.tryParse(dataInformation['GrandTotal'].toString())
        //             .toStringAsFixed(2),
        //         (double.tryParse(dataInformation['CGST'].toString()) +
        //                 double.tryParse(dataInformation['SGST'].toString()) +
        //                 double.tryParse(dataInformation['IGST'].toString()))
        //             .toStringAsFixed(2)));
        //     printer.feed(
        //         ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        //   } else if (isEsQrCodeKSA) {
        //     printer.qrcode(SaudiConversion.getBase64(
        //         companySettings.name,
        //         ComSettings.getValue('GST-NO', settings),
        //         DateUtil.dateTimeQrDMY(
        //             DateUtil.datedYMD(dataInformation['DDate']) +
        //                 ' ' +
        //                 DateUtil.timeHMS(dataInformation['BTime'])),
        //         double.tryParse(dataInformation['GrandTotal'].toString())
        //             .toStringAsFixed(2),
        //         (double.tryParse(dataInformation['CGST'].toString()) +
        //                 double.tryParse(dataInformation['SGST'].toString()) +
        //                 double.tryParse(dataInformation['IGST'].toString()))
        //             .toStringAsFixed(2)));
        //     printer.feed(
        //         ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        //   }
        // } else {
        printer
            .feed(ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        // }

        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    }
  }

  Future<void> receiptData(NetworkPrinter printer, PaperSize paper) async {
    var bill = widget.data[2][0][0];
    var printerSize = widget.data[3];
    CompanyInformation companySettings = widget.data[0];
    List<CompanySettings> settings = widget.data[1];
    var dataParticulars = bill['Particular'];
    var ledgerName = bill['name'];
    var invoiceHead =
        Settings.getValue<String>('key-receipt-voucher-head', 'RECEIPT')
                .isNotEmpty
            ? Settings.getValue<String>('key-receipt-voucher-head', 'RECEIPT')
            : 'Receipt Invoice';

    if (printerSize == "2") {
      try {
        printer.text(companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            ),
            linesAfter: 1);
        printer.text(
          '',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        companySettings.add1.toString().trim().isNotEmpty ??
            (printer.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        companySettings.add2.toString().trim().isNotEmpty ??
            (printer.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        printer.text(
            'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        printer.text(
            companyTaxMode == 'INDIA'
                ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        printer.text(invoiceHead,
            styles: const PosStyles(align: PosAlign.center, bold: true));
        // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
        //     styles: const PosStyles(align: PosAlign.left));
        printer.hr();
        printer.row([
          PosColumn(
              text: 'Invoice No : ${bill['entryNo']}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        printer.row([
          PosColumn(
              text: 'Date : ${DateUtil.dateDMY(bill['date'])}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        printer.text('From : ',
            styles: const PosStyles(align: PosAlign.left, bold: true));
        printer.text('${bill['name']}',
            styles: const PosStyles(align: PosAlign.left, bold: true));

        printer.row([
          PosColumn(
              text: 'Amount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text:
                  double.tryParse(bill['amount'].toString()).toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        printer.row([
          PosColumn(
              text: 'Discount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text: double.tryParse(bill['discount'].toString())
                  .toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size2, width: PosTextSize.size2,
                    bold: true,
                    align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(bill['total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                    bold: true)),
          ]);
        } else {
          if (ledgerName != 'CASH') {
            var bal = bill['oldBalance'].toString().split(' ')[0];
            double oldBalance = double.tryParse(bal.toString());
            printer.row([
              PosColumn(
                  text: 'Total :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: bill['total'].toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.row([
              PosColumn(
                  text: 'Old Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: oldBalance.toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.text(
              '',
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
              ),
            );
            double balance =
                oldBalance - double.tryParse(bill['total'].toString());
            printer.row([
              PosColumn(
                  text: 'Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: balance.toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          } else {
            printer.row([
              PosColumn(
                  text: 'Total :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(bill['total'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          }
        }

        // ticket.feed(1);
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    } else {
      try {
        printer.text(companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            ),
            linesAfter: 1);
        printer.text(
          '',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        companySettings.add1.toString().trim().isNotEmpty ??
            (printer.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        companySettings.add2.toString().trim().isNotEmpty ??
            (printer.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        printer.text(
            'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        printer.text(
            companyTaxMode == 'INDIA'
                ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        printer.text(invoiceHead,
            styles: const PosStyles(align: PosAlign.center, bold: true));
        // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
        //     styles: const PosStyles(align: PosAlign.left));
        printer.hr();
        printer.row([
          PosColumn(
              text: 'Invoice No : ${bill['entryNo']}',
              width: 6,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Date : ${DateUtil.dateDMY(bill['date'])}',
              width: 6,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        printer.row([
          PosColumn(
              text: 'From : ${bill['name']}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        printer.row([
          PosColumn(
              text: 'Amount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text:
                  double.tryParse(bill['amount'].toString()).toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        printer.row([
          PosColumn(
              text: 'Discount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text: double.tryParse(bill['discount'].toString())
                  .toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size2, width: PosTextSize.size2,
                    bold: true,
                    align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(bill['total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                    bold: true)),
          ]);
        } else {
          if (bill['name'] != 'CASH') {
            var bal = bill['oldBalance'].toString().split(' ')[0];
            double oldBalance = double.tryParse(bal.toString());
            printer.row([
              PosColumn(
                  text: 'Total :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: bill['total'].toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.row([
              PosColumn(
                  text: 'Old Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: oldBalance.toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.text(
              '',
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
              ),
            );
            double balance = oldBalance > 0
                ? oldBalance > double.tryParse(bill['total'].toString())
                    ? (oldBalance - double.tryParse(bill['total'].toString()))
                    : double.tryParse(bill['total'].toString()) - oldBalance
                : double.tryParse(bill['total'].toString());
            printer.row([
              PosColumn(
                  text: 'Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: balance.toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          } else {
            printer.row([
              PosColumn(
                  text: 'Total :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(bill['total'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          }
        }

        // ticket.feed(1);
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    }
  }

  Future<void> paymentData(NetworkPrinter printer, PaperSize paper) async {
    var bill = widget.data[2][0][0];
    var printerSize = widget.data[3];
    CompanyInformation companySettings = widget.data[0];
    List<CompanySettings> settings = widget.data[1];
    var dataParticulars = bill['Particular'];
    var ledgerName = bill['name'];

    var invoiceHead =
        Settings.getValue<String>('key-payment-voucher-head', 'PAYMENT')
                .isNotEmpty
            ? Settings.getValue<String>('key-payment-voucher-head', 'PAYMENT')
            : 'Payment Invoice';

    if (printerSize == "2") {
      try {
        printer.text(companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            ),
            linesAfter: 1);
        printer.text(
          '',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        companySettings.add1.toString().trim().isNotEmpty ??
            (printer.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        companySettings.add2.toString().trim().isNotEmpty ??
            (printer.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        printer.text(
            'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        printer.text(
            companyTaxMode == 'INDIA'
                ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        printer.text(invoiceHead,
            styles: const PosStyles(align: PosAlign.center, bold: true));
        // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
        //     styles: const PosStyles(align: PosAlign.left));
        printer.hr();
        printer.row([
          PosColumn(
              text: 'Invoice No : ${bill['entryNo']}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        printer.row([
          PosColumn(
              text: 'Date : ${DateUtil.dateDMY(bill['date'])}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        printer.text('From : ',
            styles: const PosStyles(align: PosAlign.left, bold: true));
        printer.text('${bill['name']}',
            styles: const PosStyles(align: PosAlign.left, bold: true));

        printer.row([
          PosColumn(
              text: 'Amount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text:
                  double.tryParse(bill['amount'].toString()).toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        printer.row([
          PosColumn(
              text: 'Discount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text: double.tryParse(bill['discount'].toString())
                  .toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size2, width: PosTextSize.size2,
                    bold: true,
                    align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(bill['total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                    bold: true)),
          ]);
        } else {
          if (ledgerName != 'CASH') {
            var bal = bill['oldBalance'].toString().split(' ')[0];
            double oldBalance = double.tryParse(bal.toString());
            printer.row([
              PosColumn(
                  text: 'Total :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: bill['total'].toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.row([
              PosColumn(
                  text: 'Old Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: oldBalance.toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.text(
              '',
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
              ),
            );
            double balance =
                oldBalance > double.tryParse(bill['total'].toString())
                    ? (oldBalance - double.tryParse(bill['total'].toString()))
                    : double.tryParse(bill['total'].toString());
            printer.row([
              PosColumn(
                  text: 'Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: balance.toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          } else {
            printer.row([
              PosColumn(
                  text: 'Total :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(bill['total'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          }
        }

        // ticket.feed(1);
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    } else {
      try {
        printer.text(companySettings.name,
            styles: PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            ),
            linesAfter: 1);
        printer.text(
          '',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        companySettings.add1.toString().trim().isNotEmpty ??
            (printer.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        companySettings.add2.toString().trim().isNotEmpty ??
            (printer.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        printer.text(
            'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        printer.text(
            companyTaxMode == 'INDIA'
                ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        printer.text(invoiceHead,
            styles: const PosStyles(align: PosAlign.center, bold: true));
        // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
        //     styles: const PosStyles(align: PosAlign.left));
        printer.hr();
        printer.row([
          PosColumn(
              text: 'Invoice No : ${bill['entryNo']}',
              width: 6,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Date : ${DateUtil.dateDMY(bill['date'])}',
              width: 6,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        printer.row([
          PosColumn(
              text: 'From : ${bill['name']}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        printer.row([
          PosColumn(
              text: 'Amount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text:
                  double.tryParse(bill['amount'].toString()).toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        printer.row([
          PosColumn(
              text: 'Discount :',
              width: 6,
              styles: const PosStyles(
                  // height: PosTextSize.size2, width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text: double.tryParse(bill['discount'].toString())
                  .toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  // height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          printer.row([
            PosColumn(
                text: 'Total :',
                width: 6,
                styles: const PosStyles(
                    // height: PosTextSize.size2, width: PosTextSize.size2,
                    bold: true,
                    align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(bill['total'].toString())
                    .toStringAsFixed(2),
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.right,
                    // height: PosTextSize.size2,
                    // width: PosTextSize.size2,
                    bold: true)),
          ]);
        } else {
          if (bill['name'] != 'CASH') {
            var bal = bill['oldBalance'].toString().split(' ')[0];
            double oldBalance = double.tryParse(bal.toString());
            printer.row([
              PosColumn(
                  text: 'Total :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: bill['total'].toString(),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.row([
              PosColumn(
                  text: 'Old Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: oldBalance.toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
            ]);
            printer.text(
              '',
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
              ),
            );
            double balance =
                oldBalance > double.tryParse(bill['total'].toString())
                    ? (oldBalance - double.tryParse(bill['total'].toString()))
                    : double.tryParse(bill['total'].toString());
            printer.row([
              PosColumn(
                  text: 'Balance :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: balance.toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          } else {
            printer.row([
              PosColumn(
                  text: 'Total :',
                  width: 6,
                  styles: const PosStyles(
                      // height: PosTextSize.size2, width: PosTextSize.size2,
                      bold: true,
                      align: PosAlign.right)),
              PosColumn(
                  text: double.tryParse(bill['total'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(
                      align: PosAlign.right,
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      bold: true)),
            ]);
          }
        }

        // ticket.feed(1);
        printer.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        printer.feed(2);
        printer.cut();
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
        printer.feed(2);
        printer.cut();
      }
    }
  }

  Future<void> testData(NetworkPrinter printer, PaperSize paper) async {
    try {
      printer.text(
        'Form with no Data',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          // height: PosTextSize.size2,
          // width: PosTextSize.size2,
        ),
      );
      printer.text(
        'This is not a model',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          // height: PosTextSize.size2,
          // width: PosTextSize.size2,
        ),
      );
      printer.feed(2);
      printer.cut();
      printer.cut();
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'tcp print:');
      printer.feed(2);
      printer.cut();
    }
  }
}
