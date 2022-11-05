// @dart = 2.11
class UserModel {
  int id, userId;
  String userName, password, groupName;
  // Map password;

  UserModel(
      {this.id, this.userId, this.userName, this.password, this.groupName});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        id: json['Auto'],
        userId: json['userID'],
        userName: json['Name'],
        password: json['Password'],
        groupName: json['GroupName']);
  }
}
