import 'package:flutter/material.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/service/api_dio.dart';

import '../../widget/loading.dart';

class SoftwareSettings extends StatefulWidget {
  const SoftwareSettings({Key? key}) : super(key: key);

  @override
  State<SoftwareSettings> createState() => _SoftwareSettingsState();
}

class _SoftwareSettingsState extends State<SoftwareSettings> {
  List<CompanySettings> _settingsList = [];
  List<CompanySettings> settingsDisplayList = [];
  DioService dio = DioService();

  @override
  void initState() {
    super.initState();
    settingsDisplayList = [];
    _settingsList = [];
    load();
  }

  load() {
    dio.getSoftwareSettings().then((value) {
      setState(() {
        _settingsList.addAll(value);
        settingsDisplayList = _settingsList;
      });
    });
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
                  //
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
    return Card(
      elevation: 2,
      child: Column(
          children: settingsDisplayList
              .map(
                (CompanySettings item) => CheckboxListTile(
                  title: Text(item.name),
                  value: item.status == 1 ? true : false,
                  onChanged: (bool? val) {
                    setState(() => item.status = val != null
                        ? val
                            ? 1
                            : 0
                        : 0);
                  },
                ),
              )
              .toList()),
    );
  }
}
