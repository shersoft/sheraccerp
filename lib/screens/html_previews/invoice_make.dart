import 'package:flutter/material.dart';
import 'package:sheraccerp/screens/html_previews/pdf_api.dart';
import 'package:sheraccerp/screens/html_previews/pdf_invoice_api.dart';
import 'package:sheraccerp/widget/pdf_screen.dart';

class InvoiceMake extends StatefulWidget {
  const InvoiceMake({Key? key}) : super(key: key);

  @override
  State<InvoiceMake> createState() => _InvoiceMakeState();
}

class _InvoiceMakeState extends State<InvoiceMake> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const TitleWidget(
                icon: Icons.picture_as_pdf,
                text: 'Generate InvoiceX',
              ),
              const SizedBox(height: 48),
              ButtonWidget(
                text: 'InvoiceX PDF',
                onClicked: () async {
                  final date = DateTime.now();
                  final dueDate = date.add(const Duration(days: 7));

                  final invoice = InvoiceX(
                    supplier: const Supplier(
                      name: 'Sarah Field',
                      address: 'Sarah Street 9, Beijing, China',
                      paymentInfo: 'https://paypal.me/sarahfieldzz',
                    ),
                    customer: const Customer(
                      name: 'Apple Inc.',
                      address: 'Apple Street, Cupertino, CA 95014',
                    ),
                    info: InvoiceXInfo(
                      date: date,
                      dueDate: dueDate,
                      description: 'My description...',
                      number: '${DateTime.now().year}-9999',
                    ),
                    items: [
                      InvoiceXItem(
                        description: 'Coffee',
                        date: DateTime.now(),
                        quantity: 3,
                        vat: 0.19,
                        unitPrice: 5.99,
                      ),
                      InvoiceXItem(
                        description: 'Water',
                        date: DateTime.now(),
                        quantity: 8,
                        vat: 0.19,
                        unitPrice: 0.99,
                      ),
                      InvoiceXItem(
                        description: 'Orange',
                        date: DateTime.now(),
                        quantity: 3,
                        vat: 0.19,
                        unitPrice: 2.99,
                      ),
                      InvoiceXItem(
                        description: 'Apple',
                        date: DateTime.now(),
                        quantity: 8,
                        vat: 0.19,
                        unitPrice: 3.99,
                      ),
                      InvoiceXItem(
                        description: 'Mango',
                        date: DateTime.now(),
                        quantity: 1,
                        vat: 0.19,
                        unitPrice: 1.59,
                      ),
                      InvoiceXItem(
                        description: 'Blue Berries',
                        date: DateTime.now(),
                        quantity: 5,
                        vat: 0.19,
                        unitPrice: 0.99,
                      ),
                      InvoiceXItem(
                        description: 'Lemon',
                        date: DateTime.now(),
                        quantity: 4,
                        vat: 0.19,
                        unitPrice: 1.29,
                      ),
                    ],
                  );

                  final pdfFile = await PdfInvoiceApi.generate(invoice);

                  // PdfApi.openFile(pdfFile);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PDFScreen(
                            pathPDF: pdfFile.path,
                            subject: 'My Invoice',
                            text: 'this is my invoice',
                          )));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onClicked;

  const ButtonWidget({
    Key? key,
    required this.text,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(40),
        ),
        child: FittedBox(
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
        onPressed: onClicked,
      );
}

class TitleWidget extends StatelessWidget {
  final IconData icon;
  final String text;

  const TitleWidget({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 100, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
}

class InvoiceX {
  final InvoiceXInfo info;
  final Supplier supplier;
  final Customer customer;
  final List<InvoiceXItem> items;

  const InvoiceX({
    required this.info,
    required this.supplier,
    required this.customer,
    required this.items,
  });
}

class InvoiceXInfo {
  final String description;
  final String number;
  final DateTime date;
  final DateTime dueDate;

  const InvoiceXInfo({
    required this.description,
    required this.number,
    required this.date,
    required this.dueDate,
  });
}

class InvoiceXItem {
  final String description;
  final DateTime date;
  final int quantity;
  final double vat;
  final double unitPrice;

  const InvoiceXItem({
    required this.description,
    required this.date,
    required this.quantity,
    required this.vat,
    required this.unitPrice,
  });
}

class Customer {
  final String name;
  final String address;

  const Customer({
    required this.name,
    required this.address,
  });
}

class Supplier {
  final String name;
  final String address;
  final String paymentInfo;

  const Supplier({
    required this.name,
    required this.address,
    required this.paymentInfo,
  });
}
