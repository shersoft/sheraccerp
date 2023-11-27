import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:sheraccerp/models/user_model.dart';
import 'package:sheraccerp/screens/ui/user_list_screen.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';
import 'package:intl/intl.dart';

class UserRegistration extends StatefulWidget {
  const UserRegistration({Key? key}) : super(key: key);

  @override
  State<UserRegistration> createState() => _UserRegistrationState();
}

class _UserRegistrationState extends State<UserRegistration> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final groupNameControl = TextEditingController();
  final userNameControl = TextEditingController();
  final passwordControl = TextEditingController();
  final confirmPasswordControl = TextEditingController();

  GlobalKey<AutoCompleteTextFieldState<String>> keyName = GlobalKey();
  GlobalKey<AutoCompleteTextFieldState<String>> keyGroupName = GlobalKey();
  DioService api = DioService();
  bool _isLoading = false,
      isExist = false,
      isExistGroup = false,
      active = true,
      isSelectedApp = false,
      showPassword = true,
      showConPassword = true;
  String id = '', idGroup = '', lName = '', gName = '';
  DateTime now = DateTime.now();
  late String formattedDate;
  int locationId = 1;
  List<String> nameListDisplay = [];
  List<String> groupListDisplay = [];
  String valueGroupType = 'ADMIN';
  late UserModel userModel;
  late UserGroupModel groupModel;
  List<UserModel> userList = [];
  List<UserGroupModel> groupList = [];

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    api.getUserListAll().then((value) {
      userList.addAll(value);
      setState(() {
        nameListDisplay.addAll(List<String>.from(userList
            .map((item) => (item.userName))
            .toList()
            .map((s) => s)
            .toList()));
      });
    });

    api.getUserGroupListAll().then((value) {
      groupList.addAll(value);
      setState(() {
        groupListDisplay.addAll(List<String>.from(groupList
            .map((item) => (item.name))
            .toList()
            .map((s) => s)
            .toList()));
      });
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
        title: const Text('User'),
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
        child: DefaultTabController(
            length: 2,
            child: Scaffold(
                appBar: AppBar(
                  backgroundColor: blue,
                  automaticallyImplyLeading: false,
                  flexibleSpace: const TabBar(
                    indicatorWeight: 5,
                    tabs: [
                      Tab(text: "User", icon: Icon(Icons.person_rounded)),
                      Tab(
                          text: "Group",
                          icon: Icon(Icons.supervised_user_circle)),
                    ],
                  ),
                ),
                body: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TabBarView(children: [
                        Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: ListView(children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
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
                                            showInSnackBar(
                                                'Please select Name');
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
                                        onPressed: () => clear(),
                                        child: const Text('Clear')),
                                    ElevatedButton(
                                      onPressed: isExist
                                          ? () {
                                              if (id.isNotEmpty) {
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                deleteData(context);
                                              } else {
                                                showInSnackBar(
                                                    'Please select Name');
                                              }
                                            }
                                          : null,
                                      child: const Text('Delete'),
                                    ),
                                  ]),
                              const Divider(
                                height: 1,
                              ),
                              Card(
                                elevation: 10,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Align(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'Group',
                                          ),
                                        ),
                                        alignment: Alignment.centerLeft),
                                    Expanded(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: valueGroupType,
                                        items: groupListDisplay
                                            .map<DropdownMenuItem<String>>(
                                                (item) {
                                          return DropdownMenuItem<String>(
                                            value: item.toString(),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(item,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            valueGroupType = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                              SimpleAutoCompleteTextField(
                                key: keyName,
                                controller: userNameControl,
                                clearOnSubmit: false,
                                suggestions: nameListDisplay,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'User name'),
                                textSubmitted: (data) {
                                  lName = data;
                                  if (lName.isNotEmpty) {
                                    int _id = userList
                                        .firstWhere(
                                            (element) =>
                                                element.userName == lName,
                                            orElse: () => UserModel.emptyData())
                                        .id;
                                    if (_id > 0) {
                                      id = _id.toString();
                                      isExist = true;
                                      findUser(lName);
                                    }
                                  }
                                },
                              ),
                              const Divider(),
                              TextField(
                                controller: passwordControl,
                                decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    icon: const Icon(
                                      Icons.lock,
                                      color: kPrimaryColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.visibility),
                                      color: kPrimaryColor,
                                      onPressed: () => setState(
                                          () => showPassword = !showPassword),
                                    ),
                                    labelText: 'Password'),
                                obscureText: showPassword,
                              ),
                              const Divider(),
                              TextField(
                                controller: confirmPasswordControl,
                                decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    icon: const Icon(
                                      Icons.lock,
                                      color: kPrimaryColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.visibility),
                                      color: kPrimaryColor,
                                      onPressed: () => setState(() =>
                                          showConPassword = !showConPassword),
                                    ),
                                    labelText: 'Confirm password'),
                                obscureText: showConPassword,
                              ),
                            ])),
                        Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: ListView(children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      child:
                                          Text(isExistGroup ? 'Edit' : 'Save'),
                                      onPressed: () {
                                        if (isExistGroup) {
                                          if (idGroup.isNotEmpty) {
                                            setState(() {
                                              _isLoading = true;
                                            });
                                            handleSubmittedGroup('edit');
                                          } else {
                                            showInSnackBar(
                                                'Please select Group Name');
                                          }
                                        } else {
                                          if (idGroup.isEmpty) {
                                            setState(() {
                                              _isLoading = true;
                                            });
                                            handleSubmittedGroup('save');
                                          } else {
                                            showInSnackBar(
                                                'Please add Group Name');
                                          }
                                        }
                                      },
                                    ),
                                    ElevatedButton(
                                        onPressed: () => clear(),
                                        child: const Text('Clear')),
                                    ElevatedButton(
                                      onPressed: isExistGroup
                                          ? () {
                                              if (idGroup.isNotEmpty) {
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                deleteDataGroup(context);
                                              } else {
                                                showInSnackBar(
                                                    'Please select Group Name');
                                              }
                                            }
                                          : null,
                                      child: const Text('Delete'),
                                    ),
                                  ]),
                              const Divider(
                                height: 1,
                              ),
                              SimpleAutoCompleteTextField(
                                key: keyGroupName,
                                controller: groupNameControl,
                                clearOnSubmit: false,
                                suggestions: groupListDisplay,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Group name'),
                                textSubmitted: (data) {
                                  gName = data;
                                  if (gName.isNotEmpty) {
                                    findUserGroup(gName);
                                  }
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Card(
                                    color: kPrimaryColor[100],
                                    elevation: 5,
                                    child: Row(
                                      children: [
                                        const Text("Save"),
                                        Checkbox(
                                            value: valueSave,
                                            onChanged: (value) {
                                              setState(() {
                                                valueSave = value!;
                                              });
                                            }),
                                      ],
                                    ),
                                  ),
                                  Card(
                                    color: kPrimaryColor[100],
                                    elevation: 5,
                                    child: Row(
                                      children: [
                                        const Text("Edit"),
                                        Checkbox(
                                            value: valueEdit,
                                            onChanged: (value) {
                                              setState(() {
                                                valueEdit = value!;
                                              });
                                            }),
                                      ],
                                    ),
                                  ),
                                  Card(
                                    color: kPrimaryColor[100],
                                    elevation: 5,
                                    child: Row(
                                      children: [
                                        const Text("Delete"),
                                        Checkbox(
                                            value: valueDelete,
                                            onChanged: (value) {
                                              setState(() {
                                                valueDelete = value!;
                                              });
                                            }),
                                      ],
                                    ),
                                  ),
                                  Card(
                                    color: kPrimaryColor[100],
                                    elevation: 5,
                                    child: Row(
                                      children: [
                                        const Text("Find"),
                                        Checkbox(
                                            value: valueFind,
                                            onChanged: (value) {
                                              setState(() {
                                                valueFind = value!;
                                              });
                                            }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ]))
                      ]),
                    ),
                  ],
                ))));
  }

  bool valueSave = true, valueEdit = true, valueDelete = true, valueFind = true;

  clear() {
    groupNameControl.text = '';
    userNameControl.text = '';
    passwordControl.text = '';
    confirmPasswordControl.text = '';
    lName = '';
    gName = '';
    id = '';
    idGroup = '';
    valueGroupType =
        groupListDisplay.isNotEmpty ? groupListDisplay[0] : 'ADMIN';
    setState(() {
      isExist = false;
      isExistGroup = false;
    });
  }

  @override
  void dispose() {
    groupNameControl.dispose();
    userNameControl.dispose();
    passwordControl.dispose();
    confirmPasswordControl.dispose();

    super.dispose();
  }

  void deleteData(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    bool result = await api.deleteUser(id, userNameControl.text);
    if (result) {
      setState(() {
        _isLoading = false;
        showInSnackBar('Deleted : User removed.');
        nameListDisplay.remove(userNameControl.text);
        clear();
      });
    } else {
      showInSnackBar('error : Cannot delete this User.');
    }
  }

  void deleteDataGroup(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    bool result = await api.deleteUserGroup(groupNameControl.text);
    if (result) {
      setState(() {
        _isLoading = false;
        showInSnackBar('Deleted : Group removed.');
        clear();
      });
    } else {
      showInSnackBar('error : Cannot delete this Group.');
    }
  }

  void handleSubmitted(String action) async {
    if (userNameControl.text.trim().isNotEmpty &&
        passwordControl.text.trim().isNotEmpty &&
        confirmPasswordControl.text.trim().isNotEmpty &&
        valueGroupType.isNotEmpty) {
      if (passwordControl.text.trim().toLowerCase() ==
          confirmPasswordControl.text.trim().toLowerCase()) {
        setState(() {
          _isLoading = true;
        });

        var data = {
          'auto': id.isNotEmpty ? id.toString() : '0',
          'name': userNameControl.text.isNotEmpty
              ? userNameControl.text.trim().toUpperCase()
              : '',
          'password': passwordControl.text.isNotEmpty
              ? passwordControl.text.trim().toUpperCase()
              : '',
          'groupName': valueGroupType.toUpperCase(),
          'underGroup': valueGroupType.toUpperCase(),
          'location': locationId,
          'user': userIdC,
          'save': valueSave ? 1 : 0,
          'edit': valueEdit ? 1 : 0,
          'find': valueFind ? 1 : 0,
          'delete': valueDelete ? 1 : 0
        };

        bool result = action == 'edit'
            ? await api.editUser(data)
            : await api.addUser(data);

        if (result) {
          saveAndRedirectToHome(action);
        } else {
          showInSnackBar(action == 'edit'
              ? 'error : Cannot edit this User.'
              : 'error : Cannot save this User.');
        }
      } else {
        showInSnackBar('error : password mismatch');
      }
    } else {
      showInSnackBar(action == 'edit'
          ? 'error : Cannot edit select name.'
          : 'error : Cannot save select name.');
    }
  }

  void handleSubmittedGroup(String action) async {
    if (groupNameControl.text.trim().isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      var data = {
        'auto': idGroup.isNotEmpty ? idGroup.toString() : '0',
        'groupName': groupNameControl.text.isNotEmpty
            ? groupNameControl.text.trim().toUpperCase()
            : '',
        'location': locationId,
        'user': userIdC,
        'save': valueSave ? 1 : 0,
        'edit': valueEdit ? 1 : 0,
        'find': valueFind ? 1 : 0,
        'delete': valueDelete ? 1 : 0
      };

      bool result = action == 'edit'
          ? await api.editUserGroup(data)
          : await api.addUserGroup(data);

      if (result) {
        saveAndRedirectToHomeGroup(action);
      } else {
        showInSnackBar(action == 'edit'
            ? 'error : Cannot edit this Group.'
            : 'error : Cannot save this Group.');
      }
    } else {
      showInSnackBar(action == 'edit'
          ? 'error : Cannot edit select group.'
          : 'error : Cannot save select group.');
    }
  }

  void saveAndRedirectToHome(action) async {
    setState(() {
      _isLoading = false;
      showInSnackBar(
          action == 'edit' ? 'Edited : User edited.' : 'Saved : User created.');
    });
  }

  void saveAndRedirectToHomeGroup(action) async {
    setState(() {
      _isLoading = false;
      showInSnackBar(action == 'edit'
          ? 'Edited : Group edited.'
          : 'Saved : Group created.');
    });
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  findUser(String name) {
    setState(() {
      _isLoading = true;
    });
    api.findUser(name).then((valueData) {
      setState(() {
        userModel = valueData;
        isExist = true;
        userNameControl.text = valueData.userName;
        lName = userNameControl.text;
        passwordControl.text = valueData.password;
        valueGroupType =
            valueData.groupName.isEmpty ? valueGroupType : valueData.groupName;
        id = valueData.id.toString();
        _isLoading = false;
      });
    });
  }

  findUserGroup(String name) {
    setState(() {
      _isLoading = true;
    });
    api.findUserGroup(name).then((valueData) {
      groupModel = valueData;
      setState(() {
        gName = groupModel.name;
        idGroup = groupModel.id.toString();
        valueSave = groupModel.save == 1 ? true : false;
        valueEdit = groupModel.edit == 1 ? true : false;
        valueDelete = groupModel.delete == 1 ? true : false;
        valueFind = groupModel.find == 1 ? true : false;
        _isLoading = false;
        isExistGroup = true;
      });
    });
  }
}
