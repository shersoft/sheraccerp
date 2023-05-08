// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/customer_model.dart';
import 'package:sheraccerp/models/ledger_name_model.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/screens/inventory/sales/select_product_sale.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';

class Sales extends StatefulWidget {
  const Sales({Key key}) : super(key: key);

  @override
  _SalesState createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  TextEditingController editingController = TextEditingController();
  final List<LedgerModel> _customer = [];
  List<LedgerModel> customerDisplay = [];
  List<SalesType> salesTypeDisplay = [];
  bool _selected = false, _defaultSale = false;
  DioService dio = DioService();
  LedgerModel _customerModel;
  bool isCustomForm = false,
      widgetID = true,
      previewData = false,
      valueMore = false,
      lastRecord = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int page = 1, pageTotal = 0, totalRecords = 0;

  @override
  void initState() {
    super.initState();
    isCustomForm =
        ComSettings.appSettings('bool', 'key-switch-sales-form-set', false)
            ? true
            : false;
    if (isCustomForm) {
      salesTypeDisplay =
          ComSettings.salesFormList('key-item-sale-form-', false);
    }

    taxable = salesTypeData != null
        ? salesTypeData.type == 'SALES-ES'
            ? false
            : true
        : taxable;

    fetchLedgerList();
  }

  fetchLedgerList() {
    dio.getCustomerNameList().then((value) {
      setState(() {
        _customer.addAll(value);
        customerDisplay = _customer;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final routes =
        ModalRoute.of(context).settings.arguments as Map<String, bool>;
    bool thisSale = routes['default'];

    return widgetID ? widgetPrefix(thisSale) : widgetSuffix(thisSale);
  }

  widgetSuffix(thisSale) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Sales"),
        ),
        body:
            customerDisplay.isNotEmpty ? selectCustomer() : fetchLedgerList());
  }

  widgetPrefix(thisSale) {
    setState(() {
      if (thisSale) {
        previewData = true;
      }
    });
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          actions: [
            Visibility(
              visible: previewData,
              child: TextButton(
                  child: Text(
                    previewData ? "New " + salesTypeData.name : 'Sales',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[700],
                  ),
                  onPressed: () async {
                    setState(() {
                      widgetID = false;
                    });
                  }),
            ),
          ],
          title: const Text('Sales'),
        ),
        body: thisSale
            ? Container(
                child: previousBill(),
              )
            : _defaultSale
                ? Container(
                    child: previousBill(),
                  )
                : previewData
                    ? Container(
                        child: previousBill(),
                      )
                    : Container(child: selectSalesType()));
  }

  final ScrollController _scrollController = ScrollController();
  bool isLoadingData = false;
  List dataDisplay = [];

  void _getMoreData() async {
    if (!lastRecord) {
      if ((dataDisplay.isEmpty || dataDisplay.length < totalRecords) &&
          !isLoadingData) {
        setState(() {
          isLoadingData = true;
        });

        List tempList = [];
        var statement = 'SalesList';

        dio
            .getPaginationList(
                statement, page, '1', salesTypeData.id.toString(), ' ', ' ')
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

  previousBill() {
    _getMoreData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreData();
      }
    });

    return ListView.builder(
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
              trailing:
                  Text('Total : ' + dataDisplay[index]['Total'].toString()),
              onTap: () {
                showEditDialog(context, dataDisplay[index]);
              },
            ),
          );
        }
      },
      controller: _scrollController,
    );
  }

  bool isData = false;

  selectSalesType() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: isCustomForm ? salesTypeDisplay.length : salesTypeList.length,
      itemBuilder: (context, index) {
        return _listSalesTypItem(index);
      },
    );
  }

  selectCustomer() {
    return _selected
        ? fetchCustomerDetailData(_customerModel.id)
        : ListView.builder(
            // shrinkWrap: true,
            itemBuilder: (context, index) {
              return index == 0 ? _searchBar() : _listItem(index - 1);
            },
            itemCount: customerDisplay.length + 1,
          );
  }

  customerDetail(CustomerModel model) {
    return Column(
      children: [
        Text(model.name),
      ],
    );
  }

  FutureBuilder<CustomerModel> fetchCustomerDetailData(int id) {
    return FutureBuilder<CustomerModel>(
      future: dio.getCustomerDetail(id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return getData(snapshot);
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return const Loading();
      },
    );
  }

  Widget getData(snapshot) {
    // taxable = _taxable;
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      return Padding(
        padding: const EdgeInsets.all(35.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  salesTypeData.rateType.isNotEmpty
                      ? Text(salesTypeData.rateType)
                      : widgetRateType(),
                  const SizedBox(
                    width: 40,
                  ),
                  const Text('Taxable'),
                  Checkbox(
                    value: taxable,
                    onChanged: (value) {
                      setState(() {
                        taxable = value;
                        taxable = taxable;
                      });
                    },
                  )
                ]),
            Text("Name : " + snapshot.data.name,
                style: const TextStyle(fontSize: 20)),
            Text(
                "Address : " +
                    snapshot.data.address1 +
                    " ," +
                    snapshot.data.address2 +
                    " ," +
                    snapshot.data.address3 +
                    " ," +
                    snapshot.data.address4,
                style: const TextStyle(fontSize: 18)),
            Text("Tax No : " + snapshot.data.taxNumber,
                style: const TextStyle(fontSize: 18)),
            Text("Phone : " + snapshot.data.phone,
                style: const TextStyle(fontSize: 18)),
            Text("Email : " + snapshot.data.email,
                style: const TextStyle(fontSize: 18)),
            Text("Balance : " + snapshot.data.balance,
                style: const TextStyle(fontSize: 18)),
            ElevatedButton(
              onPressed: () {
                if (salesTypeData.rateType.isNotEmpty) {
                  rateType = salesTypeData.id.toString();
                }
                model.addCustomer(snapshot.data);
                Navigator.pushReplacementNamed(context, '/add_product');
                // Navigator.push(context,
                // MaterialPageRoute(builder: (context) => AddProductsale()));
              },
              style: ElevatedButton.styleFrom(
                  elevation: 0,
                  primary: Colors.red,
                  onPrimary: Colors.white,
                  onSurface: Colors.grey),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.shopping_bag,
                      color: Colors.white,
                    ),
                    SizedBox(
                      width: 4.0,
                    ),
                    Text(
                      "Add Product To Cart",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _dropDownValue = '';
  widgetRateType() {
    return FutureBuilder(
      future: dio.getRateTypeList(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? DropdownButton<String>(
                hint: Text(_dropDownValue.isNotEmpty
                    ? _dropDownValue.split('-')[1]
                    : 'select rate type'),
                items: snapshot.data.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item.id.toString() + "-" + item.name,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _dropDownValue = value;
                    rateType = value.split('-')[0];
                  });
                },
              )
            : Container();
      },
    );
  }

  _listItem(index) {
    return InkWell(
      child: Card(
        child: ListTile(title: Text(customerDisplay[index].name)),
      ),
      onTap: () {
        setState(() {
          _customerModel = customerDisplay[index];
          _selected = true;
        });
      },
    );
  }

  _listSalesTypItem(index) {
    return InkWell(
      child: Card(
        child: ListTile(
            title: Text(isCustomForm
                ? salesTypeDisplay[index].name
                : salesTypeList[index].name)),
      ),
      onTap: () {
        setState(() {
          salesTypeData =
              isCustomForm ? salesTypeDisplay[index] : salesTypeList[index];
          // _defaultSale = true;
          // fetchLedgerList();
          previewData = true;
        });
      },
    );
  }

  _searchBar() {
    return Padding(
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
                setState(() {
                  customerDisplay = _customer.where((item) {
                    var itemName = item.name.toLowerCase();
                    return itemName.contains(text);
                  }).toList();
                });
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
                  arguments: {'parent': 'CUSTOMERS'});
            },
          )
        ],
      ),
    );
  }
}

showEditDialog(context, dataDynamic) {
  ConfirmAlertBox(
      buttonColorForNo: Colors.red,
      buttonColorForYes: Colors.green,
      icon: Icons.check,
      onPressedNo: () {
        Navigator.of(context).pop();
      },
      onPressedYes: () {
        Navigator.of(context).pop();
        fetchSale(context, dataDynamic);
      },
      buttonTextForNo: 'No',
      buttonTextForYes: 'YES',
      infoMessage: 'Do you want to edit or delete\nRefNo:${dataDynamic['Id']}',
      title: 'Update',
      context: context);
}

fetchSale(context, data) {
  rateType = salesTypeData.id.toString();
  DioService api = DioService();
  api.findSale(data['Id'], salesTypeData.id, 'SalesFind').then((value) {
    if (value != null) {
      MainModel model = MainModel();
      var responds = value['recordsets'];
      List<dynamic> information = responds[0];
      List<dynamic> particulars = responds[1];
      // List<dynamic> deliveryNoteDetails = responds[3];

      model.addCustomer({
        'Ledcode': information[0]['Customer'],
        'LedName': information[0]['Toname'],
        'add1': information[0]['Add1'],
        'add2': information[0]['Add2'],
        'add3': information[0]['Add3'],
        'add4': information[0]['Add4']
      });
      for (var product in particulars) {
        model.addProduct(CartItem(
            id: model.cart.length + 1,
            itemId: product['ItemID'],
            itemName: product['name'],
            quantity: double.tryParse(product['Qty'].toString()),
            rate: double.tryParse(product['Rate'].toString()),
            rRate: double.tryParse(product['RealRate'].toString()),
            uniqueCode: product['UniqueCode'],
            gross: double.tryParse(product['GrossValue'].toString()),
            discount: double.tryParse(product['Disc'].toString()),
            discountPercent: double.tryParse(product['DiscPersent'].toString()),
            rDiscount: double.tryParse(product['RDisc'].toString()),
            fCess: double.tryParse(product['Fcess'].toString()),
            serialNo: product['serialno'],
            tax: double.tryParse(product['CGST'].toString()) +
                double.tryParse(product['SGST'].toString()) +
                double.tryParse(product['IGST'].toString()),
            taxP: 0,
            unitId: product['Unit'],
            unitValue: double.tryParse(product['UnitValue'].toString()),
            pRate: double.tryParse(product['Prate'].toString()),
            rPRate: double.tryParse(product['Rprate'].toString()),
            barcode: product['UniqueCode'],
            expDate: '2020-01-01',
            free: double.tryParse(product['freeQty'].toString()),
            fUnitId: int.tryParse(product['Funit'].toString()),
            cdPer: 0, //product['']cdPer,
            cDisc: 0, //product['']cDisc,
            net: double.tryParse(product['GrossValue'].toString()), //subTotal,
            cess: double.tryParse(product['cess'].toString()), //cess,
            total: double.tryParse(product['Total'].toString()), //total,
            profitPer: 0, //product['']profitPer,
            fUnitValue:
                double.tryParse(product['FValue'].toString()), //fUnitValue,
            adCess: double.tryParse(product['adcess'].toString()), //adCess,
            iGST: double.tryParse(product['IGST'].toString()),
            cGST: double.tryParse(product['CGST'].toString()),
            sGST: double.tryParse(product['SGST'].toString())));
      }
    }

    // Navigator.pushReplacementNamed(context, '/preview_show',
    // arguments: {'title': 'Sale'});
  });
}
