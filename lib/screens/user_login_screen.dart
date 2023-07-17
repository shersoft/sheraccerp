// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/api_error.dart';
import 'package:sheraccerp/models/company_user.dart';
import 'package:sheraccerp/service/api.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({Key key}) : super(key: key);

  @override
  _UserLoginScreenState createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _username = "", _password = "";
  String _regId = "", firm = "", firmCode = "";
  bool _isLoading = false, showPassword = true;
  ApiResponse _apiResponse;

  @override
  void initState() {
    _load();
    super.initState();
  }

  _load() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      _regId = (pref.getString('regId') ?? "");
      firm = (pref.getString('CompanyName') ?? "");
      firmCode = (pref.getString('CustomerCode') ?? "");
    });
  }

  void _handleLogout() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Company'),
        content: const Text('Do you want to logout'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              pref.remove('fId');
              pref.remove('api');
              pref.remove('regId');
              pref.remove('CompanyName');
              pref.remove('DBName');
              pref.remove('DBNameT');
              pref.remove('Active');
              pref.remove('UserName');
              pref.remove('Password');
              pref.remove('CustomerCode');
              Settings.clearCache();
              Navigator.pushNamedAndRemoveUntil(context, '/login_company',
                  ModalRoute.withName('/login_company'));
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Login'),
          // brightness: Brightness.dark,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _handleLogout();
              },
            )
          ],
        ),
        body: ProgressHUD(
          inAsyncCall: _isLoading,
          color: red,
          opacity: 0.0,
          child: SizedBox(
            width: double.infinity,
            height: size.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Text('Welcome to ' + firm),
                      const Icon(
                        Icons.person_pin_rounded,
                        size: 70,
                        color: kPrimaryColor,
                      ),
                      SizedBox(height: size.height * 0.03),
                      Center(
                        child: Form(
                          autovalidateMode: AutovalidateMode.always,
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 5),
                                        width: size.width * 0.8,
                                        decoration: BoxDecoration(
                                          color: kPrimaryLightColor,
                                          borderRadius:
                                              BorderRadius.circular(29),
                                        ),
                                        child: TextFormField(
                                          key: const Key("_username"),
                                          decoration: const InputDecoration(
                                            icon: Icon(
                                              Icons.person,
                                              color: kPrimaryColor,
                                            ),
                                            label: Text("User Name"),
                                            border: InputBorder.none,
                                          ),
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
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 5),
                                        width: size.width * 0.8,
                                        decoration: BoxDecoration(
                                          color: kPrimaryLightColor,
                                          borderRadius:
                                              BorderRadius.circular(29),
                                        ),
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            label: const Text("Password"),
                                            icon: const Icon(
                                              Icons.lock,
                                              color: kPrimaryColor,
                                            ),
                                            suffixIcon: IconButton(
                                              icon:
                                                  const Icon(Icons.visibility),
                                              color: kPrimaryColor,
                                              onPressed: () => setState(() =>
                                                  showPassword = !showPassword),
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          obscureText: showPassword,
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
                                      ),
                                      const SizedBox(height: 10.0),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        width: size.width * 0.8,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(29),
                                          child: TextButton(
                                            onPressed: _handleSubmitted,
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 20,
                                                      horizontal: 40),
                                              backgroundColor: kPrimaryColor,
                                            ),
                                            child: const Text(
                                              "LOGIN",
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        width: size.width * 0.8,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(29),
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                                foregroundColor: kPrimaryColor),
                                            child: const Text(
                                                "Create an account ?"),
                                            onPressed: () {
                                              Navigator.pushNamedAndRemoveUntil(
                                                context,
                                                '/register',
                                                ModalRoute.withName(
                                                    '/register'),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      if (_regId == "") {
        showInSnackBar('Sorry! your company not found');
      } else {
        form.save();
        _apiResponse = await authenticateUser(_username, _password, _regId);
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
    String _userId = (_apiResponse.Data as CompanyUser).userId;
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString("userId", _userId);

    if (_userId != "") {
      Navigator.pushNamedAndRemoveUntil(context, '/', ModalRoute.withName('/'));
      // ApiResponse _apiResponse = await getUserDetails(_userId);
      // if ((_apiResponse.ApiError as ApiError) == null) {
      //   Future.delayed(Duration(milliseconds: 3000), () {
      //     CompanyUser _user = _apiResponse.Data;
      //     if (_user.userType.toUpperCase() == 'ADMIN') {
      //       Navigator.pushNamedAndRemoveUntil(
      //           context, '/admin_home', ModalRoute.withName('/admin_home'),
      //           arguments: (_apiResponse.Data as CompanyUser));
      //     } else if (_user.userType.toUpperCase() == 'OWNER') {
      //   Navigator.pushNamedAndRemoveUntil(
      //       context, '/owner_home', ModalRoute.withName('/owner_home'),
      //       arguments: (_user));
      // } else if (_user.userType.toUpperCase() == 'STAFF') {
      //       Navigator.pushNamedAndRemoveUntil(
      //           context, '/staff_home', ModalRoute.withName('/staff_home'),
      //           arguments: (_apiResponse.Data as CompanyUser));
      //     } else if (_user.userType.toUpperCase() == 'SALESMAN') {
      //       Navigator.pushNamedAndRemoveUntil(context, '/salesMan_home',
      //           ModalRoute.withName('/salesMan_home'),
      //           arguments: (_apiResponse.Data as CompanyUser));
      //     } else {
      //       Navigator.pushNamedAndRemoveUntil(
      //           context, '/home', ModalRoute.withName('/home'));
      //     }
      //   });
      // }
    } else {
      showInSnackBar('your not a authorized user');
    }
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
