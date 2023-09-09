import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:sheraccerp/models/print_settings_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';

class InvoiceDesign extends StatefulWidget {
  const InvoiceDesign({Key? key}) : super(key: key);

  @override
  State<InvoiceDesign> createState() => _InvoiceDesignState();
}

class _InvoiceDesignState extends State<InvoiceDesign> {
  DioService api = DioService();
  String path = '';
  bool isLoading = false;
  late PrintSettingsModel printSettingsModel;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async {
    if (printSettingsList != null) {
      if (printSettingsList.isNotEmpty) {
        printSettingsModel = printSettingsList.firstWhere((element) =>
            element.model == 'INVOICE DESIGNER' &&
            element.dTransaction == 'SALES-BB' &&
            element.fyId == currentFinancialYear.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Designer Preview'),
      ),
      body: Center(
        child: isLoading
            ? const Loading()
            : Column(
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        await downloadAndOpenFile(context);
                      },
                      child: const Text('Generate')),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PDFScreen(
                                  pathPDF: path.toString(),
                                  subject: 'title',
                                  text: 'this is title',
                                )));
                      },
                      child: const Text('View pdf'))
                ],
              ),
      ),
    );
  }

  static Future<String?> openFile(String url) async {
    final OpenResult result = await OpenFile.open(url);
    switch (result.type) {
      case ResultType.error:
        return result.message;
      default:
        return null;
    }
  }

  Future<void> downloadAndOpenFile(BuildContext context) async {
    var data = {
      "fileName": ComSettings.removeInvDesignFilePath(
          printSettingsModel.filePath), //"TAXINVOICE.repx",
      "code": '',
      "id": "1",
      "decimalPoint": 0,
      "CurrencyFormat": "##0.00",
      "printCaption": "TAX INVOICE",
      "obTotal": "0.00",
      "obNetBalance": "0.00",
      "checkob": true,
      "bankifsc": "ifsc",
      "bankaccount": "bankac",
      "bankbranch": "branch",
      "Warehousename": "ware name",
      "WareHouseAdd1": " ware add1",
      "bill_lines": 13,
      "WareHouseAdd2": "ware add2",
      "WareHouseAdd3": "ware add3",
      "SiVa": "siva",
      "CIva": "civa",
      "PointThisBill": "0.00",
      "TotalPoint": "0.00",
      "CompanyName": "SHERSOFT PVT",
      "CompanyAdd1": "JUBILY ROAD PERINTHALMANNA",
      "CompanyAdd2": "MALAPPURAM",
      "CompanyAdd3": "add3",
      "CompanyAdd4": "add4",
      "CompanyAdd5": "add5",
      "SoftwarePackage": "INDIA",
      "companyTaxNo": "32AF42424E3424",
      "CompanyMailId": "cmail",
      "CompanyTelephone": "cphone",
      "companyMobile": "7560889996",
      "CompanyBank": "federal",
      "State": "KERALA",
      "StateCode": "32",
      "ledName": "customer 1",
      "ledAdd1": "c add1",
      "ledAdd2": "c add 2",
      "ledAdd3": "c add 3",
      "ledAdd4": "c add 4",
      "ledTaxNo": "32 c tax",
      "ledPan": "led pan",
      "ledmobile": "012345678",
      "ledState": "KERALA",
      "ledStateCode": "32",
      "ledCperson": "ledconpersn",
      "ledCreditDays": "0",
      "ledMailId": "ledmail",
      "invoiceLetter": printSettingsModel.invoiceLetter,
      "invoiceNo": "1001",
      "invoiceSuffix": printSettingsModel.invoiceSuffix,
      "date": "2023-08-28",
      "SalesMan": "sales1",
      "Narration": "narration",
      "Location": "location",
      "Project": "proj",
      "TotalGross": "105.00",
      "TotalDisc": "1.00",
      "TotalNet": "104.00",
      "TotalCgst": "1.20",
      "TotalSgst": "1.20",
      "TotalIgst": "2.40",
      "TotalCess": "0.00",
      "TotalKfc": "0.00",
      "TotalTotal": "104.00",
      "TotalQty": "1",
      "OtherCharges": "0.10",
      "OtherdiscAmount": "0.50",
      "LoadingCharge": "0.25",
      "ServiceCharge": "0.32",
      "GrandTotal": "106.20",
      "cashpaid": "58.20",
      "ledgerOpeningBalance": "20.00",
      "Roundoff": "0.02",
      "Time": "10:20:53",
      "words": "paisa hai",
      "deliverynote": "deliverynote",
      "vehicle": "vehicle",
      "destination": "destination",
      "waybillno": "waybillno-25",
      "pono": "pono",
      "Place": "place",
      "dtissue": "dtissue",
      "dtdespacth": "dtdescp",
      "deliverydate": "2023-08-29",
      "terms": "termsfsfs",
      "JobNo": "00245",
      "dName": "dNAme sdsd",
      "dAdddress": "d addeee",
      "dAdd1": "dadd1 ...",
      "dGstno": "dgstno...",
      "dState": "dstate",
      "dStateCode": "32",
      "pointOb": "0.01",
      "systemNo": "05185",
      "CurrentUserName": "ADMIN",
      "ReturnAmount": "0.00",
      "tenderBalance": "0.00",
      "tenderCash": "0.00",
      "CardAc": "card ac",
      "CardAmount": "0.00",
      "YouHaveSaved": "you have hi",
      "Redeem": "0",
      "Combined": "combined",
      "EmiAc": "emiac",
      "SaudiQr": "sudi",
      "EmiRefNo": "emiref",
      "mrpTotal": "10.00",
      "TenderType": "tenderty",
      "CheckCardDetails": false,
      "IRN": "irn",
      "SignInv": "signinv",
      "SignQR": "signqr",
      "upiurl": "upi",
      "TcsAmount": "tcsamt",
      "TcsPer": "tscper",
      "AckDate": "ackdate",
      "Ackno": "acckno",
      "SecondName": "secname",
      "dtSalesDate": "dtsalerdd",
      "paymentTerms": "payterm",
      "WarrentyTerms": "warterm",
      "salesEntryNo": "1",
      "CheckSalesReturn": false,
      "QuotationNo": "",
      "OtherCharges1": "other1",
      "OtherCharges2": "other2",
      "OtherCharges3": "other3",
      "OtherCharges4": "other4",
      "OtherCharges5": "other5",
      "OtherCharges6": "other6",
      "despathed": "desped",
      "itemList": [
        {
          "Barcode": "1000",
          "ItemCode": "1",
          "ItemName": "ItemName",
          "Qty": "1",
          "Rate": "10",
          "RRate": "10",
          "Gross": "10",
          "Disc": "0",
          "DiscPer": "0",
          "RDisc": "0",
          "Net": "10",
          "CGST": "0",
          "CGSTP": "0",
          "SGST": "0",
          "SGSTP": "0",
          "IGST": "0",
          "IGSTP": "0",
          "KFC": "0",
          "KFCPer": "0",
          "Total": "10",
          "ItemId": "1",
          "SlNo": "1",
          "Mrp": "10",
          "Unit": "1",
          "CessP": "0",
          "Cess": "0",
          "Adcess": "0",
          "AdcessP": "0",
          "SerialNo": "0",
          "HSN": "123465",
          "AltQty": "ن",
          "RegItemName": "ييب",
          "isRegItemName": "يلل",
          "QtyArabic": "ث",
          "RateArabic": "ق",
          "TotalArabic": "ف",
          "MinQty": "0",
          "MaxQty": "0",
          "Branch": "10",
          "LC": "0",
          "TaxPer": "0",
          "UnitCost": "0",
          "FreeQty": "0",
          "ScanBarcode": "0",
          "TotalTax": "0",
          "MUltiUnitRate": "10",
          "ItemMultiBarcode": "1000",
          "EmpCode": "0",
          "UnitId": "1",
          "UnitValue": "1",
          "Remark": "Remark",
          "isRegName": false
        }
      ]
    };

    try {
      File? file = await api.getInvoiceDesignerPdf(data);
      if (file != null) {
        // final String? result = await openFile(file.path.toString());
        // if (result != null) {
        //   // Warning
        // }
        path = file.path.toString();
        if (path.isNotEmpty) {
          setState(() {
            isLoading = false;
          });
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PDFScreen(
                    pathPDF: path.toString(),
                    subject: 'title',
                    text: 'this is title',
                  )));
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint(e.toString());
    }
  }

  // Future<File?> downloadPDF(data) async {
  //   try {
  //     final response = await dio.post(
  //         'http://148.72.210.101:888/Home/DownloadPdf',
  //         data: data,
  //         options: Options(
  //             headers: {'Content-Type': 'application/json'},
  //             responseType: ResponseType.bytes));
  //     if (response != null) {
  //       final Directory? appDir = await getTemporaryDirectory();
  //       String tempPath = appDir!.path;
  //       final String fileName =
  //           DateTime.now().microsecondsSinceEpoch.toString() + '-' + 'akt.pdf';
  //       File file = File('$tempPath/$fileName');
  //       if (!await file.exists()) {
  //         await file.create();
  //       }
  //       await file.writeAsBytes(response.data);
  //       return file;
  //     }
  //     debugPrint('The download failed.');
  //   } catch (value) {
  //     if (value is DioError) {
  //       debugPrint(value.response.toString());
  //     }
  //     debugPrint(value.toString());
  //   }
  //   return null;
  // }
}
