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
