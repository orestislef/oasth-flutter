import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/helpers/language_helper.dart';
import 'package:oasth/helpers/location_helper.dart';
import 'package:oasth/helpers/text_broadcaster.dart';
import 'package:oasth/screens/stop_page.dart';

import '../api/responses/route_detail_and_stops.dart';

class MapWithNearbyStations extends StatefulWidget {
  const MapWithNearbyStations({super.key, this.hasBackButton = false});

  final bool hasBackButton;

  @override
  State<MapWithNearbyStations> createState() => _MapWithNearbyStationsState();
}

class _MapWithNearbyStationsState extends State<MapWithNearbyStations> {
  final MapController _mapController = MapController();
  LocationData? _userLocation;
  List<Stop> _allStops = [];
  List<Stop> _nearbyStops = [];
  bool _showOnlyNearby = false;
  bool _isLoadingLocation = true;
  bool _isLoadingStops = true;
  String? _errorMessage;
  double _searchRadius = 1000; // meters

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadMapData() async {
    await Future.wait([
      _loadUserLocation(),
      _loadStops(),
    ]);
  }

  Future<void> _loadUserLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
        _errorMessage = null;
      });

      final location = await LocationHelper.getUserLocation();
      
      if (mounted) {
        setState(() {
          _userLocation = location;
          _isLoadingLocation = false;
        });
        
        if (location != null) {
          _updateNearbyStops();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _errorMessage = 'location_error'.tr();
        });
      }
    }
  }

  Future<void> _loadStops() async {
    try {
      setState(() {
        _isLoadingStops = true;
        _errorMessage = null;
      });

      final stops = await Api.getAllStops2();
      
      if (mounted) {
        setState(() {
          _allStops = stops;
          _isLoadingStops = false;
        });
        
        _updateNearbyStops();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStops = false;
          _errorMessage = 'stops_loading_error'.tr();
        });
      }
    }
  }

  void _updateNearbyStops() {
    if (_userLocation == null || _allStops.isEmpty) return;

    final userLatLng = LatLng(_userLocation!.latitude!, _userLocation!.longitude!);
    final distance = const Distance();

    _nearbyStops = _allStops.where((stop) {
      final stopLatLng = LatLng(
        double.parse(stop.stopLat!),
        double.parse(stop.stopLng!),
      );
      return distance.as(LengthUnit.Meter, userLatLng, stopLatLng) <= _searchRadius;
    }).toList();

    // Sort by distance
    _nearbyStops.sort((a, b) {
      final distanceA = distance.as(
        LengthUnit.Meter,
        userLatLng,
        LatLng(double.parse(a.stopLat!), double.parse(a.stopLng!)),
      );
      final distanceB = distance.as(
        LengthUnit.Meter,
        userLatLng,
        LatLng(double.parse(b.stopLat!), double.parse(b.stopLng!)),
      );
      return distanceA.compareTo(distanceB);
    });

    setState(() {});
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      _mapController.move(
        LatLng(_userLocation!.latitude!, _userLocation!.longitude!),
        16.0,
      );
    }
  }

  void _toggleNearbyFilter() {
    setState(() {
      _showOnlyNearby = !_showOnlyNearby;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hasBackButton ? _buildAppBar(context) : null,
      body: Stack(
        children: [
          _buildMapContent(context),
          _buildTopControls(context),
          if (_isLoadingLocation || _isLoadingStops) _buildLoadingOverlay(context),
          if (_errorMessage != null) _buildErrorOverlay(context),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    if (!widget.hasBackButton) return null;
    
    return AppBar(
      title: Text('nearby_stops_map'.tr()),
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showMapInfoDialog,
          tooltip: 'map_info'.tr(),
        ),
      ],
    );
  }

  Widget _buildMapContent(BuildContext context) {
    final stopsToShow = _showOnlyNearby ? _nearbyStops : _allStops;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialRotation: _userLocation?.heading ?? 0.0,
        maxZoom: 18.0,
        minZoom: 8.0,
        initialCenter: LatLng(
          _userLocation?.latitude ?? 40.629269,
          _userLocation?.longitude ?? 22.947412,
        ),
        initialZoom: _userLocation != null ? 16.0 : 12.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.oasth.oast',
          errorTileCallback: (tile, error, stackTrace) {
            // Handle tile loading errors gracefully
          },
        ),
        if (_userLocation != null)
          CurrentLocationLayer(
            alignPositionOnUpdate: AlignOnUpdate.once,
            alignDirectionOnUpdate: AlignOnUpdate.once,
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
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            rotate: false,
            maxZoom: 15.0,
            size: const Size(40, 40),
            markers: _buildMarkers(stops: stopsToShow),
            builder: (context, markers) => _buildClusterMarker(context, markers),
          ),
        ),
      ],
    );
  }

  Widget _buildTopControls(BuildContext context) {
    if (widget.hasBackButton) return const SizedBox.shrink();
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          if (widget.hasBackButton)
            Card(
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.adaptive.arrow_back),
                tooltip: 'back'.tr(),
              ),
            ),
          const Spacer(),
          _buildFilterChip(context),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showOnlyNearby ? Icons.location_on : Icons.location_off,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              _showOnlyNearby 
                  ? 'nearby_only'.tr(namedArgs: {'count': _nearbyStops.length.toString()})
                  : 'all_stops'.tr(namedArgs: {'count': _allStops.length.toString()}),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: _toggleNearbyFilter,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  _showOnlyNearby ? Icons.toggle_on : Icons.toggle_off,
                  color: _showOnlyNearby 
                      ? Theme.of(context).primaryColor 
                      : Theme.of(context).disabledColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: .8),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator.adaptive(),
                const SizedBox(height: 16),
                Text(
                  _isLoadingLocation 
                      ? 'getting_location'.tr()
                      : 'loading_nearby_stops'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                StreamBuilder<String>(
                  stream: TextBroadcaster.getTextStream(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'please_wait'.tr(),
                      
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: .9),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'map_loading_error'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: Text('go_back'.tr()),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _loadMapData,
                      icon: const Icon(Icons.refresh),
                      label: Text('try_again'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_userLocation != null)
          FloatingActionButton.small(
            heroTag: "center_location",
            onPressed: _centerOnUserLocation,
            tooltip: 'center_on_location'.tr(),
            child: const Icon(Icons.my_location),
          ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: "filter",
          onPressed: _toggleNearbyFilter,
          tooltip: _showOnlyNearby ? 'show_all_stops'.tr() : 'show_nearby_only'.tr(),
          backgroundColor: _showOnlyNearby 
              ? Theme.of(context).primaryColor 
              : Theme.of(context).cardColor,
          child: Icon(
            _showOnlyNearby ? Icons.location_on : Icons.location_off,
            color: _showOnlyNearby 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: "settings",
          onPressed: _showRadiusDialog,
          tooltip: 'adjust_search_radius'.tr(),
          child: const Icon(Icons.tune),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers({required List<Stop> stops}) {
    return stops.map((stop) => _buildStopMarker(stop)).toList();
  }

  Marker _buildStopMarker(Stop stop) {
    final isNearby = _nearbyStops.contains(stop);
    
    return Marker(
      height: 60,
      width: 160,
      rotate: false,
      point: LatLng(
        double.parse(stop.stopLat!),
        double.parse(stop.stopLng!),
      ),
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => _onPressMarker(stop: stop),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isNearby 
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor,
                  width: isNearby ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: .2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                LanguageHelper.getLanguageUsedInApp(context) == 'en'
                    ? stop.stopDescriptionEng ?? 'no_description'.tr()
                    : stop.stopDescription ?? 'no_description'.tr(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isNearby 
                      ? Theme.of(context).primaryColor
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isNearby 
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: .3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_bus,
                size: 16,
                color: isNearby 
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterMarker(BuildContext context, List<Marker> markers) {
    if (markers.isEmpty) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: .3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _buildClusterMarkerCount(markers.length),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  void _onPressMarker({required Stop stop}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StopPage(stop: stop),
      ),
    );
  }

  String _buildClusterMarkerCount(int length) {
    if (length <= 1000) {
      return length.toString();
    } else if (length <= 10000) {
      return '${(length / 1000).toStringAsFixed(1)}k';
    } else if (length <= 1000000) {
      return '${(length / 1000).toStringAsFixed(0)}k';
    }
    return '999k+';
  }

  void _showMapInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('map_information'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              context,
              Icons.location_on,
              'your_location'.tr(),
              'blue_dot_explanation'.tr(),
            ),
            _buildInfoItem(
              context,
              Icons.directions_bus,
              'bus_stops'.tr(),
              'bus_stop_markers_explanation'.tr(),
            ),
            _buildInfoItem(
              context,
              Icons.filter_alt,
              'nearby_filter'.tr(),
              'nearby_filter_explanation'.tr(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('got_it'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRadiusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('search_radius'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('adjust_search_radius_description'.tr()),
            const SizedBox(height: 16),
            Slider(
              value: _searchRadius,
              min: 500,
              max: 5000,
              divisions: 9,
              label: '${(_searchRadius / 1000).toStringAsFixed(1)} km',
              onChanged: (value) {
                setState(() {
                  _searchRadius = value;
                });
              },
            ),
            Text(
              'current_radius'.tr(namedArgs: {
                'radius': (_searchRadius / 1000).toStringAsFixed(1)
              }),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              _updateNearbyStops();
              Navigator.pop(context);
            },
            child: Text('apply'.tr()),
          ),
        ],
      ),
    );
  }
}