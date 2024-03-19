// @dart = 2.11
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:pdf/widgets.dart';

import 'package:sheraccerp/app_settings_page.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/company_user.dart';
import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/form_model.dart';
import 'package:sheraccerp/models/option_rate_type.dart';
import 'package:sheraccerp/models/other_registrations.dart';
import 'package:sheraccerp/models/print_settings_model.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/models/sms_data_model.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/models/voucher_type_model.dart';
import 'package:sheraccerp/screens/accounts/ledger.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/util/dateUtil.dart';

const gstBaseApi = "https://api.mastergst.com";
const gstApi = "https://api.mastergst.com/einvoice/authenticate"; //get
const gstAuthApi = "/einvoice/authenticate"; //get
const gstDetailsApi = "/einvoice/type/GSTNDETAILS/version/V1_03"; //get
const gstSyncCpApi = "/einvoice/type/SYNC_GSTIN_FROMCP/version/V1_03"; //get
const gstIrnApi = "/einvoice/type/GENERATE/version/V1_03"; //post
const gstEInvDetailsApi = "/einvoice/type/GETIRN/version/V1_03"; //get
const gstIrnByDocApi = "/einvoice/type/GETIRNBYDOCDETAILS/version/V1_03"; //get
const gstCancelIrnApi = "/einvoice/type/CANCEL/version/V1_03"; //post
const gstEWayBillApi = "/einvoice/type/GENERATE_EWAYBILL/version/V1_03"; //post
const gstEWayDetailsByIrnApi =
    "/einvoice/type/GETEWAYBILLIRN/version/V1_03"; //get
const gstB2BQRDetailsApi = "/einvoice/qrcode";
const invoiceUrl = 'http://148.72.210.101:888/Home/DownloadPdf';
const geoApiFy =
    'https://api.geoapify.com/v1/geocode/search?text=pin&lang=en&limit=1&type=postcode&format=json&apiKey=d1f13eb6d5b04bcdbe6cfdad0d01cbaa';
const eWayAuthApi = "/ewaybillapi/v1.03/authenticate";
const eWayBillApi = "/ewayapi/genewaybill";
const eWayBillCancelApi = "/ewaybillapi/v1.03/ewayapi/canewb";
//05AAACH6188F1ZM
//mastergst	Malli#123	29AABCT1332L000

bool isDarkTheme = false;
bool isUsingHive = true;
String deviceId = '0';
const String isApp = '1';
const softwarePassword = 'SHERSOFT';
String _sherSoftPassword = '';
get sherSoftPassword => _sherSoftPassword;
set sherSoftPassword(String value) => _sherSoftPassword = value;

const String apiV = 'v22/';

const currencySymbol = '₹';
// const bool isVariant = false;
const bool isKFC = false;
const double kfcPer = 0;
int defaultUnitID =
    Settings.getValue<int>('key-dropdown-item-default-sku-view', 0);
String defaultLocation = 'SHOP';
const bool isArea = false;
const bool isRoute = false;
bool isEstimateDataBase = false;
String userNameC = 'ADMIN';
CompanyUser companyUserData;
FinancialYear currentFinancialYear;
List<FormModel> userControlData = [];
int userIdC = 1;
String _toDay;
String get getToDay => _toDay;
set setToDay(String day) => _toDay = day;
CustomerModel tempLedgerData;

List<UnitModel> unitData = [];
List unitList = [];
List locationList = [];
List areaList = [];
List salesmanList = [];
List groupList = [];
List routeList = [];
List brandList = [];
List categoryList = [];
List mfrList = [];
List modelList = [];
List subCategoryList = [];
List<SalesType> salesTypeList = [];
List<VoucherType> voucherTypeList = [];
List otherRegistrationList = [];
List<OtherRegistrationModel> otherRegUnitList = [];
List<OtherRegistrationModel> otherRegLocationList = [];
List<OtherRegistrationModel> otherRegAreaList = [];
List<OtherRegistrationModel> otherRegRouteList = [];
List<OptionRateType> optionRateTypeList = [];
List<PrintSettingsModel> printSettingsList = [];
List<SmsDataModel> smsSettingsList = [];
List otherRegSalesManList = [];
List mainAccount = [];
List cashAccount = [];
List<String> taxCalculationList = ['MINUS', 'PLUS'];
DioService dioApi = DioService();

String rateType = '';
// String unitType = '';
String userRole = '';
String saleAccount = '';
String taxMethod = '';
String companyTaxMode = '';
List<dynamic> dataDynamic = [];
var argumentsPass;
Uint8List byteImageQr;
const List<String> stockValuationData = [
  'AVERAGE VALUE',
  'LAST PRATE',
  'REAL',
  'MRP CHANGE'
];
const List<String> typeOfSupplyData = ['GOODS', 'SERVICE'];
const List<String> rateTypeData = [
  'MRP',
  'RETAIL',
  'SPRETAIL',
  'WHOLESALE',
  'BRANCH'
];

List<DataJson> rateTypeModelData = [
  DataJson(id: 0, name: ''),
  DataJson(id: 1, name: 'MRP'),
  DataJson(id: 2, name: 'RETAIL'),
  DataJson(id: 3, name: 'SPRETAIL'),
  DataJson(id: 4, name: 'WHOLESALE'),
  DataJson(id: 5, name: 'BRANCH')
];

class ComSettings {
  fetchOtherData() {
    DioService api = DioService();
    api.fetchUnitList(0).then((value) {
      unitData = value;
      if (unitList.isEmpty) {
        unitList.add(AppSettingsMap(key: 1, value: ''));
      }
      for (var data in unitData) {
        var exist = unitList.firstWhere((element) => element.value == data.name,
            orElse: () => null);
        if (exist == null) {
          unitList.add(AppSettingsMap(key: data.id, value: data.name));
        }
      }
    });
    api.getSalesTypeList().then((value) {
      salesTypeList.addAll(value);
    });

    api.getVoucherTypeList().then((value) {
      voucherTypeList.addAll(value);
    });

    api.fetchOtherRegList().then((value) {
      if (value != null && value.isNotEmpty) {
        otherRegistrationList = value;
        Map<String, dynamic> map = value[0];
        if (map['location'].length > 0) {
          if (map['location'][0]['Auto'] == 1) {
            locationList.add(AppSettingsMap(key: 0, value: ''));
          } else {
            locationList.add(AppSettingsMap(key: 1, value: ''));
          }
        }
        for (var json in map['location']) {
          otherRegLocationList.add(OtherRegistrationModel.fromJson(json));
          locationList
              .add(AppSettingsMap(key: json['auto'], value: json['Name']));
        }
        for (var json in map['unit']) {
          otherRegUnitList.add(OtherRegistrationModel.fromJson(json));
        }
        if (map['area'].length > 0) {
          if (map['area'][0]['Auto'] == 1) {
            areaList.add(AppSettingsMap(key: 0, value: ''));
          } else {
            areaList.add(AppSettingsMap(key: 1, value: ''));
          }
        }
        for (var json in map['area']) {
          otherRegAreaList.add(OtherRegistrationModel.fromJson(json));
          otherRegAreaList.sort((a, b) => a.name.compareTo(b.name));
          areaList.add(AppSettingsMap(key: json['auto'], value: json['Name']));
        }
        if (map['salesMan'].length > 0) {
          if (map['salesMan'][0]['Auto'] == 1) {
            salesmanList.add(AppSettingsMap(key: 0, value: ''));
          } else {
            salesmanList.add(AppSettingsMap(key: 1, value: ''));
          }
        }
        for (var json in map['salesMan']) {
          otherRegSalesManList.add(json);
          salesmanList
              .add(AppSettingsMap(key: json['Auto'], value: json['Name']));
        }
        if (map['route'].length > 0) {
          if (map['route'][0]['Auto'] == 1) {
            routeList.add(AppSettingsMap(key: 0, value: ''));
          } else {
            routeList.add(AppSettingsMap(key: 1, value: ''));
          }
        }
        for (var json in map['route']) {
          otherRegRouteList.add(OtherRegistrationModel.fromJson(json));
          otherRegRouteList.sort((a, b) => a.name.compareTo(b.name));
          routeList.add(AppSettingsMap(key: json['auto'], value: json['Name']));
        }
        if (map['brand'].length > 0) {
          if (map['brand'][0]['Auto'] == 1) {
            brandList.add(AppSettingsMap(key: 0, value: ''));
          } else {
            brandList.add(AppSettingsMap(key: 1, value: ''));
          }
        }
        for (var json in map['brand']) {
          brandList.add(AppSettingsMap(key: json['auto'], value: json['Name']));
        }
        if (map['category'].length > 0) {
          if (map['category'][0]['Auto'] == 1) {
            categoryList.add(AppSettingsMap(key: 0, value: ''));
          } else {
            categoryList.add(AppSettingsMap(key: 1, value: ''));
          }
        }
        for (var json in map['category']) {
          categoryList
              .add(AppSettingsMap(key: json['auto'], value: json['Name']));
        }
        if (map['mfr'].length > 0) {
          if (map['mfr'][0]['Auto'] == 1) {
            mfrList.add(AppSettingsMap(key: 0, value: ''));
          } else {
            mfrList.add(AppSettingsMap(key: 1, value: ''));
          }
        }
        for (var json in map['mfr']) {
          mfrList.add(AppSettingsMap(key: json['auto'], value: json['Name']));
        }
        if (map['model'].length > 0) {
          if (map['model'][0]['Auto'] == 1) {
            modelList.add(AppSettingsMap(key: 0, value: ''));
          } else {
            modelList.add(AppSettingsMap(key: 1, value: ''));
          }
        }
        for (var json in map['model']) {
          modelList.add(AppSettingsMap(key: json['auto'], value: json['Name']));
        }
        if (map['sub_category'].length > 0) {
          if (map['sub_category'][0]['Auto'] == 1) {
            subCategoryList.add(AppSettingsMap(key: 0, value: ''));
          } else {
            subCategoryList.add(AppSettingsMap(key: 1, value: ''));
          }
        }
        for (var json in map['sub_category']) {
          subCategoryList
              .add(AppSettingsMap(key: json['auto'], value: json['Name']));
        }
      }
    });

    api.getMainAccount().then((value) {
      mainAccount.addAll(value);
      cashAccount = [];
      if (mainAccount.isNotEmpty) {
        cashAccount.add(AppSettingsMap(key: 1, value: ''));
      }
      for (var element in mainAccount) {
        if (element['lh_name'] == 'CASH IN HAND') {
          cashAccount.add(AppSettingsMap(
              key: element['LedCode'], value: element['LedName']));
        }
      }
    });

    api.getMainHead().then((value) {
      groupList = [];
      if (value.isNotEmpty) {
        groupList.add(AppSettingsMap(key: 1, value: ''));
      }
      for (var element in value) {
        groupList.add(
            AppSettingsMap(key: element['ledCode'], value: element['LedName']));
      }
    });

    api.getRateTypeList().then((value) {
      if (value.isNotEmpty) {
        optionRateTypeList = [];
        optionRateTypeList.addAll(value);
      }
    });

    api.getPrintSettings().then((value) {
      if (value.isNotEmpty) {
        printSettingsList = [];
        printSettingsList.addAll(value);
      }
    });

    api.getSMSApiDataList().then((value) => smsSettingsList.addAll(value));
  }

  static getStatus(String name, List<CompanySettings> data) {
    bool status = false;
    for (var option in data) {
      //s_Value,Status,Name
      if (option.name == name) {
        status = option.status == 1 ? true : false;
        break;
      } else {
        status = false;
      }
    }
    return status;
  }

  static getValue(String name, List<CompanySettings> data) {
    String status = '';
    for (var option in data) {
      //s_Value,Status,Name
      if (option.name == name) {
        status = option.value;
        break;
      } else {
        status = '';
      }
    }
    return status;
  }

  static getReportDesignStatus(String name, List<ReportDesign> data) {
    bool status = false;
    for (var option in data) {
      //s_Value,Status,Name
      if (option.visibility == name) {
        status = option.visibility;
        break;
      } else {
        status = false;
      }
    }
    return status;
  }

  static getReportDesignValue(String name, List<ReportDesign> data) {
    String status = '';
    for (var option in data) {
      //s_Value,Status,Name
      if (option.caption == name) {
        status = option.caption;
        break;
      } else {
        status = '';
      }
    }
    return status;
  }

  static oKNumeric(String result) {
    if (result == null) {
      return false;
    }
    return double.tryParse(result) != null;
  }

  static getIfInteger(String value) {
    try {
      String v;
      var patter = value.split(".");
      if (int.tryParse(patter[1]) > 0) {
        v = value;
      } else {
        v = int.tryParse(patter[0]).toString();
      }
      return v;
    } catch (e) {
      return value;
    }
  }

  static selectSalesType(String id) {
    bool status;
    for (var option in salesTypeList) {
      if (option.id.toString() == id) {
        salesTypeData = option;
        status = true;
        break;
      } else {
        status = false;
      }
    }
    return status;
  }

  static appSettings(T, cacheKey, defaultValue) {
    switch (T) {
      case 'String':
        return Settings.getValue<String>(cacheKey, defaultValue);
        break;
      case 'bool':
        return Settings.getValue<bool>(cacheKey, defaultValue);
        break;
      case 'int':
        return Settings.getValue<int>(cacheKey, defaultValue);
        break;
      case 'double':
        return Settings.getValue<double>(cacheKey, defaultValue);
        break;
      case 'Object':
        return Settings.getValue<Object>(cacheKey, defaultValue);
        break;
    }
  }

  static rateTypeSlot(type) {
    switch (type) {
      case 'MRP':
        return 1;
        break;
      case 'RETAIL':
        return 2;
        break;
      case 'SPRETAIL':
        return 3;
        break;
      case 'WHOLESALE':
        return 4;
        break;
      case 'BRANCH':
        return 5;
        break;
      default:
        return 4;
    }
  }

  static salesFormList(cacheKey, defaultValue) {
    List<SalesType> sTypeList = [];
    for (var option in salesTypeList) {
      if (appSettings('bool', cacheKey + option.id.toString(), defaultValue)) {
        sTypeList.add(option);
      }
    }
    return sTypeList;
  }

  static salesRateTypeList(cacheKey, defaultValue) {
    List<OptionRateType> rateTypeList = [];
    for (var option in optionRateTypeList) {
      if (appSettings('bool', cacheKey + option.id.toString(), defaultValue)) {
        rateTypeList.add(option);
      }
    }
    return rateTypeList;
  }

  static userControl(String name) {
    int result;
    if (userControlData.isNotEmpty) {
      bool status = userControlData
          .firstWhere(
            (element) => element.title == name.toUpperCase(),
            orElse: () => FormModel(id: 0, title: name, isChecked: false),
          )
          .isChecked;
      if (status) {
        result = 1;
      } else {
        result = 0;
      }
    } else {
      result = -1;
    }
    return result < 0
        ? false
        // ? name == 'RECEIPTX' || name == 'PAYMENTX'
        //     ? true
        //     : false
        : result == 1
            ? true
            : false;
  }

  static billLineValue(int d) {
    int result = 0;
    result = d - 1;
    printLines = result;
    return result;
  }

  static String removeZero(double money) {
    var response = money.toString();

    if (money.toString().split(".").isNotEmpty) {
      var decimalPoint = money.toString().split(".")[1];
      if (decimalPoint == "0") {
        response = response.split(".0").join("");
      }
      if (decimalPoint == "00") {
        response = response.split(".00").join("");
      }
    }

    return response;
  }

  static String removeInvDesignFilePath(String filePath) {
    List<String> splits = filePath.split('.');
    return splits[0]
            .replaceAll('D:', '')
            .replaceAll(RegExp('[^A-Za-z0-9]'), '.')
            .replaceAll(".SherAcc.INVOICE.", '')
            .replaceAll(".", '_')
            .replaceAll('_SherAcc_Invoice_', '') +
        '.' +
        splits[1];
  }
}

Document documentPDF;
int printLines;

class UnitSettings {
  static getUnitName(int id) {
    String name = '';
    if (unitList.isNotEmpty) {
      var exist = unitList.firstWhere((element) => element.key == id,
          orElse: () => null);
      if (exist != null) {
        name = exist.value;
      }
    }
    return name;
  }

  static getUnitId(String name) {
    int id = 0;
    if (unitList.isNotEmpty) {
      var exist = unitList.firstWhere((element) => element.name == name,
          orElse: () => null);
      if (exist != null) {
        id = exist.id;
      }
    }
    return id;
  }

  static getUnitListItemValue(int itemID, String type) {
    Object value;
    //{"PUnit":3,"SUnit":2,"Unit":3,"ItemId":4,"Conversion":30,"name":"BOX","auto":3}
    if (unitData.isNotEmpty) {
      var data = unitData.firstWhere((element) => element.itemId == itemID,
          orElse: () => null);
      if (data != null) {
        if (type == 'PUnit') {
          value = data.pUnit;
        } else if (type == 'SUnit') {
          value = data.sUnit;
        } else if (type == 'Unit') {
          value = data.unit;
        } else if (type == 'Conversion') {
          value = data.conversion;
        } else if (type == 'name') {
          value = data.name;
        } else if (type == 'auto') {
          value = data.id;
        }
      } else {
        value = '';
      }
    }
    return value;
  }
}

class ScreenConfig {
  static double deviceWidth;
  static double deviceHeight;
  static double designHeight = 1300;
  static double designWidth = 600;
  static init(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;
  }

  // Designer user 1300 device height,
  // so I have to normalize to the device height
  static double getProportionalHeight(height) {
    return (height / designHeight) * deviceHeight;
  }

  static double getProportionalWidth(width) {
    return (width / designWidth) * deviceWidth;
  }
}

// Colors
const iPrimarryColor = Color(0xFFF9FCFF);
const iAccentColor = Color(0xFFFFB44B);
const iAccentColor2 = Color(0xFFFFEAC9);

const demoData = [
  {
    "imagePath": "assets/logo1.png",
    "price": 5,
    "quantity": 2,
    "itemDesc": "Gingerbread Cake with orange cream chees"
  },
  {
    "imagePath": "assets/logo1.png",
    "price": 10,
    "quantity": 4,
    "itemDesc": "Sauteed Onion and Hotdog with Ketchup"
  },
  {
    "imagePath": "assets/logo1.png",
    "price": 14,
    "quantity": 1,
    "itemDesc": "Supreme Pizza Recipe"
  }
];

class SaudiConversion {
  static String getBase64(String sellerName, String vatRegistration,
      String timeStamp, String invoiceAmount, String taxAmount) {
    BytesBuilder bytesBuilder = BytesBuilder();
    getByteValue(bytesBuilder, 1, sellerName);
    getByteValue(bytesBuilder, 2, vatRegistration);
    getByteValue(bytesBuilder, 3, timeStamp);
    getByteValue(bytesBuilder, 4, invoiceAmount);
    getByteValue(bytesBuilder, 5, taxAmount);
    Uint8List qrCodeBytes = bytesBuilder.toBytes();
    const Base64Encoder base64Encoder = Base64Encoder();
    return base64Encoder.convert(qrCodeBytes);
  }

  static void getByteValue(
      BytesBuilder bytesBuilder, int tagnums, String tagValue) {
    bytesBuilder.addByte(tagnums);
    List<int> valueByte = utf8.encode(tagValue);
    bytesBuilder.addByte(valueByte.length);
    bytesBuilder.add(valueByte);
  }
}

List<GSTStateModel> gstStateModels = [
  GSTStateModel(state: "", code: ""),
  GSTStateModel(state: "JAMMU AND KASHMIR", code: "01"),
  GSTStateModel(state: "HIMACHAL PRADESH", code: "02"),
  GSTStateModel(state: "PUNJAB", code: "03"),
  GSTStateModel(state: "CHANDIGARH", code: "04"),
  GSTStateModel(state: "UTTARAKHAND", code: "05"),
  GSTStateModel(state: "HARYANA", code: "06"),
  GSTStateModel(state: "DELHI", code: "07"),
  GSTStateModel(state: "RAJASTHAN", code: "08"),
  GSTStateModel(state: "UTTAR PRADESH", code: "09"),
  GSTStateModel(state: "BIHAR", code: "10"),
  GSTStateModel(state: "SIKKIM", code: "11"),
  GSTStateModel(state: "ARUNACHAL PRADESH", code: "12"),
  GSTStateModel(state: "NAGALAND", code: "13"),
  GSTStateModel(state: "MANIPUR", code: "14"),
  GSTStateModel(state: "MIZORAM", code: "15"),
  GSTStateModel(state: "TRIPURA", code: "16"),
  GSTStateModel(state: "MEGHALAYA", code: "17"),
  GSTStateModel(state: "ASSAM", code: "18"),
  GSTStateModel(state: "WEST BENGAL", code: "19"),
  GSTStateModel(state: "JHARKHAND", code: "20"),
  GSTStateModel(state: "ODISHA", code: "21"),
  GSTStateModel(state: "CHATTISGARH", code: "22"),
  GSTStateModel(state: "MADHYA PRADESH", code: "23"),
  GSTStateModel(state: "GUJARAT", code: "24"),
  GSTStateModel(
      state: "DADRA AND NAGAR HAVELI AND DAMAN AND DIU (NEWLY MERGED UT)",
      code: "26"),
  GSTStateModel(state: "MAHARASHTRA", code: "27"),
  GSTStateModel(state: "ANDHRA PRADESH (BEFORE DIVISION)", code: "28"),
  GSTStateModel(state: "KARNATAKA", code: "29"),
  GSTStateModel(state: "GOA", code: "30"),
  GSTStateModel(state: "LAKSHADWEEP", code: "31"),
  GSTStateModel(state: "KERALA", code: "32"),
  GSTStateModel(state: "TAMIL NADU", code: "33"),
  GSTStateModel(state: "PUDUCHERRY", code: "34"),
  GSTStateModel(state: "ANDAMAN AND NICOBAR ISLANDS", code: "35"),
  GSTStateModel(state: "TELANGANA", code: "36"),
  GSTStateModel(state: "ANDHRA PRADESH (NEWLY ADDED)", code: "37"),
  GSTStateModel(state: "LADAKH(NEWLY ADDED)", code: "38"),
  GSTStateModel(state: "OTHER TERRITORY", code: "97"),
  GSTStateModel(state: "CENTRE JURISDICTION", code: "99")
];

class GSTStateModel {
  String state;
  String code;
  GSTStateModel({
    this.state,
    this.code,
  });

  Map<String, dynamic> toMap() {
    return {
      'state': state,
      'code': code,
    };
  }

  factory GSTStateModel.fromMap(Map<String, dynamic> map) {
    return GSTStateModel(
      state: map['state'] ?? '',
      code: map['code'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory GSTStateModel.fromJson(String source) =>
      GSTStateModel.fromMap(json.decode(source));
}

bool checkFinancialYear(String date) {
  bool status = false;
  if (currentFinancialYear.status == 1) {
    DateTime startDate = DateTime.parse(DateFormat('yyyy-MM-dd')
        .format(DateTime.parse(currentFinancialYear.startDate)));
    DateTime endDate = DateTime.parse(DateFormat('yyyy-MM-dd')
        .format(DateTime.parse(currentFinancialYear.endDate)));
    DateTime currentDate =
        DateTime.parse(DateFormat('yyyy-MM-dd').format(DateTime.parse(date)));
    status = DateUtil.checkYearDate(
        startDate: startDate, endDate: endDate, currentDate: currentDate);
    var startDateX = (currentFinancialYear.startDate);
    var endDateX = (currentFinancialYear.endDate);
  }
  return status;
}

List<dynamic> tempCustomerData = [];
