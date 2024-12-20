// @dart = 2.11

import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/bussiness_card.dart';
import 'package:sheraccerp/screens/settings/add_logo.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/lang.dart';
import 'package:sheraccerp/util/res_color.dart';

class Profile extends StatefulWidget {
  const Profile({Key key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  CompanyInformation companySettings;
  List<CompanySettings> settings;
  bool viewProfile = true;
  String _dropDownTaxCalculation, _dropDownSecondFont;
  String _taxNoHint = '';
  String _dropDownState = '';
  String _stateCode = '';
  GSTStateModel gstStateM;
  DioService api = DioService();

  @override
  void initState() {
    super.initState();
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            Visibility(
              visible: viewProfile,
              child: IconButton(
                  onPressed: () {
                    setState(() {
                      viewProfile = false;
                    });
                  },
                  icon: const Icon(Icons.edit)),
            ),
            Visibility(
              visible: !viewProfile,
              child: IconButton(
                  onPressed: () {
                    setState(() {
                      updateProfile();
                    });
                  },
                  icon: const Icon(Icons.edit)),
            ),
          ],
          title: const Text('Profile'),
        ),
        body: viewProfile ? widgetView() : editProfile());
  }

  widgetView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Image.asset(
        //   'assets/logo.png',
        //   height: 90,
        //   width: 80,
        // ),
        Text(
          companySettings.name,
          style: const TextStyle(
              color: kPrimaryDarkColor,
              fontSize: 25,
              fontWeight: FontWeight.bold),
        ),
        Text(
          companySettings.add1,
          style: const TextStyle(
              letterSpacing: 1,
              color: kPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 20,
          width: 150,
          child: Divider(
            color: indigoAccent,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BusinessCard(),
            ),
          ),
          child: const Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
            child: ListTile(
              leading: Icon(
                Icons.card_membership_rounded,
                color: indigoAccent,
              ),
              title: Text(
                'Business Card',
                style: TextStyle(
                  color: blueAccent,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
          child: ListTile(
            leading: const Icon(
              Icons.phone,
              color: indigoAccent,
            ),
            title: Text(
              'Tel:' +
                  companySettings.telephone +
                  '  Mob:' +
                  companySettings.mobile,
              style: const TextStyle(
                color: blueAccent,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 25),
          child: ListTile(
            leading: const Icon(
              Icons.credit_card,
              color: indigoAccent,
            ),
            title: Text(
              companyTaxMode == 'INDIA'
                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                  : 'VATNO : ${ComSettings.getValue('GST-NO', settings)}',
              style: const TextStyle(
                color: blueAccent,
                fontSize: 15,
              ),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 25),
          child: ListTile(
            leading: const Icon(
              Icons.email,
              color: indigoAccent,
            ),
            title: Text(
              'Email:' + companySettings.email.toString(),
              style: const TextStyle(
                color: blueAccent,
                fontSize: 15,
              ),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 25),
          child: ListTile(
            leading: const Icon(
              Icons.location_on_rounded,
              color: indigoAccent,
            ),
            title: Text(
              companySettings.add2 +
                  ',' +
                  companySettings.add3 +
                  ',' +
                  companySettings.add4 +
                  ',' +
                  companySettings.add5,
              style: const TextStyle(
                color: blueAccent,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 25),
          child: ListTile(
            leading: const Icon(
              Icons.pin_rounded,
              color: indigoAccent,
            ),
            title: Text(
              'PIN:' + companySettings.pin,
              style: const TextStyle(
                color: blueAccent,
                fontSize: 15,
              ),
            ),
          ),
        ),
        Center(
          child: Card(
            child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => const AddLogo()));
                },
                child: const Text(
                  'Add Logo',
                )),
          ),
        )
      ],
    );
  }

  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _add1C = TextEditingController();
  final TextEditingController _add2C = TextEditingController();
  final TextEditingController _add3C = TextEditingController();
  final TextEditingController _add4C = TextEditingController();
  final TextEditingController _add5C = TextEditingController();
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _mobileC = TextEditingController();
  final TextEditingController _pinC = TextEditingController();
  final TextEditingController _sCurrencyC = TextEditingController();
  final TextEditingController _sNameC = TextEditingController();
  // final TextEditingController _telephoneC = TextEditingController();
  final TextEditingController _tinC = TextEditingController();
  final TextEditingController _taxNoC = TextEditingController();

  editProfile() {
    _nameC.text = (companySettings.name);
    _add1C.text = (companySettings.add1);
    _add2C.text = (companySettings.add2);
    _add3C.text = (companySettings.add3);
    _add4C.text = (companySettings.add4);
    _add5C.text = (companySettings.add5);
    _emailC.text = (companySettings.email);
    _mobileC.text = (companySettings.mobile);
    _pinC.text = (companySettings.pin);
    _sCurrencyC.text = (companySettings.sCurrency);
    _sNameC.text = (companySettings.sName);
    _dropDownTaxCalculation =
        _dropDownTaxCalculation ?? (companySettings.taxCalculation);
    _dropDownSecondFont = _dropDownSecondFont ??
        LanguageList.getLanguage(companySettings.secondFont).name.toUpperCase();
    // _telephoneC.text = (companySettings.telephone);
    _tinC.text = (companySettings.tin);
    _taxNoC.text = '${ComSettings.getValue('GST-NO', settings)}';
    _taxNoHint = companyTaxMode == 'INDIA' ? 'GSTNO ' : 'VATNO ';
    var _gstStateM = GSTStateModel(
        state: ComSettings.getValue('COMP-STATE', settings),
        code: ComSettings.getValue('COMP-STATECODE', settings));
    var gstState =
        gstStateModels.lastWhere((element) => element.code == _gstStateM.code);
    gstStateM = gstStateM ?? gstState;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _nameC,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Name'),
            ),
            const Divider(
              height: 10,
            ),
            TextField(
              controller: _add1C,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Address 1'),
            ),
            const Divider(
              height: 10,
            ),
            TextField(
              controller: _add2C,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), label: Text('Address 2')),
            ),
            const Divider(
              height: 10,
            ),
            TextField(
              controller: _add3C,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), label: Text('Address 3')),
            ),
            const Divider(
              height: 10,
            ),
            TextField(
              controller: _add4C,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), label: Text('Address 4')),
            ),
            const Divider(
              height: 10,
            ),
            TextField(
              controller: _add5C,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), label: Text('Address 5')),
            ),
            const Divider(
              height: 10,
            ),
            TextField(
              controller: _taxNoC,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(), label: Text(_taxNoHint)),
            ),
            const Divider(
              height: 10,
            ),
            TextField(
              controller: _emailC,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), label: Text('Mail Id')),
            ),
            const Divider(
              height: 10,
            ),
            TextField(
              controller: _mobileC,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), label: Text('Mobile No')),
            ),
            Card(
              elevation: 5,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('State'),
                      Text('Code'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: 40,
                        width: MediaQuery.of(context).size.width - 60,
                        child: DropdownButton<GSTStateModel>(
                          items: gstStateModels
                              .map<DropdownMenuItem<GSTStateModel>>((item) {
                            return DropdownMenuItem<GSTStateModel>(
                              value: item,
                              child: Text(
                                item.state,
                                // style: const TextStyle(fontSize: 8),
                                overflow: TextOverflow.fade,
                                softWrap: true,
                              ),
                            );
                          }).toList(),
                          onChanged: (item) {
                            setState(() {
                              _dropDownState = item.state;
                              _stateCode = item.code;
                              gstStateM = item;
                            });
                          },
                          value: gstStateM,
                        ),
                      ),
                      Text(
                        _stateCode,
                        // overflow: TextOverflow.fade,
                        // style: const TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(
              height: 10,
            ),
            TextField(
              controller: _sNameC,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), label: Text('Second Name')),
            ),
            Card(
              elevation: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Second Font'),
                  DropdownButton<String>(
                    items: secondFontList.map<DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _dropDownSecondFont = value;
                      });
                    },
                    value: _dropDownSecondFont,
                  ),
                  const Text('Tax'),
                  DropdownButton<String>(
                    items: taxCalculationList
                        .map<DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _dropDownTaxCalculation = value;
                      });
                    },
                    value: _dropDownTaxCalculation,
                  ),
                ],
              ),
            ),
            Card(
              child: Row(
                children: [
                  // const Text(
                  //   'Software Type :',
                  //   style: TextStyle(fontSize: 10),
                  // ),
                  // DropdownButton<String>(
                  //   hint: Text('Software Type'),
                  //   items:
                  //       ['SherAcc ERP'].map<DropdownMenuItem<String>>((item) {
                  //     return DropdownMenuItem<String>(
                  //       value: item,
                  //       child: Text(item),
                  //     );
                  //   }).toList(),
                  //   onChanged: (value) {
                  //     // setState(() {
                  //     //   _dropDownSecondFont = value;
                  //     // });
                  //   },
                  //   value: 'SherAcc ERP', //_dropDownSecondFont,
                  // ),
                  Expanded(
                    child: TextField(
                      controller: _pinC,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), label: Text('PinCode')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _sCurrencyC,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text('Currency')),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 10,
            ),
            // TextField(
            //   controller: _telephoneC,
            //   decoration: const InputDecoration(
            //       border: OutlineInputBorder(), label: Text('Telephone')),
            // ),
            Card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bank Account'),
                  DropdownButton<String>(
                    hint: const Text('Bank Account'),
                    items: [''].map<DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      // setState(() {
                      //   _dropDownSecondFont = value;
                      // });
                    },
                    value: '', //_dropDownSecondFont,
                  ),
                ],
              ),
            ),
            const Divider(
              height: 10,
            ),
            TextField(
              controller: _tinC,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), label: Text('Tin No')),
            ),
          ],
        ),
      ),
    );
  }

  void updateProfile() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String code = pref.getString('Code') ?? "0";
    // String companyName = pref.getString('CompanyName') ?? "0";
    String dbName = pref.getString('DBName') ?? "0";
    String taxDbName = pref.getString('DBNameT') ?? "0";
    String name = _nameC.text.trim().toUpperCase() ?? 'Company Name';
    String _secondFont =
        LanguageList.getLanguageByName(_dropDownSecondFont).code;

    var data = {
      'companyName': name,
      'code': code,
      'secondName': _sNameC.text.trim().toUpperCase(),
      'add1': _add1C.text.trim(),
      'add2': _add2C.text.trim(),
      'add3': _add3C.text.trim(),
      'add4': _add4C.text.trim(),
      'add5': _add5C.text.trim(),
      'email': _emailC.text.trim(),
      'telephone': '', //_telephoneC.text.trim(),
      'mobile': _mobileC.text.trim(),
      'pinCode': _pinC.text.trim(),
      'currency': _sCurrencyC.text.trim(),
      'taxNo': _taxNoC.text.trim(),
      'state': _dropDownState.trim(),
      'stateCode': _stateCode.trim(),
      'tin': _tinC.text.trim(),
      'taxCalculation': _dropDownTaxCalculation.trim(),
      'secondFont': _secondFont.trim(),
      'dbName': dbName,
      'taxDbName': taxDbName,
      'customerCode': companySettings.customerCode,
      'eDate': companySettings.eDate,
      'runningDate': companySettings.runningDate,
      'sDate': companySettings.sDate,
      'statement': 'Update',
    };
    api.companyUpdate(data).then((value) async {
      if (value) {
        await pref.setString("CompanyName", name);
        var dataBase = isEstimateDataBase ? dbName : taxDbName;
        showInSnackBarAction(dataBase);
        companySettings.add1 = _add1C.text.trim();
        companySettings.add2 = _add2C.text.trim();
        companySettings.add3 = _add3C.text.trim();
        companySettings.add4 = _add4C.text.trim();
        companySettings.add5 = _add5C.text.trim();
        companySettings.email = _emailC.text.trim();
        companySettings.mobile = _mobileC.text.trim();
        companySettings.name = name.toUpperCase();
        companySettings.pin = _pinC.text.trim();
        companySettings.sCurrency = _sCurrencyC.text.trim();
        companySettings.secondFont = _secondFont.trim();
        companySettings.taxCalculation = _dropDownTaxCalculation.trim();
        companySettings.tin = _tinC.text.trim();
      } else {
        showInSnackBar('error');
      }
    });
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  void showInSnackBarAction(dataBase) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Company Updated.'),
      duration: const Duration(seconds: 1),
      action: SnackBarAction(
        label: 'Click',
        onPressed: () {
          ScopedModel.of<MainModel>(context).getCompanySettingsAll(dataBase);
        },
        textColor: Colors.white,
        disabledTextColor: Colors.grey,
      ),
      backgroundColor: Colors.red,
    ));
  }
}
