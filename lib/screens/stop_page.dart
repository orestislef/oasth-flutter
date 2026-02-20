import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/stop_details.dart';
import 'package:oasth/helpers/language_helper.dart';

class StopPage extends StatefulWidget {
  const StopPage({super.key, required this.stop});

  final Stop stop;

  @override
  State<StopPage> createState() => _StopPageState();
}

class _StopPageState extends State<StopPage> {
  late Timer _timer;
  late Future<StopArrivals> _futureStopArrivals;
  final MapController _mapController = MapController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadStopArrivals();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _loadStopArrivals() {
    setState(() {
      _futureStopArrivals = Api.getStopArrivals(widget.stop.stopCode!);
    });
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
    
    _loadStopArrivals();
    
    // Add a small delay to show the refresh animation
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _openInMaps() {
    try {
      MapsLauncher.launchCoordinates(
        double.parse(widget.stop.stopLat!),
        double.parse(widget.stop.stopLng!),
        widget.stop.stopDescription ?? 'Bus Stop',
      );
    } catch (e) {
      _showErrorSnackBar('failed_to_open_maps'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildStopInfo(context),
          const SizedBox(height: 16),
          _buildArrivalsSection(context),
          const SizedBox(height: 16),
          _buildMapSection(context),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        LanguageHelper.getLanguageUsedInApp(context) == 'en'
            ? widget.stop.stopDescriptionEng ?? widget.stop.stopDescription ?? 'stop_details'.tr()
            : widget.stop.stopDescription ?? widget.stop.stopDescriptionEng ?? 'stop_details'.tr(),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: _isRefreshing 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Icon(Icons.refresh),
          onPressed: _isRefreshing ? null : _refreshArrivals,
          tooltip: 'refresh_arrivals'.tr(),
        ),
      ],
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
              widget.stop.stopStreet ?? 'n_a'.tr(),
            ),
            if (widget.stop.stopStreetEng != null && widget.stop.stopStreetEng!.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.translate,
                'english_street'.tr(),
                widget.stop.stopStreetEng!,
              ),
            _buildInfoRow(
              context,
              Icons.numbers,
              'route_stop_order'.tr(),
              widget.stop.routeStopOrder ?? 'n_a'.tr(),
            ),
            _buildInfoRow(
              context,
              Icons.accessible,
              'accessibility'.tr(),
              widget.stop.stopAmea == '0' ? 'not_accessible'.tr() : 'accessible'.tr(),
              trailing: widget.stop.stopAmea == '0' 
                  ? Icon(Icons.close, color: Theme.of(context).colorScheme.error)
                  : Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
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
    return Expanded(
      flex: 2,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
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
            Expanded(
              child: _buildArrivalsContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivalsContent(BuildContext context) {
    return FutureBuilder<StopArrivals>(
      future: _futureStopArrivals,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }
        
        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error.toString());
        }
        
        if (!snapshot.hasData || snapshot.data!.stopDetails.isEmpty) {
          return _buildEmptyArrivalsState(context);
        }
        
        return _buildArrivalsList(context, snapshot.data!);
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'loading_arrivals'.tr(),
            
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              maxLines: 3,
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildArrivalsList(BuildContext context, StopArrivals stopArrivals) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stopArrivals.stopDetails.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final arrival = stopArrivals.stopDetails[index];
        return _buildArrivalCard(context, arrival);
      },
    );
  }

  Widget _buildArrivalCard(BuildContext context, StopDetails arrival) {
    final minutes = int.tryParse(arrival.btime2 ?? '0') ?? 0;
    final isImminent = minutes <= 2;
    final isSoon = minutes <= 5;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isImminent 
              ? Theme.of(context).colorScheme.error.withValues(alpha: .1)
              : isSoon 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: .1)
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
            arrival.routeCode ?? 'N/A',
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
        '${'bus'.tr()} ${arrival.vehCode ?? 'N/A'}',
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
      trailing: Icon(
        isImminent ? Icons.warning : Icons.access_time,
        color: isImminent 
            ? Theme.of(context).colorScheme.error
            : isSoon 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).primaryColor.withValues(alpha: .6),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Card(
        margin: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
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
            Expanded(
              child: _buildMap(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    try {
      final lat = double.parse(widget.stop.stopLat!);
      final lng = double.parse(widget.stop.stopLng!);
      
      return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          maxZoom: 18.0,
          minZoom: 8.0,
          initialCenter: LatLng(lat, lng),
          initialZoom: 16.0,
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
          MarkerLayer(
            markers: [
              Marker(
                rotate: false,
                width: 50.0,
                height: 50.0,
                point: LatLng(lat, lng),
                child: GestureDetector(
                  onTap: _openInMaps,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withValues(alpha: .3),
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
      );
    } catch (e) {
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
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: "refresh",
          onPressed: _isRefreshing ? null : _refreshArrivals,
          tooltip: 'refresh_arrivals'.tr(),
          child: _isRefreshing 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
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