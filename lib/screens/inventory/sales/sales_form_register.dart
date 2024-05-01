import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sheraccerp/models/other_registrations.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/screens/other_registration.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class SalesFormRegister extends StatefulWidget {
  const SalesFormRegister({Key? key}) : super(key: key);

  @override
  State<SalesFormRegister> createState() => _SalesFormRegisterState();
}

class _SalesFormRegisterState extends State<SalesFormRegister> {
  bool isLoading = false,
      _tax = false,
      _accounts = false,
      _stock = false,
      _eInv = false;
  SalesType? salesType;
  DioService api = DioService();
  String selectedRateType = 'MRP';
  DataJson selectedLocationData = DataJson(id: 1, name: 'SHOP');
  String selectedLocation = '';

  List<DataJson> location = [DataJson(id: 0, name: '')];
  final controlName = TextEditingController();
  final controlType = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (salesTypeList.isEmpty) {
      api.getSalesTypeList().then((value) {
        salesTypeList.addAll(value);
      });
    }

    if (otherRegLocationList.isNotEmpty) {
      location.removeAt(0);
      for (var element in otherRegLocationList) {
        location.add(DataJson(id: element.id, name: element.name));
      }
      selectedLocationData = location[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
            color: white,
            iconSize: 40,
            onPressed: () {
              saveData();
            },
            icon: const Icon(Icons.save)),
      ], title: const Text('Sales Form Register')),
      body: ProgressHUD(
          inAsyncCall: isLoading,
          opacity: 0.0,
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                TextField(
                  style: const TextStyle(fontSize: 11),
                  controller: controlName,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: 'Name'),
                ),
                TextField(
                  style: const TextStyle(fontSize: 11),
                  controller: controlType,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: 'Type'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Stock : ',
                      style: TextStyle(fontSize: 11),
                    ),
                    Checkbox(
                      value: _stock,
                      onChanged: (value) {
                        setState(() {
                          _stock = value!;
                        });
                      },
                    ),
                    const Text(
                      'Account : ',
                      style: TextStyle(fontSize: 11),
                    ),
                    Checkbox(
                      value: _accounts,
                      onChanged: (value) {
                        setState(() {
                          _accounts = value!;
                        });
                      },
                    ),
                    const Text(
                      'Tax : ',
                      style: TextStyle(fontSize: 11),
                    ),
                    Checkbox(
                      value: _tax,
                      onChanged: (value) {
                        setState(() {
                          _tax = value!;
                        });
                      },
                    ),
                    const Text(
                      'eINV : ',
                      style: TextStyle(fontSize: 11),
                    ),
                    Checkbox(
                      value: _eInv,
                      onChanged: (value) {
                        setState(() {
                          _eInv = value!;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Rate'),
                    Text('Location'),
                  ],
                ),
                Card(
                  elevation: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Select rate type',
                                textAlign: TextAlign.center),
                          ),
                          value: selectedRateType,
                          items: rateTypeData
                              .map<DropdownMenuItem<String>>((item) {
                            return DropdownMenuItem<String>(
                              value: item.toString(),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(item,
                                    style: const TextStyle(
                                        overflow: TextOverflow.ellipsis)),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRateType = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: DropdownButton<DataJson>(
                          isExpanded: true,
                          hint: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Select rate type',
                                textAlign: TextAlign.center),
                          ),
                          value: selectedLocationData,
                          items:
                              location.map<DropdownMenuItem<DataJson>>((item) {
                            return DropdownMenuItem<DataJson>(
                              value: item,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(item.name,
                                    style: const TextStyle(
                                        overflow: TextOverflow.ellipsis)),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedLocationData = value!;
                              selectedLocation = value.name;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          if (controlName.text.isNotEmpty) {
                            if (salesType != null) {
                              salesType!.accounts = _accounts;
                              salesType!.eInvoice = _eInv;
                              salesType!.location = selectedLocationData.id;
                              salesType!.name = controlName.text.trim();
                              salesType!.rateType = selectedRateType;
                              salesType!.sColor = '-1';
                              salesType!.stock = _stock;
                              salesType!.tax = _tax;
                              salesType!.type =
                                  controlType.text.trim().toUpperCase();
                              setState(() {
                                salesTypeList[(salesTypeList.indexWhere(
                                        (element) =>
                                            element.id == salesType!.id))] =
                                    salesType;
                                salesType = null;
                              });
                            } else {
                              SalesType dataS = SalesType(
                                  accounts: _accounts,
                                  eInvoice: _eInv,
                                  id: 0,
                                  location: selectedLocationData.id,
                                  name: controlName.text.trim(),
                                  rateType: selectedRateType,
                                  sColor: '-1',
                                  stock: _stock,
                                  tax: _tax,
                                  type: controlType.text.trim().toUpperCase());
                              setState(() {
                                salesTypeList.add(dataS);
                              });
                            }
                          } else {
                            showInSnackBar('Select Name');
                          }
                        },
                        child: Text(salesType != null ? 'Edit' : 'Add')),
                    Visibility(
                      visible: salesType != null,
                      child: ElevatedButton(
                          onPressed: () {
                            if (salesType != null) {
                              setState(() {
                                salesTypeList.removeAt(salesTypeList.indexWhere(
                                    (element) => element.id == salesType!.id));
                                clear();
                              });
                            }
                          },
                          child: const Text('Remove')),
                    ),
                  ],
                ),
                const Divider(
                  height: 1,
                ),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: salesTypeList.length,
                    itemBuilder: (context, index) {
                      var data = salesTypeList[index];
                      return Card(
                        elevation: 2,
                        color: blue[50],
                        child: ListTile(
                          title: Text(data.name),
                          subtitle: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    data.type,
                                    style: const TextStyle(
                                        color: black, fontSize: 10),
                                  ),
                                  Text(
                                    data.rateType,
                                    style: const TextStyle(
                                        color: black, fontSize: 10),
                                  ),
                                  Text(
                                    locationData(data.location),
                                    style: const TextStyle(
                                        color: black, fontSize: 10),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Stock : ',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Checkbox(
                                    value: data.stock,
                                    onChanged: (value) {
                                      setState(() {
                                        data.stock = value;
                                      });
                                    },
                                  ),
                                  const Text(
                                    'Account : ',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Checkbox(
                                    value: data.accounts,
                                    onChanged: (value) {
                                      setState(() {
                                        data.accounts = value;
                                      });
                                    },
                                  ),
                                  const Text(
                                    'Tax : ',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Checkbox(
                                    value: data.tax,
                                    onChanged: (value) {
                                      setState(() {
                                        data.tax = value;
                                      });
                                    },
                                  ),
                                  const Text(
                                    'eINV : ',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Checkbox(
                                    value: data.eInvoice,
                                    onChanged: (value) {
                                      setState(() {
                                        data.eInvoice = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onLongPress: () {
                            setState(() {
                              salesType = data;
                              controlName.text = salesType!.name;
                              controlType.text = salesType!.type;
                              selectedLocationData = location.firstWhere(
                                  (element) =>
                                      element.id == salesType!.location);
                              selectedLocation = selectedLocationData.name;
                              selectedRateType = salesType!.rateType;
                              _accounts = salesType!.accounts;
                              _stock = salesType!.stock;
                              _tax = salesType!.tax;
                              _eInv = salesType!.eInvoice;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ]))),
    );
  }

  saveData() {
    setState(() {
      isLoading = true;
    });
    var particular = convertData(salesTypeList);
    var data = {'id': '0', 'particular': particular};

    api.salesFormAdd(data).then((value) {
      if (value) {
        showInSnackBar('saved');
      } else {
        showInSnackBar('failed');
      }
    });
  }

  void showInSnackBar(String value) {
    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String locationData(int id) {
    return otherRegLocationList
            .firstWhere(
              (element) => element.id == id,
              orElse: () => OtherRegistrationModel.emptyData(),
            )
            .name ??
        'SHOP';
  }

  String convertData(List<SalesType> salesTypeList) {
    String result =
        jsonEncode(salesTypeList.map((e) => e.toJson()).toList()).toString();
    return result;
  }

  void clear() {
    salesType = null;
    controlName.text = '';
    controlType.text = '';
  }
}
