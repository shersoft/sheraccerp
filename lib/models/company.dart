// @dart = 2.11
import 'dart:convert';

class Company {
  String registrationId;
  String code;
  String companyName;
  String dBName;
  String dBNameT;
  String active;
  String username;
  String password;
  String customerCode;

  Company(
      {this.registrationId,
      this.code,
      this.companyName,
      this.dBName,
      this.dBNameT,
      this.active,
      this.username,
      this.password,
      this.customerCode});

  // String get registrationId => _registrationId;
  // set registrationId(String registrationId) => _registrationId = registrationId;
  // String get companyName => _companyName;
  // set companyName(String companyName) => _companyName = companyName;
  // String get dBName => _dBName;
  // String get dBNameT => _dBNameT;
  // set dBName(String dBName) => _dBName = dBName;
  // set dBNameT(String dBNameT) => _dBNameT = dBNameT;
  // String get active => _active;
  // set active(String active) => _active = active;
  // String get username => _username;
  // set username(String username) => _username = username;
  // String get password => _password;
  // set password(String password) => _password = password;
  // String get customerCode => _customerCode;
  // set customerCode(String customerCode) => _customerCode = customerCode;
  // Company.fromList(List<Company> json) {
  //   final List<Company> items =
  //       json.map((item) => Company.fromJson(item)).toList().cast<Company>();
  //   return items;
  // }

  factory Company.fromJson(Map<String, dynamic> dataJson) => Company(
      registrationId: dataJson['RegistrationId'].toString(),
      code: dataJson['Code'],
      companyName: dataJson['CompanyName'],
      dBName: dataJson['DBName'],
      dBNameT: dataJson['DBNameT'],
      active: dataJson['Active'].toString(),
      username: dataJson['UserName'],
      password: dataJson['Password'],
      customerCode: dataJson['CustomerCode']);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['RegistrationId'] = registrationId;
    data['Code'] = code;
    data['CompanyName'] = companyName;
    data['DBName'] = dBName;
    data['DBNameT'] = dBNameT;
    data['Active'] = active;
    data['UserName'] = username;
    data['Password'] = password;
    data['CustomerCode'] = customerCode;
    return data;
  }
}

class FirmModel {
  String id;
  String code;
  String name;
  String sYear;
  String eYear;
  String dbName;
  String dbNameT;

  FirmModel(
      {this.id,
      this.code,
      this.name,
      this.sYear,
      this.eYear,
      this.dbName,
      this.dbNameT});

  factory FirmModel.fromJson(Map<String, dynamic> dataJson) => FirmModel(
      id: dataJson['Id'].toString(),
      code: dataJson['Code'].toString(),
      name: dataJson['Name'].toString(),
      sYear: dataJson['SYear'].toString(),
      eYear: dataJson['EYear'].toString(),
      dbName: dataJson['DBName'].toString(),
      dbNameT: dataJson['DBNameT'].toString());
}

class CompanyInformation {
  String name;
  String add1;
  String add2;
  String add3;
  String add4;
  String add5;
  String sName;
  String telephone;
  String email;
  String mobile;
  String tin;
  String pin;
  String taxCalculation;
  String sCurrency;
  String sDate;
  String eDate;
  String customerCode;
  String runningDate;
  CompanyInformation({
    this.name,
    this.add1,
    this.add2,
    this.add3,
    this.add4,
    this.add5,
    this.sName,
    this.telephone,
    this.email,
    this.mobile,
    this.tin,
    this.pin,
    this.taxCalculation,
    this.sCurrency,
    this.sDate,
    this.eDate,
    this.customerCode,
    this.runningDate,
  });

  factory CompanyInformation.fromJson(Map<String, dynamic> dataJson) =>
      CompanyInformation(
        name: dataJson['name'] ?? '',
        add1: dataJson['add1'] ?? '',
        add2: dataJson['add2'] ?? '',
        add3: dataJson['add3'] ?? '',
        add4: dataJson['add4'] ?? '',
        add5: dataJson['add5'] ?? '',
        sName: dataJson['Sname'] ?? 'SHERACC',
        telephone: dataJson['telephone'] ?? '',
        email: dataJson['email'] ?? '',
        mobile: dataJson['mobile'] ?? '',
        tin: dataJson['tin'] ?? '',
        pin: dataJson['pin'] ?? '',
        taxCalculation: dataJson['TaxCalculation'] ?? 'MINUS',
        sCurrency: dataJson['s_currency'] ?? '',
        sDate: dataJson['sDate'] ?? '',
        eDate: dataJson['eDate'] ?? '',
        customerCode: dataJson['customerCode'] ?? '',
        runningDate: dataJson['insDate'] ?? '',
      );

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'add1': add1,
      'add2': add2,
      'add3': add3,
      'add4': add4,
      'add5': add5,
      'sName': sName,
      'telephone': telephone,
      'email': email,
      'mobile': mobile,
      'tin': tin,
      'pin': pin,
      'taxCalculation': taxCalculation,
      'sCurrency': sCurrency,
      'sDate': sDate,
      'eDate': eDate,
      'customerCode': customerCode,
      'runningDate': runningDate,
    };
  }

  String toJson() => json.encode(toMap());

  factory CompanyInformation.fromMap(Map<String, dynamic> map) {
    return CompanyInformation(
      name: map['name'] ?? '',
      add1: map['add1'] ?? '',
      add2: map['add2'] ?? '',
      add3: map['add3'] ?? '',
      add4: map['add4'] ?? '',
      add5: map['add5'] ?? '',
      sName: map['sName'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      mobile: map['mobile'] ?? '',
      tin: map['tin'] ?? '',
      pin: map['pin'] ?? '',
      taxCalculation: map['taxCalculation'] ?? '',
      sCurrency: map['sCurrency'] ?? '',
      sDate: map['sDate'] ?? '',
      eDate: map['eDate'] ?? '',
      customerCode: map['customerCode'] ?? '',
      runningDate: map['runningDate'] ?? '',
    );
  }
}

class CompanySettings {
  String name;
  String value;
  int status;
  CompanySettings({
    this.name,
    this.value,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'value': value,
      'status': status,
    };
  }

  String toJson() => json.encode(toMap());

  factory CompanySettings.fromJson(Map<String, dynamic> map) {
    return CompanySettings(
      name: map['Name'] ?? '',
      value: map['s_Value'] ?? '',
      status: map['Status']?.toInt() ?? 0,
    );
  }

  String companyInformationToMap(List<CompanySettings> data) =>
      json.encode(List<dynamic>.from(data.map((x) => x.toMap())));
}

class FinancialYear {
  int id;
  String startDate;
  String endDate;
  String narration;
  int createdUser;
  String createdDate;
  int status;
  FinancialYear({
    this.id,
    this.startDate,
    this.endDate,
    this.narration,
    this.createdUser,
    this.createdDate,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate,
      'endDate': endDate,
      'narration': narration,
      'createdUser': createdUser,
      'createdDate': createdDate,
      'status': status,
    };
  }

  String toJson() => json.encode(toMap());

  factory FinancialYear.fromJson(Map<String, dynamic> map) {
    return FinancialYear(
      id: map['FyId']?.toInt() ?? 0,
      startDate: map['FromDate'] ?? '',
      endDate: map['ToDate'] ?? '',
      narration: map['Narration'] ?? '',
      createdUser: map['CreatedUser']?.toInt() ?? 0,
      createdDate: map['CreatedDate'] ?? '',
      status: map['Status']?.toInt() ?? 0,
    );
  }

  String financialYearToMap(List<FinancialYear> data) =>
      json.encode(List<dynamic>.from(data.map((x) => x.toMap())));
}
