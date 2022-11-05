// @dart = 2.11
class StatementItem {
  int id;
  String party;
  String debit;
  String credit;

  StatementItem({this.id, this.party, this.debit, this.credit});

  Map<String, dynamic> toJson() =>
      {"id": id, "PARTY": party, "DEBIT": debit, "CREDIT": credit};

  StatementItem.fromJson(Map<String, dynamic> json) {
    id = 0; //id
    party = json['Party'].toString();
    debit = json['Debit'].toString();
    credit = json['Credit'].toString();
  }
}
