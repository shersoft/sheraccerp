// @dart = 2.11

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/util/res_color.dart';

class PassCodeAuth extends StatefulWidget {
  const PassCodeAuth({Key key}) : super(key: key);

  @override
  _PassCodeAuthState createState() => _PassCodeAuthState();
}

class _PassCodeAuthState extends State<PassCodeAuth> {
  var _passCode = '', _rePassCode = '';
  bool _bioModeLogin = false,
      _userModeLogin = false,
      _passCodeModeLogin = false;
  bool isBioAuthSwitched = false, isUserSwitched = false;
  bool _passCodeValid = true, _rePassCodeValid = true;
  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  bool _canCheckBiometrics = false, _isLoading = false;
  bool isSavedSuccess = false, showPassword = false;

  @override
  void initState() {
    super.initState();
    auth.isDeviceSupported().then(
          (isSupported) => setState(() => _supportState = isSupported
              ? _SupportState.supported
              : _SupportState.unsupported),
        );
    loadDefault();
  }

  loadDefault() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    _bioModeLogin = pref.getBool('bioModeLogin') ?? false;
    _userModeLogin = pref.getBool("userModeLogin") ?? false;
    _passCodeModeLogin = pref.getBool('passCodeModeLogin') ?? false;
    if (_bioModeLogin) {
      setState(() {
        isBioAuthSwitched = true;
      });
    }
    if (_userModeLogin) {
      setState(() {
        isUserSwitched = true;
      });
    }
    if (_bioModeLogin || _userModeLogin || _passCodeModeLogin) {
      setState(() {
        isSavedSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [],
        title: const Text('Set Secure Lock'),
      ),
      body: Container(
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
                  Visibility(
                    visible: !isUserSwitched,
                    child: Column(
                      children: [
                        makeInput(
                            label: isSavedSuccess
                                ? "Enter New 4 Digit Pass Code"
                                : "Enter 4 Digit Pass Code",
                            // obscureText: showPassword,
                            idS: 1),
                        makeInput(
                            label: "Re-Enter Pass Code",
                            // obscureText: showPassword,
                            idS: 2),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Text('Use Biometric Authentication'),
                      Switch(
                        value: isBioAuthSwitched,
                        onChanged: (value) {
                          _checkBio(value);
                          setState(() {
                            isBioAuthSwitched = value;
                          });
                        },
                      ),
                    ],
                  ),
                  Visibility(
                    visible: isBioAuthSwitched,
                    child: Column(
                      children: [
                        if (_supportState == _SupportState.unknown)
                          const Text("This device is not detected Bio")
                        else if (_supportState == _SupportState.supported)
                          const Text("This device is supported Bio")
                        else
                          const Text("This device is not supported Bio"),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Text('Use Company Login'),
                      Switch(
                        value: isUserSwitched,
                        onChanged: (value) {
                          setState(() {
                            isUserSwitched = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 3, left: 3),
                    child: isSavedSuccess
                        ? Column(
                            children: [
                              MaterialButton(
                                minWidth: double.infinity,
                                height: 50,
                                onPressed: () => _handleSubmitted(),
                                color: blueAccent,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40)),
                                child: const Text(
                                  "UPDATE",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18),
                                ),
                              ),
                              const Divider(),
                              MaterialButton(
                                minWidth: double.infinity,
                                height: 50,
                                onPressed: () => _handleRemove(),
                                color: redAccent,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40)),
                                child: const Text(
                                  "REMOVE",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18),
                                ),
                              ),
                            ],
                          )
                        : MaterialButton(
                            minWidth: double.infinity,
                            height: 50,
                            onPressed: () => _handleSubmitted(),
                            color: indigoAccent,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40)),
                            child: const Text(
                              "SAVE",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 18),
                            ),
                          ),
                  ),
                  _isLoading ? const CircularProgressIndicator() : Container()
                ],
              ),
            ]),
      ),
    );
  }

  // authenticateWidget() {
  //   if (isBioAuthSwitched) {
  //     _checkBio(isBioAuthSwitched);
  //   }
  //   return Scaffold(
  //     appBar: AppBar(
  //       actions: [],
  //       title: Text('Set Secure Lock'),
  //     ),
  //     body: Container(
  //       padding: EdgeInsets.symmetric(horizontal: 40),
  //       height: MediaQuery.of(context).size.height - 50,
  //       width: double.infinity,
  //       child: Column(children: <Widget>[
  //         Column(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           children: <Widget>[
  //             Visibility(
  //               visible: !isUserSwitched,
  //               child: Column(
  //                 children: [
  //                   makeInput(
  //                       label: "Enter 4 Digit Pass Code",
  //                       obscureText: true,
  //                       idS: 1),
  //                 ],
  //               ),
  //             ),
  //             InkWell(
  //                 onTap: () => ConfirmAlertBox(
  //                       buttonColorForNo: white,
  //                       buttonColorForYes: red,
  //                       buttonTextForNo: 'Close',
  //                       buttonTextForYes: 'Reset',
  //                       onPressedYes: _handleRemove,
  //                       onPressedNo: () {
  //                         Navigator.of(context).pop();
  //                       },
  //                     ),
  //                 child: Text('Forgot got Pass Code?')),
  //             SizedBox(
  //               height: 20,
  //             ),
  //             Container(
  //               padding: EdgeInsets.only(top: 3, left: 3),
  //               child: MaterialButton(
  //                 minWidth: double.infinity,
  //                 height: 50,
  //                 onPressed: () => _handleSubmitted(),
  //                 color: indigoAccent,
  //                 elevation: 5,
  //                 shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(40)),
  //                 child: Text(
  //                   "CONTINUE",
  //                   style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
  //                 ),
  //               ),
  //             ),
  //             _isLoading ? CircularProgressIndicator() : Container()
  //           ],
  //         ),
  //       ]),
  //     ),
  //   );
  // }

  Widget makeInput({label, idS}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w400, color: Colors.black87),
        ),
        const SizedBox(
          height: 5,
        ),
        TextField(
          obscureText: showPassword,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter(RegExp(r'[0-9]'), allow: true)
          ],
          maxLength: 4,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[400])),
            border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[400])),
            errorText: idS == 1
                ? _passCodeValid
                    ? null
                    : 'Please enter 4 digit passCode'
                : _rePassCodeValid
                    ? null
                    : 'Please re-enter 4 Digit passCode',
            suffixIcon: IconButton(
              icon: const Icon(Icons.visibility),
              color: kPrimaryColor,
              onPressed: () => setState(() => showPassword = !showPassword),
            ),
          ),
          onChanged: (value) {
            if (idS == 1) {
              _passCodeValid = value.length == 4 ? true : false;
            } else {
              _rePassCodeValid = value.length == 4 ? true : false;
            }
            setState(() {
              if (idS == 1) {
                _passCode = value;
              } else {
                _rePassCode = value;
              }
            });
          },
          onSubmitted: (value) {
            setState(() {
              if (idS == 1) {
                _passCode = value;
              } else {
                _rePassCode = value;
              }
            });
          },
        ),
        const SizedBox(
          height: 30,
        ),
      ],
    );
  }

  void _handleSubmitted() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      _isLoading = true;
    });

    if (isBioAuthSwitched) {
      await pref.setBool("bioModeLogin", true);
    } else {
      await pref.setBool("bioModeLogin", false);
    }
    if (isUserSwitched) {
      await pref.setBool("userModeLogin", true);
      await pref.setBool("passCodeModeLogin", false);
      Navigator.pushNamedAndRemoveUntil(context, '/', ModalRoute.withName('/'));
    } else {
      if (_passCode.isNotEmpty &&
          _rePassCode.isNotEmpty &&
          _passCode == _rePassCode) {
        if (_passCode.length == 4) {
          await pref.setBool("userModeLogin", false);
          await pref.setBool("passCodeModeLogin", true);
          await pref.setString("passCode", _passCode);
          setState(() {
            _isLoading = false;
            isSavedSuccess = true;
          });
          Navigator.pushNamedAndRemoveUntil(
              context, '/', ModalRoute.withName('/'));
        } else {
          showInSnackBar('Please enter 4 Digit PassCode before setting.');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (_passCode != _rePassCode) {
          showInSnackBar('Please enter PassCode not matching.');
        } else if (_passCode.isEmpty) {
          showInSnackBar('Please enter PassCode before setting.');
        } else if (_rePassCode.isEmpty) {
          showInSnackBar('Please Re-Enter PassCode before setting.');
        } else {
          showInSnackBar('Please enter PassCode before setting.');
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleRemove() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (pref.getBool('bioModeLogin')) _cancelAuthentication();
    await pref.setBool("userModeLogin", false);
    await pref.setBool("passCodeModeLogin", false);
    await pref.setString("passCode", '');
    await pref.setBool("bioModeLogin", false);
    setState(() {
      isSavedSuccess = false;
    });
    Navigator.pushNamedAndRemoveUntil(context, '/', ModalRoute.withName('/'));
  }

  void _checkBio(status) {
    status
        ? _checkBiometrics().then((value) => {
              if (_canCheckBiometrics) {_authenticateWithBiometrics()}
            })
        : _cancelAuthentication();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException {
      canCheckBiometrics = false;
      // print(e);
    }
    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  // Future<void> _getAvailableBiometrics() async {
  //   List<BiometricType> availableBiometrics = [];
  //   try {
  //     availableBiometrics = await auth.getAvailableBiometrics();
  //   } on PlatformException {
  //     availableBiometrics = <BiometricType>[];
  //     // print(e);
  //   }
  //   if (!mounted) return;

  //   setState(() {});
  // }

  // Future<void> _authenticate() async {
  //   bool authenticated = false;
  //   try {
  //     setState(() {});
  //     authenticated = await auth.authenticate(
  //         localizedReason: 'Let OS determine authentication method',
  //         useErrorDialogs: true,
  //         stickyAuth: true);
  //     setState(() {
  //       isBioAuthSwitched = false;
  //     });
  //   } on PlatformException catch (e) {
  //     print(e);
  //     setState(() {
  //       isBioAuthSwitched = false;
  //     });
  //     return;
  //   }
  //   if (!mounted) return;
  // }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      setState(() {});
      authenticated = await auth.authenticate(
          localizedReason:
              'Scan your fingerprint (or face or whatever) to authenticate',
          options: const AuthenticationOptions(
              useErrorDialogs: true, stickyAuth: true, biometricOnly: true));
      setState(() {
        isBioAuthSwitched = authenticated ? true : false;
      });
    } on PlatformException {
      // print(e);
      setState(() {
        isBioAuthSwitched = false;
      });
      return;
    }
    if (!mounted) return;

    // final String message = authenticated ? 'Authorized' : 'Not Authorized';
    // setState(() {});
  }

  void _cancelAuthentication() async {
    await auth.stopAuthentication();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}
