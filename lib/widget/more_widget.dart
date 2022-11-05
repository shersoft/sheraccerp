import 'package:flutter/material.dart';
import 'package:sheraccerp/screens/about_shersoft.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:sheraccerp/screens/profile.dart';
import 'package:sheraccerp/screens/ui/add_screen.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:sheraccerp/screens/user_list.dart';

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
