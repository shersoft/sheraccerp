class LocationModel {
  double latitude;
  double longitude;

  LocationModel({
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromMap(Map<String, dynamic> json) => LocationModel(
        latitude: double.parse(json["Latitude"].toString()),
        longitude: double.parse(json["Longitude"].toString()),
      );

  Map<String, dynamic> toMap() => {
        "Latitude": latitude,
        "Longitude": longitude,
      };

  static emptyData() {
    return LocationModel(latitude: 10.973145, longitude: 76.216909);
  }
}

class LocationUserModel {
  String name;
  List<LocationModel> locationList;
  LocationUserModel({
    required this.name,
    required this.locationList,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'locationList': locationList.map((x) => x.toMap()).toList(),
    };
  }

  factory LocationUserModel.fromMap(Map<String, dynamic> map) {
    return LocationUserModel(
      name: map['name'] ?? '',
      locationList: List<LocationModel>.from(
          map['location']?.map((x) => LocationModel.fromMap(x))),
    );
  }

  static emptyData() {
    return LocationUserModel(name: '', locationList: [
      LocationModel(latitude: 10.973145, longitude: 76.216909)
    ]);
  }
}
