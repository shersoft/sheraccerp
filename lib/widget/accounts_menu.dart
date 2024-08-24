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
            showPaymentOptionList(context);
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
            showReceiptOptionList(context);
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
            Navigator.pushNamed(context, '/groupRegistration',
                arguments: {'parent': ''});
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
      ],
    );
  }

  showReceiptOptionList(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Receipt Option'),
            children: [
              SimpleDialogOption(
                child: Card(
                    color: blue.shade50,
                    child: const ListTile(title: Text('Cash Receipt'))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/RPVoucher',
                      arguments: {'voucher': 'Receipt'});
                },
              ),
              SimpleDialogOption(
                child: Card(
                    color: blue.shade50,
                    child: const ListTile(title: Text('Bank Receipt'))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/BankVoucher',
                      arguments: {'voucher': 'Receipt'});
                },
              ),
              SimpleDialogOption(
                child: Card(
                    color: blue.shade50,
                    child: const ListTile(title: Text('Receipt Invoice'))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/InvRPVoucher',
                      arguments: {'voucher': 'Receipt Invoice'});
                },
              ),
              SimpleDialogOption(
                child: Card(
                    color: blue.shade50,
                    child: const ListTile(title: Text('Receipt Order'))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/RPVoucher',
                      arguments: {'voucher': 'Receipt Order'});
                },
              ),
            ],
          );
        });
  }

  showPaymentOptionList(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Payment Option'),
            children: [
              SimpleDialogOption(
                child: Card(
                    color: blue.shade50,
                    child: const ListTile(title: Text('Cash Payment'))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/RPVoucher',
                      arguments: {'voucher': 'Payment'});
                },
              ),
              SimpleDialogOption(
                child: Card(
                    color: blue.shade50,
                    child: const ListTile(title: Text('Bank Payment'))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/BankVoucher',
                      arguments: {'voucher': 'Payment'});
                },
              ),
              SimpleDialogOption(
                child: Card(
                    color: blue.shade50,
                    child: const ListTile(title: Text('Payment Invoice'))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/InvRPVoucher',
                      arguments: {'voucher': 'Payment Invoice'});
                },
              ),
              // SimpleDialogOption(
              //   child: Card(
              //       color: blue.shade50,
              //       child: const ListTile(title: Text('Payment Order'))),
              //   onPressed: () {
              //     Navigator.of(context).pop();
              //     Navigator.pushNamed(context, '/RPVoucher',
              //         arguments: {'voucher': 'Payment Order'});
              //   },
              // ),
            ],
          );
        });
  }
}
