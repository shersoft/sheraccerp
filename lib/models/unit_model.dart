// @dart = 2.11
class UnitModel {
  int id;
  int pUnit;
  int sUnit;
  int unit;
  int itemId;
  double conversion;
  String name;
  UnitModel(
      {this.id,
      this.pUnit,
      this.sUnit,
      this.unit,
      this.itemId,
      this.conversion,
      this.name});

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
        id: json['auto'],
        pUnit: json['PUnit'],
        sUnit: json['SUnit'],
        unit: json['Unit'],
        itemId: json['ItemId'],
        conversion: double.tryParse(json['Conversion'].toString()),
        name: json['name']);
  }
}

class UnitDetailModel {
  int id;
  int itemId;
  int unitId;
  int pUnitId;
  int sUnitId;
  String name;
  String rateType;
  double conversion;
  String barcode;
  int gatePass;
  UnitDetailModel(
      {this.id,
      this.rateType,
      this.barcode,
      this.conversion,
      this.name,
      this.itemId,
      this.unitId,
      this.pUnitId,
      this.sUnitId,
      this.gatePass});

  factory UnitDetailModel.fromJson(Map<String, dynamic> json) {
    return UnitDetailModel(
        id: json['Auto'],
        rateType: json['rate'],
        barcode: json['barcode'],
        conversion: json[
            'conversion'], //double.tryParse(json['conversion'].toString()),
        name: json['name'],
        itemId: json['item_id'],
        unitId: json['unit_id'],
        pUnitId: json['Punit_id'],
        sUnitId: json['Sunit_id'],
        gatePass: json['GatePass']);
  }

  Map<String, dynamic> toCartJson() {
    return {
      'id': id,
      'itemId': itemId,
      'unitId': unitId,
      'pUnitId': pUnitId,
      'sUnitId': sUnitId,
      'name': name,
      'rateType': rateType,
      'conversion': conversion,
      'barcode': barcode,
      'gatePass': gatePass,
    };
  }

  static List encodeCartToJson(List<UnitDetailModel> list) {
    List jsonList = [];
    list.map((item) => jsonList.add(item.toCartJson())).toList();
    return jsonList;
  }

  Map toCartMap() {
    var map = {};
    map["id"] = id;
    map['itemId'] = itemId;
    map["unitId"] = unitId;
    map["pUnitId"] = pUnitId;
    map["sUnitId"] = sUnitId;
    map["name"] = name;
    map["rateType"] = rateType;
    map["conversion"] = conversion;
    map["barcode"] = barcode;
    map["gatePass"] = gatePass;
    return map;
  }
}
