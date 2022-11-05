class FormModel {
  int id;
  String title;
  bool isChecked;
  FormModel({
    required this.id,
    required this.title,
    required this.isChecked,
  });

  factory FormModel.fromJson(Map<String, dynamic> json) => FormModel(
        id: json['id'],
        title: json['name'],
        isChecked: json['status'] != null
            ? json['status'] == 1
                ? true
                : false
            : false,
      );

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': title, 'status': isChecked};
  }

  static List encodeCartToJson(List<FormModel> list) {
    List jsonList = [];
    list.map((item) => jsonList.add(item.toJson())).toList();
    return jsonList;
  }
}
