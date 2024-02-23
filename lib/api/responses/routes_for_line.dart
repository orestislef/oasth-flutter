class RoutesForLine {
  late List<RouteForLine> routes;

  static RoutesForLine fromMap(List<dynamic> map) {
    RoutesForLine obj = RoutesForLine();
    obj.routes = [];
    for (int i = 0; i < map.length; i++) {
      obj.routes.add(RouteForLine.fromMap(map[i]));
    }
    return obj;
  }

  Map toJson() => {
        "routes": routes,
      };
}

class RouteForLine {
  String? routeCode;
  String? routeDescription;
  String? routeDescriptionEng;

  static RouteForLine fromMap(Map<String, dynamic> map) {
    RouteForLine routeForLineBean = RouteForLine();
    routeForLineBean.routeCode = map['route_code'];
    routeForLineBean.routeDescription = map['route_descr'];
    routeForLineBean.routeDescriptionEng = map['route_descr_eng'];
    return routeForLineBean;
  }

  Map toJson() => {
        "route_code": routeCode,
        "route_descr": routeDescription,
        "route_descr_eng": routeDescriptionEng,
      };
}
