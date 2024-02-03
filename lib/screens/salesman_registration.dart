import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:sheraccerp/models/sales_man_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/option_radio_group.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';
import 'package:intl/intl.dart';

class SalesmanRegistration extends StatefulWidget {
  const SalesmanRegistration({Key? key}) : super(key: key);

  @override
  State<SalesmanRegistration> createState() => _SalesmanRegistrationState();
}

class _SalesmanRegistrationState extends State<SalesmanRegistration> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final nameControl = TextEditingController();
  final sectionControl = TextEditingController();
  final addressControl = TextEditingController();
  final address2Control = TextEditingController();
  final address3Control = TextEditingController();
  final mobileControl = TextEditingController();
  final salaryControl = TextEditingController();
  final otRateControl = TextEditingController();
  final otHourControl = TextEditingController();
  final dailyAllowanceControl = TextEditingController();
  final liveDeductionControl = TextEditingController();
  final casualLeaveControl = TextEditingController();
  final commissionPercentageControl = TextEditingController();
  final workingHourControl = TextEditingController();
  final pfControl = TextEditingController();
  final userNameControl = TextEditingController();
  final passwordControl = TextEditingController();

  GlobalKey<AutoCompleteTextFieldState<String>> keyName = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keySection = GlobalKey();
  DioService api = DioService();
  bool _isLoading = false,
      isExist = false,
      active = true,
      isSelectedApp = false;
  String id = '', lName = '';
  String _dropDownValueType = 'Monthly';
  String _dropDownValueCommissionStatus = 'No';
  DateTime now = DateTime.now();
  late SalesManModel salesman;
  late EmployeeModel employee;
  late List<SalesManModel> salesmanList = [];
  List<String> nameListDisplay = [];
  List<String> typeData = [
    "Monthly",
    "Daily",
    "Work Basis",
    "Per Hour Basis",
    "Weekly"
  ];
  List<String> commissionStatus = ["No", "Yes"];
  int? selectedGender;
  late String formattedDate;
  int locationId = 1;

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    api.getSalesManListAll().then((value) {
      salesmanList.addAll(value);
      nameListDisplay.addAll(List<String>.from(salesmanList
          .map((item) => (item.name))
          .toList()
          .map((s) => s)
          .toList()));
    });
    locationId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        actions: const [],
        title: const Text('Salesman'),
      ),
      body: ProgressHUD(
        inAsyncCall: _isLoading,
        opacity: 0.0,
        child: contentWidget(),
      ),
    );
  }

  contentWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        Expanded(
          flex: 0,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ElevatedButton(
              child: Text(isExist ? 'Edit' : 'Save'),
              onPressed: () {
                if (isExist) {
                  if (id.isNotEmpty) {
                    setState(() {
                      _isLoading = true;
                    });
                    handleSubmitted('edit');
                  } else {
                    showInSnackBar('Please select Name');
                  }
                } else {
                  if (id.isEmpty) {
                    setState(() {
                      _isLoading = true;
                    });
                    handleSubmitted('save');
                  } else {
                    showInSnackBar('Please add Name');
                  }
                }
              },
            ),
            ElevatedButton(
                onPressed: () => clear(), child: const Text('Clear')),
            ElevatedButton(
              onPressed: isExist
                  ? () {
                      if (id.isNotEmpty) {
                        setState(() {
                          _isLoading = true;
                        });
                        deleteData(context);
                      } else {
                        showInSnackBar('Please select Name');
                      }
                    }
                  : null,
              child: const Text('Delete'),
            ),
            // PopupMenuButton<String>(
            //   icon: const Icon(Icons.settings, color: blue),
            //   onSelected: (value) {
            //     setState(() {
            //       if (value == 'ReName') {
            //         if (lName.isNotEmpty) {
            //           _reNameDialog(context);
            //         }
            //       }
            //     });
            //   },
            //   itemBuilder: (BuildContext context) => [
            //     const PopupMenuItem<String>(
            //       value: 'ReName',
            //       child: Text('ReName'),
            //     ),
            //   ],
            // ),
          ]),
        ),
        const Divider(
          height: 1,
        ),
        SimpleAutoCompleteTextField(
          key: keyName,
          controller: nameControl,
          clearOnSubmit: false,
          suggestions: nameListDisplay,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: 'Employee Name'),
          textSubmitted: (data) {
            lName = data;
            if (lName.isNotEmpty) {
              int _id = salesmanList
                  .firstWhere((element) => element.name == lName,
                      orElse: () => SalesManModel.emptyData())
                  .id;
              if (_id > 0) {
                id = _id.toString();
                isExist = true;
                findSalesman(lName);
              }
            }
          },
        ),
        const Divider(
          height: 1,
        ),
        // SimpleAutoCompleteTextField(
        //   key: keySection,
        //   controller: sectionControl,
        //   clearOnSubmit: false,
        //   suggestions: [''],
        //   decoration: const InputDecoration(
        //       border: OutlineInputBorder(), labelText: 'Section'),
        // ),
        const Divider(
          height: 1,
        ),
        Card(
          elevation: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gender'),
              Expanded(
                child: OptionRadio(
                    text: 'Male',
                    index: 0,
                    selectedButton: selectedGender,
                    press: (val) {
                      setState(() {
                        selectedGender = val;
                      });
                    }),
              ),
              Expanded(
                child: OptionRadio(
                    text: 'Female',
                    index: 1,
                    selectedButton: selectedGender,
                    press: (val) {
                      setState(() {
                        selectedGender = val;
                      });
                    }),
              ),
            ],
          ),
        ),
        const Divider(
          height: 2,
        ),
        SizedBox(
          height: 230,
          child: ListView(
            children: [
              TextField(
                controller: addressControl,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Address'),
              ),
              const Divider(
                height: 2,
              ),
              TextField(
                controller: address2Control,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Address2'),
              ),
              const Divider(
                height: 2,
              ),
              TextField(
                controller: address3Control,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Address3'),
              ),
              const Divider(
                height: 2,
              ),
              TextField(
                controller: mobileControl,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Mobile'),
              ),
            ],
          ),
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
                    Tab(text: "Payroll", icon: Icon(Icons.roller_shades)),
                    Tab(text: "Details", icon: Icon(Icons.read_more)),
                    Tab(
                        text: "Payroll App",
                        icon: Icon(Icons.supervised_user_circle)),
                    // Tab(
                    //     text: "Rate Type",
                    //     icon: Icon(Icons.format_list_numbered)),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: ListView(
                      children: [
                        Card(
                          elevation: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              const Align(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Type',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10),
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft),
                              Expanded(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Select type',
                                        textAlign: TextAlign.center),
                                  ),
                                  value: _dropDownValueType.toString(),
                                  items: typeData
                                      .map<DropdownMenuItem<String>>((item) {
                                    return DropdownMenuItem<String>(
                                      value: item.toString(),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(item,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _dropDownValueType = value!;
                                    });
                                  },
                                ),
                              ),
                              const Text(
                                'Date Of Join ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                              InkWell(
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                onTap: () => _selectDate(),
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
                                controller: salaryControl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Basic Salary'),
                              ),
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Expanded(
                              child: TextField(
                                controller: otHourControl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'O.T Hour'),
                              ),
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Expanded(
                              child: TextField(
                                controller: otRateControl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'O.T Rate'),
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
                                controller: dailyAllowanceControl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Daily Allowances'),
                              ),
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Expanded(
                              child: TextField(
                                controller: casualLeaveControl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Casual Leave/Year'),
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
                                controller: liveDeductionControl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Leave Deduction'),
                              ),
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Card(
                              elevation: 2,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Active'),
                                  Checkbox(
                                    value: active,
                                    onChanged: (value) {
                                      setState(() {
                                        active = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ListView(
                      children: [
                        const Divider(),
                        Card(
                          elevation: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Align(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Commission Status',
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft),
                              Expanded(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value:
                                      _dropDownValueCommissionStatus.toString(),
                                  items: commissionStatus
                                      .map<DropdownMenuItem<String>>((item) {
                                    return DropdownMenuItem<String>(
                                      value: item.toString(),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(item,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _dropDownValueCommissionStatus = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: commissionPercentageControl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: '%'),
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
                                controller: pfControl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'P.F'),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Expanded(
                              child: TextField(
                                controller: workingHourControl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Working Hours'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ListView(
                      children: [
                        const Divider(),
                        TextField(
                          controller: userNameControl,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'UserName'),
                        ),
                        const Divider(),
                        TextField(
                          controller: passwordControl,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Password'),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('App Enable'),
                            Switch(
                                onChanged: (bool value) {
                                  setState(() {
                                    isSelectedApp = value;
                                  });
                                },
                                value: isSelectedApp),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  clear() {
    nameControl.text = '';
    address2Control.text = '';
    address3Control.text = '';
    addressControl.text = '';
    mobileControl.text = '';
    salaryControl.text = '';
    otRateControl.text = '';
    otHourControl.text = '';
    dailyAllowanceControl.text = '';
    liveDeductionControl.text = '';
    casualLeaveControl.text = '';
    commissionPercentageControl.text = '';
    workingHourControl.text = '';
    pfControl.text = '';
    userNameControl.text = '';
    passwordControl.text = '';
    lName = '';
    id = '';
    _dropDownValueType = typeData[0];
    setState(() {
      isExist = false;
    });
  }

  @override
  void dispose() {
    nameControl.dispose();
    addressControl.dispose();
    address2Control.dispose();
    address3Control.dispose();
    mobileControl.dispose();
    salaryControl.dispose();
    otRateControl.dispose();
    otHourControl.dispose();
    dailyAllowanceControl.dispose();
    liveDeductionControl.dispose();
    casualLeaveControl.dispose();
    commissionPercentageControl.dispose();
    workingHourControl.dispose();
    pfControl.dispose();
    userNameControl.dispose();
    passwordControl.dispose();
    super.dispose();
  }

  void deleteData(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    bool result = await api.deleteSalesman(id, nameControl.text);
    if (result) {
      setState(() {
        _isLoading = false;
        showInSnackBar('Deleted : Salesman removed.');
        salesmanList.remove(employee);
        nameListDisplay.remove(nameControl.text);
        clear();
      });
    } else {
      showInSnackBar('error : Cannot delete this Salesman.');
    }
  }

  void handleSubmitted(String action) async {
    if (nameControl.text.trim().isNotEmpty &&
        salaryControl.text.trim().isNotEmpty &&
        _dropDownValueType.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      var _gender = selectedGender == 0 ? "M" : "F";
      var data = {
        'auto': id.isNotEmpty ? id.toString() : '0',
        'name': nameControl.text.isNotEmpty
            ? nameControl.text.trim().toUpperCase()
            : '',
        'address1': addressControl.text.isNotEmpty
            ? addressControl.text.trim().toUpperCase()
            : '',
        'address2': address2Control.text.isNotEmpty
            ? address2Control.text.trim().toUpperCase()
            : '',
        'address3': address3Control.text.isNotEmpty
            ? address3Control.text.trim().toUpperCase()
            : '',
        'mobile': mobileControl.text.isNotEmpty
            ? mobileControl.text.trim().toUpperCase()
            : '',
        'section': '',
        'location': locationId,
        'gender': _gender,
        'date': DateUtil.dateYMD(formattedDate),
        'type': _dropDownValueType,
        'salary': salaryControl.text.isNotEmpty ? salaryControl.text.trim() : 0,
        'ot': otRateControl.text.isNotEmpty ? otRateControl.text.trim() : 0,
        'otHour': otHourControl.text.isNotEmpty ? otHourControl.text.trim() : 0,
        'liveDeduction': liveDeductionControl.text.isNotEmpty
            ? liveDeductionControl.text.trim()
            : 0,
        'dailyAllowance': dailyAllowanceControl.text.isNotEmpty
            ? dailyAllowanceControl.text.trim()
            : 0,
        'casualLeave': casualLeaveControl.text.isNotEmpty
            ? casualLeaveControl.text.trim()
            : 0,
        'active': active ? 1 : 0,
        'commissionStatus': _dropDownValueCommissionStatus,
        'commissionPercentage': commissionPercentageControl.text.isNotEmpty
            ? commissionPercentageControl.text.trim()
            : 0,
        'pf': pfControl.text.isNotEmpty ? pfControl.text.trim() : 0,
        'workingHour': workingHourControl.text.isNotEmpty
            ? workingHourControl.text.trim().toString()
            : '0',
        'telephone': '',
        'activate': isSelectedApp,
        'total': 0,
        'tickEligibility': 0,
        'min': '',
        'empCode': '0',
        'empId': '',
        'vehicleCommission': 0,
        'loadingCharge': 0,
        'mode': '',
        'lunchMin': 0,
        'sms': '',
        'esi': 0,
        'att': 0,
        'expDate': '2020-01-01',
        'expDateArabic': '2020-01-01',
        'baladiyaExpDate': '2020-01-01',
        'passportExpDate': '2020-01-01',
        'user': userIdC,
        'daysInaMonth': 0,
        'presentDays': 0,
      };

      bool result = action == 'edit'
          ? await api.editSalesman(data)
          : await api.addSalesman(data);

      if (result) {
        saveAndRedirectToHome(action);
      } else {
        showInSnackBar(action == 'edit'
            ? 'error : Cannot edit this Salesman.'
            : 'error : Cannot save this Salesman.');
      }
    } else {
      showInSnackBar(action == 'edit'
          ? 'error : Cannot edit select name.'
          : 'error : Cannot save select name.');
    }
  }

  void saveAndRedirectToHome(action) async {
    setState(() {
      _isLoading = false;
      showInSnackBar(action == 'edit'
          ? 'Edited : Salesman edited.'
          : 'Saved : Salesman created.');
    });
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  void findSalesman(String name) {
    setState(() {
      _isLoading = true;
    });
    api.findSalesman(name).then((valueData) {
      employee = valueData;
      setState(() {
        isExist = true;
        nameControl.text = employee.name ?? '';
        lName = nameControl.text;
        addressControl.text = employee.address1 ?? '';
        address2Control.text = employee.address2 ?? '';
        address3Control.text = employee.address3 ?? '';
        mobileControl.text = employee.mobile ?? '';
        salaryControl.text = employee.salary.toString();
        otRateControl.text = employee.ot.toString();
        otHourControl.text = employee.otHour.toString();
        dailyAllowanceControl.text = employee.dailyAllowance.toString();
        liveDeductionControl.text = employee.liveDeduction.toString();
        casualLeaveControl.text = employee.casualLeave.toString();
        commissionPercentageControl.text =
            employee.commissionPercentage.toString();
        workingHourControl.text = employee.workingHour;
        pfControl.text = employee.pf.toString();
        userNameControl.text = '';
        passwordControl.text = '';
        isSelectedApp = employee.activate;
        active = employee.active == 1 ? true : false;
        // .text = employee.att;
        id = employee.auto.toString();
        // .text = employee.baladiyaExpiryDate;
        _dropDownValueCommissionStatus = employee.commissionStatus;
        formattedDate = DateUtil.dateDMY(employee.date);
        // .text = employee.empCode;
        // .text = employee.empId;
        // .text = employee.employeeSection;
        // .text = employee.esi;
        // .text = employee.expiryDate;
        // .text = employee.expiryDateArabic;
        selectedGender = employee.gender == 'M' ? 0 : 1;
        // .text = employee.ledCode;
        // .text = employee.loadingCharge;
        locationId = employee.location;
        // .text = employee.lunchMin;
        // .text = employee.min;
        // .text = employee.mode;
        // .text = employee.passportExpiryDate;
        // .text = employee.sms;
        // .text = employee.telephone;
        // .text = employee.tickEligibility;
        // .text = employee.total;
        _dropDownValueType = employee.type;
        // .text = employee.vehicleCommission;

        _isLoading = false;
      });
    });
  }

  final TextEditingController _textFieldController = TextEditingController();

  _reNameDialog(BuildContext context) {
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
                bool _state = await api.renameSalesMan(body);
                _state
                    ? showInSnackBar('Ledger Name Renamed')
                    : showInSnackBar('Error');
                if (_state) {
                  nameControl.text = _textFieldController.text.toUpperCase();
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

  Future _selectDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => {formattedDate = DateFormat('dd-MM-yyyy').format(picked)});
    }
  }
}
