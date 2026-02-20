import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/bus_location.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/helpers/language_helper.dart';
import 'package:oasth/screens/stop_page.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({
    super.key,
    required this.details,
    required this.stops,
    this.hasAppBar = true,
    required this.routeCode,
    this.routeName,
    this.lineId,
  });

  final bool hasAppBar;
  final List<Details> details;
  final List<Stop> stops;
  final String routeCode;
  final String? routeName;
  final String? lineId;

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  final MapController _mapController = MapController();
  Timer? _busLocationTimer;
  BusLocation? _currentBusLocation;
  bool _isLoadingBuses = true;
  bool _showStopLabels = true;
  bool _showBuses = true;
  bool _hasError = false;

  List<LatLng> _routePoints = [];
  List<Marker> _stopMarkers = [];
  List<Marker> _busMarkers = [];

  @override
  void initState() {
    super.initState();
    _initializeRoute();
    _startBusLocationUpdates();
  }

  @override
  void dispose() {
    _busLocationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _initializeRoute() {
    _routePoints = widget.details
        .map((detail) => LatLng(
              double.parse(detail.routedY),
              double.parse(detail.routedX),
            ))
        .toList();

    _stopMarkers = widget.stops.map((stop) => _buildStopMarker(stop)).toList();
  }

  void _startBusLocationUpdates() {
    _loadBusLocations();
    _busLocationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadBusLocations();
      }
    });
  }

  Future<void> _loadBusLocations() async {
    try {
      final busLocation = await Api.getBusLocations(widget.routeCode);
      if (mounted) {
        setState(() {
          _currentBusLocation = busLocation;
          _isLoadingBuses = false;
          _hasError = false;
          _busMarkers = _buildBusMarkers(busLocation);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBuses = false;
          _hasError = true;
        });
      }
    }
  }

  List<Marker> _buildBusMarkers(BusLocation busLocation) {
    if (busLocation.busLocation.isEmpty) return [];

    return busLocation.busLocation.map((bus) {
      return Marker(
        width: 40,
        height: 40,
        rotate: false,
        alignment: Alignment.center,
        point: LatLng(
          double.parse(bus.csLat!),
          double.parse(bus.csLng!),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.onSecondary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withAlpha(76),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_bus,
            size: 20,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      );
    }).toList();
  }

  Marker _buildStopMarker(Stop stop) {
    return Marker(
      width: _showStopLabels ? 140 : 32,
      height: _showStopLabels ? 80 : 32,
      rotate: false,
      alignment: Alignment.center,
      point: LatLng(
        double.parse(stop.stopLat!),
        double.parse(stop.stopLng!),
      ),
      child: GestureDetector(
        onTap: () => _navigateToStop(stop),
        child: _showStopLabels
            ? _buildLabeledStopMarker(stop)
            : _buildSimpleStopMarker(stop),
      ),
    );
  }

  Widget _buildLabeledStopMarker(Stop stop) {
    final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
        ? stop.stopDescriptionEng ?? stop.stopDescription ?? 'unknown_stop'.tr()
        : stop.stopDescription ?? stop.stopDescriptionEng ?? 'unknown_stop'.tr();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withAlpha(76),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withAlpha(76),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.location_on,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleStopMarker(Stop stop) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.onPrimary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(76),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.location_on,
        size: 18,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  void _navigateToStop(Stop stop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StopPage(stop: stop),
      ),
    );
  }

  void _toggleStopLabels() {
    setState(() {
      _showStopLabels = !_showStopLabels;
      _stopMarkers = widget.stops.map((stop) => _buildStopMarker(stop)).toList();
    });
  }

  void _toggleBusVisibility() {
    setState(() {
      _showBuses = !_showBuses;
    });
  }

  void _fitRouteToView() {
    if (_routePoints.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: _routePoints,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  void _showRouteInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _buildRouteInfoModal(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hasAppBar ? _buildAppBar(context) : null,
      body: Stack(
        children: [
          _buildMap(context),
          _buildTopControls(context),
          if (_hasError) _buildErrorBanner(context),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.routeName ?? 'route'.tr()),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showRouteInfo,
          tooltip: 'route_information'.tr(),
        ),
      ],
    );
  }

  Widget _buildMap(BuildContext context) {
    if (_isLoadingBuses && _routePoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 16),
            Text(
              'loading_route_map'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final allMarkers = <Marker>[
      ..._stopMarkers,
      if (_showBuses) ..._busMarkers,
    ];

    return ClipRRect(
      borderRadius: widget.hasAppBar 
          ? BorderRadius.zero 
          : const BorderRadius.all(Radius.circular(12)),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          maxZoom: 18.0,
          minZoom: 8.0,
          initialCameraFit: _routePoints.isNotEmpty
              ? CameraFit.coordinates(
                  coordinates: _routePoints,
                  padding: const EdgeInsets.all(50),
                )
              : null,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.oasth.oast',
          ),
          if (_routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 4,
                  color: Theme.of(context).primaryColor,
                  strokeJoin: StrokeJoin.round,
                  strokeCap: StrokeCap.round,
                ),
              ],
            ),
          MarkerLayer(
            markers: allMarkers,
            alignment: Alignment.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls(BuildContext context) {
    if (widget.hasAppBar) return const SizedBox.shrink();
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Card(
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.adaptive.arrow_back),
              tooltip: 'back'.tr(),
            ),
          ),
          const Spacer(),
          _buildControlChips(context),
        ],
      ),
    );
  }

  Widget _buildControlChips(BuildContext context) {
    return Row(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.label,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'labels'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _toggleStopLabels,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _showStopLabels ? Icons.toggle_on : Icons.toggle_off,
                      color: _showStopLabels 
                          ? Theme.of(context).primaryColor 
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_bus,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'buses'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _toggleBusVisibility,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _showBuses ? Icons.toggle_on : Icons.toggle_off,
                      color: _showBuses 
                          ? Theme.of(context).primaryColor 
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Positioned(
      top: widget.hasAppBar ? 0 : MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'bus_location_error'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: _loadBusLocations,
                child: Text(
                  'retry'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: "fit_route",
          onPressed: _fitRouteToView,
          tooltip: 'fit_route_to_view'.tr(),
          child: const Icon(Icons.fit_screen),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: "toggle_labels",
          onPressed: _toggleStopLabels,
          tooltip: _showStopLabels ? 'hide_stop_labels'.tr() : 'show_stop_labels'.tr(),
          backgroundColor: _showStopLabels 
              ? Theme.of(context).primaryColor 
              : Theme.of(context).cardColor,
          child: Icon(
            Icons.label,
            color: _showStopLabels 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: "toggle_buses",
          onPressed: _toggleBusVisibility,
          tooltip: _showBuses ? 'hide_buses'.tr() : 'show_buses'.tr(),
          backgroundColor: _showBuses 
              ? Theme.of(context).primaryColor 
              : Theme.of(context).cardColor,
          child: Icon(
            Icons.directions_bus,
            color: _showBuses 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfoModal(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.8,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'route_information'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(
                        context,
                        'route_details'.tr(),
                        [
                          _buildInfoRow(context, 'line_number'.tr(), widget.lineId ?? 'N/A'),
                          _buildInfoRow(context, 'route_code'.tr(), widget.routeCode),
                          _buildInfoRow(context, 'total_stops'.tr(), widget.stops.length.toString()),
                          _buildInfoRow(context, 'active_buses'.tr(), 
                              _currentBusLocation?.busLocation.length.toString() ?? '0'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildInfoSection(
                        context,
                        'map_legend'.tr(),
                        [
                          _buildLegendItem(context, Icons.location_on, 'bus_stops'.tr(), 
                              Theme.of(context).primaryColor),
                          _buildLegendItem(context, Icons.directions_bus, 'live_buses'.tr(), 
                              Theme.of(context).colorScheme.secondary),
                          _buildLegendItem(context, Icons.timeline, 'route_path'.tr(), 
                              Theme.of(context).primaryColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}