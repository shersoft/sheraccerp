import 'package:flutter/material.dart';
import 'package:sheraccerp/util/res_color.dart';

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo.png',
          height: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          'Customer',
          style: TextStyle(
            color: firebaseYellow,
            fontSize: 18,
          ),
        ),
        const Text(
          ' List',
          style: TextStyle(
            color: firebaseOrange,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
