import 'package:flutter/material.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';

showConfirmAlertBoxOption(context, String title, String message, bool buttonYes,
    bool buttonNo, Color buttonColorForNo, Color buttonColorForYes) {
  ConfirmAlertBox(
      buttonColorForNo: buttonColorForNo, //Colors.white,
      buttonColorForYes: buttonColorForYes, //Colors.green,
      icon: Icons.check,
      onPressedYes: () {
        Navigator.of(context).pop();
      },
      buttonTextForNo: 'No',
      onPressedNo: () => Navigator.of(context).pop(),
      infoMessage: message,
      title: title,
      context: context);
}

showConfirmAlertBox(context, String title, String message) {
  ConfirmAlertBox(
      buttonColorForNo: Colors.white,
      buttonColorForYes: Colors.green,
      icon: Icons.check,
      onPressedYes: () {
        Navigator.of(context).pop();
      },
      // buttonTextForNo: 'No',
      infoMessage: message,
      title: title,
      context: context);
}

showWarningAlertBox(context, String title, String message) {
  ConfirmAlertBox(
      buttonColorForNo: Colors.red,
      buttonColorForYes: Colors.white,
      icon: Icons.warning,
      onPressedNo: () {
        Navigator.of(context).pop();
      },
      buttonTextForNo: 'Close',
      infoMessage: message,
      title: title,
      context: context);
}
