// @dart = 2.9
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_sunmi_printer/flutter_sunmi_printer.dart';
import 'package:json_table/json_table.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/print_settings_model.dart';
import 'package:sheraccerp/models/sales_bill.dart';
import 'package:sheraccerp/models/sales_model.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/models/voucher_type_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/html_previews/sales_preview.dart';
import 'package:sheraccerp/screens/html_previews/sales_return_preview.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/blue_thermal.dart';
import 'package:sheraccerp/service/bt_print.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/invoice.dart';
import 'package:sheraccerp/util/number_to_word.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';

import 'package:image/image.dart' as img;
import 'package:image/image.dart' as images;
import 'package:sunmi_printer_service/sunmi_printer_service.dart';
import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;
import 'package:sunmi_printer_service/sunmi_printer_service.dart' as sum_mi;

import 'package:webview_flutter/webview_flutter.dart';
import 'package:zxing2/qrcode.dart';

class PurchaseReturnPreviewShow extends StatefulWidget {
  const PurchaseReturnPreviewShow({Key key}) : super(key: key);

  @override
  State<PurchaseReturnPreviewShow> createState() =>
      _PurchaseReturnPreviewShowState();
}

class _PurchaseReturnPreviewShowState extends State<PurchaseReturnPreviewShow> {
  final GlobalKey _globalKey = GlobalKey();
  DioService api = DioService();
  var totalQty = 0.0, totalRate = 0.0;
  String companyState = '', companyStateCode = '', companyTaxNo = '';
  dynamic data;
  bool _isLoading = true;
  bool isQrCodeKSA = false;
  bool isEsQrCodeKSA = false; //
  int printerType = 0, printerDevice = 0, printModel = 2;
  bool toggle = true;
  var eNo = 0, type = 0;
  var companyTaxMode = '';
  List<JsonTableColumn> columnsVAT, columnsGST, columns;
  CompanyInformation companySettings;
  var customerBalance = '0';
  List<CompanySettings> settings;
  VoucherType voucherTypeData;
  var dataInformation,
      dataParticularsAll = [],
      dataParticulars = [],
      dataSerialNO = [],
      purchaseExpense = [],
      otherAmount = [],
      dataLedger = [],
      dataBankLedger = [];
  Uint8List byteImage;
  int decimal = 2;
  PrintSettingsModel printSettingsModel;

  Future<Uint8List> _capturePng() async {
    try {
      // print('inside');
      RenderRepaintBoundary boundary =
          _globalKey.currentContext.findRenderObject();
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes1 = byteData.buffer.asUint8List();
      var pngBytes = resizeImage(pngBytes1);
      // var bs64 = base64Encode(pngBytes);
      // print(pngBytes);
      // print(bs64);
      // setState(() {});
      return pngBytes;
    } catch (e) {
      // print(e);
      return null;
    }
  }

  Uint8List resizeImage(Uint8List data) {
    Uint8List resizedData = data;
    images.Image img = images.decodeImage(data);
    // images.Image img1 = images.fill(0);
    images.Image resized = images.copyResize(img, width: 500, height: 500);
    resizedData = images.encodePng(resized);
    return resizedData;
  }

  var labelSerialNo = 'SerialNo';
  bool isItemSerialNo, isInvoiceDesigner = false;

  @override
  void initState() {
    super.initState();
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();

    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;
    companyState = ComSettings.getValue('COMP-STATE', settings);
    companyStateCode = ComSettings.getValue('COMP-STATECODE', settings);
    companyTaxNo = ComSettings.getValue('GST-NO', settings);
    isQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
    isEsQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
    printerType =
        ComSettings.appSettings('int', 'key-dropdown-printer-type-view', 0);
    printerDevice =
        ComSettings.appSettings('int', 'key-dropdown-printer-device-view', 0);
    printModel =
        ComSettings.appSettings('int', "key-dropdown-printer-model-view", 2);
    printLines = ComSettings.billLineValue(
        ComSettings.appSettings('int', "key-dropdown-print-line", 2));
    isItemSerialNo = ComSettings.getStatus('KEY ITEM SERIAL NO', settings);
    labelSerialNo =
        ComSettings.getValue('KEY ITEM SERIAL NO', settings).toString();
    labelSerialNo.isNotEmpty ?? 'SerialNo';
    columnsVAT = [
      JsonTableColumn("slno", label: "No"),
      JsonTableColumn("itemname", label: "Description"),
      JsonTableColumn("hsn", label: "HSN"),
      JsonTableColumn("RealRate", label: "Unit Price"),
      JsonTableColumn("Qty", label: "Qty"),
      JsonTableColumn("unitName", label: "SKU"),
      JsonTableColumn("Rate", label: "Rate"),
      JsonTableColumn("Net", label: "NetAmount"),
      JsonTableColumn("igst", label: "Tax % "),
      JsonTableColumn("IGST", label: "Tax"),
      JsonTableColumn("Total", label: "Total")
    ];
    columnsGST = [
      JsonTableColumn("slno", label: "No"),
      JsonTableColumn("itemname", label: "Description"),
      JsonTableColumn("hsn", label: "HSN"),
      JsonTableColumn("RealRate", label: "Unit Price"),
      JsonTableColumn("Qty", label: "Qty"),
      JsonTableColumn("unitName", label: "SKU"),
      JsonTableColumn("Rate", label: "Rate"),
      JsonTableColumn("Net", label: "NetAmount"),
      JsonTableColumn("igst", label: "Tax % "),
      JsonTableColumn("CGST", label: "CGST"),
      JsonTableColumn("SGST", label: "SGST"),
      JsonTableColumn("Total", label: "Total")
    ];
    columns = [
      JsonTableColumn("slno", label: "No"),
      JsonTableColumn("itemname", label: "Description"),
      JsonTableColumn("Rate", label: "Rate"),
      JsonTableColumn("Qty", label: "Qty"),
      JsonTableColumn("unitName", label: "SKU"),
      JsonTableColumn("Net", label: "NetAmount"),
      JsonTableColumn("Total", label: "Total")
    ];
    eNo = dataDynamic[0]['EntryNo'];
    type = int.parse(dataDynamic[0]['Type'].toString());

    if (printSettingsList != null) {
      if (printSettingsList.isNotEmpty) {
        printSettingsModel = printSettingsList.firstWhere(
            (element) =>
                element.model == 'INVOICE DESIGNER' &&
                element.dTransaction == 'PURCHASE RETURN' &&
                element.fyId == currentFinancialYear.id,
            orElse: () => printSettingsList.isNotEmpty
                ? printSettingsList[0]
                : PrintSettingsModel.empty());
      }
    }

    voucherTypeData = voucherTypeList.firstWhere(
      (element) => element.voucher.toLowerCase() == 'purchase return',
      orElse: () => VoucherType(
          id: 9,
          name: 'Purchase Return Entry',
          voucher: 'Purchase Return',
          abbr: 'PURCHASE RETURN',
          location: 1,
          active: 1,
          tax: 1,
          sentry: 0),
    );

    api
        .fetchPurchaseReturnInvoice(
            dataDynamic[0]['EntryNo'], '1', voucherTypeData.id)
        .then((value) {
      if (value != null) {
        setState(() {
          data = value;
          dataInformation = value['Information'][0];
          dataParticularsAll = value['Particulars'];
          dataSerialNO = value['SerialNO'];
          purchaseExpense = data['PurchaseExpense'];
          otherAmount = []; //value['otherAmount'];
          customerBalance = '0'; //data['BalanceAmount'].toString();
          dataLedger = value['ledger'];
          dataBankLedger = value['bankLedger'];
          loadAsset();
          _isLoading = false;

          List itemIdList = [];
          dataParticulars.addAll(dataParticularsAll);

          data['Particulars'] = dataParticulars;

          if (printerType == 9) {
            isInvoiceDesigner = true;
          } else {
            _createPDF(
                    printModel,
                    'Purchase_Return_ref_${dataInformation['RealEntryNo']}',
                    companySettings,
                    settings,
                    data,
                    customerBalance)
                .then((value) => pdfPath = value);
          }
        });
      }
    });
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
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 20.0,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/purchaseReturn');
            },
          ),
          title: const Text('Purchase Return View',
              style: TextStyle(fontSize: 16)),
          actions: [
            IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () {
                  setState(
                    () {
                      // Future.delayed(const Duration(milliseconds: 1000), () {
                      // _createPDF(
                      //         title +
                      //             '_ref_${dataInformation['RealEntryNo']}',
                      //         companySettings,
                      //         settings,
                      //         data,
                      //         customerBalance)
                      //     .then((value) =>
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PDFScreen(
                                pathPDF: pdfPath,
                                subject: 'Purchase Return',
                                text: 'this is Purchase Return',
                              )));
                      // );
                      // try {
                      //   debugPrint('pdf generating');
                      //   LayoutCallbackWithData builder;
                      //   PdfPageFormat pageFormat;
                      //   builder = generateInvoice;
                      //   // generateInvoice(pageFormat, data).then((value) {
                      //   //   build(context);
                      //   debugPrint('pdf generated sucess');
                      //   // });
                      // } catch (ex) {
                      //   debugPrint(ex.toString());
                      // }
                      // });
                    },
                  );
                }),
            IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  argumentsPass = {
                    'mode': 'selectedLedger',
                    'name': dataInformation['ToName'],
                    'id': dataInformation['Customer']
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
                              'Purchase_Return_ref_${dataInformation['RealEntryNo']}',
                              companySettings,
                              settings,
                              data,
                              byteImage,
                              customerBalance,
                              printerType,
                              printerDevice,
                              printModel);
                        })
                      });
                })
          ],
        ),
        body: eNo > 0
            ? isInvoiceDesigner
                ? invoiceGenerate(context)
                // : webView()
                : previewWidget()
            : const Center(child: Text('Not Found')));
  }

  Future<ui.Image> loadImage(Uint8List img) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  void loadAsset() async {
    if (isQrCodeKSA) {
      Uint8List data = (await _qr1()).buffer.asUint8List();
      byteImageQr = data;
    } else if (isEsQrCodeKSA) {
      Uint8List data = (await _qr1()).buffer.asUint8List();
      byteImageQr = data;
    }
  }

  Future<Uint8List> _qr1() async {
    var _dataQr = dataInformation = !null
        ? ''
        : SaudiConversion.getBase64(
            companySettings.name,
            '${ComSettings.getValue('GST-NO', settings)}',
            DateUtil.dateTimeQrDMY(DateUtil.datedYMD(dataInformation['DDate']) +
                ' ' +
                DateUtil.timeHMS(dataInformation['BTime'])),
            double.tryParse(dataInformation['GrandTotal'].toString())
                .toStringAsFixed(decimal),
            (double.tryParse(dataInformation['CGST'].toString()) +
                    double.tryParse(dataInformation['SGST'].toString()) +
                    double.tryParse(dataInformation['tax'].toString()))
                .toStringAsFixed(decimal));
    var qrcode = Encoder.encode(_dataQr, ErrorCorrectionLevel.h);
    var matrix = qrcode.matrix;
    var scale = 4;

    var image = img.Image(matrix.width * scale, matrix.height * scale);
    for (var x = 0; x < matrix.width; x++) {
      for (var y = 0; y < matrix.height; y++) {
        if (matrix.get(x, y) == 1) {
          img.fillRect(image, x * scale, y * scale, x * scale + scale,
              y * scale + scale, 0xFF000000);
        }
      }
    }
    return img.encodePng(image);
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
    var taxSale = dataInformation != null
        ? dataInformation['TaxType'] == 'T'
            ? true
            : false
        : false;
    var invoiceHead = Settings.getValue<String>(
        'key-purchase-return-head', 'PURCHASE RETURN');

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
                    String dataHtml = taxSale
                        ? '''
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
                            <table width="100%">
                      <tr>
                      <p><td align="left">Invoice No : ${dataInformation['InvoiceNo']}<td align="right">Date : ${DateUtil.dateDMY(dataInformation['DDate'])}</p>
                      </tr>
                            </table>
                            <h4>Bill To : ${dataInformation['ToName']}</h4>
                            <h5>${companyTaxMode == 'INDIA' ? dataInformation['Add1'] : 'T-No :' + dataInformation['gstno']}<h5/>
                            <hr size="1" width="100%">
                            <table id="items">
                        
                        ''' +
                            _itemHeader(companyTaxMode) +
                            _item(taxSale) +
                            '''<tr>
                          <td colspan="4" class="blank"><hr></hr></td>
                      </tr>
                            </table>
                            <table width="100%" id="line_total">
                              <tr>
                        <td width="64%" align="center">Total : </td>
                        <td width="8%" align="right">${totalQty.toStringAsFixed(0)}</td>
                        <td width="10%" align="right">${totalRate.toStringAsFixed(decimal)}</td>
                        <td width="10%" align="right">${double.tryParse(dataInformation['Total'].toString()).toStringAsFixed(decimal)}</td>
                              </tr>
                            </table>
                            <hr></hr>
                            <table width="100%" id="item_total">
                              <tr>
                      <td colspan="3" class="blank"></td>
                      <td colspan="2" class="total-line" align="right">Total :</td>
                      <td class="total-value" align="right">${double.tryParse(dataInformation['NetAmount'].toString()).toStringAsFixed(decimal)}</td>
                              </tr>
                              <tr>
                        <td colspan="3" class="blank"> </td>
                        <td colspan="2" class="total-line" align="right">Tax :</td>
                        <td class="total-value" align="right">${(double.tryParse(dataInformation['CGST'].toString()) + double.tryParse(dataInformation['SGST'].toString()) + double.tryParse(dataInformation['tax'].toString())).toStringAsFixed(decimal)}</td>
                              </tr>
                              <tr>
                        ''' +
                            _otherAmount() +
                            '''
                              </tr>
                              <tr>
                      <td colspan="3" class="blank"></td>
                      <td colspan="2" class="total-value1" align="right">Net Total(Inclusive of all taxes) :</td>
                          <td class="total-value" align="right">${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}</td>
                              </tr>
                            </table>
                            <table width="100%">
                      <tr>
                          <td style="font-size:10px;">${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}</td>
                        </tr>
                        </table>
                          <hr></hr>
                            <table width="100%">
                        <tr>
                        <td style="font-size:12px;" align="left"> Cash Received : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}</td>
                        <td style="font-size:12px;" align="right"> Bill Balance : ${(double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toStringAsFixed(decimal)}</td>
                        </tr>
                            </table>
                            <hr></hr>
                            <table align="center" width="100%" >
                      <tr>
                        <td style="font-size:12px;" align="left"> Old Balance : ${double.tryParse(customerBalance.toString()).toStringAsFixed(decimal)}</td>
                        <td style="font-size:12px;" align="right"> Balance : ${(double.tryParse(customerBalance) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toStringAsFixed(decimal)}</td>
                        </tr>
                            </table>
                            <hr></hr>
                            <table align="center" width="100%" >
                      <tr>
                          <td width="16.7%" align="center" style="font-size:10px;">${data['message']}</td>
                        </tr>
                            </table>
                        '''
                        : '''
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
                        </style>
                        <table width="100%">
                              <tr>
                      <th align="center"><u>$invoiceHead</u></th>
                              </tr>
                            </table>
                            <table width="100%">
                      <tr>
                      <p><td align="left">Invoice No : ${dataInformation['InvoiceNo']}<td align="right">Date : ${DateUtil.dateDMY(dataInformation['DDate'])}</p>
                      </tr>
                            </table>
                            <h4>Bill To : ${dataInformation['ToName']}</h4>
                            <hr size="1" width="100%">
                            <table id="items">
                        <tr> ''' +
                            _itemHeader1() +
                            _item(taxSale) +
                            '''<tr>
                          <td colspan="4" class="blank"><hr></hr></td>
                      </tr>
                            </table>
                            <table width="100%" id="line_total">
                              <tr>
                        <td width="64%" align="center">Total : </td>
                        <td width="8%" align="right">${totalQty.toStringAsFixed(0)}</td>
                        <td width="10%" align="right">${totalRate.toStringAsFixed(decimal)}</td>
                        <td width="10%" align="right">${double.tryParse(dataInformation['Total'].toString()).toStringAsFixed(decimal)}</td>
                              </tr>
                            </table>
                            <hr></hr>
                            <table width="100%" id="item_total">
                              <tr>
                      <td colspan="3" class="blank"></td>
                      <td colspan="2" class="total-line" align="right">Total :</td>
                      <td class="total-value" align="right">${double.tryParse(dataInformation['NetAmount'].toString()).toStringAsFixed(decimal)}</td>
                              </tr>
                              <tr>
                        <td colspan="3" class="blank"> </td>
                              </tr>
                              ''' +
                            _otherAmount() +
                            '''
                              <tr>
                                <td colspan="3" class="blank"></td>
                                <td colspan="2" class="total-value1" align="right">Tax :</td>
                                    <td class="total-value" align="right">${(double.tryParse(dataInformation['CGST'].toString()) + double.tryParse(dataInformation['SGST'].toString()) + double.tryParse(dataInformation['tax'].toString()) + double.tryParse(dataInformation['Cess'].toString()) + double.tryParse(dataInformation['TCS'].toString())).toStringAsFixed(decimal)}</td>
                              </tr>
                              <tr>
                      <td colspan="3" class="blank"></td>
                      <td colspan="2" class="total-value1" align="right">Net Total :</td>
                          <td class="total-value" align="right">${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}</td>
                              </tr>
                            </table>
                            <table width="100%">
                      <tr>
                          <td style="font-size:10px;"> Amount in Words: ${NumberToWord().convertDouble('en', double.tryParse(dataInformation['GrandTotal'].toString()))}</td>
                        </tr>
                        </table>
                        <hr></hr>
                            <table width="100%">
                        <tr>
                        <td style="font-size:10px;" align="left"> Cash Received : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}</td>
                        <td style="font-size:10px;" align="right"> Bill Balance : ${(double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toStringAsFixed(decimal)}</td>
                        </tr>
                            </table>
                            <hr></hr>
                            <table width="100%" >
                            <tr>
                        <td style="font-size:10px;" align="left"> Old Balance : ${double.tryParse(customerBalance.toString()).toStringAsFixed(decimal)}</td>
                        <td style="font-size:10px;" align="right"> Balance : ${((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toStringAsFixed(decimal)}</td>
                        </tr>
                            </table>
                            <hr></hr>
                            <table align="center" width="80%" >
                        <tr>
                          <td width="16.7%" align="center" style="font-size:9px;">${data['message']}</td>
                        </tr>
                            ''';

                    /*********************QR Code**********************/
                    if (isQrCodeKSA) {
                      if (taxSale) {
                        String html =
                            "<img src='{IMAGE_PLACEHOLDER}' style=\"float:center;margin-left:132px;width:80px;height:80px;\">\n";
                        String image = uint8ListTob64(byteImageQr);
                        html = html.replaceAll("{IMAGE_PLACEHOLDER}", image);
                        dataHtml += html;
                      } else if (isEsQrCodeKSA) {
                        String html =
                            "<img src='{IMAGE_PLACEHOLDER}' style=\"float:center;margin-left:132px;width:80px;height:80px;\">\n";
                        String image = uint8ListTob64(byteImageQr);
                        html = html.replaceAll("{IMAGE_PLACEHOLDER}", image);
                        dataHtml += html;
                      }
                    }
                    dataHtml += '''
                            </table>
                        ''';
                    contr.loadUrl(Uri.dataFromString(dataHtml,
                            mimeType: 'text/html', encoding: utf8)
                        .toString());
                  }),
            )),
          ]);
  }

  invoiceGenerate(context) {
    var taxInvoice = dataInformation != null
        ? dataInformation['TaxType'] == 'T'
            ? true
            : false
        : false;
    var invoiceHead = Settings.getValue<String>(
        'key-purchase-return-head', 'PURCHASE RETURN');
    var ledger = dataLedger[0];
    List<dynamic> itemData = [];
    double subTotalQty = 0,
        subTotalCGST = 0,
        subTotalSGST = 0,
        subTotalIGST = 0,
        subTotalRate = 0,
        subTotalDiscount = 0,
        subTotalGross = 0,
        subTotalMrp = 0;
    for (var item in dataParticulars) {
      subTotalQty += double.tryParse(item['Qty'].toString());
      subTotalRate += double.tryParse(item['PRate'].toString());
      subTotalDiscount += double.tryParse(item['Disc'].toString());
      // subTotalMrp += 0;
      subTotalCGST += double.tryParse(item['CGST'].toString());
      // subTotalIGST += double.tryParse(item['Disc'].toString());
      subTotalSGST += double.tryParse(item['SGST'].toString());
      subTotalGross += double.tryParse(item['GrossValue'].toString());

      itemData.add({
        "Barcode": item['UniqueCode'].toString() ?? '0.00',
        "ItemCode": item['ProductCode'].toString() ?? '0',
        "ItemName": item['ProductName'].toString() ?? ' ',
        "Qty": item['Qty'].toString() ?? '0',
        "Rate": item['PRate'].toString() ?? '0.00',
        "RRate": item['RealPrate'].toString() ?? '0.00',
        "Gross": item['GrossValue'].toString() ?? '0.00',
        "Disc": item['Disc'].toString() ?? '0',
        "DiscPer": item['DiscPersent'].toString() ?? '0.00',
        "RDisc": '0.00',
        "Net": item['Net'].toString() ?? '0.00',
        "CGST": item['CGST'].toString() ?? '0.00',
        "CGSTP": (double.tryParse(item['tax'].toString()) / 2)
                .toStringAsFixed(decimal) ??
            '0',
        "SGST": item['SGST'].toString() ?? '0',
        "SGSTP": (double.tryParse(item['tax'].toString()) / 2)
                .toStringAsFixed(decimal) ??
            '0',
        "IGST": '0',
        "IGSTP": '0',
        "KFC": item['Fcess'].toString() ?? '0',
        "KFCPer": "0",
        "Total": item['Total'].toString() ?? '0',
        "ItemId": item['ItemName'].toString() ?? '0',
        "SlNo": item['ItemId'].toString() ?? '0',
        "Mrp": item['PRate'].toString() ?? '0',
        "Unit": ' ',
        "CessP": item['cessper'].toString() ?? '0',
        "Cess": item['cess'].toString() ?? '0',
        "Adcess": item['adcess'].toString() ?? '0',
        "AdcessP": item['adcessper'].toString() ?? '0',
        "SerialNo": item['serialno'].toString() ?? ' ',
        "HSN": item['hsncode'].toString() ?? ' ',
        "AltQty": "ن" ?? '0',
        "RegItemName": "ييب" ?? ' ',
        "isRegItemName": "يلل" ?? ' ',
        "QtyArabic": "ث" ?? '0',
        "RateArabic": "ق" ?? '0',
        "TotalArabic": "ف" ?? '0',
        "MinQty": '0',
        "MaxQty": '0',
        "Branch": item['PRate'].toString() ?? '0',
        "LC": '0',
        "TaxPer": item['tax'].toString() ?? '0',
        "UnitCost": '0',
        "FreeQty": item['freeQty'].toString() ?? '0',
        "ScanBarcode": ' ',
        "TotalTax": '0',
        "MUltiUnitRate": '0',
        "ItemMultiBarcode": ' ',
        "EmpCode": ' ',
        "UnitId": ' ',
        "UnitValue": item['UnitValue'].toString() ?? '1',
        "Remark": item['SerialnoList'].toString() ?? ' ',
        "isRegName": false
      });
    }
    var data = {
      "fileName":
          ComSettings.removeInvDesignFilePath(printSettingsModel.filePath) ??
              ' ',
      "code": ' ',
      "id": dataInformation['EntryNo'].toString() ?? '0',
      "decimalPoint": decimal ?? 2,
      "CurrencyFormat": "##0.00",
      "printCaption": invoiceHead ?? ' ',
      "obTotal": "0.00",
      "obNetBalance": "0.00",
      "checkob": true,
      "bankifsc": ' ',
      "bankaccount": ' ',
      "bankbranch": ' ',
      "Warehousename": ' ',
      "WareHouseAdd1": ' ',
      "bill_lines": printLines ?? 12,
      "WareHouseAdd2": ' ',
      "WareHouseAdd3": ' ',
      "SiVa": ' ',
      "CIva": ' ',
      "PointThisBill": "0.00",
      "TotalPoint": "0.00",
      "CompanyName": companySettings.name ?? ' ',
      "CompanyAdd1": companySettings.add1 ?? ' ',
      "CompanyAdd2": companySettings.add2 ?? ' ',
      "CompanyAdd3": companySettings.add3 ?? ' ',
      "CompanyAdd4": companySettings.add4 ?? ' ',
      "CompanyAdd5": companySettings.add5 ?? ' ',
      "SoftwarePackage": companyTaxMode ?? ' ',
      "companyTaxNo": companyTaxNo ?? ' ',
      "CompanyMailId": companySettings.email ?? ' ',
      "CompanyTelephone": companySettings.telephone ?? ' ',
      "companyMobile": companySettings.mobile ?? ' ',
      "CompanyBank": ' ',
      "State": companyState ?? ' ',
      "StateCode": companyStateCode ?? ' ',
      "ledName": dataInformation['FromSup'].toString() ?? ' ',
      "ledAdd1": ledger['add1'] != null ? ledger['add1'].toString() : ' ',
      "ledAdd2": ledger['add2'] != null ? ledger['add2'].toString() : ' ',
      "ledAdd3": ledger['add3'] != null ? ledger['add3'].toString() : ' ',
      "ledAdd4": ledger['add4'] != null ? ledger['add4'].toString() : ' ',
      "ledTaxNo": ledger['gstno'] != null ? ledger['gstno'].toString() : ' ',
      "ledPan": ledger['pan'] != null ? ledger['pan'].toString() : ' ',
      "ledmobile": ledger['Mobile'] != null ? ledger['Mobile'].toString() : ' ',
      "ledState": ledger['state'] != null ? ledger['state'].toString() : ' ',
      "ledStateCode":
          ledger['stateCode'] != null ? ledger['stateCode'].toString() : ' ',
      "ledCperson":
          ledger['CPerson'] != null ? ledger['CPerson'].toString() : ' ',
      "ledCreditDays":
          ledger['CDays'] != null ? ledger['CDays'].toString() : '0',
      "ledMailId": ledger['Email'] != null ? ledger['Email'].toString() : ' ',
      "invoiceLetter": printSettingsModel.invoiceLetter ?? ' ',
      "invoiceNo": dataInformation['EntryNo'].toString() ?? '0',
      "invoiceSuffix": printSettingsModel.invoiceSuffix ?? ' ',
      "date": DateUtil.dateDMY(dataInformation['DDate']) ?? ' ',
      "SalesMan": ' ',
      "Narration": dataInformation['Narration'].toString() ?? ' ',
      "Location": "SHOP",
      "Project": "-1",
      "TotalGross": dataInformation['GrossValue'].toString() ?? '0',
      "TotalDisc": subTotalDiscount.toStringAsFixed(decimal) ?? '0',
      "TotalNet": subTotalGross.toStringAsFixed(decimal) ?? '0',
      "TotalCgst": subTotalCGST.toStringAsFixed(decimal) ?? '0',
      "TotalSgst": subTotalSGST.toStringAsFixed(decimal) ?? '0',
      "TotalIgst": subTotalIGST.toStringAsFixed(decimal) ?? '0',
      "TotalCess": dataInformation['Cess'].toString() ?? '0',
      "TotalKfc": "0.00",
      "TotalTotal": dataInformation['Total'].toString() ?? '0',
      "TotalQty": subTotalQty.toString() ?? '0',
      "OtherCharges": '0',
      "OtherdiscAmount": '0',
      "LoadingCharge": '0',
      "ServiceCharge": "0.00",
      "GrandTotal": dataInformation['GrandTotal'].toString() ?? '0',
      "cashpaid": '0',
      "ledgerOpeningBalance": "0.00",
      "Roundoff": dataInformation['ROUNDOFF'].toString() ?? '0',
      "Time":
          DateUtil.timeHMSA(dataInformation['DDate'].toString()) ?? '00:00:000',
      "words": ((companySettings.sCurrency.isEmpty
                  ? ' Rupees '
                  : companySettings.sCurrency) +
              ' ' +
              (companySettings.secondFont.isEmpty
                  ? (NumberToWord().convertDouble(
                          'en',
                          double.tryParse(
                              dataInformation['GrandTotal'].toString())) +
                      'Only')
                  : NumberToWord().convertDouble(
                      companySettings.secondFont,
                      double.tryParse(
                          dataInformation['GrandTotal'].toString()))) ??
          ' '),
      "purchaseExpense": ' ',
      "vehicle": ' ',
      "destination": ' ',
      "waybillno": " ",
      "pono": " ",
      "Place": " ",
      "dtissue": " ",
      "dtdespacth": " ",
      "deliverydate": "2023-08-29",
      "terms": " ",
      "JobNo": " ",
      "dName": " ",
      "dAdddress": " ",
      "dAdd1": " ",
      "dGstno": " ",
      "dState": "KERALA",
      "dStateCode": "32",
      "pointOb": "0.00",
      "systemNo": "0",
      "CurrentUserName": userNameC ?? '0',
      "ReturnAmount": '0',
      "tenderBalance": "0.00",
      "tenderCash": "0.00",
      "CardAc": "card ac",
      "CardAmount": "0.00",
      "YouHaveSaved": " ",
      "Redeem": "0",
      "Combined": "0",
      "EmiAc": " ",
      "SaudiQr": " ",
      "EmiRefNo": " ",
      "mrpTotal": "0.00",
      "TenderType": " ",
      "CheckCardDetails": false,
      "IRN": " ",
      "SignInv": " ",
      "SignQR": " ",
      "upiurl": " ",
      "TcsAmount": "0.00",
      "TcsPer": "0",
      "AckDate": " ",
      "Ackno": " ",
      "SecondName": " ",
      "dtSalesDate": " ",
      "paymentTerms": " ",
      "WarrentyTerms": " ",
      "salesEntryNo": dataInformation['EntryNo'].toString() ?? '0',
      "CheckSalesReturn": false,
      "QuotationNo": " ",
      "OtherCharges1": "0.00",
      "OtherCharges2": "0.00",
      "OtherCharges3": "0.00",
      "OtherCharges4": "0.00",
      "OtherCharges5": "0.00",
      "OtherCharges6": "0.00",
      "despathed": " ",
      "itemList": itemData
    };

    // if (kIsWeb) {
    //   try {
    //     final bytes = await pdf.save();
    //     final blob = html.Blob([bytes], 'application/pdf');
    //     final url = html.Url.createObjectUrlFromBlob(blob);
    //     final anchor = html.AnchorElement()
    //       ..href = url
    //       ..style.display = 'none'
    //       ..download = '$title.pdf';
    //     html.document.body.children.add(anchor);
    //     anchor.click();
    //     html.document.body.children.remove(anchor);
    //     html.Url.revokeObjectUrl(url);
    //     return '';
    //   } catch (ex) {
    //     ex.toString();
    //   }
    //   return '';
    // } else {
    //   var output = await getTemporaryDirectory();
    //   final file = File('${output.path}/xxx.pdf');
    //   await file.writeAsBytes(await pdf.save());
    //   return file.path.toString();
    // }

    return FutureBuilder<List<int>>(
      future: api.getInvoiceDesignerPdfData(data),
      builder: (context, AsyncSnapshot<List<int>> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data != null) {
            List<int> bytes = snapshot.data;
            if (kIsWeb) {
              try {
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
              } catch (ex) {
                ex.toString();
              }
            } else {
              pdfFunction(bytes);
            }
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text('No Data Found..'),
                  ElevatedButton(
                      onPressed: () {
                        //try agin
                      },
                      child: const Text('Select Again'))
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

  String uint8ListTob64(Uint8List uint8list) {
    String base64String = base64Encode(uint8list);
    String header = "data:image/png;base64,";
    return header + base64String;
  }

  showData() {
    var taxSale = dataInformation['TaxType'] == 'T' ? true : false;
    var invoiceHead = Settings.getValue<String>(
        'key-purchase-return-head', 'PURCHASE RETURN');
    return _isLoading
        ? const Loading()
        : taxSale
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(2.0),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    children: [
                      Text(invoiceHead,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.bold)),
                      /*company*/
                      Row(
                        children: [
                          Text(companySettings.name,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          Text(companySettings.add1 +
                              ',' +
                              companySettings.add2),
                        ],
                      ),
                      Row(
                        children: [
                          Text(companySettings.telephone +
                              ',' +
                              companySettings.mobile),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(companyTaxNo),
                          Text('Date : ' +
                              DateUtil.dateDMY(dataInformation['DDate'])),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(companySettings.pin),
                          Text('Invoice : ' + dataInformation['InvoiceNo']),
                        ],
                      ),
                      /*customer*/
                      const Text(' '),
                      Row(
                        children: [
                          const Text('BILL To :- ',
                              style: TextStyle(
                                  color: Colors.black,
                                  // fontSize: 19,
                                  fontWeight: FontWeight.bold)),
                          Text(dataInformation['ToName'],
                              style: const TextStyle(
                                  color: Colors.black,
                                  // fontSize: 19,
                                  fontWeight: FontWeight.bold))
                        ],
                      ),
                      Row(
                        children: [
                          Text((dataInformation['Add1'] +
                              ',' +
                              dataInformation['Add2'])),
                        ],
                      ),
                      companyTaxMode == 'INDIA'
                          ? Row(
                              children: [
                                Text(dataInformation['Add4']),
                              ],
                            )
                          : Row(
                              children: [
                                Text('T-No :${dataInformation['gstno']}'),
                              ],
                            ),
                      Row(
                        children: [
                          Text(dataInformation['Add3']),
                        ],
                      ),
                      JsonTable(
                        dataParticulars,
                        columns:
                            companyTaxMode == 'INDIA' ? columnsGST : columnsVAT,
                        // showColumnToggle: true,
                        allowRowHighlight: true,
                        rowHighlightColor: Colors.yellow[500].withOpacity(0.7),
                        // paginationRowCount: 4,
                        onRowSelect: (index, map) {
                          // print(index);
                          // print(map);
                        },
                      ),
                      const SizedBox(
                        height: 40.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('SUB TOTAL : ${dataInformation['GrossValue']}'),
                        ],
                      ),
                      companyTaxMode == 'INDIA'
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                    'CESS : ${double.tryParse(dataInformation['Cess'].toString()).toStringAsFixed(decimal)} CGST : ${double.tryParse(dataInformation['CGST'].toString()).toStringAsFixed(decimal)} SGST : ${double.tryParse(dataInformation['SGST'].toString()).toStringAsFixed(decimal)} = ${(double.tryParse(dataInformation['Cess'].toString()) + double.tryParse(dataInformation['CGST'].toString()) + double.tryParse(dataInformation['SGST'].toString())).toStringAsFixed(decimal)}'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('VAT : ${dataInformation['tax']}'),
                              ],
                            ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('TOTAL : ${dataInformation['GrandTotal']}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('PAID : ${dataInformation['CashReceived']}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('TOTAL DUE : ${dataInformation['GrandTotal']}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(data['message'])
                    ],
                  ),
                ))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(2.0),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    children: [
                      Text(invoiceHead,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.bold)),
                      // /*company*/
                      // Row(
                      //   children: [
                      //     Text(companySettings.name'],
                      //         style: TextStyle(
                      //             color: Colors.black,
                      //             fontSize: 22,
                      //             fontWeight: FontWeight.bold)),
                      //   ],
                      // ),
                      // Row(
                      //   children: [
                      //     Text(companySettings.add1'] +
                      //         ',' +
                      //         companySettings.add2']),
                      //   ],
                      // ),
                      // Row(
                      //   children: [
                      //     Text(companySettings.telephone'] +
                      //         ',' +
                      //         companySettings.mobile']),
                      //   ],
                      // ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Text(Settings.getValue('GST-NO', settings)),
                      //     Text('Date : ' + DateUtil.dateDMY(dataInformation['DDate'])),
                      //   ],
                      // ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Text(companySettings.pin']),
                      //     Text('Invoice : ' + dataInformation['InvoiceNo']),
                      //   ],
                      // ),
                      /*customer*/
                      // Container(child: Text(' ')
                      // ),
                      Row(
                        children: [
                          const Text('BILL To :- ',
                              style: TextStyle(
                                  color: Colors.black,
                                  // fontSize: 19,
                                  fontWeight: FontWeight.bold)),
                          Text(dataInformation['ToName'],
                              style: const TextStyle(
                                  color: Colors.black,
                                  // fontSize: 19,
                                  fontWeight: FontWeight.bold))
                        ],
                      ),
                      Row(
                        children: [
                          Text((dataInformation['Add1'] +
                              ',' +
                              dataInformation['Add2'])),
                        ],
                      ),
                      JsonTable(
                        dataParticulars,
                        columns: columns,
                        // showColumnToggle: true,
                        allowRowHighlight: true,
                        rowHighlightColor: Colors.yellow[500].withOpacity(0.7),
                        // paginationRowCount: 4,
                        onRowSelect: (index, map) {
                          // print(index);
                          // print(map);
                        },
                      ),
                      const SizedBox(
                        height: 40.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('SUB TOTAL : ${dataInformation['GrossValue']}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('TOTAL : ${dataInformation['GrandTotal']}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('PAID : ${dataInformation['CashReceived']}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('TOTAL DUE : ${dataInformation['GrandTotal']}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(data['message'])
                    ],
                  ),
                ));
  }

  _itemHeader(String tType) {
    var str = '';
    str += tType == 'INDIA'
        ? '''
    <tr>
                            <th width="64%" align="center"><b>Description</b></th>
                            <th width="8%" align="center"><b>HSN</b></th>
                            <th width="8%" align="center"><b>Qty</b></th>
                            <th width="10%" align="center"><b>Rate</b></th>
                            <th width="10%" align="center"><b>Tax%</b></th>
                            <th width="10%" align="center"><b>CGST</b></th>
                            <th width="10%" align="center"><b>SGST</b></th>
                            <th width="10%" align="center"><b>Total</b></th>
                            '''
        : '''<tr>
                            <th width="64%" align="center"><b>Description</b></th>
                            <th width="8%" align="center"><b>HSN</b></th>
                            <th width="8%" align="center"><b>Qty</b></th>
                            <th width="10%" align="center"><b>Rate</b></th>
                            <th width="10%" align="center"><b>Tax%</b></th>
                            <th width="10%" align="center"><b>Vat</b></th>
                            <th width="10%" align="center"><b>Total</b></th>''';
    return str;
  }

  _itemHeader1() {
    var str = '';
    str += isItemSerialNo
        ? '''
                            <th width="50%" align="center"><b>Description</b></th>
                            <th width="8%" align="center"><b>''' +
            labelSerialNo +
            '''</b></th>
                            <th width="8%" align="center"><b>Qty</b></th>
                            <th width="10%" align="center"><b>Rate</b></th>
                            <th width="10%" align="center"><b>Total</b></th>
                        '''
        : '''
                            <th width="64%" align="center"><b>Description</b></th>
                            <th width="8%" align="center"><b>Qty</b></th>
                            <th width="10%" align="center"><b>Rate</b></th>
                            <th width="10%" align="center"><b>Total</b></th>
                        ''';
    return str;
  }

  _item(bool taxIn) {
    var str = '';
    for (var i = 0; i < dataParticulars.length; i++) {
      str += taxIn
          ? companyTaxMode == 'INDIA'
              ? isItemSerialNo
                  ? '''
                    </tr>
                      <tr class="item-row">
                      <td width="50%" align="left">${dataParticulars[i]['ProductName']}</td>
                      <td width="10%" align="center">${dataParticulars[i]['serialno'].toString()}</td>
                      <td width="6%" align="left">${dataParticulars[i]['hsncode']}</td>
                      <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                      <td width="10%" align="right">${double.tryParse(dataParticulars[i]['PRate'].toString()).toStringAsFixed(decimal)}</td>
                      <td width="3%" align="right">${double.tryParse(dataParticulars[i]['tax'].toString()).toStringAsFixed(decimal)}</td>
                      <td width="10%" align="right">${double.tryParse(dataParticulars[i]['CGST'].toString()).toStringAsFixed(decimal)}</td>
                      <td width="10%" align="right">${double.tryParse(dataParticulars[i]['SGST'].toString()).toStringAsFixed(decimal)}</td>
                      <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                    </tr>
                    '''
                  : '''
                  </tr>
                    <tr class="item-row">
                    <td width="50%" align="left">${dataParticulars[i]['ProductName']}</td>
                    <td width="6%" align="left">${dataParticulars[i]['hsncode']}</td>
                    <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['PRate'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="3%" align="right">${double.tryParse(dataParticulars[i]['tax'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['CGST'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['SGST'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                  </tr>
                  '''
              : isItemSerialNo
                  ? '''
                  </tr>
                    <tr class="item-row">
                    <td width="50%" align="left">${dataParticulars[i]['ProductName']}</td>
                    <td width="10%" align="center">${dataParticulars[i]['serialno'].toString()}</td>
                    <td width="6%" align="left">${dataParticulars[i]['hsncode']}</td>
                    <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['PRate'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="3%" align="right">${double.tryParse(dataParticulars[i]['tax'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['tax'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                  </tr>
                  '''
                  : '''
                  </tr>
                    <tr class="item-row">
                    <td width="50%" align="left">${dataParticulars[i]['ProductName']}</td>
                    <td width="6%" align="left">${dataParticulars[i]['hsncode']}</td>
                    <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['PRate'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="3%" align="right">${double.tryParse(dataParticulars[i]['tax'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['tax'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                  </tr>
                '''
          : isItemSerialNo
              ? '''
                  </tr>
                    <tr class="item-row">
                    <td width="64%" align="left">${dataParticulars[i]['ProductName']}</td>
                    <td width="10%" align="center">${dataParticulars[i]['serialno'].toString()}</td>
                    <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['PRate'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                  </tr>
                '''
              : '''
                </tr>
                  <tr class="item-row">
                  <td width="64%" align="left">${dataParticulars[i]['ProductName']}</td>
                  <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                  <td width="10%" align="right">${double.tryParse(dataParticulars[i]['PRate'].toString()).toStringAsFixed(decimal)}</td>
                  <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                </tr>
                ''';
      totalQty += double.tryParse(dataParticulars[i]['Qty'].toString());
      totalRate += double.tryParse(dataParticulars[i]['PRate'].toString());
    }
    return str;
  }

  _otherAmount() {
    var str = ''; //Auto,symbol,LedName,Amount
    for (var i = 0; i < otherAmount.length; i++) {
      if (otherAmount[i]['Amount'].toDouble() > 0) {
        str += '''
      <tr>
        <td colspan="3" class="blank"> </td>
        <td colspan="2" class="total-line" align="right">${otherAmount[i]['LedName']} :</td>
        <td class="total-value" align="right">${otherAmount[i]['Amount']}</td>
      </tr>
      ''';
      }
    }
    return str;
  }

  Future<Uint8List> _captureQr() async {
    // print('inside');
    RenderRepaintBoundary boundary =
        _globalKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    var pngBytes = byteData.buffer.asUint8List();
    var bs64 = base64Encode(pngBytes);
    // print(pngBytes);
    // print(bs64);
    setState(() {});
    return pngBytes;
  }

  pdfFunction(List<int> bytes) async {
    try {
      final Directory appDir = await getTemporaryDirectory();
      String tempPath = appDir.path;
      final String fileName =
          DateTime.now().microsecondsSinceEpoch.toString() + '-' + 's.pdf';
      File file = File('$tempPath/$fileName');
      if (!await file.exists()) {
        await file.create();
      }
      await file.writeAsBytes(bytes);
      var path = file.path.toString();
      if (path.isNotEmpty) {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PDFScreen(
                    pathPDF: path.toString(),
                    subject: 'title',
                    text: 'this is title',
                  )));
        });
      }
    } catch (ex) {
      debugPrint(ex.toString());
    }
  }

  previewWidget() {
    var taxInvoice = dataInformation != null
        ? dataInformation['TaxType'] == 'T'
            ? true
            : false
        : false;
    var invoiceHead = Settings.getValue<String>(
        'key-purchase-return-head', 'PURCHASE RETURN');
    // companyTaxMode == 'INDIA' ? '' : '';
    double totalQuantity = dataParticulars.fold(
        0, (total, particular) => total + particular['Qty']);
    double totalTaxablevalue = dataParticulars.fold(
        0, (total, particular) => total + particular['Net'].toDouble());
    double lineTotal = dataParticulars.fold(
        0, (total, particular) => total + particular['Total'].toDouble());
    double oldBalance = double.tryParse(customerBalance).toDouble();

    double cBalance = double.tryParse(customerBalance).toDouble() ?? 0.00;
    double grandTotal =
        _isLoading ? 0 : dataInformation['GrandTotal']?.toDouble() ?? 0.00;
    // double cashReceived = _isLoading?0:dataInformation['CashReceived'].toDouble() ?? 0.00;
    double cashReceived =
        _isLoading ? 0 : (dataInformation['CashReceived']?.toDouble() ?? 0.00);

    double balance = cBalance + grandTotal - cashReceived;

    return taxInvoice
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: _isLoading
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
                  : SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            RepaintBoundary(
                              key: _globalKey,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      height: 100,
                                      width: MediaQuery.of(context).size.width,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.black, width: 2),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  companySettings.name,
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  companySettings.add1,
                                                  style: const TextStyle(
                                                      fontSize: 8),
                                                ),
                                                Text(
                                                  companySettings.add2,
                                                  style: const TextStyle(
                                                      fontSize: 8),
                                                ),
                                                Text(
                                                  companySettings.email,
                                                  style: const TextStyle(
                                                      fontSize: 8),
                                                ),
                                                Text(
                                                  companySettings.mobile,
                                                  style: const TextStyle(
                                                      fontSize: 8),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Text(
                                                "GST No : $companyTaxNo",
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                "State      : $companyState       $companyStateCode",
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 20,
                                      width: MediaQuery.of(context).size.width,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          // top: BorderSide(color: Colors.black, width: 2),
                                          right: BorderSide(
                                              color: Colors.black, width: 2),

                                          left: BorderSide(
                                              color: Colors.black, width: 2),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "PURCHASE RETURN",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 70,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 2),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                  " Invoice No        ${dataInformation['RealEntryNo']}",
                                                  style: const TextStyle(
                                                      fontSize: 6),
                                                ),
                                                Text(
                                                  " Invoice Date     ${DateUtil.dateDMY(dataInformation['DDate'])} ",
                                                  style: const TextStyle(
                                                      fontSize: 6),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 70,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                    color: Colors.black,
                                                    width: 2),
                                                right: BorderSide(
                                                    color: Colors.black,
                                                    width: 2),
                                                bottom: BorderSide(
                                                    color: Colors.black,
                                                    width: 2),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: const [
                                                Center(
                                                  child: Text(
                                                    "Transportation Mode",
                                                    style: TextStyle(
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 2,
                                                ),
                                                Text(
                                                  " Vehicle No",
                                                  style: TextStyle(fontSize: 6),
                                                ),
                                                Text(
                                                  " Date & Time of Supply",
                                                  style: TextStyle(fontSize: 6),
                                                ),
                                                Text(
                                                  " Place of Supply",
                                                  style: TextStyle(fontSize: 6),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 110,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                // top: BorderSide(color: Colors.black, width: 2),
                                                right: BorderSide(
                                                    color: Colors.black,
                                                    width: 2),
                                                bottom: BorderSide(
                                                    color: Colors.black,
                                                    width: 2),
                                                left: BorderSide(
                                                    color: Colors.black,
                                                    width: 2),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Center(
                                                  child: Text(
                                                    "Details of Receiver (Billed To)",
                                                    style: TextStyle(
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        decoration:
                                                            TextDecoration
                                                                .underline),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 2,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      " Name",
                                                      style: TextStyle(
                                                          fontSize: 6),
                                                    ),
                                                    const SizedBox(
                                                      width: 20,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        "    ${dataInformation['LedName']}",
                                                        style: const TextStyle(
                                                            fontSize: 6),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      " Address",
                                                      style: TextStyle(
                                                          fontSize: 6),
                                                    ),
                                                    const SizedBox(
                                                      width: 20,
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "${dataLedger[0]['add1']}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 6),
                                                        ),
                                                        Text(
                                                          "${dataLedger[0]['add2']}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 6),
                                                        ),
                                                        Text(
                                                          "${dataLedger[0]['add3']}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 6),
                                                        ),
                                                        Text(
                                                          "${dataLedger[0]['add4']}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 6),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 1,
                                                ),
                                                Text(
                                                  " Mobile                ${dataLedger[0]['Mobile']}",
                                                  style: const TextStyle(
                                                      fontSize: 6),
                                                ),
                                                Text(
                                                  " Sate/Code         ${dataLedger[0]['state']}        ${dataLedger[0]['stateCode']}",
                                                  style: const TextStyle(
                                                      fontSize: 6),
                                                ),
                                                Text(
                                                  " GST No              ${dataLedger[0]['gstno']}",
                                                  style: const TextStyle(
                                                      fontSize: 6),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 110,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                // top: BorderSide(color: Colors.black, width: 2),
                                                right: BorderSide(
                                                    color: Colors.black,
                                                    width: 2),
                                                bottom: BorderSide(
                                                    color: Colors.black,
                                                    width: 2),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Center(
                                                  child: Text(
                                                    "Details of Consignee (Shipped To)",
                                                    style: TextStyle(
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        decoration:
                                                            TextDecoration
                                                                .underline),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                                const Text(
                                                  " Name           ",
                                                  style: TextStyle(fontSize: 6),
                                                ),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      " Address          ",
                                                      style: TextStyle(
                                                          fontSize: 6),
                                                    ),
                                                    const SizedBox(
                                                      width: 35,
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: const [
                                                        Text(
                                                          "",
                                                          style: TextStyle(
                                                              fontSize: 6),
                                                        ),
                                                        Text(
                                                          "",
                                                          style: TextStyle(
                                                              fontSize: 6),
                                                        ),
                                                        Text(
                                                          "",
                                                          style: TextStyle(
                                                              fontSize: 6),
                                                        ),
                                                        Text(
                                                          "",
                                                          style: TextStyle(
                                                              fontSize: 6),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(),
                                          color: Colors.grey.shade300),
                                      child: Table(
                                        border: const TableBorder(
                                          horizontalInside: BorderSide
                                              .none, // Remove horizontal borders inside the table

                                          verticalInside:
                                              BorderSide(), // Keep vertical borders
                                        ),
                                        columnWidths: const {
                                          0: FixedColumnWidth(10),
                                          1: FlexColumnWidth(22),
                                          2: FlexColumnWidth(7),
                                          3: FlexColumnWidth(7),
                                          4: FlexColumnWidth(7),
                                          5: FlexColumnWidth(10),
                                          6: FlexColumnWidth(10),
                                          7: FlexColumnWidth(15),
                                          8: FlexColumnWidth(15),
                                          9: FlexColumnWidth(15),
                                          10: FlexColumnWidth(15),
                                        },
                                        children: [
                                          TableRow(children: [
                                            Center(
                                                child: Column(
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                    "No",
                                                    style: TextStyle(
                                                        fontSize: 4,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            )),
                                            const Padding(
                                              padding: EdgeInsets.all(2.0),
                                              child: Text(
                                                "Description of Goods",
                                                style: TextStyle(
                                                    fontSize: 4,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.all(2.0),
                                              child: Text(
                                                "  Hsn\n Code",
                                                style: TextStyle(
                                                    fontSize: 4,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                    'Qty',
                                                    style: TextStyle(
                                                        fontSize: 4,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.all(2.0),
                                              child: Center(
                                                child: Text(
                                                  'UOM',
                                                  style: TextStyle(
                                                      fontSize: 4,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                    '  Unit\n Price',
                                                    style: TextStyle(
                                                        fontSize: 4,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                    'Taxable\n Value',
                                                    style: TextStyle(
                                                        fontSize: 4,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Center(
                                                    child: Text(
                                                      'CGST',
                                                      style: TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Center(
                                                    child: Text(
                                                      'SGST',
                                                      style: TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Center(
                                                    child: Text(
                                                      'IGST',
                                                      style: TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                    '   Total\nAmount',
                                                    style: TextStyle(
                                                        fontSize: 5,
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration:
                                          BoxDecoration(border: Border.all()),
                                      child: Table(
                                        border: const TableBorder(
                                          horizontalInside: BorderSide
                                              .none, // Remove horizontal borders inside the table

                                          verticalInside:
                                              BorderSide(), // Keep vertical borders
                                        ),
                                        columnWidths: const {
                                          0: FixedColumnWidth(10),
                                          1: FlexColumnWidth(22),
                                          2: FlexColumnWidth(7),
                                          3: FlexColumnWidth(7),
                                          4: FlexColumnWidth(7),
                                          5: FlexColumnWidth(10),
                                          6: FlexColumnWidth(10),
                                          7: FlexColumnWidth(6),
                                          8: FlexColumnWidth(9),
                                          9: FlexColumnWidth(6),
                                          10: FlexColumnWidth(9),
                                          11: FlexColumnWidth(6),
                                          12: FlexColumnWidth(9),
                                          13: FlexColumnWidth(15),
                                        },
                                        children: [
                                          for (var i = 0;
                                              i < dataParticulars.length;
                                              i++)
                                            TableRow(children: [
                                              Center(
                                                  child: Column(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Text(
                                                      dataParticulars[i]
                                                              ['GridID']
                                                          .toString(),
                                                      style: const TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              )),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(2.0),
                                                child: Text(
                                                  dataParticulars[i]
                                                          ['ProductName']
                                                      .toString(),
                                                  style: const TextStyle(
                                                      fontSize: 4,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(2.0),
                                                child: Text(
                                                  dataParticulars[i]['hsncode'],
                                                  style: const TextStyle(
                                                      fontSize: 4,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Text(
                                                      dataParticulars[i]['Qty']
                                                          .toStringAsFixed(2),
                                                      style: const TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.all(2.0),
                                                // child: Text(
                                                //   dataParticulars[i]
                                                //       ['unitName'],
                                                //   style: const TextStyle(
                                                //       fontSize: 4,
                                                //       fontWeight:
                                                //           FontWeight.bold),
                                                // ),
                                                child: Text(""),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Text(
                                                      dataParticulars[i]
                                                              ['RealPrate']
                                                          .toStringAsFixed(2),
                                                      style: const TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Text(
                                                      '${dataParticulars[i]['Net'].toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Center(
                                                      child: Text(
                                                        '${dataParticulars[i]['tax'] / 2}%',
                                                        style: const TextStyle(
                                                            fontSize: 4,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Text(
                                                      dataParticulars[i]['CGST']
                                                          .toStringAsFixed(2),
                                                      style: const TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Center(
                                                      child: Text(
                                                        '${dataParticulars[i]['tax'] / 2}%',
                                                        style: const TextStyle(
                                                            fontSize: 4,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Text(
                                                      dataParticulars[i]['SGST']
                                                          .toStringAsFixed(2),
                                                      style: const TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(2.0),
                                                    child: Center(
                                                      child: Text(
                                                        '0%',
                                                        style: TextStyle(
                                                            fontSize: 4,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: const [
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(2.0),
                                                    child: Text(
                                                      '0.00',
                                                      style: TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Text(
                                                      dataParticulars[i]
                                                              ['Total']
                                                          .toStringAsFixed(2),
                                                      style: const TextStyle(
                                                          fontSize: 5,
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ]),
                                          if (dataParticulars.length < 10)
                                            for (var k = 0; k < 4; k++)
                                              TableRow(children: [
                                                Center(
                                                    child: Column(
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Text(
                                                        '\n',
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ],
                                                )),
                                                const Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                    "",
                                                    style: TextStyle(
                                                        fontSize: 5,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                const Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                    "",
                                                    style: TextStyle(
                                                        fontSize: 5,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Text(
                                                        "",
                                                        style: TextStyle(
                                                            fontSize: 5,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                    "",
                                                    style: TextStyle(
                                                        fontSize: 5,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Text(
                                                        "",
                                                        style: TextStyle(
                                                            fontSize: 5,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Text(
                                                        '',
                                                        style: TextStyle(
                                                            fontSize: 5,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Center(
                                                        child: Text(
                                                          '',
                                                          style: TextStyle(
                                                              fontSize: 5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Text(
                                                        "",
                                                        style: TextStyle(
                                                            fontSize: 5,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Center(
                                                        child: Text(
                                                          '',
                                                          style: TextStyle(
                                                              fontSize: 5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Text(
                                                        "",
                                                        style: TextStyle(
                                                            fontSize: 5,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Center(
                                                        child: Text(
                                                          '',
                                                          style: TextStyle(
                                                              fontSize: 5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Text(
                                                        '',
                                                        style: TextStyle(
                                                            fontSize: 5,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Text(
                                                        "",
                                                        style: TextStyle(
                                                            fontSize: 6,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ]),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(),
                                          color: Colors.grey.shade100),
                                      child: Table(
                                        border: const TableBorder(
                                          horizontalInside: BorderSide
                                              .none, // Remove horizontal borders inside the table

                                          verticalInside:
                                              BorderSide(), // Keep vertical borders
                                        ),
                                        columnWidths: const {
                                          0: FlexColumnWidth(35.4),
                                          1: FlexColumnWidth(8),
                                          2: FlexColumnWidth(18.5),
                                          3: FlexColumnWidth(11),
                                          4: FlexColumnWidth(16.5),
                                          5: FlexColumnWidth(16.5),
                                          6: FlexColumnWidth(16.5),
                                          7: FlexColumnWidth(16.5),
                                        },
                                        children: [
                                          TableRow(children: [
                                            Center(
                                                child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Text(
                                                    "Total",
                                                    style: TextStyle(
                                                        fontSize: 6,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            )),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Text(
                                                    totalQuantity
                                                        .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                        fontSize: 3,
                                                        fontWeight:
                                                            FontWeight.w900),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.all(2.0),
                                              child: Center(
                                                child: Text(
                                                  '',
                                                  style: TextStyle(
                                                      fontSize: 4,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Text(
                                                    totalTaxablevalue
                                                        .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                        fontSize: 4,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Center(
                                                    child: Text(
                                                      '${dataInformation['CGST'].toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Center(
                                                    child: Text(
                                                      '${dataInformation['SGST'].toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Center(
                                                    child: Text(
                                                      '${dataInformation['IGST'].toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                          fontSize: 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Text(
                                                    '${dataInformation['Total'].toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                        fontSize: 4,
                                                        fontWeight:
                                                            FontWeight.w900),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2,
                                            height: 102,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                // top: BorderSide(color: Colors.black, width: 2),
                                                right: BorderSide(
                                                    color: Colors.black,
                                                    width: 1),
                                                bottom: BorderSide(
                                                    color: Colors.black,
                                                    width: 1),
                                                left: BorderSide(
                                                    color: Colors.black,
                                                    width: 1),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 5.0, top: 5),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    NumberToWord().convertDouble(
                                                        'en',
                                                        double.tryParse(
                                                            dataInformation[
                                                                    'GrandTotal']
                                                                .toString())),
                                                    style: const TextStyle(
                                                        fontSize: 7,
                                                        fontWeight:
                                                            FontWeight.w900),
                                                  ),
                                                  const SizedBox(
                                                    height: 2,
                                                  ),
                                                  const Text(
                                                    "Bank Details",
                                                    style: TextStyle(
                                                        fontSize: 6,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        decoration:
                                                            TextDecoration
                                                                .underline),
                                                  ),
                                                  Column(
                                                    children: [
                                                      SizedBox(
                                                          height: 40,
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    companySettings
                                                                        .name,
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            7),
                                                                  ),
                                                                  Text(
                                                                    "${dataBankLedger[0]['name'] ?? ''}",
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            7),
                                                                  ),
                                                                  Text(
                                                                    "A/C  : ${dataBankLedger[0]['account'] ?? ''}",
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            7),
                                                                  ),
                                                                  Text(
                                                                    "IFSC : ${dataBankLedger[0]['ifsc'] ?? ''}",
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            7),
                                                                  ),
                                                                  Text(
                                                                    "${dataBankLedger[0]['branch'] ?? ''}",
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            7),
                                                                  ),
                                                                ],
                                                              ),
                                                              Visibility(
                                                                visible:
                                                                    oldBalance >
                                                                            0 ||
                                                                        balance >
                                                                            0,
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                          .only(
                                                                      right:
                                                                          10.0),
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Row(
                                                                        children: [
                                                                          const SizedBox(
                                                                            width:
                                                                                40,
                                                                            child:
                                                                                Text(
                                                                              "OB           : ",
                                                                              style: TextStyle(fontSize: 6),
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            double.tryParse(customerBalance).toStringAsFixed(decimal),
                                                                            style:
                                                                                const TextStyle(fontSize: 6),
                                                                          )
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        children: [
                                                                          const SizedBox(
                                                                            width:
                                                                                40,
                                                                            child:
                                                                                Text(
                                                                              "Balance  : ",
                                                                              style: TextStyle(fontSize: 6),
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            balance.toStringAsFixed(decimal),
                                                                            style:
                                                                                const TextStyle(fontSize: 6),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          )),
                                                    ],
                                                  ),
                                                  const Text(
                                                    "Certified that the particular given above are true and Correct",
                                                    style: TextStyle(
                                                        fontSize: 6,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2,
                                            height: 102,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                // top: BorderSide(color: Colors.black, width: 2),
                                                right: BorderSide(
                                                    color: Colors.black,
                                                    width: 1),
                                                bottom: BorderSide(
                                                    color: Colors.black,
                                                    width: 1),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                _addOtherAmountNew(otherAmount),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        height: 17,
                                                        decoration:
                                                            const BoxDecoration(
                                                          border: Border(
                                                            // top: BorderSide(color: Colors.black, width: 2),
                                                            right: BorderSide(
                                                                color: Colors
                                                                    .black,
                                                                width: 1),
                                                            bottom: BorderSide(
                                                                color: Colors
                                                                    .black,
                                                                width: 1),
                                                          ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: const [
                                                            Text(
                                                              "TCS ",
                                                              style: TextStyle(
                                                                  fontSize: 8,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        height: 17,
                                                        decoration:
                                                            const BoxDecoration(
                                                                border: Border(
                                                          // top: BorderSide(color: Colors.black, width: 2),
                                                          right: BorderSide(
                                                              color:
                                                                  Colors.black,
                                                              width: 1),
                                                          bottom: BorderSide(
                                                              color:
                                                                  Colors.black,
                                                              width: 1),
                                                        )),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              '${dataInformation['TCS'].toStringAsFixed(2)} ',
                                                              style: const TextStyle(
                                                                  fontSize: 8,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        height: 17,
                                                        decoration:
                                                            const BoxDecoration(
                                                          border: Border(
                                                            // top: BorderSide(color: Colors.black, width: 2),
                                                            right: BorderSide(
                                                                color: Colors
                                                                    .black,
                                                                width: 1),
                                                            bottom: BorderSide(
                                                                color: Colors
                                                                    .black,
                                                                width: 1),
                                                          ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: const [
                                                            Text(
                                                              "Round off ",
                                                              style: TextStyle(
                                                                  fontSize: 8,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        height: 17,
                                                        decoration:
                                                            const BoxDecoration(
                                                                border: Border(
                                                          // top: BorderSide(color: Colors.black, width: 2),
                                                          right: BorderSide(
                                                              color:
                                                                  Colors.black,
                                                              width: 1),
                                                          bottom: BorderSide(
                                                              color:
                                                                  Colors.black,
                                                              width: 1),
                                                        )),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              '${dataInformation['ROUNDOFF'].toStringAsFixed(2)} ',
                                                              style: const TextStyle(
                                                                  fontSize: 8,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        height: 17,
                                                        decoration:
                                                            const BoxDecoration(
                                                          border: Border(
                                                            // top: BorderSide(color: Colors.black, width: 2),
                                                            right: BorderSide(
                                                                color: Colors
                                                                    .black,
                                                                width: 1),
                                                            bottom: BorderSide(
                                                                color: Colors
                                                                    .black,
                                                                width: 1),
                                                          ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: const [
                                                            Text(
                                                              "Total ",
                                                              style: TextStyle(
                                                                  fontSize: 8,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        height: 17,
                                                        decoration:
                                                            const BoxDecoration(
                                                          border: Border(
                                                            // top: BorderSide(color: Colors.black, width: 2),
                                                            right: BorderSide(
                                                                color: Colors
                                                                    .black,
                                                                width: 1),
                                                            bottom: BorderSide(
                                                                color: Colors
                                                                    .black,
                                                                width: 1),
                                                          ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              "${dataInformation['GrandTotal'].toStringAsFixed(2)} ",
                                                              style: const TextStyle(
                                                                  fontSize: 7,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 3,
                                                ),
                                                Text(
                                                  companySettings.name,
                                                  style: const TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w900),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                const Text(
                                                  "Authorised Signatuory",
                                                  style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          )
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: _isLoading
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
                  : Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: SingleChildScrollView(
                          child: Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: 30,
                            decoration: BoxDecoration(
                                color: Colors.grey[300], border: Border.all()),
                            child: const Center(
                                child: Text(
                              "PURCHASE RETURN",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: 100,
                            decoration: const BoxDecoration(
                                border: Border(
                                    left: BorderSide(),
                                    right: BorderSide(),
                                    bottom: BorderSide())),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: 8,
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "  No         :",
                                      style: TextStyle(fontSize: 9),
                                    ),
                                    Text(
                                      "   ${dataInformation['InvoiceNo']}",
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "  Date      :",
                                      style: TextStyle(fontSize: 9),
                                    ),
                                    Text(
                                      "   ${DateUtil.dateDMY(dataInformation['DDate'])}",
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "  To          :",
                                      style: TextStyle(fontSize: 9),
                                    ),
                                    Text(
                                      "   ${dataInformation['ToName']}",
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.grey[300], border: Border.all()),
                            child: Table(
                              border: const TableBorder(
                                horizontalInside: BorderSide
                                    .none, // Remove horizontal borders inside the table

                                verticalInside:
                                    BorderSide(), // Keep vertical borders
                              ),
                              columnWidths: const {
                                0: FixedColumnWidth(15),
                                1: FlexColumnWidth(20),
                                2: FlexColumnWidth(10),
                                3: FlexColumnWidth(10),
                                4: FlexColumnWidth(10),
                                5: FlexColumnWidth(20),
                              },
                              children: [
                                TableRow(children: [
                                  Center(
                                      child: Column(
                                    children: const [
                                      Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Text(
                                          'No',
                                          style: TextStyle(
                                              fontSize: 6,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  )),
                                  const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Center(
                                      child: Text(
                                        'Description Of Goods',
                                        style: TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Center(
                                      child: Text(
                                        'Qty',
                                        style: TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Center(
                                      child: Text(
                                        'Unit',
                                        style: TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Center(
                                      child: Text(
                                        'Rate',
                                        style: TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Center(
                                      child: Text(
                                        'Total',
                                        style: TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(border: Border.all()),
                            child: Table(
                              border: const TableBorder(
                                horizontalInside: BorderSide
                                    .none, // Remove horizontal borders inside the table

                                verticalInside:
                                    BorderSide(), // Keep vertical borders
                              ),
                              columnWidths: const {
                                0: FixedColumnWidth(15),
                                1: FlexColumnWidth(20),
                                2: FlexColumnWidth(10),
                                3: FlexColumnWidth(10),
                                4: FlexColumnWidth(10),
                                5: FlexColumnWidth(20),
                              },
                              children: [
                                for (var i = 0; i < dataParticulars.length; i++)
                                  TableRow(children: [
                                    Center(
                                        child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Text(
                                            '${dataParticulars[i]['slno']}',
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
                                        dataParticulars[i]['itemname'],
                                        style: const TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Center(
                                        child: Text(
                                          dataParticulars[i]['Qty']
                                              .toStringAsFixed(2),
                                          style: const TextStyle(
                                              fontSize: 6,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            dataParticulars[i]['unitName']
                                                .toString(),
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
                                            dataParticulars[i]['RealRate']
                                                .toStringAsFixed(2),
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
                                            dataParticulars[i]['Total']
                                                .toStringAsFixed(2),
                                            style: const TextStyle(
                                                fontSize: 6,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]),
                                if (5 < 10)
                                  for (var k = 0; k < 8; k++)
                                    TableRow(children: [
                                      Center(
                                          child: Column(
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.all(2.0),
                                            child: Text(
                                              '\n',
                                              style: TextStyle(
                                                  fontSize: 6,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      )),
                                      const Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Text(
                                          '',
                                          style: TextStyle(
                                              fontSize: 6,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Center(
                                          child: Text(
                                            '',
                                            style: TextStyle(
                                                fontSize: 6,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: const [
                                            Text(
                                              '',
                                              style: TextStyle(
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
                                          children: const [
                                            Text(
                                              '',
                                              style: TextStyle(
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
                                          children: const [
                                            Text(
                                              '',
                                              style: TextStyle(
                                                  fontSize: 6,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                border: const Border(
                                    bottom: BorderSide(),
                                    left: BorderSide(),
                                    right: BorderSide())),
                            child: Table(
                              border: const TableBorder(
                                horizontalInside: BorderSide
                                    .none, // Remove horizontal borders inside the table

                                verticalInside:
                                    BorderSide(), // Keep vertical borders
                              ),
                              columnWidths: const {
                                0: FixedColumnWidth(15),
                                1: FlexColumnWidth(20),
                                2: FlexColumnWidth(10),
                                3: FlexColumnWidth(10),
                                4: FlexColumnWidth(10),
                                5: FlexColumnWidth(20),
                              },
                              children: [
                                TableRow(children: [
                                  Center(
                                      child: Column(
                                    children: const [
                                      Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Text(
                                          '',
                                          style: TextStyle(
                                              fontSize: 6,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  )),
                                  const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Center(
                                      child: Text(
                                        'Total',
                                        style: TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Center(
                                      child: Text(
                                        totalQuantity.toStringAsFixed(2),
                                        style: const TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Center(
                                      child: Text(
                                        '',
                                        style: TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Center(
                                      child: Text(
                                        '',
                                        style: TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${lineTotal.toStringAsFixed(2)} ',
                                          style: const TextStyle(
                                              fontSize: 6,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width / 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Amount In Words :",
                                        style: TextStyle(
                                            fontSize: 8,
                                            decoration:
                                                TextDecoration.underline),
                                      ),
                                      Text(
                                        NumberToWord().convertDouble(
                                            'en',
                                            double.tryParse(
                                                dataInformation['GrandTotal']
                                                    .toString())),
                                        style: const TextStyle(
                                          fontSize: 8,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width / 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              for (var i = 0;
                                                  i < otherAmount.length;
                                                  i++)
                                                Text(
                                                  "${otherAmount[i]['LedName']} ",
                                                  style: const TextStyle(
                                                    fontSize: 7,
                                                  ),
                                                ),
                                              const Text(
                                                "Return Amt         :",
                                                style: TextStyle(
                                                  fontSize: 8,
                                                ),
                                              ),
                                              const Text(
                                                "BILL AMOUNT    :",
                                                style: TextStyle(
                                                  fontSize: 8,
                                                ),
                                              ),
                                              const Text(
                                                "OB                       :",
                                                style: TextStyle(
                                                  fontSize: 8,
                                                ),
                                              ),
                                              const Text(
                                                "Cash Recieved   :",
                                                style: TextStyle(
                                                  fontSize: 8,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              const Text(
                                                "NET AMOUNT    :",
                                                style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              for (var i = 0;
                                                  i < otherAmount.length;
                                                  i++)
                                                Text(
                                                  "${otherAmount[i]['Amount'].toStringAsFixed(2)} ",
                                                  style: const TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              Text(
                                                "${dataInformation['ReturnAmount'].toStringAsFixed(2)} ",
                                                style: const TextStyle(
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                "${dataInformation['GrandTotal'].toStringAsFixed(2)} ",
                                                style: const TextStyle(
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                "${dataInformation['BalanceAmount'].toStringAsFixed(2)} ",
                                                style: const TextStyle(
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                "${dataInformation['CashReceived'].toStringAsFixed(2)} ",
                                                style: const TextStyle(
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Text(
                                                "${(lineTotal - dataInformation['ReturnAmount'] + otherAmount.fold(0.0, (t, e) => t + double.parse(e['Symbol'] == '-' ? (e['Amount'] * -1).toString() : e['Amount'].toString()))).toStringAsFixed(2)} ",
                                                style: const TextStyle(
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ))),
            ),
          );
  }
}

_addOtherAmountNew(List otherAmount) {
  return otherAmount.isNotEmpty && checkOtherAmountHaveValue(otherAmount)
      ? Table(
          // border: pw.TableBorder.all(width: 0.2),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
              for (var i = 0; i < otherAmount.length; i++)
                TableRow(children: [
                  Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          otherAmount[i]['LedName'] +
                              ' : ' +
                              otherAmount[i]['Amount'].toStringAsFixed(2),
                          style: const TextStyle(
                              fontSize: 5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ])
                ]),
            ])
      : Container(
          height: 15,
          decoration: const BoxDecoration(
            border: Border(
              // top: BorderSide(color: Colors.black, width: 2),
              right: BorderSide(color: Colors.black, width: 1),
              bottom: BorderSide(color: Colors.black, width: 1),
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
    var customerModel,
    int printerType,
    int printerDevice,
    int printModel) {
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
      _selectBtThermalPrint(
          context, title, companySettings, settings, data, byteImage, "4");
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
      //13: UROVO
      printUrovo([companySettings, settings, data]);
    }
  } else if (printerType == 3) {
    // 3: 'Cloud',
    //
  } else if (printerType == 4) {
    // 4: 'Document',
    if (printModel == 4)
      savePrintPDF(documentPDF);
    else
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
      _selectBtThermalPrint(
          context, title, companySettings, settings, data, byteImage, "4");
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
      //13: UROVO
      printUrovo([companySettings, settings, data]);
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
    if (printModel == 4)
      savePrintPDF(documentPDF);
    else
      printDocument(title, companySettings, settings, data, customerModel);
  }
}

Future<String> askPrintMethod(
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

List<String> newDataList = ["2", "3", "4", "5"];

_showPrinterSize(BuildContext context, title, companySettings, settings, data,
    byteImage) async {
  _asyncSimpleDialog(context).then((value) => printBluetooth(
      context, title, companySettings, settings, data, byteImage, value));
  // return await showDialog(
  //   context: context,
  //   builder: (context) => AlertDialog(
  //     title: const Text('Printer Size'),
  //     // content: const Text('Do you want to logout'),
  //     // return showDialog(
  //     //     context: context,
  //     //     builder: (context) {
  //     //       return AlertDialog(
  //     //         title: const Text('Printer Size'),
  //     content: SizedBox(
  //         width: double.minPositive,
  //         child: Expanded(
  //           child: ListView.builder(
  //             shrinkWrap: true,
  //             itemCount: newDataList == null ? 0 : newDataList?.length,
  //             itemBuilder: (BuildContext context, int index) {
  //               return ListTile(
  //                   title: Text(newDataList[index]),
  //                   onTap: () {
  //                     var bill = data['Information'][0];
  //                     var ledgerName = mainAccount
  //                         .firstWhere(
  //                           (element) =>
  //                               element['LedCode'].toString() ==
  //                               bill['Customer'].toString(),
  //                           orElse: () => {'LedName': bill['ToName']},
  //                         )['LedName']
  //                         .toString();
  //                     if (ledgerName != 'CASH') {
  //                       var a = 'Not a cash bill';
  //                       debugPrint('**************************$a');
  //                     } else {
  //                       var b = 'cash bill';
  //                       debugPrint('**************************$b');
  //                     }

  //                     printBluetooth(context, title, companySettings, settings,
  //                         data, byteImage, newDataList[index]);
  //                   });
  //             },
  //           ),
  //         )),
  //   ),
  // );
}

Future<String> _asyncSimpleDialog(BuildContext context) async {
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

_selectBtThermalPrint(
    BuildContext context,
    String title,
    CompanyInformation companySettings,
    List<CompanySettings> settings,
    data,
    byteImage,
    size) async {
  var dataAll = [companySettings, settings, data, size, "SALE"];
  // dataAll.add('Settings[' + settings + ']');b
  Navigator.push(context,
      MaterialPageRoute(builder: (_) => BlueThermalPrint(dataAll, byteImage)));
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
//   var PurchaseExpense = data['PurchaseExpense'];
//
//   var taxSale = salesTypeX.type == 'SALES-ES'
//       ? false
//       : salesTypeX.type == 'SALES-Q'
//           ? false
//           : salesTypeX.type == 'SALES-O'
//               ? false
//               : true;
// var invoiceHead = salesTypeX.type == 'SALES-ES'
//         ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
//         : salesTypeX.type == 'SALES-Q'
//             ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
//             : salesTypeX.type == 'SALES-O'
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
//   bytes += generator.text('Invoice : ' + dataInformation['InvoiceNo']);
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
//         text: '${dataParticulars[i]['ItemId']}',
//         width: 1,
//         styles: PosStyles(align: PosAlign.right),
//       ),
//       PosColumn(
//         text: dataParticulars[i]['ProductName'],
//         width: 6,
//         styles: PosStyles(align: PosAlign.center),
//       ),
//       PosColumn(
//         text: '${dataParticulars[i]['RealPrate']}',
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
//   bytes += generator.text('VAT : ${dataInformation['tax']}',
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
  CompanyInformation firm = dataAll[0];
  List<CompanySettings> settings = dataAll[1];
  var bill = dataAll[2];
  var inf = bill['Information'][0];
  var det = bill['Particulars'];
  var serialNo = bill['SerialNO'];
  var PurchaseExpense = bill['PurchaseExpense'];
  var otherAmount = bill['otherAmount'];

  var taxSale = inf['TaxType'] == 'T' ? true : false;
  var invoiceHead =
      Settings.getValue<String>('key-purchase-return-head', 'PURCHASE RETURN');
  bool isQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
  bool isEsQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
  int printCopy = Settings.getValue<int>('key-dropdown-print-copy-view', 0);
  int printerModel =
      Settings.getValue<int>('key-dropdown-printer-model-view', 0);

  bool result = await SunmiPrinterService.init();
  if (result) {
    if (taxSale) {
      await SPrinter.setAlign(sum_mi.Align.center);
      await SPrinter.setFontSize(30);
      await SPrinter.text(firm.name);
      await SPrinter.setFontSize(26);
      await SPrinter.lineWrap();
      await SPrinter.text(firm.add1);
      await SPrinter.text('Tel : ${firm.telephone + ',' + firm.mobile}');
      await SPrinter.lineWrap();
      await SPrinter.text(companyTaxMode == 'INDIA'
          ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
          : 'TRN : ${ComSettings.getValue('GST-NO', settings)}');
      await SPrinter.lineWrap();
      await SPrinter.text(invoiceHead);
      await SPrinter.setFontSize(24);
      await SPrinter.columnsText(
        [
          'Invoice No : ${inf['InvoiceNo']}',
          'Date : ${DateUtil.dateDMY(inf['DDate']) + ' ' + DateUtil.timeHMSA(inf['BTime'])}'
        ],
        width: [18, 19],
        align: [1, 1],
      );
      await SPrinter.lineWrap();
      await SPrinter.text('Bill To : ${inf['ToName']}');
      await SPrinter.setAlign(sum_mi.Align.left);
      await SPrinter.setFontSize(20);
      if (inf['gstno'].toString().trim().isNotEmpty) {
        await SPrinter.text(companyTaxMode == 'INDIA'
            ? 'GSTNO : ${inf['gstno'].toString().trim()}'
            : 'TRN : ${inf['gstno'].toString().trim()}');
      }
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
          det[i]['ProductName'],
          det[i]['Qty'].toString(),
          det[i]['PRate'].toString(),
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
    } else {
      if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
        await SPrinter.setAlign(sum_mi.Align.center);
        await SPrinter.setFontSize(30);
        await SPrinter.text(firm.name);
        await SPrinter.setFontSize(26);
        await SPrinter.lineWrap();
        await SPrinter.text(firm.add1);
        await SPrinter.text('Tel : ${firm.telephone + ',' + firm.mobile}');
        await SPrinter.lineWrap();
        await SPrinter.text(companyTaxMode == 'INDIA'
            ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
            : 'TRN : ${ComSettings.getValue('GST-NO', settings)}');
        await SPrinter.lineWrap();
        await SPrinter.text(invoiceHead);
        await SPrinter.setFontSize(24);
        await SPrinter.columnsText(
          [
            'Invoice No : ${inf['InvoiceNo']}',
            'Date : ${DateUtil.dateDMY(inf['DDate']) + ' ' + DateUtil.timeHMSA(inf['BTime'])}'
          ],
          width: [18, 19],
          align: [1, 1],
        );
      } else {
        await SPrinter.setAlign(sum_mi.Align.center);
        await SPrinter.setFontSize(26);
        await SPrinter.text(invoiceHead);
        await SPrinter.setFontSize(24);
        await SPrinter.columnsText(
          [
            'Invoice No : ${inf['InvoiceNo']}',
            'Date : ${DateUtil.dateDMY(inf['DDate']) + ' ' + DateUtil.timeHMSA(inf['BTime'])}'
          ],
          width: [18, 19],
          align: [1, 1],
        );
      }
      await SPrinter.lineWrap();
      await SPrinter.text('Bill To : ${inf['ToName']}');
      await SPrinter.setAlign(sum_mi.Align.left);
      await SPrinter.setFontSize(20);
      if (isEsQrCodeKSA) {
        if (inf['gstno'].toString().trim().isNotEmpty) {
          await SPrinter.text(companyTaxMode == 'INDIA'
              ? 'GSTNO : ${inf['gstno'].toString().trim()}'
              : 'TRN : ${inf['gstno'].toString().trim()}');
        }
      }
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
          det[i]['ProductName'],
          det[i]['Qty'].toString(),
          det[i]['PRate'].toString(),
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
    }
    for (var i = 0; i < otherAmount.length; i++) {
      if (otherAmount[i]['Amount'].toDouble() > 0) {
        await SPrinter.lineWrap();
        await SPrinter.columnsText(
          ['${otherAmount[i]['LedName']} :', '${otherAmount[i]['Amount']}'],
          width: [16, 16],
          align: [0, 2],
        );
      }
    }
    await SPrinter.lineWrap();
    await SPrinter.setAlign(sum_mi.Align.right);
    await SPrinter.setFontSize(27);
    await SPrinter.columnsText(
      [
        "Net Amount :",
        double.tryParse(inf['GrandTotal'].toString()).toStringAsFixed(2)
      ],
      width: [16, 16],
      align: [0, 2],
    );
    await SPrinter.lineWrap();
    await SPrinter.setFontSize(22);
    var balance = (double.tryParse(inf['Balance'].toString()) -
                double.tryParse(inf['GrandTotal'].toString())) >
            0
        ? (double.tryParse(inf['Balance'].toString()) -
                double.tryParse(inf['GrandTotal'].toString()))
            .toString()
        : '0';
    await SPrinter.lineWrap();
    await SPrinter.text(
        'Received : ${inf['CashReceived']} / Balance : ${(double.tryParse(balance)) + (double.tryParse(inf['GrandTotal'].toString()) - double.tryParse(inf['CashReceived'].toString()))}');
    await SPrinter.lineWrap();
    await SPrinter.setAlign(sum_mi.Align.center);
    await SPrinter.setFontSize(20);
    await SPrinter.text(bill['message']);
    await SPrinter.lineWrap();
    if (isQrCodeKSA) {
      if (taxSale) {
        await SPrinter.qrCode(SaudiConversion.getBase64(
            firm.name,
            ComSettings.getValue('GST-NO', settings),
            DateUtil.dateTimeQrDMY(DateUtil.datedYMD(inf['DDate']) +
                ' ' +
                DateUtil.timeHMS(inf['BTime'])),
            double.tryParse(inf['GrandTotal'].toString()).toStringAsFixed(2),
            (double.tryParse(inf['CGST'].toString()) +
                    double.tryParse(inf['SGST'].toString()) +
                    double.tryParse(inf['tax'].toString()))
                .toStringAsFixed(2)));
      }
    } else if (isEsQrCodeKSA) {
      await SPrinter.qrCode(SaudiConversion.getBase64(
          firm.name,
          ComSettings.getValue('GST-NO', settings),
          DateUtil.dateTimeQrDMY(DateUtil.datedYMD(inf['DDate']) +
              ' ' +
              DateUtil.timeHMS(inf['BTime'])),
          double.tryParse(inf['GrandTotal'].toString()).toStringAsFixed(2),
          (double.tryParse(inf['CGST'].toString()) +
                  double.tryParse(inf['SGST'].toString()) +
                  double.tryParse(inf['tax'].toString()))
              .toStringAsFixed(2)));
    }
    await SPrinter.lineWrap(3);
  }
}

void printSunmiV2(dataAll) async {
  CompanyInformation firm = dataAll[0];
  List<CompanySettings> setting = dataAll[1];
  var bill = dataAll[2];
  var inf = bill['Information'][0];
  var det = bill['Particulars'];
  var serialNo = bill['SerialNO'];
  var PurchaseExpense = bill['PurchaseExpense'];
  var otherAmount = bill['otherAmount'];

  SunmiPrinter.hr();
  SunmiPrinter.text(
    firm.name,
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
    firm.add1,
    styles: const SunmiStyles(align: SunmiAlign.center),
  );
  SunmiPrinter.text(
    'Tel : ${firm.telephone + ',' + firm.mobile}',
    styles: const SunmiStyles(align: SunmiAlign.center),
  );
  SunmiPrinter.emptyLines(1);
  await SPrinter.text(companyTaxMode == 'INDIA'
      ? 'GSTNO : ${ComSettings.getValue('GST-NO', setting)}'
      : 'TRN : ${ComSettings.getValue('GST-NO', setting)}');
  await SPrinter.lineWrap();
  await SPrinter.setFontSize(24);
  await SPrinter.text('Invoice No : ${inf['InvoiceNo']}');
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
      det[i]['ProductName'],
      det[i]['Qty'].toString(),
      det[i]['PRate'].toString(),
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
  var balance = (double.tryParse(inf['Balance'].toString()) -
              double.tryParse(inf['GrandTotal'].toString())) >
          0
      ? (double.tryParse(inf['Balance'].toString()) -
              double.tryParse(inf['GrandTotal'].toString()))
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
      'Received : ${inf['CashReceived']} / Balance : ${(double.tryParse(balance)) + (double.tryParse(inf['GrandTotal'].toString()) - double.tryParse(inf['CashReceived'].toString()))}');
  await SPrinter.lineWrap();
  await SPrinter.setAlign(sum_mi.Align.center);
  await SPrinter.setFontSize(20);
  await SPrinter.text(bill['message']);
  await SPrinter.lineWrap(3);
}

const channel = MethodChannel('sherAccChannel');

void printUrovo(dataAll) async {
  CompanyInformation firm = dataAll[0];
  var settings = dataAll[1];
  var bill = dataAll[2];
  var inf = bill['Information'][0];
  var det = bill['Particulars'];
  var serialNo = bill['SerialNO'];
  var PurchaseExpense = bill['PurchaseExpense'];
  var otherAmount = bill['otherAmount'];

  bool taxSale = inf['TaxType'] == 'T' ? true : false;
  var invoiceHead =
      Settings.getValue<String>('key-purchase-return-head', 'PURCHASE RETURN');
  bool isQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
  bool isEsQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
  int printCopy = Settings.getValue<int>('key-dropdown-print-copy-view', 0);
  int printerModel =
      Settings.getValue<int>('key-dropdown-printer-model-view', 0);

  bool result = await channel.invokeMethod('PrinterUrovoAppInstalled') ?? false;
  // if (result) {
  //   await printText("This is Text Message\n\n", 14, false, false, posPrinter);
  //   await lineWrap(14, posPrinter);
  // }
  if (result) {
    String balance = (double.tryParse(inf['Balance'].toString()) -
                double.tryParse(inf['GrandTotal'].toString())) >
            0
        ? (double.tryParse(inf['Balance'].toString()) -
                double.tryParse(inf['GrandTotal'].toString()))
            .toString()
        : '0';
    String qrCode = isQrCodeKSA
        ? taxSale
            ? SaudiConversion.getBase64(
                settings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(DateUtil.datedYMD(inf['DDate']) +
                    ' ' +
                    DateUtil.timeHMS(inf['BTime'])),
                double.tryParse(inf['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(inf['CGST'].toString()) +
                        double.tryParse(inf['SGST'].toString()) +
                        double.tryParse(inf['tax'].toString()))
                    .toStringAsFixed(2))
            : ''
        : isEsQrCodeKSA
            ? SaudiConversion.getBase64(
                settings.name,
                ComSettings.getValue('GST-NO', settings),
                DateUtil.dateTimeQrDMY(DateUtil.datedYMD(inf['DDate']) +
                    ' ' +
                    DateUtil.timeHMS(inf['BTime'])),
                double.tryParse(inf['GrandTotal'].toString())
                    .toStringAsFixed(2),
                (double.tryParse(inf['CGST'].toString()) +
                        double.tryParse(inf['SGST'].toString()) +
                        double.tryParse(inf['tax'].toString()))
                    .toStringAsFixed(2))
            : '';
    // var contentx = {
    //   'taxSale': taxSale,
    //   'invoiceHead': invoiceHead,
    //   'isQrCodeKSA': isQrCodeKSA,
    //   'isEsQrCodeKSA': isEsQrCodeKSA,
    //   'printCopy': printCopy,
    //   'printerModel': printerModel,
    //   'companyTaxMode': companyTaxMode,
    //   'taxNo': ComSettings.getValue('GST-NO', settings),
    //   'companyInfo': json.encode(firm),
    //   'information': json.encode(inf),
    //   'particulars': json.encode(det),
    //   'serialNo': json.encode(serialNo),
    //   'PurchaseExpense': json.encode(PurchaseExpense),
    //   'otherAmount': json.encode(otherAmount),
    //   'printHeaderInEs':
    //       ComSettings.appSettings('bool', 'key-print-header-es', false),
    //   'balance': balance,
    //   'message': bill['message'],
    //   'qrCode': qrCode,
    // };
    // var content = SalesBillData(
    //     taxSale: taxSale,
    //     invoiceHead: invoiceHead,
    //     isQrCodeKsa: isQrCodeKSA,
    //     isEsQrCodeKsa: isEsQrCodeKSA,
    //     printCopy: printCopy,
    //     printerModel: printerModel,
    //     companyTaxMode: companyTaxMode,
    //     taxNo: ComSettings.getValue('GST-NO', settings),
    //     companyInfo: [
    //       CompanyInfo(
    //           name: firm.name,
    //           add1: firm.add1,
    //           add2: firm.add2,
    //           add3: firm.add3,
    //           add4: firm.add4,
    //           add5: firm.add5,
    //           sName: firm.sName,
    //           telephone: firm.telephone,
    //           email: firm.email,
    //           mobile: firm.mobile,
    //           tin: firm.tin,
    //           pin: firm.pin,
    //           taxCalculation: firm.taxCalculation,
    //           sCurrency: firm.sCurrency,
    //           sDate: firm.sDate,
    //           eDate: firm.eDate,
    //           customerCode: firm.customerCode,
    //           runningDate: firm.runningDate)
    //     ],
    //     information: [
    //       BillInformation(
    //           dDate: inf['DDate'],
    //           bTime: inf["BTime"],
    //           invoiceNo: inf["InvoiceNo"],
    //           entryNo: inf["EntryNo"],
    //           realEntryNo: inf["RealEntryNo"],
    //           customer: inf["Customer"],
    //           toName: inf["ToName"],
    //           add1: inf["Add1"],
    //           add2: inf["Add2"],
    //           add3: inf["Add3"],
    //           add4: inf["Add4"],
    //           grossValue: double.tryParse(inf["GrossValue"].toString()) ?? 0,
    //           discount: double.tryParse(inf["Discount"].toString()) ?? 0,
    //           netAmount: double.tryParse(inf["NetAmount"].toString()) ?? 0,
    //           cess: double.tryParse(inf["cess"].toString()) ?? 0,
    //           total: double.tryParse(inf["Total"].toString()) ?? 0,
    //           loadingCharge:
    //               double.tryParse(inf["loadingCharge"].toString()) ?? 0,
    //           otherCharges:
    //               double.tryParse(inf["OtherCharges"].toString()) ?? 0,
    //           otherDiscount:
    //               double.tryParse(inf["OtherDiscount"].toString()) ?? 0,
    //           roundoff: double.tryParse(inf["Roundoff"].toString()) ?? 0,
    //           grandTotal: double.tryParse(inf["GrandTotal"].toString()) ?? 0,
    //           narration: inf["Narration"],
    //           profit: double.tryParse(inf["Profit"].toString()) ?? 0,
    //           cashReceived:
    //               double.tryParse(inf["CashReceived"].toString()) ?? 0,
    //           cgst: double.tryParse(inf["CGST"].toString()) ?? 0,
    //           sgst: double.tryParse(inf["SGST"].toString()) ?? 0,
    //           igst: double.tryParse(inf["IGST"].toString()) ?? 0,
    //           returnAmount:
    //               double.tryParse(inf["ReturnAmount"].toString()) ?? 0,
    //           returnNo: inf["ReturnNo"],
    //           balanceAmount:
    //               double.tryParse(inf["BalanceAmount"].toString()) ?? 0,
    //           balance: double.tryParse(inf["Balance"].toString()) ?? 0,
    //           gstno: inf["gstno"])
    //     ],
    //     particulars: Particular.fromJsonListDynamic(det),
    //     serialNo: SerialNOModel.fromJsonListDynamic(serialNo),
    //     purchaseExpense: PurchaseExpenseModel.fromJsonListDynamic(deliveryNote),
    //     otherAmount: BillOtherAmount.fromJsonListDynamic(otherAmount),
    //     printHeaderInEs:
    //         ComSettings.appSettings('bool', 'key-print-header-es', false),
    //     balance: balance,
    //     message: bill['message'],
    //     qrCode: qrCode);

    // if (taxSale) {
    //   await printText(firm['name'], 18, true, false, posPrinter);
    //   await printText(firm['add1'], 14, true, false, posPrinter);
    //   await printText('Tel : ${firm['telephone'] + ',' + firm['mobile']}', 14,
    //       true, false, posPrinter);
    //   await printText(
    //       companyTaxMode == 'INDIA'
    //           ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
    //           : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
    //       14,
    //       true,
    //       false,
    //       posPrinter);
    //   await printText(invoiceHead, 16, true, false, posPrinter);
    //   await printColumnsText(
    //       sprintf("%s %s", {
    //         'Invoice No : ${inf['InvoiceNo']}',
    //         'Date : ${DateUtil.dateDMY(inf['DDate']) + ' ' + DateUtil.timeHMSA(inf['BTime'])}'
    //       }),
    //       14,
    //       false,
    //       false,
    //       posPrinter);
    //   await printText(
    //       'Bill To : ${inf['ToName']}', 14, false, false, posPrinter);
    //   if (inf['gstno'].toString().trim().isNotEmpty) {
    //     await printText(
    //         companyTaxMode == 'INDIA'
    //             ? 'GSTNO : ${inf['gstno'].toString().trim()}'
    //             : 'TRN : ${inf['gstno'].toString().trim()}',
    //         14,
    //         false,
    //         false,
    //         posPrinter);
    //   }
    //   await lineWrap(14, posPrinter);
    //   //'column'
    //   await printColumnsText(
    //       sprintf("%s %s %s %s", {"Description", "Qty", "Price", "Total"}),
    //       14,
    //       true,
    //       false,
    //       posPrinter);
    //   for (var i = 0; i < det.length; i++) {
    //     await printColumnsText(
    //         sprintf("%s %f %f %f", {
    //           det[i]['ProductName'],
    //           det[i]['Qty'].toString(),
    //           det[i]['PRate'].toString(),
    //           det[i]['Total'].toString()
    //         }),
    //         14,
    //         false,
    //         false,
    //         posPrinter);
    //   }
    // } else {
    //   if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
    //     // await printText(posPrinter.setAlign(sum_mi.Align.center);
    //     // await posPrinter.setFontSize(30);
    //     await printText(firm['name'], 18, true, false, posPrinter);
    //     await printText(firm['add1'], 14, true, false, posPrinter);
    //     await printText('Tel : ${firm['telephone'] + ',' + firm['mobile']}', 14,
    //         true, false, posPrinter);
    //     await printText(
    //         companyTaxMode == 'INDIA'
    //             ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
    //             : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
    //         14,
    //         true,
    //         false,
    //         posPrinter);
//
    //     await printText(
    //         'Invoice No : ${inf['InvoiceNo']}    Date : ${DateUtil.dateDMY(inf['DDate']) + ' ' + DateUtil.timeHMSA(inf['BTime'])}',
    //         14,
    //         true,
    //         false,
    //         posPrinter);
    //   } else {
    //     await printText(
    //         'Invoice No : ${inf['InvoiceNo']}    Date : ${DateUtil.dateDMY(inf['DDate']) + ' ' + DateUtil.timeHMSA(inf['BTime'])}',
    //         14,
    //         true,
    //         false,
    //         posPrinter);
    //   }
    //   await printText(
    //       'Bill To : ${inf['ToName']}', 14, true, false, posPrinter);
    //   if (isEsQrCodeKSA) {
    //     if (inf['gstno'].toString().trim().isNotEmpty) {
    //       await printText(
    //           companyTaxMode == 'INDIA'
    //               ? 'GSTNO : ${inf['gstno'].toString().trim()}'
    //               : 'TRN : ${inf['gstno'].toString().trim()}',
    //           14,
    //           true,
    //           false,
    //           posPrinter);
    //     }
    //   }
    //   await printColumnsText(
    //       sprintf("%s %s %s %s", {"Description", "Qty", "Price", "Total"}),
    //       14,
    //       true,
    //       false,
    //       posPrinter);
    //   await lineWrap(32, posPrinter);
    //   for (var i = 0; i < det.length; i++) {
    //     await printColumnsText(
    //         sprintf("%s %f %f %f", {
    //           det[i]['ProductName'],
    //           det[i]['Qty'].toString(),
    //           det[i]['PRate'].toString(),
    //           det[i]['Total'].toString()
    //         }),
    //         14,
    //         false,
    //         false,
    //         posPrinter);
    //   }
    // }
    // lineWrap(32, posPrinter);
    // for (var i = 0; i < otherAmount.length; i++) {
    //   if (otherAmount[i]['Amount'].toDouble() > 0) {
    //     await printColumnsText(
    //         sprintf("%s %f", {
    //           "${otherAmount[i]['LedName']} :",
    //           "${otherAmount[i]['Amount']}"
    //         }),
    //         14,
    //         false,
    //         false,
    //         posPrinter);
    //   }
    // }
    // await lineWrap(32, posPrinter);
    // await printColumnsText(
    //     sprintf("%s %f", {
    //       "Net Amount :",
    //       double.tryParse(inf['GrandTotal'].toString()).toStringAsFixed(2)
    //     }),
    //     14,
    //     false,
    //     false,
    //     posPrinter);
    // var balance = (double.tryParse(inf['Balance'].toString()) -
    //             double.tryParse(inf['GrandTotal'].toString())) >
    //         0
    //     ? (double.tryParse(inf['Balance'].toString()) -
    //             double.tryParse(inf['GrandTotal'].toString()))
    //         .toString()
    //     : '0';
    // await lineWrap(32, posPrinter);
    // await printText(
    //     'Received : ${inf['CashReceived']} / Balance : ${(double.tryParse(balance)) + (double.tryParse(inf['GrandTotal'].toString()) - double.tryParse(inf['CashReceived'].toString()))}',
    //     14,
    //     false,
    //     false,
    //     posPrinter);
    // await printText(bill['message'], 14, false, false, posPrinter);
    // if (isQrCodeKSA) {
    //   if (taxSale) {
    //     await posPrinter.qrCode(SaudiConversion.getBase64(
    //         settings.name,
    //         ComSettings.getValue('GST-NO', settings),
    //         DateUtil.dateTimeQrDMY(DateUtil.datedYMD(inf['DDate']) +
    //             ' ' +
    //             DateUtil.timeHMS(inf['BTime'])),
    //         double.tryParse(inf['GrandTotal'].toString()).toStringAsFixed(2),
    //         (double.tryParse(inf['CGST'].toString()) +
    //                 double.tryParse(inf['SGST'].toString()) +
    //                 double.tryParse(inf['tax'].toString()))
    //             .toStringAsFixed(2)));
    //   }
    // } else if (isEsQrCodeKSA) {
    //   await posPrinter.qrCode(SaudiConversion.getBase64(
    //       settings.name,
    //       ComSettings.getValue('GST-NO', settings),
    //       DateUtil.dateTimeQrDMY(DateUtil.datedYMD(inf['DDate']) +
    //           ' ' +
    //           DateUtil.timeHMS(inf['BTime'])),
    //       double.tryParse(inf['GrandTotal'].toString()).toStringAsFixed(2),
    //       (double.tryParse(inf['CGST'].toString()) +
    //               double.tryParse(inf['SGST'].toString()) +
    //               double.tryParse(inf['tax'].toString()))
    //           .toStringAsFixed(2)));
    // }
    // await lineWrap(32, posPrinter);
    // await lineWrap(32, posPrinter);
    // await lineWrap(32, posPrinter);
    // await lineWrap(32, posPrinter);

    try {
      // var b = salesBillDataToMap([content]);
      // var c = content.toJson();
      // var status = await channel
      //     .invokeMethod('sentPrintUrovo', <String, String>{'content': c});
      // debugPrint('Print finished' + status.ToString());
    } catch (ex) {
      debugPrint('errrr:' + ex.ToString());
    }
  } else {
    debugPrint('Printer app not installed');
  }
}

void printSunmiV2Test(dataAll) async {
  var bill = dataAll[2];
  var dataInformation = bill['Information'][0];
  var dataParticulars = bill['Particulars'];
  var dataSerialNO = bill['SerialNO'];
  var PurchaseExpense = bill['PurchaseExpense'];
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
    int model,
    String title,
    CompanyInformation companySettings,
    List<CompanySettings> settings,
    var data,
    var customerBalance) async {
  return makePDF(model, title, companySettings, settings, data, customerBalance)
      .then((value) => savePreviewPDF(value, title));
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

Future<pw.Document> makePDF(
    int model,
    String title,
    CompanyInformation companySettings,
    List<CompanySettings> settings,
    var data,
    var customerBalance) async {
  var dataInformation = data['Information'][0];
  var dataParticulars = data['Particulars'];
  // var dataSerialNO = data['SerialNO'];
  var PurchaseExpense = data['PurchaseExpense'];
  var otherAmount = data['otherAmount'];
  var dataLedger = data['ledger'][0];
  var dataBankLedger = data['bankLedger'][0];

  bool printHeaderOnES =
      ComSettings.appSettings('bool', 'key-print-header-es', false);
  var taxSale = dataInformation['TaxType'] == 'T' ? true : false;
  var invoiceHead =
      Settings.getValue<String>('key-purchase-return-head', 'PURCHASE RETURN');
  int decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
      ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
      : 2;
  bool isItemSerialNo = ComSettings.getStatus('KEY ITEM SERIAL NO', settings);
  var labelSerialNo =
      ComSettings.getValue('KEY ITEM SERIAL NO', settings).toString();
  labelSerialNo.isNotEmpty ?? 'SerialNo';
  var tableHeaders = taxSale
      ? companyTaxMode == 'INDIA'
          ? isItemSerialNo
              ? [
                  "No",
                  "Description",
                  "HSN",
                  "Unit Price",
                  "Qty",
                  labelSerialNo,
                  "Rate",
                  "NetAmount",
                  "Tax % ",
                  "CGST",
                  "SGST",
                  "Total"
                ]
              : [
                  "No",
                  "Description",
                  "HSN",
                  "Unit Price",
                  "Qty",
                  "SKU",
                  "Rate",
                  "NetAmount",
                  "Tax % ",
                  "CGST",
                  "SGST",
                  "Total"
                ]
          : isItemSerialNo
              ? [
                  "No",
                  "Description",
                  "HSN",
                  "Unit Price",
                  "Qty",
                  labelSerialNo,
                  "Rate",
                  "NetAmount",
                  "Tax % ",
                  "VAT",
                  "Total"
                ]
              : [
                  "No",
                  "Description",
                  "HSN",
                  "Unit Price",
                  "Qty",
                  "SKU",
                  "Rate",
                  "NetAmount",
                  "Tax % ",
                  "VAT",
                  "Total"
                ]
      : isItemSerialNo
          ? ["No", "Description", "Rate", "Qty", labelSerialNo, "Total"]
          : ["No", "Description", "Unit Price", "Qty", "SKU", "Total"];

  final imageQr = byteImageQr != null
      ? pw.MemoryImage(Uint8List.fromList(byteImageQr))
      : null;

  final pdf = pw.Document();
  var _pageFormat = PdfPageFormat.a4;

  // if (model == 2) {
  //   taxSale
  //       ? pdf.addPage(pw.MultiPage(
  //           /*company*/
  //           maxPages: 100,
  //           header: (context) => pw.Column(children: [
  //                 pw.Row(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.center,
  //                     children: [
  //                       pw.Expanded(
  //                           child: pw.Column(children: [
  //                         pw.Container(
  //                           height: 20,
  //                           padding: const pw.EdgeInsets.all(8),
  //                           alignment: pw.Alignment.center,
  //                           child: pw.Text(
  //                             invoiceHead,
  //                             style: pw.TextStyle(
  //                               fontWeight: pw.FontWeight.bold,
  //                               fontSize: 25,
  //                             ),
  //                           ),
  //                         ),
  //                         pw.Container(
  //                             height: 80,
  //                             padding: const pw.EdgeInsets.all(8),
  //                             alignment: pw.Alignment.center,
  //                             child: pw.RichText(
  //                                 textAlign: pw.TextAlign.center,
  //                                 text: pw.TextSpan(
  //                                     text: '${companySettings.name}\n',
  //                                     style: pw.TextStyle(
  //                                       // color: _darkColor,
  //                                       fontWeight: pw.FontWeight.bold,
  //                                       fontSize: 15,
  //                                     ),
  //                                     children: [
  //                                       const pw.TextSpan(
  //                                         text: '\n',
  //                                         style: pw.TextStyle(
  //                                           fontSize: 5,
  //                                         ),
  //                                       ),
  //                                       pw.TextSpan(
  //                                           text: companySettings.add2
  //                                                   .toString()
  //                                                   .isEmpty
  //                                               ? companySettings.add1
  //                                               : companySettings.add1 +
  //                                                   '\n' +
  //                                                   companySettings.add2,
  //                                           style: pw.TextStyle(
  //                                             fontWeight: pw.FontWeight.bold,
  //                                             fontSize: 10,
  //                                           ),
  //                                           children: [
  //                                             companySettings.telephone
  //                                                     .toString()
  //                                                     .isNotEmpty
  //                                                 ? pw.TextSpan(
  //                                                     text: companySettings
  //                                                         .telephone,
  //                                                     children: [
  //                                                         companySettings.mobile
  //                                                                 .toString()
  //                                                                 .isNotEmpty ??
  //                                                             pw.TextSpan(
  //                                                                 text: ', ' +
  //                                                                     companySettings
  //                                                                         .mobile),
  //                                                       ])
  //                                                 : const pw.TextSpan(
  //                                                     text: '\n',
  //                                                     style: pw.TextStyle(
  //                                                       fontSize: 5,
  //                                                     ),
  //                                                   ),
  //                                           ]),
  //                                       pw.TextSpan(
  //                                         text:
  //                                             '${ComSettings.getValue('GST-NO', settings)}',
  //                                         style: pw.TextStyle(
  //                                           fontWeight: pw.FontWeight.bold,
  //                                           fontSize: 10,
  //                                         ),
  //                                       ),
  //                                     ]))),
  //                         pw.Container(
  //                           padding: const pw.EdgeInsets.all(10),
  //                           alignment: pw.Alignment.center,
  //                           height: 10,
  //                           child: pw.GridView(
  //                             crossAxisCount: 2,
  //                             children: [
  //                               pw.Text(
  //                                   'Invoice : ' + dataInformation['InvoiceNo'],
  //                                   style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold,
  //                                     fontSize: 10,
  //                                   ),
  //                                   textAlign: pw.TextAlign.left),
  //                               pw.Text(
  //                                   'Date : ' +
  //                                       DateUtil.dateDMY(
  //                                           dataInformation['DDate']),
  //                                   style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold,
  //                                     fontSize: 10,
  //                                   ),
  //                                   textAlign: pw.TextAlign.right),
  //                             ],
  //                           ),
  //                         ),
  //                       ])),
  //                     ]),
  //                 if (context.pageNumber > 1) pw.SizedBox(height: 20)
  //               ]),
  //           build: (context) => [
  //                 /*customer*/
  //                 pw.Row(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                     children: [
  //                       pw.Container(
  //                         margin: const pw.EdgeInsets.only(left: 10, right: 10),
  //                         height: 70,
  //                         child: pw.Text(
  //                           'Bill to:',
  //                           style: pw.TextStyle(
  //                             fontWeight: pw.FontWeight.bold,
  //                             fontSize: 12,
  //                           ),
  //                         ),
  //                       ),
  //                       pw.Expanded(
  //                         child: pw.Container(
  //                           height: 70,
  //                           child: pw.RichText(
  //                               text: pw.TextSpan(
  //                                   text: '${dataInformation['ToName']}\n',
  //                                   style: pw.TextStyle(
  //                                     // color: _darkColor,
  //                                     fontWeight: pw.FontWeight.bold,
  //                                     fontSize: 12,
  //                                   ),
  //                                   children: [
  //                                 const pw.TextSpan(
  //                                   text: '\n',
  //                                   style: pw.TextStyle(
  //                                     fontSize: 5,
  //                                   ),
  //                                 ),
  //                                 pw.TextSpan(
  //                                     text: dataInformation['Add2']
  //                                             .toString()
  //                                             .isEmpty
  //                                         ? dataInformation['Add1']
  //                                         : dataInformation['Add1'] +
  //                                             '\n' +
  //                                             dataInformation['Add2'],
  //                                     style: pw.TextStyle(
  //                                       fontWeight: pw.FontWeight.normal,
  //                                       fontSize: 10,
  //                                     ),
  //                                     children: const [
  //                                       pw.TextSpan(
  //                                         text: '\n',
  //                                         style: pw.TextStyle(
  //                                           fontSize: 5,
  //                                         ),
  //                                       )
  //                                     ]),
  //                                 companyTaxMode == 'INDIA'
  //                                     ? pw.TextSpan(
  //                                         text: dataInformation['Add4'],
  //                                         style: pw.TextStyle(
  //                                           fontWeight: pw.FontWeight.normal,
  //                                           fontSize: 10,
  //                                         ),
  //                                         children: const [
  //                                             pw.TextSpan(
  //                                               text: '\n',
  //                                               style: pw.TextStyle(
  //                                                 fontSize: 5,
  //                                               ),
  //                                             )
  //                                           ])
  //                                     : pw.TextSpan(
  //                                         text:
  //                                             'T-No :${dataInformation['gstno']}',
  //                                         style: pw.TextStyle(
  //                                           fontWeight: pw.FontWeight.normal,
  //                                           fontSize: 10,
  //                                         ),
  //                                         children: const [
  //                                             pw.TextSpan(
  //                                               text: '\n',
  //                                               style: pw.TextStyle(
  //                                                 fontSize: 5,
  //                                               ),
  //                                             )
  //                                           ]),
  //                                 pw.TextSpan(
  //                                   text: dataInformation['Add3'],
  //                                   style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.normal,
  //                                     fontSize: 10,
  //                                   ),
  //                                 )
  //                               ])),
  //                         ),
  //                       ),
  //                     ]),
  //                 pw.Table(
  //                   border: pw.TableBorder.all(width: 0.2),
  //                   defaultColumnWidth: const pw.IntrinsicColumnWidth(),
  //                   children: [
  //                     companyTaxMode == 'INDIA'
  //                         ? pw.TableRow(children: [
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[0],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[1],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[2],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[3],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[4],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[5],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[6],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[7],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[8],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[9],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[10],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[11],
  //                                       style: const pw.TextStyle(fontSize: 9)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                           ])
  //                         : pw.TableRow(children: [
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[0],
  //                                       style: pw.TextStyle(
  //                                           fontSize: 9,
  //                                           fontWeight: pw.FontWeight.bold)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[1],
  //                                       style: pw.TextStyle(
  //                                           fontSize: 9,
  //                                           fontWeight: pw.FontWeight.bold)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[2],
  //                                       style: pw.TextStyle(
  //                                           fontSize: 9,
  //                                           fontWeight: pw.FontWeight.bold)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[3],
  //                                       style: pw.TextStyle(
  //                                           fontSize: 9,
  //                                           fontWeight: pw.FontWeight.bold)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[4],
  //                                       style: pw.TextStyle(
  //                                           fontSize: 9,
  //                                           fontWeight: pw.FontWeight.bold)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[5],
  //                                       style: pw.TextStyle(
  //                                           fontSize: 9,
  //                                           fontWeight: pw.FontWeight.bold)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[6],
  //                                       style: pw.TextStyle(
  //                                           fontSize: 9,
  //                                           fontWeight: pw.FontWeight.bold)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[7],
  //                                       style: pw.TextStyle(
  //                                           fontSize: 9,
  //                                           fontWeight: pw.FontWeight.bold)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[8],
  //                                       style: pw.TextStyle(
  //                                           fontSize: 9,
  //                                           fontWeight: pw.FontWeight.bold)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[9],
  //                                       style: pw.TextStyle(
  //                                           fontSize: 9,
  //                                           fontWeight: pw.FontWeight.bold)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.center,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Text(tableHeaders[10],
  //                                       style: pw.TextStyle(
  //                                           fontSize: 9,
  //                                           fontWeight: pw.FontWeight.bold)),
  //                                   // pw.Divider(thickness: 1)
  //                                 ]),
  //                           ]),
  //                     for (var i = 0; i < dataParticulars.length; i++)
  //                       // dataParticulars
  //                       companyTaxMode == 'INDIA'
  //                           ? pw.TableRow(children: [
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           '${dataParticulars[i]['ItemId']}',
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.start,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           dataParticulars[i]['ProductName'],
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.start,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           dataParticulars[i]['hsncode'],
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           double.tryParse(dataParticulars[i]
  //                                                       ['RealPrate']
  //                                                   .toString())
  //                                               .toStringAsFixed(decimal),
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           '${dataParticulars[i]['Qty']}',
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               isItemSerialNo
  //                                   ? pw.Column(
  //                                       crossAxisAlignment:
  //                                           pw.CrossAxisAlignment.center,
  //                                       mainAxisAlignment:
  //                                           pw.MainAxisAlignment.center,
  //                                       children: [
  //                                           pw.Padding(
  //                                             padding:
  //                                                 const pw.EdgeInsets.all(2.0),
  //                                             child: pw.Text(
  //                                                 dataParticulars[i]['serialno']
  //                                                     .toString(),
  //                                                 style: const pw.TextStyle(
  //                                                     fontSize: 9)),
  //                                             // pw.Divider(thickness: 1)
  //                                           )
  //                                         ])
  //                                   : pw.Column(
  //                                       crossAxisAlignment:
  //                                           pw.CrossAxisAlignment.center,
  //                                       mainAxisAlignment:
  //                                           pw.MainAxisAlignment.center,
  //                                       children: [
  //                                           pw.Padding(
  //                                             padding:
  //                                                 const pw.EdgeInsets.all(2.0),
  //                                             child: pw.Text(
  //                                                 dataParticulars[i]['unitName']
  //                                                     .toString(),
  //                                                 style: const pw.TextStyle(
  //                                                     fontSize: 9)),
  //                                             // pw.Divider(thickness: 1)
  //                                           )
  //                                         ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           double.tryParse(dataParticulars[i]
  //                                                       ['PRate']
  //                                                   .toString())
  //                                               .toStringAsFixed(decimal),
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           double.tryParse(dataParticulars[i]
  //                                                       ['Net']
  //                                                   .toString())
  //                                               .toStringAsFixed(decimal),
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           '${dataParticulars[i]['tax']} %',
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           double.tryParse(dataParticulars[i]
  //                                                       ['CGST']
  //                                                   .toString())
  //                                               .toStringAsFixed(decimal),
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           double.tryParse(dataParticulars[i]
  //                                                       ['SGST']
  //                                                   .toString())
  //                                               .toStringAsFixed(decimal),
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           double.tryParse(dataParticulars[i]
  //                                                       ['Total']
  //                                                   .toString())
  //                                               .toStringAsFixed(decimal),
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                             ])
  //                           : pw.TableRow(children: [
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           '${dataParticulars[i]['ItemId']}',
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     ),
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.start,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           dataParticulars[i]['ProductName'],
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     ),
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.start,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           dataParticulars[i]['hsncode'],
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           double.tryParse(dataParticulars[i]
  //                                                       ['RealPrate']
  //                                                   .toString())
  //                                               .toStringAsFixed(decimal),
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           '${dataParticulars[i]['Qty']}',
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               isItemSerialNo
  //                                   ? pw.Column(
  //                                       crossAxisAlignment:
  //                                           pw.CrossAxisAlignment.center,
  //                                       mainAxisAlignment:
  //                                           pw.MainAxisAlignment.center,
  //                                       children: [
  //                                           pw.Padding(
  //                                             padding:
  //                                                 const pw.EdgeInsets.all(2.0),
  //                                             child: pw.Text(
  //                                                 dataParticulars[i]['serialno']
  //                                                     .toString(),
  //                                                 style: const pw.TextStyle(
  //                                                     fontSize: 9)),
  //                                             // pw.Divider(thickness: 1)
  //                                           )
  //                                         ])
  //                                   : pw.Column(
  //                                       crossAxisAlignment:
  //                                           pw.CrossAxisAlignment.center,
  //                                       mainAxisAlignment:
  //                                           pw.MainAxisAlignment.center,
  //                                       children: [
  //                                           pw.Padding(
  //                                             padding:
  //                                                 const pw.EdgeInsets.all(2.0),
  //                                             child: pw.Text(
  //                                                 dataParticulars[i]['unitName']
  //                                                     .toString(),
  //                                                 style: const pw.TextStyle(
  //                                                     fontSize: 9)),
  //                                             // pw.Divider(thickness: 1)
  //                                           )
  //                                         ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           double.tryParse(dataParticulars[i]
  //                                                       ['PRate']
  //                                                   .toString())
  //                                               .toStringAsFixed(decimal),
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           double.tryParse(dataParticulars[i]
  //                                                       ['Net']
  //                                                   .toString())
  //                                               .toStringAsFixed(decimal),
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           '${dataParticulars[i]['tax']} %',
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           double.tryParse(dataParticulars[i]
  //                                                       ['tax']
  //                                                   .toString())
  //                                               .toStringAsFixed(decimal),
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                               pw.Column(
  //                                   crossAxisAlignment:
  //                                       pw.CrossAxisAlignment.end,
  //                                   mainAxisAlignment:
  //                                       pw.MainAxisAlignment.center,
  //                                   children: [
  //                                     pw.Padding(
  //                                       padding: const pw.EdgeInsets.all(2.0),
  //                                       child: pw.Text(
  //                                           double.tryParse(dataParticulars[i]
  //                                                       ['Total']
  //                                                   .toString())
  //                                               .toStringAsFixed(decimal),
  //                                           style: const pw.TextStyle(
  //                                               fontSize: 9)),
  //                                       // pw.Divider(thickness: 1)
  //                                     )
  //                                   ]),
  //                             ])
  //                   ],
  //                 ),
  //                 pw.SizedBox(
  //                   height: 40.0,
  //                 ),
  //                 pw.Column(
  //                   children: [
  //                     pw.Row(
  //                       mainAxisAlignment: pw.MainAxisAlignment.end,
  //                       children: [
  //                         pw.Text(
  //                             'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
  //                       ],
  //                     ),
  //                     companyTaxMode == 'INDIA'
  //                         ? pw.Row(
  //                             mainAxisAlignment: pw.MainAxisAlignment.end,
  //                             children: [
  //                               pw.Text(
  //                                   'CESS : ${double.tryParse(dataInformation['Cess'].toString()).toStringAsFixed(decimal)} CGST : ${double.tryParse(dataInformation['CGST'].toString()).toStringAsFixed(decimal)} SGST : ${double.tryParse(dataInformation['SGST'].toString()).toStringAsFixed(decimal)} = ${(double.tryParse(dataInformation['Cess'].toString()) + double.tryParse(dataInformation['CGST'].toString()) + double.tryParse(dataInformation['SGST'].toString())).toStringAsFixed(decimal)}'),
  //                             ],
  //                           )
  //                         : pw.Row(
  //                             mainAxisAlignment: pw.MainAxisAlignment.end,
  //                             children: [
  //                               pw.Text(
  //                                   'VAT : ${double.tryParse(dataInformation['tax'].toString()).toStringAsFixed(decimal)}'),
  //                             ],
  //                           ),
  //                     /**other amount**/
  //                     // otherAmount.length>0 ?
  //                     pw.Row(
  //                       mainAxisAlignment: pw.MainAxisAlignment.end,
  //                       children: [
  //                         pw.Text('***Discount***'),
  //                       ],
  //                     ),
  //                     _addOtherAmountPDF(otherAmount),
  //                     pw.Row(
  //                       mainAxisAlignment: pw.MainAxisAlignment.end,
  //                       children: [
  //                         pw.Text(
  //                             'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
  //                       ],
  //                     ),
  //                     pw.Row(
  //                       mainAxisAlignment: pw.MainAxisAlignment.end,
  //                       children: [
  //                         pw.Text(
  //                             'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
  //                             style: pw.TextStyle(
  //                                 color: PdfColors.black,
  //                                 fontSize: 19,
  //                                 fontWeight: pw.FontWeight.bold)),
  //                       ],
  //                     ),
  //                     pw.Row(
  //                       children: [
  //                         pw.Text(
  //                           'Bill Balance : ${double.tryParse((double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toString()).toStringAsFixed(decimal)}',
  //                         ),
  //                       ],
  //                     ),
  //                     pw.Row(
  //                       children: [
  //                         pw.Text(
  //                           'Old Balance : ${double.tryParse(customerBalance.toString()).toStringAsFixed(decimal)}',
  //                         ),
  //                       ],
  //                     ),
  //                     pw.Row(
  //                       children: [
  //                         pw.Text(
  //                           'Balance : ${double.tryParse(((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toString()).toStringAsFixed(decimal)}',
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //                 byteImageQr != null
  //                     ? pw.Image(imageQr,
  //                         height: 100,
  //                         width:
  //                             100) //Image.provider(imageQr, width: 100, height: 100)
  //                     : pw.Header(text: ''),
  //                 pw.Container(
  //                     alignment: pw.Alignment.center,
  //                     child: pw.Text(data['message'],
  //                         textAlign: pw.TextAlign.center))
  //               ],
  //           footer: _buildFooter))
  //       : printHeaderOnES
  //           ? pdf.addPage(pw.MultiPage(
  //               maxPages: 100,
  //               header: (context) => pw.Column(children: [
  //                     pw.Container(
  //                       height: 20,
  //                       padding: const pw.EdgeInsets.all(10),
  //                       alignment: pw.Alignment.center,
  //                       child: pw.Text(
  //                         invoiceHead,
  //                         style: pw.TextStyle(
  //                           fontWeight: pw.FontWeight.bold,
  //                           fontSize: 25,
  //                         ),
  //                       ),
  //                     ),
  //                     pw.SizedBox(height: 5),
  //                     pw.Container(
  //                         height: 80,
  //                         padding: const pw.EdgeInsets.all(8),
  //                         alignment: pw.Alignment.center,
  //                         child: pw.RichText(
  //                             textAlign: pw.TextAlign.center,
  //                             text: pw.TextSpan(
  //                                 text: '${companySettings.name}\n',
  //                                 style: pw.TextStyle(
  //                                   // color: _darkColor,
  //                                   fontWeight: pw.FontWeight.bold,
  //                                   fontSize: 15,
  //                                 ),
  //                                 children: [
  //                                   const pw.TextSpan(
  //                                     text: '\n',
  //                                     style: pw.TextStyle(
  //                                       fontSize: 5,
  //                                     ),
  //                                   ),
  //                                   pw.TextSpan(
  //                                       text: companySettings.add2
  //                                               .toString()
  //                                               .isEmpty
  //                                           ? companySettings.add1
  //                                           : companySettings.add1 +
  //                                               '\n' +
  //                                               companySettings.add2,
  //                                       style: pw.TextStyle(
  //                                         fontWeight: pw.FontWeight.bold,
  //                                         fontSize: 10,
  //                                       ),
  //                                       children: [
  //                                         companySettings.telephone
  //                                                 .toString()
  //                                                 .isNotEmpty
  //                                             ? pw.TextSpan(
  //                                                 text:
  //                                                     companySettings.telephone,
  //                                                 children: [
  //                                                     companySettings.mobile
  //                                                             .toString()
  //                                                             .isNotEmpty ??
  //                                                         pw.TextSpan(
  //                                                             text: ', ' +
  //                                                                 companySettings
  //                                                                     .mobile),
  //                                                   ])
  //                                             : const pw.TextSpan(
  //                                                 text: '\n',
  //                                                 style: pw.TextStyle(
  //                                                   fontSize: 5,
  //                                                 ),
  //                                               ),
  //                                       ]),
  //                                   pw.TextSpan(
  //                                     text:
  //                                         '${ComSettings.getValue('GST-NO', settings)}',
  //                                     style: pw.TextStyle(
  //                                       fontWeight: pw.FontWeight.bold,
  //                                       fontSize: 10,
  //                                     ),
  //                                   ),
  //                                 ]))),
  //                     pw.SizedBox(height: 20),
  //                     pw.Container(
  //                       padding: const pw.EdgeInsets.all(10),
  //                       alignment: pw.Alignment.center,
  //                       height: 10,
  //                       child: pw.GridView(
  //                         crossAxisCount: 2,
  //                         children: [
  //                           pw.Text('EntryNo : ' + dataInformation['InvoiceNo'],
  //                               style: pw.TextStyle(
  //                                 fontWeight: pw.FontWeight.bold,
  //                                 fontSize: 10,
  //                               ),
  //                               textAlign: pw.TextAlign.left),
  //                           pw.Text(
  //                               'Date : ' +
  //                                   DateUtil.dateDMY(dataInformation['DDate']),
  //                               style: pw.TextStyle(
  //                                 fontWeight: pw.FontWeight.bold,
  //                                 fontSize: 10,
  //                               ),
  //                               textAlign: pw.TextAlign.right),
  //                         ],
  //                       ),
  //                     ),
  //                     if (context.pageNumber > 1) pw.SizedBox(height: 20)
  //                   ]),
  //               build: (context) => [
  //                     /*customer*/
  //                     pw.Row(
  //                         crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                         children: [
  //                           pw.Container(
  //                             margin:
  //                                 const pw.EdgeInsets.only(left: 10, right: 10),
  //                             height: 70,
  //                             child: pw.Text(
  //                               'Bill to:',
  //                               style: pw.TextStyle(
  //                                 fontWeight: pw.FontWeight.bold,
  //                                 fontSize: 12,
  //                               ),
  //                             ),
  //                           ),
  //                           pw.Expanded(
  //                               child: pw.Container(
  //                                   height: 50,
  //                                   child: pw.RichText(
  //                                       text: pw.TextSpan(
  //                                           text:
  //                                               '${dataInformation['ToName']}\n',
  //                                           style: pw.TextStyle(
  //                                             // color: _darkColor,
  //                                             fontWeight: pw.FontWeight.bold,
  //                                             fontSize: 12,
  //                                           ),
  //                                           children: [
  //                                         const pw.TextSpan(
  //                                           text: '\n',
  //                                           style: pw.TextStyle(
  //                                             fontSize: 5,
  //                                           ),
  //                                         ),
  //                                         pw.TextSpan(
  //                                           text: dataInformation['Add2']
  //                                                   .toString()
  //                                                   .isEmpty
  //                                               ? dataInformation['Add1']
  //                                               : dataInformation['Add1'] +
  //                                                   '\n' +
  //                                                   dataInformation['Add2'],
  //                                           style: pw.TextStyle(
  //                                             fontWeight: pw.FontWeight.normal,
  //                                             fontSize: 10,
  //                                           ),
  //                                         )
  //                                       ])))),
  //                         ]),
  //                     pw.Table(
  //                       border: pw.TableBorder.all(width: 0.2),
  //                       children: [
  //                         pw.TableRow(children: [
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[0],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[1],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[2],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[3],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[4],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[5],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                         ]),
  //                         for (var i = 0; i < dataParticulars.length; i++)
  //                           pw.TableRow(children: [
  //                             pw.Column(
  //                                 crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Padding(
  //                                     padding: const pw.EdgeInsets.all(2.0),
  //                                     child: pw.Text(
  //                                         '${dataParticulars[i]['ItemId']}',
  //                                         style:
  //                                             const pw.TextStyle(fontSize: 9)),
  //                                     // pw.Divider(thickness: 1)
  //                                   ),
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.start,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Padding(
  //                                     padding: const pw.EdgeInsets.all(2.0),
  //                                     child: pw.Text(
  //                                         dataParticulars[i]['ProductName'],
  //                                         style:
  //                                             const pw.TextStyle(fontSize: 9)),
  //                                     // pw.Divider(thickness: 1)
  //                                   ),
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Padding(
  //                                     padding: const pw.EdgeInsets.all(2.0),
  //                                     child: pw.Text(
  //                                         double.tryParse(dataParticulars[i]
  //                                                     ['PRate']
  //                                                 .toString())
  //                                             .toStringAsFixed(decimal),
  //                                         style:
  //                                             const pw.TextStyle(fontSize: 9)),
  //                                     // pw.Divider(thickness: 1)
  //                                   )
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Padding(
  //                                     padding: const pw.EdgeInsets.all(2.0),
  //                                     child: pw.Text(
  //                                         dataParticulars[i]['Qty']
  //                                             .toStringAsFixed(decimal),
  //                                         style:
  //                                             const pw.TextStyle(fontSize: 9)),
  //                                     // pw.Divider(thickness: 1)
  //                                   )
  //                                 ]),
  //                             isItemSerialNo
  //                                 ? pw.Column(
  //                                     crossAxisAlignment:
  //                                         pw.CrossAxisAlignment.center,
  //                                     mainAxisAlignment:
  //                                         pw.MainAxisAlignment.center,
  //                                     children: [
  //                                         pw.Padding(
  //                                           padding:
  //                                               const pw.EdgeInsets.all(2.0),
  //                                           child: pw.Text(
  //                                               dataParticulars[i]['serialno']
  //                                                   .toString(),
  //                                               style: const pw.TextStyle(
  //                                                   fontSize: 9)),
  //                                           // pw.Divider(thickness: 1)
  //                                         )
  //                                       ])
  //                                 : pw.Column(
  //                                     crossAxisAlignment:
  //                                         pw.CrossAxisAlignment.center,
  //                                     mainAxisAlignment:
  //                                         pw.MainAxisAlignment.center,
  //                                     children: [
  //                                         pw.Padding(
  //                                           padding:
  //                                               const pw.EdgeInsets.all(2.0),
  //                                           child: pw.Text(
  //                                               dataParticulars[i]['unitName']
  //                                                   .toString(),
  //                                               style: const pw.TextStyle(
  //                                                   fontSize: 9)),
  //                                           // pw.Divider(thickness: 1)
  //                                         )
  //                                       ]),
  //                             pw.Column(
  //                                 crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Padding(
  //                                     padding: const pw.EdgeInsets.all(2.0),
  //                                     child: pw.Text(
  //                                         double.tryParse(dataParticulars[i]
  //                                                     ['Total']
  //                                                 .toString())
  //                                             .toStringAsFixed(decimal),
  //                                         style:
  //                                             const pw.TextStyle(fontSize: 9)),
  //                                     // pw.Divider(thickness: 1)
  //                                   )
  //                                 ]),
  //                           ])
  //                       ],
  //                     ),
  //                     pw.SizedBox(
  //                       height: 40.0,
  //                     ),
  //                     pw.Column(
  //                       children: [
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text(
  //                                 'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
  //                           ],
  //                         ),
  //                         /**other amount**/
  //                         // otherAmount.length>0 ?
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text(''),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text('***Discount***'),
  //                           ],
  //                         ),
  //                         _addOtherAmountPDF(otherAmount),
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text(
  //                                 'TOTAL : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}'),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text(
  //                                 'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text(
  //                                 'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
  //                                 style: pw.TextStyle(
  //                                     // color: Colors.black,
  //                                     fontSize: 19,
  //                                     fontWeight: pw.FontWeight.bold)),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           children: [
  //                             pw.Text(
  //                               'Bill Balance : ${(double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toStringAsFixed(decimal)}',
  //                             ),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           children: [
  //                             pw.Text(
  //                               'Old Balance : ${double.tryParse(customerBalance).toStringAsFixed(decimal)}',
  //                             ),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           children: [
  //                             pw.Text(
  //                               'Balance : ${((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toStringAsFixed(decimal)}',
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                     pw.Container(
  //                         alignment: pw.Alignment.center,
  //                         child: pw.Text(data['message'],
  //                             textAlign: pw.TextAlign.center))
  //                   ],
  //               footer: _buildFooter))
  //           : pdf.addPage(pw.MultiPage(
  //               maxPages: 100,
  //               header: (context) => pw.Column(children: [
  //                     pw.Container(
  //                       height: 20,
  //                       padding: const pw.EdgeInsets.all(10),
  //                       alignment: pw.Alignment.center,
  //                       child: pw.Text(
  //                         invoiceHead,
  //                         style: pw.TextStyle(
  //                           fontWeight: pw.FontWeight.bold,
  //                           fontSize: 25,
  //                         ),
  //                       ),
  //                     ),
  //                     pw.SizedBox(height: 20),
  //                     pw.Container(
  //                       padding: const pw.EdgeInsets.all(10),
  //                       alignment: pw.Alignment.center,
  //                       height: 10,
  //                       child: pw.GridView(
  //                         crossAxisCount: 2,
  //                         children: [
  //                           pw.Text('EntryNo : ' + dataInformation['InvoiceNo'],
  //                               style: pw.TextStyle(
  //                                 fontWeight: pw.FontWeight.bold,
  //                                 fontSize: 10,
  //                               ),
  //                               textAlign: pw.TextAlign.left),
  //                           pw.Text(
  //                               'Date : ' +
  //                                   DateUtil.dateDMY(dataInformation['DDate']),
  //                               style: pw.TextStyle(
  //                                 fontWeight: pw.FontWeight.bold,
  //                                 fontSize: 10,
  //                               ),
  //                               textAlign: pw.TextAlign.right),
  //                         ],
  //                       ),
  //                     ),
  //                     if (context.pageNumber > 1) pw.SizedBox(height: 20)
  //                   ]),
  //               build: (context) => [
  //                     /*customer*/
  //                     pw.Row(
  //                         crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                         children: [
  //                           pw.Container(
  //                             margin:
  //                                 const pw.EdgeInsets.only(left: 10, right: 10),
  //                             height: 70,
  //                             child: pw.Text(
  //                               'Bill to:',
  //                               style: pw.TextStyle(
  //                                 fontWeight: pw.FontWeight.bold,
  //                                 fontSize: 12,
  //                               ),
  //                             ),
  //                           ),
  //                           pw.Expanded(
  //                               child: pw.Container(
  //                                   height: 50,
  //                                   child: pw.RichText(
  //                                       text: pw.TextSpan(
  //                                           text:
  //                                               '${dataInformation['ToName']}\n',
  //                                           style: pw.TextStyle(
  //                                             // color: _darkColor,
  //                                             fontWeight: pw.FontWeight.bold,
  //                                             fontSize: 12,
  //                                           ),
  //                                           children: [
  //                                         const pw.TextSpan(
  //                                           text: '\n',
  //                                           style: pw.TextStyle(
  //                                             fontSize: 5,
  //                                           ),
  //                                         ),
  //                                         pw.TextSpan(
  //                                           text: dataInformation['Add2']
  //                                                   .toString()
  //                                                   .isEmpty
  //                                               ? dataInformation['Add1']
  //                                               : dataInformation['Add1'] +
  //                                                   '\n' +
  //                                                   dataInformation['Add2'],
  //                                           style: pw.TextStyle(
  //                                             fontWeight: pw.FontWeight.normal,
  //                                             fontSize: 10,
  //                                           ),
  //                                         )
  //                                       ])))),
  //                         ]),
  //                     pw.Table(
  //                       border: pw.TableBorder.all(width: 0.2),
  //                       children: [
  //                         pw.TableRow(children: [
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[0],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[1],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[2],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[3],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[4],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                           pw.Column(
  //                               crossAxisAlignment:
  //                                   pw.CrossAxisAlignment.center,
  //                               mainAxisAlignment: pw.MainAxisAlignment.center,
  //                               children: [
  //                                 pw.Text(tableHeaders[5],
  //                                     style: const pw.TextStyle(fontSize: 9)),
  //                                 // pw.Divider(thickness: 1)
  //                               ]),
  //                         ]),
  //                         for (var i = 0; i < dataParticulars.length; i++)
  //                           pw.TableRow(children: [
  //                             pw.Column(
  //                                 crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Padding(
  //                                     padding: const pw.EdgeInsets.all(2.0),
  //                                     child: pw.Text(
  //                                         '${dataParticulars[i]['ItemId']}',
  //                                         style:
  //                                             const pw.TextStyle(fontSize: 9)),
  //                                     // pw.Divider(thickness: 1)
  //                                   ),
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment:
  //                                     pw.CrossAxisAlignment.start,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Padding(
  //                                     padding: const pw.EdgeInsets.all(2.0),
  //                                     child: pw.Text(
  //                                         dataParticulars[i]['ProductName'],
  //                                         style:
  //                                             const pw.TextStyle(fontSize: 9)),
  //                                     // pw.Divider(thickness: 1)
  //                                   ),
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Padding(
  //                                     padding: const pw.EdgeInsets.all(2.0),
  //                                     child: pw.Text(
  //                                         double.tryParse(dataParticulars[i]
  //                                                     ['PRate']
  //                                                 .toString())
  //                                             .toStringAsFixed(decimal),
  //                                         style:
  //                                             const pw.TextStyle(fontSize: 9)),
  //                                     // pw.Divider(thickness: 1)
  //                                   )
  //                                 ]),
  //                             pw.Column(
  //                                 crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Padding(
  //                                     padding: const pw.EdgeInsets.all(2.0),
  //                                     child: pw.Text(
  //                                         dataParticulars[i]['Qty']
  //                                             .toStringAsFixed(decimal),
  //                                         style:
  //                                             const pw.TextStyle(fontSize: 9)),
  //                                     // pw.Divider(thickness: 1)
  //                                   )
  //                                 ]),
  //                             isItemSerialNo
  //                                 ? pw.Column(
  //                                     crossAxisAlignment:
  //                                         pw.CrossAxisAlignment.center,
  //                                     mainAxisAlignment:
  //                                         pw.MainAxisAlignment.center,
  //                                     children: [
  //                                         pw.Padding(
  //                                           padding:
  //                                               const pw.EdgeInsets.all(2.0),
  //                                           child: pw.Text(
  //                                               dataParticulars[i]['serialno']
  //                                                   .toString(),
  //                                               style: const pw.TextStyle(
  //                                                   fontSize: 9)),
  //                                           // pw.Divider(thickness: 1)
  //                                         )
  //                                       ])
  //                                 : pw.Column(
  //                                     crossAxisAlignment:
  //                                         pw.CrossAxisAlignment.center,
  //                                     mainAxisAlignment:
  //                                         pw.MainAxisAlignment.center,
  //                                     children: [
  //                                         pw.Padding(
  //                                           padding:
  //                                               const pw.EdgeInsets.all(2.0),
  //                                           child: pw.Text(
  //                                               dataParticulars[i]['unitName']
  //                                                   .toString(),
  //                                               style: const pw.TextStyle(
  //                                                   fontSize: 9)),
  //                                           // pw.Divider(thickness: 1)
  //                                         )
  //                                       ]),
  //                             pw.Column(
  //                                 crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                                 mainAxisAlignment:
  //                                     pw.MainAxisAlignment.center,
  //                                 children: [
  //                                   pw.Padding(
  //                                     padding: const pw.EdgeInsets.all(2.0),
  //                                     child: pw.Text(
  //                                         double.tryParse(dataParticulars[i]
  //                                                     ['Total']
  //                                                 .toString())
  //                                             .toStringAsFixed(decimal),
  //                                         style:
  //                                             const pw.TextStyle(fontSize: 9)),
  //                                     // pw.Divider(thickness: 1)
  //                                   )
  //                                 ]),
  //                           ])
  //                       ],
  //                     ),
  //                     pw.SizedBox(
  //                       height: 40.0,
  //                     ),
  //                     pw.Column(
  //                       children: [
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text(
  //                                 'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
  //                           ],
  //                         ),
  //                         /**other amount**/
  //                         // otherAmount.length>0 ?
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text(''),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text('***Discount***'),
  //                           ],
  //                         ),
  //                         _addOtherAmountPDF(otherAmount),
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text(
  //                                 'TOTAL : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}'),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text(
  //                                 'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           mainAxisAlignment: pw.MainAxisAlignment.end,
  //                           children: [
  //                             pw.Text(
  //                                 'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
  //                                 style: pw.TextStyle(
  //                                     // color: Colors.black,
  //                                     fontSize: 19,
  //                                     fontWeight: pw.FontWeight.bold)),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           children: [
  //                             pw.Text(
  //                               'Bill Balance : ${(double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toStringAsFixed(decimal)}',
  //                             ),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           children: [
  //                             pw.Text(
  //                               'Old Balance : ${double.tryParse(customerBalance).toStringAsFixed(decimal)}',
  //                             ),
  //                           ],
  //                         ),
  //                         pw.Row(
  //                           children: [
  //                             pw.Text(
  //                               'Balance : ${((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toStringAsFixed(decimal)}',
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                     pw.Container(
  //                         alignment: pw.Alignment.center,
  //                         child: pw.Text(data['message'],
  //                             textAlign: pw.TextAlign.center))
  //                   ],
  //               footer: _buildFooter));
  // } else
  if (model == 3) {
    taxSale
        ? pdf.addPage(pw.MultiPage(
            /*company*/
            maxPages: 100,
            header: (context) => pw.Column(children: [
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Expanded(
                            child: pw.Column(children: [
                          pw.Container(
                            height: 20,
                            padding: const pw.EdgeInsets.all(8),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              invoiceHead,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 25,
                              ),
                            ),
                          ),
                          pw.Container(
                              height: 80,
                              padding: const pw.EdgeInsets.all(8),
                              alignment: pw.Alignment.center,
                              child: pw.RichText(
                                  textAlign: pw.TextAlign.center,
                                  text: pw.TextSpan(
                                      text: '${companySettings.name}\n',
                                      style: pw.TextStyle(
                                        // color: _darkColor,
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      children: [
                                        const pw.TextSpan(
                                          text: '\n',
                                          style: pw.TextStyle(
                                            fontSize: 5,
                                          ),
                                        ),
                                        pw.TextSpan(
                                            text: companySettings.add2
                                                    .toString()
                                                    .isEmpty
                                                ? companySettings.add1
                                                : companySettings.add1 +
                                                    '\n' +
                                                    companySettings.add2,
                                            style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                            children: [
                                              companySettings.telephone
                                                      .toString()
                                                      .isNotEmpty
                                                  ? pw.TextSpan(
                                                      text: companySettings
                                                          .telephone,
                                                      children: [
                                                          companySettings.mobile
                                                                  .toString()
                                                                  .isNotEmpty ??
                                                              pw.TextSpan(
                                                                  text: ', ' +
                                                                      companySettings
                                                                          .mobile),
                                                        ])
                                                  : const pw.TextSpan(
                                                      text: '\n',
                                                      style: pw.TextStyle(
                                                        fontSize: 5,
                                                      ),
                                                    ),
                                            ]),
                                        pw.TextSpan(
                                          text:
                                              '${ComSettings.getValue('GST-NO', settings)}',
                                          style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ]))),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            alignment: pw.Alignment.center,
                            height: 10,
                            child: pw.GridView(
                              crossAxisCount: 2,
                              children: [
                                pw.Text(
                                    'Invoice : ' + dataInformation['InvoiceNo'],
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    textAlign: pw.TextAlign.left),
                                pw.Text(
                                    'Date : ' +
                                        DateUtil.dateDMY(
                                            dataInformation['DDate']),
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    textAlign: pw.TextAlign.right),
                              ],
                            ),
                          ),
                        ])),
                      ]),
                  if (context.pageNumber > 1) pw.SizedBox(height: 20)
                ]),
            build: (context) => [
                  /*customer*/
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(left: 10, right: 10),
                          height: 70,
                          child: pw.Text(
                            'Bill to:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Container(
                            height: 70,
                            child: pw.RichText(
                                text: pw.TextSpan(
                                    text: '${dataInformation['ToName']}\n',
                                    style: pw.TextStyle(
                                      // color: _darkColor,
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    children: [
                                  const pw.TextSpan(
                                    text: '\n',
                                    style: pw.TextStyle(
                                      fontSize: 5,
                                    ),
                                  ),
                                  pw.TextSpan(
                                      text: dataInformation['Add2']
                                              .toString()
                                              .isEmpty
                                          ? dataInformation['Add1']
                                          : dataInformation['Add1'] +
                                              '\n' +
                                              dataInformation['Add2'],
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.normal,
                                        fontSize: 10,
                                      ),
                                      children: const [
                                        pw.TextSpan(
                                          text: '\n',
                                          style: pw.TextStyle(
                                            fontSize: 5,
                                          ),
                                        )
                                      ]),
                                  companyTaxMode == 'INDIA'
                                      ? pw.TextSpan(
                                          text: dataInformation['Add4'],
                                          style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.normal,
                                            fontSize: 10,
                                          ),
                                          children: const [
                                              pw.TextSpan(
                                                text: '\n',
                                                style: pw.TextStyle(
                                                  fontSize: 5,
                                                ),
                                              )
                                            ])
                                      : pw.TextSpan(
                                          text:
                                              'T-No :${dataInformation['gstno']}',
                                          style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.normal,
                                            fontSize: 10,
                                          ),
                                          children: const [
                                              pw.TextSpan(
                                                text: '\n',
                                                style: pw.TextStyle(
                                                  fontSize: 5,
                                                ),
                                              )
                                            ]),
                                  pw.TextSpan(
                                    text: dataInformation['Add3'],
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.normal,
                                      fontSize: 10,
                                    ),
                                  )
                                ])),
                          ),
                        ),
                      ]),
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.2),
                    defaultColumnWidth: const pw.IntrinsicColumnWidth(),
                    children: [
                      companyTaxMode == 'INDIA'
                          ? pw.TableRow(children: [
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[0],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[1],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[2],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[3],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[4],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[5],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[6],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[7],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[8],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[9],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[10],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[11],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                            ])
                          : pw.TableRow(children: [
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[0],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[1],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[2],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[3],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[4],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[5],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[6],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[7],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[8],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[9],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[10],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                            ]),
                      for (var i = 0; i < dataParticulars.length; i++)
                        // dataParticulars
                        companyTaxMode == 'INDIA'
                            ? pw.TableRow(children: [
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['ItemId']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['ProductName'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['hsncode'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['RealPrate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['Qty']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                isItemSerialNo
                                    ? pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['serialno']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ])
                                    : pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['unitName']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['PRate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Net']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['tax']} %',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['CGST']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['SGST']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Total']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                              ])
                            : pw.TableRow(children: [
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['ItemId']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      ),
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['ProductName'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      ),
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['hsncode'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['RealPrate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['Qty']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                isItemSerialNo
                                    ? pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['serialno']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ])
                                    : pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['unitName']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['PRate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Net']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['tax']} %',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['tax']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Total']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                              ])
                    ],
                  ),
                  pw.SizedBox(
                    height: 40.0,
                  ),
                  pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      companyTaxMode == 'INDIA'
                          ? pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                    'CESS : ${double.tryParse(dataInformation['Cess'].toString()).toStringAsFixed(decimal)} CGST : ${double.tryParse(dataInformation['CGST'].toString()).toStringAsFixed(decimal)} SGST : ${double.tryParse(dataInformation['SGST'].toString()).toStringAsFixed(decimal)} = ${(double.tryParse(dataInformation['Cess'].toString()) + double.tryParse(dataInformation['CGST'].toString()) + double.tryParse(dataInformation['SGST'].toString())).toStringAsFixed(decimal)}'),
                              ],
                            )
                          : pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                    'VAT : ${double.tryParse(dataInformation['tax'].toString()).toStringAsFixed(decimal)}'),
                              ],
                            ),
                      /**other amount**/
                      // otherAmount.length>0 ?
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('***Discount***'),
                        ],
                      ),
                      _addOtherAmountPDF(otherAmount),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
                              style: pw.TextStyle(
                                  color: PdfColors.black,
                                  fontSize: 19,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Bill Balance : ${double.tryParse((double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toString()).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Old Balance : ${double.tryParse(customerBalance.toString()).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Balance : ${double.tryParse(((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toString()).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                  byteImageQr != null
                      ? pw.Image(imageQr,
                          height: 100,
                          width:
                              100) //Image.provider(imageQr, width: 100, height: 100)
                      : pw.Header(text: ''),
                  pw.Container(
                      alignment: pw.Alignment.center,
                      child: pw.Text(data['message'],
                          textAlign: pw.TextAlign.center))
                ],
            footer: _buildFooter))
        : pdf.addPage(pw.MultiPage(
            maxPages: 100,
            header: (context) => pw.Column(children: [
                  pw.Container(
                    height: 20,
                    padding: const pw.EdgeInsets.all(10),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      invoiceHead,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    alignment: pw.Alignment.center,
                    height: 10,
                    child: pw.GridView(
                      crossAxisCount: 2,
                      children: [
                        pw.Text('EntryNo : ' + dataInformation['InvoiceNo'],
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                            textAlign: pw.TextAlign.left),
                        pw.Text(
                            'Date : ' +
                                DateUtil.dateDMY(dataInformation['DDate']),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                            textAlign: pw.TextAlign.right),
                      ],
                    ),
                  ),
                  if (context.pageNumber > 1) pw.SizedBox(height: 20)
                ]),
            build: (context) => [
                  /*customer*/
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(left: 10, right: 10),
                          height: 70,
                          child: pw.Text(
                            'Bill to:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Expanded(
                            child: pw.Container(
                                height: 50,
                                child: pw.RichText(
                                    text: pw.TextSpan(
                                        text: '${dataInformation['ToName']}\n',
                                        style: pw.TextStyle(
                                          // color: _darkColor,
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        children: [
                                      const pw.TextSpan(
                                        text: '\n',
                                        style: pw.TextStyle(
                                          fontSize: 5,
                                        ),
                                      ),
                                      pw.TextSpan(
                                        text: dataInformation['Add2']
                                                .toString()
                                                .isEmpty
                                            ? dataInformation['Add1']
                                            : dataInformation['Add1'] +
                                                '\n' +
                                                dataInformation['Add2'],
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.normal,
                                          fontSize: 10,
                                        ),
                                      )
                                    ])))),
                      ]),
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.2),
                    children: [
                      pw.TableRow(children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[0],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[1],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[2],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[3],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[4],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[5],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                      ]),
                      for (var i = 0; i < dataParticulars.length; i++)
                        pw.TableRow(children: [
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      '${dataParticulars[i]['ItemId']}',
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ),
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      dataParticulars[i]['ProductName'],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ),
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      double.tryParse(dataParticulars[i]
                                                  ['PRate']
                                              .toString())
                                          .toStringAsFixed(decimal),
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                )
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      dataParticulars[i]['Qty']
                                          .toStringAsFixed(decimal),
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                )
                              ]),
                          isItemSerialNo
                              ? pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['serialno']
                                                .toString(),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ])
                              : pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['unitName']
                                                .toString(),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      double.tryParse(dataParticulars[i]
                                                  ['Total']
                                              .toString())
                                          .toStringAsFixed(decimal),
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                )
                              ]),
                        ])
                    ],
                  ),
                  pw.SizedBox(
                    height: 40.0,
                  ),
                  pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      /**other amount**/
                      // otherAmount.length>0 ?
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(''),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('***Discount***'),
                        ],
                      ),
                      _addOtherAmountPDF(otherAmount),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'TOTAL : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
                              style: pw.TextStyle(
                                  // color: Colors.black,
                                  fontSize: 19,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Bill Balance : ${(double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Old Balance : ${double.tryParse(customerBalance).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Balance : ${((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                      alignment: pw.Alignment.center,
                      child: pw.Text(data['message'],
                          textAlign: pw.TextAlign.center))
                ],
            footer: _buildFooter));
  } else if (model == 4) {
    int lineItem = dataParticulars.length;
    int addLines =
        lineItem > printLines ? lineItem - printLines : printLines - lineItem;
    int col = 11;
    //GST
    pdf.addPage(pw.MultiPage(
      pageTheme: _buildTheme(_pageFormat),
      /*company*/
      maxPages: 10,
      header: (context) => pw.Column(children: [
        pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Row(children: [
              pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companySettings.name,
                    style: pw.TextStyle(
                      fontSize: 14.0,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 1 * PdfPageFormat.mm),
                  pw.Text(
                    companySettings.add1,
                    style: const pw.TextStyle(
                      fontSize: 9.0,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(width: 1 * PdfPageFormat.mm),
                  pw.Text(
                    companySettings.add2,
                    style: const pw.TextStyle(
                      fontSize: 9.0,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(width: 1 * PdfPageFormat.mm),
                  pw.Text(
                    'MOB : ${companySettings.mobile}',
                    style: const pw.TextStyle(
                      fontSize: 9.0,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GST No :${ComSettings.getValue('GST-NO', settings)}',
                    style: pw.TextStyle(
                      fontSize: 10.0,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4 * PdfPageFormat.mm),
                  pw.Text(
                    'State :${ComSettings.getValue('COMP-STATE', settings)}    ${ComSettings.getValue('COMP-STATECODE', settings)}',
                    style: pw.TextStyle(
                      fontSize: 10.0,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ])),
        pw.Divider(),
        pw.Center(
          child: pw.Text(
            'TAX INVOICE',
            style: const pw.TextStyle(
              fontSize: 15.0,
              // fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Divider(height: 0.2),
        pw.Padding(
            padding: const pw.EdgeInsets.only(left: 5),
            child: pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(100),
                  1: const pw.FlexColumnWidth(100),
                },
                border: const pw.TableBorder(
                    verticalInside: pw.BorderSide(
                        width: 1,
                        color: PdfColors.black,
                        style: pw.BorderStyle.solid)),
                children: [
                  pw.TableRow(children: [
                    pw.Text(
                      '',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 7,
                        // color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'Transportation Mode',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 7,
                      ),
                    ),
                    pw.SizedBox(height: 1 * PdfPageFormat.mm),
                  ]),
                  pw.TableRow(children: [
                    pw.Text(
                      '',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 7,
                        // color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      ' Vechicle No :',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 7,
                      ),
                    ),
                    pw.SizedBox(height: 1 * PdfPageFormat.mm),
                  ]),
                  pw.TableRow(children: [
                    pw.Text(
                      ' Invoice No :   ${dataInformation['InvoiceNo']}',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 7,
                      ),
                    ),
                    pw.Text(
                      ' Date & Time Of Supply',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 7,
                      ),
                    ),
                    pw.SizedBox(height: 1 * PdfPageFormat.mm),
                  ]),
                  pw.TableRow(children: [
                    pw.Text(
                      ' Invoice Date : ${DateUtil.dateDMY(dataInformation['DDate'])}',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 7,
                      ),
                    ),
                    pw.Text(
                      ' Palce Of Supply',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 7,
                      ),
                    ),
                    pw.SizedBox(height: 1 * PdfPageFormat.mm),
                  ]),
                ])),
        pw.Divider(height: 0.2),
        pw.Padding(
            padding: const pw.EdgeInsets.only(left: 5),
            child: pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(100),
                  1: const pw.FlexColumnWidth(100),
                },
                border: const pw.TableBorder(
                    verticalInside: pw.BorderSide(
                        width: 1,
                        color: PdfColors.black,
                        style: pw.BorderStyle.solid)),
                children: [
                  pw.TableRow(children: [
                    pw.Text(
                      'Details Of Receiver (Billed To)',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 7.0,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.Text(
                      'Details Of Consignee (Shipped To)',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 7.0,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.SizedBox(height: 1 * PdfPageFormat.mm),
                  ]),
                  pw.TableRow(children: [
                    pw.Text(
                      'Name:        ${dataInformation['ToName']}',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                      ),
                    ),
                    pw.Text(
                      ' Name:      ',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                      ),
                    ),
                    pw.SizedBox(height: 1 * PdfPageFormat.mm),
                  ]),
                  pw.TableRow(children: [
                    // pw.Text(
                    //   ' Address :  ', //${dataInformation['Add2']}',
                    //   textAlign: pw.TextAlign.left,
                    //   style: const pw.TextStyle(
                    //     fontSize: 8.0,
                    //   ),
                    // ),
                    pw.RichText(
                      text: pw.TextSpan(
                          text: dataLedger['add2'].toString().isEmpty
                              ? 'Address:  ' + dataLedger['add1']
                              : 'Address:  ' +
                                  dataLedger['add1'] +
                                  '\n' +
                                  dataLedger['add2'],
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.normal,
                            fontSize: 9,
                          ),
                          children: const [
                            pw.TextSpan(
                              text: '\n',
                              style: pw.TextStyle(
                                fontSize: 5,
                              ),
                            )
                          ]),
                    ),
                    pw.Text(
                      ' Address :  ',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                      ),
                    ),
                    pw.SizedBox(height: 1 * PdfPageFormat.mm),
                  ]),
                  pw.TableRow(children: [
                    pw.Text(
                      ' Mobile:     ${dataLedger['Mobile']}',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                      ),
                    ),
                    pw.Text(
                      '  ',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 8.0,
                      ),
                    ),
                    pw.SizedBox(height: 1 * PdfPageFormat.mm),
                  ]),
                  pw.TableRow(children: [
                    pw.Text(
                      ' State/Code:${dataLedger['state']} ${dataLedger['stateCode']} ${dataLedger['PinNo']}',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                      ),
                    ),
                    pw.Text(
                      '   ',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                      ),
                    ),
                    pw.SizedBox(height: 1 * PdfPageFormat.mm),
                  ]),
                  pw.TableRow(children: [
                    pw.Text(
                      ' GST No:    ${dataLedger['gstno']}',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                      ),
                    ),
                    pw.Text(
                      '  ',
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 9.0,
                      ),
                    ),
                    pw.SizedBox(height: 1 * PdfPageFormat.mm),
                  ]),
                ])),
        if (context.pageNumber > 1) pw.SizedBox(height: 20)
      ]),
      build: (context) => [
        pw.Table(
          border: pw.TableBorder.all(width: 0.7),
          defaultColumnWidth: const pw.IntrinsicColumnWidth(),
          children: [
            pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('No',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        // pw.Divider(thickness: 1)
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('Description Of Goods',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        // pw.Divider(thickness: 1)
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('Hsn\nCode',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        // pw.Divider(thickness: 1)
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('Qty',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        // pw.Divider(thickness: 1)
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('UOM',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        // pw.Divider(thickness: 1)
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('Unit\nPrice',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        // pw.Divider(thickness: 1)
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('Taxable\nValue',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        // pw.Divider(thickness: 1)
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('CGST',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        // pw.Divider(thickness: 1)
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('SGST',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        // pw.Divider(thickness: 1)
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('tax',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        // pw.Divider(thickness: 1)
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('Total Amount',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        // pw.Divider(thickness: 1)
                      ]),
                ]),
            for (var i = 0; i < dataParticulars.length; i++)
              // dataParticulars
              pw.TableRow(children: [
                // pw.Column(
                //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                //     mainAxisAlignment: pw.MainAxisAlignment.center,
                //     children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2.0),
                  child: pw.Text('${dataParticulars[i]['ItemId']}',
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 8)),
                  // pw.Divider(thickness: 1)
                ),
                // ]),
                // pw.Column(
                //     crossAxisAlignment: pw.CrossAxisAlignment.start,
                //     mainAxisAlignment: pw.MainAxisAlignment.center,
                //     children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2.0),
                  child: pw.SizedBox(
                      width: 100,
                      child: pw.Text(dataParticulars[i]['ProductName'],
                          softWrap: true,
                          overflow: pw.TextOverflow.clip,
                          style: const pw.TextStyle(fontSize: 8))),
                  // pw.Divider(thickness: 1)
                ),
                // ]),
                // pw.Column(
                //     crossAxisAlignment: pw.CrossAxisAlignment.start,
                //     mainAxisAlignment: pw.MainAxisAlignment.center,
                //     children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2.0),
                  child: pw.Text(dataParticulars[i]['hsncode'],
                      style: const pw.TextStyle(fontSize: 8)),
                  // pw.Divider(thickness: 1)
                ),
                // ]),
                // pw.Column(
                //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                //     mainAxisAlignment: pw.MainAxisAlignment.center,
                //     children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2.0),
                  child: pw.Text('${dataParticulars[i]['Qty']}',
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 8)),
                  // pw.Divider(thickness: 1)
                ),
                // ]),
                // pw.Column(
                //     crossAxisAlignment: pw.CrossAxisAlignment.center,
                //     mainAxisAlignment: pw.MainAxisAlignment.center,
                //     children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2.0),
                  child: pw.Text(dataParticulars[i]['unitName'].toString(),
                      style: const pw.TextStyle(fontSize: 8)),
                  // pw.Divider(thickness: 1)
                ),
                // ]),
                // pw.Column(
                //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                //     mainAxisAlignment: pw.MainAxisAlignment.center,
                //     children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2.0),
                  child: pw.Text(
                      double.tryParse(
                              dataParticulars[i]['RealPrate'].toString())
                          .toStringAsFixed(decimal),
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 8)),
                  // pw.Divider(thickness: 1)
                ),
                // ]),
                // pw.Column(
                //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                //     mainAxisAlignment: pw.MainAxisAlignment.center,
                //     children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2.0),
                  child: pw.Text(
                      double.tryParse(dataParticulars[i]['Net']
                              .toStringAsFixed(decimal))
                          .toStringAsFixed(decimal),
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 8)),
                  // pw.Divider(thickness: 1)
                ),
                // ]),
                // pw.Column(
                //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                //     mainAxisAlignment: pw.MainAxisAlignment.center,
                //     children: [
                pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(4),
                      1: const pw.FlexColumnWidth(9),
                    },
                    border: pw.TableBorder.symmetric(
                      outside: pw.BorderSide.none,
                      inside: const pw.BorderSide(
                          width: 0.7,
                          color: PdfColors.black,
                          style: pw.BorderStyle.solid),
                    ),
                    children: [
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.0),
                          child: pw.Text(
                              '${ComSettings.removeZero(int.parse(dataParticulars[i]['tax'].toString()) / 2)}%',
                              style: const pw.TextStyle(fontSize: 7)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.0),
                          child: pw.Text(
                              dataParticulars[i]['CGST']
                                  .toStringAsFixed(decimal),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 8)),
                        )
                      ]),
                    ]),
                // ]),
                // pw.Column(
                //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                //     mainAxisAlignment: pw.MainAxisAlignment.center,
                //     children: [
                pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(4),
                      1: const pw.FlexColumnWidth(9),
                    },
                    border: pw.TableBorder.symmetric(
                      outside: pw.BorderSide.none,
                      inside: const pw.BorderSide(
                          width: 0.7,
                          color: PdfColors.black,
                          style: pw.BorderStyle.solid),
                    ),
                    children: [
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.0),
                          child: pw.Text(
                              '${ComSettings.removeZero(int.parse(dataParticulars[i]['tax'].toString()) / 2)}%',
                              style: const pw.TextStyle(fontSize: 7)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.0),
                          child: pw.Text(
                              dataParticulars[i]['SGST']
                                  .toStringAsFixed(decimal),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 8)),
                        )
                      ]),
                    ]),
                // ]),
                // pw.Column(
                //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                //     mainAxisAlignment: pw.MainAxisAlignment.center,
                //     children: [
                pw.Table(
                    // columnWidths: {
                    //   0: const pw.FlexColumnWidth(15),
                    //   1: const pw.FlexColumnWidth(15),
                    // },
                    border: pw.TableBorder.symmetric(
                      outside: pw.BorderSide.none,
                      inside: const pw.BorderSide(
                          width: 0.7,
                          color: PdfColors.black,
                          style: pw.BorderStyle.solid),
                    ),
                    children: [
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.0),
                          child: pw.Text(
                              '${ComSettings.removeZero(dataParticulars[i]['tax'].toDouble())}%',
                              style: const pw.TextStyle(fontSize: 7)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.0),
                          child: pw.Text(
                              dataParticulars[i]['tax']
                                  .toStringAsFixed(decimal),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 8)),
                        )
                      ]),
                    ]),
                // ]),
                // pw.Column(
                //     crossAxisAlignment: pw.CrossAxisAlignment.end,
                //     mainAxisAlignment: pw.MainAxisAlignment.center,
                //     children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2.0),
                  child: pw.Text(
                      double.tryParse(dataParticulars[i]['Total'].toString())
                          .toStringAsFixed(decimal),
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 8)),
                  // pw.Divider(thickness: 1)
                )
              ]),
            // ]),
            //add bill total line
            for (var i = 0; i < addLines; i++)
              pw.TableRow(children: [
                for (var j = 0; j < col; j++)
                  j == 7 || j == 8
                      ? pw.Table(
                          columnWidths: {
                            0: const pw.FlexColumnWidth(4),
                            1: const pw.FlexColumnWidth(9),
                          },
                          border: pw.TableBorder.symmetric(
                            outside: pw.BorderSide.none,
                            inside: const pw.BorderSide(
                                width: 0.7,
                                color: PdfColors.black,
                                style: pw.BorderStyle.solid),
                          ),
                          children: [
                            pw.TableRow(children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.SizedBox(
                                  height: 8,
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.SizedBox(
                                  height: 8,
                                ),
                              )
                            ]),
                          ])
                      : j == 9
                          ? pw.Table(
                              border: pw.TableBorder.symmetric(
                                outside: pw.BorderSide.none,
                                inside: const pw.BorderSide(
                                    width: 0.7,
                                    color: PdfColors.black,
                                    style: pw.BorderStyle.solid),
                              ),
                              children: [
                                  pw.TableRow(children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.SizedBox(
                                        height: 8,
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.SizedBox(
                                        height: 8,
                                      ),
                                    )
                                  ]),
                                ])
                          : pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(2.0),
                                    child: pw.SizedBox(
                                      height: 8,
                                    ),
                                  )
                                ]),
              ]),
            pw.TableRow(children: [
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2.0),
                      child: pw.Text(' ',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      // pw.Divider(thickness: 1)
                    )
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2.0),
                      child: pw.Text('Total',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      // pw.Divider(thickness: 1)
                    )
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2.0),
                      child: pw.Text('                          ',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      // pw.Divider(thickness: 1)
                    )
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2.0),
                      child: pw.Text(
                          dataParticulars
                              .fold(
                                  0.0,
                                  (a, b) =>
                                      a + double.parse(b['Qty'].toString()))
                              .toStringAsFixed(0),
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      // pw.Divider(thickness: 1)
                    )
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2.0),
                      child: pw.Text('     ',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      // pw.Divider(thickness: 1)
                    )
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2.0),
                      child: pw.Text(
                          dataParticulars
                              .fold(
                                  0.0,
                                  (a, b) =>
                                      a +
                                      double.parse(b['RealPrate'].toString()))
                              .toStringAsFixed(2),
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      // pw.Divider(thickness: 1)
                    )
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2.0),
                      child: pw.Text(
                          dataParticulars
                              .fold(
                                  0.0,
                                  (a, b) =>
                                      a + double.parse(b['Net'].toString()))
                              .toStringAsFixed(2),
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      // pw.Divider(thickness: 1)
                    )
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2.0),
                      child: pw.Text(
                          dataParticulars
                              .fold(
                                  0.0,
                                  (a, b) =>
                                      a + double.parse(b['CGST'].toString()))
                              .toStringAsFixed(2),
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),

                      // pw.Divider(thickness: 1)
                    )
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2.0),
                      child: pw.Text(
                          dataParticulars
                              .fold(
                                  0.0,
                                  (a, b) =>
                                      a + double.parse(b['SGST'].toString()))
                              .toStringAsFixed(2),
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),

                      // pw.Divider(thickness: 1)
                    )
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2.0),
                      child: pw.Text(
                          dataParticulars
                              .fold(
                                  0.0,
                                  (a, b) =>
                                      a + double.parse(b['tax'].toString()))
                              .toStringAsFixed(2),
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),

                      // pw.Divider(thickness: 1)
                    )
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2.0),
                      child: pw.Text(
                          dataParticulars
                              .fold(
                                  0.0,
                                  (a, b) =>
                                      a + double.parse(b['Total'].toString()))
                              .toStringAsFixed(2),
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      // pw.Divider(thickness: 1)
                    )
                  ]),
            ]),
          ],
        ),
        // pw.SizedBox(
        //   height: 40.0,
        // ),
      ],
      footer: (context) => pw.Column(
        children: [
          pw.Padding(
              padding: const pw.EdgeInsets.only(left: 5),
              child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Table(
                        //   columnWidths: {
                        //   0: const pw.FlexColumnWidth(2),
                        //   1: const pw.FlexColumnWidth(1),
                        // },
                        // border: const pw.TableBorder(
                        //     verticalInside: pw.BorderSide(
                        //         width: 1,
                        //         color: PdfColors.black,
                        //         style: pw.BorderStyle.solid)),
                        children: [
                          pw.TableRow(children: [
                            pw.SizedBox(
                                width: 300,
                                child: pw.RichText(
                                    softWrap: true,
                                    maxLines: 3,
                                    text: pw.TextSpan(
                                        style: const pw.TextStyle(fontSize: 8),
                                        text: NumberToWord().convertDouble(
                                            'en',
                                            double.tryParse(
                                                dataInformation['GrandTotal']
                                                    .toString()))))),
                            pw.SizedBox(height: 5 * PdfPageFormat.mm),
                          ]),
                          pw.TableRow(children: [
                            pw.Text(
                              '          Bank Details',
                              textAlign: pw.TextAlign.left,
                              style: const pw.TextStyle(
                                  decoration: pw.TextDecoration.underline,
                                  fontSize: 8),
                            ),
                            pw.SizedBox(height: 1 * PdfPageFormat.mm),
                          ]),
                          pw.TableRow(children: [
                            pw.RichText(
                                text: pw.TextSpan(
                                    text: companySettings.name,
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                    ),
                                    children: [
                                  pw.TextSpan(
                                    text: '\n${dataBankLedger['name']}',
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text:
                                        '\nACC NO : ${dataBankLedger['account']}',
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text:
                                        '\nIFSC CODE : ${dataBankLedger['ifsc']}',
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: '\n${dataBankLedger['branch']}',
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                ])),
                            pw.SizedBox(height: 20 * PdfPageFormat.mm),
                          ]),
                        ]),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(children: [
                          pw.Table(
                              // columnWidths: {
                              //   0: const pw.FlexColumnWidth(100),
                              //   1: const pw.FlexColumnWidth(60),
                              // },
                              border: pw.TableBorder.all(width: 0.2
                                  // verticalInside: pw.BorderSide(
                                  //     width: 1,
                                  //     color: PdfColors.black,
                                  //     style: pw.BorderStyle.solid)
                                  ),
                              children: [
                                pw.TableRow(children: [
                                  pw.Text(
                                    '                          ',
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.Text(
                                    '                          ',
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.SizedBox(height: 1 * PdfPageFormat.mm),
                                ]),
                                pw.TableRow(children: [
                                  pw.Text(
                                    '      TCS                ',
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.Text(
                                    double.tryParse(
                                            dataInformation['TCS'].toString())
                                        .toStringAsFixed(decimal),
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.SizedBox(height: 1 * PdfPageFormat.mm),
                                ]),
                                pw.TableRow(children: [
                                  pw.Text(
                                    'Round Off',
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.Text(
                                    double.tryParse(dataInformation['ROUNDOFF']
                                            .toString())
                                        .toStringAsFixed(decimal),
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.SizedBox(height: 1 * PdfPageFormat.mm),
                                ]),
                                pw.TableRow(children: [
                                  pw.Text(
                                    'Total',
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(
                                    double.tryParse(
                                            dataInformation['GrandTotal']
                                                .toString())
                                        .toStringAsFixed(decimal),
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.SizedBox(height: 1 * PdfPageFormat.mm),
                                ]),
                              ]),
                          pw.Text(
                            companySettings.name,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 10 * PdfPageFormat.mm),
                          pw.Text(
                            'Authorised Signatuory',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontSize: 10,
                            ),
                          ),
                          pw.SizedBox(height: 10 * PdfPageFormat.mm),
                        ])),
                  ])),
          pw.Text(
            'Certified that the particular given above are true and correct',
            textAlign: pw.TextAlign.left,
            style: const pw.TextStyle(
              fontSize: 6,
            ),
          ),
          _buildFooter(context)
        ],
      ),
    ));
  } else if (model == 5) {
    taxSale
        ? pdf.addPage(pw.MultiPage(
            /*company*/
            maxPages: 100,
            header: (context) => pw.Column(children: [
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Expanded(
                            child: pw.Column(children: [
                          pw.Container(
                            height: 20,
                            padding: const pw.EdgeInsets.all(8),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              invoiceHead,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 25,
                              ),
                            ),
                          ),
                          pw.Container(
                              height: 80,
                              padding: const pw.EdgeInsets.all(8),
                              alignment: pw.Alignment.center,
                              child: pw.RichText(
                                  textAlign: pw.TextAlign.center,
                                  text: pw.TextSpan(
                                      text: '${companySettings.name}\n',
                                      style: pw.TextStyle(
                                        // color: _darkColor,
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      children: [
                                        const pw.TextSpan(
                                          text: '\n',
                                          style: pw.TextStyle(
                                            fontSize: 5,
                                          ),
                                        ),
                                        pw.TextSpan(
                                            text: companySettings.add2
                                                    .toString()
                                                    .isEmpty
                                                ? companySettings.add1
                                                : companySettings.add1 +
                                                    '\n' +
                                                    companySettings.add2,
                                            style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                            children: [
                                              companySettings.telephone
                                                      .toString()
                                                      .isNotEmpty
                                                  ? pw.TextSpan(
                                                      text: companySettings
                                                          .telephone,
                                                      children: [
                                                          companySettings.mobile
                                                                  .toString()
                                                                  .isNotEmpty ??
                                                              pw.TextSpan(
                                                                  text: ', ' +
                                                                      companySettings
                                                                          .mobile),
                                                        ])
                                                  : const pw.TextSpan(
                                                      text: '\n',
                                                      style: pw.TextStyle(
                                                        fontSize: 5,
                                                      ),
                                                    ),
                                            ]),
                                        pw.TextSpan(
                                          text:
                                              '${ComSettings.getValue('GST-NO', settings)}',
                                          style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ]))),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            alignment: pw.Alignment.center,
                            height: 10,
                            child: pw.GridView(
                              crossAxisCount: 2,
                              children: [
                                pw.Text(
                                    'Invoice : ' + dataInformation['InvoiceNo'],
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    textAlign: pw.TextAlign.left),
                                pw.Text(
                                    'Date : ' +
                                        DateUtil.dateDMY(
                                            dataInformation['DDate']),
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    textAlign: pw.TextAlign.right),
                              ],
                            ),
                          ),
                        ])),
                      ]),
                  if (context.pageNumber > 1) pw.SizedBox(height: 20)
                ]),
            build: (context) => [
                  /*customer*/
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(left: 10, right: 10),
                          height: 70,
                          child: pw.Text(
                            'Bill to:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Container(
                            height: 70,
                            child: pw.RichText(
                                text: pw.TextSpan(
                                    text: '${dataInformation['ToName']}\n',
                                    style: pw.TextStyle(
                                      // color: _darkColor,
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    children: [
                                  const pw.TextSpan(
                                    text: '\n',
                                    style: pw.TextStyle(
                                      fontSize: 5,
                                    ),
                                  ),
                                  pw.TextSpan(
                                      text: dataInformation['Add2']
                                              .toString()
                                              .isEmpty
                                          ? dataInformation['Add1']
                                          : dataInformation['Add1'] +
                                              '\n' +
                                              dataInformation['Add2'],
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.normal,
                                        fontSize: 10,
                                      ),
                                      children: const [
                                        pw.TextSpan(
                                          text: '\n',
                                          style: pw.TextStyle(
                                            fontSize: 5,
                                          ),
                                        )
                                      ]),
                                  companyTaxMode == 'INDIA'
                                      ? pw.TextSpan(
                                          text: dataInformation['Add4'],
                                          style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.normal,
                                            fontSize: 10,
                                          ),
                                          children: const [
                                              pw.TextSpan(
                                                text: '\n',
                                                style: pw.TextStyle(
                                                  fontSize: 5,
                                                ),
                                              )
                                            ])
                                      : pw.TextSpan(
                                          text:
                                              'T-No :${dataInformation['gstno']}',
                                          style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.normal,
                                            fontSize: 10,
                                          ),
                                          children: const [
                                              pw.TextSpan(
                                                text: '\n',
                                                style: pw.TextStyle(
                                                  fontSize: 5,
                                                ),
                                              )
                                            ]),
                                  pw.TextSpan(
                                    text: dataInformation['Add3'],
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.normal,
                                      fontSize: 10,
                                    ),
                                  )
                                ])),
                          ),
                        ),
                      ]),
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.2),
                    defaultColumnWidth: const pw.IntrinsicColumnWidth(),
                    children: [
                      companyTaxMode == 'INDIA'
                          ? pw.TableRow(children: [
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[0],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[1],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[2],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[3],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[4],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[5],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[6],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[7],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[8],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[9],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[10],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[11],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                            ])
                          : pw.TableRow(children: [
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[0],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[1],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[2],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[3],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[4],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[5],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[6],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[7],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[8],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[9],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[10],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                            ]),
                      for (var i = 0; i < dataParticulars.length; i++)
                        // dataParticulars
                        companyTaxMode == 'INDIA'
                            ? pw.TableRow(children: [
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['ItemId']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['ProductName'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['hsncode'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['RealPrate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['Qty']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                isItemSerialNo
                                    ? pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['serialno']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ])
                                    : pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['unitName']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['PRate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Net']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['tax']} %',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['CGST']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['SGST']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Total']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                              ])
                            : pw.TableRow(children: [
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['ItemId']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      ),
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['ProductName'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      ),
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['hsncode'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['RealPrate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['Qty']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                isItemSerialNo
                                    ? pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['serialno']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ])
                                    : pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['unitName']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['PRate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Net']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['tax']} %',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['tax']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Total']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                              ])
                    ],
                  ),
                  pw.SizedBox(
                    height: 40.0,
                  ),
                  pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      companyTaxMode == 'INDIA'
                          ? pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                    'CESS : ${double.tryParse(dataInformation['Cess'].toString()).toStringAsFixed(decimal)} CGST : ${double.tryParse(dataInformation['CGST'].toString()).toStringAsFixed(decimal)} SGST : ${double.tryParse(dataInformation['SGST'].toString()).toStringAsFixed(decimal)} = ${(double.tryParse(dataInformation['Cess'].toString()) + double.tryParse(dataInformation['CGST'].toString()) + double.tryParse(dataInformation['SGST'].toString())).toStringAsFixed(decimal)}'),
                              ],
                            )
                          : pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                    'VAT : ${double.tryParse(dataInformation['tax'].toString()).toStringAsFixed(decimal)}'),
                              ],
                            ),
                      /**other amount**/
                      // otherAmount.length>0 ?
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('***Discount***'),
                        ],
                      ),
                      _addOtherAmountPDF(otherAmount),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
                              style: pw.TextStyle(
                                  color: PdfColors.black,
                                  fontSize: 19,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Bill Balance : ${double.tryParse((double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toString()).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Old Balance : ${double.tryParse(customerBalance.toString()).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Balance : ${double.tryParse(((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toString()).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                  byteImageQr != null
                      ? pw.Image(imageQr,
                          height: 100,
                          width:
                              100) //Image.provider(imageQr, width: 100, height: 100)
                      : pw.Header(text: ''),
                  pw.Container(
                      alignment: pw.Alignment.center,
                      child: pw.Text(data['message'],
                          textAlign: pw.TextAlign.center))
                ],
            footer: _buildFooter))
        : pdf.addPage(pw.MultiPage(
            maxPages: 100,
            header: (context) => pw.Column(children: [
                  pw.Container(
                    height: 20,
                    padding: const pw.EdgeInsets.all(10),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      invoiceHead,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    alignment: pw.Alignment.center,
                    height: 10,
                    child: pw.GridView(
                      crossAxisCount: 2,
                      children: [
                        pw.Text('EntryNo : ' + dataInformation['InvoiceNo'],
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                            textAlign: pw.TextAlign.left),
                        pw.Text(
                            'Date : ' +
                                DateUtil.dateDMY(dataInformation['DDate']),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                            textAlign: pw.TextAlign.right),
                      ],
                    ),
                  ),
                  if (context.pageNumber > 1) pw.SizedBox(height: 20)
                ]),
            build: (context) => [
                  /*customer*/
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(left: 10, right: 10),
                          height: 70,
                          child: pw.Text(
                            'Bill to:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Expanded(
                            child: pw.Container(
                                height: 50,
                                child: pw.RichText(
                                    text: pw.TextSpan(
                                        text: '${dataInformation['ToName']}\n',
                                        style: pw.TextStyle(
                                          // color: _darkColor,
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        children: [
                                      const pw.TextSpan(
                                        text: '\n',
                                        style: pw.TextStyle(
                                          fontSize: 5,
                                        ),
                                      ),
                                      pw.TextSpan(
                                        text: dataInformation['Add2']
                                                .toString()
                                                .isEmpty
                                            ? dataInformation['Add1']
                                            : dataInformation['Add1'] +
                                                '\n' +
                                                dataInformation['Add2'],
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.normal,
                                          fontSize: 10,
                                        ),
                                      )
                                    ])))),
                      ]),
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.2),
                    children: [
                      pw.TableRow(children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[0],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[1],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[2],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[3],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[4],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[5],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                      ]),
                      for (var i = 0; i < dataParticulars.length; i++)
                        pw.TableRow(children: [
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      '${dataParticulars[i]['ItemId']}',
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ),
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      dataParticulars[i]['ProductName'],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ),
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      double.tryParse(dataParticulars[i]
                                                  ['PRate']
                                              .toString())
                                          .toStringAsFixed(decimal),
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                )
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      dataParticulars[i]['Qty']
                                          .toStringAsFixed(decimal),
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                )
                              ]),
                          isItemSerialNo
                              ? pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['serialno']
                                                .toString(),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ])
                              : pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['unitName']
                                                .toString(),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      double.tryParse(dataParticulars[i]
                                                  ['Total']
                                              .toString())
                                          .toStringAsFixed(decimal),
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                )
                              ]),
                        ])
                    ],
                  ),
                  pw.SizedBox(
                    height: 40.0,
                  ),
                  pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      /**other amount**/
                      // otherAmount.length>0 ?
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(''),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('***Discount***'),
                        ],
                      ),
                      _addOtherAmountPDF(otherAmount),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'TOTAL : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
                              style: pw.TextStyle(
                                  // color: Colors.black,
                                  fontSize: 19,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Bill Balance : ${(double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Old Balance : ${double.tryParse(customerBalance).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Balance : ${((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                      alignment: pw.Alignment.center,
                      child: pw.Text(data['message'],
                          textAlign: pw.TextAlign.center))
                ],
            footer: _buildFooter));
  } else if (model == 6) {
    taxSale
        ? pdf.addPage(pw.MultiPage(
            /*company*/
            maxPages: 100,
            header: (context) => pw.Column(children: [
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Expanded(
                            child: pw.Column(children: [
                          pw.Container(
                            height: 20,
                            padding: const pw.EdgeInsets.all(8),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              invoiceHead,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 25,
                              ),
                            ),
                          ),
                          pw.Container(
                              height: 80,
                              padding: const pw.EdgeInsets.all(8),
                              alignment: pw.Alignment.center,
                              child: pw.RichText(
                                  textAlign: pw.TextAlign.center,
                                  text: pw.TextSpan(
                                      text: '${companySettings.name}\n',
                                      style: pw.TextStyle(
                                        // color: _darkColor,
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      children: [
                                        const pw.TextSpan(
                                          text: '\n',
                                          style: pw.TextStyle(
                                            fontSize: 5,
                                          ),
                                        ),
                                        pw.TextSpan(
                                            text: companySettings.add2
                                                    .toString()
                                                    .isEmpty
                                                ? companySettings.add1
                                                : companySettings.add1 +
                                                    '\n' +
                                                    companySettings.add2,
                                            style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                            children: [
                                              companySettings.telephone
                                                      .toString()
                                                      .isNotEmpty
                                                  ? pw.TextSpan(
                                                      text: companySettings
                                                          .telephone,
                                                      children: [
                                                          companySettings.mobile
                                                                  .toString()
                                                                  .isNotEmpty ??
                                                              pw.TextSpan(
                                                                  text: ', ' +
                                                                      companySettings
                                                                          .mobile),
                                                        ])
                                                  : const pw.TextSpan(
                                                      text: '\n',
                                                      style: pw.TextStyle(
                                                        fontSize: 5,
                                                      ),
                                                    ),
                                            ]),
                                        pw.TextSpan(
                                          text:
                                              '${ComSettings.getValue('GST-NO', settings)}',
                                          style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ]))),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            alignment: pw.Alignment.center,
                            height: 10,
                            child: pw.GridView(
                              crossAxisCount: 2,
                              children: [
                                pw.Text(
                                    'Invoice : ' + dataInformation['InvoiceNo'],
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    textAlign: pw.TextAlign.left),
                                pw.Text(
                                    'Date : ' +
                                        DateUtil.dateDMY(
                                            dataInformation['DDate']),
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    textAlign: pw.TextAlign.right),
                              ],
                            ),
                          ),
                        ])),
                      ]),
                  if (context.pageNumber > 1) pw.SizedBox(height: 20)
                ]),
            build: (context) => [
                  /*customer*/
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(left: 10, right: 10),
                          height: 70,
                          child: pw.Text(
                            'Bill to:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Container(
                            height: 70,
                            child: pw.RichText(
                                text: pw.TextSpan(
                                    text: '${dataInformation['ToName']}\n',
                                    style: pw.TextStyle(
                                      // color: _darkColor,
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    children: [
                                  const pw.TextSpan(
                                    text: '\n',
                                    style: pw.TextStyle(
                                      fontSize: 5,
                                    ),
                                  ),
                                  pw.TextSpan(
                                      text: dataInformation['Add2']
                                              .toString()
                                              .isEmpty
                                          ? dataInformation['Add1']
                                          : dataInformation['Add1'] +
                                              '\n' +
                                              dataInformation['Add2'],
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.normal,
                                        fontSize: 10,
                                      ),
                                      children: const [
                                        pw.TextSpan(
                                          text: '\n',
                                          style: pw.TextStyle(
                                            fontSize: 5,
                                          ),
                                        )
                                      ]),
                                  companyTaxMode == 'INDIA'
                                      ? pw.TextSpan(
                                          text: dataInformation['Add4'],
                                          style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.normal,
                                            fontSize: 10,
                                          ),
                                          children: const [
                                              pw.TextSpan(
                                                text: '\n',
                                                style: pw.TextStyle(
                                                  fontSize: 5,
                                                ),
                                              )
                                            ])
                                      : pw.TextSpan(
                                          text:
                                              'T-No :${dataInformation['gstno']}',
                                          style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.normal,
                                            fontSize: 10,
                                          ),
                                          children: const [
                                              pw.TextSpan(
                                                text: '\n',
                                                style: pw.TextStyle(
                                                  fontSize: 5,
                                                ),
                                              )
                                            ]),
                                  pw.TextSpan(
                                    text: dataInformation['Add3'],
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.normal,
                                      fontSize: 10,
                                    ),
                                  )
                                ])),
                          ),
                        ),
                      ]),
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.2),
                    defaultColumnWidth: const pw.IntrinsicColumnWidth(),
                    children: [
                      companyTaxMode == 'INDIA'
                          ? pw.TableRow(children: [
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[0],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[1],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[2],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[3],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[4],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[5],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[6],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[7],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[8],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[9],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[10],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[11],
                                        style: const pw.TextStyle(fontSize: 9)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                            ])
                          : pw.TableRow(children: [
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[0],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[1],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[2],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[3],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[4],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[5],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[6],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[7],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[8],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[9],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(tableHeaders[10],
                                        style: pw.TextStyle(
                                            fontSize: 9,
                                            fontWeight: pw.FontWeight.bold)),
                                    // pw.Divider(thickness: 1)
                                  ]),
                            ]),
                      for (var i = 0; i < dataParticulars.length; i++)
                        // dataParticulars
                        companyTaxMode == 'INDIA'
                            ? pw.TableRow(children: [
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['ItemId']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['ProductName'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['hsncode'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['RealPrate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['Qty']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                isItemSerialNo
                                    ? pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['serialno']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ])
                                    : pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['unitName']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['PRate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Net']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['tax']} %',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['CGST']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['SGST']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Total']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                              ])
                            : pw.TableRow(children: [
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['ItemId']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      ),
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['ProductName'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      ),
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['hsncode'],
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['RealPrate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['Qty']}',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                isItemSerialNo
                                    ? pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['serialno']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ])
                                    : pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.center,
                                        children: [
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.all(2.0),
                                              child: pw.Text(
                                                  dataParticulars[i]['unitName']
                                                      .toString(),
                                                  style: const pw.TextStyle(
                                                      fontSize: 9)),
                                              // pw.Divider(thickness: 1)
                                            )
                                          ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['PRate']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Net']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            '${dataParticulars[i]['tax']} %',
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['tax']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            double.tryParse(dataParticulars[i]
                                                        ['Total']
                                                    .toString())
                                                .toStringAsFixed(decimal),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                              ])
                    ],
                  ),
                  pw.SizedBox(
                    height: 40.0,
                  ),
                  pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      companyTaxMode == 'INDIA'
                          ? pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                    'CESS : ${double.tryParse(dataInformation['Cess'].toString()).toStringAsFixed(decimal)} CGST : ${double.tryParse(dataInformation['CGST'].toString()).toStringAsFixed(decimal)} SGST : ${double.tryParse(dataInformation['SGST'].toString()).toStringAsFixed(decimal)} = ${(double.tryParse(dataInformation['Cess'].toString()) + double.tryParse(dataInformation['CGST'].toString()) + double.tryParse(dataInformation['SGST'].toString())).toStringAsFixed(decimal)}'),
                              ],
                            )
                          : pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                    'VAT : ${double.tryParse(dataInformation['tax'].toString()).toStringAsFixed(decimal)}'),
                              ],
                            ),
                      /**other amount**/
                      // otherAmount.length>0 ?
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('***Discount***'),
                        ],
                      ),
                      _addOtherAmountPDF(otherAmount),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
                              style: pw.TextStyle(
                                  color: PdfColors.black,
                                  fontSize: 19,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Bill Balance : ${double.tryParse((double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toString()).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Old Balance : ${double.tryParse(customerBalance.toString()).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Balance : ${double.tryParse(((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toString()).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                  byteImageQr != null
                      ? pw.Image(imageQr,
                          height: 100,
                          width:
                              100) //Image.provider(imageQr, width: 100, height: 100)
                      : pw.Header(text: ''),
                  pw.Container(
                      alignment: pw.Alignment.center,
                      child: pw.Text(data['message'],
                          textAlign: pw.TextAlign.center))
                ],
            footer: _buildFooter))
        : pdf.addPage(pw.MultiPage(
            maxPages: 100,
            header: (context) => pw.Column(children: [
                  pw.Container(
                    height: 20,
                    padding: const pw.EdgeInsets.all(10),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      invoiceHead,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    alignment: pw.Alignment.center,
                    height: 10,
                    child: pw.GridView(
                      crossAxisCount: 2,
                      children: [
                        pw.Text('EntryNo : ' + dataInformation['InvoiceNo'],
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                            textAlign: pw.TextAlign.left),
                        pw.Text(
                            'Date : ' +
                                DateUtil.dateDMY(dataInformation['DDate']),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                            textAlign: pw.TextAlign.right),
                      ],
                    ),
                  ),
                  if (context.pageNumber > 1) pw.SizedBox(height: 20)
                ]),
            build: (context) => [
                  /*customer*/
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(left: 10, right: 10),
                          height: 70,
                          child: pw.Text(
                            'Bill to:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Expanded(
                            child: pw.Container(
                                height: 50,
                                child: pw.RichText(
                                    text: pw.TextSpan(
                                        text: '${dataInformation['ToName']}\n',
                                        style: pw.TextStyle(
                                          // color: _darkColor,
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        children: [
                                      const pw.TextSpan(
                                        text: '\n',
                                        style: pw.TextStyle(
                                          fontSize: 5,
                                        ),
                                      ),
                                      pw.TextSpan(
                                        text: dataInformation['Add2']
                                                .toString()
                                                .isEmpty
                                            ? dataInformation['Add1']
                                            : dataInformation['Add1'] +
                                                '\n' +
                                                dataInformation['Add2'],
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.normal,
                                          fontSize: 10,
                                        ),
                                      )
                                    ])))),
                      ]),
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.2),
                    children: [
                      pw.TableRow(children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[0],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[1],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[2],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[3],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[4],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(tableHeaders[5],
                                  style: const pw.TextStyle(fontSize: 9)),
                              // pw.Divider(thickness: 1)
                            ]),
                      ]),
                      for (var i = 0; i < dataParticulars.length; i++)
                        pw.TableRow(children: [
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      '${dataParticulars[i]['ItemId']}',
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ),
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      dataParticulars[i]['ProductName'],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ),
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      double.tryParse(dataParticulars[i]
                                                  ['PRate']
                                              .toString())
                                          .toStringAsFixed(decimal),
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                )
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      dataParticulars[i]['Qty']
                                          .toStringAsFixed(decimal),
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                )
                              ]),
                          isItemSerialNo
                              ? pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['serialno']
                                                .toString(),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ])
                              : pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(2.0),
                                        child: pw.Text(
                                            dataParticulars[i]['unitName']
                                                .toString(),
                                            style: const pw.TextStyle(
                                                fontSize: 9)),
                                        // pw.Divider(thickness: 1)
                                      )
                                    ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                      double.tryParse(dataParticulars[i]
                                                  ['Total']
                                              .toString())
                                          .toStringAsFixed(decimal),
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                )
                              ]),
                        ])
                    ],
                  ),
                  pw.SizedBox(
                    height: 40.0,
                  ),
                  pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      /**other amount**/
                      // otherAmount.length>0 ?
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(''),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('***Discount***'),
                        ],
                      ),
                      _addOtherAmountPDF(otherAmount),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'TOTAL : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                              'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
                              style: pw.TextStyle(
                                  // color: Colors.black,
                                  fontSize: 19,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Bill Balance : ${(double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Old Balance : ${double.tryParse(customerBalance).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Balance : ${((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toStringAsFixed(decimal)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                      alignment: pw.Alignment.center,
                      child: pw.Text(data['message'],
                          textAlign: pw.TextAlign.center))
                ],
            footer: _buildFooter));
  } else {
    taxSale
        // ? pdf.addPage(pw.MultiPage(
        //     /*company*/
        //     maxPages: 100,
        //     header: (context) => pw.Column(children: [
        //           pw.Row(
        //               crossAxisAlignment: pw.CrossAxisAlignment.center,
        //               children: [
        //                 pw.Expanded(
        //                     child: pw.Column(children: [
        //                   pw.Container(
        //                     height: 20,
        //                     padding: const pw.EdgeInsets.all(8),
        //                     alignment: pw.Alignment.center,
        //                     child: pw.Text(
        //                       invoiceHead,
        //                       style: pw.TextStyle(
        //                         fontWeight: pw.FontWeight.bold,
        //                         fontSize: 25,
        //                       ),
        //                     ),
        //                   ),
        //                   pw.Container(
        //                       height: 80,
        //                       padding: const pw.EdgeInsets.all(8),
        //                       alignment: pw.Alignment.center,
        //                       child: pw.RichText(
        //                           textAlign: pw.TextAlign.center,
        //                           text: pw.TextSpan(
        //                               text: '${companySettings.name}\n',
        //                               style: pw.TextStyle(
        //                                 // color: _darkColor,
        //                                 fontWeight: pw.FontWeight.bold,
        //                                 fontSize: 15,
        //                               ),
        //                               children: [
        //                                 const pw.TextSpan(
        //                                   text: '\n',
        //                                   style: pw.TextStyle(
        //                                     fontSize: 5,
        //                                   ),
        //                                 ),
        //                                 pw.TextSpan(
        //                                     text: companySettings.add2
        //                                             .toString()
        //                                             .isEmpty
        //                                         ? companySettings.add1
        //                                         : companySettings.add1 +
        //                                             '\n' +
        //                                             companySettings.add2,
        //                                     style: pw.TextStyle(
        //                                       fontWeight: pw.FontWeight.bold,
        //                                       fontSize: 10,
        //                                     ),
        //                                     children: [
        //                                       companySettings.telephone
        //                                               .toString()
        //                                               .isNotEmpty
        //                                           ? pw.TextSpan(
        //                                               text: companySettings
        //                                                   .telephone,
        //                                               children: [
        //                                                   companySettings.mobile
        //                                                           .toString()
        //                                                           .isNotEmpty ??
        //                                                       pw.TextSpan(
        //                                                           text: ', ' +
        //                                                               companySettings
        //                                                                   .mobile),
        //                                                 ])
        //                                           : const pw.TextSpan(
        //                                               text: '\n',
        //                                               style: pw.TextStyle(
        //                                                 fontSize: 5,
        //                                               ),
        //                                             ),
        //                                     ]),
        //                                 pw.TextSpan(
        //                                   text:
        //                                       '${ComSettings.getValue('GST-NO', settings)}',
        //                                   style: pw.TextStyle(
        //                                     fontWeight: pw.FontWeight.bold,
        //                                     fontSize: 10,
        //                                   ),
        //                                 ),
        //                               ]))),
        //                   pw.Container(
        //                     padding: const pw.EdgeInsets.all(10),
        //                     alignment: pw.Alignment.center,
        //                     height: 10,
        //                     child: pw.GridView(
        //                       crossAxisCount: 2,
        //                       children: [
        //                         pw.Text(
        //                             'Invoice : ' + dataInformation['InvoiceNo'],
        //                             style: pw.TextStyle(
        //                               fontWeight: pw.FontWeight.bold,
        //                               fontSize: 10,
        //                             ),
        //                             textAlign: pw.TextAlign.left),
        //                         pw.Text(
        //                             'Date : ' +
        //                                 DateUtil.dateDMY(
        //                                     dataInformation['DDate']),
        //                             style: pw.TextStyle(
        //                               fontWeight: pw.FontWeight.bold,
        //                               fontSize: 10,
        //                             ),
        //                             textAlign: pw.TextAlign.right),
        //                       ],
        //                     ),
        //                   ),
        //                 ])),
        //               ]),
        //           if (context.pageNumber > 1) pw.SizedBox(height: 20)
        //         ]),
        //     build: (context) => [
        //           /*customer*/
        //           pw.Row(
        //               crossAxisAlignment: pw.CrossAxisAlignment.start,
        //               children: [
        //                 pw.Container(
        //                   margin: const pw.EdgeInsets.only(left: 10, right: 10),
        //                   height: 70,
        //                   child: pw.Text(
        //                     'Bill to:',
        //                     style: pw.TextStyle(
        //                       fontWeight: pw.FontWeight.bold,
        //                       fontSize: 12,
        //                     ),
        //                   ),
        //                 ),
        //                 pw.Expanded(
        //                   child: pw.Container(
        //                     height: 70,
        //                     child: pw.RichText(
        //                         text: pw.TextSpan(
        //                             text: '${dataInformation['ToName']}\n',
        //                             style: pw.TextStyle(
        //                               // color: _darkColor,
        //                               fontWeight: pw.FontWeight.bold,
        //                               fontSize: 12,
        //                             ),
        //                             children: [
        //                           const pw.TextSpan(
        //                             text: '\n',
        //                             style: pw.TextStyle(
        //                               fontSize: 5,
        //                             ),
        //                           ),
        //                           pw.TextSpan(
        //                               text: dataInformation['Add2']
        //                                       .toString()
        //                                       .isEmpty
        //                                   ? dataInformation['Add1']
        //                                   : dataInformation['Add1'] +
        //                                       '\n' +
        //                                       dataInformation['Add2'],
        //                               style: pw.TextStyle(
        //                                 fontWeight: pw.FontWeight.normal,
        //                                 fontSize: 10,
        //                               ),
        //                               children: const [
        //                                 pw.TextSpan(
        //                                   text: '\n',
        //                                   style: pw.TextStyle(
        //                                     fontSize: 5,
        //                                   ),
        //                                 )
        //                               ]),
        //                           companyTaxMode == 'INDIA'
        //                               ? pw.TextSpan(
        //                                   text: dataInformation['Add4'],
        //                                   style: pw.TextStyle(
        //                                     fontWeight: pw.FontWeight.normal,
        //                                     fontSize: 10,
        //                                   ),
        //                                   children: const [
        //                                       pw.TextSpan(
        //                                         text: '\n',
        //                                         style: pw.TextStyle(
        //                                           fontSize: 5,
        //                                         ),
        //                                       )
        //                                     ])
        //                               : pw.TextSpan(
        //                                   text:
        //                                       'T-No :${dataInformation['gstno']}',
        //                                   style: pw.TextStyle(
        //                                     fontWeight: pw.FontWeight.normal,
        //                                     fontSize: 10,
        //                                   ),
        //                                   children: const [
        //                                       pw.TextSpan(
        //                                         text: '\n',
        //                                         style: pw.TextStyle(
        //                                           fontSize: 5,
        //                                         ),
        //                                       )
        //                                     ]),
        //                           pw.TextSpan(
        //                             text: dataInformation['Add3'],
        //                             style: pw.TextStyle(
        //                               fontWeight: pw.FontWeight.normal,
        //                               fontSize: 10,
        //                             ),
        //                           )
        //                         ])),
        //                   ),
        //                 ),
        //               ]),
        //           pw.Table(
        //             border: pw.TableBorder.all(width: 0.2),
        //             defaultColumnWidth: const pw.IntrinsicColumnWidth(),
        //             children: [
        //               companyTaxMode == 'INDIA'
        //                   ? pw.TableRow(children: [
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[0],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[1],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[2],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[3],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[4],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[5],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[6],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[7],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[8],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[9],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[10],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[11],
        //                                 style: const pw.TextStyle(fontSize: 9)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                     ])
        //                   : pw.TableRow(children: [
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[0],
        //                                 style: pw.TextStyle(
        //                                     fontSize: 9,
        //                                     fontWeight: pw.FontWeight.bold)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[1],
        //                                 style: pw.TextStyle(
        //                                     fontSize: 9,
        //                                     fontWeight: pw.FontWeight.bold)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[2],
        //                                 style: pw.TextStyle(
        //                                     fontSize: 9,
        //                                     fontWeight: pw.FontWeight.bold)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[3],
        //                                 style: pw.TextStyle(
        //                                     fontSize: 9,
        //                                     fontWeight: pw.FontWeight.bold)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[4],
        //                                 style: pw.TextStyle(
        //                                     fontSize: 9,
        //                                     fontWeight: pw.FontWeight.bold)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[5],
        //                                 style: pw.TextStyle(
        //                                     fontSize: 9,
        //                                     fontWeight: pw.FontWeight.bold)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[6],
        //                                 style: pw.TextStyle(
        //                                     fontSize: 9,
        //                                     fontWeight: pw.FontWeight.bold)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[7],
        //                                 style: pw.TextStyle(
        //                                     fontSize: 9,
        //                                     fontWeight: pw.FontWeight.bold)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[8],
        //                                 style: pw.TextStyle(
        //                                     fontSize: 9,
        //                                     fontWeight: pw.FontWeight.bold)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[9],
        //                                 style: pw.TextStyle(
        //                                     fontSize: 9,
        //                                     fontWeight: pw.FontWeight.bold)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.center,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Text(tableHeaders[10],
        //                                 style: pw.TextStyle(
        //                                     fontSize: 9,
        //                                     fontWeight: pw.FontWeight.bold)),
        //                             // pw.Divider(thickness: 1)
        //                           ]),
        //                     ]),
        //               for (var i = 0; i < dataParticulars.length; i++)
        //                 // dataParticulars
        //                 companyTaxMode == 'INDIA'
        //                     ? pw.TableRow(children: [
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     '${dataParticulars[i]['ItemId']}',
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.start,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     dataParticulars[i]['ProductName'],
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.start,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     dataParticulars[i]['hsncode'],
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     double.tryParse(dataParticulars[i]
        //                                                 ['RealPrate']
        //                                             .toString())
        //                                         .toStringAsFixed(decimal),
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     '${dataParticulars[i]['Qty']}',
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         isItemSerialNo
        //                             ? pw.Column(
        //                                 crossAxisAlignment:
        //                                     pw.CrossAxisAlignment.center,
        //                                 mainAxisAlignment:
        //                                     pw.MainAxisAlignment.center,
        //                                 children: [
        //                                     pw.Padding(
        //                                       padding:
        //                                           const pw.EdgeInsets.all(2.0),
        //                                       child: pw.Text(
        //                                           dataParticulars[i]['serialno']
        //                                               .toString(),
        //                                           style: const pw.TextStyle(
        //                                               fontSize: 9)),
        //                                       // pw.Divider(thickness: 1)
        //                                     )
        //                                   ])
        //                             : pw.Column(
        //                                 crossAxisAlignment:
        //                                     pw.CrossAxisAlignment.center,
        //                                 mainAxisAlignment:
        //                                     pw.MainAxisAlignment.center,
        //                                 children: [
        //                                     pw.Padding(
        //                                       padding:
        //                                           const pw.EdgeInsets.all(2.0),
        //                                       child: pw.Text(
        //                                           dataParticulars[i]['unitName']
        //                                               .toString(),
        //                                           style: const pw.TextStyle(
        //                                               fontSize: 9)),
        //                                       // pw.Divider(thickness: 1)
        //                                     )
        //                                   ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     double.tryParse(dataParticulars[i]
        //                                                 ['PRate']
        //                                             .toString())
        //                                         .toStringAsFixed(decimal),
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     double.tryParse(dataParticulars[i]
        //                                                 ['Net']
        //                                             .toString())
        //                                         .toStringAsFixed(decimal),
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     '${dataParticulars[i]['tax']} %',
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     double.tryParse(dataParticulars[i]
        //                                                 ['CGST']
        //                                             .toString())
        //                                         .toStringAsFixed(decimal),
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     double.tryParse(dataParticulars[i]
        //                                                 ['SGST']
        //                                             .toString())
        //                                         .toStringAsFixed(decimal),
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     double.tryParse(dataParticulars[i]
        //                                                 ['Total']
        //                                             .toString())
        //                                         .toStringAsFixed(decimal),
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                       ])
        //                     : pw.TableRow(children: [
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     '${dataParticulars[i]['ItemId']}',
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               ),
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.start,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     dataParticulars[i]['ProductName'],
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               ),
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.start,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     dataParticulars[i]['hsncode'],
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     double.tryParse(dataParticulars[i]
        //                                                 ['RealPrate']
        //                                             .toString())
        //                                         .toStringAsFixed(decimal),
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     '${dataParticulars[i]['Qty']}',
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         isItemSerialNo
        //                             ? pw.Column(
        //                                 crossAxisAlignment:
        //                                     pw.CrossAxisAlignment.center,
        //                                 mainAxisAlignment:
        //                                     pw.MainAxisAlignment.center,
        //                                 children: [
        //                                     pw.Padding(
        //                                       padding:
        //                                           const pw.EdgeInsets.all(2.0),
        //                                       child: pw.Text(
        //                                           dataParticulars[i]['serialno']
        //                                               .toString(),
        //                                           style: const pw.TextStyle(
        //                                               fontSize: 9)),
        //                                       // pw.Divider(thickness: 1)
        //                                     )
        //                                   ])
        //                             : pw.Column(
        //                                 crossAxisAlignment:
        //                                     pw.CrossAxisAlignment.center,
        //                                 mainAxisAlignment:
        //                                     pw.MainAxisAlignment.center,
        //                                 children: [
        //                                     pw.Padding(
        //                                       padding:
        //                                           const pw.EdgeInsets.all(2.0),
        //                                       child: pw.Text(
        //                                           dataParticulars[i]['unitName']
        //                                               .toString(),
        //                                           style: const pw.TextStyle(
        //                                               fontSize: 9)),
        //                                       // pw.Divider(thickness: 1)
        //                                     )
        //                                   ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     double.tryParse(dataParticulars[i]
        //                                                 ['PRate']
        //                                             .toString())
        //                                         .toStringAsFixed(decimal),
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     double.tryParse(dataParticulars[i]
        //                                                 ['Net']
        //                                             .toString())
        //                                         .toStringAsFixed(decimal),
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     '${dataParticulars[i]['tax']} %',
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     double.tryParse(dataParticulars[i]
        //                                                 ['tax']
        //                                             .toString())
        //                                         .toStringAsFixed(decimal),
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                         pw.Column(
        //                             crossAxisAlignment:
        //                                 pw.CrossAxisAlignment.end,
        //                             mainAxisAlignment:
        //                                 pw.MainAxisAlignment.center,
        //                             children: [
        //                               pw.Padding(
        //                                 padding: const pw.EdgeInsets.all(2.0),
        //                                 child: pw.Text(
        //                                     double.tryParse(dataParticulars[i]
        //                                                 ['Total']
        //                                             .toString())
        //                                         .toStringAsFixed(decimal),
        //                                     style: const pw.TextStyle(
        //                                         fontSize: 9)),
        //                                 // pw.Divider(thickness: 1)
        //                               )
        //                             ]),
        //                       ])
        //             ],
        //           ),
        //           pw.SizedBox(
        //             height: 40.0,
        //           ),
        //           pw.Column(
        //             children: [
        //               pw.Row(
        //                 mainAxisAlignment: pw.MainAxisAlignment.end,
        //                 children: [
        //                   pw.Text(
        //                       'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
        //                 ],
        //               ),
        //               companyTaxMode == 'INDIA'
        //                   ? pw.Row(
        //                       mainAxisAlignment: pw.MainAxisAlignment.end,
        //                       children: [
        //                         pw.Text(
        //                             'CESS : ${double.tryParse(dataInformation['Cess'].toString()).toStringAsFixed(decimal)} CGST : ${double.tryParse(dataInformation['CGST'].toString()).toStringAsFixed(decimal)} SGST : ${double.tryParse(dataInformation['SGST'].toString()).toStringAsFixed(decimal)} = ${(double.tryParse(dataInformation['Cess'].toString()) + double.tryParse(dataInformation['CGST'].toString()) + double.tryParse(dataInformation['SGST'].toString())).toStringAsFixed(decimal)}'),
        //                       ],
        //                     )
        //                   : pw.Row(
        //                       mainAxisAlignment: pw.MainAxisAlignment.end,
        //                       children: [
        //                         pw.Text(
        //                             'VAT : ${double.tryParse(dataInformation['tax'].toString()).toStringAsFixed(decimal)}'),
        //                       ],
        //                     ),
        //               /**other amount**/
        //               // otherAmount.length>0 ?
        //               pw.Row(
        //                 mainAxisAlignment: pw.MainAxisAlignment.end,
        //                 children: [
        //                   pw.Text('***Discount***'),
        //                 ],
        //               ),
        //               _addOtherAmountPDF(otherAmount),
        //               pw.Row(
        //                 mainAxisAlignment: pw.MainAxisAlignment.end,
        //                 children: [
        //                   pw.Text(
        //                       'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
        //                 ],
        //               ),
        //               pw.Row(
        //                 mainAxisAlignment: pw.MainAxisAlignment.end,
        //                 children: [
        //                   pw.Text(
        //                       'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
        //                       style: pw.TextStyle(
        //                           color: PdfColors.black,
        //                           fontSize: 19,
        //                           fontWeight: pw.FontWeight.bold)),
        //                 ],
        //               ),
        //               pw.Row(
        //                 children: [
        //                   pw.Text(
        //                     'Bill Balance : ${double.tryParse((double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toString()).toStringAsFixed(decimal)}',
        //                   ),
        //                 ],
        //               ),
        //               pw.Row(
        //                 children: [
        //                   pw.Text(
        //                     'Old Balance : ${double.tryParse(customerBalance.toString()).toStringAsFixed(decimal)}',
        //                   ),
        //                 ],
        //               ),
        //               pw.Row(
        //                 children: [
        //                   pw.Text(
        //                     'Balance : ${double.tryParse(((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toString()).toStringAsFixed(decimal)}',
        //                   ),
        //                 ],
        //               ),
        //             ],
        //           ),
        //           byteImageQr != null
        //               ? pw.Image(imageQr,
        //                   height: 100,
        //                   width:
        //                       100) //Image.provider(imageQr, width: 100, height: 100)
        //               : pw.Header(text: ''),
        //           pw.Container(
        //               alignment: pw.Alignment.center,
        //               child: pw.Text(data['message'],
        //                   textAlign: pw.TextAlign.center))
        //         ],
        //     footer: _buildFooter))
        ? pdf.addPage(pw.MultiPage(
            maxPages: 100,
            pageFormat: pw.PdfPageFormat.a4,
            header: (pw.Context context) => _buildHeaderr(context,
                companySettings, settings, dataLedger, dataInformation),
            footer: (pw.Context context) => _buildFooterr(
                context,
                dataBankLedger,
                dataInformation,
                companySettings,
                customerBalance,
                dataInformation),
            build: (pw.Context context) {
              double calculateTotalQuantity(List<dynamic> perticu) {
                return perticu.fold(
                    0, (total, particular) => total + particular['Qty']);
              }

              double calculateTotalTaxablevalue(List<dynamic> perticu) {
                return perticu.fold(
                    0,
                    (total, particular) =>
                        total + particular['Net'].toDouble());
              }

              double calculateTotalAmount(List<dynamic> perticu) {
                return perticu.fold(
                    0,
                    (total, particular) =>
                        total + particular['Total'].toDouble());
              }

              double calculateTotalCGST(List<dynamic> perticu) {
                return perticu.fold(
                    0,
                    (total, particular) =>
                        total + particular['CGST'].toDouble());
              }

              double calculateTotalSGST(List<dynamic> perticu) {
                return perticu.fold(
                    0,
                    (total, particular) =>
                        total + particular['SGST'].toDouble());
              }

              double calculateEstTotalAmount(List<dynamic> perticu) {
                return perticu.fold(
                    0,
                    (total, particular) =>
                        total + particular['Total'].toDouble());
              }

              double calculateEstTotalQuantity(List<dynamic> perticu) {
                return perticu.fold(
                    0,
                    (total, particular) =>
                        total + particular['Qty'].toDouble());
              }

              double totalQuantity = calculateTotalQuantity(dataParticulars);

              double totalTaxablevalue =
                  calculateTotalTaxablevalue(dataParticulars);
              double totalAmount = calculateTotalAmount(dataParticulars);
              double totalCGST = calculateTotalCGST(dataParticulars);
              double totalSGST = calculateTotalCGST(dataParticulars);
              double totalEstAmount = calculateEstTotalAmount(dataParticulars);
              double totalEstQuantity =
                  calculateEstTotalQuantity(dataParticulars);
              final int totalRowCount = 11; // Desired total row count
              final int existingRowCount = dataParticulars.length;

// Calculate the number of empty rows needed
              final int emptyRowCount = totalRowCount - existingRowCount;
              List<pw.Widget> widgets = [
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Table(
                    border: const pw.TableBorder(
                      horizontalInside: pw.BorderSide
                          .none, // Remove horizontal borders inside the table

                      verticalInside: pw.BorderSide(), // Keep vertical borders
                    ),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(10),
                      1: pw.FlexColumnWidth(22),
                      2: pw.FlexColumnWidth(7),
                      3: pw.FlexColumnWidth(7),
                      4: pw.FlexColumnWidth(7),
                      5: pw.FlexColumnWidth(10),
                      6: pw.FlexColumnWidth(10),
                      7: pw.FlexColumnWidth(6),
                      8: pw.FlexColumnWidth(9),
                      9: pw.FlexColumnWidth(6),
                      10: pw.FlexColumnWidth(9),
                      11: pw.FlexColumnWidth(6),
                      12: pw.FlexColumnWidth(9),
                      13: pw.FlexColumnWidth(15),
                    },
                    children: [
                      for (var i = 0; i < dataParticulars.length; i++)
                        pw.TableRow(children: [
                          pw.Center(
                              child: pw.Column(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  dataParticulars[i]['GridID'].toString(),
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          )),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Text(
                              dataParticulars[i]['ProductName'],
                              style: pw.TextStyle(
                                  fontSize: 5, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Text(
                              dataParticulars[i]['hsncode'],
                              style: pw.TextStyle(
                                  fontSize: 5, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  dataParticulars[i]['Qty'].toStringAsFixed(2),
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            // child: pw.Text(
                            //   dataParticulars[i]['unitName'],
                            //   style: pw.TextStyle(
                            //       fontSize: 5, fontWeight: pw.FontWeight.bold),
                            // ),
                            child: pw.Text(""),
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  dataParticulars[i]['RealPrate']
                                      .toStringAsFixed(2),
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  '${dataParticulars[i]['Net']}',
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Center(
                                  child: pw.Text(
                                    '${dataParticulars[i]['tax'] / 2}%',
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  dataParticulars[i]['CGST'].toStringAsFixed(2),
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Center(
                                  child: pw.Text(
                                    '${dataParticulars[i]['tax'] / 2}%',
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  dataParticulars[i]['SGST'].toStringAsFixed(2),
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Center(
                                  child: pw.Text(
                                    '0%',
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  '0.00',
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  dataParticulars[i]['Total']
                                      .toStringAsFixed(2),
                                  style: pw.TextStyle(
                                      fontSize: 6,
                                      color:
                                          const pw.PdfColor.fromInt(0xFF000000),
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ]),
                      for (var j = 0; j < emptyRowCount; j++)
                        pw.TableRow(children: [
                          pw.Center(
                              child: pw.Column(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  '\n',
                                  style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          )),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Text(
                              "",
                              style: pw.TextStyle(
                                  fontSize: 5, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Text(
                              "",
                              style: pw.TextStyle(
                                  fontSize: 5, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  "",
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Text(
                              "",
                              style: pw.TextStyle(
                                  fontSize: 5, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  "",
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  '',
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Center(
                                  child: pw.Text(
                                    '',
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  "",
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Center(
                                  child: pw.Text(
                                    '',
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  "",
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Center(
                                  child: pw.Text(
                                    '',
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  '',
                                  style: pw.TextStyle(
                                      fontSize: 5,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  "",
                                  style: pw.TextStyle(
                                      fontSize: 6,
                                      color:
                                          const pw.PdfColor.fromInt(0xFF000000),
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ]),
                      if (dataParticulars.length < 5)
                        for (var k = 0; k < 10; k++)
                          pw.TableRow(children: [
                            pw.Center(
                                child: pw.Column(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                    '\n',
                                    style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ],
                            )),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text(
                                "",
                                style: pw.TextStyle(
                                    fontSize: 5,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text(
                                "",
                                style: pw.TextStyle(
                                    fontSize: 5,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                    "",
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text(
                                "",
                                style: pw.TextStyle(
                                    fontSize: 5,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                    "",
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                    '',
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Center(
                                    child: pw.Text(
                                      '',
                                      style: pw.TextStyle(
                                          fontSize: 5,
                                          fontWeight: pw.FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                    "",
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Center(
                                    child: pw.Text(
                                      '',
                                      style: pw.TextStyle(
                                          fontSize: 5,
                                          fontWeight: pw.FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                    "",
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Center(
                                    child: pw.Text(
                                      '',
                                      style: pw.TextStyle(
                                          fontSize: 5,
                                          fontWeight: pw.FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                    '',
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                    "",
                                    style: pw.TextStyle(
                                        fontSize: 6,
                                        color: const pw.PdfColor.fromInt(
                                            0xFF000000),
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                    ],
                  ),
                ),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  height: 20, width: double.infinity,
                  // color: const pw.PdfColor.fromInt(0xFF808080), // Grey color
                  child: pw.Row(
                    children: [
                      pw.Container(
                        height: 20,
                        width: 121.5,
                        decoration: const pw.BoxDecoration(
                            border: pw.Border(
                                right: pw.BorderSide(), left: pw.BorderSide())),
                        child: pw.Center(
                          child: pw.Text(
                            " Total ",
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ),
                      pw.Container(
                        height: 20,
                        width: 27,
                        decoration: const pw.BoxDecoration(
                            border: pw.Border(right: pw.BorderSide())),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(right: 2.0),
                              child: pw.Text(
                                '${totalQuantity.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                    fontSize: 5,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                          height: 20,
                          width: 65.2,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(right: pw.BorderSide())),
                          child: pw.Center(
                            child: pw.Text(
                              " ",
                              style: const pw.TextStyle(fontSize: 5),
                            ),
                          )),
                      pw.Container(
                        height: 20,
                        width: 38.2,
                        decoration: const pw.BoxDecoration(
                            border: pw.Border(right: pw.BorderSide())),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(right: 2.0),
                              child: pw.Text(
                                '${totalTaxablevalue.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                    fontSize: 5,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        height: 20,
                        width: 58,
                        decoration: const pw.BoxDecoration(
                            border: pw.Border(right: pw.BorderSide())),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(right: 2.0),
                              child: pw.Text(
                                '${totalCGST.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                    fontSize: 5,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        height: 20,
                        width: 57.2,
                        decoration: const pw.BoxDecoration(
                            border: pw.Border(right: pw.BorderSide())),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(right: 2.0),
                              child: pw.Text(
                                '${totalSGST.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                    fontSize: 5,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        height: 20,
                        width: 57.5,
                        decoration: const pw.BoxDecoration(
                            border: pw.Border(right: pw.BorderSide())),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(right: 2.0),
                              child: pw.Text(
                                "0.00",
                                style: pw.TextStyle(
                                    fontSize: 5,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          height: 20,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(right: pw.BorderSide())),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Padding(
                                  padding: const pw.EdgeInsets.only(right: 2.0),
                                  child: pw.Text(
                                    '${totalAmount.toStringAsFixed(2)}',
                                    style: pw.TextStyle(
                                        fontSize: 5,
                                        fontWeight: pw.FontWeight.bold),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ];

              return widgets;
            },
          ))

        // : printHeaderOnES
        //     ? pdf.addPage(pw.MultiPage(
        //         maxPages: 100,
        //         header: (context) => pw.Column(children: [
        //               pw.Container(
        //                 height: 20,
        //                 padding: const pw.EdgeInsets.all(10),
        //                 alignment: pw.Alignment.center,
        //                 child: pw.Text(
        //                   invoiceHead,
        //                   style: pw.TextStyle(
        //                     fontWeight: pw.FontWeight.bold,
        //                     fontSize: 25,
        //                   ),
        //                 ),
        //               ),
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
        //                                 text: companySettings.add2
        //                                         .toString()
        //                                         .isEmpty
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
        //                                           text:
        //                                               companySettings.telephone,
        //                                           children: [
        //                                               companySettings.mobile
        //                                                       .toString()
        //                                                       .isNotEmpty ??
        //                                                   pw.TextSpan(
        //                                                       text: ', ' +
        //                                                           companySettings
        //                                                               .mobile),
        //                                             ])
        //                                       : const pw.TextSpan(
        //                                           text: '\n',
        //                                           style: pw.TextStyle(
        //                                             fontSize: 5,
        //                                           ),
        //                                         ),
        //                                 ]),
        //                             pw.TextSpan(
        //                               text:
        //                                   '${ComSettings.getValue('GST-NO', settings)}',
        //                               style: pw.TextStyle(
        //                                 fontWeight: pw.FontWeight.bold,
        //                                 fontSize: 10,
        //                               ),
        //                             ),
        //                           ]))),
        //               pw.SizedBox(height: 20),
        //               pw.Container(
        //                 padding: const pw.EdgeInsets.all(10),
        //                 alignment: pw.Alignment.center,
        //                 height: 10,
        //                 child: pw.GridView(
        //                   crossAxisCount: 2,
        //                   children: [
        //                     pw.Text('EntryNo : ' + dataInformation['InvoiceNo'],
        //                         style: pw.TextStyle(
        //                           fontWeight: pw.FontWeight.bold,
        //                           fontSize: 10,
        //                         ),
        //                         textAlign: pw.TextAlign.left),
        //                     pw.Text(
        //                         'Date : ' +
        //                             DateUtil.dateDMY(dataInformation['DDate']),
        //                         style: pw.TextStyle(
        //                           fontWeight: pw.FontWeight.bold,
        //                           fontSize: 10,
        //                         ),
        //                         textAlign: pw.TextAlign.right),
        //                   ],
        //                 ),
        //               ),
        //               if (context.pageNumber > 1) pw.SizedBox(height: 20)
        //             ]),
        //         build: (context) => [
        //               /*customer*/
        //               pw.Row(
        //                   crossAxisAlignment: pw.CrossAxisAlignment.start,
        //                   children: [
        //                     pw.Container(
        //                       margin:
        //                           const pw.EdgeInsets.only(left: 10, right: 10),
        //                       height: 70,
        //                       child: pw.Text(
        //                         'Bill to:',
        //                         style: pw.TextStyle(
        //                           fontWeight: pw.FontWeight.bold,
        //                           fontSize: 12,
        //                         ),
        //                       ),
        //                     ),
        //                     pw.Expanded(
        //                         child: pw.Container(
        //                             height: 50,
        //                             child: pw.RichText(
        //                                 text: pw.TextSpan(
        //                                     text:
        //                                         '${dataInformation['ToName']}\n',
        //                                     style: pw.TextStyle(
        //                                       // color: _darkColor,
        //                                       fontWeight: pw.FontWeight.bold,
        //                                       fontSize: 12,
        //                                     ),
        //                                     children: [
        //                                   const pw.TextSpan(
        //                                     text: '\n',
        //                                     style: pw.TextStyle(
        //                                       fontSize: 5,
        //                                     ),
        //                                   ),
        //                                   pw.TextSpan(
        //                                     text: dataInformation['Add2']
        //                                             .toString()
        //                                             .isEmpty
        //                                         ? dataInformation['Add1']
        //                                         : dataInformation['Add1'] +
        //                                             '\n' +
        //                                             dataInformation['Add2'],
        //                                     style: pw.TextStyle(
        //                                       fontWeight: pw.FontWeight.normal,
        //                                       fontSize: 10,
        //                                     ),
        //                                   )
        //                                 ])))),
        //                   ]),
        //               pw.Table(
        //                 border: pw.TableBorder.all(width: 0.2),
        //                 children: [
        //                   pw.TableRow(children: [
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[0],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[1],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[2],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[3],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[4],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[5],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                   ]),
        //                   for (var i = 0; i < dataParticulars.length; i++)
        //                     pw.TableRow(children: [
        //                       pw.Column(
        //                           crossAxisAlignment: pw.CrossAxisAlignment.end,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Padding(
        //                               padding: const pw.EdgeInsets.all(2.0),
        //                               child: pw.Text(
        //                                   '${dataParticulars[i]['ItemId']}',
        //                                   style:
        //                                       const pw.TextStyle(fontSize: 9)),
        //                               // pw.Divider(thickness: 1)
        //                             ),
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.start,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Padding(
        //                               padding: const pw.EdgeInsets.all(2.0),
        //                               child: pw.Text(
        //                                   dataParticulars[i]['ProductName'],
        //                                   style:
        //                                       const pw.TextStyle(fontSize: 9)),
        //                               // pw.Divider(thickness: 1)
        //                             ),
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment: pw.CrossAxisAlignment.end,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Padding(
        //                               padding: const pw.EdgeInsets.all(2.0),
        //                               child: pw.Text(
        //                                   double.tryParse(dataParticulars[i]
        //                                               ['PRate']
        //                                           .toString())
        //                                       .toStringAsFixed(decimal),
        //                                   style:
        //                                       const pw.TextStyle(fontSize: 9)),
        //                               // pw.Divider(thickness: 1)
        //                             )
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment: pw.CrossAxisAlignment.end,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Padding(
        //                               padding: const pw.EdgeInsets.all(2.0),
        //                               child: pw.Text(
        //                                   dataParticulars[i]['Qty']
        //                                       .toStringAsFixed(decimal),
        //                                   style:
        //                                       const pw.TextStyle(fontSize: 9)),
        //                               // pw.Divider(thickness: 1)
        //                             )
        //                           ]),
        //                       isItemSerialNo
        //                           ? pw.Column(
        //                               crossAxisAlignment:
        //                                   pw.CrossAxisAlignment.center,
        //                               mainAxisAlignment:
        //                                   pw.MainAxisAlignment.center,
        //                               children: [
        //                                   pw.Padding(
        //                                     padding:
        //                                         const pw.EdgeInsets.all(2.0),
        //                                     child: pw.Text(
        //                                         dataParticulars[i]['serialno']
        //                                             .toString(),
        //                                         style: const pw.TextStyle(
        //                                             fontSize: 9)),
        //                                     // pw.Divider(thickness: 1)
        //                                   )
        //                                 ])
        //                           : pw.Column(
        //                               crossAxisAlignment:
        //                                   pw.CrossAxisAlignment.center,
        //                               mainAxisAlignment:
        //                                   pw.MainAxisAlignment.center,
        //                               children: [
        //                                   pw.Padding(
        //                                     padding:
        //                                         const pw.EdgeInsets.all(2.0),
        //                                     child: pw.Text(
        //                                         dataParticulars[i]['unitName']
        //                                             .toString(),
        //                                         style: const pw.TextStyle(
        //                                             fontSize: 9)),
        //                                     // pw.Divider(thickness: 1)
        //                                   )
        //                                 ]),
        //                       pw.Column(
        //                           crossAxisAlignment: pw.CrossAxisAlignment.end,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Padding(
        //                               padding: const pw.EdgeInsets.all(2.0),
        //                               child: pw.Text(
        //                                   double.tryParse(dataParticulars[i]
        //                                               ['Total']
        //                                           .toString())
        //                                       .toStringAsFixed(decimal),
        //                                   style:
        //                                       const pw.TextStyle(fontSize: 9)),
        //                               // pw.Divider(thickness: 1)
        //                             )
        //                           ]),
        //                     ])
        //                 ],
        //               ),
        //               pw.SizedBox(
        //                 height: 40.0,
        //               ),
        //               pw.Column(
        //                 children: [
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text(
        //                           'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
        //                     ],
        //                   ),
        //                   /**other amount**/
        //                   // otherAmount.length>0 ?
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text(''),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text('***Discount***'),
        //                     ],
        //                   ),
        //                   _addOtherAmountPDF(otherAmount),
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text(
        //                           'TOTAL : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}'),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text(
        //                           'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text(
        //                           'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
        //                           style: pw.TextStyle(
        //                               // color: Colors.black,
        //                               fontSize: 19,
        //                               fontWeight: pw.FontWeight.bold)),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     children: [
        //                       pw.Text(
        //                         'Bill Balance : ${(double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toStringAsFixed(decimal)}',
        //                       ),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     children: [
        //                       pw.Text(
        //                         'Old Balance : ${double.tryParse(customerBalance).toStringAsFixed(decimal)}',
        //                       ),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     children: [
        //                       pw.Text(
        //                         'Balance : ${((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toStringAsFixed(decimal)}',
        //                       ),
        //                     ],
        //                   ),
        //                 ],
        //               ),
        //               pw.Container(
        //                   alignment: pw.Alignment.center,
        //                   child: pw.Text(data['message'],
        //                       textAlign: pw.TextAlign.center))
        //             ],
        //         footer: _buildFooter))
        //     : pdf.addPage(pw.MultiPage(
        //         maxPages: 100,
        //         header: (context) => pw.Column(children: [
        //               pw.Container(
        //                 height: 20,
        //                 padding: const pw.EdgeInsets.all(10),
        //                 alignment: pw.Alignment.center,
        //                 child: pw.Text(
        //                   invoiceHead,
        //                   style: pw.TextStyle(
        //                     fontWeight: pw.FontWeight.bold,
        //                     fontSize: 25,
        //                   ),
        //                 ),
        //               ),
        //               pw.SizedBox(height: 20),
        //               pw.Container(
        //                 padding: const pw.EdgeInsets.all(10),
        //                 alignment: pw.Alignment.center,
        //                 height: 10,
        //                 child: pw.GridView(
        //                   crossAxisCount: 2,
        //                   children: [
        //                     pw.Text('EntryNo : ' + dataInformation['InvoiceNo'],
        //                         style: pw.TextStyle(
        //                           fontWeight: pw.FontWeight.bold,
        //                           fontSize: 10,
        //                         ),
        //                         textAlign: pw.TextAlign.left),
        //                     pw.Text(
        //                         'Date : ' +
        //                             DateUtil.dateDMY(dataInformation['DDate']),
        //                         style: pw.TextStyle(
        //                           fontWeight: pw.FontWeight.bold,
        //                           fontSize: 10,
        //                         ),
        //                         textAlign: pw.TextAlign.right),
        //                   ],
        //                 ),
        //               ),
        //               if (context.pageNumber > 1) pw.SizedBox(height: 20)
        //             ]),
        //         build: (context) => [
        //               /*customer*/
        //               pw.Row(
        //                   crossAxisAlignment: pw.CrossAxisAlignment.start,
        //                   children: [
        //                     pw.Container(
        //                       margin:
        //                           const pw.EdgeInsets.only(left: 10, right: 10),
        //                       height: 70,
        //                       child: pw.Text(
        //                         'Bill to:',
        //                         style: pw.TextStyle(
        //                           fontWeight: pw.FontWeight.bold,
        //                           fontSize: 12,
        //                         ),
        //                       ),
        //                     ),
        //                     pw.Expanded(
        //                         child: pw.Container(
        //                             height: 50,
        //                             child: pw.RichText(
        //                                 text: pw.TextSpan(
        //                                     text:
        //                                         '${dataInformation['ToName']}\n',
        //                                     style: pw.TextStyle(
        //                                       // color: _darkColor,
        //                                       fontWeight: pw.FontWeight.bold,
        //                                       fontSize: 12,
        //                                     ),
        //                                     children: [
        //                                   const pw.TextSpan(
        //                                     text: '\n',
        //                                     style: pw.TextStyle(
        //                                       fontSize: 5,
        //                                     ),
        //                                   ),
        //                                   pw.TextSpan(
        //                                     text: dataInformation['Add2']
        //                                             .toString()
        //                                             .isEmpty
        //                                         ? dataInformation['Add1']
        //                                         : dataInformation['Add1'] +
        //                                             '\n' +
        //                                             dataInformation['Add2'],
        //                                     style: pw.TextStyle(
        //                                       fontWeight: pw.FontWeight.normal,
        //                                       fontSize: 10,
        //                                     ),
        //                                   )
        //                                 ])))),
        //                   ]),
        //               pw.Table(
        //                 border: pw.TableBorder.all(width: 0.2),
        //                 children: [
        //                   pw.TableRow(children: [
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[0],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[1],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[2],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[3],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[4],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                     pw.Column(
        //                         crossAxisAlignment:
        //                             pw.CrossAxisAlignment.center,
        //                         mainAxisAlignment: pw.MainAxisAlignment.center,
        //                         children: [
        //                           pw.Text(tableHeaders[5],
        //                               style: const pw.TextStyle(fontSize: 9)),
        //                           // pw.Divider(thickness: 1)
        //                         ]),
        //                   ]),
        //                   for (var i = 0; i < dataParticulars.length; i++)
        //                     pw.TableRow(children: [
        //                       pw.Column(
        //                           crossAxisAlignment: pw.CrossAxisAlignment.end,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Padding(
        //                               padding: const pw.EdgeInsets.all(2.0),
        //                               child: pw.Text(
        //                                   '${dataParticulars[i]['ItemId']}',
        //                                   style:
        //                                       const pw.TextStyle(fontSize: 9)),
        //                               // pw.Divider(thickness: 1)
        //                             ),
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment:
        //                               pw.CrossAxisAlignment.start,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Padding(
        //                               padding: const pw.EdgeInsets.all(2.0),
        //                               child: pw.Text(
        //                                   dataParticulars[i]['ProductName'],
        //                                   style:
        //                                       const pw.TextStyle(fontSize: 9)),
        //                               // pw.Divider(thickness: 1)
        //                             ),
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment: pw.CrossAxisAlignment.end,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Padding(
        //                               padding: const pw.EdgeInsets.all(2.0),
        //                               child: pw.Text(
        //                                   double.tryParse(dataParticulars[i]
        //                                               ['PRate']
        //                                           .toString())
        //                                       .toStringAsFixed(decimal),
        //                                   style:
        //                                       const pw.TextStyle(fontSize: 9)),
        //                               // pw.Divider(thickness: 1)
        //                             )
        //                           ]),
        //                       pw.Column(
        //                           crossAxisAlignment: pw.CrossAxisAlignment.end,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Padding(
        //                               padding: const pw.EdgeInsets.all(2.0),
        //                               child: pw.Text(
        //                                   dataParticulars[i]['Qty']
        //                                       .toStringAsFixed(decimal),
        //                                   style:
        //                                       const pw.TextStyle(fontSize: 9)),
        //                               // pw.Divider(thickness: 1)
        //                             )
        //                           ]),
        //                       isItemSerialNo
        //                           ? pw.Column(
        //                               crossAxisAlignment:
        //                                   pw.CrossAxisAlignment.center,
        //                               mainAxisAlignment:
        //                                   pw.MainAxisAlignment.center,
        //                               children: [
        //                                   pw.Padding(
        //                                     padding:
        //                                         const pw.EdgeInsets.all(2.0),
        //                                     child: pw.Text(
        //                                         dataParticulars[i]['serialno']
        //                                             .toString(),
        //                                         style: const pw.TextStyle(
        //                                             fontSize: 9)),
        //                                     // pw.Divider(thickness: 1)
        //                                   )
        //                                 ])
        //                           : pw.Column(
        //                               crossAxisAlignment:
        //                                   pw.CrossAxisAlignment.center,
        //                               mainAxisAlignment:
        //                                   pw.MainAxisAlignment.center,
        //                               children: [
        //                                   pw.Padding(
        //                                     padding:
        //                                         const pw.EdgeInsets.all(2.0),
        //                                     child: pw.Text(
        //                                         dataParticulars[i]['unitName']
        //                                             .toString(),
        //                                         style: const pw.TextStyle(
        //                                             fontSize: 9)),
        //                                     // pw.Divider(thickness: 1)
        //                                   )
        //                                 ]),
        //                       pw.Column(
        //                           crossAxisAlignment: pw.CrossAxisAlignment.end,
        //                           mainAxisAlignment:
        //                               pw.MainAxisAlignment.center,
        //                           children: [
        //                             pw.Padding(
        //                               padding: const pw.EdgeInsets.all(2.0),
        //                               child: pw.Text(
        //                                   double.tryParse(dataParticulars[i]
        //                                               ['Total']
        //                                           .toString())
        //                                       .toStringAsFixed(decimal),
        //                                   style:
        //                                       const pw.TextStyle(fontSize: 9)),
        //                               // pw.Divider(thickness: 1)
        //                             )
        //                           ]),
        //                     ])
        //                 ],
        //               ),
        //               pw.SizedBox(
        //                 height: 40.0,
        //               ),
        //               pw.Column(
        //                 children: [
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text(
        //                           'SUB TOTAL : ${double.tryParse(dataInformation['GrossValue'].toString()).toStringAsFixed(decimal)}'),
        //                     ],
        //                   ),
        //                   /**other amount**/
        //                   // otherAmount.length>0 ?
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text(''),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text('***Discount***'),
        //                     ],
        //                   ),
        //                   _addOtherAmountPDF(otherAmount),
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text(
        //                           'TOTAL : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}'),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text(
        //                           'PAID : ${double.tryParse(dataInformation['CashReceived'].toString()).toStringAsFixed(decimal)}'),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     mainAxisAlignment: pw.MainAxisAlignment.end,
        //                     children: [
        //                       pw.Text(
        //                           'TOTAL DUE : ${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}',
        //                           style: pw.TextStyle(
        //                               // color: Colors.black,
        //                               fontSize: 19,
        //                               fontWeight: pw.FontWeight.bold)),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     children: [
        //                       pw.Text(
        //                         'Bill Balance : ${(double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString())).toStringAsFixed(decimal)}',
        //                       ),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     children: [
        //                       pw.Text(
        //                         'Old Balance : ${double.tryParse(customerBalance).toStringAsFixed(decimal)}',
        //                       ),
        //                     ],
        //                   ),
        //                   pw.Row(
        //                     children: [
        //                       pw.Text(
        //                         'Balance : ${((double.tryParse(customerBalance)) + (double.tryParse(dataInformation['GrandTotal'].toString()) - double.tryParse(dataInformation['CashReceived'].toString()))).toStringAsFixed(decimal)}',
        //                       ),
        //                     ],
        //                   ),
        //                 ],
        //               ),
        //               pw.Container(
        //                   alignment: pw.Alignment.center,
        //                   child: pw.Text(data['message'],
        //                       textAlign: pw.TextAlign.center))
        //             ],
        //         footer: _buildFooter));
        : pdf.addPage(pw.MultiPage(
            maxPages: 100,
            pageFormat: pw.PdfPageFormat.a4,
            header: (pw.Context context) => _buildEstimateHeader(
                companySettings,
                settings,
                dataLedger,
                dataInformation,
                printHeaderOnES),
            footer: (pw.Context context) => _buildEstimateFooter(
                context,
                dataBankLedger,
                dataInformation,
                companySettings,
                otherAmount,
                dataParticulars),
            build: (pw.Context context) {
              double calculateEstTotalAmount(List<dynamic> perticu) {
                return perticu.fold(
                    0,
                    (total, particular) =>
                        total + particular['Total'].toDouble());
              }

              double calculateEstTotalQuantity(List<dynamic> perticu) {
                return perticu.fold(
                    0,
                    (total, particular) =>
                        total + particular['Qty'].toDouble());
              }

              final int totalRowCount = 53; // Desired total row count
              final int existingRowCount = dataParticulars.length;

// Calculate the number of empty rows needed
              final int emptyRowCount = totalRowCount - existingRowCount;
              List<pw.Widget> widgets = [
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Table(
                    border: const pw.TableBorder(
                      horizontalInside: pw.BorderSide
                          .none, // Remove horizontal borders inside the table

                      verticalInside: pw.BorderSide(), // Keep vertical borders
                    ),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(15),
                      1: pw.FlexColumnWidth(20),
                      2: pw.FlexColumnWidth(10),
                      3: pw.FlexColumnWidth(10),
                      4: pw.FlexColumnWidth(10),
                      5: pw.FlexColumnWidth(20),
                    },
                    children: [
                      for (var i = 0; i < dataParticulars.length; i++)
                        pw.TableRow(children: [
                          pw.Center(
                              child: pw.Column(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  dataParticulars[i]['GridID'].toString(),
                                  style: pw.TextStyle(
                                      fontSize: 6,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          )),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Text(
                              dataParticulars[i]['ProductName'].toString(),
                              style: pw.TextStyle(
                                  fontSize: 6, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Center(
                              child: pw.Text(
                                dataParticulars[i]['Qty'].toStringAsFixed(2),
                                style: pw.TextStyle(
                                    fontSize: 6,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                // pw.Text(
                                //   dataParticulars[i]['unitName'].toString(),
                                //   style: pw.TextStyle(
                                //       fontSize: 6,
                                //       fontWeight: pw.FontWeight.bold),
                                // ),
                                pw.Text(""),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                  dataParticulars[i]['PRate']
                                      .toStringAsFixed(2),
                                  style: pw.TextStyle(
                                      fontSize: 6,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                  dataParticulars[i]['Total']
                                      .toStringAsFixed(2),
                                  style: pw.TextStyle(
                                      fontSize: 6,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      if (dataParticulars.length > 45)
                        for (var k = 0; k < 45; k++)
                          pw.TableRow(children: [
                            pw.Center(
                                child: pw.Column(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(2.0),
                                  child: pw.Text(
                                    '\n',
                                    style: pw.TextStyle(
                                        fontSize: 6,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                              ],
                            )),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text(
                                '',
                                style: pw.TextStyle(
                                    fontSize: 6,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Center(
                                child: pw.Text(
                                  '',
                                  style: pw.TextStyle(
                                      fontSize: 6,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    '',
                                    style: pw.TextStyle(
                                        fontSize: 6,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    '',
                                    style: pw.TextStyle(
                                        fontSize: 6,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    '',
                                    style: pw.TextStyle(
                                        fontSize: 6,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                      for (var j = 0; j < emptyRowCount; j++)
                        pw.TableRow(children: [
                          pw.Center(
                              child: pw.Column(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                  '\n',
                                  style: pw.TextStyle(
                                      fontSize: 6,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          )),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Text(
                              '',
                              style: pw.TextStyle(
                                  fontSize: 6, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Center(
                              child: pw.Text(
                                '',
                                style: pw.TextStyle(
                                    fontSize: 6,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                  '',
                                  style: pw.TextStyle(
                                      fontSize: 6,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                  '',
                                  style: pw.TextStyle(
                                      fontSize: 6,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.0),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                  '',
                                  style: pw.TextStyle(
                                      fontSize: 6,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ]),
                    ],
                  ),
                ),
                pw.Container(
                  decoration: const pw.BoxDecoration(
                      color: pw.PdfColor.fromInt(0xFFCCCCCC),
                      border: pw.Border(
                          bottom: pw.BorderSide(),
                          left: pw.BorderSide(),
                          right: pw.BorderSide())),
                  child: pw.Table(
                    border: const pw.TableBorder(
                      horizontalInside: pw.BorderSide
                          .none, // Remove horizontal borders inside the table

                      verticalInside: pw.BorderSide(), // Keep vertical borders
                    ),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(15),
                      1: pw.FlexColumnWidth(20),
                      2: pw.FlexColumnWidth(10),
                      3: pw.FlexColumnWidth(10),
                      4: pw.FlexColumnWidth(10),
                      5: pw.FlexColumnWidth(20),
                    },
                    children: [
                      pw.TableRow(children: [
                        pw.Center(
                            child: pw.Column(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2.0),
                              child: pw.Text(
                                '',
                                style: pw.TextStyle(
                                    fontSize: 6,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        )),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.0),
                          child: pw.Center(
                            child: pw.Text(
                              'Total',
                              style: pw.TextStyle(
                                  fontSize: 6, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.0),
                          child: pw.Center(
                            child: pw.Text(
                              '${calculateEstTotalQuantity(dataParticulars)}',
                              style: pw.TextStyle(
                                  fontSize: 6, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.0),
                          child: pw.Center(
                            child: pw.Text(
                              '',
                              style: pw.TextStyle(
                                  fontSize: 6, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.0),
                          child: pw.Center(
                            child: pw.Text(
                              '',
                              style: pw.TextStyle(
                                  fontSize: 6, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.0),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                '${calculateEstTotalAmount(dataParticulars).toStringAsFixed(2)} ',
                                style: pw.TextStyle(
                                    fontSize: 6,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ];

              return widgets;
            },
          ));
  }
  documentPDF = pdf;
  return pdf;
}

_buildEstimateFooter(pw.Context context, dataBankLedger, dataInformation,
    companySettings, otherAmount, dataParticulars) {
  double calculateEstTotalAmount(List<dynamic> perticu) {
    return perticu.fold(
        0, (total, particular) => total + particular['Total'].toDouble());
  }

  return pw.Column(
    children: [
      pw.SizedBox(
        height: 10,
      ),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.SizedBox(
              width: double.infinity / 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Amount In Words :",
                    style: const pw.TextStyle(
                        fontSize: 8, decoration: pw.TextDecoration.underline),
                  ),
                  pw.Text(
                    NumberToWord().convertDouble(
                        'en',
                        double.tryParse(
                            dataInformation['GrandTotal'].toString())),
                    style: const pw.TextStyle(
                      fontSize: 8,
                    ),
                  )
                ],
              ),
            ),
          ),
          pw.Expanded(
            child: pw.SizedBox(
              width: double.infinity / 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < otherAmount.length; i++)
                            pw.Text(
                              "${otherAmount[i]['ledName']} ",
                              style: const pw.TextStyle(
                                fontSize: 8,
                              ),
                            ),
                          pw.Text(
                            "Return Amt          :",
                            style: const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),
                          pw.Text(
                            "BILL AMOUNT    :",
                            style: const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),
                          pw.Text(
                            "OB                       :",
                            style: const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),
                          pw.Text(
                            "Cash Recieved    :",
                            style: const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),
                          pw.SizedBox(
                            height: 5,
                          ),
                          pw.Text(
                            "NET AMOUNT    :",
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                          )
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < otherAmount.length; i++)
                            pw.Text(
                              "${otherAmount[i]['Amount'].toStringAsFixed(2)} ",
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold),
                            ),
                          pw.Text(
                            "${dataInformation['ReturnAmount'].toStringAsFixed(2)} ",
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            "${(calculateEstTotalAmount(dataParticulars) - dataInformation['ReturnAmount'] + otherAmount.fold(0.0, (t, e) => t + double.parse(e['symbol'] == '-' ? (e['Amount'] * -1).toString() : e['Amount'].toString()))).toStringAsFixed(2)} ",
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            "${dataInformation['BalanceAmount'].toStringAsFixed(2)} ",
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            "${dataInformation['CashReceived'].toStringAsFixed(2)} ",
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(
                            height: 5,
                          ),
                          pw.Text(
                            "${dataInformation['GrandTotal'].toStringAsFixed(2)} ",
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                          )
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(
        height: 20,
      ),
      pw.Footer(
        trailing: pw.Text('Page ${context.pageNumber} /${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10)),
      ),
    ],
  );
}

_buildEstimateHeader(
    companyS, companySettings, dataLedger, dataInformation, bool isHeading) {
  var companyState = ComSettings.getValue('COMP-STATE', companyS);
  var companyStateCode = ComSettings.getValue('COMP-STATECODE', companyS);
  var companyTaxNo = ComSettings.getValue('GST-NO', companyS);
  return pw.Column(children: [
    isHeading
        ? pw.Container(
            padding: const pw.EdgeInsets.all(10),
            height: 100,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                  color: const pw.PdfColor.fromInt(0xFF000000), // Black color
                  width: 2),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyS.name,
                        style: pw.TextStyle(
                            fontSize: 15, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        companyS.add1,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        companySettings.add2,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        companyS.email,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        companyS.mobile,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      height: 5,
                    ),
                    pw.Text(
                      "GST No : $companyTaxNo",
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(
                      height: 10,
                    ),
                    pw.Text(
                      "State: ${companyState}    ${companyStateCode}",
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          )
        : pw.Container(),
    pw.Container(
      width: double.infinity,
      height: 30,
      decoration: pw.BoxDecoration(
          color: const pw.PdfColor.fromInt(0xFFCCCCCC),
          border: pw.Border.all()),
      child: pw.Center(
          child: pw.Text(
        "ESTIMATE",
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      )),
    ),
    pw.Container(
      width: double.infinity,
      height: 100,
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              left: pw.BorderSide(),
              right: pw.BorderSide(),
              bottom: pw.BorderSide())),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            height: 8,
          ),
          pw.Row(
            children: [
              pw.Text(
                "  No         :",
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                "   ${dataInformation['InvoiceNo']}",
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Text(
                "  Date      :",
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                "   ${DateUtil.dateDMY(dataInformation['DDate'])}",
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Text(
                "  To         :",
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                "    ${dataInformation['ToName']}",
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    ),
    pw.Container(
      decoration: pw.BoxDecoration(
          color: const pw.PdfColor.fromInt(0xFFCCCCCC),
          border: pw.Border.all()),
      child: pw.Table(
        border: const pw.TableBorder(
          horizontalInside:
              pw.BorderSide.none, // Remove horizontal borders inside the table

          verticalInside: pw.BorderSide(), // Keep vertical borders
        ),
        columnWidths: const {
          0: pw.FixedColumnWidth(15),
          1: pw.FlexColumnWidth(20),
          2: pw.FlexColumnWidth(10),
          3: pw.FlexColumnWidth(10),
          4: pw.FlexColumnWidth(10),
          5: pw.FlexColumnWidth(20),
        },
        children: [
          pw.TableRow(children: [
            pw.Center(
                child: pw.Column(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2.0),
                  child: pw.Text(
                    'No',
                    style: pw.TextStyle(
                        fontSize: 6, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            )),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2.0),
              child: pw.Center(
                child: pw.Text(
                  'Description Of Goods',
                  style:
                      pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2.0),
              child: pw.Center(
                child: pw.Text(
                  'Qty',
                  style:
                      pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2.0),
              child: pw.Center(
                child: pw.Text(
                  'Unit',
                  style:
                      pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2.0),
              child: pw.Center(
                child: pw.Text(
                  'Rate',
                  style:
                      pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2.0),
              child: pw.Center(
                child: pw.Text(
                  'Total',
                  style:
                      pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
          ]),
        ],
      ),
    ),
  ]);
}

_buildFooterr(pw.Context context, bankledger, dataInfo, cSettings,
    customerBalance, dataInformation) {
  double oldBalance = double.tryParse(customerBalance).toDouble();

  double cBalance = double.tryParse(customerBalance).toDouble() ?? 0.00;
  double grandTotal = dataInformation['GrandTotal']?.toDouble() ?? 0.00;
  // double cashReceived = _isLoading?0:dataInformation['CashReceived'].toDouble() ?? 0.00;
  double cashReceived = (dataInformation['CashReceived']?.toDouble() ?? 0.00);

  double balance = cBalance + grandTotal - cashReceived;
  return pw.Column(
    children: [
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              width: double.infinity / 2,
              height: 102,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  // top: BorderSide(color: Colors.black, width: 2),
                  right: pw.BorderSide(
                      color: pw.PdfColor.fromInt(0xFF000000), // Black color,
                      width: 1),
                  bottom: pw.BorderSide(
                      color: pw.PdfColor.fromInt(0xFF000000), // Black color,
                      width: 1),
                  left: pw.BorderSide(
                      color: pw.PdfColor.fromInt(0xFF000000), // Black color,
                      width: 1),
                ),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 0, left: 3),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      NumberToWord().convertDouble('en',
                          double.tryParse(dataInfo['GrandTotal'].toString())),
                      style: pw.TextStyle(
                          fontSize: 7, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(
                      height: 5,
                    ),
                    pw.Text(
                      "Bank Details",
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline),
                    ),
                    pw.Column(
                      children: [
                        pw.Container(
                            height: 40,
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      " ${bankledger['name']}",
                                      style: const pw.TextStyle(fontSize: 7),
                                    ),
                                    pw.Text(
                                      " ${bankledger['account']}",
                                      style: const pw.TextStyle(fontSize: 7),
                                    ),
                                    pw.Text(
                                      " ${bankledger['ifsc']}",
                                      style: const pw.TextStyle(fontSize: 7),
                                    ),
                                    pw.Text(
                                      " ${bankledger['branch']}",
                                      style: const pw.TextStyle(fontSize: 7),
                                    ),
                                  ],
                                ),
                                oldBalance > 0 || balance > 0
                                    ? pw.Padding(
                                        padding: const pw.EdgeInsets.only(
                                            right: 10.0),
                                        child: pw.Column(
                                          mainAxisAlignment:
                                              pw.MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.start,
                                          children: [
                                            pw.Row(
                                              children: [
                                                pw.SizedBox(
                                                  child: pw.Text(
                                                    "OB           : ",
                                                    style: const pw.TextStyle(
                                                        fontSize: 6),
                                                  ),
                                                ),
                                                pw.Text(
                                                  double.tryParse(
                                                          customerBalance)
                                                      .toStringAsFixed(2),
                                                  style: const pw.TextStyle(
                                                      fontSize: 6),
                                                )
                                              ],
                                            ),
                                            pw.Row(
                                              children: [
                                                pw.SizedBox(
                                                  child: pw.Text(
                                                    "Balance  : ",
                                                    style: const pw.TextStyle(
                                                        fontSize: 6),
                                                  ),
                                                ),
                                                pw.Text(
                                                  balance.toStringAsFixed(2),
                                                  style: const pw.TextStyle(
                                                      fontSize: 6),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    : pw.Container(),
                              ],
                            )),
                      ],
                    ),
                    pw.Text(
                      " Certified that the perticular given above are true and Correct",
                      style: pw.TextStyle(
                          fontSize: 6, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              width: double.infinity / 2,
              height: 102,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  // top: BorderSide(color: Colors.black, width: 2),
                  right: pw.BorderSide(
                      color: pw.PdfColor.fromInt(0xFF000000), // Black color,
                      width: 1),
                  bottom: pw.BorderSide(
                      color: pw.PdfColor.fromInt(0xFF000000), // Black color,
                      width: 1),
                ),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    height: 15,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        // top: BorderSide(color: Colors.black, width: 2),
                        right: pw.BorderSide(
                            color:
                                pw.PdfColor.fromInt(0xFF000000), // Black color,
                            width: 1),
                        bottom: pw.BorderSide(
                            color:
                                pw.PdfColor.fromInt(0xFF000000), // Black color,
                            width: 1),
                      ),
                    ),
                  ),
                  pw.Container(
                    height: 15,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        // top: BorderSide(color: Colors.black, width: 2),
                        right: pw.BorderSide(
                            color:
                                pw.PdfColor.fromInt(0xFF000000), // Black color,
                            width: 1),
                        bottom: pw.BorderSide(
                            color:
                                pw.PdfColor.fromInt(0xFF000000), // Black color,
                            width: 1),
                      ),
                    ),
                  ),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          height: 17,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              // top: BorderSide(color: Colors.black, width: 2),
                              right: pw.BorderSide(
                                  color: pw.PdfColor.fromInt(
                                      0xFF000000), // Black color,
                                  width: 1),
                              bottom: pw.BorderSide(
                                  color: pw.PdfColor.fromInt(
                                      0xFF000000), // Black color,
                                  width: 1),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                "Round off ",
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          height: 17,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(
                            // top: BorderSide(color: Colors.black, width: 2),
                            right: pw.BorderSide(
                                color: pw.PdfColor.fromInt(
                                    0xFF000000), // Black color,
                                width: 1),
                            bottom: pw.BorderSide(
                                color: pw.PdfColor.fromInt(
                                    0xFF000000), // Black color,
                                width: 1),
                          )),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                "0.00 ",
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          height: 17,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              // top: BorderSide(color: Colors.black, width: 2),
                              right: pw.BorderSide(
                                  color: pw.PdfColor.fromInt(
                                      0xFF000000), // Black color,
                                  width: 1),
                              bottom: pw.BorderSide(
                                  color: pw.PdfColor.fromInt(
                                      0xFF000000), // Black color,
                                  width: 1),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                "Total ",
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          height: 17,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              // top: BorderSide(color: Colors.black, width: 2),
                              right: pw.BorderSide(
                                  color: pw.PdfColor.fromInt(
                                      0xFF000000), // Black color,
                                  width: 1),
                              bottom: pw.BorderSide(
                                  color: pw.PdfColor.fromInt(
                                      0xFF000000), // Black color,
                                  width: 1),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                "${dataInfo['GrandTotal']?.toStringAsFixed(2)} ",
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    cSettings.name,
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(
                    height: 10,
                  ),
                  pw.Text(
                    "Authorised Signatuory",
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(
        height: 10,
      ),
      pw.Footer(
        trailing: pw.Text('Page ${context.pageNumber} /${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10)),
      ),
    ],
  );
}

_buildHeaderr(
  pw.Context context,
  companySettings,
  settings,
  dataLedger,
  dataInformation,
) {
  var companyState = ComSettings.getValue('COMP-STATE', settings);
  var companyStateCode = ComSettings.getValue('COMP-STATECODE', settings);
  var companyTaxNo = ComSettings.getValue('GST-NO', settings);
  return pw.Column(children: [
    pw.Container(
      padding: const pw.EdgeInsets.all(10),
      height: 100,
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
            color: const pw.PdfColor.fromInt(0xFF000000), // Black color
            width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companySettings.name,
                  style: pw.TextStyle(
                      fontSize: 15, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  companySettings.add1,
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Text(
                  companySettings.add2,
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Text(
                  companySettings.email,
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Text(
                  companySettings.mobile,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                height: 5,
              ),
              pw.Text(
                "GST No : $companyTaxNo",
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(
                height: 10,
              ),
              pw.Text(
                "State      : $companyState       $companyStateCode",
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    ),
    pw.Container(
      height: 20,
      width: double.infinity,
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          // top: BorderSide(color: Colors.black, width: 2),
          right: pw.BorderSide(
              color: pw.PdfColor.fromInt(0xFF000000), // Black color
              width: 2),

          left: pw.BorderSide(
              color: pw.PdfColor.fromInt(0xFF000000), // Black color
              width: 2),
        ),
      ),
      child: pw.Center(
        child: pw.Text(
          "PURCHASE RETURN",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),
    ),
    pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            height: 70,
            width: double.infinity / 2,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                  color: const pw.PdfColor.fromInt(0xFF000000), // Black color
                  width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  height: 10,
                ),
                pw.Text(
                  " Invoice No        ${dataInformation['RealEntryNo']}",
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  " Invoice Date     ${DateUtil.dateDMY(dataInformation['DDate'])} ",
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            height: 70,
            width: double.infinity / 2,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                    color: pw.PdfColor.fromInt(0xFF000000), // Black color
                    width: 2),
                right: pw.BorderSide(
                    color: pw.PdfColor.fromInt(0xFF000000), // Black color,
                    width: 2),
                bottom: pw.BorderSide(
                    color: pw.PdfColor.fromInt(0xFF000000), // Black color
                    width: 2),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  height: 10,
                ),
                pw.Text(
                  " Vehicle No",
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  " Date & Time of Supply",
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  " Place of Supply",
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            height: 110,
            width: double.infinity / 2,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                // top: BorderSide(color: Colors.black, width: 2),
                right: pw.BorderSide(
                    color: pw.PdfColor.fromInt(0xFF000000), // Black color,
                    width: 2),
                bottom: pw.BorderSide(
                    color: pw.PdfColor.fromInt(0xFF000000), // Black color,
                    width: 2),
                left: pw.BorderSide(
                    color: pw.PdfColor.fromInt(0xFF000000), // Black color,
                    width: 2),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    "Details of Receiver (Billed To)",
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline),
                  ),
                ),
                pw.SizedBox(
                  height: 5,
                ),
                pw.Text(
                  " Name                   ${dataInformation['LedName']}",
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      " Address",
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(
                      width: 35,
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "${dataLedger['add1']} ",
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          "${dataLedger['add2']} ",
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          "${dataLedger['add3']} ",
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          "${dataLedger['add4']} ",
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(
                  height: 1,
                ),
                pw.Text(
                  " Mobile                ${dataLedger['Mobile']}",
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Text(
                  " Sate/Code         ${dataLedger['state']}        ${dataLedger['stateCode']}",
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Text(
                  " GST No                  ${dataLedger['gstno']}",
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            height: 110,
            width: double.infinity / 2,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                // top: BorderSide(color: Colors.black, width: 2),
                right: pw.BorderSide(
                    color: pw.PdfColor.fromInt(0xFF000000), // Black color,
                    width: 2),
                bottom: pw.BorderSide(
                    color: pw.PdfColor.fromInt(0xFF000000), // Black color,
                    width: 2),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    "Details of Consignee (Shipped To)",
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline),
                  ),
                ),
                pw.SizedBox(
                  height: 5,
                ),
                pw.Text(
                  " Name              ",
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      " Address",
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(
                      width: 28,
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [pw.Text('')],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    pw.Container(
      height: 20, width: double.infinity,
      color: const pw.PdfColor.fromInt(0xFFC0C0C0), // Light Grey color
      // color: const pw.PdfColor.fromInt(0xFF808080), // Grey color
      child: pw.Row(
        children: [
          pw.Container(
            height: 20,
            width: 10,
            decoration: const pw.BoxDecoration(
                border:
                    pw.Border(right: pw.BorderSide(), left: pw.BorderSide())),
            child: pw.Center(
              child: pw.Text(
                " No ",
                style: const pw.TextStyle(fontSize: 6),
              ),
            ),
          ),
          pw.Container(
            height: 20,
            width: 84,
            decoration: const pw.BoxDecoration(
                border: pw.Border(
              right: pw.BorderSide(),
            )),
            child: pw.Center(
              child: pw.Text(
                " Description of goods",
                style: const pw.TextStyle(fontSize: 6),
              ),
            ),
          ),
          pw.Container(
            height: 20,
            width: 27,
            decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide())),
            child: pw.Center(
              child: pw.Text(
                "Hsn code",
                style: const pw.TextStyle(fontSize: 6),
              ),
            ),
          ),
          pw.Container(
            height: 20,
            width: 27,
            decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide())),
            child: pw.Center(
              child: pw.Text(
                "Qty",
                style: const pw.TextStyle(fontSize: 6),
              ),
            ),
          ),
          pw.Container(
              height: 20,
              width: 27,
              decoration: const pw.BoxDecoration(
                  border: pw.Border(right: pw.BorderSide())),
              child: pw.Center(
                child: pw.Text(
                  "UOM",
                  style: const pw.TextStyle(fontSize: 6),
                ),
              )),
          pw.Container(
              height: 20,
              width: 38.2,
              decoration: const pw.BoxDecoration(
                  border: pw.Border(right: pw.BorderSide())),
              child: pw.Center(
                child: pw.Text(
                  "Unit price",
                  style: const pw.TextStyle(fontSize: 6),
                ),
              )),
          pw.Container(
              height: 20,
              width: 38.2,
              decoration: const pw.BoxDecoration(
                  border: pw.Border(right: pw.BorderSide())),
              child: pw.Center(
                child: pw.Text(
                  "Taxable value",
                  style: const pw.TextStyle(fontSize: 6),
                ),
              )),
          pw.Container(
            height: 20,
            width: 58,
            decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide())),
            child: pw.Center(
              child: pw.Text(
                "CGST",
                style: const pw.TextStyle(fontSize: 6),
              ),
            ),
          ),
          pw.Container(
              height: 20,
              width: 57.2,
              decoration: const pw.BoxDecoration(
                  border: pw.Border(right: pw.BorderSide())),
              child: pw.Center(
                child: pw.Text(
                  "SGST",
                  style: const pw.TextStyle(fontSize: 6),
                ),
              )),
          pw.Container(
              height: 20,
              width: 57.5,
              decoration: const pw.BoxDecoration(
                  border: pw.Border(right: pw.BorderSide())),
              child: pw.Center(
                child: pw.Text(
                  "IGST",
                  style: const pw.TextStyle(fontSize: 6),
                ),
              )),
          pw.Expanded(
            child: pw.Container(
                height: 20,
                decoration: const pw.BoxDecoration(
                    border: pw.Border(right: pw.BorderSide())),
                child: pw.Center(
                  child: pw.Text(
                    "Total Amount",
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                )),
          ),
        ],
      ),
    ),
  ]);
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
          color: PdfColors.grey,
        ),
      ),
    ],
  );
}

pw.PageTheme _buildTheme(PdfPageFormat pageFormat) {
  return pw.PageTheme(
    pageFormat: pageFormat,
    buildBackground: (context) => pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(width: 1, color: PdfColors.black),
      ),
    ),
    orientation: pw.PageOrientation.portrait,
    // margin: pw.EdgeInsets.all(10),
    // theme: pw.ThemeData.withFont(
    //   base: base,
    //   bold: bold,
    //   italic: italic,
    // ),
  );
}

_addOtherAmountPDF(var dataAmount) {
  // bool isData = true;
  return dataAmount.length > 0
      ? pw.Table(
          // border: pw.TableBorder.all(width: 0.2),
          defaultColumnWidth: const pw.IntrinsicColumnWidth(),
          children: [
              for (var i = 0; i < dataAmount.length; i++)
                pw.TableRow(children: [
                  pw.Column(children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(dataAmount[i]['LedName'] +
                            ' : ' +
                            dataAmount[i]['Amount'].toStringAsFixed(2)),
                      ],
                    ),
                  ])
                ]),
            ])
      : pw.Table(
          // border: pw.TableBorder.all(width: 0.2),
          defaultColumnWidth: const pw.IntrinsicColumnWidth(),
          children: [
              pw.TableRow(children: [
                pw.Column(children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('Discount : 0.00'),
                    ],
                  ),
                ])
              ]),
            ]);
}

printDocument(String title, CompanyInformation companySettings,
    List<CompanySettings> settings, var data, var customerBalance) async {
  await Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async => await Printing.convertHtml(
            format: format,
            html: '<html><body><p>Model Not Found!</p></body></html>',
          ));
}

printDocumentGST(String title, CompanyInformation companySettings,
    List<CompanySettings> settings, var data, var customerBalance) async {
  await Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async => await Printing.convertHtml());
}

Future<String> savePrintPDF(pw.Document pdf) async {
  await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save());
  return 'printing';
}

typedef LayoutCallbackWithData = Future<Uint8List> Function(
    PdfPageFormat pageFormat, CustomData data);
