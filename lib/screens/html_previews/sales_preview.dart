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
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/sales_bill.dart';
import 'package:sheraccerp/models/sales_model.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
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
import 'package:sunmi_printer_service/sunmi_printer_service.dart' as sum_mi;

import 'package:webview_flutter/webview_flutter.dart';
import 'package:zxing2/qrcode.dart';

class SalesPreviewShow extends StatefulWidget {
  const SalesPreviewShow({Key key}) : super(key: key);

  @override
  State createState() => _SalesPreviewShowState();
}

class _SalesPreviewShowState extends State<SalesPreviewShow> {
  final GlobalKey _globalKey = GlobalKey();
  DioService api = DioService();
  SalesModel salesModel;
  var totalQty = 0.0, totalRate = 0.0;
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
  var dataInformation,
      dataParticularsAll = [],
      dataParticulars = [],
      dataSerialNO = [],
      dataDeliveryNote = [],
      otherAmount = [];
  Uint8List byteImage;
  int decimal = 2;

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
  bool isItemSerialNo;

  @override
  void initState() {
    super.initState();
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();

    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;
    isQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA', settings);
    isEsQrCodeKSA = ComSettings.getStatus('KEY QRCODE KSA ON ES', settings);
    printerType =
        ComSettings.appSettings('int', 'key-dropdown-printer-type-view', 0);
    printerDevice =
        ComSettings.appSettings('int', 'key-dropdown-printer-device-view', 0);
    printModel =
        ComSettings.appSettings('int', "key-dropdown-printer-model-view", 2);
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
    type = dataDynamic[0]['Type'];

    api.fetchSalesInvoice(eNo, type).then((value) {
      setState(() {
        data = value;
        dataInformation = value['Information'][0];
        customerBalance = dataInformation['Balance'].toString();
        dataParticularsAll = value['Particulars'];
        dataSerialNO = value['SerialNO'];
        dataDeliveryNote = value['DeliveryNote'];
        otherAmount = value['otherAmount'];
        loadAsset();
        _isLoading = false;

        List itemIdList = [];
        // for (var u in dataParticularsAll) {
        //   if (itemIdList.contains(u["itemId"].toString().trim())) {
        //     int index = dataParticulars.indexWhere((i) =>
        //         i['itemId'].toString().trim() == u['itemId'].toString().trim());
        //     double qty =
        //         double.tryParse(dataParticulars[index]['Qty'].toString()) +
        //             double.tryParse(u['Qty'].toString());
        //     // dataParticulars[index]['hsncode'] = hsncode;
        //     dataParticulars[index]['Qty'] = qty;
        //     dataParticulars[index]['Net'] = qty *
        //         double.tryParse(dataParticulars[index]['RealRate'].toString());
        //     dataParticulars[index]['CGST'] =
        //         double.tryParse(dataParticulars[index]['CGST'].toString()) +
        //             double.tryParse(u['CGST'].toString());
        //     dataParticulars[index]['SGST'] =
        //         double.tryParse(dataParticulars[index]['SGST'].toString()) +
        //             double.tryParse(u['SGST'].toString());
        //     dataParticulars[index]['IGST'] =
        //         double.tryParse(dataParticulars[index]['IGST'].toString()) +
        //             double.tryParse(u['IGST'].toString());
        //     dataParticulars[index]['Total'] =
        //         double.tryParse(dataParticulars[index]['Total'].toString()) +
        //             double.tryParse(u['Total'].toString());
        //     dataParticulars[index]['GrossValue'] = double.tryParse(
        //             dataParticulars[index]['GrossValue'].toString()) +
        //         double.tryParse(u['GrossValue'].toString());
        //     dataParticulars[index]['cess'] =
        //         double.tryParse(dataParticulars[index]['cess'].toString()) +
        //             double.tryParse(u['cess'].toString());
        //     dataParticulars[index]['adcess'] =
        //         double.tryParse(dataParticulars[index]['adcess'].toString()) +
        //             double.tryParse(u['adcess'].toString());
        //     dataParticulars[index]['Disc'] =
        //         double.tryParse(dataParticulars[index]['Disc'].toString()) +
        //             double.tryParse(u['Disc'].toString());
        //     dataParticulars[index]['DiscPersent'] = double.tryParse(
        //             dataParticulars[index]['DiscPersent'].toString()) +
        //         double.tryParse(u['DiscPersent'].toString());
        //     dataParticulars[index]['Fcess'] =
        //         double.tryParse(dataParticulars[index]['Fcess'].toString()) +
        //             double.tryParse(u['Fcess'].toString());
        //   } else {
        //     itemIdList.add(u['itemId'].toString().trim());
        //     dataParticulars.add(u);
        //   }
        // }
        dataParticulars.addAll(dataParticularsAll);

        data['Particulars'] = dataParticulars;
        if (title.isEmpty) {
          title = (ModalRoute.of(context).settings.arguments
              as Map<String, String>)['title'];
        }
        _createPDF(title + '_ref_${dataInformation['RealEntryNo']}',
                companySettings, settings, data, customerBalance)
            .then((value) => pdfPath = value);
      });
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

  var title = '';
  @override
  Widget build(BuildContext context) {
    final route =
        ModalRoute.of(context).settings.arguments as Map<String, String>;
    title = route['title'];
    return Scaffold(
        appBar: AppBar(
          title: Text(title + ' Preview'),
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
                                subject: title,
                                text: 'this is ' + title,
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
                              title + '_ref_${dataInformation['RealEntryNo']}',
                              companySettings,
                              settings,
                              data,
                              byteImage,
                              customerBalance,
                              printerType,
                              printerDevice);
                        })
                      });
                })
          ],
        ),
        body: eNo > 0 ? webView() : const Center(child: Text('Not Found')));
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
    var _dataQr = SaudiConversion.getBase64(
        companySettings.name,
        '${ComSettings.getValue('GST-NO', settings)}',
        DateUtil.dateTimeQrDMY(DateUtil.datedYMD(dataInformation['DDate']) +
            ' ' +
            DateUtil.timeHMS(dataInformation['BTime'])),
        double.tryParse(dataInformation['GrandTotal'].toString())
            .toStringAsFixed(decimal),
        (double.tryParse(dataInformation['CGST'].toString()) +
                double.tryParse(dataInformation['SGST'].toString()) +
                double.tryParse(dataInformation['IGST'].toString()))
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
    var taxSale = salesTypeData.tax;
    var invoiceHead = salesTypeData.type == 'SALES-ES'
        ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
        : salesTypeData.type == 'SALES-Q'
            ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
            : salesTypeData.type == 'SALES-O'
                ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
                : Settings.getValue<String>(
                    'key-sales-invoice-head', 'INVOICE');

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
                        <td class="total-value" align="right">${(double.tryParse(dataInformation['CGST'].toString()) + double.tryParse(dataInformation['SGST'].toString()) + double.tryParse(dataInformation['IGST'].toString())).toStringAsFixed(decimal)}</td>
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
                          <td style="font-size:10px;">${NumberToWord().convert('en', double.tryParse(dataInformation['GrandTotal'].toString()).round())}</td>
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
                      <td colspan="2" class="total-value1" align="right">Net Total :</td>
                          <td class="total-value" align="right">${double.tryParse(dataInformation['GrandTotal'].toString()).toStringAsFixed(decimal)}</td>
                              </tr>
                            </table>
                            <table width="100%">
                      <tr>
                          <td style="font-size:10px;"> Amount in Words: ${NumberToWord().convert('en', double.tryParse(dataInformation['GrandTotal'].toString()).round())}</td>
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

  String uint8ListTob64(Uint8List uint8list) {
    String base64String = base64Encode(uint8list);
    String header = "data:image/png;base64,";
    return header + base64String;
  }

  showData() {
    var taxSale = salesTypeData.tax;
    var invoiceHead = salesTypeData.type == 'SALES-ES'
        ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
        : salesTypeData.type == 'SALES-Q'
            ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
            : salesTypeData.type == 'SALES-O'
                ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
                : Settings.getValue<String>(
                    'key-sales-invoice-head', 'INVOICE');
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
                          Text(ComSettings.getValue('GST-NO', settings)),
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
                                    'CGST : ${dataInformation['CGST']} SGST : ${dataInformation['SGST']} = ${(dataInformation['CGST'] + dataInformation['SGST'])}'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('VAT : ${dataInformation['IGST']}'),
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
                      <td width="50%" align="left">${dataParticulars[i]['itemname']}</td>
                      <td width="10%" align="center">${dataParticulars[i]['serialno'].toString()}</td>
                      <td width="6%" align="left">${dataParticulars[i]['hsncode']}</td>
                      <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                      <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Rate'].toString()).toStringAsFixed(decimal)}</td>
                      <td width="3%" align="right">${double.tryParse(dataParticulars[i]['igst'].toString()).toStringAsFixed(decimal)}</td>
                      <td width="10%" align="right">${double.tryParse(dataParticulars[i]['CGST'].toString()).toStringAsFixed(decimal)}</td>
                      <td width="10%" align="right">${double.tryParse(dataParticulars[i]['SGST'].toString()).toStringAsFixed(decimal)}</td>
                      <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                    </tr>
                    '''
                  : '''
                  </tr>
                    <tr class="item-row">
                    <td width="50%" align="left">${dataParticulars[i]['itemname']}</td>
                    <td width="6%" align="left">${dataParticulars[i]['hsncode']}</td>
                    <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Rate'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="3%" align="right">${double.tryParse(dataParticulars[i]['igst'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['CGST'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['SGST'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                  </tr>
                  '''
              : isItemSerialNo
                  ? '''
                  </tr>
                    <tr class="item-row">
                    <td width="50%" align="left">${dataParticulars[i]['itemname']}</td>
                    <td width="10%" align="center">${dataParticulars[i]['serialno'].toString()}</td>
                    <td width="6%" align="left">${dataParticulars[i]['hsncode']}</td>
                    <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Rate'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="3%" align="right">${double.tryParse(dataParticulars[i]['igst'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['IGST'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                  </tr>
                  '''
                  : '''
                  </tr>
                    <tr class="item-row">
                    <td width="50%" align="left">${dataParticulars[i]['itemname']}</td>
                    <td width="6%" align="left">${dataParticulars[i]['hsncode']}</td>
                    <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Rate'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="3%" align="right">${double.tryParse(dataParticulars[i]['igst'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['IGST'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                  </tr>
                '''
          : isItemSerialNo
              ? '''
                  </tr>
                    <tr class="item-row">
                    <td width="64%" align="left">${dataParticulars[i]['itemname']}</td>
                    <td width="10%" align="center">${dataParticulars[i]['serialno'].toString()}</td>
                    <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Rate'].toString()).toStringAsFixed(decimal)}</td>
                    <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                  </tr>
                '''
              : '''
                </tr>
                  <tr class="item-row">
                  <td width="64%" align="left">${dataParticulars[i]['itemname']}</td>
                  <td width="6%" align="right">${dataParticulars[i]['unitName'].toString().isNotEmpty ? dataParticulars[i]['Qty'].toString() + ' (' + dataParticulars[i]['unitName'] + ')' : dataParticulars[i]['Qty']}</td>
                  <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Rate'].toString()).toStringAsFixed(decimal)}</td>
                  <td width="10%" align="right">${double.tryParse(dataParticulars[i]['Total'].toString()).toStringAsFixed(decimal)}</td>
                </tr>
                ''';
      totalQty += double.tryParse(dataParticulars[i]['Qty'].toString());
      totalRate += double.tryParse(dataParticulars[i]['Rate'].toString());
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
    int printerDevice) {
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
      //13: UROVO
      printUrovo([companySettings, settings, data]);
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

List<String> newDataList = ["2", "3", "4"];

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

  var taxSale = salesTypeData.tax;
  var invoiceHead = salesTypeData.type == 'SALES-ES'
      ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
      : salesTypeData.type == 'SALES-Q'
          ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
          : salesTypeData.type == 'SALES-O'
              ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
              : Settings.getValue<String>('key-sales-invoice-head', 'INVOICE');
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
      await SPrinter.text(firm['name']);
      await SPrinter.setFontSize(26);
      await SPrinter.lineWrap();
      await SPrinter.text(firm['add1']);
      await SPrinter.text('Tel : ${firm['telephone'] + ',' + firm['mobile']}');
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
    } else {
      if (ComSettings.appSettings('bool', 'key-print-header-es', false)) {
        await SPrinter.setAlign(sum_mi.Align.center);
        await SPrinter.setFontSize(30);
        await SPrinter.text(firm['name']);
        await SPrinter.setFontSize(26);
        await SPrinter.lineWrap();
        await SPrinter.text(firm['add1']);
        await SPrinter.text(
            'Tel : ${firm['telephone'] + ',' + firm['mobile']}');
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
            settings.name,
            ComSettings.getValue('GST-NO', settings),
            DateUtil.dateTimeQrDMY(DateUtil.datedYMD(inf['DDate']) +
                ' ' +
                DateUtil.timeHMS(inf['BTime'])),
            double.tryParse(inf['GrandTotal'].toString()).toStringAsFixed(2),
            (double.tryParse(inf['CGST'].toString()) +
                    double.tryParse(inf['SGST'].toString()) +
                    double.tryParse(inf['IGST'].toString()))
                .toStringAsFixed(2)));
      }
    } else if (isEsQrCodeKSA) {
      await SPrinter.qrCode(SaudiConversion.getBase64(
          settings.name,
          ComSettings.getValue('GST-NO', settings),
          DateUtil.dateTimeQrDMY(DateUtil.datedYMD(inf['DDate']) +
              ' ' +
              DateUtil.timeHMS(inf['BTime'])),
          double.tryParse(inf['GrandTotal'].toString()).toStringAsFixed(2),
          (double.tryParse(inf['CGST'].toString()) +
                  double.tryParse(inf['SGST'].toString()) +
                  double.tryParse(inf['IGST'].toString()))
              .toStringAsFixed(2)));
    }
    await SPrinter.lineWrap(3);
  }
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
  var deliveryNote = bill['DeliveryNote'];
  var otherAmount = bill['otherAmount'];

  bool taxSale = salesTypeData.tax;
  var invoiceHead = salesTypeData.type == 'SALES-ES'
      ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
      : salesTypeData.type == 'SALES-Q'
          ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
          : salesTypeData.type == 'SALES-O'
              ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
              : Settings.getValue<String>('key-sales-invoice-head', 'INVOICE');
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
                        double.tryParse(inf['IGST'].toString()))
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
                        double.tryParse(inf['IGST'].toString()))
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
    //   'deliveryNote': json.encode(deliveryNote),
    //   'otherAmount': json.encode(otherAmount),
    //   'printHeaderInEs':
    //       ComSettings.appSettings('bool', 'key-print-header-es', false),
    //   'balance': balance,
    //   'message': bill['message'],
    //   'qrCode': qrCode,
    // };
    var content = SalesBillData(
        taxSale: taxSale,
        invoiceHead: invoiceHead,
        isQrCodeKsa: isQrCodeKSA,
        isEsQrCodeKsa: isEsQrCodeKSA,
        printCopy: printCopy,
        printerModel: printerModel,
        companyTaxMode: companyTaxMode,
        taxNo: ComSettings.getValue('GST-NO', settings),
        companyInfo: [
          CompanyInfo(
              name: firm.name,
              add1: firm.add1,
              add2: firm.add2,
              add3: firm.add3,
              add4: firm.add4,
              add5: firm.add5,
              sName: firm.sName,
              telephone: firm.telephone,
              email: firm.email,
              mobile: firm.mobile,
              tin: firm.tin,
              pin: firm.pin,
              taxCalculation: firm.taxCalculation,
              sCurrency: firm.sCurrency,
              sDate: firm.sDate,
              eDate: firm.eDate,
              customerCode: firm.customerCode,
              runningDate: firm.runningDate)
        ],
        information: [
          BillInformation(
              dDate: inf['DDate'],
              bTime: inf["BTime"],
              invoiceNo: inf["InvoiceNo"],
              entryNo: inf["EntryNo"],
              realEntryNo: inf["RealEntryNo"],
              customer: inf["Customer"],
              toName: inf["ToName"],
              add1: inf["Add1"],
              add2: inf["Add2"],
              add3: inf["Add3"],
              add4: inf["Add4"],
              grossValue: double.tryParse(inf["GrossValue"].toString()) ?? 0,
              discount: double.tryParse(inf["Discount"].toString()) ?? 0,
              netAmount: double.tryParse(inf["NetAmount"].toString()) ?? 0,
              cess: double.tryParse(inf["cess"].toString()) ?? 0,
              total: double.tryParse(inf["Total"].toString()) ?? 0,
              loadingCharge:
                  double.tryParse(inf["loadingCharge"].toString()) ?? 0,
              otherCharges:
                  double.tryParse(inf["OtherCharges"].toString()) ?? 0,
              otherDiscount:
                  double.tryParse(inf["OtherDiscount"].toString()) ?? 0,
              roundoff: double.tryParse(inf["Roundoff"].toString()) ?? 0,
              grandTotal: double.tryParse(inf["GrandTotal"].toString()) ?? 0,
              narration: inf["Narration"],
              profit: double.tryParse(inf["Profit"].toString()) ?? 0,
              cashReceived:
                  double.tryParse(inf["CashReceived"].toString()) ?? 0,
              cgst: double.tryParse(inf["CGST"].toString()) ?? 0,
              sgst: double.tryParse(inf["SGST"].toString()) ?? 0,
              igst: double.tryParse(inf["IGST"].toString()) ?? 0,
              returnAmount:
                  double.tryParse(inf["ReturnAmount"].toString()) ?? 0,
              returnNo: inf["ReturnNo"],
              balanceAmount:
                  double.tryParse(inf["BalanceAmount"].toString()) ?? 0,
              balance: double.tryParse(inf["Balance"].toString()) ?? 0,
              gstno: inf["gstno"])
        ],
        particulars: Particular.fromJsonListDynamic(det),
        serialNo: SerialNO.fromJsonListDynamic(serialNo),
        deliveryNote: DeliveryNote.fromJsonListDynamic(deliveryNote),
        otherAmount: BillOtherAmount.fromJsonListDynamic(otherAmount),
        printHeaderInEs:
            ComSettings.appSettings('bool', 'key-print-header-es', false),
        balance: balance,
        message: bill['message'],
        qrCode: qrCode);

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
    //           det[i]['itemname'],
    //           det[i]['Qty'].toString(),
    //           det[i]['Rate'].toString(),
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
    //           det[i]['itemname'],
    //           det[i]['Qty'].toString(),
    //           det[i]['Rate'].toString(),
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
    //                 double.tryParse(inf['IGST'].toString()))
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
    //               double.tryParse(inf['IGST'].toString()))
    //           .toStringAsFixed(2)));
    // }
    // await lineWrap(32, posPrinter);
    // await lineWrap(32, posPrinter);
    // await lineWrap(32, posPrinter);
    // await lineWrap(32, posPrinter);

    try {
      var b = salesBillDataToMap([content]);
      var c = content.toJson();
      var status = await channel
          .invokeMethod('sentPrintUrovo', <String, String>{'content': c});
      debugPrint('Print finished' + status.ToString());
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

Future<String> _createPDF(String title, CompanyInformation companySettings,
    List<CompanySettings> settings, var data, var customerBalance) async {
  return makePDF(title, companySettings, settings, data, customerBalance)
      .then((value) => savePreviewPDF(value, title));
}

Future<String> savePreviewPDF(pw.Document pdf, var title) async {
  title = title.replaceAll(new RegExp(r'[^\w\s]+'), '');
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
  var output = await getTemporaryDirectory();
  final file = File('${output.path}/' + title + '.pdf');
  await file.writeAsBytes(await pdf.save());
  return file.path.toString();
  // }
}

Future<pw.Document> makePDF(String title, CompanyInformation companySettings,
    List<CompanySettings> settings, var data, var customerBalance) async {
  var dataInformation = data['Information'][0];
  var dataParticulars = data['Particulars'];
  // var dataSerialNO = data['SerialNO'];
  // var dataDeliveryNote = data['DeliveryNote'];
  var otherAmount = data['otherAmount'];

  var taxSale = salesTypeData.tax;
  var invoiceHead = salesTypeData.type == 'SALES-ES'
      ? Settings.getValue<String>('key-sales-estimate-head', 'ESTIMATE')
      : salesTypeData.type == 'SALES-Q'
          ? Settings.getValue<String>('key-sales-quotation-head', 'QUOTATION')
          : salesTypeData.type == 'SALES-O'
              ? Settings.getValue<String>('key-sales-order-head', 'ORDER')
              : Settings.getValue<String>('key-sales-invoice-head', 'INVOICE');
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(tableHeaders[0],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ]),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(tableHeaders[1],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ]),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(tableHeaders[2],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ]),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(tableHeaders[3],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ]),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(tableHeaders[4],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ]),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(tableHeaders[5],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ]),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(tableHeaders[6],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ]),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(tableHeaders[7],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ]),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(tableHeaders[8],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ]),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(tableHeaders[9],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ]),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(tableHeaders[10],
                                      style: const pw.TextStyle(fontSize: 9)),
                                  // pw.Divider(thickness: 1)
                                ]),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
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
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          '${dataParticulars[i]['slno']}',
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
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
                                          dataParticulars[i]['itemname'],
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
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
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          double.tryParse(dataParticulars[i]
                                                      ['RealRate']
                                                  .toString())
                                              .toStringAsFixed(decimal),
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          '${dataParticulars[i]['Qty']}',
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
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
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          double.tryParse(dataParticulars[i]
                                                      ['Rate']
                                                  .toString())
                                              .toStringAsFixed(decimal),
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
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
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          '${dataParticulars[i]['igst']} %',
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
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
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
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
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
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
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                            ])
                          : pw.TableRow(children: [
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          '${dataParticulars[i]['slno']}',
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
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
                                          dataParticulars[i]['itemname'],
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
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
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          double.tryParse(dataParticulars[i]
                                                      ['RealRate']
                                                  .toString())
                                              .toStringAsFixed(decimal),
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          '${dataParticulars[i]['Qty']}',
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
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
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          double.tryParse(dataParticulars[i]
                                                      ['Rate']
                                                  .toString())
                                              .toStringAsFixed(decimal),
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
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
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          '${dataParticulars[i]['igst']} %',
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          double.tryParse(dataParticulars[i]
                                                      ['IGST']
                                                  .toString())
                                              .toStringAsFixed(decimal),
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ]),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
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
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
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
                                  'CGST : ${double.tryParse(dataInformation['CGST'].toString()).toStringAsFixed(decimal)} SGST : ${double.tryParse(dataInformation['SGST'].toString()).toStringAsFixed(decimal)} = ${(double.tryParse(dataInformation['CGST'].toString()) + double.tryParse(dataInformation['SGST'].toString())).toStringAsFixed(decimal)}'),
                            ],
                          )
                        : pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                  'VAT : ${double.tryParse(dataInformation['IGST'].toString()).toStringAsFixed(decimal)}'),
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
                                child: pw.Text('${dataParticulars[i]['slno']}',
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
                                child: pw.Text(dataParticulars[i]['itemname'],
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
                                    double.tryParse(dataParticulars[i]['Rate']
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
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          dataParticulars[i]['serialno']
                                              .toString(),
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
                                      // pw.Divider(thickness: 1)
                                    )
                                  ])
                            : pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(2.0),
                                      child: pw.Text(
                                          dataParticulars[i]['unitName']
                                              .toString(),
                                          style:
                                              const pw.TextStyle(fontSize: 9)),
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
                                    double.tryParse(dataParticulars[i]['Total']
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

Future<String> printDocument(String title, CompanyInformation companySettings,
    List<CompanySettings> settings, var data, var customerBalance) async {
  await Printing.layoutPdf(
      // [onLayout] will be called multiple times
      // when the user changes the printer or printer settings
      onLayout: (PdfPageFormat format) async => await Printing.convertHtml(
            format: format,
            html: '<html><body><p>Hello!</p></body></html>',
          ));
}

Future<String> savePrintPDF(pw.Document pdf) async {
  // await Printing.layoutPdf(
  //     onLayout: (PdfPageFormat format) async => pdf.save());
  return 'printing';
}

typedef LayoutCallbackWithData = Future<Uint8List> Function(
    PdfPageFormat pageFormat, CustomData data);
