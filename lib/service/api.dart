// @dart = 2.11
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/company_user.dart';
import 'package:sheraccerp/models/form_model.dart';
import 'package:sheraccerp/models/sale_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/models/api_error.dart';
import 'package:sheraccerp/models/company.dart';

Future<ApiResponse> authenticate(String customerId) async {
  ApiResponse _apiResponse = ApiResponse();
  var dio = Dio(BaseOptions(maxRedirects: 5));

  SharedPreferences pref = await SharedPreferences.getInstance();
  try {
    final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'company/Authenticate/$customerId');

    switch (response.statusCode) {
      case 200:
        List<dynamic> output = response.data;
        if (output.isNotEmpty) {
          Map<dynamic, dynamic> responseBody = output[0];
          _apiResponse.Data = Company.fromJson(responseBody);
        } else {
          _apiResponse.ApiError = ApiError(error: "Invalid Customer ID");
        }
        break;
      case 401:
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
      default:
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
    }
  } catch (e) {
    debugPrint('io error..' + e.message);
    final errorMessage = DioExceptions.fromDioError(e).toString();
    _apiResponse.ApiError = ApiError(error: "$errorMessage. Please retry");
  }
  return _apiResponse;
}

Future<ApiResponse> getFirmList(String customerCode) async {
  ApiResponse _apiResponse = ApiResponse();
  var dio = Dio(BaseOptions(maxRedirects: 5));

  SharedPreferences pref = await SharedPreferences.getInstance();
  try {
    final response = await dio.get(pref
            .getString('api' ?? '127.0.0.1:80/api/') +
        apiV +
        'company/getFirmList/${Uri.encodeComponent(customerCode).toString()}');

    switch (response.statusCode) {
      case 200:
        List<dynamic> output = response.data;
        if (output.isNotEmpty) {
          List<FirmModel> data = [];
          for (var json in output) {
            //Map<dynamic, dynamic> responseBody = output[0];
            data.add(FirmModel.fromJson(json));
          }
          _apiResponse.Data = data;
        } else {
          _apiResponse.ApiError = ApiError(error: "Invalid Customer Code");
        }
        break;
      case 401:
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
      default:
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
    }
  } catch (e) {
    debugPrint('io error..' + e.message + e.response.toString());
    _apiResponse.ApiError = ApiError(error: "Server error. Please retry");
  }
  return _apiResponse;
}

Future<ApiResponse> authenticateCompany(
    String username, String password) async {
  ApiResponse _apiResponse = ApiResponse();
  var dio = Dio(BaseOptions(maxRedirects: 5));

  SharedPreferences pref = await SharedPreferences.getInstance();
  try {
    final response = await dio.get(pref
            .getString('api' ?? '127.0.0.1:80/api/') +
        apiV +
        'company/Login/${Uri.encodeComponent(username).toString()}/${Uri.encodeComponent(password).toString()}');

    switch (response.statusCode) {
      case 200:
        List<dynamic> output = response.data;
        if (output.isNotEmpty) {
          Map<dynamic, dynamic> responseBody = output[0];
          _apiResponse.Data = Company.fromJson(responseBody);
        } else {
          _apiResponse.ApiError =
              ApiError(error: "Invalid UserName or Password");
        }
        break;
      case 401:
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
      default:
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
    }
  } catch (e) {
    debugPrint('io error..' + e.message);
    _apiResponse.ApiError = ApiError(error: "Server error. Please retry");
  }
  return _apiResponse;
}

Future<ApiResponse> authenticateUser(
    String username, String password, String regId) async {
  ApiResponse _apiResponse = ApiResponse();
  String deviceId = '0'; //await _commonService.getDeviceId();
  SharedPreferences pref = await SharedPreferences.getInstance();
  var dio = Dio(BaseOptions(maxRedirects: 5));
  try {
    final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'companyUser/Login/' +
            Uri.encodeComponent(username).toString() +
            '/' +
            Uri.encodeComponent(password).toString() +
            '/' +
            regId +
            '/' +
            Uri.encodeComponent(deviceId).toString());

    switch (response.statusCode) {
      case 200:
        List<dynamic> output = response.data;
        if (output.isNotEmpty) {
          Map<dynamic, dynamic> responseBody = output[0];
          _apiResponse.Data = CompanyUser.fromJson(responseBody);
        } else {
          _apiResponse.ApiError =
              ApiError(error: "Invalid UserName or Password");
        }
        break;
      case 401:
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
      default:
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
    }
  } catch (e) {
    debugPrint('io error..' + e.message);
    _apiResponse.ApiError = ApiError(error: "Server error. Please retry");
  }
  return _apiResponse;
}

Future<ApiResponse> createUser(
    String username, String password, String regId) async {
  ApiResponse _apiResponse = ApiResponse();
  String deviceId = '0'; //await _commonService.getDeviceId();
  // _commonService.getDeviceId().then((id) {
  //   deviceId = id;
  // });
  var dio = Dio(BaseOptions(maxRedirects: 5));
  SharedPreferences pref = await SharedPreferences.getInstance();

  try {
    final response = await dio.post(
        pref.getString('api' ?? '127.0.0.1:80/api/') + '' + 'companyUser/add',
        data: json.encode({
          'registrationId': regId,
          'username': username,
          'password': password,
          'active': '0',
          'deviceId': deviceId,
          'userType': 'SalesMan'
        }),
        options: Options(headers: {'Content-Type': 'application/json'}));

    switch (response.statusCode) {
      case 200:
        _apiResponse.Data = null;
        break;
      case 201:
        List<dynamic> output = response.data;
        var output1 = output[0];
        if (output1[0]['error'].toString() == 'Saved') {
          _apiResponse.Data = null;
        } else {
          List<dynamic> output = response.data;
          var output1 = output[0];
          Map<dynamic, dynamic> responseBody = output1[0];
          _apiResponse.ApiError = ApiError.fromJson(responseBody);
        }
        break;
      case 401:
        List<dynamic> output = response.data;
        var output1 = output[0];
        Map<dynamic, dynamic> responseBody = output1[0];
        _apiResponse.ApiError = ApiError.fromJson(responseBody);
        break;
      default:
        List<dynamic> output = response.data;
        var output1 = output[0];
        Map<dynamic, dynamic> responseBody = output1[0];
        _apiResponse.ApiError = ApiError.fromJson(responseBody);
        break;
    }
  } catch (e) {
    debugPrint('io error..' + e.message);
    _apiResponse.ApiError = ApiError(error: "Server error. Please retry");
  }
  return _apiResponse;
}

Future<ApiResponse> getCompanyDetails(String regId) async {
  ApiResponse _apiResponse = ApiResponse();
  var dio = Dio(BaseOptions(maxRedirects: 5));
  SharedPreferences pref = await SharedPreferences.getInstance();
  try {
    final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') + apiV + 'company/$regId');

    switch (response.statusCode) {
      case 200:
        List<dynamic> output = response.data;
        if (output.isNotEmpty) {
          Map<dynamic, dynamic> responseBody = output[0];
          _apiResponse.Data = CompanyUser.fromJson(responseBody);
        } else {
          _apiResponse.ApiError = ApiError(error: "Invalid UserName");
        }
        break;
      case 401:
        // print((_apiResponse.ApiError as ApiError).error);
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
      default:
        // print((_apiResponse.ApiError as ApiError).error);
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
    }
  } catch (e) {
    debugPrint('io error..' + e.message);
    _apiResponse.ApiError = ApiError(error: "Server error. Please retry");
  }
  return _apiResponse;
}

Future<ApiResponse> getUserDetails(String userId) async {
  ApiResponse _apiResponse = ApiResponse();
  var dio = Dio(BaseOptions(maxRedirects: 5));
  SharedPreferences pref = await SharedPreferences.getInstance();
  try {
    final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'companyUser/$userId');

    switch (response.statusCode) {
      case 200:
        List<dynamic> output = response.data;
        if (output.isNotEmpty) {
          Map<dynamic, dynamic> responseBody = output[0];
          _apiResponse.Data = CompanyUser.fromJson(responseBody);
        } else {
          _apiResponse.ApiError = ApiError(error: "Invalid UserName");
        }
        break;
      case 401:
        // print((_apiResponse.ApiError as ApiError).error);
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
      default:
        // print((_apiResponse.ApiError as ApiError).error);
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
    }
  } catch (e) {
    debugPrint('io error..' + e.message);
    _apiResponse.ApiError = ApiError(error: "Server error. Please retry");
  }
  return _apiResponse;
}

Future<ApiResponse> getDashDetails(String userId) async {
  ApiResponse _apiResponse = ApiResponse();
  var dio = Dio(BaseOptions(maxRedirects: 5));
  SharedPreferences pref = await SharedPreferences.getInstance();
  try {
    final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'CompanyUser/get?id=$userId');

    switch (response.statusCode) {
      case 200:
        List<dynamic> output = response.data;
        if (output.isNotEmpty) {
          Map<dynamic, dynamic> responseBody = output[0];
          _apiResponse.Data = CompanyUser.fromJson(responseBody);
        } else {
          _apiResponse.ApiError =
              ApiError(error: "Invalid UserName or Password");
        }
        break;
      case 401:
        // print((_apiResponse.ApiError as ApiError).error);
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
      default:
        // print((_apiResponse.ApiError as ApiError).error);
        _apiResponse.ApiError = ApiError.fromJson(json.decode(response.data));
        break;
    }
  } catch (e) {
    final errorMessage = DioExceptions.fromDioError(e).toString();
    _apiResponse.ApiError = ApiError(error: "$errorMessage. Please retry");
  }
  return _apiResponse;
}

Future<List<CompanyUser>> getCompanyUserList(String regId) async {
  var dio = Dio(BaseOptions(maxRedirects: 5));
  SharedPreferences pref = await SharedPreferences.getInstance();
  List<CompanyUser> list = [];
  regId = regId.isNotEmpty ? regId : '0';

  try {
    final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'companyUserList/$regId');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data != null) {
        for (var json in data) {
          list.add(CompanyUser.fromJson(json));
        }
        return list;
      }
      return list;
    } else {
      return list;
      // throw Exception('Failed to load internet');
    }
  } catch (ex) {
    debugPrint(ex.toString());
    return list;
  }
}

Future<List<FormModel>> getCompanyUserControlList(String userId) async {
  var dio = Dio(BaseOptions(maxRedirects: 5));
  SharedPreferences pref = await SharedPreferences.getInstance();
  List<FormModel> list = [];

  try {
    final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'companyUserControlList/$userId');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data != null) {
        for (var json in data) {
          list.add(FormModel.fromJson(json));
        }
        return list;
      }
      return list;
    } else {
      return list;
      // throw Exception('Failed to load internet');
    }
  } catch (ex) {
    debugPrint(ex.toString());
    return list;
  }
}

Future<List<FormModel>> getCompanyUserControlForms() async {
  var dio = Dio(BaseOptions(maxRedirects: 5));
  SharedPreferences pref = await SharedPreferences.getInstance();
  List<FormModel> list = [];

  try {
    final response = await dio.get(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'companyUserControlForms');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data != null) {
        for (var json in data) {
          list.add(FormModel.fromJson(json));
        }
        return list;
      }
      return list;
    } else {
      return list;
      // throw Exception('Failed to load internet');
    }
  } catch (ex) {
    debugPrint(ex.toString());
    return list;
  }
}

Future<bool> addUserControl(data) async {
  var dio = Dio(BaseOptions(maxRedirects: 5));
  bool ret = false;
  SharedPreferences pref = await SharedPreferences.getInstance();
  try {
    final response = await dio.post(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            'companyUser/addUserControl',
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
    }
  } catch (e) {
    debugPrint(e.toString());
    final errorMessage = DioExceptions.fromDioError(e).toString();
  }
  return ret;
}

Future<bool> changeCompanyUserPassword(var body) async {
  bool ret = false;
  var dio = Dio(BaseOptions(maxRedirects: 5));
  SharedPreferences pref = await SharedPreferences.getInstance();
  try {
    final response = await dio.put(
        pref.getString('api' ?? '127.0.0.1:80/api/') +
            apiV +
            '/companyUser/changePassword',
        data: json.encode(body),
        options: Options(headers: {'Content-Type': 'application/json'}));

    if (response.statusCode == 200) {
      ret = true;
    } else {
      ret = false;
    }
  } catch (ex) {
    debugPrint(ex.toString());
    ret = false;
  }
  return ret;
}

class ApiResponse {
  // _data will hold any response converted into
  // its own object. For example user.
  Object _data;
  // _apiError will hold the error object
  Object _apiError;

  Object get Data => _data;
  set Data(Object data) => _data = data;

  Object get ApiError => _apiError as Object;
  set ApiError(Object error) => _apiError = error;

  final sales = BehaviorSubject<List<SaleModel>>();

  dispose() {
    sales.close();
  }
}
