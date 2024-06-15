// @dart = 2.11
import 'dart:io';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/number_to_word.dart';
import '../util/dateUtil.dart';
import 'printerenum.dart' as Enu;
import 'package:flutter/services.dart';

class BlueThermalPrint extends StatefulWidget {
  final data;
  final Uint8List byteImage;

  const BlueThermalPrint(this.data, this.byteImage, {Key key})
      : super(key: key);

  @override
  State<BlueThermalPrint> createState() => _BlueThermalPrintState();
}

class _BlueThermalPrintState extends State<BlueThermalPrint> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice _device;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    bool isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      debugPrint('error....');
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
            debugPrint("bluetooth device state: connected");
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            debugPrint("bluetooth device state: disconnected");
          });
          break;
        case BlueThermalPrinter.DISCONNECT_REQUESTED:
          setState(() {
            _connected = false;
            debugPrint("bluetooth device state: disconnect requested");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_OFF:
          setState(() {
            _connected = false;
            debugPrint("bluetooth device state: bluetooth turning off");
          });
          break;
        case BlueThermalPrinter.STATE_OFF:
          setState(() {
            _connected = false;
            debugPrint("bluetooth device state: bluetooth off");
          });
          break;
        case BlueThermalPrinter.STATE_ON:
          setState(() {
            _connected = false;
            debugPrint("bluetooth device state: bluetooth on");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_ON:
          setState(() {
            _connected = false;
            debugPrint("bluetooth device state: bluetooth turning on");
          });
          break;
        case BlueThermalPrinter.ERROR:
          setState(() {
            _connected = false;
            debugPrint("bluetooth device state: error");
          });
          break;
        default:
          debugPrint(state.toString());
          break;
      }
    });

    if (!mounted) return;
    setState(() {
      _devices = devices;
    });

    if (isConnected == true) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Thermal Printer'),
        ),
        body: ListView.builder(
            itemCount: _devices.length,
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                onTap: () {
                  _device = _devices[index];
                  _connected ? printData(widget.data) : _connect();
                },
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
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.refresh),
          onPressed: () {
            initPlatformState();
          },
        ),
        // body: Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: ListView(
        //     children: <Widget>[
        //       Row(
        //         crossAxisAlignment: CrossAxisAlignment.center,
        //         mainAxisAlignment: MainAxisAlignment.start,
        //         children: <Widget>[
        //           const SizedBox(width: 10),
        //           const Text(
        //             'Device:',
        //             style: TextStyle(
        //               fontWeight: FontWeight.bold,
        //             ),
        //           ),
        //           const SizedBox(width: 30),
        //           Expanded(
        //             child: DropdownButton(
        //               items: _getDeviceItems(),
        //               onChanged: (BluetoothDevice value) =>
        //                   setState(() => _device = value),
        //               value: _device,
        //             ),
        //           ),
        //         ],
        //       ),
        //       const SizedBox(height: 10),
        //       Row(
        //         crossAxisAlignment: CrossAxisAlignment.center,
        //         mainAxisAlignment: MainAxisAlignment.end,
        //         children: <Widget>[
        //           ElevatedButton(
        //             style:
        //                 ElevatedButton.styleFrom(backgroundColor: Colors.brown),
        //             onPressed: () {
        //               initPlatformState();
        //             },
        //             child: const Text(
        //               'Refresh',
        //               style: TextStyle(color: Colors.white),
        //             ),
        //           ),
        //           const SizedBox(width: 20),
        //           ElevatedButton(
        //             style: ElevatedButton.styleFrom(
        //                 backgroundColor:
        //                     _connected ? Colors.red : Colors.green),
        //             onPressed: _connected ? _disconnect : _connect,
        //             child: Text(
        //               _connected ? 'Disconnect' : 'Connect',
        //               style: const TextStyle(color: Colors.white),
        //             ),
        //           ),
        //         ],
        //       ),
        //       Padding(
        //         padding:
        //             const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
        //         child: ElevatedButton(
        //           style:
        //               ElevatedButton.styleFrom(backgroundColor: Colors.brown),
        //           onPressed: () async {
        //             printData(widget.data);
        //           },
        //           child: const Text('PRINT',
        //               style: TextStyle(color: Colors.white)),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }

  // List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
  //   List<DropdownMenuItem<BluetoothDevice>> items = [];
  //   if (_devices.isEmpty) {
  //     items.add(const DropdownMenuItem(
  //       child: Text('NONE'),
  //     ));
  //   } else {
  //     _devices.forEach((device) {
  //       items.add(DropdownMenuItem(
  //         child: Text(device.name ?? ""),
  //         value: device,
  //       ));
  //     });
  //   }
  //   return items;
  // }

  void _connect() {
    if (_device != null) {
      bluetooth.isConnected.then((isConnected) {
        if (isConnected == false) {
          bluetooth.connect(_device).catchError((error) {
            setState(() => _connected = false);
          }).whenComplete(() => printData(widget.data));
          setState(() {
            _connected = true;
            // Future.delayed(const Duration(seconds: 1)).then((value) {
            //   printData(widget.data);
            // });
          });
        }
      });
    } else {
      show('No device selected.');
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    // setState(() => _connected = false);
  }

  @override
  void dispose() {
    _disconnect();
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
        _device =
            _devices.firstWhere((element) => element.name == defaultPrinter);
        printData(widget.data);
      }
    }
  }

  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: duration,
      ),
    );
  }

  printData(var data) async {
    var bill = data[2];
    var printerSize = data[3];
    CompanyInformation companySettings = data[0];
    List<CompanySettings> settings = data[1];
    if (widget.data[4] == 'SALE') {
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
              ? Settings.getValue<String>(
                  'key-sales-quotation-head', 'QUOTATION')
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
      int printerLines = Settings.getValue<int>('key-dropdown-print-line', 0);
      bool isLogo = ComSettings.appSettings('bool', 'key-print-logo', false);
      //image max 300px X 300px
      printerLines = printerLines * 10;
      String printerLine = "-";
      for (int k = 0; k <= printerLines; k++) {
        printerLine = printerLine + "-";
      }

      //image from File path
      File file;
      if (isLogo) {
        String dir = (await getApplicationDocumentsDirectory()).path;
        file = File('$dir/logo.png');
      }

      bluetooth.isConnected.then((isConnected) {
        if (isConnected == true) {
          String line = "0";
          try {
            if (printerModel == 5) {
              if (isLogo) {
                bluetooth.printNewLine();
                if (file != null) {
                  bluetooth.printImage(file.path); //path of your image/logo
                }
                bluetooth.printNewLine();
              }
              bluetooth.printNewLine();
              bluetooth.printCustom(companySettings.name,
                  Enu.Size.boldLarge.val, Enu.Align.center.val);
              bluetooth.printNewLine();
              line = "1";
              if (companySettings.add1.toString().trim().isNotEmpty) {
                bluetooth.printCustom(companySettings.add1.toString().trim(),
                    Enu.Size.bold.val, Enu.Align.center.val);
              }
              if (companySettings.add2.toString().trim().isNotEmpty) {
                bluetooth.printCustom(companySettings.add2.toString().trim(),
                    Enu.Size.bold.val, Enu.Align.center.val);
              }
              bluetooth.printCustom(
                  'Phone No: ${companySettings.telephone + ',' + companySettings.mobile}',
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "2";
              bluetooth.printCustom(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO: ${ComSettings.getValue('GST-NO', settings)}'
                      : 'TRN NO: ${ComSettings.getValue('GST-NO', settings)}',
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "3";
              bluetooth.printCustom(
                  invoiceHead, Enu.Size.boldMedium.val, Enu.Align.center.val);
              // bluetooth.printLeftRight("LEFT", "RIGHT", Size.medium.val);
              // bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
              line = "4";
              bluetooth.printCustom(
                  'Voucher No:${dataInformation['InvoiceNo']}',
                  Enu.Size.bold.val,
                  Enu.Align.left.val);
              // bluetooth.print4Column("Voucher No:",'${dataInformation['InvoiceNo']}',"","", Enu.Size.bold.val,format: "%-20s %20s %20s %20s %n");
              // bluetooth.printLeftRight('Voucher No:${dataInformation['InvoiceNo']}',
              //     "", Enu.Size.bold.val);
              // bluetooth.printNewLine();
              line = "5";
              bluetooth.printCustom(
                  'Ordering Date:${DateUtil.dateDMY(dataInformation['DDate'])}',
                  Enu.Size.bold.val,
                  Enu.Align.left.val);
              line = "6";
              var bal = double.tryParse(dataInformation['Balance'].toString()) +
                  (double.tryParse(dataInformation['GrandTotal'].toString()) -
                      double.tryParse(
                          dataInformation['CashReceived'].toString()));
              // bluetooth.printLeftRight(
              //   'Party Name:${dataInformation['ToName']}',
              //   'Party Balance:${bal.toStringAsFixed(2)}',
              //   Enu.Size.bold.val,
              // );
              bluetooth.print4Column(
                  'Party Name:${dataInformation['ToName']}',
                  '',
                  "",
                  'Party Balance:${bal.toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-20s %5s %5s %20s %n");
              line = "7";
              // bluetooth.printLeftRight(
              //     companyTaxMode == 'INDIA'
              //         ? 'GSTNO:${dataInformation['gstno'].toString().trim()}'
              //         : 'Party TRNNO:${dataInformation['gstno'].toString().trim()}',
              //     "",
              //     Enu.Size.bold.val);
              bluetooth.printCustom(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO:${dataInformation['gstno'].toString().trim()}'
                      : 'Party TRNNO:${dataInformation['gstno'].toString().trim()}',
                  Enu.Size.bold.val,
                  Enu.Align.left.val);
              line = "8";
              // bluetooth.printNewLine();
              bluetooth.printCustom(
                  '----------------------------------------------------------',
                  Enu.Size.medium.val,
                  Enu.Align.center.val);
              line = "9";
              bluetooth.print7Column("Slno", "Item Des", "Qty(UOM)", "Rate",
                  "Taxable", "Tax amt", "Net Amt", Enu.Size.bold.val,
                  format: "%2s %-20s %7s %7s %6s %7s %7s %n");
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              line = "10";
              for (var i = 0; i < dataParticulars.length; i++) {
                var itemName = dataParticulars[i]['itemname'].toString();
                bluetooth.print7Column(
                    '${i + 1}', itemName, "", "", "", "", "", Enu.Size.bold.val,
                    format: "%2s %-24s %7s %7s %6s %7s %7s %n");
                bluetooth.print7Column(
                    "",
                    "",
                    '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                    '${dataParticulars[i]['Rate']}',
                    '${dataParticulars[i]['RealRate']}',
                    '${dataParticulars[i]['IGST']}',
                    '${dataParticulars[i]['Total']}',
                    Enu.Size.bold.val,
                    format: "%2s %-25s %7s %7s %6s %7s %7s %n");
              }
              line = "11";
              // bluetooth.printNewLine();
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              bluetooth.printCustom(
                  'Gross Total:${dataInformation['NetAmount']}',
                  Enu.Size.bold.val,
                  Enu.Align.right.val);
              line = "12";
              bluetooth.printCustom(
                  'VAT:' +
                      (double.tryParse(dataInformation['CGST'].toString()) +
                              double.tryParse(
                                  dataInformation['SGST'].toString()) +
                              double.tryParse(
                                  dataInformation['IGST'].toString()))
                          .toStringAsFixed(2),
                  Enu.Size.bold.val,
                  Enu.Align.right.val);
              line = "13";
              for (var i = 0; i < otherAmount.length; i++) {
                if (otherAmount[i]['Amount'].toDouble() > 0) {
                  bluetooth.printCustom(
                      '${otherAmount[i]['LedName']} :${double.tryParse(otherAmount[i]['Amount'].toString()).toStringAsFixed(2)}',
                      Enu.Size.bold.val,
                      Enu.Align.right.val);
                }
              }
              line = "14";
              bluetooth.printCustom(
                  'NET TOTAL:${dataInformation['GrandTotal']}',
                  Enu.Size.bold.val,
                  Enu.Align.right.val);
              // bluetooth.printNewLine();
              line = "15";
              bluetooth.printCustom('${bill['message']}', Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "16";
              bluetooth.printNewLine();
              // bluetooth.printQRcode(
              //     "Insert Your Own Text to Generate", 200, 200, Align.center.val);
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              // bluetooth
              //     .paperCut(); //some printer not supported (sometime making image not centered)
              //bluetooth.drawerPin2(); // or you can use bluetooth.drawerPin5();
              // }else{}
            } else if (printerModel == 7) {
              if (isLogo) {
                bluetooth.printNewLine();
                if (file != null) {
                  bluetooth.printImage(file.path); //path of your image/logo
                }
                bluetooth.printNewLine();
              }
              bluetooth.printNewLine();
              bluetooth.printCustom(companySettings.name,
                  Enu.Size.extraLarge.val, Enu.Align.center.val);
              bluetooth.printNewLine();
              line = "1";
              if (companySettings.add1.toString().trim().isNotEmpty) {
                bluetooth.printCustom(companySettings.add1.toString().trim(),
                    Enu.Size.bold.val, Enu.Align.center.val);
              }
              bluetooth.printCustom(
                  'Mob: ${companySettings.mobile} ${companySettings.telephone}',
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "2";
              bluetooth.printCustom(
                  'TRN: ${ComSettings.getValue('GST-NO', settings)}',
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
              bluetooth.printCustom('E-Mail: ${companySettings.email}',
                  Enu.Size.bold.val, Enu.Align.center.val);
              line = "2A";
              bluetooth.printNewLine();
              line = "3";
              bluetooth.printCustom(
                  invoiceHead, Enu.Size.boldMedium.val, Enu.Align.center.val);
              line = "4";
              bluetooth.printNewLine();
              bluetooth.printCustom(
                  'Customer Name:${dataInformation['ToName']}',
                  Enu.Size.bold.val,
                  Enu.Align.left.val);
              bluetooth.printCustom(
                  'Voucher No   :${dataInformation['InvoiceNo']}',
                  Enu.Size.bold.val,
                  Enu.Align.left.val);
              bluetooth.printCustom('TRN No       :${dataInformation['gstno']}',
                  Enu.Size.bold.val, Enu.Align.left.val);
              line = "5";
              // bluetooth.printCustom(
              //     'Date         :${DateUtil.dateDMY(dataInformation['DDate'])}',
              //     Enu.Size.bold.val,
              //     Enu.Align.left.val);
              line = "6";
              var dateTime = DateUtil.dateDMY(dataInformation['DDate']) +
                  ' ' +
                  DateUtil.timeHMSA(dataInformation['BTime']);
              bluetooth.printCustom('Date & Time  :$dateTime',
                  Enu.Size.bold.val, Enu.Align.left.val);
              line = "7";
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              bluetooth.print8Column("SNo", "Description", " ", " ", " ", " ",
                  " ", " ", Enu.Size.bold.val);
              line = "8";
              bluetooth.print8Column(" ", " ", "UOM", "Rate", "Gross",
                  "Aft Disc", "Vat%", "Net", Enu.Size.bold.val);
              line = "9";
              bluetooth.print8Column(" ", " ", "Qty", " ", "Disc", "E Duty",
                  "Vat", "", Enu.Size.bold.val);
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              line = "10";
              for (var i = 0; i < dataParticulars.length; i++) {
                var itemName = dataParticulars[i]['itemname'].toString();
                bluetooth.print3Column(
                    '${i + 1}', itemName, "", Enu.Size.bold.val,
                    format: "%-2s %-57s %-2s %n");
                bluetooth.print8Column(
                    "",
                    "",
                    dataParticulars[i]['unitName'].toString(),
                    '${dataParticulars[i]['RealRate'].toStringAsFixed(2)}',
                    '${dataParticulars[i]['GrossValue'].toStringAsFixed(2)}',
                    '${dataParticulars[i]['Net'].toStringAsFixed(2)}',
                    '${dataParticulars[i]['igst']}',
                    '${dataParticulars[i]['Total'].toStringAsFixed(2)}',
                    Enu.Size.bold.val,
                    format: "%-2s %-20s %-6s %6s %6s %6s %6s %6s %n");
                bluetooth.print8Column(
                    "",
                    "",
                    '${dataParticulars[i]['Qty'].toStringAsFixed(2)}',
                    " ",
                    '${dataParticulars[i]['RDisc'].toStringAsFixed(2)}',
                    "0.00",
                    '${dataParticulars[i]['IGST'].toStringAsFixed(2)}',
                    " ",
                    Enu.Size.bold.val,
                    format: "%-2s %-20s %6s %6s %6s %6s %6s %6s %n");
              }
              line = "11";
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              bluetooth.print3Column(
                  'Total Gross Amount',
                  ':',
                  '${dataInformation['NetAmount'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              bluetooth.print3Column(
                  'Discount Amount',
                  ':',
                  '${dataInformation['OtherDiscount'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              line = "12";
              bluetooth.print3Column(
                  'OtherCharges',
                  ':',
                  '${dataInformation['OtherCharges'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              bluetooth.print3Column(
                  'Net Amount',
                  ':',
                  '${dataInformation['NetAmount'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              line = "13";
              bluetooth.print3Column(
                  'Excise Duty', ':', '0.00', Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              line = "14";
              bluetooth.print3Column(
                  'Vat Amount',
                  ':',
                  (double.tryParse(dataInformation['CGST'].toString()) +
                          double.tryParse(dataInformation['SGST'].toString()) +
                          double.tryParse(dataInformation['IGST'].toString()))
                      .toStringAsFixed(2),
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              line = "15";
              bluetooth.print3Column(
                  'Total Amount',
                  ':',
                  '${dataInformation['GrandTotal'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              bluetooth.printCustom(
                  'Amount In Words : ${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
                  Enu.Size.medium.val,
                  Enu.Align.left.val);
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              bluetooth.printCustom("Remarks:${dataInformation['Narration']}",
                  Enu.Size.medium.val, Enu.Align.left.val);
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              bluetooth.printNewLine();
              bluetooth.printCustom('${bill['message']}', Enu.Size.medium.val,
                  Enu.Align.left.val);
              line = "16";
              bluetooth.printNewLine();
              bluetooth.print4Column("Receiver Name & Sign :", "____________",
                  "Salesman Sign", "____________", Enu.Size.bold.val,
                  format: "%-16s %-15s %-16s %-15s %n");
              if (Settings.getValue<bool>('key-print-balance', false)) {
                //
              } else {
                var bal = double.tryParse(
                        dataInformation['Balance'].toString()) +
                    (double.tryParse(dataInformation['GrandTotal'].toString()) -
                        double.tryParse(
                            dataInformation['CashReceived'].toString()));
                bluetooth.printNewLine();
                bluetooth.printCustom(
                    'Party Balance: ${bal.toStringAsFixed(2)}',
                    Enu.Size.medium.val,
                    Enu.Align.left.val);
              }
              bluetooth.printQRcode(
                  companySettings.email, 200, 200, Enu.Align.center.val);
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              // bluetooth
              //     .paperCut(); //some printer not supported (sometime making image not centered)
              //bluetooth.drawerPin2(); // or you can use bluetooth.drawerPin5();
              // }else{}
            } else if (printerModel == 8) {
              var bal = double.tryParse(dataInformation['Balance'].toString()) +
                  (double.tryParse(dataInformation['GrandTotal'].toString()) -
                      double.tryParse(
                          dataInformation['CashReceived'].toString()));
              if (isLogo) {
                bluetooth.printNewLine();
                if (file != null) {
                  bluetooth.printImage(file.path); //path of your image/logo
                }
                bluetooth.printNewLine();
              }
              bluetooth.printNewLine();
              bluetooth.printCustom(companySettings.name,
                  Enu.Size.boldLarge.val, Enu.Align.center.val);
              bluetooth.printNewLine();
              line = "1";
              if (companySettings.add1.toString().trim().isNotEmpty) {
                bluetooth.printCustom(companySettings.add1.toString().trim(),
                    Enu.Size.bold.val, Enu.Align.center.val);
              }
              if (companySettings.add2.toString().trim().isNotEmpty) {
                bluetooth.printCustom(companySettings.add2.toString().trim(),
                    Enu.Size.bold.val, Enu.Align.center.val);
              }
              bluetooth.printCustom(
                  'Phone No: ${companySettings.telephone + ',' + companySettings.mobile}',
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "2";
              bluetooth.printCustom(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO: ${ComSettings.getValue('GST-NO', settings)}'
                      : 'TRN NO: ${ComSettings.getValue('GST-NO', settings)}',
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "3";
              bluetooth.printCustom(
                  invoiceHead, Enu.Size.boldMedium.val, Enu.Align.center.val);
              // bluetooth.printLeftRight("LEFT", "RIGHT", Size.medium.val);
              // bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
              line = "4";
              bluetooth.print3Column(
                  "Invoice No:${dataInformation['InvoiceNo']}",
                  " ",
                  'Date:${DateUtil.dateDMY(dataInformation['DDate'])}',
                  Enu.Size.bold.val,
                  format: "%-10s %-4s %-18s %n");
              line = "5";
              bluetooth.printCustom(
                  '----------------------------------------------------------',
                  Enu.Size.medium.val,
                  Enu.Align.center.val);
              line = "6";
              bluetooth.printCustom('${dataInformation['ToName']}',
                  Enu.Size.bold.val, Enu.Align.left.val);
              line = "7";
              bluetooth.printCustom(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO:${dataInformation['gstno'].toString().trim()}'
                      : 'TRN:${dataInformation['gstno'].toString().trim()}',
                  Enu.Size.bold.val,
                  Enu.Align.left.val);
              line = "8";
              // bluetooth.printNewLine();
              bluetooth.printCustom(
                  '----------------------------------------------------------',
                  Enu.Size.medium.val,
                  Enu.Align.center.val);
              line = "9";
              bluetooth.print5Column("Description", "Qty", "Price", "Vat",
                  "Total", Enu.Size.bold.val,
                  format: "%-20s %-4s %-4s %-4s %-6s %n");
              bluetooth.printCustom(
                  '----------------------------------------------------------',
                  Enu.Size.medium.val,
                  Enu.Align.center.val);
              line = "10";
              for (var i = 0; i < dataParticulars.length; i++) {
                var itemName = dataParticulars[i]['itemname'].toString();
                bluetooth.printCustom(
                    itemName, Enu.Size.bold.val, Enu.Align.left.val);
                // bluetooth.print4Column(itemName, "", "", "", Enu.Size.bold.val,
                //     format: "%35s %-1s %1s %1s %n");
                bluetooth.print5Column(
                    "",
                    '${dataParticulars[i]['Qty']}',
                    '${dataParticulars[i]['RealRate'].toStringAsFixed(2)}',
                    (double.tryParse(dataInformation['CGST'].toString()) +
                            double.tryParse(
                                dataInformation['SGST'].toString()) +
                            double.tryParse(dataInformation['IGST'].toString()))
                        .toStringAsFixed(2),
                    '${dataParticulars[i]['Total'].toStringAsFixed(2)}',
                    Enu.Size.bold.val,
                    format: "%-20s %4s %4s %4s %6s %n");
              }
              line = "11";
              // bluetooth.printNewLine();
              bluetooth.printCustom(
                  '----------------------------------------------------------',
                  Enu.Size.medium.val,
                  Enu.Align.center.val);
              bluetooth.printCustom(
                  'Gross Total:${dataInformation['NetAmount'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  Enu.Align.right.val);
              line = "12";
              bluetooth.printCustom(
                  'VAT:' +
                      (double.tryParse(dataInformation['CGST'].toString()) +
                              double.tryParse(
                                  dataInformation['SGST'].toString()) +
                              double.tryParse(
                                  dataInformation['IGST'].toString()))
                          .toStringAsFixed(2),
                  Enu.Size.bold.val,
                  Enu.Align.right.val);
              line = "13";
              bluetooth.printCustom(
                  'Discount:${dataInformation['OtherDiscount'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  Enu.Align.right.val);
              line = "14";
              bluetooth.printCustom(
                  'NET TOTAL:${dataInformation['GrandTotal'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  Enu.Align.right.val);
              // bluetooth.printNewLine();
              line = "15";
              bluetooth.printCustom('${bill['message']}', Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "16";
              bluetooth.printNewLine();
              if (isQrCodeKSA) {
                bluetooth.printQRcode(
                    SaudiConversion.getBase64(
                        companySettings.name,
                        ComSettings.getValue('GST-NO', settings),
                        DateUtil.dateTimeQrDMY(
                            DateUtil.datedYMD(dataInformation['DDate']) +
                                ' ' +
                                DateUtil.timeHMS(dataInformation['BTime'])),
                        double.tryParse(
                                dataInformation['GrandTotal'].toString())
                            .toStringAsFixed(2),
                        (double.tryParse(dataInformation['CGST'].toString()) +
                                double.tryParse(
                                    dataInformation['SGST'].toString()) +
                                double.tryParse(
                                    dataInformation['IGST'].toString()))
                            .toStringAsFixed(2)),
                    200,
                    200,
                    Enu.Align.center.val);
              }
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              // bluetooth
              //     .paperCut(); //some printer not supported (sometime making image not centered)
              //bluetooth.drawerPin2(); // or you can use bluetooth.drawerPin5();
              // }else{}
            } else {
              if (taxSale) {
                if (isLogo) {
                  bluetooth.printNewLine();
                  if (file != null) {
                    bluetooth.printImage(file.path); //path of your image/logo
                  }
                  bluetooth.printNewLine();
                }
                bluetooth.printNewLine();
                bluetooth.printCustom(companySettings.name,
                    Enu.Size.boldLarge.val, Enu.Align.center.val);
                bluetooth.printNewLine();
                line = "1";
                if (companySettings.add1.toString().trim().isNotEmpty) {
                  bluetooth.printCustom(companySettings.add1.toString().trim(),
                      Enu.Size.bold.val, Enu.Align.center.val);
                }
                if (companySettings.add2.toString().trim().isNotEmpty) {
                  bluetooth.printCustom(companySettings.add2.toString().trim(),
                      Enu.Size.bold.val, Enu.Align.center.val);
                }
                if (companySettings.add3.toString().trim().isNotEmpty) {
                  bluetooth.printCustom(companySettings.add3.toString().trim(),
                      Enu.Size.bold.val, Enu.Align.center.val);
                }
                if (companySettings.add4.toString().trim().isNotEmpty) {
                  bluetooth.printCustom(companySettings.add4.toString().trim(),
                      Enu.Size.bold.val, Enu.Align.center.val);
                }
                if (companySettings.telephone.toString().trim().isNotEmpty ||
                    companySettings.mobile.toString().trim().isNotEmpty) {
                  bluetooth.printCustom(
                      companySettings.telephone + ',' + companySettings.mobile,
                      Enu.Size.bold.val,
                      Enu.Align.center.val);
                }
                line = "2";
                bluetooth.printCustom(
                    companyTaxMode == 'INDIA'
                        ? 'GSTNO: ${ComSettings.getValue('GST-NO', settings)}'
                        : companyTaxMode == 'GULF'
                            ? 'TRN NO: ${ComSettings.getValue('GST-NO', settings)}'
                            : 'TaxNo: ${ComSettings.getValue('GST-NO', settings)}',
                    Enu.Size.bold.val,
                    Enu.Align.center.val);
                line = "3";
                bluetooth.printCustom(
                    invoiceHead, Enu.Size.boldMedium.val, Enu.Align.center.val);
                // bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
                // bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
                line = "4";
                // bluetooth.print3Column(
                //     "Invoice No : ${dataInformation['InvoiceNo']}",
                //     " ",
                //     'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                //     Enu.Size.bold.val,
                //     format: "%-18s %-4s %-20s %n");
                // bluetooth.printLeftRight(
                //     "Invoice No : ${dataInformation['InvoiceNo']}",
                //     'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                //     Enu.Size.bold.val);
                bluetooth.printCustom(
                    'Invoice No : ${dataInformation['InvoiceNo']}',
                    Enu.Size.bold.val,
                    Enu.Align.left.val);
                bluetooth.printCustom(
                    'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                    Enu.Size.bold.val,
                    Enu.Align.left.val);
                line = "5";
                bluetooth.printCustom(
                    '----------------------------------------------------------',
                    Enu.Size.medium.val,
                    Enu.Align.center.val);
                line = "6";
                bluetooth.printCustom('Bill To : ${dataInformation['ToName']}',
                    Enu.Size.bold.val, Enu.Align.left.val);
                line = "7";
                if (dataInformation['gstno'].toString().trim().isNotEmpty) {
                  bluetooth.printCustom(
                      (companyTaxMode == 'INDIA'
                          ? 'GSTNO : ${dataInformation['gstno'].toString().trim()}'
                          : companyTaxMode == 'GULF'
                              ? 'TRN : ${dataInformation['gstno'].toString().trim()}'
                              : 'TaxNo : ${dataInformation['gstno'].toString().trim()}'),
                      Enu.Size.bold.val,
                      Enu.Align.left.val);
                }
                line = "8";
                // bluetooth.printNewLine();
                bluetooth.printCustom(
                    '----------------------------------------------------------',
                    Enu.Size.medium.val,
                    Enu.Align.center.val);
                line = "9";
                bluetooth.print5Column("Description", "Qty", "Price", "Disc",
                    "Total", Enu.Size.bold.val,
                    format: "%-20s %-4s %-4s %-4s %-6s %n");
                bluetooth.printCustom(
                    '----------------------------------------------------------',
                    Enu.Size.medium.val,
                    Enu.Align.center.val);
                line = "10";
                for (var i = 0; i < dataParticulars.length; i++) {
                  var itemName = dataParticulars[i]['itemname'].toString();
                  bluetooth.printCustom(
                      itemName, Enu.Size.bold.val, Enu.Align.left.val);
                  // bluetooth.print4Column(itemName, "", "", "", Enu.Size.bold.val,
                  //     format: "%35s %-1s %1s %1s %n");
                  bluetooth.print5Column(
                      "",
                      '${dataParticulars[i]['Qty']}',
                      '${dataParticulars[i]['Rate'].toStringAsFixed(2)}',
                      '${dataParticulars[i]['Disc'].toStringAsFixed(2)}',
                      '${dataParticulars[i]['Total'].toStringAsFixed(2)}',
                      Enu.Size.bold.val,
                      format: "%-20s %4s %4s %4s %6s %n");
                }
                line = "11";
                // bluetooth.printNewLine();
                bluetooth.printCustom(
                    '----------------------------------------------------------',
                    Enu.Size.medium.val,
                    Enu.Align.center.val);
                bluetooth.printCustom(
                    'Gross Total :    ${dataInformation['NetAmount'].toStringAsFixed(2)}',
                    Enu.Size.bold.val,
                    Enu.Align.right.val);
                line = "12";
                bluetooth.printCustom(
                    'Tax :     ' +
                        (double.tryParse(dataInformation['CGST'].toString()) +
                                double.tryParse(
                                    dataInformation['SGST'].toString()) +
                                double.tryParse(
                                    dataInformation['IGST'].toString()))
                            .toStringAsFixed(2),
                    Enu.Size.bold.val,
                    Enu.Align.right.val);
                line = "13";
                for (var i = 0; i < otherAmount.length; i++) {
                  if (otherAmount[i]['Amount'].toDouble() > 0) {
                    bluetooth.printCustom(
                        '${otherAmount[i]['LedName']} :${double.tryParse(otherAmount[i]['Amount'].toString()).toStringAsFixed(2)}',
                        Enu.Size.bold.val,
                        Enu.Align.right.val);
                  }
                }
                line = "14";
                bluetooth.printCustom(
                    'Net Total : ${dataInformation['GrandTotal'].toStringAsFixed(2)}',
                    Enu.Size.boldMedium.val,
                    Enu.Align.right.val);
                // bluetooth.printNewLine();
                line = "15";
                if (isQrCodeKSA) {
                  bluetooth.printQRcode(
                      SaudiConversion.getBase64(
                          companySettings.name,
                          ComSettings.getValue('GST-NO', settings),
                          DateUtil.dateTimeQrDMY(
                              DateUtil.datedYMD(dataInformation['DDate']) +
                                  ' ' +
                                  DateUtil.timeHMS(dataInformation['BTime'])),
                          double.tryParse(
                                  dataInformation['GrandTotal'].toString())
                              .toStringAsFixed(2),
                          (double.tryParse(dataInformation['CGST'].toString()) +
                                  double.tryParse(
                                      dataInformation['SGST'].toString()) +
                                  double.tryParse(
                                      dataInformation['IGST'].toString()))
                              .toStringAsFixed(2)),
                      200,
                      200,
                      Enu.Align.center.val);
                }
              } else {
                if (ComSettings.appSettings(
                    'bool', 'key-print-header-es', false)) {
                  if (isLogo) {
                    bluetooth.printNewLine();
                    if (file != null) {
                      bluetooth.printImage(file.path); //path of your image/logo
                    }
                    bluetooth.printNewLine();
                  }
                  bluetooth.printNewLine();
                  bluetooth.printCustom(companySettings.name,
                      Enu.Size.boldLarge.val, Enu.Align.center.val);
                  bluetooth.printNewLine();
                  line = "1";
                  if (companySettings.add1.toString().trim().isNotEmpty) {
                    bluetooth.printCustom(
                        companySettings.add1.toString().trim(),
                        Enu.Size.bold.val,
                        Enu.Align.center.val);
                  }
                  if (companySettings.add2.toString().trim().isNotEmpty) {
                    bluetooth.printCustom(
                        companySettings.add2.toString().trim(),
                        Enu.Size.bold.val,
                        Enu.Align.center.val);
                  }
                  if (companySettings.add3.toString().trim().isNotEmpty) {
                    bluetooth.printCustom(
                        companySettings.add3.toString().trim(),
                        Enu.Size.bold.val,
                        Enu.Align.center.val);
                  }
                  if (companySettings.add4.toString().trim().isNotEmpty) {
                    bluetooth.printCustom(
                        companySettings.add4.toString().trim(),
                        Enu.Size.bold.val,
                        Enu.Align.center.val);
                  }
                  if (companySettings.telephone.toString().trim().isNotEmpty ||
                      companySettings.mobile.toString().trim().isNotEmpty) {
                    bluetooth.printCustom(
                        'Tel : ${companySettings.telephone + ',' + companySettings.mobile}',
                        Enu.Size.bold.val,
                        Enu.Align.center.val);
                  }
                  line = "2";
                }
                line = "3";
                bluetooth.printCustom(
                    invoiceHead, Enu.Size.bold.val, Enu.Align.center.val);
                // bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
                // bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
                line = "4";
                bluetooth.print3Column(
                    "Invoice No : ${dataInformation['InvoiceNo']}",
                    " ",
                    'Date : ${DateUtil.dateDMY(dataInformation['DDate']) + ' ' + DateUtil.timeHMSA(dataInformation['BTime'])}',
                    Enu.Size.bold.val,
                    format: "%-18s %-4s %-20s %n");
                line = "5";
                bluetooth.printCustom(
                    '----------------------------------------------------------',
                    Enu.Size.medium.val,
                    Enu.Align.center.val);
                line = "6";
                bluetooth.printCustom('${dataInformation['ToName']}',
                    Enu.Size.bold.val, Enu.Align.left.val);
                line = "7";
                line = "8";
                // bluetooth.printNewLine();
                bluetooth.printCustom(
                    '----------------------------------------------------------',
                    Enu.Size.medium.val,
                    Enu.Align.center.val);
                line = "9";
                bluetooth.print5Column("Description", "Qty", "Price", "Disc",
                    "Total", Enu.Size.bold.val,
                    format: "%-20s %-4s %-4s %-4s %-6s %n");
                bluetooth.printCustom(
                    '----------------------------------------------------------',
                    Enu.Size.medium.val,
                    Enu.Align.center.val);
                line = "10";
                for (var i = 0; i < dataParticulars.length; i++) {
                  var itemName = dataParticulars[i]['itemname'].toString();
                  bluetooth.printCustom(
                      itemName, Enu.Size.bold.val, Enu.Align.left.val);
                  // bluetooth.print4Column(itemName, "", "", "", Enu.Size.bold.val,
                  //     format: "%35s %-1s %1s %1s %n");
                  bluetooth.print5Column(
                      "",
                      '${dataParticulars[i]['Qty']}',
                      '${dataParticulars[i]['Rate'].toStringAsFixed(2)}',
                      '${dataParticulars[i]['Disc'].toStringAsFixed(2)}',
                      '${dataParticulars[i]['Total'].toStringAsFixed(2)}',
                      Enu.Size.bold.val,
                      format: "%-20s %4s %4s %4s %6s %n");
                }
                line = "11";
                // bluetooth.printNewLine();
                bluetooth.printCustom(
                    '----------------------------------------------------------',
                    Enu.Size.medium.val,
                    Enu.Align.center.val);
                bluetooth.printCustom(
                    'Gross Total : ${dataInformation['NetAmount'].toStringAsFixed(2)}',
                    Enu.Size.bold.val,
                    Enu.Align.right.val);
                line = "12";
                for (var i = 0; i < otherAmount.length; i++) {
                  if (otherAmount[i]['Amount'].toDouble() > 0) {
                    bluetooth.printCustom(
                        '${otherAmount[i]['LedName']} :${double.tryParse(otherAmount[i]['Amount'].toString()).toStringAsFixed(2)}',
                        Enu.Size.bold.val,
                        Enu.Align.right.val);
                  }
                }
                line = "13";
                bluetooth.printCustom(
                    'Net Total : ${dataInformation['GrandTotal'].toStringAsFixed(2)}',
                    Enu.Size.bold.val,
                    Enu.Align.right.val);
                // bluetooth.printNewLine();
                line = "14";
                if (isQrCodeKSA) {
                  bluetooth.printQRcode(
                      SaudiConversion.getBase64(
                          companySettings.name,
                          ComSettings.getValue('GST-NO', settings),
                          DateUtil.dateTimeQrDMY(
                              DateUtil.datedYMD(dataInformation['DDate']) +
                                  ' ' +
                                  DateUtil.timeHMS(dataInformation['BTime'])),
                          double.tryParse(
                                  dataInformation['GrandTotal'].toString())
                              .toStringAsFixed(2),
                          (double.tryParse(dataInformation['CGST'].toString()) +
                                  double.tryParse(
                                      dataInformation['SGST'].toString()) +
                                  double.tryParse(
                                      dataInformation['IGST'].toString()))
                              .toStringAsFixed(2)),
                      200,
                      200,
                      Enu.Align.center.val);
                }
              }

              if (!Settings.getValue<bool>('key-print-balance', false)) {
                bluetooth.printCustom(
                    '----------------------------------------------------------',
                    Enu.Size.medium.val,
                    Enu.Align.center.val);
                bluetooth.printLeftRight(
                    "CashReceived : ",
                    "${dataInformation['CashReceived'].toStringAsFixed(2)}",
                    Enu.Size.bold.val);
                bluetooth.printLeftRight(
                    "Old Balance : ",
                    "${dataInformation['Balance'].toStringAsFixed(2)}",
                    Enu.Size.bold.val);
                bluetooth.printLeftRight(
                    "Balance : ",
                    ((double.tryParse(dataInformation['Balance'].toString())) +
                            (double.tryParse(
                                    dataInformation['GrandTotal'].toString()) -
                                double.tryParse(dataInformation['CashReceived']
                                    .toString())))
                        .toStringAsFixed(2),
                    Enu.Size.bold.val);
              }
              bluetooth.printNewLine();
              bluetooth.printCustom('${bill['message']}', Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "15";
              bluetooth.printNewLine();
              bluetooth.printNewLine();
            }
          } catch (e, s) {
            FirebaseCrashlytics.instance
                .recordError(e, s, reason: 'blue print:' + line);
          }
        }
      });
    } else if (widget.data[4] == 'SALES RETURN') {
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
      var invoiceHead =
          Settings.getValue<String>('key-sales-return-head', 'Sales Return');
      bool isQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
      bool isEsQrCodeKSA =
          ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
      int printCopy = Settings.getValue<int>('key-dropdown-print-copy-view', 0);
      int printerModel =
          Settings.getValue<int>('key-dropdown-printer-model-view', 0);
      int printerLines = Settings.getValue<int>('key-dropdown-print-line', 0);
      //image max 300px X 300px
      printerLines = printerLines * 10;
      String printerLine = "-";
      for (int k = 0; k <= printerLines; k++) {
        printerLine = printerLine + "-";
      }

      ///image from File path
      // String filename = 'yourlogo.png';
      // ByteData bytesData = await rootBundle.load("assets/logo1.png");
      // String dir = (await getApplicationDocumentsDirectory()).path;
      // File file = await File('$dir/$filename').writeAsBytes(bytesData.buffer
      //     .asUint8List(bytesData.offsetInBytes, bytesData.lengthInBytes));

      ///image from Asset
      ByteData bytesAsset = await rootBundle.load("assets/logo1.png");
      Uint8List imageBytesFromAsset = bytesAsset.buffer
          .asUint8List(bytesAsset.offsetInBytes, bytesAsset.lengthInBytes);

      ///image from Network
      // var response = await http.get(Uri.parse(
      //     "https://raw.githubusercontent.com/kakzaki/blue_thermal_printer/master/example/assets/images/yourlogo.png"));
      // Uint8List bytesNetwork = response.bodyBytes;
      // Uint8List imageBytesFromNetwork = bytesNetwork.buffer
      //     .asUint8List(bytesNetwork.offsetInBytes, bytesNetwork.lengthInBytes);

      bluetooth.isConnected.then((isConnected) {
        if (isConnected == true) {
          String line = "0";
          try {
            if (printerModel == 5) {
              bluetooth.printNewLine();
              // bluetooth.printImage(file.path); //path of your image/logo
              // bluetooth.printNewLine();
              // bluetooth.printImageBytes(imageBytesFromAsset); //image from Asset
              // bluetooth.printNewLine();
              // bluetooth.printImageBytes(imageBytesFromNetwork); //image from Network
              // bluetooth.printNewLine();
              // if (taxSale) {
              bluetooth.printCustom(companySettings.name,
                  Enu.Size.boldLarge.val, Enu.Align.center.val);
              bluetooth.printNewLine();
              line = "1";
              if (companySettings.add1.toString().trim().isNotEmpty) {
                bluetooth.printCustom(companySettings.add1.toString().trim(),
                    Enu.Size.bold.val, Enu.Align.center.val);
              }
              if (companySettings.add2.toString().trim().isNotEmpty) {
                bluetooth.printCustom(companySettings.add2.toString().trim(),
                    Enu.Size.bold.val, Enu.Align.center.val);
              }
              bluetooth.printCustom(
                  'Phone No: ${companySettings.telephone + ',' + companySettings.mobile}',
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "2";
              bluetooth.printCustom(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO: ${ComSettings.getValue('GST-NO', settings)}'
                      : 'TRN NO: ${ComSettings.getValue('GST-NO', settings)}',
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "3";
              bluetooth.printCustom(
                  invoiceHead, Enu.Size.boldMedium.val, Enu.Align.center.val);
              // bluetooth.printLeftRight("LEFT", "RIGHT", Size.medium.val);
              // bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
              line = "4";
              bluetooth.printCustom(
                  'Voucher No:${dataInformation['InvoiceNo']}',
                  Enu.Size.bold.val,
                  Enu.Align.left.val);
              // bluetooth.print4Column("Voucher No:",'${dataInformation['InvoiceNo']}',"","", Enu.Size.bold.val,format: "%-20s %20s %20s %20s %n");
              // bluetooth.printLeftRight('Voucher No:${dataInformation['InvoiceNo']}',
              //     "", Enu.Size.bold.val);
              // bluetooth.printNewLine();
              line = "5";
              bluetooth.printCustom(
                  'Ordering Date:${DateUtil.dateDMY(dataInformation['DDate'])}',
                  Enu.Size.bold.val,
                  Enu.Align.left.val);
              line = "6";
              var bal = double.tryParse(dataInformation['Balance'].toString()) -
                  double.tryParse(dataInformation['GrandTotal'].toString());
              // bluetooth.printLeftRight(
              //   'Party Name:${dataInformation['ToName']}',
              //   'Party Balance:${bal.toStringAsFixed(2)}',
              //   Enu.Size.bold.val,
              // );
              bluetooth.print4Column(
                  'Party Name:${dataInformation['ToName']}',
                  '',
                  "",
                  'Party Balance:${bal.toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-20s %5s %5s %20s %n");
              line = "7";
              // bluetooth.printLeftRight(
              //     companyTaxMode == 'INDIA'
              //         ? 'GSTNO:${dataInformation['gstno'].toString().trim()}'
              //         : 'Party TRNNO:${dataInformation['gstno'].toString().trim()}',
              //     "",
              //     Enu.Size.bold.val);
              bluetooth.printCustom(
                  companyTaxMode == 'INDIA'
                      ? 'GSTNO:${dataInformation['gstno'].toString().trim()}'
                      : 'Party TRNNO:${dataInformation['gstno'].toString().trim()}',
                  Enu.Size.bold.val,
                  Enu.Align.left.val);
              line = "8";
              // bluetooth.printNewLine();
              bluetooth.printCustom(
                  '----------------------------------------------------------',
                  Enu.Size.medium.val,
                  Enu.Align.center.val);
              line = "9";
              bluetooth.print7Column("Slno", "Item Des", "Qty(UOM)", "Rate",
                  "Taxable", "Tax amt", "Net Amt", Enu.Size.bold.val,
                  format: "%2s %-20s %7s %7s %6s %7s %7s %n");
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              line = "10";
              for (var i = 0; i < dataParticulars.length; i++) {
                var itemName = dataParticulars[i]['itemname'].toString();
                bluetooth.print7Column(
                    '${i + 1}', itemName, "", "", "", "", "", Enu.Size.bold.val,
                    format: "%2s %-24s %7s %7s %6s %7s %7s %n");
                bluetooth.print7Column(
                    "",
                    "",
                    '${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}',
                    '${dataParticulars[i]['Rate']}',
                    '${dataParticulars[i]['RealRate']}',
                    '${dataParticulars[i]['IGST']}',
                    '${dataParticulars[i]['Total']}',
                    Enu.Size.bold.val,
                    format: "%2s %-25s %7s %7s %6s %7s %7s %n");
              }
              line = "11";
              // bluetooth.printNewLine();
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              bluetooth.printCustom(
                  'Gross Total:${dataInformation['NetAmount']}',
                  Enu.Size.bold.val,
                  Enu.Align.right.val);
              line = "12";
              bluetooth.printCustom(
                  'VAT:' +
                      (double.tryParse(dataInformation['CGST'].toString()) +
                              double.tryParse(
                                  dataInformation['SGST'].toString()) +
                              double.tryParse(
                                  dataInformation['IGST'].toString()))
                          .toStringAsFixed(2),
                  Enu.Size.bold.val,
                  Enu.Align.right.val);
              line = "13";
              bluetooth.printCustom(
                  'Discount:${dataInformation['OtherDiscount']}',
                  Enu.Size.bold.val,
                  Enu.Align.right.val);
              line = "14";
              bluetooth.printCustom(
                  'NET TOTAL:${dataInformation['GrandTotal']}',
                  Enu.Size.bold.val,
                  Enu.Align.right.val);
              // bluetooth.printNewLine();
              line = "15";
              bluetooth.printCustom('${bill['message']}', Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "16";
              bluetooth.printNewLine();
              // bluetooth.printQRcode(
              //     "Insert Your Own Text to Generate", 200, 200, Align.center.val);
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              // bluetooth
              //     .paperCut(); //some printer not supported (sometime making image not centered)
              //bluetooth.drawerPin2(); // or you can use bluetooth.drawerPin5();
              // }else{}
            } else if (printerModel == 7) {
              bluetooth.printNewLine();
              bluetooth.printImageBytes(imageBytesFromAsset); //image from Asset
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              bluetooth.printCustom(companySettings.name,
                  Enu.Size.extraLarge.val, Enu.Align.center.val);
              bluetooth.printNewLine();
              line = "1";
              if (companySettings.add1.toString().trim().isNotEmpty) {
                bluetooth.printCustom(companySettings.add1.toString().trim(),
                    Enu.Size.bold.val, Enu.Align.center.val);
              }
              bluetooth.printCustom(
                  'Mob: ${companySettings.mobile} ${companySettings.telephone}',
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
              line = "2";
              bluetooth.printCustom(
                  'TRN: ${ComSettings.getValue('GST-NO', settings)}',
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
              bluetooth.printCustom('E-Mail: ${companySettings.email}',
                  Enu.Size.bold.val, Enu.Align.center.val);
              line = "2A";
              bluetooth.printNewLine();
              line = "3";
              bluetooth.printCustom(
                  invoiceHead, Enu.Size.boldMedium.val, Enu.Align.center.val);
              line = "4";
              bluetooth.printNewLine();
              bluetooth.printCustom(
                  'Customer Name:${dataInformation['ToName']}',
                  Enu.Size.bold.val,
                  Enu.Align.left.val);
              bluetooth.printCustom(
                  'Voucher No   :${dataInformation['InvoiceNo']}',
                  Enu.Size.bold.val,
                  Enu.Align.left.val);
              bluetooth.printCustom('TRN No       :${dataInformation['gstno']}',
                  Enu.Size.bold.val, Enu.Align.left.val);
              line = "5";
              // bluetooth.printCustom(
              //     'Date         :${DateUtil.dateDMY(dataInformation['DDate'])}',
              //     Enu.Size.bold.val,
              //     Enu.Align.left.val);
              line = "6";
              var dateTime = DateUtil.dateDMY(dataInformation['DDate']) +
                  ' ' +
                  DateUtil.timeHMSA(dataInformation['BTime']);
              bluetooth.printCustom('Date & Time  :$dateTime',
                  Enu.Size.bold.val, Enu.Align.left.val);
              line = "7";
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              bluetooth.print8Column("SNo", "Description", " ", " ", " ", " ",
                  " ", " ", Enu.Size.bold.val);
              line = "8";
              bluetooth.print8Column(" ", " ", "UOM", "Rate", "Gross",
                  "Aft Disc", "Vat%", "Net", Enu.Size.bold.val);
              line = "9";
              bluetooth.print8Column(" ", " ", "Qty", " ", "Disc", "E Duty",
                  "Vat", "", Enu.Size.bold.val);
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              line = "10";
              for (var i = 0; i < dataParticulars.length; i++) {
                var itemName = dataParticulars[i]['itemname'].toString();
                bluetooth.print3Column(
                    '${i + 1}', itemName, "", Enu.Size.bold.val,
                    format: "%-2s %-57s %-2s %n");
                bluetooth.print8Column(
                    "",
                    "",
                    dataParticulars[i]['unitName'].toString(),
                    '${dataParticulars[i]['RealRate'].toStringAsFixed(2)}',
                    '${dataParticulars[i]['GrossValue'].toStringAsFixed(2)}',
                    '${dataParticulars[i]['Net'].toStringAsFixed(2)}',
                    '${dataParticulars[i]['igst']}',
                    '${dataParticulars[i]['Total'].toStringAsFixed(2)}',
                    Enu.Size.bold.val,
                    format: "%-2s %-20s %-6s %6s %6s %6s %6s %6s %n");
                bluetooth.print8Column(
                    "",
                    "",
                    '${dataParticulars[i]['Qty'].toStringAsFixed(2)}',
                    " ",
                    '${dataParticulars[i]['RDisc'].toStringAsFixed(2)}',
                    "0.00",
                    '${dataParticulars[i]['IGST'].toStringAsFixed(2)}',
                    " ",
                    Enu.Size.bold.val,
                    format: "%-2s %-20s %6s %6s %6s %6s %6s %6s %n");
              }
              line = "11";
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              bluetooth.print3Column(
                  'Total Gross Amount',
                  ':',
                  '${dataInformation['NetAmount'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              bluetooth.print3Column(
                  'Discount Amount',
                  ':',
                  '${dataInformation['OtherDiscount'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              line = "12";
              bluetooth.print3Column(
                  'OtherCharges',
                  ':',
                  '${dataInformation['OtherCharges'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              bluetooth.print3Column(
                  'Net Amount',
                  ':',
                  '${dataInformation['NetAmount'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              line = "13";
              bluetooth.print3Column(
                  'Excise Duty', ':', '0.00', Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              line = "14";
              bluetooth.print3Column(
                  'Vat Amount',
                  ':',
                  (double.tryParse(dataInformation['CGST'].toString()) +
                          double.tryParse(dataInformation['SGST'].toString()) +
                          double.tryParse(dataInformation['IGST'].toString()))
                      .toStringAsFixed(2),
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              line = "15";
              bluetooth.print3Column(
                  'Total Amount',
                  ':',
                  '${dataInformation['GrandTotal'].toStringAsFixed(2)}',
                  Enu.Size.bold.val,
                  format: "%-30s %-10s %20s %n");
              bluetooth.printCustom(
                  'Amount In Words : ${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}',
                  Enu.Size.medium.val,
                  Enu.Align.left.val);
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              bluetooth.printCustom("Remarks:${dataInformation['Narration']}",
                  Enu.Size.medium.val, Enu.Align.left.val);
              bluetooth.printCustom(
                  printerLine, Enu.Size.medium.val, Enu.Align.center.val);
              bluetooth.printNewLine();
              bluetooth.printCustom('${bill['message']}', Enu.Size.medium.val,
                  Enu.Align.left.val);
              line = "16";
              bluetooth.printNewLine();
              bluetooth.print4Column("Receiver Name & Sign :", "____________",
                  "Salesman Sign", "____________", Enu.Size.bold.val,
                  format: "%-16s %-15s %-16s %-15s %n");
              if (Settings.getValue<bool>('key-print-balance', false)) {
                //
              } else {
                var bal = double.tryParse(
                        dataInformation['Balance'].toString()) -
                    double.tryParse(dataInformation['GrandTotal'].toString());
                bluetooth.printNewLine();
                bluetooth.printCustom(
                    'Party Balance: ${bal.toStringAsFixed(2)}',
                    Enu.Size.medium.val,
                    Enu.Align.left.val);
              }
              bluetooth.printQRcode(
                  companySettings.email, 200, 200, Enu.Align.center.val);
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              // bluetooth
              //     .paperCut(); //some printer not supported (sometime making image not centered)
              //bluetooth.drawerPin2(); // or you can use bluetooth.drawerPin5();
              // }else{}
            } else {
              bluetooth.printNewLine();
              //
            }
          } catch (e, s) {
            FirebaseCrashlytics.instance
                .recordError(e, s, reason: 'blue print:' + line);
          }
        }
      });
    } else if (widget.data[4] == 'RECEIPT') {
      bill = bill[0][0];

      bool isLogo = ComSettings.appSettings('bool', 'key-print-logo', false);
      //image max 300px X 300px
      //image from File path
      File file;
      if (isLogo) {
        String dir = (await getApplicationDocumentsDirectory()).path;
        file = File('$dir/logo.png');
      }

      var invoiceHead =
          Settings.getValue<String>('key-receipt-voucher-head', 'RECEIPT')
                  .isNotEmpty
              ? Settings.getValue<String>('key-receipt-voucher-head', 'RECEIPT')
              : 'Receipt Invoice';

      bluetooth.isConnected.then((isConnected) {
        if (isConnected == true) {
          String line = "0";
          try {
            if (isLogo) {
              bluetooth.printNewLine();
              if (file != null) {
                bluetooth.printImage(file.path); //path of your image/logo
              }
              bluetooth.printNewLine();
            }
            bluetooth.printNewLine();
            bluetooth.printCustom(companySettings.name, Enu.Size.boldLarge.val,
                Enu.Align.center.val);
            bluetooth.printNewLine();
            line = "1";
            if (companySettings.add1.toString().trim().isNotEmpty) {
              bluetooth.printCustom(companySettings.add1.toString().trim(),
                  Enu.Size.bold.val, Enu.Align.center.val);
            }
            if (companySettings.add2.toString().trim().isNotEmpty) {
              bluetooth.printCustom(companySettings.add2.toString().trim(),
                  Enu.Size.bold.val, Enu.Align.center.val);
            }
            if (companySettings.add3.toString().trim().isNotEmpty) {
              bluetooth.printCustom(companySettings.add3.toString().trim(),
                  Enu.Size.bold.val, Enu.Align.center.val);
            }
            if (companySettings.add4.toString().trim().isNotEmpty) {
              bluetooth.printCustom(companySettings.add4.toString().trim(),
                  Enu.Size.bold.val, Enu.Align.center.val);
            }
            if (companySettings.telephone.toString().trim().isNotEmpty ||
                companySettings.mobile.toString().trim().isNotEmpty) {
              bluetooth.printCustom(
                  companySettings.telephone + ',' + companySettings.mobile,
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
            }
            line = "2";
            bluetooth.printCustom(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO: ${ComSettings.getValue('GST-NO', settings)}'
                    : companyTaxMode == 'GULF'
                        ? 'TRN NO: ${ComSettings.getValue('GST-NO', settings)}'
                        : 'TaxNo: ${ComSettings.getValue('GST-NO', settings)}',
                Enu.Size.bold.val,
                Enu.Align.center.val);
            line = "3";
            bluetooth.printCustom(
                invoiceHead, Enu.Size.boldMedium.val, Enu.Align.center.val);
            // bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
            // bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
            // line = "4";
            bluetooth.printCustom('Invoice No : ${bill['entryNo']}',
                Enu.Size.bold.val, Enu.Align.left.val);
            bluetooth.printCustom('Date : ${DateUtil.dateDMY(bill['date'])}',
                Enu.Size.bold.val, Enu.Align.left.val);
            bluetooth.printCustom('From : ${bill['name']}', Enu.Size.bold.val,
                Enu.Align.left.val);
            bluetooth.printCustom(
                '----------------------------------------------------------',
                Enu.Size.medium.val,
                Enu.Align.center.val);

            bluetooth.print3Column(
                "Amount   : ",
                " ",
                double.tryParse(bill['amount'].toString()).toStringAsFixed(2),
                Enu.Size.bold.val,
                format: "%-18s %-4s %20s %n");
            bluetooth.print3Column(
                "Discount : ",
                " ",
                double.tryParse(bill['discount'].toString()).toStringAsFixed(2),
                Enu.Size.bold.val,
                format: "%-18s %-4s %20s %n");
            if (Settings.getValue<bool>('key-print-balance', false)) {
              bluetooth.print3Column(
                  "Total    : ",
                  " ",
                  double.tryParse(bill['total'].toString()).toStringAsFixed(2),
                  Enu.Size.bold.val,
                  format: "%-18s %-4s %20s %n");
            } else {
              if (bill['name'] != 'CASH') {
                var bal = bill['oldBalance'].toString().split(' ')[0];
                double oldBalance = double.tryParse(bal.toString());
                bluetooth.print3Column(
                    "Total    : ",
                    " ",
                    double.tryParse(bill['total'].toString())
                        .toStringAsFixed(2),
                    Enu.Size.bold.val,
                    format: "%-18s %-4s %20s %n");
                bluetooth.printCustom(
                    '----------------------------------------------------------',
                    Enu.Size.medium.val,
                    Enu.Align.center.val);
                bluetooth.printLeftRight("Old Balance : ",
                    oldBalance.toStringAsFixed(2), Enu.Size.bold.val);
                double balance = oldBalance > 0
                    ? oldBalance > double.tryParse(bill['total'].toString())
                        ? (oldBalance -
                            double.tryParse(bill['total'].toString()))
                        : double.tryParse(bill['total'].toString()) - oldBalance
                    : double.tryParse(bill['total'].toString());
                bluetooth.printLeftRight("Balance : ",
                    balance.toStringAsFixed(2), Enu.Size.bold.val);
              } else {
                bluetooth.print3Column(
                    "Total    : ",
                    " ",
                    double.tryParse(bill['total'].toString())
                        .toStringAsFixed(2),
                    Enu.Size.bold.val,
                    format: "%-18s %-4s %20s %n");
              }
            }

            bluetooth.printNewLine();
            bluetooth.printCustom(
                '${bill['message']}', Enu.Size.bold.val, Enu.Align.center.val);
            line = "15";
            bluetooth.printNewLine();
            bluetooth.printNewLine();
          } catch (e, s) {
            FirebaseCrashlytics.instance
                .recordError(e, s, reason: 'blue print:' + line);
          }
        }
      });
    } else if (widget.data[4] == 'PAYMENT') {
      bill = bill[0][0];

      bool isLogo = ComSettings.appSettings('bool', 'key-print-logo', false);
      //image max 300px X 300px
      //image from File path
      File file;
      if (isLogo) {
        String dir = (await getApplicationDocumentsDirectory()).path;
        file = File('$dir/logo.png');
      }

      var invoiceHead =
          Settings.getValue<String>('key-payment-voucher-head', 'PAYMENT')
                  .isNotEmpty
              ? Settings.getValue<String>('key-payment-voucher-head', 'PAYMENT')
              : 'Payment Invoice';

      bluetooth.isConnected.then((isConnected) {
        if (isConnected == true) {
          String line = "0";
          try {
            if (isLogo) {
              bluetooth.printNewLine();
              if (file != null) {
                bluetooth.printImage(file.path); //path of your image/logo
              }
              bluetooth.printNewLine();
            }
            bluetooth.printNewLine();
            bluetooth.printCustom(companySettings.name, Enu.Size.boldLarge.val,
                Enu.Align.center.val);
            bluetooth.printNewLine();
            line = "1";
            if (companySettings.add1.toString().trim().isNotEmpty) {
              bluetooth.printCustom(companySettings.add1.toString().trim(),
                  Enu.Size.bold.val, Enu.Align.center.val);
            }
            if (companySettings.add2.toString().trim().isNotEmpty) {
              bluetooth.printCustom(companySettings.add2.toString().trim(),
                  Enu.Size.bold.val, Enu.Align.center.val);
            }
            if (companySettings.add3.toString().trim().isNotEmpty) {
              bluetooth.printCustom(companySettings.add3.toString().trim(),
                  Enu.Size.bold.val, Enu.Align.center.val);
            }
            if (companySettings.add4.toString().trim().isNotEmpty) {
              bluetooth.printCustom(companySettings.add4.toString().trim(),
                  Enu.Size.bold.val, Enu.Align.center.val);
            }
            if (companySettings.telephone.toString().trim().isNotEmpty ||
                companySettings.mobile.toString().trim().isNotEmpty) {
              bluetooth.printCustom(
                  companySettings.telephone + ',' + companySettings.mobile,
                  Enu.Size.bold.val,
                  Enu.Align.center.val);
            }
            line = "2";
            bluetooth.printCustom(
                companyTaxMode == 'INDIA'
                    ? 'GSTNO: ${ComSettings.getValue('GST-NO', settings)}'
                    : companyTaxMode == 'GULF'
                        ? 'TRN NO: ${ComSettings.getValue('GST-NO', settings)}'
                        : 'TaxNo: ${ComSettings.getValue('GST-NO', settings)}',
                Enu.Size.bold.val,
                Enu.Align.center.val);
            line = "3";
            bluetooth.printCustom(
                invoiceHead, Enu.Size.boldMedium.val, Enu.Align.center.val);
            // bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
            // bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
            // line = "4";
            bluetooth.printCustom('Invoice No : ${bill['entryNo']}',
                Enu.Size.bold.val, Enu.Align.left.val);
            bluetooth.printCustom('Date : ${DateUtil.dateDMY(bill['date'])}',
                Enu.Size.bold.val, Enu.Align.left.val);
            bluetooth.printCustom('From : ${bill['name']}', Enu.Size.bold.val,
                Enu.Align.left.val);
            bluetooth.printCustom(
                '----------------------------------------------------------',
                Enu.Size.medium.val,
                Enu.Align.center.val);

            bluetooth.print3Column(
                "Amount   : ",
                " ",
                double.tryParse(bill['amount'].toString()).toStringAsFixed(2),
                Enu.Size.bold.val,
                format: "%-18s %-4s %20s %n");
            bluetooth.print3Column(
                "Discount : ",
                " ",
                double.tryParse(bill['discount'].toString()).toStringAsFixed(2),
                Enu.Size.bold.val,
                format: "%-18s %-4s %20s %n");
            if (Settings.getValue<bool>('key-print-balance', false)) {
              bluetooth.print3Column(
                  "Total    : ",
                  " ",
                  double.tryParse(bill['total'].toString()).toStringAsFixed(2),
                  Enu.Size.bold.val,
                  format: "%-18s %-4s %20s %n");
            } else {
              if (bill['name'] != 'CASH') {
                var bal = bill['oldBalance'].toString().split(' ')[0];
                double oldBalance = double.tryParse(bal.toString());
                bluetooth.print3Column(
                    "Total    : ",
                    " ",
                    double.tryParse(bill['total'].toString())
                        .toStringAsFixed(2),
                    Enu.Size.bold.val,
                    format: "%-18s %-4s %20s %n");
                bluetooth.printCustom(
                    '----------------------------------------------------------',
                    Enu.Size.medium.val,
                    Enu.Align.center.val);
                bluetooth.printLeftRight("Old Balance : ",
                    oldBalance.toStringAsFixed(2), Enu.Size.bold.val);
                double balance = oldBalance > 0
                    ? oldBalance > double.tryParse(bill['total'].toString())
                        ? (oldBalance -
                            double.tryParse(bill['total'].toString()))
                        : double.tryParse(bill['total'].toString()) - oldBalance
                    : double.tryParse(bill['total'].toString());
                bluetooth.printLeftRight("Balance : ",
                    balance.toStringAsFixed(2), Enu.Size.bold.val);
              } else {
                bluetooth.print3Column(
                    "Total    : ",
                    " ",
                    double.tryParse(bill['total'].toString())
                        .toStringAsFixed(2),
                    Enu.Size.bold.val,
                    format: "%-18s %-4s %20s %n");
              }
            }

            bluetooth.printNewLine();
            bluetooth.printCustom(
                '${bill['message']}', Enu.Size.bold.val, Enu.Align.center.val);
            line = "15";
            bluetooth.printNewLine();
            bluetooth.printNewLine();
          } catch (e, s) {
            FirebaseCrashlytics.instance
                .recordError(e, s, reason: 'blue print:' + line);
          }
        }
      });
    }
  }
}
