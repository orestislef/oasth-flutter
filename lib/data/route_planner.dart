import 'dart:collection';
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
  final bool isWalkingEdge;

  const RouteEdge({
    required this.fromStopCode,
    required this.toStopCode,
    required this.routeCode,
    required this.lineId,
    required this.routeDescription,
    required this.distanceMeters,
    this.isWalkingEdge = false,
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

  /// Walking distance threshold for creating transfer edges (meters)
  static const double walkingTransferRadius = 400.0;

  /// Walking speed for cost estimation (~5 km/h = ~1.4 m/s)
  /// We multiply distance by a penalty factor to make walking less desirable
  static const double walkingPenaltyFactor = 3.0;

  bool get isReady => _graphReady;

  /// Statistics for debugging
  int get totalStops => _stopsByCode.length;
  int get totalEdges =>
      _edgesByStop.values.fold(0, (sum, edges) => sum + edges.length);

  /// Get a stop by its code, or null if not found.
  Stop? getStop(String code) => _stopsByCode[code];

  Future<void> buildGraph({
    required OasthRepository repository,
    void Function(RoutePlannerProgress progress)? onProgress,
  }) async {
    if (_graphReady || _building) return;
    _building = true;

    debugPrint('[RoutePlanner] === Starting graph build ===');

    // Try loading from disk cache first
    final loaded = await Api.tryLoadFromDisk();
    if (loaded) {
      debugPrint('[RoutePlanner] Disk cache loaded, building graph from memory');
    } else {
      debugPrint('[RoutePlanner] No disk cache, will fetch from API');
    }

    try {
      final lines = await repository.getLines();
      debugPrint('[RoutePlanner] Loaded ${lines.length} lines');

      if (lines.isEmpty) {
        debugPrint('[RoutePlanner] ERROR: No lines loaded! Cannot build graph.');
        _building = false;
        return;
      }

      final lineRoutes = <(LineData, List<LineRoute>)>[];
      int totalRoutes = 0;

      for (final line in lines) {
        try {
          final routes = await repository.getRoutesForLine(line.lineCode);
          lineRoutes.add((line, routes));
          totalRoutes += routes.length;
        } catch (e) {
          debugPrint(
              '[RoutePlanner] Failed to get routes for line ${line.lineID} (${line.lineCode}): $e');
        }
      }

      debugPrint('[RoutePlanner] Total routes to process: $totalRoutes');

      int processed = 0;
      int emptyRoutes = 0;
      int totalStopsProcessed = 0;

      for (final (line, routes) in lineRoutes) {
        for (final route in routes) {
          try {
            final stops = await repository.getStopsForRoute(route.routeCode);

            if (stops.isEmpty) {
              emptyRoutes++;
            } else {
              totalStopsProcessed += stops.length;
              _indexStops(stops);
              _addEdgesForRoute(
                routeCode: route.routeCode,
                lineId: line.lineID,
                routeDescription: route.routeDescription,
                stops: stops,
              );
            }
          } catch (e) {
            debugPrint(
                '[RoutePlanner] Failed to get stops for route ${route.routeCode}: $e');
          }

          processed++;
          onProgress?.call(
            RoutePlannerProgress(
              processedRoutes: processed,
              totalRoutes: totalRoutes,
            ),
          );
        }
      }

      debugPrint('[RoutePlanner] Route edges built:');
      debugPrint('  - Stops indexed: ${_stopsByCode.length}');
      debugPrint('  - Total stops processed: $totalStopsProcessed');
      debugPrint('  - Empty routes skipped: $emptyRoutes');
      debugPrint(
          '  - Bus edges: ${_edgesByStop.values.fold(0, (int sum, List<RouteEdge> edges) => sum + edges.length)}');

      // Build walking transfer edges between nearby stops
      _buildWalkingEdges();

      debugPrint('[RoutePlanner] === Graph build complete ===');
      debugPrint(
          '  - Total stops: ${_stopsByCode.length}');
      debugPrint(
          '  - Total edges (bus + walking): ${_edgesByStop.values.fold(0, (int sum, List<RouteEdge> edges) => sum + edges.length)}');

      // Print sample stop data for validation
      if (_stopsByCode.isNotEmpty) {
        final sample = _stopsByCode.values.first;
        debugPrint(
            '  - Sample stop: ${sample.stopCode} "${sample.stopDescription}" at (${sample.stopLat}, ${sample.stopLng})');
      }

      // Count stops with valid coordinates
      final validCoordStops = _stopsByCode.values
          .where((s) => s.stopLat != 0.0 || s.stopLng != 0.0)
          .length;
      debugPrint(
          '  - Stops with valid coordinates: $validCoordStops / ${_stopsByCode.length}');

      _graphReady = true;
    } catch (e, stackTrace) {
      debugPrint('[RoutePlanner] ERROR building graph: $e');
      debugPrint('[RoutePlanner] Stack: $stackTrace');
    } finally {
      _building = false;
    }
  }

  /// Build walking edges between stops that are within [walkingTransferRadius].
  /// Uses a grid-based spatial index for efficiency.
  void _buildWalkingEdges() {
    debugPrint('[RoutePlanner] Building walking transfer edges...');

    // Grid cell size in degrees (~400m at Thessaloniki's latitude)
    const gridSize = 0.004;
    final grid = <String, List<Stop>>{};

    // Index all stops with valid coordinates into grid cells
    for (final stop in _stopsByCode.values) {
      if (stop.stopLat == 0.0 && stop.stopLng == 0.0) continue;
      final cellKey =
          '${(stop.stopLat / gridSize).floor()}_${(stop.stopLng / gridSize).floor()}';
      grid.putIfAbsent(cellKey, () => []).add(stop);
    }

    int walkingEdgesAdded = 0;

    // For each stop, check stops in neighboring grid cells
    for (final stop in _stopsByCode.values) {
      if (stop.stopLat == 0.0 && stop.stopLng == 0.0) continue;

      final cellX = (stop.stopLat / gridSize).floor();
      final cellY = (stop.stopLng / gridSize).floor();

      // Check 3x3 neighborhood of grid cells
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final neighborKey = '${cellX + dx}_${cellY + dy}';
          final neighborStops = grid[neighborKey];
          if (neighborStops == null) continue;

          for (final other in neighborStops) {
            if (other.stopCode == stop.stopCode) continue;

            // Check if these stops are on different routes
            // (walking between stops on the same route is pointless)
            if (_stopsShareRoute(stop.stopCode, other.stopCode)) continue;

            final distance = _haversineMeters(
              stop.stopLat,
              stop.stopLng,
              other.stopLat,
              other.stopLng,
            );

            if (distance <= walkingTransferRadius && distance > 0) {
              // Add bidirectional walking edge with penalty
              final walkingCost = distance * walkingPenaltyFactor;

              _edgesByStop.putIfAbsent(stop.stopCode, () => []).add(
                    RouteEdge(
                      fromStopCode: stop.stopCode,
                      toStopCode: other.stopCode,
                      routeCode: 'WALK',
                      lineId: 'WALK',
                      routeDescription: 'Walking transfer',
                      distanceMeters: walkingCost,
                      isWalkingEdge: true,
                    ),
                  );
              walkingEdgesAdded++;
            }
          }
        }
      }
    }

    debugPrint(
        '[RoutePlanner] Walking edges added: $walkingEdgesAdded');
  }

  /// Check if two stops share any bus route (i.e., are already connected).
  bool _stopsShareRoute(String stopCodeA, String stopCodeB) {
    final edgesA = _edgesByStop[stopCodeA];
    if (edgesA == null) return false;

    // Get all routes that stop A is on
    final routesA = <String>{};
    for (final edge in edgesA) {
      if (!edge.isWalkingEdge) routesA.add(edge.routeCode);
    }

    final edgesB = _edgesByStop[stopCodeB];
    if (edgesB == null) return false;

    // Check if stop B shares any route with stop A
    for (final edge in edgesB) {
      if (!edge.isWalkingEdge && routesA.contains(edge.routeCode)) {
        return true;
      }
    }

    return false;
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

    debugPrint(
        '[RoutePlanner] Nearest stop to ($lat, $lng): ${best.stopCode} "${best.stopDescription}" at ${bestDistance.toStringAsFixed(0)}m');

    return best;
  }

  /// Find the N nearest stops to a location (for multi-origin/destination search).
  List<(Stop, double)> findNearestStops(double lat, double lng,
      {int count = 5}) {
    final distances = <(Stop, double)>[];

    for (final stop in _stopsByCode.values) {
      if (stop.stopLat == 0.0 && stop.stopLng == 0.0) continue;
      final distance = _haversineMeters(lat, lng, stop.stopLat, stop.stopLng);
      distances.add((stop, distance));
    }

    distances.sort((a, b) => a.$2.compareTo(b.$2));
    return distances.take(count).toList();
  }

  OfflineRouteResult? findBestRoute(
    String startCode,
    String endCode, {
    bool minimizeTransfers = true,
    double transferPenalty = 800.0,
  }) {
    if (!_graphReady) {
      debugPrint('[RoutePlanner] ERROR: Graph not ready!');
      throw StateError('Route graph is not ready');
    }

    debugPrint('[RoutePlanner] === Finding route: $startCode -> $endCode ===');

    if (!_stopsByCode.containsKey(startCode)) {
      debugPrint('[RoutePlanner] ERROR: Start stop $startCode not in graph');
      return null;
    }
    if (!_stopsByCode.containsKey(endCode)) {
      debugPrint('[RoutePlanner] ERROR: End stop $endCode not in graph');
      return null;
    }

    final startEdges = _edgesByStop[startCode] ?? const [];
    final endEdges = _edgesByStop[endCode] ?? const [];
    debugPrint(
        '[RoutePlanner] Start stop edges: ${startEdges.length}, End stop edges: ${endEdges.length}');

    if (startEdges.isEmpty) {
      debugPrint('[RoutePlanner] ERROR: Start stop has no edges!');
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

    // A* algorithm with priority queue
    final openQueue = SplayTreeMap<double, List<String>>();
    final gScore = <String, double>{startCode: 0.0};
    final fScore = <String, double>{
      startCode: _heuristic(startCode, endCode),
    };
    final cameFrom = <String, RouteEdge>{};
    final closedSet = <String>{};

    void addToQueue(String code, double score) {
      openQueue.putIfAbsent(score, () => []).add(code);
    }

    String? popBest() {
      while (openQueue.isNotEmpty) {
        final bestScore = openQueue.firstKey()!;
        final list = openQueue[bestScore]!;
        final code = list.removeLast();
        if (list.isEmpty) openQueue.remove(bestScore);
        if (!closedSet.contains(code)) return code;
      }
      return null;
    }

    addToQueue(startCode, fScore[startCode]!);

    int nodesExpanded = 0;

    while (openQueue.isNotEmpty) {
      final current = popBest();
      if (current == null) break;

      if (closedSet.contains(current)) continue;
      closedSet.add(current);
      nodesExpanded++;

      if (current == endCode) {
        debugPrint(
            '[RoutePlanner] Route found! Expanded $nodesExpanded nodes.');
        return _reconstructPath(startCode, endCode, cameFrom);
      }

      final edges = _edgesByStop[current] ?? const [];

      for (final edge in edges) {
        if (closedSet.contains(edge.toStopCode)) continue;

        double cost = edge.distanceMeters;

        // Add transfer penalty when switching bus lines
        if (minimizeTransfers && cameFrom.containsKey(current)) {
          final prevEdge = cameFrom[current]!;
          if (prevEdge.routeCode != edge.routeCode &&
              !prevEdge.isWalkingEdge) {
            cost += transferPenalty;
          }
        }

        final tentative = (gScore[current] ?? double.infinity) + cost;
        final previous = gScore[edge.toStopCode] ?? double.infinity;
        if (tentative < previous) {
          cameFrom[edge.toStopCode] = edge;
          gScore[edge.toStopCode] = tentative;
          final f = tentative + _heuristic(edge.toStopCode, endCode);
          fScore[edge.toStopCode] = f;
          addToQueue(edge.toStopCode, f);
        }
      }
    }

    debugPrint(
        '[RoutePlanner] No route found after expanding $nodesExpanded nodes.');
    debugPrint(
        '[RoutePlanner] Closed set size: ${closedSet.length}');

    // Try multi-stop approach: find route between multiple nearby stops
    return _tryMultiStopRoute(
      startCode,
      endCode,
      minimizeTransfers: minimizeTransfers,
      transferPenalty: transferPenalty,
    );
  }

  /// If direct A* fails, try routing between the nearest N stops to both
  /// origin and destination to find any possible connection.
  OfflineRouteResult? _tryMultiStopRoute(
    String startCode,
    String endCode, {
    bool minimizeTransfers = true,
    double transferPenalty = 800.0,
  }) {
    final startStop = _stopsByCode[startCode];
    final endStop = _stopsByCode[endCode];
    if (startStop == null || endStop == null) return null;

    debugPrint('[RoutePlanner] Trying multi-stop fallback...');

    // Find nearest stops to both endpoints
    final nearStart =
        findNearestStops(startStop.stopLat, startStop.stopLng, count: 8);
    final nearEnd =
        findNearestStops(endStop.stopLat, endStop.stopLng, count: 8);

    OfflineRouteResult? bestResult;
    double bestTotalCost = double.infinity;

    for (final (altStart, startWalk) in nearStart) {
      if (startWalk > 1000) continue; // Max 1km walk to start

      for (final (altEnd, endWalk) in nearEnd) {
        if (endWalk > 1000) continue; // Max 1km walk to end
        if (altStart.stopCode == altEnd.stopCode) continue;

        // Quick check: do these stops have edges?
        if ((_edgesByStop[altStart.stopCode] ?? []).isEmpty) continue;

        // Run A* between these alternative stops (without recursion)
        final result = _directAStar(
          altStart.stopCode,
          altEnd.stopCode,
          minimizeTransfers: minimizeTransfers,
          transferPenalty: transferPenalty,
        );

        if (result != null) {
          final totalCost =
              result.totalDistanceMeters + startWalk * 3 + endWalk * 3;
          if (totalCost < bestTotalCost) {
            bestTotalCost = totalCost;
            bestResult = OfflineRouteResult(
              startStop: startStop,
              endStop: endStop,
              edges: result.edges,
              totalDistanceMeters: result.totalDistanceMeters,
            );
          }
        }
      }
    }

    if (bestResult != null) {
      debugPrint(
          '[RoutePlanner] Multi-stop fallback found route with cost ${bestTotalCost.toStringAsFixed(0)}m');
    } else {
      debugPrint('[RoutePlanner] Multi-stop fallback: no route found');
    }

    return bestResult;
  }

  /// Direct A* without the multi-stop fallback (to prevent recursion).
  OfflineRouteResult? _directAStar(
    String startCode,
    String endCode, {
    bool minimizeTransfers = true,
    double transferPenalty = 800.0,
  }) {
    final openQueue = SplayTreeMap<double, List<String>>();
    final gScore = <String, double>{startCode: 0.0};
    final cameFrom = <String, RouteEdge>{};
    final closedSet = <String>{};

    void addToQueue(String code, double score) {
      openQueue.putIfAbsent(score, () => []).add(code);
    }

    String? popBest() {
      while (openQueue.isNotEmpty) {
        final bestScore = openQueue.firstKey()!;
        final list = openQueue[bestScore]!;
        final code = list.removeLast();
        if (list.isEmpty) openQueue.remove(bestScore);
        if (!closedSet.contains(code)) return code;
      }
      return null;
    }

    addToQueue(startCode, _heuristic(startCode, endCode));

    while (openQueue.isNotEmpty) {
      final current = popBest();
      if (current == null) break;

      if (closedSet.contains(current)) continue;
      closedSet.add(current);

      if (current == endCode) {
        return _reconstructPath(startCode, endCode, cameFrom);
      }

      final edges = _edgesByStop[current] ?? const [];

      for (final edge in edges) {
        if (closedSet.contains(edge.toStopCode)) continue;

        double cost = edge.distanceMeters;

        if (minimizeTransfers && cameFrom.containsKey(current)) {
          final prevEdge = cameFrom[current]!;
          if (prevEdge.routeCode != edge.routeCode &&
              !prevEdge.isWalkingEdge) {
            cost += transferPenalty;
          }
        }

        final tentative = (gScore[current] ?? double.infinity) + cost;
        final previous = gScore[edge.toStopCode] ?? double.infinity;
        if (tentative < previous) {
          cameFrom[edge.toStopCode] = edge;
          gScore[edge.toStopCode] = tentative;
          final f = tentative + _heuristic(edge.toStopCode, endCode);
          addToQueue(edge.toStopCode, f);
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
    int safety = 0;
    while (current != startCode && safety < 10000) {
      final edge = cameFrom[current];
      if (edge == null) break;
      edges.add(edge);
      current = edge.fromStopCode;
      safety++;
    }

    final path = edges.reversed.toList();
    final totalDistance = path.fold<double>(
      0.0,
      (sum, edge) => sum + edge.distanceMeters,
    );

    debugPrint('[RoutePlanner] Path reconstructed: ${path.length} edges, '
        '${totalDistance.toStringAsFixed(0)}m total');

    // Log route segments
    String? currentRoute;
    for (final edge in path) {
      if (edge.routeCode != currentRoute) {
        if (edge.isWalkingEdge) {
          debugPrint(
              '  [WALK] ${edge.fromStopCode} -> ${edge.toStopCode} (${edge.distanceMeters.toStringAsFixed(0)}m)');
        } else {
          debugPrint(
              '  [${edge.lineId}] Route ${edge.routeCode}: ${edge.routeDescription}');
        }
        currentRoute = edge.routeCode;
      }
    }

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
    if (from.stopLat == 0.0 && from.stopLng == 0.0) return 0.0;
    if (to.stopLat == 0.0 && to.stopLng == 0.0) return 0.0;
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

      // Forward edge (direction of travel)
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

      // Reverse edge (allows routing in opposite direction)
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

  double _haversineMeters(
      double lat1, double lon1, double lat2, double lon2) {
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
