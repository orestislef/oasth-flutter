class RoutesForStop {
  List<RouteForStop>? routesForStop;

  static RoutesForStop fromMap(List<dynamic> map) {
    RoutesForStop routesForStop = RoutesForStop();
    routesForStop.routesForStop = List<RouteForStop>.from(
      (map).map((o) => RouteForStop.fromMap(o)),
    );
    return routesForStop;
  }

  Map<String, dynamic> toJson() => {
        "routesForStop": routesForStop?.map((e) => e.toJson()).toList(),
      };
}

class RouteForStop {
  String? routeCode;
  String? lineCode;
  String? hidden;
  String? routeDescr;
  String? routeType;
  String? routeDistance;
  String? lineID;
  String? lineDescription;
  String? masterLineCode;

  static RouteForStop fromMap(Map<String, dynamic> map) {
    RouteForStop routeForStop = RouteForStop();
    routeForStop.routeCode = map['RouteCode'];
    routeForStop.lineCode = map['LineCode'];
    routeForStop.hidden = map['hidden'];
    routeForStop.routeDescr = map['RouteDescr'];
    routeForStop.routeType = map['RouteType'];
    routeForStop.routeDistance = map['RouteDistance'];
    routeForStop.lineID = map['LineID'];
    routeForStop.lineDescription = map['LineDescr'];
    routeForStop.masterLineCode = map['MasterLineCode'];
    return routeForStop;
  }

  Map<String, dynamic> toJson() => {
        "RouteCode": routeCode,
        "LineCode": lineCode,
        "hidden": hidden,
        "RouteDescr": routeDescr,
        "RouteType": routeType,
        "RouteDistance": routeDistance,
        "LineID": lineID,
        "LineDescr": lineDescription,
        "MasterLineCode": masterLineCode,
      };
}
