import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sheraccerp/shared/constants.dart';

class KSAQR extends StatefulWidget {
  const KSAQR({Key? key}) : super(key: key);

  @override
  _KSAQRState createState() => _KSAQRState();
}

class _KSAQRState extends State<KSAQR> {

  String content ="1234567890";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Generate QR Code")),
      ),
      body: Column(
        children: [
          Text(SaudiConversion.getBase64("SAFVAN P","300068657700003","2021-12-15 14:56:51", "1000.00", "100.00")),
          const SizedBox(height: 10),
          const Expanded(
          flex: 5,
            child: Text('XX'),//QrImage(data: SaudiConversion.getBase64("SAFVAN P","300068657700003","2021-12-09T13:22:09", "1000.00", "100.00"),size: 200,),
          ),
          TextButton(onPressed: (){
            //
          }, child: const Text('Generate'))//Image(data: qrData),
        ],
      ),
    );
  }
}
