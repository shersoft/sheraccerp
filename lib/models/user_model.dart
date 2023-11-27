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
        userId: json['UserID'] ?? 0,
        userName: json['Name'] ?? '',
        password: json['Password'] ?? '',
        groupName: json['GroupName'] ?? '');
  }

  static emptyData() {
    return UserModel(
        groupName: '', id: 0, password: '', userId: 0, userName: '');
  }
}

class UserGroupModel {
  int id, save, edit, find, delete;
  String name;
  UserGroupModel(
      {this.id, this.name, this.save, this.edit, this.delete, this.find});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'save': save,
      'edit': edit,
      'find': find,
      'delete': delete,
      'name': name,
    };
  }

  factory UserGroupModel.fromMap(Map<String, dynamic> map) {
    return UserGroupModel(
      id: map['Auto'] ?? 0,
      save: map['S'] ?? 0,
      edit: map['E'] ?? 0,
      find: map['F'] ?? 0,
      delete: map['D'] ?? 0,
      name: map['Name'] ?? '',
    );
  }
}
