import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:sheraccerp/models/tax_group_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/progress_hud.dart';
import 'package:intl/intl.dart';

class TaxRegistration extends StatefulWidget {
  const TaxRegistration({Key? key}) : super(key: key);

  @override
  State<TaxRegistration> createState() => _TaxRegistrationState();
}

class _TaxRegistrationState extends State<TaxRegistration> {
  GlobalKey<AutoCompleteTextFieldState<String>> keyName = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keySchedule = GlobalKey();
  DioService api = DioService();
  bool isLoading = false, isFloodCess = false, isExist = false;
  DateTime now = DateTime.now();
  final nameControl = TextEditingController();
  final scheduleControl = TextEditingController();
  final gstPControl = TextEditingController();
  final sGstControl = TextEditingController();
  final cGstControl = TextEditingController();
  final iGstControl = TextEditingController();
  final kfcControl = TextEditingController();
  List<String> groupNameListDisplay = [];
  late String fromDate, toDate;
  List<TaxGroupModel> taxGroupList = [];
  List<String> taxScheduleListDisplay = [];
  String id = '0';

  @override
  void initState() {
    super.initState();

    fromDate = DateFormat('dd-MM-yyyy').format(now);
    toDate = DateFormat('dd-MM-yyyy').format(now);

    loadData();
  }

  @override
  void dispose() {
    nameControl.dispose();
    scheduleControl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(actions: [
          IconButton(
            color: white,
            iconSize: 40,
            onPressed: () {
              clear();
            },
            icon: const Icon(Icons.clear),
          ),
          Visibility(
              visible: isExist,
              child: IconButton(
                icon: const Icon(Icons.delete),
                color: red,
                iconSize: 40,
                onPressed: () {
                  if (nameControl.text.isNotEmpty) {
                    deleteData();
                  }
                },
              )),
          IconButton(
              color: white,
              iconSize: 40,
              onPressed: () {
                if (nameControl.text.isNotEmpty &&
                    scheduleControl.text.isNotEmpty &&
                    cGstControl.text.isNotEmpty &&
                    sGstControl.text.isNotEmpty &&
                    iGstControl.text.isNotEmpty &&
                    gstPControl.text.isNotEmpty) {
                  saveData();
                }
              },
              icon: isExist ? const Icon(Icons.edit) : const Icon(Icons.save)),
        ], title: const Text('TaxGroupRegister')),
        body: ProgressHUD(
            inAsyncCall: isLoading,
            opacity: 0.0,
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(children: [
                  SimpleAutoCompleteTextField(
                    key: keyName,
                    controller: nameControl,
                    clearOnSubmit: false,
                    suggestions: groupNameListDisplay,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: 'Group Name'),
                    textSubmitted: (data) {
                      var lName = data;
                      if (lName.isNotEmpty) {
                        findTaxData();
                      }
                    },
                  ),
                  const Divider(),
                  SimpleAutoCompleteTextField(
                    key: keySchedule,
                    controller: scheduleControl,
                    clearOnSubmit: false,
                    suggestions: taxScheduleListDisplay,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Schedule Name'),
                    textSubmitted: (data) {
                      var lName = data;
                      if (lName.isNotEmpty) {
                        findTaxData();
                      }
                    },
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: gstPControl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(), labelText: 'GST %'),
                        ),
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Expanded(
                        child: TextField(
                          controller: sGstControl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(), labelText: 'SGST'),
                        ),
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Expanded(
                        child: TextField(
                          controller: cGstControl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(), labelText: 'CGST'),
                        ),
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Expanded(
                        child: TextField(
                          controller: iGstControl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(), labelText: 'IGST'),
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                      child: TextField(
                        controller: kfcControl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: 'KFC'),
                      ),
                      visible: isFloodCess),
                  const Divider(),
                  Card(
                    elevation: 5,
                    child: SizedBox(
                      height: 50,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Start Date'),
                            InkWell(
                              child: Text(
                                fromDate,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              onTap: () => _selectDateFrom(),
                            ),
                            const Text('End Date'),
                            InkWell(
                              child: Text(
                                toDate,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              onTap: () => _selectDateTo(),
                            ),
                          ]),
                    ),
                  ),
                  Expanded(
                    child: taxGroupList.isNotEmpty
                        ? ListView.builder(
                            itemCount: taxGroupList.length,
                            itemBuilder: (context, index) => Card(
                                  child: ListTile(
                                    title: Text(
                                      '${taxGroupList[index].name} / ${taxGroupList[index].schedule}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    subtitle: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'GST% : ${taxGroupList[index].gst}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        Text(
                                          'CGST : ${taxGroupList[index].cGst}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        Text(
                                          'SGST : ${taxGroupList[index].sGst}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        Text(
                                          'IGST : ${taxGroupList[index].iGst}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        Text(
                                          'KFC : ${taxGroupList[index].fCess}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(DateUtil.dateDMY(
                                            taxGroupList[index].sDate)),
                                        Text(DateUtil.dateDMY(
                                            taxGroupList[index].eDate))
                                      ],
                                    ),
                                    onTap: () {
                                      TaxGroupModel dataModel =
                                          taxGroupList[index];
                                      setState(() {
                                        cGstControl.text =
                                            dataModel.cGst.toStringAsFixed(2);
                                        kfcControl.text =
                                            dataModel.fCess.toStringAsFixed(2);
                                        iGstControl.text =
                                            dataModel.iGst.toStringAsFixed(2);
                                        gstPControl.text =
                                            dataModel.iGst.toStringAsFixed(2);
                                        nameControl.text = dataModel.name;
                                        sGstControl.text =
                                            dataModel.sGst.toStringAsFixed(2);
                                        scheduleControl.text =
                                            dataModel.schedule;
                                        id = dataModel.id.toString();
                                        fromDate =
                                            DateUtil.dateDMY(dataModel.sDate);
                                        toDate =
                                            DateUtil.dateDMY(dataModel.eDate);
                                        isExist =
                                            dataModel.id > 0 ? true : false;
                                      });
                                    },
                                  ),
                                ))
                        : const Loading(),
                  )
                ]))));
  }

  saveData() {
    setState(() {
      isLoading = true;
    });
    var data = {
      'auto': id,
      'taxGroup': nameControl.text,
      'schedule': scheduleControl.text,
      'gstP': gstPControl.text,
      'cGST': cGstControl.text,
      'sGST': sGstControl.text,
      'iGST': iGstControl.text,
      'kfc': kfcControl.text.isNotEmpty ? kfcControl.text : '0',
      'sDate': DateUtil.dateYMD(fromDate),
      'eDate': DateUtil.dateYMD(toDate)
    };

    if (isExist && double.parse(id) > 0) {
      api.taxGroupEdit(data).then((value) {
        if (value) {
          showInSnackBar('edited');
          loadData();
        } else {
          showInSnackBar('failed');
        }
      });
    } else {
      api.taxGroupAdd(data).then((value) {
        if (value) {
          showInSnackBar('Saved');
          loadData();
        } else {
          showInSnackBar('Failed');
        }
      });
    }
  }

  deleteData() {
    setState(() {
      isLoading = true;
    });
    var data = {
      'auto': id,
      'taxGroup': nameControl.text,
    };

    if (isExist && double.parse(id) > 0) {
      api.taxGroupDelete(data).then((value) {
        if (value) {
          showInSnackBar('Deleted');
          loadData();
        } else {
          showInSnackBar('Failed');
        }
      });
    }
  }

  void showInSnackBar(String value) {
    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  void clear() {
    setState(() {
      nameControl.text = '';
      kfcControl.text = '';
      cGstControl.text = '';
      iGstControl.text = '';
      sGstControl.text = '';
      scheduleControl.text = '';
      gstPControl.text = '';

      fromDate = DateFormat('dd-MM-yyyy').format(now);
      toDate = DateFormat('dd-MM-yyyy').format(now);
      isExist = false;
      id = '0';
    });
  }

  _selectDateFrom() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => {fromDate = DateFormat('dd-MM-yyyy').format(picked)});
    }
  }

  _selectDateTo() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => {toDate = DateFormat('dd-MM-yyyy').format(picked)});
    }
  }

  void findTaxData() {
    if (nameControl.text.isNotEmpty && scheduleControl.text.isNotEmpty) {
      var name = nameControl.text.toUpperCase();
      var schedule = scheduleControl.text.toUpperCase();
      try {
        TaxGroupModel dataModel = taxGroupList.firstWhere(
            (element) => element.name == name && element.schedule == schedule,
            orElse: TaxGroupModel.emptyData());
        if (dataModel.id > 0) {
          setState(() {
            cGstControl.text = dataModel.cGst.toStringAsFixed(2);
            kfcControl.text = dataModel.fCess.toStringAsFixed(2);
            iGstControl.text = dataModel.iGst.toStringAsFixed(2);
            gstPControl.text = dataModel.iGst.toStringAsFixed(2);
            nameControl.text = dataModel.name;
            sGstControl.text = dataModel.sGst.toStringAsFixed(2);
            scheduleControl.text = dataModel.schedule;
            id = dataModel.id.toString();
            fromDate = DateUtil.dateDMY(dataModel.sDate);
            toDate = DateUtil.dateDMY(dataModel.eDate);
            id = dataModel.id.toString();
            isExist = true;
          });
        } else {
          setState(() {
            isExist = false;
            id = '0';
          });
        }
      } catch (ex) {
        debugPrint(ex.toString());
      }
    }
  }

  void loadData() {
    api.taxGroupAll().then((value) {
      setState(() {
        taxGroupList.addAll(value);
      });

      groupNameListDisplay.addAll(List<String>.from(taxGroupList
          .map((item) => (item.name))
          .toList()
          .map((s) => s)
          .toList()));

      taxScheduleListDisplay.addAll(List<String>.from(taxGroupList
          .map((item) => (item.schedule))
          .toList()
          .map((s) => s)
          .toList()));
    });
  }
}
