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

  const StockProduct(
      {this.name,
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
      this.minimumRate});

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
        minimumRate: double.tryParse(json['minimumRate'].toString()));
  }
}
