import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerWidget extends StatefulWidget {
  const ColorPickerWidget({Key? key}) : super(key: key);

  @override
  State createState() => ColorPickerWidgetState();
}

class ColorPickerWidgetState extends State {
  Color currentColor = Colors.amber;

  void changeColor(Color color) => setState(() => currentColor = color);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Color Picker Example'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'HSV'),
              Tab(text: 'Material'),
              Tab(text: 'Block'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                          titlePadding: const EdgeInsets.all(0.0),
                          contentPadding: const EdgeInsets.all(0.0),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: currentColor,
                              onColorChanged: changeColor,
                              colorPickerWidth: 300.0,
                              pickerAreaHeightPercent: 0.7,
                              enableAlpha: true,
                              displayThumbColor: true,
                              // showLabel: true,
                              labelTypes: const [],
                              paletteType: PaletteType.hsv,
                              pickerAreaBorderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2.0),
                                topRight: Radius.circular(2.0),
                              ),
                            ),
                          ));
                    },
                  );
                },
                child: const Text('Change me'),
                style: ElevatedButton.styleFrom(
                  elevation: 3.0,
                  primary: currentColor,
                  textStyle: TextStyle(
                    color: useWhiteForeground(currentColor)
                        ? const Color(0xffffffff)
                        : const Color(0xff000000),
                  ),
                ),
              ),
            ),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 3.0,
                  primary: currentColor,
                  textStyle: TextStyle(
                    color: useWhiteForeground(currentColor)
                        ? const Color(0xffffffff)
                        : const Color(0xff000000),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        titlePadding: const EdgeInsets.all(0.0),
                        contentPadding: const EdgeInsets.all(0.0),
                        content: SingleChildScrollView(
                          child: MaterialPicker(
                            pickerColor: currentColor,
                            onColorChanged: changeColor,
                            enableLabel: true,
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Text('Change me'),
              ),
            ),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 3.0,
                  primary: currentColor,
                  textStyle: TextStyle(
                    color: useWhiteForeground(currentColor)
                        ? const Color(0xffffffff)
                        : const Color(0xff000000),
                  ),
                ),
                onPressed: () {
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
                      );
                    },
                  );
                },
                child: const Text('Change me'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
