import 'dart:convert';

class InvoiceParticulars {
  int id;
  int pEntryNo;
  String entryType;
  int ledger;
  String invoiceNo;
  String narration;
  double amount;
  double discount;
  double total;
  String date;
  InvoiceParticulars({
    required this.id,
    required this.pEntryNo,
    required this.entryType,
    required this.ledger,
    required this.invoiceNo,
    required this.narration,
    required this.amount,
    required this.discount,
    required this.total,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pEntryNo': pEntryNo,
      'entryType': entryType,
      'ledger': ledger,
      'invoiceNo': invoiceNo,
      'narration': narration,
      'amount': amount,
      'discount': discount,
      'total': total,
      'date': date,
    };
  }

  factory InvoiceParticulars.fromMap(Map<String, dynamic> map) {
    return InvoiceParticulars(
      id: map['id']?.toInt() ?? 0,
      pEntryNo: map['pEntryNo']?.toInt() ?? 0,
      entryType: map['entryType'] ?? '',
      ledger: map['ledger']?.toInt() ?? 0,
      invoiceNo: map['invoiceNo'] ?? '',
      narration: map['narration'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      date: map['date'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory InvoiceParticulars.fromJson(String source) =>
      InvoiceParticulars.fromMap(json.decode(source));
}
