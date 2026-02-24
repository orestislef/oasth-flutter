import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/data/route_planner.dart';
import 'package:oasth/data/route_planner_models.dart';

class ResultsStep extends StatelessWidget {
  final RouteResult result;
  final VoidCallback onResetToInput;

  const ResultsStep({
    super.key,
    required this.result,
    required this.onResetToInput,
  });

  @override
  Widget build(BuildContext context) {
    if (result.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('finding_best_route'.tr()),
          ],
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
              result.error ?? 'unknown_error'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onResetToInput,
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
              onPressed: onResetToInput,
              icon: const Icon(Icons.edit),
              label: Text('change_route'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteResult(BuildContext context) {
    final route = result.route!;
    final startStop = result.nearestStartStop!;
    final endStop = result.nearestEndStop!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRouteSummaryCard(context, route, startStop, endStop),
          const SizedBox(height: 16),
          _buildSegmentedPathCard(context, route),
          const SizedBox(height: 16),
          _buildQuickActionsCard(context),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onResetToInput,
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
          _buildSegmentItem(
            context,
            icon: Icons.directions_bus,
            title: '${'line'.tr()} ${segment.lineId}',
            subtitle:
                '${segment.routeDescription}\n${segment.stops.length} ${'stops'.tr()}',
            color: Theme.of(context).primaryColor,
          ),
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
        ));
      }
      segments.last.stops.add(edge);
    }

    return segments;
  }

  Widget _buildSegmentItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    bool isStart = false,
    bool isEnd = false,
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
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'quick_actions'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.star_outline,
                    label: 'save_route'.tr(),
                    onTap: () => _showFeatureSnackBar(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.share,
                    label: 'share'.tr(),
                    onTap: () => _showFeatureSnackBar(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.map,
                    label: 'view_map'.tr(),
                    onTap: () => _showFeatureSnackBar(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('feature_coming_soon'.tr()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
