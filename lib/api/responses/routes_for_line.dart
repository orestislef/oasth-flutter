class RoutesForLine {
  final List<LineRoute> routesForLine;

  const RoutesForLine({required this.routesForLine});

  factory RoutesForLine.fromMap(List<dynamic> map) {
    return RoutesForLine(
      routesForLine: map.map((e) => LineRoute.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'routes': routesForLine.map((e) => e.toMap()).toList(),
      };
}

class LineRoute {
  final String routeCode;
  final String routeDescription;
  final String routeDescriptionEng;

  const LineRoute({
    required this.routeCode,
    required this.routeDescription,
    required this.routeDescriptionEng,
  });

  factory LineRoute.fromMap(Map<String, dynamic> map) {
    return LineRoute(
      routeCode: map['route_code']?.toString() ?? '',
      routeDescription: map['route_descr']?.toString() ?? '',
      routeDescriptionEng: map['route_descr_eng']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'route_code': routeCode,
        'route_descr': routeDescription,
        'route_descr_eng': routeDescriptionEng,
      };
}
