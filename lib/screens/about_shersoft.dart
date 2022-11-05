import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSherSoft extends StatelessWidget {
  AboutSherSoft({Key? key}) : super(key: key);

  launchURL() async {
    const url = 'https://Shersoftware.com';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'Shersoftware@Gmail.com',
      queryParameters: {'subject': 'about as'});

  launchPhone() async {
    const url = 'tel:+91 9847997755';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  callNumber() async {
    const number = '9847997755'; //set the number here
    // bool? res =
    await FlutterPhoneDirectCaller.callNumber(number);
  }

  smsToNumber() async {
    String url = "";
    if (Platform.isAndroid) {
      //FOR Android
      url = 'sms:9847006558?body=message';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } else if (Platform.isIOS) {
      //FOR IOS
      url = 'sms:9847006558&body=message';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  sentMail() async {
    const url = "mailto:smith@example.org?subject=News&body=New%20plugin";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.8,
                  child: Container(
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 63,
                      height: 63,
                    ),
                    const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Text(
                        "Shersoft",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text(
                        "Software Company",
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text(
                        "📌Kerala, Malappuram, Perinthalmanna",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    )
                  ],
                ),
              ),
            ),
            ListView(
              shrinkWrap: true,
              children: [
                const SizedBox(
                  height: 200,
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        "SherAcc ERP",
                        style: TextStyle(
                            color: kPrimaryDarkColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => callNumber(),
                        child: const Icon(
                          Icons.phone,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      const Text(
                        "+91 9847997755",
                        style: TextStyle(color: Colors.blue, fontSize: 18),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => launchURL(),
                        child: const Icon(
                          Icons.web,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      const Text(
                        "Shersoftware.com",
                        style: TextStyle(color: Colors.blue, fontSize: 18),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => sentMail(),
                        child: const Icon(
                          Icons.mail,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      const Text(
                        "Shersoftware@gmail.com",
                        style: TextStyle(color: Colors.blue, fontSize: 18),
                      )
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Card(
                            child: Chip(
                                shadowColor: Colors.black,
                                backgroundColor: Colors.white,
                                label: Icon(
                                  Icons.computer,
                                  color: blue,
                                ))),
                        Card(
                            child: Chip(
                                shadowColor: Colors.black,
                                backgroundColor: Colors.white,
                                label: Icon(
                                  Icons.web,
                                  color: blue,
                                ))),
                        Card(
                            child: Chip(
                                shadowColor: Colors.black,
                                backgroundColor: Colors.white,
                                label: Icon(
                                  Icons.phone_android,
                                  color: blue,
                                ))),
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Card(
                            child: Chip(
                                shadowColor: Colors.black,
                                backgroundColor: Colors.white,
                                label: Text(
                                  "Sheracc",
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 14),
                                ))),
                        Card(
                            child: Chip(
                                shadowColor: Colors.black,
                                backgroundColor: Colors.white,
                                label: Text(
                                  "SherPharma",
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 14),
                                ))),
                        Card(
                            child: Chip(
                                shadowColor: Colors.black,
                                backgroundColor: Colors.white,
                                label: Text(
                                  "SherGold",
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 14),
                                ))),
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Card(
                            child: Chip(
                                shadowColor: Colors.black,
                                backgroundColor: Colors.white,
                                label: Text(
                                  "SherDoc",
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 14),
                                ))),
                        Card(
                            child: Chip(
                                shadowColor: Colors.black,
                                backgroundColor: Colors.white,
                                label: Text(
                                  "SherTex",
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 14),
                                ))),
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Card(
                            child: Chip(
                                shadowColor: Colors.black,
                                backgroundColor: Colors.white,
                                label: Text(
                                  "&More",
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 14),
                                ))),
                      ]),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
