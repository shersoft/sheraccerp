import 'package:flutter/material.dart';

import '../models/ledger_name_model.dart';
import '../service/api_dio.dart';

class LedgerProvider with ChangeNotifier {
  List<LedgerModel> ledgerList = [];
  DioService api = DioService();

  List<LedgerModel> _ledgerDisplay = [];
  List<LedgerModel> get ledgerDisplay => _ledgerDisplay;
  set ledgerDisplay(List<LedgerModel> value) {
    _ledgerDisplay = value;
    notifyListeners();
  }

  List<LedgerModel> _ledger = [];
  List<LedgerModel> get ledger => _ledger;
  set ledger(List<LedgerModel> value) {
    _ledger = value;
    notifyListeners();
  }

  LedgerProvider() {
    loadLedger();
  }
  loadLedger() async {
    ledgerList = await api.getLedgerAll();
    ledgerDisplay = ledgerList;
    ledger = ledgerList;
    notifyListeners();
  }
}
