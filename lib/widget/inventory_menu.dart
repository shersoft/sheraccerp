import 'package:flutter/material.dart';
import 'package:sheraccerp/screens/about_shersoft.dart';
import 'package:sheraccerp/screens/html_previews/invoice_make.dart';
import 'package:sheraccerp/screens/inventory/sales/sale.dart';
import 'package:sheraccerp/util/res_color.dart';

import '../shared/constants.dart';

class InventoryMenu extends StatelessWidget {
  const InventoryMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: MediaQuery.of(context).size.width > 500
          ? (MediaQuery.of(context).size.width ~/ 250).toInt()
          : (MediaQuery.of(context).size.width ~/ 150).toInt(),
      children: [
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.add_shopping_cart,
                    color: Colors.purple[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Product',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/product');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.store,
                    color: Colors.pink[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Opening Stock',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/openingStock');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.shopping_bag,
                    color: Colors.red[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Purchase',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/purchase');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.storefront_rounded,
                    color: kPrimaryColor[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Sales',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            ComSettings.appSettings('bool', 'key-simple-sales', false)
                ? Navigator.pushNamed(context, '/SimpleSale')
                : Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => Sale(
                          oldSale: false,
                          thisSale: false,
                        )));
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.shopping_bag,
                    color: Colors.orange[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Purchase Return',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/purchaseReturn');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.assignment_returned_outlined,
                    color: Colors.amber[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Sale Return',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/salesReturn');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.water_damage_outlined,
                    color: Colors.brown[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Damage',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/damageEntry');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.shopping_bag_sharp,
                    color: green[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Purchase Order',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/purchaseOrder');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(
                    Icons.swap_horiz_outlined,
                    color: Colors.red,
                    size: 90.0,
                  ),
                  Text(
                    'Stock Trasfer',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/stockTransfer');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(
                    Icons.add_shopping_cart,
                    color: blue,
                    size: 90.0,
                  ),
                  Text(
                    'Product Management',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/ProductManagement');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(
                    Icons.car_repair_rounded,
                    color: blueAccent,
                    size: 90.0,
                  ),
                  Text(
                    'Alignment Entry',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/AlignmentEntry');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(
                    Icons.miscellaneous_services_rounded,
                    color: green,
                    size: 90.0,
                  ),
                  Text(
                    'Service Entry',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/ServiceEntry');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(
                    Icons.add_task,
                    color: red,
                    size: 90.0,
                  ),
                  Text(
                    'Stock Management',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/StockManagement');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(
                    Icons.storefront_rounded,
                    color: indigoAccent,
                    size: 90.0,
                  ),
                  Text(
                    'DeliveryNote',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/DeliveryNote');
          },
        ),
      ],
    );
  }
}
