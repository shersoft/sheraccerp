// @dart = 2.11

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/models/ledger_parent.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class GroupRegistration extends StatefulWidget {
  const GroupRegistration({Key key}) : super(key: key);

  @override
  _GroupRegistrationState createState() => _GroupRegistrationState();
}

class _GroupRegistrationState extends State<GroupRegistration> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _nameCtr = TextEditingController();
  GlobalKey<AutoCompleteTextFieldState<String>> keyGroupRegistrationName =
      GlobalKey();

  DioService api = DioService();
  bool _isLoading = false,
      isUnderSelected = false,
      isExist = false,
      buttonEvent = false;
  String GroupRegistrationId = '';
  List<LedgerModel> GroupRegistrationList = [];
  List<String> GroupRegistrationListDisplay = [];
  List<dynamic> GroupRegistrationGroupList = [];
  String lName = '';
  int locationId = 1, salesManId = 0;

  @override
  void initState() {
    super.initState();
    // settings = ScopedModel.of<MainModel>(context).getSettings();

    // api.getGroupRegistrationAll().then(
    //   (value) {
    //     setState(() {
    //       GroupRegistrationList.addAll(value);
    //       GroupRegistrationListDisplay.addAll(List<String>.from(GroupRegistrationList
    //           .map((item) => (item.name))
    //           .toList()
    //           .map((s) => s)
    //           .toList()));
    //     });
    //   },
    // );
    api.getLedgerParent().then((value) {
      setState(() {
        GroupRegistrationGroupList.addAll(value);
        GroupRegistrationGroupList.add(LedgerParent(id: 0, name: ''));
      });
    });
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
            ? GroupRegistrationGroupList.firstWhere(
                (element) => element.name == parentName,
                orElse: () => LedgerModel(id: 0, name: '')).id
            : _dropDownValue;
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
        title: const Text("GroupRegistration"),
      ),
      body: ProgressHUD(
        inAsyncCall: _isLoading,
        opacity: 0.0,
        // child: detailWidget(),
        child: tabBarWidget(),
      ),
    );
  }

  void _deleteGroupRegistration(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    bool result =
        false; //await api.spGroupRegistrationDelete(GroupRegistrationId);
    if (result) {
      setState(() {
        _isLoading = false;
        showInSnackBar('Deleted : GroupRegistration removed.');
      });
    } else {
      showInSnackBar('error : Cannot delete this GroupRegistration.');
    }
  }

  void _handleSubmitted(String action) async {
    setState(() {
      _isLoading = true;
    });

    var name = _nameCtr.text;
    var data = [
      {
        'name': name.toUpperCase(),
        'parent': _dropDownValue,
      }
    ];

    bool result = false; //action == 'edit'
    //     ? await api.spGroupRegistrationEdit(data)
    //     : await api.spGroupRegistrationAdd(data);

    if (result) {
      _saveAndRedirectToHome(action);
    } else {
      showInSnackBar(action == 'edit'
          ? 'error : Cannot edit this GroupRegistration.'
          : 'error : Cannot save this GroupRegistration.');
    }
  }

  void _saveAndRedirectToHome(action) async {
    setState(() {
      _isLoading = false;
      showInSnackBar(action == 'edit'
          ? 'Updated : GroupRegistration edited.'
          : 'Saved : GroupRegistration created.');
    });
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  int _dropDownValue = 0;

  findGroupRegistration(id) {
    setState(() {
      _isLoading = true;
    });
    // api.findGroupRegistration(id).then((value) {
    //   var data = value[0][0];
    //   setState(() {
    //     _nameCtr.text = data['LedName'] ?? '';
    //     if (data['lh_id'] > 0) {
    //       _dropDownValue = data['lh_id'];
    //     }
    //   });
    //   setState(() {
    //     _isLoading = false;
    //   });
    // });
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
                      if (GroupRegistrationId.isNotEmpty) {
                        setState(() {
                          _isLoading = true;
                          buttonEvent = true;
                        });
                        _handleSubmitted('edit');
                      } else {
                        showInSnackBar('Please select GroupRegistration');
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
                      if (GroupRegistrationId.isEmpty) {
                        setState(() {
                          _isLoading = true;
                          buttonEvent = true;
                        });
                        _handleSubmitted('save');
                      } else {
                        showInSnackBar('Please add GroupRegistration');
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
                          if (GroupRegistrationId.isNotEmpty) {
                            setState(() {
                              _isLoading = true;
                              buttonEvent = true;
                            });
                            _deleteGroupRegistration(context);
                          } else {
                            showInSnackBar('Please select GroupRegistration');
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
                  if (value == 'ReName GroupRegistration') {
                    if (lName.isNotEmpty) {
                      _reNameGroupRegistrationDialog(context);
                    }
                  }
                });
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'ReName GroupRegistration',
                  child: Text('ReName GroupRegistration'),
                ),
              ],
            ),
          ]),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              children: [
                const Divider(),
                SimpleAutoCompleteTextField(
                  key: keyGroupRegistrationName,
                  controller: _nameCtr,
                  clearOnSubmit: false,
                  suggestions: GroupRegistrationListDisplay,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'GroupRegistration Name'),
                  textSubmitted: (data) {
                    lName = data;
                    if (lName.isNotEmpty) {
                      int _id = GroupRegistrationList.firstWhere(
                          (element) => element.name == lName,
                          orElse: () => LedgerModel(id: 0, name: '')).id;
                      if (_id > 0) {
                        GroupRegistrationId = _id.toString();
                        isExist = true;
                        findGroupRegistration(GroupRegistrationId);
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
                      child: Text('Select under', textAlign: TextAlign.center),
                    ),
                    value: _dropDownValue.toString(),
                    items: GroupRegistrationGroupList.map<
                        DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem<String>(
                        value: item.id.toString(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child:
                              Text(item.name, overflow: TextOverflow.ellipsis),
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
        ),
      ],
    );
  }

  clear() {}

  final TextEditingController _textFieldController = TextEditingController();

  _reNameGroupRegistrationDialog(BuildContext context) async {
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
                bool _state = false; //await api.renameGroupRegistration(body);
                _state
                    ? showInSnackBar('GroupRegistration Name Renamed')
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
    // _nameCtr.dispose();
    super.dispose();
  }
}
