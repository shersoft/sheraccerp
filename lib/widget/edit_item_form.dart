import 'package:flutter/material.dart';

import 'package:sheraccerp/util/database.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/util/validator.dart';
import 'package:sheraccerp/widget/custom_form_field.dart';

// class EditItemForm extends StatefulWidget {
//   final FocusNode nameFocusNode;
//   final FocusNode passwordFocusNode;
//   final FocusNode positionFocusNode;
//   final String currentName;
//   final String currentPassword;
//   final String currentPosition;
//   final bool currentStatus;
//   final String documentId;

//   const EditItemForm({
//     required this.nameFocusNode,
//     required this.passwordFocusNode,
//     required this.positionFocusNode,
//     required this.currentName,
//     required this.currentPassword,
//     required this.currentPosition,
//     required this.currentStatus,
//     required this.documentId,
//   });

//   @override
//   _EditItemFormState createState() => _EditItemFormState();
// }

// class _EditItemFormState extends State<EditItemForm> {
//   final _editItemFormKey = GlobalKey<FormState>();

//   bool _isProcessing = false, _status = false;

//   late TextEditingController _nameController;
//   late TextEditingController _passwordController;
//   String dropDownValue = '';

//   @override
//   void initState() {
//     _nameController = TextEditingController(
//       text: widget.currentName,
//     );

//     _passwordController = TextEditingController(
//       text: widget.currentPassword,
//     );

//     dropDownValue = widget.currentPosition;

//     _status = widget.currentStatus;
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _editItemFormKey,
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(
//               left: 8.0,
//               right: 8.0,
//               bottom: 24.0,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 24.0),
//                 Database.userUid == '099077055'
//                     ? Row(
//                         // mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           Text('Active',
//                               style: TextStyle(
//                                 color: firebaseGrey,
//                               )),
//                           Checkbox(
//                             value: _status,
//                             onChanged: (value) {
//                               setState(() {
//                                 _status = value!;
//                               });
//                             },
//                           )
//                         ],
//                       )
//                     : Container(),
//                 Text(
//                   'UserName',
//                   style: TextStyle(
//                     color: firebaseGrey,
//                     fontSize: 22.0,
//                     letterSpacing: 1,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 8.0),
//                 CustomFormField(
//                   isLabelEnabled: false,
//                   controller: _nameController,
//                   focusNode: widget.nameFocusNode,
//                   keyboardType: TextInputType.text,
//                   inputAction: TextInputAction.next,
//                   validator: (value) => Validator.validateField(
//                     value: value,
//                   ),
//                   label: 'UserName',
//                   hint: 'Enter your UserName',
//                 ),
//                 SizedBox(height: 24.0),
//                 Text(
//                   'Password',
//                   style: TextStyle(
//                     color: firebaseGrey,
//                     fontSize: 22.0,
//                     letterSpacing: 1,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 8.0),
//                 CustomFormField(
//                   isLabelEnabled: false,
//                   controller: _passwordController,
//                   focusNode: widget.passwordFocusNode,
//                   keyboardType: TextInputType.text,
//                   inputAction: TextInputAction.next,
//                   validator: (value) => Validator.validateField(
//                     value: value,
//                   ),
//                   label: 'Password',
//                   hint: 'Enter your Password',
//                 ),
//                 SizedBox(height: 24.0),
//                 Container(
//                     padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                     decoration: BoxDecoration(
//                         color: white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(10)),
//                     // dropdown below..
//                     child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Position',
//                             style: TextStyle(
//                               color: firebaseGrey,
//                               fontSize: 22.0,
//                               letterSpacing: 1,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(height: 8.0),
//                           DropdownButton<String>(
//                               value: dropDownValue,
//                               icon: Icon(Icons.arrow_drop_down),
//                               iconSize: 35,
//                               underline: SizedBox(),
//                               onChanged: (value) {
//                                 setState(() {
//                                   dropDownValue = value!;
//                                 });
//                               },
//                               items: <String>[
//                                 'Staff',
//                                 'OWNER',
//                                 'Admin',
//                                 'SalesMan'
//                               ].map<DropdownMenuItem<String>>((String value) {
//                                 return DropdownMenuItem<String>(
//                                   value: value,
//                                   child: Text(value),
//                                 );
//                               }).toList()),
//                         ]))
//               ],
//             ),
//           ),
//           _isProcessing
//               ? Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                       kPrimaryColor,
//                     ),
//                   ),
//                 )
//               : Container(
//                   width: double.maxFinite,
//                   child: ElevatedButton(
//                     style: ButtonStyle(
//                       backgroundColor: MaterialStateProperty.all(
//                         kPrimaryColor,
//                       ),
//                       shape: MaterialStateProperty.all(
//                         RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                     ),
//                     onPressed: () async {
//                       widget.nameFocusNode.unfocus();
//                       widget.positionFocusNode.unfocus();

//                       if (_editItemFormKey.currentState!.validate()) {
//                         setState(() {
//                           _isProcessing = true;
//                         });

//                         // await Database.updateUser(
//                         //   docId: widget.documentId,
//                         //   userName: _nameController.text,
//                         //   position: dropDownValue,
//                         //   password: _passwordController.text,
//                         //   status: _status,
//                         // );

//                         setState(() {
//                           _isProcessing = false;
//                         });

//                         Navigator.of(context).pop();
//                       }
//                     },
//                     child: Padding(
//                       padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
//                       child: Text(
//                         'UPDATE ITEM',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: firebaseGrey,
//                           letterSpacing: 2,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }
// }

class EditItemFormC extends StatefulWidget {
  final FocusNode codeFocusNode;
  // final FocusNode dbFocusNode;
  // final FocusNode nameFocusNode;
  // final FocusNode serverNameFocusNode;
  final FocusNode urlFocusNode;

  final String currentCode;
  // final String currentDb;
  // final String currentName;
  // final String currentServerName;
  final String currentUrl;
  // final bool currentStatus;
  final String documentId;

  const EditItemFormC({
    Key? key,
    required this.codeFocusNode,
    required this.urlFocusNode,
    required this.currentCode,
    required this.currentUrl,
    required this.documentId,
  }) : super(key: key);

  @override
  _EditItemFormCState createState() => _EditItemFormCState();
}

class _EditItemFormCState extends State<EditItemFormC> {
  final _editItemFormKey = GlobalKey<FormState>();

  bool _isProcessing = false;
  String _code = '0000';

  // late TextEditingController _nameController;
  // late TextEditingController _dataNameController;
  // late TextEditingController _serverController;
  late TextEditingController _urlController;

  @override
  void initState() {
    _code = widget.currentCode;
    // _nameController = TextEditingController(text: widget.currentName);
    // _dataNameController = TextEditingController(text: widget.currentDb);
    // _serverController = TextEditingController(text: widget.currentServerName);
    _urlController = TextEditingController(text: widget.currentUrl);
    // _status = widget.currentStatus;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _editItemFormKey,
      child: ListView(
        children: [
          // Ink(
          //     decoration: BoxDecoration(
          //       color: firebaseGrey.withOpacity(0.1),
          //       borderRadius: BorderRadius.circular(8.0),
          //     ),
          //     child: ListTile(
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(8.0),
          //         ),
          //         title: Text('View User List',
          //             style: TextStyle(
          //               color: firebaseGrey,
          //               fontSize: 19.0,
          //               letterSpacing: 1,
          //               fontWeight: FontWeight.bold,
          //             )),
          //         onTap: () => Navigator.of(context).push(MaterialPageRoute(
          //             builder: (context) => UserList(
          //                   documentId: _code,
          //                 ))))),
          Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              bottom: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5.0),
                // Row(
                //   // mainAxisAlignment: MainAxisAlignment.spaceAround,
                //   children: [
                Text(
                  'Code : ' + _code,
                  style: const TextStyle(
                    color: firebaseGrey,
                    fontSize: 19.0,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                //     SizedBox(
                //       width: 80,
                //     ),
                //     Text('Active',
                //         style: TextStyle(
                //           color: firebaseGrey,
                //         )),
                //     Checkbox(
                //       value: _status,
                //       onChanged: (value) {
                //         setState(() {
                //           _status = value!;
                //         });
                //       },
                //     )
                //   ],
                // ),
                // SizedBox(height: 0.0),
                // Text(
                //   'DataBase',
                //   style: TextStyle(
                //     color: firebaseGrey,
                //     fontSize: 22.0,
                //     letterSpacing: 1,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // // SizedBox(height: 8.0),
                // CustomFormField(
                //   isLabelEnabled: false,
                //   controller: _dataNameController,
                //   focusNode: widget.dbFocusNode,
                //   keyboardType: TextInputType.text,
                //   inputAction: TextInputAction.next,
                //   validator: (value) => Validator.validateField(
                //     value: value,
                //   ),
                //   label: 'DataBase',
                //   hint: 'Enter DataBase Name',
                // ),
                // Text(
                //   'Name',
                //   style: TextStyle(
                //     color: firebaseGrey,
                //     fontSize: 22.0,
                //     letterSpacing: 1,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // // SizedBox(height: 8.0),
                // CustomFormField(
                //   isLabelEnabled: false,
                //   controller: _nameController,
                //   focusNode: widget.nameFocusNode,
                //   keyboardType: TextInputType.text,
                //   inputAction: TextInputAction.next,
                //   validator: (value) => Validator.validateField(
                //     value: value,
                //   ),
                //   label: 'Name',
                //   hint: 'Enter Firm Name',
                // ),
                // Text(
                //   'Server Name',
                //   style: TextStyle(
                //     color: firebaseGrey,
                //     fontSize: 22.0,
                //     letterSpacing: 1,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // // SizedBox(height: 8.0),
                // CustomFormField(
                //   isLabelEnabled: false,
                //   controller: _serverController,
                //   focusNode: widget.serverNameFocusNode,
                //   keyboardType: TextInputType.text,
                //   inputAction: TextInputAction.next,
                //   validator: (value) => Validator.validateField(
                //     value: value,
                //   ),
                //   label: 'Server',
                //   hint: 'Enter Server Name',
                // ),
                // SizedBox(height: 24.0),
                const Text(
                  'API URL',
                  style: TextStyle(
                    color: firebaseGrey,
                    fontSize: 22.0,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // SizedBox(height: 8.0),
                CustomFormField(
                  maxLines: 3,
                  isLabelEnabled: false,
                  controller: _urlController,
                  focusNode: widget.urlFocusNode,
                  keyboardType: TextInputType.text,
                  inputAction: TextInputAction.done,
                  validator: (value) => Validator.validateField(
                    value: value,
                  ),
                  label: 'Url',
                  hint: 'Enter Url',
                ),
              ],
            ),
          ),
          _isProcessing
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      kPrimaryColor,
                    ),
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        kPrimaryColor,
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    onPressed: () async {
                      // widget.nameFocusNode.unfocus();
                      widget.urlFocusNode.unfocus();

                      if (_editItemFormKey.currentState!.validate()) {
                        setState(() {
                          _isProcessing = true;
                        });

                        await Database.updateFirm(
                          docId: widget.documentId,
                          // dataName: _dataNameController.text,
                          // name: _nameController.text,
                          // server: _serverController.text,
                          // status: _status,
                          url: _urlController.text,
                        );

                        setState(() {
                          _isProcessing = false;
                        });

                        Navigator.of(context).pop();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
                      child: Text(
                        'UPDATE ITEM',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: firebaseGrey,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
