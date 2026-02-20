import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/data/oasth_repository.dart';
import 'package:oasth/data/route_planner.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RouteStep { input, preferences, results }

class RoutePreferences {
  final bool minimizeTransfers;
  final int maxWalkingDistance;
  final bool preferAccessibility;

  const RoutePreferences({
    this.minimizeTransfers = true,
    this.maxWalkingDistance = 500,
    this.preferAccessibility = false,
  });

  RoutePreferences copyWith({
    bool? minimizeTransfers,
    int? maxWalkingDistance,
    bool? preferAccessibility,
  }) {
    return RoutePreferences(
      minimizeTransfers: minimizeTransfers ?? this.minimizeTransfers,
      maxWalkingDistance: maxWalkingDistance ?? this.maxWalkingDistance,
      preferAccessibility: preferAccessibility ?? this.preferAccessibility,
    );
  }
}

class SavedPlace {
  final String name;
  final double latitude;
  final double longitude;
  final String? stopCode;

  const SavedPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.stopCode,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'stopCode': stopCode,
      };

  factory SavedPlace.fromMap(Map<String, dynamic> map) => SavedPlace(
        name: map['name'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        stopCode: map['stopCode'] as String?,
      );
}

class RouteResult {
  final Stop? nearestStartStop;
  final Stop? nearestEndStop;
  final OfflineRouteResult? route;
  final String? error;
  final bool isLoading;

  const RouteResult({
    this.nearestStartStop,
    this.nearestEndStop,
    this.route,
    this.error,
    this.isLoading = false,
  });

  RouteResult copyWith({
    Stop? nearestStartStop,
    Stop? nearestEndStop,
    OfflineRouteResult? route,
    String? error,
    bool? isLoading,
    bool clearError = false,
    bool clearRoute = false,
  }) {
    return RouteResult(
      nearestStartStop: nearestStartStop ?? this.nearestStartStop,
      nearestEndStop: nearestEndStop ?? this.nearestEndStop,
      route: clearRoute ? null : (route ?? this.route),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BestRoutePage extends StatefulWidget {
  const BestRoutePage({super.key});

  @override
  State<BestRoutePage> createState() => _BestRoutePageState();
}

class _BestRoutePageState extends State<BestRoutePage>
    with TickerProviderStateMixin {
  RouteStep _currentStep = RouteStep.input;

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  SavedPlace? _fromPlace;
  SavedPlace? _toPlace;

  RoutePreferences _preferences = const RoutePreferences();
  RouteResult _result = const RouteResult();

  List<SavedPlace> _recentSearches = [];
  List<SavedPlace> _savedPlaces = [];

  bool _graphReady = false;
  bool _buildingGraph = false;
  double _graphProgress = 0.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _loadSavedData();
    _checkGraphStatus();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final recentJson = prefs.getStringList('recent_routes') ?? [];
    setState(() {
      _recentSearches = recentJson
          .map((j) => SavedPlace.fromMap(
              Map<String, dynamic>.from(Uri.splitQueryString(j))))
          .toList();
    });

    final savedJson = prefs.getStringList('saved_places') ?? [];
    setState(() {
      _savedPlaces = savedJson
          .map((j) => SavedPlace.fromMap(
              Map<String, dynamic>.from(Uri.splitQueryString(j))))
          .toList();
    });
  }

  Future<void> _saveRecentSearch(SavedPlace from, SavedPlace to) async {
    final prefs = await SharedPreferences.getInstance();

    _recentSearches.insert(0, from);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }

    await prefs.setStringList(
      'recent_routes',
      _recentSearches
          .map((p) => Uri(queryParameters: p.toMap()).query)
          .toList(),
    );
  }

  Future<void> _checkGraphStatus() async {
    final planner = RoutePlanner();
    if (planner.isReady) {
      setState(() => _graphReady = true);
      return;
    }

    setState(() => _buildingGraph = true);

    planner
        .buildGraph(
      repository: OasthRepository(),
      onProgress: (progress) {
        setState(() {
          _graphProgress = progress.processedRoutes / progress.totalRoutes;
        });
      },
    )
        .then((_) {
      setState(() {
        _graphReady = true;
        _buildingGraph = false;
      });
    }).catchError((e) {
      setState(() => _buildingGraph = false);
      debugPrint('Failed to build graph: $e');
    });
  }

  Future<void> _getCurrentLocation(bool isFrom) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          _showError('location_permission_denied'.tr());
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('location_permission_permanently_denied'.tr());
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final place = SavedPlace(
        name: 'current_location'.tr(),
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        if (isFrom) {
          _fromPlace = place;
          _fromController.text = place.name;
        } else {
          _toPlace = place;
          _toController.text = place.name;
        }
      });
    } catch (e) {
      _showError('location_error'.tr());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _goToNextStep() {
    if (_fromPlace == null || _toPlace == null) {
      _showError('please_select_locations'.tr());
      return;
    }

    setState(() {
      _currentStep = RouteStep.preferences;
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _findRoute() async {
    if (!_graphReady) {
      _showError('route_data_loading'.tr());
      return;
    }

    setState(() {
      _currentStep = RouteStep.results;
      _result = const RouteResult(isLoading: true);
    });
    _animationController.reset();
    _animationController.forward();

    try {
      final planner = RoutePlanner();

      final startStop = planner.findNearestStop(
        _fromPlace!.latitude,
        _fromPlace!.longitude,
      );

      final endStop = planner.findNearestStop(
        _toPlace!.latitude,
        _toPlace!.longitude,
      );

      final route = planner.findBestRoute(startStop.stopCode, endStop.stopCode);

      setState(() {
        _result = RouteResult(
          nearestStartStop: startStop,
          nearestEndStop: endStop,
          route: route,
          isLoading: false,
        );
      });

      await _saveRecentSearch(_fromPlace!, _toPlace!);
    } catch (e) {
      setState(() {
        _result = RouteResult(
          error: 'no_route_found'.tr(),
          isLoading: false,
        );
      });
    }
  }

  void _resetToInput() {
    setState(() {
      _currentStep = RouteStep.input;
      _result = const RouteResult();
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _swapLocations() {
    setState(() {
      final tempPlace = _fromPlace;
      final tempText = _fromController.text;

      _fromPlace = _toPlace;
      _fromController.text = _toController.text;

      _toPlace = tempPlace;
      _toController.text = tempText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            if (_buildingGraph && !_graphReady) _buildGraphProgressIndicator(),
            Expanded(
              child: switch (_currentStep) {
                RouteStep.input => _buildInputStep(),
                RouteStep.preferences => _buildPreferencesStep(),
                RouteStep.results => _buildResultsStep(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withAlpha(30),
            Theme.of(context).primaryColor.withAlpha(10),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.route,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'route_planner'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _getStepSubtitle(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withAlpha(178),
                      ),
                ),
              ],
            ),
          ),
          if (_currentStep != RouteStep.input)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetToInput,
              tooltip: 'start_over'.tr(),
            ),
        ],
      ),
    );
  }

  String _getStepSubtitle() {
    return switch (_currentStep) {
      RouteStep.input => 'step_1_of_3'.tr(),
      RouteStep.preferences => 'step_2_of_3'.tr(),
      RouteStep.results => 'step_3_of_3'.tr(),
    };
  }

  Widget _buildGraphProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'loading_route_data'.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _graphProgress),
        ],
      ),
    );
  }

  Widget _buildInputStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLocationCard(
            title: 'from_location'.tr(),
            controller: _fromController,
            place: _fromPlace,
            onLocationTap: () => _getCurrentLocation(true),
            onChanged: (value) {
              if (_fromPlace != null && value != _fromPlace!.name) {
                setState(() => _fromPlace = null);
              }
            },
          ),
          Center(
            child: IconButton(
              onPressed: _swapLocations,
              icon: const Icon(Icons.swap_vert),
              tooltip: 'swap_locations'.tr(),
            ),
          ),
          _buildLocationCard(
            title: 'to_location'.tr(),
            controller: _toController,
            place: _toPlace,
            onLocationTap: () => _getCurrentLocation(false),
            onChanged: (value) {
              if (_toPlace != null && value != _toPlace!.name) {
                setState(() => _toPlace = null);
              }
            },
          ),
          const SizedBox(height: 24),
          if (_recentSearches.isNotEmpty) ...[
            Text(
              'recent_places'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recentSearches.length,
                itemBuilder: (context, index) {
                  final place = _recentSearches[index];
                  return _buildRecentPlaceChip(place);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          FilledButton.icon(
            onPressed:
                (_fromPlace != null && _toPlace != null) ? _goToNextStep : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text('continue'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required TextEditingController controller,
    required SavedPlace? place,
    required VoidCallback onLocationTap,
    required Function(String) onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  title == 'from_location'.tr()
                      ? Icons.trip_origin
                      : Icons.location_on,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'enter_location_hint'.tr(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: onLocationTap,
                ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPlaceChip(SavedPlace place) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          if (_fromPlace == null) {
            setState(() {
              _fromPlace = place;
              _fromController.text = place.name;
            });
          } else if (_toPlace == null) {
            setState(() {
              _toPlace = place;
              _toController.text = place.name;
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 4),
              Text(
                place.name,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'route_preferences'.tr(),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('minimize_transfers'.tr()),
                    subtitle: Text('minimize_transfers_desc'.tr()),
                    value: _preferences.minimizeTransfers,
                    onChanged: (v) => setState(() {
                      _preferences =
                          _preferences.copyWith(minimizeTransfers: v);
                    }),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('max_walking_distance'.tr()),
                    subtitle: Slider(
                      value: _preferences.maxWalkingDistance.toDouble(),
                      min: 100,
                      max: 2000,
                      divisions: 19,
                      label: '${_preferences.maxWalkingDistance}m',
                      onChanged: (v) => setState(() {
                        _preferences = _preferences.copyWith(
                          maxWalkingDistance: v.round(),
                        );
                      }),
                    ),
                    trailing: Text('${_preferences.maxWalkingDistance}m'),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('accessible_route'.tr()),
                    subtitle: Text('accessible_route_desc'.tr()),
                    value: _preferences.preferAccessibility,
                    onChanged: (v) => setState(() {
                      _preferences =
                          _preferences.copyWith(preferAccessibility: v);
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _currentStep = RouteStep.input),
                  icon: const Icon(Icons.arrow_back),
                  label: Text('back'.tr()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _graphReady ? _findRoute : null,
                  icon: const Icon(Icons.search),
                  label: Text('find_route'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsStep() {
    if (_result.isLoading) {
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

    if (_result.error != null) {
      return _buildErrorResult();
    }

    if (_result.route == null) {
      return _buildNoRouteResult();
    }

    return _buildRouteResult();
  }

  Widget _buildErrorResult() {
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
              _result.error ?? 'unknown_error'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _resetToInput,
              icon: const Icon(Icons.refresh),
              label: Text('try_again'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRouteResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Theme.of(context).disabledColor),
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
              onPressed: _resetToInput,
              icon: const Icon(Icons.edit),
              label: Text('change_route'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteResult() {
    final route = _result.route!;
    final startStop = _result.nearestStartStop!;
    final endStop = _result.nearestEndStop!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRouteSummaryCard(route, startStop, endStop),
          const SizedBox(height: 16),
          _buildSegmentedPathCard(route),
          const SizedBox(height: 16),
          _buildQuickActionsCard(route),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _resetToInput,
            icon: const Icon(Icons.add),
            label: Text('plan_new_route'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSummaryCard(
      OfflineRouteResult route, Stop startStop, Stop endStop) {
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
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                    Icons.straighten, '$distanceKm km', 'total_distance'.tr()),
                _buildSummaryItem(
                    Icons.swap_horiz, '$transferCount', 'transfers'.tr()),
                _buildSummaryItem(
                    Icons.location_on, '${route.edges.length}', 'stops'.tr()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon,
            size: 24, color: Theme.of(context).colorScheme.onPrimaryContainer),
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

  Widget _buildSegmentedPathCard(OfflineRouteResult route) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alt_route, color: Theme.of(context).primaryColor),
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
              _buildPathSegments(route),
          ],
        ),
      ),
    );
  }

  Widget _buildPathSegments(OfflineRouteResult route) {
    final segments = _groupEdgesByRoute(route.edges);

    return Column(
      children: [
        _buildSegmentItem(
          icon: Icons.trip_origin,
          title: 'start'.tr(),
          subtitle: route.startStop.stopDescription,
          isStart: true,
        ),
        for (final segment in segments)
          _buildSegmentItem(
            icon: Icons.directions_bus,
            title: '${'line'.tr()} ${segment.routeCode}',
            subtitle: '${segment.stops.length} ${'stops'.tr()}',
            color: Theme.of(context).primaryColor,
          ),
        _buildSegmentItem(
          icon: Icons.location_on,
          title: 'destination'.tr(),
          subtitle: route.endStop.stopDescription,
          isEnd: true,
        ),
      ],
    );
  }

  List<_RouteSegment> _groupEdgesByRoute(List<RouteEdge> edges) {
    final segments = <_RouteSegment>[];

    for (final edge in edges) {
      if (segments.isEmpty || segments.last.routeCode != edge.routeCode) {
        segments.add(_RouteSegment(routeCode: edge.routeCode));
      }
      segments.last.stops.add(edge);
    }

    return segments;
  }

  Widget _buildSegmentItem({
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
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      size: 16, color: color != null ? Colors.white : null),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

  Widget _buildQuickActionsCard(OfflineRouteResult route) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
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
                    icon: Icons.star_outline,
                    label: 'save_route'.tr(),
                    onTap: () => _showError('feature_coming_soon'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.share,
                    label: 'share'.tr(),
                    onTap: () => _showError('feature_coming_soon'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.map,
                    label: 'view_map'.tr(),
                    onTap: () => _showError('feature_coming_soon'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
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

class _RouteSegment {
  final String routeCode;
  final List<RouteEdge> stops = [];

  _RouteSegment({required this.routeCode});
}
