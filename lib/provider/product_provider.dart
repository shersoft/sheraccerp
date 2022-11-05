import 'package:flutter/material.dart';
import 'package:sheraccerp/service/api_dio.dart';

import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  List<Product> productList = [];
  DioService api = DioService();

  ProductProvider() {
    loadProduct();
  }

  loadProduct() async {
    var productList1 = await api.getProductData();
    notifyListeners();
  }
}
