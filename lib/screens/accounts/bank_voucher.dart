// @dart = 2.11
import 'dart:convert';
import 'dart:typed_data';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/models/sms_data_model.dart';
import 'package:sheraccerp/screens/html_previews/rpv_preview.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/bt_print.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

import '../../scoped-models/main.dart';

class BankVoucher extends StatefulWidget {
  const BankVoucher({Key key}) : super(key: key);

  @override
  _BankVoucherState createState() => _BankVoucherState();
}

class _BankVoucherState extends State<BankVoucher> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<LedgerModel> cashBankACList = [];
  Size deviceSize;
  List<dynamic> items = [];
  List<String> type = ['', 'CHEQUE', 'RTGS/NFT', 'UPI'];
  List<String> statusType = ['', 'PENDING', 'CLEARED', 'BOUNCED', 'CANCELLED'];
  String dropDownType = '', dropDownStatusType = '';
  List<dynamic> itemDisplay = [];
  DioService api = DioService();
  DateTime now = DateTime.now();
  String formattedDate,
      formattedClearDate,
      chequeNo = '',
      narration = '',
      projectId = '-1';
  double balance = 0, total = 0, amount = 0, discount = 0, bankCharge = 0;
  var accountId = '', accountName = '';
  LedgerModel ledData;
  bool _isLoading = false,
      isSelected = false,
      oldVoucher = false,
      valueMore = false,
      widgetID = true,
      lastRecord = false,
      buttonEvent = false,
      isMultiRvPv = false;
  int refNo = 0, acId = 0;
  int page = 1, pageTotal = 0, totalRecords = 0;
  int locationId = 1,
      salesManId = 0,
      decimal = 2,
      groupId = 0,
      areaId = 0,
      routeId = 0;
  List<CompanySettings> settings;
  CompanyInformation companySettings;
  final TextEditingController _controllerAmount = TextEditingController();
  final TextEditingController _controllerDiscount = TextEditingController();
  final TextEditingController _controllerChequeNo = TextEditingController();
  final TextEditingController _controllerBankCharge = TextEditingController();
  final TextEditingController _controllerNarration = TextEditingController();

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);
    formattedClearDate = formattedDate;
    api.getLedgerByType('SelectbankOnly').then((value) {
      List<LedgerModel> _dataTemp = [];
      for (var ledger in value) {
        _dataTemp
            .add(LedgerModel(id: ledger['ledcode'], name: ledger['LedName']));
      }
      setState(() {
        cashBankACList.addAll(_dataTemp);
      });
    });

    loadSettings();
    loadAsset();
  }

  loadSettings() {
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();
    acId = 0;
    salesManId = ComSettings.appSettings(
            'int', 'key-dropdown-default-salesman-view', 1) -
        1;
    locationId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;
    isMultiRvPv = ComSettings.getStatus('KEY MULTI RV-PV', settings);
    groupId =
        ComSettings.appSettings('int', 'key-dropdown-default-group-view', 0) -
            1;
    areaId =
        ComSettings.appSettings('int', 'key-dropdown-default-area-view', 0) - 1;
    routeId =
        ComSettings.appSettings('int', 'key-dropdown-default-route-view', 0) -
            1;
  }

  @override
  Widget build(BuildContext context) {
    deviceSize = MediaQuery.of(context).size;
    final routes =
        ModalRoute.of(context).settings.arguments as Map<String, String>;
    var title = routes != null ? routes['voucher'].toString() : 'Voucher';
    title = 'Bank $title';
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
                      accountId =
                          int.parse(accountId) > 0 ? accountId.toString() : '0';
                      if (companyUserData.deleteData) {
                        title == 'Bank Payment'
                            ? deleteVoucher('Bank Payment', 'DELETE')
                            : deleteVoucher('Bank Receipt', 'DELETE');
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
                      accountId =
                          int.parse(accountId) > 0 ? accountId.toString() : '0';
                      if (companyUserData.updateData) {
                        title == 'Bank Payment'
                            ? submitData('Bank Payment', 'UPDATE')
                            : submitData('Bank Receipt', 'UPDATE');
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
                      if (accountId.trim().isEmpty) {
                        accountId = int.parse(accountId) > 0
                            ? accountId.toString()
                            : '0';
                      }
                      if (companyUserData.insertData) {
                        title == 'Bank Payment'
                            ? submitData('Bank Payment', 'INSERT')
                            : submitData('Bank Receipt', 'INSERT');
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

  var nameLike = 'a';
  _body(mode) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      child: SingleChildScrollView(
        child: voucherWidget(mode),
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
        var statement = mode == 'Bank Payment' ? 'BPVList' : 'BRVList';
        salesManId = salesManId > 0 ? salesManId : -1;
        locationId = locationId > 0 ? locationId : -1;
        String salesMan = salesManId > 0 ? salesManId.toString() : '';
        api
            .getPaginationList(statement, page, locationId.toString(), '0',
                DateUtil.dateYMD(formattedDate), salesMan)
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
    super.dispose();
  }

  CustomerModel ledgerData;
  ledgerDetailWidget(int id) {
    return FutureBuilder<CustomerModel>(
      future: api.getCustomerDetail(id),
      builder: (context, snapshot) {
        ledgerData = snapshot.data;
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

  void submitData(mode, operation) async {
    if (accountId.isEmpty) {
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
              'amount': amount,
              'discount': discount,
              'total': total,
              'narration': narration,
              'Ledid': ledData.id
            }) +
            ']';
        var data = [
          {
            'entryno': oldVoucher ? dataDynamic[0]['EntryNo'].toString() : '1',
            'nameId': ledData.id,
            'bankId': accountId,
            'type': dropDownType,
            'chequeNo': _controllerChequeNo.text,
            'status': dropDownStatusType,
            'date': formatDMY(formattedDate),
            'clrdate': formatDMY(formattedClearDate),
            'location': locationId,
            'amount': amount,
            'bankCharge': _controllerBankCharge.text.isNotEmpty
                ? '_controllerBankCharge.text'
                : '0',
            'discount': discount,
            'narration': narration,
            'user': userIdC,
            'fyId': currentFinancialYear.id,
            'statementType': operation == 'UPDATE'
                ? mode == 'Bank Payment'
                    ? 'PvUpdate'
                    : 'RvUpdate'
                : mode == 'Bank Payment'
                    ? 'PvInsert'
                    : 'RvInsert'
            //PvFind, RvFind
          }
        ];
        refNo = await api.addBankVoucher(data);
        if (refNo > 0) {
          setState(() {
            _isLoading = false;
            buttonEvent = false;
            if (operation == 'DELETE') {
              showInSnackBar('Deleted');
            } else {
              var dataAll = [
                {
                  'entryno':
                      oldVoucher ? dataDynamic[0]['EntryNo'].toString() : '0',
                  'nameId': ledData.id,
                  'bankId': accountId,
                  'type': dropDownType,
                  'chequeNo': _controllerChequeNo.text,
                  'status': dropDownStatusType,
                  'date': formatDMY(formattedDate),
                  'clrdate': formatDMY(formattedClearDate),
                  'location': locationId,
                  'amount': amount,
                  'bankCharge': _controllerBankCharge.text,
                  'discount': discount,
                  'narration': narration,
                  'user': userIdC,
                  'account': accountName,
                  'name': ledgerData.name,
                  'oldBalance': ledgerData.balance,
                  'message': footerMessage
                }
              ];
              actionShow(mode, context, dataAll);
            }
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

  void deleteVoucher(mode, operation) async {
    if (accountId.isEmpty) {
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
        var entryNo = oldVoucher ? dataDynamic[0]['EntryNo'].toString() : '0';
        var fyId = currentFinancialYear.id;
        var statementType = mode == 'Bank Payment' ? 'PvDelete' : 'RvDelete';
        refNo = await api.deleteBankVoucher(entryNo, fyId, statementType);
        if (refNo > 0) {
          setState(() {
            _isLoading = false;
            buttonEvent = false;
            showInSnackBar('Deleted');
            clearData();
          });
        } else {
          var opr = 'error : Cannot delete this ' + mode;
          showInSnackBar(opr);
        }
      }
    }
  }

  Uint8List byteImage;
  loadAsset() async {
    // Test image
    ByteData bytes = await rootBundle.load('assets/logo.png');
    final buffer = bytes.buffer;
    byteImage = Uint8List.view(buffer);
  }

  actionShow(mode, context, data) async {
    var form = mode == 'Bank Payment' ? 'BANK PAYMENT' : 'BANK RECEIPT';
    var title = mode == 'Bank Payment'
        ? 'Bank Payment Voucher'
        : 'Bank Receipt Voucher';

    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
        },
        onPressedYes: () {
          Navigator.of(context).pop();
          // _showPrinterSize(context).then((value) => printBluetooth(context,
          //     title, companySettings, settings, data, byteImage, value, form));
          sentToPreview(title, form, data);
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage: 'Do you want to preview \nRefNo:${data[0]['entryNo']}',
        title: 'Print Voucher',
        context: context);
  }

  sentToPreview(String title, String form, var data) {
    var dataAll = [data, form];
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RVPreviewShow(title: title, dataAll: dataAll)));
  }

  clearData() {
    _controllerAmount.text = '';
    _controllerDiscount.text = '';
    _controllerNarration.text = '';
    accountId = '';
    accountName = '';
    ledgerData = null;
    _dropDownValue = '';
    balance = 0;
    amount = 0;
    discount = 0;
    narration = '';
    ledData.id = 0;
    ledData.name = '';
    total = 0;
    setState(() {
      isSelected = false;
      widgetID = true;
      oldVoucher = false;
      isLoadingData = false;
      dataDisplay = [];
      lastRecord = false;
      page = 1;
    });
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  calculate(mode) {
    setState(() {
      total = amount + discount + bankCharge;
    });
  }

  var _dropDownValue = '';
  widgetAccount() {
    return DropdownButton<String>(
      hint: Text(_dropDownValue.isNotEmpty
          ? _dropDownValue.split('-')[1]
          : 'Select bank account'),
      items: cashBankACList.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem<String>(
          value: item.id.toString() + "-" + item.name,
          child: Text(item.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _dropDownValue = value;
          accountId = value.split('-')[0];
          accountName = value.split('-')[1];
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

  Future _selectClearDate() async {
    DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(
          () => {formattedClearDate = DateFormat('dd-MM-yyyy').format(picked)});
    }
  }

  String formatDMY(value) {
    var dateTime = DateFormat("dd-mm-yyyy").parse(value.toString());
    return DateFormat("yyyy-mm-dd").format(dateTime);
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
              Text("No data in" + mode),
              TextButton.icon(
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
          clearData();
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

  var footerMessage = '';
  fetchVoucher(context, data, mode) {
    api
        .fetchBankVoucher(
            data['Id'], mode == 'Bank Payment' ? 'FindPv' : 'FindRv')
        .then((value) {
      if (value != null) {
        var information = value[0][0];
        footerMessage = value[1][0]['s_Value'];
        formattedDate = DateUtil.dateDMY(information['DDate']);
        formattedClearDate = DateUtil.dateDMY(information['ClrDate']);

        dataDynamic = [
          {
            'RealEntryNo': information['EntryNo'],
            'EntryNo': information['EntryNo'],
            'InvoiceNo': information['EntryNo'],
            'Type': '0'
          }
        ];
        _dropDownValue = information['BankId'].toString() +
            '-' +
            information['BankName'].toString();
        accountName = information['BankName'].toString();
        accountId = information['BankId'].toString();
        acId = information['NameId'];
        ledData = LedgerModel(
            id: information['NameId'], name: information['LedgerName']);
        amount = double.tryParse(information['Amount'].toString());
        bankCharge = double.tryParse(information['BankCharge'].toString());
        discount = double.tryParse(information['Discount'].toString());
        // total = double.tryParse(information['Total'].toString());
        dropDownType = information['Type'].toString();
        chequeNo = information['ChequeNo'].toString();
        dropDownStatusType = information['Status'].toString();
        narration = information['Narration'].toString();
        setState(() {
          widgetID = false;
          oldVoucher = true;
          isSelected = true;
          _controllerAmount.text = amount.toString();
          _controllerBankCharge.text =
              bankCharge > 0 ? bankCharge.toString() : '';
          _controllerDiscount.text = discount > 0 ? discount.toString() : '';
          _controllerNarration.text = narration.toString();
          _controllerChequeNo.text = chequeNo.toString();
        });
      }
    });
  }

  voucherWidget(var mode) {
    return Column(
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
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              onTap: () => _selectDate(),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text('Bank Account ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            widgetAccount(),
          ],
        ),
        Card(
          elevation: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  var under =
                      mode == 'Bank Payment' ? 'SUPPLIERS' : 'CUSTOMERS';
                  Navigator.pushNamed(context, '/ledger',
                      arguments: {'parent': under});
                },
                child: const Text('Add new ledger'),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: kPrimaryColor,
                ),
                onPressed: () {
                  var under =
                      mode == 'Bank Payment' ? 'SUPPLIERS' : 'CUSTOMERS';
                  Navigator.pushNamed(context, '/ledger',
                      arguments: {'parent': under});
                },
              ),
            ],
          ),
        ),
        const Divider(),
        DropdownSearch<LedgerModel>(
          maxHeight: 300,
          onFind: (String filter) async {
            nameLike = filter.isNotEmpty ? filter : 'a';
            var models = api.getCustomerNameListLike(
                groupId, areaId, routeId, salesManId, nameLike);
            return models;
          },
          isFilteredOnline: true,
          dropdownSearchDecoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: "Select Ledger Name"),
          onChanged: (LedgerModel data) {
            // print(data);
            ledData = data;
            setState(() {
              isSelected = true;
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
        Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: 10,
              ),
              const Text('Type '),
              Expanded(
                child: DropdownButton<String>(
                  hint: const Text('Type'),
                  value: dropDownType,
                  items: type.map<DropdownMenuItem<String>>((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      dropDownType = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextField(
                controller: _controllerChequeNo,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text('Cheque No'),
                ),
                onChanged: (value) {
                  setState(() {
                    chequeNo = value;
                  });
                },
              ),
            ),
          ],
        ),
        Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: 10,
              ),
              const Text('Status '),
              Expanded(
                child: DropdownButton<String>(
                  hint: const Text('Status'),
                  value: dropDownStatusType,
                  items: statusType.map<DropdownMenuItem<String>>((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      dropDownStatusType = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text('Clear Date : '),
              InkWell(
                child: Text(
                  formattedClearDate,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                onTap: () => _selectClearDate(),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextField(
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
            ),
            const SizedBox(
              width: 2,
            ),
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
          ],
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextField(
                controller: _controllerBankCharge,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter(RegExp(r'[0-9]'),
                      allow: true, replacementString: '.')
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text('Bank Charge'),
                ),
                onChanged: (value) {
                  setState(() {
                    bankCharge = value != null
                        ? value.trim().isNotEmpty
                            ? double.tryParse(value)
                            : 0
                        : 0;
                    calculate(mode);
                  });
                },
              ),
            ),
            // Expanded(
            //     child: Text(
            //   'Total : ${total.toStringAsFixed(0)}',
            //   style: const TextStyle(fontWeight: FontWeight.bold),
            // )),
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
                  label: Text('Narration'),
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

  voucherParticularWidget(mode) {}
}
