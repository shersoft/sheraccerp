class SmsDataModel {
  String voucher;
  String messageBody;
  String apiLink;

  SmsDataModel({
    required this.voucher,
    required this.messageBody,
    required this.apiLink,
  });

  factory SmsDataModel.fromMap(Map<String, dynamic> json) => SmsDataModel(
        voucher: json["Voucher"],
        messageBody: json["MessageBody"],
        apiLink: json["ApiLink"],
      );

  Map<String, dynamic> toMap() => {
        "Voucher": voucher,
        "MessageBody": messageBody,
        "ApiLink": apiLink,
      };

  static emptyData() {
    return SmsDataModel(voucher: '', messageBody: '', apiLink: '');
  }
}
