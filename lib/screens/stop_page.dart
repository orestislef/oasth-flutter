import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:oasth/api/responses/bus_location.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/stop_details.dart';
import 'package:oasth/data/oasth_repository.dart';
import 'package:oasth/helpers/language_helper.dart';
import 'package:oasth/helpers/location_helper.dart';
import 'package:oasth/helpers/notification_helper.dart';
import 'package:oasth/helpers/tile_layer_helper.dart';
import 'package:oasth/widgets/shimmer_loading.dart';

class StopPage extends StatefulWidget {
  const StopPage({super.key, required this.stop});

  final Stop stop;

  @override
  State<StopPage> createState() => _StopPageState();
}

class _StopPageState extends State<StopPage> {
  final _repo = OasthRepository();
  Timer? _timer;
  final MapController _mapController = MapController();
  bool _isRefreshing = false;

  List<StopDetails>? _arrivals;
  bool _isInitialLoading = true;
  String? _error;

  LocationData? _userLocation;

  // Bus tracking state
  String? _expandedArrivalKey;
  final Map<String, _BusTrackingInfo> _trackingCache = {};

  // Reminder state
  final _notificationHelper = NotificationHelper();
  final Set<String> _reminderSet = {};

  @override
  void initState() {
    super.initState();
    _loadStopArrivals();
    _startAutoRefresh();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadStopArrivals() async {
    try {
      final data = await _repo.getStopArrivals(widget.stop.stopCode);
      if (!mounted) return;
      setState(() {
        _arrivals = data;
        _isInitialLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isInitialLoading = false;
      });
    }
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

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadStopArrivals();
      }
    });
  }

  Future<void> _refreshArrivals() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await _loadStopArrivals();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _openInMaps() {
    try {
      MapsLauncher.launchCoordinates(
        widget.stop.stopLat,
        widget.stop.stopLng,
        widget.stop.stopDescription.isNotEmpty
            ? widget.stop.stopDescription
            : 'Bus Stop',
      );
    } catch (e) {
      _showErrorSnackBar('failed_to_open_maps'.tr());
    }
  }

  String _getStopDescription(BuildContext context) {
    return LanguageHelper.getLanguageUsedInApp(context) == 'en'
        ? widget.stop.stopDescriptionEng.isNotEmpty
            ? widget.stop.stopDescriptionEng
            : widget.stop.stopDescription
        : widget.stop.stopDescription.isNotEmpty
            ? widget.stop.stopDescription
            : widget.stop.stopDescriptionEng;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [_buildSliverAppBar(context)];
        },
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildStopInfo(context),
            const SizedBox(height: 16),
            _buildArrivalsSection(context),
            const SizedBox(height: 16),
            _buildMapSection(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: _isRefreshing
              ? const ShimmerContainer(
                  child: ShimmerBox(width: 20, height: 20),
                )
              : const Icon(Icons.refresh),
          onPressed: _isRefreshing ? null : _refreshArrivals,
          tooltip: 'refresh_arrivals'.tr(),
        ),
        IconButton(
          icon: const Icon(Icons.map),
          onPressed: _openInMaps,
          tooltip: 'open_in_maps'.tr(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 16),
        title: Hero(
          tag: 'stop_name_${widget.stop.stopCode}',
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              _getStopDescription(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withAlpha(51),
                Theme.of(context).primaryColor.withAlpha(25),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 60),
            child: Row(
              children: [
                Hero(
                  tag: 'stop_icon_${widget.stop.stopCode}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withAlpha(76),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.directions_bus,
                          size: 36,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'stop_information'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.stop.stopCode,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withAlpha(178),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStopInfo(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'stop_information'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.location_on,
              'street'.tr(),
              widget.stop.stopStreet.isNotEmpty
                  ? widget.stop.stopStreet
                  : 'n_a'.tr(),
            ),
            if (widget.stop.stopStreetEng.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.translate,
                'english_street'.tr(),
                widget.stop.stopStreetEng,
              ),
            _buildInfoRow(
              context,
              Icons.numbers,
              'route_stop_order'.tr(),
              widget.stop.routeStopOrder.isNotEmpty
                  ? widget.stop.routeStopOrder
                  : 'n_a'.tr(),
            ),
            _buildInfoRow(
              context,
              Icons.accessible,
              'accessibility'.tr(),
              widget.stop.stopAmea == '0'
                  ? 'not_accessible'.tr()
                  : 'accessible'.tr(),
              trailing: widget.stop.stopAmea == '0'
                  ? Icon(Icons.close,
                      color: Theme.of(context).colorScheme.error)
                  : Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor.withValues(alpha: .7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).hintColor,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildArrivalsSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'live_arrivals'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  'updates_every_10s'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildArrivalsContent(context),
        ],
      ),
    );
  }

  Widget _buildArrivalsContent(BuildContext context) {
    if (_isInitialLoading) {
      return _buildLoadingState(context);
    }

    if (_error != null && _arrivals == null) {
      return _buildErrorState(context, _error!);
    }

    if (_arrivals == null || _arrivals!.isEmpty) {
      return _buildEmptyArrivalsState(context);
    }

    return _buildArrivalsList(context, _arrivals!);
  }

  Widget _buildLoadingState(BuildContext context) {
    return ShimmerContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (_) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerArrivalCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
              'error_loading_arrivals'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshArrivals,
              icon: const Icon(Icons.refresh),
              label: Text('try_again'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyArrivalsState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 48,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'no_arrivals_scheduled'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'check_back_later'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivalsList(BuildContext context, List<StopDetails> arrivals) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: arrivals.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildArrivalCard(context, arrivals[index]);
      },
    );
  }

  Widget _buildArrivalCard(BuildContext context, StopDetails arrival) {
    final minutes = int.tryParse(arrival.btime2) ?? 0;
    final isImminent = minutes <= 2;
    final isSoon = minutes <= 5;
    final key = '${arrival.routeCode}_${arrival.vehCode}';
    final isExpanded = _expandedArrivalKey == key;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          onTap: minutes > 0 ? () => _toggleArrivalExpansion(arrival) : null,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isImminent
                  ? Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: .1)
                  : isSoon
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .1)
                      : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isImminent
                    ? Theme.of(context).colorScheme.error
                    : isSoon
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
              ),
            ),
            child: Center(
              child: Text(
                arrival.routeCode,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isImminent
                      ? Theme.of(context).colorScheme.error
                      : isSoon
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
          title: Text(
            '${'bus'.tr()} ${arrival.vehCode}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          subtitle: Text(
            minutes == 0
                ? 'arriving_now'.tr()
                : '${'in'.tr()} $minutes ${'minutes'.tr()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isImminent
                      ? Theme.of(context).colorScheme.error
                      : isSoon
                          ? Theme.of(context).colorScheme.primary
                          : null,
                  fontWeight: isImminent ? FontWeight.w600 : null,
                ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (minutes > 1 && !_reminderSet.contains(key))
                IconButton(
                  icon: const Icon(Icons.notifications_none, size: 20),
                  onPressed: () => _showReminderDialog(arrival),
                  tooltip: 'set_reminder'.tr(),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                )
              else if (_reminderSet.contains(key))
                Icon(Icons.notifications_active,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Icon(
                isImminent
                    ? Icons.warning
                    : isExpanded
                        ? Icons.expand_less
                        : Icons.access_time,
                color: isImminent
                    ? Theme.of(context).colorScheme.error
                    : isSoon
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .primaryColor
                            .withValues(alpha: .6),
              ),
            ],
          ),
        ),
        if (isExpanded) _buildTrackingPanel(context, key),
      ],
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.map,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'stop_location'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _openInMaps,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text('open_in_maps'.tr()),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 300,
            child: _buildMap(context),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      _mapController.move(
        LatLng(_userLocation!.latitude!, _userLocation!.longitude!),
        16.0,
      );
    }
  }

  Widget _buildMap(BuildContext context) {
    final lat = widget.stop.stopLat;
    final lng = widget.stop.stopLng;

    if (lat == 0.0 && lng == 0.0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'map_unavailable'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final stopLatLng = LatLng(lat, lng);
    LatLng? userLatLng;
    double? distanceToStop;

    if (_userLocation != null) {
      userLatLng = LatLng(_userLocation!.latitude!, _userLocation!.longitude!);
      distanceToStop =
          const Distance().as(LengthUnit.Meter, userLatLng, stopLatLng);
    }

    // Fit map to show both user and stop
    CameraFit? initialFit;
    if (userLatLng != null && distanceToStop != null && distanceToStop < 50000) {
      initialFit = CameraFit.coordinates(
        coordinates: [stopLatLng, userLatLng],
        padding: const EdgeInsets.all(50),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            maxZoom: 18.0,
            minZoom: 8.0,
            initialCenter: initialFit == null ? stopLatLng : stopLatLng,
            initialZoom: initialFit == null ? 16.0 : 16.0,
            initialCameraFit: initialFit,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            const MapTileLayer(),
            // Walking dashed line from user to stop
            if (userLatLng != null && distanceToStop != null && distanceToStop < 50000)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [userLatLng, stopLatLng],
                    color: Theme.of(context).colorScheme.tertiary,
                    strokeWidth: 3,
                    pattern: const StrokePattern.dotted(),
                  ),
                ],
              ),
            // User location layer
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
            MarkerLayer(
              markers: [
                Marker(
                  rotate: false,
                  width: 50.0,
                  height: 50.0,
                  point: stopLatLng,
                  child: GestureDetector(
                    onTap: _openInMaps,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .shadowColor
                                .withValues(alpha: .3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_bus,
                        size: 28,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Distance badge overlay
        if (distanceToStop != null)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: .2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_walk,
                    size: 16,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDistance(distanceToStop),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_userLocation != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.small(
              heroTag: "my_location",
              onPressed: _centerOnUserLocation,
              tooltip: 'center_on_location'.tr(),
              child: const Icon(Icons.my_location),
            ),
          ),
        FloatingActionButton.small(
          heroTag: "refresh",
          onPressed: _isRefreshing ? null : _refreshArrivals,
          tooltip: 'refresh_arrivals'.tr(),
          child: _isRefreshing
              ? const ShimmerContainer(
                  child: ShimmerBox(width: 20, height: 20),
                )
              : const Icon(Icons.refresh),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: "location",
          onPressed: _openInMaps,
          tooltip: 'open_in_maps'.tr(),
          child: const Icon(Icons.map),
        ),
      ],
    );
  }

  // --- Bus tracking methods ---

  void _toggleArrivalExpansion(StopDetails arrival) {
    final key = '${arrival.routeCode}_${arrival.vehCode}';
    setState(() {
      if (_expandedArrivalKey == key) {
        _expandedArrivalKey = null;
      } else {
        _expandedArrivalKey = key;
        if (!_trackingCache.containsKey(key)) {
          _fetchBusTracking(arrival).then((info) {
            if (mounted && info != null) {
              setState(() => _trackingCache[key] = info);
            }
          });
        }
      }
    });
  }

  Future<_BusTrackingInfo?> _fetchBusTracking(StopDetails arrival) async {
    try {
      final routeData =
          await _repo.getRouteDetailsAndStops(arrival.routeCode);
      final stops = routeData.stops;
      if (stops.isEmpty) return null;

      final currentIdx = stops.indexWhere(
        (s) => s.stopCode == widget.stop.stopCode,
      );

      final busLocations =
          await _repo.getBusLocations(arrival.routeCode);

      BusLocationData? matchedBus;
      for (final bus in busLocations) {
        if (bus.vehNo == arrival.vehCode) {
          matchedBus = bus;
          break;
        }
      }

      int? busStopIdx;
      if (matchedBus != null) {
        double minDist = double.infinity;
        for (int i = 0; i < stops.length; i++) {
          final dist = _haversineMeters(
            matchedBus.csLat,
            matchedBus.csLng,
            stops[i].stopLat,
            stops[i].stopLng,
          );
          if (dist < minDist) {
            minDist = dist;
            busStopIdx = i;
          }
        }
      }

      int? stopsAway;
      if (currentIdx >= 0 && busStopIdx != null) {
        stopsAway = currentIdx - busStopIdx;
        if (stopsAway < 0) stopsAway = 0;
      }

      return _BusTrackingInfo(
        routeStops: stops,
        currentStopIndex: currentIdx,
        busStopIndex: busStopIdx,
        busLocation: matchedBus,
        stopsAway: stopsAway,
      );
    } catch (e) {
      debugPrint('Bus tracking error: $e');
      return null;
    }
  }

  double _haversineMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371000.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = pow(sin(dLat / 2), 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            pow(sin(dLon / 2), 2);
    return radius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Widget _buildTrackingPanel(BuildContext context, String key) {
    final info = _trackingCache[key];
    if (info == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (info.busLocation == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          'bus_not_found_on_route'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.stopsAway != null && info.stopsAway! > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${info.stopsAway} ${'stops_away'.tr()}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ),
          _buildMiniRouteStrip(context, info),
        ],
      ),
    );
  }

  Widget _buildMiniRouteStrip(
      BuildContext context, _BusTrackingInfo info) {
    final startIdx = max(0, (info.busStopIndex ?? 0) - 1);
    final endIdx =
        min(info.routeStops.length, (info.currentStopIndex) + 2);
    if (endIdx <= startIdx) return const SizedBox.shrink();

    final visibleStops = info.routeStops.sublist(startIdx, endIdx);

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          for (int i = 0; i < visibleStops.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: Theme.of(context).dividerColor,
                ),
              ),
            _buildStopDot(context, info, startIdx + i, visibleStops[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildStopDot(
    BuildContext context,
    _BusTrackingInfo info,
    int globalIdx,
    Stop stop,
  ) {
    final isBusHere = globalIdx == info.busStopIndex;
    final isCurrentStop = globalIdx == info.currentStopIndex;

    final stopName = LanguageHelper.getLanguageUsedInApp(context) == 'en'
        ? stop.stopDescriptionEng.isNotEmpty
            ? stop.stopDescriptionEng
            : stop.stopDescription
        : stop.stopDescription.isNotEmpty
            ? stop.stopDescription
            : stop.stopDescriptionEng;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBusHere)
          Icon(Icons.directions_bus,
              size: 14, color: Theme.of(context).colorScheme.secondary)
        else
          const SizedBox(height: 14),
        const SizedBox(height: 2),
        Container(
          width: isCurrentStop || isBusHere ? 14 : 10,
          height: isCurrentStop || isBusHere ? 14 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrentStop
                ? Theme.of(context).primaryColor
                : isBusHere
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).dividerColor,
          ),
        ),
        const SizedBox(height: 2),
        if (isCurrentStop || isBusHere)
          SizedBox(
            width: 60,
            child: Text(
              stopName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          )
        else
          const SizedBox(height: 10),
      ],
    );
  }

  // --- Reminder methods ---

  Future<void> _showReminderDialog(StopDetails arrival) async {
    final minutes = int.tryParse(arrival.btime2) ?? 0;
    if (minutes <= 1) return;

    final shouldSet = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('set_reminder'.tr()),
        content: Text(
          'reminder_dialog_text'.tr(namedArgs: {
            'vehCode': arrival.vehCode,
            'routeCode': arrival.routeCode,
            'minutes': minutes.toString(),
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('set_reminder'.tr()),
          ),
        ],
      ),
    );

    if (shouldSet == true && mounted) {
      final stopName = _getStopDescription(context);
      final hasPermission =
          await _notificationHelper.requestPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('notification_permission_denied'.tr()),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final key = '${arrival.routeCode}_${arrival.vehCode}';
      final notificationId = key.hashCode;

      await _notificationHelper.scheduleArrivalReminder(
        id: notificationId,
        lineId: arrival.routeCode,
        vehCode: arrival.vehCode,
        minutesUntilArrival: minutes,
        stopName: stopName,
      );

      setState(() {
        _reminderSet.add(key);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('reminder_set'.tr(namedArgs: {
              'minutes': (minutes - 1).toString(),
            })),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'dismiss'.tr(),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class _BusTrackingInfo {
  final List<Stop> routeStops;
  final int currentStopIndex;
  final int? busStopIndex;
  final BusLocationData? busLocation;
  final int? stopsAway;

  _BusTrackingInfo({
    required this.routeStops,
    required this.currentStopIndex,
    this.busStopIndex,
    this.busLocation,
    this.stopsAway,
  });
}
