import 'package:flutter/material.dart';
import 'package:sheraccerp/models/stock_product.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/util/dateUtil.dart';

class StockProvider with ChangeNotifier {
  List<StockProduct> listStock = [];
  DioService api = DioService();
  DateTime now = DateTime.now();
  StockProvider() {
    loadStock();
  }

  loadStock() async {
    String formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    listStock =
        (await api.fetchStockProduct(DateUtil.dateDMY2YMD(formattedDate)))
            .cast<StockProduct>();
    notifyListeners();
  }
}
