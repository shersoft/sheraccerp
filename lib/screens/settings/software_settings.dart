import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';

import '../../widget/loading.dart';

class SoftwareSettings extends StatefulWidget {
  const SoftwareSettings({Key? key}) : super(key: key);

  @override
  State<SoftwareSettings> createState() => _SoftwareSettingsState();
}

class _SoftwareSettingsState extends State<SoftwareSettings> {
  List<CompanySettings> _settingsList = [];
  List<CompanySettings> settingsData = [];
  List<CompanySettings> settingsDisplayList = [];
  DioService dio = DioService();
  late CompanyInformation _companySettings;
  List<CompanySettings> _settings = [];
  String toolBarSale = '',
      cashAC = '',
      stockValue = '',
      defaultLocation = '',
      decimalPoint = '',
      boxColor = '',
      toolBarColor = '',
      backhand = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    settingsDisplayList = [];
    _settingsList = [];

    _companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    _settings = ScopedModel.of<MainModel>(context).getSettings();

    toolBarSale =
        ComSettings.getValue('TOOLBAR SALES', _settings).toString().trim() ??
            '1';
    cashAC =
        ComSettings.getValue('CASH A/C', _settings).toString().trim() ?? 'CASH';
    decimalPoint =
        ComSettings.getValue('DECIMAL', _settings).toString().trim() ?? '2';
    boxColor = ComSettings.getValue('BOXCOLOR', _settings).toString().trim() ??
        '-8323200';
    stockValue =
        ComSettings.getValue('STOCK METHODE', _settings).toString().trim() ??
            'AVERAGE VALUE';
    defaultLocation =
        ComSettings.getValue('DEFAULT LOCATION', _settings).toString().trim() ??
            'SHOP';
    toolBarColor =
        ComSettings.getValue('TOOLBARCOLOR', _settings).toString().trim() ??
            '16777215';
    toolBarColor = toolBarColor.isEmpty ? '16777215' : toolBarColor;

    load();
  }

  load() {
    if (_settings.isNotEmpty && _settings.first.id > 0) {
      setState(() {
        _settingsList.addAll(_settings);
        settingsData = _settingsList;
        settingsDisplayList = _settingsList;
      });
    } else {
      dio.getSoftwareSettings().then((value) {
        setState(() {
          _settingsList.addAll(value);
          settingsData = _settingsList;
          settingsDisplayList = _settingsList;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  settingsDisplayList = _settingsList;
                });
              },
              icon: const Icon(Icons.filter_alt)),
          IconButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  saveData();
                });
              },
              icon: const Icon(Icons.save)),
        ], title: const Text('General')),
        body: _settingsList.isEmpty ? const Loading() : loadData());
  }

  loadData() {
    return ListView.builder(
        itemCount: settingsDisplayList.length,
        itemBuilder: (BuildContext context, int index) {
          return index == 0 ? _searchBar() : _listItem(index - 1);
        });
  }

  _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: const InputDecoration(
            border: OutlineInputBorder(), label: Text('Search...')),
        onChanged: (text) {
          text = text.toLowerCase();
          setState(() {
            settingsDisplayList = _settingsList.where((item) {
              var itemName = item.name.toString().toLowerCase();
              return itemName.contains(text);
            }).toList();
          });
        },
      ),
    );
  }

  _listItem(int index) {
    CompanySettings item = settingsDisplayList[index];
    // debugPrint(item.toJson());
    return Card(
      elevation: 2,
      child: Column(children: [
        CheckboxListTile(
          title: Text(item.name),
          value: item.status == 1 ? true : false,
          onChanged: (bool? val) {
            setState(() => item.status = val != null
                ? val
                    ? 1
                    : 0
                : 0);
            updateItem(item);
          },
        ),
      ]),
    );
  }

  updateItem(CompanySettings item) {
    int index = settingsData.indexWhere((element) => element.name == item.name);
    settingsData[index] = item;
  }

  saveData() {
    final body = {
      'toolBarSale': toolBarSale,
      'cashAC': cashAC,
      'stockValue': stockValue,
      'defaultLocation': defaultLocation,
      'decimalPoint': decimalPoint,
      'boxColor': boxColor,
      'toolBarColor': toolBarColor,
      'backhand': backhand,
      'data': settingsData
    };
    dio.updateGeneralSetting(body).then((value) {
      if (value) {
        ScopedModel.of<MainModel>(context).setSettings(settingsData);
        showInSnackBar('Settings Saved');
      } else {
        showInSnackBar('Error');
      }
    });
  }

  void showInSnackBar(String value) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
