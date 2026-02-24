import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/data/route_planner.dart';
import 'package:oasth/data/route_planner_models.dart';

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

  void _openFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenMap(
          route: widget.route,
          result: widget.result,
        ),
      ),
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

  Widget _buildMap(BuildContext context) {
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

      if (points.length >= 2) {
        if (segment.isWalking) {
          // Dashed walking line
          polylines.add(Polyline(
            points: points,
            color: Theme.of(context).colorScheme.tertiary,
            strokeWidth: 3,
            pattern: const StrokePattern.dotted(),
          ));
        } else {
          // Bus route line
          final color = lineColors.putIfAbsent(segment.lineId, () {
            final c = colorPalette[colorIndex % colorPalette.length];
            colorIndex++;
            return c;
          });

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

    // Calculate bounds
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
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.lefkaditishub.oasth',
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Stop? _findStop(String code) {
    if (widget.route.startStop.stopCode == code) return widget.route.startStop;
    if (widget.route.endStop.stopCode == code) return widget.route.endStop;
    return RoutePlanner().getStop(code);
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

class _FullScreenMap extends StatefulWidget {
  final OfflineRouteResult route;
  final RouteResult result;

  const _FullScreenMap({required this.route, required this.result});

  @override
  State<_FullScreenMap> createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<_FullScreenMap> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('route_map'.tr()),
        actions: [
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

  Widget _buildMap(BuildContext context) {
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

      if (points.length >= 2) {
        if (segment.isWalking) {
          polylines.add(Polyline(
            points: points,
            color: Theme.of(context).colorScheme.tertiary,
            strokeWidth: 3,
            pattern: const StrokePattern.dotted(),
          ));
        } else {
          final color = lineColors.putIfAbsent(segment.lineId, () {
            final c = colorPalette[colorIndex % colorPalette.length];
            colorIndex++;
            return c;
          });
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
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.lefkaditishub.oasth',
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Stop? _findStop(String code) {
    if (widget.route.startStop.stopCode == code) return widget.route.startStop;
    if (widget.route.endStop.stopCode == code) return widget.route.endStop;
    return RoutePlanner().getStop(code);
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
