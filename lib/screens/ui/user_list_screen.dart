import 'package:flutter/material.dart';

import 'package:sheraccerp/screens/ui/add_screen.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/app_bar_title.dart';

class UserList extends StatefulWidget {
  final String documentId;
  const UserList({
    Key? key,
    required this.documentId,
  }) : super(key: key);

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blueAccent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        title: const AppBarTitle(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddScreen(),
            ),
          );
        },
        backgroundColor: kPrimaryColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 10.0,
            left: 16.0,
            right: 16.0,
            bottom: 20.0,
          ),
          child: Container(), //ItemUserList(uId: widget.documentId),
        ),
      ),
    );
  }
}
