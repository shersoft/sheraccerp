// @dart = 2.11
import 'dart:convert';
import 'dart:io';

import 'package:cross_file/src/types/interface.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/company.dart';

import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/group_model.dart';
import 'package:sheraccerp/models/gst_auth_model.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/models/ledger_parent.dart';
import 'package:sheraccerp/models/option_rate_type.dart';
import 'package:sheraccerp/models/print_settings_model.dart';
import 'package:sheraccerp/models/product_manage_model.dart';
import 'package:sheraccerp/models/product_register_model.dart';
import 'package:sheraccerp/models/sales_man_model.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/models/stock_item.dart';
import 'package:sheraccerp/models/stock_product.dart';
import 'package:sheraccerp/models/tax_group_model.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/models/user_model.dart';
import 'package:sheraccerp/models/voucher_type_model.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/widget/simple_piediagram_pay_rec.dart';
import 'package:http/http.dart' as ht;

import '../models/sms_data_model.dart';

class DioService {
  var dio = Dio();
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
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<List<dynamic>> findLedger(id) async {
    List<dynamic> ret = [];
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/find/$dataBase',
          queryParameters: {'id': id});

      if (response.statusCode == 200) {
        ret = response.data;
      } else {
        ret = [];
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> renameLedger(var body) async {
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
              'Ledger/rename/$dataBase',
          queryParameters: body,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        if (response.data.toString() == "1") {
          ret = true;
        } else {
          ret = false; //
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

  Future<bool> addOthersAmount(body) async {
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
              'sale/addOthersAmount/$dataBase',
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

  Future<bool> deleteDeliveryNote(entryNo, type, form) async {
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
            'sale/deleteDeliveryNote/$dataBase',
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

  Future<int> deleteVoucher(
      String id, int fyId, String statementType, int frmId) async {
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
          'fyId': currentFinancialYear.id,
          'frmId': frmId
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

  Future<List<dynamic>> getListPageReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'listPageReportAll/$dataBase',
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
              'salesReportMonthly/$dataBase',
          queryParameters: {
            'location': branchId,
            'fyId': currentFinancialYear.id
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

  Future<List<dynamic>> getPurchaseReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'purchase_report/$dataBase',
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
              'purchaseReportMonthly/$dataBase',
          queryParameters: {
            'location': branchId,
            'fyId': currentFinancialYear.id
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

  Future<ProductRegisterModel> getProductById(String id) async {
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
              'Product/getById/$dataBase',
          queryParameters: {'id': id});

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
          userIdC = jsonResponse[0]['Auto'];
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

  Future<List<LedgerModel>> getLedgerByGroup(groupId) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerModel> _items = [];
    try {
      var _groupId = groupId > 1 ? groupId : 0,
          _areaId = 0,
          _routeId = 0,
          _salesman = 0,
          like = '';
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'Ledger/getLedgerByParent/$dataBase',
        queryParameters: {
          'groupId': _groupId,
          'areaId': _areaId,
          'routeId': _routeId,
          'salesman': _salesman,
          'like': like
        },
      );
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

  Future<List<LedgerModel>> getLedgerBySalesMan(salesManId) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<LedgerModel> _items = [];
    try {
      var _salesman = salesManId > 0 ? salesManId : 0,
          _areaId = 0,
          _routeId = 0,
          _groupId = 0,
          like = '';
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'Ledger/getLedgerByParent/$dataBase',
        queryParameters: {
          'groupId': _groupId,
          'areaId': _areaId,
          'routeId': _routeId,
          'salesman': _salesman,
          'like': like
        },
      );
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
      )
          // .onError((error, stackTrace) {
          //   debugPrint('Erorr:' + error.toString());
          // })
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

  Future<List<SalesType>> getSalesReturnTypeList() async {
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
              'sale/getSalesReturnTypeList/$dataBase');
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
      if (salesman > 0) {
        var _salesman = salesman > 0 ? salesman : 0;
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
        if (_data.isNotEmpty) {
          _item = CustomerModel.fromJson(_data[0]);
        } else {
          _item = CustomerModel.emptyData();
          _item.id = id;
          _item.name = '';
        }
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
        if (_data.isNotEmpty) {
          _item = CustomerModel.fromJson(_data[0]);
        } else {
          _item = CustomerModel.emptyData();
          _item.id = id;
          _item.name = '';
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _item;
  }

  Future<List<Map<String, dynamic>>> getLedgerListByType(sType) async {
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
              'accounts_report/groupListNew/' +
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

  Future<List<StockItem>> fetchStockProductLike(
      String date, String like) async {
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
              'stock/getStockSaleListLike/$dataBase',
          queryParameters: {
            'id': id,
            'location': location,
            'date': date,
            'like': like
          });
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

  Future<List<StockItem>> fetchNoStockProductLike(
      String date, String like) async {
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
              'Product/getProductListLike/$dataBase',
          queryParameters: {'date': date, 'like': like});
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

  Future<List<StockProduct>> fetchStockVariantList(int id) async {
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
              'stock/getStockVariantList/$dataBase',
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

  Future<List<dynamic>> fetchNoStockVariantList(String id) async {
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
              'stock/getNonStockVariantList/$dataBase',
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

  Future<List<StockProduct>> fetchStockByItemCode(String itemCode) async {
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
              'stock/getStockByItemCode/$dataBase',
          queryParameters: {'itemCode': itemCode, 'location': location});
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
              'stock/selectStockById/$dataBase',
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
              'product/getProductPurchase/$dataBase',
          queryParameters: {'id': id});
      //v20 'product/getProductPurchase/$dataBase/$id');
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
              'Product/getMultiUnit/$dataBase',
          queryParameters: {'id': id});
      //v20 'Product/getMultiUnit/$dataBase/$id');
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

  Future<bool> addOtherRegistration(data) async {
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
              'OtherRegistration/Add/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 201) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> editOtherRegistration(data) async {
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
              'OtherRegistration/Edit/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 201) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> deleteOtherRegistration(id) async {
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
              'OtherRegistration/Delete/$dataBase',
          queryParameters: {'auto': id},
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        ret = true;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
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
          queryParameters: {'id': ledger});
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

  Future<dynamic> fetchPreviousPurchaseBills(ledger) async {
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
              'purchase/previous_bills/$dataBase',
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

  Future<dynamic> fetchDeliveryNoteInvoice(int id, int type) async {
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
              'sale/findDeliveryNote/$dataBase',
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

  Future<dynamic> fetchSalesReturnInvoice(String id, int type) async {
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
              'sale/findReturn/$dataBase',
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

  Future<List<ProductPurchaseModel>> fetchAllProductPurchase() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<ProductPurchaseModel> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Product/getProductListPurchase/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;

        _items = List<ProductPurchaseModel>.from(
            jsonResponse.map((x) => ProductPurchaseModel.fromMap(x)));
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
              'Product/getProductPurchaseById/$dataBase',
          queryParameters: {'id': id});

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
              'Product/getProductPurchaseByStock/$dataBase',
          queryParameters: {'id': id, 'location': location});
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

  Future<dynamic> fetchPurchaseInvoiceSp(int id, String type, var frmId) async {
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
              'purchaseSP/find/$dataBase',
          queryParameters: {
            'id': id,
            'statement': type,
            'fyId': currentFinancialYear.id,
            'frmId': frmId
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

  Future<dynamic> fetchPurchaseInvoice(int id, String type, var frmId) async {
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
              'purchaseFind/$dataBase',
          queryParameters: {
            'id': id,
            'type': type,
            'fyId': currentFinancialYear.id,
            'frmId': frmId
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

  Future<dynamic> fetchPurchaseInvoiceOld(int id, String type) async {
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
              'purchase/find/$dataBase',
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

  Future<dynamic> fetchPurchaseReturnInvoice(
      int id, String type, var frmId) async {
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
              'purchaseReturn/find/$dataBase',
          queryParameters: {
            'id': id,
            'type': type,
            'fyId': currentFinancialYear.id,
            'frmId': frmId
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

  Future<bool> deletePurchase(entryNo, type, frmId) async {
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
          'fyId': currentFinancialYear.id,
          'frmId': frmId
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

  Future<dynamic> fetchVoucher(int id, String type, frmId) async {
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
              'Voucher/find/$dataBase',
          queryParameters: {
            'id': id,
            'type': type,
            'fyId': currentFinancialYear.id,
            'frmId': frmId
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
              'Journal/find/$dataBase',
          queryParameters: {'id': id, 'fyId': currentFinancialYear.id});
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
              'InvoiceVoucher/find/$dataBase',
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
              'stock/stockTransferFind/$dataBase',
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

  Future<List<dynamic>> getSoldProductTracking(id, ledger) async {
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
              'sale/getSoldProductTracking/$dataBase',
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

  Future<bool> stockManagementDelete(entryNo) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.delete(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/deleteStockManagement/$dataBase',
          queryParameters: {
            'fyId': currentFinancialYear.id,
            'entryNo': entryNo
          },
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

  Future<List<dynamic>> stockManagementFind(String entryNo) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'stock/findStockManagement/$dataBase',
          queryParameters: {
            'fyId': currentFinancialYear.id,
            'entryNo': entryNo
          },
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('Failed to load data');
        return null;
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return null;
    }
  }

  Future<List<CompanySettings>> getSoftwareSettings() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<CompanySettings> _data = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'SoftwareSettings/$dataBase');
      if (response.statusCode == 200) {
        for (var data in response.data) {
          _data.add(CompanySettings.fromJson1(data));
        }
      } else {
        //
      }
    } on DioError {
      // print(e.message);
    }
    return _data;
  }

  Future<List<PrintSettingsModel>> getPrintSettings() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<PrintSettingsModel> _data = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'PrintSettings/$dataBase',
          queryParameters: {
            'fyId': currentFinancialYear != null ? currentFinancialYear.id : 0
          });
      if (response.statusCode == 200) {
        for (var data in response.data) {
          _data.add(PrintSettingsModel.fromMap(data));
        }
      } else {
        //
      }
    } on DioError {
      // print(e.message);
    }
    return _data;
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

      if (response.statusCode == 201) {
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

  Future<bool> updateGeneralSetting(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'updateGeneralSetting/$dataBase',
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
      final response = await dio.get(gstBaseApi + gstDetailsApi,
          queryParameters: {
            "param1": taxNumber,
            "email": bClient != "SHERSOFT"
                ? "ac.japansquare@gmail.com"
                : "shersoftware@gmail.com"
          },
          options: Options(headers: {
            "param1": taxNumber,
            "email": bClient != "SHERSOFT"
                ? "abc@gmail.com"
                : "shersoftware@gmail.com",
            'ip_address': ipAddress,
            'client_id': clientId,
            'client_secret': clientSecret,
            'username': username,
            'auth-token': authToken,
            'gstin': companyGstNo,
          }));

      if (response.statusCode == 200) {
        if (response.data != null) {
          var _data = response.data;
          if (_data['status_cd'] == '0') {
            data = GstNoResult(
              data: GSTNoData(
                  AddrBnm: '',
                  AddrBno: '',
                  AddrFlno: '',
                  AddrLoc: '',
                  AddrPncd: 0,
                  AddrSt: '',
                  BlkStatus: '',
                  DtDReg: '',
                  DtReg: '',
                  Gstin: '',
                  LegalName: '',
                  StateCode: 0,
                  Status: '',
                  TradeName: '',
                  TxpType: ''),
              status_cd: _data['status_cd'] ?? '',
              status_desc: _data['status_desc'] ?? '',
            );
          } else {
            data = GstNoResult.fromMap(_data);
          }
        }
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
      final response = await dio.post(gstBaseApi + gstIrnApi,
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
      final response = await dio.post(gstBaseApi + gstCancelIrnApi,
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

  Future<File> getInvoiceDesignerPdfFile(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    data.update('code', (value) => pref.getString('Code') ?? 'COM');

    try {
      final response = await dio.post(invoiceUrl,
          data: json.encode(data),
          options: Options(
              headers: {'Content-Type': 'application/json'},
              responseType: ResponseType.bytes));
      if (response != null) {
        final Directory appDir = await getTemporaryDirectory();
        String tempPath = appDir.path;
        final String fileName =
            DateTime.now().microsecondsSinceEpoch.toString() + '-' + 's.pdf';
        File file = File('$tempPath/$fileName');
        if (!await file.exists()) {
          await file.create();
        }
        await file.writeAsBytes(response.data);
        return file;
      }
      debugPrint('The download failed.');
    } catch (value) {
      if (value is DioError) {
        debugPrint(value.response.toString());
      }
      debugPrint(value.toString());
    }
    return null;
  }

  Future<List<int>> getInvoiceDesignerPdfData(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    data.update('code', (value) => pref.getString('Code') ?? 'COM');
    try {
      final response = await dio.post(invoiceUrl,
          data: json.encode(data),
          options: Options(
              headers: {'Content-Type': 'application/json'},
              responseType: ResponseType.bytes));
      if (response != null) {
        return response.data;
      }
      debugPrint('The download failed.');
    } catch (value) {
      if (value is DioError) {
        debugPrint(value.response.toString());
      }
      // debugPrint(value.toString());
    }
    return null;
  }

  Future<bool> updateBillInfo(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/editIrn/$dataBase',
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

  Future<bool> updateReturnBillInfo(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/editSalesReturnIrn/$dataBase',
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

  Future<bool> updateCanceledBillInfo(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/editCanceledSaleIrn/$dataBase',
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

  Future<bool> updateCanceledReturnBillInfo(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/editCanceledSalesReturnIrn/$dataBase',
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

  Future<Map<String, dynamic>> getGeoCode(String pin) async {
    final response = await dio.get(geoApiFy.replaceAll('pin', pin),
        options: Options(headers: {'Content-Type': 'application/json'}));
    if (response.statusCode == 200) {
      var data = response.data['results'][0];
      return {'place': data['county'], 'lon': data['lon'], 'lat': data['lat']};
    } else {
      return {};
    }
  }

  Future<EWayResultModel> authEWay(
      String bClient,
      String username,
      String password,
      String ipAddress,
      clientId,
      String clientSecret,
      gstNo) async {
    EWayResultModel data;
    try {
      final response = await dio.get(gstBaseApi + eWayAuthApi,
          queryParameters: {
            "email": bClient != "SHERSOFT"
                ? "ac.japansquare@gmail.com"
                : "shersoftware@gmail.com",
            'username': username,
            'password': password
          },
          options: Options(headers: {
            'Accept': 'application/json',
            'ip_address': ipAddress,
            'client_id': clientId,
            'client_secret': clientSecret,
            'gstin': gstNo
          }));
      if (response.statusCode == 200) {
        var _data = response.data;
        return data = EWayResultModel.fromMap(_data);
      } else {
        debugPrint('Failed to load data');
        return EWayResultModel.emptyData();
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return EWayResultModel.emptyData();
    }
  }

  Future<EWayResultModel> generateEWayBill(
      String bClient,
      String gstNo,
      String password,
      String ipAddress,
      clientId,
      String clientSecret,
      data) async {
    EWayResultModel data;
    try {
      final response = await dio.post(gstBaseApi + eWayBillApi,
          queryParameters: {
            "email": bClient != "SHERSOFT"
                ? "ac.japansquare@gmail.com"
                : "shersoftware@gmail.com"
          },
          options: Options(headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'ip_address': ipAddress,
            'client_id': clientId,
            'client_secret': clientSecret,
            'gstin': gstNo
          }),
          data: data);
      if (response.statusCode == 200) {
        var _data = response.data;
        return data = EWayResultModel.fromMap(_data);
      } else {
        debugPrint('Failed to load data');
        return EWayResultModel.emptyData();
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return EWayResultModel.emptyData();
    }
  }

  Future<EWayResultModel> cancelEWayBill(
      String bClient,
      String gstNo,
      String password,
      String ipAddress,
      clientId,
      String clientSecret,
      data) async {
    try {
      final response = await dio.post(gstBaseApi + eWayBillCancelApi,
          queryParameters: {
            "email": bClient != "SHERSOFT"
                ? "ac.japansquare@gmail.com"
                : "shersoftware@gmail.com"
          },
          options: Options(headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'ip_address': ipAddress,
            'client_id': clientId,
            'client_secret': clientSecret,
            'gstin': gstNo
          }),
          data: data);
      if (response.statusCode == 200) {
        var _data = response.data;
        return EWayResultModel.fromMap(_data);
      } else {
        debugPrint('Failed to load data');
        return EWayResultModel.emptyData();
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
      return EWayResultModel.emptyData();
    }
  }

  Future<List<dynamic>> getTaxReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'TaxReport/$dataBase',
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

  Future<List<SmsDataModel>> getSMSApiData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<SmsDataModel> data = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'getSMSSettings/$dataBase');
      if (response.statusCode == 200) {
        data = response.data;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return data;
  }

  Future<List<SmsDataModel>> getSMSApiDataList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<SmsDataModel> data = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'getSMSSettingsList/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var _data in jsonResponse) {
          data.add(SmsDataModel.fromMap(_data));
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

  Future<bool> sentSmsOverApi(String urlData) async {
    try {
      final response = await dio.get(urlData);
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

  Future<bool> saveSmsApi(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    bool result = false;
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'addSMSSettings/$dataBase',
          data: json.encode(data));
      if (response.statusCode == 200) {
        result = true;
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return result;
  }

  Future<dynamic> fetchBankVoucher(int id, String type) async {
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
              'BankVoucher/find/$dataBase',
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

  Future<int> addBankVoucher(List<Map<String, Object>> data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'BankVoucher/add/$dataBase',
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

  Future<int> deleteBankVoucher(
      String id, int fyId, String statementType) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.delete(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'BankVoucher/delete/$dataBase',
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

  Future<List<dynamic>> getSerialNoReport(type, String serialNo, String itemId,
      String mfr, String category, String subCategory, String branch) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    String statement = type == 'Select All'
        ? 'all'
        : type == 'Details'
            ? 'details'
            : 'transaction';
    dynamic _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'serialNoReport/$statement/$dataBase',
          queryParameters: {
            'itemId': itemId,
            'serialNo': serialNo,
            'mfrId': mfr,
            'categoryId': category,
            'subCategoryId': subCategory,
            'branch': branch
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

  Future<List<SalesManModel>> getSalesManList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<SalesManModel> resultData = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'salesman/salesmanList/$dataBase');
      if (response.statusCode == 200) {
        for (var json in response.data) {
          resultData.add(SalesManModel.fromJson(json));
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return resultData;
  }

  Future<List<SalesManModel>> getSalesManListAll() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<SalesManModel> resultData = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'salesman/listAll/$dataBase');
      if (response.statusCode == 200) {
        for (var json in response.data) {
          resultData.add(SalesManModel.fromJson(json));
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return resultData;
  }

  Future<List<SalesManModel>> getSalesManAll() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<SalesManModel> resultData = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'salesman/All/$dataBase');
      if (response.statusCode == 200) {
        for (var json in response.data) {
          resultData.add(SalesManModel.fromJson(json));
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return resultData;
  }

  Future<EmployeeModel> findSalesman(String name) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    EmployeeModel resultData;
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'salesman/find/$dataBase',
          queryParameters: {'name': name});
      if (response.statusCode == 200) {
        for (var employeeModel in response.data) {
          resultData = EmployeeModel.fromMap(employeeModel);
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return resultData;
  }

  Future<bool> addSalesman(data) async {
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
              'salesman/add/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 201) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> editSalesman(data) async {
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
              'salesman/edit/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 201) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> deleteSalesman(String id, String name) async {
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
              'salesman/delete/$dataBase',
          queryParameters: {'auto': id, 'name': name},
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        ret = true;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> renameSalesMan(Map<String, String> body) async {
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
              'salesman/rename/$dataBase',
          queryParameters: body,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        if (response.data.toString() == "1") {
          ret = true;
        } else {
          ret = false; //
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

  Future<List<dynamic>> getCityListBySalesMan(int id) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    dynamic resultData;
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'salesman/getCityListBySalesMan/$dataBase',
          queryParameters: {'id': id});
      if (response.statusCode == 200) {
        resultData = response.data;
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return resultData;
  }

  Future<List<UserModel>> getUserListAll() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    List<UserModel> userList = [];
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'users/All/$dataBase');

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data['recordset'];
        if (jsonResponse.isNotEmpty) {
          for (var map in jsonResponse) {
            userList.add(UserModel(
                id: map['auto'],
                groupName: '',
                password: '',
                userId: 0,
                userName: map['name']));
          }
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return userList;
  }

  Future<bool> checkPasswordUser(String name, String password) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    bool check = false;
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'users/checkPassword/$dataBase',
          queryParameters: {'password': password, 'name': name});

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        check = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return check;
  }

  Future<bool> changePasswordUser(String name, String password) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    bool check = false;
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'users/changePassword/$dataBase',
          data: {'name': name, 'password': password});

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        check = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return check;
  }

  Future<UserModel> findUser(String name) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    UserModel userModel = UserModel.emptyData();
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
          for (var map in jsonResponse) {
            userModel = UserModel.fromJson(map);
          }
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return userModel;
  }

  Future<bool> addUser(Map<String, Object> data) async {
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
              'users/add/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> editUser(Map<String, Object> data) async {
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
              'users/edit/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> deleteUser(String id, String name) async {
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
              'users/delete/$dataBase',
          queryParameters: {'auto': id, 'name': name},
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        ret = true;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<List<UserGroupModel>> getUserGroupListAll() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    List<UserGroupModel> userList = [];
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'userGroup/All/$dataBase');

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        if (jsonResponse.isNotEmpty) {
          for (var map in jsonResponse) {
            userList.add(UserGroupModel.fromMap(map));
          }
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return userList;
  }

  Future<UserGroupModel> findUserGroup(String name) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    UserGroupModel groupModel;
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'userGroup/find/$dataBase',
          queryParameters: {'name': name});

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        if (jsonResponse.isNotEmpty) {
          groupModel = UserGroupModel.fromMap(jsonResponse[0]);
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return groupModel;
  }

  Future<bool> addUserGroup(Map<String, Object> data) async {
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
              'userGroup/Add/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> editUserGroup(Map<String, Object> data) async {
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
              'userGroup/edit/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> deleteUserGroup(String name) async {
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
              'userGroup/delete/$dataBase',
          queryParameters: {'groupName': name},
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        ret = true;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<List<SalesType>> salesFormList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    List<SalesType> resultData;
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'salesForm/ListAll/$dataBase',
      );

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var data in jsonResponse) {
          resultData.add(SalesType.fromJson(data));
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return resultData;
  }

  Future<bool> salesFormAdd(data) async {
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
              'salesForm/add/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 201) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> salesOtherDetailsAdd(data) async {
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
              'salesForm/addOtherDetails/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 201) {
        // var jsonResponse = response.data;
        ret = true;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> checkDomain() async {
    try {
      String domain = kIsWeb ? 'www.google.com' : 'https://www.google.com/';
      final response = await dio.get(domain);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      return false;
      // debugPrint(e.toString());
    }
    return false;
  }

  Future<bool> updateGeneralSettingMobile(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.put(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'updateGeneralSettingMobile/$dataBase',
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

  Future<List<TaxGroupModel>> taxGroupAll() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<TaxGroupModel> _items = [];
    try {
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'taxGroup/All' +
            '/$dataBase',
      );
      final data = response.data;
      if (data != null) {
        _items = TaxGroupModel.fromMapList(data);
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return _items;
  }

  Future<bool> taxGroupAdd(data) async {
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
              'taxGroup/add/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 201) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> taxGroupEdit(data) async {
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
              'taxGroup/edit/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 201) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> taxGroupDelete(data) async {
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
              'taxGroup/delete/$dataBase',
          queryParameters: data,
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        ret = true;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<List<ReportDesign>> getReportDesignByName(String form) async {
    List<ReportDesign> _reportDesign = [];
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'reportDesignerByName/$dataBase',
          queryParameters: {'name': form});
      if (response.statusCode == 200) {
        List<dynamic> _data = response.data;
        for (var data in _data) {
          _reportDesign.add(ReportDesign.fromMap(data));
        }
      } else {
        // throw Exception('Failed to load data');
      }
    } on DioError {
      // print(e.message);
    }
    return _reportDesign;
  }

  Future<List<VoucherType>> voucherFormList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    List<VoucherType> result = [];
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'voucherForm/All/$dataBase',
      );

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var data in jsonResponse) {
          result.add(VoucherType.fromMap(data));
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return result;
  }

  Future<VoucherType> getVoucherForm() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    VoucherType result = VoucherType.emptyData();
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'voucherForm/find/$dataBase',
      );

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var data in jsonResponse) {
          result = (VoucherType.fromMap(data));
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return result;
  }

  Future<bool> voucherFormAdd(data) async {
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
              'voucherForm/add/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 201) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> voucherFormEdit(data) async {
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
              'voucherForm/edit/$dataBase',
          data: json.encode(data),
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 201) {
        var jsonResponse = response.data;
        ret = jsonResponse['returnValue'] > 0 ? true : false;
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> voucherFormDelete(int id) async {
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
              'voucherForm/delete/$dataBase',
          queryParameters: {'id': id},
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 201) {
        // var jsonResponse = response.data;
        // ret = jsonResponse['returnValue'] > 0 ? true : false;
        if (response.data.toString() == "1") {
          ret = true;
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<List<VoucherType>> getVoucherTypeList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<VoucherType> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'voucherForm/All/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var ledger in jsonResponse) {
          _items.add(VoucherType.fromMap(ledger));
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

  Future<bool> checkDayStatus(String date) async {
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
              'sale/CheckDayStatus/$dataBase',
          queryParameters: {'date': date},
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        if (response.data['status']) {
          ret = true;
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> checkManualInvoiceNoStatus(String id) async {
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
              'sale/CheckManualInvoiceNo/$dataBase',
          queryParameters: {'id': id},
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        if (response.data['status']) {
          ret = true;
        }
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<String> getSalesInvoiceNo(int saleFormId, String statement) async {
    String ret =
        '0'; // SEntryNo, SalesFindLast, SalesFindFirst, SREntryNo, SalesReturnFindLast, SalesReturnFindFirst
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/getEntryNo/$dataBase',
          queryParameters: {
            'type': saleFormId,
            'fyId': currentFinancialYear.id,
            'statement': statement
          },
          options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200) {
        ret = response.data.toString();
      } else {
        debugPrint('Unexpected error occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<List<DataJson>> getUnregisteredSalesLedgerDataListLike(
      String like) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<DataJson> _items = [];
    try {
      Response response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getUnregisteredSalesLedgerListLike/$dataBase',
          queryParameters: {'name': like});

      if (response.statusCode == 200) {
        var data = response.data;
        if (data != null) {
          tempCustomerData = data;
          for (var map in data) {
            _items.add(DataJson(id: map['Ledcode'], name: map['LedName']));
          }
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

  Future<List<String>> getVehicleNameList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<String> _items = [];
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'sale/getVehicleNoList/$dataBase');
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var map in jsonResponse) {
          _items.add((map['evehicleno'] ?? ''));
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

  Future<List<dynamic>> getOtherDataDiscountByName(String percentage) async {
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
              'OtherRegistration/DiscountByName/$dataBase',
          queryParameters: {'name': percentage});
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

  Future<List<String>> getUnregisteredNameList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    List<String> _items = [];
    try {
      Response response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getUnregisteredSalesLedgerList/$dataBase');

      if (response.statusCode == 200) {
        var data = response.data;
        if (data != null) {
          tempCustomerData = data;
          for (var map in data) {
            _items.add(map['LedName']);
          }
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

  Future<CustomerModel> getNonCustomerDetail(String name) async {
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
              'Ledger/getNonCustomerDetail/$dataBase',
          queryParameters: {'name': name});
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

  Future<String> translateText(String sourceText) async {
    String translation = "";
    String from = 'en'; //'auto' for default
    String to = secondLanguage ?? 'en';
    try {
      final parameters = {
        'client': 'gtx',
        'sl': from,
        'tl': to,
        'dt': 't',
        'q': sourceText
      };
      String url = "https://translate.googleapis.com/translate_a/single";
      final response = await dio.get(url, queryParameters: parameters);
      if (response.statusCode == 200) {
        List<dynamic> jsonData = response.data;
        if (jsonData == null) {
          debugPrint('Error: Can\'t parse json data');
        }

        final sb = StringBuffer();
        for (var c = 0; c < jsonData[0].length; c++) {
          sb.write(jsonData[0][c][0]);
        }
        if (from == 'auto' && from != to) {
          from = jsonData[2] ?? from;
          if (from == to) {
            from = 'auto';
          }
        }
        translation = sb.toString();
      }
    } catch (ex) {
      ex.Message;
    }
    if (translation.length > 1) {
      translation = translation.substring(1);
    }
    return translation;
  }

  Future<dynamic> getBalance(
      int id, String statement, String type, String date, entryNo) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    dynamic _items = '0';
    try {
      Response response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'Ledger/getBalance/$dataBase',
          queryParameters: {
            'Id': id,
            'statement': statement,
            'type': type,
            'date': date,
            'entryNo': entryNo,
            'fyId': currentFinancialYear.id
          });

      if (response.statusCode == 200) {
        var data = response.data;
        if (data != null) {
          _items = data;
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

  Future<List<dynamic>> getSalesManReport(data) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.post(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'accounts_report/salesManReport/$dataBase',
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

  Future<bool> validateGstNo(String taxNumber) async {
    var _ip = await getPublicIp();
    var result = false;
    var authResponse = await authenticateGSTPortal(
        gstCommonUserName,
        gstCommonPassword,
        _ip,
        gstCommonClientId,
        gstCommonClientSecret,
        gstCommonGstNo);
    if (authResponse != null) {
      AuthClass authData = authResponse;
      if (authData.status_cd.toString() != "Sucess") {
        result = false;
      } else {
        await getGstResult(
                'SHERSOFT',
                taxNumber,
                gstCommonUserName,
                _ip,
                gstCommonClientId,
                gstCommonClientSecret,
                authData.data.AuthToken,
                gstCommonGstNo)
            .then((resultResponse) {
          if (resultResponse.status_cd == '1') {
            result = true;
          } else {
            result = false;
          }
        });
      }
    } else {
      result = false;
    }
    return result;
  }

  Future<List<dynamic>> findGroupRegistration(id) async {
    List<dynamic> ret = [];
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'groupRegister/find/$dataBase',
          queryParameters: {'id': id});

      if (response.statusCode == 200) {
        ret = response.data;
      } else {
        ret = [];
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> groupRegistrationAdd(data) async {
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
              'groupRegister/add/$dataBase',
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

  Future<bool> groupRegistrationEdit(data) async {
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
              'groupRegister/edit/$dataBase',
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

  Future<bool> groupRegistrationDelete(String id) async {
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
              'groupRegister/delete/$dataBase/$id');

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

  Future<List<DataJson>> getGroup() async {
    List<DataJson> ret = [];
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'groupRegister/$dataBase',
          queryParameters: {'statement': 'SelectGroup'});

      if (response.statusCode == 200) {
        if (response.data != null && response.data.isNotEmpty) {
          ret = DataJson.fromJsonList(response.data);
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<List<MainHeadsModel>> getGroupHeads() async {
    List<MainHeadsModel> ret = [];
    SharedPreferences pref = await SharedPreferences.getInstance();
    String dataBase = 'cSharp';
    dataBase = isEstimateDataBase
        ? (pref.getString('DBName') ?? "cSharp")
        : (pref.getString('DBNameT') ?? "cSharp");
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'groupRegister/$dataBase',
          queryParameters: {'statement': 'SelectParentHeads'});

      if (response.statusCode == 200) {
        if (response.data != null && response.data.isNotEmpty) {
          ret = MainHeadsModel.fromJsonList(response.data);
        }
      } else {
        debugPrint('Unexpected error Occurred!');
      }
    } catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      debugPrint(errorMessage.toString());
    }
    return ret;
  }

  Future<bool> renameGroup(var body) async {
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
              'groupRegister/rename/$dataBase',
          queryParameters: body,
          options: Options(headers: {'Content-Type': 'application/json'}));

      if (response.statusCode == 200) {
        if (response.data.toString() == "1") {
          ret = true;
        } else {
          ret = false; //
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

  Future<bool> addProductImageEComm(id, XFile image) async {
    String fileName = image.name;
    var imageFormat = 'jpg'.toLowerCase();
    try {
      var url = '$erpImageUploadUrl/upload-image/$id.$imageFormat';
      var stream = ht.ByteStream((image.openRead()));
      var length = await image.length();
      var uri = Uri.parse(url);
      var request = ht.MultipartRequest("POST", uri);
      var multipartFile =
          ht.MultipartFile('image', stream, length, filename: fileName);
      request.files.add(multipartFile);
      var response = await request.send();
      if (response.statusCode == 200) {
        //List<dynamic> data = response.data;
        return true;
      } else {
        debugPrint('Failed to load data');
        return false;
      }
    } catch (e) {
      final errorMessage = e.toString();
      debugPrint(errorMessage.toString());
      return false;
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

  factory DataJson.fromJsonX(Map<String, dynamic> json) {
    return DataJson(id: json['auto'], name: json['Name']);
  }

  static List<DataJson> fromJsonList(List list) {
    return list.map((item) => DataJson.fromJson(item)).toList();
  }

  static List<DataJson> fromJsonListX(List list) {
    return list.map((item) => DataJson.fromJsonX(item)).toList();
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
