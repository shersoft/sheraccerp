// @dart = 2.11
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/models/ledger_parent.dart';
import 'package:sheraccerp/models/option_rate_type.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/models/stock_item.dart';
import 'package:sheraccerp/models/stock_product.dart';
import 'package:sheraccerp/models/tax_group_model.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/provider/app_provider.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/widget/simple_piediagram_pay_rec.dart';

class DioService {
  var dio = Dio(BaseOptions(maxRedirects: 5));
  DioService();

  Future<Map<dynamic, dynamic>> fetchDashTotalData(
      formattedDate, branch) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp',
        sType = 'Total Summary',
        sDate = formattedDate,
        eDate = formattedDate;
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      var response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'dashboard/Total/$dataBase/${Uri.encodeComponent(sType).toString()}/$sDate/$eDate/$branch');

      if (response.statusCode == 200) {
        Map<dynamic, dynamic> responseBodyOfTotal;
        List<dynamic> outList = response.data;
        responseBodyOfTotal = outList[0];
        return responseBodyOfTotal;
      } else {
        debugPrint('Failed to load internet');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<dynamic> fetchDashSalesSummary(formattedDate, fromDate, branch) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp',
        sType = 'Sales Summary',
        sDate = fromDate,
        eDate = formattedDate;
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      var response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'dashboard/SummaryList/$dataBase/${Uri.encodeComponent(sType).toString()}/$sDate/$eDate/$branch');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('Failed to load internet');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<dynamic> fetchDashPurchaseSummary(
      formattedDate, fromDate, branch) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp',
        sType = 'Purchase Summary',
        sDate = fromDate,
        eDate = formattedDate;
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      var response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'dashboard/SummaryList/$dataBase/${Uri.encodeComponent(sType).toString()}/$sDate/$eDate/$branch');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('Failed to load internet');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<dynamic> fetchDashStatement(formattedDate, branch) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp',
        sType = 'Daily Statement',
        sDate = formattedDate,
        eDate = formattedDate;
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      var response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'dashboard/dayStatement/$dataBase/${Uri.encodeComponent(sType).toString()}/$sDate/$eDate/$branch');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('Failed to load internet');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<dynamic> fetchDashDailyStatement(formattedDate, head, branch) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', sDate = formattedDate, eDate = formattedDate;
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      var response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'dashboard/dayStatement/$dataBase/${Uri.encodeComponent(head).toString()}/$sDate/$eDate/$branch');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('Failed to load internet');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<bool> addEvent(data) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      // if (dataBase == 'C1_DEEMATRADING22' || dataBase == 'Csharp') {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'comapny/event/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 201) {
        if (response.statusMessage == "Created") {
          ret = true;
        } else {
          ret = false;
        }
      } else {
        ret = false;
        debugPrint('Unexpected error Occurred!');
      }
      // }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> spLedgerAdd(data) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/add/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 201) {
        if (response.data.toString() == "1") {
          ret = true;
        } else {
          ret = false;
        }
      } else {
        ret = false;
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> spLedgerEdit(data) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/edit/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 201) {
        if (response.data.toString() == "1") {
          ret = true;
        } else {
          ret = false;
        }
      } else {
        ret = false;
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> spLedgerDelete(id) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.delete(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/delete/$dataBase/$id');

      if (response.statusCode == 200) {
        if (response.data.toString() == "1") {
          ret = true;
        } else {
          ret = false;
        }
      } else {
        ret = false;
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> addProduct(var body) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");

    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/add/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        if (jsonResponse['returnValue'] > 0) {
          ret = true;
        } else {
          ret = false;
        }
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> addOpeningStock(var body) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'purchase/OpeningStockAdd/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        //RealEntryNo,EntryNo,InvoiceNo,Type
        var jsonResponse = response.data; //json.decode(response.data);
        if (jsonResponse['returnValue'] > 0) {
          ret = true;
        } else {
          ret = false;
        }
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> stockTransfer(var body) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/stockTransfer/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        //RealEntryNo,EntryNo,InvoiceNo,Type
        var jsonResponse = response.data; //json.decode(response.data);
        if (jsonResponse['returnValue'] > 0) {
          ret = true;
        } else {
          ret = false;
        }
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> addPurchase(var body) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'purchase/purchaseAdd/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        //RealEntryNo,EntryNo,InvoiceNo,Type
        var jsonResponse = response.data; //json.decode(response.data);
        if (jsonResponse['returnValue'] > 0) {
          ret = true;
        } else {
          ret = false;
        }
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> newSale(var body) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/salesAdd/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] == 1 ? true : false;
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> addDamage(var body) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'damage/Add/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] == 1 ? true : false;
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> addSaleOld(var body) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/add/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        //RealEntryNo,EntryNo,InvoiceNo,Type
        var jsonResponse = response.data; //json.decode(response.data);
        dataDynamic = jsonResponse;
        ret = true;
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<int> addSale(var body) async {
    int ret = 0;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/add/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        ret = response.data;
      } else {
        ret = 0;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<int> editSale(var body) async {
    int ret = 0;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/edit/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        ret = response.data;
      } else {
        ret = 0;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<int> spSale(var body) async {
    int ret = 0;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/sale/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        ret = response.data['returnValue'];
      } else {
        ret = 0;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> addOtherAmount(body) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/addOtherAmount/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        ret = response.data > 0 ? true : false;
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> checkBill(data) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/checkPrint/$dataBase',
          queryParameters: {
            'statement': data['statement'].toString(),
            'entryNo': data['entryNo'].toString(),
            'sType': data['sType'].toString(),
            'grandTotal': data['grandTotal'].toString()
          });

      if (response.statusCode == 200) {
        ret = response.data['returnValue'] > 0 ? true : false;
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<dynamic> spSaleFind(var body) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/sale/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        return jsonResponse['recordsets'];
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<bool> deleteSale(entryNo, type, form) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.delete(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'sale/delete/$dataBase/$entryNo/$type/$form',
      );
      if (response.statusCode == 200) {
        ret = response.data > 0 ? true : false;
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<int> addVoucher(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Voucher/add/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 201) {
        if (response.data['returnValue'] > 0) {
          return response.data['returnValue'];
        } else {
          return 0;
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<int> addInvoiceVoucher(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'InvoiceVoucher/add/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 201) {
        if (response.data['returnValue'] > 0) {
          return response.data['returnValue'];
        } else {
          return 0;
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<int> editInvoiceVoucher(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'InvoiceVoucher/edit/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 201) {
        if (response.data['returnValue'] > 0) {
          return response.data['returnValue'];
        } else {
          return 0;
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<int> deleteInvoiceVoucher(id, type) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.delete(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'InvoiceVoucher/delete/$dataBase/$id/$type',
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 201) {
        if (response.data['returnValue'] > 0) {
          return response.data['returnValue'];
        } else {
          return 0;
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<dynamic>> fetchSalesTypeList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', statement = 'SelectSalesType';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sales_list/$dataBase/$statement');
      List<dynamic> _items = [];
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var json in jsonResponse) {
          _items.add({'id': json['iD'], 'value': true, 'name': json['type']});
        }
        return _items;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<dynamic>> getSalesReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sales_report/$dataBase',
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<dynamic>> getSalesListReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'listPageReport/$dataBase',
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<dynamic>> getSalesReturnReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'SalesReturnReport/$dataBase',
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<dynamic>> getProductReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'ProductList/$dataBase',
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<dynamic>> getMonthlySalesReport(branchId) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'salesReportMonthly/$dataBase/$branchId');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<dynamic>> getPurchaseReport(
      branchId,
      statement,
      sDate,
      eDate,
      supplierId,
      project,
      itemId,
      mfr,
      category,
      subcategory,
      salesman,
      taxGroup) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'purchaseReport/$dataBase/$branchId/$statement/$sDate/$eDate/$supplierId/$project/$itemId/$mfr/$category/$subcategory/$salesman/$taxGroup');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<dynamic>> getMonthlyPurchaseReport(branchId) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'purchaseReportMonthly/$dataBase/$branchId');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<dynamic>> getStockReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock_report/$dataBase',
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['recordset'];
        return data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<dynamic>> fetchBankVouchers() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'inventory_report/BankVouchers/$dataBase');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<dynamic>> fetchEventDetails(date) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'inventory_report/EventDetails/$dataBase/$date');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<int> getProductId() async {
    int ret = 0;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/getProductId/$dataBase');

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] + 1;
      } else {
        ret = 0;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> getUserLogin(name, password) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'users/find/$dataBase/${Uri.encodeComponent(name).toString()}');

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        if (jsonResponse.isNotEmpty) {
          userNameC = jsonResponse[0]['Name'];
          userIdC = jsonResponse[0]['UserID'];
          if (jsonResponse[0]['Name'].toUpperCase() == name &&
              jsonResponse[0]['Password'].toUpperCase() == password) {
            ret = true;
          }
        } else {
          ret = false;
        }
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<Map<String, dynamic>> getProductData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/getProductData/$dataBase');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return {};
    }
  }

  Future<List<dynamic>> getSalesListDataS(statement) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    var filter = ' ';
    try {
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            Uri.encodeComponent(statement).toString() +
            '/$dataBase/$filter',
      );
      final data = response.data;
      if (data != null) {
        List<dynamic> list;
        list = data.map((item) => (item['name'])).toList();
        return list; //.map((s) => s as String).toList();
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return [];
  }

  Future<List<DataJson>> getSupplierListData(filter) async {
    // /Ledger/getSupplierList/:dataBase/:name
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    filter = filter.toString().isEmpty ? ' ' : filter;
    List<DataJson> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getSupplierList/$dataBase/$filter');
      final data = response.data;
      if (data != null && data.isNotEmpty) {
        _items = DataJson.fromJsonList(data);
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<DataJson>> getSalesListData(filter, statement) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    filter = filter.toString().isEmpty ? ' ' : filter;
    List<DataJson> _items = [];
    try {
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            statement +
            '/$dataBase/$filter',
        queryParameters: {"filter": filter},
      );
      final data = response.data;
      if (data != null) {
        _items = DataJson.fromJsonList(data);
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<TaxGroupModel>> getTaxGroupData(filter, statement) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    filter = filter.toString().isEmpty ? ' ' : filter;
    List<TaxGroupModel> _items = [];
    try {
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            Uri.encodeComponent(statement).toString() +
            '/$dataBase/$filter',
        queryParameters: {"filter": filter},
      );
      final data = response.data;
      if (data != null) {
        _items = TaxGroupModel.fromJsonList(data);
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<DataJson>> getHSNListData(filter, statement) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    filter = filter.toString().isEmpty ? ' ' : filter;
    List<DataJson> _items = [];
    try {
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            statement +
            '/$dataBase/$filter',
        queryParameters: {"filter": filter},
      );
      final data = response.data;
      if (data != null) {
        _items = DataJson.fromJsonList(data);
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<LedgerModel>> getLedgerAll() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerModel> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getAll/$dataBase');
      if (response.statusCode == 200) {
        for (var data in response.data) {
          _items.add(LedgerModel.fromJson(data));
        }
        return _items;
      } else {
        debugPrint('Failed to load data');
        return _items;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return _items;
    }
  }

  Future<List<LedgerParent>> getLedgerGroupAll() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerParent> _items = [];
    try {
      // getMainHead
      //LedCode'], value: element['LedName
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getParentList/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var group in jsonResponse) {
          _items.add(LedgerParent.fromJson(
              group)); //{'Ledcode': group['lh_id'], 'LedName': group['lh_name']});
        }
        return _items;
      } else {
        debugPrint('Failed to load data');
        return _items;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return _items;
    }
  }

  Future<List<dynamic>> getLedger(String name) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'Ledger/getLedger/$dataBase/${Uri.encodeComponent(name).toString()}');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        _items = jsonResponse;
        return _items;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> getPaginationList(String statement, int page,
      String location, String type, String date, String salesMan) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'listPage/$dataBase/$statement/$page/$location/$type/$date/$salesMan');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        _items = jsonResponse;
        return _items;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> getDamageReport(String statementType, String sDate,
      String eDate, String condition) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'damage_report/$dataBase/$statementType/$sDate/$eDate/$condition');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        _items = jsonResponse;
        return _items;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> getLedgerByType(String type) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'Ledger/getLedgerByType/$dataBase/${Uri.encodeComponent(type).toString()}');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        _items = jsonResponse;
        return _items;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> getPurchaseAC() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'purchase/getPurchaseAC/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        _items = jsonResponse;
        return _items;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> getStockAC() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getStockAC/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        _items = jsonResponse;
        return _items;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<LedgerParent>> getLedgerParent() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerParent> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getParentList/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data as List;
        for (var ledger in jsonResponse) {
          _items.add(LedgerParent.fromJson(ledger));
        }

        return _items;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<LedgerModel>> getCashBankAc() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerModel> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getCashAndBank/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var ledger in jsonResponse) {
          _items.add(LedgerModel.fromJsonL(ledger));
        }
      } else {
        debugPrint('Failed to load data');
      }
      return _items;
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<LedgerModel>> getLedgerData(filter) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerModel> _items = [];
    try {
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'Ledger/getAll/$dataBase',
        queryParameters: {"filter": filter},
      );
      final data = response.data;
      if (data != null) {
        _items = LedgerModel.fromJsonList(data);
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<LedgerModel>> getLedgerDataByParent(
      filter, int groupId, int areaId, int routeId, int salesman) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerModel> _items = [];
    try {
      Response response;
      if (groupId > 1 || areaId > 1 || routeId > 1) {
        var _groupId = groupId > 1 ? groupId : 0,
            _areaId = areaId > 1 ? areaId : 0,
            _routeId = routeId > 1 ? routeId : 0,
            _salesman = 0;
        response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getLedgerByParent/$dataBase/$_groupId/$_areaId/$_routeId/$_salesman',
          queryParameters: {"filter": filter},
        );
      } else {
        response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getAll/$dataBase',
          queryParameters: {"filter": filter},
        );
      }
      final data = response.data;
      if (data != null) {
        _items = LedgerModel.fromJsonList(data);
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<SalesType>> getSalesTypeList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<SalesType> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/getSalesTypeList/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var ledger in jsonResponse) {
          _items.add(SalesType.fromJson(ledger));
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<OptionRateType>> getRateTypeList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<OptionRateType> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/getRateTypeList/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var ledger in jsonResponse) {
          _items.add(OptionRateType.fromJson(ledger));
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<LedgerModel>> getCustomerNameList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerModel> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getCustomerCashList/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var ledger in jsonResponse) {
          _items.add(LedgerModel.fromJson(ledger));
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<LedgerModel>> getCustomerNameListByParent(
      int groupId, int areaId, int routeId, int salesman) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerModel> _items = [];
    try {
      Response response;
      if (groupId > 1 || areaId > 1 || routeId > 1) {
        var _groupId = groupId > 1 ? groupId : 0,
            _areaId = areaId > 1 ? areaId : 0,
            _routeId = routeId > 1 ? routeId : 0,
            _salesman = 0;
        response = await dio.get(pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'Ledger/getLedgerByParent/$dataBase/$_groupId/$_areaId/$_routeId/$_salesman');
      } else {
        response = await dio.get(pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'Ledger/getCustomerCashList/$dataBase');
      }
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var ledger in jsonResponse) {
          _items.add(LedgerModel.fromJson(ledger));
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<LedgerModel>> getCustomerNameListLike(
      int groupId, int areaId, int routeId, int salesman, String like) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerModel> _items = [];
    try {
      Response response;
      if (groupId > 1 || areaId > 1 || routeId > 1) {
        var _groupId = groupId > 1 ? groupId : 0,
            _areaId = areaId > 1 ? areaId : 0,
            _routeId = routeId > 1 ? routeId : 0,
            _salesman = 0;
        response = await dio.get(pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'Ledger/getLedgerByParentLike/$dataBase/$_groupId/$_areaId/$_routeId/$_salesman/$like');
      } else {
        response = await dio.get(pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'Ledger/getLedgerListLike/$dataBase/$like');
      }
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var ledger in jsonResponse) {
          _items.add(LedgerModel.fromJson(ledger));
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<LedgerModel>> getSupplierNameList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerModel> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getCustomerCashList/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var ledger in jsonResponse) {
          _items.add(LedgerModel.fromJson(ledger));
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> getSalesAccountList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getSalesAccountList/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        // for (var ledger in jsonResponse) {
        //   _items.add(LedgerModel.fromJson(ledger));
        // }
        _items = jsonResponse;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<CustomerModel> getCustomerDetail(int id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    CustomerModel _item = CustomerModel();
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getDetail/$dataBase/$id');
      if (response.statusCode == 200) {
        List<dynamic> _data = response.data;
        _item = CustomerModel.fromJson(_data[0]);
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _item;
  }

  Future<CustomerModel> getCustomerDetailStock(int id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    CustomerModel _item = CustomerModel();
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getDetailWithStock/$dataBase/$id');
      if (response.statusCode == 200) {
        List<dynamic> _data = response.data;
        _item = CustomerModel.fromJson(_data[0]);
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _item;
  }

  Future<List<dynamic>> getSalesManList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getSalesManList/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var json in jsonResponse) {
          // _items.add({'id': json['iD'], 'value': true, 'name': json['type']});
          _items.add({
            'id': json['Auto'],
            'name': json['name'],
            'empCode': json['emp_code'],
            'employeeSection': json['EmployeeSection'],
            'salary': json['Salary'],
            'active': json['Active']
          });
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<Map<String, dynamic>>> getLedgerList(sType) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<Map<String, dynamic>> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getLedgerByType/' +
              dataBase +
              '/' +
              Uri.encodeComponent(sType).toString());
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        _items = List.from(data);
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<Map<String, dynamic>>> fetchProfitAndLossAccount(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<Map<String, dynamic>> _items = [];
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'accounts_report/ProfitAndLoss/' +
              dataBase,
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        if (response.data.toString().isNotEmpty) {
          List<dynamic> data = response.data;
          _items = List.from(data);
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<Map<String, dynamic>>> fetchClosingReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<Map<String, dynamic>> _items = [];
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'inventory_report/ClosingReport/' +
              dataBase,
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        _items = List.from(data);
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<Map<String, dynamic>>> getEmployeeList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<Map<String, dynamic>> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'EmployeeReport/getEmployeeList/' +
              dataBase,
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        if (response.data.toString().isNotEmpty) {
          List<dynamic> data = response.data;
          _items = List.from(data);
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<Map<String, dynamic>>> spEmployee(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<Map<String, dynamic>> _items = [];
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'EmployeeReport/getEmployeeReport/' +
              dataBase,
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        if (response.data.toString().isNotEmpty) {
          List<dynamic> data = response.data;
          _items = List.from(data);
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<Map<String, dynamic>>> getCustomerCardList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<Map<String, dynamic>> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'CustomerCard/CustomerCardList/' +
              dataBase,
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        if (response.data.toString().isNotEmpty) {
          List<dynamic> data = response.data;
          _items = List.from(data);
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<Map<String, dynamic>>> fetchLedgerReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<Map<String, dynamic>> _items = [];
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'accounts_report/getLedgerReport/' +
              dataBase,
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        if (response.data.toString().isNotEmpty) {
          List<dynamic> data = response.data['recordset'];
          _items = List.from(data);
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<Map<String, dynamic>>> fetchBalanceSheet(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<Map<String, dynamic>> _items = [];
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'BalanceSheet/getBalanceSheet/' +
              dataBase,
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        if (response.data.toString().isNotEmpty) {
          List<dynamic> data = response.data;
          _items = List.from(data);
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<Map<String, dynamic>>> fetchGroupReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<Map<String, dynamic>> _items = [];
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'accounts_report/Grouplist/' +
              dataBase,
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        _items = List.from(data);
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

//invoice wise customer //
  Future<List<StockProduct>> fetchStockProductByBarcode(String id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', location = '0';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    if (locationList.isNotEmpty) {
      location = locationList
          .where((element) => element.value == 'SHOP')
          .map((e) => e.key)
          .first
          .toString();
    }
    int lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    location =
        lId.toString().trim().isNotEmpty ? lId.toString().trim() : location;
    List<StockProduct> _items = [];

    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/getStockSaleListByBarcode/$dataBase/$id/$location');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var product in jsonResponse) {
          _items.add(StockProduct.fromJson(product));
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<StockItem>> fetchStockProduct(String date) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', location = '0', id = '1';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    if (locationList.isNotEmpty) {
      location = locationList
          .where((element) => element.value == 'SHOP')
          .map((e) => e.key)
          .first
          .toString();
    }
    int lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 0) -
        1;
    location = lId.toString().trim().isNotEmpty
        ? lId < 1
            ? location
            : lId.toString().trim()
        : location;
    List<StockItem> _items = [];

    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/getStockSaleList/$dataBase/$id/$location/$date');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var product in jsonResponse) {
          //.map((data) => new StockProduct.fromJson(data))
          _items.add(StockItem.fromJson(product));
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<StockItem>> fetchStockProductByLocation(
      String location, String date) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', id = '1';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    location = location.toString().trim().isNotEmpty ? location : '0';
    List<StockItem> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/getStockSaleList/$dataBase/$id/$location/$date');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var product in jsonResponse) {
          _items.add(StockItem.fromJson(product));
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<StockProduct>> fetchStockVariant(int id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', location = '0';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    if (locationList.isNotEmpty) {
      location = locationList
          .where((element) => element.value == 'SHOP')
          .map((e) => e.key)
          .first
          .toString();
    }
    int lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    location =
        lId.toString().trim().isNotEmpty ? lId.toString().trim() : location;
    List<StockProduct> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/getStockVariant/$dataBase/$id/$location');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var product in jsonResponse) {
          _items.add(StockProduct.fromJson(product));
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<StockProduct>> fetchStockVariantProduct(int id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', location = '0';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    if (locationList.isNotEmpty) {
      location = locationList
          .where((element) => element.value == 'SHOP')
          .map((e) => e.key)
          .first
          .toString();
    }
    int lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    location =
        lId.toString().trim().isNotEmpty ? lId.toString().trim() : location;
    List<StockProduct> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/getStockVariant/$dataBase/$id/$location');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var product in jsonResponse) {
          _items.add(StockProduct.fromJson(product));
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<StockProduct>> fetchStockItem(int id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', location = '0';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    if (locationList.isNotEmpty) {
      location = locationList
          .where((element) => element.value == 'SHOP')
          .map((e) => e.key)
          .first
          .toString();
    }
    int lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    location =
        lId.toString().trim().isNotEmpty ? lId.toString().trim() : location;
    List<StockProduct> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/getStockItem/$dataBase/$id/$location');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var product in jsonResponse) {
          _items.add(StockProduct.fromJson(product));
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<double> getStockOf(int id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', location = '0';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    if (locationList.isNotEmpty) {
      location = locationList
          .where((element) => element.value == 'SHOP')
          .map((e) => e.key)
          .first
          .toString();
    }
    int lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    location =
        lId.toString().trim().isNotEmpty ? lId.toString().trim() : location;
    List<double> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              '/stock/selectStockById/$dataBase/$id/$location');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var product in jsonResponse) {
          _items.add(double.tryParse(product['Qty'].toString()));
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items[0];
  }

  Future<double> getMinimumRateOf(int id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<double> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              '/product/getProductPurchase/$dataBase/$id');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var product in jsonResponse) {
          _items.add(double.tryParse(product['Qty'].toString()));
        }
        return _items[0];
      } else {
        debugPrint('Unexpected error Occurred!');
        return 0;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return 0;
    }
  }

  Future<List<UnitModel>> fetchUnitOf(int id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<UnitModel> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/getMultiUnit/$dataBase/$id');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var data in jsonResponse) {
          _items.add(UnitModel.fromJson(data));
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<UnitModel>> fetchUnitList(int id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<UnitModel> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/getMultiUnitAll/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var data in jsonResponse) {
          _items.add(UnitModel.fromJson(data));
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> getMainAccount() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getMainAccount/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        _items = jsonResponse as List;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> getMainHead() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getMainHead/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        return jsonResponse as List;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> fetchOtherRegList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'OtherRegistration/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        _items = jsonResponse as List;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> fetchDetailAmount() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/getDetailAmount/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        _items = jsonResponse as List;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<dynamic> fetchPreviousBills(ledger) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    dynamic _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/previous_bills/$dataBase/$ledger');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;

        _items = jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<dynamic> fetchSalesInvoice(int id, int type) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    dynamic _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/find/$dataBase/$id/$type');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;

        _items = jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<dynamic> findSale(int id, int type, String statement) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    dynamic _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/find/$dataBase/$id/$type/$statement');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;

        _items = jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> fetchAllProductPurchase() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/getProductListPurchase/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;

        _items = jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> fetchProductPurchaseListLike(String name) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/getProductListPurchaseLike/$dataBase/$name');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;

        _items = jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> fetchProductPrize(int id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/getProductPurchaseById/$dataBase/$id');
      if (response.statusCode == 200) {
        dynamic jsonResponse = response.data;
        _items = jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> fetchProductPrizeStock(int id, int location) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/getProductPurchaseByStock/$dataBase/$id/$location');
      if (response.statusCode == 200) {
        dynamic jsonResponse = response.data;
        _items = jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future fetchExpenseData(
      String sDate, String eDate, String sType, var branch) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'dashboard/Expense/$dataBase/${Uri.encodeComponent(sType).toString()}/$sDate/$eDate/$branch');

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        return jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future fetchExpenseLedger(String sDate, String eDate, name, branch) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'dashboard/getExpenseLedger/$dataBase/$sDate/$eDate/$name/$branch');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        return jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future fetchCashBankLedger(String sDate, String eDate) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    var branch = 0;
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'dashboard/getCashBankLedger/$dataBase/$sDate/$eDate/$branch');

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        return jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
  }

  Future<List<ChartPayRec>> fetchReceivableAndPayable(
      String sDate, String eDate, var branch) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<ChartPayRec> data = [];
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          'dashboard/getReceivableAndPayable/$dataBase/$sDate/$eDate/$branch');

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var _data in jsonResponse) {
          data.add(ChartPayRec.fromJson(_data));
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return data;
  }

  Future<dynamic> fetchPurchaseInvoice(int id, String type) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    dynamic _items = [];
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          '/purchase/find/$dataBase/$id/${Uri.encodeComponent(type).toString()}');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;

        _items = jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<bool> deletePurchase(entryNo, type) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.delete(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'purchase/delete/$dataBase/$entryNo/$type',
      );
      if (response.statusCode == 200) {
        ret = response.data['returnValue'] > 0 ? true : false;
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (ex) {
      ex.toString();
      ret = false;
    }
    return ret;
  }

  Future<dynamic> fetchVoucher(int id, String type) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    dynamic _items = [];
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          '/Voucher/find/$dataBase/$id/${Uri.encodeComponent(type).toString()}');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;

        _items = jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<dynamic> fetchInvoiceVoucher(int id, String type) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    dynamic _items = [];
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          '/InvoiceVoucher/find/$dataBase/$id/${Uri.encodeComponent(type).toString()}');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        _items = jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<dynamic> fetchStockTransfer(int id, String type) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    dynamic _items = [];
    try {
      final response = await dio.get(pref
              .getString('api' ?? '127.0.0.1:80/api/') +
          apiV +
          '/stock/stockTransferfind/$dataBase/$id/${Uri.encodeComponent(type).toString()}');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;

        _items = jsonResponse;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<bool> deleteStockTransfer(entryNo, type) async {
    bool ret = false;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.delete(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'stock/delete/$dataBase/$entryNo/$type',
      );
      if (response.statusCode == 200) {
        ret = response.data['returnValue'] > 0 ? true : false;
      } else {
        ret = false;
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<List<Map<String, dynamic>>> fetchQuickSearch(value) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<Map<String, dynamic>> _items = [];
    try {
      //localhost:8090/api/v7/inventory_report/QuickSearch/csharp/cable
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'inventory_report/QuickSearch/' +
              dataBase +
              '/${Uri.encodeComponent(value).toString()}');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        _items = List.from(data);
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<List<dynamic>> getProductTracking(id, ledger) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/getProductTracking/$dataBase/$id/$ledger');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        _items = data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }
}

class DataJson {
  int id;
  String name;

  DataJson({this.id, this.name});

  factory DataJson.fromJson(Map<String, dynamic> json) {
    return DataJson(id: json['id'], name: json['name']);
  }

  static List<DataJson> fromJsonList(List list) {
    return list.map((item) => DataJson.fromJson(item)).toList();
  }

  String userAsString() {
    return '#$id $name';
  }

  @override
  String toString() => name;
}

class DioExceptions implements Exception {
  DioExceptions.fromDioError(DioError dioError) {
    switch (dioError.type) {
      case DioErrorType.cancel:
        message = "Request to API server was cancelled";
        break;
      case DioErrorType.connectTimeout:
        message = "Connection timeout with API server";
        break;
      case DioErrorType.other:
        message = "Connection to API server failed due to internet connection";
        break;
      case DioErrorType.receiveTimeout:
        message = "Receive timeout in connection with API server";
        break;
      case DioErrorType.response:
        message =
            _handleError(dioError.response.statusCode, dioError.response.data);
        break;
      case DioErrorType.sendTimeout:
        message = "Send timeout in connection with API server";
        break;
      default:
        message = "Something went wrong";
        break;
    }
  }

  String message;

  String _handleError(int statusCode, dynamic error) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 404:
        return error["message"];
      case 500:
        return 'Internal server error';
      default:
        return 'Oops something went wrong';
    }
  }

  @override
  String toString() => message;
}
