import 'dart:convert';

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class SalesOtherDetailRegister extends StatefulWidget {
  const SalesOtherDetailRegister({Key? key}) : super(key: key);

  @override
  State<SalesOtherDetailRegister> createState() =>
      _SalesOtherDetailRegisterState();
}

class _SalesOtherDetailRegisterState extends State<SalesOtherDetailRegister> {
  bool isLoading = false,
      otherAmountLoaded = false,
      isExist = false,
      _printVisible = false;
  DioService api = DioService();
  List<LedgerModel> ledgerList = [];
  final controlName = TextEditingController();
  final controlPercentage = TextEditingController();
  final controlAmount = TextEditingController();
  List<dynamic> otherAmountList = [];
  GlobalKey<AutoCompleteTextFieldState<String>> keyName = GlobalKey();
  List<String> nameListDisplay = [];
  List<String> symbolData = ['', '+', '-'];
  String selectedSymbol = '';
  Map<String, dynamic> selectedModel = {};

  @override
  void initState() {
    super.initState();

    api.fetchDetailAmount().then((value) {
      otherAmountList = value;
      setState(() {
        otherAmountLoaded = true;
      });
    });

    api.getLedgerListByType('SelectExpenceAndIncome').then((value) {
      List<LedgerModel> _dataTemp = [];
      for (var ledger in value) {
        _dataTemp
            .add(LedgerModel(id: ledger['Ledcode'], name: ledger['LedName']));
      }
      setState(() {
        ledgerList.addAll(_dataTemp);
        nameListDisplay.addAll(List<String>.from(ledgerList
            .map((item) => (item.name))
            .toList()
            .map((s) => s)
            .toList()));
      });
    });
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
      ], title: const Text('Sales OtherDetails')),
      body: ProgressHUD(
          inAsyncCall: isLoading,
          opacity: 0.0,
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                SimpleAutoCompleteTextField(
                  key: keyName,
                  controller: controlName,
                  clearOnSubmit: false,
                  suggestions: nameListDisplay,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: 'Account'),
                  textSubmitted: (data) {
                    // lName = data;
                  },
                ),
                const Divider(
                  height: 10,
                ),
                Row(
                  children: [
                    // Expanded(
                    //   child: TextField(
                    //     style: const TextStyle(fontSize: 11),
                    //     controller: controlSymbol,
                    //     decoration: const InputDecoration(
                    //         border: OutlineInputBorder(), labelText: '+/-'),
                    //   ),
                    // ),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Select rate type',
                              textAlign: TextAlign.center),
                        ),
                        value: selectedSymbol,
                        items: symbolData.map<DropdownMenuItem<String>>((item) {
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
                            selectedSymbol = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(fontSize: 11),
                        controller: controlPercentage,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: '%'),
                      ),
                    ),
                  ],
                ),
                const Divider(
                  height: 10,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(fontSize: 11),
                          controller: controlAmount,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Amount'),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      const Text(
                        'Print Visibility : ',
                        style: TextStyle(fontSize: 11),
                      ),
                      Checkbox(
                        value: _printVisible,
                        onChanged: (value) {
                          setState(() {
                            _printVisible = value!;
                          });
                        },
                      ),
                    ]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          if (controlName.text.isNotEmpty &&
                              selectedSymbol.isNotEmpty) {
                            if (isExist) {
                              selectedModel['LedName'] =
                                  controlName.text.trim().toUpperCase();
                              selectedModel['Symbol'] =
                                  selectedSymbol.trim().toUpperCase();
                              selectedModel['Percentage'] = controlPercentage
                                      .text.isNotEmpty
                                  ? controlPercentage.text.trim().toUpperCase()
                                  : '0';
                              selectedModel['Amount'] =
                                  controlAmount.text.isNotEmpty
                                      ? controlAmount.text.trim().toUpperCase()
                                      : '0';
                              selectedModel['pVisible'] = _printVisible;
                              setState(() {
                                otherAmountList[(otherAmountList.indexWhere(
                                        (element) =>
                                            element['LedCode'] ==
                                            selectedModel['LedCode']))] =
                                    selectedModel;
                                selectedModel = {};
                              });
                            } else {
                              String _ledCode = ledgerList
                                  .firstWhere((element) =>
                                      element.name ==
                                      controlName.text.trim().toUpperCase())
                                  .id
                                  .toString();
                              Map<String, dynamic> dataS = {
                                'LedCode': _ledCode,
                                'LedName':
                                    controlName.text.trim().toUpperCase(),
                                'Symbol': selectedSymbol.trim().toUpperCase(),
                                'Percentage': controlPercentage.text.isNotEmpty
                                    ? controlPercentage.text
                                        .trim()
                                        .toUpperCase()
                                    : '0',
                                'Amount': controlAmount.text.isNotEmpty
                                    ? controlAmount.text.trim().toUpperCase()
                                    : '0',
                                'pVisible': _printVisible,
                              };
                              setState(() {
                                otherAmountList.add(dataS);
                              });
                            }
                          } else {
                            showInSnackBar('Select Account and Symbol +/-');
                          }
                        },
                        child: Text(isExist ? 'Edit' : 'Add')),
                    Visibility(
                      visible: isExist,
                      child: ElevatedButton(
                          onPressed: () {
                            if (isExist) {
                              setState(() {
                                otherAmountList.removeAt(
                                    otherAmountList.indexWhere((element) =>
                                        element['LedCode'] ==
                                        selectedModel['LedCode']));
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
                    itemCount: otherAmountList.length,
                    itemBuilder: (context, index) {
                      var data = otherAmountList[index];
                      return Card(
                        elevation: 2,
                        color: blue[50],
                        child: ListTile(
                          title: Text(data['LedName']),
                          subtitle: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Card(
                                      elevation: 2,
                                      color: blue[100],
                                      child: Row(children: [
                                        const Text('+/- : '),
                                        Text(
                                          data['Symbol'],
                                        ),
                                      ])),
                                  Card(
                                      elevation: 2,
                                      color: blue[100],
                                      child: Row(children: [
                                        const Text('% : '),
                                        Text(data['Percentage'].toString()),
                                      ])),
                                  Card(
                                    elevation: 2,
                                    color: blue[100],
                                    child: Row(
                                      children: [
                                        const Text('Amount : '),
                                        Text(
                                          data['Amount'].toString(), //[LedCode]
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Text(
                                    'Print Visibility:',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Checkbox(
                                    value: false,
                                    onChanged: (value) {
                                      // setState(() {
                                      //   data.eInvoice = value;
                                      // });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onLongPress: () {
                            setState(() {
                              isExist = true;
                              selectedModel = data;
                              controlName.text = selectedModel['LedName'];
                              selectedSymbol = selectedModel['Symbol'];
                              controlPercentage.text =
                                  selectedModel['Percentage'].toString();
                              controlAmount.text =
                                  selectedModel['Amount'].toString();
                              // _printVisible = selectedModel[''];
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

    api.salesOtherDetailsAdd(otherAmountList).then((value) {
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

  void clear() {
    setState(() {
      controlAmount.text = '';
      controlName.text = '';
      controlPercentage.text = '';
      selectedSymbol = '';
      _printVisible = false;
    });
  }
}
