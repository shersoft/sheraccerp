// @dart = 2.11
class CustomerModel {
  int id;
  String name;
  String address1;
  String address2;
  String address3;
  String address4;
  String taxNumber;
  String phone;
  String email;
  String balance;
  String city, route, state, stateCode, remarks;

  CustomerModel(
      {this.id,
      this.name,
      this.address1,
      this.address2,
      this.address3,
      this.address4,
      this.taxNumber,
      this.phone,
      this.email,
      this.balance,
      this.city,
      this.route,
      this.state,
      this.stateCode,
      this.remarks});

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
        id: json['Ledcode'],
        name: json['LedName'],
        address1: json['add1'],
        address2: json['add2'],
        address3: json['add3'],
        address4: json['add4'],
        taxNumber: json['gstno'],
        phone: json['Mobile'],
        email: json['Email'],
        balance: json['balance'],
        city: json['city'].toString(),
        route: json['route'].toString(),
        state: json['state'],
        stateCode: json['stateCode'],
        remarks: json['remarks']);
  }

  Map toCustomerMap() {
    var map = {};
    map["id"] = id;
    map["name"] = name;
    map["address1"] = address1;
    map["address2"] = address2;
    map["address3"] = address3;
    map["address4"] = address4;
    map["taxNumber"] = taxNumber;
    map["phone"] = phone;
    map["email"] = email;
    map["balance"] = balance;
    map["city"] = city;
    map["route"] = route;
    map["state"] = state;
    map["stateCode"] = stateCode;
    map["remarks"] = remarks;

    return map;
  }

  Map<String, dynamic> toJson1() {
    return {
      'id': id.toString(),
      'name': name,
      'address1': address1,
      'address2': address2,
      'address3': address3,
      'address4': address4,
      'taxNumber': taxNumber,
      'phone': phone,
      'email': email,
      'balance': balance,
      'city': city,
      'route': route,
      'state': state,
      'stateCode': stateCode,
      'remarks': remarks
    };
  }

  static List encodeCustomerToJson(List<CustomerModel> list) {
    List jsonList = [];
    list.map((item) => jsonList.add(item.toJson1())).toList();
    return jsonList;
  }
}
