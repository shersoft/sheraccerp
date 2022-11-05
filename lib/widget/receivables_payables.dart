import 'package:flutter/material.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/widget/simple_piediagram_pay_rec.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:sheraccerp/widget/loading.dart';

class ReceivablesAndPayables extends StatelessWidget {
  DioService api = DioService();
  var dropDownBranchId;

  ReceivablesAndPayables({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (locationList.isNotEmpty) {
      dropDownBranchId = locationList
          .where((element) => element.value == 'SHOP')
          .map((e) => e.key)
          .first;
    }
    return FutureBuilder(
        future: api.fetchReceivableAndPayable(
            '2000-01-01', '2000-01-01', dropDownBranchId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Loading();
          } else {
            return snapshot.hasData
                ? SimplePieDiagramPayRec(_getExpenseSeriesData(snapshot.data),
                    animate: true)
                : const Loading();
          }
        });
  }

  _getExpenseSeriesData(var _data) {
    List<charts.Series<ChartPayRec, String>> series = [
      charts.Series<ChartPayRec, String>(
        id: 'PayRec',
        colorFn: (ChartPayRec expense, _) =>
            charts.ColorUtil.fromDartColor(Color(int.parse(expense.colorVal))),
        domainFn: (ChartPayRec expense, _) => expense.amount,
        measureFn: (ChartPayRec expense, _) =>
            double.tryParse((expense.amount).split(" ")[1]),
        data: _data,
        labelAccessorFn: (ChartPayRec expense, _) => expense.amount,
      )
    ];
    return series;
  }
}
