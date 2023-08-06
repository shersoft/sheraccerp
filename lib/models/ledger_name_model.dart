// @dart = 2.11
import 'dart:convert';

class LedgerModel {
  int id;
  String name;

  LedgerModel({this.id, this.name});

  factory LedgerModel.fromJson(Map<String, dynamic> jsonData) {
    return LedgerModel(id: jsonData['Ledcode'], name: jsonData['LedName']);
  }

  factory LedgerModel.fromJsonL(Map<String, dynamic> jsonData) {
    return LedgerModel(id: jsonData['ledcode'], name: jsonData['LedName']);
  }

  static List<LedgerModel> fromJsonList(List list) {
    return list.map((item) => LedgerModel.fromJson(item)).toList();
  }

  ///this method will prevent the override of toString
  String userAsString() {
    return '#$id $name';
  }

  ///custom comparing function to check if two users are equal
  // bool isEqual(LedgerModel ? model) {
  //   return this.id == model?.id;
  // }

  @override
  String toString() => name;
}

List<LedgerModel> ledgerUserFilterCreation(
    List<LedgerModel> data, String filter) {
  List<LedgerModel> result = [];
  var ledgerModel = data.where(
      (element) => element.name.toLowerCase().contains(filter.toLowerCase()));
  result.addAll(ledgerModel);
  return result;
}

List<LedgersModel> ledgersModelFromJson(String str) => List<LedgersModel>.from(
    json.decode(str).map((x) => LedgersModel.fromJson(x)));

String ledgersModelToJson(List<LedgersModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class LedgersModel {
  LedgersModel({
    this.ledcode,
    this.ledName,
  });

  int ledcode;
  String ledName;

  factory LedgersModel.fromJson(Map<String, dynamic> json) => LedgersModel(
        ledcode: json["Ledcode"],
        ledName: json["LedName"],
      );

  Map<String, dynamic> toJson() => {
        "Ledcode": ledcode,
        "LedName": ledName,
      };
}
