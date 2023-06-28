import 'dart:convert';

class ProductRegisterModel {
  ProductRegisterModel({
    required this.slno,
    required this.itemcode,
    required this.hsncode,
    required this.itemname,
    required this.catagoryId,
    required this.mfrId,
    required this.subcatagoryId,
    required this.unitId,
    required this.rackId,
    required this.packing,
    required this.reorder,
    required this.maxorder,
    required this.taxgroupId,
    required this.tax,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.cessper,
    required this.adcessper,
    required this.mrp,
    required this.retail,
    required this.wsrate,
    required this.sprate,
    required this.branch,
    required this.stockvaluation,
    required this.typeofsupply,
    required this.checkNeg,
    required this.active,
    required this.internationalbarcode,
    required this.serialno,
    required this.bom,
    required this.photo,
    required this.regItemName,
    required this.stockQty,
    required this.taxGroupName,
    required this.pluNo,
    required this.machineItem,
    required this.packingItem,
    required this.speedBill,
    required this.expiry,
    required this.brand,
    required this.pcsBox,
    required this.sqftBox,
    required this.lc,
  });

  int slno;
  String itemcode;
  String hsncode;
  String itemname;
  int catagoryId;
  int mfrId;
  int subcatagoryId;
  int unitId;
  int rackId;
  int packing;
  double reorder;
  double maxorder;
  int taxgroupId;
  double tax;
  double cgst;
  double sgst;
  double igst;
  double cess;
  double cessper;
  double adcessper;
  double mrp;
  double retail;
  double wsrate;
  double sprate;
  double branch;
  String stockvaluation;
  String typeofsupply;
  int checkNeg;
  int active;
  String internationalbarcode;
  int serialno;
  int bom;
  Photo photo;
  String regItemName;
  double stockQty;
  String taxGroupName;
  int pluNo;
  int machineItem;
  int packingItem;
  int speedBill;
  int expiry;
  int brand;
  double pcsBox;
  double sqftBox;
  double lc;

  factory ProductRegisterModel.fromJson(String str) =>
      ProductRegisterModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ProductRegisterModel.fromMap(Map<String, dynamic> json) =>
      ProductRegisterModel(
        slno: json["slno"] ?? 0,
        itemcode: json["itemcode"] ?? '0',
        hsncode: json["hsncode"] ?? '',
        itemname: json["itemname"] ?? '',
        catagoryId: json["Catagory_id"] ?? 0,
        mfrId: json["Mfr_id"] ?? 0,
        subcatagoryId: json["subcatagory_id"] ?? 0,
        unitId: json["unit_id"] ?? 0,
        rackId: json["rack_id"] ?? 0,
        packing: json["packing"] ?? 0,
        reorder: json["reorder"].toDouble() ??
            0, //double.tryParse(json['Qty'].toString())
        maxorder: json["maxorder"].toDouble() ?? 0,
        taxgroupId: json["taxgroup_id"] ?? 0,
        tax: json["tax"].toDouble() ?? 0.0,
        cgst: json["cgst"]?.toDouble() ?? 0.0,
        sgst: json["sgst"]?.toDouble() ?? 0.0,
        igst: json["igst"].toDouble() ?? 0.0,
        cess: json["cess"].toDouble() ?? 0.0,
        cessper: json["cessper"].toDouble() ?? 0.0,
        adcessper: json["adcessper"].toDouble() ?? 0.0,
        mrp: json["mrp"].toDouble() ?? 0.0,
        retail: json["retail"].toDouble() ?? 0.0,
        wsrate: json["wsrate"].toDouble() ?? 0.0,
        sprate: json["sprate"].toDouble() ?? 0.0,
        branch: json["branch"].toDouble() ?? 0.0,
        stockvaluation: json["stockvaluation"] ?? 'AVERAGE VALUE',
        typeofsupply: json["typeofsupply"] ?? 'GOODS',
        checkNeg: json["check_neg"] ?? 0,
        active: json["active"] ?? 0,
        internationalbarcode: json["Internationalbarcode"],
        serialno: json["serialno"] ?? 0,
        bom: json["bom"] ?? 0,
        photo: Photo.fromMap(json["photo"]),
        regItemName: json["RegItemName"] ?? '',
        stockQty: json["StockQty"] != null ? json["StockQty"].toDouble() : 0.0,
        taxGroupName: json["TaxGroup_Name"] ?? '',
        pluNo: json["PluNo"] ?? 0,
        machineItem: json["MachineItem"] ?? 0,
        packingItem: json["PackingItem"] ?? 0,
        speedBill: json["SpeedBill"] ?? 0,
        expiry: json["Expiry"] ?? 0,
        brand: json["Brand"] ?? 0,
        pcsBox: json["PcsBox"].toDouble() ?? 0.0,
        sqftBox: json["SqftBox"].toDouble() ?? 0.0,
        lc: json["LC"].toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        "slno": slno,
        "itemcode": itemcode,
        "hsncode": hsncode,
        "itemname": itemname,
        "Catagory_id": catagoryId,
        "Mfr_id": mfrId,
        "subcatagory_id": subcatagoryId,
        "unit_id": unitId,
        "rack_id": rackId,
        "packing": packing,
        "reorder": reorder,
        "maxorder": maxorder,
        "taxgroup_id": taxgroupId,
        "tax": tax,
        "cgst": cgst,
        "sgst": sgst,
        "igst": igst,
        "cess": cess,
        "cessper": cessper,
        "adcessper": adcessper,
        "mrp": mrp,
        "retail": retail,
        "wsrate": wsrate,
        "sprate": sprate,
        "branch": branch,
        "stockvaluation": stockvaluation,
        "typeofsupply": typeofsupply,
        "check_neg": checkNeg,
        "active": active,
        "Internationalbarcode": internationalbarcode,
        "serialno": serialno,
        "bom": bom,
        "photo": photo.toMap(),
        "RegItemName": regItemName,
        "StockQty": stockQty,
        "TaxGroup_Name": taxGroupName,
        "PluNo": pluNo,
        "MachineItem": machineItem,
        "PackingItem": packingItem,
        "SpeedBill": speedBill,
        "Expiry": expiry,
        "Brand": brand,
        "PcsBox": pcsBox,
        "SqftBox": sqftBox,
        "LC": lc,
      };
}

class Photo {
  Photo({
    required this.type,
    required this.data,
  });

  Type type;
  List<int> data;

  factory Photo.fromJson(String str) => Photo.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Photo.fromMap(Map<String, dynamic> json) => Photo(
        type: typeValues.map[json["type"]]!,
        data: List<int>.from(json["data"].map((x) => x)),
      );

  Map<String, dynamic> toMap() => {
        "type": typeValues.reverse[type],
        "data": List<dynamic>.from(data.map((x) => x)),
      };
}

enum Type { BUFFER }

final typeValues = EnumValues({"Buffer": Type.BUFFER});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
