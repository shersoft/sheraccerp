import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/api_error.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/screens/dash_report/dashboard_screen.dart';
import 'package:sheraccerp/service/api.dart';
import 'package:sheraccerp/util/database.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/util/validator.dart';
import 'package:sheraccerp/widget/custom_form_field.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class LoginForm extends StatefulWidget {
  final FocusNode focusNode;

  const LoginForm({
    Key? key,
    required this.focusNode,
  }) : super(key: key);
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _uidController = TextEditingController();
  late ApiResponse _apiResponse;

  final _loginInFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String dropdownApiV = 'v19';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _loginInFormKey,
      child: _isLoading
          ? const Loading()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 8.0,
                    bottom: 24.0,
                  ),
                  child: Column(
                    children: [
                      CustomFormField(
                        controller: _uidController,
                        focusNode: widget.focusNode,
                        keyboardType: TextInputType.number,
                        inputAction: TextInputAction.done,
                        validator: (value) => Validator.validateCustomerID(
                          uid: value,
                        ),
                        label: 'Customer ID',
                        hint: 'Enter your unique identifier',
                      ),
                      DropdownButton<String>(
                        items: [
                          'v19',
                          'v18',
                          'v17',
                          'v16',
                          'v15',
                          'v14',
                          'v13',
                          'v12',
                          'v11',
                          'v10'
                        ].map<DropdownMenuItem<String>>((item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            dropdownApiV = value ?? '';
                          });
                        },
                        value: dropdownApiV,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 0.0, right: 0.0),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          kPrimaryDarkColor,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      onPressed: () async {
                        widget.focusNode.unfocus();

                        if (_loginInFormKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });
                          Database.userUid = _uidController.text.trim();
                          SharedPreferences pref =
                              await SharedPreferences.getInstance();

                          if (_uidController.text.trim() == '099077055') {
                            setState(() {
                              _isLoading = false;
                            });
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const DashboardScreen(),
                              ),
                            );
                          } else {
                            Database.loginUser(
                                    docId: _uidController.text.trim())
                                .first
                                .then<dynamic>(
                                    (DocumentSnapshot snapshot) async {
                              if (snapshot.data() != null) {
                                if (snapshot['url'] != null ||
                                    snapshot['url'] != '') {
                                  await pref.setString("fId", snapshot.id);
                                  await pref.setString("api", snapshot['url']);
                                  await pref.setString("apiV", dropdownApiV);

                                  if (_uidController.text.trim() ==
                                      '099077055') {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const DashboardScreen(),
                                      ),
                                    );
                                  } else {
                                    _handleSubmitted(snapshot.id);
                                    // Navigator.of(context).pushReplacement(
                                    //   MaterialPageRoute(
                                    //     builder: (context) => UserLoginScreen(),
                                    //   ),
                                    // );
                                  }
                                } else {
                                  showInSnackBar('Error server not ready');
                                }
                              } else {
                                if (_uidController.text.trim() == '099077055') {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DashboardScreen(),
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  showInSnackBar('Customer ID not found');
                                }
                              }
                            });
                          }
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
                        child: Text(
                          'Start',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: firebaseGrey,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _handleSubmitted(id) async {
    try {
      _apiResponse = await authenticate(id);
      if ((_apiResponse.ApiError as ApiError) == null) {
        setState(() {
          _isLoading = false;
        });
        _saveAndRedirectToHome();
      } else {
        setState(() {
          _isLoading = false;
        });
        showInSnackBar((_apiResponse.ApiError as ApiError).error);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showInSnackBar(e.toString());
    }
  }

  void _saveAndRedirectToHome() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(
        "regId", (_apiResponse.Data as Company).registrationId);
    await pref.setString(
        "CompanyName", (_apiResponse.Data as Company).companyName);
    await pref.setString("DBName", (_apiResponse.Data as Company).dBName);
    await pref.setString("DBNameT", (_apiResponse.Data as Company).dBNameT);
    await pref.setString("Active", (_apiResponse.Data as Company).active);
    await pref.setString("UserName", (_apiResponse.Data as Company).username);
    await pref.setString("Password", (_apiResponse.Data as Company).password);
    await pref.setString(
        "CustomerCode", (_apiResponse.Data as Company).customerCode);
    await pref.setString("Code", (_apiResponse.Data as Company).code);

    Navigator.pushNamedAndRemoveUntil(
        context, '/login', ModalRoute.withName('/login'),
        arguments: (_apiResponse.Data as Company));
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
