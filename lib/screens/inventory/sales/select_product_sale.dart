// @dart = 2.9
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:scoped_model/scoped_model.dart';
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
import 'package:intl/intl.dart';

class AddProductsale extends StatefulWidget {
  AddProductsale({Key key}) : super(key: key);

  @override
  State<AddProductsale> createState() => _AddProductsaleState();
}

class _AddProductsaleState extends State<AddProductsale> {
  //declare
  bool outOfStock = false,
      enableMULTIUNIT = false,
      pRateBasedProfitInSales = false,
      negativeStock = false,
      cessOnNetAmount = false,
      negativeStockStatus = false,
      enableKeralaFloodCess = false,
      useUNIQUECODEASBARCODE = false,
      useOLDBARCODE = false,
      isMinimumRatedLock = false;
  DateTime now = DateTime.now();
  String formattedDate, _narration = '';
  bool isItemData = false;
  int saleAccount = 0, acId = 0, decimal = 2;
  int lId = 0, groupId = 0;
  var salesManId = 0;
  bool productScanner = false, loadScanner = false;
  Barcode result;
  bool itemCodeVise = false,
      isItemRateEditLocked = false,
      isMinimumRate = false,
      isItemDiscountEditLocked = false,
      keyItemsVariantStock = false;

  @override
  void initState() {
    super.initState();
    formattedDate =
        getToDay.isNotEmpty ? getToDay : DateFormat('dd-MM-yyyy').format(now);

    CompanyInformation companySettings =
        ScopedModel.of<MainModel>(context).getCompanySettings();
    List<CompanySettings> settings =
        ScopedModel.of<MainModel>(context).getSettings();
    lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;

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
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;
    isItemDiscountEditLocked =
        ComSettings.getStatus('KEY LOCK SALES DISCOUNT', settings);
    isItemRateEditLocked =
        ComSettings.getStatus('KEY LOCK SALES RATE', settings);
    isMinimumRate =
        ComSettings.getStatus('KEY LOCK MINIMUM SALES RATE', settings);

    itemCodeVise = ComSettings.appSettings('bool', 'key-item-by-code', false);
    keyItemsVariantStock =
        ComSettings.appSettings('bool', 'key-items-variant-stock', false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: selectProductWidget());
  }

  List<dynamic> itemDisplay = [];
  List<dynamic> items = [];
  DioService dio = DioService();

  selectProductWidget() {
    setState(() {
      if (items.isNotEmpty) isItemData = true;
    });
    return FutureBuilder<List<StockItem>>(
      future: dio.fetchStockProduct(DateUtil.dateDMY2YMD(formattedDate)),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            var data = snapshot.data;
            if (!isItemData) {
              itemDisplay = data;
              items = data;
            }
            return ListView.builder(
              // shrinkWrap: true,
              itemBuilder: (context, index) {
                return index == 0
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Search...'),
                          onChanged: (text) {
                            text = text.toLowerCase();
                            setState(() {
                              itemDisplay = items.where((item) {
                                var itemName = itemCodeVise
                                    ? item.code.toString().toLowerCase() +
                                        ' ' +
                                        item.name.toLowerCase()
                                    : item.name.toLowerCase();
                                return itemName.contains(text);
                              }).toList();
                            });
                          },
                        ),
                      )
                    : InkWell(
                        child: Card(
                          child: ListTile(
                            title: Text(
                                'Name : ${itemCodeVise ? itemDisplay[index - 1].code.toString() + ' ' + itemDisplay[index - 1].name : itemDisplay[index - 1].name}'),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Qty :${itemDisplay[index - 1].quantity}'),
                                // TextButton(
                                //     onPressed: () {
                                // if (singleProduct) {
                                //   addProduct(CartItem(
                                // id: totalItem + 1,
                                // itemId: product.itemId,
                                // itemName: product.name,
                                // quantity: 1,
                                // rate: rate,
                                // rRate: rRate,
                                // uniqueCode: uniqueCode,
                                // gross: gross,
                                // discount: discount,
                                // discountPercent: discountPercent,
                                // rDiscount: rDisc,
                                // fCess: kfc,
                                // serialNo: '',
                                // tax: tax,
                                // taxP: taxP,
                                // unitId: _dropDownUnit,
                                // unitValue: unitValue,
                                // pRate: pRate,
                                // rPRate: rPRate,
                                // barcode: barcode,
                                // expDate: expDate,
                                // free: free,
                                // fUnitId: fUnitId,
                                // cdPer: cdPer,
                                // cDisc: cDisc,
                                // net: subTotal,
                                // cess: cess,
                                // total: total,
                                // profitPer: profitPer,
                                // fUnitValue: fUnitValue,
                                // adCess: adCess,
                                // iGST: iGST,
                                // cGST: csGST,
                                // sGST: csGST));
                                // } else {
                                // Fluttertoast.showToast(
                                // msg: 'this is not Completed');
                                // }
                                // },
                                // child: const Card(
                                //     child: Text(' + ',
                                //         style: TextStyle(
                                //             fontSize: 25, color: blue))))
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            productModel = itemDisplay[index - 1];
                          });
                        },
                      );
              },
              itemCount: itemDisplay.length + 1,
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [SizedBox(height: 20), Text('No Data Found..')],
              ),
            );
          }
        } else if (snapshot.hasError) {
          return AlertDialog(
            title: const Text(
              'An Error Occurred!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
              ),
            ),
            content: Text(
              "${snapshot.error}",
              style: const TextStyle(
                color: Colors.blueAccent,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('This may take some time..')
            ],
          ),
        );
      },
    );
  }
}

class ProductAddSale extends StatefulWidget {
  ProductAddSale({Key key}) : super(key: key);

  @override
  State<ProductAddSale> createState() => _ProductAddSaleState();
}

class _ProductAddSaleState extends State<ProductAddSale> {
  //declare
  bool outOfStock = false,
      enableMULTIUNIT = false,
      pRateBasedProfitInSales = false,
      negativeStock = false,
      cessOnNetAmount = false,
      negativeStockStatus = false,
      enableKeralaFloodCess = false,
      useUNIQUECODEASBARCODE = false,
      useOLDBARCODE = false,
      isMinimumRatedLock = false;

  bool isItemData = false;
  int saleAccount = 0, acId = 0, decimal = 2;
  int lId = 0, groupId = 0;
  var salesManId = 0;
  bool productScanner = false, loadScanner = false;
  Barcode result;
  bool itemCodeVise = false,
      isItemRateEditLocked = false,
      isMinimumRate = false,
      isItemDiscountEditLocked = false,
      keyItemsVariantStock = false;

  @override
  void initState() {
    super.initState();
    CompanyInformation companySettings =
        ScopedModel.of<MainModel>(context).getCompanySettings();
    List<CompanySettings> settings =
        ScopedModel.of<MainModel>(context).getSettings();

    lId = ComSettings.appSettings(
            'int', 'key-dropdown-default-location-view', 2) -
        1;

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
    decimal = ComSettings.getValue('DECIMAL', settings).toString().isNotEmpty
        ? int.tryParse(ComSettings.getValue('DECIMAL', settings).toString())
        : 2;
    isItemDiscountEditLocked =
        ComSettings.getStatus('KEY LOCK SALES DISCOUNT', settings);
    isItemRateEditLocked =
        ComSettings.getStatus('KEY LOCK SALES RATE', settings);
    isMinimumRate =
        ComSettings.getStatus('KEY LOCK MINIMUM SALES RATE', settings);

    itemCodeVise = ComSettings.appSettings('bool', 'key-item-by-code', false);
    keyItemsVariantStock =
        ComSettings.appSettings('bool', 'key-items-variant-stock', false);
  }

  DioService dio = DioService();
  Size deviceSize;

  @override
  Widget build(BuildContext context) {
    deviceSize = MediaQuery.of(context).size;
    return Container(child: itemDetailWidget());
  }

  itemDetailWidget() {
    return productModel.hasVariant
        ? showVariantDialog(productModel.id, productModel.name,
            productModel.quantity.toString())
        : selectStockLedger();
  }

  selectStockLedger() {
    return FutureBuilder(
        future: dio.fetchStockVariant(productModel.id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.length > 0) {
              return showAddMore(context, snapshot.data[0]);
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text('Stock Ledger Data Missing...'),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            // nextWidget = 2;
                          });
                        },
                        child: const Text('Select Product Again'))
                  ],
                ),
              );
            }
          } else if (snapshot.hasError) {
            return AlertDialog(
              title: const Text(
                'An Error Occurred!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
              content: Text(
                "${snapshot.error}",
                style: const TextStyle(
                  color: Colors.blueAccent,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('This may take some time..')
              ],
            ),
          );
        });
  }

  bool isVariantSelected = false;
  int positionID = 0;
  // List<StockProduct> _autoStockVariant = [];
  // double _stockVariantQuantity = 0;
  showVariantDialog(int id, String name, String quantity) {
    // _stockVariantQuantity = double.tryParse(quantity);
    return FutureBuilder<List<StockProduct>>(
      future: dio.fetchStockVariant(id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isNotEmpty) {
            // _autoStockVariant.clear();
            // _autoStockVariant = _autoVariantSelect ? snapshot.data : [];
            return isVariantSelected
                ? showAddMore(context, snapshot.data[positionID])
                : keyItemsVariantStock
                    ? SizedBox(
                        height: deviceSize.height - 20,
                        width: 400.0,
                        child: ListView(children: [
                          Center(child: Text(name + ' / ' + quantity)),
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: snapshot.data.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                elevation: 5,
                                child: ListTile(
                                    title: Text(
                                        'Id: ${snapshot.data[index].productId} / Quantity : ${snapshot.data[index].quantity} '),
                                    subtitle: Text(ComSettings.appSettings(
                                            'bool',
                                            'key-item-sale-retail',
                                            false)
                                        ? 'Mrp : ${snapshot.data[index].sellingPrice} / Retail : ${snapshot.data[index].retailPrice}'
                                        : 'Rate : ${snapshot.data[index].sellingPrice}'),
                                    onTap: () {
                                      setState(() {
                                        isVariantSelected = true;
                                        positionID = index;
                                      });
                                    }),
                              );
                            },
                          ),
                        ]),
                      )
                    : showAddMore(context, snapshot.data[0]);
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  SizedBox(height: 20),
                  Text('No Data Found..')
                ],
              ),
            );
          }
        } else if (snapshot.hasError) {
          return AlertDialog(
            title: const Text(
              'An Error Occurred!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
              ),
            ),
            content: Text(
              "${snapshot.error}",
              style: const TextStyle(
                color: Colors.blueAccent,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('This may take some time..')
            ],
          ),
        );
      },
    );
  }

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _discountPercentController =
      TextEditingController();
  final _resetKey = GlobalKey<FormState>();
  String expDate = '2000-01-01';
  int _dropDownUnit = 0, fUnitId = 0, uniqueCode = 0, barcode = 0;
  bool rateEdited = false, isTax = false;

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
      rateOff = 0,
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
      pRate = 0,
      rPRate = 0;

  showAddMore(BuildContext context, StockProduct product) {
    pRate = product.buyingPrice;
    rPRate = product.buyingPriceReal;
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
    if (saleRate > 0 && !rateEdited && _rateController.text.isEmpty) {
      _rateController.text = _conversion > 0
          ? (saleRate * _conversion).toStringAsFixed(decimal)
          : saleRate.toStringAsFixed(decimal);
      rate = _conversion > 0 ? saleRate * _conversion : saleRate;
    }
    uniqueCode = product.productId;
    List<UnitModel> unitList = [];

    calculate() {
      if (enableMULTIUNIT) {
        if (saleRate > 0) {
          if (_conversion > 0) {
            //var r = 0.0;
            if (rateEdited) {
              rate = double.tryParse(_rateController.text);
              // rate = double.tryParse(_rateController.text) * _conversion;
            } else {
              //r = (saleRate * _conversion);
              rate = saleRate * _conversion;
              _rateController.text = rate.toStringAsFixed(decimal);
            }
            //rate = r;
            // _rateController.text = r.toStringAsFixed(decimal);
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
        if (rateEdited) {
          rate = double.tryParse(_rateController.text);
        } else if (saleRate > 0) {
          _rateController.text = saleRate.toStringAsFixed(decimal);
          rate = saleRate;
        } else {
          rate = _rateController.text.isNotEmpty
              ? double.tryParse(_rateController.text)
              : 0;
        }
      }
      quantity = _quantityController.text.isNotEmpty
          ? double.tryParse(_quantityController.text)
          : 0;
      rRate = taxMethod == 'MINUS'
          ? cessOnNetAmount
              ? CommonService.getRound(
                  4, (100 * rate) / (100 + taxP + kfcP + cessPer))
              : CommonService.getRound(4, (100 * rate) / (100 + taxP + kfcP))
          : rate;
      discount = _discountController.text.isNotEmpty
          ? double.tryParse(_discountController.text)
          : 0;
      double discP = _discountPercentController.text.isNotEmpty
          ? double.tryParse(_discountPercentController.text)
          : 0;
      double qt = _quantityController.text.isNotEmpty
          ? double.tryParse(_quantityController.text)
          : 0;
      double sRate = _rateController.text.isNotEmpty
          ? double.tryParse(_rateController.text)
          : 0;
      _discountController.text = _discountPercentController.text.isNotEmpty
          ? (((qt * sRate) * discP) / 100).toStringAsFixed(decimal)
          : '';
      discountPercent = _discountPercentController.text.isNotEmpty
          ? double.tryParse(_discountPercentController.text)
          : 0;
      discount = discountPercent > 0
          ? double.tryParse(_discountController.text)
          : discount;
      rDisc = taxMethod == 'MINUS'
          ? CommonService.getRound(4, ((discount * 100) / (taxP + 100)))
          : discount;
      gross = CommonService.getRound(decimal, ((rRate * quantity)));
      subTotal = CommonService.getRound(decimal, (gross - rDisc));
      if (taxP > 0) {
        tax = CommonService.getRound(decimal, ((subTotal * taxP) / 100));
      }
      if (companyTaxMode == 'INDIA') {
        kfc = isKFC
            ? CommonService.getRound(decimal, ((subTotal * kfcP) / 100))
            : 0;
        double csPer = taxP / 2;
        iGST = 0;
        csGST = CommonService.getRound(decimal, ((subTotal * csPer) / 100));
      } else if (companyTaxMode == 'GULF') {
        iGST = CommonService.getRound(decimal, ((subTotal * taxP) / 100));
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
          cess = CommonService.getRound(decimal, ((subTotal * cessPer) / 100));
          adCess = CommonService.getRound(decimal, (quantity * adCessPer));
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
                2, (total - (product.buyingPrice * _conversion * quantity)))
            : CommonService.getRound(decimal,
                (total - (product.buyingPriceReal * _conversion * quantity)));
      } else {
        profitPer = pRateBasedProfitInSales
            ? CommonService.getRound(
                2, (total - (product.buyingPrice * quantity)))
            : CommonService.getRound(
                2, (total - (product.buyingPriceReal * quantity)));
      }
      unitValue = _conversion > 0 ? _conversion : 1;
    }

    return Container();
    // return Container(
    //   padding: const EdgeInsets.all(8.0),
    //   child: ListView(
    //     children: [
    //       Text(product.name),
    //       SingleChildScrollView(
    //         child: Form(
    //           key: _resetKey,
    //           autovalidateMode: AutovalidateMode.always,
    //           child: Column(
    //             mainAxisSize: MainAxisSize.min,
    //             children: [
    //               Row(
    //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //                   children: [
    //                     MaterialButton(
    //                       onPressed: () {
    //                         setState(() {
    //                           // nextWidget = 2;
    //                           // clearValue();
    //                         });
    //                       },
    //                       child: const Text("BACK"),
    //                       color: blue[400],
    //                     ),
    //                     const SizedBox(
    //                       width: 2,
    //                     ),
    //                     MaterialButton(
    //                       onPressed: () {
    //                         setState(() {
    //                           // nextWidget = 4;
    //                           // clearValue();
    //                         });
    //                       },
    //                       child: const Text("CANCEL"),
    //                       color: blue[400],
    //                     ),
    //                     const SizedBox(
    //                       width: 2,
    //                     ),
    //                     MaterialButton(
    //                       child: const Text("ADD"),
    //                       color: blue,
    //                       onPressed: () {
    //                         setState(() {
    //                           if (outOfStock) {
    //                             ScaffoldMessenger.of(context)
    //                                 .showSnackBar(SnackBar(
    //                               content:
    //                                   const Text('Sorry stock not available.'),
    //                               duration: const Duration(seconds: 3),
    //                               action: SnackBarAction(
    //                                 label: 'Click',
    //                                 onPressed: () {
    //                                   // print('Action is clicked');
    //                                 },
    //                                 textColor: Colors.white,
    //                                 disabledTextColor: Colors.grey,
    //                               ),
    //                               backgroundColor: Colors.red,
    //                             ));
    //                           } else {
    //                             if (isMinimumRatedLock) {
    //                               ScaffoldMessenger.of(context)
    //                                   .showSnackBar(SnackBar(
    //                                 content:
    //                                     const Text('Sorry rate is limited.'),
    //                                 duration: const Duration(seconds: 1),
    //                                 action: SnackBarAction(
    //                                   label: 'Click',
    //                                   onPressed: () {
    //                                     // print('Action is clicked');
    //                                   },
    //                                   textColor: Colors.white,
    //                                   disabledTextColor: Colors.grey,
    //                                 ),
    //                                 backgroundColor: Colors.red,
    //                               ));
    //                             } else {
    //                               // if (_autoVariantSelect) {
    //                               //   double qty = 0;
    //                               //   for (StockProduct product
    //                               //       in _autoStockVariant) {
    //                               //     if (qty == quantity) {
    //                               //       break;
    //                               //     }
    //                               //     qty += product.quantity;
    //                               //     addProduct(CartItem(
    //                               //         id: totalItem + 1,
    //                               //         itemId: product.itemId,
    //                               //         itemName: product.name,
    //                               //         quantity: product.quantity,
    //                               //         rate: rate,
    //                               //         rRate: rRate,
    //                               //         uniqueCode: product.productId,
    //                               //         gross: gross,
    //                               //         discount: discount,
    //                               //         discountPercent: discountPercent,
    //                               //         rDiscount: rDisc,
    //                               //         fCess: kfc,
    //                               //         serialNo: '',
    //                               //         tax: tax,
    //                               //         taxP: taxP,
    //                               //         unitId: _dropDownUnit,
    //                               //         unitValue: unitValue,
    //                               //         pRate: pRate,
    //                               //         rPRate: rPRate,
    //                               //         barcode: barcode,
    //                               //         expDate: expDate,
    //                               //         free: free,
    //                               //         fUnitId: fUnitId,
    //                               //         cdPer: cdPer,
    //                               //         cDisc: cDisc,
    //                               //         net: subTotal,
    //                               //         cess: cess,
    //                               //         total: total,
    //                               //         profitPer: profitPer,
    //                               //         fUnitValue: fUnitValue,
    //                               //         adCess: adCess,
    //                               //         iGST: iGST,
    //                               //         cGST: csGST,
    //                               //         sGST: csGST,
    //                               //         stock: product.quantity));
    //                               //   }
    //                               // } else {
    //                               addProduct(CartItem(
    //                                   id: totalItem + 1,
    //                                   itemId: product.itemId,
    //                                   itemName: product.name,
    //                                   quantity: quantity,
    //                                   rate: rate,
    //                                   rRate: rRate,
    //                                   uniqueCode: uniqueCode,
    //                                   gross: gross,
    //                                   discount: discount,
    //                                   discountPercent: discountPercent,
    //                                   rDiscount: rDisc,
    //                                   fCess: kfc,
    //                                   serialNo: '',
    //                                   tax: tax,
    //                                   taxP: taxP,
    //                                   unitId: _dropDownUnit,
    //                                   unitValue: unitValue,
    //                                   pRate: pRate,
    //                                   rPRate: rPRate,
    //                                   barcode: barcode,
    //                                   expDate: expDate,
    //                                   free: free,
    //                                   fUnitId: fUnitId,
    //                                   cdPer: cdPer,
    //                                   cDisc: cDisc,
    //                                   net: subTotal,
    //                                   cess: cess,
    //                                   total: total,
    //                                   profitPer: profitPer,
    //                                   fUnitValue: fUnitValue,
    //                                   adCess: adCess,
    //                                   iGST: iGST,
    //                                   cGST: csGST,
    //                                   sGST: csGST,
    //                                   stock: product.quantity,
    //                                   minimumRate: product.minimumRate));
    //                               // }
    //                             }
    //                           }
    //                           if (totalItem > 0) {
    //                             clearValue();
    //                             nextWidget = 4;
    //                           }
    //                         });
    //                       },
    //                     ),
    //                   ]),
    //               const Divider(),
    //               Row(
    //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                 children: [
    //                   Expanded(
    //                       child: Padding(
    //                     padding: const EdgeInsets.all(2.0),
    //                     child: TextFormField(
    //                       controller: _quantityController,
    //                       // autofocus: true,
    //                       validator: (value) {
    //                         if (outOfStock) {
    //                           return 'No Stock';
    //                         }
    //                         return null;
    //                       },
    //                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
    //                       decoration: const InputDecoration(border: OutlineInputBorder(),
    //                           labelText: 'Quantity', labelText: '0.0'),
    //                       onChanged: (value) {
    //                         if (value.isNotEmpty) {
    //                           bool cartQ = false;
    //                           setState(() {
    //                             if (totalItem > 0) {
    //                               double cartS = 0, cartQt = 0;
    //                               for (var element in cartItem) {
    //                                 if (element.itemId == product.itemId) {
    //                                   cartQt += element.quantity;
    //                                   cartS = element.stock;
    //                                 }
    //                               }
    //                               if (cartS > 0) {
    //                                 if (cartS <
    //                                     cartQt + double.tryParse(value)) {
    //                                   cartQ = true;
    //                                 }
    //                               }
    //                             }

    //                             outOfStock = negativeStock
    //                                 ? false
    //                                 : salesTypeData.stock
    //                                     ? double.tryParse(value) >
    //                                             product.quantity
    //                                         ? true
    //                                         : cartQ
    //                                             ? true
    //                                             : false
    //                                     : false;
    //                             calculate();
    //                           });
    //                         }
    //                       },
    //                     ),
    //                   )),
    //                   Visibility(
    //                     visible: enableMULTIUNIT,
    //                     child: Expanded(
    //                       child: Padding(
    //                         padding: const EdgeInsets.all(2.0),
    //                         child: FutureBuilder(
    //                           future: dio.fetchUnitOf(product.itemId),
    //                           builder: (BuildContext context,
    //                               AsyncSnapshot snapshot) {
    //                             if (snapshot.hasData) {
    //                               unitList.clear();
    //                               for (var i = 0;
    //                                   i < snapshot.data.length;
    //                                   i++) {
    //                                 if (defaultUnitID.toString().isNotEmpty) {
    //                                   if (snapshot.data[i].id ==
    //                                       defaultUnitID - 1) {
    //                                     _dropDownUnit = snapshot.data[i].id;
    //                                     _conversion =
    //                                         snapshot.data[i].conversion;
    //                                   }
    //                                 }
    //                                 unitList.add(UnitModel(
    //                                     id: snapshot.data[i].id,
    //                                     itemId: snapshot.data[i].itemId,
    //                                     conversion: snapshot.data[i].conversion,
    //                                     name: snapshot.data[i].name,
    //                                     pUnit: snapshot.data[i].pUnit,
    //                                     sUnit: snapshot.data[i].sUnit,
    //                                     unit: snapshot.data[i].unit));
    //                               }
    //                             }
    //                             return snapshot.hasData
    //                                 ? DropdownButton<String>(
    //                                     hint: Text(_dropDownUnit > 0
    //                                         ? UnitSettings.getUnitName(
    //                                             _dropDownUnit)
    //                                         : 'SKU'),
    //                                     items: snapshot.data
    //                                         .map<DropdownMenuItem<String>>(
    //                                             (item) {
    //                                       return DropdownMenuItem<String>(
    //                                         value: item.id.toString(),
    //                                         child: Text(item.name),
    //                                       );
    //                                     }).toList(),
    //                                     onChanged: (value) {
    //                                       setState(() {
    //                                         _dropDownUnit = int.tryParse(value);
    //                                         for (var i = 0;
    //                                             i < unitList.length;
    //                                             i++) {
    //                                           UnitModel _unit = unitList[i];
    //                                           if (_unit.unit ==
    //                                               int.tryParse(value)) {
    //                                             _conversion = _unit.conversion;
    //                                             break;
    //                                           }
    //                                         }
    //                                         calculate();
    //                                       });
    //                                     },
    //                                   )
    //                                 : Container();
    //                           },
    //                         ),
    //                       ),
    //                     ),
    //                   ),
    //                   Visibility(
    //                     visible: enableMULTIUNIT
    //                         ? _conversion > 0
    //                             ? true
    //                             : false
    //                         : false,
    //                     child: Expanded(
    //                         child: Padding(
    //                       padding: const EdgeInsets.all(2.0),
    //                       child: Text('$_conversion'),
    //                     )),
    //                   ),
    //                 ],
    //               ),
    //               Row(
    //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                   children: [
    //                     Expanded(
    //                         child: Padding(
    //                       padding: const EdgeInsets.all(2.0),
    //                       child: TextField(
    //                         controller: _rateController,
    //                         readOnly: isItemRateEditLocked,
    //                         // autofocus: true,
    //                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
    //                         decoration: const InputDecoration(border: OutlineInputBorder(),
    //                             labelText: 'Price', labelText: '0.0'),
    //                         onChanged: (value) {
    //                           if (value.isNotEmpty) {
    //                             if (isMinimumRate) {
    //                               double minRate = product.minimumRate ?? 0;
    //                               if (double.tryParse(_rateController.text) >=
    //                                   minRate) {
    //                                 setState(() {
    //                                   rateEdited = true;
    //                                   isMinimumRatedLock = false;
    //                                   calculate();
    //                                 });
    //                               } else {
    //                                 setState(() {
    //                                   isMinimumRatedLock = true;
    //                                 });
    //                               }
    //                             } else {
    //                               setState(() {
    //                                 rateEdited = true;
    //                                 calculate();
    //                               });
    //                             }
    //                           }
    //                         },
    //                       ),
    //                     )),
    //                     TextButton.icon(
    //                         onPressed: () {
    //                           List<ProductRating> rateData = [
    //                             ProductRating(
    //                                 id: 0,
    //                                 name: 'MRP',
    //                                 rate: product.sellingPrice),
    //                             ProductRating(
    //                                 id: 1,
    //                                 name: 'Retail',
    //                                 rate: product.retailPrice),
    //                             ProductRating(
    //                                 id: 2,
    //                                 name: 'WsRate',
    //                                 rate: product.wholeSalePrice)
    //                           ];
    //                           showDialog(
    //                               context: context,
    //                               builder: (BuildContext context) {
    //                                 return AlertDialog(
    //                                   scrollable: true,
    //                                   title: ComSettings.appSettings('bool',
    //                                           'key-items-prate-sale', false)
    //                                       ? Column(
    //                                           children: [
    //                                             const Text('Select Rate'),
    //                                             Text(
    //                                               'PRate : ${product.buyingPrice} / RPRate : ${product.buyingPriceReal}',
    //                                               style: const TextStyle(
    //                                                   fontSize: 10),
    //                                             ),
    //                                           ],
    //                                         )
    //                                       : const Text('Select Rate'),
    //                                   content: SizedBox(
    //                                     height: 200.0,
    //                                     width: 400.0,
    //                                     child: ListView.builder(
    //                                       shrinkWrap: true,
    //                                       itemCount: rateData.length,
    //                                       itemBuilder: (BuildContext context,
    //                                           int index) {
    //                                         return Card(
    //                                           elevation: 5,
    //                                           child: ListTile(
    //                                               title: Text(rateData[index]
    //                                                       .name +
    //                                                   ' : ${rateData[index].rate}'),
    //                                               // subtitle: Text(
    //                                               //     'Quantity : ${rateData[index].quantity} Rate ${rateData[index].sellingPrice}'),
    //                                               onTap: () {
    //                                                 Navigator.of(context).pop();
    //                                                 setState(() {
    //                                                   rate =
    //                                                       rateData[index].rate;
    //                                                   saleRate =
    //                                                       rateData[index].rate;
    //                                                   _rateController.text =
    //                                                       saleRate
    //                                                           .toStringAsFixed(
    //                                                               2);
    //                                                   calculate();
    //                                                 });
    //                                               }),
    //                                         );
    //                                       },
    //                                     ),
    //                                   ),
    //                                 );
    //                               });
    //                         },
    //                         icon: const Icon(
    //                             Icons.arrow_drop_down_circle_outlined),
    //                         label: const Text('')),
    //                     Visibility(
    //                       visible: false, //taxMethod == 'MINUS',
    //                       child: Text(
    //                         '$rRate',
    //                         style: const TextStyle(color: Colors.red),
    //                       ),
    //                     )
    //                   ]),
    //               Visibility(
    //                 visible: !isItemDiscountEditLocked,
    //                 child: Row(
    //                   children: [
    //                     Expanded(
    //                         child: Padding(
    //                       padding: const EdgeInsets.all(2.0),
    //                       child: TextField(
    //                         controller: _discountPercentController,
    //                         // autofocus: true,
    //                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
    //                         decoration: const InputDecoration(border: OutlineInputBorder(),
    //                             labelText: ' % ', hintText: '0.0'),
    //                         onChanged: (value) {
    //                           setState(() {
    //                             calculate();
    //                           });
    //                         },
    //                       ),
    //                     )),
    //                     Expanded(
    //                         child: Padding(
    //                       padding: const EdgeInsets.all(2.0),
    //                       child: TextField(
    //                         controller: _discountController,
    //                         // autofocus: true,
    //                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
    //                         decoration: const InputDecoration(border: OutlineInputBorder(),
    //                             labelText: 'Discount', labelText: '0.0'),
    //                         onChanged: (value) {
    //                           setState(() {
    //                             calculate();
    //                           });
    //                         },
    //                       ),
    //                     )),
    //                     Visibility(
    //                       visible: isTax,
    //                       child: Expanded(
    //                           child: Padding(
    //                               padding: const EdgeInsets.all(2.0),
    //                               child: Text('Tax % : $taxP'))),
    //                     )
    //                   ],
    //                 ),
    //               ),
    //               Row(mainAxisAlignment: MainAxisAlignment.end, children: [
    //                 const Padding(
    //                   padding: EdgeInsets.all(2.0),
    //                   child: Text('SubTotal : '),
    //                 ),
    //                 Padding(
    //                   padding: const EdgeInsets.all(2.0),
    //                   child: Text(subTotal.toStringAsFixed(decimal)),
    //                 ),
    //               ]),
    //               Visibility(
    //                 visible: isTax,
    //                 child: Row(
    //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                     children: [
    //                       const Padding(
    //                         padding: EdgeInsets.all(2.0),
    //                         child: Text('Tax : '),
    //                       ),
    //                       Padding(
    //                         padding: const EdgeInsets.all(2.0),
    //                         child: Text(tax.toStringAsFixed(decimal)),
    //                       ),
    //                     ]),
    //               ),
    //               const Divider(),
    //               Row(mainAxisAlignment: MainAxisAlignment.end, children: [
    //                 const Padding(
    //                   padding: EdgeInsets.all(2.0),
    //                   child: Text(
    //                     'Total : ',
    //                     style: TextStyle(fontSize: 20),
    //                   ),
    //                 ),
    //                 Padding(
    //                   padding: const EdgeInsets.all(2.0),
    //                   child: Text(
    //                     total.toStringAsFixed(decimal),
    //                     style: const TextStyle(fontSize: 20),
    //                   ),
    //                 ),
    //               ]),
    //             ],
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }
}

StockItem productModel;
