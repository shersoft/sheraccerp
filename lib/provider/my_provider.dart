import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class MyProvider with ChangeNotifier, DiagnosticableTreeMixin {
  MyProvider();

  bool _otherAmountLoaded = false;
}
