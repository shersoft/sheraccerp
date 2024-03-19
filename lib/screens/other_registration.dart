import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:sheraccerp/models/other_registrations.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class OtherRegistration extends StatefulWidget {
  const OtherRegistration({Key? key}) : super(key: key);

  @override
  State<OtherRegistration> createState() => _OtherRegistrationState();
}

class _OtherRegistrationState extends State<OtherRegistration> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final nameControl = TextEditingController();
  final descriptionControl = TextEditingController();
  GlobalKey<AutoCompleteTextFieldState<String>> keyName = GlobalKey();
  DioService api = DioService();
  List<String> typeData = [];
  bool _isLoading = false,
      valueActive = true,
      valueCostCenter = false,
      valueFranchisee = false,
      valueBillWise = false,
      isExist = false;
  String id = '', lName = '';
  String _dropDownValue = '';
  DateTime now = DateTime.now();
  late OtherRegistrationModel otherRegistration;
  late List<OtherRegistrationModel> otherList = [];
  List<String> nameListDisplay = [];

  @override
  void initState() {
    super.initState();
    typeData.add('');
    Map data = otherRegistrationList[0];
    data.forEach((key, value) {
      typeData.add(key.toString());
      value.toList().asMap().forEach((k, v) {
        otherList.add(OtherRegistrationModel.fromJson(v));
      });
    });
    nameListDisplay.addAll(List<String>.from(
        otherList.map((item) => (item.name)).toList().map((s) => s).toList()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        actions: const [],
        title: const Text('OtherRegistration'),
      ),
      body: ProgressHUD(
        inAsyncCall: _isLoading,
        opacity: 0.0,
        child: tabBarWidget(),
      ),
    );
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
                        deleteOtherRegistration(context);
                      } else {
                        showInSnackBar('Please select Name');
                      }
                    }
                  : null,
              child: const Text('Delete'),
            ),
          ]),
        ),
        const Divider(),
        const Align(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Type',
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
              child: Text('Select type', textAlign: TextAlign.center),
            ),
            value: _dropDownValue.toString(),
            items: typeData.map<DropdownMenuItem<String>>((item) {
              return DropdownMenuItem<String>(
                value: item.toString(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _dropDownValue = value!;
                nameListDisplay.clear();
                nameListDisplay.addAll(List<String>.from(otherList
                    .where((element) =>
                        element.type.toLowerCase() ==
                        _dropDownValue.toLowerCase())
                    .toList()
                    .map((e) => e.name)));
                nameControl.text = '';
              });
            },
          ),
        ),
        const Divider(),
        SimpleAutoCompleteTextField(
          key: keyName,
          controller: nameControl,
          clearOnSubmit: false,
          suggestions: nameListDisplay,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: 'Name'),
          textSubmitted: (data) {
            lName = data;
            if (lName.isNotEmpty) {
              int _id = otherList
                  .firstWhere((element) => element.name == lName,
                      orElse: () => OtherRegistrationModel.emptyData())
                  .id;
              if (_id > 0) {
                id = _id.toString();
                isExist = true;
                findOtherRegistration(id);
              }
            }
          },
        ),
        TextField(
          controller: descriptionControl,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: 'Description'),
        )
      ],
    );
  }

  clear() {
    nameControl.text = '';
    descriptionControl.text = '';
    lName = '';
    id = '';
    _dropDownValue = '';
    setState(() {
      isExist = false;
    });
  }

  @override
  void dispose() {
    nameControl.dispose();
    descriptionControl.dispose();
    super.dispose();
  }

  void deleteOtherRegistration(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    bool result = await api.deleteOtherRegistration(id);
    if (result) {
      setState(() {
        _isLoading = false;
        showInSnackBar('Deleted : OtherRegistration removed.');
      });
    } else {
      showInSnackBar('error : Cannot delete this OtherRegistration.');
    }
  }

  void handleSubmitted(String action) async {
    setState(() {
      _isLoading = true;
    });

    var name = nameControl.text,
        description = descriptionControl.text,
        type = _dropDownValue;
    var data = {
      'name': name.toUpperCase(),
      'description': description,
      'type': type.toUpperCase(),
      'auto': id.isNotEmpty ? id.toString() : '0',
      'add1': '',
      'add2': '',
      'add3': '',
      'email': '',
      'user': userIdC,
      'cash': 0,
      'toolBarSale': 0
    };

    bool result = action == 'edit'
        ? await api.editOtherRegistration(data)
        : await api.addOtherRegistration(data);

    if (result) {
      saveAndRedirectToHome(action);
    } else {
      showInSnackBar(action == 'edit'
          ? 'error : Cannot edit this OtherRegistration.'
          : 'error : Cannot save this OtherRegistration.');
    }
  }

  void saveAndRedirectToHome(action) async {
    setState(() {
      _isLoading = false;
      showInSnackBar(action == 'edit'
          ? 'Updated : OtherRegistration edited.'
          : 'Saved : OtherRegistration created.');
    });
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  void findOtherRegistration(String id) {
    setState(() {
      _isLoading = true;
    });
    OtherRegistrationModel data = otherList.firstWhere((element) =>
        element.name.toLowerCase() == nameControl.text.toLowerCase());
    setState(() {
      nameControl.text = data.name ?? '';
      descriptionControl.text = data.description ?? '';
      _isLoading = false;
    });
  }
}
