import 'package:flutter/material.dart';
import 'package:sheraccerp/screens/inventory/cart_product.dart';

class Cart extends StatefulWidget {
  const Cart({Key? key}) : super(key: key);

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          'Your Cart',
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: const SingleCartProduct(),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Row(
          children: <Widget>[
            const Expanded(
                child: ListTile(
              title: Text("Total"),
              subtitle: Text("₹230"),
            )),
            Expanded(
                child: MaterialButton(
              onPressed: () {},
              child: const Text("Check Out",
                  style: TextStyle(color: Colors.white)),
              color: Colors.orange,
            )),
          ],
        ),
      ),
    );
  }
}
