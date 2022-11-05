// @dart = 2.11
class StockItem {
  int id;
  String name;
  String code;
  double quantity;
  bool hasVariant;

  StockItem({this.id, this.name,this.code, this.quantity, this.hasVariant});

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
        id: json['itemId'],
        name: json['itemName'],
        code: json['itemcode'],
        quantity: double.tryParse(json['qty'].toString()),
        hasVariant: json['hasVariant'] == 1 ? true : false);
  }
}
