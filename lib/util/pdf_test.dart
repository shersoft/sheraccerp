import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

class Message {
  Message(this.image, this.sendPort);
  final Uint8List image;
  final SendPort sendPort;
}

Future<Uint8List> download(String url) async {
  final HttpClient client = HttpClient();
  final HttpClientRequest request = await client.getUrl(Uri.parse(url));
  final HttpClientResponse response = await request.close();
  final BytesBuilder builder = await response.fold(
      BytesBuilder(), (BytesBuilder b, List<int> d) => b..add(d));
  final List<int> data = builder.takeBytes();
  return Uint8List.fromList(data);
}

void compute(Message message) {
  final Document pdf = Document();
  final PdfImage image = PdfImage.jpeg(
    pdf.document,
    image: message.image,
  );
  // pdf.addPage(Page(build: (Context context) => Center(child: Image(image))));
  message.sendPort.send(pdf.save());
}

Future<void> main() async {
  final Completer<void> completer = Completer<void>();
  final ReceivePort receivePort = ReceivePort();
  receivePort.listen((dynamic data) async {
    if (data is List<int>) {
      // debugPrint('Received a ${data.length} bytes PDF');
      final File file = File('isolate.pdf');
      await file.writeAsBytes(data);
      // debugPrint('File saved');
    }
    completer.complete();
  });
  // debugPrint('Download image');
  final Uint8List imageBytes = await download(
      'https://s3-us-west-2.amazonaws.com/uw-s3-cdn/wp-content/uploads/sites/6/2017/11/04133712/waterfall-750x500.jpg');
  // debugPrint('Generate PDF');
  await Isolate.spawn<Message>(
    compute,
    Message(imageBytes, receivePort.sendPort),
  );
  // debugPrint('Wait PDF to be generated');
  await completer.future;
  // debugPrint('Done');
}
