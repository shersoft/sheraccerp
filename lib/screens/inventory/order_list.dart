import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/screens/inventory/sales/sales_list.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';

class OrderList extends StatefulWidget {
  const OrderList({Key? key}) : super(key: key);

  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  bool loadReport = false;
  double offset = 0;
  List<dynamic> resultData = [];
  List<SalesType> salesTypeData = [];
  var dropDownBranchId;
  String fromDate = '', toDate = '';
  DateTime now = DateTime.now();
  DioService api = DioService();
  var salesManId = 0;

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
    salesTypeData = salesTypeList;
    salesManId = ComSettings.appSettings(
            'int', 'key-dropdown-default-salesman-view', 1) -
        1;
  }

  void itemChange(bool val, int index) {
    setState(() {
      salesTypeData[index].stock = val;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  });
                },
                icon: const Icon(Icons.filter_alt)),
            IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {
                  setState(
                    () {
                      // Future.delayed(Duration(milliseconds: 1000), () {
                      //   _createPDF(widget.name +
                      //           ' Date :' +
                      //           widget.sDate +
                      //           ' - ' +
                      //           widget.eDate)
                      //       .then((value) =>
                      //           Navigator.of(context).push(MaterialPageRoute(
                      //               builder: (_) => PDFScreen(
                      //                     pathPDF: value,
                      //                     subject: widget.name +
                      //                         ' Date :' +
                      //                         widget.sDate +
                      //                         ' - ' +
                      //                         widget.eDate,
                      //                     text: 'this is ' +
                      //                         widget.name +
                      //                         ' Date :' +
                      //                         widget.sDate +
                      //                         ' - ' +
                      //                         widget.eDate,
                      //                   ))));
                      // });
                    },
                  );
                }),
          ],
          // ignore: prefer_const_constructors
          title: const Text('Order Report'),
        ),
        body: loadReport
            ? reportView('Order Report')
            : selectData('Order Report'));
  }

  final controller = ScrollController();
  final ScrollController _scrollController = ScrollController();
  bool isLoadingData = false, valueMore = false, lastRecord = false;
  // final _scaffoldKey = GlobalKey<ScaffoldState>();
  int page = 1, pageTotal = 0, totalRecords = 0;
  List dataDisplay = [];
  List dataDisplayHead = [];

  selectData(title) {
    int _branchId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 0) -
        1;
    dropDownBranchId = _branchId > 0 ? _branchId : dropDownBranchId;
    // var _idp = locationList.isNotEmpty
    //     ? Map.fromIterable(locationList,
    //         key: (e) => e.key + 1, value: (e) => e.value)
    //     : {
    //         2: '',
    //       };

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
                            fontWeight: FontWeight.bold, fontSize: 20),
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
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      onTap: () => _selectDate('t'),
                    ),
                  ],
                ),
              ),

              const Divider(),
              // Card(
              // elevation: 2,
              // child: DropDownSettingsTile<int>(
              //   title: 'Branch',
              //   settingKey: 'key-dropdown-default-location-view',
              //   values: locationList.isNotEmpty
              //       ? Map.fromIterable(locationList,
              //           key: (e) => e.key + 1, value: (e) => e.value)
              //       : {
              //           2: '',
              //         },
              //   selected: 2,
              //   onChange: (value) {
              //     debugPrint('key-dropdown-default-location-view: $value');
              //     dropDownBranchId = value - 1;
              //   },
              // ),
              // ),
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
            ],
          ),
        ),
      ],
    );
  }

  Future _selectDate(String type) async {
    DateTime? picked = await showDatePicker(
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

  reportView(title) {
    controller.addListener(onScroll);
    List<dynamic> dataSType = [];
    // if (ComSettings.appSettings('bool', 'key-switch-sales-form-set', false)) {
    //   for (var data in salesTypeData) {
    //     if (data.stock) dataSType.add({'id': data.id});
    //   }
    // } else {
    for (var data in salesTypeData) {
      if (data.name == 'Sales Order Entry') dataSType.add({'id': data.id});
    }
    // }

    return _saleListData('SalesList', dataSType, title);
  }

  void _getMoreData(String statementType, var dataSType) async {
    if (!lastRecord) {
      if ((dataDisplay.isEmpty || dataDisplay.length < totalRecords) &&
          !isLoadingData) {
        setState(() {
          isLoadingData = true;
        });

        List tempList = [];

        var dataJsonS = '[' +
            json.encode({
              'statementType': statementType.isEmpty ? '' : statementType,
              'sDate': fromDate.isEmpty ? '' : formatYMD(fromDate),
              'eDate': toDate.isEmpty ? '' : formatYMD(toDate),
              'itemId': '0',
              'customerId': '0',
              'mfr': '0',
              'category': '0',
              'subcategory': '0',
              'location':
                  dropDownBranchId > 0 ? dropDownBranchId.toString() : '1',
              'project': '0',
              'salesman': salesManId.toString(),
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

  _saleListData(String statementType, var dataSType, String title) {
    _getMoreData(statementType, dataSType);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreData(statementType, dataSType);
      }
    });

    return Column(
      children: [
        dataDisplay.isEmpty
            ? const Loading()
            : Container(
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
                              dataDisplayHead[0]['Balance'].toStringAsFixed(2),
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
                                colors: [Color(0xff6DC8F3), Color(0xff73A1F9)],
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
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        dataDisplay[index]['ToName'].toString(),
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontFamily: 'Avenir',
                                            fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        'Invoice : ' +
                                            dataDisplay[index]['Invoice']
                                                .toString(),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Avenir',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Date     : ' +
                                            dataDisplay[index]['Date']
                                                .toString(),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Avenir',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Bill          : ',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Avenir',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Cash     : ',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Avenir',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Balance : ',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Avenir',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      dataDisplay[index]['Total']
                                          .toStringAsFixed(2),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Avenir',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      dataDisplay[index]['Cash']
                                          .toStringAsFixed(2),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Avenir',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      dataDisplay[index]['Balance']
                                          .toStringAsFixed(2),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Avenir',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700),
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
              }
            },
            controller: _scrollController,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    super.dispose();
  }
}
