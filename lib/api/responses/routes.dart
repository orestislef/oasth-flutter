class Routes {
  List<Route>? routes;

  static Routes fromMap(List<dynamic> map) {
    Routes routes = Routes();
    routes.routes = List<Route>.from(
      (map).map((o) => Route.fromMap(o)),
    );
    return routes;
  }

  Map<String, dynamic> toJson() => {
        "routes": routes?.map((e) => e.toJson()).toList(),
      };
}

class Route {
  String? routeCode;
  String? lineCode;
  String? routeDescription;
  String? routeType;
  String? routeDistance;

  static Route fromMap(Map<String, dynamic> map) {
    Route route = Route();
    route.routeCode = map['RouteCode'];
    route.lineCode = map['LineCode'];
    route.routeDescription = map['RouteDescr'];
    route.routeType = map['RouteType'];
    route.routeDistance = map['RouteDistance'];
    return route;
  }

  Map<String, dynamic> toJson() => {
        "RouteCode": routeCode,
        "LineCode": lineCode,
        "RouteDescr": routeDescription,
        "RouteType": routeType,
        "RouteDistance": routeDistance,
      };
}
