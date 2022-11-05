import 'dart:convert';

import 'package:sheraccerp/models/sales_model.dart';

List<SalesBillData> salesBillDataFromMap(String str) =>
    List<SalesBillData>.from(
        json.decode(str).map((x) => SalesBillData.fromMap(x)));

String salesBillDataToMap(List<SalesBillData> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class SalesBillData {
  SalesBillData({
    required this.taxSale,
    required this.invoiceHead,
    required this.isQrCodeKsa,
    required this.isEsQrCodeKsa,
    required this.printCopy,
    required this.printerModel,
    required this.companyTaxMode,
    required this.taxNo,
    required this.companyInfo,
    required this.information,
    required this.particulars,
    required this.serialNo,
    required this.deliveryNote,
    required this.otherAmount,
    required this.printHeaderInEs,
    required this.balance,
    required this.message,
    required this.qrCode,
  });

  bool taxSale;
  String invoiceHead;
  bool isQrCodeKsa;
  bool isEsQrCodeKsa;
  int printCopy;
  int printerModel;
  String companyTaxMode;
  String taxNo;
  List<CompanyInfo> companyInfo;
  List<BillInformation> information;
  List<Particular> particulars;
  List<SerialNO> serialNo;
  List<DeliveryNote> deliveryNote;
  List<BillOtherAmount> otherAmount;
  bool printHeaderInEs;
  String balance;
  String message;
  String qrCode;

  factory SalesBillData.fromMap(Map<String, dynamic> json) => SalesBillData(
        taxSale: json["taxSale"],
        invoiceHead: json["invoiceHead"],
        isQrCodeKsa: json["isQrCodeKSA"],
        isEsQrCodeKsa: json["isEsQrCodeKSA"],
        printCopy: json["printCopy"],
        printerModel: json["printerModel"],
        companyTaxMode: json["companyTaxMode"],
        taxNo: json["taxNo"],
        companyInfo: List<CompanyInfo>.from(
            json["companyInfo"].map((x) => CompanyInfo.fromMap(x))),
        information: List<BillInformation>.from(
            json["information"].map((x) => BillInformation.fromMap(x))),
        particulars: List<Particular>.from(
            json["particulars"].map((x) => Particular.fromMap(x))),
        serialNo: List<SerialNO>.from(json["serialNo"].map((x) => x)),
        deliveryNote:
            List<DeliveryNote>.from(json["deliveryNote"].map((x) => x)),
        otherAmount: List<BillOtherAmount>.from(
            json["otherAmount"].map((x) => BillOtherAmount.fromMap(x))),
        printHeaderInEs: json["printHeaderInEs"],
        balance: json["balance"].toString(),
        message: json["message"],
        qrCode: json["qrCode"],
      );

  Map<String, dynamic> toMap() => {
        "taxSale": taxSale,
        "invoiceHead": invoiceHead,
        "isQrCodeKSA": isQrCodeKsa,
        "isEsQrCodeKSA": isEsQrCodeKsa,
        "printCopy": printCopy,
        "printerModel": printerModel,
        "companyTaxMode": companyTaxMode,
        "taxNo": taxNo,
        "companyInfo": List<dynamic>.from(companyInfo.map((x) => x.toMap())),
        "information": List<dynamic>.from(information.map((x) => x.toMap())),
        "particulars": List<dynamic>.from(particulars.map((x) => x.toMap())),
        "serialNo": List<dynamic>.from(serialNo.map((x) => x)),
        "deliveryNote": List<dynamic>.from(deliveryNote.map((x) => x)),
        "otherAmount": List<dynamic>.from(otherAmount.map((x) => x.toMap())),
        "printHeaderInEs": printHeaderInEs,
        "balance": balance,
        "message": message,
        "qrCode": qrCode,
      };

  factory SalesBillData.fromJson(String str) =>
      SalesBillData.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());
}

class CompanyInfo {
  CompanyInfo({
    required this.name,
    required this.add1,
    required this.add2,
    required this.add3,
    required this.add4,
    required this.add5,
    required this.sName,
    required this.telephone,
    required this.email,
    required this.mobile,
    required this.tin,
    required this.pin,
    required this.taxCalculation,
    required this.sCurrency,
    required this.sDate,
    required this.eDate,
    required this.customerCode,
    required this.runningDate,
  });

  String name;
  String add1;
  String add2;
  String add3;
  String add4;
  String add5;
  String sName;
  String telephone;
  String email;
  String mobile;
  String tin;
  String pin;
  String taxCalculation;
  String sCurrency;
  String sDate;
  String eDate;
  String customerCode;
  String runningDate;

  factory CompanyInfo.fromMap(Map<String, dynamic> json) => CompanyInfo(
        name: json["name"],
        add1: json["add1"],
        add2: json["add2"],
        add3: json["add3"],
        add4: json["add4"],
        add5: json["add5"],
        sName: json["sName"],
        telephone: json["telephone"],
        email: json["email"],
        mobile: json["mobile"],
        tin: json["tin"],
        pin: json["pin"],
        taxCalculation: json["taxCalculation"],
        sCurrency: json["sCurrency"],
        sDate: json["sDate"],
        eDate: json["eDate"],
        customerCode: json["customerCode"],
        runningDate: json["runningDate"],
      );

  Map<String, dynamic> toMap() => {
        "name": name,
        "add1": add1,
        "add2": add2,
        "add3": add3,
        "add4": add4,
        "add5": add5,
        "sName": sName,
        "telephone": telephone,
        "email": email,
        "mobile": mobile,
        "tin": tin,
        "pin": pin,
        "taxCalculation": taxCalculation,
        "sCurrency": sCurrency,
        "sDate": sDate,
        "eDate": eDate,
        "customerCode": customerCode,
        "runningDate": runningDate,
      };

  static List<CompanyInfo> fromJsonList(List list) {
    return list.map((item) => CompanyInfo.fromJson(item)).toList();
  }

  factory CompanyInfo.fromJson(String str) =>
      CompanyInfo.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());
}

class BillInformation {
  BillInformation({
    required this.dDate,
    required this.bTime,
    required this.invoiceNo,
    required this.entryNo,
    required this.realEntryNo,
    required this.customer,
    required this.toName,
    required this.add1,
    required this.add2,
    required this.add3,
    required this.add4,
    required this.grossValue,
    required this.discount,
    required this.netAmount,
    required this.cess,
    required this.total,
    required this.loadingCharge,
    required this.otherCharges,
    required this.otherDiscount,
    required this.roundoff,
    required this.grandTotal,
    required this.narration,
    required this.profit,
    required this.cashReceived,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.returnAmount,
    required this.returnNo,
    required this.balanceAmount,
    required this.balance,
    required this.gstno,
  });

  String dDate;
  String bTime;
  String invoiceNo;
  int entryNo;
  int realEntryNo;
  int customer;
  String toName;
  String add1;
  String add2;
  String add3;
  String add4;
  double grossValue;
  double discount;
  double netAmount;
  double cess;
  double total;
  double loadingCharge;
  double otherCharges;
  double otherDiscount;
  double roundoff;
  double grandTotal;
  String narration;
  double profit;
  double cashReceived;
  double cgst;
  double sgst;
  double igst;
  double returnAmount;
  int returnNo;
  double balanceAmount;
  double balance;
  String gstno;

  factory BillInformation.fromMap(Map<String, dynamic> json) => BillInformation(
        dDate: json["DDate"],
        bTime: json["BTime"],
        invoiceNo: json["InvoiceNo"],
        entryNo: json["EntryNo"],
        realEntryNo: json["RealEntryNo"],
        customer: json["Customer"],
        toName: json["ToName"],
        add1: json["Add1"],
        add2: json["Add2"],
        add3: json["Add3"],
        add4: json["Add4"],
        grossValue: double.tryParse(json["GrossValue"].toString()) ?? 0,
        discount: double.tryParse(json["Discount"].toString()) ?? 0,
        netAmount: double.tryParse(json["NetAmount"].toString()) ?? 0,
        cess: double.tryParse(json["cess"].toString()) ?? 0,
        total: double.tryParse(json["Total"].toString()) ?? 0,
        loadingCharge: double.tryParse(json["loadingCharge"].toString()) ?? 0,
        otherCharges: double.tryParse(json["OtherCharges"].toString()) ?? 0,
        otherDiscount: double.tryParse(json["OtherDiscount"].toString()) ?? 0,
        roundoff: double.tryParse(json["Roundoff"].toString()) ?? 0,
        grandTotal: double.tryParse(json["GrandTotal"].toString()) ?? 0,
        narration: json["Narration"],
        profit: double.tryParse(json["Profit"].toString()) ?? 0,
        cashReceived: double.tryParse(json["CashReceived"].toString()) ?? 0,
        cgst: double.tryParse(json["CGST"].toString()) ?? 0,
        sgst: double.tryParse(json["SGST"].toString()) ?? 0,
        igst: double.tryParse(json["IGST"].toString()) ?? 0,
        returnAmount: double.tryParse(json["ReturnAmount"].toString()) ?? 0,
        returnNo: json["ReturnNo"],
        balanceAmount: double.tryParse(json["BalanceAmount"].toString()) ?? 0,
        balance: double.tryParse(json["Balance"].toString()) ?? 0,
        gstno: json["gstno"],
      );

  Map<String, dynamic> toMap() => {
        "DDate": dDate,
        "BTime": bTime,
        "InvoiceNo": invoiceNo,
        "EntryNo": entryNo,
        "RealEntryNo": realEntryNo,
        "Customer": customer,
        "ToName": toName,
        "Add1": add1,
        "Add2": add2,
        "Add3": add3,
        "Add4": add4,
        "GrossValue": grossValue,
        "Discount": discount,
        "NetAmount": netAmount,
        "cess": cess,
        "Total": total,
        "loadingCharge": loadingCharge,
        "OtherCharges": otherCharges,
        "OtherDiscount": otherDiscount,
        "Roundoff": roundoff,
        "GrandTotal": grandTotal,
        "Narration": narration,
        "Profit": profit,
        "CashReceived": cashReceived,
        "CGST": cgst,
        "SGST": sgst,
        "IGST": igst,
        "ReturnAmount": returnAmount,
        "ReturnNo": returnNo,
        "BalanceAmount": balanceAmount,
        "Balance": balance,
        "gstno": gstno,
      };
}

class BillOtherAmount {
  BillOtherAmount({
    required this.ledCode,
    required this.symbol,
    required this.ledName,
    required this.amount,
    required this.percentage,
  });

  int ledCode;
  String symbol;
  String ledName;
  double amount;
  double percentage;

  factory BillOtherAmount.fromMap(Map<String, dynamic> json) => BillOtherAmount(
        ledCode: json["LedCode"],
        symbol: json["Symbol"],
        ledName: json["LedName"],
        amount: double.tryParse(json["Amount"].toString()) ?? 0,
        percentage: double.tryParse(json["Percentage"].toString()) ?? 0,
      );

  Map<String, dynamic> toMap() => {
        "LedCode": ledCode,
        "Symbol": symbol,
        "LedName": ledName,
        "Amount": amount,
        "Percentage": percentage,
      };

  static List<BillOtherAmount> fromJsonList(List list) {
    return list.map((item) => BillOtherAmount.fromJson(item)).toList();
  }

  factory BillOtherAmount.fromJson(String str) =>
      BillOtherAmount.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  static List<BillOtherAmount> fromJsonListDynamic(List<dynamic> list) {
    return list.map((item) => BillOtherAmount.fromJsonMap(item)).toList();
  }

  factory BillOtherAmount.fromJsonMap(Map<String, dynamic> map) =>
      BillOtherAmount.fromMap(map);
}

class Particular {
  Particular({
    required this.slno,
    required this.itemname,
    required this.itemId,
    required this.uniqueCode,
    required this.realRate,
    required this.qty,
    required this.rate,
    required this.net,
    required this.particularIgst,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.total,
    required this.unit,
    required this.unitName,
    required this.freeQty,
    required this.funit,
    required this.grossValue,
    required this.cess,
    required this.fValue,
    required this.adcess,
    required this.disc,
    required this.rDisc,
    required this.fcess,
    required this.serialno,
    required this.discPersent,
    required this.unitValue,
    required this.prate,
    required this.rprate,
  });

  String slno;
  String itemname;
  int itemId;
  int uniqueCode;
  double realRate;
  double qty;
  double rate;
  double net;
  double particularIgst;
  double cgst;
  double sgst;
  double igst;
  double total;
  int unit;
  String unitName;
  double freeQty;
  int funit;
  double grossValue;
  double cess;
  int fValue;
  double adcess;
  double disc;
  double rDisc;
  double fcess;
  String serialno;
  double discPersent;
  int unitValue;
  double prate;
  double rprate;

  factory Particular.fromMap(Map<String, dynamic> json) => Particular(
        slno: json["slno"],
        itemname: json["itemname"],
        itemId: json["itemId"],
        uniqueCode: json["UniqueCode"],
        realRate: double.tryParse(json["RealRate"].toString()) ?? 0,
        qty: double.tryParse(json["Qty"].toString()) ?? 0,
        rate: double.tryParse(json["Rate"].toString()) ?? 0,
        net: double.tryParse(json["Net"].toString()) ?? 0,
        particularIgst: double.tryParse(json["igst"].toString()) ?? 0,
        cgst: double.tryParse(json["CGST"].toString()) ?? 0,
        sgst: double.tryParse(json["SGST"].toString()) ?? 0,
        igst: double.tryParse(json["IGST"].toString()) ?? 0,
        total: double.tryParse(json["Total"].toString()) ?? 0,
        unit: json["Unit"],
        unitName: json["unitName"],
        freeQty: double.tryParse(json["freeQty"].toString()) ?? 0,
        funit: json["Funit"],
        grossValue: double.tryParse(json["GrossValue"].toString()) ?? 0,
        cess: double.tryParse(json["cess"].toString()) ?? 0,
        fValue: json["FValue"],
        adcess: double.tryParse(json["adcess"].toString()) ?? 0,
        disc: double.tryParse(json["Disc"].toString()) ?? 0,
        rDisc: double.tryParse(json["RDisc"].toString()) ?? 0,
        fcess: double.tryParse(json["Fcess"].toString()) ?? 0,
        serialno: json["serialno"],
        discPersent: double.tryParse(json["DiscPersent"].toString()) ?? 0,
        unitValue: json["UnitValue"],
        prate: double.tryParse(json["Prate"].toString()) ?? 0,
        rprate: double.tryParse(json["Rprate"].toString()) ?? 0,
      );

  Map<String, dynamic> toMap() => {
        "slno": slno,
        "itemname": itemname,
        "itemId": itemId,
        "UniqueCode": uniqueCode,
        "RealRate": realRate,
        "Qty": qty,
        "Rate": rate,
        "Net": net,
        "igst": particularIgst,
        "CGST": cgst,
        "SGST": sgst,
        "IGST": igst,
        "Total": total,
        "Unit": unit,
        "unitName": unitName,
        "freeQty": freeQty,
        "Funit": funit,
        "GrossValue": grossValue,
        "cess": cess,
        "FValue": fValue,
        "adcess": adcess,
        "Disc": disc,
        "RDisc": rDisc,
        "Fcess": fcess,
        "serialno": serialno,
        "DiscPersent": discPersent,
        "UnitValue": unitValue,
        "Prate": prate,
        "Rprate": rprate,
      };

  static List<Particular> fromJsonList(List list) {
    return list.map((item) => Particular.fromJson(item)).toList();
  }

  factory Particular.fromJson(String str) =>
      Particular.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());

  static List<Particular> fromJsonListDynamic(List<dynamic> list) {
    return list.map((item) => Particular.fromJsonMap(item)).toList();
  }

  factory Particular.fromJsonMap(Map<String, dynamic> map) =>
      Particular.fromMap(map);
}

String MapToJson(Map<String, dynamic> map) {
  String res = "[";

  res += "{";

  for (String k in map.keys) {
    res += '"';
    res += k;
    res += '":"';
    res += map[k].toString();
    res += '",';
  }
  res = res.substring(0, res.length - 1);

  res += "},";
  res = res.substring(0, res.length - 1);

  res += "]";

  return res;
}

var billJson = [
  {
    "taxSale": false,
    "invoiceHead": "ESTIMATE",
    "isQrCodeKSA": false,
    "isEsQrCodeKSA": false,
    "printCopy": 2,
    "printerModel": 2,
    "companyTaxMode": "INDIA",
    "taxNo": "321234567891012",
    "companyInfo": [
      {
        "name": "SHERACC",
        "add1": "Jubily Junction",
        "add2": "Calicut Road, Perinthalmanna",
        "add3": "",
        "add4": "",
        "add5": "",
        "sName": "SHERACC",
        "telephone": "",
        "email": "",
        "mobile": "09605974174",
        "tin": "",
        "pin": "",
        "taxCalculation": "MINUS",
        "sCurrency": "",
        "sDate": "2021-04-01T00:00:00.000Z",
        "eDate": "2025-03-31T00:00:00.000Z",
        "customerCode": "01",
        "runningDate": "2020-01-01T00:00:00.000Z"
      }
    ],
    "information": [
      {
        "DDate": "2022-11-01T00:00:00.000Z",
        "BTime": "1900-01-01T11:49:02.407Z",
        "InvoiceNo": "213",
        "EntryNo": 213,
        "RealEntryNo": 579,
        "Customer": 22010,
        "ToName": "EECCO CAR",
        "Add1": "",
        "Add2": "",
        "Add3": "  ",
        "Add4": "",
        "GrossValue": 91008.5,
        "Discount": 0,
        "NetAmount": 91008.5,
        "cess": 0,
        "Total": 91008.5,
        "loadingCharge": 0,
        "OtherCharges": 0,
        "OtherDiscount": 0,
        "Roundoff": 0.5,
        "GrandTotal": 91009,
        "Narration": "",
        "Profit": 17000.6,
        "CashReceived": 0,
        "CGST": 0,
        "SGST": 0,
        "IGST": 0,
        "ReturnAmount": 0,
        "ReturnNo": 0,
        "BalanceAmount": 91009,
        "Balance": -895038,
        "gstno": ""
      }
    ],
    "particulars": [
      {
        "slno": "1",
        "itemname": "product 1",
        "itemId": 6,
        "UniqueCode": 6,
        "RealRate": 9.5,
        "Qty": 1,
        "Rate": 9.5,
        "Net": 9.5,
        "igst": 18,
        "CGST": 0,
        "SGST": 0,
        "IGST": 0,
        "Total": 9.5,
        "Unit": 0,
        "unitName": "",
        "freeQty": 0,
        "Funit": 0,
        "GrossValue": 9.5,
        "cess": 0,
        "FValue": 0,
        "adcess": 0,
        "Disc": 0,
        "RDisc": 0,
        "Fcess": 0,
        "serialno": "",
        "DiscPersent": 0,
        "UnitValue": 1,
        "Prate": 7.76,
        "Rprate": 7.86
      },
      {
        "slno": "2",
        "itemname": "APPLE X2",
        "itemId": 120,
        "UniqueCode": 381,
        "RealRate": 90999,
        "Qty": 1,
        "Rate": 90999,
        "Net": 90999,
        "igst": 0,
        "CGST": 0,
        "SGST": 0,
        "IGST": 0,
        "Total": 90999,
        "Unit": 0,
        "unitName": "",
        "freeQty": 0,
        "Funit": 0,
        "GrossValue": 90999,
        "cess": 0,
        "FValue": 0,
        "adcess": 0,
        "Disc": 0,
        "RDisc": 0,
        "Fcess": 0,
        "serialno": "",
        "DiscPersent": 0,
        "UnitValue": 1,
        "Prate": 74000,
        "Rprate": 74000
      }
    ],
    "serialNo": [],
    "deliveryNote": [],
    "otherAmount": [
      {
        "LedCode": 11,
        "Symbol": "-",
        "LedName": "DISCOUNT ALLOWED",
        "Amount": 0,
        "Percentage": 0
      },
      {
        "LedCode": 980,
        "Symbol": "+",
        "LedName": "OTHER CHARGES ON SALES",
        "Amount": 0,
        "Percentage": 0
      },
      {
        "LedCode": 981,
        "Symbol": "+",
        "LedName": "LABOUR CHARGES ON SALES",
        "Amount": 0,
        "Percentage": 0
      }
    ],
    "printHeaderInEs": false,
    "balance": "0",
    "message": "have a nice day",
    "qrCode": ""
  }
];
