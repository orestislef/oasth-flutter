import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:oasth/data/oasth_repository.dart';
import 'package:oasth/data/route_planner.dart';
import 'package:oasth/data/route_planner_models.dart';
import 'package:oasth/screens/best_route/input_step.dart';
import 'package:oasth/screens/best_route/results_step.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RouteStep { input, results }

class BestRoutePage extends StatefulWidget {
  const BestRoutePage({super.key});

  @override
  State<BestRoutePage> createState() => _BestRoutePageState();
}

class _BestRoutePageState extends State<BestRoutePage>
    with TickerProviderStateMixin {
  RouteStep _currentStep = RouteStep.input;

  SavedPlace? _fromPlace;
  SavedPlace? _toPlace;

  RoutePreferences _preferences = const RoutePreferences();
  RouteResult _result = const RouteResult();

  List<SavedPlace> _recentSearches = [];

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

  void _swapLocations() {
    setState(() {
      final tempPlace = _fromPlace;
      _fromPlace = _toPlace;
      _toPlace = tempPlace;
    });
  }

  Future<void> _findRoute() async {
    if (!_graphReady) {
      _showError('route_data_loading'.tr());
      return;
    }

    if (_fromPlace == null || _toPlace == null) {
      _showError('please_select_locations'.tr());
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

      final route = planner.findBestRoute(
        startStop.stopCode,
        endStop.stopCode,
        minimizeTransfers: _preferences.minimizeTransfers,
      );

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
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
                RouteStep.input => InputStep(
                    fromPlace: _fromPlace,
                    toPlace: _toPlace,
                    preferences: _preferences,
                    recentSearches: _recentSearches,
                    graphReady: _graphReady,
                    onFromChanged: (place) =>
                        setState(() => _fromPlace = place),
                    onToChanged: (place) => setState(() => _toPlace = place),
                    onPreferencesChanged: (prefs) =>
                        setState(() => _preferences = prefs),
                    onFindRoute: _findRoute,
                    onSwapLocations: _swapLocations,
                  ),
                RouteStep.results => ResultsStep(
                    result: _result,
                    onResetToInput: _resetToInput,
                  ),
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
                  'find_best_route'.tr(),
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
}
