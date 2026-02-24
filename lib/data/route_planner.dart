import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/lines.dart';
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
  final String lineId;
  final String routeDescription;
  final double distanceMeters;

  const RouteEdge({
    required this.fromStopCode,
    required this.toStopCode,
    required this.routeCode,
    required this.lineId,
    required this.routeDescription,
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

    // Try loading from disk cache first so all API calls hit in-memory cache
    final loaded = await Api.tryLoadFromDisk();
    if (loaded) {
      debugPrint('[RoutePlanner] Disk cache loaded, building graph from memory');
    }

    final lines = await repository.getLines();
    final lineRoutes = <(LineData, List<LineRoute>)>[];
    int totalRoutes = 0;

    for (final line in lines) {
      final routes = await repository.getRoutesForLine(line.lineCode);
      lineRoutes.add((line, routes));
      totalRoutes += routes.length;
    }

    int processed = 0;

    for (final (line, routes) in lineRoutes) {
      for (final route in routes) {
        final stops = await repository.getStopsForRoute(route.routeCode);
        _indexStops(stops);
        _addEdgesForRoute(
          routeCode: route.routeCode,
          lineId: line.lineID,
          routeDescription: route.routeDescription,
          stops: stops,
        );
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

  /// Search stops by name/description (for autocomplete).
  List<Stop> searchStopsByName(String query, {int limit = 5}) {
    if (!_graphReady || query.isEmpty) return [];
    final q = query.toLowerCase();
    return _stopsByCode.values
        .where((s) =>
            s.stopDescription.toLowerCase().contains(q) ||
            s.stopDescriptionEng.toLowerCase().contains(q) ||
            s.stopStreet.toLowerCase().contains(q) ||
            s.stopStreetEng.toLowerCase().contains(q))
        .take(limit)
        .toList();
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

  OfflineRouteResult? findBestRoute(
    String startCode,
    String endCode, {
    bool minimizeTransfers = true,
    double transferPenalty = 800.0,
  }) {
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
        double cost = edge.distanceMeters;

        // Add transfer penalty when switching bus lines
        if (minimizeTransfers && cameFrom.containsKey(current)) {
          final prevEdge = cameFrom[current]!;
          if (prevEdge.routeCode != edge.routeCode) {
            cost += transferPenalty;
          }
        }

        final tentative = (gScore[current] ?? double.infinity) + cost;
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
    return _haversineMeters(
        from.stopLat, from.stopLng, to.stopLat, to.stopLng);
  }

  void _indexStops(List<Stop> stops) {
    for (final stop in stops) {
      _stopsByCode.putIfAbsent(stop.stopCode, () => stop);
    }
  }

  void _addEdgesForRoute({
    required String routeCode,
    required String lineId,
    required String routeDescription,
    required List<Stop> stops,
  }) {
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
              lineId: lineId,
              routeDescription: routeDescription,
              distanceMeters: distance,
            ),
          );

      _edgesByStop.putIfAbsent(to.stopCode, () => []).add(
            RouteEdge(
              fromStopCode: to.stopCode,
              toStopCode: from.stopCode,
              routeCode: routeCode,
              lineId: lineId,
              routeDescription: routeDescription,
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
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a.toDouble()), sqrt(1 - a.toDouble()));
    return radius * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180.0);
}
