// @dart = 2.11
class ExpenseListItemModel {
  final int id;
  final String eno, party, amount;

  ExpenseListItemModel({this.id, this.eno, this.party, this.amount});

  Map<String, dynamic> toJson() =>
      {"id": id, "Inv": eno, "Party": party, "Amount": amount};

  factory ExpenseListItemModel.fromJson(Map<String, dynamic> json) {
    return ExpenseListItemModel(
        id: int.tryParse(json['SlNo']),
        eno: json['SlNo'],
        party: json['LedName'].toString(),
        amount: json['Debit'].toString());
  }
}
