import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sheraccerp/models/user_model.dart';
import 'package:sheraccerp/service/api_dio.dart';

class UserDataProvider {
  DioService api = DioService();

  final String _dataPath = "assets/data/users.json";
  late List<UserModel> users;

  Future<List<UserModel>> loadUserData() async {
    var dataString = await loadAsset();
    Map<String, dynamic> jsonUserData = jsonDecode(dataString);
    users = UserModel.fromJson(jsonUserData['users']) as List<UserModel>;
    print('done loading user!' + jsonEncode(users));
    return users;
  }

  Future<String> loadAsset() async {
    return await Future.delayed(Duration(seconds: 10), () async {
      return await rootBundle.loadString(_dataPath);
    });
  }
}
