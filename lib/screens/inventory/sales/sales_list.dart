// @dart = 2.7
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:csv/csv.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:sheraccerp/models/option_rate_type.dart';

import 'package:sheraccerp/models/other_registrations.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/screens/inventory/sales/sale.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';

import 'package:sheraccerp/widget/loading.dart';

class SalesList extends StatefulWidget {
  const SalesList({Key key}) : super(key: key);

  @override
  _SalesListState createState() => _SalesListState();
}

class _SalesListState extends State<SalesList> {
  String fromDate;
  var _data;
  int menuId = 0;
  String toDate;
  bool loadReport = false,
      stockValuation = false,
      isType = false,
      classic = true,
      newMode = false,
      isAdminUser = false;
  List<String> tableColumn = [];
  DateTime now = DateTime.now();
  DioService api = DioService();
  var itemId,
      itemName,
      customer,
      supplier,
      mfr,
      category,
      subCategory,
      locationId,
      salesMan,
      project,
      taxGroup;
  final controller = ScrollController();
  double offset = 0;
  List<dynamic> resultData = [];
  List<SalesType> salesTypeDataList = [];
  List<TypeItem> dropdownItemsType = [
    TypeItem(1, 'Daily'),
    TypeItem(2, 'Summary'),
    TypeItem(3, 'Sales Daily'),
    TypeItem(4, 'Sales ItemWise'),
    TypeItem(5, 'Item Summary'),
    TypeItem(6, 'P&L Summary'),
    TypeItem(7, 'P&L ItemWise'),
    TypeItem(8, 'P&L ItemSimple'),
    TypeItem(9, 'Packing Slip'),
    TypeItem(10, 'Customer Summary'),
    TypeItem(11, 'Daily Sales Tax Report'),
    TypeItem(12, 'IVA Report'),
    TypeItem(13, 'Customer Summery Invoice'),
    TypeItem(14, 'Counter Wise Report'),
    TypeItem(15, 'Replace P&L ItemWise'),
    TypeItem(16, 'Simple P&l Report'),
    TypeItem(17, 'Scheme Report'),
    TypeItem(18, 'ItemWise Monthly'),
    TypeItem(19, 'P&L ItemWise New'),
    TypeItem(20, 'Customer Address'),
    TypeItem(21, 'Insurance Report'),
    TypeItem(22, 'Sales Qty Total'),
    TypeItem(23, 'Location Wise Summary'),
    TypeItem(24, 'Location Wise Qty Total'),
    // TypeItem(25, 'ItemWise Rate Analysis'),
    // TypeItem(26, 'ItemWise Profit Analysis'),
    // TypeItem(27, 'Sales E-Invoice Report'),
    // TypeItem(28, 'Month Wise Item Summery'),
    // TypeItem(29, 'Supplier Wise Sales Total'),
    // TypeItem(30, 'Sales ItemWise Customer Grouping'),
    // TypeItem(31, 'Sales Summery DC'),
    // TypeItem(32, 'Sales Monthly'),
    // TypeItem(33, 'DeliveryNote Summery')
  ];
  int valueType = 1;
  String area = '0', route = '0';
  dynamic areaModel, routeModel;
  DataJson location;
  // List<ItemDataModel> areaDataList = [];
  bool isBranchSelected = false;

  @override
  void initState() {
    super.initState();
    fromDate = DateFormat('dd-MM-yyyy').format(now);
    toDate = DateFormat('dd-MM-yyyy').format(now);

    // if (locationList.isNotEmpty) {
    //   dropDownBranchId = locationList
    //       .where((element) => element.value == defaultLocation)
    //       .map((e) => e.key)
    //       .first;
    // }
    salesTypeDataList = salesTypeList;

    isAdminUser =
        companyUserData.userType.toUpperCase() == 'ADMIN' ? true : false;
    if (!isAdminUser) {
      locationId = ComSettings.appSettings(
              'int', 'key-dropdown-default-location-view', 2) -
          1;
      OtherRegistrationModel otherData = otherRegLocationList.firstWhere(
          (element) => element.id == locationId,
          orElse: () => OtherRegistrationModel(
              add1: '',
              add2: '',
              add3: '',
              description: '',
              email: '',
              id: locationId,
              name: defaultLocation,
              type: ''));
      location = DataJson(id: otherData.id, name: otherData.name);

      // for (OtherRegistrationModel element in otherRegAreaList) {
      //   areaDataList.add(
      //       ItemDataModel(id: element.id, name: element.name, status: true));
      // }
      // api.getCityListBySalesMan(salesMan).then(
      //   (valueResult) {
      //     if (valueResult.isNotEmpty) {
      //       areaDataList.clear();
      //       for (Map element in valueResult) {
      //         areaDataList.add(ItemDataModel(
      //             id: element['id'],
      //             name: (element['name'] ?? ''),
      //             status: element['id'] == 0 ? false : true));
      //       }
      //     }
      //   },
      // );

      int salesManId = ComSettings.appSettings(
              'int', 'key-dropdown-default-salesman-view', 1) -
          1;
      if (salesManId > 0) {
        salesMan = DataJson(id: salesManId, name: '');
      }
    }
  }

  void itemChange(bool val, int index) {
    setState(() {
      salesTypeDataList[index].stock = val;
    });
  }

  List<Widget> _getChildren(data) {
    return List<Widget>.generate(
        data.length,
        (index) => CheckboxListTile(
            value: data[index].stock,
            title: Text(data[index].name),
            onChanged: (bool value) {
              itemChange(value, index);
            }));
  }

  @override
  Widget build(BuildContext context) {
    final routes =
        ModalRoute.of(context).settings.arguments as Map<String, String>;
    var title = routes != null ? routes['title'].toString() : 'Sales';
    isType = title == 'Sales' ? true : false;
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {
                    loadReport = false;
                    isLoadingData = false;
                    valueMore = false;
                    lastRecord = false;
                    page = 1;
                    pageTotal = 0;
                    totalRecords = 0;
                    dataDisplay = [];
                    dataDisplayHead = [];
                    itemId = null;
                    itemName = null;
                    customer = null;
                    mfr = null;
                    category = null;
                    subCategory = null;
                    locationId = null;
                    project != null;
                    salesMan != null;
                    taxGroup = null;
                    stockValuation = false;
                    isBranchSelected = false;
                    supplier = null;
                    area = '0';
                    route = '0';
                  });
                },
                icon: const Icon(Icons.filter_alt)),
            PopupMenuButton(
              icon: const Icon(Icons.share_rounded),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  child: Text('PDF'),
                  value: 1,
                ),
                const PopupMenuItem(
                  child: Text('CSV'),
                  value: 2,
                ),
              ],
              onSelected: (menuId) {
                setState(() {
                  // debugPrint(menuId.toString());
                  if (menuId == 1) {
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      _createPDF(title + ' Date :' + fromDate + ' - ' + toDate)
                          .then((value) =>
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => PDFScreen(
                                        pathPDF: value,
                                        subject: title +
                                            ' Date :' +
                                            fromDate +
                                            ' - ' +
                                            toDate,
                                        text: 'this is ' +
                                            title +
                                            ' Date :' +
                                            fromDate +
                                            ' - ' +
                                            toDate,
                                      ))));
                    });
                  } else if (menuId == 2) {
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      _createCSV(title + ' Date :' + fromDate + ' - ' + toDate)
                          .then((value) {
                        var text = 'this is ' +
                            title +
                            ' Date :' +
                            fromDate +
                            ' - ' +
                            toDate;
                        var subject =
                            title + ' Date :' + fromDate + ' - ' + toDate;
                        List<String> paths = [];
                        paths.add(value);
                        urlFileShare(context, text, subject, paths);
                      });
                    });
                  }
                });
              },
            )
          ],
          title: Text(title + ' Report'),
        ),
        body: loadReport ? reportView(title) : selectData(title));
  }

  reportView(title) {
    controller.addListener(onScroll);
    List<dynamic> dataSType = [];
    if (isType) {
      title = dropdownItemsType
          .where((TypeItem element) => element.id == valueType)
          .map((e) => e.name)
          .first;
    }
    var statementType = title == 'BillWise' ||
            title == 'Summary' ||
            title == 'Sales'
        ? 'Sales_Summery'
        : title == 'Sales ItemWise'
            ? 'Sales_ItemWise'
            : title == 'Daily' || title == 'Sales Daily'
                ? 'Sales_Daily'
                : title == 'P&L Summary'
                    ? 'P_l_Summery'
                    : title == 'P&L ItemWise'
                        ? 'P_l_ItemWise_New'
                        : title == 'P&L ItemSimple'
                            ? 'P_l_ItemSimple'
                            : title == 'Item Summary'
                                ? 'Item_Summery'
                                : title == 'Packing Slip'
                                    ? 'Packing_Slip'
                                    : title == 'Customer Summary'
                                        ? 'Sales_Customer_Summery'
                                        : title == 'Daily Sales Tax Report'
                                            ? 'Daily Sales Tax Report'
                                            : title == 'IVA Report'
                                                ? 'IVA Report'
                                                : title ==
                                                        'Customer Summery Invoice'
                                                    ? 'Customer_Summery_Invoice'
                                                    : title ==
                                                            'Counter Wise Report'
                                                        ? 'Counter_Wise_Report'
                                                        : title ==
                                                                'Replace P&L ItemWise'
                                                            ? 'Replace_p_l_Itemwise'
                                                            : title ==
                                                                    'Simple P&l Report'
                                                                ? 'Simple_P_l_Report'
                                                                : title ==
                                                                        'Scheme Report'
                                                                    ? 'SchemeReport'
                                                                    : title ==
                                                                            'ItemWise Monthly'
                                                                        ? 'Itemwise_monthly'
                                                                        : title ==
                                                                                'Sales Qty Total'
                                                                            ? 'Sales_QtyTotal'
                                                                            : title == 'Location Wise Summary'
                                                                                ? 'Location Wise Summary'
                                                                                : title == 'Location Wise Qty Total'
                                                                                    ? 'Location Wise Qty Total'
                                                                                    : 'Sales_Summery';

    for (var data in salesTypeDataList) {
      if (data.stock) dataSType.add({'id': data.id});
    }

    if (title == 'Daily') {
      newMode = true;
    } else {
      newMode = false;
    }
    if (newMode) {
      return _saleListData('SalesList', dataSType, title);
    } else {
      var locationData = [];
      if (isAdminUser) {
        if (isBranchSelected) {
          locationData.add({'id': location.id});
        } else {
          for (var data in locationList) {
            if (data.value.toString().isNotEmpty) {
              locationData.add({'id': data.key});
            }
          }
        }
      } else {
        locationData.add({'id': location.id});
      }
      String areaId = area.isNotEmpty ? area : '0';
      String routeId = route.isNotEmpty ? route : '0';
      if (itemName != null) {
        itemId = itemName;
      }

      var dataJson = '[' +
          json.encode({
            'statementType': statementType.isEmpty ? '' : statementType,
            'sDate': fromDate.isEmpty ? '' : formatYMD(fromDate),
            'eDate': toDate.isEmpty ? '' : formatYMD(toDate),
            'itemId': itemId != null ? itemId.id : '0',
            'customerId': customer != null ? customer.id : '0',
            'mfr': mfr != null ? mfr.id : '0',
            'category': category != null ? category.id : '0',
            'subcategory': subCategory != null ? subCategory.id : '0',
            'location': locationId != null
                ? jsonEncode([
                    {'id': locationId}
                  ])
                : jsonEncode(locationData),
            'project': project != null ? project.id : '0',
            'salesman': salesMan != null ? salesMan.id : '0',
            'salesType': dataSType != null
                ? jsonEncode(dataSType)
                : jsonEncode([
                    {'id': 0}
                  ]),
            'toName': '',
            'taxGroup': taxGroup != null ? taxGroup.id : '0',
            'groupId': '0',
            'areaId': areaId,
            'type': '0',
            'hsnCode': '',
            'cashSale': '0',
            'creditSales': '0',
            'rateType': stockValuation ? 'RPRate' : 'PRate',
            'serialNo': '',
            'supplierId': supplier != null ? supplier.id : '0',
            'srCheck': '0',
            'serviceCheck': '0',
            'expenseCheck': '0',
            'counterNo': '',
            'cardNo': '',
            'salesman2': '0',
            'typeOfSupply': 'ALL',
            'barcode': '0',
            'userId': '0',
            'hsn': '',
            'supLed': '0',
          }) +
          ']';

      return FutureBuilder<List<dynamic>>(
        future: api.getSalesReport(dataJson),
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.isNotEmpty) {
              var data = snapshot.data;
              var col = data[0].keys.toList();
              if (classic &&
                  statementType != 'P_l_ItemWise_New' &&
                  statementType != 'Sales_QtyTotal') {
                Map<String, dynamic> totalData = {};
                for (int i = 0; i < col.length; i++) {
                  var cell = '';
                  if (col[i].toLowerCase() == ('discount') ||
                      col[i].toLowerCase() == ('grossvalue') ||
                      col[i].toLowerCase() == ('cgst') ||
                      col[i].toLowerCase() == ('sgst') ||
                      col[i].toLowerCase() == ('igst') ||
                      col[i].toLowerCase() == ('netamount') ||
                      col[i].toLowerCase() == ('cess') ||
                      col[i].toLowerCase() == ('tcs') ||
                      col[i].toLowerCase() == ('othercharges') ||
                      col[i].toLowerCase() == ('otherdiscount') ||
                      col[i].toLowerCase() == ('loadingcharge') ||
                      col[i].toLowerCase() == ('roundoff') ||
                      col[i].toLowerCase() == ('grandtotal') ||
                      col[i].toLowerCase() == ('creditsales') ||
                      col[i].toLowerCase() == ('cashsales') ||
                      col[i].toLowerCase() == ('bankamount') ||
                      col[i].toLowerCase() == ('qty') ||
                      col[i].toLowerCase() == ('free') ||
                      col[i].toLowerCase() == ('freeqty') ||
                      col[i].toLowerCase() == ('rate') ||
                      col[i].toLowerCase() == ('prate') ||
                      col[i].toLowerCase() == ('srate') ||
                      col[i].toLowerCase() == ('profit') ||
                      col[i].toLowerCase() == ('total') ||
                      col[i].toLowerCase() == ('labourcharge') ||
                      col[i].toLowerCase() == ('returnamount') ||
                      col[i].toLowerCase() == ('balance')) {
                    cell = data
                        .fold(
                            0.0,
                            (a, b) =>
                                a +
                                (b[col[i]] != null
                                    ? b[col[i]] == ''
                                        ? 0
                                        : double.tryParse(
                                                b[col[i]].toString()) ??
                                            0
                                    : 0))
                        .toStringAsFixed(2);
                  }
                  if (i == 0) {
                    cell = 'Total';
                  }
                  totalData[col[i]] = cell;
                }
                if (totalData.isNotEmpty) {
                  data.add(totalData);
                }
                _data = data;
              } else {
                _data = data;
              }
              tableColumn = data[0].keys.toList();
              return classic
                  ? Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                                child: Text(
                              title +
                                  ' Date: From ' +
                                  fromDate +
                                  ' To ' +
                                  toDate,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateColor.resolveWith(
                                    (states) => Colors.grey.shade200),
                                border: TableBorder.all(
                                    width: 1.0, color: Colors.black),
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
                                          for (int i = 0;
                                              i < values.length;
                                              i++)
                                            DataCell(
                                              Align(
                                                alignment:
                                                    ComSettings.oKNumeric(
                                                  values[col[i]] != null
                                                      ? values[col[i]]
                                                          .toString()
                                                      : '',
                                                )
                                                        ? Alignment.centerRight
                                                        : Alignment.centerLeft,
                                                child: InkWell(
                                                  child: Text(
                                                    values[col[i]] != null
                                                        ? values[col[i]]
                                                            .toString()
                                                        : '',
                                                    softWrap: true,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    // style: TextStyle(fontSize: 6),
                                                  ),
                                                  onLongPress: () {
                                                    if (col[i] == 'EntryNo') {
                                                      var no = values[col[i]];
                                                      dataDynamic = [
                                                        {
                                                          'RealEntryNo':
                                                              int.tryParse(no),
                                                          'EntryNo':
                                                              int.tryParse(no),
                                                          'Id':
                                                              int.tryParse(no),
                                                          'InvoiceNo': '0',
                                                          'Type': '0'
                                                        }
                                                      ];
                                                      showEditDialog(
                                                          context,
                                                          int.tryParse(
                                                              no.toString()));
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            )
                            // SizedBox(height: 500),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return index == 0
                            ? Card(
                                elevation: 5,
                                child: Column(
                                  children: [
                                    Center(
                                        child: Text(
                                      title +
                                          ' Date: From ' +
                                          fromDate +
                                          ' To ' +
                                          toDate,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )),
                                    Text(
                                      'Total Sales Invoice : ' +
                                          (data.length - 1).toString(),
                                      style: const TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Text(
                                          'Cash:' +
                                              data[index]['CashSales']
                                                  .toStringAsFixed(2),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        Text(
                                          'Bank:' +
                                              data[index]['BankAmount']
                                                  .toStringAsFixed(2),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Text(
                                          'Total:' +
                                              data[index]['GrandTotal']
                                                  .toStringAsFixed(2),
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('Balance:' +
                                            data[index]['Balance']
                                                .toStringAsFixed(2)),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Stack(
                                    children: <Widget>[
                                      Container(
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          gradient: const LinearGradient(
                                              colors: [
                                                Color(0xff6DC8F3),
                                                Color(0xff73A1F9)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0xff73A1F9),
                                              blurRadius: 12,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        top: 0,
                                        child: CustomPaint(
                                          size: const Size(100, 150),
                                          painter: CustomCardShapePainter(
                                              24,
                                              const Color(0xff6DC8F3),
                                              const Color(0xff73A1F9)),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              flex: 5,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: <Widget>[
                                                  Text(
                                                    data[index][col[0]][2]
                                                        .toString(),
                                                    style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w700),
                                                  ),
                                                  Text(
                                                    'invoice : ' +
                                                        data[index][col[0]][1]
                                                            .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  Text(
                                                    'date : ' +
                                                        data[index][col[0]][0]
                                                            .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 5,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: <Widget>[
                                                  Text(
                                                    'Bill : ' +
                                                        data[index]
                                                                ['GrandTotal']
                                                            .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w700),
                                                  ),
                                                  Text(
                                                    'CASH : ' +
                                                        data[index]['CashSales']
                                                            .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w700),
                                                  ),
                                                  Text(
                                                    'Balance : ' +
                                                        data[index]['Balance']
                                                            .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w700),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                      },
                    );
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  final ScrollController _scrollController = ScrollController();
  bool isLoadingData = false, valueMore = false, lastRecord = false;
  // final _scaffoldKey = GlobalKey<ScaffoldState>();
  int page = 1, pageTotal = 0, totalRecords = 0;

  void _getMoreData(String statementType, var dataSType) async {
    if (!lastRecord) {
      if ((dataDisplay.isEmpty || dataDisplay.length < totalRecords) &&
          !isLoadingData) {
        setState(() {
          isLoadingData = true;
        });

        List tempList = [];

        // statement, page, '1', salesTypeData.id.toString(), ' ', ' '
        var _location = '0';
        if (location != null) {
          _location = location.id.toString() ?? '0';
        }

        var dataJsonS = '[' +
            json.encode({
              'statementType': statementType.isEmpty ? '' : statementType,
              'sDate': fromDate.isEmpty ? '' : formatYMD(fromDate),
              'eDate': toDate.isEmpty ? '' : formatYMD(toDate),
              'itemId': itemId != null ? itemId.id : '0',
              'customerId': customer != null ? customer.id : '0',
              'mfr': mfr != null ? mfr.id : '0',
              'category': category != null ? category.id : '0',
              'subcategory': subCategory != null ? subCategory.id : '0',
              'location': _location,
              'project': project != null ? project.id : '0',
              'salesman': salesMan != null ? salesMan.id : '0',
              'salesType': dataSType != null
                  ? jsonEncode(dataSType)
                  : jsonEncode({'id': 0}),
              "page": page
            }) +
            ']';
        api.getSalesListReport(dataJsonS).then((value) {
          final response = value;
          pageTotal = response[1][0]['Filtered'];
          totalRecords = response[1][0]['Total'];
          page++;
          for (int i = 0; i < response[0].length; i++) {
            tempList.add(response[0][i]);
          }

          setState(() {
            isLoadingData = false;
            dataDisplay.addAll(tempList);
            dataDisplayHead.addAll(response[1]);
            lastRecord = tempList.isNotEmpty ? false : true;
          });
        });
      }
    }
  }

  List dataDisplay = [];
  List dataDisplayHead = [];

  _saleListData(String statementType, var dataSType, String title) {
    _getMoreData(statementType, dataSType);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreData(statementType, dataSType);
      }
    });

    return isLoadingData
        ? const Loading()
        : dataDisplay.isEmpty
            ? const Card(child: Center(child: Text('No Data')))
            : Column(
                children: [
                  Container(
                      decoration: BoxDecoration(
                          color: blue[200],
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20.0),
                              bottomRight: Radius.circular(20.0))),
                      child: Column(
                        children: [
                          Center(
                              child: Text(
                            ' Date: ' + fromDate + ' - ' + toDate,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                          Text(
                            'Total Sales Invoice : ' +
                                (dataDisplayHead[0]['Filtered']).toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                'Cash:' +
                                    dataDisplayHead[0]['CashReceived']
                                        .toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Bank:' +
                                    dataDisplayHead[0]['BankAmount']
                                        .toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                'Total : ' +
                                    dataDisplayHead[0]['GrandTotal']
                                        .toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Balance:' +
                                    dataDisplayHead[0]['Balance']
                                        .toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      )),
                  Expanded(
                    child: ListView.builder(
                      itemCount: dataDisplay.length,
                      itemBuilder: (BuildContext context, int index) {
                        if (dataDisplay.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Opacity(
                                opacity: isLoadingData ? 1.0 : 00,
                                child: const CircularProgressIndicator(),
                              ),
                            ),
                          );
                        } else {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Stack(
                                children: <Widget>[
                                  Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: const LinearGradient(
                                          colors: [
                                            Color(0xff6DC8F3),
                                            Color(0xff73A1F9)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0xff73A1F9),
                                          blurRadius: 12,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    top: 0,
                                    child: CustomPaint(
                                      size: const Size(100, 150),
                                      painter: CustomCardShapePainter(
                                          24,
                                          const Color(0xff6DC8F3),
                                          const Color(0xff73A1F9)),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          flex: 5,
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: InkWell(
                                              onTap: () {
                                                int _id = int.tryParse(
                                                    dataDisplay[index]['Type']
                                                        .toString());
                                                SalesType sData =
                                                    salesTypeDataList
                                                        .where((element) =>
                                                            element.id == _id)
                                                        .first;
                                                salesTypeData = SalesType(
                                                    id: sData.id,
                                                    accounts: sData.accounts,
                                                    location:
                                                        (locationId != null
                                                            ? locationId
                                                            : sData.location),
                                                    name: sData.name,
                                                    rateType: sData.rateType,
                                                    stock: sData.stock,
                                                    type: sData.type,
                                                    eInvoice: sData.eInvoice,
                                                    sColor: sData.sColor,
                                                    tax: sData.tax);
                                                dataDynamic = [
                                                  {'Id': _id}
                                                ];
                                                dataDynamic = [
                                                  {
                                                    'RealEntryNo': int.tryParse(
                                                        dataDisplay[index]['Id']
                                                            .toString()),
                                                    'EntryNo': int.tryParse(
                                                        dataDisplay[index]['Id']
                                                            .toString()),
                                                    'Id': int.tryParse(
                                                        dataDisplay[index]['Id']
                                                            .toString()),
                                                    'InvoiceNo': int.tryParse(
                                                        dataDisplay[index]
                                                                ['Invoice']
                                                            .toString()),
                                                    'Type': _id.toString()
                                                  }
                                                ];
                                                showEditDialog(
                                                    context,
                                                    int.tryParse(
                                                        dataDisplay[index]['Id']
                                                            .toString()));
                                              },
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    dataDisplay[index]['ToName']
                                                        .toString(),
                                                    style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w700),
                                                  ),
                                                  Text(
                                                    'Invoice : ' +
                                                        dataDisplay[index]
                                                                ['Invoice']
                                                            .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Date     : ' +
                                                        dataDisplay[index]
                                                                ['Date']
                                                            .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Bill          : ',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              'Cash     : ',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              'Balance : ',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        InkWell(
                                          onTap: () {
                                            int _id = int.tryParse(
                                                dataDisplay[index]['Type']
                                                    .toString());
                                            SalesType sData = salesTypeDataList
                                                .where((element) =>
                                                    element.id == _id)
                                                .first;
                                            salesTypeData = SalesType(
                                                id: sData.id,
                                                accounts: sData.accounts,
                                                location: locationId != null
                                                    ? locationId
                                                    : sData.location,
                                                name: sData.name,
                                                rateType: sData.rateType,
                                                stock: sData.stock,
                                                type: sData.type,
                                                eInvoice: sData.eInvoice,
                                                sColor: sData.sColor,
                                                tax: sData.tax);
                                            showDetails(context,
                                                dataDisplay[index], _id);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: <Widget>[
                                                Text(
                                                  dataDisplay[index]['Total']
                                                      .toStringAsFixed(2),
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                                Text(
                                                  dataDisplay[index]['Cash']
                                                      .toStringAsFixed(2),
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                                Text(
                                                  dataDisplay[index]['Balance']
                                                      .toStringAsFixed(2),
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      controller: _scrollController,
                    ),
                  ),
                ],
              );
  }

  showDetails(context, data, sType) {
    dataDynamic = [
      {
        'RealEntryNo': int.tryParse(data['Id'].toString()),
        'EntryNo': int.tryParse(data['Id'].toString()),
        'InvoiceNo': int.tryParse(data['Id'].toString()),
        'Type': sType ?? 3
      }
    ];
    Navigator.pushNamed(context, '/preview_show', arguments: {'title': 'Sale'});
  }

  selectData(title) {
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
                      ' From : ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    InkWell(
                      child: Text(
                        fromDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      onTap: () => _selectDate('f'),
                    ),
                    const Text(
                      ' To : ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    InkWell(
                      child: Text(
                        toDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      onTap: () => _selectDate('t'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Card(
              //   elevation: 2,
              //   child: DropDownSettingsTile<int>(
              //     title: 'Branch',
              //     settingKey: 'key-dropdown-default-location-view',
              //     values: locationList.isNotEmpty
              //         ? {for (var e in locationList) e.key + 1: e.value}
              //         : {
              //             2: '',
              //           },
              //     selected: 2,
              //     onChange: (value) {
              //       debugPrint('key-dropdown-default-location-view: $value');
              //       dropDownBranchId = value - 1;
              //     },
              //   ),
              // ),
              Visibility(
                visible: isAdminUser,
                child: DropdownSearch<dynamic>(
                  maxHeight: 300,
                  onFind: (String filter) =>
                      api.getSalesListData(filter, 'sales_list/location'),
                  dropdownSearchDecoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: 'Select Branch'),
                  onChanged: (dynamic data) {
                    location = data;
                    isBranchSelected = true;
                  },
                  showSearchBox: true,
                ),
              ),
              isType
                  ? Row(
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
                    )
                  : Container(),
              // Divider(),
              TextButton(
                onPressed: () {
                  setState(() {
                    loadReport = true;
                    location = isAdminUser
                        ? isBranchSelected
                            ? location
                            : DataJson(id: 1, name: defaultLocation)
                        : location;
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
              Container(
                decoration:
                    BoxDecoration(border: Border.all(width: 0.3, color: black)),
                child: Row(children: [
                  const Text('Stock Valuation Last P-Rate'),
                  Checkbox(
                    value: stockValuation,
                    onChanged: (value) {
                      setState(() {
                        stockValuation = value;
                      });
                    },
                  )
                ]),
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/ItemCode'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Select Item Code'),
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
                    border: OutlineInputBorder(),
                    labelText: "Select Item Name"),
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
                    border: OutlineInputBorder(), labelText: "Select Customer"),
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
                    border: OutlineInputBorder(), labelText: "Select Item MFR"),
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
                    border: OutlineInputBorder(), labelText: "Select Category"),
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
                    labelText: "Select SubCategory"),
                onChanged: (dynamic data) {
                  subCategory = data;
                },
                showSearchBox: true,
              ),
              Visibility(visible: isAdminUser, child: const Divider()),
              Visibility(
                visible: isAdminUser,
                child: DropdownSearch<dynamic>(
                  maxHeight: 300,
                  onFind: (String filter) =>
                      api.getSalesListData(filter, 'sales_list/salesMan'),
                  dropdownSearchDecoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Select SalesMan"),
                  onChanged: (dynamic data) {
                    salesMan = data;
                  },
                  showSearchBox: true,
                ),
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/project'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: "Select Project"),
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
                    border: OutlineInputBorder(), labelText: "Select TaxGroup"),
                onChanged: (dynamic data) {
                  taxGroup = data;
                },
                showSearchBox: true,
              ),
              const Divider(),
              DropdownSearch<dynamic>(
                maxHeight: 300,
                onFind: (String filter) =>
                    api.getSalesListData(filter, 'sales_list/supplier'),
                dropdownSearchDecoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: "Select Supplier"),
                onChanged: (dynamic data) {
                  supplier = data;
                },
                showSearchBox: true,
              ),
              Visibility(visible: isAdminUser, child: const Divider()),
              Visibility(
                visible: isAdminUser,
                child: Card(
                  elevation: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text('Select Area'),
                      DropdownButton<OtherRegistrationModel>(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: otherRegAreaList
                            .map((OtherRegistrationModel items) {
                          return DropdownMenuItem<OtherRegistrationModel>(
                            value: items,
                            child: Text(items.name),
                          );
                        }).toList(),
                        value: areaModel,
                        onChanged: (value) {
                          setState(() {
                            areaModel = value;
                            area = value.id.toString();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Card(
                elevation: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text('Select Route'),
                    DropdownButton<OtherRegistrationModel>(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items:
                          otherRegRouteList.map((OtherRegistrationModel items) {
                        return DropdownMenuItem<OtherRegistrationModel>(
                          value: items,
                          child: Text(items.name),
                        );
                      }).toList(),
                      value: routeModel,
                      onChanged: (value) {
                        routeModel = value;
                        route = value.id.toString();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              salesTypeDataList.isNotEmpty
                  ? ExpansionTile(
                      title: const Text('Sales Name'),
                      children: _getChildren(salesTypeDataList),
                    )
                  : Container(),
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

  void onScroll() {
    setState(() {
      offset = (controller.hasClients) ? controller.offset : 0;
    });
  }

  Future<String> _createPDF(String title) async {
    return makePDF(title).then((value) => savePreviewPDF(value, title));
  }

  Future<pw.Document> makePDF(String title) async {
    // var tableHeaders = [
    //   "Date",
    //   "Particulars",
    //   "Voucher",
    //   "EntryNo",
    //   "Debit",
    //   "Credit",
    //   "Balance",
    //   "Narration"
    // ];

    var data = _data;

    final pw.Document pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
        // pageFormat: PdfPageFormat.a4,
        maxPages: 100,
        header: (context) => pw.Column(children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      color: const PdfColor.fromInt(0),
                      fontSize: 25,
                      fontWeight: pw.FontWeight.bold)),
            ]),
        build: (context) => [
              pw.Table(
                border: pw.TableBorder.all(width: 0.2),
                children: [
                  pw.TableRow(children: [
                    for (int k = 0; k < tableColumn.length; k++)
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(tableColumn[k],
                                style: const pw.TextStyle(fontSize: 6)),
                            // pw.Divider(thickness: 1)
                          ]),
                  ]),
                  for (var i = 0; i < data.length; i++)
                    pw.TableRow(children: [
                      for (int l = 0; l < tableColumn.length; l++)
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(2.0),
                                child: pw.Text(
                                    data[i][tableColumn[l]].toString() ?? '',
                                    style: const pw.TextStyle(fontSize: 6)),
                                // pw.Divider(thickness: 1)
                              ),
                            ]),
                    ])
                ],
              ),
            ],
        footer: _buildFooter));

    return pdf;
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(),
        pw.Text(
          'Page ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.red,
          ),
        ),
      ],
    );
  }

  Future<String> savePreviewPDF(pw.Document pdf, var title) async {
    title = title.replaceAll(RegExp(r'[^\w\s]+'), '');
    if (kIsWeb) {
      try {
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..style.display = 'none'
        //   ..download = '$title.pdf';
        // html.document.body.children.add(anchor);
        // anchor.click();
        // html.document.body.children.remove(anchor);
        // html.Url.revokeObjectUrl(url);
        return '';
      } catch (ex) {
        ex.toString();
      }
      return '';
    } else {
      var output = await getTemporaryDirectory();
      final file = File('${output.path}/' + title + '.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path.toString();
    }
  }

  Future<String> _createCSV(String title) async {
    return _generateCsvFile(title)
        .then((value) => savePreviewCSV(value, title));
  }

  Future<String> _generateCsvFile(String title) async {
    var dataList = _data;
    List<List<dynamic>> rows = [];
    var col = dataList[0].keys.toList();
    List<dynamic> row = [];
    for (var columnName in col) {
      row.add(columnName.toString());
    }
    rows.add(row);

    for (var i = 0; i < dataList.length; i++) {
      List<dynamic> row1 = [];
      for (var columnName in col) {
        row1.add(dataList[i][columnName].toString());
      }
      rows.add(row1);
    }
    return const ListToCsvConverter().convert(rows);
  }

  Future<String> savePreviewCSV(var csv, var title) async {
    title = title.replaceAll(RegExp(r'[^\w\s]+'), '');
    if (kIsWeb) {
      try {
        // final bytes = utf8.encode(csv);
        // final blob = html.Blob([bytes], 'application/csv');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement()
        //   ..href = url
        //   ..style.display = 'none'
        //   ..download = '$title.csv';
        // html.document.body.children.add(anchor);
        // anchor.click();
        // html.document.body.children.remove(anchor);
        // html.Url.revokeObjectUrl(url);
        return '';
      } catch (ex) {
        ex.toString();
      }
      return '';
    } else {
      var output = await getTemporaryDirectory();
      final file = File('${output.path}/' + title + '.csv');
      await file.writeAsString(csv);
      return file.path.toString();
    }
  }

  Future<void> urlFileShare(BuildContext context, String text, String subject,
      List<String> paths) async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    if (paths.isNotEmpty) {
      List<XFile> files = [];
      for (String value in paths) {
        files.add(XFile(value));
      }
      await Share.shareXFiles(files,
          text: text,
          subject: subject,
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
    }
  }

  showEditDialog(context, int _id) {
    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
        },
        onPressedYes: () {
          Navigator.of(context).pop();
          ComSettings.appSettings('bool', 'key-simple-sales', false)
              ? Navigator.pushNamed(context, '/SimpleSale')
              : Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const Sale(
                        oldSale: true,
                        thisSale: false,
                      )));
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage: 'Do you want to edit or delete\nRefNo:$_id',
        title: 'Update',
        context: context);
  }
}

class TypeItem {
  int id;
  String name;
  TypeItem(this.id, this.name);
}

class CustomCardShapePainter extends CustomPainter {
  final double radius;
  final Color startColor;
  final Color endColor;

  CustomCardShapePainter(this.radius, this.startColor, this.endColor);

  @override
  void paint(Canvas canvas, Size size) {
    var radius = 24.0;

    var paint = Paint();
    paint.shader = ui.Gradient.linear(
        const Offset(0, 0), Offset(size.width, size.height), [
      HSLColor.fromColor(startColor).withLightness(0.8).toColor(),
      endColor
    ]);

    var path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width - radius, size.height)
      ..quadraticBezierTo(
          size.width, size.height, size.width, size.height - radius)
      ..lineTo(size.width, radius)
      ..quadraticBezierTo(size.width, 0, size.width - radius, 0)
      ..lineTo(size.width - 1.5 * radius, 0)
      ..quadraticBezierTo(-radius, 2 * radius, 0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
