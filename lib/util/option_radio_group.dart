// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:sheraccerp/util/res_color.dart';

class OptionRadio extends StatefulWidget {
  final String text;
  final int index;
  final int selectedButton;
  final Function press;

  const OptionRadio({
    Key key,
    this.text,
    this.index,
    this.selectedButton,
    this.press,
  }) : super(key: key);

  @override
  OptionRadioPage createState() => OptionRadioPage();
}

class OptionRadioPage extends State<OptionRadio> {
  // QuestionController controllerCopy =QuestionController();

  int id = 1;

  OptionRadioPage();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.press(widget.index);
      },
      child: Row(
        children: [
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                  unselectedWidgetColor: Colors.grey,
                  disabledColor: Colors.blue),
              child: Column(children: [
                RadioListTile(
                  title: Text(
                    "${widget.index + 1}. ${widget.text}",
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    softWrap: true,
                  ),
                  groupValue: widget.selectedButton,
                  value: widget.index,
                  activeColor: kPrimaryColor,
                  onChanged: (val) async {
                    widget.press(widget.index);
                  },
                  toggleable: true,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
