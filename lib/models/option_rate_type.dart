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
