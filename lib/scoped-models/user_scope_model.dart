// @dart = 2.11
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/user_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/shared/constants.dart';

mixin UserScopeModel on Model {
  bool _isAuthenticated = false;
  bool _isRole = false;
  MainModel model;
  UserModel _user;

  bool get isAuthenticated {
    return _isAuthenticated;
  }

  bool get isRole {
    return _isRole;
  }

  UserModel get user {
    return _user;
  }

  void set user(users) {
    _user = users;
    notifyListeners();
  }

  loggedInUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = (prefs.getString('userId') ?? "");
    if (token != null) {
      _isAuthenticated = true;
      notifyListeners();
    } else {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  roleUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool token = prefs.getBool('regId');
    if (token != null) {
      _isRole = token;
      notifyListeners();
    } else {
      _isRole = false;
      notifyListeners();
    }
  }

  getUser(userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var dio = Dio();
    final response = await dio.get(
        prefs.getString('api' ?? '127.0.0.1:80/api/') + apiV + 'User/$userId');
    if (response.statusCode == 200) {
      List<dynamic> _data = jsonDecode(response.data);
      _user = UserModel.fromJson(_data[0]);
      notifyListeners();
    } else {
      _user = null;
      throw Exception('Failed to load album');
    }
  }
}
