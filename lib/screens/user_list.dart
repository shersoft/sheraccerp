// @dart = 2.11

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/company_user.dart';
import 'package:sheraccerp/models/form_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/widget/user_control_list.dart';
import 'package:sheraccerp/service/api.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key key}) : super(key: key);

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  var regId = "";
  bool nextWidget = false;
  CompanyUser userData;
  List<FormModel> form = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _load();
    super.initState();
    form = [];
  }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      regId = (prefs.getString('regId') ?? "0");
      // firm = (prefs.getString('CompanyName') ?? "");
      // firmCode = (prefs.getString('CustomerCode') ?? "");
    });
    // getCompanyUserControlList(userData.userId).then((value) => {form = value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
        actions: [
          Visibility(
            visible: nextWidget,
            child: IconButton(
                onPressed: () {
                  List<FormModel> forms = [];
                  forms = form
                      .where((element) => element.isChecked == true)
                      .toList();
                  var part = json.encode(forms);
                  var data = {'id': userData.userId, 'data': part};
                  addUserControl(data).then((value) => {
                        value
                            ? ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Saved')),
                              )
                            : ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Data Error')),
                              )
                      });
                },
                icon: const Icon(Icons.save)),
          )
        ],
      ),
      body: Container(
        child: nextWidget ? userDetails(userData) : fetchUser(regId),
      ),
    );
  }

  Widget fetchUser(String id) {
    return FutureBuilder<List<CompanyUser>>(
      future: getCompanyUserList(id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data;
          return ListView.builder(
              itemCount: data.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text('User: ' + data[index].username),
                    subtitle: Text('Logged In: ' +
                        DateUtil.dateTimeDMY(data[index].loginDate)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(data[index].userType),
                        Icon(Icons.circle,
                            size: 10,
                            color: data[index].active == "false" ? red : green),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        userData = data[index];
                        nextWidget = true;
                      });
                      // showEditDialog(context, data[index]);
                    },
                  ),
                );
              });
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return const Loading();
      },
    );
  }

  showEditDialog(BuildContext context, CompanyUser user) async {
    TextEditingController _textFieldController = TextEditingController();
    TextEditingController _textFieldController1 = TextEditingController();
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: SizedBox(
              height: 100,
              child: Column(
                children: [
                  TextField(
                    controller: _textFieldController,
                    textInputAction: TextInputAction.go,
                    decoration:
                        const InputDecoration(hintText: "Enter new password"),
                  ),
                  TextField(
                    controller: _textFieldController1,
                    textInputAction: TextInputAction.go,
                    decoration:
                        const InputDecoration(hintText: "Confirm password"),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Submit'),
                onPressed: () {
                  if (_textFieldController.text == _textFieldController1.text &&
                      _textFieldController.text.isNotEmpty &&
                      _textFieldController1.text.isNotEmpty) {
                    var body = [
                      {
                        'id': user.registrationId.toString(),
                        'userId': user.userId.toString(),
                        'password': _textFieldController.text,
                      }
                    ];
                    changeCompanyUserPassword(body).then((value) {
                      String msg = "Error password update";
                      if (value) {
                        msg = "Password updated";
                        Navigator.of(context).pop();
                      }
                      Fluttertoast.showToast(msg: msg);
                    });
                  } else {
                    String msg = "Enter password";
                    if (_textFieldController.text
                            .compareTo(_textFieldController1.text) !=
                        0) {
                      msg = "Password not match";
                    }
                    Fluttertoast.showToast(msg: msg);
                  }
                },
              )
            ],
          );
        });
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<String> roles = [
    'Staff',
    'SalesMan',
    'Delivery',
    'Collection',
    'Admin',
    'Manager',
    'Owner'
  ];
  String role = '';
  bool showPassword = true;

  userDetails(CompanyUser user) {
    _nameController.text = user.username.toString();
    _passwordController.text = user.password.toString();
    if (role == '') {
      role = user.userType;
    }
    return Form(
      autovalidateMode: AutovalidateMode.always,
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.face,
                    color: Colors.blue,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    user.userId,
                    style: const TextStyle(color: Colors.blue, fontSize: 18),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: Colors.blue,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    user.atDate,
                    style: const TextStyle(color: Colors.blue, fontSize: 18),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text('UserName : ${user.username.toString()}'),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Icon(
              //       Icons.circle,
              //       color: user.active == "false" ? Colors.red : Colors.green,
              //     ),
              //   ],
              // ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.rule,
                    color: Colors.blue,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text('User Role : '),
                  DropdownButton<String>(
                      items: roles.map((String items) {
                        return DropdownMenuItem(
                          value: items,
                          child: Text(items),
                        );
                      }).toList(),
                      value: role != '' ? role : roles[0],
                      onChanged: (value) {
                        setState(() {
                          role = value;
                        });
                      })
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit_note,
                    color: Colors.blue,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text('Save : '),
                  Checkbox(value: user.insertData, onChanged: (value) {}),
                  const Text('Edit : '),
                  Checkbox(value: user.insertData, onChanged: (value) {}),
                  const Text('Delete : '),
                  Checkbox(value: user.insertData, onChanged: (value) {}),
                ],
              ),
            ),
            // TextFormField(
            //   key: const Key("_username"),
            //   keyboardType: TextInputType.text,
            //   controller: _nameController,
            //   validator: (value) {
            //     if (value.isEmpty) {
            //       return 'Username is required';
            //     }
            //     return null;
            //   },
            // ),
            Row(children: [
              ElevatedButton(
                  onPressed: () => showEditDialog(context, user),
                  child: const Text('Change Password')),
              // TextFormField(
              //   decoration: InputDecoration(
              //     hintText: "Password",
              //     suffixIcon: IconButton(
              //       icon: const Icon(Icons.visibility),
              //       color: kPrimaryColor,
              //       onPressed: () => setState(() => showPassword = !showPassword),
              //     ),
              //   ),
              //   controller: _passwordController,
              //   obscureText: showPassword,
              //   validator: (value) {
              //     if (value.isEmpty) {
              //       return 'Password is required';
              //     }
              //     return null;
              //   },
              // ),
              const SizedBox(
                width: 10,
              ),
              const Padding(
                padding: EdgeInsets.all(2.0),
                child: Text(
                  'User Control',
                ),
              ),
            ]),
            form.isEmpty
                ? userControlWidget(userData.userId)
                : userControlWidgetLoad(),
          ],
        ),
      ),
    );
  }

  userControlWidgetLoad() {
    return Column(
        children: form
            .map(
              (FormModel item) => CheckboxListTile(
                title: Text(item.title),
                value: item.isChecked,
                onChanged: (bool val) {
                  setState(() => item.isChecked = val);
                },
              ),
            )
            .toList());
  }

  bool newControl = false;
  userControlWidget(id) {
    return FutureBuilder<List<FormModel>>(
      future: newControl
          ? getCompanyUserControlForms()
          : getCompanyUserControlList(id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            form = snapshot.data;
            return Column(
                children: form
                    .map(
                      (FormModel item) => CheckboxListTile(
                        title: Text(item.title),
                        value: item.isChecked,
                        onChanged: (bool val) {
                          setState(() => item.isChecked = val);
                        },
                      ),
                    )
                    .toList());
          } else {
            return TextButton.icon(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(kPrimaryColor),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              ),
              onPressed: () {
                setState(() {
                  newControl = true;
                });
              },
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Add'),
            );
          }
        } else {
          return const Loading();
        }
      },
    );
  }
}
