// @dart = 2.11
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/gst_auth_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';

class GenerateE_Invoice extends StatefulWidget {
  final data;
  GenerateE_Invoice({
    Key key,
    this.data,
  }) : super(key: key);

  @override
  State<GenerateE_Invoice> createState() => _GenerateE_InvoiceState();
}

class _GenerateE_InvoiceState extends State<GenerateE_Invoice> {
//   0:
// "success" -> true
// 1:
// "Information" -> List (1 item)
// 2:
// "Particulars" -> List (1 item)
// 3:
// "SerialNO" -> List (0 items)
// 4:
// "DeliveryNote" -> List (0 items)
// 5:
// "message" -> "have a nice day"
// 6:
// "otherAmount" -> List (3 items)
  dynamic data;
  var information, particulars, serialNO, deliveryNoteDetails;
  List otherAmountList;
  String formattedDate, _narration = '';
  DateTime now = DateTime.now();
  CompanyInformation companySettings;
  List<CompanySettings> settings;

  TextEditingController ackNoControl = TextEditingController();
  TextEditingController ackExpiryControl = TextEditingController();
  TextEditingController signedInvoiceControl = TextEditingController();
  TextEditingController irInControl = TextEditingController();
  TextEditingController signedQrCodeControl = TextEditingController();
  TextEditingController bill_to_placeControl = TextEditingController();
  TextEditingController ship_to_placeControl = TextEditingController();
  TextEditingController desp_nameControl = TextEditingController();
  TextEditingController desp_address1Control = TextEditingController();
  TextEditingController desp_address2Control = TextEditingController();
  TextEditingController desp_stateControl = TextEditingController();
  TextEditingController desp_pinCodeControl = TextEditingController();
  TextEditingController desp_placeControl = TextEditingController();
  TextEditingController buyer_gstInControl = TextEditingController();
  TextEditingController buyer_tradeNameControl = TextEditingController();
  TextEditingController buyer_address1Control = TextEditingController();
  TextEditingController buyer_address2Control = TextEditingController();
  TextEditingController buyer_address3Control = TextEditingController();
  TextEditingController buyer_address4Control = TextEditingController();
  TextEditingController buyer_stateCodeControl = TextEditingController();
  TextEditingController buyer_pinCodeControl = TextEditingController();
  TextEditingController buyer_eMailControl = TextEditingController();
  TextEditingController buyer_phoneControl = TextEditingController();
  TextEditingController Control = TextEditingController();

  String invoiceId = '',
      invoiceNo = '',
      salesType = '',
      gross = '0',
      net = '0',
      sGst = '0',
      cGst = '0',
      iGst = '0',
      cess = '0',
      stateCess = '0',
      discount = '0',
      otherCharge = '0',
      roundOff = '0',
      totalTotal = '0',
      grandTotal = '0',
      irn = '',
      entryType = '';
  //string _customer, DataTable _itemList, string Gross, string sgst, string cgst, string igst, string cess, string statecess, string discount, string othercharge, string rounoff, string totaltotal, string grandtotal, string EntryNo, DateTimePicker dt, string irn, int salestype, string NetAmount, string EntryType, string tcs
  String ackNo = '',
      ackExpiry = '',
      signedInvoice = '',
      irIn = '',
      signedQrCode = '';
  String bill_to_place = '', ship_to_place = '';
  //Despatch from Details
  String desp_name = '',
      desp_address1 = '',
      desp_address2 = '',
      desp_state = '',
      desp_pinCode = '',
      desp_place = '';
  //Buyer Details
  String buyer_gstIn = '',
      buyer_tradeName = '',
      buyer_address1 = '',
      buyer_address2 = '',
      buyer_address3 = '',
      buyer_address4 = '',
      buyer_stateCode = '',
      buyer_pinCode = '',
      buyer_eMail = '',
      buyer_phone = '';

  bool isEWayBill = false;
  String ipAddress = '127.0.0.1';
  DioService api = DioService();
  bool salesmanAsVehicle = false;
  String eWayBillClient = '';

  @override
  void initState() {
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);
    data = widget.data;
    information = data['Information'][0];
    particulars = data['Particulars'];
    serialNO = data['SerialNO'];
    deliveryNoteDetails = data['DeliveryNote'];
    otherAmountList = data['otherAmount'];

    invoiceId = information['EntryNo'].toString();
    invoiceNo = information['InvoiceNo'].toString();

    companySettings = ScopedModel.of<MainModel>(context).getCompanySettings();
    settings = ScopedModel.of<MainModel>(context).getSettings();
    formattedDate = companySettings.eDate.isNotEmpty
        ? DateUtil.dateDMY(companySettings.eDate)
        : formattedDate;
    salesmanAsVehicle =
        ComSettings.getStatus('USE SALESMAN AS VEHICLE', settings);
    eWayBillClient = ComSettings.getValue('EWAYBILLAPI OWNER', settings);
    super.initState();
    // printIps();
    api.eInvoiceDetails().then((value) {
      var data = value[0];
      _username = data['username'];
      _password = data['password'];
      if (eWayBillClient != "SHERSOFT") {
        _clientId = data['ClientId'];
        _clientSecret = data['Clientscreate'];
      } else {
        var cId = "980431a0-99cb-4e7b-8588-3aef1ed001f7";
        var cSecret = "d3b67dda-6eaf-4caf-bccb-725f11221277";
        _clientId = cId;
        _clientSecret = cSecret;
      }
    });
    api.getCustomerDetail(information['Customer']).then((value) {
      var data = value;
      buyer_address1 = data.address1;
      buyer_address1Control.text = buyer_address1;
      buyer_address2 = data.address2;
      buyer_address2Control.text = buyer_address2;
      buyer_address3 = data.address3;
      buyer_address3Control.text = buyer_address3;
      buyer_address4 = data.address4;
      buyer_address4Control.text = buyer_address4;
      buyer_eMail = data.email;
      buyer_eMailControl.text = buyer_eMail;
      buyer_gstIn = data.taxNumber;
      buyer_gstInControl.text = buyer_gstIn;
      buyer_phone = data.phone;
      buyer_phoneControl.text = buyer_phone;
      buyer_pinCode = data.pinNo;
      buyer_pinCodeControl.text = buyer_pinCode;
      buyer_stateCode = data.stateCode;
      buyer_stateCodeControl.text = buyer_stateCode;
      buyer_tradeName = data.name;
      buyer_tradeNameControl.text = buyer_tradeName;
    });
    gross = information['GrossValue'].toStringAsFixed(2);
    net = information['NetAmount'].toStringAsFixed(2);
    sGst = information['SGST'].toStringAsFixed(2);
    cGst = information['CGST'].toStringAsFixed(2);
    iGst = information['IGST'].toStringAsFixed(2);
    cess = information['cess'].toStringAsFixed(2);
    discount = '0';
    double tcs = 0;
    otherCharge =
        (double.tryParse(information['OtherCharges'].toString()) + tcs)
            .toStringAsFixed(2);
    roundOff = information['Roundoff'].toStringAsFixed(2);
    totalTotal = information['Total'].toStringAsFixed(2);
    grandTotal = information['GrandTotal'].toStringAsFixed(2);
    irn = ''; //information['irn'].toStringAsFixed(2);
    entryType = '';

    fetchPublicIp();
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
    var data = widget.data;
    var information = data['Information'][0];
    var particulars = data['Particulars'];
    // var serialNO = value['SerialNO'];
    // var deliveryNoteDetails = value['DeliveryNote'];
    otherAmountList = data['otherAmount'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Invoice'),
        actions: [
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                setState(
                  () {
                    generateEInvoice();
                  },
                );
              }),
          IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(
                  () {
                    //
                  },
                );
              }),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Date : ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  InkWell(
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    onTap: () => _selectDate(),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.settings, color: blue),
                    onSelected: (value) {
                      setState(() {
                        if (value == 'Configure') {
                          showEditDialog(context);
                        }
                      });
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'Configure',
                        child: Text('Configure e-Invoice Client'),
                      ),
                      // const PopupMenuItem<String>(
                      //   value: 'Edit  e-Invoice',
                      //   child: Text('Edit  e-Invoice Details'),
                      // ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: TextField(
                      controller: ackNoControl,
                      decoration: const InputDecoration(
                        labelText: 'Ack No',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        ackNo = value;
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    child: TextField(
                      controller: ackExpiryControl,
                      decoration: const InputDecoration(
                        labelText: 'Ack Expiry',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        ackExpiry = value;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              TextField(
                controller: irInControl,
                decoration: const InputDecoration(
                  labelText: 'IRN',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  irIn = value;
                },
              ),
              const SizedBox(
                height: 5,
              ),
              TextField(
                controller: signedInvoiceControl,
                decoration: const InputDecoration(
                  labelText: 'Signed Invoice',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  signedInvoice = value;
                },
              ),
              const SizedBox(
                height: 5,
              ),
              TextField(
                controller: signedQrCodeControl,
                decoration: const InputDecoration(
                  labelText: 'Signed QrCode',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  signedQrCode = value;
                },
              ),
              const Divider(
                thickness: 1,
                color: black,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Center(
                      child: Card(
                          elevation: 0,
                          child: Text(
                            'Place Of Party',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ))),
                  const SizedBox(
                    width: 5,
                  ),
                  const Text('Sent E-Way Bill?'),
                  DropdownButton(
                    hint: const Center(
                      child: Text('Sent E-Way Bill?'),
                    ),
                    items: const [
                      DropdownMenuItem(
                        child: Text("Yes"),
                        value: 'Yes',
                      ),
                      DropdownMenuItem(
                        child: Text("No"),
                        value: 'No',
                      )
                    ],
                    value: isEWayBill ? 'Yes' : 'No',
                    onChanged: (value) {
                      setState(() {
                        isEWayBill = value == 'Yes' ? true : false;
                      });
                    },
                  )
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              TextField(
                controller: bill_to_placeControl,
                decoration: const InputDecoration(
                  labelText: 'Bill To Place',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  bill_to_place = value;
                },
              ),
              const SizedBox(
                height: 5,
              ),
              TextField(
                controller: ship_to_placeControl,
                decoration: const InputDecoration(
                  labelText: 'Ship To Place',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  ship_to_place = value;
                },
              ),
              const Divider(
                thickness: 1,
                color: black,
              ),
              Card(
                elevation: 6,
                surfaceTintColor: indigoAccent,
                shadowColor: blue,
                child: Column(
                  children: [
                    const Center(
                        child: Card(
                            elevation: 0,
                            child: Text(
                              'Dispatch From Details',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ))),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: desp_nameControl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        desp_name = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: desp_address1Control,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        desp_address1 = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: desp_address2Control,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        desp_address2 = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: desp_stateControl,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        desp_state = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: desp_pinCodeControl,
                      decoration: const InputDecoration(
                        labelText: 'Pin Code',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        desp_pinCode = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: desp_placeControl,
                      decoration: const InputDecoration(
                        labelText: 'Place',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        desp_place = value;
                      },
                    ),
                  ],
                ),
              ),
              const Divider(
                thickness: 1,
                color: black,
              ),
              Card(
                elevation: 6,
                surfaceTintColor: indigoAccent,
                shadowColor: blue,
                child: Column(
                  children: [
                    const Center(
                        child: Card(
                            elevation: 0,
                            child: Text(
                              'Buyer Details',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ))),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: buyer_gstInControl,
                      decoration: const InputDecoration(
                        labelText: 'GSTin',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        buyer_gstIn = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: buyer_tradeNameControl,
                      decoration: const InputDecoration(
                        labelText: 'TradeName',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        buyer_tradeName = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: buyer_address1Control,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        buyer_address1 = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: buyer_address2Control,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        buyer_address2 = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: buyer_address3Control,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        buyer_address3 = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: buyer_address4Control,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        buyer_address4 = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: buyer_stateCodeControl,
                      decoration: const InputDecoration(
                        labelText: 'State Code',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        buyer_stateCode = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: buyer_pinCodeControl,
                      decoration: const InputDecoration(
                        labelText: 'Pin Code',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        buyer_pinCode = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: buyer_eMailControl,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        buyer_eMail = value;
                      },
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextField(
                      controller: buyer_phoneControl,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        buyer_phone = value;
                      },
                    ),
                  ],
                ),
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
      setState(() => {formattedDate = DateFormat('dd-MM-yyyy').format(picked)});
    }
  }

  var _username = '';
  var _password = '';
  var _clientId = '';
  var _clientSecret = '';
  var _gstIn = '';

  void generateEInvoice() {
    companySettings.pin = '676521';
    if (companySettings.pin.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add Company PinCode!')));
      return;
    }
    companySettings.email = 'test@gmail.com';
    if (companySettings.email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add Company Email!')));
      return;
    }
    if (companySettings.mobile.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add Company Mobile!')));
      return;
    }
    String companyTaxNumber = ComSettings.getValue('GST-NO', settings);
    String companyState = ComSettings.getValue('COMP-STATE', settings);
    String companyStateCode = ComSettings.getValue('COMP-STATECODE', settings);
    api
        .authenticateGSTPortal(
            _username, _password, ipAddress, _clientId, _clientSecret, _gstIn)
        .then((value) {
      // debugPrint(value.toString());
      if (value != null) {
        AuthClass authData = value;
        if (authData.status_cd.toString() != "1") {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['status_desc'].toString())));
          return;
        } else {
          ackExpiry = authData.data.TokenExpiry;
          ackExpiryControl.text = ackExpiry;
          ackNo = authData.data.AuthToken;
          ackExpiryControl.text = ackExpiry;
          if (buyer_pinCodeControl.text.isEmpty ||
              desp_pinCodeControl.text.isEmpty ||
              buyer_phoneControl.text.isEmpty) {
            api
                .getGstResult(eWayBillClient, buyer_gstIn, _username, ipAddress,
                    _clientId, _clientSecret, ackNo, companyTaxNumber)
                .then((value) {
              if (value.status_cd == '1') {
                buyer_gstIn = value.data.Gstin;
                buyer_gstInControl.text = buyer_gstIn;
                buyer_tradeName = value.data.TradeName;
                buyer_tradeNameControl.text = buyer_tradeName;
                buyer_address1 = value.data.AddrBno;
                buyer_address1Control.text = buyer_address1;
                if (value.data.AddrFlno.length <= 3) {
                  buyer_address2 = "abc";
                } else {
                  buyer_address2 = value.data.AddrFlno;
                }
                buyer_address2Control.text = buyer_address2;

                buyer_address3 = value.data.AddrSt;
                buyer_address3Control.text = value.data.AddrSt;
                buyer_address4 = value.data.AddrLoc;
                buyer_address4Control.text = value.data.AddrLoc;
                var txtBuyerPinCode = buyer_pinCode; //TextBox
                int addrPncd = value.data.AddrPncd;
                buyer_pinCodeControl.text = addrPncd.toString();
                var txtBStateCode = buyer_stateCodeControl.text; //TextBox
                addrPncd = value.data.StateCode;
                buyer_stateCodeControl.text = addrPncd.toString();
                if (buyer_eMailControl.text.isEmpty) {
                  buyer_eMailControl.text = "abc@gmail.com";
                }
                if (buyer_eMailControl.text == " ") {
                  buyer_eMailControl.text = "abc@gmail.com";
                }
                if (buyer_phoneControl.text.isEmpty) {
                  buyer_phoneControl.text = "9000000000";
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid GST Number')));
                return;
              }
            });
          }
          if (entryType == 'SALES') {
            //str5 = select type from SalesType where id
          } else if (entryType == 'SALES RETURN') {
            //str5 = elect type from SalesReturnType where id
          }
          var invoiceLetter = '';
          // invoiceLetter = SherClass.FundbReader(string.Concat(new object[] { "select invoiceletter from printsettings where DTransaction= '", str5, "' AND FYid = ", SherClass.FyID }) ?? "").Rows[0]["invoiceletter"].ToString();
          var invoiceLetterSuffix = '';
          // invoiceLetterSuffix = SherClass.FundbReader(string.Concat(new object[] { "select invoicesuffix from printsettings where DTransaction= '", str5, "' AND FYid = ", SherClass.FyID }) ?? "").Rows[0]["invoicesuffix"].ToString();
          TranDtls tranDtls = TranDtls(
              EcmGstin: null,
              IgstOnIntra: "N",
              RegRev: "N",
              SupTyp: "B2B",
              TaxSch: "GST");
          invoiceLetter = invoiceLetter + invoiceId + invoiceLetterSuffix;
          String str6 = "INV";
          if (entryType == "SALES") {
            str6 = "INV";
          } else if (entryType == "SALES RETURN") {
            str6 = "CRN";
          }
          DocDtls docDtl =
              DocDtls(Dt: formattedDate, No: invoiceLetter, Typ: str6);

          SellerDtls sellerDtl = SellerDtls(
              Addr1: companySettings.add1,
              Addr2: companySettings.add2,
              Em: companySettings.email,
              Gstin: companyTaxNumber,
              LglNm: companySettings.name,
              Loc: companySettings.add3,
              Ph: companySettings.mobile,
              Pin: int.parse(companySettings.pin),
              Stcd: companyStateCode,
              TrdNm: companySettings.name);
          BuyerDtls buyerDtl = BuyerDtls(
              Addr1: buyer_address1,
              Addr2: buyer_address2,
              Em: buyer_eMail,
              Gstin: buyer_gstIn,
              LglNm: buyer_tradeName,
              Loc: buyer_address4,
              Ph: buyer_phone,
              Pin: int.parse(buyer_pinCode),
              Pos: buyer_stateCode,
              Stcd: buyer_stateCode,
              TrdNm: buyer_tradeName);

          List<ItemListEinvoice> itemListEinvoices = <ItemListEinvoice>[];
          List<BchDtls> bchDtls = <BchDtls>[];
          int slNo = 1;
          for (var product in particulars) {
            BchDtls bchDtl = BchDtls(
                Expdt: formattedDate,
                Nm: product["Barcde"].ToString(),
                wrDt: formattedDate);

            List<AttribDtl> attribDtls = <AttribDtl>[];
            attribDtls
                .add(AttribDtl(Nm: product["PrdDesc"].ToString(), Val: "1000"));

            itemListEinvoices.add(ItemListEinvoice(
                AssAmt: double.tryParse(product['Net'].toString()),
                AttribDtls: attribDtls,
                Barcde: product["UniqueCode"].ToString(),
                bchDtls: bchDtl,
                CesAmt: double.tryParse(product['cess'].toString()),
                CesNonAdvlAmt: 0,
                CesRt: int.tryParse(product['cessper'].toString()),
                CgstAmt: int.tryParse(product['CGST'].toString()),
                Discount: int.tryParse(product['RDisc'].toString()),
                FreeQty: int.tryParse(product['freeQty'].toString()),
                GstRt: int.tryParse(product['igst'].toString()),
                HsnCd: product['hsncode'].toString(),
                IgstAmt: double.tryParse(product['IGST'].toString()),
                IsServc:
                    product['typeofsupply'].toString().toUpperCase() == 'GOODS'
                        ? 'N'
                        : 'Y',
                OrdLineRef: '',
                OrgCntry: 'IN',
                OthChrg: 0,
                PrdDesc: product['itemname'].toString(),
                PrdSlNo: product['itemId'].toString(),
                PreTaxVal: int.tryParse(product['igst'].toString()),
                Qty: double.tryParse(product['Qty'].toString()),
                SgstAmt: int.tryParse(product['SGST'].toString()),
                SlNo: slNo.toString(),
                StateCesAmt: 0,
                StateCesNonAdvlAmt: 0,
                StateCesRt: 0,
                TotAmt: double.tryParse(product['GrossValue'].toString()),
                TotItemVal: double.tryParse(product['Total'].toString()),
                Unit: product['unitName'].toString(),
                UnitPrice: double.tryParse(product['RealRate'].toString())));
            slNo++;
          }
          ValDtls valDtl = ValDtls(
              AssVal: double.parse(net),
              CesVal: double.parse(cess),
              CgstVal: int.parse(cGst),
              Discount: int.parse(discount),
              IgstVal: double.parse(iGst),
              OthChrg: int.parse(otherCharge),
              RndOffAmt: double.parse(roundOff),
              SgstVal: int.parse(sGst),
              StCesVal: double.parse(stateCess),
              TotInvVal: int.parse(totalTotal),
              TotInvValFc: double.parse(grandTotal));
          EInvoice eInvoice = EInvoice(
              buyerDtls: buyerDtl,
              docDtls: docDtl,
              ItemList: itemListEinvoices,
              sellerDtls: sellerDtl,
              tranDtls: tranDtls,
              valDtls: valDtl,
              Version: "1.1");
          var _data = json.encode(eInvoice);
          api
              .generateEInvoice(eWayBillClient, _username, ipAddress, _clientId,
                  _clientSecret, ackNo, companyTaxNumber, _data)
              .then((value) {
            //
          });
          //           if (rnResult.status_cd != "1")
          //           {
          //               MessageBox.Show(restResponse.get_Content());
          //           }
          //           else
          //           {
          //               this.Irn = rnResult.data.Irn;
          //               this.txtirn.Text = this.Irn;
          //               this.SignedInvoice = rnResult.data.SignedInvoice;
          //               this.SignedQRCode = rnResult.data.SignedQRCode;
          //               this.txtackdate.Text = rnResult.data.AckDt;
          //               this.txtackno.Text = rnResult.data.AckNo.ToString();
          //               this.AckDate = this.txtackdate.Text;
          //               this.AckNo = this.txtackno.Text;
          //               base.Close();
          //           }
        }
      }
    });
  }

  showEditDialog(BuildContext context) async {
    TextEditingController usernameControl =
        TextEditingController(text: _username);
    TextEditingController passwordControl =
        TextEditingController(text: _password);
    TextEditingController idControl = TextEditingController(text: _clientId);
    TextEditingController secretControl =
        TextEditingController(text: _clientSecret);
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Client Settings'),
            content: SizedBox(
              height: 300,
              child: Column(
                children: [
                  TextField(
                    controller: usernameControl,
                    textInputAction: TextInputAction.go,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Enter username"),
                    onChanged: (value) => _username = value,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  TextField(
                    controller: passwordControl,
                    textInputAction: TextInputAction.go,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Enter password"),
                    onChanged: (value) => _username = value,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  TextField(
                    controller: idControl,
                    textInputAction: TextInputAction.go,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Enter client id"),
                    onChanged: (value) => _clientId = value,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  TextField(
                    controller: secretControl,
                    textInputAction: TextInputAction.go,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Enter client secrete"),
                    onChanged: (value) => _clientSecret = value,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Update'),
                onPressed: () {
                  if (_username.isNotEmpty && _password.isNotEmpty) {
                    var data = json.encode({
                      "username": _username,
                      "password": _password,
                      "clientId": _clientId,
                      "clientSecrete": _clientSecret
                    });
                    api.eInvoiceUpdate(data).then((value) {
                      String msg = "Error update";
                      if (value) {
                        msg = "client  updated";
                      }
                      Navigator.of(context).pop();
                      Fluttertoast.showToast(msg: msg);
                    });
                  } else {
                    Fluttertoast.showToast(msg: "Enter username and password");
                  }
                },
              )
            ],
          );
        });
  }

  void setEInvoiceDetails() {
    var data = json.encode({
      "username": _username,
      "password": _password,
      "clientId": _clientId,
      "clientSecrete": _clientSecret
    });
    api.eInvoiceUpdate(data).then((value) {
      if (value) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Updated')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Error')));
      }
    });
  }
}
