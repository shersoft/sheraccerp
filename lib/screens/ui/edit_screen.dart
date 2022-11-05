import 'package:flutter/material.dart';

import 'package:sheraccerp/util/database.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/app_bar_title.dart';
import 'package:sheraccerp/widget/edit_item_form.dart';

// class EditScreen extends StatefulWidget {
//   final String currentName;
//   final String currentPassword;
//   final String currentPosition;
//   final bool currentStatus;
//   final String documentId;

//   EditScreen({
//     required this.currentName,
//     required this.currentPassword,
//     required this.currentPosition,
//     required this.currentStatus,
//     required this.documentId,
//   });

//   @override
//   _EditScreenState createState() => _EditScreenState();
// }

// class _EditScreenState extends State<EditScreen> {
//   final FocusNode _nameFocusNode = FocusNode();
//   final FocusNode _passwordFocusNode = FocusNode();
//   final FocusNode _positionFocusNode = FocusNode();

//   bool _isDeleting = false;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         _nameFocusNode.unfocus();
//         _passwordFocusNode.unfocus();
//         _positionFocusNode.unfocus();
//       },
//       child: Scaffold(
//         backgroundColor: blueAccent,
//         appBar: AppBar(
//           elevation: 0,
//           backgroundColor: kPrimaryColor,
//           title: AppBarTitle(),
//           actions: [
//             _isDeleting
//                 ? Padding(
//                     padding: const EdgeInsets.only(
//                       top: 10.0,
//                       bottom: 10.0,
//                       right: 16.0,
//                     ),
//                     child: CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation<Color>(
//                         Colors.redAccent,
//                       ),
//                       strokeWidth: 3,
//                     ),
//                   )
//                 : IconButton(
//                     icon: Icon(
//                       Icons.delete,
//                       color: Colors.redAccent,
//                       size: 32,
//                     ),
//                     onPressed: () async {
//                       setState(() {
//                         _isDeleting = true;
//                       });

//                       // await Database.deleteUser(
//                       //   docId: widget.documentId,
//                       // );

//                       setState(() {
//                         _isDeleting = false;
//                       });

//                       Navigator.of(context).pop();
//                     },
//                   ),
//           ],
//         ),
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.only(
//               left: 16.0,
//               right: 16.0,
//               bottom: 20.0,
//             ),
//             child: EditItemForm(
//               documentId: widget.documentId,
//               nameFocusNode: _nameFocusNode,
//               positionFocusNode: _positionFocusNode,
//               currentName: widget.currentName,
//               currentPosition: widget.currentPosition,
//               currentStatus: widget.currentStatus,
//               currentPassword: widget.currentPassword,
//               passwordFocusNode: _passwordFocusNode,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class EditScreenC extends StatefulWidget {
  final String currentCode;
  // final String currentDb;
  // final String currentName;
  // final String currentServerName;
  final String currentUrl;
  // final bool currentStatus;
  final String documentId;

  const EditScreenC({
    Key? key,
    required this.currentCode,
    required this.currentUrl,
    required this.documentId,
  }) : super(key: key);

  @override
  _EditScreenCState createState() => _EditScreenCState();
}

class _EditScreenCState extends State<EditScreenC> {
  final FocusNode _codeFocusNode = FocusNode();
  // final FocusNode _dbFocusNode = FocusNode();
  // final FocusNode _nameFocusNode = FocusNode();
  // final FocusNode _serverNameFocusNode = FocusNode();
  final FocusNode _urlFocusNode = FocusNode();

  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _codeFocusNode.unfocus();
        // _dbFocusNode.unfocus();
        // _nameFocusNode.unfocus();
        // _serverNameFocusNode.unfocus();
        _urlFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: blueAccent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: kPrimaryColor,
          title: const AppBarTitle(),
          actions: [
            _isDeleting
                ? const Padding(
                    padding: EdgeInsets.only(
                      top: 10.0,
                      bottom: 10.0,
                      right: 16.0,
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.redAccent,
                      ),
                      strokeWidth: 3,
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 32,
                    ),
                    onPressed: () async {
                      setState(() {
                        _isDeleting = true;
                      });

                      await Database.deleteFirm(
                        docId: widget.documentId,
                      );

                      setState(() {
                        _isDeleting = false;
                      });

                      Navigator.of(context).pop();
                    },
                  ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 20.0,
            ),
            child: EditItemFormC(
              documentId: widget.documentId,
              codeFocusNode: _codeFocusNode,
              // nameFocusNode: _nameFocusNode,
              // dbFocusNode: _dbFocusNode,
              // serverNameFocusNode: _serverNameFocusNode,
              urlFocusNode: _urlFocusNode,
              currentCode: widget.currentCode,
              // currentName: widget.currentName,
              // currentDb: widget.currentDb,
              // currentServerName: widget.currentServerName,
              currentUrl: widget.currentUrl,
              // currentStatus: widget.currentStatus,
            ),
          ),
        ),
      ),
    );
  }
}
