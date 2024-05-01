// @dart = 2.9
import 'package:flutter/material.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/util/color_palette.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class AlignmentEntry extends StatefulWidget {
  AlignmentEntry({Key key}) : super(key: key);

  @override
  State<AlignmentEntry> createState() => _AlignmentEntryState();
}

class _AlignmentEntryState extends State<AlignmentEntry> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool thisSale = false, _isLoading = false, buttonEvent = false;
  DioService dio = DioService();
  Size deviceSize;
  bool isTax = true,
      otherAmountLoaded = false,
      valueMore = false,
      lastRecord = false,
      widgetID = true,
      previewData = false,
      oldBill = false,
      itemCodeVise = false,
      isItemRateEditLocked = false,
      isMinimumRate = false,
      isItemDiscountEditLocked = false,
      isItemSerialNo = false,
      keyItemsVariantStock = false,
      enableBarcode = false,
      _isReturnInSales = false,
      productTracking = false,
      isFreeItem = false,
      isStockProductOnlyInSalesQO = false,
      isSalesManWiseLedger = false,
      isFreeQty = false;
  DateTime now = DateTime.now();
  String formattedDate, _narration = '';
  int page = 1, pageTotal = 0, totalRecords = 0;
  int saleAccount = 0, acId = 0, decimal = 2;
  List<dynamic> ledgerDisplay = [];
  List<dynamic> _ledger = [];
  List<dynamic> itemDisplay = [];
  List<dynamic> items = [];
  int lId = 0, groupId = 0, areaId = 0, routeId = 0;

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;

    loadSettings();
  }

  loadSettings() {
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();

    String cashAc =
        ComSettings.getValue('CASH A/C', settings).toString().trim() ?? 'CASH';
    try {
      acId = mainAccount
          .firstWhere((element) => element['LedName'] == cashAc)['LedCode'];
      int cashId =
          ComSettings.appSettings('int', 'key-dropdown-default-cash-ac', 0) - 1;
      acId = cashId > 0
          ? mainAccount.firstWhere((element) => element['LedCode'] == cashId,
              orElse: () => {'LedName': cashAc, 'LedCode': acId})['LedCode']
          : acId;
    } catch (e) {
      e.toString();
      acId = -1;
    }
  }

  CompanyInformation companySettings;
  List<CompanySettings> settings;

  @override
  Widget build(BuildContext context) {
    deviceSize = MediaQuery.of(context).size;
    return WillPopScope(
        onWillPop: _onWillPop,
        child: widgetID ? widgetPrefix(thisSale) : widgetSuffix(thisSale));
  }

  Future<bool> _onWillPop() async {
    if (nextWidget == 3) {
      return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Back'),
              content: const Text('Select Item Again?'),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      nextWidget = 2;
                      // clearValue();
                    });
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Select'),
                ),
              ],
            ),
          )) ??
          false;
    } else {
      return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Are you sure?'),
              content: const Text('Do you want to exit Sale'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          )) ??
          false;
    }
  }

  widgetSuffix(thisSale) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Sales"),
          actions: [
            Visibility(
              visible: enableBarcode,
              child: IconButton(
                  onPressed: () {
                    //searchProductBarcode();
                  },
                  icon: const Icon(Icons.document_scanner)),
            ),
            Visibility(
              visible: oldBill,
              child: IconButton(
                  color: red,
                  iconSize: 40,
                  onPressed: () {
                    if (buttonEvent) {
                      return;
                    } else {
                      if (companyUserData.deleteData) {
                        // if (totalItem > 0) {
                        //   setState(() {
                        //     _isLoading = true;
                        //     buttonEvent = true;
                        //   });
                        //   deleteSale(context);
                        // } else {
                        //   Fluttertoast.showToast(
                        //       msg: 'Please select atleast one bill');
                        //   setState(() {
                        //     buttonEvent = false;
                        //   });
                        // }
                      } else {
                        Fluttertoast.showToast(
                            msg: 'Permission denied\ncan`t delete');
                        setState(() {
                          buttonEvent = false;
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever)),
            ),
            oldBill
                ? IconButton(
                    color: green,
                    iconSize: 40,
                    onPressed: () {
                      if (buttonEvent) {
                        return;
                      } else {
                        if (companyUserData.updateData) {
                          // if (totalItem > 0) {
                          //   setState(() {
                          //     _isLoading = true;
                          //     buttonEvent = true;
                          //   });
                          //   updateSale();
                          // } else {
                          //   Fluttertoast.showToast(
                          //       msg: 'Please select atleast one bill');
                          //   setState(() {
                          //     buttonEvent = false;
                          //   });
                          // }
                        } else {
                          Fluttertoast.showToast(
                              msg: 'Permission denied\ncan`t edit');
                          setState(() {
                            buttonEvent = false;
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.edit))
                : IconButton(
                    color: white,
                    iconSize: 40,
                    onPressed: () {
                      if (buttonEvent) {
                        return;
                      } else {
                        if (companyUserData.insertData) {
                          // if (totalItem > 0) {
                          //   setState(() {
                          //     _isLoading = true;
                          //     buttonEvent = true;
                          //   });
                          //   saveSale();
                          // } else {
                          //   Fluttertoast.showToast(
                          //       msg: 'Please add at least one item');
                          //   setState(() {
                          //     buttonEvent = false;
                          //   });
                          // }
                        } else {
                          Fluttertoast.showToast(
                              msg: 'Permission denied\ncan`t save');
                          setState(() {
                            buttonEvent = false;
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.save)),
          ],
        ),
        body: ProgressHUD(
            inAsyncCall: _isLoading, opacity: 0.0, child: selectWidget()));
  }

  widgetPrefix(thisSale) {
    setState(() {
      if (thisSale) {
        previewData = true;
      }
    });

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("AlignmentEntry"),
          actions: [
            Visibility(
              visible: previewData,
              child: TextButton(
                  child: Text(
                    previewData ? "New AlignmentEntry" : 'AlignmentEntry',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[700],
                  ),
                  onPressed: () async {
                    setState(() {
                      widgetID = false;
                    });
                  }),
            ),
          ],
        ),
        body: previewData
            ? Container(
                child: previousBill(),
              )
            : const Center(child: Text('Alignment Entry')));
  }

  final ScrollController _scrollController = ScrollController();
  bool isLoadingData = false;
  List dataDisplay = [];

  void _getMoreData() async {
    if (!lastRecord) {
      if (dataDisplay.isEmpty ||
          // ignore: curly_braces_in_flow_control_structures
          dataDisplay.length < totalRecords) if (!isLoadingData) {
        setState(() {
          isLoadingData = true;
        });

        List tempList = [];
        var statement = 'SalesList';
        var locationId = lId.toString().trim().isNotEmpty ? lId : lId;

        dio
            .getPaginationList(statement, page, locationId.toString(), '0',
                DateUtil.dateYMD(formattedDate), '0')
            .then((value) {
          if (value.isEmpty) {
            return;
          }
          final response = value;
          pageTotal = response[1][0]['Filtered'];
          totalRecords = response[1][0]['Total'];
          page++;
          for (int i = 0; i < response[0].length; i++) {
            tempList.add(response[0][i]);
          }

          if (mounted) {
            setState(() {
              isLoadingData = false;
              dataDisplay.addAll(tempList);
              lastRecord = tempList.isNotEmpty ? false : true;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  previousBill() {
    _getMoreData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreData();
      }
    });
    return dataDisplay.isNotEmpty
        ? ListView.builder(
            itemCount: dataDisplay.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == dataDisplay.length) {
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
                return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    height: 80,
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 5),
                          blurRadius: 6,
                          color: const Color(0xff000000).withOpacity(0.06),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dataDisplay[index]['Name'],
                                  // maxLines: 1,
                                  style: const TextStyle(
                                    // fontSize: 16,
                                    color: ColorPalette.timberGreen,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Date :${dataDisplay[index]['Date']}',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ColorPalette.timberGreen
                                            .withOpacity(0.44),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 5,
                                        top: 2,
                                        right: 5,
                                      ),
                                      child: Icon(
                                        Icons.circle,
                                        size: 5,
                                        color: ColorPalette.timberGreen
                                            .withOpacity(0.44),
                                      ),
                                    ),
                                    Text(
                                      'EntryNo :${dataDisplay[index]['Id'].toString()}',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ColorPalette.timberGreen
                                            .withOpacity(0.44),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              showEditDialog(context, dataDisplay[index]);
                            },
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ColorPalette.nileBlue,
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                        '${dataDisplay[index]['Total'].toStringAsFixed(decimal)}'),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // showDetails(context, dataDisplay[index]);
                            },
                          ),
                        ),
                      ],
                    ));
                // return Card(
                //   elevation: 3,
                //   clipBehavior: Clip.hardEdge,
                //   margin: EdgeInsets.all(2),
                //   child: ListTile(
                //     title: Text(dataDisplay[index]['Name']),
                //     subtitle: Text('Date: ' +
                //         dataDisplay[index]['Date'] +
                //         ' / EntryNo : ' +
                //         dataDisplay[index]['Id'].toString()),
                //     trailing: Text(
                //         'Total : ' + dataDisplay[index]['Total'].toString()),
                //     onTap: () {
                //       if (userRole == 'SALESMAN') {
                //         showEditDialog(context, dataDisplay[index]);
                //       } else {
                //         showEditDialog(context, dataDisplay[index]);
                //       }
                //     },
                //   ),
                // );

              }
            },
            controller: _scrollController,
          )
        : Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Empty AlignmentEntry"),
              TextButton.icon(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(kPrimaryColor),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                  onPressed: () {
                    setState(() {
                      widgetID = false;
                    });
                  },
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Take New AlignmentEntry'))
            ],
          ));
  }

  showEditDialog(context, dataDynamic) {
    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
        },
        onPressedYes: () {
          Navigator.of(context).pop();
          // fetchEntry(context, dataDynamic);
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage:
            'Do you want to edit or delete\nRefNo:${dataDynamic['Id']}',
        title: 'Update',
        context: context);
  }

  int nextWidget = 0;
  selectWidget() {
    // return nextWidget == 0
    //     ? selectLedgerWidget()
    //     : nextWidget == 1
    //         ? selectLedgerDetailWidget()
    //         : nextWidget == 2
    //             ? selectProductWidget()
    //             : nextWidget == 3
    //                 ? itemDetailWidget()
    //                 : nextWidget == 4
    //                     ? cartProduct()
    //                     : nextWidget == 5
    //                         ? const Text('No Data 5')
    //                         : nextWidget == 6
    //                             ? const Text('No Data 6')
    //                             :
    return const Text('No Widget');
  }

  var nameLike = "a";
  selectLedgerWidget() {
    return FutureBuilder<List<dynamic>>(
      future: isSalesManWiseLedger
          ? dio.getLedgerBySalesManLike(0, nameLike)
          : dio.getCustomerNameListLike(groupId, areaId, routeId, 0, nameLike),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            return ListView.builder(
              // shrinkWrap: true,
              itemBuilder: (context, index) {
                return index == 0
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Flexible(
                              child: TextField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  label: Text('Search...'),
                                ),
                                onChanged: (text) {
                                  text = text.toLowerCase();
                                  setState(() {
                                    // ledgerDisplay = _ledger.where((item) {
                                    //   var itemName = item.name.toLowerCase();
                                    // return itemName.contains(text);
                                    // }).toList();
                                    nameLike = text.isNotEmpty ? text : 'a';
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: kPrimaryColor,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/ledger',
                                    arguments: {'parent': 'CUSTOMERS'});
                              },
                            )
                          ],
                        ),
                      )
                    : InkWell(
                        child: Card(
                          child: ListTile(title: Text(data[index - 1].name)),
                        ),
                        onTap: () {
                          setState(() {
                            // ledgerModel = data[index - 1];
                            nextWidget = 1;
                            isData = false;
                          });
                        },
                      );
              },
              itemCount: data.length + 1,
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

  bool isData = false;

  selectLedgerDetailWidget() {
    return FutureBuilder<CustomerModel>(
      future: dio.getCustomerDetail(0),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.id != null || snapshot.data.id > 0) {
            return Padding(
              padding: const EdgeInsets.all(35.0),
              child: snapshot.data.name == 'CASH'
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          SizedBox(
                            width: 40,
                          ),
                        ]),
                        const Text(
                          'NAME ',
                          style: TextStyle(color: blue),
                        ),
                        InkWell(
                          child: Text(snapshot.data.name,
                              style: const TextStyle(fontSize: 20)),
                          onTap: () {
                            setState(() {
                              nextWidget = 0;
                              nameLike = 'a';
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              label: Text('Customer Name'),
                            ),
                            onChanged: (value) {
                              // setState(() {
                              //   customerName = value.isNotEmpty
                              //       ? value.toUpperCase()
                              //       : 'CASH';
                              // });
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // if (salesTypeData.rateType.isNotEmpty) {
                              //   rateType = salesTypeData.id.toString();
                              // }
                              // ledgerModel = CustomerModel(
                              //     id: snapshot.data.id,
                              //     name: customerName,
                              //     address1: snapshot.data.address1,
                              //     address2: snapshot.data.address2,
                              //     address3: snapshot.data.address3,
                              //     address4: snapshot.data.address4,
                              //     balance: snapshot.data.balance,
                              //     city: snapshot.data.city,
                              //     email: snapshot.data.email,
                              //     phone: snapshot.data.phone,
                              //     route: snapshot.data.route,
                              //     state: snapshot.data.state,
                              //     stateCode: snapshot.data.stateCode,
                              //     taxNumber: snapshot.data.taxNumber);
                              nextWidget = 2;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              elevation: 0,
                              primary: kPrimaryColor,
                              onPrimary: white,
                              onSurface: grey),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const <Widget>[
                                Icon(
                                  Icons.shopping_bag,
                                  color: white,
                                ),
                                SizedBox(
                                  width: 4.0,
                                ),
                                Text(
                                  "Add Product To Cart",
                                  style: TextStyle(color: white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Name',
                          style: TextStyle(
                              color: blue, fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          child: Text(snapshot.data.name,
                              style: const TextStyle(fontSize: 20)),
                          onTap: () {
                            setState(() {
                              nextWidget = 0;
                              nameLike = 'a';
                            });
                          },
                        ),
                        const Text(
                          'Address',
                          style: TextStyle(
                              color: blue, fontWeight: FontWeight.bold),
                        ),
                        Text(
                            snapshot.data.address1 +
                                " ," +
                                snapshot.data.address2 +
                                " ," +
                                snapshot.data.address3 +
                                " ," +
                                snapshot.data.address4,
                            style: const TextStyle(fontSize: 18)),
                        const Text(
                          'Tax No',
                          style: TextStyle(
                              color: blue, fontWeight: FontWeight.bold),
                        ),
                        Text(snapshot.data.taxNumber,
                            style: const TextStyle(fontSize: 18)),
                        const Text(
                          'Phone',
                          style: TextStyle(
                              color: blue, fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          child: Text(snapshot.data.phone,
                              style: const TextStyle(fontSize: 18)),
                          onDoubleTap: () => callNumber(snapshot.data.phone),
                        ),
                        const Text(
                          'Email',
                          style: TextStyle(
                              color: blue, fontWeight: FontWeight.bold),
                        ),
                        Text(snapshot.data.email,
                            style: const TextStyle(fontSize: 18)),
                        const Text(
                          'Balance',
                          style: TextStyle(
                              color: blue, fontWeight: FontWeight.bold),
                        ),
                        Text(snapshot.data.balance,
                            style: const TextStyle(fontSize: 18)),
                        ElevatedButton(
                          onPressed: () {
                            // setState(() {
                            //   if (salesTypeData.type == 'SALES-BB') {
                            //     if (snapshot.data.taxNumber.isNotEmpty) {
                            //       if (salesTypeData.rateType.isNotEmpty) {
                            //         rateType = salesTypeData.id.toString();
                            //       }
                            //       ledgerModel = snapshot.data;
                            //       nextWidget = 2;
                            //     } else {
                            //       ScaffoldMessenger.of(context).showSnackBar(
                            //           const SnackBar(
                            //               content: Text(
                            //                   'B2B Invoice not allow without a TAX number')));
                            //     }
                            //   } else {
                            //     if (salesTypeData.rateType.isNotEmpty) {
                            //       rateType = salesTypeData.id.toString();
                            //     }
                            //     ledgerModel = snapshot.data;
                            //     nextWidget = 2;
                            //   }
                            // });
                          },
                          style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: kPrimaryDarkColor,
                              foregroundColor: white,
                              disabledBackgroundColor: grey),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const <Widget>[
                                Icon(
                                  Icons.shopping_bag,
                                  color: white,
                                ),
                                SizedBox(
                                  width: 4.0,
                                ),
                                Text(
                                  "Add Product To Cart",
                                  style: TextStyle(color: white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  callNumber(number) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(number);
    } catch (_e) {
      debugPrint(_e);
    }
  }
}
