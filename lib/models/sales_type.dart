// @dart = 2.11
class SalesType {
  int id;
  String name, type, rateType;
  int location;
  bool stock, accounts;

  SalesType(
      {this.id,
      this.name,
      this.type,
      this.rateType,
      this.stock,
      this.accounts,
      this.location});

  factory SalesType.fromJson(Map<String, dynamic> json) {
    return SalesType(
        id: json['iD'],
        name: json['Name'],
        type: json['Type'],
        rateType: json['RateType'],
        stock: json['Stock'] == 1 ? true : false,
        accounts: json['Accounts'] == 1 ? true : false,
        location: json['Location']);
  }
}

SalesType salesTypeData;
bool taxable = false;
