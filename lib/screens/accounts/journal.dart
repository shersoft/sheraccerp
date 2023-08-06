// @dart = 2.11

import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';

import '../../models/company.dart';
import '../../models/ledger_name_model.dart';
import '../../scoped-models/main.dart';
import '../../service/api_dio.dart';
import '../../service/com_service.dart';
import '../../shared/constants.dart';
import '../../util/dateUtil.dart';
import '../../util/res_color.dart';
import '../../widget/progress_hud.dart';

class Journal extends StatefulWidget {
  const Journal({Key key}) : super(key: key);

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> {
  DioService api = DioService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Size deviceSize;
  DateTime now = DateTime.now();
  String formattedDate, narration = '';
  List<LedgerModel> ledgerList = [];
  LedgerModel ledgerDebitData, ledgerCreditData;
  bool _isLoading = false,
      isSelected = false,
      oldVoucher = false,
      valueMore = false,
      widgetID = true,
      lastRecord = false,
      buttonEvent = false;
  int refNo = 0;
  int page = 1, pageTotal = 0, totalRecords = 0;
  int locationId = 1, salesManId = 0, decimal = 2;
  List<CompanySettings> settings;
  CompanyInformation companySettings;
  final TextEditingController _controllerAmount = TextEditingController();
  FocusNode _focusNode = FocusNode();
  final TextEditingController _controllerNarration = TextEditingController();
  double amount = 0;

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);
    loadSettings();
    loadAsset();
  }

  loadSettings() {
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();
    salesManId = ComSettings.appSettings(
            'int', 'key-dropdown-default-salesman-view', 1) -
        1;
    locationId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;

    api.getLedgerAll().then((value) => ledgerList.addAll(value));
  }

  @override
  Widget build(BuildContext context) {
    _controllerAmount.selection = TextSelection.fromPosition(
        TextPosition(offset: _controllerAmount.text.length));

    deviceSize = MediaQuery.of(context).size;
    return WillPopScope(
        onWillPop: _onWillPop,
        child: widgetID ? widgetPrefix() : widgetSuffix());
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

  widgetSuffix() {
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
                        submitData('DELETE');
                      } else {
                        showInSnackBar('Permission denied\ncan`t delete');
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
                        submitData('UPDATE');
                      } else {
                        showInSnackBar('Permission denied\ncan`t edit');
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
                        submitData('INSERT');
                      } else {
                        showInSnackBar('Permission denied\ncan`t save');
                        setState(() {
                          buttonEvent = false;
                        });
                      }
                    },
                    icon: const Icon(Icons.save)),
          ],
          title: const Text('Journal'),
        ),
        body: ProgressHUD(
          inAsyncCall: _isLoading,
          opacity: 0.0,
          child: _body(),
        ));
  }

  var nameLike = 'a';
  _body() {
    return Container(
      padding: const EdgeInsets.all(6.0),
      child: SingleChildScrollView(
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
            Card(
              elevation: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/ledger',
                          arguments: {'parent': ''});
                    },
                    child: const Text('Add new ledger'),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: kPrimaryColor,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/ledger',
                          arguments: {'parent': ''});
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
                var models = ledgerUserFilterCreation(ledgerList, nameLike);
                return models;
              },
              isFilteredOnline: true,
              dropdownSearchDecoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Select Debit Account"),
              onChanged: (LedgerModel data) {
                debugPrint(data.toString());
                ledgerDebitData = data;
                setState(() {
                  isSelected = true;
                });
              },
              showSearchBox: true,
              selectedItem: ledgerDebitData,
            ),
            const Divider(),
            DropdownSearch<LedgerModel>(
              maxHeight: 300,
              onFind: (String filter) async {
                nameLike = filter.isNotEmpty ? filter : 'a';
                var models = ledgerUserFilterCreation(ledgerList, nameLike);
                return models;
              },
              isFilteredOnline: true,
              dropdownSearchDecoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Select Credit Account"),
              onChanged: (LedgerModel data) {
                ledgerCreditData = data;
                setState(() {
                  isSelected = true;
                });
              },
              showSearchBox: true,
              selectedItem: ledgerCreditData,
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controllerAmount,
                    focusNode: _focusNode,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
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
        ),
      ),
    );
  }

  widgetPrefix() {
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
          title: const Text('Journal'),
        ),
        body: Container(
          child: previousBill(),
        ));
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
        var statement = 'JVList';
        salesManId = salesManId > 0 ? salesManId : -1;
        locationId = locationId > 0 ? locationId : -1;
        api
            .getPaginationList(statement, page, locationId.toString(), '0',
                DateUtil.dateYMD(formattedDate), salesManId.toString())
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
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
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

  String formatDMY(value) {
    var dateTime = DateFormat("dd-mm-yyyy").parse(value.toString());
    return DateFormat("yyyy-mm-dd").format(dateTime);
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
                      showEditDialog(context, dataDisplay[index]);
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
              const Text("No data in Journal"),
              TextButton.icon(
                  onPressed: () {
                    setState(() {
                      widgetID = false;
                    });
                  },
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Take New Journal'))
            ],
          ));
  }

  void submitData(operation) async {
    amount = _controllerAmount.text.isNotEmpty
        ? double.tryParse(_controllerAmount.text.trim())
        : 0;
    narration =
        _controllerNarration.text.isNotEmpty ? _controllerNarration.text : '';
    if (amount <= 0 || ledgerDebitData == null || ledgerCreditData == null) {
      showInSnackBar('Select Account and amount');
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
            'narration': narration,
            'debitId': ledgerDebitData.id,
            'creditId': ledgerCreditData.id
          }) +
          ']';
      var data = [
        {
          'entryNo': oldVoucher ? dataDynamic[0]['EntryNo'].toString() : '0',
          'date': formatDMY(formattedDate),
          'amount': amount,
          'narration': '',
          'time': timeIs,
          'toDevice': 'api',
          'location': locationId,
          'user': userIdC,
          'project': '-1',
          'salesman': salesManId,
          'checkReturn': -1,
          'particular': particular,
          'fyId': currentFinancialYear.id
        }
      ];
      if (operation == 'DELETE') {
        var _entryNo = oldVoucher ? dataDynamic[0]['EntryNo'].toString() : '0',
            refNo = await api.deleteJournalVoucher(
                _entryNo, formatDMY(formattedDate), userIdC, timeIs);
      } else if (operation == 'UPDATE') {
        refNo = await api.editJournalVoucher(data);
      } else {
        refNo = await api.addJournalVoucher(data);
      }
      if (refNo > 0) {
        setState(() {
          _isLoading = false;
          buttonEvent = false;
          if (operation == 'DELETE') {
            showInSnackBar('Deleted');
          } else {
            var dataAll = [
              {
                'entryNo':
                    oldVoucher ? dataDynamic[0]['EntryNo'].toString() : refNo,
                'date': formatDMY(formattedDate),
                'amount': amount,
                'particular': particular,
                'message': footerMessage
              }
            ];
            actionShow(context, dataAll);
          }
          clearData();
        });
      } else {
        var opr = operation == 'DELETE'
            ? 'error : Cannot delete this journal'
            : operation == 'UPDATE'
                ? 'error : Cannot update this journal'
                : 'error : Cannot save this journal';
        showInSnackBar(opr);
      }
    }
  }

  showEditDialog(context, dataDynamic) {
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
          fetchVoucher(context, dataDynamic);
        },
        buttonTextForNo: 'No',
        buttonTextForYes: 'YES',
        infoMessage:
            'Do you want to edit or delete\nRefNo:${dataDynamic['Id']}',
        title: 'Update',
        context: context);
  }

  var footerMessage = '';
  fetchVoucher(context, data) {
    int row = 0;
    api.fetchJournalVoucher(data['Id']).then((value) {
      if (value != null) {
        var information = value[0][0];
        var particulars = value[1];
        footerMessage = value[2][0]['s_Value'];
        List c = value[1].toList();
        row = c.length;
        formattedDate = DateUtil.dateDMY(information['DDate']);

        dataDynamic = [
          {
            'RealEntryNo': information['EntryNo'],
            'EntryNo': information['EntryNo'],
            'InvoiceNo': information['EntryNo'],
            'Type': '0'
          }
        ];

        // _dropDownValue = information['LedCode'].toString() +
        //     '-' +
        //     information['LedName'].toString();
        // accountName = information['LedName'].toString();
        // accountId = information['LedCode'].toString();
        var part1 = particulars[0];
        ledgerDebitData =
            LedgerModel(id: part1['debitId'], name: part1['debitName']);
        ledgerCreditData =
            LedgerModel(id: part1['creditId'], name: part1['creditName']);
        amount = double.tryParse(information['Amount'].toString());
        narration = part1['Narration'].toString();

        setState(() {
          if (row > 0) {
            widgetID = false;
            oldVoucher = true;
            isSelected = true;
            _controllerAmount.text = amount.toString();
            _controllerNarration.text = narration.toString();
          }
        });
      }
    });
  }

  clearData() {
    _controllerAmount.text = '';
    _controllerNarration.text = '';
    amount = 0;
    narration = '';
    ledgerCreditData.id = 0;
    ledgerDebitData.id = 0;
    ledgerCreditData.name = '';
    ledgerDebitData.name = '';
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

  actionShow(context, data) async {
    var form = 'JOURNAL';
    var title = 'journal Voucher';

    ConfirmAlertBox(
        buttonColorForNo: Colors.red,
        buttonColorForYes: Colors.green,
        icon: Icons.check,
        onPressedNo: () {
          Navigator.of(context).pop();
        },
        onPressedYes: () {
          Navigator.of(context).pop();
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
    // Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //         builder: (_) => RVPreviewShow(title: title, dataAll: dataAll)));
  }

  Uint8List byteImage;
  loadAsset() async {
    // Test image
    ByteData bytes = await rootBundle.load('assets/logo.png');
    final buffer = bytes.buffer;
    byteImage = Uint8List.view(buffer);
  }

  getFilterItems(String text) {}
}
