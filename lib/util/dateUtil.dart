import 'package:intl/intl.dart';

class DateUtil {
  static const date_format = 'dd/MM/yy';
  String formattedDate(DateTime dateTime) {
    // print('dateTime ($dateTime)');
    return DateFormat(date_format).format(dateTime);
  }

  static String dateYMD(value) {
    var dateTime = DateFormat("dd-MM-yyyy").parse(value.toString());
    return DateFormat("yyyy-MM-dd").format(dateTime);
  }

  static String dateYMD1(value) {
    var dateTime = DateFormat("dd/MM/yyyy").parse(value.toString());
    return DateFormat("yyyy-MM-dd").format(dateTime);
  }

  static String dateDMY2YMD(value) {
    var dateTime = DateFormat("dd-MM-yyyy").parse(value.toString());
    return DateFormat("yyyy-MM-dd").format(dateTime);
  }

  static String datePickerYMD(picker) {
    return DateFormat('yyyy-MM-dd').format(picker);
  }

  static String datePickerDMY(picker) {
    return DateFormat('dd-MM-yyyy').format(picker);
  }

  static String dateDMY(value) {
    var dateTime = DateFormat("yyyy-MM-dd").parse(value.toString());
    return DateFormat("dd-MM-yyyy").format(dateTime);
  }

  static String dateDMY1(value) {
    var dateTime = DateFormat("yyyy-MM-dd").parse(value.toString());
    return DateFormat("dd/MM/yyyy").format(dateTime);
  }

  static String dateDMmmY(value) {
    var dateTime = DateFormat("yyyy-MM-dd").parse(value.toString());
    return DateFormat("dd/MMM/yyyy").format(dateTime);
  }

  static DateTime dateTimeYMDHMS(_date, _time) {
    var date = DateFormat("yyyy-MM-dd").parse(_date.toString());
    var time =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(_time.toString());
    return DateFormat("yyyy-MM-dd HH:mm:ss")
        .parse(date.toString() + ' ' + time.toString());
  }

  static String timeHMS(value) {
    var dateTime =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(value.toString());
    return DateFormat("HH:mm:ss").format(dateTime);
  }

  static String timeHMSA(value) {
    var dateTime =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(value.toString());
    return DateFormat("hh:mm a").format(dateTime);
  }

  static String datedYMD(value) {
    var dateTime =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(value.toString());
    return DateFormat("yyyy-MM-dd").format(dateTime);
  }

  static String dateTimeDMY(value) {
    var dateTime =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(value.toString());
    return DateFormat("dd-MM-yyyy hh:mm a").format(dateTime);
  }

  static String dateTimeQrDMY(value) {
    var dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(value.toString());
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(dateTime);
  }

  static getDays({required DateTime start, required DateTime end}) {
    final days = end.difference(start).inDays;

    return ('$days days ago');
  }
}
