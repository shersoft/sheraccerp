// @dart = 2.9
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/order.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';

class ConfirmOrder extends StatefulWidget {
  const ConfirmOrder({Key key}) : super(key: key);

  @override
  _ConfirmOrderState createState() => _ConfirmOrderState();
}

class _ConfirmOrderState extends State<ConfirmOrder> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DioService api = DioService();
  List<dynamic> _ledger;
  List<dynamic> otherAmountList = [];
  bool isTax = true,
      _isCashBill = false,
      otherAmountLoaded = false,
      valueMore = false,
      SalesReturnInSales = false,
      billed = false;
  final TextEditingController _controllerCashReceived = TextEditingController();
  final TextEditingController _controllerOtherDiscount =
      TextEditingController();
  final TextEditingController _controllerLoadingCharge =
      TextEditingController();
  final TextEditingController _controllerOtherCharges = TextEditingController();
  final TextEditingController _controllerLabourCharge = TextEditingController();
  final List<TextEditingController> _controllers = [];
  DateTime now = DateTime.now();
  String formattedDate, _narration = '';
  double _balance = 0, grandTotal = 0;
  Size _deviceSize;

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('dd-MM-yyyy').format(now);
    api.getSalesAccountList().then((value) {
      _ledger = value;
    });
    api.fetchDetailAmount().then((value) {
      otherAmountList = value;
      setState(() {
        otherAmountLoaded = true;
      });
    });
    loadSettings();
  }

  loadSettings() {
    // var companySettings =
    //     ScopedModel.of<MainModel>(context).getCompanySettings()[0];
    var settings = ScopedModel.of<MainModel>(context).getSettings();

    SalesReturnInSales = ComSettings.getStatus('ENABLE MULTI-UNIT', settings);
  }

  @override
  Widget build(BuildContext context) {
    _deviceSize = MediaQuery.of(context).size;
    isTax = salesTypeData.tax;
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      // order.customerModel.addAll(model.customer);
      // order.lineItems.addAll(model.cart);
      return Scaffold(
          appBar: AppBar(
            key: _scaffoldKey,
            backgroundColor: kPrimaryColor,
            title: const Text("Confirm"),
            leading: Container(),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/add_product');
                },
                child: const Icon(
                  Icons.shopping_basket,
                  color: Colors.white,
                ),
              ),
              TextButton(
                  child: const Text(
                    "Save",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[700],
                  ),
                  onPressed: () async {
                    saleAccount = _ledger[0]['ledcode'].toString();
                    var salesManId = ComSettings.appSettings(
                            'int', 'key-dropdown-default-salesman-view', 1) -
                        1;
                    int lId = ComSettings.appSettings(
                            'int', 'key-dropdown-default-location-view', 2) -
                        1;
                    var locationId = lId.toString().trim().isNotEmpty
                        ? lId
                        : salesTypeData.location;
                    Order _order = Order(
                        customerModel:
                            ScopedModel.of<MainModel>(context).customer,
                        lineItems: ScopedModel.of<MainModel>(context).cart,
                        grossValue: ScopedModel.of<MainModel>(context)
                            .totalGrossValue
                            .toString(),
                        discount: ScopedModel.of<MainModel>(context)
                            .totalDiscount
                            .toString(),
                        rDiscount: ScopedModel.of<MainModel>(context)
                            .totalRDiscount
                            .toString(),
                        net: ScopedModel.of<MainModel>(context)
                            .totalNet
                            .toString(),
                        cGST: ScopedModel.of<MainModel>(context)
                            .totalCgST
                            .toString(),
                        sGST: ScopedModel.of<MainModel>(context)
                            .totalSgST
                            .toString(),
                        iGST: ScopedModel.of<MainModel>(context)
                            .totalIgST
                            .toString(),
                        cess: ScopedModel.of<MainModel>(context)
                            .totalCess
                            .toString(),
                        adCess: ScopedModel.of<MainModel>(context)
                            .totalAdCess
                            .toString(),
                        fCess: ScopedModel.of<MainModel>(context)
                            .totalFCess
                            .toString(),
                        total: ScopedModel.of<MainModel>(context)
                            .totalCartValue
                            .toString(),
                        grandTotal: grandTotal > 0
                            ? grandTotal.toString()
                            : ScopedModel.of<MainModel>(context)
                                .totalCartValue
                                .toString(),
                        profit: ScopedModel.of<MainModel>(context)
                            .totalProfit
                            .toString(),
                        cashReceived: _controllerCashReceived.text.isNotEmpty
                            ? _controllerCashReceived.text
                            : '0',
                        otherDiscount: _controllerOtherDiscount.text.isNotEmpty
                            ? _controllerOtherDiscount.text
                            : '0',
                        loadingCharge: _controllerLoadingCharge.text.isNotEmpty
                            ? _controllerLoadingCharge.text
                            : '0',
                        otherCharges: _controllerOtherCharges.text.isNotEmpty
                            ? _controllerOtherCharges.text
                            : '0',
                        labourCharge: _controllerLabourCharge.text.isNotEmpty
                            ? _controllerLabourCharge.text
                            : '0',
                        discountPer: '0',
                        balanceAmount: _balance > 0
                            ? _balance.toStringAsFixed(2)
                            : _controllerCashReceived.text.isNotEmpty
                                ? grandTotal > 0
                                    ? ComSettings.appSettings(
                                            'bool', 'key-round-off-amount', false)
                                        ? (grandTotal - double.tryParse(_controllerCashReceived.text))
                                            .toStringAsFixed(2)
                                        : (grandTotal - double.tryParse(_controllerCashReceived.text))
                                            .roundToDouble()
                                            .toString()
                                    : ComSettings.appSettings(
                                            'bool', 'key-round-off-amount', false)
                                        ? ((model.totalCartValue) -
                                                double.tryParse(_controllerCashReceived
                                                    .text))
                                            .toStringAsFixed(2)
                                        : ((model.totalCartValue) -
                                                double.tryParse(_controllerCashReceived.text))
                                            .roundToDouble()
                                            .toString()
                                : grandTotal > 0
                                    ? ComSettings.appSettings('bool', 'key-round-off-amount', false)
                                        ? grandTotal.toStringAsFixed(2)
                                        : grandTotal.roundToDouble().toString()
                                    : ComSettings.appSettings('bool', 'key-round-off-amount', false)
                                        ? model.totalCartValue.toStringAsFixed(2)
                                        : model.totalCartValue.roundToDouble().toString(),
                        creditPeriod: '0',
                        narration: _narration.isNotEmpty ? _narration : '',
                        takeUser: '1',
                        location: locationId.toString(),
                        billType: '0',
                        roundOff: '0',
                        salesMan: salesManId.toString(),
                        sType: salesTypeData.rateType,
                        dated: DateUtil.dateYMD(formattedDate),
                        cashAC: _isCashBill ? '1' : '0',
                        otherAmountData: otherAmountList);
                    if (_order.lineItems.isNotEmpty) {
                      bool _stateIsChanged =
                          false; //await model.saveSale(_order);
                      if (_stateIsChanged) {
                        ScopedModel.of<MainModel>(context).clearCart();
                        showMore(context);
                      }
                    }
                  }),
            ],
            bottom: model.isLoading
                ? const PreferredSize(
                    child: LinearProgressIndicator(),
                    preferredSize: Size.fromHeight(10),
                  )
                : PreferredSize(
                    child: Container(),
                    preferredSize: const Size.fromHeight(10),
                  ),
          ),
          body: ScopedModel.of<MainModel>(context, rebuildOnChange: true)
                  .cart
                  .isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("No items in Cart"),
                      TextButton.icon(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(kPrimaryColor),
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.shopping_bag),
                          label: const Text('Take New Sale'))
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(3.0),
                  child: Column(children: [
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                          itemCount: 1,
                          itemBuilder: (context, index) {
                            return ScopedModelDescendant<MainModel>(
                                builder: (context, child, model) {
                              return Container(
                                color: Colors.blue[50],
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        const Text(
                                          'Date : ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        InkWell(
                                          child: Text(
                                            formattedDate,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18),
                                          ),
                                          onTap: () => _selectDate(),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        const Text(
                                          'Cash Bill: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        Checkbox(
                                          checkColor: Colors.greenAccent,
                                          activeColor: Colors.red,
                                          value: _isCashBill,
                                          onChanged: (bool value) {
                                            setState(() {
                                              _isCashBill = value;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    ListTile(
                                      title: Text(model.customer[index].name,
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(model.customer[index].address1),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            });
                          }),
                    ),
                    Expanded(
                      child: otherAmountLoaded
                          ? ListView.builder(
                              itemCount: ScopedModel.of<MainModel>(context,
                                      rebuildOnChange: true)
                                  .totalItem,
                              itemBuilder: (context, index) {
                                return ScopedModelDescendant<MainModel>(
                                  builder: (context, child, model) {
                                    return ListTile(
                                      title: Text(model.cart[index].itemName),
                                      subtitle: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            height: 40,
                                            width: 40,
                                            child: Card(
                                              color: Colors.green[200],
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.add,
                                                  color: Colors.black,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  model.updateProduct(
                                                      model.cart[index],
                                                      model.cart[index]
                                                              .quantity +
                                                          1);
                                                },
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            child: Text(
                                                model.cart[index].quantity
                                                    .toString(),
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            onTap: () {
                                              _displayTextInputDialog(
                                                  context,
                                                  'Edit Quantity',
                                                  model.cart[index].quantity > 0
                                                      ? double.tryParse(model
                                                              .cart[index]
                                                              .quantity
                                                              .toString())
                                                          .toString()
                                                      : '',
                                                  model.cart[index].id);
                                            },
                                          ),
                                          SizedBox(
                                            height: 40,
                                            width: 40,
                                            child: Card(
                                              color: Colors.red[200],
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.remove,
                                                  color: Colors.black,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  model.updateProduct(
                                                      model.cart[index],
                                                      model.cart[index]
                                                              .quantity -
                                                          1);
                                                },
                                              ),
                                            ),
                                          ),
                                          Text(
                                              model.cart[index].unitId > 0
                                                  ? '(' +
                                                      UnitSettings.getUnitName(
                                                          model.cart[index]
                                                              .unitId) +
                                                      ')'
                                                  : " x ",
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12)),
                                          InkWell(
                                            child: Text(
                                                model.cart[index].rate
                                                    .toStringAsFixed(2),
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            onTap: () {
                                              _displayTextInputDialog(
                                                  context,
                                                  'Edit Rate',
                                                  model.cart[index].rate > 0
                                                      ? double.tryParse(model
                                                              .cart[index].rate
                                                              .toString())
                                                          .toString()
                                                      : '',
                                                  model.cart[index].id);
                                            },
                                          ),
                                          const Text(" = ",
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                              ((model.cart[index].quantity *
                                                          model.cart[index]
                                                              .rate) -
                                                      (model.cart[index]
                                                          .discount))
                                                  .toStringAsFixed(2),
                                              style: const TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20)),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : const Text(''),
                    ),
                    Container(
                      color: Colors.blue[50],
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("SubTotal: ",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[300])),
                              Text(
                                  CommonService.getRound(
                                          2,
                                          (ScopedModel.of<MainModel>(context,
                                                  rebuildOnChange: true)
                                              .totalGrossValue))
                                      .toStringAsFixed(2),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[300])),
                            ],
                          ),
                          Visibility(
                            visible: isTax,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Tax: ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[400])),
                                Text(
                                    CommonService.getRound(
                                            2,
                                            (ScopedModel.of<MainModel>(context,
                                                    rebuildOnChange: true)
                                                .taxTotalCartValue))
                                        .toStringAsFixed(2),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[400])),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total: ",
                                  style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[500])),
                              Text(
                                  CommonService.getRound(
                                          2,
                                          (ScopedModel.of<MainModel>(context,
                                                  rebuildOnChange: true)
                                              .totalCartValue))
                                      .toStringAsFixed(2),
                                  style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[500])),
                            ],
                          ),
                          Card(
                            elevation: 5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const Text('More Details'),
                                Checkbox(
                                    value: valueMore,
                                    onChanged: (value) {
                                      setState(() {
                                        valueMore = value;
                                      });
                                    }),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: valueMore,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          label: Text('Narration'),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _narration = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: _deviceSize.height / 6,
                                  child: Container(
                                    color: white,
                                    child: ListView.builder(
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: otherAmountList.length,
                                        shrinkWrap: true,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          _controllers
                                              .add(TextEditingController());
                                          _controllers[index].text =
                                              otherAmountList[index]['amount']
                                                  .toString();
                                          return Container(
                                              padding: const EdgeInsets.only(
                                                  top: 0, right: 10, left: 10),
                                              child: Row(children: <Widget>[
                                                expandStyle(
                                                    2,
                                                    Container(
                                                        margin: const EdgeInsets
                                                            .only(top: 35),
                                                        child: Text(
                                                            otherAmountList[
                                                                    index]
                                                                ['ledname']))),
                                                expandStyle(
                                                    1,
                                                    TextFormField(
                                                        controller: TextEditingController.fromValue(TextEditingValue(
                                                            text: otherAmountList[
                                                                        index]
                                                                    ['amount']
                                                                .toString(),
                                                            selection: TextSelection.collapsed(
                                                                offset: otherAmountList[
                                                                            index]
                                                                        [
                                                                        'amount']
                                                                    .toString()
                                                                    .length))),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        onFieldSubmitted:
                                                            (String str) {
                                                          //       //
                                                          //     },
                                                          // onChanged: (String str) {
                                                          // String str = '';
                                                          var cartTotal = (ScopedModel.of<
                                                                      MainModel>(
                                                                  context,
                                                                  rebuildOnChange:
                                                                      true)
                                                              .totalCartValue);
                                                          if (str.isNotEmpty) {
                                                            otherAmountList[
                                                                        index]
                                                                    ['amount'] =
                                                                double.tryParse(
                                                                    str);
                                                            otherAmountList[
                                                                        index]
                                                                    [
                                                                    'pecentage'] =
                                                                CommonService.getRound(
                                                                    2,
                                                                    ((double.tryParse(str) *
                                                                            100) /
                                                                        cartTotal));

                                                            // print(total);

                                                            var netTotal = cartTotal +
                                                                otherAmountList.fold(
                                                                    0,
                                                                    (t, e) =>
                                                                        t +
                                                                        double.parse(e['symbol'] ==
                                                                                '-'
                                                                            ? (e['amount'] * -1).toString()
                                                                            : e['amount'].toString()));
                                                            // print(
                                                            //     'grand : $netTotal');
                                                            setState(() {
                                                              grandTotal =
                                                                  netTotal;
                                                            });
                                                          }
                                                        }))
                                              ]));
                                        }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GrandTotal : ',
                                  style: TextStyle(
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red)),
                              Text(
                                  grandTotal > 0
                                      ? ComSettings.appSettings(
                                              'bool', 'key-round-off-amount', false)
                                          ? CommonService.getRound(2, grandTotal)
                                              .toString()
                                          : CommonService.getRound(2, grandTotal)
                                              .roundToDouble()
                                              .toString()
                                      : ComSettings.appSettings(
                                              'bool', 'key-round-off-amount', false)
                                          ? CommonService.getRound(
                                                  2,
                                                  (ScopedModel.of<MainModel>(context,
                                                          rebuildOnChange: true)
                                                      .totalCartValue))
                                              .toString()
                                          : CommonService.getRound(
                                                  2,
                                                  (ScopedModel.of<MainModel>(context, rebuildOnChange: true)
                                                          .totalCartValue)
                                                      .roundToDouble())
                                              .toString(),
                                  style: const TextStyle(
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red))
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controllerCashReceived,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter(
                                        RegExp(r'[0-9]'),
                                        allow: true,
                                        replacementString: '.')
                                  ],
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    label: Text('Cash Received'),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _balance = _controllerCashReceived
                                              .text.isNotEmpty
                                          ? grandTotal > 0
                                              ? grandTotal -
                                                  double.tryParse(
                                                      _controllerCashReceived
                                                          .text)
                                              : ((model.totalCartValue) -
                                                  double.tryParse(
                                                      _controllerCashReceived
                                                          .text))
                                          : grandTotal > 0
                                              ? grandTotal
                                              : model.totalCartValue;
                                    });
                                  },
                                ),
                              ),
                              const Text('Balance : '),
                              Text(ComSettings.appSettings(
                                      'bool', 'key-round-off-amount', false)
                                  ? _balance.toStringAsFixed(2)
                                  : _balance.roundToDouble().toString()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ])));
    });
  }

  expandStyle(int flex, Widget child) => Expanded(flex: flex, child: child);

  Future<void> _displayTextInputDialog(
      BuildContext context, String title, String text, int id) async {
    TextEditingController _controller = TextEditingController();
    String valueText;
    _controller.text = text;
    return showDialog(
      context: context,
      builder: (context) {
        return ScopedModelDescendant<MainModel>(
            builder: (context, child, model) {
          return (StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                onChanged: (value) {
                  setState(() {
                    valueText = value;
                  });
                },
                controller: _controller,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text("value")),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter(RegExp(r'[0-9]'),
                      allow: true, replacementString: '.')
                ],
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('CANCEL'),
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                    });
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('OK'),
                  onPressed: () {
                    setState(() {
                      // var more = {"Tax": ""};
                      model.editProduct(title, valueText, id);
                      Navigator.pop(context);
                    });
                  },
                ),
              ],
            );
          }));
        });
      },
    );
  }

  Future _selectDate() async {
    DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null)
      setState(() => {formattedDate = DateFormat('dd-MM-yyyy').format(picked)});
  }
}

showMore(context) {
  ConfirmAlertBox(
      buttonColorForNo: Colors.red,
      buttonColorForYes: Colors.green,
      icon: Icons.check,
      onPressedNo: () {
        Navigator.of(context).pop();
        // var settings = ScopedModel.of<MainModel>(context).getSettings();
        // bool sType = ComSettings.getValue('TOOLBAR SALES', settings)
        //         .toString()
        //         .isNotEmpty
        //     ? ComSettings.selectSalesType(
        //         ComSettings.getValue('TOOLBAR SALES', settings))
        //     : false;
        Navigator.pop(context);
      },
      onPressedYes: () {
        Navigator.of(context).pop();
        Navigator.pushReplacementNamed(context, '/preview_show',
            arguments: {'title': 'Sales'});
      },
      buttonTextForNo: 'No',
      buttonTextForYes: 'YES',
      infoMessage:
          'Do you want to Preview\nRefNo:${dataDynamic[0]['RealEntryNo']}\nNo:${dataDynamic[0]['EntryNo']}\nInvoice:${dataDynamic[0]['InvoiceNo']}',
      title: 'SAVED',
      context: context);
}
