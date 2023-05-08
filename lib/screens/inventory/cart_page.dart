// @dart = 2.9
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/scoped-models/main.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CartPageState();
  }
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text("Cart"),
          actions: <Widget>[
            TextButton(
                child: const Text(
                  "Clear",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => ScopedModel.of<MainModel>(context).clearCart())
          ],
        ),
        body: ScopedModel.of<MainModel>(context, rebuildOnChange: true)
                .cart
                .isEmpty
            ? const Center(
                child: Text("No items in Cart"),
              )
            : Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      itemCount: ScopedModel.of<MainModel>(context,
                              rebuildOnChange: true)
                          .totalItem,
                      itemBuilder: (context, index) {
                        return ScopedModelDescendant<MainModel>(
                          builder: (context, child, model) {
                            return ListTile(
                              title: Text(model.cart[index].itemName),
                              subtitle: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: Card(
                                      color: Colors.green[200],
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.black,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          model.updateProduct(model.cart[index],
                                              model.cart[index].quantity + 1);
                                          // model.removeProduct(model.cart[index]);
                                        },
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    child: Card(
                                      child: Text(
                                          model.cart[index].quantity.toString(),
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    onTap: () {
                                      _displayTextInputDialog(
                                          context,
                                          'Edit Quantity',
                                          double.tryParse(model
                                                  .cart[index].quantity
                                                  .toString())
                                              .toString(),
                                          model.cart[index].id);
                                    },
                                  ),
                                  SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: Card(
                                      color: Colors.red[200],
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          color: Colors.black,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          model.updateProduct(model.cart[index],
                                              model.cart[index].quantity - 1);
                                          // model.removeProduct(model.cart[index]);
                                        },
                                      ),
                                    ),
                                  ),
                                  Text(
                                      model.cart[index].unitId > 0
                                          ? '(' +
                                              UnitSettings.getUnitName(
                                                  model.cart[index].unitId) +
                                              ')'
                                          : " x ",
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 12)),
                                  InkWell(
                                    child: Card(
                                      child: Text(
                                          model.cart[index].rate
                                              .toStringAsFixed(2),
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    onTap: () {
                                      _displayTextInputDialog(
                                          context,
                                          'Edit Rate',
                                          double.tryParse(model.cart[index].rate
                                                  .toString())
                                              .toString(),
                                          model.cart[index].id);
                                    },
                                  ),
                                  const Text(" = ",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      ((model.cart[index].quantity *
                                                  model.cart[index].rate) -
                                              (model.cart[index].discount))
                                          .toStringAsFixed(2),
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20)),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Total: " +
                            ScopedModel.of<MainModel>(context,
                                    rebuildOnChange: true)
                                .totalCartValue
                                .toStringAsFixed(2) +
                            "",
                        style: const TextStyle(
                            fontSize: 24.0, fontWeight: FontWeight.bold),
                      )),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            elevation: 0,
                            primary: Colors.blue[900],
                            onPrimary: Colors.white,
                            onSurface: Colors.grey),
                        child: const Text("Check Out"),
                        onPressed: () {
                          Navigator.pushNamed(context, '/check_out');
                        },
                      ))
                ])));
  }

  Future<void> _displayTextInputDialog(
      BuildContext context, String title, String text, int id) async {
    TextEditingController _controller = TextEditingController();
    String valueText;
    _controller.text = text;
    return showDialog(
      context: context,
      builder: (context) {
        return ScopedModelDescendant<MainModel>(
            builder: (context, child, model) {
          return (StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                onChanged: (value) {
                  setState(() {
                    valueText = value;
                  });
                },
                controller: _controller,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "value"),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter(RegExp(r'[0-9]'),
                      allow: true, replacementString: '.')
                ],
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('CANCEL'),
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                    });
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('OK'),
                  onPressed: () {
                    setState(() {
                      model.editProduct(title, valueText, id);
                      Navigator.pop(context);
                    });
                  },
                ),
              ],
            );
          }));
        });
      },
    );
  }
}
