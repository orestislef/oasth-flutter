import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oasth/data/route_planner.dart';
import 'package:oasth/data/route_planner_models.dart';
import 'package:oasth/helpers/app_routes.dart';
import 'package:oasth/helpers/geocoding_helper.dart';
import 'package:oasth/screens/location_picker_page.dart';
import 'package:oasth/widgets/shimmer_loading.dart';
import 'package:go_router/go_router.dart';

class InputStep extends StatefulWidget {
  final SavedPlace? fromPlace;
  final SavedPlace? toPlace;
  final RoutePreferences preferences;
  final List<RecentRoute> recentSearches;
  final bool graphReady;
  final ValueChanged<SavedPlace?> onFromChanged;
  final ValueChanged<SavedPlace?> onToChanged;
  final ValueChanged<RoutePreferences> onPreferencesChanged;
  final VoidCallback onFindRoute;
  final VoidCallback onSwapLocations;
  final ValueChanged<RecentRoute> onSelectRecentRoute;
  final ValueChanged<int> onDeleteRecentSearch;

  const InputStep({
    super.key,
    required this.fromPlace,
    required this.toPlace,
    required this.preferences,
    required this.recentSearches,
    required this.graphReady,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPreferencesChanged,
    required this.onFindRoute,
    required this.onSwapLocations,
    required this.onSelectRecentRoute,
    required this.onDeleteRecentSearch,
  });

  @override
  State<InputStep> createState() => _InputStepState();
}

class _InputStepState extends State<InputStep> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  List<GeocodingResult> _fromSuggestions = [];
  List<GeocodingResult> _toSuggestions = [];
  Timer? _searchDebounce;
  int _searchGeneration = 0; // cancels stale Nominatim results
  bool _isFromSearching = false;
  bool _isToSearching = false;
  bool _isGettingFromLocation = false;
  bool _isGettingToLocation = false;
  bool _showPreferences = false;

  @override
  void initState() {
    super.initState();
    if (widget.fromPlace != null) {
      _fromController.text = widget.fromPlace!.name;
    }
    if (widget.toPlace != null) {
      _toController.text = widget.toPlace!.name;
    }
  }

  @override
  void didUpdateWidget(covariant InputStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fromPlace != oldWidget.fromPlace) {
      _fromController.text = widget.fromPlace?.name ?? '';
    }
    if (widget.toPlace != oldWidget.toPlace) {
      _toController.text = widget.toPlace?.name ?? '';
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation(bool isFrom) async {
    if (isFrom ? _isGettingFromLocation : _isGettingToLocation) return;
    setState(() {
      if (isFrom) {
        _isGettingFromLocation = true;
      } else {
        _isGettingToLocation = true;
      }
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
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

      final address = await GeocodingHelper.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      final place = SavedPlace(
        name: address,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      setState(() {
        if (isFrom) {
          _fromController.text = place.name;
          _fromSuggestions = [];
        } else {
          _toController.text = place.name;
          _toSuggestions = [];
        }
      });

      if (isFrom) {
        widget.onFromChanged(place);
      } else {
        widget.onToChanged(place);
      }
    } catch (e) {
      if (mounted) _showError('location_error'.tr());
    } finally {
      if (mounted) {
        setState(() {
          if (isFrom) {
            _isGettingFromLocation = false;
          } else {
            _isGettingToLocation = false;
          }
        });
      }
    }
  }

  Future<void> _pickFromMap(bool isFrom) async {
    final result = await context.push<LocationPickerResult>(
      AppRoutes.locationPicker,
    );
    if (result == null || !mounted) return;

    final place = SavedPlace(
      name: result.address,
      latitude: result.latitude,
      longitude: result.longitude,
    );

    setState(() {
      if (isFrom) {
        _fromController.text = place.name;
        _fromSuggestions = [];
      } else {
        _toController.text = place.name;
        _toSuggestions = [];
      }
    });

    if (isFrom) {
      widget.onFromChanged(place);
    } else {
      widget.onToChanged(place);
    }
  }

  void _clearField(bool isFrom) {
    setState(() {
      if (isFrom) {
        _fromController.clear();
        _fromSuggestions = [];
      } else {
        _toController.clear();
        _toSuggestions = [];
      }
    });
    if (isFrom) {
      widget.onFromChanged(null);
    } else {
      widget.onToChanged(null);
    }
  }

  void _onLocationFieldChanged(String value, bool isFrom) {
    if (isFrom && widget.fromPlace != null && value != widget.fromPlace!.name) {
      widget.onFromChanged(null);
    } else if (!isFrom &&
        widget.toPlace != null &&
        value != widget.toPlace!.name) {
      widget.onToChanged(null);
    }

    _searchDebounce?.cancel();

    if (value.length < 3) {
      setState(() {
        if (isFrom) {
          _fromSuggestions = [];
        } else {
          _toSuggestions = [];
        }
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 800), () {
      _searchSuggestions(value, isFrom);
    });
  }

  Future<void> _searchSuggestions(String query, bool isFrom) async {
    final generation = ++_searchGeneration;

    setState(() {
      if (isFrom) {
        _isFromSearching = true;
      } else {
        _isToSearching = true;
      }
    });

    // Show local stop results immediately (no network needed)
    final results = <GeocodingResult>[];
    final planner = RoutePlanner();
    if (planner.isReady) {
      final stops = planner.searchStopsByName(query);
      results.addAll(stops.map((s) {
        final name = s.stopDescriptionEng.isNotEmpty
            ? s.stopDescriptionEng
            : s.stopDescription;
        final street =
            s.stopStreetEng.isNotEmpty ? s.stopStreetEng : s.stopStreet;
        return GeocodingResult(
          displayName: street.isNotEmpty ? '$name ($street)' : name,
          latitude: s.stopLat,
          longitude: s.stopLng,
          type: 'stop',
        );
      }));
    }

    // Show stop results right away while address search loads
    if (mounted && generation == _searchGeneration && results.isNotEmpty) {
      setState(() {
        if (isFrom) {
          _fromSuggestions = List.of(results);
        } else {
          _toSuggestions = List.of(results);
        }
      });
    }

    // Fetch address results from Nominatim (slower, can timeout)
    if (generation != _searchGeneration) return; // stale, skip network call
    final addresses = await GeocodingHelper.searchAddress(query);
    if (generation != _searchGeneration) return; // stale, discard results

    results.addAll(addresses);

    if (mounted) {
      setState(() {
        if (isFrom) {
          _fromSuggestions = results;
          _isFromSearching = false;
        } else {
          _toSuggestions = results;
          _isToSearching = false;
        }
      });
    }
  }

  void _selectSuggestion(GeocodingResult suggestion, bool isFrom) {
    final place = SavedPlace(
      name: suggestion.displayName,
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
    );

    setState(() {
      if (isFrom) {
        _fromController.text = place.name;
        _fromSuggestions = [];
      } else {
        _toController.text = place.name;
        _toSuggestions = [];
      }
    });

    if (isFrom) {
      widget.onFromChanged(place);
    } else {
      widget.onToChanged(place);
    }
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLocationCard(
            title: 'from_location'.tr(),
            controller: _fromController,
            place: widget.fromPlace,
            isFrom: true,
            suggestions: _fromSuggestions,
          ),
          Center(
            child: IconButton(
              onPressed: widget.onSwapLocations,
              icon: const Icon(Icons.swap_vert),
              tooltip: 'swap_locations'.tr(),
            ),
          ),
          _buildLocationCard(
            title: 'to_location'.tr(),
            controller: _toController,
            place: widget.toPlace,
            isFrom: false,
            suggestions: _toSuggestions,
          ),
          const SizedBox(height: 16),
          _buildPreferencesSection(),
          const SizedBox(height: 24),
          if (widget.recentSearches.isNotEmpty) ...[
            Text(
              'recent_searches'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...List.generate(widget.recentSearches.length, (index) {
              final route = widget.recentSearches[index];
              return _buildRecentRouteCard(route, index);
            }),
            const SizedBox(height: 24),
          ],
          FilledButton.icon(
            onPressed: (widget.fromPlace != null &&
                    widget.toPlace != null &&
                    widget.graphReady)
                ? widget.onFindRoute
                : null,
            icon: const Icon(Icons.search),
            label: Text('find_route'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required TextEditingController controller,
    required SavedPlace? place,
    required bool isFrom,
    required List<GeocodingResult> suggestions,
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
                  isFrom ? Icons.trip_origin : Icons.location_on,
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
              onChanged: (value) => _onLocationFieldChanged(value, isFrom),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: 'enter_location_hint'.tr(),
                suffixIcon: (isFrom
                        ? _isGettingFromLocation
                        : _isGettingToLocation)
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: ShimmerContainer(
                          child: ShimmerBox(width: 20, height: 20),
                        ),
                      )
                    : controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _clearField(isFrom),
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (isFrom
                            ? _isGettingFromLocation
                            : _isGettingToLocation)
                        ? null
                        : () => _getCurrentLocation(isFrom),
                    icon: (isFrom
                            ? _isGettingFromLocation
                            : _isGettingToLocation)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: ShimmerContainer(
                              child: ShimmerBox(width: 16, height: 16),
                            ),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: Text('current_location'.tr(),
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickFromMap(isFrom),
                    icon: const Icon(Icons.map, size: 18),
                    label: Text('pick_from_map'.tr(),
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              ],
            ),
            if ((isFrom ? _isFromSearching : _isToSearching) &&
                suggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: ShimmerContainer(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: 4,
                    borderRadius: 2,
                  ),
                ),
              ),
            if (suggestions.isNotEmpty)
              _buildSuggestionsList(suggestions, isFrom),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(
      List<GeocodingResult> suggestions, bool isFrom) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.only(top: 8),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = suggestions[index];
          final isStop = s.type == 'stop';
          return ListTile(
            dense: true,
            leading: Icon(
              isStop ? Icons.directions_bus : Icons.location_on,
              size: 20,
              color: isStop
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.error,
            ),
            title: Text(
              s.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            subtitle: Text(
              isStop ? 'bus_stop'.tr() : 'address'.tr(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            onTap: () => _selectSuggestion(s, isFrom),
          );
        },
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showPreferences = !_showPreferences),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.tune, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'route_preferences'.tr(),
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showPreferences ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  SwitchListTile(
                    title: Text('minimize_transfers'.tr()),
                    subtitle: Text('minimize_transfers_desc'.tr()),
                    value: widget.preferences.minimizeTransfers,
                    onChanged: (v) => widget.onPreferencesChanged(
                      widget.preferences.copyWith(minimizeTransfers: v),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('max_walking_distance'.tr()),
                    subtitle: Slider(
                      value:
                          widget.preferences.maxWalkingDistance.toDouble(),
                      min: 100,
                      max: 2000,
                      divisions: 19,
                      label: '${widget.preferences.maxWalkingDistance}m',
                      onChanged: (v) => widget.onPreferencesChanged(
                        widget.preferences
                            .copyWith(maxWalkingDistance: v.round()),
                      ),
                    ),
                    trailing:
                        Text('${widget.preferences.maxWalkingDistance}m'),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('accessible_route'.tr()),
                    subtitle: Text('accessible_route_desc'.tr()),
                    value: widget.preferences.preferAccessibility,
                    onChanged: (v) => widget.onPreferencesChanged(
                      widget.preferences.copyWith(preferAccessibility: v),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _showPreferences
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRouteCard(RecentRoute route, int index) {
    return Dismissible(
      key: ValueKey('recent_${index}_${route.timestamp.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDeleteRecentSearch(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => widget.onSelectRecentRoute(route),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trip_origin, size: 12,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              route.from.name,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12,
                              color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              route.to.name,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).hintColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
