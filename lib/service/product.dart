// @dart = 2.11
class ProductService {
  //  Firestore _firestore = Firestore.instance;
  String ref = 'products';

  void uploadProduct(
      {String productName,
      String category,
      int price,
      int quantity,
      String image}) {
    // var id = Uuid();
    // String productId = '00';
    //id.v1();

    // _firestore.collection(ref).document(productId).setData({
    //   'name': productName,
    //   'id': productId,
    //   'category': category,
    //   'quantity': quantity,
    //   'price': price,
    //   'picture': image
    // });
  }

  getproduct(String cate) {
    // return _firestore
    //     .collection('products')
    //     .where('category', isEqualTo: cate)
    //     .getDocuments();
    return 'cat';
  }
}
