// @dart = 2.9
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sheraccerp/screens/inventory/cart_product.dart';
import 'package:sheraccerp/screens/home/home.dart';
import 'package:sheraccerp/service/cartproduct.dart';

class ProductViewDetail extends StatefulWidget {
  final product_detail_name;
  final product_detail_price;
  final product_detail_picture;
  final product_detail_quantity;

  const ProductViewDetail({
    this.product_detail_name,
    this.product_detail_price,
    this.product_detail_picture,
    this.product_detail_quantity,
  });
  @override
  _ProductViewDetailState createState() => _ProductViewDetailState();
}

class _ProductViewDetailState extends State<ProductViewDetail> {
  // final TextEditingController _productNameController = TextEditingController();
  // final TextEditingController _productPriceController = TextEditingController();
  final CartService _cartService = CartService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String _currentItemSelected = '1';
  String quant = '0';
  final _numbers = ['0'];
  @override
  void initState() {
    _getQuantity();
    super.initState();
  }

  void quantityD() {
    _numbers.removeLast();
    for (int i = 1; i <= int.parse(quant); i++) {
      _numbers.add(i.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: InkWell(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Home()));
              },
              child: const Text('Place Order')),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.shopping_basket, color: Colors.black),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SingleCartProduct()));
              },
            )
          ],
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Builder(
              builder: (context) => Form(
                    key: _formKey,
                    child: ListView(
                      children: <Widget>[
                        SizedBox(
                          height: 300.0,
                          child: GridTile(
                            child: Container(
                              color: Colors.white,
                              child:
                                  Image.network(widget.product_detail_picture),
                            ),
                            footer: Container(
                                color: Colors.white70,
                                child: ListTile(
                                  leading: Text(
                                    widget.product_detail_name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0),
                                  ),
                                  title: Row(
                                    children: <Widget>[
                                      Expanded(
                                          child: Text(
                                        "₹${widget.product_detail_price}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                      ))
                                    ],
                                  ),
                                )),
                          ),
                        ),

                        // +===============================================
//                    FIRST BUTTON QUANTITY BUTTON
                        //+================================================
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: MaterialButton(
                                onPressed: () {},
                                color: Colors.grey[200],
                                textColor: Colors.black,
                                child: Row(
                                  children: <Widget>[
                                    const Text("Quantity     "),
                                    Wrap(
                                      children: <Widget>[
                                        DropdownButton<String>(
                                          items: _numbers
                                              .map((String dropDownStringItem) {
                                            return DropdownMenuItem<String>(
                                              value: dropDownStringItem,
                                              child: Text(dropDownStringItem),
                                            );
                                          }).toList(),
                                          onChanged: (String newValueSelected) {
                                            _dropDownItemSelected(
                                                newValueSelected);
                                          },
                                          value: _currentItemSelected,
                                        ),
                                      ],
                                    ),

                                    // +===============================================
//                    ADD TO CART BUTTON
                                    //+================================================
                                    Expanded(
                                      child: MaterialButton(
                                        onPressed: () {
                                          validateAndUpload();
                                        },
                                        color: Colors.red,
                                        textColor: Colors.white,
                                        child: Row(
                                          children: <Widget>[
                                            const Text(
                                              "Add To Cart",
                                              textAlign: TextAlign.center,
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.add_shopping_cart),
                                              alignment: Alignment.centerRight,
                                              color: Colors.white,
                                              onPressed: () {},
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),

                        const Divider(),
                        const Text(' Similar Products'),
                        const SizedBox(
                          height: 300.0,
                          child: SimilarProducts(),
                        ),
                      ],
                    ),
                  )),
        ));
  }

  _getQuantity() async {
    setState(() {
      quant = widget.product_detail_quantity.toString();
      quantityD();
      _currentItemSelected = '1';
    });
  }

  void _dropDownItemSelected(String newValueSelected) {
    setState(() {
      _currentItemSelected = newValueSelected;
    });
  }

  void validateAndUpload() async {
    if (_formKey.currentState.validate()) {
      setState(() => isLoading = true);

      _cartService.uploadProduct(
          productName: widget.product_detail_name,
          price: widget.product_detail_price,
          quantity: int.parse(_currentItemSelected),
          image: widget.product_detail_picture);
      _formKey.currentState.reset();

      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: 'Product added to the Cart');
      Navigator.pop(context);
    }
  }
}

class SimilarProducts extends StatefulWidget {
  const SimilarProducts({Key key}) : super(key: key);

  @override
  _SimilarProductsState createState() => _SimilarProductsState();
}

class _SimilarProductsState extends State<SimilarProducts> {
  var product_list = [
    {
      "name": "Amul Butter",
      "picture": "assets/icons/no_image.png",
      "price": "30",
    },
    {
      "name": "Shampoo",
      "picture": "assets/icons/no_image.png",
      "price": "200",
    },
    {
      "name": "Corn Flakes",
      "picture": "assets/icons/no_image.png",
      "price": "150",
    },
    {
      "name": "Hide n Seek",
      "picture": "assets/icons/no_image.png",
      "price": "30",
    },
  ];
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: product_list.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemBuilder: (BuildContext context, int index) {
        return Similar_Single_prod(
          product_name: product_list[index]['name'],
          product_pictures: product_list[index]['picture'],
          product_price: product_list[index]['price'],
        );
      },
    );
  }
}

class Similar_Single_prod extends StatelessWidget {
  final product_name;
  final product_pictures;
  final product_price;

  const Similar_Single_prod({
    this.product_name,
    this.product_pictures,
    this.product_price,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Hero(
        tag: product_name,
        child: Material(
            child: InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ProductViewDetail(
                          //passing the values of product grid view to product view details
                          product_detail_name: product_name,
                          product_detail_price: product_price,
                          product_detail_picture: product_pictures,
                        ))),
                child: GridTile(
                  footer: Container(
                      color: Colors.white,
                      child: ListTile(
                        title: Text(product_name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          "₹$product_price",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )),
                  // footer: Container(

                  //   color: Colors.white70,
                  //   child: ListTile(

                  //     leading: Text(product_name, style:TextStyle(fontWeight: FontWeight.bold,)),
                  //     title: Text("\₹$product_price", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800,),
                  //     ),
                  //     )
                  // ),
                  child: Image.asset(
                    product_pictures,
                    fit: BoxFit.cover,
                  ),
                ))),
      ),
    );
  }
}
