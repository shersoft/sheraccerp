import 'dart:convert';

class RPModel {
  String entryNo;
  RPModel({
    required this.entryNo,
  });

  RPModel copyWith({
    String? entryNo,
  }) {
    return RPModel(
      entryNo: entryNo ?? this.entryNo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entryNo': entryNo,
    };
  }

  factory RPModel.fromMap(Map<String, dynamic> map) {
    return RPModel(
      entryNo: map['entryNo'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory RPModel.fromJson(String source) =>
      RPModel.fromMap(json.decode(source));

  @override
  String toString() => 'RPModel(entryNo: $entryNo)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RPModel && other.entryNo == entryNo;
  }

  @override
  int get hashCode => entryNo.hashCode;
}

class RpVoucherParticularModel {
  int id;
  String name;
  double amount;
  double discount;
  double total;
  String narration;
  String balance;
  String phone;
  RpVoucherParticularModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.discount,
    required this.total,
    required this.narration,
    required this.balance,
    required this.phone,
  });

  RpVoucherParticularModel copyWith({
    int? id,
    String? name,
    double? amount,
    double? discount,
    double? total,
    String? narration,
    String? balance,
    String? phone,
  }) {
    return RpVoucherParticularModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      narration: narration ?? this.narration,
      balance: balance ?? this.balance,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'discount': discount,
      'total': total,
      'narration': narration,
      'balance': balance,
      'phone': phone,
    };
  }

  factory RpVoucherParticularModel.fromMap(Map<String, dynamic> map) {
    return RpVoucherParticularModel(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      narration: map['narration'] ?? '',
      balance: map['balance'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory RpVoucherParticularModel.fromJson(String source) =>
      RpVoucherParticularModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'RpVoucherParticularModel(id: $id, name: $name, amount: $amount, discount: $discount, total: $total, narration: $narration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RpVoucherParticularModel &&
        other.id == id &&
        other.name == name &&
        other.amount == amount &&
        other.discount == discount &&
        other.total == total &&
        other.narration == narration &&
        other.balance == balance;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        amount.hashCode ^
        discount.hashCode ^
        total.hashCode ^
        narration.hashCode;
  }

  static toMapData(List<RpVoucherParticularModel> particularList) {
    return particularList
        .map((e) => json.encode({
              'Ledid': e.id,
              'name': e.name,
              'amount': e.amount,
              'discount': e.discount,
              'total': e.total,
              'narration': e.narration,
            }))
        .toList();
  }
}
