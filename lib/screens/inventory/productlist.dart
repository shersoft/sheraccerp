// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:sheraccerp/screens/inventory/product_view_details.dart';

class ProductList extends StatefulWidget {
  const ProductList({Key key}) : super(key: key);

  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final TextEditingController _searchTextController = TextEditingController();
  bool showCart = false;

  Future _data;
  Future getCat() async {
    return null;
  }

  @override
  void initState() {
    super.initState();
    _data = getCat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Material(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.black.withOpacity(0.2),
            elevation: 0.0,
            child: TextFormField(
              controller: _searchTextController,
              decoration: const InputDecoration(
                label: Text("  Search..."),
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return "The search field cannot be empty";
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: _loadProduct());
  }

  _loadProduct() {
    return FutureBuilder(
        future: _data,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Text("Loading....."),
            );
          } else {
            return ListView.builder(
                itemCount: snapshot.data.length,
                shrinkWrap: true,
                itemBuilder: (_, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 10.0),
                    child: InkWell(
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ProductViewDetail(
                                      //passing the values of product grid view to product view details
                                      product_detail_name:
                                          snapshot.data[index].data['name'],
                                      product_detail_price:
                                          snapshot.data[index].data['price'],
                                      product_detail_picture:
                                          snapshot.data[index].data['picture'],
                                      product_detail_quantity:
                                          snapshot.data[index].data['quantity'],
                                    ))),
                        child: SizedBox(
                          height: 150.0,
                          child: GridTile(
                            child: Container(
                              color: Colors.white,
                              //child: Image.asset('assets/icons/no_image.png'),
                              child: Image.network(
                                  snapshot.data[index].data['picture']),
                            ),
                            footer: Container(
                                color: Colors.white,
                                child: ListTile(
                                  title: Text(snapshot.data[index].data['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  trailing: Text(
                                    snapshot.data[index].data['price']
                                        .toString(),
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )),
                          ),
                        )),
                  );
                });
          }
        });
  }
}
