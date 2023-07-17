// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sheraccerp/models/product_manage_model.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:intl/intl.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/progress_hud.dart';

class ProductManagement extends StatefulWidget {
  ProductManagement({Key key}) : super(key: key);

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DioService api = DioService();
  DataJson productModel;
  Size deviceSize;
  String productId = '';
  List<DataJson> productList = [];
  bool _isLoading = false, isExist = false, buttonEvent = false;
  String _result;

  @override
  void initState() {
    api.fetchAllProductPurchase().then((value) {
      setState(() {
        for (var data in value) {
          productList.add(DataJson(id: data['slno'], name: data['itemname']));
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    deviceSize = MediaQuery.of(context).size;
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              var result = await showSearch<List<DataJson>>(
                context: context,
                delegate: CustomDelegateProduct(productList),
              );

              setState(() {
                _result = result[0].name;
                productId = result[0].id.toString();
                if (productId.isNotEmpty) {
                  findProductDetails(productId);
                }
              });
            },
          ),
        ]),
        body: ProgressHUD(
            inAsyncCall: _isLoading, opacity: 0.0, child: formWidget()));
  }

  int nextWidget = 0;
  List<ProductManageModel> productData = [];
  ProductManageModel productSingle;
  DateTime now = DateTime.now();

  TextEditingController controllerOBarcode = TextEditingController();
  TextEditingController controllerMrp = TextEditingController();
  TextEditingController controllerRetail = TextEditingController();
  TextEditingController controllerSPRetail = TextEditingController();
  TextEditingController controllerWholeSale = TextEditingController();
  TextEditingController controllerBranch = TextEditingController();

  String oBarcode = '';
  double quantity = 0,
      mrp = 0,
      retail = 0,
      spRetail = 0,
      wholeSale = 0,
      branch = 0;
  int _index = 0;

  formWidget() {
    return nextWidget == 0
        ? const Center(
            child: Text('Select Product'),
          )
        : nextWidget == 1
            ? productData.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    // shrinkWrap: true,
                    itemCount: productData.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        child: Card(
                          child: ListTile(
                              title: Text(
                                  '${productData[index].uniquecode} $_result')),
                        ),
                        onTap: () {
                          setState(() {
                            _index = index;
                            productSingle = productData[index];
                            controllerMrp.text =
                                productSingle.mrp.toStringAsFixed(2);
                            controllerRetail.text =
                                productSingle.retail.toStringAsFixed(2);
                            controllerSPRetail.text =
                                productSingle.spretail.toStringAsFixed(2);
                            controllerWholeSale.text =
                                productSingle.wSrate.toStringAsFixed(2);
                            controllerBranch.text =
                                productSingle.branch.toStringAsFixed(2);
                            controllerOBarcode.text = productSingle.obarcode;
                            nextWidget = 2;
                          });
                        },
                      );
                    })
            : nextWidget == 2
                ? Container(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Item : $_result')),
                          Row(
                            children: [
                              Expanded(
                                  child: MaterialButton(
                                onPressed: () {
                                  setState(() {
                                    nextWidget = 1;
                                    clearValue();
                                  });
                                },
                                child: const Text("Back"),
                                color: blue[400],
                              )),
                              const SizedBox(
                                width: 2,
                              ),
                              Expanded(
                                  child: MaterialButton(
                                onPressed: () {
                                  setState(() {
                                    nextWidget = 0;
                                  });
                                },
                                child: const Text("Cancel"),
                                color: blue[400],
                              )),
                              const SizedBox(
                                width: 2,
                              ),
                              Expanded(
                                  child: MaterialButton(
                                onPressed: () {
                                  setState(() {
                                    oBarcode =
                                        controllerOBarcode.text.isNotEmpty
                                            ? controllerOBarcode.text
                                            : '';
                                    mrp = controllerMrp.text.isNotEmpty
                                        ? double.tryParse(controllerMrp.text)
                                        : mrp;
                                    retail = controllerRetail.text.isNotEmpty
                                        ? double.tryParse(controllerRetail.text)
                                        : retail;
                                    wholeSale =
                                        controllerWholeSale.text.isNotEmpty
                                            ? double.tryParse(
                                                controllerWholeSale.text)
                                            : wholeSale;
                                    spRetail =
                                        controllerSPRetail.text.isNotEmpty
                                            ? double.tryParse(
                                                controllerSPRetail.text)
                                            : spRetail;
                                    branch = controllerBranch.text.isNotEmpty
                                        ? double.tryParse(controllerBranch.text)
                                        : branch;
                                    if (productSingle.uniquecode
                                        .toString()
                                        .isNotEmpty) {
                                      productSingle.obarcode = oBarcode;
                                      productSingle.mrp = mrp;
                                      productSingle.retail = retail;
                                      productSingle.spretail = spRetail;
                                      productSingle.wSrate = wholeSale;
                                      productSingle.branch = branch;
                                      productData.removeAt(_index);
                                      productData.insert(_index, productSingle);
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      updateData();
                                      //   clearValue();
                                      //   editItem = false;
                                    }
                                  });
                                },
                                child: const Text("Add"),
                                color: blue,
                              )),
                            ],
                          ),
                          TextField(
                            controller: controllerOBarcode,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                label: Text('Old Barcode')),
                            onChanged: (value) {
                              setState(() {
                                // editableRate = true;
                                oBarcode = value;
                              });
                            },
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const Text('Mrp'),
                              SizedBox(
                                height: 30,
                                width: 100,
                                child: TextField(
                                  controller: controllerMrp,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      label: Text('MRP')),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter(
                                        RegExp(r'[0-9]'),
                                        allow: true,
                                        replacementString: '.')
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      // editableMrp = true;
                                      mrp = double.tryParse(value);
                                    });
                                  },
                                ),
                              ),
                              const Text('Retail'),
                              SizedBox(
                                height: 30,
                                width: 100,
                                child: TextField(
                                  controller: controllerRetail,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      label: Text('Retail')),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter(
                                        RegExp(r'[0-9]'),
                                        allow: true,
                                        replacementString: '.')
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      // editableRetail = true;
                                      retail = double.tryParse(value);
                                      // calculateRate();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const Text('WholeSale'),
                              SizedBox(
                                height: 30,
                                width: 100,
                                child: TextField(
                                  controller: controllerWholeSale,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      label: Text('WholeSale')),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter(
                                        RegExp(r'[0-9]'),
                                        allow: true,
                                        replacementString: '.')
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      // editableWSale = true;
                                      wholeSale = double.tryParse(value);
                                      // calculateRate();
                                    });
                                  },
                                ),
                              ),
                              const Text('Branch'),
                              SizedBox(
                                height: 30,
                                width: 100,
                                child: TextField(
                                  controller: controllerBranch,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      label: Text('Branch')),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter(
                                        RegExp(r'[0-9]'),
                                        allow: true,
                                        replacementString: '.')
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      // editableBranch = true;
                                      branch = double.tryParse(value);
                                      // calculateRate();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : nextWidget == 3
                    ? const Center(
                        child: Text('Product Updated'),
                      )
                    : nextWidget == 4
                        ? const Center(
                            child: Text('Update Error'),
                          )
                        : const Center(
                            child: Text('No widget'),
                          );
  }

  void findProductDetails(String productId) {
    productData = [];
    var date =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);
    api.fetchProductDetails(productId, DateUtil.dateYMD(date)).then((data) {
      productData.addAll(data);
      setState(() {
        nextWidget = 1;
      });
    });
  }

  void clearValue() {
    controllerOBarcode.text = '';
    controllerMrp.text = '';
    controllerRetail.text = '';
    controllerSPRetail.text = '';
    controllerWholeSale.text = '';
    controllerBranch.text = '';
    productSingle = null;
    _index = 0;
  }

  void updateData() {
    api.updateProductDetails(productData).then((value) {
      setState(() {
        value ? nextWidget = 3 : nextWidget = 4;
        _isLoading = false;
      });
    });
  }
}

class CustomDelegateProduct extends SearchDelegate<List<DataJson>> {
  List<DataJson> data;
  CustomDelegateProduct(this.data);

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.chevron_left),
      onPressed: () => close(context, []));

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) {
    List<DataJson> listToShow;
    if (query.isNotEmpty) {
      listToShow = data
          .where((e) =>
              e.name.toLowerCase().contains(query.toLowerCase()) &&
              e.name.toLowerCase().startsWith(query.toLowerCase()))
          .toList();
    } else {
      listToShow = data;
    }
    return ListView.builder(
      itemCount: listToShow.length,
      itemBuilder: (_, i) {
        var noun = listToShow[i];
        return ListTile(
          title: Text(noun.name),
          onTap: () => close(context, [noun]),
        );
      },
    );
  }
}
