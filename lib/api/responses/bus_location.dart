class BusLocation {
  late List<BusLocationData> busLocation;

  static BusLocation fromMap(List<dynamic> map) {
    BusLocation obj = BusLocation();
    obj.busLocation = [];
    for (int i = 0; i < map.length; i++) {
      obj.busLocation.add(BusLocationData.fromMap(map[i]));
    }
    return obj;
  }
}

class BusLocationData {
  String? vehNo;
  String? csDate;
  String? csLat;
  String? csLng;
  String? routeCode;

  static BusLocationData fromMap(Map<String, dynamic> map) {
    BusLocationData objBean = BusLocationData();
    objBean.vehNo = map['VEH_NO'];
    objBean.csDate = map['CS_DATE'];
    objBean.csLat = map['CS_LAT'];
    objBean.csLng = map['CS_LNG'];
    objBean.routeCode = map['ROUTE_CODE'];
    return objBean;
  }

  Map toJson() => {
        "VEH_NO": vehNo,
        "CS_DATE": csDate,
        "CS_LAT": csLat,
        "CS_LNG": csLng,
        "ROUTE_CODE": routeCode
      };
}
