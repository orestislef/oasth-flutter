import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:oasth/helpers/geocoding_helper.dart';
import 'package:oasth/helpers/location_helper.dart';
import 'package:oasth/helpers/tile_layer_helper.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String address;

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationPickerPage extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerPage({super.key, this.initialLocation});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  LocationData? _userLocation;
  bool _isConfirming = false;
  LatLng _center = const LatLng(40.6401, 22.9444); // Thessaloniki default

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _center = widget.initialLocation!;
    }
    _loadUserLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    try {
      final location = await LocationHelper.getUserLocation();
      if (mounted && location != null) {
        setState(() => _userLocation = location);
        // If no initial location was provided, center on user
        if (widget.initialLocation == null) {
          final userLatLng =
              LatLng(location.latitude!, location.longitude!);
          _mapController.move(userLatLng, 16.0);
          setState(() => _center = userLatLng);
        }
      }
    } catch (_) {}
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      final userLatLng =
          LatLng(_userLocation!.latitude!, _userLocation!.longitude!);
      _mapController.move(userLatLng, 16.0);
    }
  }

  Future<void> _confirmLocation() async {
    setState(() => _isConfirming = true);

    try {
      final center = _mapController.camera.center;
      final address = await GeocodingHelper.reverseGeocode(
        center.latitude,
        center.longitude,
      );

      if (!mounted) return;

      Navigator.of(context).pop(LocationPickerResult(
        latitude: center.latitude,
        longitude: center.longitude,
        address: address,
      ));
    } catch (_) {
      if (!mounted) return;
      // Still return with coordinate-based name
      final center = _mapController.camera.center;
      Navigator.of(context).pop(LocationPickerResult(
        latitude: center.latitude,
        longitude: center.longitude,
        address:
            '${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('pick_from_map'.tr()),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initialLocation != null ? 16.0 : 13.0,
            ),
            children: [
              const MapTileLayer(),
              if (_userLocation != null)
                CurrentLocationLayer(
                  alignPositionOnUpdate: AlignOnUpdate.never,
                  alignDirectionOnUpdate: AlignOnUpdate.never,
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
            ],
          ),
          // Center crosshair pin
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Icon(
                Icons.location_on,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          // Hint text at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'move_map_to_select'.tr(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // FABs
          Positioned(
            bottom: 90,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_userLocation != null)
                  FloatingActionButton.small(
                    heroTag: 'center_user',
                    onPressed: _centerOnUserLocation,
                    tooltip: 'center_on_location'.tr(),
                    child: const Icon(Icons.my_location),
                  ),
              ],
            ),
          ),
          // Confirm button at bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: FilledButton.icon(
              onPressed: _isConfirming ? null : _confirmLocation,
              icon: _isConfirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_isConfirming
                  ? 'loading'.tr()
                  : 'confirm_location'.tr()),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
