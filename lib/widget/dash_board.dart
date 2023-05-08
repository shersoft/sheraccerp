import 'package:flutter/material.dart';
import 'cash_and_bank.dart';
import 'expense.dart';
import 'receivables_payables.dart';
import 'statement.dart';

class DashList extends StatefulWidget {
  const DashList({Key? key}) : super(key: key);

  @override
  State<DashList> createState() => _DashListState();
}

class _DashListState extends State<DashList> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return index == 1
        ? SizedBox(
            height: size.height,
            width: size.height,
            child: Column(
              children: [
                const Expanded(child: Statement()),
                BackButton(
                  onPressed: () {
                    setState(() {
                      index = 0;
                    });
                  },
                ),
              ],
            ),
          )
        : index == 2
            ? SizedBox(
                height: size.height,
                width: size.height,
                child: Column(
                  children: [
                    const Expanded(child: Expense()),
                    BackButton(
                      onPressed: () {
                        setState(() {
                          index = 0;
                        });
                      },
                    ),
                  ],
                ),
              )
            : index == 3
                ? SizedBox(
                    height: size.height,
                    width: size.height,
                    child: Column(
                      children: [
                        Expanded(child: CashAndBank()),
                        BackButton(
                          onPressed: () {
                            setState(() {
                              index = 0;
                            });
                          },
                        ),
                      ],
                    ),
                  )
                : index == 4
                    ? SizedBox(
                        height: size.height,
                        width: size.height,
                        child: Column(
                          children: [
                            BackButton(
                              onPressed: () {
                                setState(() {
                                  index = 0;
                                });
                              },
                            ),
                            Expanded(child: ReceivablesAndPayables()),
                          ],
                        ),
                      )
                    : Center(
                        child: ListView(shrinkWrap: true, children: [
                          Card(
                              elevation: 5,
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50))),
                              child: TextButton(
                                child: const Text('Statement',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        fontFamily: 'Poppins')),
                                onPressed: () {
                                  setState(() {
                                    index = 1;
                                  });
                                },
                              )),
                          Card(
                              elevation: 5,
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50))),
                              child: TextButton(
                                child: const Text('Expense',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        fontFamily: 'Poppins')),
                                onPressed: () {
                                  setState(() {
                                    index = 2;
                                  });
                                },
                              )),
                          Card(
                              elevation: 5,
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50))),
                              child: TextButton(
                                child: const Text('Cash & Bank',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        fontFamily: 'Poppins')),
                                onPressed: () {
                                  setState(() {
                                    index = 3;
                                  });
                                },
                              )),
                          Card(
                              elevation: 5,
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50))),
                              child: TextButton(
                                child: const Text('Receivable & Payable',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        fontFamily: 'Poppins')),
                                onPressed: () {
                                  setState(() {
                                    index = 4;
                                  });
                                },
                              )),
                        ]),
                      );
  }
}
