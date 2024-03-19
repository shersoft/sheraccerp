// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:sheraccerp/app_settings_page.dart';

class SalesManSettings extends StatefulWidget {
  const SalesManSettings({Key key}) : super(key: key);

  @override
  _SalesManSettingsState createState() => _SalesManSettingsState();
}

class _SalesManSettingsState extends State<SalesManSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: WillPopScope(
      child: const AppSettings(),
      onWillPop: onBackPress,
    ));
  }

  Future<bool> onBackPress() {
    Navigator.pushNamedAndRemoveUntil(context, '/', ModalRoute.withName('/'));
    return Future.value(false);
  }
}
