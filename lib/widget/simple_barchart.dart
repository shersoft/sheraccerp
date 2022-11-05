// @dart = 2.7
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/util/dateUtil.dart';

class SimpleBarChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  const SimpleBarChart(this.seriesList, {Key key, this.animate})
      : super(key: key);

  /// Creates a [BarChart] with sample data and no transition.
  factory SimpleBarChart.withSampleData() {
    return SimpleBarChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<ChartSales, String>> _createSampleData() {
    final data = [
      ChartSales(ddate: '2014', amount: 5),
      ChartSales(ddate: '2015', amount: 25),
      ChartSales(ddate: '2016', amount: 100),
      ChartSales(ddate: '2017', amount: 75),
    ];

    return [
      charts.Series<ChartSales, String>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (ChartSales sales, _) => sales.ddate,
        measureFn: (ChartSales sales, _) => sales.amount,
        data: data,
      )
    ];
  }
}

/// Sample ordinal data type.
class ChartSales {
  final String ddate;
  final int amount;

  ChartSales({this.ddate, this.amount});

  factory ChartSales.fromJson(Map<String, dynamic> json) {
    return ChartSales(
        ddate: DateUtil().formattedDate(DateTime.parse(json['ddate'])),
        amount: CommonService().getDoubleToInteger(json['Amount'].toString()));
  }
}

class ChartPurchase {
  final String date;
  final int amount;

  ChartPurchase({this.date, this.amount});

  factory ChartPurchase.fromJson(Map<String, dynamic> json) {
    return ChartPurchase(
        date: DateUtil().formattedDate(DateTime.parse(json['ddate'])),
        amount: CommonService().getDoubleToInteger(json['amount'].toString()));
  }
}

class ChartExpense {
  final String amount;
  final int id;

  ChartExpense({this.amount, this.id});

  factory ChartExpense.fromJson(Map<String, dynamic> json) {
    return ChartExpense(amount: json['amount'].toString(), id: json['id']);
  }
}
