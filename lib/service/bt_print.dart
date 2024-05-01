// @dart = 2.11
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_x/esc_pos_utils_x.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart' as pos;
// import 'package:blue_print_pos/blue_print_pos.dart';
// import 'package:blue_print_pos/models/blue_device.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/number_to_word.dart';

class BtPrint extends StatefulWidget {
  final data;
  final Uint8List byteImage;

  const BtPrint(this.data, this.byteImage, {Key key}) : super(key: key);

  @override
  _BtPrintState createState() => _BtPrintState();
}

class _BtPrintState extends State<BtPrint> {
  PrinterBluetoothManager printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _devices = [];
  bool _connected = false;
  bool _isLoading = false;
  BluetoothDevice _device;
  String tips = 'no device connect';
  List<BluetoothDevice> _blueDevices = [];
  var companyTaxMode = '';
  int printModel = 2;

  // BluetoothManager bluetoothManager = BluetoothManager.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScanPressed());
    initDefaultData();
  }

  final BlueThermalPrinter _bluePrintPos = BlueThermalPrinter.instance;

  Future<void> _onScanPressed() async {
    setState(() => _isLoading = true);
    _bluePrintPos.getBondedDevices().then((List<BluetoothDevice> devices) {
      debugPrint(devices.toString());
      if (devices.isNotEmpty) {
        var map = devices.map((e) {
          var _dat = pos.BluetoothDevice()
            ..name = e.name
            ..address = e.address
            ..connected = e.connected
            ..type = e.type;

          return PrinterBluetooth(_dat);
        }).toList();
        setState(() {
          _devices = map;
          _blueDevices = devices;
          _isLoading = false;
          printDefault();
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  void _onConnect() async {
    if (_device != null && _device.address != null) {
      var _dat = pos.BluetoothDevice()
        ..name = _device.name
        ..connected = _device.connected
        ..type = _device.type;

      PrinterBluetooth(_dat);
      await _bluePrintPos.connect(_device);
    } else {
      setState(() {
        tips = 'please select device';
      });
      debugPrint('please select device');
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //
  //   printerManager.scanResults.listen((devices) async {
  //     // debugPrint('UI: Devices found ${devices.length}');
  //     setState(() {
  //       _devices = devices;
  //     });
  //   });
  //   if (_devices.isEmpty) {
  //     _startScanDevices();
  //   }
  // }

  void _startScanDevices() {
    setState(() {
      _devices = [];
    });
    printerManager.startScan(const Duration(seconds: 2));
  }

  void _stopScanDevices() {
    printerManager.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print'),
      ),
      body: ListView.builder(
          itemCount: _devices.length,
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              onTap: () => _setPrinter(_devices[index]),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(_devices[index].name ?? ''),
                              Text(_devices[index].address ?? ''),
                              Text(
                                'Click to print receipt',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                            onPressed: () {
                              setState(() {
                                defaultPrinter = _devices[index].name;
                                setDefaultPrinter();
                              });
                            },
                            child: Text(defaultPrinter.isNotEmpty
                                ? _devices[index].name == defaultPrinter
                                    ? 'Default'
                                    : 'Set Default'
                                : 'Set Default'))
                      ],
                    ),
                  ),
                  const Divider(),
                ],
              ),
            );
          }),
      floatingActionButton: FutureBuilder(
        future: getResult(),
        initialData: const [],
        builder: (c, snapshot) {
          if (snapshot.hasData) {
            return FloatingActionButton(
              child: const Icon(Icons.stop),
              onPressed: _stopScanDevices,
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
              child: const Icon(Icons.search),
              onPressed: _onScanPressed,
            );
          }
        },
      ),
    );
  }

  getResult() {
    setState(() {
      _blueDevices;
    });
    return Future.value(_blueDevices);
  }

  void _setPrinter(PrinterBluetooth printer) async {
    debugPrint(printer.name);
    printerManager.selectPrinter(printer);

    var printerSize = widget.data[3];
    PaperSize paper = PaperSize.mm80;
    if (printerSize == "2") {
      paper = PaperSize.mm58;
    } else if (printerSize == "3") {
      paper = PaperSize.mm80;
    } else if (printerSize == "4") {
      paper = PaperSize.mm112;
    } else if (printerSize == "5") {
      paper = PaperSize.mm58;
    }

    if (widget.data.isNotEmpty) {
      printModel =
          ComSettings.appSettings('int', "key-dropdown-printer-model-view", 2);
      if (widget.data[4] == 'SALE') {
        final PosPrintResult res =
            await printerManager.printTicket(await (printModel == 3
                ? salesVatData(paper)
                : printModel == 4
                    ? salesGSTData(paper)
                    : printModel == 5
                        ? salesVat1Data(paper)
                        : salesDefaultData(paper)));
        showDialog(
            context: context,
            builder: (context) => AlertDialog(content: Text(res.msg)));
      } else if (widget.data[4] == 'SALES RETURN') {
        final PosPrintResult res =
            await printerManager.printTicket(await salesReturnData(paper));
        showDialog(
            context: context,
            builder: (context) => AlertDialog(content: Text(res.msg)));
      } else if (widget.data[4] == 'RECEIPT') {
        final PosPrintResult res =
            await printerManager.printTicket(await receiptData(paper));
        showDialog(
            context: context,
            builder: (context) => AlertDialog(content: Text(res.msg)));
      } else if (widget.data[4] == 'PAYMENT') {
        final PosPrintResult res =
            await printerManager.printTicket(await paymentData(paper));
        showDialog(
            context: context,
            builder: (context) => AlertDialog(content: Text(res.msg)));
      }
    } else {
      final PosPrintResult res =
          await printerManager.printTicket(await testData(paper));
      showDialog(
          context: context,
          builder: (context) => AlertDialog(content: Text(res.msg)));
    }
  }

  Future<List<int>> printImage(PaperSize paper) async {
    var profile = await CapabilityProfile.load();
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];
    // Print image
    final Uint8List bytess = widget.byteImage;
    final img.Image image = img.decodeImage(bytess);
    bytes += ticket.image(image);
    bytes += ticket.feed(2);
    bytes += ticket.cut();
    return bytes;
  }

  var taxPercentages = '';
  List<dynamic> taxableData = [];

  Future<List<int>> salesVatData(PaperSize paper) async {
    var profile = await CapabilityProfile.load();
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];
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
          bytes += ticket.text(
            companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              // height: PosTextSize.size2,
              // width: PosTextSize.size2,
            ),
          );
          var text2 = ticket.text(companySettings.add1,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          companySettings.add1.toString().trim().isNotEmpty ?? (bytes += text2);
          var text3 = ticket.text(companySettings.add2,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          companySettings.add2.toString().trim().isNotEmpty ?? (bytes += text3);
          bytes += ticket.text(
              'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          bytes += ticket.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          bytes += ticket.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.row([
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
          bytes += ticket.text('Bill To : ',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          bytes += ticket.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              bytes += ticket.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left, bold: true));
            }
          }
          bytes += ticket.hr();
          bytes += ticket.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          bytes += ticket.row([
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
            bytes += ticket.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.text(
              companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            bytes += ticket.text(
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
                (bytes += ticket.text(companySettings.add1,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (bytes += ticket.text(companySettings.add2,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            bytes += ticket.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            bytes += ticket.hr();
            bytes += ticket.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            bytes += ticket.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          } else {
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            bytes += ticket.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            bytes += ticket.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          }
          bytes += ticket.hr();

          bytes += ticket.text('Bill To :',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          bytes += ticket.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              bytes += ticket.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left, bold: true));
            }
          }
          bytes += ticket.hr();
          bytes += ticket.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          bytes += ticket.row([
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
          bytes += ticket.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            bytes += ticket.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
        // bytes += ticket.hr();
        // bytes += ticket.text(
        //     'Amount in Words: ${NumberToWord().convertToDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
        //     linesAfter: 1);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
        bytes += ticket.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        if (isQrCodeKSA) {
          // Print QR Code using native function
          // bytes += ticket.qrcode('example.com');
          if (taxSale) {
            bytes += ticket.qrcode(SaudiConversion.getBase64(
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
            bytes += ticket.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          } else if (isEsQrCodeKSA) {
            bytes += ticket.qrcode(SaudiConversion.getBase64(
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
            bytes += ticket.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          }
        } else {
          bytes += ticket.feed(
              ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        }
        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
      }
    } else {
      try {
        if (taxSale) {
          bytes += ticket.text(
            companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              // height: PosTextSize.size2,
              // width: PosTextSize.size2,
            ),
          );
          bytes += ticket.text('');

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
          var text2 = ticket.text(companySettings.add1,
              styles: const PosStyles(align: PosAlign.center));
          companySettings.add1.toString().trim().isNotEmpty ?? (bytes += text2);
          var text3 = ticket.text(companySettings.add2,
              styles: const PosStyles(align: PosAlign.center));
          companySettings.add2.toString().trim().isNotEmpty ?? (bytes += text3);
          bytes += ticket.text(
              'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center));
          bytes += ticket.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center));
          bytes += ticket.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.hr();
          bytes += ticket.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 12,
                styles: const PosStyles(align: PosAlign.left)),
          ]);
          bytes += ticket.row([
            PosColumn(
                text:
                    'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                width: 12,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          bytes += ticket.hr();
          bytes += ticket.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left));
          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              bytes += ticket.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left));
            }
          }
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.text(
              companySettings.name,
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
                (bytes += ticket.text(companySettings.add1,
                    styles: const PosStyles(align: PosAlign.center)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (bytes += ticket.text(companySettings.add2,
                    styles: const PosStyles(align: PosAlign.center)));
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
            bytes += ticket.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center));
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            bytes += ticket.row([
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
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            bytes += ticket.row([
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
          bytes += ticket.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              bytes += ticket.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left));
            }
          }
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
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
            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
        bytes += ticket.hr();
        bytes += ticket.row([
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
        bytes += ticket.hr();
        bytes += ticket.text(
            'Amount in Words: ${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
            linesAfter: 1);

        // ticket.feed(1);
        bytes += ticket.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        if (isQrCodeKSA) {
          // Print QR Code using native function
          // bytes += ticket.qrcode('example.com');
          if (taxSale) {
            bytes += ticket.qrcode(SaudiConversion.getBase64(
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
            bytes += ticket.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          } else if (isEsQrCodeKSA) {
            bytes += ticket.qrcode(SaudiConversion.getBase64(
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
            bytes += ticket.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          }
        } else {
          bytes += ticket.feed(
              ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        }
        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
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
    //         .recordError(e, s, reason: 'bt print:' + ticket.toString());
    //     return ticket;
    //   }
    // }
    // }
  }

  Future<List<int>> salesVat1Data(PaperSize paper) async {
    var profile = await CapabilityProfile.load();
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];
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
          bytes += ticket.text(
            companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              // height: PosTextSize.size2,
              // width: PosTextSize.size2,
            ),
          );
          var text2 = ticket.text(companySettings.add1,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          companySettings.add1.toString().trim().isNotEmpty ?? (bytes += text2);
          var text3 = ticket.text(companySettings.add2,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          companySettings.add2.toString().trim().isNotEmpty ?? (bytes += text3);
          bytes += ticket.text(
              'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          bytes += ticket.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          bytes += ticket.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.row([
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
          bytes += ticket.text('Bill To : ',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          bytes += ticket.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              bytes += ticket.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left, bold: true));
            }
          }
          bytes += ticket.hr();
          bytes += ticket.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          bytes += ticket.row([
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
            bytes += ticket.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.text(
              companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            bytes += ticket.text(
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
                (bytes += ticket.text(companySettings.add1,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (bytes += ticket.text(companySettings.add2,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            bytes += ticket.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            bytes += ticket.hr();
            bytes += ticket.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            bytes += ticket.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          } else {
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            bytes += ticket.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            bytes += ticket.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          }
          bytes += ticket.hr();

          bytes += ticket.text('Bill To :',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          bytes += ticket.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              bytes += ticket.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left, bold: true));
            }
          }
          bytes += ticket.hr();
          bytes += ticket.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          bytes += ticket.row([
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
          bytes += ticket.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            bytes += ticket.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
        // bytes += ticket.hr();
        // bytes += ticket.text(
        //     'Amount in Words: ${NumberToWord().convert('en', double.tryParse(dataInformation['GrandTotal'].toString()).round())}',
        //     linesAfter: 1);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
        bytes += ticket.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
      }
    } else {
      try {
        if (taxSale) {
          bytes += ticket.text(
            companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              // height: PosTextSize.size2,
              // width: PosTextSize.size2,
            ),
          );
          bytes += ticket.text('');

          var text2 = ticket.text(companySettings.add1,
              styles: const PosStyles(align: PosAlign.center));
          companySettings.add1.toString().trim().isNotEmpty ?? (bytes += text2);
          var text3 = ticket.text(companySettings.add2,
              styles: const PosStyles(align: PosAlign.center));
          companySettings.add2.toString().trim().isNotEmpty ?? (bytes += text3);
          bytes += ticket.text(
              'Phone No: ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center));
          bytes += ticket.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO: ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN NO: ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center));
          bytes += ticket.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.hr();
          bytes += ticket.row([
            PosColumn(
                text: 'Voucher No:${dataInformation['InvoiceNo']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: '',
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          bytes += ticket.row([
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
          bytes += ticket.row([
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
          bytes += ticket.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO:${dataInformation['gstno'].toString().trim()}'
                  : 'Party TRNNO:${dataInformation['gstno'].toString().trim()}',
              styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.row([
              PosColumn(
                  text: '${i + 1}',
                  width: 1,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: itemName,
                  width: 11,
                  styles: const PosStyles(align: PosAlign.left)),
            ]);
            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.row([
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
          bytes += ticket.row([
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
          bytes += ticket.row([
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
            bytes += ticket.text(
              companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );

            var text2 = ticket.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center));
            companySettings.add1.toString().trim().isNotEmpty ??
                (bytes += text2);
            var text3 = ticket.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center));
            companySettings.add2.toString().trim().isNotEmpty ??
                (bytes += text3);
            bytes += ticket.text(
                'Phone No: ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
            bytes += ticket.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO: ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN NO: ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center));
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          } else {
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          bytes += ticket.row([
            PosColumn(
                text: 'Voucher No:${dataInformation['InvoiceNo']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: '',
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          bytes += ticket.row([
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
          bytes += ticket.row([
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
          bytes += ticket.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO:${dataInformation['gstno'].toString().trim()}'
                  : 'Party TRNNO:${dataInformation['gstno'].toString().trim()}',
              styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.row([
              PosColumn(
                  text: '${i + 1}',
                  width: 1,
                  styles: const PosStyles(align: PosAlign.right)),
              PosColumn(
                  text: itemName,
                  width: 11,
                  styles: const PosStyles(align: PosAlign.left)),
            ]);
            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.row([
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
          bytes += ticket.row([
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
          bytes += ticket.row([
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

        bytes += ticket.hr();
        bytes += ticket.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        bytes += ticket
            .feed(ComSettings.appSettings('int', 'key-dropdown-print-line', 1));

        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
      }
    }
  }

  Future<List<int>> salesGSTData(PaperSize paper) async {
    var profile = await CapabilityProfile.load();
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];
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
          bytes += ticket.text(
            companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              // height: PosTextSize.size2,
              // width: PosTextSize.size2,
            ),
          );
          if (companySettings.add1.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add2.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add3.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add3,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add4.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add4,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.telephone.toString().trim().isNotEmpty ||
              companySettings.mobile.toString().trim().isNotEmpty) {
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
          }
          bytes += ticket.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : companyTaxMode == 'GULF'
                      ? 'TRN : ${ComSettings.getValue('GST-NO', settings)}'
                      : 'TaxNo : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          bytes += ticket.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.row([
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
          bytes += ticket.text('Bill To : ',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          bytes += ticket.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          //not acceptable if (isEsQrCodeKSA) {
          if (dataInformation['gstno'].toString().trim().isNotEmpty) {
            bytes += ticket.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                    : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                styles: const PosStyles(align: PosAlign.left, bold: true));
          }
          // }
          bytes += ticket.hr();
          bytes += ticket.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          bytes += ticket.row([
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
            bytes += ticket.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            bytes += ticket.row([
              PosColumn(text: '', width: 1),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                  width: 4),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 3,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 4,
                  styles: const PosStyles(align: PosAlign.right, bold: true)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          }
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.text(
              companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            bytes += ticket.text(
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
                (bytes += ticket.text(companySettings.add1,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (bytes += ticket.text(companySettings.add2,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            bytes += ticket.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            bytes += ticket.hr();
            bytes += ticket.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            bytes += ticket.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          } else {
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            bytes += ticket.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            bytes += ticket.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          }
          bytes += ticket.hr();

          bytes += ticket.text('Bill To :',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          bytes += ticket.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              bytes += ticket.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left, bold: true));
            }
          }
          bytes += ticket.hr();
          bytes += ticket.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          bytes += ticket.row([
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
          bytes += ticket.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            bytes += ticket.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
        // bytes += ticket.hr();
        // bytes += ticket.text(
        //     'Amount in Words: ${NumberToWord().convert('en', double.tryParse(dataInformation['GrandTotal'].toString()).round())}',
        //     linesAfter: 1);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
        bytes += ticket.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        if (isQrCodeKSA) {
          // Print QR Code using native function
          // bytes += ticket.qrcode('example.com');
          if (taxSale) {
            bytes += ticket.qrcode(SaudiConversion.getBase64(
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
            bytes += ticket.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          } else if (isEsQrCodeKSA) {
            bytes += ticket.qrcode(SaudiConversion.getBase64(
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
            bytes += ticket.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          }
        } else {
          bytes += ticket.feed(
              ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        }
        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
      }
    } else {
      try {
        if (taxSale) {
          bytes += ticket.text(
            companySettings.name,
            styles: const PosStyles(
                align: PosAlign.center, bold: true, height: PosTextSize.size2),
          );
          bytes += ticket.text('');

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
            bytes += ticket.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          if (companySettings.add2.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          if (companySettings.add3.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add3,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          if (companySettings.add4.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add4,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          if (companySettings.telephone.toString().trim().isNotEmpty ||
              companySettings.mobile.toString().trim().isNotEmpty) {
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          bytes += ticket.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : companyTaxMode == 'GULF'
                      ? 'TRN : ${ComSettings.getValue('GST-NO', settings)}'
                      : 'TaxNo : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2));
          bytes += ticket.text(invoiceHead,
              styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.hr();
          bytes += ticket.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 12,
                styles: const PosStyles(
                    align: PosAlign.left,
                    bold: true,
                    height: PosTextSize.size2)),
          ]);
          bytes += ticket.row([
            PosColumn(
                text:
                    'Date       : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                width: 12,
                styles: const PosStyles(
                    align: PosAlign.left,
                    bold: true,
                    height: PosTextSize.size2)),
          ]);
          bytes += ticket.hr();
          bytes += ticket.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          //don't use it if (isEsQrCodeKSA) {
          if (dataInformation['gstno'].toString().trim().isNotEmpty) {
            bytes += ticket.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                    : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                styles: const PosStyles(align: PosAlign.left, bold: true));
          }
          // }
          bytes += ticket.hr();
          bytes += ticket.row([
            PosColumn(
                text: 'Description',
                width: 7,
                styles: const PosStyles(bold: true, height: PosTextSize.size2)),
            PosColumn(
                text: 'Qty',
                width: 1,
                styles: const PosStyles(bold: true, height: PosTextSize.size2)),
            PosColumn(
                text: 'Price',
                width: 2,
                styles: const PosStyles(
                    align: PosAlign.right,
                    bold: true,
                    height: PosTextSize.size2)),
            PosColumn(
                text: 'Total',
                width: 2,
                styles: const PosStyles(
                    align: PosAlign.right,
                    bold: true,
                    height: PosTextSize.size2)),
          ]);
          bytes += ticket.hr();
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
            bytes += ticket.row([
              PosColumn(
                  text: itemName,
                  width: 7,
                  styles: const PosStyles(height: PosTextSize.size2)),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + '' + dataParticulars[i]['unitName'] + '' : dataParticulars[i]['Qty']}',
                  width: 1,
                  styles: const PosStyles(height: PosTextSize.size2)),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 2,
                  styles: const PosStyles(
                      align: PosAlign.right, height: PosTextSize.size2)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 2,
                  styles: const PosStyles(
                      align: PosAlign.right, height: PosTextSize.size2)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
            //hsn gst o vat
            // bytes += ticket.hr();
            bytes += ticket.row(companyTaxMode == 'INDIA'
                ? [
                    PosColumn(
                        text: '${dataParticulars[i]['hsncode']}', width: 4),
                    PosColumn(text: '$taxPercentages', width: 4),
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
          bytes += ticket.hr();
          bytes += ticket.row([
            PosColumn(
                text: 'Total ',
                width: 3,
                styles: const PosStyles(height: PosTextSize.size2)),
            PosColumn(
                text: '$totalQty',
                width: 3,
                styles: const PosStyles(
                    align: PosAlign.right, height: PosTextSize.size2)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(
                    align: PosAlign.right, height: PosTextSize.size2)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 3,
                styles: const PosStyles(
                    align: PosAlign.right, height: PosTextSize.size2)),
          ]);
          bytes += ticket.hr();
          // bytes += ticket.row([
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
          // bytes += ticket.hr();
          // bytes += ticket.row([
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
            bytes += ticket.text(
              companySettings.name,
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
                (bytes += ticket.text(companySettings.add1,
                    styles: const PosStyles(align: PosAlign.center)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (bytes += ticket.text(companySettings.add2,
                    styles: const PosStyles(align: PosAlign.center)));
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
            bytes += ticket.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center));
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            bytes += ticket.row([
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
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            bytes += ticket.row([
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
          bytes += ticket.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              bytes += ticket.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left));
            }
          }
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
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
            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
              PosColumn(
                  text: '${otherAmount[i]['LedName']} :',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right, bold: true
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      )),
              PosColumn(
                  text: double.tryParse(otherAmount[i]['Amount'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right, bold: true
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      )),
            ]);
          }
        }
        bytes += ticket.hr();
        bytes += ticket.row([
          PosColumn(
              text: 'Net Amount :',
              width: 6,
              styles: const PosStyles(
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text: double.tryParse(dataInformation['GrandTotal'].toString())
                  .toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                  bold: true)),
        ]);
        bytes += ticket.hr();
        bytes += ticket.text(
            'Amount in Words: ${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
            linesAfter: 1,
            styles: const PosStyles(bold: true));

        if (taxSale) {
          bytes += ticket.hr();
          bytes += companyTaxMode == 'INDIA'
              ? ticket.row([
                  PosColumn(
                      text: 'GST %',
                      width: 3,
                      styles:
                          const PosStyles(align: PosAlign.center, bold: true)),
                  PosColumn(
                      text: 'Taxable',
                      width: 3,
                      styles:
                          const PosStyles(align: PosAlign.center, bold: true)),
                  PosColumn(
                      text: 'CGST Amt',
                      width: 3,
                      styles:
                          const PosStyles(align: PosAlign.center, bold: true)),
                  PosColumn(
                      text: 'SGST Amt',
                      width: 3,
                      styles:
                          const PosStyles(align: PosAlign.center, bold: true)),
                ])
              : ticket.row([
                  PosColumn(
                      text: 'VAT %',
                      width: 4,
                      styles:
                          const PosStyles(align: PosAlign.center, bold: true)),
                  PosColumn(
                      text: 'Taxable',
                      width: 4,
                      styles:
                          const PosStyles(align: PosAlign.center, bold: true)),
                  PosColumn(
                      text: 'Vat Amt',
                      width: 4,
                      styles:
                          const PosStyles(align: PosAlign.center, bold: true)),
                ]);
          bytes += ticket.hr();
          for (var i = 0; i < taxableData.length; i++) {
            bytes += companyTaxMode == 'INDIA'
                ? ticket.row([
                    PosColumn(
                        text: '${taxableData[i]['tax'].toString()} %',
                        width: 3,
                        styles:
                            const PosStyles(align: PosAlign.right, bold: true)),
                    PosColumn(
                        text: '${taxableData[i]['taxable'].toStringAsFixed(2)}',
                        width: 3,
                        styles:
                            const PosStyles(align: PosAlign.right, bold: true)),
                    PosColumn(
                        text: '${taxableData[i]['CGST'].toStringAsFixed(2)}',
                        width: 3,
                        styles:
                            const PosStyles(align: PosAlign.right, bold: true)),
                    PosColumn(
                        text: '${taxableData[i]['SGST'].toStringAsFixed(2)}',
                        width: 3,
                        styles:
                            const PosStyles(align: PosAlign.right, bold: true)),
                  ])
                : ticket.row([
                    PosColumn(
                        text: '${taxableData[i]['tax'].toString()} %',
                        width: 4,
                        styles:
                            const PosStyles(align: PosAlign.right, bold: true)),
                    PosColumn(
                        text: '${taxableData[i]['taxable'].toStringAsFixed(2)}',
                        width: 4,
                        styles:
                            const PosStyles(align: PosAlign.right, bold: true)),
                    PosColumn(
                        text: '${taxableData[i]['IGST'].toStringAsFixed(2)}',
                        width: 4,
                        styles:
                            const PosStyles(align: PosAlign.right, bold: true)),
                  ]);
            bytes += ticket.hr();
          }
        }
        if (Settings.getValue<bool>('key-print-balance', false)) {
          //
        } else {
          bytes += ticket.row([
            PosColumn(
                text: 'CashReceived : ',
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.center, height: PosTextSize.size2)),
            PosColumn(
                text: '${dataInformation['CashReceived']}',
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.center, height: PosTextSize.size2)),
          ]);
          bytes += ticket.row([
            PosColumn(
                text: 'Old Balance : ${dataInformation['Balance']}',
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.center, height: PosTextSize.size2)),
            PosColumn(
                text:
                    'Balance : ${(double.tryParse(dataInformation['Balance'].toString())) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))}',
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.center, height: PosTextSize.size2)),
          ]);
        }

        // ticket.feed(1);
        bytes += ticket.row([
          PosColumn(
              text: '${bill['message']}',
              width: 12,
              styles: const PosStyles(align: PosAlign.center))
        ]);

        if (isQrCodeKSA) {
          // Print QR Code using native function
          // bytes += ticket.qrcode('example.com');
          if (taxSale) {
            bytes += ticket.qrcode(SaudiConversion.getBase64(
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
            bytes += ticket.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          } else if (isEsQrCodeKSA) {
            bytes += ticket.qrcode(SaudiConversion.getBase64(
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
            bytes += ticket.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          }
        } else {
          bytes += ticket.feed(
              ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        }
        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        bytes += ticket.rawBytes([0], isKanji: false);
        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
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
    //         .recordError(e, s, reason: 'bt print:' + ticket.toString());
    //     return ticket;
    //   }
    // }
    // }
  }

  Future<List<int>> salesDefaultData(PaperSize paper) async {
    var profile = await CapabilityProfile.load();
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];
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
          bytes += ticket.text(
            companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              // height: PosTextSize.size2,
              // width: PosTextSize.size2,
            ),
          );
          if (companySettings.add1.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add2.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add3.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add3,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.add4.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add4,
                styles: const PosStyles(align: PosAlign.center));
          }
          if (companySettings.telephone.toString().trim().isNotEmpty ||
              companySettings.mobile.toString().trim().isNotEmpty) {
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
          }
          // bytes += ticket.text(
          //     companyTaxMode == 'INDIA'
          //         ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
          //         : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
          //     styles: const PosStyles(align: PosAlign.center, bold: true));
          bytes += ticket.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.row([
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
          bytes += ticket.text('Bill To : ',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          bytes += ticket.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          //not acceptable if (isEsQrCodeKSA) {
          // if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //   bytes += ticket.text(
          //       companyTaxMode == 'INDIA'
          //           ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //           : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //       styles: const PosStyles(align: PosAlign.left, bold: true));
          // }
          // }
          bytes += ticket.hr();
          bytes += ticket.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          bytes += ticket.row([
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
          // for (var i = 0; i < dataParticulars.length; i++) {
          //   if (double.tryParse(dataParticulars[i]['igst'].toString()) > 0) {
          //     taxPercentages = dataParticulars[i]['igst'].toString() + ' %';
          //     // if (taxPercentages.contains(
          //     //     '@' + dataParticulars[i]['igst'].toString() + ' %')) {
          //   } else {
          //     taxPercentages = '0 %';
          //   }
          //   // }
          //   var itemName = dataParticulars[i]['itemname'].toString();
          //   bytes += ticket.text(itemName,
          //       styles: const PosStyles(align: PosAlign.left, bold: true));

          //   bytes += ticket.row([
          //     PosColumn(text: '', width: 2),
          //     PosColumn(
          //         text:
          //             '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
          //         width: 1),
          //     PosColumn(
          //         text: '${dataParticulars[i]['Rate']}',
          //         width: 2,
          //         styles: const PosStyles(align: PosAlign.right, bold: true)),
          //     PosColumn(
          //         text: '${dataParticulars[i]['Total']}',
          //         width: 2,
          //         styles: const PosStyles(align: PosAlign.right, bold: true)),
          //   ]);
          //   totalQty += dataParticulars[i]['Qty'];
          //   totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
          // }
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          // bytes += ticket.row([
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
            bytes += ticket.text(
              companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            bytes += ticket.text(
              '',
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            companySettings.add1.toString().trim().isNotEmpty ??
                (bytes += ticket.text(companySettings.add1,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (bytes += ticket.text(companySettings.add2,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // bytes += ticket.text(
            //     companyTaxMode == 'INDIA'
            //         ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
            //         : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
            //     styles: const PosStyles(align: PosAlign.center, bold: true));
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            bytes += ticket.hr();
            bytes += ticket.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            bytes += ticket.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          } else {
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            bytes += ticket.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            bytes += ticket.row([
              PosColumn(
                  text:
                      'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          }
          bytes += ticket.hr();

          bytes += ticket.text('Bill To :',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          bytes += ticket.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          // if (isEsQrCodeKSA) {
          //   if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //     bytes += ticket.text(
          //         companyTaxMode == 'INDIA'
          //             ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //             : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //         styles: const PosStyles(align: PosAlign.left, bold: true));
          //   }
          // }
          bytes += ticket.hr();
          bytes += ticket.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          bytes += ticket.row([
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
          bytes += ticket.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            bytes += ticket.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
        // bytes += ticket.hr();
        // bytes += ticket.text(
        //     'Amount in Words: ${NumberToWord().convert('en', double.tryParse(dataInformation['GrandTotal'].toString()).round())}',
        //     linesAfter: 1);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.text('${dataBankLedger['name']}',
              styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.text('ACC NO : ${dataBankLedger['account']}',
              styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.text('IFSC CODE : ${dataBankLedger['ifsc']}',
              styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.text('Branch : ${dataBankLedger['branch']}',
              styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.hr();
        }

        // ticket.feed(1);
        bytes += ticket.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));
        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
      }
    } else {
      try {
        if (taxSale) {
          bytes += ticket.text(
            companySettings.name,
            styles: const PosStyles(
                align: PosAlign.center, bold: true, height: PosTextSize.size2),
          );
          bytes += ticket.text('');

          if (companySettings.add1.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          if (companySettings.add2.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          if (companySettings.add3.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add3,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          if (companySettings.add4.toString().trim().isNotEmpty) {
            bytes += ticket.text(companySettings.add4,
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          if (companySettings.telephone.toString().trim().isNotEmpty ||
              companySettings.mobile.toString().trim().isNotEmpty) {
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
          }
          bytes += ticket.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : companyTaxMode == 'GULF'
                      ? 'TRN : ${ComSettings.getValue('GST-NO', settings)}'
                      : 'TaxNo : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2));
          bytes += ticket.text(invoiceHead,
              styles: const PosStyles(
                  align: PosAlign.center,
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size2));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.hr();
          bytes += ticket.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 12,
                styles: const PosStyles(
                    align: PosAlign.left,
                    bold: true,
                    height: PosTextSize.size2)),
          ]);
          bytes += ticket.row([
            PosColumn(
                text:
                    'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                width: 12,
                styles: const PosStyles(
                    align: PosAlign.left,
                    bold: true,
                    height: PosTextSize.size2)),
          ]);
          bytes += ticket.hr();
          bytes += ticket.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          //don't use it if (isEsQrCodeKSA) {
          // if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //   bytes += ticket.text(
          //       companyTaxMode == 'INDIA'
          //           ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //           : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //       styles: const PosStyles(align: PosAlign.left));
          // }
          // }
          if (dataInformation['gstno'].toString().trim().isNotEmpty) {
            bytes += ticket.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                    : companyTaxMode == 'GULF'
                        ? 'TRN : ${dataInformation['gstno'].toString().trim()}'
                        : 'TaxNo : ${dataInformation['gstno'].toString().trim()}',
                styles: const PosStyles(align: PosAlign.left, bold: true));
          }
          bytes += ticket.hr();
          bytes += ticket.row([
            PosColumn(
                text: 'Description',
                width: 6,
                styles: const PosStyles(bold: true, height: PosTextSize.size2)),
            PosColumn(
                text: 'Qty',
                width: 1,
                styles: const PosStyles(bold: true, height: PosTextSize.size2)),
            PosColumn(
                text: 'Price',
                width: 2,
                styles: const PosStyles(bold: true, height: PosTextSize.size2)),
            PosColumn(
                text: 'Disc',
                width: 1,
                styles: const PosStyles(bold: true, height: PosTextSize.size2)),
            PosColumn(
                text: 'Total',
                width: 2,
                styles: const PosStyles(bold: true, height: PosTextSize.size2)),
          ]);
          bytes += ticket.hr();
          double totalQty = 0, totalRate = 0, totalDisc = 0;
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
            bytes += ticket.row([
              PosColumn(
                  text: itemName,
                  width: 6,
                  styles: const PosStyles(height: PosTextSize.size2)),
              PosColumn(
                  text:
                      '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + '' + dataParticulars[i]['unitName'] + '' : dataParticulars[i]['Qty']}',
                  width: 1,
                  styles: const PosStyles(height: PosTextSize.size2)),
              PosColumn(
                  text: '${dataParticulars[i]['Rate']}',
                  width: 2,
                  styles: const PosStyles(
                      align: PosAlign.right, height: PosTextSize.size2)),
              PosColumn(
                  text: '${dataParticulars[i]['Disc']}',
                  width: 1,
                  styles: const PosStyles(
                      align: PosAlign.right, height: PosTextSize.size2)),
              PosColumn(
                  text: '${dataParticulars[i]['Total']}',
                  width: 2,
                  styles: const PosStyles(
                      align: PosAlign.right, height: PosTextSize.size2)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
            totalDisc += double.tryParse(dataParticulars[i]['Disc'].toString());
          }
          bytes += ticket.hr();
          bytes += ticket.row([
            PosColumn(
                text: 'Total ',
                width: 3,
                styles: const PosStyles(height: PosTextSize.size2)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(
                    align: PosAlign.right, height: PosTextSize.size2)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 2,
                styles: const PosStyles(
                    align: PosAlign.right, height: PosTextSize.size2)),
            PosColumn(
                text: totalDisc.toStringAsFixed(2),
                width: 2,
                styles: const PosStyles(
                    align: PosAlign.right, height: PosTextSize.size2)),
            PosColumn(
                text: '${dataInformation['Total']}',
                width: 3,
                styles: const PosStyles(
                    align: PosAlign.right, height: PosTextSize.size2)),
          ]);
          bytes += ticket.hr();
        } else {
          if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
            bytes += ticket.text(
              companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            companySettings.add1.toString().trim().isNotEmpty ??
                (bytes += ticket.text(companySettings.add1,
                    styles: const PosStyles(align: PosAlign.center)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (bytes += ticket.text(companySettings.add2,
                    styles: const PosStyles(align: PosAlign.center)));
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));

            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            bytes += ticket.row([
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
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            bytes += ticket.row([
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
          bytes += ticket.text('Bill To : ${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left));

          if (isEsQrCodeKSA) {
            if (dataInformation['gstno'].toString().trim().isNotEmpty) {
              bytes += ticket.text(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                      : 'TRN : ${dataInformation['gstno'].toString().trim()}',
                  styles: const PosStyles(align: PosAlign.left));
            }
          }
          bytes += ticket.hr();
          bytes += ticket.row([
            PosColumn(text: 'Description', width: 6),
            PosColumn(text: 'Qty', width: 1),
            PosColumn(
                text: 'Price',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Disc',
                width: 1,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: 'Total',
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          bytes += ticket.hr();
          double totalQty = 0, totalRate = 0, totalDisc = 0;
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
            bytes += ticket.row([
              PosColumn(text: itemName, width: 6),
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
                  text: double.tryParse(dataParticulars[i]['Disc'].toString())
                      .toStringAsFixed(2),
                  width: 1,
                  styles: const PosStyles(
                      align: PosAlign.right, height: PosTextSize.size2)),
              PosColumn(
                  text: double.tryParse(dataParticulars[i]['Total'].toString())
                      .toStringAsFixed(2),
                  width: 2,
                  styles: const PosStyles(align: PosAlign.right)),
            ]);
            totalQty += dataParticulars[i]['Qty'];
            totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
            totalDisc += double.tryParse(dataParticulars[i]['Disc'].toString());
          }
          bytes += ticket.hr();
          bytes += ticket.row([
            PosColumn(
                text: 'Sub =',
                width: 3,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: '$totalQty',
                width: 2,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: totalRate.toStringAsFixed(2),
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: totalDisc.toStringAsFixed(2),
                width: 2,
                styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
                text: double.tryParse(dataInformation['Total'].toString())
                    .toStringAsFixed(2),
                width: 3,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
              PosColumn(
                  text: '${otherAmount[i]['LedName']} :',
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right, bold: true
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      )),
              PosColumn(
                  text: double.tryParse(otherAmount[i]['Amount'].toString())
                      .toStringAsFixed(2),
                  width: 6,
                  styles: const PosStyles(align: PosAlign.right, bold: true
                      // height: PosTextSize.size2,
                      // width: PosTextSize.size2,
                      )),
            ]);
          }
        }
        bytes += ticket.hr();
        bytes += ticket.row([
          PosColumn(
              text: 'Net Amount :',
              width: 6,
              styles: const PosStyles(
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                  bold: true,
                  align: PosAlign.right)),
          PosColumn(
              text: double.tryParse(dataInformation['GrandTotal'].toString())
                  .toStringAsFixed(2),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right,
                  height: PosTextSize.size2,
                  // width: PosTextSize.size2,
                  bold: true)),
        ]);
        bytes += ticket.hr();
        bytes += ticket.text(
            'Amount in Words: ${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
            linesAfter: 1,
            styles: const PosStyles(bold: true));

        if (Settings.getValue<bool>('key-print-balance', false)) {
          //
        } else {
          bytes += ticket.row([
            PosColumn(
                text: 'CashReceived : ',
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.center, height: PosTextSize.size2)),
            PosColumn(
                text: '${dataInformation['CashReceived']}',
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.center, height: PosTextSize.size2)),
          ]);
          bytes += ticket.row([
            PosColumn(
                text: 'Old Balance : ${dataInformation['Balance']}',
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.center, height: PosTextSize.size2)),
            PosColumn(
                text:
                    'Balance : ${(double.tryParse(dataInformation['Balance'].toString())) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))}',
                width: 6,
                styles: const PosStyles(
                    align: PosAlign.center, height: PosTextSize.size2)),
          ]);
        }
        if (Settings.getValue<bool>('key-print-bank-details', false)) {
          bytes += ticket.hr();
          bytes += ticket.text('${dataBankLedger['name']}',
              styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.text('ACC NO : ${dataBankLedger['account']}',
              styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.text('IFSC CODE : ${dataBankLedger['ifsc']}',
              styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.text('Branch : ${dataBankLedger['branch']}',
              styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.hr();
        }

        // ticket.feed(1);
        bytes += ticket.row([
          PosColumn(
              text: '${bill['message']}',
              width: 12,
              styles: const PosStyles(align: PosAlign.center))
        ]);

        if (isQrCodeKSA) {
          // Print QR Code using native function
          // bytes += ticket.qrcode('example.com');
          if (taxSale) {
            bytes += ticket.qrcode(SaudiConversion.getBase64(
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
            bytes += ticket.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          } else if (isEsQrCodeKSA) {
            bytes += ticket.qrcode(SaudiConversion.getBase64(
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
            bytes += ticket.feed(
                ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
          }
        } else {
          bytes += ticket.feed(
              ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        }

        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
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

  Future<List<int>> salesReturnData(PaperSize paper) async {
    var profile = await CapabilityProfile.load();
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];
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
          bytes += ticket.text(
            companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              // height: PosTextSize.size2,
              // width: PosTextSize.size2,
            ),
          );
          var text2 = ticket.text(companySettings.add1,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          companySettings.add1.toString().trim().isNotEmpty ?? (bytes += text2);
          var text3 = ticket.text(companySettings.add2,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          companySettings.add2.toString().trim().isNotEmpty ?? (bytes += text3);
          bytes += ticket.text(
              'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          bytes += ticket.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center, bold: true));
          bytes += ticket.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 6,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: 'Date : ${DateUtil.dateDMY(dataInformation['DDate'])}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          bytes += ticket.text('Bill To : ',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          bytes += ticket.text('${dataInformation['Toname']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          // if (isEsQrCodeKSA) {
          //   if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //     bytes += ticket.text(
          //         companyTaxMode == 'INDIA'
          //             ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //             : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //         styles: const PosStyles(align: PosAlign.left, bold: true));
          //   }
          // }
          bytes += ticket.hr();
          bytes += ticket.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));
          bytes += ticket.row([
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
            bytes += ticket.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.text(
              companySettings.name,
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                // height: PosTextSize.size2,
                // width: PosTextSize.size2,
              ),
            );
            bytes += ticket.text(
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
                (bytes += ticket.text(companySettings.add1,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (bytes += ticket.text(companySettings.add2,
                    styles:
                        const PosStyles(align: PosAlign.center, bold: true)));
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            bytes += ticket.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center, bold: true));
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            bytes += ticket.hr();
            bytes += ticket.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            bytes += ticket.row([
              PosColumn(
                  text: 'Date : ${DateUtil.dateDMY(dataInformation['DDate'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          } else {
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            bytes += ticket.row([
              PosColumn(
                  text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
            bytes += ticket.row([
              PosColumn(
                  text: 'Date : ${DateUtil.dateDMY(dataInformation['DDate'])}',
                  width: 12,
                  styles: const PosStyles(align: PosAlign.left, bold: true)),
            ]);
          }
          bytes += ticket.hr();

          bytes += ticket.text('Bill To :',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          bytes += ticket.text('${dataInformation['ToName']}',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          // if (isEsQrCodeKSA) {
          //   if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //     bytes += ticket.text(
          //         companyTaxMode == 'INDIA'
          //             ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //             : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //         styles: const PosStyles(align: PosAlign.left, bold: true));
          //   }
          // }
          bytes += ticket.hr();
          bytes += ticket.text('Description',
              styles: const PosStyles(align: PosAlign.left, bold: true));

          bytes += ticket.row([
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
          bytes += ticket.hr();
          double totalQty = 0, totalRate = 0;
          for (var i = 0; i < dataParticulars.length; i++) {
            var itemName = dataParticulars[i]['itemname'].toString();
            bytes += ticket.text(itemName,
                styles: const PosStyles(align: PosAlign.left, bold: true));

            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
        //     bytes += ticket.hr();
        //     bytes += ticket.row([
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
        // bytes += ticket.hr();
        // bytes += ticket.text(
        //     'Amount in Words: ${NumberToWord().convert('en', double.tryParse(dataInformation['GrandTotal'].toString()).round())}',
        //     linesAfter: 1);
        if (Settings.getValue<bool>('key-print-balance', false)) {
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
            bytes += ticket.hr();
            // bytes += ticket.row([
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
            bytes += ticket.hr();
            bytes += ticket.row([
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
        bytes += ticket.text('Have a nice day',
            styles: const PosStyles(align: PosAlign.center));

        // if (isQrCodeKSA) {
        //   // Print QR Code using native function
        //   // bytes += ticket.qrcode('example.com');
        //   if (taxSale) {
        //     bytes += ticket.qrcode(SaudiConversion.getBase64(
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
        //     bytes += ticket.feed(
        //         ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        //   } else if (isEsQrCodeKSA) {
        //     bytes += ticket.qrcode(SaudiConversion.getBase64(
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
        //     bytes += ticket.feed(
        //         ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        //   }
        // } else {
        //   bytes += ticket.feed(
        //       ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        // }
        // ticket.cut();
        // FirebaseCrashlytics.instance
        //     .setCustomKey('str_key', 'bt print complited');
        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
      }
    } else {
      try {
        if (taxSale) {
          bytes += ticket.text(
            companySettings.name,
            styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              // height: PosTextSize.size2,
              // width: PosTextSize.size2,
            ),
          );
          bytes += ticket.text('');

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
          var text2 = ticket.text(companySettings.add1,
              styles: const PosStyles(align: PosAlign.center));
          companySettings.add1.toString().trim().isNotEmpty ?? (bytes += text2);
          var text3 = ticket.text(companySettings.add2,
              styles: const PosStyles(align: PosAlign.center));
          companySettings.add2.toString().trim().isNotEmpty ?? (bytes += text3);
          bytes += ticket.text(
              'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
              styles: const PosStyles(align: PosAlign.center));
          bytes += ticket.text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
              styles: const PosStyles(align: PosAlign.center));
          bytes += ticket.text(invoiceHead,
              styles: const PosStyles(align: PosAlign.center, bold: true));
          // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
          //     styles: const PosStyles(align: PosAlign.left));
          bytes += ticket.hr();
          bytes += ticket.row([
            PosColumn(
                text: 'Invoice No : ${dataInformation['InvoiceNo']}',
                width: 12,
                styles: const PosStyles(align: PosAlign.left)),
          ]);
          bytes += ticket.row([
            PosColumn(
                text: 'Date : ${DateUtil.dateDMY(dataInformation['DDate'])}',
                width: 12,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          bytes += ticket.hr();
          bytes += ticket.text('Bill To : ${dataInformation['Toname']}',
              styles: const PosStyles(align: PosAlign.left));
          // if (isEsQrCodeKSA) {
          //   if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //     bytes += ticket.text(
          //         companyTaxMode == 'INDIA'
          //             ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //             : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //         styles: const PosStyles(align: PosAlign.left));
          //   }
          // }
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
            bytes += ticket.text(
              companySettings.name,
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
                (bytes += ticket.text(companySettings.add1,
                    styles: const PosStyles(align: PosAlign.center)));
            companySettings.add2.toString().trim().isNotEmpty ??
                (bytes += ticket.text(companySettings.add2,
                    styles: const PosStyles(align: PosAlign.center)));
            bytes += ticket.text(
                'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                styles: const PosStyles(align: PosAlign.center));
            bytes += ticket.text(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                styles: const PosStyles(align: PosAlign.center));
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));
            bytes += ticket.row([
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
            bytes += ticket.text(invoiceHead,
                styles: const PosStyles(align: PosAlign.center, bold: true));
            // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
            //     styles: const PosStyles(align: PosAlign.left));DateUtil.dateDMY
            bytes += ticket.row([
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
          bytes += ticket.text('Bill To : ${dataInformation['Toname']}',
              styles: const PosStyles(align: PosAlign.left));

          // if (isEsQrCodeKSA) {
          //   if (dataInformation['gstno'].toString().trim().isNotEmpty) {
          //     bytes += ticket.text(
          //         companyTaxMode == 'INDIA'
          //             ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
          //             : 'TRN : ${dataInformation['gstno'].toString().trim()}',
          //         styles: const PosStyles(align: PosAlign.left));
          //   }
          // }
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
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
            bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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
          bytes += ticket.hr();
          bytes += ticket.row([
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

        bytes += ticket.hr();
        bytes += ticket.row([
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
        bytes += ticket.hr();
        bytes += ticket.text(
            'Amount in Words: ${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
            linesAfter: 1);

        // ticket.feed(1);
        bytes += ticket.text('Have a nice day',
            styles: const PosStyles(align: PosAlign.center));

        // if (isQrCodeKSA) {
        //   // Print QR Code using native function
        //   // bytes += ticket.qrcode('example.com');
        //   if (taxSale) {
        //     bytes += ticket.qrcode(SaudiConversion.getBase64(
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
        //     bytes += ticket.feed(
        //         ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        //   } else if (isEsQrCodeKSA) {
        //     bytes += ticket.qrcode(SaudiConversion.getBase64(
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
        //     bytes += ticket.feed(
        //         ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        //   }
        // } else {
        bytes += ticket
            .feed(ComSettings.appSettings('int', 'key-dropdown-print-line', 1));
        // }

        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
      }
    }
  }

  Future<List<int>> receiptData(PaperSize paper) async {
    var profile = await CapabilityProfile.load();
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];
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
        bytes += ticket.text(
          companySettings.name,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        bytes += ticket.text(
          '',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        companySettings.add1.toString().trim().isNotEmpty ??
            (bytes += ticket.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        companySettings.add2.toString().trim().isNotEmpty ??
            (bytes += ticket.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        bytes += ticket.text(
            'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += ticket.text(
            companyTaxMode == 'INDIA'
                ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                : companyTaxMode == 'GULF'
                    ? 'TRN : ${ComSettings.getValue('GST-NO', settings)}'
                    : 'TAX No : ${ComSettings.getValue('GST-NO', settings)}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += ticket.text(invoiceHead,
            styles: const PosStyles(align: PosAlign.center, bold: true));
        // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
        //     styles: const PosStyles(align: PosAlign.left));
        bytes += ticket.hr();
        bytes += ticket.row([
          PosColumn(
              text: 'Invoice No : ${bill['entryNo']}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        bytes += ticket.row([
          PosColumn(
              text: 'Date : ${DateUtil.dateDMY(bill['date'])}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        bytes += ticket.text('From : ',
            styles: const PosStyles(align: PosAlign.left, bold: true));
        bytes += ticket.text('${bill['name']}',
            styles: const PosStyles(align: PosAlign.left, bold: true));

        bytes += ticket.row([
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
        bytes += ticket.row([
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
          bytes += ticket.row([
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
            bytes += ticket.row([
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
            bytes += ticket.row([
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
            bytes += ticket.text(
              '',
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
              ),
            );
            double balance =
                oldBalance - double.tryParse(bill['total'].toString());
            bytes += ticket.row([
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
            bytes += ticket.row([
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
        bytes += ticket.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
      }
    } else {
      try {
        bytes += ticket.text(
          companySettings.name,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        bytes += ticket.text(
          '',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        companySettings.add1.toString().trim().isNotEmpty ??
            (bytes += ticket.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        companySettings.add2.toString().trim().isNotEmpty ??
            (bytes += ticket.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        bytes += ticket.text(
            'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += ticket.text(
            companyTaxMode == 'INDIA'
                ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += ticket.text(invoiceHead,
            styles: const PosStyles(align: PosAlign.center, bold: true));
        // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
        //     styles: const PosStyles(align: PosAlign.left));
        bytes += ticket.hr();
        bytes += ticket.row([
          PosColumn(
              text: 'Invoice No : ${bill['entryNo']}',
              width: 6,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Date : ${DateUtil.dateDMY(bill['date'])}',
              width: 6,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        bytes += ticket.row([
          PosColumn(
              text: 'From : ${bill['name']}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        bytes += ticket.row([
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
        bytes += ticket.row([
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
          bytes += ticket.row([
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
            bytes += ticket.row([
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
            bytes += ticket.row([
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
            bytes += ticket.text(
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
            bytes += ticket.row([
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
            bytes += ticket.row([
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
        bytes += ticket.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
      }
    }
  }

  Future<List<int>> paymentData(PaperSize paper) async {
    var profile = await CapabilityProfile.load();
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];
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
        bytes += ticket.text(
          companySettings.name,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        bytes += ticket.text(
          '',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        companySettings.add1.toString().trim().isNotEmpty ??
            (bytes += ticket.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        companySettings.add2.toString().trim().isNotEmpty ??
            (bytes += ticket.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        bytes += ticket.text(
            'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += ticket.text(
            companyTaxMode == 'INDIA'
                ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += ticket.text(invoiceHead,
            styles: const PosStyles(align: PosAlign.center, bold: true));
        // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
        //     styles: const PosStyles(align: PosAlign.left));
        bytes += ticket.hr();
        bytes += ticket.row([
          PosColumn(
              text: 'Invoice No : ${bill['entryNo']}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        bytes += ticket.row([
          PosColumn(
              text: 'Date : ${DateUtil.dateDMY(bill['date'])}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        bytes += ticket.text('From : ',
            styles: const PosStyles(align: PosAlign.left, bold: true));
        bytes += ticket.text('${bill['name']}',
            styles: const PosStyles(align: PosAlign.left, bold: true));

        bytes += ticket.row([
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
        bytes += ticket.row([
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
          bytes += ticket.row([
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
            bytes += ticket.row([
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
            bytes += ticket.row([
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
            bytes += ticket.text(
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
            bytes += ticket.row([
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
            bytes += ticket.row([
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
        bytes += ticket.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
      }
    } else {
      try {
        bytes += ticket.text(
          companySettings.name,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        bytes += ticket.text(
          '',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        );
        companySettings.add1.toString().trim().isNotEmpty ??
            (bytes += ticket.text(companySettings.add1,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        companySettings.add2.toString().trim().isNotEmpty ??
            (bytes += ticket.text(companySettings.add2,
                styles: const PosStyles(align: PosAlign.center, bold: true)));
        bytes += ticket.text(
            'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += ticket.text(
            companyTaxMode == 'INDIA'
                ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
            styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += ticket.text(invoiceHead,
            styles: const PosStyles(align: PosAlign.center, bold: true));
        // ticket.text('Invoice No : ${dataInformation['InvoiceNo']}',
        //     styles: const PosStyles(align: PosAlign.left));
        bytes += ticket.hr();
        bytes += ticket.row([
          PosColumn(
              text: 'Invoice No : ${bill['entryNo']}',
              width: 6,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
          PosColumn(
              text: 'Date : ${DateUtil.dateDMY(bill['date'])}',
              width: 6,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        bytes += ticket.row([
          PosColumn(
              text: 'From : ${bill['name']}',
              width: 12,
              styles: const PosStyles(align: PosAlign.left, bold: true)),
        ]);
        bytes += ticket.row([
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
        bytes += ticket.row([
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
          bytes += ticket.row([
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
            bytes += ticket.row([
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
            bytes += ticket.row([
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
            bytes += ticket.text(
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
            bytes += ticket.row([
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
            bytes += ticket.row([
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
        bytes += ticket.text('${bill['message']}',
            styles: const PosStyles(align: PosAlign.center));

        bytes += ticket.feed(2);
        return bytes;
      } catch (e, s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'bt print:' + ticket.toString());
        bytes += ticket.feed(2);
        return bytes;
      }
    }
  }

  Future<List<int>> testData(PaperSize paper) async {
    var profile = await CapabilityProfile.load();
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];
    try {
      bytes += ticket.text(
        'Form with no Data',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          // height: PosTextSize.size2,
          // width: PosTextSize.size2,
        ),
      );
      bytes += ticket.text(
        'This is not a model',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          // height: PosTextSize.size2,
          // width: PosTextSize.size2,
        ),
      );
      bytes += ticket.feed(2);
      bytes += ticket.cut();
      return bytes;
    } catch (e, s) {
      FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'bt print:' + ticket.toString());
      bytes += ticket.feed(2);
      return bytes;
    }
  }

  @override
  void dispose() {
    printerManager.stopScan();
    // TODO: implement dispose
    super.dispose();
  }

  String defaultPrinter = '';
  void initDefaultData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    defaultPrinter = pref.getString('defaultPrinter') ?? '';
  }

  void setDefaultPrinter() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString('defaultPrinter', defaultPrinter);
  }

  void printDefault() {
    if (mounted) {
      if (defaultPrinter.isNotEmpty) {
        PrinterBluetooth device =
            _devices.firstWhere((element) => element.name == defaultPrinter);

        _setPrinter(device);
      }
    }
  }
}
