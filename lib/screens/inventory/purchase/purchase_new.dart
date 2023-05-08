import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/provider/ledger_provider.dart';
import 'package:sheraccerp/provider/purchase_provider.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class PurchaseNew extends StatefulWidget {
  const PurchaseNew({Key? key}) : super(key: key);

  @override
  State<PurchaseNew> createState() => _PurchaseNewState();
}

class _PurchaseNewState extends State<PurchaseNew> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool lastRecord = false;
  int page = 1, pageTotal = 0, totalRecords = 0;
  DioService dio = DioService();

  @override
  Widget build(BuildContext context) {
    PurchaseProvider provider =
        Provider.of<PurchaseProvider>(context, listen: false);
    return WillPopScope(
        onWillPop: _onWillPop,
        child: provider.widgetID
            ? widgetPrefix(provider)
            : widgetSuffix(provider));
  }

  Future<bool> _onWillPop() async {
    PurchaseProvider provider = Provider.of<PurchaseProvider>(context);
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit Purchase'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  provider.setNextWidget = 0;
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  widgetSuffix(PurchaseProvider provider) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        actions: [
          Visibility(
            visible: provider.oldBill,
            child: IconButton(
                color: red,
                iconSize: 40,
                onPressed: () {
                  if (provider.cartItem.isNotEmpty) {
                    setState(() {
                      provider.setIsLoading = true;
                    });
                    // delete(context);
                  } else {
                    // showInSnackBar('No items found on bill');
                  }
                },
                icon: const Icon(Icons.delete_forever)),
          ),
          provider.oldBill
              ? IconButton(
                  color: green,
                  iconSize: 40,
                  onPressed: () async {
                    // if (buttonEvent) {
                    //   return;
                    // } else {
                    //   setState(() {
                    //     _isLoading = true;
                    //     buttonEvent = true;
                    //   });
                    //   var inf = '[' +
                    //       json.encode({
                    //         'id': ledgerModel.id,
                    //         'name': ledgerModel.name,
                    //         'invNo': invNoController.text.isNotEmpty
                    //             ? invNoController.text
                    //             : '0',
                    //         'invDate': DateUtil.dateYMD(invDate)
                    //       }) +
                    //       ']';
                    //   var jsonItem = CartItemP.encodeCartToJson(cartItem);
                    //   var items = json.encode(jsonItem);
                    //   var stType = 'P_Update';
                    //   var data = '[' +
                    //       json.encode({
                    //         'entryNo': dataDynamic[0]['EntryNo'],
                    //         'date': DateUtil.dateYMD(formattedDate),
                    //         'grossValue': totalGrossValue,
                    //         'discount': totalDiscount,
                    //         'net': totalNet,
                    //         'cess': totalCess,
                    //         'total': totalCartTotal,
                    //         'otherCharges': 0,
                    //         'otherDiscount': 0,
                    //         'grandTotal': totalCartTotal,
                    //         'taxType': isTax ? 'T' : 'N.T',
                    //         'purchaseAccount': purchaseAccountList[0]['id'],
                    //         'narration': _narration,
                    //         'type': 'P',
                    //         'cashPaid': cashPaidController.text.isNotEmpty
                    //             ? cashPaidController.text
                    //             : '0',
                    //         'igst': totalIgST,
                    //         'cgst': totalCgST,
                    //         'sgst': totalSgST,
                    //         'fCess': totalFCess,
                    //         'adCess': totalAdCess,
                    //         'Salesman': salesManId,
                    //         'location': locationId,
                    //         'statementtype': stType
                    //       }) +
                    //       ']';

                    //   final body = {
                    //     'information': inf,
                    //     'data': data,
                    //     'particular': items
                    //   };
                    //   bool _state = await dio.addPurchase(body);
                    //   setState(() {
                    //     _isLoading = false;
                    //   });
                    //   if (_state) {
                    //     cartItem.clear();
                    //     showMore(context, 'Edited');
                    //   } else {
                    //     showInSnackBar('Error enter data correctly');
                    //     setState(() {
                    //       buttonEvent = false;
                    //     });
                    //   }
                    // }
                  },
                  icon: const Icon(Icons.edit))
              : IconButton(
                  color: blue,
                  iconSize: 40,
                  onPressed: () async {
                    // if (buttonEvent) {
                    //   return;
                    // } else {
                    //   setState(() {
                    //     _isLoading = true;
                    //     buttonEvent = true;
                    //   });
                    //   var inf = '[' +
                    //       json.encode({
                    //         'id': ledgerModel.id,
                    //         'name': ledgerModel.name,
                    //         'invNo': invNoController.text.isNotEmpty
                    //             ? invNoController.text
                    //             : '0',
                    //         'invDate': DateUtil.dateYMD(invDate)
                    //       }) +
                    //       ']';
                    //   var jsonItem = CartItemP.encodeCartToJson(cartItem);
                    //   var items = json.encode(jsonItem);
                    //   var stType = 'P_Insert';
                    //   var data = '[' +
                    //       json.encode({
                    //         'date': DateUtil.dateYMD(formattedDate),
                    //         'grossValue': totalGrossValue,
                    //         'discount': totalDiscount,
                    //         'net': totalNet,
                    //         'cess': totalCess,
                    //         'total': totalCartTotal,
                    //         'otherCharges': 0,
                    //         'otherDiscount': 0,
                    //         'grandTotal': totalCartTotal,
                    //         'taxType': isTax ? 'T' : 'N.T',
                    //         'purchaseAccount': purchaseAccountList[0]['id'],
                    //         'narration': _narration,
                    //         'type': 'P',
                    //         'cashPaid': cashPaidController.text.isNotEmpty
                    //             ? cashPaidController.text
                    //             : '0',
                    //         'igst': totalIgST,
                    //         'cgst': totalCgST,
                    //         'sgst': totalSgST,
                    //         'fCess': totalFCess,
                    //         'adCess': totalAdCess,
                    //         'Salesman': salesManId,
                    //         'location': locationId,
                    //         'statementtype': stType
                    //       }) +
                    //       ']';

                    //   final body = {
                    //     'information': inf,
                    //     'data': data,
                    //     'particular': items
                    //   };
                    //   bool _state = await dio.addPurchase(body);
                    //   setState(() {
                    //     _isLoading = false;
                    //   });
                    //   if (_state) {
                    //     cartItem.clear();
                    //     showMore(context, 'Saved');
                    //   } else {
                    //     showInSnackBar('Error enter data correctly');
                    //     setState(() {
                    //       buttonEvent = false;
                    //     });
                    //   }
                    // }
                  },
                  icon: const Icon(Icons.save)),
        ],
        title: const Text('Purchase'),
      ),
      body: ProgressHUD(
          inAsyncCall: provider.isLoading,
          opacity: 0.0,
          child: const SelectWidget()),
    );
  }

  widgetPrefix(PurchaseProvider provider) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          actions: [
            TextButton(
                child: const Text(
                  " New ",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue[700],
                ),
                onPressed: () async {
                  setState(() {
                    provider.setWidgetID = false;
                  });
                }),
          ],
          title: const Text('Purchase'),
        ),
        body: Container(
          child: previousBill(provider),
        ));
  }

  final ScrollController _scrollController = ScrollController();
  bool isLoadingData = false;
  List dataDisplay = [];

  void _getMoreData(PurchaseProvider provider) async {
    if (!lastRecord) {
      if (dataDisplay.isEmpty ||
          // ignore: curly_braces_in_flow_control_structures
          dataDisplay.length < totalRecords) if (!isLoadingData) {
        setState(() {
          isLoadingData = true;
        });

        List tempList = [];
        var statement = 'PurchaseList';

        dio
            .getPaginationList(
                statement,
                page,
                '1',
                '0',
                DateUtil.dateYMD(provider.formattedDate),
                provider.salesManId.toString())
            .then((value) {
          if (value.isEmpty) {
            return;
          }
          final response = value;
          pageTotal = response[1][0]['Filtered'];
          totalRecords = response[1][0]['Total'];
          page++;
          for (int i = 0; i < response[0].length; i++) {
            tempList.add(response[0][i]);
          }

          setState(() {
            isLoadingData = false;
            dataDisplay.addAll(tempList);
            lastRecord = tempList.isNotEmpty ? false : true;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  previousBill(PurchaseProvider provider) {
    _getMoreData(provider);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreData(provider);
      }
    });

    return dataDisplay.isNotEmpty
        ? ListView.builder(
            itemCount: dataDisplay.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == dataDisplay.length) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Opacity(
                      opacity: isLoadingData ? 1.0 : 00,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                );
              } else {
                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(dataDisplay[index]['Name']),
                    subtitle: Text('Date: ' +
                        dataDisplay[index]['Date'] +
                        ' / EntryNo : ' +
                        dataDisplay[index]['Id'].toString()),
                    trailing: Text(
                        'Total : ' + dataDisplay[index]['Total'].toString()),
                    onTap: () {
                      // showEditDialog(context, dataDisplay[index]);
                    },
                  ),
                );
              }
            },
            controller: _scrollController,
          )
        : Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No items in Purchase"),
              TextButton.icon(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(kPrimaryColor),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                  onPressed: () {
                    setState(() {
                      provider.setWidgetID = false;
                    });
                  },
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Take New Purchase'))
            ],
          ));
  }
}

class SelectWidget extends StatelessWidget {
  const SelectWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    PurchaseProvider provider = Provider.of<PurchaseProvider>(context);
    return provider.nextWidget == 0
        ? const LedgerWidget()
        : provider.nextWidget == 1
            ? const PurchaseHeaderWidget()
            : const Center(child: Text('No widget'));
  }
}

class LedgerWidget extends StatelessWidget {
  const LedgerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    PurchaseProvider provider =
        Provider.of<PurchaseProvider>(context, listen: false);
    return Consumer<LedgerProvider>(builder: (context, ledgerProvider, child) {
      var data = ledgerProvider.ledgerDisplay;
      return data.isEmpty
          ? const Loading()
          : ListView.builder(
              // shrinkWrap: true,
              itemBuilder: (context, index) {
                return index == 0
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Flexible(
                              child: TextField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Search...',
                                ),
                                onChanged: (text) {
                                  text = text.toLowerCase();
                                  ledgerProvider.ledgerDisplay =
                                      ledgerProvider.ledger.where((item) {
                                    var itemName = item.name.toLowerCase();
                                    return itemName.contains(text);
                                  }).toList();
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: kPrimaryColor,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/ledger',
                                    arguments: {'parent': 'SUPPLIERS'});
                              },
                            )
                          ],
                        ),
                      )
                    : InkWell(
                        child: Card(
                          child: ListTile(title: Text(data[index - 1].name)),
                        ),
                        onTap: () {
                          // setState(() {
                          provider.ledgerModel = data[index - 1];
                          provider.setNextWidget = 1;
                          // });
                        },
                      );
              },
              itemCount: data.length + 1,
            );
    });
  }
}

class PurchaseHeaderWidget extends StatelessWidget {
  const PurchaseHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    PurchaseProvider provider =
        Provider.of<PurchaseProvider>(context, listen: false);
    return Center(
        child: Column(
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Text(
                          'Date : ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          child: Text(
                            provider.formattedDate,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () => _selectDate(provider, 'f', context),
                        ),
                        const Text(
                          'Tax:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Checkbox(
                          checkColor: Colors.greenAccent,
                          activeColor: Colors.red,
                          value: provider.isTax,
                          onChanged: (bool? value) {
                            provider.isTax = value!;
                          },
                        ),
                        const Visibility(
                          visible: false,
                          child: Text(
                            'Cash:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Visibility(
                          visible: false,
                          child: Checkbox(
                            checkColor: Colors.greenAccent,
                            activeColor: Colors.red,
                            value: provider.isCashBill,
                            onChanged: (bool? value) {
                              provider.isTax = value!;
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Text('Inv.No:'),
                        SizedBox(
                          width: 100,
                          height: 20,
                          child: TextField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            // controller: invNoController,
                            // onChanged: (value) {
                            //   setState(() {
                            //     invNoController.text = value;
                            //   });
                            // },
                          ),
                        ),
                        const Text('Inv.Date:'),
                        // InkWell(
                        //   child: Text(invDate),
                        //   onTap: () => _selectDate('t'),
                        // ),
                      ],
                    ),
                    // ListTile(
                    //   title: Text(ledgerModel.name,
                    //       style: const TextStyle(
                    //           fontWeight: FontWeight.bold, color: Colors.red)),
                    // ),
                  ],
                );
              }),
        ),
        InkWell(
            child: const SizedBox(
              height: 40,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Text(
                      'Add Item',
                      style: TextStyle(
                          color: blue,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                    ),
                  )),
            ),
            onTap: () {
              // setState(() {
              //   nextWidget = 2;
              // });
            }),
        // SizedBox(
        //   height: _deviceSize.height / 6,
        //   child: Container(child: Text('xz')),
        // ),
      ],
    ));
  }
}

Future _selectDate(
    PurchaseProvider provider, String type, BuildContext context) async {
  DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100));
  if (picked != null) {
    // setState(() => {
    //       if (type == 'f')
    //         {formattedDate = DateFormat('dd-MM-yyyy').format(picked)}
    //       else
    //         {invDate = DateFormat('dd-MM-yyyy').format(picked)}
    //     });
  }
}

/**/