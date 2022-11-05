// @dart = 2.7
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/models/expense_list_item_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/widget/expense_listview.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/simple_piediagram.dart';

class Expense extends StatefulWidget {
  const Expense({Key key}) : super(key: key);

  @override
  _ExpenseState createState() => _ExpenseState();
}

class _ExpenseState extends State<Expense> {
  String heading = "";
  final List<ChartExpense> _expenseData = [];
  DateTime now = DateTime.now();
  String formattedDate;
  DioService api = DioService();
  final colorValues = [
    '0xffE33335',
    '0xff990099',
    '0xffEED44C',
    '0xff109618',
    '0xFF0000FF',
    '0xff990099',
    '0xffE33335',
    '0xffEED44C',
    '0xff109618',
    '0xFF0000FF'
  ];

  List<ExpenseListItemModel> lItems = [];
  var dropDownBranchId;

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('yyyy-MM-dd').format(now);
    if (locationList.isNotEmpty) {
      dropDownBranchId = locationList
          .where((element) => element.value == 'SHOP')
          .map((e) => e.key)
          .first;
      _fetchData(dropDownBranchId);
    }
  }

  Future _fetchData(var branchID) async {
    api
        .fetchExpenseData(formattedDate, formattedDate, 'All Expense', branchID)
        .then((value) {
      setState(() {
        for (var data in value) {
          lItems.add(ExpenseListItemModel.fromJson(data));
        }
        int n = 0;
        for (var json in value) {
          if (n < 5) {
            _expenseData.add(ChartExpense(
                id: int.tryParse(json['SlNo']),
                name: json['LedName'],
                amount: json['Debit'].toString(),
                colorVal: colorValues[n]));
          }
          n++;
        }
      });
    });
  }

  _getExpenseSeriesData() {
    List<charts.Series<ChartExpense, String>> series = [
      charts.Series<ChartExpense, String>(
        id: 'Expense',
        colorFn: (ChartExpense expense, _) =>
            charts.ColorUtil.fromDartColor(Color(int.parse(expense.colorVal))),
        domainFn: (ChartExpense expense, _) => expense.name,
        measureFn: (ChartExpense expense, _) => double.parse(expense.amount),
        data: _expenseData,
        labelAccessorFn: (ChartExpense expense, _) => expense.amount,
      )
    ];
    return series;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: DropDownSettingsTile<int>(
              title: 'Branch',
              settingKey: 'key-dropdown-default-location-view',
              values: locationList.isNotEmpty
                  ? Map.fromIterable(locationList,
                      key: (e) => e.key + 1, value: (e) => e.value)
                  : {
                      2: '',
                    },
              selected: 2,
              onChange: (value) {
                debugPrint('key-dropdown-default-location-view: $value');
                dropDownBranchId = value - 1;
                _fetchData(dropDownBranchId);
              },
            ),
          ),
          const Center(
            child: Text(
              'All Expenses',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            height: 10.0,
          ),
          SizedBox(
              height: 320.0,
              width: 320.0,
              child: _expenseData.isNotEmpty
                  ? SimplePieDiagram(_getExpenseSeriesData(), animate: true)
                  : const Loading()),
          const SizedBox(
            height: 10.0,
          ),
          lItems.isNotEmpty
              ? ExpenseListView(
                  listViewModels: lItems, branchId: dropDownBranchId)
              : const Loading(),
        ],
      ),
    ));
  }
}
