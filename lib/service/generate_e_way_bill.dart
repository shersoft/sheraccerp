// @dart = 2.11
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/gst_auth_model.dart';
import 'package:sheraccerp/models/print_settings_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

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
  var information, particulars, particularData, serialNO, deliveryNoteDetails;
  List otherAmountList;
  String formattedDate, eWayBillClient = '';
  DateTime now = DateTime.now();
  CompanyInformation companySettings;
  List<CompanySettings> settings;
  PrintSettingsModel printSettingsModel;
  bool _isLoading = false;

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
  TextEditingController fromGstNoControl = TextEditingController();
  TextEditingController fromNameControl = TextEditingController();
  TextEditingController fromAddress1Control = TextEditingController();
  TextEditingController fromAddress2Control = TextEditingController();
  TextEditingController fromAddress3Control = TextEditingController();
  TextEditingController fromAddress4Control = TextEditingController();
  TextEditingController fromStateControl = TextEditingController();
  TextEditingController fromStateCodeControl = TextEditingController();
  TextEditingController fromActualStateCodeControl = TextEditingController();
  TextEditingController fromPinCodeControl = TextEditingController();
  TextEditingController fromEmailControl = TextEditingController();
  TextEditingController fromPhoneControl = TextEditingController();

  TextEditingController toGstNoControl = TextEditingController();
  TextEditingController toNameControl = TextEditingController();
  TextEditingController toAddress1Control = TextEditingController();
  TextEditingController toAddress2Control = TextEditingController();
  TextEditingController toAddress3Control = TextEditingController();
  TextEditingController toAddress4Control = TextEditingController();
  TextEditingController toPinCodeControl = TextEditingController();
  TextEditingController toStateCodeControl1 = TextEditingController();
  TextEditingController toStateCodeControl2 = TextEditingController();

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

  String supplyTypeValue = 'Outward',
      subSupplyTypeValue = 'Supply',
      doctypeValue = 'Tax Invoice',
      transModeValue = 'Road',
      vehicleTypeValue = 'Regular',
      transactionTypeValue = 'Regular';
  bool isKmLoading = false;
  String transactionId = '';

  List colHeader = [
    "SlNo",
    "ItemName",
    "HSN",
    "Qty",
    "Unit",
    "Net",
    "CGST",
    "SGST",
    "IGST",
    "CESS"
  ];

  @override
  void initState() {
    super.initState();
    entryType = widget.type ?? '';
    formattedDate = DateFormat('dd/MM/yyyy').format(now);
    data = widget.data;
    information = data['Information'][0];
    particularData = data['Particulars'];
    serialNO = data['SerialNO'];
    deliveryNoteDetails = data['DeliveryNote'];
    otherAmountList = data['otherAmount'];
    invoiceId = information['EntryNo'].toString();
    invoiceNo = information['InvoiceNo'].toString();
    invoiceDate = DateUtil.dateDMY1(information['DDate'].toString());
    invoiceNoControl.text = invoiceNo;
    invoiceDateControl.text = invoiceDate;
    transDocNoControl.text = invoiceNo;
    transDocDateControl.text =
        DateUtil.dateDMmmY(information['DDate'].toString());
    particulars = partBData(particularData);

    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();
    totalValueControl.text = information['NetAmount'].toString();
    cGSTControl.text = information['CGST'].toString();
    sGSTControl.text = information['SGST'].toString();
    iGSTControl.text = information['IGST'].toString();
    cessControl.text = information['cess'].toString();
    totalControl.text = information['Total'].toString();
    otherChargeControl.text = information['OtherCharges'].toString();
    refNoControl.text = invoiceNo;
    eWayBillNoControl.text = information['EWayBillNo'].toString().trim();
    vehicleControl.text = information['EVehicleNo'].toString().trim();

    // manualInvoiceNumberInSales =
    //     ComSettings.getStatus('MANNUAL INVOICE NUMBER IN SALES', settings);
    eWayBillClient = ComSettings.getValue('EWAYBILLAPI OWNER', settings);
    fromGstNoControl.text = ComSettings.getValue('GST-NO', settings);
    fromStateControl.text = ComSettings.getValue('COMP-STATE', settings);
    var cStateCode = ComSettings.getValue('COMP-STATECODE', settings);
    fromStateCodeControl.text = cStateCode;
    fromActualStateCodeControl.text = cStateCode;
    fromAddress1Control.text = companySettings.add1;
    fromAddress2Control.text = companySettings.add2;
    fromAddress3Control.text = companySettings.add3;
    fromAddress4Control.text = companySettings.add4;
    var cAddress5 = companySettings.add5;
    fromEmailControl.text = companySettings.email;
    fromNameControl.text = companySettings.name;
    fromPhoneControl.text = companySettings.mobile;
    fromPinCodeControl.text = companySettings.pin;
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
    api.eInvoiceDetails().then((value) {
      var data = value[0];
      _username = data['username'];
      _password = data['password'];
      if (eWayBillClient != "SHERSOFT") {
        _clientId = data['ClientId'];
        _clientSecret = data['Clientscreate'];
      } else {
        var cId = "2d9193c4-d528-42a0-b7bc-a01ac3d3827b";
        var cSecret = "bb60872c-e8f7-4056-a34a-e9157c4110ca";
        _clientId = cId;
        _clientSecret = cSecret;
      }
    });
    api.getCustomerDetail(information['Customer']).then((value) {
      var data = value;
      toAddress1Control.text = data.address1;
      toAddress2Control.text = data.address2;
      toAddress3Control.text = data.address3;
      toAddress4Control.text = data.address4;
      // emailControl.text = data.email;
      toGstNoControl.text = data.taxNumber;
      // phoneControl.text = data.phone;
      toPinCodeControl.text = data.pinNo;
      var stateCode1 = data.stateCode;
      var stateCode2 = data.stateCode;
      toStateCodeControl1.text = stateCode1;
      toStateCodeControl2.text = stateCode2;
      toNameControl.text = data.name;
      if (toPinCodeControl.text.isNotEmpty &&
          fromPinCodeControl.text.isNotEmpty) {
        calculateDistance();
      }
    });
  }

  var _username = '';
  var _password = '';
  var _clientId = '';
  var _clientSecret = '';
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
    if (eWayBillNoControl.text.trim().isNotEmpty) {
      //
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('E-Way Bill'),
          actions: [
            IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  setState(
                    () {
                      _isLoading = true;
                      generateEWayBill();
                    },
                  );
                }),
            IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  setState(
                    () {
                      _isLoading = true;
                      cancelEWayBill();
                    },
                  );
                }),
            IconButton(
                icon: const Icon(Icons.print),
                onPressed: () {
                  setState(
                    () {
                      _isLoading = true;
                      printEWayBill();
                    },
                  );
                }),
          ],
        ),
        body: ProgressHUD(
          inAsyncCall: _isLoading,
          opacity: 0.0,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
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
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.bold),
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
                                controller: fromGstNoControl,
                                decoration: const InputDecoration(
                                  labelText: 'GST No.',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: fromNameControl,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: fromAddress1Control,
                                decoration: const InputDecoration(
                                  labelText: 'Address1',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: fromAddress2Control,
                                decoration: const InputDecoration(
                                  labelText: 'Address2',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: fromAddress3Control,
                                decoration: const InputDecoration(
                                  labelText: 'Place',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: fromPinCodeControl,
                                decoration: const InputDecoration(
                                  labelText: 'PinCode',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: fromStateCodeControl,
                                      decoration: const InputDecoration(
                                        labelText: 'StateCode',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: fromActualStateCodeControl,
                                      decoration: const InputDecoration(
                                        labelText: 'Actual StateCode',
                                        border: OutlineInputBorder(),
                                      ),
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
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
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
                                controller: toGstNoControl,
                                decoration: const InputDecoration(
                                  labelText: 'GST No.',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: toNameControl,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: toAddress1Control,
                                decoration: const InputDecoration(
                                  labelText: 'Address1',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: toAddress2Control,
                                decoration: const InputDecoration(
                                  labelText: 'Address2',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: toAddress3Control,
                                decoration: const InputDecoration(
                                  labelText: 'Place',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: toPinCodeControl,
                                decoration: const InputDecoration(
                                  labelText: 'PinCode',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: toStateCodeControl1,
                                      decoration: const InputDecoration(
                                        labelText: 'StateCode',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: toStateCodeControl2,
                                      decoration: const InputDecoration(
                                        labelText: 'Actual StateCode',
                                        border: OutlineInputBorder(),
                                      ),
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
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  Card(
                    elevation: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          'Supply Type',
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(
                          width: 80,
                          child: DropdownButton(
                            items: supplyType
                                .map<DropdownMenuItem<String>>((item) {
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
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        const Text(
                          'Sub Supply Type',
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(
                          width: 80,
                          child: DropdownButton(
                            items: subSupplyType
                                .map<DropdownMenuItem<String>>((item) {
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
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                  const Divider(),
                  Card(
                    elevation: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          'Trans Mode',
                          // style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 1),
                        DropdownButton(
                          items:
                              transMode.map<DropdownMenuItem<String>>((item) {
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
                        SizedBox(
                          width: 90,
                          child: Expanded(
                            child: TextField(
                              controller: distanceControl,
                              decoration: const InputDecoration(
                                labelText: 'Distance',
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          'Vehicle Type',
                          // style: TextStyle(fontSize: 10),
                        ),
                        DropdownButton(
                          items:
                              vehicleType.map<DropdownMenuItem<String>>((item) {
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
                        SizedBox(
                          width: 120,
                          child: Expanded(
                            child: TextField(
                              controller: vehicleControl,
                              decoration: const InputDecoration(
                                labelText: 'Vehicle No',
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Card(
                    elevation: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          'Doc Type',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 2),
                        SizedBox(
                          width: 100,
                          child: DropdownButton(
                            items:
                                doctype.map<DropdownMenuItem<String>>((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child:
                                    Text(item, style: TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            value: doctypeValue,
                            onChanged: (value) {
                              setState(() {
                                doctypeValue = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Transaction Type',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 2),
                        SizedBox(
                          width: 120,
                          child: DropdownButton(
                            items: transactionType
                                .map<DropdownMenuItem<String>>((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child:
                                    Text(item, style: TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            value: transactionTypeValue,
                            onChanged: (value) {
                              setState(() {
                                transactionTypeValue = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: transporterControl,
                          decoration: const InputDecoration(
                            labelText: 'Transporter Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          controller: fromGstNoControl,
                          decoration: const InputDecoration(
                            labelText: 'Id',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: transDocNoControl,
                          decoration: const InputDecoration(
                            labelText: 'Trans Doc No',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            // invoiceNo = value;
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: TextField(
                          controller: transDocDateControl,
                          decoration: const InputDecoration(
                            labelText: 'Trans Doc Date',
                            border: OutlineInputBorder(),
                          ),
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
                      Expanded(
                        child: TextField(
                          controller: totalValueControl,
                          decoration: const InputDecoration(
                            labelText: 'Total Value',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: TextField(
                          controller: sGSTControl,
                          decoration: const InputDecoration(
                            labelText: 'SGST',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: TextField(
                          controller: cGSTControl,
                          decoration: const InputDecoration(
                            labelText: 'CGST',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: iGSTControl,
                          decoration: const InputDecoration(
                            labelText: 'IGST',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: TextField(
                          controller: cessControl,
                          decoration: const InputDecoration(
                            labelText: 'CESS',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: TextField(
                          controller: totalControl,
                          decoration: const InputDecoration(
                            labelText: 'Total',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: mainHSNControl,
                          decoration: const InputDecoration(
                            labelText: 'Main HSN',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          controller: otherChargeControl,
                          decoration: const InputDecoration(
                            labelText: 'Other Charges',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: refNoControl,
                          decoration: const InputDecoration(
                            labelText: 'Ref No',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          controller: eWayBillNoControl,
                          decoration: const InputDecoration(
                            labelText: 'E-Way Bill No',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.grey.shade200),
                        border:
                            TableBorder.all(width: 1.0, color: Colors.black),
                        columnSpacing: 12,
                        dataRowHeight: 20,
                        headingRowHeight: 30,
                        columns: [
                          for (int i = 0; i < colHeader.length; i++)
                            DataColumn(
                              label: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  colHeader[i],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                        rows: [
                          for (var values in particulars)
                            DataRow(cells: [
                              DataCell(
                                Align(
                                  alignment: ComSettings.oKNumeric(
                                    values['no'].toString(),
                                  )
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    values['no'].toString(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    // style: TextStyle(fontSize: 6),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: ComSettings.oKNumeric(
                                    values['name'].toString(),
                                  )
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    values['name'].toString(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    // style: TextStyle(fontSize: 6),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: ComSettings.oKNumeric(
                                    values['hsn'].toString(),
                                  )
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    values['hsn'] != null
                                        ? values['hsn'].toString()
                                        : '',
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    // style: TextStyle(fontSize: 6),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: ComSettings.oKNumeric(
                                    values['qty'].toString(),
                                  )
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    values['qty'].toString(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    // style: TextStyle(fontSize: 6),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: ComSettings.oKNumeric(
                                    values['unit'].toString(),
                                  )
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    values['unit'].toString(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    // style: TextStyle(fontSize: 6),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: ComSettings.oKNumeric(
                                    values['net'].toString(),
                                  )
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    values['net'].toString(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    // style: TextStyle(fontSize: 6),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: ComSettings.oKNumeric(
                                    values['cGst'].toString(),
                                  )
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    values['cGst'].toString(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    // style: TextStyle(fontSize: 6),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: ComSettings.oKNumeric(
                                    values['cGst'].toString(),
                                  )
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    values['cGst'].toString(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    // style: TextStyle(fontSize: 6),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: ComSettings.oKNumeric(
                                    values['iGst'].toString(),
                                  )
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    values['iGst'].toString(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    // style: TextStyle(fontSize: 6),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: ComSettings.oKNumeric(
                                    values['cess'].toString(),
                                  )
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    values['cess'].toString(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    // style: TextStyle(fontSize: 6),
                                  ),
                                ),
                              ),
                            ]),
                        ]),
                  ),
                  const Divider(),
                ],
              ),
            ),
          ),
        ));
  }

  void generateEWayBill() {
    if (fromPinCodeControl.text.isNotEmpty &&
        fromPinCodeControl.text.isNotEmpty &&
        distanceControl.text.isNotEmpty &&
        transporterControl.text.isNotEmpty &&
        transDocNoControl.text.isNotEmpty &&
        transactionId.isNotEmpty) {
      String docType = doctypeValue == 'Tax Invoice'
          ? 'INV'
          : doctypeValue == 'Bill of Supply'
              ? 'BIL'
              : doctypeValue == 'Bill of Entry'
                  ? 'BOE'
                  : doctypeValue == 'Delivery Challan'
                      ? 'CHL'
                      : doctypeValue == 'Others'
                          ? 'OTH'
                          : '';
      String supplyType = supplyTypeValue == 'Inward'
          ? 'I'
          : supplyTypeValue == 'Outward'
              ? 'O'
              : '';
      String subSupplyType = subSupplyTypeValue == 'Supply'
          ? '1'
          : subSupplyTypeValue == 'Import'
              ? '2'
              : subSupplyTypeValue == 'Export'
                  ? '3'
                  : subSupplyTypeValue == 'Job Work'
                      ? '4'
                      : subSupplyTypeValue == 'For Own Use'
                          ? '5'
                          : subSupplyTypeValue == 'Job work Returns'
                              ? '6'
                              : subSupplyTypeValue == 'Sales Return'
                                  ? '7'
                                  : subSupplyTypeValue == 'SKD/CKD'
                                      ? '8'
                                      : subSupplyTypeValue == 'Line Sales'
                                          ? '9'
                                          : subSupplyTypeValue ==
                                                  'Recipient Not Known'
                                              ? '10'
                                              : subSupplyTypeValue ==
                                                      'Exhibition or Fairs'
                                                  ? '11'
                                                  : subSupplyTypeValue ==
                                                          'Others'
                                                      ? '12'
                                                      : '0';
      String transMode = transModeValue == "Road"
          ? "1"
          : transModeValue == "Rail"
              ? "2"
              : transModeValue == "Air"
                  ? "3"
                  : transModeValue == "Ship"
                      ? "4"
                      : '0';
      String vehicleType = vehicleTypeValue != "Regular" ? "O" : "R";
      int transactionType = vehicleTypeValue == "Regular"
          ? 1
          : vehicleTypeValue == "Bill To-Ship To"
              ? 2
              : vehicleTypeValue == "Bill From-Dispatch From"
                  ? 3
                  : vehicleTypeValue == "Combination of 2 and 3"
                      ? 4
                      : 0;
      List<EwayItemListModel> itemList = [];
      for (var item in particulars) {
        if (item['name'] == null) {
          continue;
        }
        itemList.add(EwayItemListModel(
            cessNonadvol: 0,
            cessRate: int.parse(item['cess'].toString()),
            cgstRate: double.parse(item['cGst'].toString()),
            hsnCode: int.parse(item['hsn'].toString()),
            igstRate: double.parse(item['iGst'].toString()),
            productDesc: item['name'].toString(),
            productName: item['name'].toString(),
            qtyUnit: item['unit'].toString(),
            quantity: double.parse(item['qty'].toString()),
            sgstRate: double.parse(item['sGst'].toString()),
            taxableAmount: double.parse(item['net'].toString())));
      }
      int actFromStateCode = fromActualStateCodeControl.text.isNotEmpty
              ? int.parse(fromActualStateCodeControl.text)
              : 0,
          actToStateCode = toStateCodeControl2.text.isNotEmpty
              ? int.parse(toStateCodeControl2.text)
              : 0,
          cessNonAdvolValue = 0,
          cessValue =
              cessControl.text.isNotEmpty ? int.parse(cessControl.text) : 0,
          fromPincode = fromPinCodeControl.text.isNotEmpty
              ? int.parse(fromPinCodeControl.text)
              : 0,
          fromStateCode = fromStateCodeControl.text.isNotEmpty
              ? int.parse(fromStateCodeControl.text)
              : 0,
          igstValue =
              iGSTControl.text.isNotEmpty ? int.parse(iGSTControl.text) : 0,
          otherValue = 0,
          toPincode = toPinCodeControl.text.isNotEmpty
              ? int.parse(toPinCodeControl.text)
              : 0,
          toStateCode = toStateCodeControl1.text.isNotEmpty
              ? int.parse(toStateCodeControl1.text)
              : 0,
          totInvValue =
              totalControl.text.isNotEmpty ? int.parse(totalControl.text) : 0;
      double cgstValue =
              cGSTControl.text.isNotEmpty ? int.parse(cGSTControl.text) : 0,
          sgstValue =
              sGSTControl.text.isNotEmpty ? int.parse(sGSTControl.text) : 0,
          totalValue = totalValueControl.text.isNotEmpty
              ? int.parse(totalValueControl.text)
              : 0;
      String docDate =
              invoiceDateControl.text.isNotEmpty ? invoiceDateControl.text : '',
          docNo = invoiceNoControl.text.isNotEmpty ? invoiceNoControl.text : '',
          fromAddr1 = fromAddress1Control.text.isNotEmpty
              ? fromAddress1Control.text
              : '',
          fromAddr2 = fromAddress2Control.text.isNotEmpty
              ? fromAddress2Control.text
              : '',
          fromGstin =
              fromGstNoControl.text.isNotEmpty ? fromGstNoControl.text : '',
          fromPlace = fromAddress3Control.text.isNotEmpty
              ? fromAddress3Control.text
              : '',
          fromTrdName =
              fromNameControl.text.isNotEmpty ? fromNameControl.text : '',
          subSupplyDesc = '',
          toAddr1 =
              toAddress1Control.text.isNotEmpty ? toAddress1Control.text : '',
          toAddr2 =
              toAddress2Control.text.isNotEmpty ? toAddress2Control.text : '',
          toGstin = toGstNoControl.text.isNotEmpty ? toGstNoControl.text : '',
          toPlace =
              toAddress3Control.text.isNotEmpty ? toAddress3Control.text : '',
          toTrdName = toNameControl.text.isNotEmpty ? toNameControl.text : '',
          transDistance =
              distanceControl.text.isNotEmpty ? distanceControl.text : '',
          transDocDate = transDocDateControl.text.isNotEmpty
              ? transDocDateControl.text
              : '',
          transDocNo =
              transDocNoControl.text.isNotEmpty ? transDocNoControl.text : '',
          transporterId = transporterIdControl.text.isNotEmpty
              ? transporterIdControl.text
              : '',
          transporterName =
              transporterControl.text.isNotEmpty ? transporterControl.text : '',
          vehicleNo = vehicleControl.text.isNotEmpty ? vehicleControl.text : '';
      EwayModel eWayModel = EwayModel(
          actFromStateCode: actFromStateCode,
          actToStateCode: actToStateCode,
          cessNonAdvolValue: cessNonAdvolValue,
          cessValue: cessValue,
          cgstValue: cgstValue,
          docDate: docDate,
          docNo: docNo,
          docType: docType,
          fromAddr1: fromAddr1,
          fromAddr2: fromAddr2,
          fromGstin: fromGstin,
          fromPincode: fromPincode,
          fromPlace: fromPlace,
          fromStateCode: fromStateCode,
          fromTrdName: fromTrdName,
          igstValue: igstValue,
          itemList: itemList,
          otherValue: otherValue,
          sgstValue: sgstValue,
          subSupplyDesc: subSupplyDesc,
          subSupplyType: subSupplyType,
          supplyType: supplyType,
          toAddr1: toAddr1,
          toAddr2: toAddr2,
          toGstin: toGstin,
          toPincode: toPincode,
          toPlace: toPlace,
          toStateCode: toStateCode,
          totalValue: totalValue,
          totInvValue: totInvValue,
          toTrdName: toTrdName,
          transactionType: transactionType,
          transDistance: transDistance,
          transDocDate: transDocDate,
          transDocNo: transDocNo,
          transMode: transMode,
          transporterId: transporterId,
          transporterName: transporterName,
          vehicleNo: vehicleNo,
          vehicleType: vehicleType);
      if (eWayBillClient != "SHERSOFT") {
        api
            .authEWay(eWayBillClient, _username, _password, ipAddress,
                _clientId, _clientSecret, fromGstNoControl.text)
            .then((respond) {
          if (respond.status_cd != '0') {
            api
                .generateEWayBill(eWayBillClient, fromGstNoControl.text,
                    _password, ipAddress, _clientId, _clientSecret, eWayModel)
                .then((result) {
              if (result.status_cd != '0') {
                setState(() {
                  var billNo = result.data.ewayBillNo ?? '';
                  var billDate = result.data.ewayBillDate ?? '';
                  var validUpTo = result.data.validUpto ?? '';
                  eWayBillNoControl.text = billNo + billDate + validUpTo;
                  _isLoading = false;
                });
              } else {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(result.status_desc)));
                setState(() {
                  _isLoading = false;
                });
              }
            });
          } else {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(respond.status_desc)));
            setState(() {
              _isLoading = false;
            });
          }
        });
      } else {
        api
            .generateEWayBill(eWayBillClient, fromGstNoControl.text, _password,
                ipAddress, _clientId, _clientSecret, eWayModel)
            .then((result) {
          if (result.status_cd != '0') {
            setState(() {
              var billNo = result.data.ewayBillNo ?? '';
              var billDate = result.data.ewayBillDate ?? '';
              var validUpTo = result.data.validUpto ?? '';
              eWayBillNoControl.text = billNo + billDate + validUpTo;
              _isLoading = false;
            });
          } else {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(result.status_desc)));
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    }
  }

  void cancelEWayBill() {
    EWayBillCancelModel _data = EWayBillCancelModel(
        cancelRmrk: 'Data Entry Mistake',
        cancelRsnCode: 3,
        ewbNo: eWayBillNoControl.text);
    if (eWayBillClient != "SHERSOFT") {
      api
          .cancelEWayBill(eWayBillClient, fromGstNoControl.text, _password,
              ipAddress, _clientId, _clientSecret, _data)
          .then((result) {
        _isLoading = false;
        if (result.status_cd != '0') {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Canceled! ' + result.status_desc)));
          setState(() {
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result.status_desc)));
          setState(() {
            _isLoading = false;
          });
        }
      });
    } else {
      api
          .cancelEWayBill(eWayBillClient, fromGstNoControl.text, _password,
              ipAddress, _clientId, _clientSecret, _data)
          .then((result) {
        _isLoading = false;
        if (result.status_cd != '0') {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Canceled! ' + result.status_desc)));
          setState(() {
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result.status_desc)));
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void showErrorCodeList(BuildContext context) {}

  calculateDistance() async {
    var pin1 = fromPinCodeControl.text ?? '';
    var pin2 = toPinCodeControl.text ?? '';
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
          distanceControl.text = result;
          if (yourData['place'].toString().trim().isNotEmpty) {
            fromAddress3Control.text = yourData['place'].toString().trim();
          }
          if (partyData['place'].toString().trim().isNotEmpty) {
            toAddress3Control.text = partyData['place'].toString().trim();
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

  void printEWayBill() {
    setState(() {
      _isLoading = false;
    });
  }

  bool interState = false;
  partBData(_data) {
    var itemData = [];
    int no = 0;
    for (var item in _data) {
      itemData.add({
        'no': no + 1,
        'name': item['itemname'],
        'hsn': item['hsncode'],
        'qty': item['Qty'],
        'unit': unitNameFormat(item['unitName']),
        'net': item['Net'],
        'cGst': interState ? '0' : gstDiv(item['igst'], 1),
        'sGst': interState ? '0' : gstDiv(item['igst'], 1),
        'iGst': interState ? item['igst'] : '0',
        'cess': item['cessper']
      });
      no++;
    }

    return itemData;
  }

  unitNameFormat(var name) {
    String result = 'NOS';
    if (name == null || name.toString().isEmpty) {
      return result;
    }
    if (name == "KG") {
      result = "KGS";
    } else if (name == "KGS") {
      result = "KGS";
    } else if (name == "NOS") {
      result = "NOS";
    } else if (name == "PCS") {
      result = "PCS";
    } else if (name == "PKT") {
      result = "PAC";
    } else if (name == "BOTTLE") {
      result = "BTL";
    } else if (name == "CS") {
      result = "BOX";
    } else if (name != "TIN") {
      result = "NOS";
    } else {
      result = "BOX";
    }
    return result;
  }

  gstDiv(value, int decimal) {
    String result = '0';
    if (value == null) {
      return result;
    } else {
      result = (double.parse(value.toString()) / 2).toStringAsFixed(decimal);
      result = int.parse(result.split('.')[1].toString()) > 0
          ? result
          : result.split('.')[0].toString();
      return result;
    }
  }
}
