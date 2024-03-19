// @dart = 2.11
class StockProduct {
  final String name;
  final int productId, itemId;
  final double quantity;
  final double buyingPrice;
  final double buyingPriceReal;
  final double sellingPrice;
  final double retailPrice;
  final double wholeSalePrice;
  final String hsnCode;
  final String stockValuation;
  final double tax;
  final double cess;
  final double cessPer;
  final double adCessPer;
  final double spRetailPrice;
  final double branch;
  final double minimumRate;
  final String serialNo;
  final String oBarcode;
  final int supplierId;
  final int locationId;
  final int categoryId;
  final int unitId;
  final int mfrId;
  final int subcategoryId;
  final int rackId;
  final double free;
  final String taxType;
  final int estUniqueCode;
  final String expDate;
  final String locked;
  final int brand;
  final int company;
  final double size;
  final int color;

  const StockProduct({
    this.name,
    this.itemId,
    this.buyingPrice,
    this.sellingPrice,
    this.buyingPriceReal,
    this.retailPrice,
    this.wholeSalePrice,
    this.quantity,
    this.productId,
    this.hsnCode,
    this.stockValuation,
    this.tax,
    this.cess,
    this.cessPer,
    this.adCessPer,
    this.spRetailPrice,
    this.branch,
    this.minimumRate,
    this.serialNo,
    this.oBarcode,
    this.supplierId,
    this.locationId,
    this.categoryId,
    this.unitId,
    this.mfrId,
    this.subcategoryId,
    this.rackId,
    this.free,
    this.taxType,
    this.estUniqueCode,
    this.expDate,
    this.locked,
    this.brand,
    this.company,
    this.size,
    this.color,
  });

  factory StockProduct.fromJson(Map<String, dynamic> json) {
    return StockProduct(
      name: json['itemname'],
      itemId: json['ItemId'],
      productId: json['uniquecode'],
      quantity: double.tryParse(json['Qty'].toString()),
      buyingPrice: double.tryParse(json['prate'].toString()),
      buyingPriceReal: double.tryParse(json['RealPrate'].toString()),
      sellingPrice: double.tryParse(json['mrp'].toString()),
      retailPrice: double.tryParse(json['retail'].toString()),
      wholeSalePrice: double.tryParse(json['WSrate'].toString()),
      hsnCode: json['hsncode'],
      stockValuation: json['stockvaluation'],
      tax: double.tryParse(json['tax'].toString()),
      cess: double.tryParse(json['cess'].toString()),
      cessPer: double.tryParse(json['cessper'].toString()),
      adCessPer: double.tryParse(json['adcessper'].toString()),
      spRetailPrice: double.tryParse(json['Spretail'].toString()),
      branch: double.tryParse(json['Branch'].toString()),
      minimumRate: double.tryParse(json['minimumRate'].toString()),
      serialNo: json['serialno'] ?? '',
      oBarcode: json['obarcode'] ?? '',
      supplierId: json['supplier'] ?? 0,
      locationId: json['location'] ?? 0,
      categoryId: json['Catagory_id'] ?? 0,
      unitId: json['unit_id'] ?? 0,
      mfrId: json['Mfr_id'] ?? 0,
      subcategoryId: json['subcatagory_id'] ?? 0,
      rackId: json['rack_id'] ?? 0,
      free: double.tryParse(
        json['Free'].toString(),
      ),
      taxType: json['TaxType'].toString(),
      estUniqueCode: json['EstUniQueCode'] ?? 0,
      expDate: json['expdate'] ?? '2023-08-01T00:00:00.000Z',
      locked: json['Locked'] ?? 'N',
      brand: json['Brand'] ?? 0,
      company: json['company'] ?? 0,
      size: double.tryParse(json['Size'].toString()),
      color: json['color'] ?? 0,
    );
  }

  static StockProduct empty() {
    return const StockProduct(
        adCessPer: 0,
        branch: 0,
        brand: 0,
        buyingPrice: 0,
        buyingPriceReal: 0,
        categoryId: 0,
        cess: 0,
        cessPer: 0,
        color: 0,
        company: 0,
        estUniqueCode: 0,
        expDate: '',
        free: 0,
        hsnCode: '',
        itemId: 0,
        locationId: 0,
        locked: '',
        mfrId: 0,
        minimumRate: 0,
        name: '',
        oBarcode: '',
        productId: 0,
        quantity: 0,
        rackId: 0,
        retailPrice: 0,
        sellingPrice: 0,
        serialNo: '',
        size: 0,
        spRetailPrice: 0,
        stockValuation: '',
        subcategoryId: 0,
        supplierId: 0,
        tax: 0,
        taxType: '',
        unitId: 0,
        wholeSalePrice: 0);
  }
}
