import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class AddLogo extends StatefulWidget {
  const AddLogo({Key? key}) : super(key: key);

  @override
  State<AddLogo> createState() => _AddLogoState();
}

class _AddLogoState extends State<AddLogo> {
  var _formKey = GlobalKey<FormState>();
  final double _minimumPadding = 5.0;
  XFile? image;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Company Logo')),
      body: Form(
          key: _formKey,
          child: Padding(
              padding: EdgeInsets.all(_minimumPadding * 2),
              child: ListView(children: <Widget>[
                const SizedBox(height: 20.0),
                //update the UI
                if (image != null)
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: Column(
                      children: [
                        Expanded(child: Image.file(File(image!.path))),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              image = null;
                            });
                          },
                          label: const Text('Remove Image'),
                          icon: const Icon(Icons.close),
                        )
                      ],
                    ),
                  )
                else
                  const SizedBox(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final ImagePicker _picker = ImagePicker();
                        final img = await _picker.pickImage(
                            source: ImageSource.gallery);
                        setState(() {
                          image = img;
                        });
                      },
                      label: const Text('Choose Image'),
                      icon: const Icon(Icons.image),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final ImagePicker _picker = ImagePicker();
                        final img =
                            await _picker.pickImage(source: ImageSource.camera);
                        setState(() {
                          image = img;
                        });
                      },
                      label: const Text('Take Photo'),
                      icon: const Icon(Icons.camera_alt_outlined),
                    ),
                  ],
                ),
                Center(
                  child: Padding(
                      padding: EdgeInsets.only(
                          bottom: 3 * _minimumPadding,
                          top: 3 * _minimumPadding),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              child: const Text("Save"),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // setState(() => loading = true);
                                  save();
                                }
                              },
                            ),
                            Container(
                              width: 5.0,
                            ),
                            ElevatedButton(
                                child: const Text("Delete"),
                                onPressed: () {
                                  delete();
                                })
                          ]) // Row

                      ),
                ),
                // Padding
              ] // Column widget list
                  ) //List view
              ) // Padding
          ),
    );
  }

  Future<void> save() async {
    try {
      if (image == null) {
        setState(() {
          showMessage('image not found');
        });
      } else {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        String appDocPath = appDocDir.path;
        const fileName = 'logo.png'; //Path.basename(image.path);
        await image?.saveTo('$appDocPath/$fileName');
        setState(() {
          showMessage('image saved');
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  showMessage(message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> loadData() async {
    ///image from File path
    String filename = 'logo.png';
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = File('$dir/$filename');
    file.exists().then((value) {
      setState(() {
        image = XFile(file.path);
      });
    });
  }

  delete() async {
    try {
      if (image != null) {
        ///image from File path
        String filename = 'logo.png';
        String dir = (await getApplicationDocumentsDirectory()).path;
        File file = File('$dir/$filename');
        file.exists().then((state) {
          if (state) {
            file.delete().then((value) {
              if (state) {
                setState(() {
                  image = null;
                  showMessage('logo deleted');
                });
              } else {
                showMessage('error deleted');
              }
            });
          } else {
            showMessage('logo not found');
          }
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
