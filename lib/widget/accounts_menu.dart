import 'package:flutter/material.dart';
import 'package:sheraccerp/util/res_color.dart';

class AccountsMenu extends StatelessWidget {
  const AccountsMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: MediaQuery.of(context).size.width > 400
          ? (MediaQuery.of(context).size.width ~/ 250).toInt()
          : (MediaQuery.of(context).size.width ~/ 150).toInt(),
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
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  Icon(
                    Icons.group_add,
                    color: Colors.red[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Ledger',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/ledger', arguments: {'parent': ''});
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  Icon(
                    Icons.group_add_rounded,
                    color: kPrimaryColor[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Group',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            // _showDialog(context);
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  Icon(
                    Icons.join_full_rounded,
                    color: Colors.brown[200],
                    size: 90.0,
                  ),
                  const Text(
                    'Journal',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/journal');
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  Icon(
                    Icons.join_full_rounded,
                    color: Colors.cyan[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Contra',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            // _showDialog(context);
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  Icon(
                    Icons.payment_rounded,
                    color: Colors.red[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Bank Payment',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/BankVoucher',
                arguments: {'voucher': 'Payment'});
          },
        ),
        GestureDetector(
          child: Card(
            elevation: 5.0,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_rounded,
                    color: Colors.green[500],
                    size: 90.0,
                  ),
                  const Text(
                    'Bank Receipt',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/BankVoucher',
                arguments: {'voucher': 'Receipt'});
          },
        ),
      ],
    );
  }
}
