// @dart = 2.7
import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';

class SalesReturnList extends StatefulWidget {
  const SalesReturnList({Key key}) : super(key: key);

  @override
  _SalesReturnListState createState() => _SalesReturnListState();
}

class _SalesReturnListState extends State<SalesReturnList> {
  String fromDate;
  String toDate;
  bool loadReport = false;
  DateTime now = DateTime.now();
  DioService api = DioService();
  var itemId,
      itemName,
      customer,
      mfr,
      category,
      subCategory,
      location = {'id': 1, 'name': defaultLocation},
      salesMan,
      project,
      taxGroup;
  final controller = ScrollController();
  double offset = 0;
  List<dynamic> resultData = [];
  var dropDownBranchId;
  List<TypeItem> dropdownItemsType = [
    TypeItem(1, 'Summary'),
    TypeItem(2, 'ItemWise')
  ];
  int valueType = 1;

  @override
  void initState() {
    super.initState();
    fromDate = DateFormat('dd-MM-yyyy').format(now);
    toDate = DateFormat('dd-MM-yyyy').format(now);

    if (locationList.isNotEmpty) {
      dropDownBranchId = locationList
          .where((element) => element.value == defaultLocation)
          .map((e) => e.key)
          .first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {
                  setState(
                    () {},
                  );
                }),
          ],
          title: const Text('SalesReturn Report'),
        ),
        body: loadReport ? reportView() : selectData());
  }

  reportView() {
    controller.addListener(onScroll);
    var statement = dropdownItemsType
        .where((TypeItem element) => element.id == valueType)
        .map((e) => e.name)
        .first;
    var statementType = statement == 'Summary'
        ? 'SalesReturn_Summery'
        : statement == 'ItemWise'
            ? 'SalesReturn_ItemWise'
            : 'SalesReturn_Summery';

    var dataJson = '[' +
        json.encode({
          'statementType': statementType.isEmpty ? '' : statementType,
          'sDate': fromDate.isEmpty ? '' : formatYMD(fromDate),
          'eDate': toDate.isEmpty ? '' : formatYMD(toDate),
          'itemId': itemId != null ? itemId['id'] : '0',
          'customerId': customer != null ? customer['id'] : '0',
          'mfr': mfr != null ? mfr['id'] : '',
          'category': category != null ? category['id'] : '0',
          'subcategory': subCategory != null ? subCategory['id'] : '0',
          'location': dropDownBranchId != null ? location['id'] ?? '0' : '0',
          'project': project != null ? project['id'] : '0',
          'salesMan': salesMan != null ? salesMan['id'] : '0'
        }) +
        ']';

    return FutureBuilder<List<dynamic>>(
      future: api.getSalesReturnReport(dataJson),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            var col = data[0].keys.toList();
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                        child: Text(
                      statement + ' Date: From ' + fromDate + ' To ' + toDate,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.grey.shade200),
                        border:
                            TableBorder.all(width: 1.0, color: Colors.black),
                        columnSpacing: 12,
                        dataRowHeight: 20,
                        headingRowHeight: 30,
                        columns: [
                          for (int i = 0; i < col.length; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  col[i],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                        rows: data
                            .map(
                              (values) => DataRow(
                                cells: [
                                  for (int i = 0; i < values.length; i++)
                                    DataCell(
                                      Align(
                                        alignment: ComSettings.oKNumeric(
                                          values[col[i]] != null
                                              ? values[col[i]].toString()
                                              : '',
                                        )
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Text(
                                          values[col[i]] != null
                                              ? values[col[i]].toString()
                                              : '',
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                          // style: TextStyle(fontSize: 6),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    // SizedBox(height: 500),
                  ],
                ),
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  SizedBox(height: 20),
                  Text('No Data Found..')
                ],
              ),
            );
          }
        } else if (snapshot.hasError) {
          return AlertDialog(
            title: const Text(
              'An Error Occurred!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
              ),
            ),
            content: Text(
              "${snapshot.error}",
              style: const TextStyle(
                color: Colors.blueAccent,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
        // By default, show a loading spinner.
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('This may take some time..')
            ],
          ),
        );
      },
    );
  }

  selectData() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                elevation: 0.5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text(
                      'From : ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    InkWell(
                      child: Text(
                        fromDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      onTap: () => _selectDate('f'),
                    ),
                    const Text(
                      'To : ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    InkWell(
                      child: Text(
                        toDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      onTap: () => _selectDate('t'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Card(
                elevation: 2,
                child: DropDownSettingsTile<int>(
                  title: 'Branch',
                  settingKey: 'key-dropdown-default-location-view',
                  values: locationList.isNotEmpty
                      ? {for (var e in locationList) e.key + 1: e.value}
                      : {
                          2: '',
                        },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-default-location-view: $value');
                    dropDownBranchId = value - 1;
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Type : '),
                  DropdownButton(
                    value: valueType,
                    items: dropdownItemsType.map((TypeItem item) {
                      return DropdownMenuItem<int>(
                        child: Text(item.name),
                        value: item.id,
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        valueType = value;
                      });
                    },
                  ),
                ],
              ),
              // Divider(),
              TextButton(
                onPressed: () {
                  setState(() {
                    loadReport = true;
                  });
                },
                child: const Text('Show'),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(kPrimaryColor),
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
                ),
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/ItemCode'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Select Item Code"),
                onChanged: (dynamic data) {
                  itemId = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/itemName'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Select Item Name"),
                onChanged: (dynamic data) {
                  itemName = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/customer'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Select Customer"),
                onChanged: (dynamic data) {
                  customer = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/manufacture'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Select Item MFR"),
                onChanged: (dynamic data) {
                  mfr = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/category'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Select Category"),
                onChanged: (dynamic data) {
                  category = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/subCategory'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Select SubCategory"),
                onChanged: (dynamic data) {
                  subCategory = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/salesMan'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Select SalesMan"),
                onChanged: (dynamic data) {
                  salesMan = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/project'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Select Project"),
                onChanged: (dynamic data) {
                  project = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/taxGroup'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Select TaxGroup"),
                onChanged: (dynamic data) {
                  taxGroup = data;
                },
                showSearchBox: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future _selectDate(String type) async {
    DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => {
            if (type == 'f')
              {fromDate = DateFormat('dd-MM-yyyy').format(picked)}
            else
              {toDate = DateFormat('dd-MM-yyyy').format(picked)}
          });
    }
  }

  String formatYMD(value) {
    var dateTime = DateFormat("dd-MM-yyyy").parse(value.toString());
    return DateFormat("yyyy-MM-dd").format(dateTime);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onScroll() {
    setState(() {
      offset = (controller.hasClients) ? controller.offset : 0;
    });
  }
}

class TypeItem {
  int id;
  String name;
  TypeItem(this.id, this.name);
}
