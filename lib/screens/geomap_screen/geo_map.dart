import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sheraccerp/models/location_model.dart';
import 'package:sheraccerp/screens/geomap_screen/lifecycle_aware_stream_builder.dart';
import 'package:sheraccerp/shared/constants.dart';

class GeoMap extends StatefulWidget {
  const GeoMap({Key? key}) : super(key: key);

  @override
  State<GeoMap> createState() => _GeoMapState();
}

class _GeoMapState extends State<GeoMap> {
  List<LocationUserModel> locationUserData = [];

  final stream =
      Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
    final dio = Dio();
    List<LocationUserModel> locationUserDataResult = [];
    try {
      final response = await dio
          .get('${geoMapUrl}getUsers', queryParameters: {'id': customerId});
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        for (var map in jsonResponse) {
          locationUserDataResult.add(LocationUserModel.fromMap(map));
        }
      } else {
        debugPrint('Failed to load data');
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    return locationUserDataResult;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SherAccERP')),
      body: Stack(
        children: [
          LifecycleAwareStreamBuilder<List<LocationUserModel>>(
            [LocationUserModel.emptyData()],
            stream: stream,
            builder: (context, sn) {
              if (sn.hasData) {
                locationUserData = sn.data!;
                return FlutterMap(
                  options:
                      MapOptions(center: LatLng(10.973145, 76.216909), zoom: 10
                          // initialCenter: const LatLng(51.5, -0.09),
                          // initialZoom: 5,
                          // cameraConstraint: CameraConstraint.contain(
                          //   bounds: LatLngBounds(
                          //     const LatLng(-90, -180),
                          //     const LatLng(90, 180),
                          //   ),
                          // ),
                          ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    PolylineLayer(polylines: polyLineWidget(locationUserData)),
                    CircleLayer(
                      circles: circleMakerWidget(locationUserData),
                    ),
                    MarkerLayer(
                      markers: buildMarkerWidget(locationUserData),
                    )
                  ],
                );
              }
              return Container();
            },
          ),
          // const FloatingMenuButton()
        ],
      ),
    );
  }

  List<LatLng> listLatLng(List<LocationModel> locationData) {
    List<LatLng> result = [];
    for (LocationModel data in locationData) {
      result.add(LatLng(data.latitude, data.longitude));
    }
    return result;
  }

  TextStyle getDefaultTextStyle() {
    return const TextStyle(
      fontSize: 12,
      backgroundColor: Colors.black,
      color: Colors.white,
    );
  }

  Container buildTextWidget(String word) {
    return Container(
        alignment: Alignment.center,
        child: Text(word,
            textAlign: TextAlign.center, style: getDefaultTextStyle()));
  }

  Marker buildMarker(LatLng coordinates, String word) {
    return Marker(
        point: coordinates,
        width: 100,
        height: 12,
        builder: (context) => buildTextWidget(word));
  }

  final _random = Random();
  polyLineWidget(List<LocationUserModel> result) {
    List<Polyline> polyLinesList = [];
    for (int i = 0; i < result.length; i++) {
      Color _randomColor = colorList[i];
      // Color.fromARGB(_random.nextInt(256), _random.nextInt(256),
      //     _random.nextInt(256), _random.nextInt(256));
      polyLinesList.add(
        Polyline(
          points: result[i].locationList.isNotEmpty
              ? listLatLng(result[i].locationList)
              : [
                  LatLng(0, 0),
                ],
          color: _randomColor,
          strokeWidth: 2,
        ),
      );
    }
    return polyLinesList;
  }

  List<Color> colorList = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.pink,
    Colors.cyan,
    Colors.lime,
    Colors.purple,
    Colors.teal,
    Colors.indigo
  ];

  circleMakerWidget(List<LocationUserModel> result) {
    List<CircleMarker> circleMarkerList = [];
    for (int i = 0; i < result.length; i++) {
      circleMarkerList.add(CircleMarker(
        point: result[i].locationList.isNotEmpty
            ? listLatLng(result[i].locationList).last
            : LatLng(52.2677, 5.1689),
        radius: 50,
        useRadiusInMeter: true,
        color: Colors.red.withOpacity(0.3),
        borderColor: Colors.red.withOpacity(0.7),
        borderStrokeWidth: 2,
      ));
    }
    return circleMarkerList;
  }

  buildMarkerWidget(List<LocationUserModel> result) {
    List<Marker> markerList = [];
    for (int i = 0; i < result.length; i++) {
      markerList.add(buildMarker(
          result[i].locationList.isNotEmpty
              ? listLatLng(result[i].locationList).last
              : LatLng(10.974949, 76.226471),
          result[i].name));
    }
    return markerList;
  }
}
