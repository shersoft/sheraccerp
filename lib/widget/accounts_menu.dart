import 'package:flutter/material.dart';

class AccountsMenu extends StatelessWidget {
  const AccountsMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: <Widget>[
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Icon(
                    Icons.payment_rounded,
                    color: Colors.green[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Payment',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/RPVoucher',
                arguments: {'voucher': 'Payment'});
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Icon(
                    Icons.receipt_rounded,
                    color: Colors.blue[500],
                    size: 90.0,
                  ),
                  const Text('Receipt',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/RPVoucher',
                arguments: {'voucher': 'Receipt'});
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Icon(
                    Icons.payments_rounded,
                    color: Colors.green[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Payment Invoice',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/InvRPVoucher',
                arguments: {'voucher': 'Payment Invoice'});
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.blue[500],
                    size: 90.0,
                  ),
                  const Text('Receipt Invoice',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/InvRPVoucher',
                arguments: {'voucher': 'Receipt Invoice'});
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Icon(
                    Icons.people_rounded,
                    color: Colors.yellow[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Customer',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/ledger',
                arguments: {'parent': 'CUSTOMERS'});
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Icon(
                    Icons.contacts,
                    color: Colors.orange[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Supplier',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/ledger',
                arguments: {'parent': 'SUPPLIERS'});
          },
        ),
        // GestureDetector(
        //   child: Card(
        //     elevation: 5.0,
        //     child: Container(
        //       padding: const EdgeInsets.all(0),
        //       child: Column(
        //         children: <Widget>[
        //           new Icon(
        //             Icons.shopping_bag,
        //             color: Colors.red[500],
        //             size: 90.0,
        //           ),
        //           Text(
        //             'Purchase',
        //             style: TextStyle(
        //                 color: Colors.black, fontWeight: FontWeight.bold),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        //   onTap: () {
        //     _showDialog(context);
        //   },
        // ),
        // GestureDetector(
        //   child: Card(
        //     elevation: 5.0,
        //     child: Container(
        //       padding: const EdgeInsets.all(0),
        //       child: Column(
        //         children: <Widget>[
        //           new Icon(
        //             Icons.storefront_rounded,
        //             color: kPrimaryColor[500],
        //             size: 90.0,
        //           ),
        //           Text(
        //             'Sale',
        //             style: TextStyle(
        //                 color: Colors.black, fontWeight: FontWeight.bold),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        //   onTap: () {
        //     _showDialog(context);
        //   },
        // ),
        // GestureDetector(
        //   child: Card(
        //     elevation: 5.0,
        //     child: Container(
        //       padding: const EdgeInsets.all(0),
        //       child: Column(
        //         children: <Widget>[
        //           new Icon(
        //             Icons.add_shopping_cart,
        //             color: Colors.purple[500],
        //             size: 90.0,
        //           ),
        //           Text(
        //             'Product',
        //             style: TextStyle(
        //                 color: Colors.black, fontWeight: FontWeight.bold),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        //   onTap: () {
        //     _showDialog(context);
        //   },
        // ),
        // GestureDetector(
        //   child: Card(
        //     elevation: 5.0,
        //     child: Container(
        //       padding: const EdgeInsets.all(0),
        //       child: Column(
        //         children: <Widget>[
        //           new Icon(
        //             Icons.store,
        //             color: Colors.pink[500],
        //             size: 90.0,
        //           ),
        //           Text(
        //             'Stock',
        //             style: TextStyle(
        //                 color: Colors.black, fontWeight: FontWeight.bold),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        //   onTap: () {
        //     _showDialog(context);
        //   },
        // ),
      ],
    );
  }
}
