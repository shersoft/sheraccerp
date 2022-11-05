// @dart = 2.11

class CommonService {
  bool getTrialPeriod(String dated) {
    // int y, m, d;
    var date = dated.contains("T") ? dated.split("T") : dated.split(" ");
    var ymd = date[0].toString().split("-");
    final day =
        DateTime(int.parse(ymd[0]), int.parse(ymd[1]), int.parse(ymd[2]));
    final date2 = DateTime.now();
    final difference = date2.difference(day).inDays;
    if (difference > 30) {
      return false;
    } else {
      return true;
    }
  }

  int getDoubleToInteger(String value) {
    double x = double.parse(value);
    int ret = x.toInt();
    return ret;
  }

  bool isNumeric(String result) {
    if (result == null) {
      return false;
    }
    return double.tryParse(result) != null;
  }

  String getNumericFromString(String value, String replace) {
    return value.replaceAll(replace, "");
  }

  String getNumericFromDrCR(String value) {
    String s = value.replaceAll(" DR", "");
    return s.replaceAll(" CR", "");
  }

  static double getRound(int n, double number) {
    // final formatter = new NumberFormat("#,###");
    if (n == 1) {
      return double.tryParse(number.toStringAsFixed(1));
    } else if (n == 2) {
      return double.tryParse(number.toStringAsFixed(2));
    } else if (n == 3) {
      return double.tryParse(number.toStringAsFixed(3));
    } else if (n == 4) {
      return double.tryParse(number.toStringAsFixed(4));
    }
  }
}
