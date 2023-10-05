class PrintSettingsModel {
  int tearOff;
  int topMargin;
  int bottomMargin;
  String dTransaction;
  String model;
  bool heading;
  bool declaration;
  int startSpace;
  String port;
  int billLines;
  int copies;
  String invoiceLetter;
  int auto;
  String note;
  String caption;
  String invoiceSuffix;
  String filePath;
  int pdf;
  String additionalPath1;
  String additionalPath2;
  int fyId;

  PrintSettingsModel({
    required this.tearOff,
    required this.topMargin,
    required this.bottomMargin,
    required this.dTransaction,
    required this.model,
    required this.heading,
    required this.declaration,
    required this.startSpace,
    required this.port,
    required this.billLines,
    required this.copies,
    required this.invoiceLetter,
    required this.auto,
    required this.note,
    required this.caption,
    required this.invoiceSuffix,
    required this.filePath,
    required this.pdf,
    required this.additionalPath1,
    required this.additionalPath2,
    required this.fyId,
  });

  factory PrintSettingsModel.fromMap(Map<String, dynamic> json) =>
      PrintSettingsModel(
        tearOff: json["TearOff"],
        topMargin: json["TopMargin"],
        bottomMargin: json["BottomMargin"],
        dTransaction: json["DTransaction"],
        model: json["Model"],
        heading: json["Headding"],
        declaration: json["Declaration"],
        startSpace: json["Startspace"],
        port: json["Port"],
        billLines: json["billlines"],
        copies: json["Copies"],
        invoiceLetter: json["invoiceletter"],
        auto: json["Auto"],
        note: json["note"],
        caption: json["caption"],
        invoiceSuffix: json["invoicesuffix"],
        filePath: json["FilePath"],
        pdf: json["PDF"],
        additionalPath1: json["Additionalpath1"],
        additionalPath2: json["Additionalpath2"],
        fyId: json["FyID"],
      );

  Map<String, dynamic> toMap() => {
        "TearOff": tearOff,
        "TopMargin": topMargin,
        "BottomMargin": bottomMargin,
        "DTransaction": dTransaction,
        "Model": model,
        "Headding": heading,
        "Declaration": declaration,
        "Startspace": startSpace,
        "Port": port,
        "billlines": billLines,
        "Copies": copies,
        "invoiceletter": invoiceLetter,
        "Auto": auto,
        "note": note,
        "caption": caption,
        "invoicesuffix": invoiceSuffix,
        "FilePath": filePath,
        "PDF": pdf,
        "Additionalpath1": additionalPath1,
        "Additionalpath2": additionalPath2,
        "FyID": fyId,
      };

  static empty() {
    return PrintSettingsModel(
        tearOff: 0,
        topMargin: 0,
        bottomMargin: 0,
        dTransaction: '',
        model: '',
        heading: false,
        declaration: false,
        startSpace: 0,
        port: '',
        billLines: 0,
        copies: 0,
        invoiceLetter: '',
        auto: 0,
        note: '',
        caption: '',
        invoiceSuffix: '',
        filePath: '',
        pdf: 0,
        additionalPath1: '',
        additionalPath2: '',
        fyId: 0);
  }
}
