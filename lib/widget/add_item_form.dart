import 'package:flutter/material.dart';

import 'package:sheraccerp/util/database.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/util/validator.dart';
import 'package:sheraccerp/widget/custom_form_field.dart';

class AddItemForm extends StatefulWidget {
  final FocusNode nameFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode positionFocusNode;

  const AddItemForm({
    Key? key,
    required this.nameFocusNode,
    required this.passwordFocusNode,
    required this.positionFocusNode,
  }) : super(key: key);

  @override
  _AddItemFormState createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _addItemFormKey = GlobalKey<FormState>();

  bool _isProcessing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  var dropDownValue = 'Staff';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _addItemFormKey,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              bottom: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24.0),
                const Text(
                  'UserName',
                  style: TextStyle(
                    color: firebaseGrey,
                    fontSize: 22.0,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                CustomFormField(
                  isLabelEnabled: false,
                  controller: _nameController,
                  focusNode: widget.nameFocusNode,
                  keyboardType: TextInputType.text,
                  inputAction: TextInputAction.next,
                  validator: (value) => Validator.validateField(
                    value: value,
                  ),
                  label: 'UserName',
                  hint: 'Enter your UserName',
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Password',
                  style: TextStyle(
                    color: firebaseGrey,
                    fontSize: 22.0,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                CustomFormField(
                  isLabelEnabled: false,
                  controller: _passwordController,
                  focusNode: widget.passwordFocusNode,
                  keyboardType: TextInputType.text,
                  inputAction: TextInputAction.next,
                  validator: (value) => Validator.validateField(
                    value: value,
                  ),
                  label: 'Password',
                  hint: 'Enter your Password',
                ),
                const SizedBox(height: 8.0),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10)),
                  // dropdown below..
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Position : ',
                        style: TextStyle(
                          color: black,
                          fontSize: 20.0,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                          value: dropDownValue,
                          icon: const Icon(Icons.arrow_drop_down),
                          iconSize: 35,
                          underline: const SizedBox(),
                          onChanged: (value) {
                            setState(() {
                              dropDownValue = value!;
                            });
                          },
                          items: <String>['Staff', 'OWNER', 'Admin', 'SalesMan']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList()),
                    ],
                  ),
                ),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
          _isProcessing
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      firebaseOrange,
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
                      widget.nameFocusNode.unfocus();
                      widget.positionFocusNode.unfocus();

                      if (_addItemFormKey.currentState!.validate()) {
                        setState(() {
                          _isProcessing = true;
                        });

                        // await Database.newUser(
                        //     userName: _nameController.text,
                        //     password: _passwordController.text,
                        //     position: dropDownValue,
                        //     status: false);

                        setState(() {
                          _isProcessing = false;
                        });

                        Navigator.of(context).pop();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
                      child: Text(
                        'ADD USER',
                        style: TextStyle(
                          fontSize: 20,
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

class AddItemFormC extends StatefulWidget {
  // final FocusNode nameFocusNode;
  // final FocusNode dataNameFocusNode;
  final FocusNode codeFocusNode;
  // final FocusNode serverFocusNode;
  final FocusNode urlFocusNode;

  const AddItemFormC({
    Key? key,
    required this.codeFocusNode,
    required this.urlFocusNode,
  }) : super(key: key);

  @override
  _AddItemFormCState createState() => _AddItemFormCState();
}

class _AddItemFormCState extends State<AddItemFormC> {
  final _addItemFormCKey = GlobalKey<FormState>();

  bool _isProcessing = false;

  final TextEditingController _codeController = TextEditingController();
  // final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _dataNameController = TextEditingController();
  // final TextEditingController _serverController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _addItemFormCKey,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              bottom: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10.0),
                // Row(
                //   // mainAxisAlignment: MainAxisAlignment.spaceAround,
                //   children: [
                //     Text(
                //       'Code',
                //       style: TextStyle(
                //         color: firebaseGrey,
                //         fontSize: 22.0,
                //         letterSpacing: 1,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
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
                CustomFormField(
                  isLabelEnabled: false,
                  controller: _codeController,
                  focusNode: widget.codeFocusNode,
                  keyboardType: TextInputType.number,
                  inputAction: TextInputAction.next,
                  validator: (value) => Validator.validateUserID(
                    uid: value,
                  ),
                  label: 'Code',
                  hint: 'Enter customer Code',
                ),
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
                //   focusNode: widget.dataNameFocusNode,
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
                //   focusNode: widget.serverFocusNode,
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
                      firebaseOrange,
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
                      widget.codeFocusNode.unfocus();
                      // widget.nameFocusNode.unfocus();
                      // widget.dataNameFocusNode.unfocus();
                      // widget.serverFocusNode.unfocus();
                      widget.urlFocusNode.unfocus();

                      if (_addItemFormCKey.currentState!.validate()) {
                        setState(() {
                          _isProcessing = true;
                        });

                        Database.tempUId = _codeController.text;

                        await Database.addItemC(
                          // name: _nameController.text,
                          // server: _serverController.text,
                          url: _urlController.text,
                          // status: _status,
                          // dataName: _dataNameController.text,
                        );

                        setState(() {
                          _isProcessing = false;
                        });

                        Navigator.of(context).pop();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                      child: Text(
                        Database.userUid == '099077055'
                            ? 'ADD CUSTOMER'
                            : 'ADD USER',
                        style: const TextStyle(
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
