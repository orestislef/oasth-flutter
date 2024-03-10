class RouteDetailAndStops {
  late List<Details> details;
  late List<Stop> stops;

  static RouteDetailAndStops fromMap(Map<String, dynamic> map) {
    RouteDetailAndStops routeDetailAndStops = RouteDetailAndStops();
    routeDetailAndStops.details = List<Details>.from(
      (map['details'] as List<dynamic>?)?.map((o) => Details.fromMap(o)) ?? [],
    );
    routeDetailAndStops.stops = List<Stop>.from(
      (map['stops'] as List<dynamic>?)?.map((o) => Stop.fromMap(o)) ?? [],
    );
    return routeDetailAndStops;
  }

  Map<String, dynamic> toJson() => {
        "details": details.map((e) => e.toJson()).toList(),
        "stops": stops.map((e) => e.toJson()).toList(),
      };
}

class Stop {
  String? stopCode;
  String? stopID;
  String? stopDescription;
  String? stopDescriptionEng;
  String?  stopStreet;
  String?  stopStreetEng;
  String? stopHeading;
  String? stopLat;
  String? stopLng;
  String? routeStopOrder;
  String? stopType;
  String? stopAmea;

  static Stop fromMap(Map<String, dynamic> map) {
    Stop stops = Stop();
    stops.stopCode = map['StopCode'];
    stops.stopID = map['StopID'];
    stops.stopDescription = map['StopDescr'];
    stops.stopDescriptionEng = map['StopDescrEng'];
    stops.stopStreet = map['StopStreet'];
    stops.stopStreetEng = map['StopStreetEng'];
    stops.stopHeading = map['StopHeading'];
    stops.stopLat = map['StopLat'];
    stops.stopLng = map['StopLng'];
    stops.routeStopOrder = map['RouteStopOrder'];
    stops.stopType = map['StopType'];
    stops.stopAmea = map['StopAmea'];
    return stops;
  }

  Map<String, dynamic> toJson() => {
        "StopCode": stopCode,
        "StopID": stopID,
        "StopDescr": stopDescription,
        "StopDescrEng": stopDescriptionEng,
        "StopStreet": stopStreet,
        "StopStreetEng": stopStreetEng,
        "StopHeading": stopHeading,
        "StopLat": stopLat,
        "StopLng": stopLng,
        "RouteStopOrder": routeStopOrder,
        "StopType": stopType,
        "StopAmea": stopAmea,
      };
}

class Details {
  late String routedX;
  late String routedY;
  late String routedOrder;

  static Details fromMap(Map<String, dynamic> map) {
    Details details = Details();
    details.routedX = map['routed_x'];
    details.routedY = map['routed_y'];
    details.routedOrder = map['routed_order'];
    return details;
  }

  Map<String, dynamic> toJson() => {
        "routed_x": routedX,
        "routed_y": routedY,
        "routed_order": routedOrder,
      };
}
