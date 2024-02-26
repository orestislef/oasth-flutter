class BusLocation {
  late List<BusLocationData> busLocation;

  static BusLocation fromMap(List<dynamic> map) {
    BusLocation busLocation = BusLocation();
    busLocation.busLocation = [];
    for (int i = 0; i < map.length; i++) {
      busLocation.busLocation.add(BusLocationData.fromMap(map[i]));
    }
    return busLocation;
  }
}

class BusLocationData {
  String? vehNo;
  String? csDate;
  String? csLat;
  String? csLng;
  String? routeCode;

  static BusLocationData fromMap(Map<String, dynamic> map) {
    BusLocationData busLocation = BusLocationData();
    busLocation.vehNo = map['VEH_NO'];
    busLocation.csDate = map['CS_DATE'];
    busLocation.csLat = map['CS_LAT'];
    busLocation.csLng = map['CS_LNG'];
    busLocation.routeCode = map['ROUTE_CODE'];
    return busLocation;
  }

  Map toJson() => {
        "VEH_NO": vehNo,
        "CS_DATE": csDate,
        "CS_LAT": csLat,
        "CS_LNG": csLng,
        "ROUTE_CODE": routeCode
      };
}
