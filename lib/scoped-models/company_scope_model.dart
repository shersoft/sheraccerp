// @dart = 2.11

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/shared/constants.dart';

mixin CompanyScopeModel on Model {
  MainModel model;
  CompanyInformation _company;
  final List<FinancialYear> _financialYear = [];
  final List<CompanySettings> _settings = [];
  var dio = Dio();

  CompanyInformation getCompanySettings() {
    return _company;
  }

  List<CompanySettings> getSettings() {
    return _settings;
  }

  List<FinancialYear> getFinancialYear() {
    return _financialYear;
  }

  getCompanySettingsAll(cId) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String code = pref.get("DBName") ?? 'csharp';
    try {
      final response = await dio.get(
          pref.getString('api' ?? '127.0.0.1:80/api/') +
              apiV +
              'companySettings/$cId',
          queryParameters: {'code': code});
      if (response.statusCode == 200) {
        List<dynamic> _data = response.data;
        _company = CompanyInformation.fromJson(_data[0][0]);
        for (var data in _data[1]) {
          _settings.add(CompanySettings.fromJson(data));
        }
        for (var data in _data[2]) {
          _financialYear.add(FinancialYear.fromJson(data));
        }
        if (_financialYear.isNotEmpty) {
          currentFinancialYear =
              _financialYear.firstWhere((element) => element.status == 1);
        }
        var defL =
            ComSettings.getValue('DEFAULT LOCATION', _settings).toString();
        defaultLocation = defL.isNotEmpty ? defL : defaultLocation;
        notifyListeners();
      } else {
        _company = null;
        throw Exception('Failed to load data');
      }
    } on DioError {
      // print(e.message);
    }
  }
}
