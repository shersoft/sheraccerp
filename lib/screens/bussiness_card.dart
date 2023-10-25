// @dart = 2.11
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';

class BusinessCard extends StatefulWidget {
  const BusinessCard({Key key}) : super(key: key);

  @override
  _BusinessCardState createState() => _BusinessCardState();
}

class _BusinessCardState extends State<BusinessCard> {
  CompanyInformation companySettings;
  List<CompanySettings> settings;

  @override
  void initState() {
    super.initState();
    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
  }

  Uint8List byteImage;
  final GlobalKey _globalKey = GlobalKey();

  Future<Uint8List> _capturePng() async {
    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext.findRenderObject();
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData.buffer.asUint8List();
      // var bs64 = base64Encode(pngBytes);
      setState(() {});
      return pngBytes;
    } catch (e) {
      // print(e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                _capturePng().then((value) => {
                      setState(() {
                        byteImage = value;
                        shareCard(context);
                      })
                    });
              }),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: MediaQuery.of(context).size.width - 10,
              child: RepaintBoundary(
                key: _globalKey,
                child: Card(
                  color: currentColor,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Container(
                      height: 200,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              companySettings.name,
                              style: TextStyle(
                                  color: currentTextColor, fontSize: 25),
                            ),
                            Text(
                              companySettings.add1,
                              style: TextStyle(
                                  color: currentTextColor, fontSize: 20),
                            ),
                            Text(
                              companyTaxMode == 'INDIA'
                                  ? 'GSTNO : ${ComSettings.getValue('GST-NO', settings)}'
                                  : 'TRN : ${ComSettings.getValue('GST-NO', settings)}',
                              style: TextStyle(
                                  color: currentTextColor, fontSize: 16),
                            ),
                            Text(
                              'Contact:' +
                                  companySettings.telephone +
                                  ' ' +
                                  companySettings.mobile,
                              style: TextStyle(
                                  color: currentTextColor, fontSize: 14),
                            ),
                            Text(
                              'Email:' + companySettings.email,
                              style: TextStyle(
                                  color: currentTextColor, fontSize: 14),
                            ),
                            Text(
                              companySettings.add2 +
                                  ',' +
                                  companySettings.add3 +
                                  ',' +
                                  companySettings.add4 +
                                  ',' +
                                  companySettings.add5,
                              style: TextStyle(
                                  color: currentTextColor, fontSize: 14),
                            ),
                            Text(
                              'PIN:' + companySettings.pin,
                              style: TextStyle(
                                  color: currentTextColor, fontSize: 14),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _showColor();
              },
              child: Container(
                width: 200,
                height: 55,
                decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: currentColor,
                    shadows: const [
                      BoxShadow(
                        color: Color.fromARGB(100, 75, 136, 230),
                        blurRadius: 10,
                        offset: Offset(0, 12),
                      )
                    ]),
                child: Center(
                    child: Text(
                  'Card Color',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: currentTextColor),
                )),
              ),
            ),
            TextButton(
              onPressed: () {
                _showTextColor();
              },
              child: Container(
                width: 200,
                height: 55,
                decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: currentColor,
                    shadows: const [
                      BoxShadow(
                        color: Color.fromARGB(100, 75, 136, 230),
                        blurRadius: 10,
                        offset: Offset(0, 12),
                      )
                    ]),
                child: Center(
                    child: Text(
                  'Change Text Color',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: currentTextColor),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color currentColor = kPrimaryDarkColor;
  Color currentTextColor = white;

  void changeColor(Color color) => setState(() => currentColor = color);
  void changeColorText(Color color) => setState(() => currentTextColor = color);

  _showColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: currentColor,
              onColorChanged: changeColor,
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }

  _showTextColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: currentTextColor,
              onColorChanged: changeColorText,
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }

  void shareCard(BuildContext context) async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    if (byteImage.isNotEmpty) {
      if (kIsWeb) {
        try {
          /**Web only**/
          // final bytes = byteImage;
          // final blob = html.Blob([bytes], 'application/pdf');
          // final url = html.Url.createObjectUrlFromBlob(blob);
          // final anchor = html.AnchorElement()
          //   ..href = url
          //   ..style.display = 'none'
          //   ..download = 'card.jpg';
          // html.document.body.children.add(anchor);
          // anchor.click();
          // html.document.body.children.remove(anchor);
          // html.Url.revokeObjectUrl(url);
        } catch (ex) {
          ex.toString();
        }
      } else {
        try {
          var output = await getTemporaryDirectory();
          final file = File('${output.path}/card.jpg');
          file.writeAsBytes(byteImage);
          String paths = file.path.toString();
          await Share.shareXFiles([XFile(paths)],
              text: 'Card',
              subject: 'Business Card',
              sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
        } catch (e) {
          // print('Share error: $e');
        }
      }
    }
  }
}
