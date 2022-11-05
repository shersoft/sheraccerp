// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class Ledger extends StatefulWidget {
  const Ledger({Key key}) : super(key: key);

  @override
  _LedgerState createState() => _LedgerState();
}

class _LedgerState extends State<Ledger> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _name = TextEditingController();
  final _add1 = TextEditingController();
  final _add2 = TextEditingController();
  final _add3 = TextEditingController();
  final _add4 = TextEditingController();
  final _city = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _email = TextEditingController();
  final _taxNo = TextEditingController();
  final _state = TextEditingController();
  final _stateCode = TextEditingController();
  final _route = TextEditingController();

  DioService api = DioService();
  bool _isLoading = false, valueActive = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final routes =
        ModalRoute.of(context).settings.arguments as Map<String, String>;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text("Ledger"),
        actions: <Widget>[
          SizedBox(
            width: 80,
            child: Card(
              color: Colors.blue,
              child: IconButton(
                icon: const Text(
                  'SAVE',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white),
                ),
                onPressed: () {
                  _handleSubmitted();
                  // if (_formKey.currentState.validate()) {
                  // contactRepository.insert({
                  //   'name': _cName.text,
                  //   'nickName': _cNickName.text,
                  //   'work': _cWork.text,
                  //   'phoneNumber': _cPhoneNumber.text,
                  //   'email': _cEmail.text,
                  //   'webSite': _cWebSite.text,
                  //   'favorite': 0,
                  //   'created': DateTime.now().toString()
                  // }).then((saved) {
                  //   bloc.getListContact();
                  //   Navigator.of(context).pop();
                  // });
                  // }
                },
              ),
            ),
          )
        ],
      ),
      body: ProgressHUD(
        inAsyncCall: _isLoading,
        opacity: 0.0,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            // SizedBox(height: 20),
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: <Widget>[
            //     Container(
            //       width: 80.0,
            //       height: 80.0,
            //       child: CircleAvatar(
            //         child: Icon(
            //           Icons.camera_alt,
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _name,
                      // autofocus: true,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(45),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        icon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'add name';
                        }
                        return null;
                      },
                    ),
                    widgetParent(
                        routes != null ? routes['parent'].toString() : ''),
                    TextFormField(
                      controller: _add1,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(25),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        icon: Icon(Icons.person),
                      ),
                    ),
                    TextFormField(
                      controller: _phoneNumber,
                      maxLength: 12,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Telephone",
                        icon: Icon(Icons.phone),
                      ),
                    ),
                    TextFormField(
                      controller: _email,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50),
                      ],
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        icon: Icon(Icons.email),
                      ),
                    ),
                    TextFormField(
                      controller: _taxNo,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50),
                      ],
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Tax No',
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Active'),
                        Checkbox(
                          value: valueActive,
                          onChanged: (bool value) {
                            setState(() {
                              valueActive = value;
                            });
                          },
                        ),
                      ],
                    ),
                    ExpansionTile(
                      key: GlobalKey(),
                      title: const Text('more'),
                      children: [
                        TextFormField(
                          controller: _add2,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Address 2',
                          ),
                        ),
                        TextFormField(
                          controller: _add3,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Address 3',
                          ),
                        ),
                        TextFormField(
                          controller: _add4,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Address 4',
                          ),
                        ),
                        TextFormField(
                          controller: _city,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(45),
                          ],
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            icon: Icon(Icons.location_city),
                          ),
                        ),
                        TextFormField(
                          controller: _route,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'Route',
                          ),
                        ),
                        TextFormField(
                          controller: _state,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'State',
                          ),
                        ),
                        TextFormField(
                          controller: _stateCode,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'State Code',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted() async {
    setState(() {
      _isLoading = true;
    });
    final FormState form = _formKey.currentState;
    if (!form.validate()) {
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      SharedPreferences pref = await SharedPreferences.getInstance();
      var _regId = (pref.getString('regId') ?? "");
      if (_regId == "") {
        showInSnackBar('Sorry! your company not found');
      } else {
        form.save();
        var name = _name.text,
            add1 = _add1.text,
            add2 = _add2.text,
            add3 = _add3.text,
            add4 = _add4.text,
            city = _city.text.isNotEmpty ? 1 : 0,
            route = _route.text.isNotEmpty ? 1 : 0,
            state = _state.text,
            stateCode = _stateCode.text,
            mobile = _phoneNumber.text,
            email = _email.text,
            taxNo = _taxNo.text;
        var data = [
          {
            'name': name.toUpperCase(),
            'parent': _dropDownValue.split('-')[0],
            'add1': add1.toUpperCase(),
            'add2': add2.toUpperCase(),
            'add3': add3.toUpperCase(),
            'add4': add4.toUpperCase(),
            'city': city,
            'route': route,
            'state': state.toUpperCase(),
            'stateCode': stateCode,
            'mobile': mobile,
            'email': email,
            'taxNo': taxNo,
            'active': valueActive ? 1 : 0
          }
        ];
        bool result = await api.spLedgerAdd(data);
        if (result) {
          _saveAndRedirectToHome();
        } else {
          showInSnackBar('error : Cannot save this Ledger.');
        }
      }
    }
  }

  void _saveAndRedirectToHome() async {
    setState(() {
      _isLoading = false;
      showInSnackBar('Saved : Ledger created.');
    });
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });
    // _scaffoldKey.currentState
    //     .showSnackBar(new SnackBar(content: new Text(value)));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String _dropDownValue = '';
  widgetParent(parent) {
    if (parent.length > 0) {}
    return FutureBuilder(
      future: api.getLedgerParent(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (parent.length > 0) {
            for (var i = 0; i < snapshot.data.length; i++) {
              var dyn = snapshot.data[i];
              var sName = dyn.name;
              if (sName == parent) {
                _dropDownValue = dyn.id.toString() + "-" + dyn.name;
                break;
              }
            }
          }
        }
        return snapshot.hasData
            ? DropdownButton<String>(
                hint: Text(_dropDownValue.isNotEmpty
                    ? _dropDownValue.split('-')[1]
                    : 'select under'),
                items: snapshot.data.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item.id.toString() + "-" + item.name,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _dropDownValue = value;
                    // _dropDownName = item.toString();
                    // rateType = value.split('-')[0];
                    // print(value + '=' + rateType);
                  });
                },
              )
            : const Center(
                child: Loading(),
              );
      },
    );
  }
}
