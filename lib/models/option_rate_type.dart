import 'dart:convert';

class OptionRateType {
  final int id;
  final String name;

  OptionRateType({required this.id, required this.name});

  factory OptionRateType.fromJson(Map<String, dynamic> json) {
    return OptionRateType(id: json['Id'], name: json['Name']);
  }

  factory OptionRateType.fromMap(Map<String, dynamic> json) => OptionRateType(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
      };
}

class ItemDataModel {
  int id;
  String name;
  bool status;
  ItemDataModel({
    required this.id,
    required this.name,
    required this.status,
  });

  ItemDataModel copyWith({
    int? id,
    String? name,
    bool? status,
  }) {
    return ItemDataModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
    };
  }

  factory ItemDataModel.fromMap(Map<String, dynamic> map) {
    return ItemDataModel(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      status: map['status'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ItemDataModel.fromJson(String source) =>
      ItemDataModel.fromMap(json.decode(source));

  @override
  String toString() => 'ItemDataModel(id: $id, name: $name, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ItemDataModel &&
        other.id == id &&
        other.name == name &&
        other.status == status;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ status.hashCode;
}
