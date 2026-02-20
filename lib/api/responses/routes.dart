class Routes {
  final List<RouteData> routes;

  const Routes({required this.routes});

  factory Routes.fromMap(List<dynamic> map) {
    return Routes(
      routes: map.map((o) => RouteData.fromMap(o)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'routes': routes.map((e) => e.toMap()).toList(),
      };
}

class RouteData {
  final String routeCode;
  final String lineCode;
  final String routeDescription;
  final String routeType;
  final String routeDistance;

  const RouteData({
    required this.routeCode,
    required this.lineCode,
    required this.routeDescription,
    required this.routeType,
    required this.routeDistance,
  });

  factory RouteData.fromMap(Map<String, dynamic> map) {
    return RouteData(
      routeCode: map['RouteCode']?.toString() ?? '',
      lineCode: map['LineCode']?.toString() ?? '',
      routeDescription: map['RouteDescr']?.toString() ?? '',
      routeType: map['RouteType']?.toString() ?? '',
      routeDistance: map['RouteDistance']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'RouteCode': routeCode,
        'LineCode': lineCode,
        'RouteDescr': routeDescription,
        'RouteType': routeType,
        'RouteDistance': routeDistance,
      };
}
