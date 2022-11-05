// @dart = 2.11
import 'package:sheraccerp/models/product.dart';
import 'package:sheraccerp/models/shop.dart';

class SaleModel {
  final Product product;
  final String salesid;
  final String dateadded;
  final int timestamp;
  final Shop shop;
  final double quantity;
  final String stockid;

  const SaleModel({
    this.product,
    this.salesid,
    this.stockid,
    this.shop,
    this.dateadded,
    this.timestamp,
    this.quantity,
  });

  Map<String, dynamic> get map {
    return {
      "product": product.map,
      "salesid": salesid,
      "dateadded": dateadded,
      "timestamp": timestamp,
      "shop": {
        "shop": shop.shop,
        "shopid": shop.shopid,
      },
      "quantity": quantity,
      "stockid": stockid
    };
  }
}
