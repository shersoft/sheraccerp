// @dart = 2.9
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sheraccerp/shared/constants.dart';

class TestPage extends StatelessWidget {
  const TestPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var _infoKey = <GlobalKey>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Popup Window"),
        backgroundColor: Colors.pink,
      ),
      backgroundColor: Colors.blueGrey,
      body: Container(
        margin: const EdgeInsets.all(8),
        child: ListView.builder(
            cacheExtent: 10000.0,
            itemCount: 2,
            /*_homeController
                          .configResponse.value.configLayoutList.length,*/
            itemBuilder: (context, index) {
              _infoKey.add(GlobalKey(debugLabel: index.toString()));
              return Card(
                  elevation: 1.5,
                  child: Container(
                      margin: const EdgeInsets.all(10),
                      child: Column(children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Bill ID: 2021",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        )),
                                    const Text("Home Delivery",
                                        style: const TextStyle(
                                          color: Colors.deepOrange,
                                          fontSize: 12,
                                        )),
                                  ]),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('12-11-2019 - 8:30 PM',
                                        style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 12,
                                        )),
                                    const Text('22 min ago',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ))
                                  ])
                            ]),
                        const SizedBox(height: 5),
                        Row(children: [
                          Flexible(
                              flex: 2500,
                              child: Row(children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Colors.red, size: 14),
                                const SizedBox(width: 5),
                                const Text('Frawns',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ))
                              ])),
                          Flexible(
                              flex: 700,
                              child: Row(children: [
                                const Text('X',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    )),
                                const Text('1',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ))
                              ])),
                          const Flexible(
                              flex: 0,
                              child: const Text(currencySymbol + '2000',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ))),
                        ]),
                        const SizedBox(height: 2),
                        Row(children: [
                          Flexible(
                              flex: 2500,
                              child: Row(children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 14),
                                const SizedBox(width: 5),
                                const Text('Veg Thaliya',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ))
                              ])),
                          Flexible(
                              flex: 700,
                              child: Row(children: [
                                const Text('X',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    )),
                                const Text('1',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ))
                              ])),
                          const Flexible(
                              flex: 0,
                              child: const Text(currencySymbol + '2000',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  )))
                        ]),
                        const SizedBox(height: 3),
                        Divider(color: Colors.grey.withOpacity(0.2)),
                        Row(children: [
                          Flexible(
                              flex: 2500,
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      const Text('Paid',
                                          style: const TextStyle(
                                            color: Colors.deepOrange,
                                            fontSize: 14,
                                          )),
                                      const SizedBox(width: 3),
                                      const Text('(Collect)',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                          ))
                                    ]),
                                    Row(children: [
                                      const Text('Total',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          )),
                                      const SizedBox(width: 3),
                                      GestureDetector(
                                          key: _infoKey[index],
                                          onTap: () {
                                            RenderBox renderBox =
                                                _infoKey[index]
                                                    .currentContext
                                                    .findRenderObject();
                                            Offset offset = renderBox
                                                .localToGlobal(Offset.zero);
                                            showPopupWindow(
                                                context: context,
                                                fullWidth: false,
                                                //isShowBg:true,
                                                position: RelativeRect.fromLTRB(
                                                    0,
                                                    offset.dy +
                                                        renderBox.size.height,
                                                    0,
                                                    0),
                                                child: GestureDetector(
                                                    onTap: () {},
                                                    child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: Column(
                                                            children: [
                                                              Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    const Text(
                                                                        'Item Total',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.grey,
                                                                          fontSize:
                                                                              12,
                                                                        )),
                                                                    const Text(
                                                                        '00',
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              14,
                                                                        ))
                                                                  ]),
                                                              const SizedBox(
                                                                  height: 3),
                                                              Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    const Text(
                                                                        'Service Tax',
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              Colors.grey,
                                                                          fontSize:
                                                                              12,
                                                                        )),
                                                                    const Text(
                                                                        '00',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              14,
                                                                        ))
                                                                  ]),
                                                              const SizedBox(
                                                                  height: 3),
                                                              Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    const Text(
                                                                        'Delivery Charge',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.grey,
                                                                          fontSize:
                                                                              12,
                                                                        )),
                                                                    const Text(
                                                                        '00',
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              14,
                                                                        ))
                                                                  ]),
                                                              const SizedBox(
                                                                  height: 3),
                                                              Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    const Text(
                                                                        'Discount',
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              Colors.grey,
                                                                          fontSize:
                                                                              12,
                                                                        )),
                                                                    const Text(
                                                                        '00',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              14,
                                                                        ))
                                                                  ]),
                                                              const SizedBox(
                                                                  height: 3),
                                                              Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    const Text(
                                                                        'CGST',
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              Colors.grey,
                                                                          fontSize:
                                                                              12,
                                                                        )),
                                                                    const Text(
                                                                        '00',
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              14,
                                                                        ))
                                                                  ]),
                                                              const SizedBox(
                                                                  height: 3),
                                                              Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    const Text(
                                                                        'SGST',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.grey,
                                                                          fontSize:
                                                                              12,
                                                                        )),
                                                                    const Text(
                                                                        '00',
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              14,
                                                                        ))
                                                                  ]),
                                                              const Divider(
                                                                  color: Colors
                                                                      .green),
                                                              Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    const Text(
                                                                        'TOTAL',
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              12,
                                                                        )),
                                                                    const Text(
                                                                        '00',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ))
                                                                  ])
                                                            ]))));
                                          },
                                          child: const Icon(Icons.info_outline,
                                              size: 20, color: Colors.blue)),
                                      const SizedBox(width: 3)
                                    ])
                                  ])),
                          Flexible(
                              flex: 700,
                              child: Row(children: [
                                const Text('X',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    )),
                                const Text('2',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ))
                              ])),
                          const Flexible(
                              flex: 0,
                              child: Text('\u20B9 6000',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  )))
                        ]),
                        const SizedBox(height: 15),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                IntrinsicWidth(
                                    child: Column(children: [
                                  const Text('REJECT',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      )),
                                  const SizedBox(height: 1),
                                  Container(color: Colors.black, height: 1)
                                ])),
                                const SizedBox(width: 20),
                                IntrinsicWidth(
                                    child: Column(children: [
                                  const Text('BILL',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      )),
                                  const SizedBox(height: 1),
                                  Container(color: Colors.black, height: 1)
                                ]))
                              ]),
                              Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Text('FOOD READY',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12)))
                            ])
                      ])));
            }),
      ),
    );
  }
}

/****************************************/
const Duration _kWindowDuration = Duration(milliseconds: 0);
const double _kWindowCloseIntervalEnd = 2.0 / 3.0;
const double _kWindowMaxWidth = 240.0;
const double _kWindowMinWidth = 48.0;
//double _kWindowMinWidth = Get.width/2;
const double _kWindowVerticalPadding = 0.0;
const double _kWindowScreenPadding = 0.0;
Future<T> showPopupWindow<T>({
  @required BuildContext context,
  RelativeRect position,
  @required Widget child,
  double elevation = 8.0,
  String semanticLabel,
  bool fullWidth,
  bool isShowBg = false,
}) {
  assert(context != null);
  String label = semanticLabel;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      label = semanticLabel;
      break;
    case TargetPlatform.android:
      break;
    case TargetPlatform.fuchsia:
      label =
          semanticLabel ?? MaterialLocalizations.of(context)?.popupMenuLabel;
      break;
    case TargetPlatform.linux:
      break;
    case TargetPlatform.macOS:
      break;
    case TargetPlatform.windows:
      break;
  }
  return Navigator.push(
      context,
      _PopupWindowRoute(
          context: context,
          position: position,
          child: child,
          elevation: elevation,
          semanticLabel: label,
          theme: Theme.of(context),
          barrierLabel:
              MaterialLocalizations.of(context).modalBarrierDismissLabel,
          fullWidth: fullWidth,
          isShowBg: isShowBg));
}

class _PopupWindowRoute<T> extends PopupRoute<T> {
  _PopupWindowRoute({
    @required BuildContext context,
    RouteSettings settings,
    @required this.child,
    this.position,
    this.elevation = 8.0,
    this.theme,
    this.barrierLabel,
    this.semanticLabel,
    this.fullWidth,
    this.isShowBg,
  }) : super(settings: settings) {
    assert(child != null);
  }
  final Widget child;
  final RelativeRect position;
  double elevation;
  final ThemeData theme;
  final String semanticLabel;
  final bool fullWidth;
  final bool isShowBg;
  @override
  Color get barrierColor => null;
  @override
  bool get barrierDismissible => true;
  @override
  final String barrierLabel;
  @override
  Duration get transitionDuration => _kWindowDuration;
  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
        parent: super.createAnimation(),
        curve: Curves.linear,
        reverseCurve: const Interval(0.0, _kWindowCloseIntervalEnd));
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    Widget win = _PopupWindow<T>(
      route: this,
      semanticLabel: semanticLabel,
      fullWidth: fullWidth,
    );
    if (theme != null) {
      win = Theme(data: theme, child: win);
    }
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return Material(
            type: MaterialType.transparency,
            child: GestureDetector(
              onTap: () {
                // Get.back();
                // NavigatorUtils.goBack(context);
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: isShowBg ? const Color(0x99000000) : null,
                child: CustomSingleChildLayout(
                  delegate: _PopupWindowLayoutDelegate(
                      position, null, Directionality.of(context)),
                  child: win,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PopupWindow<T> extends StatelessWidget {
  const _PopupWindow({
    Key key,
    this.route,
    this.semanticLabel,
    this.fullWidth = false,
  }) : super(key: key);
  final _PopupWindowRoute<T> route;
  final String semanticLabel;
  final bool fullWidth;
  @override
  Widget build(BuildContext context) {
    const double length = 10.0;
    const double unit = 1.0 /
        (length + 1.5); // 1.0 for the width and 0.5 for the last item's fade.
    final CurveTween opacity =
        CurveTween(curve: const Interval(0.0, 1.0 / 3.0));
    final CurveTween width = CurveTween(curve: const Interval(0.0, unit));
    final CurveTween height =
        CurveTween(curve: const Interval(0.0, unit * length));
    Size device = MediaQuery.of(context).size;
    final Widget child = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: fullWidth ? double.infinity : _kWindowMinWidth,
          maxWidth: fullWidth ? double.infinity : device.width / 1.15,
        ),
        child: SingleChildScrollView(
          //padding: EdgeInsets.all(20),
          padding:
              const EdgeInsets.symmetric(vertical: _kWindowVerticalPadding),
          child: route.child,
        ));
    return AnimatedBuilder(
      animation: route.animation,
      builder: (BuildContext context, Widget child) {
        return Opacity(
          opacity: opacity.evaluate(route.animation),
          child: Material(
            type: route.elevation == 0
                ? MaterialType.transparency
                : MaterialType.card,
            elevation: route.elevation,
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              widthFactor: width.evaluate(route.animation),
              heightFactor: height.evaluate(route.animation),
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: semanticLabel,
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _PopupWindowLayoutDelegate extends SingleChildLayoutDelegate {
  _PopupWindowLayoutDelegate(
      this.position, this.selectedItemOffset, this.textDirection);
  final RelativeRect position;
  final double selectedItemOffset;
  final TextDirection textDirection;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest -
        const Offset(_kWindowScreenPadding * 2.0, _kWindowScreenPadding * 2.0));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double y;
    if (selectedItemOffset == null) {
      y = position.top;
    } else {
      y = position.top +
          (size.height - position.top - position.bottom) / 2.0 -
          selectedItemOffset;
    }
    // Find the ideal horizontal position.
    double x;
    x = (size.width - childSize.width) / 2;

    if (x < _kWindowScreenPadding) {
      x = _kWindowScreenPadding;
    } else if (x + childSize.width > size.width - _kWindowScreenPadding) {
      x = size.width - childSize.width - _kWindowScreenPadding;
    }
    if (y < _kWindowScreenPadding)
      y = _kWindowScreenPadding;
    else if (y + childSize.height > size.height - _kWindowScreenPadding)
      y = size.height - childSize.height - _kWindowScreenPadding;
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopupWindowLayoutDelegate oldDelegate) {
    return position != oldDelegate.position;
  }
}
