// @dart = 2.11

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/models/ledger_parent.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class Ledger extends StatefulWidget {
  const Ledger({Key key}) : super(key: key);

  @override
  _LedgerState createState() => _LedgerState();
}

class _LedgerState extends State<Ledger> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _nameCtr = TextEditingController();
  final _add1Ctr = TextEditingController();
  final _add2Ctr = TextEditingController();
  final _add3Ctr = TextEditingController();
  final _add4Ctr = TextEditingController();
  final _cityCtr = TextEditingController();
  final _phoneNumberCtr = TextEditingController();
  final _emailCtr = TextEditingController();
  final _taxNoCtr = TextEditingController();
  final _routeCtr = TextEditingController();
  final _debitAmountCtr = TextEditingController();
  final _creditAmountCtr = TextEditingController();
  final _panCtr = TextEditingController();
  final _pinCtr = TextEditingController();
  final _secondNameCtr = TextEditingController();
  final _creditAmtCtr = TextEditingController();
  final _creditDaysCtr = TextEditingController();
  final _personCtr = TextEditingController();

  GlobalKey<AutoCompleteTextFieldState<String>> keyLedgerName = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyCity = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyRoute = GlobalKey();

  DioService api = DioService();
  bool _isLoading = false,
      valueActive = true,
      isUnderSelected = false,
      valueCostCenter = false,
      valueFranchisee = false,
      valueBillWise = false,
      isExist = false,
      buttonEvent = false;
  String ledgerId = '';
  List<LedgerModel> ledgerList = [];
  List<String> ledgerListDisplay = [];
  List<dynamic> ledgerGroupList = [];
  List<dynamic> salesManList = otherRegSalesManList;
  List<String> cityList = [];
  List<String> routeList = [];
  String obDate = '', lName = '';
  DateTime now = DateTime.now();
  int locationId = 1, salesManId = 0;
  String _dropDownState = 'KERALA';
  String _stateCode = '32';
  GSTStateModel gstStateM;
  dynamic cityData, routeData;

  @override
  void initState() {
    super.initState();

    // salesManId = ComSettings.appSettings(
    //         'int', 'key-dropdown-default-salesman-view', 1) -
    //     1;
    locationId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    // var isIn = salesManList.isEmpty
    //     ? null
    //     : salesManList.firstWhere((element) => element['Auto'] == 0,
    //         orElse: () => null);
    // if (isIn == null) {
    //   salesManList.add({'Auto': 0, 'Name': ''});
    // }

    obDate = DateUtil.datePickerDMY(now);
    api.getLedgerAll().then(
      (value) {
        setState(() {
          ledgerList.addAll(value);
          ledgerListDisplay.addAll(List<String>.from(ledgerList
              .map((item) => (item.name))
              .toList()
              .map((s) => s)
              .toList()));
        });
      },
    );
    api.getLedgerParent().then((value) {
      setState(() {
        ledgerGroupList.addAll(value);
        ledgerGroupList.add(LedgerParent(id: 0, name: ''));
      });
    });
    var gstState = gstStateModels.lastWhere((element) => element.code == '32');
    gstStateM = gstStateM ?? gstState;
    cityList.addAll(otherRegAreaList.map((e) => e.name).toList());
    routeList.addAll(otherRegRouteList.map((e) => e.name).toList());
  }

  String _result;

  @override
  Widget build(BuildContext context) {
    final routes =
        ModalRoute.of(context).settings.arguments as Map<String, String>;
    if (!isUnderSelected) {
      if (routes != null) {
        var parentName = routes['parent'] ?? '';
        _dropDownValue = parentName.isNotEmpty
            ? ledgerGroupList
                .firstWhere((element) => element.name == parentName,
                    orElse: () => LedgerModel(id: 0, name: ''))
                .id
            : _dropDownValue;
      }
      int groupId = 0;
      groupId =
          ComSettings.appSettings('int', 'key-dropdown-default-group-view', 0) -
              1;
      if (groupId > 1) {
        _dropDownValue = groupId;
      }
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text("Ledger"),
      ),
      body: ProgressHUD(
        inAsyncCall: _isLoading,
        opacity: 0.0,
        // child: detailWidget(),
        child: tabBarWidget(),
      ),
    );
  }

  void _deleteLedger(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    bool result = await api.spLedgerDelete(ledgerId);
    if (result) {
      setState(() {
        _isLoading = false;
        showInSnackBar('Deleted : Ledger removed.');
      });
    } else {
      showInSnackBar('error : Cannot delete this Ledger.');
    }
  }

  void _handleSubmitted(String action) async {
    setState(() {
      _isLoading = true;
    });

    var name = _nameCtr.text,
        add1 = _add1Ctr.text,
        add2 = _add2Ctr.text,
        add3 = _add3Ctr.text,
        add4 = _add4Ctr.text,
        city = cityData != null ? cityData.id : 0,
        route = routeData != null ? routeData.id : 0,
        state = _dropDownState,
        stateCode = _stateCode,
        mobile = _phoneNumberCtr.text,
        email = _emailCtr.text,
        taxNo = _taxNoCtr.text;
    double crAmount = _creditAmountCtr.text.isNotEmpty
            ? double.tryParse(_creditAmountCtr.text)
            : 0,
        drAmount = _debitAmountCtr.text.isNotEmpty
            ? double.tryParse(_debitAmountCtr.text)
            : 0;
    var data = [
      {
        'name': name.toUpperCase(),
        'parent': _dropDownValue,
        'add1': add1.toUpperCase(),
        'add2': add2.toUpperCase(),
        'add3': add3.toUpperCase(),
        'add4': add4.toUpperCase(),
        'city': city,
        'route': route,
        'state': state.toUpperCase(),
        'stateCode': stateCode,
        'mobile': mobile,
        'salesMan': salesManId > 0 ? salesManId.toString() : '0',
        'email': email,
        'taxNo': taxNo,
        'active': valueActive ? 1 : 0,
        'obDate': DateUtil.dateDMY2YMD(obDate),
        'credit': crAmount,
        'debit': drAmount,
        'location': locationId > 0 ? locationId.toString() : '1',
        'id': ledgerId.isNotEmpty ? ledgerId : 0,
        'pan': _panCtr.text,
        'cDays':
            _creditDaysCtr.text.isNotEmpty ? int.parse(_creditDaysCtr.text) : 0,
        'cAmount': _creditAmtCtr.text.isNotEmpty
            ? double.parse(_creditAmtCtr.text)
            : 0,
        'cPerson': _personCtr.text.toUpperCase(),
        'costCenter': valueCostCenter ? 1 : 0,
        'franchisee': valueFranchisee ? 1 : 0,
        'billWise': valueBillWise ? 1 : 0,
        'pin': _pinCtr.text,
        'secondName': _secondNameCtr.text,
        'bpr': 0,
      }
    ];

    bool result = action == 'edit'
        ? await api.spLedgerEdit(data)
        : await api.spLedgerAdd(data);

    if (result) {
      _saveAndRedirectToHome(action);
    } else {
      showInSnackBar(action == 'edit'
          ? 'error : Cannot edit this Ledger.'
          : 'error : Cannot save this Ledger.');
    }
  }

  void _saveAndRedirectToHome(action) async {
    setState(() {
      _isLoading = false;
      showInSnackBar(action == 'edit'
          ? 'Updated : Ledger edited.'
          : 'Saved : Ledger created.');
    });
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  int _dropDownValue = 0;

  findLedger(id) {
    setState(() {
      _isLoading = true;
    });
    api.findLedger(id).then((value) {
      var data = value[0][0];
      List dataTransaction = value[1];
      setState(() {
        _nameCtr.text = data['LedName'] ?? '';
        _add1Ctr.text = data['add1'] ?? '';
        _add2Ctr.text = data['add2'] ?? '';
        _add3Ctr.text = data['add3'] ?? '';
        _add4Ctr.text = data['add4'] ?? '';
        if (data['city'] > 0) {
          cityData = otherRegAreaList
              .firstWhere((element) => element.id == data['city']);
          _cityCtr.text = cityData.name;
        }
        if (data['route'] > 0) {
          routeData = otherRegRouteList
              .firstWhere((element) => element.id == data['route']);
          _routeCtr.text = routeData.name;
        }
        if (data['lh_id'] > 0) {
          _dropDownValue = data['lh_id'];
        }
        _phoneNumberCtr.text = data['Mobile'];
        _panCtr.text = data['pan'];
        _emailCtr.text = data['Email'];
        _dropDownState = data['state'].toString();
        _stateCode = data['stateCode'].toString();
        _taxNoCtr.text = data['gstno'].toString();
        _creditDaysCtr.text = data['CDays'].toString();
        _creditAmtCtr.text = data['CAmount'].toString();
        valueActive = data['Active'] == 1 ? true : false;
        salesManId = data['SalesMan'] ?? 0;
        var _bpr = data['bpr'].toString();
        var _rent = data['Rent'].toString();
        locationId = data['Location'] ?? 0;
        var orderDate = data['OrderDate'];
        var deliveryData = data['DeliveryData'];
        _personCtr.text = data['CPerson'];
        valueCostCenter = data['CostCenter'] == 1 ? true : false;
        valueFranchisee = data['Franchisee'] == 1 ? true : false;
        var salesRate = data['SalesRate'];
        var subGroup = data['SubGroup'] == 1 ? true : false;
        _pinCtr.text = data['PinNo'];
        var TCS_Status = data['TCS_Status'];
        var TCSLimit = data['TCSLimit'];
        _secondNameCtr.text = data['SecondName'];

        if (dataTransaction.isNotEmpty) {
          var d = dataTransaction[0];
          obDate = DateUtil.dateDMY(d['atDate'].toString());
          double dr = d['atDebitAmount'] != null
              ? double.tryParse(d['atDebitAmount'].toString())
              : 0;
          double cr = d['atCreditAmount'] != null
              ? double.tryParse(d['atCreditAmount'].toString())
              : 0;
          if (dr > 0) {
            _debitAmountCtr.text = dr.toStringAsFixed(2);
          }
          if (cr > 0) {
            _creditAmountCtr.text = cr.toStringAsFixed(2);
          }
        }
      });
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future _selectDate() async {
    DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => {obDate = DateUtil.datePickerDMY(picked)});
    }
  }

  tabBarWidget() {
    return Column(
      children: [
        Expanded(
          flex: 0,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ElevatedButton(
              child: Text(isExist ? 'Edit' : 'Save'),
              onPressed: () {
                if (buttonEvent) {
                  return;
                } else {
                  if (isExist) {
                    if (companyUserData.updateData) {
                      if (ledgerId.isNotEmpty) {
                        setState(() {
                          _isLoading = true;
                          buttonEvent = true;
                        });
                        _handleSubmitted('edit');
                      } else {
                        showInSnackBar('Please select ledger');
                        setState(() {
                          buttonEvent = false;
                        });
                      }
                    } else {
                      showInSnackBar('Permission denied\ncan`t edit');
                      setState(() {
                        buttonEvent = false;
                      });
                    }
                  } else {
                    if (companyUserData.insertData) {
                      if (ledgerId.isEmpty) {
                        setState(() {
                          _isLoading = true;
                          buttonEvent = true;
                        });
                        _handleSubmitted('save');
                      } else {
                        showInSnackBar('Please add ledger');
                        setState(() {
                          buttonEvent = false;
                        });
                      }
                    } else {
                      showInSnackBar('Permission denied\ncan`t save');
                      setState(() {
                        buttonEvent = false;
                      });
                    }
                  }
                }
              },
            ),
            ElevatedButton(
                onPressed: () => clear(), child: const Text('Clear')),
            ElevatedButton(
              onPressed: isExist
                  ? () {
                      if (buttonEvent) {
                        return;
                      } else {
                        if (companyUserData.deleteData) {
                          if (ledgerId.isNotEmpty) {
                            setState(() {
                              _isLoading = true;
                              buttonEvent = true;
                            });
                            _deleteLedger(context);
                          } else {
                            showInSnackBar('Please select ledger');
                            setState(() {
                              buttonEvent = false;
                            });
                          }
                        } else {
                          showInSnackBar('Permission denied\ncan`t delete');
                          setState(() {
                            buttonEvent = false;
                          });
                        }
                      }
                    }
                  : null,
              child: const Text('Delete'),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings, color: blue),
              onSelected: (value) {
                // Handle menu item selection
                setState(() {
                  // Perform actions based on the selected value
                  if (value == 'ReName Ledger') {
                    if (lName.isNotEmpty) {
                      _reNameLedgerDialog(context);
                    }
                  }
                });
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'ReName Ledger',
                  child: Text('ReName Ledger'),
                ),
              ],
            ),
          ]),
        ),
        Expanded(
          flex: 1,
          child: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: blue,
                automaticallyImplyLeading: false,
                flexibleSpace: const TabBar(
                  indicatorWeight: 5,
                  tabs: [
                    Tab(text: "Account", icon: Icon(Icons.person)),
                    Tab(
                        text: "Address",
                        icon: Icon(Icons.maps_home_work_rounded)),
                    Tab(text: "Opening Balance", icon: Icon(Icons.money)),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Column(
                      children: [
                        const Divider(),
                        SimpleAutoCompleteTextField(
                          key: keyLedgerName,
                          controller: _nameCtr,
                          clearOnSubmit: false,
                          suggestions: ledgerListDisplay,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Ledger Name'),
                          textSubmitted: (data) {
                            lName = data;
                            if (lName.isNotEmpty) {
                              int _id = ledgerList
                                  .firstWhere(
                                      (element) => element.name == lName,
                                      orElse: () =>
                                          LedgerModel(id: 0, name: ''))
                                  .id;
                              if (_id > 0) {
                                ledgerId = _id.toString();
                                isExist = true;
                                findLedger(ledgerId);
                              }
                            }
                          },
                        ),
                        const Divider(),
                        const Align(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Under',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            alignment: Alignment.centerLeft),
                        Card(
                          elevation: 10,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Select under',
                                  textAlign: TextAlign.center),
                            ),
                            value: _dropDownValue.toString(),
                            items: ledgerGroupList
                                .map<DropdownMenuItem<String>>((item) {
                              return DropdownMenuItem<String>(
                                value: item.id.toString(),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(item.name,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                isUnderSelected = true;
                                _dropDownValue = int.parse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ListView(
                      children: [
                        const Divider(),
                        TextFormField(
                          controller: _add1Ctr,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Address',
                          ),
                        ),
                        const Divider(),
                        TextFormField(
                          controller: _add2Ctr,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Address 2',
                          ),
                        ),
                        const Divider(),
                        TextFormField(
                          controller: _add3Ctr,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Address 3',
                          ),
                        ),
                        const Divider(),
                        TextFormField(
                          controller: _add4Ctr,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Address 4',
                          ),
                        ),
                        const Divider(),
                        TextFormField(
                          controller: _taxNoCtr,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Tax No',
                          ),
                        ),
                        const Divider(),
                        SimpleAutoCompleteTextField(
                          clearOnSubmit: false,
                          key: keyCity,
                          suggestions: cityList,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select Area',
                              labelText: 'Area'),
                          textSubmitted: (data) {
                            cityData = otherRegAreaList.firstWhere(
                              (element) => element.name == data,
                              orElse: () => null,
                            );
                          },
                          controller: _cityCtr,
                        ),
                        const Divider(),
                        SimpleAutoCompleteTextField(
                          clearOnSubmit: false,
                          key: keyRoute,
                          suggestions: routeList,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select Route',
                              labelText: 'Route'),
                          textSubmitted: (data) {
                            routeData = otherRegRouteList.firstWhere(
                              (element) => element.name == data,
                              orElse: () => null,
                            );
                          },
                          controller: _routeCtr,
                        ),
                        const Divider(),
                        TextFormField(
                          controller: _phoneNumberCtr,
                          maxLength: 12,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Telephone",
                            icon: Icon(Icons.phone),
                          ),
                        ),
                        TextFormField(
                          controller: _emailCtr,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'E-mail',
                            icon: Icon(Icons.email),
                          ),
                        ),
                        Card(
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'State',
                                  style: TextStyle(
                                      decoration: TextDecoration.underline),
                                ),
                                Text(
                                  'Code',
                                  style: TextStyle(
                                      decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<GSTStateModel>(
                                isExpanded: true,
                                items: gstStateModels
                                    .map<DropdownMenuItem<GSTStateModel>>(
                                        (item) {
                                  return DropdownMenuItem<GSTStateModel>(
                                    value: item,
                                    child: Text(item.state),
                                  );
                                }).toList(),
                                onChanged: (item) {
                                  setState(() {
                                    _dropDownState = item.state;
                                    _stateCode = item.code;
                                    gstStateM = item;
                                  });
                                },
                                value: gstStateM,
                              ),
                            ),
                            Text(_stateCode),
                          ],
                        ),
                        TextFormField(
                          controller: _panCtr,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(20),
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'PAN',
                          ),
                        ),
                        const Divider(),
                        TextFormField(
                          controller: _pinCtr,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'PIN',
                          ),
                        ),
                        const Divider(),
                        TextFormField(
                          controller: _secondNameCtr,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Second Name(native language)',
                          ),
                        ),
                        const Divider(),
                        Card(
                          elevation: 5,
                          color: blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Card(
                                    color: blue.shade50,
                                    elevation: 0,
                                    child: const Text(
                                      'Credit Limit',
                                      style: TextStyle(
                                          fontSize: 20,
                                          decoration: TextDecoration.underline),
                                    )),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _creditAmtCtr,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Amount',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _creditDaysCtr,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Days',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        TextFormField(
                          controller: _personCtr,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Contact Person',
                          ),
                        ),
                        const Divider(),
                        const Text('SalesMan'),
                        Card(
                          elevation: 10,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Select SalesMan',
                                  textAlign: TextAlign.center),
                            ),
                            items: salesManList
                                .map<DropdownMenuItem<String>>((item) {
                              return DropdownMenuItem<String>(
                                value: item['Auto'].toString(),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(item['Name'],
                                      overflow: TextOverflow.ellipsis),
                                ),
                              );
                            }).toList(),
                            // value: salesManId.toString(),
                            onChanged: (value) {
                              setState(() {
                                salesManId = int.parse(value);
                              });
                            },
                          ),
                        ),
                        const Divider(
                          height: 150,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      children: [
                        const Card(
                            child: Text(
                          'Opening Balance',
                          style: TextStyle(
                              fontSize: 25,
                              decoration: TextDecoration.underline),
                        )),
                        const Divider(
                          height: 5,
                        ),
                        InkWell(
                          child: Text(
                            obDate,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                          onTap: () => _selectDate(),
                        ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _debitAmountCtr,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(50),
                                ],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Receive Amount',
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _creditAmountCtr,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(50),
                                ],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Pay Amount',
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Card(
                          elevation: 5,
                          child: IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text('Active'),
                                    value: valueActive,
                                    onChanged: (value) {
                                      setState(() {
                                        valueActive = value;
                                      });
                                    },
                                  ),
                                ),
                                const VerticalDivider(
                                  color: Colors.black,
                                  thickness: 2,
                                ),
                                Expanded(
                                  child: CheckboxListTile(
                                    value: valueCostCenter,
                                    onChanged: (value) {
                                      setState(() {
                                        valueCostCenter = value;
                                      });
                                    },
                                    title: const Text('Cost Center'),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        Card(
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                    child: CheckboxListTile(
                                        value: valueFranchisee,
                                        onChanged: (value) {
                                          setState(() {
                                            valueFranchisee = value;
                                          });
                                        },
                                        title: const Text('Franchisee')),
                                  ),
                                  const VerticalDivider(
                                    color: Colors.black,
                                    thickness: 2,
                                  ),
                                  Expanded(
                                    child: CheckboxListTile(
                                      value: valueBillWise,
                                      onChanged: (value) {
                                        setState(() {
                                          valueBillWise = value;
                                        });
                                      },
                                      title: const Text(
                                          'Bill Wise (Receipt/Payment)'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  clear() {}

  final TextEditingController _textFieldController = TextEditingController();

  _reNameLedgerDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'ReName $lName',
            style: const TextStyle(fontSize: 12),
          ),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), label: Text("Enter New Name")),
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _isLoading = true; //
                });
                var body = {
                  'newName': _textFieldController.text.toUpperCase(),
                  'oldName': lName.toUpperCase()
                };
                bool _state = await api.renameLedger(body);
                _state
                    ? showInSnackBar('Ledger Name Renamed')
                    : showInSnackBar('Error');
                if (_state) {
                  _nameCtr.text = _textFieldController.text.toUpperCase();
                  lName = _textFieldController.text.toUpperCase();
                  _textFieldController.text = '';
                }
                setState(() {
                  _isLoading = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // _textFieldController.dispose();
    // _panCtr.dispose();
    // _pinCtr.dispose();
    // _add1Ctr.dispose();
    // _add2Ctr.dispose();
    // _add3Ctr.dispose();
    // _add4Ctr.dispose();
    // _cityCtr.dispose();
    // _nameCtr.dispose();
    // _emailCtr.dispose();
    // _routeCtr.dispose();
    // _taxNoCtr.dispose();
    // _personCtr.dispose();
    // _creditAmtCtr.dispose();
    // _creditDaysCtr.dispose();
    // _debitAmountCtr.dispose();
    // _phoneNumberCtr.dispose();
    // _secondNameCtr.dispose();
    // _taxNoCtr.dispose();

    super.dispose();
  }
}
