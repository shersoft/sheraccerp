// @dart = 2.11
import 'package:flutter/material.dart';

import 'package:sheraccerp/screens/inventory/categorydetail.dart';

class HorizontalList extends StatelessWidget {
  const HorizontalList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const <Widget>[
          Category(
            imageLocation: 'assets/icons/no_image.png',
            imageCaption: 'Groceries & Staples',
          ),
          Category(
            imageLocation: 'assets/icons/no_image.png',
            imageCaption: 'Household Needs',
          ),
          Category(
            imageLocation: 'assets/icons/no_image.png',
            imageCaption: 'Personal Needs',
          ),
          Category(
            imageLocation: 'assets/icons/no_image.png',
            imageCaption: 'Dairy Products',
          ),
          Category(
            imageLocation: 'assets/icons/no_image.png',
            imageCaption: 'Frozen Food',
          ),
          Category(
            imageLocation: 'assets/icons/no_image.png',
            imageCaption: 'Snacks',
          ),
        ],
      ),
    );
  }
}

class Category extends StatelessWidget {
  final String imageLocation;
  final String imageCaption;

  const Category({
    Key key,
    this.imageLocation,
    this.imageCaption,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: InkWell(
        onTap: () {},
        child: SizedBox(
            width: 150.0,
            child: InkWell(
              onTap: () {
                var route = MaterialPageRoute(
                  builder: (BuildContext context) =>
                      NextPage(value: imageCaption),
                );
                Navigator.of(context).push(route);
                //   Naator.push(context, new MaterialPageRoute(builder: (context) => ProductCategories(categ:  ProductCategories(snapshot.data[index].data['category']))));
              },
              child: ListTile(
                title: Image.asset(
                  // IMAGE LOCATION
                  imageLocation,
                  width: 100.0,
                  height: 80.0,
                ),
                subtitle: Text(
                  imageCaption,
                  textAlign: TextAlign.center,
                ),
              ),
            )),
      ),
    );
  }
}
