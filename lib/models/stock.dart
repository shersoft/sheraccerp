// @dart = 2.11
import 'package:flutter/foundation.dart';
import 'package:sheraccerp/models/product.dart';
import 'package:sheraccerp/models/shop.dart';

class Stock {
  final Product product;
  final double quantity;
  final String stockid;
  final String dateadded;
  final Shop shop;

  const Stock(
      {@required this.product,
      @required this.dateadded,
      @required this.shop,
      @required this.quantity,
      this.stockid});

  Map<String, dynamic> get map {
    return {
      "product": product.map,
      "quantity": quantity,
      "dateadded": dateadded,
      "shop": {
        "shop": shop.shop,
        "shopid": shop.shopid,
      },
      "stockid": stockid
    };
  }
}
