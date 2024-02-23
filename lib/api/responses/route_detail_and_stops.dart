class RouteDetailAndStops {
  late List<Details> details;
  late List<Stops> stops;

  static RouteDetailAndStops fromMap(Map<String, dynamic> map) {
    RouteDetailAndStops routeDetailAndStops = RouteDetailAndStops();
    routeDetailAndStops.details = List<Details>.from(
      (map['details'] as List<dynamic>?)?.map((o) => Details.fromMap(o)) ?? [],
    );
    routeDetailAndStops.stops = List<Stops>.from(
      (map['stops'] as List<dynamic>?)?.map((o) => Stops.fromMap(o)) ?? [],
    );
    return routeDetailAndStops;
  }

  Map<String, dynamic> toJson() => {
    "details": details.map((e) => e.toJson()).toList(),
    "stops": stops.map((e) => e.toJson()).toList(),
  };
}

class Stops {
  late String? stopCode;
  late String stopID;
  late String stopDescription;
  late String stopDescriptionEng;
  late String? stopStreet;
  dynamic stopStreetEng;
  late String stopHeading;
  late String stopLat;
  late String stopLng;
  late String routeStopOrder;
  late String stopType;
  late String stopAmea;

  static Stops fromMap(Map<String, dynamic> map) {
    Stops stops = Stops();
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
