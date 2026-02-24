import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/data/oasth_repository.dart';
import 'package:oasth/data/route_planner.dart';
import 'package:oasth/data/route_planner_models.dart';
import 'package:oasth/screens/best_route/route_map.dart';
import 'package:oasth/widgets/shimmer_loading.dart';

class ResultsStep extends StatefulWidget {
  final RouteResult result;
  final VoidCallback onResetToInput;

  const ResultsStep({
    super.key,
    required this.result,
    required this.onResetToInput,
  });

  @override
  State<ResultsStep> createState() => _ResultsStepState();
}

class _ResultsStepState extends State<ResultsStep> {
  final _repo = OasthRepository();
  // boarding stop code → next arrival minutes for the route
  Map<String, String?> _arrivalTimes = {};
  bool _loadingArrivals = false;

  @override
  void initState() {
    super.initState();
    _fetchArrivalTimes();
  }

  @override
  void didUpdateWidget(covariant ResultsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.result.route != oldWidget.result.route) {
      _fetchArrivalTimes();
    }
  }

  Future<void> _fetchArrivalTimes() async {
    final route = widget.result.route;
    if (route == null || route.edges.isEmpty) return;

    setState(() => _loadingArrivals = true);

    final segments = _groupEdgesByRoute(route.edges);
    final newTimes = <String, String?>{};

    for (final segment in segments) {
      if (segment.isWalking || segment.stops.isEmpty) continue;

      final boardingStop = segment.stops.first.fromStopCode;
      final routeCode = segment.routeCode;

      try {
        final arrivals = await _repo.getStopArrivals(boardingStop);
        final matching = arrivals
            .where((a) => a.routeCode == routeCode)
            .toList();

        if (matching.isNotEmpty) {
          newTimes['${boardingStop}_$routeCode'] = matching.first.btime2;
        } else if (arrivals.isNotEmpty) {
          // Show closest arrival for any route at this stop
          newTimes['${boardingStop}_$routeCode'] = null;
        }
      } catch (_) {
        // Silently skip if API fails
      }
    }

    if (!mounted) return;
    setState(() {
      _arrivalTimes = newTimes;
      _loadingArrivals = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (result.isLoading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ShimmerContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ShimmerRouteResultCard(),
              const SizedBox(height: 16),
              const ShimmerBox(
                  width: double.infinity, height: 300, borderRadius: 12),
              const SizedBox(height: 16),
              ...List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ShimmerListTile(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (result.error != null) {
      return _buildErrorResult(context);
    }

    if (result.route == null) {
      return _buildNoRouteResult(context);
    }

    return _buildRouteResult(context);
  }

  Widget _buildErrorResult(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              widget.result.error ?? 'unknown_error'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.onResetToInput,
              icon: const Icon(Icons.refresh),
              label: Text('try_again'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRouteResult(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              'no_route_found'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'no_route_hint'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.onResetToInput,
              icon: const Icon(Icons.edit),
              label: Text('change_route'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteResult(BuildContext context) {
    final route = widget.result.route!;
    final startStop = widget.result.nearestStartStop!;
    final endStop = widget.result.nearestEndStop!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRouteSummaryCard(context, route, startStop, endStop),
          const SizedBox(height: 16),
          RouteMapView(route: route, result: widget.result),
          const SizedBox(height: 16),
          _buildSegmentedPathCard(context, route),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: widget.onResetToInput,
            icon: const Icon(Icons.add),
            label: Text('plan_new_route'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSummaryCard(
      BuildContext context, OfflineRouteResult route, Stop startStop, Stop endStop) {
    final distanceKm = (route.totalDistanceMeters / 1000).toStringAsFixed(1);
    final transferCount = _countTransfers(route);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus,
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'route_found'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(context, Icons.straighten,
                    '$distanceKm km', 'total_distance'.tr()),
                _buildSummaryItem(context, Icons.swap_horiz,
                    '$transferCount', 'transfers'.tr()),
                _buildSummaryItem(context, Icons.location_on,
                    '${route.edges.length}', 'stops'.tr()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon,
            size: 24,
            color: Theme.of(context).colorScheme.onPrimaryContainer),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withAlpha(178),
              ),
        ),
      ],
    );
  }

  int _countTransfers(OfflineRouteResult route) {
    if (route.edges.isEmpty) return 0;

    String? currentRoute;
    int transfers = 0;

    for (final edge in route.edges) {
      if (currentRoute != null && edge.routeCode != currentRoute) {
        transfers++;
      }
      currentRoute = edge.routeCode;
    }

    return transfers;
  }

  Widget _buildSegmentedPathCard(
      BuildContext context, OfflineRouteResult route) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alt_route,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'journey_details'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (route.edges.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('same_location'.tr()),
                ),
              )
            else
              _buildPathSegments(context, route),
          ],
        ),
      ),
    );
  }

  Widget _buildPathSegments(BuildContext context, OfflineRouteResult route) {
    final segments = _groupEdgesByRoute(route.edges);

    return Column(
      children: [
        _buildSegmentItem(
          context,
          icon: Icons.trip_origin,
          title: 'start'.tr(),
          subtitle: route.startStop.stopDescription,
          isStart: true,
        ),
        for (final segment in segments)
          segment.isWalking
              ? _buildSegmentItem(
                  context,
                  icon: Icons.directions_walk,
                  title: 'walking_transfer'.tr(),
                  subtitle:
                      '${(segment.stops.fold<double>(0, (sum, e) => sum + e.distanceMeters) / 3).toStringAsFixed(0)}m',
                  color: Theme.of(context).colorScheme.tertiary,
                )
              : _buildBusSegmentItem(context, segment),
        _buildSegmentItem(
          context,
          icon: Icons.location_on,
          title: 'destination'.tr(),
          subtitle: route.endStop.stopDescription,
          isEnd: true,
        ),
      ],
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

  Widget _buildBusSegmentItem(BuildContext context, RouteSegment segment) {
    final boardingStop = segment.stops.first.fromStopCode;
    final key = '${boardingStop}_${segment.routeCode}';
    final arrivalMin = _arrivalTimes[key];
    final hasArrival = _arrivalTimes.containsKey(key) && arrivalMin != null;
    final minutes = int.tryParse(arrivalMin ?? '') ?? 0;

    String arrivalText = '';
    if (_loadingArrivals) {
      arrivalText = '';
    } else if (hasArrival) {
      if (minutes <= 1) {
        arrivalText = 'arriving_now'.tr();
      } else {
        arrivalText = '$minutes min';
      }
    }

    return _buildSegmentItem(
      context,
      icon: Icons.directions_bus,
      title: '${'line'.tr()} ${segment.lineId}',
      subtitle:
          '${segment.routeDescription}\n${segment.stops.length} ${'stops'.tr()}',
      color: Theme.of(context).primaryColor,
      trailing: _loadingArrivals
          ? const ShimmerContainer(
              child: ShimmerBox(width: 50, height: 20, borderRadius: 4),
            )
          : hasArrival
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: minutes <= 2
                        ? Theme.of(context).colorScheme.error.withAlpha(25)
                        : Theme.of(context).primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: minutes <= 2
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: minutes <= 2
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        arrivalText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: minutes <= 2
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).primaryColor,
                            ),
                      ),
                    ],
                  ),
                )
              : null,
    );
  }

  Widget _buildSegmentItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    bool isStart = false,
    bool isEnd = false,
    Widget? trailing,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color ??
                        Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      size: 16,
                      color: color != null
                          ? Theme.of(context).colorScheme.onPrimary
                          : null),
                ),
                if (!isEnd)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

}
