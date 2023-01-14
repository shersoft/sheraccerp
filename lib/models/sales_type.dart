// @dart = 2.11
class SalesType {
  int id;
  String name, type, rateType, sColor;
  int location;
  bool stock, accounts, tax, eInvoice;

  SalesType(
      {this.id,
      this.name,
      this.type,
      this.rateType,
      this.stock,
      this.accounts,
      this.location,
      this.sColor,
      this.tax,
      this.eInvoice});

  factory SalesType.fromJson(Map<String, dynamic> json) {
    return SalesType(
        id: json['iD'],
        name: json['Name'],
        type: json['Type'],
        rateType: json['RateType'],
        stock: json['Stock'] == 1 ? true : false,
        accounts: json['Accounts'] == 1 ? true : false,
        location: json['Location'],
        sColor: json['Scolor'],
        tax: json['Tax'] == 1 ? true : false,
        eInvoice: json['EInvoice'] == 1 ? true : false);
  }
}

SalesType salesTypeData;
bool taxable = false;
