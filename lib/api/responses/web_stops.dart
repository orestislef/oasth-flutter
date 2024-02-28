import 'package:oasth/api/responses/route_detail_and_stops.dart';

class WebStops{
  final List<Stop> stops;

  WebStops({required this.stops});

  factory WebStops.fromMap(List<dynamic> data) {
    List<Stop> stops = [];
    for (var stop in data) {
      stops.add(Stop.fromMap(stop));
    }
    return WebStops(stops: stops);
  }

  Map<String, dynamic> toJson() => {
    "stops": stops.map((e) => e.toJson()).toList(),
  };
}