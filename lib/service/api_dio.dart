// @dart = 2.11
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/gst_auth_model.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/models/ledger_parent.dart';
import 'package:sheraccerp/models/option_rate_type.dart';
import 'package:sheraccerp/models/product_manage_model.dart';
import 'package:sheraccerp/models/product_register_model.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/models/stock_item.dart';
import 'package:sheraccerp/models/stock_product.dart';
import 'package:sheraccerp/models/tax_group_model.dart';
import 'package:sheraccerp/models/unit_model.dart';
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
      var response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'dashboard/Total/$dataBase',
          queryParameters: {
            'statementType': sType,
            'sDate': sDate,
            'eDate': eDate,
            'branch': branch
          });

      if (response.statusCode == 200) {
        Map<dynamic, dynamic> responseBodyOfTotal;
        List<dynamic> outList = response.data;
        responseBodyOfTotal = outList[0];
        return responseBodyOfTotal;
      } else {
        debugPrint('Failed to load internet');
        return {};
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return {};
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
      var response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'dashboard/SummaryList/$dataBase',
          queryParameters: {
            'statementType': sType,
            'sDate': sDate,
            'eDate': eDate,
            'branch': branch
          });

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
      var response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'dashboard/SummaryList/$dataBase',
          queryParameters: {
            'statementType': sType,
            'sDate': sDate,
            'eDate': eDate,
            'branch': branch
          });
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
      var response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'dashboard/dayStatement/$dataBase',
          queryParameters: {
            'statementType': sType,
            'sDate': sDate,
            'eDate': eDate,
            'branch': branch
          });

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
      var response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'dashboard/dayStatement/$dataBase',
          queryParameters: {
            'statementType': head,
            'sDate': sDate,
            'eDate': eDate,
            'branch': branch
          });

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
              'company/event/$dataBase',
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
        // if (response.data.toString() == "1") {
        ret = true;
        // } else {
        //   ret = false;
        // }
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

  Future<dynamic> spLedger(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    var _item = [];
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/sp_ledger/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200 || response.statusCode == 201) {
        List<dynamic> _data = response.data;
        _item = _data;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _item;
  }

  Future<dynamic> addProduct(var body) async {
    dynamic ret = '0';
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
        if (response.data['id'] > 0) {
          ret = response.data['id'].toString();
        } else {
          ret = response.data['message'];
        }
      } else {
        ret = 'Unexpected error occurred!';
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      ret = errorMessage;
    }
    return ret;
  }

  Future<dynamic> editProduct(var body) async {
    dynamic ret = '0';
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");

    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/edit/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        if (jsonResponse['message'] == 'success') {
          ret = jsonResponse['message'];
        } else {
          ret = jsonResponse['message'];
        }
      } else {
        ret = 'unexpected error';
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      ret = errorMessage.toString();
    }
    return ret;
  }

  Future<bool> deleteProduct(var id) async {
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
              'Product/delete/$dataBase',
          queryParameters: {'id': id},
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

  Future<bool> renameProduct(var body) async {
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
              'Product/rename/$dataBase',
          data: json.encode(body),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        if (jsonResponse['message'] == 'success') {
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

  Future<dynamic> addSale(var body) async {
    dynamic ret = '0';
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
        if (response.data['id'] > 0) {
          ret = response.data['id'].toString();
        } else {
          ret = response.data['message'];
        }
      } else {
        ret = 'Unexpected error occurred!';
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      ret = errorMessage.toString();
    }
    return ret;
  }

  Future<dynamic> editSale(var body) async {
    dynamic ret = 0;
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
        if (response.data['id'] > 0) {
          ret = response.data['id'].toString();
        } else {
          ret = response.data['message'];
        }
      } else {
        ret = '0';
        debugPrint('Unexpected error occurred!');
        ret = 'Unexpected error occurred!';
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      ret = errorMessage.toString();
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
            'grandTotal': data['grandTotal'].toString(),
            'fyId': currentFinancialYear.id,
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
            'sale/delete/$dataBase',
        queryParameters: {
          'entryNo': entryNo,
          'type': type,
          'form': form,
          'fyId': currentFinancialYear.id,
        },
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
        return 0;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return 0;
    }
  }

  Future<int> deleteVoucher(String id, int fyId, String statementType) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.delete(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'Voucher/delete/$dataBase',
        queryParameters: {
          'id': id,
          'statementType': statementType,
          'fyId': currentFinancialYear.id
        },
      );

      if (response.statusCode == 200) {
        if (response.data['returnValue'] > 0) {
          return response.data['returnValue'];
        } else {
          return 0;
        }
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

  Future<int> addJournalVoucher(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Journal/add/$dataBase',
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
        return 0;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return 0;
    }
  }

  Future<int> editJournalVoucher(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Journal/edit/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        if (response.data['returnValue'] > 0) {
          return response.data['returnValue'];
        } else {
          return 0;
        }
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

  Future<int> deleteJournalVoucher(id, date, user, time) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.delete(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Journal/delete/$dataBase',
          queryParameters: {
            'id': id,
            'date': date,
            'user': user,
            'time': time,
            'fyId': currentFinancialYear.id
          },
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        if (response.data['returnValue'] > 0) {
          return response.data['returnValue'];
        } else {
          return 0;
        }
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
        return 0;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return 0;
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
        return 0;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return 0;
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
              'InvoiceVoucher/delete/$dataBase',
          queryParameters: {'id': id, 'type': type},
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 201) {
        if (response.data['returnValue'] > 0) {
          return response.data['returnValue'];
        } else {
          return 0;
        }
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
              'sales_list/$dataBase',
          queryParameters: {'statementType': statement});
      List<dynamic> _items = [];
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var json in jsonResponse) {
          _items.add({'id': json['iD'], 'value': true, 'name': json['type']});
        }
        return _items;
      } else {
        debugPrint('Failed to load data');
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return [];
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
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return [];
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
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return [];
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
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return [];
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
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return [];
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
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return [];
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'purchaseReport/$dataBase',
          queryParameters: {
            'sDate': '$sDate',
            'eDate': '$eDate',
            'branchId': branchId,
            'statementType': statement,
            'supplierId': supplierId,
            'project': project,
            'itemId': itemId,
            'mfr': mfr,
            'category': category,
            'subcategory': subcategory,
            'salesman': salesman,
            'taxGroup': taxGroup
          });
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return [];
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
              'purchaseReportMonthly/$dataBase');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return [];
    }
  }

  Future<List<dynamic>> getStockReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock_report_new/$dataBase',
          queryParameters: data,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return e.response.statusCode == 400
          ? [
              {
                'error': errorMessage,
                'respond': e.response.statusCode.toString(),
              }
            ]
          : [
              {
                'error': errorMessage,
                'respond': e.response.statusCode.toString(),
              }
            ];
    }
  }

  Future<List<dynamic>> getStockLedgerReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock_ledger_report/$dataBase',
          queryParameters: data,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return e.response.statusCode == 400
          ? [
              {
                'error': errorMessage,
                'respond': e.response.statusCode.toString(),
              }
            ]
          : [
              {
                'error': errorMessage,
                'respond': e.response.statusCode.toString(),
              }
            ];
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
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return [];
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
              'inventory_report/EventDetails/$dataBase',
          queryParameters: {'date': date});

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data;
      } else {
        debugPrint('Failed to load data');
        return [];
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return [];
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

  Future<ProductRegisterModel> getProductByName(String _name) async {
    ProductRegisterModel model;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/getByName/$dataBase',
          queryParameters: {'name': _name});

      if (response.statusCode == 200) {
        var data = response.data;
        if (data != null) {
          model = ProductRegisterModel.fromMap(data[0]);
        } else {
          // model = ;
          debugPrint('Unexpected error occurred!');
        }
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return model;
  }

  Future<ProductRegisterModel> getProductByCode(String _code) async {
    ProductRegisterModel model;
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/getByCode/$dataBase',
          queryParameters: {'code': _code});

      if (response.statusCode == 200) {
        var data = response.data;
        if (data != null) {
          model = ProductRegisterModel.fromMap(data[0]);
        } else {
          // model = ;
          debugPrint('Unexpected error occurred!');
        }
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return model;
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
              'users/find/$dataBase',
          queryParameters: {'name': name});

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
        return {};
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
              'Ledger/getSupplierList/$dataBase',
          queryParameters: {'name': filter});
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
            '/$dataBase',
        queryParameters: {"value": filter},
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
            statement +
            '/$dataBase',
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
            '/$dataBase',
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getParentList/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var group in jsonResponse) {
          _items.add(LedgerParent.fromJson(group));
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getLedger/$dataBase',
          queryParameters: {'name': name});
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
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'listPage/$dataBase',
        queryParameters: {
          'statementType': statement,
          'page': page,
          'location': location,
          'type': type,
          'date': date,
          'salesMan': salesMan,
          'fyId': currentFinancialYear.id
        },
      ).onError((error, stackTrace) {
        debugPrint('Erorr:' + error.toString());
      })
          // .timeout(const Duration(seconds: 10));
          ;
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'damage_report/$dataBase',
          queryParameters: {
            'statementType': statementType,
            'sDate': sDate,
            'eDate': eDate,
            'condition': condition
          });
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getLedgerByType/$dataBase',
          queryParameters: {'type': type});
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
              'Ledger/getLedgerByParent/$dataBase',
          queryParameters: {
            'groupId': _groupId,
            'areaId': _areaId,
            'routeId': _routeId,
            'salesman': _salesman,
            'filter': filter
          },
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
        optionRateTypeList = _items;
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
        response = await dio.get(
            pref.getString('api' ?? '127.0.0.1:80/api/') +
                apiV +
                'Ledger/getLedgerByParent/$dataBase',
            queryParameters: {
              'groupId': _groupId,
              'areaId': _areaId,
              'routeId': _routeId,
              'salesman': _salesman,
              'filter': ''
            });
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
        response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getLedgerByParentLike/$dataBase',
          queryParameters: {
            'groupId': _groupId,
            'areaId': _areaId,
            'routeId': _routeId,
            'salesman': _salesman,
            'like': like
          },
        );
      } else {
        response = await dio.get(
            pref.getString('api' ?? '127.0.0.1:80/api/') +
                apiV +
                'Ledger/getLedgerListLike/$dataBase',
            queryParameters: {'name': like});
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

  Future<List<LedgerModel>> getLedgerBySalesManLike(
      int salesman, String like) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerModel> _items = [];
    try {
      Response response;
      if (salesman > 1) {
        var _salesman = salesman > 1 ? salesman : 0;
        response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getLedgerBySalesManLike/$dataBase',
          queryParameters: {'salesman': _salesman, 'like': like},
        );
      } else {
        response = await dio.get(
            pref.getString('api' ?? '127.0.0.1:80/api/') +
                apiV +
                'Ledger/getLedgerListLike/$dataBase',
            queryParameters: {'name': like});
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
              'Ledger/getLedgerByType/$dataBase',
          queryParameters: {'type': sType});
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'accounts_report/ProfitAndLoss/' +
              dataBase,
          queryParameters: data);
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'inventory_report/ClosingReport/' +
              dataBase,
          queryParameters: data);
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

  Future<List<dynamic>> fetchClosingReportAll(data) async {
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
              'inventory_report/ClosingReportAll/' +
              dataBase,
          queryParameters: data);
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
          .where((element) => element.value == defaultLocation)
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
              'stock/getStockSaleListByBarcode/$dataBase',
          queryParameters: {'Id': id, 'location': location});
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
          .where((element) => element.value == defaultLocation)
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
              'stock/getStockSaleList/$dataBase',
          queryParameters: {'id': id, 'location': location, 'date': date});
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

  Future<List<StockItem>> fetchNoStockProduct(String date) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', location = '0', id = '1';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    if (locationList.isNotEmpty) {
      location = locationList
          .where((element) => element.value == defaultLocation)
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
              'Product/getProductList/$dataBase',
          queryParameters: {'date': date});
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
              'stock/getStockSaleList/$dataBase',
          queryParameters: {'id': id, 'location': location, 'date': date});
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
          .where((element) => element.value == defaultLocation)
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
              'stock/getStockVariant/$dataBase',
          queryParameters: {'Id': id, 'location': location});
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

  Future<List<dynamic>> fetchNoStockVariant(String id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', location = '0';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    if (locationList.isNotEmpty) {
      location = locationList
          .where((element) => element.value == defaultLocation)
          .map((e) => e.key)
          .first
          .toString();
    }
    int lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    location =
        lId.toString().trim().isNotEmpty ? lId.toString().trim() : location;
    List<dynamic> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/getNonStockVariant/$dataBase',
          queryParameters: {'Id': id});
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var product in jsonResponse) {
          _items.add(product);
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
          .where((element) => element.value == defaultLocation)
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
              'stock/getStockVariant/$dataBase',
          queryParameters: {'Id': id, 'location': location});
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
          .where((element) => element.value == defaultLocation)
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
              'stock/getStockItem/$dataBase',
          queryParameters: {'Id': id, 'location': location});
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
          .where((element) => element.value == defaultLocation)
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
              '/stock/selectStockById/$dataBase',
          queryParameters: {'id': id, 'location': location});
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        if (jsonResponse.isNotEmpty) {
          for (var product in jsonResponse) {
            _items.add(double.tryParse(product['Qty'].toString()));
          }
        } else {
          _items.add(0);
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
              'sale/previous_bills/$dataBase',
          queryParameters: {'id': ledger, 'fyId': currentFinancialYear.id});
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

  Future<dynamic> fetchItemBills(sDate, eDate) async {
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
              'sale/Item_bills/$dataBase',
          queryParameters: {
            'sDate': sDate,
            'eDate': eDate,
            'fyId': currentFinancialYear.id
          });
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
              'sale/find/$dataBase',
          queryParameters: {
            'id': id,
            'type': type,
            'fyId': currentFinancialYear.id,
          });
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
              'Product/getProductListPurchaseLike/$dataBase',
          queryParameters: {'name': name});
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'dashboard/Expense/$dataBase',
          queryParameters: {
            'statementType': sType,
            'sDate': sDate,
            'eDate': eDate,
            'branch': branch
          });

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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'dashboard/getExpenseLedger/$dataBase',
          queryParameters: {
            'sDate': sDate,
            'eDate': eDate,
            'name': name,
            'branch': branch
          });
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
              'dashboard/getCashBankLedger/$dataBase',
          queryParameters: {'sDate': sDate, 'eDate': eDate, 'branch': branch});

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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'dashboard/getReceivableAndPayable/$dataBase',
          queryParameters: {'sDate': sDate, 'eDate': eDate, 'branch': branch});

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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              '/purchase/find/$dataBase',
          queryParameters: {
            'id': id,
            'statement': type,
            'fyId': currentFinancialYear.id
          });
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
            'purchase/delete/$dataBase',
        queryParameters: {
          'entryNo': entryNo,
          'type': type,
          'fyId': currentFinancialYear.id
        },
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              '/Voucher/find/$dataBase',
          queryParameters: {
            'id': id,
            'type': type,
            'fyId': currentFinancialYear.id
          });
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

  Future<dynamic> fetchJournalVoucher(int id) async {
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
              '/Journal/find/$dataBase',
          queryParameters: {'id': id});
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              '/InvoiceVoucher/find/$dataBase',
          queryParameters: {'id': id, 'type': type});
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              '/stock/stockTransferFind/$dataBase',
          queryParameters: {'entryNo': id, 'fyId': currentFinancialYear.id});
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
            'stock/delete/$dataBase',
        queryParameters: {
          'entryNo': entryNo,
          'type': type,
          'fyId': currentFinancialYear.id
        },
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
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'inventory_report/QuickSearch/$dataBase',
          queryParameters: {'name': value});

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
              'sale/getProductTracking/$dataBase',
          queryParameters: {'id': id, 'ledger': ledger});

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

  Future<List<ProductManageModel>> fetchProductDetails(id, String date) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp', location = '0';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    if (locationList.isNotEmpty) {
      location = locationList
          .where((element) => element.value == defaultLocation)
          .map((e) => e.key)
          .first
          .toString();
    }
    int lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    location =
        lId.toString().trim().isNotEmpty ? lId.toString().trim() : location;
    List<ProductManageModel> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/getProductManagement/$dataBase',
          queryParameters: {'id': id, 'location': location, 'date': date});

      if (response.statusCode == 200) {
        var data = response.data;
        for (var row in data) {
          _items.add(ProductManageModel.fromMap(row));
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

  Future<bool> updateProductDetails(List<ProductManageModel> data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/UpdateProductManagement/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        if (response.data['returnValue'] > 0) {
          return response.data['returnValue'] > 0 ? true : false;
        } else {
          return false;
        }
      } else {
        debugPrint('Unexpected error Occurred!');
        return false;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return false;
    }
  }

  Future<List<dynamic>> getVoucherList(
      String ledCode,
      String location,
      String groupCode,
      String project,
      String fromDate,
      String toDate,
      String sDate,
      String eDate,
      String where,
      String cashId,
      String salesman,
      String statement,
      String area,
      String route) async {
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
              'voucher_report/getListReport/$dataBase',
          queryParameters: {
            'ledCode': ledCode,
            'location': location,
            'groupCode': groupCode,
            'project': project,
            'fromDate': fromDate,
            'toDate': toDate,
            'sDate': sDate,
            'eDate': eDate,
            'where': where,
            'cashId': cashId,
            'salesman': salesman,
            'statement': statement,
            'areaId': area,
            'routeId': route
          });

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

  Future<int> getStockManageMentId() async {
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
              'stock/getStockManagementId/$dataBase',
          queryParameters: {'fyId': currentFinancialYear.id});
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

  Future<bool> stockManagementUpdate(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/stockManagement/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Failed to load data');
        return false;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return false;
    }
  }

  Future<bool> companyUpdate(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'company/company/update',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        return response.data > 0 ? true : false;
      } else {
        debugPrint('Failed to load data');
        return false;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return false;
    }
  }

  Future<dynamic> eInvoiceDetails() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'EInvoice/Details/$dataBase');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('Unexpected error Occurred!');
        return {};
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return {};
    }
  }

  Future<bool> eInvoiceUpdate(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'EInvoice/$dataBase',
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Failed to load data');
        return false;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return false;
    }
  }

  Future<dynamic> getPublicIp() async {
    try {
      final response = await dio.get("https://ipinfo.io/ip");
      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('Unexpected error Occurred!');
        return {};
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return {};
    }
  }

  Future<AuthClass> authenticateGSTPortal(
      username, password, ipAddress, clientId, clientSecret, gstIn) async {
    AuthClass data;
    try {
      final response = await dio.get(gstBaseApi + gstAuthApi,
          options: Options(headers: {
            'accept': '*/*',
            'username': username,
            'password': password,
            'ip_address': ipAddress,
            'client_id': clientId,
            'client_secret': clientSecret,
            'gstin': gstIn,
          }),
          queryParameters: {'email': 'shersoftware@gmail.com'});

      if (response.statusCode == 200) {
        var _data = response.data;
        data = AuthClass.fromMap(_data);
        return data;
      } else {
        debugPrint('Failed to load data');
        return data;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return data;
    }
  }

  Future<GstNoResult> getGstResult(
      String bClient,
      String taxNumber,
      String username,
      String ipAddress,
      clientId,
      String clientSecret,
      String authToken,
      String companyGstNo) async {
    GstNoResult data;
    try {
      final response = await dio.get(
          "https://api.mastergst.com/einvoice/type/GSTNDETAILS/version/V1_03",
          queryParameters: {
            "param1": taxNumber,
            "email": bClient != "SHERSOFT"
                ? "ac.japansquare@gmail.com"
                : "shersoftware@gmail.com"
          },
          options: Options(headers: {
            'accept': '*/*',
            'ip_address': ipAddress,
            'client_id': clientId,
            'client_secret': clientSecret,
            'username': username,
            'auth-token': authToken,
            'gstin': companyGstNo,
          }));

      if (response.statusCode == 200) {
        var _data = response.data;
        data = GstNoResult.fromMap(_data);
        return data;
      } else {
        debugPrint('Failed to load data');
        return data;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return data;
    }
  }

  Future<IRnResult> generateEInvoice(
      String bClient,
      String username,
      String ipAddress,
      clientId,
      String clientSecret,
      String authToken,
      String companyGstNo,
      data) async {
    IRnResult data;
    try {
      final response = await dio.post(
          "https://api.mastergst.com/einvoice/type/GENERATE/version/V1_03",
          queryParameters: {
            "email": bClient != "SHERSOFT"
                ? "ac.japansquare@gmail.com"
                : "shersoftware@gmail.com"
          },
          options: Options(headers: {
            'accept': '*/*',
            'ip_address': ipAddress,
            'client_id': clientId,
            'client_secret': clientSecret,
            'username': username,
            'auth-token': authToken,
            'gstin': companyGstNo,
            'Content-Type': 'application/json'
          }),
          data: data);

      if (response.statusCode == 200) {
        var _data = response.data;
        data = IRnResult.fromMap(_data);
        return data;
      } else {
        debugPrint('Failed to load data');
        return data;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return data;
    }
  }

  Future<IRnResult> cancelIRN(
      String bClient,
      String username,
      String ipAddress,
      clientId,
      String clientSecret,
      String authToken,
      String companyGstNo,
      data) async {
    IRnResult data;
    try {
      final response = await dio.post(
          "https://api.mastergst.com/einvoice/type/GENERATE/version/V1_03",
          queryParameters: {
            "email": bClient != "SHERSOFT"
                ? "ac.japansquare@gmail.com"
                : "shersoftware@gmail.com"
          },
          options: Options(headers: {
            'accept': '*/*',
            'ip_address': ipAddress,
            'client_id': clientId,
            'client_secret': clientSecret,
            'username': username,
            'auth-token': authToken,
            'gstin': companyGstNo,
            'Content-Type': 'application/json'
          }),
          data: data);

      if (response.statusCode == 200) {
        var _data = response.data;
        data = IRnResult.fromMap(_data);
        return data;
      } else {
        debugPrint('Failed to load data');
        return data;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return data;
    }
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
