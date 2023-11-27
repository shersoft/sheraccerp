import 'package:flutter/material.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class SalesOtherDetailRegister extends StatefulWidget {
  const SalesOtherDetailRegister({Key? key}) : super(key: key);

  @override
  State<SalesOtherDetailRegister> createState() =>
      _SalesOtherDetailRegisterState();
}

class _SalesOtherDetailRegisterState extends State<SalesOtherDetailRegister> {
  bool isLoading = false;
  DioService api = DioService();
  List<LedgerModel> ledgerList = [];

  @override
  void initState() {
    super.initState();
    api.getLedgerListByType('SelectExpenceAndIncome').then((value) {
      List<LedgerModel> _dataTemp = [];
      for (var ledger in value) {
        _dataTemp
            .add(LedgerModel(id: ledger['ledcode'], name: ledger['LedName']));
      }
      setState(() {
        ledgerList.addAll(_dataTemp);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(actions: const [], title: const Text('Sales OtherDetails')),
      body: ProgressHUD(
          inAsyncCall: isLoading,
          opacity: 0.0,
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: const [Text('data')]))),
    );
  }
}
