import 'dart:convert';

List<LedgersTableModel> ledgersTableModelFromJson(String str) =>
    List<LedgersTableModel>.from(
        json.decode(str).map((x) => LedgersTableModel.fromJson(x)));

String ledgersTableModelToJson(List<LedgersTableModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class LedgersTableModel {
  LedgersTableModel({
    required this.ledCode,
    required this.ledName,
    required this.lhId,
    required this.add1,
    required this.add2,
    required this.add3,
    required this.add4,
    required this.city,
    required this.route,
    required this.state,
    required this.stateCode,
    required this.mobile,
    required this.pan,
    required this.email,
    required this.gstNo,
    required this.cDays,
    required this.cAmount,
    required this.active,
    required this.salesMan,
    required this.bpr,
    required this.rent,
    required this.increment,
    required this.agrDate,
    required this.agreeImage,
    required this.idProof,
    required this.location,
    required this.orderDate,
    required this.deliveryDate,
    required this.cPerson,
    required this.costCenter,
    required this.franchisee,
    required this.salesRate,
    required this.localName,
    required this.subGroup,
    required this.pinNo,
    required this.tcsStatus,
    required this.tcsLimit,
  });

  int ledCode;
  String ledName;
  int lhId;
  String add1;
  String add2;
  String add3;
  String add4;
  int city;
  int route;
  String state;
  String stateCode;
  String mobile;
  String pan;
  String email;
  String gstNo;
  int cDays;
  double cAmount;
  bool active;
  int salesMan;
  int bpr;
  double rent;
  int increment;
  DateTime agrDate;
  AgreeImage agreeImage;
  AgreeImage idProof;
  int location;
  int orderDate;
  int deliveryDate;
  String cPerson;
  int costCenter;
  int franchisee;
  double salesRate;
  String localName;
  int subGroup;
  String pinNo;
  int tcsStatus;
  double tcsLimit;

  factory LedgersTableModel.fromJson(Map<String, dynamic> json) =>
      LedgersTableModel(
        ledCode: json["Ledcode"] ?? 0,
        ledName: json["LedName"] ?? "",
        lhId: json["lh_id"] ?? 0,
        add1: json["add1"] ?? "",
        add2: json["add2"] ?? "",
        add3: json["add3"] ?? "",
        add4: json["add4"] ?? "",
        city: json["city"] ?? 0,
        route: json["route"] ?? 0,
        state: json["state"] ?? "",
        stateCode: json["stateCode"] ?? "",
        mobile: json["Mobile"] ?? "",
        pan: json["pan"] ?? "",
        email: json["Email"] ?? "",
        gstNo: json["gstno"] ?? "",
        cDays: json["CDays"] ?? 0,
        cAmount: json["CAmount"].toDouble() ?? 0.0,
        active: json["Active"] != null
            ? json["Active"] == 1
                ? true
                : false
            : false,
        salesMan: json["SalesMan"] ?? 0,
        bpr: json["bpr"] ?? 0,
        rent: json["Rent"].toDouble() ?? 0.0,
        increment: json["increment"] ?? 0,
        agrDate: DateTime.parse(json["agrdate"]),
        agreeImage: AgreeImage.fromJson(json["AgreeImage"]),
        idProof: AgreeImage.fromJson(json["idproof"]),
        location: json["Location"] ?? 0,
        orderDate: json["OrderDate"] ?? 0,
        deliveryDate: json["DeliveryDate"] ?? 0,
        cPerson: json["CPerson"] ?? "",
        costCenter: json["CostCenter"] ?? 0,
        franchisee: json["Franchisee"] ?? 0,
        salesRate: json["SalesRate"].toDouble() ?? 0.0,
        localName: json["LocalName"] ?? "",
        subGroup: json["SubGroup"] ?? 0,
        pinNo: json["PinNo"] ?? "",
        tcsStatus: json["TCS_Status"] ?? 0,
        tcsLimit: json["TCSLimit"].toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        "Ledcode": ledCode,
        "LedName": ledName,
        "lh_id": lhId,
        "add1": add1,
        "add2": add2,
        "add3": add3,
        "add4": add4,
        "city": city,
        "route": route,
        "state": state,
        "stateCode": stateCode,
        "Mobile": mobile,
        "pan": pan,
        "Email": email,
        "gstno": gstNo,
        "CDays": cDays,
        "CAmount": cAmount,
        "Active": active,
        "SalesMan": salesMan,
        "bpr": bpr,
        "Rent": rent,
        "increment": increment,
        "agrdate": agrDate.toIso8601String(),
        "AgreeImage": agreeImage.toJson(),
        "idproof": idProof.toJson(),
        "Location": location,
        "OrderDate": orderDate,
        "DeliveryDate": deliveryDate,
        "CPerson": cPerson,
        "CostCenter": costCenter,
        "Franchisee": franchisee,
        "SalesRate": salesRate,
        "LocalName": localName,
        "SubGroup": subGroup,
        "PinNo": pinNo,
        "TCS_Status": tcsStatus,
        "TCSLimit": tcsLimit,
      };
}

class AgreeImage {
  AgreeImage({
    required this.type,
    required this.data,
  });

  String type;
  List<int> data;

  factory AgreeImage.fromJson(Map<String, dynamic> json) => AgreeImage(
        type: json["type"],
        data: List<int>.from(json["data"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "data": List<dynamic>.from(data.map((x) => x)),
      };
}
