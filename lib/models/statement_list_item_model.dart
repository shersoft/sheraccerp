class StatementListItemModel {
  final int id;
  final String eno, party, amount, status;

  StatementListItemModel(
      {required this.id,
      required this.eno,
      required this.party,
      required this.amount,
      required this.status});

  Map<String, dynamic> toJson() => {
        "id": id,
        "Inv": eno,
        "Party": party,
        "Amount": amount,
        "Status": status
      };

  factory StatementListItemModel.fromJson(Map<String, dynamic> json) {
    return StatementListItemModel(
        id: json['id'],
        eno: json['entryno'].toString(),
        party: json['ledname'],
        amount: json['amount'].toString(),
        status: json['status']);
  }
}
