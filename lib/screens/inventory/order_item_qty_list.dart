// @dart = 2.11
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/screens/inventory/sales/sales_list.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';

import 'sales/previous_bill.dart';

class OrderItemList extends StatefulWidget {
  const OrderItemList({Key key}) : super(key: key);

  @override
  State<OrderItemList> createState() => _OrderItemListState();
}

class _OrderItemListState extends State<OrderItemList> {
  bool loadReport = false;
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
    var _infoKey = <GlobalKey>[];
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {
                    loadReport = false;
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
          title: const Text('Order Item Report'),
        ),
        body: loadReport
            ? reportView('Order Item Report', _infoKey)
            : selectData('Order Item Report'));
  }

  List dataDisplay = [];
  List dataDisplayHead = [];

  selectData(title) {
    dropDownBranchId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 0) -
        1;
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

  reportView(title, _infoKey) {
    return FutureBuilder(
      future: api.fetchItemBills(formatYMD(fromDate), formatYMD(toDate)),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.length > 0) {
            var data = snapshot.data;
            var information = data['Information'];
            var particulars = data['Particulars'];
            // var serialNO = data['SerialNO'];
            // var deliveryNoteDetails = data['DeliveryNote'];
            var otherAmountList = data['otherAmount'];

            return ListView.builder(
                cacheExtent: 10000.0,
                itemCount: information.length,
                itemBuilder: (context, index) {
                  _infoKey.add(GlobalKey(debugLabel: index.toString()));
                  List<dynamic> items = particulars
                      .where((item) =>
                          item['EntryNo'] == information[index]['EntryNo'])
                      .toList();

                  return Card(
                      elevation: 1.5,
                      child: Container(
                          margin: const EdgeInsets.all(10),
                          child: Column(children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "EntryNo: ${information[index]['EntryNo']}",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                            )),
                                        Text(
                                            information[index]['SType'] != null
                                                ? information[index]['SType'] ==
                                                        '1'
                                                    ? 'B2B SALE'
                                                    : information[index]
                                                                ['SType'] ==
                                                            '2'
                                                        ? 'B2C SALE'
                                                        : information[index]
                                                                    ['SType'] ==
                                                                '3'
                                                            ? 'ESTIMATE'
                                                            : 'CASH SALE'
                                                : 'SALES INVOICE',
                                            style: const TextStyle(
                                              color: Colors.deepOrange,
                                              fontSize: 12,
                                            )),
                                      ]),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                            DateUtil.dateDMY(information[index]
                                                    ['DDate']) +
                                                ' ' +
                                                DateUtil.timeHMSA(
                                                    information[index]
                                                        ['BTime']),
                                            style: TextStyle(
                                              color: Colors.blueGrey.shade600,
                                              fontSize: 12,
                                            )),
                                        Text(
                                            DateUtil.getDays(
                                                    start:
                                                        DateUtil.dateTimeYMDHMS(
                                                            information[index]
                                                                ['DDate'],
                                                            information[index]
                                                                ['BTime']),
                                                    end: DateTime.now())
                                                .toString(),
                                            style: const TextStyle(
                                              color: Colors.cyan,
                                              fontSize: 10,
                                            ))
                                      ])
                                ]),
                            const SizedBox(height: 5),
                            Column(
                              children: [
                                /**** loop start ***/
                                for (var item in items)
                                  Row(children: [
                                    Flexible(
                                        flex: 2500,
                                        child: Row(children: [
                                          const Icon(Icons.check_circle,
                                              size: 14),
                                          const SizedBox(width: 5),
                                          RichText(
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            strutStyle:
                                                StrutStyle(fontSize: 12.0),
                                            text: TextSpan(
                                                text: "${item['itemname']}",
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                )),
                                          )
                                        ])),
                                    Flexible(
                                        flex: 700,
                                        child: Row(children: [
                                          Text("${item['Qty']}",
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                              )),
                                          const Text("X",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              )),
                                          Text("${item['Rate']}",
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                              ))
                                        ])),
                                    Flexible(
                                        flex: 0,
                                        child: Text(
                                            "${item['Total'].toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                            ))),
                                  ]),
                              ],
                              /**loop end****/
                            ),
                            Divider(color: Colors.grey.withOpacity(0.1)),
                            Row(children: [
                              Flexible(
                                  flex: 2500,
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(children: [
                                          Text(
                                              "CashReceived:${information[index]['CashReceived'].toStringAsFixed(2)}",
                                              style: TextStyle(
                                                color: Colors.green.shade900,
                                                fontSize: 12,
                                              )),
                                        ]),
                                        Row(children: [
                                          const Text('Total',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                              )),
                                          const SizedBox(width: 3),
                                          GestureDetector(
                                              key: _infoKey[index],
                                              onTap: () {
                                                RenderBox renderBox =
                                                    _infoKey[index]
                                                        .currentContext
                                                        .findRenderObject();
                                                Offset offset = renderBox
                                                    .localToGlobal(Offset.zero);
                                                showPopupWindow(
                                                    context: context,
                                                    fullWidth: false,
                                                    //isShowBg:true,
                                                    position:
                                                        RelativeRect.fromLTRB(
                                                            0,
                                                            offset.dy +
                                                                renderBox.size
                                                                    .height,
                                                            0,
                                                            0),
                                                    child: GestureDetector(
                                                        onTap: () {},
                                                        child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(10),
                                                            child: Column(
                                                                children: [
                                                                  Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        const Text(
                                                                            'Item Total',
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.grey,
                                                                              fontSize: 12,
                                                                            )),
                                                                        Text(
                                                                            information[index]['GrossValue'].toStringAsFixed(
                                                                                2),
                                                                            style:
                                                                                const TextStyle(
                                                                              color: Colors.black,
                                                                              fontSize: 14,
                                                                            ))
                                                                      ]),
                                                                  const SizedBox(
                                                                      height:
                                                                          3),
                                                                  Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        const Text(
                                                                            'Other Charge',
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.grey,
                                                                              fontSize: 12,
                                                                            )),
                                                                        Text(
                                                                            information[index]['OtherCharges'].toStringAsFixed(
                                                                                2),
                                                                            style:
                                                                                const TextStyle(
                                                                              color: Colors.black,
                                                                              fontSize: 14,
                                                                            ))
                                                                      ]),
                                                                  const SizedBox(
                                                                      height:
                                                                          3),
                                                                  Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        const Text(
                                                                            'Loading Charge',
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.grey,
                                                                              fontSize: 12,
                                                                            )),
                                                                        Text(
                                                                            information[index]['loadingCharge'].toStringAsFixed(
                                                                                2),
                                                                            style:
                                                                                const TextStyle(
                                                                              color: Colors.black,
                                                                              fontSize: 14,
                                                                            ))
                                                                      ]),
                                                                  const SizedBox(
                                                                      height:
                                                                          3),
                                                                  Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        const Text(
                                                                            'Discount',
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.grey,
                                                                              fontSize: 12,
                                                                            )),
                                                                        Text(
                                                                            information[index]['Discount'].toStringAsFixed(
                                                                                2),
                                                                            style:
                                                                                const TextStyle(
                                                                              color: Colors.black,
                                                                              fontSize: 14,
                                                                            ))
                                                                      ]),
                                                                  const SizedBox(
                                                                      height:
                                                                          3),
                                                                  Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        const Text(
                                                                            'CGST',
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.grey,
                                                                              fontSize: 12,
                                                                            )),
                                                                        Text(
                                                                            information[index]['CGST'].toStringAsFixed(
                                                                                2),
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.black,
                                                                              fontSize: 14,
                                                                            ))
                                                                      ]),
                                                                  const SizedBox(
                                                                      height:
                                                                          3),
                                                                  Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        const Text(
                                                                            'SGST',
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.grey,
                                                                              fontSize: 12,
                                                                            )),
                                                                        Text(
                                                                            information[index]['SGST'].toStringAsFixed(
                                                                                2),
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.black,
                                                                              fontSize: 14,
                                                                            ))
                                                                      ]),
                                                                  const Divider(
                                                                      color: Colors
                                                                          .green),
                                                                  Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        const Text(
                                                                            'TOTAL',
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.black,
                                                                              fontSize: 12,
                                                                            )),
                                                                        Text(
                                                                            information[index]['Total'].toStringAsFixed(
                                                                                2),
                                                                            style:
                                                                                const TextStyle(
                                                                              color: Colors.black,
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.bold,
                                                                            ))
                                                                      ])
                                                                ]))));
                                              },
                                              child: const Icon(
                                                  Icons.info_outline,
                                                  size: 20,
                                                  color: Colors.blue)),
                                          const SizedBox(width: 3)
                                        ])
                                      ])),
                              Flexible(
                                  flex: 700,
                                  child: Row(children: [
                                    const Text('Q:',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        )),
                                    Text(items.length.toString(),
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ))
                                  ])),
                              Flexible(
                                  flex: 0,
                                  child: Text(
                                      "\u20B9 ${information[index]['GrandTotal'].toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                      )))
                            ]),
                          ])));
                });
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
