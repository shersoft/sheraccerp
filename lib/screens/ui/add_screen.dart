import 'package:flutter/material.dart';
import 'package:sheraccerp/util/database.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/add_item_form.dart';
import 'package:sheraccerp/widget/app_bar_title.dart';

class AddScreen extends StatelessWidget {
  final FocusNode _codeFocusNode = FocusNode();
  // final FocusNode _nameFocusNode = FocusNode();
  // final FocusNode _dataNameFocusNode = FocusNode();
  // final FocusNode _passwordFocusNode = FocusNode();
  // final FocusNode _positionFocusNode = FocusNode();
  // final FocusNode _serverFocusNode = FocusNode();
  final FocusNode _urlFocusNode = FocusNode();

  AddScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // _passwordFocusNode.unfocus();
        // _positionFocusNode.unfocus();
        _codeFocusNode.unfocus();
        // _nameFocusNode.unfocus();
        // _dataNameFocusNode.unfocus();
        // _serverFocusNode.unfocus();
        _urlFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: blueAccent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: kPrimaryColor,
          title: Database.userUid == '099077055'
              ? const AppBarTitle()
              : const Text('User List'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 20.0,
            ),
            child: Database.userUid == '099077055'
                ? AddItemFormC(
                    codeFocusNode: _codeFocusNode,
                    // nameFocusNode: _nameFocusNode,
                    // serverFocusNode: _serverFocusNode,
                    urlFocusNode: _urlFocusNode,
                    // dataNameFocusNode: _dataNameFocusNode,
                  )
                : Container(),
            // AddItemForm(
            //   nameFocusNode: _nameFocusNode,
            //   passwordFocusNode: _passwordFocusNode,
            //   positionFocusNode: _positionFocusNode,
            // ),
          ),
        ),
      ),
    );
  }
}
