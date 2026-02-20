import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BestRoutePage extends StatefulWidget {
  const BestRoutePage({super.key});

  @override
  State<BestRoutePage> createState() => _BestRoutePageState();
}

class _BestRoutePageState extends State<BestRoutePage> with TickerProviderStateMixin {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _startLocationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _canGetDirections = false;
  bool _loadingStartLocation = false;
  bool _loadingDestination = false;
  bool _hasLocationPermission = false;
  String? _errorMessage;
  String _selectedTravelMode = 'transit';
  List<String> _recentSearches = [];

  final Map<String, IconData> _travelModes = {
    'transit': Icons.directions_bus,
    'walking': Icons.directions_walk,
    'driving': Icons.directions_car,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _startLocationController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    setState(() {
      _hasLocationPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
  }

  void _validateFields() {
    setState(() {
      _canGetDirections = _startLocationController.text.trim().isNotEmpty &&
          _destinationController.text.trim().isNotEmpty;
    });
  }

  void _swapLocations() {
    setState(() {
      final temp = _startLocationController.text;
      _startLocationController.text = _destinationController.text;
      _destinationController.text = temp;
      _validateFields();
    });
  }

  void _clearFields() {
    setState(() {
      _startLocationController.clear();
      _destinationController.clear();
      _canGetDirections = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLocationInputs(context),
                    const SizedBox(height: 24),
                    _buildTravelModeSelector(context),
                    const SizedBox(height: 24),
                    _buildDirectionsButton(context),
                    const SizedBox(height: 24),
                    _buildInfoSection(context),
                    if (_recentSearches.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildRecentSearches(context),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withAlpha(25),
            Theme.of(context).primaryColor.withAlpha(12),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.route,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'route_planner'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'find_best_route'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(178),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInputs(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'journey_details'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_startLocationController.text.isNotEmpty || _destinationController.text.isNotEmpty)
                  IconButton(
                    onPressed: _clearFields,
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'clear_all_fields'.tr(),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // From field
            _buildLocationField(
              context: context,
              controller: _startLocationController,
              label: 'from_location'.tr(),
              hint: 'enter_starting_point'.tr(),
              icon: Icons.trip_origin,
              isLoading: _loadingStartLocation,
              onLocationTap: () => _getCurrentLocation(isStart: true),
              onChanged: (_) => _validateFields(),
            ),
            
            const SizedBox(height: 12),
            
            // Swap button
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: _swapLocations,
                  icon: const Icon(Icons.swap_vert),
                  tooltip: 'swap_locations'.tr(),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // To field
            _buildLocationField(
              context: context,
              controller: _destinationController,
              label: 'to_location'.tr(),
              hint: 'enter_destination'.tr(),
              icon: Icons.location_on,
              isLoading: _loadingDestination,
              onLocationTap: () => _getCurrentLocation(isStart: false),
              onChanged: (_) => _validateFields(),
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
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
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onLocationTap,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: isLoading
                ? Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(12),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : _hasLocationPermission
                    ? IconButton(
                        onPressed: onLocationTap,
                        icon: const Icon(Icons.my_location),
                        tooltip: 'use_current_location'.tr(),
                      )
                    : IconButton(
                        onPressed: _requestLocationPermission,
                        icon: const Icon(Icons.location_disabled),
                        tooltip: 'enable_location'.tr(),
                      ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTravelModeSelector(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'travel_mode'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _travelModes.entries.map((entry) {
                  final isSelected = _selectedTravelMode == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTravelMode = entry.key;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              entry.value,
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getTravelModeLabel(entry.key),
                              style: TextStyle(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTravelModeLabel(String mode) {
    switch (mode) {
      case 'transit':
        return 'public_transport'.tr();
      case 'walking':
        return 'walking'.tr();
      case 'driving':
        return 'driving'.tr();
      default:
        return mode;
    }
  }

  Widget _buildDirectionsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _canGetDirections ? _launchMaps : null,
        icon: const Icon(Icons.navigation),
        label: Text(
          'get_directions'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'how_it_works'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              context,
              Icons.edit_location,
              'enter_locations'.tr(),
              'enter_locations_description'.tr(),
            ),
            _buildInfoItem(
              context,
              Icons.directions,
              'choose_travel_mode'.tr(),
              'choose_travel_mode_description'.tr(),
            ),
            _buildInfoItem(
              context,
              Icons.open_in_new,
              'get_directions'.tr(),
              'get_directions_description'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(178),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'recent_searches'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._recentSearches.map((search) => ListTile(
              dense: true,
              leading: const Icon(Icons.history),
              title: Text(search),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Handle recent search selection
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation({required bool isStart}) async {
    setState(() {
      if (isStart) {
        _loadingStartLocation = true;
      } else {
        _loadingDestination = true;
      }
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('location_services_disabled'.tr());
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('location_permission_denied'.tr());
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('location_permission_permanently_denied'.tr());
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        String address = [
          placemark.street,
          placemark.locality,
          placemark.postalCode,
          placemark.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        setState(() {
          if (isStart) {
            _startLocationController.text = address;
          } else {
            _destinationController.text = address;
          }
        });
        _validateFields();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        if (isStart) {
          _loadingStartLocation = false;
        } else {
          _loadingDestination = false;
        }
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    setState(() {
      _hasLocationPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });

    if (!_hasLocationPermission) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('location_permission_required'.tr()),
        content: Text('location_permission_explanation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: Text('open_settings'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMaps() async {
    if (!_canGetDirections) return;

    try {
      String startLocation = _startLocationController.text.trim();
      String destination = _destinationController.text.trim();
      
      String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${Uri.encodeComponent(startLocation)}'
          '&destination=${Uri.encodeComponent(destination)}'
          '&travelmode=$_selectedTravelMode';

      if (await canLaunchUrlString(googleMapsUrl)) {
        await launchUrlString(googleMapsUrl);
        
        // Add to recent searches (you could persist this)
        setState(() {
          String searchEntry = '$startLocation → $destination';
          _recentSearches.removeWhere((search) => search == searchEntry);
          _recentSearches.insert(0, searchEntry);
          if (_recentSearches.length > 5) {
            _recentSearches = _recentSearches.take(5).toList();
          }
        });
      } else {
        setState(() {
          _errorMessage = 'could_not_open_maps'.tr();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'error_launching_maps'.tr();
      });
    }
  }
}