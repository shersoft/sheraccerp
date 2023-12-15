import 'package:flutter/material.dart';
import 'package:sheraccerp/screens/about_shersoft.dart';
import 'package:sheraccerp/screens/printer_settings.dart';
import 'package:sheraccerp/screens/profile.dart';
import 'package:sheraccerp/screens/salesman_registration.dart';
import 'package:sheraccerp/screens/settings/software_settings.dart';
import 'package:sheraccerp/screens/tax_registration.dart';
import 'package:sheraccerp/screens/ui/add_screen.dart';
import 'package:sheraccerp/screens/user_list.dart';
import 'package:sheraccerp/screens/user_registration.dart';

import '../../util/res_color.dart';

class MoreWidget extends StatelessWidget {
  const MoreWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        Card(
          elevation: 2,
          child: TextButton(
            child: const Text('Company Profile'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const Profile(),
                ),
              );
            },
          ),
        ),
        Card(
          elevation: 2,
          child: TextButton(
            child: const Text('User List'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserScreen(),
                ),
              );
            },
          ),
        ),
        // Card(
        //   elevation: 2,
        //   child: TextButton(
        //     child: const Text('Create New User'),
        //     onPressed: () {
        //       Navigator.of(context).push(
        //         MaterialPageRoute(
        //           builder: (context) => AddScreen(),
        //         ),
        //       );
        //     },
        //   ),
        // ),
        Card(
          elevation: 2,
          child: TextButton(
            child: const Text('Software Settings'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsMenu()),
              );
            },
          ),
        ),
        Card(
          elevation: 2,
          child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutSherSoft()),
                );
              },
              child: const Text('About Developer')),
        ),
      ],
    );
  }
}

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [],
        title: const Text('Software Settings'),
      ),
      body: GridView.count(
        primary: false,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        crossAxisCount: MediaQuery.of(context).size.width > 400
            ? (MediaQuery.of(context).size.width ~/ 250).toInt()
            : (MediaQuery.of(context).size.width ~/ 150).toInt(),
        children: <Widget>[
          GestureDetector(
            child: Card(
              elevation: 5.0,
              child: Container(
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const <Widget>[
                    Icon(
                      Icons.settings,
                      color: blue,
                      size: 90.0,
                    ),
                    Text(
                      'General',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
          // GestureDetector(
          //   child: Card(
          //     elevation: 5.0,
          //     child: Container(
          //       padding: const EdgeInsets.all(0),
          //       child: Column(
          //         mainAxisAlignment: MainAxisAlignment.spaceAround,
          //         children: const <Widget>[
          //           Icon(
          //             Icons.business_rounded,
          //             color: blue,
          //             size: 90.0,
          //           ),
          //           Text('Default',
          //               style: TextStyle(
          //                   color: Colors.black, fontWeight: FontWeight.bold)),
          //         ],
          //       ),
          //     ),
          //   ),
          //   onTap: () {
          //     _showAlert(context);
          //   },
          // ),
          GestureDetector(
            child: Card(
              elevation: 5.0,
              child: Container(
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const <Widget>[
                    Icon(
                      Icons.print_rounded,
                      size: 90.0,
                      color: blue,
                    ),
                    Text(
                      'Printer',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => const PrintSettings()));
            },
          ),
          GestureDetector(
            child: Card(
              elevation: 5.0,
              child: Container(
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const <Widget>[
                    Icon(
                      Icons.settings,
                      color: blue,
                      size: 90.0,
                    ),
                    Text(
                      'Other',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              Navigator.of(context).pushNamed('/OtherRegistration');
            },
          ),
          GestureDetector(
            child: Card(
              elevation: 5.0,
              child: Container(
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const <Widget>[
                    Icon(
                      Icons.man_rounded,
                      color: blue,
                      size: 90.0,
                    ),
                    Text(
                      'Salesman',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const SalesmanRegistration()));
            },
          ),
          GestureDetector(
            child: Card(
              elevation: 5.0,
              child: Container(
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const <Widget>[
                    Icon(
                      Icons.supervised_user_circle,
                      color: blue,
                      size: 90.0,
                    ),
                    Text(
                      'User',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => const UserRegistration()));
            },
          ),
          GestureDetector(
            child: Card(
              elevation: 5.0,
              child: Container(
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const <Widget>[
                    Icon(
                      Icons.how_to_vote,
                      color: blue,
                      size: 90.0,
                    ),
                    Text(
                      'Tax Group',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => const TaxRegistration()));
            },
          ),
        ],
      ),
    );
  }

  void showAlert(BuildContext context) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 50.0,
                width: 50.0,
              ),
              const Text("SherAcc Alert"),
            ],
          ),
          content: const Text("Not Available. \nwe will update next time"),
          actions: <Widget>[
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
}

class MoreWidget2 extends StatelessWidget {
  const MoreWidget2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        Card(
          elevation: 2,
          child: TextButton(
            child: const Text('Change Password'),
            onPressed: () {
              //
            },
          ),
        ),
        Card(
          elevation: 2,
          child: TextButton(
            child: const Text('Other'),
            onPressed: () {
              //
            },
          ),
        ),
        Card(
          elevation: 2,
          child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutSherSoft()),
                );
              },
              child: const Text('About Developer')),
        ),
      ],
    );
  }
}
