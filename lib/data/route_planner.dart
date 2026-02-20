import 'dart:math';

import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/routes_for_line.dart';
import 'package:oasth/data/oasth_repository.dart';

class RoutePlannerProgress {
  final int processedRoutes;
  final int totalRoutes;

  const RoutePlannerProgress({
    required this.processedRoutes,
    required this.totalRoutes,
  });
}

class RouteEdge {
  final String fromStopCode;
  final String toStopCode;
  final String routeCode;
  final double distanceMeters;

  const RouteEdge({
    required this.fromStopCode,
    required this.toStopCode,
    required this.routeCode,
    required this.distanceMeters,
  });
}

class OfflineRouteResult {
  final Stop startStop;
  final Stop endStop;
  final List<RouteEdge> edges;
  final double totalDistanceMeters;

  const OfflineRouteResult({
    required this.startStop,
    required this.endStop,
    required this.edges,
    required this.totalDistanceMeters,
  });
}

class RoutePlanner {
  static final RoutePlanner _instance = RoutePlanner._();
  factory RoutePlanner() => _instance;
  RoutePlanner._();

  final Map<String, Stop> _stopsByCode = {};
  final Map<String, List<RouteEdge>> _edgesByStop = {};
  bool _graphReady = false;
  bool _building = false;

  bool get isReady => _graphReady;

  Future<void> buildGraph({
    required OasthRepository repository,
    void Function(RoutePlannerProgress progress)? onProgress,
  }) async {
    if (_graphReady || _building) return;
    _building = true;

    final lines = await repository.getLines();
    final Map<String, List<LineRoute>> routesByLine = {};
    int totalRoutes = 0;

    for (final line in lines) {
      final routes = await repository.getRoutesForLine(line.lineCode);
      routesByLine[line.lineCode] = routes;
      totalRoutes += routes.length;
    }

    int processed = 0;

    for (final entry in routesByLine.entries) {
      for (final route in entry.value) {
        final stops = await repository.getStopsForRoute(route.routeCode);
        _indexStops(stops);
        _addEdgesForRoute(route.routeCode, stops);
        processed++;
        onProgress?.call(
          RoutePlannerProgress(
            processedRoutes: processed,
            totalRoutes: totalRoutes,
          ),
        );
      }
    }

    _graphReady = true;
    _building = false;
  }

  Stop findNearestStop(double lat, double lng) {
    Stop? best;
    double bestDistance = double.infinity;

    for (final stop in _stopsByCode.values) {
      if (stop.stopLat == 0.0 && stop.stopLng == 0.0) continue;
      final distance = _haversineMeters(lat, lng, stop.stopLat, stop.stopLng);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = stop;
      }
    }

    if (best == null) {
      throw StateError('No stops available for routing');
    }

    return best;
  }

  OfflineRouteResult? findBestRoute(String startCode, String endCode) {
    if (!_graphReady) {
      throw StateError('Route graph is not ready');
    }

    if (!_stopsByCode.containsKey(startCode) ||
        !_stopsByCode.containsKey(endCode)) {
      return null;
    }

    if (startCode == endCode) {
      return OfflineRouteResult(
        startStop: _stopsByCode[startCode]!,
        endStop: _stopsByCode[endCode]!,
        edges: const [],
        totalDistanceMeters: 0.0,
      );
    }

    final openSet = <String>{startCode};
    final gScore = <String, double>{startCode: 0.0};
    final fScore = <String, double>{
      startCode: _heuristic(startCode, endCode),
    };
    final cameFrom = <String, RouteEdge>{};

    while (openSet.isNotEmpty) {
      String current = openSet.first;
      double currentScore = fScore[current] ?? double.infinity;
      for (final node in openSet) {
        final score = fScore[node] ?? double.infinity;
        if (score < currentScore) {
          current = node;
          currentScore = score;
        }
      }

      if (current == endCode) {
        return _reconstructPath(startCode, endCode, cameFrom);
      }

      openSet.remove(current);
      final edges = _edgesByStop[current] ?? const [];

      for (final edge in edges) {
        final tentative =
            (gScore[current] ?? double.infinity) + edge.distanceMeters;
        final previous = gScore[edge.toStopCode] ?? double.infinity;
        if (tentative < previous) {
          cameFrom[edge.toStopCode] = edge;
          gScore[edge.toStopCode] = tentative;
          fScore[edge.toStopCode] =
              tentative + _heuristic(edge.toStopCode, endCode);
          openSet.add(edge.toStopCode);
        }
      }
    }

    return null;
  }

  OfflineRouteResult _reconstructPath(
    String startCode,
    String endCode,
    Map<String, RouteEdge> cameFrom,
  ) {
    final edges = <RouteEdge>[];
    String current = endCode;
    while (current != startCode) {
      final edge = cameFrom[current];
      if (edge == null) break;
      edges.add(edge);
      current = edge.fromStopCode;
    }

    final path = edges.reversed.toList();
    final totalDistance = path.fold<double>(
      0.0,
      (sum, edge) => sum + edge.distanceMeters,
    );

    return OfflineRouteResult(
      startStop: _stopsByCode[startCode]!,
      endStop: _stopsByCode[endCode]!,
      edges: path,
      totalDistanceMeters: totalDistance,
    );
  }

  double _heuristic(String fromCode, String toCode) {
    final from = _stopsByCode[fromCode];
    final to = _stopsByCode[toCode];
    if (from == null || to == null) return 0.0;
    return _haversineMeters(from.stopLat, from.stopLng, to.stopLat, to.stopLng);
  }

  void _indexStops(List<Stop> stops) {
    for (final stop in stops) {
      _stopsByCode.putIfAbsent(stop.stopCode, () => stop);
    }
  }

  void _addEdgesForRoute(String routeCode, List<Stop> stops) {
    if (stops.length < 2) return;

    for (var i = 0; i < stops.length - 1; i++) {
      final from = stops[i];
      final to = stops[i + 1];
      final distance = _haversineMeters(
        from.stopLat,
        from.stopLng,
        to.stopLat,
        to.stopLng,
      );

      _edgesByStop.putIfAbsent(from.stopCode, () => []).add(
            RouteEdge(
              fromStopCode: from.stopCode,
              toStopCode: to.stopCode,
              routeCode: routeCode,
              distanceMeters: distance,
            ),
          );

      _edgesByStop.putIfAbsent(to.stopCode, () => []).add(
            RouteEdge(
              fromStopCode: to.stopCode,
              toStopCode: from.stopCode,
              routeCode: routeCode,
              distanceMeters: distance,
            ),
          );
    }
  }

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a.toDouble()), sqrt(1 - a.toDouble()));
    return radius * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180.0);
}
