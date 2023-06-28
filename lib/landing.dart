// @dart = 2.9
import 'dart:async';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/main.dart';
import 'package:sheraccerp/models/api_error.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/company_user.dart';
import 'package:sheraccerp/provider/app_provider.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/company_alert.dart';
import 'package:sheraccerp/service/api.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';

class Landing extends StatefulWidget {
  const Landing({Key key}) : super(key: key);

  @override
  _LandingState createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  String _userId = "", _regId = "";
  bool isMultiFirm = false,
      secureAuth = false,
      nextWidget = false,
      _isInternet = false,
      _badRequest = false,
      _loadAgin = false;
  AppProvider appProvider;
  LocalAuthentication auth = LocalAuthentication();
  List<FirmModel> data;
  DioService api = DioService();

  @override
  void initState() {
    super.initState();
    secureAuth = ComSettings.appSettings('bool', 'key-switch-user-mode', false);
    appProvider = Provider.of<AppProvider>(context, listen: false);

    loadingFirmList();
    initPlatformState();
  }

  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Future<void> initPlatformState() async {
    try {
      if (kIsWeb) {
        WebBrowserInfo deviceData = await deviceInfoPlugin.webBrowserInfo;
        var _deviceId = deviceData.userAgent ?? '0';
        debugPrint('your Device ID : $_deviceId');
        deviceId = _deviceId;
      } else {
        if (Platform.isAndroid) {
          AndroidDeviceInfo deviceData = await deviceInfoPlugin.androidInfo;
          var _deviceId = deviceData.androidId ?? '0';
          debugPrint('your Device ID : $_deviceId');
          deviceId = _deviceId;
        } else if (Platform.isIOS) {
          IosDeviceInfo deviceData = await deviceInfoPlugin.iosInfo;
          var _deviceId = deviceData.utsname.machine ?? '0';
          debugPrint('your Device ID : $_deviceId');
          deviceId = _deviceId;
        } else if (Platform.isLinux) {
          LinuxDeviceInfo deviceData = (await deviceInfoPlugin.linuxInfo);
          var _deviceId = deviceData.machineId ?? '0';
          debugPrint('your Device ID : $_deviceId');
          deviceId = _deviceId;
        } else if (Platform.isMacOS) {
          MacOsDeviceInfo deviceData = (await deviceInfoPlugin.macOsInfo);
          var _deviceId = deviceData.computerName ?? '0';
          debugPrint('your Device ID : $_deviceId');
          deviceId = _deviceId;
        } else if (Platform.isWindows) {
          WindowsDeviceInfo deviceData = (await deviceInfoPlugin.windowsInfo);
          var _deviceId = deviceData.computerName ?? '0';
          debugPrint('your Device ID : $_deviceId');
          deviceId = _deviceId;
        }
      }
    } on PlatformException {
      debugPrint('Error: Failed to get platform version.');
    }
  }

  Future<bool> isInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('connected');
        _isInternet = true;
      }
    } on SocketException catch (_) {
      debugPrint('not connected');
      _isInternet = false;
    }
    return _isInternet;
  }

  void _handleLogout() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.remove('userId');
    Navigator.pushNamedAndRemoveUntil(
        context, '/login', ModalRoute.withName('/login'));
  }

  @override
  Widget build(BuildContext context) {
    return isMultiFirm ? widgetDisplay() : widgetAuthDisplay();
  }

  widgetDisplay() {
    return Scaffold(
      appBar: AppBar(
        title: Text(nextWidget ? 'Authenticate' : 'Firm List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _handleLogout();
            },
          ),
        ],
        elevation: .1,
      ),
      body: nextWidget ? authUser() : firmWidget(),
    );
  }

  widgetAuthDisplay() {
    return nextWidget
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Authenticate'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    _handleLogout();
                  },
                ),
              ],
              elevation: .1,
            ),
            body: authUser(),
          )
        : Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimaryColor, kPrimaryColor])),
            child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/logo.png',
                        height: 100,
                        width: 90,
                      ),
                      SizedBox(
                        width: 250.0,
                        child: TextLiquidFill(
                          text: 'SherAcc',
                          waveColor: Colors.white,
                          boxBackgroundColor: kPrimaryColor[600],
                          textStyle: const TextStyle(
                            fontSize: 40.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Raleway',
                          ),
                          boxHeight: 100.0,
                        ),
                      ),
                      Visibility(
                        visible: _badRequest,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            const Text(
                              'Network is to slow!',
                              style: TextStyle(color: white, fontSize: 20),
                            ),
                            InkWell(
                              child: Card(
                                elevation: 10,
                                color: blue,
                                child: Row(children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Try agin',
                                      style:
                                          TextStyle(color: white, fontSize: 20),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.network_check_sharp),
                                    color: red,
                                  )
                                ]),
                              ),
                              onTap: () {
                                setState(() {
                                  loadingFirmList();
                                  _loadAgin = true;
                                });
                              },
                            )
                          ],
                        ),
                      ),
                      Visibility(
                        visible: _loadAgin,
                        child: CircularProgressIndicator(
                          color: _loadAgin ? red : white,
                        ),
                      ),
                      widgetParent(),
                    ],
                  ),
                )),
          );
  }

  widgetParent() {
    return FutureBuilder(
      future: isInternet(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return Visibility(
              visible: !_isInternet,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text(
                      'No Internet try Agin !',
                      style: TextStyle(color: white, fontSize: 20),
                    ),
                    _animateRotate(),
                  ],
                ),
              ));
        }
        return const Center(
          child: Loading(),
        );
      },
    );
  }

  _animateRotate() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 300,
        child: Card(
          elevation: 40,
          color: red,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(width: 20.0, height: 100.0),
              const Text(
                'No',
                style: TextStyle(fontSize: 30.0, color: white),
              ),
              const SizedBox(width: 20.0, height: 100.0),
              DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 30.0,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    RotateAnimatedText('INTERNET'),
                    RotateAnimatedText('MOBILE DATA'),
                    RotateAnimatedText('WIFI'),
                  ],
                  onTap: () {
                    debugPrint("Tap Event");
                    setState(() {
                      loadingFirmList();
                      _loadAgin = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  firmWidget() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 5,
              child: SizedBox(
                height: 6,
                width: double.infinity,
                child: LinearProgressIndicator(
                    backgroundColor: firebaseGrey,
                    value: _progress,
                    valueColor: const AlwaysStoppedAnimation(indigoAccent)),
              ),
            ),
            ListView.builder(
              primary: false,
              shrinkWrap: true,
              itemCount: data.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  elevation: 8.0,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 6.0),
                  child: Container(
                    decoration: const BoxDecoration(color: kPrimaryDarkColor),
                    child: makeListTile(data[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  makeListTile(FirmModel data) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      leading: Container(
        padding: const EdgeInsets.only(right: 12.0),
        decoration: const BoxDecoration(
            border:
                Border(right: BorderSide(width: 1.0, color: Colors.white24))),
        child: const Icon(Icons.autorenew, color: Colors.white),
      ),
      title: Text(
        data.name,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(data.code,
                    style: const TextStyle(color: Colors.white))),
          )
        ],
      ),
      trailing: const Icon(Icons.keyboard_arrow_right,
          color: Colors.white, size: 30.0),
      onTap: () {
        _clickedDb(data);
      },
    );
  }

  void _clickedDb(FirmModel data) {
    setState(() {
      _progress = 0;
    });
    startTimer();
    loadingFirm(data);
  }

  loadingFirm(FirmModel firm) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString("CompanyName", firm.name);
    await pref.setString("DBName", firm.dbName ?? firm.code);
    await pref.setString("DBNameT", firm.dbNameT ?? firm.code);
    await pref.setString("Code", firm.code);

    if (secureAuth) {
      setState(() {
        nextWidget = true;
      });
    } else {
      _loadingCompanyInfo();
      _loadUserInfo();
    }
  }

  bool isBioAuthSwitched = false, isUserSwitched = false, isPassSwitched;
  String _companyName = '';
  loadingFirmList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    _regId = (pref.getString('regId') ?? "");
    if (_regId.trim().isNotEmpty) {
      isBioAuthSwitched = pref.getBool('bioModeLogin') ?? false;
      isUserSwitched = pref.getBool("userModeLogin") ?? false;
      isPassSwitched = pref.getBool('passCodeModeLogin') ?? false;
      if (pref.getString('CustomerCode').trim().isNotEmpty) {
        _companyName = pref.getString("CompanyName");
        //Check multi firm
        await getFirmList(pref.getString('CustomerCode')).then((value) {
          setState(() {
            ApiResponse apiResponse = value;
            if ((apiResponse.ApiError as ApiError) == null) {
              data = apiResponse.Data;
            } else {
              _showErrorDialog((apiResponse.ApiError as ApiError).error);
            }
          });
        }).catchError((error) {
          _showErrorDialog(error.error);
          setState(() {
            data = [];
          });
        });

        Future.delayed(const Duration(milliseconds: 3000), () {
          if (data.length > 1) {
            setState(() {
              isMultiFirm = true;
            });
          } else {
            setState(() {
              isMultiFirm = false;
            });
            if (secureAuth) {
              setState(() {
                nextWidget = true;
              });
            } else {
              _loadingCompanyInfo();
              _loadUserInfo();
            }
          }
        });
      } else {
        if (secureAuth) {
          setState(() {
            nextWidget = true;
          });
        } else {
          _loadingCompanyInfo();
          _loadUserInfo();
        }
      }
    } else {
      Future.delayed(const Duration(milliseconds: 3000), () {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login_company', ModalRoute.withName('/login_company'));
      });
    }
  }

  bool _passCodeValid = false,
      _userNameValid = false,
      _passwordValid = false,
      _isLoading = false,
      showPassword = true;
  String _passCode = '', _userName = '', _password = '';

  authUser() {
    if (isUserSwitched) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        height: MediaQuery.of(context).size.height - 50,
        width: double.infinity,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SizedBox(
                    height: 70.0,
                    child: Image.asset(
                      "assets/logo.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 15.0),
                  Center(
                    child: Text(_companyName,
                        style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo)),
                  ),
                  const SizedBox(height: 15.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Enter UserName',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextField(
                        obscureText: false,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 10),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[400])),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[400])),
                          errorText:
                              _userNameValid ? null : 'Please enter username',
                        ),
                        onChanged: (value) {
                          _userNameValid = value.isNotEmpty ? true : false;

                          setState(() {
                            _userName = value;
                          });
                        },
                        onSubmitted: (value) {
                          setState(() {
                            _userName = value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Enter Password',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextField(
                        obscureText: showPassword,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 10),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[400])),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[400])),
                          errorText:
                              _passwordValid ? null : 'Please enter password',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.visibility),
                            color: kPrimaryColor,
                            onPressed: () =>
                                setState(() => showPassword = !showPassword),
                          ),
                        ),
                        onChanged: (value) {
                          _passwordValid = value.isNotEmpty ? true : false;

                          setState(() {
                            _password = value;
                          });
                        },
                        onSubmitted: (value) {
                          setState(() {
                            _password = value;
                          });
                        },
                      ),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const InkWell(
                          child: Text(
                        'Forgot Password ?',
                        style: TextStyle(color: blueAccent),
                      )),
                      Card(
                        child: InkWell(
                          child: const Text(
                            '***',
                            style: TextStyle(color: grey),
                          ),
                          onDoubleTap: () {
                            appProvider.isEstimate =
                                appProvider.isEstimate ? false : true;
                            isEstimateDataBase =
                                isEstimateDataBase ? false : true;
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _isLoading ? const CircularProgressIndicator() : Container(),
                  isBioAuthSwitched
                      ? TextButton.icon(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(kPrimaryColor),
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                            });
                            auth
                                .authenticate(
                                    localizedReason:
                                        'Scan your fingerprint to authenticate',
                                    options: const AuthenticationOptions(
                                        useErrorDialogs: true,
                                        stickyAuth: true,
                                        biometricOnly: true))
                                .then((value) => loadHome(value));
                          },
                          icon: const Icon(
                            Icons.fingerprint,
                            size: 60,
                          ),
                          label: const Text(''))
                      : Container(),
                  Container(
                    padding: const EdgeInsets.only(top: 3, left: 3),
                    child: Consumer<AppProvider>(
                      builder: (BuildContext context, model, Widget child) {
                        return MaterialButton(
                          minWidth: double.infinity,
                          height: 50,
                          onPressed: () => _loginSubmitted(),
                          color:
                              model.isEstimate ? greenDark : kPrimaryDarkColor,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40)),
                          child: const Text("CONTINUE",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: white)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Powered By SherSoft',
                      style: TextStyle(color: grey, fontSize: 14),
                    ),
                  )
                ],
              ),
            ]),
      );
    } else if (isPassSwitched) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        height: MediaQuery.of(context).size.height - 50,
        width: double.infinity,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Enter 4 Digit Pass Code',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextField(
                        obscureText: showPassword,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 10),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[400])),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[400])),
                          errorText: _passCodeValid
                              ? null
                              : 'Please enter 4 digit passCode',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.visibility),
                            color: kPrimaryColor,
                            onPressed: () =>
                                setState(() => showPassword = !showPassword),
                          ),
                        ),
                        onChanged: (value) {
                          _passCodeValid = value.length == 4 ? true : false;

                          setState(() {
                            _passCode = value;
                          });
                        },
                        onSubmitted: (value) {
                          setState(() {
                            _passCode = value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                  const InkWell(
                      // onTap: () => ConfirmAlertBox(
                      //   buttonColorForNo: white,
                      //   buttonColorForYes: red,
                      //   buttonTextForNo: 'Close',
                      //   buttonTextForYes: 'Reset',
                      //   onPressedYes: _handleRemove,
                      //   onPressedNo: () {
                      //     Navigator.of(context).pop();
                      //   },
                      // ),
                      child: Text(
                    'Forgot Pass Code?',
                    style: TextStyle(color: blueAccent),
                  )),
                  const SizedBox(
                    height: 20,
                  ),
                  _isLoading ? const CircularProgressIndicator() : Container(),
                  isBioAuthSwitched
                      ? TextButton.icon(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(kPrimaryColor),
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                            });
                            auth
                                .authenticate(
                                    localizedReason:
                                        'Scan your fingerprint to authenticate',
                                    options: const AuthenticationOptions(
                                        useErrorDialogs: true,
                                        stickyAuth: true,
                                        biometricOnly: true))
                                .then((value) => loadHome(value));
                          },
                          icon: const Icon(
                            Icons.fingerprint,
                            size: 60,
                          ),
                          label: const Text(''))
                      : Container(),
                  Container(
                    padding: const EdgeInsets.only(top: 3, left: 3),
                    child: MaterialButton(
                      minWidth: double.infinity,
                      height: 50,
                      onPressed: () => _handleSubmitted(),
                      color: indigoAccent,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40)),
                      child: const Text(
                        "CONTINUE",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
      );
    } else {
      loadHome(true);
    }
  }

  _handleSubmitted() async {
    setState(() {
      _isLoading = true;
    });
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (_passCode.isNotEmpty) {
      if (_passCode == pref.getString('passCode')) {
        loadHome(true);
      } else {
        _showErrorDialog('PassCode Not Found');
      }
    }
  }

  _loginSubmitted() async {
    setState(() {
      _isLoading = true;
    });
    if (_userName.trim().isNotEmpty || _password.trim().isNotEmpty) {
      api
          .getUserLogin(
              _userName.trim().toUpperCase(), _password.trim().toUpperCase())
          .then((value) {
        if (value) {
          loadHome(true);
        } else {
          setState(() {
            _isLoading = false;
          });
          _showErrorDialog('Incorrect username or password');
        }
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Enter username and password');
    }
  }

  loadHome(bool status) {
    if (status) {
      appProvider.isEstimate;
      _loadingCompanyInfo();
      _loadUserInfo();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        height: MediaQuery.of(context).size.height - 50,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
          ],
        ),
      );
    } else {
      // _showErrorDialog('Not Found');
      setState(() {
        _isLoading = false;
      });
    }
  }

  _loadingCompanyInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    _regId = (pref.getString('regId') ?? "");
    if (_regId.isNotEmpty) {
      var dataBase = isEstimateDataBase
          ? pref.getString('DBName')
          : pref.getString('DBNameT');
      ScopedModel.of<MainModel>(context).getCompanySettingsAll(dataBase);
      ScopedModel.of<MainModel>(context)
          .getReportDesignByName(dataBase, 'Ledger_Report_Qty');
    }
  }

  _loadUserInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    _regId = (pref.getString('regId') ?? "");
    if (_regId == "") {
      Future.delayed(const Duration(milliseconds: 3000), () {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login_company', ModalRoute.withName('/login_company'));
      });
    } else {
      _userId = (pref.getString('userId') ?? "");
      if (_userId == "") {
        Future.delayed(const Duration(milliseconds: 3000), () {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', ModalRoute.withName('/login'));
        });
      } else {
        // ApiResponse _apiResponse = await getUserDetails(_userId);
        await getUserDetails(_userId).then((value) {
          ApiResponse _apiResponse = value;
          if ((_apiResponse.ApiError as ApiError) == null) {
            // Future.delayed(const Duration(milliseconds: 3000), () {
            CompanyUser _user = _apiResponse.Data;
            companyUserData = _user;
            // if (companyUserData.active.isNotEmpty &&
            //     companyUserData.active.toUpperCase() == 'TRUE') {
            //   userRole = _user.userType.toUpperCase();

            if (_userId != null) {
              getCompanyUserControlList(_userId).then((value) {
                userControlData.addAll(value);
                if (_user.userType.toUpperCase() == 'ADMIN') {
                  Navigator.pushNamedAndRemoveUntil(context, '/admin_home',
                      ModalRoute.withName('/admin_home'),
                      arguments: (_user));
                } else if (_user.userType.toUpperCase() == 'OWNER') {
                  Navigator.pushNamedAndRemoveUntil(context, '/owner_home',
                      ModalRoute.withName('/owner_home'),
                      arguments: (_user));
                } else if (_user.userType.toUpperCase() == 'STAFF') {
                  Navigator.pushNamedAndRemoveUntil(context, '/staff_home',
                      ModalRoute.withName('/staff_home'),
                      arguments: (_user));
                } else if (_user.userType.toUpperCase() == 'SALESMAN') {
                  Navigator.pushNamedAndRemoveUntil(context, '/salesMan_home',
                      ModalRoute.withName('/salesMan_home'),
                      arguments: (_user));
                } else if (_user.userType.toUpperCase() == 'DELIVERY') {
                  Navigator.pushNamedAndRemoveUntil(context, '/delivery_home',
                      ModalRoute.withName('/delivery_home'),
                      arguments: (_user));
                } else if (_user.userType.toUpperCase() == 'MANAGER') {
                  Navigator.pushNamedAndRemoveUntil(context, '/manager_home',
                      ModalRoute.withName('/manager_home'),
                      arguments: (_user));
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', ModalRoute.withName('/home'));
                }
              });
            } else {
              if (_user.userType.toUpperCase() == 'ADMIN') {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/admin_home', ModalRoute.withName('/admin_home'),
                    arguments: (_user));
              } else if (_user.userType.toUpperCase() == 'OWNER') {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/owner_home', ModalRoute.withName('/owner_home'),
                    arguments: (_user));
              } else if (_user.userType.toUpperCase() == 'STAFF') {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/staff_home', ModalRoute.withName('/staff_home'),
                    arguments: (_user));
              } else if (_user.userType.toUpperCase() == 'SALESMAN') {
                Navigator.pushNamedAndRemoveUntil(context, '/salesMan_home',
                    ModalRoute.withName('/salesMan_home'),
                    arguments: (_user));
              } else if (_user.userType.toUpperCase() == 'DELIVERY') {
                Navigator.pushNamedAndRemoveUntil(context, '/delivery_home',
                    ModalRoute.withName('/delivery_home'),
                    arguments: (_user));
              } else if (_user.userType.toUpperCase() == 'MANAGER') {
                Navigator.pushNamedAndRemoveUntil(context, '/manager_home',
                    ModalRoute.withName('/manager_home'),
                    arguments: (_user));
              } else {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', ModalRoute.withName('/home'));
              }
            }
            // } else {
            //   debugPrint('Sorry! No longer Available');
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => CompanyAlert()),
            //   );
            // }
            // });
          } else {
            ApiError error = _apiResponse.ApiError;
            _showErrorDialog(error.error);
            setState(() {
              debugPrint(error.error.toString());
              _badRequest = true;
            });
          }
        }).catchError((onError) {
          if (onError.error !=
              'Connection to API server failed due to internet connection') {
            setState(() {
              debugPrint(onError.error.toString());
              _badRequest = true;
            });
          }
        }); //.timeout(const Duration(seconds: 5));
      }
    }
  }

  _loadControlData(id) async {
    getCompanyUserControlList(id).then((value) {
      userControlData.addAll(value);
    });
  }

  void _showErrorDialog(String message) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Row(
            children: [
              Image.asset('assets/icons/ic_warning_black_24dp.png',
                  height: 30, width: 30),
              const Text("SherAcc Alert"),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  double _progress = 0;

  void startTimer() {
    Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) async {
        if (mounted) {
          setState(
            () {
              if (_progress == 1) {
                timer.cancel();
              } else {
                _progress += 0.2;
              }
            },
          );
        }
      },
    );
  }
}
