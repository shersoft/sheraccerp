import 'package:flutter/material.dart';
import 'package:sheraccerp/util/res_color.dart';

class PlusMinusButtons extends StatelessWidget {
  final VoidCallback deleteQuantity;
  final VoidCallback addQuantity;
  final String text;
  const PlusMinusButtons(
      {Key? key,
      required this.addQuantity,
      required this.deleteQuantity,
      required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          child: IconButton(
              onPressed: deleteQuantity,
              icon: Icon(
                Icons.remove,
                color: red,
              )),
        ),
        Text(text),
        IconButton(
            onPressed: addQuantity,
            icon: Icon(
              Icons.add,
              color: green,
            )),
      ],
    );
  }

  // child: Card(
  //               color: Colors.green[200],
  //               child: IconButton(
  //                 icon: const Icon(
  //                   Icons.add,
  //                   color: Colors.black,
  //                   size: 18,
  //                 ),
  //                 onPressed: () {
  //                   if (oldBill) {
  //                     api
  //                         .getStockOf(
  //                             cartItem[index].itemId)
  //                         .then((value) {
  //                       cartItem[index].stock = value;
  //                       setState(() {
  //                         bool cartQ = false;
  //                         if (totalItem > 0) {
  //                           double cartS = 0, cartQt = 0;
  //                           for (var element in cartItem) {
  //                             if (element.itemId ==
  //                                 cartItem[index].itemId) {
  //                               cartQt += element.quantity;
  //                               cartS = element.stock;
  //                             }
  //                           }
  //                           cartS = oldBill ? value : cartS;
  //                           if (cartS > 0) {
  //                             if (cartS < cartQt + 1) {
  //                               cartQ = true;
  //                             }
  //                           }
  //                         }
  //                         outOfStock = isLockQtyOnlyInSales
  //                             ? cartItem[index].quantity +
  //                                         1 >
  //                                     cartItem[index].stock
  //                                 ? true
  //                                 : cartQ
  //                                     ? true
  //                                     : false
  //                             : negativeStock
  //                                 ? false
  //                                 : salesTypeData.type ==
  //                                             'SALES-O' ||
  //                                         salesTypeData
  //                                                 .type ==
  //                                             'SALES-Q'
  //                                     ? isStockProductOnlyInSalesQO
  //                                         ? cartItem[index]
  //                                                         .quantity +
  //                                                     1 >
  //                                                 cartItem[
  //                                                         index]
  //                                                     .stock
  //                                             ? true
  //                                             : cartQ
  //                                                 ? true
  //                                                 : false
  //                                         : false
  //                                     : cartItem[index]
  //                                                     .quantity +
  //                                                 1 >
  //                                             cartItem[
  //                                                     index]
  //                                                 .stock
  //                                         ? true
  //                                         : cartQ
  //                                             ? true
  //                                             : false;
  //                         if (outOfStock) {
  //                           ScaffoldMessenger.of(context)
  //                               .showSnackBar(SnackBar(
  //                             content: const Text(
  //                                 'Sorry stock not available.'),
  //                             duration: const Duration(
  //                                 seconds: 10),
  //                             action: SnackBarAction(
  //                               label: 'Click',
  //                               onPressed: () {
  //                                 // print('Action is clicked');
  //                               },
  //                               textColor: Colors.white,
  //                               disabledTextColor:
  //                                   Colors.grey,
  //                             ),
  //                             backgroundColor: Colors.red,
  //                           ));
  //                         } else {
  //                           updateProduct(
  //                               cartItem[index],
  //                               cartItem[index].quantity +
  //                                   1,
  //                               index);
  //                         }
  //                       });
  //                     });
  //                   } else {
  //                     setState(() {
  //                       bool cartQ = false;
  //                       if (totalItem > 0) {
  //                         double cartS = 0, cartQt = 0;
  //                         for (var element in cartItem) {
  //                           if (element.itemId ==
  //                               cartItem[index].itemId) {
  //                             cartQt += element.quantity;
  //                             cartS = element.stock;
  //                           }
  //                         }
  //                         // cartS = oldBill?:cartS;
  //                         if (cartS > 0) {
  //                           if (cartS < cartQt + 1) {
  //                             cartQ = true;
  //                           }
  //                         }
  //                       }
  //                       outOfStock = isLockQtyOnlyInSales
  //                           ? ((cartItem[index].quantity *
  //                                               cartItem[index]
  //                                                   .unitValue) +
  //                                           cartItem[index]
  //                                               .free) +
  //                                       1 >
  //                                   cartItem[index].stock
  //                               ? true
  //                               : cartQ
  //                                   ? true
  //                                   : false
  //                           : negativeStock
  //                               ? false
  //                               : salesTypeData.type ==
  //                                           'SALES-O' ||
  //                                       salesTypeData
  //                                               .type ==
  //                                           'SALES-Q'
  //                                   ? isStockProductOnlyInSalesQO
  //                                       ? ((cartItem[index].quantity * cartItem[index].unitValue) +
  //                                                       cartItem[index]
  //                                                           .free) +
  //                                                   1 >
  //                                               cartItem[
  //                                                       index]
  //                                                   .stock
  //                                           ? true
  //                                           : cartQ
  //                                               ? true
  //                                               : false
  //                                       : false
  //                                   : cartItem[index]
  //                                                   .quantity +
  //                                               1 >
  //                                           cartItem[index]
  //                                               .stock
  //                                       ? true
  //                                       : cartQ
  //                                           ? true
  //                                           : false;
  //                       if (outOfStock) {
  //                         ScaffoldMessenger.of(context)
  //                             .showSnackBar(SnackBar(
  //                           content: const Text(
  //                               'Sorry stock not available.'),
  //                           duration:
  //                               const Duration(seconds: 10),
  //                           action: SnackBarAction(
  //                             label: 'Click',
  //                             onPressed: () {
  //                               // print('Action is clicked');
  //                             },
  //                             textColor: Colors.white,
  //                             disabledTextColor:
  //                                 Colors.grey,
  //                           ),
  //                           backgroundColor: Colors.red,
  //                         ));
  //                       } else {
  //                         updateProduct(
  //                             cartItem[index],
  //                             cartItem[index].quantity + 1,
  //                             index);
  //                       }
  //                     });
  //                   }
  //                 },
  //               ),
  //             ),
}

class ReusableWidget extends StatelessWidget {
  final String title, value;
  const ReusableWidget({Key? key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.subtitle2,
          ),
        ],
      ),
    );
  }
}
