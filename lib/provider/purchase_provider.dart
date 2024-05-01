import 'package:flutter/cupertino.dart';
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:intl/intl.dart';

class PurchaseProvider with ChangeNotifier {
  PurchaseProvider() {
    _salesManId = ComSettings.appSettings(
            'int', 'key-dropdown-default-salesman-view', 1) -
        1;
    _branchId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;
    setDate(DateFormat('dd-MM-yyyy').format(DateTime.now()));
    // dio.getSalesAccountList().then((value) {
    //   saleAccount = value;
    // });

    _groupId =
        ComSettings.appSettings('int', 'key-dropdown-default-group-view', 0) -
            1;

    _saleAccount = mainAccount.firstWhere(
        (element) => element['LedName'] == 'GENERAL SALES A/C')['LedCode'];
    _acId = mainAccount
        .firstWhere((element) => element['LedName'] == 'CASH')['LedCode'];
    int cashId =
        ComSettings.appSettings('int', 'key-dropdown-default-cash-ac', 0) - 1;
    _acId = cashId > 0
        ? mainAccount.firstWhere((element) => element['LedCode'] == cashId,
            orElse: () => {'LedName': 'CASH', 'LedCode': _acId})['LedCode']
        : _acId;

    // fetchData();
  }
  final scaffoldKey = GlobalKey();
  late CustomerModel _ledgerDataModel;
  CustomerModel get ledgerDataModel => _ledgerDataModel;
  set ledgerDataModel(CustomerModel value) => _ledgerDataModel = value;

  late LedgerModel _ledgerModel;
  LedgerModel get ledgerModel => _ledgerModel;

  set ledgerModel(LedgerModel value) => _ledgerModel = value;

  int _branchId = 0,
      _groupId = 0,
      _salesManId = 0,
      _acId = 0,
      _decimal = 2,
      _saleAccount = 0,
      _nextWidget = 0;
  get nextWidget => _nextWidget;
  set setNextWidget(int value) {
    _nextWidget = value;
    notifyListeners();
  }

  bool _widgetID = true, _oldBill = false, _isLoading = false;

  get isLoading => _isLoading;
  set setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  get oldBill => _oldBill;

  set setOldBill(bool value) {
    _oldBill = value;
    notifyListeners();
  }

  get widgetID => _widgetID;
  set setWidgetID(bool value) {
    _widgetID = value;
    notifyListeners();
  }

  get getBranchId => _branchId;
  set setBranchId(int id) {
    _branchId = id;
    notifyListeners();
  }

  get getGroupId => _groupId;
  set setGroupId(int id) {
    _groupId = id;
    notifyListeners();
  }

  get salesManId => _salesManId;
  set setSalesManId(int id) {
    _salesManId = id;
    notifyListeners();
  }

  late List<CartItemP> _cartItem = [];
  List<CartItemP> get cartItem => _cartItem;

  set cartItem(List<CartItemP> value) => _cartItem = value;

  String _formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String get formattedDate => _formattedDate;
  void setDate(String formattedDate) {
    _formattedDate = formattedDate;
    notifyListeners();
  }

  bool _isTax = true, _isCashBill = false;
  bool get isTax => _isTax;
  set isTax(bool value) {
    _isTax = value;
    notifyListeners();
  }

  bool get isCashBill => _isCashBill;
  set isCashBill(bool value) {
    _isCashBill = value;
    notifyListeners();
  }
}
