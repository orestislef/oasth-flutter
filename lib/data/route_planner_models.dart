import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/data/route_planner.dart';

class RoutePreferences {
  final bool minimizeTransfers;
  final int maxWalkingDistance;
  final bool preferAccessibility;

  const RoutePreferences({
    this.minimizeTransfers = true,
    this.maxWalkingDistance = 500,
    this.preferAccessibility = false,
  });

  RoutePreferences copyWith({
    bool? minimizeTransfers,
    int? maxWalkingDistance,
    bool? preferAccessibility,
  }) {
    return RoutePreferences(
      minimizeTransfers: minimizeTransfers ?? this.minimizeTransfers,
      maxWalkingDistance: maxWalkingDistance ?? this.maxWalkingDistance,
      preferAccessibility: preferAccessibility ?? this.preferAccessibility,
    );
  }
}

class SavedPlace {
  final String name;
  final double latitude;
  final double longitude;
  final String? stopCode;

  const SavedPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.stopCode,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'stopCode': stopCode ?? '',
      };

  factory SavedPlace.fromMap(Map<String, dynamic> map) => SavedPlace(
        name: map['name'] as String? ?? '',
        latitude: double.tryParse(map['latitude']?.toString() ?? '') ?? 0,
        longitude: double.tryParse(map['longitude']?.toString() ?? '') ?? 0,
        stopCode: (map['stopCode'] as String?)?.isNotEmpty == true
            ? map['stopCode'] as String
            : null,
      );
}

class RouteResult {
  final Stop? nearestStartStop;
  final Stop? nearestEndStop;
  final OfflineRouteResult? route;
  final String? error;
  final bool isLoading;

  const RouteResult({
    this.nearestStartStop,
    this.nearestEndStop,
    this.route,
    this.error,
    this.isLoading = false,
  });

  RouteResult copyWith({
    Stop? nearestStartStop,
    Stop? nearestEndStop,
    OfflineRouteResult? route,
    String? error,
    bool? isLoading,
    bool clearError = false,
    bool clearRoute = false,
  }) {
    return RouteResult(
      nearestStartStop: nearestStartStop ?? this.nearestStartStop,
      nearestEndStop: nearestEndStop ?? this.nearestEndStop,
      route: clearRoute ? null : (route ?? this.route),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RouteSegment {
  final String routeCode;
  final String lineId;
  final String routeDescription;
  final List<RouteEdge> stops = [];

  RouteSegment({
    required this.routeCode,
    required this.lineId,
    required this.routeDescription,
  });
}
