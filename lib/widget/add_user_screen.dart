// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/api_error.dart';
import 'package:sheraccerp/service/api.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class Register extends StatefulWidget {
  const Register({Key key}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _username = "", _password = "";
  ApiResponse _apiResponse;
  String _regId = "";
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Register'),
        ),
        body: ProgressHUD(
          inAsyncCall: _isLoading,
          opacity: 0.0,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: Form(
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TextFormField(
                              key: const Key("_username"),
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: "Username"),
                              keyboardType: TextInputType.text,
                              onSaved: (String value) {
                                _username = value.trim();
                              },
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'Username is required';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: "Password"),
                              obscureText: true,
                              onSaved: (String value) {
                                _password = value.trim();
                              },
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10.0),
                            ButtonBar(
                              children: <Widget>[
                                TextButton(
                                  child:
                                      const Text("Already have an account ?"),
                                  onPressed: () {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/login',
                                      ModalRoute.withName('/login'),
                                    );
                                  },
                                ),
                                TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: white,
                                      backgroundColor: kPrimaryDarkColor,
                                      disabledForegroundColor:
                                          grey.withOpacity(0.38),
                                    ),
                                    onPressed: _handleSubmitted,
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.red,
                                    ),
                                    label: const Text('Create')),
                              ],
                            ),
                          ],
                        ),
                      ]),
                ),
              ),
            ),
          ),
        ));
  }

  void _handleSubmitted() async {
    setState(() {
      _isLoading = true;
    });
    final FormState form = _formKey.currentState;
    if (!form.validate()) {
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _regId = (prefs.getString('regId') ?? "");
      if (_regId == "") {
        showInSnackBar('Sorry! your company not found');
      } else {
        form.save();
        _apiResponse = await createUser(_username, _password, _regId);
        if ((_apiResponse.ApiError as ApiError) == null) {
          _saveAndRedirectToHome();
        } else {
          showInSnackBar((_apiResponse.ApiError as ApiError).error);
        }
      }
    }
  }

  void _saveAndRedirectToHome() async {
    setState(() {
      _isLoading = false;
    });
    Navigator.pushNamedAndRemoveUntil(
        context, '/login', ModalRoute.withName('/login'));
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
