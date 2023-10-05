import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/models/sales_model.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/models/stock_item.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';

class SalesProvider with ChangeNotifier {
  final scaffoldKey = GlobalKey();
  List<SalesType> _salesTypeDisplay = [];
  late List<OtherAmount> _otherAmountList;
  late CustomerModel _ledgerModel;
  late SalesModel _salesModel;
  bool _isCustomForm = false;
  bool _customerReusableProduct = false;
  int _branchId = 0,
      _groupId = 0,
      _salesManId = 0,
      _saleAccount = 0,
      _acId = 0,
      _decimal = 2;
  get getBranchId => _branchId;
  set setBranchId(int id) {
    _branchId = id;
    notifyListeners();
  }

  get getSaleAccount => _saleAccount;
  set setSaleAccount(int id) {
    _saleAccount = id;
    notifyListeners();
  }

  get getGroupId => _groupId;
  set setGroupId(int id) {
    _groupId = id;
    notifyListeners();
  }

  get getSalesManId => _salesManId;
  set setSalesManId(int id) {
    _salesManId = id;
    notifyListeners();
  }

  bool _defaultSale = false,
      _thisSale = false,
      _isLoading = false,
      _loadScanner = false;
  bool _isTax = true,
      _otherAmountLoaded = false,
      _valueMore = false,
      _lastRecord = false,
      _widgetID = true,
      _previewData = false,
      _oldBill = false,
      _itemCodeVise = false,
      _ledgerScanner = false,
      _productScanner = false,
      _isItemDiscountEditLocked = false;
  bool get isItemDiscountEditLocked => _isItemDiscountEditLocked;
  set isItemDiscountEditLocked(bool value) => _isItemDiscountEditLocked = value;
  bool isItemRateEditLocked = false;
  get getIsItemRateEditLocked => isItemRateEditLocked;

  set setIsItemRateEditLocked(isItemRateEditLocked) =>
      isItemRateEditLocked = isItemRateEditLocked;

  List<CartItem> _cartItem = [];
  List<CartItem> get cartItem => _cartItem;

  set cartItem(List<CartItem> value) => _cartItem = value;
  bool get getLedgerScanner => _ledgerScanner;
  set setLedgerScanner(bool value) {
    _ledgerScanner = value;
  }

  bool get getProductScanner => _productScanner;
  set setProductScanner(bool value) {
    _productScanner = value;
  }

  SalesProvider() {
    taxable = salesTypeData.tax;
    _isCustomForm =
        ComSettings.appSettings('bool', 'key-switch-sales-form-set', false)
            ? true
            : false;
    salesTypeDisplay = _isCustomForm
        ? ComSettings.salesFormList('key-item-sale-form-', false)
        : salesTypeList;
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
    _acId =
        ComSettings.appSettings('int', 'key-dropdown-default-cash-ac', 0) - 1 >
                _acId
            ? ComSettings.appSettings(
                    'int', 'key-dropdown-default-cash-ac', _acId) -
                1
            : _acId;

    _ledgerScanner =
        ComSettings.appSettings('bool', 'key-customer-scan', false);
    _itemCodeVise = ComSettings.appSettings('bool', 'key-item-by-code', false);
    _customerReusableProduct =
        ComSettings.appSettings('bool', 'key-customer-reusable-product', false)
            ? true
            : false;
    fetchData();
  }

  void fetchData() {
    DioService().fetchDetailAmount().then((value) {
      List<OtherAmount> xData = [];
      for (var other in value) {
        xData.add(OtherAmount.fromJson(other));
      }

      setOtherAmountList = xData;
      otherAmountLoaded = true;
      notifyListeners();
    });
  }

  loadSettings() {
    CompanyInformation companySettings = CompanyInformation(name: 'Bla bla');
    List<CompanySettings> settings = [
      CompanySettings(name: 'X', status: 0, value: '')
    ];

    taxMethod = companySettings.taxCalculation;
    _enableMULTIUNIT = ComSettings.getStatus('ENABLE MULTI-UNIT', settings);
    _pRateBasedProfitInSales =
        ComSettings.getStatus('PRATE BASED PROFIT IN SALES', settings);
    _negativeStock = ComSettings.getStatus('ALLOW NEGETIVE STOCK', settings);
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    _cessOnNetAmount = ComSettings.getStatus('CESS ON NET AMOUNT', settings);
    _enableKeralaFloodCess =
        ComSettings.getStatus('ENABLE KERALA FLOOD CESS', settings);
    _useUNIQUECODEASBARCODE =
        ComSettings.getStatus('USE UNIQUECODE AS BARCODE', settings);
    _useOLDBARCODE = ComSettings.getStatus('USE OLD BARCODE', settings);
    _decimal = (ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
            ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
            : 2) ??
        0;
    notifyListeners();
  }

  int get decimal => _decimal;

  set decimal(int value) => _decimal = value;

  get getCustomerReusableProduct => _customerReusableProduct;
  set setCustomerReusableProduct(bool value) {
    _customerReusableProduct = value;
  }

  List<OtherAmount> get getOtherAmountList => _otherAmountList;
  set setOtherAmountList(List<OtherAmount> data) {
    _otherAmountList = data;
    notifyListeners();
  }

  late StockItem _stockModel;
  StockItem get getStockItem => _stockModel;

  set setStockItem(StockItem data) {
    _stockModel = data;
  }

  SalesModel get getSalesModel => _salesModel;
  set setSalesModel(SalesModel model) {
    _salesModel = model;
    notifyListeners();
  }

  CustomerModel get getLedgerModel => _ledgerModel;
  set setCustomerModel(CustomerModel data) {
    _ledgerModel = data;
    notifyListeners();
  }

  set setLedger(var data) {
    setCustomerModel = CustomerModel(
        id: data.id,
        name: data.name,
        address1: '',
        address2: '',
        address3: '',
        address4: '',
        taxNumber: '',
        phone: '',
        email: '',
        balance: '',
        city: '',
        route: '',
        state: '',
        stateCode: '',
        remarks: '');
  }

  SalesType get getSalesTypeData => salesTypeData;

  set setSalesTypeData(SalesType salesType) {
    salesTypeData = salesType;
    notifyListeners();
  }

  List<SalesType> get getSalesTypeDisplay => _salesTypeDisplay;
  set salesTypeDisplay(List<SalesType> data) {
    _salesTypeDisplay = data;
    notifyListeners();
  }

  bool get getTaxable => taxable;
  set setTaxable(bool _taxable) {
    taxable = _taxable;
    notifyListeners();
  }

  bool get isCustomForm => _isCustomForm;
  set isCustomForm(bool isCustomForm) {
    _isCustomForm = isCustomForm;
    notifyListeners();
  }

  bool get loadScanner => _loadScanner;
  set loadScanner(bool loadScanner) {
    _loadScanner = loadScanner;
    notifyListeners();
  }

  bool get defaultSale => _defaultSale;
  set defaultSale(bool defaultSale) {
    _defaultSale = defaultSale;
    notifyListeners();
  }

  bool get thisSale => _thisSale;
  set thisSale(bool thisSale) {
    _thisSale = thisSale;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  set isLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  String _formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String get getDate => _formattedDate;
  void setDate(String formattedDate) {
    _formattedDate = formattedDate;
    notifyListeners();
  }

  bool get isTax => _isTax;
  set isTax(bool isTax) {
    _isTax = isTax;
    // notifyListeners();
  }

  bool get otherAmountLoaded => _otherAmountLoaded;
  set otherAmountLoaded(bool otherAmountLoaded) {
    _otherAmountLoaded = otherAmountLoaded;
    notifyListeners();
  }

  bool get valueMore => _valueMore;
  set valueMore(bool valueMore) {
    _valueMore = valueMore;
    notifyListeners();
  }

  bool get lastRecord => _lastRecord;
  set lastRecord(bool lastRecord) {
    _lastRecord = lastRecord;
    notifyListeners();
  }

  bool get widgetID => _widgetID;
  set widgetID(bool widgetID) {
    _widgetID = widgetID;
    notifyListeners();
  }

  bool get previewData => _previewData;
  set previewData(bool previewData) {
    _previewData = previewData;
    // notifyListeners();
  }

  bool get oldBill => _oldBill;
  set oldBill(bool oldBill) {
    _oldBill = oldBill;
    notifyListeners();
  }

  bool get itemCodeVise => _itemCodeVise;
  set itemCodeVise(bool itemCodeVise) {
    _itemCodeVise = itemCodeVise;
    notifyListeners();
  }

  double _totalGrossValue = 0;
  get totalGrossValue => _totalGrossValue;
  double _totalDiscount = 0;
  get totalDiscount => _totalDiscount;
  double _totalNet = 0;
  get totalNet => _totalNet;
  double _totalCess = 0;
  get totalCess => _totalCess;
  double _totalIgST = 0;
  get totalIgST => _totalIgST;
  double _totalCgST = 0;
  get totalCgST => _totalCgST;
  double _totalSgST = 0;
  get totalSgST => _totalSgST;
  double _totalFCess = 0;
  get totalFCess => _totalFCess;
  double _totalAdCess = 0;
  get totalAdCess => _totalAdCess;
  double _totalRDiscount = 0;
  get totalRDiscount => _totalRDiscount;
  double _taxTotalCartValue = 0;
  get taxTotalCartValue => _taxTotalCartValue;
  double _totalCartValue = 0;
  get totalCartValue => _totalCartValue;
  double _totalProfit = 0;
  get totalProfit => _totalProfit;
  double _grandTotal = 0;
  get getGrandTotal => _grandTotal;
  set setGrangTotal(double d) {
    _grandTotal = d;
    notifyListeners();
  }

  int get totalItem => _cartItem.length;

  CartItem addCart(ParticularsModel product) {
    return CartItem(
        stock: 0,
        id: totalItem + 1,
        itemId: product.itemId,
        itemName: product.itemname,
        quantity: product.qty,
        rate: product.rate,
        rRate: product.realRate,
        uniqueCode: product.uniqueCode,
        gross: product.grossValue,
        discount: product.disc,
        discountPercent: product.discPersent,
        rDiscount: product.rDisc,
        fCess: product.fcess,
        serialNo: product.serialno,
        tax: product.cGST + product.sGST + product.iGST,
        taxP: product.taxP,
        unitId: product.unit,
        unitValue: product.unitValue,
        pRate: product.pRate,
        rPRate: product.rPrate,
        barcode: product.uniqueCode,
        expDate: '2020-01-01',
        free: product.freeQty,
        fUnitId: product.funit,
        cdPer: 0,
        cDisc: 0,
        net: product.grossValue,
        cess: product.cess,
        total: product.total,
        profitPer: 0, //product['']profitPer,
        fUnitValue: product.fValue,
        adCess: product.adcess,
        iGST: product.iGST,
        cGST: product.cGST,
        sGST: product.sGST,
        minimumRate: 0);
  }

  void addProduct(product) {
    int index = _cartItem.indexWhere((i) => i.id == product.id);

    if (index != -1) {
      updateProduct(product, product.quantity + 1);
    } else {
      _cartItem.add(product);
      calculateTotal();
    }
    notifyListeners();
  }

  void removeProduct(product) {
    int index = _cartItem.indexWhere((i) => i.id == product.id);
    _cartItem[index].quantity = 1;
    _cartItem.removeWhere((item) => item.id == product.id);
    notifyListeners();
  }

  void updateProduct(product, qty) {
    int index = _cartItem.indexWhere((i) => i.id == product.id);
    _cartItem[index].quantity = qty;

    _cartItem[index].gross = CommonService.getRound(
        2, (_cartItem[index].rRate * _cartItem[index].quantity));
    _cartItem[index].net = CommonService.getRound(
        2, (_cartItem[index].gross - _cartItem[index].rDiscount));
    if (_cartItem[index].taxP > 0) {
      _cartItem[index].tax = CommonService.getRound(
          2, ((_cartItem[index].net * _cartItem[index].taxP) / 100));
      if (companyTaxMode == 'INDIA') {
        _cartItem[index].fCess = 0; //isKFC
        //     ? CommonService.getRound(decimal, ((_cartItem[index].net * kfcPer) / 100))
        //     : 0;
        double csPer = _cartItem[index].taxP / 2;
        double csGST = CommonService.getRound(
            _decimal, ((_cartItem[index].net * csPer) / 100));
        _cartItem[index].sGST = csGST;
        _cartItem[index].cGST = csGST;
      } else if (companyTaxMode == 'GULF') {
        _cartItem[index].cGST = 0;
        _cartItem[index].sGST = 0;
        _cartItem[index].iGST = CommonService.getRound(
            2, ((_cartItem[index].net * _cartItem[index].taxP) / 100));
      } else {
        _cartItem[index].cGST = 0;
        _cartItem[index].sGST = 0;
        _cartItem[index].fCess = 0;
      }
    }
    _cartItem[index].total = CommonService.getRound(
        2,
        (_cartItem[index].net +
            _cartItem[index].cGST +
            _cartItem[index].sGST +
            _cartItem[index].iGST +
            _cartItem[index].cess +
            _cartItem[index].fCess +
            _cartItem[index].adCess));
    _cartItem[index].profitPer = CommonService.getRound(
        2,
        _cartItem[index].total -
            _cartItem[index].rPRate * _cartItem[index].quantity);

    if (_cartItem[index].quantity == 0) removeProduct(product);

    calculateTotal();
  }

  bool _outOfStock = false,
      _enableMULTIUNIT = false,
      _pRateBasedProfitInSales = false,
      _negativeStock = false,
      _cessOnNetAmount = false,
      _negativeStockStatus = false,
      _enableKeralaFloodCess = false,
      _useUNIQUECODEASBARCODE = false,
      _useOLDBARCODE = false;

  bool get outOfStock => _outOfStock;

  set outOfStock(bool value) => _outOfStock = value;
  get enableMULTIUNIT => _enableMULTIUNIT;
  get pRateBasedProfitInSales => _pRateBasedProfitInSales;
  get negativeStock => _negativeStock;
  get cessOnNetAmount => _cessOnNetAmount;
  get negativeStockStatus => _negativeStockStatus;
  get enableKeralaFloodCess => _enableKeralaFloodCess;
  get useUNIQUECODEASBARCODE => _useUNIQUECODEASBARCODE;
  get useOLDBARCODE => _useOLDBARCODE;

  bool _isItemData = false;
  bool get isItemData => _isItemData;
  set isItemData(bool value) {
    _isItemData = value;
    notifyListeners();
  }

  void editProduct(String title, String value, int id) {
    int index = _cartItem.indexWhere((i) => i.id == id);
    if (title == 'Edit Rate') {
      _cartItem[index].rate = double.tryParse(value) ?? 0;
      _cartItem[index].rRate = taxMethod == 'MINUS'
          ? isKFC
              ? CommonService.getRound(
                  4,
                  (100 * _cartItem[index].rate) /
                      (100 + _cartItem[index].taxP + kfcPer))
              : CommonService.getRound(4,
                  (100 * _cartItem[index].rate) / (100 + _cartItem[index].taxP))
          : _cartItem[index].rate;
    } else if (title == 'Edit Quantity') {
      bool cartQ = false;
      if (totalItem > 0) {
        double cartS = 0, cartQt = 0;
        double oldQty = _cartItem[index].quantity;
        for (var element in _cartItem) {
          if (element.itemId == _cartItem[index].itemId) {
            cartQt += element.quantity;
            cartS = element.stock;
          }
        }
        if (cartS > 0) {
          if (cartS < cartQt - oldQty + double.tryParse(value)!) {
            cartQ = true;
          }
        }
      }
      _outOfStock = negativeStock
          ? false
          : salesTypeData.stock
              ? double.tryParse(value)! > _cartItem[index].stock
                  ? true
                  : cartQ
                      ? true
                      : false
              : false;
      if (outOfStock) {
        /**do ui***/
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //   content: const Text('Sorry stock not available.'),
        //   duration: const Duration(seconds: 10),
        //   action: SnackBarAction(
        //     label: 'Click',
        //     onPressed: () {
        //       // print('Action is clicked');
        //     },
        //     textColor: Colors.white,
        //     disabledTextColor: Colors.grey,
        //   ),
        //   backgroundColor: Colors.red,
        // ));
      } else {
        _cartItem[index].quantity = double.tryParse(value) ?? 0;
      }
    }
    _cartItem[index].gross = CommonService.getRound(
        2, (_cartItem[index].rRate * _cartItem[index].quantity));
    _cartItem[index].net = CommonService.getRound(
        2, (_cartItem[index].gross - _cartItem[index].rDiscount));
    if (_cartItem[index].taxP > 0) {
      _cartItem[index].tax = CommonService.getRound(
          2, ((_cartItem[index].net * _cartItem[index].taxP) / 100));
      if (companyTaxMode == 'INDIA') {
        _cartItem[index].fCess = 0;
        double csPer = _cartItem[index].taxP / 2;
        double csGST = CommonService.getRound(
            _decimal, ((_cartItem[index].net * csPer) / 100));
        _cartItem[index].sGST = csGST;
        _cartItem[index].cGST = csGST;
      } else if (companyTaxMode == 'GULF') {
        _cartItem[index].cGST = 0;
        _cartItem[index].sGST = 0;
        _cartItem[index].iGST = CommonService.getRound(
            2, ((_cartItem[index].net * _cartItem[index].taxP) / 100));
      } else {
        _cartItem[index].cGST = 0;
        _cartItem[index].sGST = 0;
        _cartItem[index].fCess = 0;
      }
    }
    _cartItem[index].total = CommonService.getRound(
        2,
        (_cartItem[index].net +
            _cartItem[index].cGST +
            _cartItem[index].sGST +
            _cartItem[index].iGST +
            _cartItem[index].cess +
            _cartItem[index].fCess +
            _cartItem[index].adCess));
    _cartItem[index].profitPer = CommonService.getRound(
        2,
        _cartItem[index].total -
            _cartItem[index].rPRate * _cartItem[index].quantity);

    calculateTotal();
  }

  void clearCart() {
    for (var f in _cartItem) {
      f.quantity = 1;
    }
    _cartItem = [];
    calculateTotal();
  }

  void calculateTotal() {
    _totalGrossValue = 0;
    _totalDiscount = 0;
    _totalRDiscount = 0;
    _totalNet = 0;
    _totalCess = 0;
    _totalIgST = 0;
    _totalCgST = 0;
    _totalSgST = 0;
    _totalFCess = 0;
    _totalAdCess = 0;
    _taxTotalCartValue = 0;
    _totalCartValue = 0;
    _totalProfit = 0;
    _grandTotal = 0;

    for (var f in _cartItem) {
      _totalGrossValue += f.gross;
      _totalDiscount += f.discount;
      _totalRDiscount += f.rDiscount;
      _totalNet += f.net;
      _totalCess += f.cess;
      _totalIgST += f.iGST;
      _totalCgST += f.cGST;
      _totalSgST += f.sGST;
      _totalFCess += f.fCess;
      _totalAdCess += f.adCess;
      _taxTotalCartValue += f.tax;
      _totalCartValue += f.total;
      _totalProfit += f.profitPer;
    }
    _grandTotal = totalCartValue +
        _otherAmountList.fold(
            0.0,
            (t, e) =>
                double.parse(t.toString()) +
                double.parse(e.symbol == '-'
                    ? (e.amount * -1).toString()
                    : e.amount.toString()));
    notifyListeners();
  }

  void resetVariable() {
    _isLoading = false;
    _loadScanner = false;
    _isTax = true;
    _otherAmountLoaded = false;
    _valueMore = false;
    _lastRecord = false;
    _widgetID = true;
    _previewData = false;
    _oldBill = false;
    _itemCodeVise = false;
    _ledgerScanner = false;
    _productScanner = false;
    _nextWidget = 0;
    _lastRecord = false;
    _pageTotal = 0;
    _totalRecords = 0;
    _page = 1;
    _isLoadingData = false;
    _dataDisplay = [];
  }

  int _nextWidget = 0;
  int get nextWidget => _nextWidget;

  set nextWidget(int value) {
    _nextWidget = value;
    notifyListeners();
  }

  String _dropRateTypeValue = '';
  String get dropRateTypeValue => _dropRateTypeValue;

  set dropRateTypeValue(String value) {
    _dropRateTypeValue = value;
    notifyListeners();
  }

  set dropRateTypeValue2(String value) {
    _dropRateTypeValue = value;
    // notifyListeners();
  }

  int _page = 1;
  int get page => _page;

  set page(int value) {
    _page = value;
    notifyListeners();
  }

  List<OrderModel> _dataDisplay = [];

  List<OrderModel> get dataDisplay => _dataDisplay;

  set dataDisplay(List<OrderModel> data) {
    _dataDisplay = data;
    notifyListeners();
  }

  bool _isLoadingData = false;
  bool get isLoadingData => _isLoadingData;
  set isLoadingData(bool value) {
    _isLoadingData = value;
    notifyListeners();
  }

  int _pageTotal = 0, _totalRecords = 0;
  int get pageTotal => _pageTotal;
  int get totalRecords => _totalRecords;
  set pageTotal(int value) {
    _pageTotal = value;
    notifyListeners();
  }

  set totalRecords(int value) {
    _totalRecords = value;
    notifyListeners();
  }

  String _statement = 'SalesList';
  String get statement => _statement;
  set statement(String value) {
    _statement = value;
    notifyListeners();
  }

  List<LedgerModel> _ledgerData = [];
  List<LedgerModel> get getLedgerData => _ledgerData;
  set setLedgerData(List<LedgerModel> value) {
    _ledgerData = value;
    // notifyListeners();
  }

  Future<List<LedgerModel>> getCustomerNameList() async => await getGroupId > 1
      ? dioApi.getCustomerNameListByParent(getGroupId, 0, 0, 0)
      : dioApi.getCustomerNameList().then((value) {
          return value;
        });

  Future<void>? fetchOrder() async {
    await dioApi
        .getPaginationList(
            statement,
            page,
            getBranchId.toString(),
            salesTypeData.id.toString(),
            DateUtil.dateYMD(getDate),
            getSalesManId.toString())
        .then((value) {
      final response = value;
      pageTotal = response[1][0]['Filtered'];
      totalRecords = response[1][0]['Total'];
      page++;
      // for (int i = 0; i < response[0].length; i++) {
      //   tempList.add(response[0][i]);
      // }
      // addPhotosToList(PhotoModel.fromJson(response).photos);
      addDataToList(OrderModel.fromJsonList(response[0]));

      isLoadingData = false;
      lastRecord = response[0].isNotEmpty ? false : true;
    });
    notifyListeners();
  }

  void addDataToList(List<OrderModel> value) {
    _dataDisplay.addAll(value);
    notifyListeners();
  }

  void getMoreData() async {
    if (!_lastRecord) {
      if (_dataDisplay.isEmpty ||
          // ignore: curly_braces_in_flow_control_structures
          _dataDisplay.length < _totalRecords) if (!_isLoadingData) {
        // isLoadingData = true;
        fetchOrder();
      }
    }
  }

  bool _isData = false;
  bool get isData => _isData;
  set isData(bool value) {
    _isData = value;
    notifyListeners();
  }

  List<StockItem> _itemDisplay = [];
  List<StockItem> _items = [];

  List<StockItem> get getItemDisplay => _itemDisplay;
  List<StockItem> get getItems => _items;

  set setItemDisplay(List<StockItem> data) {
    _itemDisplay = data;
  }

  set setItems(List<StockItem> data) {
    _items = data;
  }

  late StockItem _productModel;
  StockItem get getProductModel => _productModel;
  set setProductModel(StockItem data) {
    _productModel = data;
  }

  bool _isVariantSelected = false;
  bool get getIsVariantSelected => _isVariantSelected;
  set setIsVariantSelected(bool value) {
    _isVariantSelected = value;
    notifyListeners();
  }

  int _positionID = 0;
  int get getPositionID => _positionID;
  set setPositionID(int value) {
    _positionID = value;
    notifyListeners();
  }

  String _expDate = '2000-01-01';
  String get expDate => _expDate;

  set expDate(String value) => _expDate = value;
  int _dropDownUnit = 0;
  int get dropDownUnit => _dropDownUnit;

  set dropDownUnit(int value) => _dropDownUnit = value;
  int _fUnitId = 0;
  int get fUnitId => _fUnitId;

  set fUnitId(int value) => _fUnitId = value;
  int _uniqueCode = 0;
  int get uniqueCode => _uniqueCode;

  set uniqueCode(int value) => _uniqueCode = value;
  int _barcode = 0;
  int get barcode => _barcode;

  set barcode(int value) => _barcode = value;
  bool _rateEdited = false;
  bool get rateEdited => _rateEdited;

  set rateEdited(bool value) => _rateEdited = value;

  clearValue() {
    // _quantityController.text = '';
    // _rateController.text = '';
    // _discountController.text = '';
    rateEdited = false;
    // _discountPercentController.text = '';
    taxP = 0;
    tax = 0;
    gross = 0;
    subTotal = 0;
    total = 0;
    quantity = 0;
    rate = 0;
    saleRate = 0;
    discount = 0;
    discountPercent = 0;
    rDisc = 0;
    rRate = 0;
    rateOff = 0;
    kfcP = 0;
    kfc = 0;
    unitValue = 1;
    _conversion = 0;
    free = 0;
    fUnitId = 0;
    fUnitValue = 0;
    cdPer = 0;
    cDisc = 0;
    cess = 0;
    cessPer = 0;
    adCessPer = 0;
    profitPer = 0;
    adCess = 0;
    iGST = 0;
    csGST = 0;
    pRate = 0;
    rPRate = 0;
    uniqueCode = 0;
    _dropDownUnit = 0;
    barcode = 0;
  }

  double _taxP = 0,
      _tax = 0,
      _gross = 0,
      _subTotal = 0,
      _total = 0,
      _quantity = 0,
      _rate = 0,
      _saleRate = 0,
      _discount = 0,
      _discountPercent = 0,
      _rDisc = 0,
      _rRate = 0,
      _rateOff = 0,
      _kfcP = 0,
      _kfc = 0,
      _unitValue = 1,
      _conversion = 0,
      _free = 0,
      _fUnitValue = 0,
      _cdPer = 0,
      _cDisc = 0,
      _cess = 0,
      _cessPer = 0,
      _adCessPer = 0,
      _profitPer = 0,
      _adCess = 0,
      _iGST = 0,
      _csGST = 0,
      _pRate = 0,
      _rPRate = 0;
  double get taxP => _taxP;

  set taxP(double value) => _taxP = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get tax => _tax;

  set tax(value) => _tax = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get gross => _gross;

  set gross(value) => _gross = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get subTotal => _subTotal;

  set subTotal(value) => _subTotal = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get total => _total;

  set total(value) => _total = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get quantity => _quantity;

  set quantity(value) => _quantity = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get rate => _rate;

  set rate(value) => _rate = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get saleRate => _saleRate;

  set saleRate(value) => _saleRate = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get discount => _discount;

  set discount(value) => _discount = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get discountPercent => _discountPercent;

  set discountPercent(value) => _discountPercent = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get rDisc => _rDisc;

  set rDisc(value) => _rDisc = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get rRate => _rRate;

  set rRate(value) => _rRate = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get rateOff => _rateOff;

  set rateOff(value) => _rateOff = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get kfcP => _kfcP;

  set kfcP(value) => _kfcP = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get kfc => _kfc;

  set kfc(value) => _kfc = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get unitValue => _unitValue;

  set unitValue(value) => _unitValue = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get conversion => _conversion;

  set conversion(value) => _conversion = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get free => _free;

  set free(value) => _free = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get fUnitValue => _fUnitValue;

  set fUnitValue(value) => _fUnitValue = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get cdPer => _cdPer;

  set cdPer(value) => _cdPer = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get cDisc => _cDisc;

  set cDisc(value) => _cDisc = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get cess => _cess;

  set cess(value) => _cess = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get cessPer => _cessPer;

  set cessPer(value) => _cessPer = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get adCessPer => _adCessPer;

  set adCessPer(value) => _adCessPer = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get profitPer => _profitPer;

  set profitPer(value) => _profitPer = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get adCess => _adCess;

  set adCess(value) => _adCess = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get iGST => _iGST;

  set iGST(value) => _iGST = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get csGST => _csGST;

  set csGST(value) => _csGST = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get pRate => _pRate;

  set pRate(value) => _pRate = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  get rPRate => _rPRate;

  set rPRate(value) => _rPRate = CommonService.getRound(
      _decimal, double.tryParse(value.toString()) ?? 0.0);

  setProductValues(product) {
    pRate = product.buyingPrice;
    rPRate = product.buyingPriceReal;
    isTax = taxable;
    taxP = isTax ? product.tax : 0;
    cess = isTax ? product.cess : 0;
    cessPer = isTax ? product.cessPer : 0;
    adCessPer = isTax ? product.adCessPer : 0;
    kfcP = isTax
        ? enableKeralaFloodCess
            ? kfcPer
            : 0
        : 0;
    if (salesTypeData.rateType == 'RETAIL') {
      saleRate = product.retailPrice;
    } else if (salesTypeData.rateType == 'WHOLESALE') {
      saleRate = product.wholeSalePrice;
    } else {
      saleRate = product.sellingPrice;
    }
    if (saleRate > 0 && !rateEdited) {
      rate = _conversion > 0
          ? (saleRate * _conversion).toStringAsFixed(_decimal)
          : saleRate.toStringAsFixed(_decimal);
      rate = _conversion > 0 ? saleRate * _conversion : saleRate;
    }
    _uniqueCode = product.productId;
    List<UnitModel> unitList = [];
  }

  calculate(product, _quantityController, _rateController, _discountController,
      _discountPercentController) {
    if (enableMULTIUNIT) {
      if (saleRate > 0) {
        if (_conversion > 0) {
          //var r = 0.0;
          if (rateEdited) {
            rate = double.tryParse(_rateController);
          } else {
            //r = (saleRate * _conversion);
            rate = saleRate * _conversion;
            // _rateController.text = rate.toStringAsFixed(decimal);
          }
          //rate = r;
          // _rateController.text = r.toStringAsFixed(decimal);
          pRate = product.buyingPrice * _conversion;
          rPRate = product.buyingPriceReal * _conversion;
        } else {
          rate = _rateController.isNotEmpty
              ? (double.tryParse(_rateController))
              : 0;
        }
      } else {
        rate =
            _rateController.isNotEmpty ? (double.tryParse(_rateController)) : 0;
      }
    } else {
      if (rateEdited) {
        rate = double.tryParse(_rateController);
      } else if (saleRate > 0) {
        // _rateController.text = saleRate.toStringAsFixed(decimal);
        rate = saleRate;
      } else {
        rate =
            _rateController.isNotEmpty ? double.tryParse(_rateController) : 0;
      }
    }
    quantity = _quantityController.isNotEmpty
        ? double.tryParse(_quantityController)
        : 0;
    rRate = taxMethod == 'MINUS'
        ? cessOnNetAmount
            ? CommonService.getRound(
                4, (100 * rate) / (100 + taxP + kfcP + cessPer))
            : CommonService.getRound(4, (100 * rate) / (100 + taxP + kfcP))
        : rate;
    discount = _discountController.isNotEmpty
        ? double.tryParse(_discountController)
        : 0;
    double discP = _discountPercentController.isNotEmpty
        ? double.tryParse(_discountPercentController) ?? 0
        : 0;
    double qt = _quantityController.isNotEmpty
        ? double.tryParse(_quantityController) ?? 0
        : 0;
    double sRate =
        _rateController.isNotEmpty ? double.tryParse(_rateController) ?? 0 : 0;
    // _discountController.text = _discountPercentController.isNotEmpty
    //     ? (((qt * sRate) * discP) / 100).toStringAsFixed(decimal)
    //     : '';
    discountPercent = _discountPercentController.isNotEmpty
        ? double.tryParse(_discountPercentController)
        : 0;
    discount =
        discountPercent > 0 ? double.tryParse(_discountController) : discount;
    rDisc = taxMethod == 'MINUS'
        ? CommonService.getRound(4, ((discount * 100) / (taxP + 100)))
        : discount;
    gross = CommonService.getRound(decimal, ((rRate * quantity)));
    subTotal = CommonService.getRound(decimal, (gross - rDisc));
    if (taxP > 0) {
      tax = CommonService.getRound(decimal, ((subTotal * taxP) / 100));
    }
    if (companyTaxMode == 'INDIA') {
      kfc = isKFC
          ? CommonService.getRound(decimal, ((subTotal * kfcP) / 100))
          : 0;
      double csPer = taxP / 2;
      iGST = 0;
      csGST = CommonService.getRound(decimal, ((subTotal * csPer) / 100));
    } else if (companyTaxMode == 'GULF') {
      iGST = CommonService.getRound(decimal, ((subTotal * taxP) / 100));
      csGST = 0;
      kfc = 0;
    } else {
      iGST = 0;
      csGST = 0;
      kfc = 0;
      tax = 0;
    }
    if (cessOnNetAmount) {
      if (cessPer > 0) {
        cess = CommonService.getRound(decimal, ((subTotal * cessPer) / 100));
        adCess = CommonService.getRound(decimal, (quantity * adCessPer));
      } else {
        cess = 0;
        adCess = 0;
      }
    } else {
      cess = 0;
      adCess = 0;
    }
    total = CommonService.getRound(
        2, (subTotal + csGST + csGST + iGST + cess + kfc + adCess));
    if (enableMULTIUNIT && _conversion > 0) {
      profitPer = pRateBasedProfitInSales
          ? CommonService.getRound(
              2, (total - (product.buyingPrice * _conversion * quantity)))
          : CommonService.getRound(decimal,
              (total - (product.buyingPriceReal * _conversion * quantity)));
    } else {
      profitPer = pRateBasedProfitInSales
          ? CommonService.getRound(
              2, (total - (product.buyingPrice * quantity)))
          : CommonService.getRound(
              2, (total - (product.buyingPriceReal * quantity)));
    }
    unitValue = _conversion > 0 ? _conversion : 1;
    notifyListeners();
  }
}

class OrderModel {
  int id;
  String name;
  String date;
  double total;
  OrderModel({
    required this.id,
    required this.name,
    required this.date,
    required this.total,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
      id: int.tryParse(json['Id'].toString()) ?? 0,
      name: json['Name'] ?? '',
      date: json['Date'] ?? '',
      total: double.tryParse(json['Total'].toString()) ?? 0);

  static List<OrderModel> fromJsonList(List list) {
    return list.map((item) => OrderModel.fromJson(item)).toList();
  }
}
