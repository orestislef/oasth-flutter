import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:oasth/api/responses/bus_location.dart';
import 'package:oasth/api/responses/lines_with_ml_info.dart';
import 'package:oasth/data/oasth_repository.dart';
import 'package:oasth/helpers/app_routes.dart';
import 'package:oasth/helpers/language_helper.dart';
import 'package:oasth/helpers/location_helper.dart';
import 'package:oasth/helpers/tile_layer_helper.dart';

class FavoritesLiveMapPage extends StatefulWidget {
  const FavoritesLiveMapPage({super.key});

  @override
  State<FavoritesLiveMapPage> createState() => _FavoritesLiveMapPageState();
}

class _FavoritesLiveMapPageState extends State<FavoritesLiveMapPage> {
  final _repo = OasthRepository();
  final MapController _mapController = MapController();
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _error;
  LocationData? _userLocation;
  bool _showPolylines = true;

  // Data
  final Map<String, Color> _lineColors = {};
  final Map<String, String> _lineNames = {};
  final Map<String, List<LatLng>> _routePolylines = {};
  final Map<String, List<String>> _lineRouteCodes = {};
  List<_FavBusMarker> _busMarkers = [];

  static const _palette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadFavoriteData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    try {
      final location = await LocationHelper.getUserLocation();
      if (mounted && location != null) {
        setState(() => _userLocation = location);
      }
    } catch (_) {}
  }

  Future<void> _loadFavoriteData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final favoriteIds = _repo.favorites.favorites;
      if (favoriteIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Get all lines to find matching favorites
      final allLines = await _repo.getLinesWithMLInfo();
      if (!mounted) return;

      final isEn = LanguageHelper.getLanguageUsedInApp(context) == 'en';
      int colorIdx = 0;

      for (final lineId in favoriteIds) {
        final line = allLines.cast<LineWithMasterLineInfo?>().firstWhere(
              (l) => l!.lineId == lineId,
              orElse: () => null,
            );
        if (line == null) continue;

        _lineColors[lineId] = _palette[colorIdx % _palette.length];
        _lineNames[lineId] = isEn
            ? line.lineDescriptionEng.isNotEmpty
                ? line.lineDescriptionEng
                : line.lineDescription
            : line.lineDescription.isNotEmpty
                ? line.lineDescription
                : line.lineDescriptionEng;
        colorIdx++;

        // Get routes for this line
        try {
          final routes = await _repo.getRoutesForLine(line.lineCode);
          final routeCodes =
              routes.map((r) => r.routeCode).toList();
          _lineRouteCodes[lineId] = routeCodes;

          // Get polyline for the first route
          if (routeCodes.isNotEmpty) {
            try {
              final routeData =
                  await _repo.getRouteDetailsAndStops(routeCodes.first);
              final points = routeData.details
                  .map((d) => LatLng(d.routedY, d.routedX))
                  .toList();
              if (points.isNotEmpty) {
                _routePolylines[lineId] = points;
              }
            } catch (_) {}
          }
        } catch (_) {}
      }

      if (!mounted) return;

      await _refreshBusLocations();

      // Auto-refresh every 10 seconds
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted) _refreshBusLocations();
      });

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshBusLocations() async {
    final markers = <_FavBusMarker>[];

    for (final entry in _lineRouteCodes.entries) {
      final lineId = entry.key;
      final color = _lineColors[lineId] ?? Colors.grey;

      for (final routeCode in entry.value) {
        try {
          final buses = await _repo.getBusLocations(routeCode);
          for (final bus in buses) {
            markers.add(_FavBusMarker(
              bus: bus,
              lineId: lineId,
              color: color,
            ));
          }
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() => _busMarkers = markers);
    }
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      _mapController.move(
        LatLng(_userLocation!.latitude!, _userLocation!.longitude!),
        14.0,
      );
    }
  }

  void _fitAllBuses() {
    final points = <LatLng>[];
    for (final m in _busMarkers) {
      points.add(LatLng(m.bus.csLat, m.bus.csLng));
    }
    if (_userLocation != null) {
      points.add(
          LatLng(_userLocation!.latitude!, _userLocation!.longitude!));
    }
    if (points.length >= 2) {
      _mapController.fitCamera(CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(50),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteIds = _repo.favorites.favorites;

    return Scaffold(
      appBar: AppBar(
        title: Text('favorites_live_map'.tr()),
        actions: [
          if (_busMarkers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.fit_screen),
              onPressed: _fitAllBuses,
              tooltip: 'fit_route_to_view'.tr(),
            ),
        ],
      ),
      body: favoriteIds.isEmpty
          ? _buildEmptyState(context)
          : _isLoading
              ? _buildLoadingState(context)
              : _error != null
                  ? _buildErrorState(context)
                  : _buildMapContent(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 24),
            Text(
              'no_favorites_for_map'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'no_favorites_for_map_desc'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.go(AppRoutes.homeTab,
                    extra: const HomeArgs(currentIndex: 1));
              },
              icon: const Icon(Icons.route),
              label: Text('go_to_lines'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'loading_favorites_map'.tr(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 24),
            Text(_error!, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFavoriteData,
              icon: const Icon(Icons.refresh),
              label: Text('try_again'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation != null
                ? LatLng(
                    _userLocation!.latitude!, _userLocation!.longitude!)
                : const LatLng(40.6401, 22.9444), // Thessaloniki center
            initialZoom: 13.0,
          ),
          children: [
            const MapTileLayer(),
            // Route polylines
            if (_showPolylines)
              PolylineLayer(
                polylines: _routePolylines.entries.map((entry) {
                  return Polyline(
                    points: entry.value,
                    strokeWidth: 3.0,
                    color: (_lineColors[entry.key] ?? Colors.grey)
                        .withValues(alpha: .6),
                  );
                }).toList(),
              ),
            // User location
            if (_userLocation != null)
              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 14,
                    ),
                  ),
                  markerSize: const Size(24, 24),
                  accuracyCircleColor:
                      Theme.of(context).primaryColor.withValues(alpha: .1),
                  headingSectorColor:
                      Theme.of(context).primaryColor.withValues(alpha: .3),
                ),
              ),
            // Bus markers
            MarkerLayer(
              markers: _busMarkers.map((m) {
                return Marker(
                  width: 36,
                  height: 36,
                  point: LatLng(m.bus.csLat, m.bus.csLng),
                  child: Container(
                    decoration: BoxDecoration(
                      color: m.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // Legend
        Positioned(
          bottom: 16,
          left: 16,
          child: _buildLegend(context),
        ),
        // FABs
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_userLocation != null)
                FloatingActionButton.small(
                  heroTag: 'center_location',
                  onPressed: _centerOnUserLocation,
                  tooltip: 'center_on_location'.tr(),
                  child: const Icon(Icons.my_location),
                ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'toggle_polylines',
                onPressed: () {
                  setState(() => _showPolylines = !_showPolylines);
                },
                tooltip: 'toggle_routes'.tr(),
                child: Icon(
                    _showPolylines ? Icons.route : Icons.route_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    if (_lineColors.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'legend'.tr(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            ..._lineColors.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: entry.value,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(
                        _lineNames[entry.key] ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Bus count
            const SizedBox(height: 4),
            Text(
              '${_busMarkers.length} ${'buses'.tr()}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavBusMarker {
  final BusLocationData bus;
  final String lineId;
  final Color color;

  _FavBusMarker({
    required this.bus,
    required this.lineId,
    required this.color,
  });
}
