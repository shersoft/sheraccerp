import 'dart:convert';
import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// class eInvoiceModel
//     {
class AddlDocDtl {
  String docs;
  String info;
  String url;
  AddlDocDtl({
    required this.docs,
    required this.info,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'docs': docs,
      'info': info,
      'url': url,
    };
  }

  factory AddlDocDtl.fromMap(Map<String, dynamic> map) {
    return AddlDocDtl(
      docs: map['docs'] ?? '',
      info: map['info'] ?? '',
      url: map['url'] ?? '',
    );
  }
}

class AttribDtl {
  String Nm;
  String Val;
  AttribDtl({
    required this.Nm,
    required this.Val,
  });

  Map<String, dynamic> toMap() {
    return {
      'Nm': Nm,
      'Val': Val,
    };
  }

  factory AttribDtl.fromMap(Map<String, dynamic> map) {
    return AttribDtl(
      Nm: map['Nm'] ?? '',
      Val: map['Val'] ?? '',
    );
  }
}

class AuthClass {
  AuthData data;
  Headers header;
  String status_cd;
  String status_desc;
  AuthClass({
    required this.data,
    required this.header,
    required this.status_cd,
    required this.status_desc,
  });

  Map<String, dynamic> toMap() {
    return {
      'data': data.toMap(),
      'header': header,
      'status_cd': status_cd,
      'status_desc': status_desc,
    };
  }

  factory AuthClass.fromMap(Map<String, dynamic> map) {
    return AuthClass(
      data: AuthData.fromMap(map['data']),
      header: Headers.fromMap(map['header']),
      status_cd: map['status_cd'] ?? '',
      status_desc: map['status_desc'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthClass.fromJson(String source) =>
      AuthClass.fromMap(json.decode(source));
}

class AuthData {
  String AuthToken;
  String ClientId;
  String Sek;
  String TokenExpiry;
  String UserName;
  AuthData({
    required this.AuthToken,
    required this.ClientId,
    required this.Sek,
    required this.TokenExpiry,
    required this.UserName,
  });

  Map<String, dynamic> toMap() {
    return {
      'AuthToken': AuthToken,
      'ClientId': ClientId,
      'Sek': Sek,
      'TokenExpiry': TokenExpiry,
      'UserName': UserName,
    };
  }

  factory AuthData.fromMap(Map<String, dynamic> map) {
    return AuthData(
      AuthToken: map['AuthToken'] ?? '',
      ClientId: map['ClientId'] ?? '',
      Sek: map['Sek'] ?? '',
      TokenExpiry: map['TokenExpiry'] ?? '',
      UserName: map['UserName'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthData.fromJson(String source) =>
      AuthData.fromMap(json.decode(source));
}

class GSTNoData {
  Object AddrBnm;
  String AddrBno;
  String AddrFlno;
  String AddrLoc;
  int AddrPncd;
  String AddrSt;
  String BlkStatus;
  Object DtDReg;
  String DtReg;
  String Gstin;
  String LegalName;
  int StateCode;
  String Status;
  String TradeName;
  String TxpType;
  GSTNoData({
    required this.AddrBnm,
    required this.AddrBno,
    required this.AddrFlno,
    required this.AddrLoc,
    required this.AddrPncd,
    required this.AddrSt,
    required this.BlkStatus,
    required this.DtDReg,
    required this.DtReg,
    required this.Gstin,
    required this.LegalName,
    required this.StateCode,
    required this.Status,
    required this.TradeName,
    required this.TxpType,
  });

  Map<String, dynamic> toMap() {
    return {
      'AddrBnm': AddrBnm,
      'AddrBno': AddrBno,
      'AddrFlno': AddrFlno,
      'AddrLoc': AddrLoc,
      'AddrPncd': AddrPncd,
      'AddrSt': AddrSt,
      'BlkStatus': BlkStatus,
      'DtDReg': DtDReg,
      'DtReg': DtReg,
      'Gstin': Gstin,
      'LegalName': LegalName,
      'StateCode': StateCode,
      'Status': Status,
      'TradeName': TradeName,
      'TxpType': TxpType,
    };
  }

  factory GSTNoData.fromMap(Map<String, dynamic> map) {
    return GSTNoData(
      AddrBnm: map['AddrBnm'],
      AddrBno: map['AddrBno'] ?? '',
      AddrFlno: map['AddrFlno'] ?? '',
      AddrLoc: map['AddrLoc'] ?? '',
      AddrPncd: map['AddrPncd']?.toInt() ?? 0,
      AddrSt: map['AddrSt'] ?? '',
      BlkStatus: map['BlkStatus'] ?? '',
      DtDReg: map['DtDReg'],
      DtReg: map['DtReg'] ?? '',
      Gstin: map['Gstin'] ?? '',
      LegalName: map['LegalName'] ?? '',
      StateCode: map['StateCode']?.toInt() ?? 0,
      Status: map['Status'] ?? '',
      TradeName: map['TradeName'] ?? '',
      TxpType: map['TxpType'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory GSTNoData.fromJson(String source) =>
      GSTNoData.fromMap(json.decode(source));
}

class GstNoResult {
  GSTNoData data;
  String status_cd;
  String status_desc;
  GstNoResult({
    required this.data,
    required this.status_cd,
    required this.status_desc,
  });

  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'status_cd': status_cd,
      'status_desc': status_desc,
    };
  }

  factory GstNoResult.fromMap(Map<String, dynamic> map) {
    return GstNoResult(
      data: GSTNoData.fromMap(map['data']),
      status_cd: map['status_cd'] ?? '',
      status_desc: map['status_desc'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory GstNoResult.fromJson(String source) =>
      GstNoResult.fromMap(json.decode(source));
}

class BchDtls {
  String Expdt;
  String Nm;
  String wrDt;
  BchDtls({
    required this.Expdt,
    required this.Nm,
    required this.wrDt,
  });

  Map<String, dynamic> toMap() {
    return {
      'Expdt': Expdt,
      'Nm': Nm,
      'wrDt': wrDt,
    };
  }

  factory BchDtls.fromMap(Map<String, dynamic> map) {
    return BchDtls(
      Expdt: map['Expdt'] ?? '',
      Nm: map['Nm'] ?? '',
      wrDt: map['wrDt'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory BchDtls.fromJson(String source) =>
      BchDtls.fromMap(json.decode(source));
}

class BuyerDtls {
  String Addr1;
  String Addr2;
  String Em;
  String Gstin;
  String LglNm;
  String Loc;
  String Ph;
  int Pin;
  String Pos;
  String Stcd;
  String TrdNm;
  BuyerDtls({
    required this.Addr1,
    required this.Addr2,
    required this.Em,
    required this.Gstin,
    required this.LglNm,
    required this.Loc,
    required this.Ph,
    required this.Pin,
    required this.Pos,
    required this.Stcd,
    required this.TrdNm,
  });

  Map<String, dynamic> toMap() {
    return {
      'Addr1': Addr1,
      'Addr2': Addr2,
      'Em': Em,
      'Gstin': Gstin,
      'LglNm': LglNm,
      'Loc': Loc,
      'Ph': Ph,
      'Pin': Pin,
      'Pos': Pos,
      'Stcd': Stcd,
      'TrdNm': TrdNm,
    };
  }

  factory BuyerDtls.fromMap(Map<String, dynamic> map) {
    return BuyerDtls(
      Addr1: map['Addr1'] ?? '',
      Addr2: map['Addr2'] ?? '',
      Em: map['Em'] ?? '',
      Gstin: map['Gstin'] ?? '',
      LglNm: map['LglNm'] ?? '',
      Loc: map['Loc'] ?? '',
      Ph: map['Ph'] ?? '',
      Pin: map['Pin']?.toInt() ?? 0,
      Pos: map['Pos'] ?? '',
      Stcd: map['Stcd'] ?? '',
      TrdNm: map['TrdNm'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory BuyerDtls.fromJson(String source) =>
      BuyerDtls.fromMap(json.decode(source));
}

class CancelIrn {
  String CnlRem;
  String CnlRsn;
  String Irn;
  CancelIrn({required this.CnlRem, required this.CnlRsn, required this.Irn});

  Map<String, dynamic> toMap() {
    return {
      'CnlRem': CnlRem,
      'CnlRsn': CnlRsn,
      'Irn': Irn,
    };
  }

  factory CancelIrn.fromMap(Map<String, dynamic> map) {
    return CancelIrn(
      CnlRem: map['CnlRem'] ?? '',
      CnlRsn: map['CnlRsn'] ?? '',
      Irn: map['Irn'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory CancelIrn.fromJson(String source) =>
      CancelIrn.fromMap(json.decode(source));
}

class CancelIRnData {
  String CancelDate;
  String Irn;
  CancelIRnData({
    required this.CancelDate,
    required this.Irn,
  });

  Map<String, dynamic> toMap() {
    return {
      'CancelDate': CancelDate,
      'Irn': Irn,
    };
  }

  factory CancelIRnData.fromMap(Map<String, dynamic> map) {
    return CancelIRnData(
      CancelDate: map['CancelDate'] ?? '',
      Irn: map['Irn'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory CancelIRnData.fromJson(String source) =>
      CancelIRnData.fromMap(json.decode(source));
}

class CancelIRnresult {
  CancelIrn data;
  String status_cd;
  String status_desc;
  CancelIRnresult({
    required this.data,
    required this.status_cd,
    required this.status_desc,
  });

  Map<String, dynamic> toMap() {
    return {
      'data': data.toMap(),
      'status_cd': status_cd,
      'status_desc': status_desc,
    };
  }

  factory CancelIRnresult.fromMap(Map<String, dynamic> map) {
    return CancelIRnresult(
      data: CancelIrn.fromMap(map['data']),
      status_cd: map['status_cd'] ?? '',
      status_desc: map['status_desc'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory CancelIRnresult.fromJson(String source) =>
      CancelIRnresult.fromMap(json.decode(source));
}

class ContrDtl {
  String Contrrefr;
  String Extrefr;
  String PoRefDt;
  String Porefr;
  String Projrefr;
  String RecAdvDt;
  String RecAdvRefr;
  String Tendrefr;
  ContrDtl({
    required this.Contrrefr,
    required this.Extrefr,
    required this.PoRefDt,
    required this.Porefr,
    required this.Projrefr,
    required this.RecAdvDt,
    required this.RecAdvRefr,
    required this.Tendrefr,
  });

  Map<String, dynamic> toMap() {
    return {
      'Contrrefr': Contrrefr,
      'Extrefr': Extrefr,
      'PoRefDt': PoRefDt,
      'Porefr': Porefr,
      'Projrefr': Projrefr,
      'RecAdvDt': RecAdvDt,
      'RecAdvRefr': RecAdvRefr,
      'Tendrefr': Tendrefr,
    };
  }

  factory ContrDtl.fromMap(Map<String, dynamic> map) {
    return ContrDtl(
      Contrrefr: map['Contrrefr'] ?? '',
      Extrefr: map['Extrefr'] ?? '',
      PoRefDt: map['PoRefDt'] ?? '',
      Porefr: map['Porefr'] ?? '',
      Projrefr: map['Projrefr'] ?? '',
      RecAdvDt: map['RecAdvDt'] ?? '',
      RecAdvRefr: map['RecAdvRefr'] ?? '',
      Tendrefr: map['Tendrefr'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ContrDtl.fromJson(String source) =>
      ContrDtl.fromMap(json.decode(source));
}

class DispDtls {
  String Addr1;

  String Addr2;

  String Loc;

  String Nm;

  int Pin;

  String Stcd;
  DispDtls({
    required this.Addr1,
    required this.Addr2,
    required this.Loc,
    required this.Nm,
    required this.Pin,
    required this.Stcd,
  });

  Map<String, dynamic> toMap() {
    return {
      'Addr1': Addr1,
      'Addr2': Addr2,
      'Loc': Loc,
      'Nm': Nm,
      'Pin': Pin,
      'Stcd': Stcd,
    };
  }

  factory DispDtls.fromMap(Map<String, dynamic> map) {
    return DispDtls(
      Addr1: map['Addr1'] ?? '',
      Addr2: map['Addr2'] ?? '',
      Loc: map['Loc'] ?? '',
      Nm: map['Nm'] ?? '',
      Pin: map['Pin']?.toInt() ?? 0,
      Stcd: map['Stcd'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DispDtls.fromJson(String source) =>
      DispDtls.fromMap(json.decode(source));
}

class DocDtls {
  String Dt;
  String No;
  String Typ;
  DocDtls({
    required this.Dt,
    required this.No,
    required this.Typ,
  });

  Map<String, dynamic> toMap() {
    return {
      'Dt': Dt,
      'No': No,
      'Typ': Typ,
    };
  }

  factory DocDtls.fromMap(Map<String, dynamic> map) {
    return DocDtls(
      Dt: map['Dt'] ?? '',
      No: map['No'] ?? '',
      Typ: map['Typ'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DocDtls.fromJson(String source) =>
      DocDtls.fromMap(json.decode(source));
}

class DocPerdDtls {
  String InvEndDt;
  String InvStDt;
  DocPerdDtls({
    required this.InvEndDt,
    required this.InvStDt,
  });

  Map<String, dynamic> toMap() {
    return {
      'InvEndDt': InvEndDt,
      'InvStDt': InvStDt,
    };
  }

  factory DocPerdDtls.fromMap(Map<String, dynamic> map) {
    return DocPerdDtls(
      InvEndDt: map['InvEndDt'] ?? '',
      InvStDt: map['InvStDt'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DocPerdDtls.fromJson(String source) =>
      DocPerdDtls.fromMap(json.decode(source));
}

class EInvoice {
  List<AddlDocDtl> AddlDocDtls;
  BuyerDtls buyerDtls;
  DispDtls dispDtls;
  DocDtls docDtls;
  EwbDtls ewbDtls;
  ExpDtls expDtls;
  List<ItemListEinvoice> ItemList;
  PayDtls payDtls;
  RefDtls refDtls;
  SellerDtls sellerDtls;
  ShipDtls shipDtls;
  TranDtls tranDtls;
  ValDtls valDtls;
  String Version;
  EInvoice({
    required this.AddlDocDtls,
    required this.buyerDtls,
    required this.dispDtls,
    required this.docDtls,
    required this.ewbDtls,
    required this.expDtls,
    required this.ItemList,
    required this.payDtls,
    required this.refDtls,
    required this.sellerDtls,
    required this.shipDtls,
    required this.tranDtls,
    required this.valDtls,
    required this.Version,
  });

  Map<String, dynamic> toMap() {
    return {
      'AddlDocDtls': AddlDocDtls.map((x) => x.toMap()).toList(),
      'BuyerDtls': buyerDtls.toMap(),
      'DispDtls': dispDtls.toMap(),
      'DocDtls': docDtls.toMap(),
      'EwbDtls': ewbDtls.toMap(),
      'ExpDtls': expDtls.toMap(),
      'ItemList': ItemList.map((x) => x.toMap()).toList(),
      'PayDtls': payDtls.toMap(),
      'RefDtls': refDtls.toMap(),
      'SellerDtls': sellerDtls.toMap(),
      'ShipDtls': shipDtls.toMap(),
      'TranDtls': tranDtls.toMap(),
      'ValDtls': valDtls.toMap(),
      'Version': Version,
    };
  }

  factory EInvoice.fromMap(Map<String, dynamic> map) {
    return EInvoice(
      AddlDocDtls: List<AddlDocDtl>.from(
          map['AddlDocDtls']?.map((x) => AddlDocDtl.fromMap(x))),
      buyerDtls: BuyerDtls.fromMap(map['BuyerDtls']),
      dispDtls: DispDtls.fromMap(map['DispDtls']),
      docDtls: DocDtls.fromMap(map['DocDtls']),
      ewbDtls: EwbDtls.fromMap(map['EwbDtls']),
      expDtls: ExpDtls.fromMap(map['ExpDtls']),
      ItemList: List<ItemListEinvoice>.from(
          map['ItemList']?.map((x) => ItemListEinvoice.fromMap(x))),
      payDtls: PayDtls.fromMap(map['PayDtls']),
      refDtls: RefDtls.fromMap(map['RefDtls']),
      sellerDtls: SellerDtls.fromMap(map['SellerDtls']),
      shipDtls: ShipDtls.fromMap(map['ShipDtls']),
      tranDtls: TranDtls.fromMap(map['TranDtls']),
      valDtls: ValDtls.fromMap(map['ValDtls']),
      Version: map['Version'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory EInvoice.fromJson(String source) =>
      EInvoice.fromMap(json.decode(source));
}

class EwbDtls {
  int Distance;

  String TransdocDt;

  String Transdocno;

  String Transid;

  String TransMode;

  String Transname;

  String Vehno;

  String Vehtype;
  EwbDtls({
    required this.Distance,
    required this.TransdocDt,
    required this.Transdocno,
    required this.Transid,
    required this.TransMode,
    required this.Transname,
    required this.Vehno,
    required this.Vehtype,
  });

  Map<String, dynamic> toMap() {
    return {
      'Distance': Distance,
      'TransdocDt': TransdocDt,
      'Transdocno': Transdocno,
      'Transid': Transid,
      'TransMode': TransMode,
      'Transname': Transname,
      'Vehno': Vehno,
      'Vehtype': Vehtype,
    };
  }

  factory EwbDtls.fromMap(Map<String, dynamic> map) {
    return EwbDtls(
      Distance: map['Distance']?.toInt() ?? 0,
      TransdocDt: map['TransdocDt'] ?? '',
      Transdocno: map['Transdocno'] ?? '',
      Transid: map['Transid'] ?? '',
      TransMode: map['TransMode'] ?? '',
      Transname: map['Transname'] ?? '',
      Vehno: map['Vehno'] ?? '',
      Vehtype: map['Vehtype'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory EwbDtls.fromJson(String source) =>
      EwbDtls.fromMap(json.decode(source));
}

class ExpDtls {
  String CntCode;

  String ForCur;

  String Port;

  String RefClm;

  String ShipBDt;

  String ShipBNo;
  ExpDtls({
    required this.CntCode,
    required this.ForCur,
    required this.Port,
    required this.RefClm,
    required this.ShipBDt,
    required this.ShipBNo,
  });

  Map<String, dynamic> toMap() {
    return {
      'CntCode': CntCode,
      'ForCur': ForCur,
      'Port': Port,
      'RefClm': RefClm,
      'ShipBDt': ShipBDt,
      'ShipBNo': ShipBNo,
    };
  }

  factory ExpDtls.fromMap(Map<String, dynamic> map) {
    return ExpDtls(
      CntCode: map['CntCode'] ?? '',
      ForCur: map['ForCur'] ?? '',
      Port: map['Port'] ?? '',
      RefClm: map['RefClm'] ?? '',
      ShipBDt: map['ShipBDt'] ?? '',
      ShipBNo: map['ShipBNo'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ExpDtls.fromJson(String source) =>
      ExpDtls.fromMap(json.decode(source));
}

class IrnData {
  String AckDt;

  Long AckNo;

  Object EwbDt;

  Object EwbNo;

  Object EwbValidTill;

  String Irn;

  Object Remarks;

  String SignedInvoice;

  String SignedQRCode;

  String Status;
  IrnData({
    required this.AckDt,
    required this.AckNo,
    required this.EwbDt,
    required this.EwbNo,
    required this.EwbValidTill,
    required this.Irn,
    required this.Remarks,
    required this.SignedInvoice,
    required this.SignedQRCode,
    required this.Status,
  });

  Map<String, dynamic> toMap() {
    return {
      'AckDt': AckDt,
      'AckNo': AckNo,
      'EwbDt': EwbDt,
      'EwbNo': EwbNo,
      'EwbValidTill': EwbValidTill,
      'Irn': Irn,
      'Remarks': Remarks,
      'SignedInvoice': SignedInvoice,
      'SignedQRCode': SignedQRCode,
      'Status': Status,
    };
  }

  factory IrnData.fromMap(Map<String, dynamic> map) {
    return IrnData(
      AckDt: map['AckDt'] ?? '',
      AckNo: map['AckNo'],
      EwbDt: map['EwbDt'],
      EwbNo: map['EwbNo'],
      EwbValidTill: map['EwbValidTill'],
      Irn: map['Irn'] ?? '',
      Remarks: map['Remarks'],
      SignedInvoice: map['SignedInvoice'] ?? '',
      SignedQRCode: map['SignedQRCode'] ?? '',
      Status: map['Status'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory IrnData.fromJson(String source) =>
      IrnData.fromMap(json.decode(source));
}

class IRnResult {
  IrnData data;

  String status_cd;

  String status_desc;
  IRnResult({
    required this.data,
    required this.status_cd,
    required this.status_desc,
  });

  Map<String, dynamic> toMap() {
    return {
      'data': data.toMap(),
      'status_cd': status_cd,
      'status_desc': status_desc,
    };
  }

  factory IRnResult.fromMap(Map<String, dynamic> map) {
    return IRnResult(
      data: IrnData.fromMap(map['data']),
      status_cd: map['status_cd'] ?? '',
      status_desc: map['status_desc'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory IRnResult.fromJson(String source) =>
      IRnResult.fromMap(json.decode(source));
}

class ItemListEinvoice {
  double AssAmt;
  List<AttribDtl> AttribDtls;
  String Barcde;
  BchDtls bchDtls;
  double CesAmt;
  int CesNonAdvlAmt;
  int CesRt;
  int CgstAmt;
  int Discount;
  int FreeQty;
  int GstRt;
  String HsnCd;
  double IgstAmt;
  String IsServc;
  String OrdLineRef;
  String OrgCntry;
  int OthChrg;
  String PrdDesc;
  String PrdSlNo;
  int PreTaxVal;
  double Qty;
  int SgstAmt;
  String SlNo;
  double StateCesAmt;
  int StateCesNonAdvlAmt;
  int StateCesRt;
  double TotAmt;
  double TotItemVal;
  String Unit;
  double UnitPrice;
  ItemListEinvoice({
    required this.AssAmt,
    required this.AttribDtls,
    required this.Barcde,
    required this.bchDtls,
    required this.CesAmt,
    required this.CesNonAdvlAmt,
    required this.CesRt,
    required this.CgstAmt,
    required this.Discount,
    required this.FreeQty,
    required this.GstRt,
    required this.HsnCd,
    required this.IgstAmt,
    required this.IsServc,
    required this.OrdLineRef,
    required this.OrgCntry,
    required this.OthChrg,
    required this.PrdDesc,
    required this.PrdSlNo,
    required this.PreTaxVal,
    required this.Qty,
    required this.SgstAmt,
    required this.SlNo,
    required this.StateCesAmt,
    required this.StateCesNonAdvlAmt,
    required this.StateCesRt,
    required this.TotAmt,
    required this.TotItemVal,
    required this.Unit,
    required this.UnitPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'AssAmt': AssAmt,
      'AttribDtls': AttribDtls.map((x) => x.toMap()).toList(),
      'Barcde': Barcde,
      'BchDtls': bchDtls.toMap(),
      'CesAmt': CesAmt,
      'CesNonAdvlAmt': CesNonAdvlAmt,
      'CesRt': CesRt,
      'CgstAmt': CgstAmt,
      'Discount': Discount,
      'FreeQty': FreeQty,
      'GstRt': GstRt,
      'HsnCd': HsnCd,
      'IgstAmt': IgstAmt,
      'IsServc': IsServc,
      'OrdLineRef': OrdLineRef,
      'OrgCntry': OrgCntry,
      'OthChrg': OthChrg,
      'PrdDesc': PrdDesc,
      'PrdSlNo': PrdSlNo,
      'PreTaxVal': PreTaxVal,
      'Qty': Qty,
      'SgstAmt': SgstAmt,
      'SlNo': SlNo,
      'StateCesAmt': StateCesAmt,
      'StateCesNonAdvlAmt': StateCesNonAdvlAmt,
      'StateCesRt': StateCesRt,
      'TotAmt': TotAmt,
      'TotItemVal': TotItemVal,
      'Unit': Unit,
      'UnitPrice': UnitPrice,
    };
  }

  factory ItemListEinvoice.fromMap(Map<String, dynamic> map) {
    return ItemListEinvoice(
      AssAmt: map['AssAmt']?.toDouble() ?? 0.0,
      AttribDtls: List<AttribDtl>.from(
          map['AttribDtls']?.map((x) => AttribDtl.fromMap(x))),
      Barcde: map['Barcde'] ?? '',
      bchDtls: BchDtls.fromMap(map['BchDtls']),
      CesAmt: map['CesAmt']?.toDouble() ?? 0.0,
      CesNonAdvlAmt: map['CesNonAdvlAmt']?.toInt() ?? 0,
      CesRt: map['CesRt']?.toInt() ?? 0,
      CgstAmt: map['CgstAmt']?.toInt() ?? 0,
      Discount: map['Discount']?.toInt() ?? 0,
      FreeQty: map['FreeQty']?.toInt() ?? 0,
      GstRt: map['GstRt']?.toInt() ?? 0,
      HsnCd: map['HsnCd'] ?? '',
      IgstAmt: map['IgstAmt']?.toDouble() ?? 0.0,
      IsServc: map['IsServc'] ?? '',
      OrdLineRef: map['OrdLineRef'] ?? '',
      OrgCntry: map['OrgCntry'] ?? '',
      OthChrg: map['OthChrg']?.toInt() ?? 0,
      PrdDesc: map['PrdDesc'] ?? '',
      PrdSlNo: map['PrdSlNo'] ?? '',
      PreTaxVal: map['PreTaxVal']?.toInt() ?? 0,
      Qty: map['Qty']?.toDouble() ?? 0.0,
      SgstAmt: map['SgstAmt']?.toInt() ?? 0,
      SlNo: map['SlNo'] ?? '',
      StateCesAmt: map['StateCesAmt']?.toDouble() ?? 0.0,
      StateCesNonAdvlAmt: map['StateCesNonAdvlAmt']?.toInt() ?? 0,
      StateCesRt: map['StateCesRt']?.toInt() ?? 0,
      TotAmt: map['TotAmt']?.toDouble() ?? 0.0,
      TotItemVal: map['TotItemVal']?.toDouble() ?? 0.0,
      Unit: map['Unit'] ?? '',
      UnitPrice: map['UnitPrice']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ItemListEinvoice.fromJson(String source) =>
      ItemListEinvoice.fromMap(json.decode(source));
}

class PayDtls {
  String Accdet;

  int Crday;

  String Crtrn;

  String Dirdr;

  String Fininsbr;

  String Mode;

  String Nm;

  int Paidamt;

  String Payinstr;

  int Paymtdue;

  String Payterm;
  PayDtls({
    required this.Accdet,
    required this.Crday,
    required this.Crtrn,
    required this.Dirdr,
    required this.Fininsbr,
    required this.Mode,
    required this.Nm,
    required this.Paidamt,
    required this.Payinstr,
    required this.Paymtdue,
    required this.Payterm,
  });

  Map<String, dynamic> toMap() {
    return {
      'Accdet': Accdet,
      'Crday': Crday,
      'Crtrn': Crtrn,
      'Dirdr': Dirdr,
      'Fininsbr': Fininsbr,
      'Mode': Mode,
      'Nm': Nm,
      'Paidamt': Paidamt,
      'Payinstr': Payinstr,
      'Paymtdue': Paymtdue,
      'Payterm': Payterm,
    };
  }

  factory PayDtls.fromMap(Map<String, dynamic> map) {
    return PayDtls(
      Accdet: map['Accdet'] ?? '',
      Crday: map['Crday']?.toInt() ?? 0,
      Crtrn: map['Crtrn'] ?? '',
      Dirdr: map['Dirdr'] ?? '',
      Fininsbr: map['Fininsbr'] ?? '',
      Mode: map['Mode'] ?? '',
      Nm: map['Nm'] ?? '',
      Paidamt: map['Paidamt']?.toInt() ?? 0,
      Payinstr: map['Payinstr'] ?? '',
      Paymtdue: map['Paymtdue']?.toInt() ?? 0,
      Payterm: map['Payterm'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PayDtls.fromJson(String source) =>
      PayDtls.fromMap(json.decode(source));
}

class PrecDocDtl {
  String InvDt;

  String InvNo;

  String OthRefNo;
  PrecDocDtl({
    required this.InvDt,
    required this.InvNo,
    required this.OthRefNo,
  });

  Map<String, dynamic> toMap() {
    return {
      'InvDt': InvDt,
      'InvNo': InvNo,
      'OthRefNo': OthRefNo,
    };
  }

  factory PrecDocDtl.fromMap(Map<String, dynamic> map) {
    return PrecDocDtl(
      InvDt: map['InvDt'] ?? '',
      InvNo: map['InvNo'] ?? '',
      OthRefNo: map['OthRefNo'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PrecDocDtl.fromJson(String source) =>
      PrecDocDtl.fromMap(json.decode(source));
}

class RefDtls {
  List<ContrDtl> ContrDtls;
  DocPerdDtls docPerdDtls;
  String InvRm;
  RefDtls({
    required this.ContrDtls,
    required this.docPerdDtls,
    required this.InvRm,
  });

  Map<String, dynamic> toMap() {
    return {
      'ContrDtls': ContrDtls.map((x) => x.toMap()).toList(),
      'docPerdDtls': docPerdDtls.toMap(),
      'InvRm': InvRm,
    };
  }

  factory RefDtls.fromMap(Map<String, dynamic> map) {
    return RefDtls(
      ContrDtls: List<ContrDtl>.from(
          map['ContrDtls']?.map((x) => ContrDtl.fromMap(x))),
      docPerdDtls: DocPerdDtls.fromMap(map['docPerdDtls']),
      InvRm: map['InvRm'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory RefDtls.fromJson(String source) =>
      RefDtls.fromMap(json.decode(source));
}

class SellerDtls {
  String Addr1;
  String Addr2;
  String Em;
  String Gstin;
  String LglNm;
  String Loc;
  String Ph;
  int Pin;
  String Stcd;
  String TrdNm;
  SellerDtls({
    required this.Addr1,
    required this.Addr2,
    required this.Em,
    required this.Gstin,
    required this.LglNm,
    required this.Loc,
    required this.Ph,
    required this.Pin,
    required this.Stcd,
    required this.TrdNm,
  });

  Map<String, dynamic> toMap() {
    return {
      'Addr1': Addr1,
      'Addr2': Addr2,
      'Em': Em,
      'Gstin': Gstin,
      'LglNm': LglNm,
      'Loc': Loc,
      'Ph': Ph,
      'Pin': Pin,
      'Stcd': Stcd,
      'TrdNm': TrdNm,
    };
  }

  factory SellerDtls.fromMap(Map<String, dynamic> map) {
    return SellerDtls(
      Addr1: map['Addr1'] ?? '',
      Addr2: map['Addr2'] ?? '',
      Em: map['Em'] ?? '',
      Gstin: map['Gstin'] ?? '',
      LglNm: map['LglNm'] ?? '',
      Loc: map['Loc'] ?? '',
      Ph: map['Ph'] ?? '',
      Pin: map['Pin']?.toInt() ?? 0,
      Stcd: map['Stcd'] ?? '',
      TrdNm: map['TrdNm'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory SellerDtls.fromJson(String source) =>
      SellerDtls.fromMap(json.decode(source));
}

class ShipDtls {
  String Addr1;

  String Addr2;

  String Gstin;

  String LglNm;

  String Loc;

  int Pin;

  String Stcd;

  String TrdNm;
  ShipDtls({
    required this.Addr1,
    required this.Addr2,
    required this.Gstin,
    required this.LglNm,
    required this.Loc,
    required this.Pin,
    required this.Stcd,
    required this.TrdNm,
  });

  Map<String, dynamic> toMap() {
    return {
      'Addr1': Addr1,
      'Addr2': Addr2,
      'Gstin': Gstin,
      'LglNm': LglNm,
      'Loc': Loc,
      'Pin': Pin,
      'Stcd': Stcd,
      'TrdNm': TrdNm,
    };
  }

  factory ShipDtls.fromMap(Map<String, dynamic> map) {
    return ShipDtls(
      Addr1: map['Addr1'] ?? '',
      Addr2: map['Addr2'] ?? '',
      Gstin: map['Gstin'] ?? '',
      LglNm: map['LglNm'] ?? '',
      Loc: map['Loc'] ?? '',
      Pin: map['Pin']?.toInt() ?? 0,
      Stcd: map['Stcd'] ?? '',
      TrdNm: map['TrdNm'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ShipDtls.fromJson(String source) =>
      ShipDtls.fromMap(json.decode(source));
}

class TranDtls {
  Object EcmGstin;
  String IgstOnIntra;
  String RegRev;
  String SupTyp;
  String TaxSch;
  TranDtls({
    required this.EcmGstin,
    required this.IgstOnIntra,
    required this.RegRev,
    required this.SupTyp,
    required this.TaxSch,
  });

  Map<String, dynamic> toMap() {
    return {
      'EcmGstin': EcmGstin,
      'IgstOnIntra': IgstOnIntra,
      'RegRev': RegRev,
      'SupTyp': SupTyp,
      'TaxSch': TaxSch,
    };
  }

  factory TranDtls.fromMap(Map<String, dynamic> map) {
    return TranDtls(
      EcmGstin: map['EcmGstin'],
      IgstOnIntra: map['IgstOnIntra'] ?? '',
      RegRev: map['RegRev'] ?? '',
      SupTyp: map['SupTyp'] ?? '',
      TaxSch: map['TaxSch'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory TranDtls.fromJson(String source) =>
      TranDtls.fromMap(json.decode(source));
}

class ValDtls {
  double AssVal;
  double CesVal;
  int CgstVal;
  int Discount;
  double IgstVal;
  int OthChrg;
  double RndOffAmt;
  int SgstVal;
  double StCesVal;
  int TotInvVal;
  double TotInvValFc;
  ValDtls({
    required this.AssVal,
    required this.CesVal,
    required this.CgstVal,
    required this.Discount,
    required this.IgstVal,
    required this.OthChrg,
    required this.RndOffAmt,
    required this.SgstVal,
    required this.StCesVal,
    required this.TotInvVal,
    required this.TotInvValFc,
  });

  Map<String, dynamic> toMap() {
    return {
      'AssVal': AssVal,
      'CesVal': CesVal,
      'CgstVal': CgstVal,
      'Discount': Discount,
      'IgstVal': IgstVal,
      'OthChrg': OthChrg,
      'RndOffAmt': RndOffAmt,
      'SgstVal': SgstVal,
      'StCesVal': StCesVal,
      'TotInvVal': TotInvVal,
      'TotInvValFc': TotInvValFc,
    };
  }

  factory ValDtls.fromMap(Map<String, dynamic> map) {
    return ValDtls(
      AssVal: map['AssVal']?.toDouble() ?? 0.0,
      CesVal: map['CesVal']?.toDouble() ?? 0.0,
      CgstVal: map['CgstVal']?.toInt() ?? 0,
      Discount: map['Discount']?.toInt() ?? 0,
      IgstVal: map['IgstVal']?.toDouble() ?? 0.0,
      OthChrg: map['OthChrg']?.toInt() ?? 0,
      RndOffAmt: map['RndOffAmt']?.toDouble() ?? 0.0,
      SgstVal: map['SgstVal']?.toInt() ?? 0,
      StCesVal: map['StCesVal']?.toDouble() ?? 0.0,
      TotInvVal: map['TotInvVal']?.toInt() ?? 0,
      TotInvValFc: map['TotInvValFc']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ValDtls.fromJson(String source) =>
      ValDtls.fromMap(json.decode(source));
}

/**Master gst */
// Exmaple Json
//GENERATE IRN (POST)

const generateIrnSchemaPostExample = {
  "Version": "1.1",
  "TranDtls": {
    "TaxSch": "GST",
    "SupTyp": "B2B",
    "RegRev": "N",
    "EcmGstin": null,
    "IgstOnIntra": "N"
  },
  "DocDtls": {"Typ": "INV", "No": "MAHI/10", "Dt": "08/08/2020"},
  "SellerDtls": {
    "Gstin": "29AABCT1332L000",
    "LglNm": "ABC company pvt ltd",
    "TrdNm": "NIC Industries",
    "Addr1": "5th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "GANDHINAGAR",
    "Pin": 560001,
    "Stcd": "29",
    "Ph": "9000000000",
    "Em": "abc@gmail.com"
  },
  "BuyerDtls": {
    "Gstin": "29AWGPV7107B1Z1",
    "LglNm": "XYZ company pvt ltd",
    "TrdNm": "XYZ Industries",
    "Pos": "37",
    "Addr1": "7th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "GANDHINAGAR",
    "Pin": 560004,
    "Stcd": "29",
    "Ph": "9000000000",
    "Em": "abc@gmail.com"
  },
  "DispDtls": {
    "Nm": "ABC company pvt ltd",
    "Addr1": "7th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "Banagalore",
    "Pin": 518360,
    "Stcd": "37"
  },
  "ShipDtls": {
    "Gstin": "29AWGPV7107B1Z1",
    "LglNm": "CBE company pvt ltd",
    "TrdNm": "kuvempu layout",
    "Addr1": "7th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "Banagalore",
    "Pin": 518360,
    "Stcd": "37"
  },
  "ItemList": [
    {
      "SlNo": "1",
      "IsServc": "N",
      "PrdDesc": "Rice",
      "HsnCd": "1001",
      "Barcde": "123456",
      "BchDtls": {"Nm": "123456", "Expdt": "01/08/2020", "wrDt": "01/09/2020"},
      "Qty": 100.345,
      "FreeQty": 10,
      "Unit": "NOS",
      "UnitPrice": 99.545,
      "TotAmt": 9988.84,
      "Discount": 10,
      "PreTaxVal": 1,
      "AssAmt": 9978.84,
      "GstRt": 12,
      "SgstAmt": 0,
      "IgstAmt": 1197.46,
      "CgstAmt": 0,
      "CesRt": 5,
      "CesAmt": 498.94,
      "CesNonAdvlAmt": 10,
      "StateCesRt": 12,
      "StateCesAmt": 1197.46,
      "StateCesNonAdvlAmt": 5,
      "OthChrg": 10,
      "TotItemVal": 12897.7,
      "OrdLineRef": "3256",
      "OrgCntry": "AG",
      "PrdSlNo": "12345",
      "AttribDtls": [
        {"Nm": "Rice", "Val": "10000"}
      ]
    }
  ],
  "ValDtls": {
    "AssVal": 9978.84,
    "CgstVal": 0,
    "SgstVal": 0,
    "IgstVal": 1197.46,
    "CesVal": 508.94,
    "StCesVal": 1202.46,
    "Discount": 10,
    "OthChrg": 20,
    "RndOffAmt": 0.3,
    "TotInvVal": 12908,
    "TotInvValFc": 12897.7
  },
  "PayDtls": {
    "Nm": "ABCDE",
    "Accdet": "5697389713210",
    "Mode": "Cash",
    "Fininsbr": "SBIN11000",
    "Payterm": "100",
    "Payinstr": "Gift",
    "Crtrn": "test",
    "Dirdr": "test",
    "Crday": 100,
    "Paidamt": 10000,
    "Paymtdue": 5000
  },
  "RefDtls": {
    "InvRm": "TEST",
    "DocPerdDtls": {"InvStDt": "01/08/2020", "InvEndDt": "01/09/2020"},
    "PrecDocDtls": [
      {"InvNo": "DOC/002", "InvDt": "01/08/2020", "OthRefNo": "123456"}
    ],
    "ContrDtls": [
      {
        "RecAdvRefr": "DOC/002",
        "RecAdvDt": "01/08/2020",
        "Tendrefr": "Abc001",
        "Contrrefr": "Co123",
        "Extrefr": "Yo456",
        "Projrefr": "Doc-456",
        "Porefr": "Doc-789",
        "PoRefDt": "01/08/2020"
      }
    ]
  },
  "AddlDocDtls": [
    {
      "Url": "https://einv-apisandbox.nic.in",
      "Docs": "Test Doc",
      "Info": "Document Test"
    }
  ],
  "ExpDtls": {
    "ShipBNo": "A-248",
    "ShipBDt": "01/08/2020",
    "Port": "INABG1",
    "RefClm": "N",
    "ForCur": "AED",
    "CntCode": "AE"
  },
  "EwbDtls": {
    "Transid": "12AWGPV7107B1Z1",
    "Transname": "XYZ EXPORTS",
    "Distance": 100,
    "Transdocno": "DOC01",
    "TransdocDt": "01/08/2020",
    "Vehno": "ka123456",
    "Vehtype": "R",
    "TransMode": "1"
  }
};
//CANCEL IRN (POST)
const cancelIRNSchemaPostExample = {
  "Irn": "a5c12dca80e743321740b001fd70953e8738d109865d28ba4013750f2046f229",
  "CnlRsn": "1",
  "CnlRem": "Wrong entry"
};

//GENERATE Ewaybill (POST)
const generateEwaybillExample = {
  "Irn": "47d7ba1814b6ca6123c780ad289b0a24e30c1baed59a7417d29a54e7b00a6bdf",
  "Distance": 100,
  "TransMode": "1",
  "TransId": "12AWGPV7107B1Z1",
  "TransName": "trans name",
  "TransDocDt": "01/08/2020",
  "TransDocNo": "TRAN/DOC/11",
  "VehNo": "KA12ER1234",
  "VehType": "R",
  "ExpShipDtls": {
    "Addr1": "7th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "Banagalore",
    "Pin": 562160,
    "Stcd": "29"
  },
  "DispDtls": {
    "Nm": "ABC company pvt ltd",
    "Addr1": "7th block, kuvempu layout",
    "Addr2": "kuvempu layout",
    "Loc": "Banagalore",
    "Pin": 562160,
    "Stcd": "29"
  }
};
