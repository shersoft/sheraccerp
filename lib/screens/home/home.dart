// @dart = 2.11

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String firm = "", firmCode = "";
  load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      firm = (prefs.getString('CompanyName') ?? "");
      firmCode = (prefs.getString('CustomerCode') ?? "");
    });
  }

  final TextEditingController _searchTextController = TextEditingController();
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
              hintText: "  Search...",
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
          IconButton(
            icon: const Icon(Icons.shopping_basket, color: Colors.black),
            onPressed: () {
              // Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //         builder: (context) => new SingleCartProduct()));
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
//            header
            UserAccountsDrawerHeader(
              accountName: const Text('User'),
              accountEmail: const Text('user@gmail.com'),
              currentAccountPicture: GestureDetector(
                child: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
              ),
              decoration: const BoxDecoration(color: Colors.orange),
            ),

            InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', ModalRoute.withName('/home'),
                    arguments: (null));
              },
              child: const ListTile(
                title: Text('Home Page'),
                leading: Icon(Icons.home),
              ),
            ),

            InkWell(
              onTap: () {},
              child: const ListTile(
                title: Text('My account'),
                leading: Icon(Icons.person),
              ),
            ),

            InkWell(
              onTap: () {
                // Navigator.pushReplacement(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => new SingleCartProduct()));
              },
              child: const ListTile(
                title: Text('My Orders'),
                leading: Icon(Icons.shopping_basket),
              ),
            ),
            InkWell(
              onTap: () {
                // Navigator.pushReplacement(context,
                //     MaterialPageRoute(builder: (context) => new ProductList()));
              },
              child: const ListTile(
                title: Text('Products'),
                leading: Icon(Icons.dashboard),
              ),
            ),
            InkWell(
              onTap: () {
                // Navigator.pushReplacement(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => new ProductCategories()));
              },
              child: const ListTile(
                title: Text('Categories'),
                leading: Icon(Icons.category),
              ),
            ),

            InkWell(
              onTap: () {},
              child: const ListTile(
                title: Text('Favourites'),
                leading: Icon(Icons.favorite),
              ),
            ),

            const Divider(),

            InkWell(
              onTap: () {
                //user.signOut();
              },
              child: const ListTile(
                title: Text('Log out'),
                leading: Icon(
                  Icons.transit_enterexit,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          //image carousel begins
          // image_carousel,

          const Divider(),
          //Padding Widget
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: Container(
              alignment: Alignment.centerLeft,
              child: const Text('  Category'),
            ),
          ),

          // HorizontalList(),
          const Divider(),

          Container(
            height: 20.0,
            child: const Text(
              '  Recent Products',
            ),
            alignment: Alignment.centerLeft,
          ),

          // Flexible(
          //   child: ProductsGridView(),
          // )
        ],
      ),
    );
  }
}
