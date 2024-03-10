class RoutesForLine {
  late List<Route> routesForLine;

  static RoutesForLine fromMap(List<dynamic> map) {
    RoutesForLine routeForLine = RoutesForLine();
    routeForLine.routesForLine = [];
    for (int i = 0; i < map.length; i++) {
      routeForLine.routesForLine.add(Route.fromMap(map[i]));
    }
    return routeForLine;
  }

  Map toJson() => {
        "routes": routesForLine,
      };
}

class Route {
  String? routeCode;
  String? routeDescription;
  String? routeDescriptionEng;

  static Route fromMap(Map<String, dynamic> map) {
    Route routeForLine = Route();
    routeForLine.routeCode = map['route_code'];
    routeForLine.routeDescription = map['route_descr'];
    routeForLine.routeDescriptionEng = map['route_descr_eng'];
    return routeForLine;
  }

  Map toJson() => {
        "route_code": routeCode,
        "route_descr": routeDescription,
        "route_descr_eng": routeDescriptionEng,
      };
}
