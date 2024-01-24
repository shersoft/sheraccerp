import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadApp extends StatefulWidget {
  const DownloadApp({
    Key? key,
  }) : super(key: key);

  @override
  State<DownloadApp> createState() => _DownloadAppState();
}

class _DownloadAppState extends State<DownloadApp> {
  late List<FileModel> fileList;

  @override
  void initState() {
    super.initState();
    fileList = [
      FileModel(title: 'SherAccERP_V21.apk', status: true),
      FileModel(title: 'SherAccERP_V20.apk', status: true),
      FileModel(title: 'SherAccERP_V19.apk', status: true),
      FileModel(title: 'SherAccERP_V18.apk', status: true),
      FileModel(title: 'SherAccERP_V17.apk', status: false),
      FileModel(title: 'SherAccERP_V16.apk', status: false),
      FileModel(title: 'SherAccERP_V15.apk', status: false),
      FileModel(title: 'SherAccERP_V14.apk', status: false),
      FileModel(title: 'SherAccERP_V13.apk', status: false),
      FileModel(title: 'SherAccERP_V12.apk', status: false),
      FileModel(title: 'SherAccERP_V11.apk', status: false),
      FileModel(title: 'SherAccERP.apk', status: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download App'),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          String title = fileList[index].title;
          bool status = fileList[index].status;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 26,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () => launchUrl(Uri.parse(
                          'https://shersoft.vindians.xyz/public/upload/$title')),
                      child: Text(
                        status ? "Download" : "Discontinued",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        itemCount: fileList.length,
      ),
    );
  }
}

class FileModel {
  String title;
  bool status;
  FileModel({
    required this.title,
    required this.status,
  });
}
