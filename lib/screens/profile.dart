// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/bussiness_card.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';

class Profile extends StatefulWidget {
  const Profile({Key key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  CompanyInformation companySettings;
  List<CompanySettings> settings;

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
          actions: const [],
          title: const Text('Profile'),
        ),
        body: Column(
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
                  fontFamily: 'Poppins',
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
                  builder: (context) => const BussinessCard(),
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
                    'Bussiness Card',
                    style: TextStyle(
                      fontFamily: 'Poppins',
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
                    fontFamily: 'Poppins',
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
                      : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
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
                    fontFamily: 'Poppins',
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
                    fontFamily: 'Poppins',
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
                    fontFamily: 'Poppins',
                    color: blueAccent,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
