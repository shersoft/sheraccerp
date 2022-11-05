// @dart = 2.11
class CompanyUser {
  String userId;
  String registrationId;
  String username;
  String password;
  String active;
  String deviceId;
  String atDate;
  String loginDate, userType;
  bool insertData, updateData, deleteData;

  CompanyUser(
      {this.userId,
      this.registrationId,
      this.username,
      this.password,
      this.active,
      this.deviceId,
      this.atDate,
      this.loginDate,
      this.userType,
      this.insertData,
      this.updateData,
      this.deleteData});

  factory CompanyUser.fromJson(Map<String, dynamic> json) => CompanyUser(
        userId: json['UserId'].toString(),
        registrationId: json['RegistrationId'].toString(),
        username: json['UserName'],
        password: json['Password'],
        active: json['Active'].toString(),
        deviceId: json['DeviceId'],
        atDate: json['atDate'],
        loginDate: json['loginDate'],
        userType: json['UserType'],
        insertData: json['InsertData'] != null
            ? json['InsertData'] == 1
                ? true
                : false
            : false,
        updateData: json['UpdateData'] != null
            ? json['UpdateData'] == 1
                ? true
                : false
            : false,
        deleteData: json['DeleteData'] != null
            ? json['DeleteData'] == 1
                ? true
                : false
            : false,
      );

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'RegistrationId': registrationId,
      'UserName': username,
      'Password': password,
      'Active': active,
      'DeviceId': deviceId,
      'atDate': atDate,
      'loginDate': loginDate,
      'UserType': userType,
      'InsertData': insertData,
      'UpdateData': updateData,
      'DeleteData': deleteData
    };
  }
}
