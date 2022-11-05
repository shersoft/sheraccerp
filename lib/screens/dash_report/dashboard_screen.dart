import 'package:flutter/material.dart';
import 'package:sheraccerp/screens/ui/add_screen.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/app_bar_title.dart';
import 'package:sheraccerp/widget/item_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // final FocusNode _nameFocusNode = FocusNode();
  // final FocusNode _emailFocusNode = FocusNode();
  // final FocusNode _passwordFocusNode = FocusNode();

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
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: 10.0,
            left: 16.0,
            right: 16.0,
            bottom: 20.0,
          ),
          child: ItemListC(),
        ),
      ),
    );
  }
}
