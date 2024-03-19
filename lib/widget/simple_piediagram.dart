// @dart = 2.7
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/util/dateUtil.dart';

class SimplePieDiagram extends StatelessWidget {
  final List<charts.Series<ChartExpense, String>> seriesList;
  final bool animate;

  const SimplePieDiagram(this.seriesList, {Key key, this.animate})
      : super(key: key);

  /// Creates a [PieChart] with sample data and no transition.
  factory SimplePieDiagram.withSampleData() {
    return SimplePieDiagram(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.PieChart(
      seriesList,
      animate: animate,
      animationDuration: const Duration(seconds: 1),
      behaviors: [
        charts.DatumLegend(
          outsideJustification: charts.OutsideJustification.endDrawArea,
          horizontalFirst: false,
          desiredMaxRows: 2,
          cellPadding: const EdgeInsets.only(right: 4.0, bottom: 4.0, top: 4.0),
          entryTextStyle: charts.TextStyleSpec(
              color: charts.MaterialPalette.purple.shadeDefault, fontSize: 18),
        )
      ],
      defaultRenderer:
          charts.ArcRendererConfig(arcWidth: 100, arcRendererDecorators: [
        charts.ArcLabelDecorator(labelPosition: charts.ArcLabelPosition.inside)
      ]),
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<ChartExpense, String>> _createSampleData() {
    final data = [
      ChartExpense(
          name: 'A CH', amount: '19800', id: 1, colorVal: '0xff990099'),
      ChartExpense(
          name: 'B CH', amount: '19000', id: 2, colorVal: '0xffE33335'),
      ChartExpense(
          name: 'C CH', amount: '18000', id: 3, colorVal: '0xffEED44C'),
      ChartExpense(
          name: 'D CH', amount: '15000', id: 4, colorVal: '0xff109618'),
      ChartExpense(
          name: 'E CH', amount: '10000', id: 5, colorVal: '0xFF0000FF'),
    ];

    return [
      charts.Series<ChartExpense, String>(
        id: 'Expense',
        colorFn: (ChartExpense expense, _) =>
            charts.ColorUtil.fromDartColor(Color(int.parse(expense.colorVal))),
        domainFn: (ChartExpense expense, _) => expense.name,
        measureFn: (ChartExpense expense, _) => expense.id,
        data: data,
      )
    ];
  }
  // static List<charts.Series<ChartSales, String>> _createSampleData() {
  //   final data = [
  //     new ChartSales(ddate: '2014', amount: 5),
  //     new ChartSales(ddate: '2015', amount: 25),
  //     new ChartSales(ddate: '2016', amount: 100),
  //     new ChartSales(ddate: '2017', amount: 75),
  //   ];

  //   return [
  //     new charts.Series<ChartSales, String>(
  //       id: 'Sales',
  //       colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
  //       domainFn: (ChartSales sales, _) => sales.ddate,
  //       measureFn: (ChartSales sales, _) => sales.amount,
  //       data: data,
  //     )
  //   ];
  // }
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
  final String colorVal;
  final String name;

  ChartExpense({this.amount, this.id, this.colorVal, this.name});

  factory ChartExpense.fromJson(Map<String, dynamic> json) {
    return ChartExpense(
        amount: json['amount'].toString(),
        id: json['id'],
        colorVal: json['color'],
        name: json['name']);
  }
  @override
  String toString() => "Record<$id:$amount>";
}
