// @dart = 2.11
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/print_settings_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';

class GenerateEWaybill extends StatefulWidget {
  final data;
  final type;
  GenerateEWaybill({
    Key key,
    this.data,
    this.type,
  }) : super(key: key);

  @override
  State<GenerateEWaybill> createState() => _GenerateEWaybillState();
}

class _GenerateEWaybillState extends State<GenerateEWaybill> {
  dynamic data;
  var information, particulars, serialNO, deliveryNoteDetails;
  List otherAmountList;
  String formattedDate, _narration = '';
  DateTime now = DateTime.now();
  CompanyInformation companySettings;
  List<CompanySettings> settings;
  PrintSettingsModel printSettingsModel;

  List<String> supplyType = ["Outward", "Inward"];
  List<String> subSupplyType = [
    "Supply",
    "Import",
    "Export",
    "Job Work",
    "For Own Use",
    "Job work Returns",
    "Sales Return",
    "SKD/CKD",
    "Line Sales",
    "Recipient Not Known",
    "Exhibition or Fairs",
    "Others"
  ];
  List<String> doctype = [
    "Tax Invoice",
    "Bill of Supply",
    "Bill of Entry",
    "Delivery Challan",
    "Credit Note",
    "Others"
  ];
  List<String> transMode = ["Road", "Rail", "Air", "Ship"];
  List<String> vehicleType = ["Regular", "ODC"];
  List<String> transactionType = [
    "Regular",
    "Bill To-Ship To",
    "Bill From-Dispatch From",
    "Combination of 2 and 3"
  ];
  String ipAddress = '127.0.0.1';
  DioService api = DioService();
  String invoiceId = '',
      invoiceNo = '',
      invoiceDate = '',
      entryType = '',
      eWaybillNo = '';
  TextEditingController cGstNoControl = TextEditingController();
  TextEditingController cNameControl = TextEditingController();
  TextEditingController cAddress1Control = TextEditingController();
  TextEditingController cAddress2Control = TextEditingController();
  TextEditingController cAddress3Control = TextEditingController();
  TextEditingController cAddress4Control = TextEditingController();
  TextEditingController cStateControl = TextEditingController();
  TextEditingController cStateCodeControl = TextEditingController();
  TextEditingController actualStateCodeControl = TextEditingController();
  TextEditingController cPinCodeControl = TextEditingController();
  TextEditingController cEmailControl = TextEditingController();
  TextEditingController cPhoneControl = TextEditingController();

  TextEditingController gstNoControl = TextEditingController();
  TextEditingController nameControl = TextEditingController();
  TextEditingController address1Control = TextEditingController();
  TextEditingController address2Control = TextEditingController();
  TextEditingController address3Control = TextEditingController();
  TextEditingController address4Control = TextEditingController();
  TextEditingController pinCodeControl = TextEditingController();
  TextEditingController stateCodeControl1 = TextEditingController();
  TextEditingController stateCodeControl2 = TextEditingController();

  TextEditingController transporterControl = TextEditingController(text: "OWN");
  TextEditingController transporterIdControl = TextEditingController();
  TextEditingController transDocNoControl = TextEditingController();
  TextEditingController transDocDateControl = TextEditingController();
  TextEditingController invoiceNoControl = TextEditingController();
  TextEditingController invoiceDateControl = TextEditingController();
  TextEditingController distanceControl = TextEditingController();
  TextEditingController totalValueControl = TextEditingController();
  TextEditingController cGSTControl = TextEditingController();
  TextEditingController sGSTControl = TextEditingController();
  TextEditingController iGSTControl = TextEditingController();
  TextEditingController cessControl = TextEditingController();
  TextEditingController totalControl = TextEditingController();
  TextEditingController mainHSNControl = TextEditingController();
  TextEditingController otherChargeControl = TextEditingController();
  TextEditingController refNoControl = TextEditingController();
  TextEditingController eWayBillNoControl = TextEditingController();
  TextEditingController vehicleControl = TextEditingController();
  TextEditingController xControl = TextEditingController();
  String cGstNo = '',
      cName = '',
      cState = '',
      cStateCode = '',
      actualStateCode = '',
      cAddress1 = '',
      cAddress2 = '',
      cAddress3 = '',
      cAddress4 = '',
      cPinCode = '',
      cEmail = '',
      cPhone = '';
  String gstNo = '',
      name = '',
      state = '',
      stateCode1 = '',
      stateCode2 = '',
      address1 = '',
      address2 = '',
      address3 = '',
      address4 = '',
      pinCode = '',
      email = '',
      phone = '';
  String supplyTypeValue = 'Outward',
      subSupplyTypeValue = 'Supply',
      doctypeValue = 'Tax Invoice',
      transModeValue = 'Road',
      vehicleTypeValue = 'Regular',
      transactionTypeValue = 'Regular';
  String distance = '', vehicle = '';
  bool isKmLoading = false;

  @override
  void initState() {
    super.initState();
    entryType = widget.type ?? '';
    formattedDate = DateFormat('dd/MM/yyyy').format(now);
    data = widget.data;
    information = data['Information'][0];
    particulars = data['Particulars'];
    serialNO = data['SerialNO'];
    deliveryNoteDetails = data['DeliveryNote'];
    otherAmountList = data['otherAmount'];

    invoiceId = information['EntryNo'].toString();
    invoiceNo = information['InvoiceNo'].toString();
    invoiceDate = DateUtil.dateDMY1(information['DDate'].toString());
    invoiceNoControl.text = invoiceNo;
    invoiceDateControl.text = invoiceDate;

    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();

    // manualInvoiceNumberInSales =
    //     ComSettings.getStatus('MANNUAL INVOICE NUMBER IN SALES', settings);
    // eWayBillClient = ComSettings.getValue('EWAYBILLAPI OWNER', settings);
    cGstNo = ComSettings.getValue('GST-NO', settings);
    cGstNoControl.text = cGstNo;
    cState = ComSettings.getValue('COMP-STATE', settings);
    cStateControl.text = cState;
    cStateCode = ComSettings.getValue('COMP-STATECODE', settings);
    cStateCodeControl.text = cStateCode;
    actualStateCodeControl.text = cStateCode;
    cAddress1 = companySettings.add1;
    cAddress1Control.text = cAddress1;
    cAddress2 = companySettings.add2;
    cAddress2Control.text = cAddress2;
    cAddress3 = companySettings.add3;
    cAddress3Control.text = cAddress3;
    cAddress4 = companySettings.add4;
    cAddress4Control.text = cAddress4;
    var cAddress5 = companySettings.add5;
    cEmail = companySettings.email;
    cEmailControl.text = cEmail;
    cName = companySettings.name;
    cNameControl.text = cName;
    cPhone = companySettings.mobile;
    cPhoneControl.text = cPhone;
    cPinCode = companySettings.pin;
    cPinCodeControl.text = cPinCode;
    var sName = companySettings.sName;
    var tel = companySettings.telephone;

    if (printSettingsList != null) {
      if (printSettingsList.isNotEmpty) {
        printSettingsModel = printSettingsList.firstWhere(
            (element) =>
                element.model == 'INVOICE DESIGNER' &&
                element.dTransaction == widget.type &&
                element.fyId == currentFinancialYear.id,
            orElse: () => printSettingsList.isNotEmpty
                ? printSettingsList[0]
                : PrintSettingsModel.empty());
      }
    }
    entryType = widget.type ?? '';
    // salestype = salestype;
    // this._salesno = entryno;
    // this.TxtEwayBillNo.Text = ewb;
    if (eWaybillNo.isNotEmpty) {
      // DataSet ds = this.dbSelectData2("Find", ewb);
      // if (ds != null && ds.Tables[0].Rows.Count > 0)
      // {
      //     this.cmbsupplytype.SelectedIndex = Convert.ToInt32(ds.Tables[0].Rows[0]["SupplyType"].ToString());
      //     this.txtinvoiceno.Text = ds.Tables[0].Rows[0]["InvoiceNo"].ToString();
      //     this.cmbtransmode.SelectedIndex = Convert.ToInt32(ds.Tables[0].Rows[0]["TransMode"].ToString());
      //     this.cmbvehicletype.SelectedIndex = Convert.ToInt32(ds.Tables[0].Rows[0]["VehicleType"].ToString());
      //     this.cmbdoctype.SelectedIndex = Convert.ToInt32(ds.Tables[0].Rows[0]["DocType"].ToString());
      //     this.txttransporter.Text = ds.Tables[0].Rows[0]["TransporterName"].ToString();
      //     this.txtdocno.Text = ds.Tables[0].Rows[0]["TransDocNo"].ToString();
      //     this.cmbsubsupplytype.SelectedIndex = Convert.ToInt32(ds.Tables[0].Rows[0]["SubSupplyType"].ToString());
      //     this.TxtOthers.Text = ds.Tables[0].Rows[0]["SupplyTypeOthers"].ToString();
      //     this.txtdocdate.Text = ds.Tables[0].Rows[0]["InvoiceDate"].ToString();
      //     this.txtdistance.Text = ds.Tables[0].Rows[0]["Distance"].ToString();
      //     this.txtvehicleno.Text = ds.Tables[0].Rows[0]["VehicleNo"].ToString();
      //     this.cmbTransactiontype.SelectedIndex = Convert.ToInt32(ds.Tables[0].Rows[0]["TransactionType"].ToString());
      //     this.txtid.Text = ds.Tables[0].Rows[0]["TransactionId"].ToString();
      //     this.txtdocdate1.Text = ds.Tables[0].Rows[0]["TransDocDate"].ToString();
      //     this.TxtEwayBillNo.Text = ds.Tables[0].Rows[0]["EwayBillNo"].ToString();
      //     this.TxtEwayBillDateTime.Text = ds.Tables[0].Rows[0]["EwayBillDate"].ToString();
      //     this.TxtValidUpto.Text = ds.Tables[0].Rows[0]["ValidUpto"].ToString();
      //     this.label38.Text = ds.Tables[0].Rows[0]["EwayStatus"].ToString();
      //     if (this.label38.Text == "Generated")
      //     {
      //         this.BtnSave.Enabled = false;
      //     }
      // }
    }
    if (entryType == "SALES") {
      // this.FnFindData(entryno.ToString(), salestype, "SALES");
      // return;
    }
    if (entryType == "DELIVERY NOTE") {
      // this.FnFindData(entryno.ToString(), salestype, "DELIVERY NOTE");
      // return;
    }
    if (entryType == "STOCK TRANSFER") {
      // this.FnFindStktr(entryno.ToString());
    }
    fetchPublicIp();

    api.getCustomerDetail(information['Customer']).then((value) {
      var data = value;
      address1 = data.address1;
      address1Control.text = address1;
      address2 = data.address2;
      address2Control.text = address2;
      address3 = data.address3;
      address3Control.text = address3;
      address4 = data.address4;
      address4Control.text = address4;
      email = data.email;
      // emailControl.text = email;
      gstNo = data.taxNumber;
      gstNoControl.text = gstNo;
      phone = data.phone;
      // phoneControl.text = phone;
      pinCode = data.pinNo;
      pinCodeControl.text = pinCode;
      stateCode1 = data.stateCode;
      stateCode2 = data.stateCode;
      stateCodeControl1.text = stateCode1;
      stateCodeControl2.text = stateCode2;
      name = data.name;
      nameControl.text = name;
    });
  }

  fetchPublicIp() {
    api.getPublicIp().then((value) => ipAddress = value);
  }

  Future printIps() async {
    for (var interface in await NetworkInterface.list()) {
      // debugPrint('== Interface: ${interface.name} ==');
      for (var addr in interface.addresses) {
        ipAddress = addr.address;
        // debugPrint(
        //     '${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Way Bill'),
        actions: [
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                setState(
                  () {
                    generateEWayBill();
                  },
                );
              }),
          IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(
                  () {
                    cancelEWayBill();
                  },
                );
              }),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     const Text(
              //       'Date : ',
              //       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              //     ),
              //     InkWell(
              //       child: Text(
              //         formattedDate,
              //         style: const TextStyle(
              //             fontWeight: FontWeight.bold, fontSize: 18),
              //       ),
              //       onTap: () => _selectDate(),
              //     ),
              //   ],
              // ),
              ExpansionTile(
                  title: const Text(
                    "Your Details",
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    const SizedBox(
                      height: 1,
                    ),
                    Card(
                      elevation: 5,
                      color: blue[50],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextField(
                            controller: cGstNoControl,
                            decoration: const InputDecoration(
                              labelText: 'GST No.',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              cGstNo = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          TextField(
                            controller: cNameControl,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              cName = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          TextField(
                            controller: cAddress1Control,
                            decoration: const InputDecoration(
                              labelText: 'Address1',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              cAddress1 = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          TextField(
                            controller: cAddress2Control,
                            decoration: const InputDecoration(
                              labelText: 'Address2',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              cAddress2 = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          TextField(
                            controller: cAddress3Control,
                            decoration: const InputDecoration(
                              labelText: 'Place',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              cAddress3 = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          TextField(
                            controller: cPinCodeControl,
                            decoration: const InputDecoration(
                              labelText: 'PinCode',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              cPinCode = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: cStateCodeControl,
                                  decoration: const InputDecoration(
                                    labelText: 'StateCode',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    cStateCode = value;
                                  },
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: TextField(
                                  controller: actualStateCodeControl,
                                  decoration: const InputDecoration(
                                    labelText: 'Actual StateCode',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    actualStateCode = value;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ]),
              ExpansionTile(
                title: const Text(
                  "Party Details",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                children: [
                  const SizedBox(
                    height: 1,
                  ),
                  Card(
                      elevation: 5,
                      color: blue[50],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextField(
                            controller: gstNoControl,
                            decoration: const InputDecoration(
                              labelText: 'GST No.',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              gstNo = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          TextField(
                            controller: nameControl,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              name = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          TextField(
                            controller: address1Control,
                            decoration: const InputDecoration(
                              labelText: 'Address1',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              address1 = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          TextField(
                            controller: address2Control,
                            decoration: const InputDecoration(
                              labelText: 'Address2',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              address2 = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          TextField(
                            controller: address3Control,
                            decoration: const InputDecoration(
                              labelText: 'Place',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              address3 = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          TextField(
                            controller: pinCodeControl,
                            decoration: const InputDecoration(
                              labelText: 'PinCode',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              pinCode = value;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: stateCodeControl1,
                                  decoration: const InputDecoration(
                                    labelText: 'StateCode',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    stateCode1 = value;
                                  },
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: TextField(
                                  controller: stateCodeControl2,
                                  decoration: const InputDecoration(
                                    labelText: 'Actual StateCode',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    stateCode2 = value;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                ],
              ),
              const Text(
                "Transport Details",
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              Card(
                elevation: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Supply Type',
                      style: TextStyle(fontSize: 10),
                    ),
                    DropdownButton(
                      items: supplyType.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      value: supplyTypeValue,
                      onChanged: (value) {
                        setState(() {
                          supplyTypeValue = value;
                        });
                      },
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    const Text(
                      'Sub Supply Type',
                      style: TextStyle(fontSize: 10),
                    ),
                    DropdownButton(
                      items:
                          subSupplyType.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      value: subSupplyTypeValue,
                      onChanged: (value) {
                        setState(() {
                          subSupplyTypeValue = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'InvoiceNo',
                      style: TextStyle(fontSize: 13),
                    ),
                    Expanded(
                      child: TextField(
                        controller: invoiceNoControl,
                        decoration: const InputDecoration(
                          labelText: 'InvoiceNo',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (value) {
                          invoiceNo = value;
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    const Text(
                      'Invoice Date',
                      style: TextStyle(fontSize: 13),
                    ),
                    Expanded(
                      child: TextField(
                        controller: invoiceDateControl,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Date',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (value) {
                          invoiceDate = value;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trans Mode',
                      style: TextStyle(fontSize: 10),
                    ),
                    DropdownButton(
                      items: transMode.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      value: transModeValue,
                      onChanged: (value) {
                        setState(() {
                          transModeValue = value;
                        });
                      },
                    ),
                    const Text(
                      'Distance',
                      style: TextStyle(fontSize: 13),
                    ),
                    Expanded(
                      child: TextField(
                        controller: distanceControl,
                        decoration: const InputDecoration(
                          labelText: 'Distance',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (value) {
                          distance = value;
                        },
                      ),
                    ),
                    isKmLoading
                        ? const Loading()
                        : ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isKmLoading = true;
                              });
                              calculateDistance();
                            },
                            child: const Text('KM'))
                  ],
                ),
              ),
              Card(
                elevation: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vehicle Type',
                      style: TextStyle(fontSize: 10),
                    ),
                    DropdownButton(
                      items: vehicleType.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      value: vehicleTypeValue,
                      onChanged: (value) {
                        setState(() {
                          vehicleTypeValue = value;
                        });
                      },
                    ),
                    const Text(
                      'Vehicle No',
                      style: TextStyle(fontSize: 13),
                    ),
                    SizedBox(
                      width: 100,
                      child: Expanded(
                        child: TextField(
                          controller: vehicleControl,
                          decoration: const InputDecoration(
                            labelText: 'Vehicle No',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (value) {
                            vehicle = value;
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Card(
                elevation: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Doc Type',
                      style: TextStyle(fontSize: 10),
                    ),
                    DropdownButton(
                      items: doctype.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      value: doctypeValue,
                      onChanged: (value) {
                        setState(() {
                          doctypeValue = value;
                        });
                      },
                    ),
                    const Text(
                      'Transaction Type',
                      style: TextStyle(fontSize: 13),
                    ),
                    DropdownButton(
                      items:
                          transactionType.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      value: transactionTypeValue,
                      onChanged: (value) {
                        setState(() {
                          transactionTypeValue = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transporter Name',
                    style: TextStyle(fontSize: 10),
                  ),
                  Expanded(
                    child: TextField(
                      controller: transporterControl,
                      decoration: const InputDecoration(
                        labelText: 'Transporter Name',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Text(
                    'Id',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: TextField(
                      controller: cGstNoControl,
                      decoration: const InputDecoration(
                        labelText: 'Id',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TransDocNo',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: TextField(
                      controller: transDocNoControl,
                      decoration: const InputDecoration(
                        labelText: 'Trans Doc No',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (value) {
                        // invoiceNo = value;
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  const Text(
                    'TransDocDate',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: TextField(
                      controller: transDocDateControl,
                      decoration: const InputDecoration(
                        labelText: 'Trans Doc Date',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (value) {
                        // invoiceDate = value;
                      },
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Value',
                    style: TextStyle(fontSize: 10),
                  ),
                  Expanded(
                    child: TextField(
                      controller: totalValueControl,
                      decoration: const InputDecoration(
                        labelText: 'Total Value',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Text(
                    'SGST',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: TextField(
                      controller: sGSTControl,
                      decoration: const InputDecoration(
                        labelText: 'SGST',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Text(
                    'CGST',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: TextField(
                      controller: cGSTControl,
                      decoration: const InputDecoration(
                        labelText: 'CGST',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'IGST',
                    style: TextStyle(fontSize: 10),
                  ),
                  Expanded(
                    child: TextField(
                      controller: iGSTControl,
                      decoration: const InputDecoration(
                        labelText: 'IGST',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Text(
                    'CESS',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: TextField(
                      controller: cessControl,
                      decoration: const InputDecoration(
                        labelText: 'CESS',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: TextField(
                      controller: totalControl,
                      decoration: const InputDecoration(
                        labelText: 'Total',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Main HSN',
                    style: TextStyle(fontSize: 10),
                  ),
                  Expanded(
                    child: TextField(
                      controller: mainHSNControl,
                      decoration: const InputDecoration(
                        labelText: 'Main HSN',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Text(
                    'Other Charges',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: TextField(
                      controller: otherChargeControl,
                      decoration: const InputDecoration(
                        labelText: 'Other Charges',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ref No',
                    style: TextStyle(fontSize: 10),
                  ),
                  Expanded(
                    child: TextField(
                      controller: refNoControl,
                      decoration: const InputDecoration(
                        labelText: 'Ref No',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Text(
                    'E-Way No',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: TextField(
                      controller: eWayBillNoControl,
                      decoration: const InputDecoration(
                        labelText: 'E-Way Bill No',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _selectDate() async {
    DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => {formattedDate = DateFormat('dd/MM/yyyy').format(picked)});
    }
  }

  void generateEWayBill() {}

  void cancelEWayBill() {}

  void showErrorCodeList(BuildContext context) {}

  calculateDistance() async {
    var pin1 = cPinCodeControl.text ?? '';
    var pin2 = pinCodeControl.text ?? '';
    if (pin1.isNotEmpty && pin2.isNotEmpty) {
      var yourData = await api.getGeoCode(pin1);
      var partyData = await api.getGeoCode(pin2);
      if (yourData.isNotEmpty && partyData.isNotEmpty) {
        double userLat = double.parse(yourData['lat'].toString()),
            userLng = double.parse(yourData['lon'].toString()),
            venueLat = double.parse(partyData['lat'].toString()),
            venueLng = double.parse(partyData['lon'].toString());
        var result =
            calculateDistanceInKilometer(userLat, userLng, venueLat, venueLng)
                .toStringAsFixed(2);
        setState(() {
          distance = result;
          distanceControl.text = distance;
          if (yourData['place'].toString().trim().isNotEmpty) {
            cAddress3Control.text = yourData['place'].toString().trim();
          }
          if (partyData['place'].toString().trim().isNotEmpty) {
            address3Control.text = partyData['place'].toString().trim();
          }
        });
      }
      setState(() {
        isKmLoading = false;
      });
    } else {
      setState(() {
        isKmLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add PinCode')));
      return;
    }
  }

  double calculateDistanceInKilometer(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
