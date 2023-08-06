// @dart = 2.11
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/order.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';

mixin CartScopeModel on Model {
  List<CartItem> cart = [];
  double totalGrossValue = 0;
  double totalDiscount = 0;
  double totalNet = 0;
  double totalCess = 0;
  double totalIgST = 0;
  double totalCgST = 0;
  double totalSgST = 0;
  double totalFCess = 0;
  double totalAdCess = 0;
  double totalRDiscount = 0;
  double taxTotalCartValue = 0;
  double totalCartValue = 0;
  double totalProfit = 0;
  Order _order;
  int get totalItem => cart.length;
  bool isLoading = false, isZeroRate = false;
  Order get order {
    return _order;
  }

  void addProduct(product) {
    int index = cart.indexWhere((i) => i.id == product.id);
    // print(index);
    if (index != -1) {
      updateProduct(product, product.quantity + 1);
    } else {
      cart.add(product);
      calculateTotal();
      notifyListeners();
    }
  }

  void removeProduct(product) {
    int index = cart.indexWhere((i) => i.id == product.id);
    cart[index].quantity = 1;
    cart.removeWhere((item) => item.id == product.id);
    calculateTotal();
    notifyListeners();
  }

  void updateProduct(product, qty) {
    int index = cart.indexWhere((i) => i.id == product.id);
    cart[index].quantity = qty;
    cart[index].tax = CommonService.getRound(
        2,
        (((cart[index].quantity * cart[index].rRate) * cart[index].taxP) /
            100));
    if (cart[index].quantity == 0) removeProduct(product);

    calculateTotal();
    notifyListeners();
  }

  void editProduct(String title, String value, int id) {
    int index = cart.indexWhere((i) => i.id == id);
    if (title == 'Edit Rate') {
      cart[index].rate = double.tryParse(value);
      // if (cart[index].rRate == 0) {
      //   cart[index].rRate = double.tryParse(value);
      //   isZeroRate = true;
      // } else if (isZeroRate) {
      //   cart[index].rRate = double.tryParse(value);
      // }
      cart[index].rRate = taxMethod == 'MINUS'
          ? isKFC
              ? CommonService.getRound(4,
                  (100 * cart[index].rate) / (100 + cart[index].taxP + kfcPer))
              : CommonService.getRound(
                  4, (100 * cart[index].rate) / (100 + cart[index].taxP))
          : cart[index].rate;
    } else if (title == 'Edit Quantity') {
      // int index = cart.indexWhere((i) => i.id == id);
      cart[index].quantity = double.tryParse(value);
    }
    cart[index].gross =
        CommonService.getRound(2, (cart[index].rRate * cart[index].quantity));
    cart[index].net =
        CommonService.getRound(2, (cart[index].gross - cart[index].rDiscount));
    if (cart[index].taxP > 0) {
      cart[index].tax = CommonService.getRound(
          2, ((cart[index].net * cart[index].taxP) / 100));
      if (companyTaxMode == 'INDIA') {
        cart[index].fCess = isKFC
            ? CommonService.getRound(2, ((cart[index].net * kfcPer) / 100))
            : 0;
        double csPer = cart[index].taxP / 2;
        double csGST =
            CommonService.getRound(2, ((cart[index].net * csPer) / 100));
        cart[index].sGST = csGST;
        cart[index].cGST = csGST;
      } else if (companyTaxMode == 'GULF') {
        cart[index].cGST = 0;
        cart[index].sGST = 0;
        cart[index].iGST = CommonService.getRound(
            2, ((cart[index].net * cart[index].taxP) / 100));
      } else {
        cart[index].cGST = 0;
        cart[index].sGST = 0;
        cart[index].fCess = 0;
      }
    }
    cart[index].total = CommonService.getRound(
        2,
        (cart[index].net +
            cart[index].cGST +
            cart[index].sGST +
            cart[index].iGST +
            cart[index].cess +
            cart[index].fCess +
            cart[index].adCess));
    cart[index].profitPer = CommonService.getRound(
        2, cart[index].total - cart[index].rPRate * cart[index].quantity);
    // }

    calculateTotal();
    notifyListeners();
  }

  void clearCart() {
    for (var f in cart) {
      f.quantity = 1;
    }
    cart = [];
    notifyListeners();
  }

  void calculateTotal() {
    totalGrossValue = 0;
    totalDiscount = 0;
    totalRDiscount = 0;
    totalNet = 0;
    totalCess = 0;
    totalIgST = 0;
    totalCgST = 0;
    totalSgST = 0;
    totalFCess = 0;
    totalAdCess = 0;
    taxTotalCartValue = 0;
    totalCartValue = 0;
    totalProfit = 0;

    for (var f in cart) {
      totalGrossValue += f.gross;
      totalDiscount += f.discount;
      totalRDiscount += f.rDiscount;
      totalNet += f.net;
      totalCess += f.cess;
      totalIgST += f.iGST;
      totalCgST += f.cGST;
      totalSgST += f.sGST;
      totalFCess += f.fCess;
      totalAdCess += f.adCess;
      taxTotalCartValue += f.tax;
      totalCartValue += f.total;
      totalProfit += f.profitPer;
    }
    // totalCartValue =
    //     ComSettings.appSettings('bool', 'key-round-off-amount', false)
    //         ? totalCartValue
    //         : totalCartValue.roundToDouble();
  }

  Future<bool> saveSaleDepriciated(Order order) async {
    var dio = Dio();
    bool ret = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cid = 'cSharp';
    cid = (prefs.getString('DBName') ?? "");
    isLoading = true;
    notifyListeners();
    // List jsonList = //CustomerModel.encodeCartToJson(order.customerModel); +
    //     CartItem.encodeCartToJson(order.lineItems);
    var jsonLedger = CustomerModel.encodeCustomerToJson(order.customerModel);
    var jsonItem = CartItem.encodeCartToJson(order.lineItems);
    var items = json.encode(jsonItem);
    var ledger = json.encode(jsonLedger);
    var otherAmount = json.encode(order.otherAmountData);
    var saleFormId = salesTypeData.id;
    var taxType = salesTypeData.tax ? 'T' : 'NT';
    var salesRateTypeId = rateType.isNotEmpty ? rateType : '1';
    var saleAccountId = saleAccount.isNotEmpty ? saleAccount : '1';
    var checkKFC = isKFC ? '1' : '0';
    double grandTotal = double.tryParse(order.grandTotal) > 0
        ? (CommonService.getRound(2, double.tryParse(order.grandTotal)) +
            CommonService.getRound(2, double.tryParse(order.loadingCharge)) +
            CommonService.getRound(2, double.tryParse(order.otherCharges)) +
            CommonService.getRound(2, double.tryParse(order.adCess)) +
            CommonService.getRound(2, double.tryParse(order.labourCharge)) -
            CommonService.getRound(2, double.tryParse(order.otherDiscount)))
        : 0;
    double roundOff = 0, different = 0;
    if (!ComSettings.appSettings('bool', 'key-round-off-amount', false)) {
      different = grandTotal - grandTotal.round();
      if (different < 0.5) {
        roundOff = CommonService.getRound(2, (different * -1));
      } else {
        roundOff = CommonService.getRound(1, (1 - different));
      }
    }
    var data = '[' +
        json.encode({
          'saleFormId': saleFormId,
          'taxType': taxType,
          'date': order.dated,
          'sType': salesRateTypeId,
          'saleAccountId': saleAccountId,
          'grossValue': order.grossValue,
          'discPercent': order.discountPer,
          'discount': order.discount,
          'rDiscount': order.rDiscount,
          'net': order.net,
          'cess': order.cess,
          'total': order.total,
          'profit': order.profit,
          'cGST': order.cGST,
          'sGST': order.sGST,
          'iGST': order.iGST,
          'addCess': order.adCess,
          'fCess': order.fCess,
          'otherDiscount': order.otherDiscount,
          'otherCharges': order.otherCharges,
          'loadingCharge': order.loadingCharge,
          'balanceAmount': ComSettings.appSettings(
                  'bool', 'key-round-off-amount', false)
              ? double.parse(order.balanceAmount).toStringAsFixed(2)
              : double.parse(order.balanceAmount).roundToDouble().toString(),
          'labourCharge': order.labourCharge,
          'grandTotal':
              ComSettings.appSettings('bool', 'key-round-off-amount', false)
                  ? grandTotal.toStringAsFixed(2)
                  : grandTotal.roundToDouble().toString(),
          'creditPeriod': order.creditPeriod,
          'takeUser': order.takeUser,
          'narration': order.narration,
          'cashReceived': order.cashReceived,
          'cashAC': order.cashAC,
          'check_kFC': checkKFC,
          'salesMan': order.salesMan,
          'location': order.location,
          'roundOff': roundOff,
          'billType': order.billType
        }) +
        ']';
    try {
      final body = {
        'information': ledger,
        'data': data,
        'particular': items,
        'otherAmount': otherAmount
      };
      final response = await dio.post(
          prefs.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'xxxxxsale/add/$cid',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        //RealEntryNo,EntryNo,InvoiceNo,Type
        var jsonResponse = response.data; //json.decode(response.data);
        dataDynamic = jsonResponse;
        isLoading = false;
        notifyListeners();
        ret = true;
      } else {
        isLoading = false;
        ret = false;
        notifyListeners();
        throw Exception('Unexpected error occurred!');
      }
    } catch (ex) {
      ex.toString();
      ret = false;
    }
    return ret;
  }
}
