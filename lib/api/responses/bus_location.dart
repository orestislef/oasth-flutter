class BusLocation {
  final List<BusLocationData> busLocation;

  const BusLocation({required this.busLocation});

  factory BusLocation.fromMap(List<dynamic> map) {
    return BusLocation(
      busLocation: map.map((e) => BusLocationData.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'busLocation': busLocation.map((e) => e.toMap()).toList(),
      };
}

class BusLocationData {
  final String vehNo;
  final String csDate;
  final double csLat;
  final double csLng;
  final String routeCode;

  const BusLocationData({
    required this.vehNo,
    required this.csDate,
    required this.csLat,
    required this.csLng,
    required this.routeCode,
  });

  factory BusLocationData.fromMap(Map<String, dynamic> map) {
    return BusLocationData(
      vehNo: map['VEH_NO']?.toString() ?? '',
      csDate: map['CS_DATE']?.toString() ?? '',
      csLat: double.tryParse(map['CS_LAT']?.toString() ?? '') ?? 0.0,
      csLng: double.tryParse(map['CS_LNG']?.toString() ?? '') ?? 0.0,
      routeCode: map['ROUTE_CODE']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'VEH_NO': vehNo,
        'CS_DATE': csDate,
        'CS_LAT': csLat.toString(),
        'CS_LNG': csLng.toString(),
        'ROUTE_CODE': routeCode,
      };
}
