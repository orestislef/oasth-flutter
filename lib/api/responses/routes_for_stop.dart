class RoutesForStop {
  final List<RouteForStop> routesForStop;

  const RoutesForStop({required this.routesForStop});

  factory RoutesForStop.fromMap(List<dynamic> map) {
    return RoutesForStop(
      routesForStop: map.map((o) => RouteForStop.fromMap(o)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'routesForStop': routesForStop.map((e) => e.toMap()).toList(),
      };
}

class RouteForStop {
  final String routeCode;
  final String lineCode;
  final String hidden;
  final String routeDescr;
  final String routeType;
  final String routeDistance;
  final String lineID;
  final String lineDescription;
  final String lineDescriptionEng;
  final String masterLineCode;

  const RouteForStop({
    required this.routeCode,
    required this.lineCode,
    required this.hidden,
    required this.routeDescr,
    required this.routeType,
    required this.routeDistance,
    required this.lineID,
    required this.lineDescription,
    required this.lineDescriptionEng,
    required this.masterLineCode,
  });

  factory RouteForStop.fromMap(Map<String, dynamic> map) {
    return RouteForStop(
      routeCode: map['RouteCode']?.toString() ?? '',
      lineCode: map['LineCode']?.toString() ?? '',
      hidden: map['hidden']?.toString() ?? '',
      routeDescr: map['RouteDescr']?.toString() ?? '',
      routeType: map['RouteType']?.toString() ?? '',
      routeDistance: map['RouteDistance']?.toString() ?? '',
      lineID: map['LineID']?.toString() ?? '',
      lineDescription: map['LineDescr']?.toString() ?? '',
      lineDescriptionEng: map['LineDescrEng']?.toString() ?? '',
      masterLineCode: map['MasterLineCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'RouteCode': routeCode,
        'LineCode': lineCode,
        'hidden': hidden,
        'RouteDescr': routeDescr,
        'RouteType': routeType,
        'RouteDistance': routeDistance,
        'LineID': lineID,
        'LineDescr': lineDescription,
        'LineDescrEng': lineDescriptionEng,
        'MasterLineCode': masterLineCode,
      };
}
