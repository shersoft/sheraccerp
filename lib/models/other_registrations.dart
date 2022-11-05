// @dart = 2.11
class OtherRegistrations {
  int id;
  String name;
  String description;
  String type;
  String add1;
  String add2;
  String add3;
  String email;
  OtherRegistrations(
      {this.id,
      this.name,
      this.description,
      this.type,
      this.add1,
      this.add2,
      this.add3,
      this.email});

  factory OtherRegistrations.fromJson(Map<String, dynamic> json) {
    return OtherRegistrations(
        id: json['auto'],
        name: json['Name'],
        description: json['Description'],
        type: json['Type'],
        add1: json['add1'],
        add2: json['add2'],
        add3: json['add3'],
        email: json['Email']);
  }
}

OtherRegistrations otherRegistrations;
