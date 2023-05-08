// @dart = 2.11
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sheraccerp/models/customer_model.dart';

import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class Ledger extends StatefulWidget {
  const Ledger({Key key}) : super(key: key);

  @override
  _LedgerState createState() => _LedgerState();
}

class _LedgerState extends State<Ledger> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _name = TextEditingController();
  final _add1 = TextEditingController();
  final _add2 = TextEditingController();
  final _add3 = TextEditingController();
  final _add4 = TextEditingController();
  final _city = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _email = TextEditingController();
  final _taxNo = TextEditingController();
  final _state = TextEditingController();
  final _stateCode = TextEditingController();
  final _route = TextEditingController();
  final _debitAmount = TextEditingController();
  final _creditAmount = TextEditingController();

  DioService api = DioService();
  bool _isLoading = false,
      valueActive = true,
      isExist = false,
      buttonEvent = false;
  String ledgerId = '';
  List<LedgerModel> ledgerList = [];
  String obDate = '';
  DateTime now = DateTime.now();
  int locationId = 1, salesManId = 0;

  @override
  void initState() {
    super.initState();

    salesManId = ComSettings.appSettings(
            'int', 'key-dropdown-default-salesman-view', 1) -
        1;
    locationId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;

    obDate = DateUtil.datePickerDMY(now);
    api.getLedgerAll().then(
      (value) {
        setState(() {
          ledgerList.addAll(value);
        });
      },
    );
  }

  String _result;

  @override
  Widget build(BuildContext context) {
    final routes =
        ModalRoute.of(context).settings.arguments as Map<String, String>;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text("Ledger"),
        actions: [
          // SizedBox(
          //   width: 80,
          //   child: Card(
          //     color: Colors.blue,
          //     child: IconButton(
          //       icon: const Text(
          //         'SAVE',
          //         style: TextStyle(
          //             fontWeight: FontWeight.bold,
          //             fontSize: 20,
          //             color: Colors.white),
          //       ),
          //       onPressed: () {
          //         _handleSubmitted();
          //       },
          //     ),
          //   ),
          // ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              var result = await showSearch<List<LedgerModel>>(
                context: context,
                delegate: CustomDelegate(ledgerList),
              );

              setState(() {
                _result = result[0].name;
                _name.text = _result;
                ledgerId = result[0].id.toString();
                if (ledgerId.isNotEmpty) {
                  isExist = true;
                  findLedger(result[0].id);
                }
              });
            },
          ),
          Visibility(
            visible: isExist,
            child: IconButton(
                color: red,
                iconSize: 40,
                onPressed: () {
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
                },
                icon: const Icon(Icons.delete_forever)),
          ),
          isExist
              ? IconButton(
                  color: green,
                  iconSize: 40,
                  onPressed: () {
                    if (buttonEvent) {
                      return;
                    } else {
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
                  },
                  icon: const Icon(Icons.save)),
        ],
      ),
      body: ProgressHUD(
        inAsyncCall: _isLoading,
        opacity: 0.0,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(45),
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                        icon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'add name';
                        }
                        return null;
                      },
                    ),
                    widgetParent(
                        routes != null ? routes['parent'].toString() : ''),
                    TextFormField(
                      controller: _add1,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(25),
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Address',
                        icon: Icon(Icons.person),
                      ),
                    ),
                    TextFormField(
                      controller: _phoneNumber,
                      maxLength: 12,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Telephone",
                        icon: Icon(Icons.phone),
                      ),
                    ),
                    TextFormField(
                      controller: _email,
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
                    TextFormField(
                      controller: _taxNo,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50),
                      ],
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Tax No',
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Active'),
                        Checkbox(
                          value: valueActive,
                          onChanged: (bool value) {
                            setState(() {
                              valueActive = value;
                            });
                          },
                        ),
                      ],
                    ),
                    ExpansionTile(
                      key: GlobalKey(),
                      title: const Text('more'),
                      children: [
                        TextFormField(
                          controller: _add2,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Address 2',
                          ),
                        ),
                        TextFormField(
                          controller: _add3,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Address 3',
                          ),
                        ),
                        TextFormField(
                          controller: _add4,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Address 4',
                          ),
                        ),
                        TextFormField(
                          controller: _city,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(45),
                          ],
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'City',
                            icon: Icon(Icons.location_city),
                          ),
                        ),
                        TextFormField(
                          controller: _route,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Route',
                          ),
                        ),
                        TextFormField(
                          controller: _state,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'State',
                          ),
                        ),
                        TextFormField(
                          controller: _stateCode,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'State Code',
                          ),
                        ),
                        const Divider(
                          height: 2,
                        ),
                        const Card(child: Text('Opening Balance')),
                        const Divider(
                          height: 2,
                        ),
                        InkWell(
                          child: Text(
                            obDate,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                          onTap: () => _selectDate(),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _debitAmount,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(50),
                                ],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Debit Amount',
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _creditAmount,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(50),
                                ],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Credit Amount',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteLedger(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    final FormState form = _formKey.currentState;
    if (!form.validate()) {
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
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
  }

  void _handleSubmitted(String action) async {
    setState(() {
      _isLoading = true;
    });
    final FormState form = _formKey.currentState;
    if (!form.validate()) {
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
      var name = _name.text,
          add1 = _add1.text,
          add2 = _add2.text,
          add3 = _add3.text,
          add4 = _add4.text,
          city = _city.text.isNotEmpty ? 1 : 0,
          route = _route.text.isNotEmpty ? 1 : 0,
          state = _state.text,
          stateCode = _stateCode.text,
          mobile = _phoneNumber.text,
          email = _email.text,
          taxNo = _taxNo.text;
      double crAmount = _creditAmount.text.isNotEmpty
              ? double.tryParse(_creditAmount.text)
              : 0,
          drAmount = _debitAmount.text.isNotEmpty
              ? double.tryParse(_debitAmount.text)
              : 0;
      var data = [
        {
          'name': name.toUpperCase(),
          'parent': _dropDownValue.split('-')[0],
          'add1': add1.toUpperCase(),
          'add2': add2.toUpperCase(),
          'add3': add3.toUpperCase(),
          'add4': add4.toUpperCase(),
          'city': city,
          'route': route,
          'state': state.toUpperCase(),
          'stateCode': stateCode,
          'mobile': mobile,
          'email': email,
          'taxNo': taxNo,
          'active': valueActive ? 1 : 0,
          'obDate': DateUtil.dateDMY2YMD(obDate),
          'credit': crAmount,
          'debit': drAmount,
          'location': locationId,
          'id': ledgerId.isNotEmpty ? ledgerId : 0
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

  String _dropDownValue = '';
  widgetParent(parent) {
    if (parent.length > 0) {}
    return FutureBuilder(
      future: api.getLedgerParent(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (parent.length > 0) {
            for (var i = 0; i < snapshot.data.length; i++) {
              var dyn = snapshot.data[i];
              var sName = dyn.name;
              if (sName == parent) {
                _dropDownValue = dyn.id.toString() + "-" + dyn.name;
                break;
              }
            }
          }
        }
        return snapshot.hasData
            ? DropdownButton<String>(
                hint: Text(_dropDownValue.isNotEmpty
                    ? _dropDownValue.split('-')[1]
                    : 'select under'),
                items: snapshot.data.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item.id.toString() + "-" + item.name,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _dropDownValue = value;
                  });
                },
              )
            : const Center(
                child: Loading(),
              );
      },
    );
  }

  findLedger(int id) {
    api.getCustomerDetail(id).then((value) {
      CustomerModel data = value;
      setState(() {
        _add1.text = data.address1;
        _add2.text = data.address2;
        _add3.text = data.address3;
        _add4.text = data.address4;
        _city.text = data.city;
        // _dropDownValue = data.;
        _email.text = data.email;
        _phoneNumber.text = data.phone;
        _route.text = data.route;
        _state.text = data.state;
        _stateCode.text = data.stateCode;
        _taxNo.text = data.taxNumber;
      });
    });
    var data = [
      {
        'name': '0',
        'parent': '0',
        'add1': '',
        'add2': '',
        'add3': '',
        'add4': '',
        'city': '0',
        'route': '0',
        'state': '',
        'stateCode': '32',
        'mobile': '',
        'email': '',
        'taxNo': '',
        'active': valueActive ? 1 : 0,
        'obDate': DateUtil.dateDMY2YMD(obDate),
        'credit': 0,
        'debit': 0,
        'statement': 'SelectOpeningBalance',
        'id': id
      }
    ];
    api.spLedger(data).then((value) {
      List<dynamic> d = value;
      if (d.isNotEmpty) {
        obDate = DateUtil.dateDMY(d[0]['atDate'].toString());
        double dr = d[0]['atDebitAmount'] != null
            ? double.tryParse(d[0]['atDebitAmount'].toString())
            : 0;
        double cr = d[0]['atCreditAmount'] != null
            ? double.tryParse(d[0]['atCreditAmount'].toString())
            : 0;
        if (dr > 0) {
          _debitAmount.text = dr.toStringAsFixed(2);
        }
        if (cr > 0) {
          _creditAmount.text = cr.toStringAsFixed(2);
        }
      }
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
}

class CustomDelegate extends SearchDelegate<List<LedgerModel>> {
  List<LedgerModel> data;
  CustomDelegate(this.data);

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.chevron_left),
      onPressed: () => close(context, []));

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) {
    List<LedgerModel> listToShow;
    if (query.isNotEmpty) {
      listToShow = data
          .where((e) =>
              e.name.toLowerCase().contains(query.toLowerCase()) &&
              e.name.toLowerCase().startsWith(query.toLowerCase()))
          .toList();
    } else {
      listToShow = data;
    }
    return ListView.builder(
      itemCount: listToShow.length,
      itemBuilder: (_, i) {
        var noun = listToShow[i];
        return ListTile(
          title: Text(noun.name),
          onTap: () => close(context, [noun]),
        );
      },
    );
  }
}
