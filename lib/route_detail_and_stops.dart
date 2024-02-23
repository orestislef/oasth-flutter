class RouteDetailAndStops {
  late List<DetailsBean> details;
  late List<StopsBean> stops;

  static RouteDetailAndStops fromMap(Map<String, dynamic> map) {
    RouteDetailAndStops routeDetailAndStopsBean = RouteDetailAndStops();
    routeDetailAndStopsBean.details = List<DetailsBean>.from(
      (map['details'] as List<dynamic>?)?.map((o) => DetailsBean.fromMap(o)) ?? [],
    );
    routeDetailAndStopsBean.stops = List<StopsBean>.from(
      (map['stops'] as List<dynamic>?)?.map((o) => StopsBean.fromMap(o)) ?? [],
    );
    return routeDetailAndStopsBean;
  }

  Map<String, dynamic> toJson() => {
    "details": details.map((e) => e.toJson()).toList(),
    "stops": stops.map((e) => e.toJson()).toList(),
  };
}

class StopsBean {
  late String stopCode;
  late String stopID;
  late String stopDescr;
  late String stopDescrEng;
  late String? stopStreet;
  dynamic stopStreetEng;
  late String stopHeading;
  late String stopLat;
  late String stopLng;
  late String routeStopOrder;
  late String stopType;
  late String stopAmea;

  static StopsBean fromMap(Map<String, dynamic> map) {
    StopsBean stopsBean = StopsBean();
    stopsBean.stopCode = map['StopCode'];
    stopsBean.stopID = map['StopID'];
    stopsBean.stopDescr = map['StopDescr'];
    stopsBean.stopDescrEng = map['StopDescrEng'];
    stopsBean.stopStreet = map['StopStreet'];
    stopsBean.stopStreetEng = map['StopStreetEng'];
    stopsBean.stopHeading = map['StopHeading'];
    stopsBean.stopLat = map['StopLat'];
    stopsBean.stopLng = map['StopLng'];
    stopsBean.routeStopOrder = map['RouteStopOrder'];
    stopsBean.stopType = map['StopType'];
    stopsBean.stopAmea = map['StopAmea'];
    return stopsBean;
  }

  Map<String, dynamic> toJson() => {
    "StopCode": stopCode,
    "StopID": stopID,
    "StopDescr": stopDescr,
    "StopDescrEng": stopDescrEng,
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

class DetailsBean {
  late String routedX;
  late String routedY;
  late String routedOrder;

  static DetailsBean fromMap(Map<String, dynamic> map) {
    DetailsBean detailsBean = DetailsBean();
    detailsBean.routedX = map['routed_x'];
    detailsBean.routedY = map['routed_y'];
    detailsBean.routedOrder = map['routed_order'];
    return detailsBean;
  }

  Map<String, dynamic> toJson() => {
    "routed_x": routedX,
    "routed_y": routedY,
    "routed_order": routedOrder,
  };
}
