// @dart = 2.9
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class SimplePieDiagramPayRec extends StatelessWidget {
  final List<charts.Series<ChartPayRec, String>> seriesList;
  final bool animate;

  const SimplePieDiagramPayRec(this.seriesList, {Key key, this.animate})
      : super(key: key);

  factory SimplePieDiagramPayRec.withSampleData() {
    return SimplePieDiagramPayRec(
      _createSampleData(),
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

  static List<charts.Series<ChartPayRec, String>> _createSampleData() {
    final data = [
      ChartPayRec(amount: 'Rec 19800', id: 1, colorVal: '0xff109618'),
      ChartPayRec(amount: 'Pay 19000', id: 2, colorVal: '0xffE33335'),
    ];

    return [
      charts.Series<ChartPayRec, String>(
        id: 'PayRec',
        colorFn: (ChartPayRec expense, _) =>
            charts.ColorUtil.fromDartColor(Color(int.parse(expense.colorVal))),
        domainFn: (ChartPayRec expense, _) => expense.amount,
        measureFn: (ChartPayRec expense, _) => expense.id,
        data: data,
      )
    ];
  }
}

class ChartPayRec {
  final int id;
  final String amount;
  final String colorVal;

  ChartPayRec({this.id, this.amount, this.colorVal});

  factory ChartPayRec.fromJson(Map<String, dynamic> json) {
    return ChartPayRec(
        id: json['id'],
        amount: json['amount'].toString(),
        colorVal: colorValues[json['id'] - 1]);
  }
  @override
  String toString() => "Record<$id:$amount>";
}

final colorValues = [
  '0xff109618',
  '0xffE33335',
  '0xff990099',
  '0xffEED44C',
  '0xff109618',
  '0xFF0000FF',
  '0xff990099',
  '0xffE33335',
  '0xffEED44C',
  '0xFF0000FF'
];
