import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:sheraccerp/models/sms_data_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class SmsSettings extends StatefulWidget {
  const SmsSettings({Key? key}) : super(key: key);

  @override
  State<SmsSettings> createState() => _SmsSettingsState();
}

class _SmsSettingsState extends State<SmsSettings> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  DioService api = DioService();
  final contentControl = TextEditingController();
  final apiLinkControl = TextEditingController();
  final mobileNoControl = TextEditingController();
  List<String> messageTips = [
    "#MobileNo#",
    "#Customer#",
    "#CompanyName#",
    "#OB#",
    "#ThisBill#",
    "#CashReceived#",
    "#TotalBalance#",
    "#NetBalance#",
    "#ItemName#",
    "#Qty#",
    "#Rate#",
    "#Total#",
    "#GrandTotal#",
    "#EntryNo#",
    "#Narration#"
  ];
  List<String> entryType = [
    "",
    "SALES",
    "RECEIPT",
    "PAYMENT",
    "DEBIT NOTE",
    "CREDIT NOTE"
  ];
  GlobalKey<AutoCompleteTextFieldState<String>> keyEntryName = GlobalKey();
  String entryName = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('SMS Settings'),
      ),
      body: ProgressHUD(
        inAsyncCall: _isLoading,
        opacity: 0.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                elevation: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('Entry name'),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child:
                              Text('Select type', textAlign: TextAlign.center),
                        ),
                        value: entryName,
                        items: entryType.map<DropdownMenuItem<String>>((item) {
                          return DropdownMenuItem<String>(
                            value: item.toString(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(item,
                                  style: const TextStyle(
                                      overflow: TextOverflow.ellipsis)),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            entryName = value!;
                            loadSmSData(entryName);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
              ),
              TextFormField(
                controller: contentControl,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Content',
                    hintText:
                        '${messageTips[0]} \n ${messageTips[1]} \n ${messageTips[2]} \n ${messageTips[3]}  ${messageTips[4]} \n ${messageTips[5]} \n ${messageTips[6]}   ${messageTips[7]} \n ${messageTips[8]} \n ${messageTips[9]} ${messageTips[10]} \n ${messageTips[11]}  ${messageTips[12]} \n ${messageTips[13]}'),
                maxLines: 10,
                autofillHints: messageTips,
              ),
              const Divider(),
              const Center(
                child: Text(
                  'Type Mobile No  As #MobileNo# and Message As #SMS# In API Link',
                  style: TextStyle(fontSize: 10),
                ),
              ),
              const Divider(),
              TextField(
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                controller: apiLinkControl,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: 'API Link'),
              ),
              const Divider(
                height: 1,
              ),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    if (entryName.isNotEmpty &&
                        contentControl.text.isNotEmpty &&
                        apiLinkControl.text.isNotEmpty) {
                      var dataMap = {
                        'voucher': entryName.trim(),
                        'messageBody': contentControl.text.toString().trim(),
                        'apiLink': apiLinkControl.text.toString().trim(),
                      };
                      api.saveSmsApi(dataMap).then((value) {
                        if (value) {
                          if (smsSettingsList != null &&
                              smsSettingsList.isNotEmpty) {
                            SmsDataModel dataModel = smsSettingsList.firstWhere(
                                (element) =>
                                    element.voucher == entryName.trim(),
                                orElse: () => SmsDataModel(
                                    voucher: '', messageBody: '', apiLink: ''));
                            if (dataModel.voucher.isNotEmpty) {
                              dataModel.voucher =
                                  entryName.trim().toUpperCase();
                              dataModel.messageBody =
                                  contentControl.text.trim().toUpperCase();
                              dataModel.apiLink =
                                  apiLinkControl.text.trim().toUpperCase();
                            } else {
                              dataModel.voucher =
                                  entryName.trim().toUpperCase();
                              dataModel.messageBody =
                                  contentControl.text.trim().toUpperCase();
                              dataModel.apiLink =
                                  apiLinkControl.text.trim().toUpperCase();
                            }
                            smsSettingsList[smsSettingsList.indexWhere(
                                    (element) =>
                                        element.voucher ==
                                        entryName.trim().toUpperCase())] =
                                dataModel;
                          }
                          showInSnackBar('Saved');
                        } else {
                          showInSnackBar('Error');
                        }
                        setState(() {
                          _isLoading = false;
                        });
                      });
                    } else {
                      String msg = '';
                      if (entryName.isEmpty) {
                        msg = 'Select Entry';
                      } else if (contentControl.text.isEmpty) {
                        msg = 'type content';
                      } else if (apiLinkControl.text.isEmpty) {
                        msg = 'fill api link';
                      }
                      showInSnackBar(msg);
                    }
                  },
                  child: const Text('Save')),
              ElevatedButton(
                  onPressed: () {
                    if (entryName.isNotEmpty &&
                        contentControl.text.isNotEmpty &&
                        apiLinkControl.text.isNotEmpty) {
                      var urlData = apiLinkControl.text.toString().trim();
                      urlData = urlData
                          .replaceFirst("#MobileNo#",
                              mobileNoControl.text.toString().trim())
                          .replaceFirst(
                              "#SMS#", contentControl.text.toString().trim());

                      api.sentSmsOverApi(urlData).then((value) =>
                          showInSnackBar(value ? 'sms sent' : 'sms failed'));
                    } else {
                      String msg = '';
                      if (entryName.isEmpty) {
                        msg = 'Select Entry';
                      } else if (contentControl.text.isEmpty) {
                        msg = 'type content';
                      } else if (apiLinkControl.text.isEmpty) {
                        msg = 'fill api link';
                      }
                      showInSnackBar(msg);
                    }
                  },
                  child: const Text('Test SMS'))
            ],
          ),
        ),
      ),
    );
  }

  void loadSmSData(String voucher) {
    if (smsSettingsList != null && smsSettingsList.isNotEmpty) {
      SmsDataModel data = smsSettingsList.firstWhere(
          (element) => element.voucher == voucher,
          orElse: () =>
              SmsDataModel(voucher: '', messageBody: '', apiLink: ''));
      if (data.voucher.isNotEmpty) {
        setState(() {
          apiLinkControl.text = data.apiLink;
          contentControl.text = data.messageBody;
        });
      }
    }
  }

  void showInSnackBar(String value) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
