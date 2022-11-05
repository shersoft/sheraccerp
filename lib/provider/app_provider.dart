import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppProvider with ChangeNotifier {
  AppProvider();
  final GlobalKey<ScaffoldState> appScaffoldKey = GlobalKey();
  bool _isInternet = false;
  bool get isInternet => _isInternet;

  set isInternet(bool value) => _isInternet = value;

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value) => _loading = value;

  bool _isMultiFirm = false,
      _secureAuth = false,
      _nextWidget = false,
      _badRequest = false,
      _loadAgin = false,
      _isEstimate = false;
  bool get isMultiFirm => _isMultiFirm;

  set isMultiFirm(bool value) => _isMultiFirm = value;

  get secureAuth => _secureAuth;

  set secureAuth(value) => _secureAuth = value;

  get nextWidget => _nextWidget;

  set nextWidget(value) => _nextWidget = value;

  get badRequest => _badRequest;

  set badRequest(value) => _badRequest = value;

  get loadAgin => _loadAgin;

  set loadAgin(value) => _loadAgin = value;
  bool get isEstimate => _isEstimate;
  set isEstimate(value) {
    _isEstimate = value;
    notifyListeners();
  }

  String _formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String get formattedDate => _formattedDate;
  set formattedDate(String formattedDate) {
    _formattedDate = formattedDate;
    notifyListeners();
  }

  //internal counter
  int _counter = 0;
//This is getter function
  int get counter => _counter;
//This is setter and set the value and notify about change
  set counter(int counter) {
    _counter = counter;
    notifyListeners();
  }

//increment function
  increment() {
    counter = counter + 1;
  }

  //decrement function
  decrement() {
    counter = counter - 1;
  }

  Future selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      formattedDate = (DateFormat('dd-MM-yyyy').format(picked));
    }
  }
}
