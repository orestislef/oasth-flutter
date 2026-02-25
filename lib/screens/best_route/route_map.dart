import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:oasth/api/responses/bus_location.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/data/oasth_repository.dart';
import 'package:oasth/data/route_planner.dart';
import 'package:oasth/data/route_planner_models.dart';
import 'package:oasth/helpers/app_routes.dart';
import 'package:oasth/helpers/location_helper.dart';
import 'package:oasth/helpers/tile_layer_helper.dart';

class RouteMapView extends StatefulWidget {
  final OfflineRouteResult route;
  final RouteResult result;

  const RouteMapView({
    super.key,
    required this.route,
    required this.result,
  });

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  final MapController _mapController = MapController();
  final _repo = OasthRepository();
  late final Future<Map<String, RouteDetailAndStops>> _routeDetailsFuture;
  List<BusLocationData> _busLocations = [];
  LocationData? _userLocation;

  @override
  void initState() {
    super.initState();
    _routeDetailsFuture = _fetchRouteDetails();
    _fetchBusLocations();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      final location = await LocationHelper.getUserLocation();
      if (mounted && location != null) {
        setState(() {
          _userLocation = location;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchBusLocations() async {
    final segments = _groupEdgesByRoute(widget.route.edges);
    final routeCodes = segments
        .where((s) => !s.isWalking)
        .map((s) => s.routeCode)
        .toSet();

    final allLocations = <BusLocationData>[];
    for (final code in routeCodes) {
      try {
        final locs = await _repo.getBusLocations(code);
        allLocations.addAll(locs);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _busLocations = allLocations);
  }

  void _openFullScreen() {
    context.push(
      AppRoutes.routeMapFull,
      extra: RouteMapFullArgs(route: widget.route, result: widget.result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.map, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'route_map'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _openFullScreen,
                  tooltip: 'view_map'.tr(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: _buildMap(context),
          ),
        ],
      ),
    );
  }

  Future<Map<String, RouteDetailAndStops>> _fetchRouteDetails() async {
    final segments = _groupEdgesByRoute(widget.route.edges);
    final routeCodes = segments
        .where((segment) => !segment.isWalking)
        .map((segment) => segment.routeCode)
        .toSet();
    final detailsByRoute = <String, RouteDetailAndStops>{};

    for (final routeCode in routeCodes) {
      try {
        detailsByRoute[routeCode] =
            await _repo.getRouteDetailsAndStops(routeCode);
      } catch (e) {
        debugPrint('[RouteMap] Failed to load route details $routeCode: $e');
      }
    }

    return detailsByRoute;
  }

  Widget _buildMap(BuildContext context) {
    return FutureBuilder<Map<String, RouteDetailAndStops>>(
      future: _routeDetailsFuture,
      builder: (context, snapshot) {
        return _buildMapWithDetails(context, snapshot.data ?? const {});
      },
    );
  }

  Widget _buildMapWithDetails(
    BuildContext context,
    Map<String, RouteDetailAndStops> detailsByRoute,
  ) {
    final segments = _groupEdgesByRoute(widget.route.edges);
    final polylines = <Polyline>[];
    final markers = <Marker>[];

    // Color palette for different bus lines
    final lineColors = <String, Color>{};
    final colorPalette = [
      Theme.of(context).primaryColor,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.error,
      Theme.of(context).colorScheme.inversePrimary,
    ];
    int colorIndex = 0;

    // Build polylines for each segment
    for (final segment in segments) {
      if (segment.isWalking) {
        final points = _buildSegmentPoints(segment, detailsByRoute);
        if (points.length >= 2) {
          polylines.add(Polyline(
            points: points,
            color: Theme.of(context).colorScheme.tertiary,
            strokeWidth: 3,
            pattern: const StrokePattern.dotted(),
          ));
        }
      } else {
        final color = lineColors.putIfAbsent(segment.lineId, () {
          final c = colorPalette[colorIndex % colorPalette.length];
          colorIndex++;
          return c;
        });

        // Ghost polyline: full bus route at 35% opacity
        final fullPoints = _pointsFromRouteDetails(detailsByRoute[segment.routeCode]);
        if (fullPoints.length >= 2) {
          polylines.add(Polyline(
            points: fullPoints,
            color: color.withAlpha(90),
            strokeWidth: 3,
          ));
        }

        // Riding segment at full opacity
        final points = _buildSegmentPoints(segment, detailsByRoute);
        if (points.length >= 2) {
          polylines.add(Polyline(
            points: points,
            color: color,
            strokeWidth: 5,
          ));
        }
      }
    }

    // Start marker
    final startStop = widget.route.startStop;
    if (startStop.stopLat != 0.0 || startStop.stopLng != 0.0) {
      markers.add(_buildStopMarker(
        context,
        startStop,
        isStart: true,
      ));
    }

    // End marker
    final endStop = widget.route.endStop;
    if (endStop.stopLat != 0.0 || endStop.stopLng != 0.0) {
      markers.add(_buildStopMarker(
        context,
        endStop,
        isEnd: true,
      ));
    }

    // Transfer point markers
    String? prevRoute;
    for (final edge in widget.route.edges) {
      if (prevRoute != null && edge.routeCode != prevRoute) {
        final stop = _findStop(edge.fromStopCode);
        if (stop != null && (stop.stopLat != 0.0 || stop.stopLng != 0.0)) {
          markers.add(_buildTransferMarker(context, stop));
        }
      }
      prevRoute = edge.routeCode;
    }

    // Live bus markers
    for (final bus in _busLocations) {
      if (bus.csLat != 0.0 || bus.csLng != 0.0) {
        final lineId = _lineIdForRouteCode(bus.routeCode, segments);
        final color = lineColors[lineId] ?? Theme.of(context).primaryColor;
        markers.add(_buildBusMarker(context, bus, color, lineId ?? ''));
      }
    }

    // Calculate bounds (only from riding polylines + stop markers, not ghost lines)
    final allPoints = <LatLng>[];
    for (final p in polylines) {
      allPoints.addAll(p.points);
    }
    for (final m in markers) {
      allPoints.add(m.point);
    }

    LatLngBounds? bounds;
    if (allPoints.length >= 2) {
      bounds = LatLngBounds.fromPoints(allPoints);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: bounds?.center ?? const LatLng(40.6401, 22.9444),
        initialZoom: 13,
        onMapReady: () {
          if (bounds != null) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(40),
              ),
            );
          }
        },
      ),
      children: [
        const MapTileLayer(),
        PolylineLayer(polylines: polylines),
        if (_userLocation != null)
          CurrentLocationLayer(
            alignPositionOnUpdate: AlignOnUpdate.never,
            alignDirectionOnUpdate: AlignOnUpdate.never,
            style: LocationMarkerStyle(
              marker: DefaultLocationMarker(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onPrimary,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
              ),
              markerSize: const Size(40, 40),
              markerDirection: MarkerDirection.heading,
            ),
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  String? _lineIdForRouteCode(String routeCode, List<RouteSegment> segments) {
    for (final s in segments) {
      if (s.routeCode == routeCode) return s.lineId;
    }
    return null;
  }

  Marker _buildBusMarker(
      BuildContext context, BusLocationData bus, Color color, String lineId) {
    return Marker(
      point: LatLng(bus.csLat, bus.csLng),
      width: 56,
      height: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withAlpha(80),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 14,
                ),
                const SizedBox(width: 2),
                Text(
                  lineId,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stop? _findStop(String code) {
    if (widget.route.startStop.stopCode == code) return widget.route.startStop;
    if (widget.route.endStop.stopCode == code) return widget.route.endStop;
    return RoutePlanner().getStop(code);
  }

  List<LatLng> _buildSegmentPoints(
    RouteSegment segment,
    Map<String, RouteDetailAndStops> detailsByRoute,
  ) {
    if (segment.stops.isEmpty) return [];
    if (segment.isWalking) return _pointsFromEdges(segment);

    final details = detailsByRoute[segment.routeCode];
    final detailsPoints = _pointsFromRouteDetails(details);
    if (detailsPoints.isEmpty) {
      debugPrint('[route_planner] No route details for ${segment.routeCode}, using edge points');
      return _pointsFromEdges(segment);
    }

    final startStop = _findStop(segment.stops.first.fromStopCode);
    final endStop = _findStop(segment.stops.last.toStopCode);
    if (startStop == null || endStop == null) {
      debugPrint('[route_planner] Missing stops: start=${startStop != null} end=${endStop != null}, returning FULL polyline');
      return detailsPoints;
    }

    final boardLatLng = LatLng(startStop.stopLat, startStop.stopLng);
    final alightLatLng = LatLng(endStop.stopLat, endStop.stopLng);

    // Find nearest polyline point to boarding stop
    int boardIdx = 0;
    double minBoardDist = double.infinity;
    for (int i = 0; i < detailsPoints.length; i++) {
      final d = _distanceMeters(boardLatLng, detailsPoints[i]);
      if (d < minBoardDist) {
        minBoardDist = d;
        boardIdx = i;
      }
    }

    // Find nearest polyline point to alighting stop (only AFTER boarding)
    int alightIdx = detailsPoints.length - 1;
    double minAlightDist = double.infinity;
    for (int i = boardIdx; i < detailsPoints.length; i++) {
      final d = _distanceMeters(alightLatLng, detailsPoints[i]);
      if (d < minAlightDist) {
        minAlightDist = d;
        alightIdx = i;
      }
    }

    debugPrint('[route_planner] Route ${segment.routeCode} (line ${segment.lineId}): '
        'polyline=${detailsPoints.length} pts');
    debugPrint('[route_planner]   boarding=${segment.stops.first.fromStopCode} → polyIdx=$boardIdx (${minBoardDist.toStringAsFixed(0)}m)');
    debugPrint('[route_planner]   alight=${segment.stops.last.toStopCode} → polyIdx=$alightIdx (${minAlightDist.toStringAsFixed(0)}m)');

    if (alightIdx <= boardIdx) {
      debugPrint('[route_planner]   could not trim, using edge points');
      return _pointsFromEdges(segment);
    }

    final trimmed = detailsPoints.sublist(boardIdx, alightIdx + 1);
    debugPrint('[route_planner]   trimmed: ${trimmed.length} of ${detailsPoints.length} pts');
    return trimmed;
  }

  List<LatLng> _pointsFromRouteDetails(RouteDetailAndStops? details) {
    if (details == null || details.details.isEmpty) return [];
    final ordered = details.details.toList()
      ..sort((a, b) {
        final aOrder = int.tryParse(a.routedOrder) ?? 0;
        final bOrder = int.tryParse(b.routedOrder) ?? 0;
        return aOrder.compareTo(bOrder);
      });

    return ordered
        .where((d) => d.routedX != 0.0 || d.routedY != 0.0)
        .map((d) => LatLng(d.routedY, d.routedX))
        .toList();
  }

  List<LatLng> _pointsFromEdges(RouteSegment segment) {
    final points = <LatLng>[];
    for (final edge in segment.stops) {
      final fromStop = _findStop(edge.fromStopCode);
      final toStop = _findStop(edge.toStopCode);
      if (fromStop != null && points.isEmpty) {
        points.add(LatLng(fromStop.stopLat, fromStop.stopLng));
      }
      if (toStop != null) {
        points.add(LatLng(toStop.stopLat, toStop.stopLng));
      }
    }
    return points;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    return const Distance().as(LengthUnit.Meter, a, b);
  }

  Marker _buildStopMarker(BuildContext context, Stop stop,
      {bool isStart = false, bool isEnd = false}) {
    return Marker(
      point: LatLng(stop.stopLat, stop.stopLng),
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: isStart
              ? Theme.of(context).colorScheme.tertiary
              : isEnd
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).colorScheme.surface, width: 3),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withAlpha(64),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isStart
              ? Icons.trip_origin
              : isEnd
                  ? Icons.location_on
                  : Icons.directions_bus,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 20,
        ),
      ),
    );
  }

  Marker _buildTransferMarker(BuildContext context, Stop stop) {
    return Marker(
      point: LatLng(stop.stopLat, stop.stopLng),
      width: 32,
      height: 32,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).colorScheme.surface, width: 2),
        ),
        child: Icon(
          Icons.swap_horiz,
          color: Theme.of(context).colorScheme.onTertiary,
          size: 16,
        ),
      ),
    );
  }

  List<RouteSegment> _groupEdgesByRoute(List<RouteEdge> edges) {
    final segments = <RouteSegment>[];

    for (final edge in edges) {
      if (segments.isEmpty || segments.last.routeCode != edge.routeCode) {
        segments.add(RouteSegment(
          routeCode: edge.routeCode,
          lineId: edge.lineId,
          routeDescription: edge.routeDescription,
          isWalking: edge.isWalkingEdge,
        ));
      }
      segments.last.stops.add(edge);
    }

    return segments;
  }
}

class FullScreenRouteMap extends StatefulWidget {
  final OfflineRouteResult route;
  final RouteResult result;

  const FullScreenRouteMap(
      {super.key, required this.route, required this.result});

  @override
  State<FullScreenRouteMap> createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<FullScreenRouteMap> {
  final MapController _mapController = MapController();
  final _repo = OasthRepository();
  late final Future<Map<String, RouteDetailAndStops>> _routeDetailsFuture;
  List<BusLocationData> _busLocations = [];
  Timer? _busPollTimer;
  LocationData? _userLocation;

  @override
  void initState() {
    super.initState();
    _routeDetailsFuture = _fetchRouteDetails();
    _fetchBusLocations();
    _busPollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchBusLocations(),
    );
    _loadUserLocation();
  }

  @override
  void dispose() {
    _busPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    try {
      final location = await LocationHelper.getUserLocation();
      if (mounted && location != null) {
        setState(() {
          _userLocation = location;
        });
      }
    } catch (_) {}
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      _mapController.move(
        LatLng(_userLocation!.latitude!, _userLocation!.longitude!),
        16.0,
      );
    }
  }

  Future<void> _fetchBusLocations() async {
    final segments = _groupEdgesByRoute(widget.route.edges);
    final routeCodes = segments
        .where((s) => !s.isWalking)
        .map((s) => s.routeCode)
        .toSet();

    final allLocations = <BusLocationData>[];
    for (final code in routeCodes) {
      try {
        final locs = await _repo.getBusLocations(code);
        allLocations.addAll(locs);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _busLocations = allLocations);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('route_map'.tr()),
        actions: [
          if (_userLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _centerOnUserLocation,
              tooltip: 'center_on_location'.tr(),
            ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: _fitBounds,
            tooltip: 'fit_route_to_view'.tr(),
          ),
        ],
      ),
      body: _buildMap(context),
    );
  }

  Future<Map<String, RouteDetailAndStops>> _fetchRouteDetails() async {
    final segments = _groupEdgesByRoute(widget.route.edges);
    final routeCodes = segments
        .where((segment) => !segment.isWalking)
        .map((segment) => segment.routeCode)
        .toSet();
    final detailsByRoute = <String, RouteDetailAndStops>{};

    for (final routeCode in routeCodes) {
      try {
        detailsByRoute[routeCode] =
            await _repo.getRouteDetailsAndStops(routeCode);
      } catch (e) {
        debugPrint('[RouteMap] Failed to load route details $routeCode: $e');
      }
    }

    return detailsByRoute;
  }

  Widget _buildMap(BuildContext context) {
    return FutureBuilder<Map<String, RouteDetailAndStops>>(
      future: _routeDetailsFuture,
      builder: (context, snapshot) {
        return _buildMapWithDetails(context, snapshot.data ?? const {});
      },
    );
  }

  Widget _buildMapWithDetails(
    BuildContext context,
    Map<String, RouteDetailAndStops> detailsByRoute,
  ) {
    final segments = _groupEdgesByRoute(widget.route.edges);
    final polylines = <Polyline>[];
    final markers = <Marker>[];

    final lineColors = <String, Color>{};
    final colorPalette = [
      Theme.of(context).primaryColor,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.error,
      Theme.of(context).colorScheme.inversePrimary,
    ];
    int colorIndex = 0;

    for (final segment in segments) {
      if (segment.isWalking) {
        final points = _buildSegmentPoints(segment, detailsByRoute);
        if (points.length >= 2) {
          polylines.add(Polyline(
            points: points,
            color: Theme.of(context).colorScheme.tertiary,
            strokeWidth: 3,
            pattern: const StrokePattern.dotted(),
          ));
        }
      } else {
        final color = lineColors.putIfAbsent(segment.lineId, () {
          final c = colorPalette[colorIndex % colorPalette.length];
          colorIndex++;
          return c;
        });

        // Ghost polyline: full bus route at 35% opacity
        final fullPoints = _pointsFromRouteDetails(detailsByRoute[segment.routeCode]);
        if (fullPoints.length >= 2) {
          polylines.add(Polyline(
            points: fullPoints,
            color: color.withAlpha(90),
            strokeWidth: 3,
          ));
        }

        // Riding segment at full opacity
        final points = _buildSegmentPoints(segment, detailsByRoute);
        if (points.length >= 2) {
          polylines.add(Polyline(
            points: points,
            color: color,
            strokeWidth: 5,
          ));
        }
      }
    }

    final startStop = widget.route.startStop;
    if (startStop.stopLat != 0.0 || startStop.stopLng != 0.0) {
      markers.add(_buildStopMarker(context, startStop, isStart: true));
    }
    final endStop = widget.route.endStop;
    if (endStop.stopLat != 0.0 || endStop.stopLng != 0.0) {
      markers.add(_buildStopMarker(context, endStop, isEnd: true));
    }

    String? prevRoute;
    for (final edge in widget.route.edges) {
      if (prevRoute != null && edge.routeCode != prevRoute) {
        final stop = _findStop(edge.fromStopCode);
        if (stop != null && (stop.stopLat != 0.0 || stop.stopLng != 0.0)) {
          markers.add(_buildTransferMarker(context, stop));
        }
      }
      prevRoute = edge.routeCode;
    }

    // Live bus markers
    for (final bus in _busLocations) {
      if (bus.csLat != 0.0 || bus.csLng != 0.0) {
        final lineId = _lineIdForRouteCode(bus.routeCode, segments);
        final color = lineColors[lineId] ?? Theme.of(context).primaryColor;
        markers.add(_buildBusMarker(context, bus, color, lineId ?? ''));
      }
    }

    final allPoints = <LatLng>[];
    for (final p in polylines) {
      allPoints.addAll(p.points);
    }
    for (final m in markers) {
      allPoints.add(m.point);
    }

    LatLngBounds? bounds;
    if (allPoints.length >= 2) {
      bounds = LatLngBounds.fromPoints(allPoints);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: bounds?.center ?? const LatLng(40.6401, 22.9444),
        initialZoom: 13,
        onMapReady: () {
          if (bounds != null) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(40),
              ),
            );
          }
        },
      ),
      children: [
        const MapTileLayer(),
        PolylineLayer(polylines: polylines),
        if (_userLocation != null)
          CurrentLocationLayer(
            alignPositionOnUpdate: AlignOnUpdate.never,
            alignDirectionOnUpdate: AlignOnUpdate.never,
            style: LocationMarkerStyle(
              marker: DefaultLocationMarker(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onPrimary,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
              ),
              markerSize: const Size(40, 40),
              markerDirection: MarkerDirection.heading,
            ),
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  String? _lineIdForRouteCode(String routeCode, List<RouteSegment> segments) {
    for (final s in segments) {
      if (s.routeCode == routeCode) return s.lineId;
    }
    return null;
  }

  Marker _buildBusMarker(
      BuildContext context, BusLocationData bus, Color color, String lineId) {
    return Marker(
      point: LatLng(bus.csLat, bus.csLng),
      width: 56,
      height: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withAlpha(80),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 14,
                ),
                const SizedBox(width: 2),
                Text(
                  lineId,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stop? _findStop(String code) {
    if (widget.route.startStop.stopCode == code) return widget.route.startStop;
    if (widget.route.endStop.stopCode == code) return widget.route.endStop;
    return RoutePlanner().getStop(code);
  }

  List<LatLng> _buildSegmentPoints(
    RouteSegment segment,
    Map<String, RouteDetailAndStops> detailsByRoute,
  ) {
    if (segment.stops.isEmpty) return [];
    if (segment.isWalking) return _pointsFromEdges(segment);

    final details = detailsByRoute[segment.routeCode];
    final detailsPoints = _pointsFromRouteDetails(details);
    if (detailsPoints.isEmpty) {
      debugPrint('[route_planner] No route details for ${segment.routeCode}, using edge points');
      return _pointsFromEdges(segment);
    }

    final startStop = _findStop(segment.stops.first.fromStopCode);
    final endStop = _findStop(segment.stops.last.toStopCode);
    if (startStop == null || endStop == null) {
      debugPrint('[route_planner] Missing stops: start=${startStop != null} end=${endStop != null}, returning FULL polyline');
      return detailsPoints;
    }

    final boardLatLng = LatLng(startStop.stopLat, startStop.stopLng);
    final alightLatLng = LatLng(endStop.stopLat, endStop.stopLng);

    // Find nearest polyline point to boarding stop
    int boardIdx = 0;
    double minBoardDist = double.infinity;
    for (int i = 0; i < detailsPoints.length; i++) {
      final d = _distanceMeters(boardLatLng, detailsPoints[i]);
      if (d < minBoardDist) {
        minBoardDist = d;
        boardIdx = i;
      }
    }

    // Find nearest polyline point to alighting stop (only AFTER boarding)
    int alightIdx = detailsPoints.length - 1;
    double minAlightDist = double.infinity;
    for (int i = boardIdx; i < detailsPoints.length; i++) {
      final d = _distanceMeters(alightLatLng, detailsPoints[i]);
      if (d < minAlightDist) {
        minAlightDist = d;
        alightIdx = i;
      }
    }

    debugPrint('[route_planner] Route ${segment.routeCode} (line ${segment.lineId}): '
        'polyline=${detailsPoints.length} pts');
    debugPrint('[route_planner]   boarding=${segment.stops.first.fromStopCode} → polyIdx=$boardIdx (${minBoardDist.toStringAsFixed(0)}m)');
    debugPrint('[route_planner]   alight=${segment.stops.last.toStopCode} → polyIdx=$alightIdx (${minAlightDist.toStringAsFixed(0)}m)');

    if (alightIdx <= boardIdx) {
      debugPrint('[route_planner]   could not trim, using edge points');
      return _pointsFromEdges(segment);
    }

    final trimmed = detailsPoints.sublist(boardIdx, alightIdx + 1);
    debugPrint('[route_planner]   trimmed: ${trimmed.length} of ${detailsPoints.length} pts');
    return trimmed;
  }

  List<LatLng> _pointsFromRouteDetails(RouteDetailAndStops? details) {
    if (details == null || details.details.isEmpty) return [];
    final ordered = details.details.toList()
      ..sort((a, b) {
        final aOrder = int.tryParse(a.routedOrder) ?? 0;
        final bOrder = int.tryParse(b.routedOrder) ?? 0;
        return aOrder.compareTo(bOrder);
      });

    return ordered
        .where((d) => d.routedX != 0.0 || d.routedY != 0.0)
        .map((d) => LatLng(d.routedY, d.routedX))
        .toList();
  }

  List<LatLng> _pointsFromEdges(RouteSegment segment) {
    final points = <LatLng>[];
    for (final edge in segment.stops) {
      final fromStop = _findStop(edge.fromStopCode);
      final toStop = _findStop(edge.toStopCode);
      if (fromStop != null && points.isEmpty) {
        points.add(LatLng(fromStop.stopLat, fromStop.stopLng));
      }
      if (toStop != null) {
        points.add(LatLng(toStop.stopLat, toStop.stopLng));
      }
    }
    return points;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    return const Distance().as(LengthUnit.Meter, a, b);
  }

  Marker _buildStopMarker(BuildContext context, Stop stop,
      {bool isStart = false, bool isEnd = false}) {
    return Marker(
      point: LatLng(stop.stopLat, stop.stopLng),
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: isStart
              ? Theme.of(context).colorScheme.tertiary
              : isEnd
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).colorScheme.surface, width: 3),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withAlpha(64),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isStart
              ? Icons.trip_origin
              : isEnd
                  ? Icons.location_on
                  : Icons.directions_bus,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 20,
        ),
      ),
    );
  }

  Marker _buildTransferMarker(BuildContext context, Stop stop) {
    return Marker(
      point: LatLng(stop.stopLat, stop.stopLng),
      width: 32,
      height: 32,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).colorScheme.surface, width: 2),
        ),
        child: Icon(
          Icons.swap_horiz,
          color: Theme.of(context).colorScheme.onTertiary,
          size: 16,
        ),
      ),
    );
  }

  void _fitBounds() {
    final allPoints = <LatLng>[];
    final startStop = widget.route.startStop;
    final endStop = widget.route.endStop;

    if (startStop.stopLat != 0.0 || startStop.stopLng != 0.0) {
      allPoints.add(LatLng(startStop.stopLat, startStop.stopLng));
    }
    if (endStop.stopLat != 0.0 || endStop.stopLng != 0.0) {
      allPoints.add(LatLng(endStop.stopLat, endStop.stopLng));
    }

    if (allPoints.length >= 2) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(allPoints),
          padding: const EdgeInsets.all(40),
        ),
      );
    }
  }

  List<RouteSegment> _groupEdgesByRoute(List<RouteEdge> edges) {
    final segments = <RouteSegment>[];
    for (final edge in edges) {
      if (segments.isEmpty || segments.last.routeCode != edge.routeCode) {
        segments.add(RouteSegment(
          routeCode: edge.routeCode,
          lineId: edge.lineId,
          routeDescription: edge.routeDescription,
          isWalking: edge.isWalkingEdge,
        ));
      }
      segments.last.stops.add(edge);
    }
    return segments;
  }
}
