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

  static List<TaxGroupModel> fromJsonList(List list) {
    return list.map((item) => TaxGroupModel.fromJson(item)).toList();
  }

  String userAsString() {
    return '#$id $name $schedule $gst $sDate $eDate $cGst $sGst $iGst $fCess';
  }

  @override
  String toString() => name;
}
