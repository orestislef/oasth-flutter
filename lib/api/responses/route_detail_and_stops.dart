class RouteDetailAndStops {
  final List<Details> details;
  final List<Stop> stops;

  const RouteDetailAndStops({required this.details, required this.stops});

  factory RouteDetailAndStops.fromMap(Map<String, dynamic> map) {
    return RouteDetailAndStops(
      details: (map['details'] as List<dynamic>?)
              ?.map((o) => Details.fromMap(o))
              .toList() ??
          [],
      stops: (map['stops'] as List<dynamic>?)
              ?.map((o) => Stop.fromMap(o))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() => {
        'details': details.map((e) => e.toMap()).toList(),
        'stops': stops.map((e) => e.toMap()).toList(),
      };
}

class Stop {
  final String stopCode;
  final String stopID;
  final String stopDescription;
  final String stopDescriptionEng;
  final String stopStreet;
  final String stopStreetEng;
  final String stopHeading;
  final double stopLat;
  final double stopLng;
  final String routeStopOrder;
  final String stopType;
  final String stopAmea;

  const Stop({
    required this.stopCode,
    required this.stopID,
    required this.stopDescription,
    required this.stopDescriptionEng,
    required this.stopStreet,
    required this.stopStreetEng,
    required this.stopHeading,
    required this.stopLat,
    required this.stopLng,
    required this.routeStopOrder,
    required this.stopType,
    required this.stopAmea,
  });

  factory Stop.fromMap(Map<String, dynamic> map) {
    return Stop(
      stopCode: map['StopCode']?.toString() ?? '',
      stopID: map['StopID']?.toString() ?? '',
      stopDescription: map['StopDescr']?.toString() ?? '',
      stopDescriptionEng: map['StopDescrEng']?.toString() ?? '',
      stopStreet: map['StopStreet']?.toString() ?? '',
      stopStreetEng: map['StopStreetEng']?.toString() ?? '',
      stopHeading: map['StopHeading']?.toString() ?? '',
      stopLat: double.tryParse(map['StopLat']?.toString() ?? '') ?? 0.0,
      stopLng: double.tryParse(map['StopLng']?.toString() ?? '') ?? 0.0,
      routeStopOrder: map['RouteStopOrder']?.toString() ?? '',
      stopType: map['StopType']?.toString() ?? '',
      stopAmea: map['StopAmea']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'StopCode': stopCode,
        'StopID': stopID,
        'StopDescr': stopDescription,
        'StopDescrEng': stopDescriptionEng,
        'StopStreet': stopStreet,
        'StopStreetEng': stopStreetEng,
        'StopHeading': stopHeading,
        'StopLat': stopLat.toString(),
        'StopLng': stopLng.toString(),
        'RouteStopOrder': routeStopOrder,
        'StopType': stopType,
        'StopAmea': stopAmea,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Stop && stopCode == other.stopCode;

  @override
  int get hashCode => stopCode.hashCode;

  @override
  String toString() => 'Stop($stopCode: $stopDescription)';
}

class Details {
  final double routedX;
  final double routedY;
  final String routedOrder;

  const Details({
    required this.routedX,
    required this.routedY,
    required this.routedOrder,
  });

  factory Details.fromMap(Map<String, dynamic> map) {
    return Details(
      routedX: double.tryParse(map['routed_x']?.toString() ?? '') ?? 0.0,
      routedY: double.tryParse(map['routed_y']?.toString() ?? '') ?? 0.0,
      routedOrder: map['routed_order']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'routed_x': routedX.toString(),
        'routed_y': routedY.toString(),
        'routed_order': routedOrder,
      };
}
