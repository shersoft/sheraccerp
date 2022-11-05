// @dart = 2.9
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/company.dart';
import 'package:sheraccerp/models/sales_type.dart';
import 'package:sheraccerp/models/stock_item.dart';
import 'package:sheraccerp/models/stock_product.dart';
import 'package:sheraccerp/models/unit_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/service/api_dio.dart';
import 'package:sheraccerp/service/com_service.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/dateUtil.dart';
import 'package:sheraccerp/util/res_color.dart';
import 'package:sheraccerp/widget/loading.dart';
import 'package:intl/intl.dart';

class ProductsListPage extends StatefulWidget {
  const ProductsListPage({Key key}) : super(key: key);

  @override
  _ProductsListPageState createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  TextEditingController editingController = TextEditingController();
  List<StockItem> items = [];
  List<StockItem> itemDisplay = [];
  DioService api = DioService();
  bool _loading = false;
  DateTime now = DateTime.now();
  String formattedDate;
  //declare
  bool outOfStock = false,
      enableMULTIUNIT = false,
      pRateBasedProfitInSales = false,
      isTax = true,
      negativeStock = false,
      cessOnNetAmount = false,
      negativeStockStatus = false,
      enableKeralaFloodCess = false,
      useUNIQUECODEASBARCODE = false,
      useOLDBARCODE = false,
      keyItemsVariantStock = false;

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    loadSettings();
    api.fetchStockProduct(DateUtil.dateDMY2YMD(formattedDate)).then((value) {
      setState(() {
        items.addAll(value);
        itemDisplay = items;
      });
    });
  }

  loadSettings() {
    CompanyInformation companySettings =
        ScopedModel.of<MainModel>(context).getCompanySettings();
    List<CompanySettings> settings =
        ScopedModel.of<MainModel>(context).getSettings();

    taxMethod = companySettings.taxCalculation;
    enableMULTIUNIT = ComSettings.getStatus('ENABLE MULTI-UNIT', settings);
    pRateBasedProfitInSales =
        ComSettings.getStatus('PRATE BASED PROFIT IN SALES', settings);
    negativeStock = ComSettings.getStatus('ALLOW NEGETIVE STOCK', settings);
    companyTaxMode = ComSettings.getValue('PACKAGE', settings);
    cessOnNetAmount = ComSettings.getStatus('CESS ON NET AMOUNT', settings);
    enableKeralaFloodCess = false;
    useUNIQUECODEASBARCODE =
        ComSettings.getStatus('USE UNIQUECODE AS BARCODE', settings);
    useOLDBARCODE = ComSettings.getStatus('USE OLD BARCODE', settings);
    keyItemsVariantStock =
        ComSettings.getStatus('KEY LOCK SALES DISCOUNT', settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        actions: [
          IconButton(
            icon: Icon(Icons.remove_shopping_cart, color: Colors.red[400]),
            onPressed: () => ScopedModel.of<MainModel>(context).clearCart(),
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.green[400]),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/check_out');
            },
          ),
        ],
        leading: Container(),
      ),
      body: _loading ? _loadProduct() : _loadCart(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _loading = true;
          });
        },
        child: const Icon(Icons.add_shopping_cart),
        backgroundColor: kPrimaryColor,
      ),
    );
  }

  _loadProduct() {
    return ListView.builder(
      // shrinkWrap: true,
      itemBuilder: (context, index) {
        return index == 0 ? _searchBar() : _listItem(index - 1);
      },
      itemCount: itemDisplay.length + 1,
    );
  }

  _loadCart() {
    return ScopedModel.of<MainModel>(context, rebuildOnChange: true)
            .cart
            .isEmpty
        ? const Center(
            child: Text("No items in Cart"),
          )
        : Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: <Widget>[
              Expanded(
                child: ListView.builder(
                  itemCount:
                      ScopedModel.of<MainModel>(context, rebuildOnChange: true)
                          .totalItem,
                  itemBuilder: (context, index) {
                    return ScopedModelDescendant<MainModel>(
                      builder: (context, child, model) {
                        return ListTile(
                          title: Text(model.cart[index].itemName),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      model.updateProduct(model.cart[index],
                                          model.cart[index].quantity + 1);
                                    },
                                  ),
                                ),
                              ),
                              InkWell(
                                child: Text(
                                    model.cart[index].quantity.toString(),
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                                onTap: () {
                                  _displayTextInputDialog(
                                      context,
                                      'Edit Quantity',
                                      model.cart[index].quantity > 0
                                          ? double.tryParse(model
                                                  .cart[index].quantity
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
                                      model.updateProduct(model.cart[index],
                                          model.cart[index].quantity - 1);
                                      // model.removeProduct(model.cart[index]);
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                  model.cart[index].unitId > 0
                                      ? '(' +
                                          UnitSettings.getUnitName(
                                              model.cart[index].unitId) +
                                          ')'
                                      : " x ",
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 12)),
                              InkWell(
                                child: Text(
                                    model.cart[index].rate.toStringAsFixed(2),
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
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
                                              model.cart[index].rate) -
                                          (model.cart[index].discount))
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
                ),
              ),
              Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    ComSettings.appSettings(
                            'bool', 'key-round-off-amount', false)
                        ? "Total: " +
                            ScopedModel.of<MainModel>(context,
                                    rebuildOnChange: true)
                                .totalCartValue
                                .toStringAsFixed(2) +
                            ""
                        : "Total: " +
                            ScopedModel.of<MainModel>(context,
                                    rebuildOnChange: true)
                                .totalCartValue
                                .roundToDouble()
                                .toString() +
                            "",
                    style: const TextStyle(
                        fontSize: 24.0, fontWeight: FontWeight.bold),
                  )),
              // SizedBox(
              //     width: double.infinity,
              //     child: ElevatedButton(
              //       style: ElevatedButton.styleFrom(
              //           elevation: 0,
              //           primary: Colors.blue[900],
              //           onPrimary: Colors.white,
              //           onSurface: Colors.grey),
              //       child: Text("Check Out"),
              //       onPressed: () {
              //         Navigator.pushNamed(context, '/check_out');
              //       },
              //     ))
            ]));
  }

  _listItem(index) {
    return ScopedModelDescendant<MainModel>(builder: (context, child, model) {
      return InkWell(
        child: Card(
          child: ListTile(
            title: Text('Name : ${itemDisplay[index].name}'),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Qty :${itemDisplay[index].quantity}'),
                // TextButton(
                //     onPressed: () {
                //       // api
                //       //     .fetchStockVariant(itemDisplay[index].id)
                //       //     .then((response) {
                //       //   // response.length > 0 ?
                //       //   var product = response[0];
                //       //   if (!inCart) {
                //       //     double kfcP = kfcPer,
                //       //         rRate = 0,
                //       //         saleRate = 0,
                //       //         cessPer = 0,
                //       //         taxP = 0,
                //       //         rDisc = 0,
                //       //         gross = 0,
                //       //         subTotal = 0,
                //       //         total = 0,
                //       //         quantity = 1,
                //       //         kfc = 0,
                //       //         tax = 0,
                //       //         csGST = 0,
                //       //         iGST = 0,
                //       //         cess = 0,
                //       //         adCess = 0,
                //       //         adCessPer = 0,
                //       //         profitPer = 0,
                //       //         unitValue = 1;
                //       //     cessPer = product.cessPer;
                //       //     adCessPer = product.adCessPer;
                //       //     taxP = salesTypeData.type == 'SALES-ES'
                //       //         ? 0
                //       //         : salesTypeData.type == 'SALES-Q'
                //       //             ? 0
                //       //             : salesTypeData.type == 'SALES-O'
                //       //                 ? 0
                //       //                 : product.tax;
                //       //     if (salesTypeData.rateType == 'RETAIL') {
                //       //       saleRate = product.retailPrice;
                //       //     } else if (salesTypeData.rateType == 'WHOLESALE') {
                //       //       saleRate = product.wholeSalePrice;
                //       //     } else {
                //       //       saleRate = product.sellingPrice;
                //       //     }
                //       //     rRate = taxMethod == 'MINUS'
                //       //         ? cessOnNetAmount
                //       //             ? CommonService.getRound(
                //       //                 2,
                //       //                 (100 * saleRate) /
                //       //                     (100 + taxP + kfcP + cessPer))
                //       //             : CommonService.getRound(
                //       //                 2, (100 * saleRate) / (100 + taxP + kfcP))
                //       //         : saleRate;
                //       //     gross =
                //       //         CommonService.getRound(2, ((rRate * quantity)));
                //       //     subTotal = CommonService.getRound(2, (gross - rDisc));
                //       //     if (taxP > 0) {
                //       //       tax = CommonService.getRound(
                //       //           2, ((subTotal * taxP) / 100));
                //       //     }
                //       //     kfc = isKFC
                //       //         ? CommonService.getRound(
                //       //             2, ((subTotal * kfcP) / 100))
                //       //         : 0;
                //       //     if (companyTaxMode == 'INDIA') {
                //       //       double csPer = taxP / 2;
                //       //       iGST = 0;
                //       //       csGST = CommonService.getRound(
                //       //           2, ((subTotal * csPer) / 100));
                //       //     } else if (companyTaxMode == 'GULF') {
                //       //       iGST = tax = CommonService.getRound(
                //       //           2, ((subTotal * taxP) / 100));
                //       //       csGST = 0;
                //       //       kfc = 0;
                //       //     } else {
                //       //       iGST = 0;
                //       //       csGST = 0;
                //       //       kfc = 0;
                //       //       tax = 0;
                //       //     }
                //       //     if (cessOnNetAmount) {
                //       //       if (cessPer > 0) {
                //       //         cess = CommonService.getRound(
                //       //             2, ((subTotal * cessPer) / 100));
                //       //         adCess = CommonService.getRound(
                //       //             2, (quantity * adCessPer));
                //       //       } else {
                //       //         cess = 0;
                //       //         adCess = 0;
                //       //       }
                //       //     } else {
                //       //       cess = 0;
                //       //       adCess = 0;
                //       //     }
                //       //     total = CommonService.getRound(
                //       //         2,
                //       //         (subTotal +
                //       //             csGST +
                //       //             csGST +
                //       //             iGST +
                //       //             cess +
                //       //             kfc +
                //       //             adCess));
                //       //     unitValue = UnitSettings.getUnitListItemValue(
                //       //         product.itemId, 'Conversion');
                //       //     if (enableMULTIUNIT && unitValue > 0) {
                //       //       profitPer = pRateBasedProfitInSales
                //       //           ? CommonService.getRound(
                //       //               2,
                //       //               (total -
                //       //                   (product.buyingPrice *
                //       //                       unitValue *
                //       //                       quantity)))
                //       //           : CommonService.getRound(
                //       //               2,
                //       //               (total -
                //       //                   (product.buyingPriceReal *
                //       //                       unitValue *
                //       //                       quantity)));
                //       //     } else {
                //       //       profitPer = pRateBasedProfitInSales
                //       //           ? CommonService.getRound(2,
                //       //               (total - (product.buyingPrice * quantity)))
                //       //           : CommonService.getRound(
                //       //               2,
                //       //               (total -
                //       //                   (product.buyingPriceReal * quantity)));
                //       //     }
                //       //     model.addProduct(CartItem(
                //       //         id: model.cart.length + 1,
                //       //         itemId: product.itemId,
                //       //         itemName: product.name,
                //       //         quantity: quantity,
                //       //         rate: saleRate,
                //       //         rRate: rRate,
                //       //         uniqueCode: product.productId.toString(),
                //       //         gross: gross,
                //       //         discount: 0,
                //       //         discountPercent: 0,
                //       //         rDiscount: rDisc,
                //       //         fCess: kfc,
                //       //         serialNo: '',
                //       //         tax: tax,
                //       //         taxP: taxP,
                //       //         unitId: defaultUnitID,
                //       //         unitValue: unitValue,
                //       //         pRate: product.buyingPrice,
                //       //         rPRate: product.buyingPriceReal,
                //       //         barcode: 0,
                //       //         expDate: '2000-01-01',
                //       //         free: 0,
                //       //         fUnitId: 0,
                //       //         cdPer: 0,
                //       //         cDisc: 0,
                //       //         net: subTotal,
                //       //         cess: cess,
                //       //         total: total,
                //       //         profitPer: profitPer,
                //       //         fUnitValue: 0,
                //       //         adCess: adCess,
                //       //         iGST: iGST,
                //       //         cGST: csGST,
                //       //         sGST: csGST));
                //       //     inCart = true;
                //       //     Fluttertoast.showToast(msg: product.name + '\nadded');
                //       //   }
                //       // });
                //       Fluttertoast.showToast(msg: 'Not Available');
                //     },
                //     child: const Card(child: Text('ADD')))
              ],
            ),
          ),
        ),
        onTap: () {
          if (salesTypeData.stock) {
            itemDisplay[index].hasVariant
                ? showVariantDialog(
                    itemDisplay[index].id,
                    itemDisplay[index].name,
                    itemDisplay[index].quantity.toString())
                : api.fetchStockVariant(itemDisplay[index].id).then((response) {
                    showAddMore(context, response[0]);
                  });
            // showD();
          } else {
            api.fetchStockItem(itemDisplay[index].id).then((response) {
              // StockProduct sp = StockProduct(
              //   name: itemDisplay[index].name,
              //   itemId: itemDisplay[index].id,
              //   adCessPer: 0,
              // );
              showAddMore(context, response[0]);
            });
          }
        },
      );
    });
  }

  _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: const InputDecoration(hintText: 'Search...'),
        onChanged: (text) {
          text = text.toLowerCase();
          setState(() {
            itemDisplay = items.where((item) {
              var itemName = item.name.toLowerCase();
              return itemName.contains(text);
            }).toList();
          });
        },
      ),
    );
  }

  bool isVariantSelected = false;
  int positionID = 0;
  // List<StockProduct> _autoStockVariant = [];
  // double _stockVariantQuantity = 0;
  showVariantDialog(int id, String name, String quantity) {
    // _stockVariantQuantity = double.tryParse(quantity);
    api.fetchStockVariant(id).then((response) {
      if (response.isNotEmpty) {
        // _autoStockVariant.clear();
        // _autoStockVariant = _autoVariantSelect ? snapshot.data : [];
        isVariantSelected
            ? showAddMore(context, response[0])
            : keyItemsVariantStock
                ? showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        scrollable: true,
                        title: Text(name),
                        content: SizedBox(
                          height: 200.0,
                          width: 400.0,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: response.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                elevation: 5,
                                child: ListTile(
                                    title: Text(
                                        'Id: ${response[index].productId}'),
                                    subtitle: Text(
                                        'Quantity : ${response[index].quantity} Rate ${response[index].sellingPrice}'),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      showAddMore(context, response[index]);
                                    }),
                              );
                            },
                          ),
                        ),
                      );
                    })
                : showAddMore(context, response[0]);
      } else {
        //no data stock ledger missing
      }
    });
  }

  showAddMore(BuildContext context, StockProduct product) {
    TextEditingController _quantityController = TextEditingController();
    TextEditingController _rateController = TextEditingController();
    TextEditingController _discountController = TextEditingController();
    // TextEditingController _discountPercentController = TextEditingController();
    final _resetKey = GlobalKey<FormState>();
    String expDate = '2000-01-01';
    int _dropDownUnit = 0, fUnitId = 0, uniqueCode = 0, barcode = 0;
    bool rateEdited = false;

    double taxP = 0,
        tax = 0,
        gross = 0,
        subTotal = 0,
        total = 0,
        quantity = 0,
        rate = 0,
        saleRate = 0,
        discount = 0,
        discountPercent = 0,
        rDisc = 0,
        rRate = 0,
        kfcP = 0,
        kfc = 0,
        unitValue = 1,
        _conversion = 0,
        free = 0,
        fUnitValue = 0,
        cdPer = 0,
        cDisc = 0,
        cess = 0,
        cessPer = 0,
        adCessPer = 0,
        profitPer = 0,
        adCess = 0,
        iGST = 0,
        csGST = 0,
        pRate = product.buyingPrice,
        rPRate = product.buyingPriceReal;
    // isTax = salesTypeData.type == 'SALES-ES'
    //     ? false
    //     : salesTypeData.type == 'SALES-Q'
    //         ? false
    //         : salesTypeData.type == 'SALES-O'
    //             ? false
    //             : true;
    isTax = taxable;
    taxP = isTax ? product.tax : 0;
    cess = isTax ? product.cess : 0;
    cessPer = isTax ? product.cessPer : 0;
    adCessPer = isTax ? product.adCessPer : 0;
    kfcP = isTax
        ? enableKeralaFloodCess
            ? kfcPer
            : 0
        : 0;
    if (salesTypeData.rateType == 'RETAIL') {
      saleRate = product.retailPrice;
    } else if (salesTypeData.rateType == 'WHOLESALE') {
      saleRate = product.wholeSalePrice;
    } else {
      saleRate = product.sellingPrice;
    }
    if (saleRate > 0) {
      _rateController.text = taxMethod == 'MINUS'
          ? isTax
              ? CommonService.getRound(
                      2, (saleRate * 100) / (100 + product.tax + kfcP))
                  .toString()
              : saleRate.toString()
          : saleRate.toString();
    }
    uniqueCode = product.productId;
    List<UnitModel> unitList = [];
    var _unitName, _unitP, _unitS, _unitOn;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ScopedModelDescendant<MainModel>(
            builder: (context, child, model) {
          return (StatefulBuilder(builder: (context, setState) {
            calculate() {
              if (enableMULTIUNIT) {
                if (saleRate > 0) {
                  if (_conversion > 0) {
                    var r = 0.0;
                    if (rateEdited) {
                      r = double.tryParse(_rateController.text);
                    } else {
                      r = (saleRate * _conversion);
                      _rateController.text = r.toStringAsFixed(2);
                    }
                    rate = r;
                    pRate = product.buyingPrice * _conversion;
                    rPRate = product.buyingPriceReal * _conversion;
                  } else {
                    rate = _rateController.text.isNotEmpty
                        ? (double.tryParse(_rateController.text))
                        : 0;
                  }
                } else {
                  rate = _rateController.text.isNotEmpty
                      ? (double.tryParse(_rateController.text))
                      : 0;
                }
              } else {
                rate = _rateController.text.isNotEmpty
                    ? double.tryParse(_rateController.text)
                    : 0;
              }
              quantity = _quantityController.text.isNotEmpty
                  ? double.tryParse(_quantityController.text)
                  : 0;
              rRate = taxMethod == 'MINUS'
                  ? cessOnNetAmount
                      ? CommonService.getRound(
                          4, (100 * rate) / (100 + taxP + kfcP + cessPer))
                      : CommonService.getRound(
                          4, (100 * rate) / (100 + taxP + kfcP))
                  : rate;
              discount = _discountController.text.isNotEmpty
                  ? double.tryParse(_discountController.text)
                  : 0;
              rDisc = taxMethod == 'MINUS'
                  ? CommonService.getRound(4, ((discount * 100) / (taxP + 100)))
                  : discount;
              gross = CommonService.getRound(2, ((rRate * quantity)));
              subTotal = CommonService.getRound(2, (gross - rDisc));
              if (taxP > 0) {
                tax = CommonService.getRound(2, ((subTotal * taxP) / 100));
              }
              if (companyTaxMode == 'INDIA') {
                kfc = isKFC
                    ? CommonService.getRound(2, ((subTotal * kfcP) / 100))
                    : 0;
                double csPer = taxP / 2;
                iGST = 0;
                csGST = CommonService.getRound(2, ((subTotal * csPer) / 100));
              } else if (companyTaxMode == 'GULF') {
                iGST = CommonService.getRound(2, ((subTotal * taxP) / 100));
                csGST = 0;
                kfc = 0;
              } else {
                iGST = 0;
                csGST = 0;
                kfc = 0;
                tax = 0;
              }
              if (cessOnNetAmount) {
                if (cessPer > 0) {
                  cess =
                      CommonService.getRound(2, ((subTotal * cessPer) / 100));
                  adCess = CommonService.getRound(2, (quantity * adCessPer));
                } else {
                  cess = 0;
                  adCess = 0;
                }
              } else {
                cess = 0;
                adCess = 0;
              }
              total = CommonService.getRound(
                  2, (subTotal + csGST + csGST + iGST + cess + kfc + adCess));
              if (enableMULTIUNIT && _conversion > 0) {
                profitPer = pRateBasedProfitInSales
                    ? CommonService.getRound(
                        2,
                        (total -
                            (product.buyingPrice * _conversion * quantity)))
                    : CommonService.getRound(
                        2,
                        (total -
                            (product.buyingPriceReal *
                                _conversion *
                                quantity)));
              } else {
                profitPer = pRateBasedProfitInSales
                    ? CommonService.getRound(
                        2, (total - (product.buyingPrice * quantity)))
                    : CommonService.getRound(
                        2, (total - (product.buyingPriceReal * quantity)));
              }
              unitValue = _conversion > 0 ? _conversion : 1;
            }

            return AlertDialog(
              title: Text(
                product.name,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _resetKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: TextFormField(
                              controller: _quantityController,
                              // autofocus: true,
                              validator: (value) {
                                if (outOfStock) {
                                  return 'No Stock';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                    allow: true, replacementString: '.')
                              ],
                              decoration: const InputDecoration(
                                  labelText: 'quantity', hintText: '0.0'),
                              onChanged: (value) {
                                setState(() {
                                  outOfStock = negativeStock
                                      ? false
                                      : salesTypeData.stock
                                          ? double.tryParse(value) >
                                                  product.quantity
                                              ? true
                                              : false
                                          : false;
                                  calculate();
                                });
                              },
                            ),
                          )),
                          Visibility(
                            visible: enableMULTIUNIT,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: FutureBuilder(
                                  future: api.fetchUnitOf(product.itemId),
                                  builder: (BuildContext context,
                                      AsyncSnapshot snapshot) {
                                    if (snapshot.hasData) {
                                      unitList.clear();
                                      for (var i = 0;
                                          i < snapshot.data.length;
                                          i++) {
                                        if (defaultUnitID
                                            .toString()
                                            .isNotEmpty) {
                                          if (snapshot.data[i].id ==
                                              defaultUnitID - 1) {
                                            _dropDownUnit = snapshot.data[i].id;
                                            _conversion =
                                                snapshot.data[i].conversion;
                                          }
                                        }
                                        unitList.add(UnitModel(
                                            id: snapshot.data[i].id,
                                            itemId: snapshot.data[i].itemId,
                                            conversion:
                                                snapshot.data[i].conversion,
                                            name: snapshot.data[i].name,
                                            pUnit: snapshot.data[i].pUnit,
                                            sUnit: snapshot.data[i].sUnit,
                                            unit: snapshot.data[i].unit));
                                      }
                                    }
                                    return snapshot.hasData
                                        ? DropdownButton<String>(
                                            hint: const Text('SKU'),
                                            value: _dropDownUnit.toString(),
                                            items: snapshot.data
                                                .map<DropdownMenuItem<String>>(
                                                    (item) {
                                              return DropdownMenuItem<String>(
                                                value: item.id.toString(),
                                                child: Text(item.name),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _dropDownUnit =
                                                    int.tryParse(value);
                                                for (var i = 0;
                                                    i < unitList.length;
                                                    i++) {
                                                  UnitModel _unit = unitList[i];
                                                  if (_unit.unit ==
                                                      int.tryParse(value)) {
                                                    _conversion =
                                                        _unit.conversion;
                                                    _unitName = _unit.name;
                                                    _unitP = _unit.pUnit;
                                                    _unitS = _unit.sUnit;
                                                    _unitOn = _unit.unit;
                                                    break;
                                                  }
                                                }
                                                calculate();
                                                _rateController.text =
                                                    rate.toStringAsFixed(2);
                                              });
                                            },
                                          )
                                        : Container();
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: enableMULTIUNIT
                                ? _conversion > 0
                                    ? true
                                    : false
                                : false,
                            child: Expanded(
                                child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text('$_conversion'),
                            )),
                          ),
                        ],
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: TextField(
                                controller: _rateController,
                                // autofocus: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                      allow: true, replacementString: '.')
                                ],
                                decoration: const InputDecoration(
                                    labelText: 'price', hintText: '0.0'),
                                onChanged: (value) {
                                  setState(() {
                                    rateEdited = _rateController.text.isNotEmpty
                                        ? true
                                        : false;
                                    calculate();
                                  });
                                },
                              ),
                            )),
                            Visibility(
                              visible: taxMethod == 'MINUS',
                              child: Text(
                                '$rRate',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          ]),
                      Row(
                        children: [
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: TextField(
                              controller: _discountController,
                              // autofocus: true,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter(RegExp(r'[0-9]'),
                                    allow: true, replacementString: '.')
                              ],
                              decoration: const InputDecoration(
                                  labelText: 'discount', hintText: '0.0'),
                              onChanged: (value) {
                                setState(() {
                                  calculate();
                                });
                              },
                            ),
                          )),
                          Visibility(
                            visible: isTax,
                            child: Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Text('Tax % : $taxP'))),
                          )
                        ],
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text('SubTotal : $subTotal'),
                            ),
                            Visibility(
                              visible: isTax,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Text('Tax : $tax'),
                              ),
                            ),
                          ]),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text('Total : $total'),
                            ),
                          ]),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("CANCEL"),
                  onPressed: () {
                    //Put your code here which you want to execute on Yes button click.
                    Navigator.of(context).pop();
                    _loading = false;
                  },
                ),
                TextButton(
                  child: const Text("ADD"),
                  onPressed: () {
                    outOfStock
                        ? ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Sorry stock not available.'),
                            duration: const Duration(seconds: 10),
                            action: SnackBarAction(
                              label: 'Click',
                              onPressed: () {
                                // print('Action is clicked');
                              },
                              textColor: Colors.white,
                              disabledTextColor: Colors.grey,
                            ),
                            backgroundColor: Colors.red,
                          ))
                        : model.addProduct(CartItem(
                            id: model.cart.length + 1,
                            itemId: product.itemId,
                            itemName: product.name,
                            quantity: quantity,
                            rate: rate,
                            rRate: rRate,
                            uniqueCode: uniqueCode,
                            gross: gross,
                            discount: discount,
                            discountPercent: discountPercent,
                            rDiscount: rDisc,
                            fCess: kfc,
                            serialNo: '',
                            tax: tax,
                            taxP: taxP,
                            unitId: _dropDownUnit,
                            unitValue: unitValue,
                            pRate: pRate,
                            rPRate: rPRate,
                            barcode: barcode,
                            expDate: expDate,
                            free: free,
                            fUnitId: fUnitId,
                            cdPer: cdPer,
                            cDisc: cDisc,
                            net: subTotal,
                            cess: cess,
                            total: total,
                            profitPer: profitPer,
                            fUnitValue: fUnitValue,
                            adCess: adCess,
                            iGST: iGST,
                            cGST: csGST,
                            sGST: csGST));
                    Navigator.of(context).pop();
                    _loading = false;
                  },
                ),
              ],
            );
          }));
        });
      },
    );
  }

  Future<void> _displayTextInputDialog(
      BuildContext context, String title, String text, int id) async {
    TextEditingController _controller = TextEditingController();
    String valueText;
    _controller.text = ComSettings.getIfInteger(text);
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
                decoration: const InputDecoration(hintText: "value"),
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
}
