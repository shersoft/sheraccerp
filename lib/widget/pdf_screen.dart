// @dart = 2.9

import 'package:flutter/material.dart';
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';
import 'package:share/share.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFScreen extends StatelessWidget {
  final String pathPDF;
  final String text;
  final String subject;
  PDFScreen({Key key, this.pathPDF, this.text, this.subject}) : super(key: key);

  final List<String> paths = [];
  @override
  Widget build(BuildContext context) {
    //   return PDFViewerScaffold(
    //       appBar: AppBar(
    //         title: Text("PDF Document"),
    //         actions: <Widget>[
    //           IconButton(
    //             icon: Icon(Icons.share),
    //             onPressed: () {
    //               paths.add(pathPDF);
    //               urlFileShare(context, text, subject, paths);
    //             },
    //           ),
    //         ],
    //       ),
    //       path: pathPDF);
    return Scaffold(
        appBar: AppBar(
          title: const Text("PDF Document"),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                paths.add(pathPDF);
                urlFileShare(context, text, subject, paths);
              },
            ),
          ],
        ),
        body: PdfView(path: pathPDF)
        // body: SfPdfViewer.file(File(pathPDF)),
        // body: Container(),
        );
  }

  Future<void> urlFileShare(
      BuildContext context, String text, String subject, var paths) async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    if (paths.isNotEmpty) {
      await Share.shareFiles(paths,
          text: text,
          subject: subject,
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
    }
  }
}
