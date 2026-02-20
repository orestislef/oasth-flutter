import 'package:oasth/api/responses/route_detail_and_stops.dart';

class WebStops {
  final List<Stop> stops;

  const WebStops({required this.stops});

  factory WebStops.fromMap(List<dynamic> data) {
    return WebStops(
      stops: data.map((e) => Stop.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'stops': stops.map((e) => e.toMap()).toList(),
      };
}
