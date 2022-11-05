import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FocusNode _uidFocusNode = FocusNode();

  Future<FirebaseApp> _initializeFirebase() async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();

    return firebaseApp;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _uidFocusNode.unfocus(),
      child: Scaffold(
        backgroundColor: blue,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 1,
                        child: Image.asset(
                          'assets/logo.png',
                          height: 160,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'SherAcc ERP',
                        style: TextStyle(
                          color: kPrimaryDarkColor,
                          fontSize: 40,
                        ),
                      ),
                      const Text(
                        'Developed by SherSoft',
                        style: TextStyle(
                          color: firebaseNavy,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                FutureBuilder(
                  future: _initializeFirebase(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error initializing Firebase Cloud');
                    } else if (snapshot.connectionState ==
                        ConnectionState.done) {
                      return LoginForm(focusNode: _uidFocusNode);
                    }
                    return const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        kPrimaryDarkColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
