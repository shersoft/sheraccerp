// @dart = 2.7
import 'package:flutter/material.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';

class PriceList extends StatefulWidget {
  const PriceList({Key key}) : super(key: key);

  @override
  State<PriceList> createState() => _PriceListState();
}

class _PriceListState extends State<PriceList> {
  List<dynamic> dataList;
  bool loadReport = false;
  DioService api = DioService();
  var itemId,
      itemName,
      location = {'id': 1, 'name': defaultLocation},
      title = '';
  final controller = ScrollController();
  double offset = 0;
  var dropDownBranchId;

  @override
  void initState() {
    super.initState();

    if (locationList.isNotEmpty) {
      dropDownBranchId = locationList
          .where((element) => element.value == defaultLocation)
          .map((e) => e.key)
          .first;
    }

    var query = {
      'statementType': 'PriceList',
      'date': '2000-01-01',
      'minus': '',
      "sDate": '2000-01-01',
      "eDate": '2000-01-01',
      "location": 1,
      "uniqueCode": 0,
      "itemId": 0,
      "itemCode": '',
      "itemName": '',
      "mfr": 0,
      "category": 0,
      "subCategory": 0,
      "rack": 0,
      "taxGroup": 0,
      "supplier": 0,
      'unitId': 0,
      "itemMovingType": ''
    };

    api.getStockReport(query).then((value) {
      setState(() {
        loadReport = true;
        dataList = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {
                  setState(
                    () {},
                  );
                }),
          ],
          title: const Text('Price List'),
        ),
        body: loadReport ? report() : const Loading());
  }

  report() {
    var col = dataList[0].keys.toList();
    return SingleChildScrollView(
      child: PaginatedDataTable(
        // header: Text('DataTable Header'),
        rowsPerPage: 100,
        horizontalMargin: 10,
        columnSpacing: 10,
        showFirstLastButtons: true,
        arrowHeadColor: black,
        // columnSpacing: 100,
        // horizontalMargin: 10,
        dataRowHeight: 20,
        headingRowHeight: 30,
        showCheckboxColumn: true,
        columns: [
          for (int i = 0; i < col.length; i++)
            DataColumn(
              label: Align(
                alignment: Alignment.center,
                child: Text(
                  col[i],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
        source: DTS(context, dataList),
        // onRowsPerPageChanged: (value) {
        //   setState(() {
        //     _rowPerPage = value;
        //   });
        // },
      ),
    );
  }
}

class DTS extends DataTableSource {
  final List<dynamic> data;
  final BuildContext context;

  DTS(this.context, this.data);
  @override
  DataRow getRow(int index) {
    final tableColumn = data[0].keys.toList();
    final values = data[index];
    return DataRow.byIndex(
        onLongPress: () {
          String name = values['ItemName'];
          Navigator.pushNamed(context, '/product', arguments: {'name': name});
        },
        index: index,
        cells: [
          for (int i = 0; i < values.length; i++)
            DataCell(
              Align(
                alignment: ComSettings.oKNumeric(
                  values[tableColumn[i]] != null
                      ? values[tableColumn[i]].toString()
                      : '',
                )
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  values[tableColumn[i]] != null
                      ? values[tableColumn[i]].toString()
                      : '',
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  // style: TextStyle(fontSize: 6),
                ),
              ),
            ),
        ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
//   TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           actions: [
//             IconButton(
//                 icon: const Icon(Icons.share_rounded),
//                 onPressed: () {
//                   setState(
//                     () {},
//                   );
//                 }),
//           ],
//           title: const Text('Price List'),
//         ),
//         body: loadReport ? report() : const Loading() //reportView()
//         );
//   }

//   report() {
//     var col = dataList[0].keys.toList();
//     return Padding(
//       padding: const EdgeInsets.all(5.0),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.vertical,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: TextField(
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   labelText: 'Search by name',
//                   suffixIcon: IconButton(
//                     icon: const Icon(Icons.clear),
//                     onPressed: () {
//                       setState(() {
//                         _searchController.clear();
//                         _searchQuery = '';
//                       });
//                     },
//                   ),
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     _searchQuery = value;
//                   });
//                 },
//               ),
//             ),
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: DataTable(
//                 headingRowColor: MaterialStateColor.resolveWith(
//                     (states) => Colors.grey.shade200),
//                 border: TableBorder.all(width: 1.0, color: Colors.black),
//                 columnSpacing: 12,
//                 dataRowHeight: 20,
//                 headingRowHeight: 30,
//                 columns: [
//                   for (int i = 0; i < col.length; i++)
//                     DataColumn(
//                       label: Align(
//                         alignment: Alignment.center,
//                         child: Text(
//                           col[i],
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                 ],
//                 rows: _buildRows(col),
//               ),
//             ),
//             // SizedBox(height: 500),
//           ],
//         ),
//       ),
//     );
//   }

//   List<DataRow> _buildRows(col) {
//     List<DataRow> rows = [];
//     List<dynamic> data = dataList;

//     List<dynamic> filteredData = data
//         .where((item) =>
//             item['ItemName'].toLowerCase().contains(_searchQuery.toLowerCase()))
//         .toList();

//     for (var values in filteredData) {
//       rows.add(DataRow(
//         onLongPress: () {
//           String name = values['ItemName'];
//           Navigator.pushNamed(context, '/product', arguments: {'name': name});
//         },
//         cells: [
//           for (int i = 0; i < values.length; i++)
//             DataCell(
//               Align(
//                 alignment: ComSettings.oKNumeric(
//                   values[col[i]] != null ? values[col[i]].toString() : '',
//                 )
//                     ? Alignment.centerRight
//                     : Alignment.centerLeft,
//                 child: Text(
//                   values[col[i]] != null ? values[col[i]].toString() : '',
//                   softWrap: true,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ),
//         ],
//       ));
//     }

//     return rows;
//   }

//   reportView() {
//     var data = {
//       'statementType': 'PriceList',
//       'date': '2000-01-01',
//       'minus': '',
//       "sDate": '2000-01-01',
//       "eDate": '2000-01-01',
//       "location": 1,
//       "uniqueCode": 0,
//       "itemId": 0,
//       "itemCode": '',
//       "itemName": '',
//       "mfr": 0,
//       "category": 0,
//       "subCategory": 0,
//       "rack": 0,
//       "taxGroup": 0,
//       "supplier": 0,
//       'unitId': 0,
//       "itemMovingType": ''
//     };
//     return FutureBuilder<List<dynamic>>(
//       future: api.getStockReport(data),
//       builder: (ctx, snapshot) {
//         if (snapshot.hasData) {
//           if (snapshot.data.isNotEmpty) {
//             var data = snapshot.data;
//             var col = data[0].keys.toList();
//             return Padding(
//               padding: const EdgeInsets.all(5.0),
//               child: SingleChildScrollView(
//                 scrollDirection: Axis.vertical,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Center(
//                         child: Text(
//                       'Price List',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     )),
//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: DataTable(
//                         headingRowColor: MaterialStateColor.resolveWith(
//                             (states) => Colors.grey.shade200),
//                         border:
//                             TableBorder.all(width: 1.0, color: Colors.black),
//                         columnSpacing: 12,
//                         dataRowHeight: 20,
//                         headingRowHeight: 30,
//                         columns: [
//                           for (int i = 0; i < col.length; i++)
//                             DataColumn(
//                               label: Align(
//                                 alignment: Alignment.center,
//                                 child: Text(
//                                   col[i],
//                                   style: const TextStyle(
//                                       fontWeight: FontWeight.bold),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                             ),
//                         ],
//                         rows: data
//                             .map(
//                               (values) => DataRow(
//                                 cells: [
//                                   for (int i = 0; i < values.length; i++)
//                                     DataCell(
//                                       Align(
//                                         alignment: ComSettings.oKNumeric(
//                                           values[col[i]] != null
//                                               ? values[col[i]].toString()
//                                               : '',
//                                         )
//                                             ? Alignment.centerRight
//                                             : Alignment.centerLeft,
//                                         child: Text(
//                                           values[col[i]] != null
//                                               ? values[col[i]].toString()
//                                               : '',
//                                           softWrap: true,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             )
//                             .toList(),
//                       ),
//                     ),
//                     // SizedBox(height: 500),
//                   ],
//                 ),
//               ),
//             );
//           } else {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: const <Widget>[
//                   SizedBox(height: 20),
//                   Text('No Data Found..')
//                 ],
//               ),
//             );
//           }
//         } else if (snapshot.hasError) {
//           return AlertDialog(
//             title: const Text(
//               'An Error Occurred!',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.redAccent,
//               ),
//             ),
//             content: Text(
//               "${snapshot.error}",
//               style: const TextStyle(
//                 color: Colors.blueAccent,
//               ),
//             ),
//             actions: <Widget>[
//               TextButton(
//                 child: const Text(
//                   'Go Back',
//                   style: TextStyle(
//                     color: Colors.redAccent,
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               )
//             ],
//           );
//         }
//         // By default, show a loading spinner.
//         return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: const <Widget>[
//               CircularProgressIndicator(),
//               SizedBox(height: 20),
//               Text('This may take some time..')
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
