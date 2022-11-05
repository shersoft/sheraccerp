// @dart = 2.11

class CartService {
  // Firestore _firestore = Firestore.instance;
  // String ref = 'cart';
  List<Item> cartData;

  void addCart(Item data) {
    cartData.add(data);
  }

  void editCart(Item data) {
    cartData.insert(data.id, data);
  }

  void removeCart(Item data) {
    cartData.removeAt(data.id);
  }

  void uploadProduct({productName, price, int quantity, image}) {}
}

class Item {
  final int id;
  final String name;
  final int productId;
  final int quantity;
  final double buyingPrice;
  final double buyingPriceReal;
  final double sellingPrice;
  final double retailPrice;

  const Item({
    this.id,
    this.name,
    this.buyingPrice,
    this.sellingPrice,
    this.buyingPriceReal,
    this.retailPrice,
    this.quantity,
    this.productId,
  });
}
