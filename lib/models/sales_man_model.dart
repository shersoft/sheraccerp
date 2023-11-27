// @dart = 2.11
class SalesManModel {
  int id;
  String name, empCode, employeeSection;
  double salary;
  bool active;

  SalesManModel(
      {this.id,
      this.name,
      this.empCode,
      this.employeeSection,
      this.salary,
      this.active});

  factory SalesManModel.fromJson(Map<String, dynamic> json) {
    return SalesManModel(
      id: json['Auto'],
      name: json['name'],
      empCode: json['emp_code'],
      employeeSection: json['EmployeeSection'],
      salary: json['Salary'].toDouble(),
      active: json['Active'] == 1 ? true : false,
    );
  }

  static emptyData() {
    return SalesManModel(
        active: true,
        empCode: '0',
        employeeSection: '',
        id: 0,
        name: '',
        salary: 0);
  }
}

class EmployeeModel {
  String name;
  String address1;
  String address2;
  String address3;
  String telephone;
  String mobile;
  String date;
  bool activate;
  double salary;
  int auto;
  double ot;
  double dailyAllowance;
  double liveDeduction;
  double total;
  String employeeSection;
  double casualLeave;
  double tickEligibility;
  String commissionStatus;
  String type;
  double commissionPercentage;
  String min;
  String empCode;
  String empId;
  String gender;
  String workingHour;
  double vehicleCommission;
  double loadingCharge;
  String mode;
  int lunchMin;
  int otHour;
  String sms;
  double esi;
  double pf;
  int active;
  int att;
  String expiryDate;
  String expiryDateArabic;
  String baladiyaExpiryDate;
  String passportExpiryDate;
  int location;
  int ledCode;

  EmployeeModel({
    this.name,
    this.address1,
    this.address2,
    this.address3,
    this.telephone,
    this.mobile,
    this.date,
    this.activate,
    this.salary,
    this.auto,
    this.ot,
    this.dailyAllowance,
    this.liveDeduction,
    this.total,
    this.employeeSection,
    this.casualLeave,
    this.tickEligibility,
    this.commissionStatus,
    this.type,
    this.commissionPercentage,
    this.min,
    this.empCode,
    this.empId,
    this.gender,
    this.workingHour,
    this.vehicleCommission,
    this.loadingCharge,
    this.mode,
    this.lunchMin,
    this.otHour,
    this.sms,
    this.esi,
    this.pf,
    this.active,
    this.att,
    this.expiryDate,
    this.expiryDateArabic,
    this.baladiyaExpiryDate,
    this.passportExpiryDate,
    this.location,
    this.ledCode,
  });

  factory EmployeeModel.fromMap(Map<String, dynamic> json) => EmployeeModel(
        name: json["Name"],
        address1: json["Address1"],
        address2: json["address2"],
        address3: json["address3"],
        telephone: json["Telephone"],
        mobile: json["Mobile"],
        date: json["DDate"],
        activate: json["Activate"],
        salary: json["Salary"].toDouble(),
        auto: json["Auto"],
        ot: json["OT"].toDouble(),
        dailyAllowance: json["DAllowance"].toDouble(),
        liveDeduction: json["LiveDeduction"].toDouble(),
        total: json["Total"].toDouble(),
        employeeSection: json["EmployeeSection"],
        casualLeave: json["CashualLeave"].toDouble(),
        tickEligibility: json["TickeEligibility"].toDouble(),
        commissionStatus: json["salescomStatus"],
        type: json["Type"],
        commissionPercentage: json["commisionper"].toDouble(),
        min: json["min"],
        empCode: json["emp_code"],
        empId: json["emp_id"],
        gender: json["Gender"],
        workingHour: json["WorkingHour"],
        vehicleCommission: json["VehicleCommision"].toDouble(),
        loadingCharge: json["LoadingCharge"].toDouble(),
        mode: json["mode"],
        lunchMin: json["lunchmin"],
        otHour: json["othour"],
        sms: json["SMS"],
        esi: json["esi"].toDouble(),
        pf: json["pf"].toDouble(),
        active: json["Active"],
        att: json["att"],
        expiryDate: json["expdate"],
        expiryDateArabic: json["ExpdateArabic"],
        baladiyaExpiryDate: json["Baladiyaexpdate"],
        passportExpiryDate: json["Passportexpdate"],
        location: json["Location"],
        ledCode: json["LedCode"],
      );

  Map<String, dynamic> toMap() => {
        "Name": name,
        "Address1": address1,
        "address2": address2,
        "address3": address3,
        "Telephone": telephone,
        "Mobile": mobile,
        "DDate": date,
        "Activate": activate,
        "Salary": salary,
        "Auto": auto,
        "OT": ot,
        "DAllowance": dailyAllowance,
        "LiveDeduction": liveDeduction,
        "Total": total,
        "EmployeeSection": employeeSection,
        "CashualLeave": casualLeave,
        "TickeEligibility": tickEligibility,
        "salescomStatus": commissionStatus,
        "Type": type,
        "commisionper": commissionPercentage,
        "min": min,
        "emp_code": empCode,
        "emp_id": empId,
        "Gender": gender,
        "WorkingHour": workingHour,
        "VehicleCommision": vehicleCommission,
        "LoadingCharge": loadingCharge,
        "mode": mode,
        "lunchmin": lunchMin,
        "othour": otHour,
        "SMS": sms,
        "esi": esi,
        "pf": pf,
        "Active": active,
        "att": att,
        "expdate": expiryDate,
        "ExpdateArabic": expiryDateArabic,
        "Baladiyaexpdate": baladiyaExpiryDate,
        "Passportexpdate": passportExpiryDate,
        "Location": location,
        "LedCode": ledCode,
      };
}
