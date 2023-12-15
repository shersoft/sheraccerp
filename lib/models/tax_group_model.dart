class TaxGroupModel {
  int id;
  String name;
  String schedule;
  double gst;
  String sDate;
  String eDate;
  double cGst;
  double sGst;
  double iGst;
  double fCess;

  TaxGroupModel(
      {required this.id,
      required this.name,
      required this.schedule,
      required this.gst,
      required this.sDate,
      required this.eDate,
      required this.cGst,
      required this.sGst,
      required this.iGst,
      required this.fCess});
  static emptyData() {
    TaxGroupModel(
        id: 0,
        name: '',
        schedule: '',
        gst: 0,
        sDate: '2020-01-01',
        eDate: '2021-01-01',
        cGst: 0,
        sGst: 0,
        iGst: 0,
        fCess: 0);
  }

  factory TaxGroupModel.fromJson(Map<String, dynamic> json) {
    return TaxGroupModel(
        id: json['id'],
        name: json['name'],
        schedule: json['schedule'],
        gst: json['gst'].toDouble(),
        sDate: json['sdate'],
        eDate: json['edate'],
        cGst: json['cgst'].toDouble(),
        sGst: json['sgst'].toDouble(),
        iGst: json['igst'].toDouble(),
        fCess: json['fcess'].toDouble());
  }

  factory TaxGroupModel.fromMap(Map<String, dynamic> json) {
    return TaxGroupModel(
        id: json['Auto'],
        name: json['Name'],
        schedule: json['schedule'],
        gst: json['Gst'].toDouble(),
        sDate: json['sdate'],
        eDate: json['edate'],
        cGst: json['cgst'].toDouble(),
        sGst: json['sgst'].toDouble(),
        iGst: json['igst'].toDouble(),
        fCess: json['Fcess'].toDouble());
  }

  static List<TaxGroupModel> fromJsonList(List list) {
    return list.map((item) => TaxGroupModel.fromJson(item)).toList();
  }

  static List<TaxGroupModel> fromMapList(List list) {
    return list.map((item) => TaxGroupModel.fromMap(item)).toList();
  }

  String userAsString() {
    return '#$id $name $schedule $gst $sDate $eDate $cGst $sGst $iGst $fCess';
  }

  @override
  String toString() => name;
}
