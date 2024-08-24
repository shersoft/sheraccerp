class MainHeadsModel {
  int mlhId;
  int plhId;
  int mlhName;

  MainHeadsModel({
    required this.mlhId,
    required this.plhId,
    required this.mlhName,
  });

  Map<String, dynamic> toMap() {
    return {
      'Mlh_Id': mlhId,
      'plh_id': plhId,
      'Mlh_name': mlhName,
    };
  }

  factory MainHeadsModel.fromMap(Map<String, dynamic> map) {
    return MainHeadsModel(
      mlhId: map['Mlh_Id']?.toInt() ?? 0,
      plhId: map['plh_id']?.toInt() ?? 0,
      mlhName: map['Mlh_name']?.toInt() ?? 0,
    );
  }

  static List<MainHeadsModel> fromJsonList(List list) {
    return list.map((item) => MainHeadsModel.fromMap(item)).toList();
  }
}
