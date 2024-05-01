// @dart = 2.11
import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/inv_pr_model.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/inventory/sales/sales_list.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class InvRPVoucher extends StatefulWidget {
  const InvRPVoucher({Key key}) : super(key: key);

  @override
  State<InvRPVoucher> createState() => _InvRPVoucherState();
}

class _InvRPVoucherState extends State<InvRPVoucher> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<LedgerModel> cashBankACList = [];
  List<InvoiceParticulars> particular = [];
  Size deviceSize;
  List<dynamic> items = [];
  List<dynamic> itemDisplay = [];
  DioService api = DioService();
  DateTime now = DateTime.now();
  String formattedDate, narration = '';
  double balance = 0, total = 0, amount = 0, discount = 0;
  var _invoiceData;
  LedgerModel ledData;
  bool _isLoading = false,
      isSelected = false,
      oldVoucher = false,
      valueMore = false,
      widgetID = true,
      lastRecord = false,
      lastRecordBill = false,
      buttonEvent = false,
      isBillSelected = false;
  int refNo = 0, acId = 0;
  int page = 1,
      pageBill = 1,
      pageTotal = 0,
      pageTotalBill = 0,
      totalRecords = 0,
      totalRecordsBill = 0;
  int locationId = 1, salesManId = -1, decimal = 2;
  final TextEditingController _controllerAmount = TextEditingController();
  final TextEditingController _controllerDiscount = TextEditingController();
  final TextEditingController _controllerNarration = TextEditingController();

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    api.getCashBankAc().then((value) {
      setState(() {
        cashBankACList.addAll(value);
      });
    });

    loadSettings();
  }

  loadSettings() {
    // var companySettings =
    //     ScopedModel.of<MainModel>(context).getCompanySettings()[0];
    var settings = ScopedModel.of<MainModel>(context).getSettings();

    String cashAc =
        ComSettings.getValue('CASH A/C', settings).toString().trim() ?? 'CASH';
    acId = mainAccount
        .firstWhere((element) => element['LedName'] == cashAc)['LedCode'];
    int cashId =
        ComSettings.appSettings('int', 'key-dropdown-default-cash-ac', 0) - 1;
    acId = cashId > 0
        ? mainAccount.firstWhere((element) => element['LedCode'] == cashId,
            orElse: () => {'LedName': cashAc, 'LedCode': acId})['LedCode']
        : acId;

    salesManId = ComSettings.appSettings(
            'int', 'key-dropdown-default-salesman-view', 1) -
        1;
    locationId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;

    for (var data in salesTypeList) {
      if (data.stock) dataSType.add({'id': data.id});
    }
  }

  @override
  Widget build(BuildContext context) {
    deviceSize = MediaQuery.of(context).size;
    final routes =
        ModalRoute.of(context).settings.arguments as Map<String, String>;
    var title = routes != null ? routes['voucher'].toString() : 'Voucher';
    return WillPopScope(
        onWillPop: _onWillPop,
        child: widgetID ? widgetPrefix(title) : widgetSuffix(title));
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit'),
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

  widgetSuffix(title) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          actions: [
            Visibility(
              visible: oldVoucher,
              child: IconButton(
                  color: red,
                  iconSize: 40,
                  onPressed: () {
                    //delete
                    if (buttonEvent) {
                      return;
                    } else {
                      if (companyUserData.deleteData) {
                        title == 'Payment Invoice'
                            ? submitData('Payment Invoice', 'DELETE')
                            : submitData('Receipt  Invoice', 'DELETE');
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
            oldVoucher
                ? IconButton(
                    color: white,
                    iconSize: 40,
                    onPressed: () {
                      //edit
                      if (companyUserData.updateData) {
                        title == 'Payment Invoice'
                            ? submitData('Payment Invoice', 'UPDATE')
                            : submitData('Receipt  Invoice', 'UPDATE');
                      } else {
                        Fluttertoast.showToast(
                            msg: 'Permission denied\ncan`t edit');
                        setState(() {
                          buttonEvent = false;
                        });
                      }
                    },
                    icon: const Icon(Icons.edit))
                : IconButton(
                    color: white,
                    iconSize: 40,
                    onPressed: () {
                      //save
                      if (companyUserData.insertData) {
                        title == 'Payment Invoice'
                            ? submitData('Payment Invoice', 'INSERT')
                            : submitData('Receipt  Invoice', 'INSERT');
                      } else {
                        Fluttertoast.showToast(
                            msg: 'Permission denied\ncan`t save');
                        setState(() {
                          buttonEvent = false;
                        });
                      }
                    },
                    icon: const Icon(Icons.save)),
          ],
          title: Text(title),
        ),
        body: ProgressHUD(
          inAsyncCall: _isLoading,
          opacity: 0.0,
          child: cashBankACList.isNotEmpty ? _body(title) : const Loading(),
        ));
  }

  _body(mode) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text(
                'Date : ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              InkWell(
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                onTap: () => _selectDate(),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text('Cash Account',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              widgetAccount(),
            ],
          ),
          DropdownSearch<LedgerModel>(
            maxHeight: 300,
            onFind: (String filter) => api.getLedgerData(filter),
            dropdownSearchDecoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text('Select Ledger Name')),
            onChanged: (LedgerModel data) {
              ledData = data;
              setState(() {
                isSelected = true;
                dataDisplayBill.clear();
                isBillSelected = false;
                amount = 0;
                discount = 0;
                total = 0;
                _controllerAmount.text = '';
                _controllerDiscount.text = '';
                _controllerNarration.text = '';
                pageBill = 1;
                pageTotalBill = 0;
                totalRecordsBill = 0;
                _invoiceData = null;
              });
            },
            showSearchBox: true,
            selectedItem: ledData,
          ),
          const Divider(),
          isSelected
              ? ledgerDetailWidget(ledData.id)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                        child: Text(
                      'Balance : 0',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )),
                  ],
                ),
          const Divider(),
          isSelected
              ? isBillSelected
                  ? _loadParticular(mode)
                  : _loadBillData(mode)
              : Container(),
        ],
      ),
    );
  }

  widgetPrefix(mode) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          actions: [
            TextButton(
                child: const Text(
                  " New ",
                  style: TextStyle(
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
          ],
          title: Text(mode),
        ),
        body: Container(
          child: previousBill(mode),
        ));
  }

  final ScrollController _scrollController = ScrollController();
  bool isLoadingData = false;
  List dataDisplay = [];

  void _getMoreData(mode) async {
    if (!lastRecord) {
      if (dataDisplay.isEmpty ||
          // ignore: curly_braces_in_flow_control_structures
          dataDisplay.length < totalRecords) if (!isLoadingData) {
        setState(() {
          isLoadingData = true;
        });

        List tempList = [];
        var _type = mode == 'Payment Invoice' ? 'PV' : 'RV';
        salesManId = salesManId > 0 ? salesManId : -1;
        locationId = locationId > 0 ? locationId : 1;
        api
            .getPaginationList('InvoicePRList', page, locationId.toString(),
                _type, DateUtil.dateYMD(formattedDate), salesManId.toString())
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

          setState(() {
            isLoadingData = false;
            dataDisplay.addAll(tempList);
            lastRecord = tempList.isNotEmpty ? false : true;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollControllerBill.dispose();
    super.dispose();
  }

  ledgerDetailWidget(int id) {
    return FutureBuilder<CustomerModel>(
      future: api.getCustomerDetail(id),
      builder: (context, snapshot) {
        return snapshot.hasData
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(
                    'Balance : ${snapshot.data.balance}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(
                      child: Text(
                    'Balance : 0',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
                ],
              );
      },
    );
  }

  _loadParticular(mode) {
    return Column(
      children: [
        const Divider(
          color: black,
          height: 10,
          thickness: 2,
        ),
        Card(
          child: ListTile(
            title: Text('Entry Type : ${_invoiceData['Stype'].toString()}'),
            subtitle: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "Entry No : ${_invoiceData['entryno']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("Invoice No : ${_invoiceData['invoiceNo']}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            trailing: Text('Balance : ${_invoiceData['Balance'].toString()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: _controllerAmount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter(RegExp(r'[0-9]'),
                          allow: true, replacementString: '.')
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Amount'),
                    ),
                    onChanged: (value) {
                      setState(() {
                        amount = value != null
                            ? value.trim().isNotEmpty
                                ? double.tryParse(value)
                                : 0
                            : 0;
                        calculate(mode);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controllerDiscount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter(RegExp(r'[0-9]'),
                      allow: true, replacementString: '.')
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text('Discount'),
                ),
                onChanged: (value) {
                  setState(() {
                    discount = value != null
                        ? value.trim().isNotEmpty
                            ? double.tryParse(value)
                            : 0
                        : 0;
                    calculate(mode);
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
              'Total : ${total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
          ],
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextField(
                controller: _controllerNarration,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text('Narration...'),
                ),
                onChanged: (value) {
                  setState(() {
                    narration = value;
                  });
                },
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  _loadBillData(mode) {
    _getMoreBillData(mode);
    _scrollControllerBill.addListener(() {
      if (_scrollControllerBill.position.pixels ==
          _scrollControllerBill.position.maxScrollExtent) {
        _getMoreBillData(mode);
      }
    });

    return dataDisplayBill.isNotEmpty
        ? Expanded(
            child: SizedBox(
              height: deviceSize.height - 30,
              child: ListView.builder(
                itemCount: dataDisplayBill.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index == dataDisplayBill.length) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Opacity(
                          opacity: isLoadingDataBill ? 1.0 : 00,
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                    );
                  } else {
                    return InkWell(
                        child: Center(
                            child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Stack(children: [
                                  Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: const LinearGradient(
                                          colors: [
                                            Color.fromARGB(255, 151, 211, 239),
                                            Color.fromARGB(255, 195, 211, 241)
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
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                dataDisplayBill[index]['Stype'],
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                              Text(
                                                'Date       : ' +
                                                    dataDisplayBill[index]
                                                            ['Ddate']
                                                        .toString(),
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                'EntryNo : ' +
                                                    dataDisplayBill[index]
                                                            ['entryno']
                                                        .toString(),
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total      : ' +
                                                dataDisplayBill[index]
                                                        ['grandtotal']
                                                    .toStringAsFixed(2),
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            'Balance : ' +
                                                dataDisplayBill[index]
                                                        ['Balance']
                                                    .toStringAsFixed(2),
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ))
                                ]))),
                        onTap: () {
                          setState(() {
                            isBillSelected = true;
                            _invoiceData = dataDisplayBill[index];
                            _controllerAmount.text = double.tryParse(
                                        dataDisplayBill[index]['Balance']
                                            .toString()) >
                                    0
                                ? dataDisplayBill[index]['Balance'].toString()
                                : '';
                            amount = _controllerAmount.text.isNotEmpty
                                ? double.tryParse(_controllerAmount.text)
                                : 0;
                            calculate(mode);
                          });
                        });
                  }
                },
                controller: _scrollControllerBill,
              ),
            ),
          )
        : Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("No data in " + mode),
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
                  label: Text('Take New ' + mode))
            ],
          ));
  }

  final ScrollController _scrollControllerBill = ScrollController();
  bool isLoadingDataBill = false;
  List dataDisplayBill = [];
  List<dynamic> dataSType = [];

  void _getMoreBillData(mode) async {
    if (!lastRecordBill) {
      if (dataDisplayBill.isEmpty ||
          // ignore: curly_braces_in_flow_control_structures
          dataDisplayBill.length < totalRecordsBill) if (!isLoadingDataBill) {
        setState(() {
          isLoadingDataBill = true;
        });

        List tempList = [];
        var _type = mode == 'Payment Invoice' ? 'PV' : 'RV';
        int _id = ledData != null ? ledData.id : 0;
        locationId = locationId > 0 ? locationId : -1;

        api
            .getPaginationList(
                'InvoiceVoucherList',
                pageBill,
                locationId.toString(),
                _type,
                DateUtil.dateYMD(formattedDate),
                _id.toString())
            .then((value) {
          final response = value;
          pageTotalBill = response[1][0]['Filtered'];
          totalRecordsBill = response[1][0]['Total'];
          pageBill++;
          for (int i = 0; i < response[0].length; i++) {
            tempList.add(response[0][i]);
          }

          setState(() {
            isLoadingDataBill = false;
            dataDisplayBill.addAll(tempList);
            lastRecordBill = tempList.isNotEmpty ? false : true;
          });
        });
      }
    }
  }

  void submitData(mode, operation) async {
    if (acId.toString().isEmpty && acId > 0) {
      Fluttertoast.showToast(msg: 'Select Cash Account');
    } else {
      if (amount <= 0 || ledData.id <= 0) {
        Fluttertoast.showToast(msg: 'Select Account and amount');
        setState(() {
          buttonEvent = false;
        });
      } else {
        setState(() {
          _isLoading = true;
          buttonEvent = true;
        });
        var particular = '[' +
            json.encode({
              'ledger': ledData.id,
              'entryType': _invoiceData['Stype'].toString(),
              'pEntryNo': _invoiceData['entryno'].toString(),
              'invoiceNo': _invoiceData['invoiceNo'].toString(),
              'date': operation == 'UPDATE' || operation == 'DELETE'
                  ? _invoiceData['Ddate']
                  : DateUtil.dateYMD1(_invoiceData['Ddate'].toString()),
              'amount': amount,
              'discount': discount,
              'total': total,
              'narration': narration
            }) +
            ']';
        var data = [
          {
            'entryNo': oldVoucher ? dataDynamic[0]['EntryNo'].toString() : '0',
            'date': DateUtil.dateYMD(formattedDate),
            'debitAccount': acId.toString(),
            'amount': amount,
            'discount': discount,
            'total': total,
            'location': 1,
            'user': 1,
            'project': -1,
            'salesman': salesManId,
            'month': '2022-01-01',
            'particular': particular,
            'vType': mode == 'Payment Invoice' ? 'PV' : 'RV',
            'fyId': currentFinancialYear.id
          }
        ];
        if (operation == 'DELETE') {
          var id = oldVoucher ? dataDynamic[0]['EntryNo'].toString() : '0';
          var type = mode == 'Payment Invoice' ? 'PV' : 'RV';
          refNo = await api.deleteInvoiceVoucher(id, type);
        } else if (operation == 'UPDATE') {
          refNo = await api.editInvoiceVoucher(data);
        } else {
          refNo = await api.addInvoiceVoucher(data);
        }
        if (refNo > 0) {
          setState(() {
            _isLoading = false;
            buttonEvent = false;
            showInSnackBar(operation == 'DELETE'
                ? 'Deleted : ' + mode + ' voucher.'
                : operation == 'UPDATE'
                    ? 'Update : ' + mode + ' voucher.'
                    : 'Saved : ' + mode + ' voucher.');
            clearData();
          });
        } else {
          var opr = operation == 'DELETE'
              ? 'error : Cannot delete this ' + mode
              : operation == 'UPDATE'
                  ? 'error : Cannot update this ' + mode
                  : 'error : Cannot save this ' + mode;
          showInSnackBar(opr);
        }
      }
    }
  }

  clearData() {
    _controllerAmount.text = '';
    _controllerDiscount.text = '';
    _controllerNarration.text = '';
    acId = 0;
    _dropDownValue = '';
    balance = 0;
    amount = 0;
    discount = 0;
    narration = '';
    ledData.id = 0;
    ledData.name = '';
    total = 0;
    isSelected = false;
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  calculate(mode) {
    setState(() {
      total =
          mode == 'Payment Invoice' ? (amount + discount) : (amount - discount);
    });
  }

  var _dropDownValue = '';
  widgetAccount() {
    return DropdownButton<String>(
      hint: Text(_dropDownValue.isNotEmpty
          ? _dropDownValue.split('-')[1]
          : 'Select cash account'),
      items: cashBankACList.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem<String>(
          value: item.id.toString() + "-" + item.name,
          child: Text(item.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _dropDownValue = value;
          acId = int.parse(value.split('-')[0]);
        });
      },
    );
  }

  Future _selectDate() async {
    DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => {formattedDate = DateFormat('dd-MM-yyyy').format(picked)});
    }
  }

  previousBill(mode) {
    _getMoreData(mode);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreData(mode);
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
                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(dataDisplay[index]['Name']),
                    subtitle: Text('Date: ' +
                        dataDisplay[index]['Date'] +
                        ' / EntryNo : ' +
                        dataDisplay[index]['Id'].toString()),
                    trailing: Text(
                        'Total : ' + dataDisplay[index]['Total'].toString()),
                    onTap: () {
                      showEditDialog(context, dataDisplay[index], mode);
                    },
                  ),
                );
              }
            },
            controller: _scrollController,
          )
        : Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("No data in " + mode),
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
                  label: Text('Take New ' + mode))
            ],
          ));
  }

  showEditDialog(context, dataDynamic, mode) {
    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
        },
        onPressedYes: () {
          Navigator.of(context).pop();
          fetchVoucher(context, dataDynamic, mode);
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage:
            'Do you want to edit or delete\nRefNo:${dataDynamic['Id']}',
        title: 'Update',
        context: context);
  }

  fetchVoucher(context, data, mode) {
    double voucherTotal = 0;
    int row = 0;
    api
        .fetchInvoiceVoucher(
            data['Id'], mode == 'Payment Invoice' ? 'PV' : 'RV')
        .then((value) {
      if (value != null) {
        var information = value[0][0];
        var particulars = value[1];
        List c = value[1].toList();
        row = c.length;
        formattedDate = DateUtil.dateDMY(information['DDATE']);

        dataDynamic = [
          {
            'RealEntryNo': information['EntryNo'],
            'EntryNo': information['EntryNo'],
            'InvoiceNo': information['EntryNo'],
            'Type': '0'
          }
        ];

        voucherTotal = double.tryParse(information['Total'].toString());
        LedgerModel acLedger = cashBankACList.firstWhere(
            (element) =>
                element.id == int.parse(information['DEBITACCOUNT'].toString()),
            orElse: () => LedgerModel(
                id: int.parse(information['DEBITACCOUNT'].toString()),
                name: '-CASH'));
        _dropDownValue = '${acLedger.id}-${acLedger.name}';
        acId = information['DEBITACCOUNT'];
        var part1 = particulars[0];
        ledData = LedgerModel(id: part1['Name'], name: '');
        amount = double.tryParse(part1['Amount'].toString());
        discount = double.tryParse(part1['Discount'].toString());
        total = double.tryParse(part1['Total'].toString());
        narration = part1['Narration'].toString();
        // 'entryType': _invoiceData['Stype'].toString(),
        // 'pEntryNo': _invoiceData['entryno'].toString(),
        // 'invoiceNo': _invoiceData['invoiceNo'].toString(),
        // 'date': DateUtil.dateYMD(_invoiceData['Ddate'].toString()),
        _invoiceData = {
          'Stype': part1['VoucherType'],
          'entryno': part1['EntryNo'],
          'invoiceNo': part1['InvoiceNo'],
          'Ddate': part1['Pdate'],
          'Balance': part1['Amount'],
        };
      }

      api.getCustomerDetail(ledData.id).then((data) {
        setState(() {
          ledData.name = data.name;
        });
      });
      setState(() {
        if (row <= 1) {
          widgetID = false;
          oldVoucher = true;
          isSelected = true;
          isBillSelected = true;
          _controllerAmount.text = amount.toString();
          _controllerDiscount.text = discount > 0 ? discount.toString() : '';
          _controllerNarration.text = narration.toString();
        }
      });
    });
  }
}
