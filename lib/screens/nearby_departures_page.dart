import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/routes_for_stop.dart';
import 'package:oasth/api/responses/stop_details.dart';
import 'package:oasth/data/oasth_repository.dart';
import 'package:oasth/data/route_planner.dart';
import 'package:oasth/helpers/app_routes.dart';
import 'package:oasth/helpers/language_helper.dart';
import 'package:oasth/helpers/location_helper.dart';
import 'package:oasth/widgets/shimmer_loading.dart';

class NearbyDeparturesPage extends StatefulWidget {
  const NearbyDeparturesPage({super.key});

  @override
  State<NearbyDeparturesPage> createState() => _NearbyDeparturesPageState();
}

class _NearbyDeparturesPageState extends State<NearbyDeparturesPage> {
  final _repo = OasthRepository();
  final _planner = RoutePlanner();
  Timer? _timer;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  List<_NearbyArrival> _arrivals = [];
  List<(Stop, double)> _nearestStops = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final location = await LocationHelper.getUserLocation();
      if (!mounted) return;

      if (location == null) {
        setState(() {
          _error = 'location_error'.tr();
          _isLoading = false;
        });
        return;
      }

      final lat = location.latitude!;
      final lng = location.longitude!;

      if (!_planner.isReady) {
        setState(() {
          _error = 'route_data_not_ready'.tr();
          _isLoading = false;
        });
        return;
      }

      _nearestStops = _planner.findNearestStops(lat, lng, count: 5);

      await _fetchArrivals();

      // Auto-refresh arrivals every 20 seconds
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (mounted) _fetchArrivals();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchArrivals() async {
    if (!_isLoading && mounted) setState(() => _isRefreshing = true);

    try {
      // Fetch arrivals and routes for all stops in parallel
      final arrivalFutures = _nearestStops
          .map((entry) => _repo.getStopArrivals(entry.$1.stopCode))
          .toList();
      final routesFutures = _nearestStops
          .map((entry) => _repo.getRoutesForStop(entry.$1.stopCode))
          .toList();

      final allArrivals = await Future.wait(arrivalFutures);
      final allRoutes = await Future.wait(routesFutures);

      if (!mounted) return;

      // Build route lookup: routeCode -> RouteForStop (for line info)
      final routeLookup = <String, RouteForStop>{};
      for (final routes in allRoutes) {
        for (final route in routes) {
          routeLookup[route.routeCode] = route;
        }
      }

      // Merge all arrivals
      final merged = <_NearbyArrival>[];
      for (int i = 0; i < _nearestStops.length; i++) {
        final (stop, distance) = _nearestStops[i];
        for (final arrival in allArrivals[i]) {
          final routeInfo = routeLookup[arrival.routeCode];
          merged.add(_NearbyArrival(
            arrival: arrival,
            stop: stop,
            distanceMeters: distance,
            lineId: routeInfo?.lineID ?? arrival.routeCode,
            lineDescription: routeInfo != null
                ? LanguageHelper.getLanguageUsedInApp(context) == 'en'
                    ? routeInfo.lineDescriptionEng.isNotEmpty
                        ? routeInfo.lineDescriptionEng
                        : routeInfo.lineDescription
                    : routeInfo.lineDescription.isNotEmpty
                        ? routeInfo.lineDescription
                        : routeInfo.lineDescriptionEng
                : '',
          ));
        }
      }

      // Sort by arrival time
      merged.sort((a, b) => a.minutes.compareTo(b.minutes));

      setState(() {
        _arrivals = merged;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('whats_coming_near_me'.tr()),
        bottom: _isRefreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    if (_error != null) {
      return _buildErrorState(context);
    }

    if (_arrivals.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _fetchArrivals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _arrivals.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildStopsHeader(context);
          }
          return _buildArrivalCard(context, _arrivals[index - 1]);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ShimmerContainer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shimmer header chips
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                3,
                (_) => const ShimmerBox(width: 140, height: 36, borderRadius: 18),
              ),
            ),
          ),
          // Shimmer arrival cards
          ...List.generate(6, (_) => const ShimmerArrivalCard()),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              _error!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text('try_again'.tr()),
            ),
          ],
        ),
      ),
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
              Icons.departure_board,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 24),
            Text(
              'no_nearby_departures'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text('try_again'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsHeader(BuildContext context) {
    if (_nearestStops.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _nearestStops.map((entry) {
          final (stop, distance) = entry;
          final name = LanguageHelper.getLanguageUsedInApp(context) == 'en'
              ? stop.stopDescriptionEng.isNotEmpty
                  ? stop.stopDescriptionEng
                  : stop.stopDescription
              : stop.stopDescription.isNotEmpty
                  ? stop.stopDescription
                  : stop.stopDescriptionEng;
          return ActionChip(
            avatar: const Icon(Icons.directions_bus, size: 16),
            label: Text(
              '$name (${_formatDistance(distance)})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onPressed: () {
              context.push(AppRoutes.stop, extra: StopArgs(stop));
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildArrivalCard(BuildContext context, _NearbyArrival item) {
    final minutes = item.minutes;
    final isImminent = minutes <= 2;
    final isSoon = minutes <= 5;

    final stopName = LanguageHelper.getLanguageUsedInApp(context) == 'en'
        ? item.stop.stopDescriptionEng.isNotEmpty
            ? item.stop.stopDescriptionEng
            : item.stop.stopDescription
        : item.stop.stopDescription.isNotEmpty
            ? item.stop.stopDescription
            : item.stop.stopDescriptionEng;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.stop, extra: StopArgs(item.stop));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Line badge
              Container(
                width: 44,
                height: 44,
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
                  borderRadius: BorderRadius.circular(10),
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
                    item.lineId,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isImminent
                          ? Theme.of(context).colorScheme.error
                          : isSoon
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.lineDescription.isNotEmpty)
                      Text(
                        item.lineDescription,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      'from_stop'.tr(namedArgs: {'stop': stopName}),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Time + distance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    minutes == 0
                        ? 'arriving_now'.tr()
                        : '$minutes ${'minutes'.tr()}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isImminent
                              ? Theme.of(context).colorScheme.error
                              : isSoon
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDistance(item.distanceMeters),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyArrival {
  final StopDetails arrival;
  final Stop stop;
  final double distanceMeters;
  final String lineId;
  final String lineDescription;

  _NearbyArrival({
    required this.arrival,
    required this.stop,
    required this.distanceMeters,
    required this.lineId,
    required this.lineDescription,
  });

  int get minutes => int.tryParse(arrival.btime2) ?? 0;
}
