import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BestRoutePage extends StatefulWidget {
  const BestRoutePage({super.key});

  @override
  State<BestRoutePage> createState() => _BestRoutePageState();
}

class _BestRoutePageState extends State<BestRoutePage> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _startLocationController =
      TextEditingController();
  bool _canGetDirections = false;
  bool _loadingStartLocation = false;
  bool _loadingDestination = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16.0),
            const Text('Βρίσκομαι κοντά σε ...'),
            const SizedBox(height: 8.0),
            TextField(
              controller: _startLocationController,
              decoration: InputDecoration(
                labelText: 'Διεύθυνση - Οδό',
                border: const OutlineInputBorder(),
                suffixIcon: _loadingStartLocation
                    ? const CircularProgressIndicator.adaptive()
                    : IconButton(
                        onPressed: () => _getCurrentLocation(isStart: true),
                        icon: const Icon(Icons.my_location),
                      ),
              ),
              onChanged: (_) => _validateFields(),
            ),
            const SizedBox(height: 16.0),
            const Text('Θέλω να πάω σε ...'),
            const SizedBox(height: 8.0),
            TextField(
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Διεύθυνση - Οδό',
                border: const OutlineInputBorder(),
                suffixIcon: _loadingDestination
                    ? const CircularProgressIndicator.adaptive()
                    : IconButton(
                        onPressed: () => _getCurrentLocation(isStart: false),
                        icon: const Icon(Icons.my_location),
                      ),
              ),
              onChanged: (_) => _validateFields(),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _canGetDirections ? _launchMaps : null,
              child: const Text('Get Directions'),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Get directions based on the provided addresses and will open Google Maps to find the best bus route.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _validateFields() {
    setState(() {
      _canGetDirections = _startLocationController.text.isNotEmpty &&
          _destinationController.text.isNotEmpty;
    });
  }

  Future<void> _getCurrentLocation({required bool isStart}) async {
    setState(() {
      if (isStart) {
        _loadingStartLocation = true;
      } else {
        _loadingDestination = true;
      }
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        if (isStart) {
          _loadingStartLocation = false;
        } else {
          _loadingDestination = false;
        }
      });
      return;
    } else {
      await Geolocator.requestPermission();
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        if (isStart) {
          _loadingStartLocation = false;
        } else {
          _loadingDestination = false;
        }
      });
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      setState(() {
        String text = '${placemarks[0].street},'
            ' ${placemarks[0].locality},'
            ' ${placemarks[0].postalCode},'
            ' ${placemarks[0].country}';
        if (isStart) {
          _startLocationController.text = text;
          _loadingStartLocation = false;
        } else {
          _destinationController.text = text;
          _loadingDestination = false;
        }
        _validateFields(); // Check if fields are filled after setting start location
      });
    } else {
      setState(() {
        if (isStart) {
          _loadingStartLocation = false;
        } else {
          _loadingDestination = false;
        }
      });
    }
  }

  Future<void> _launchMaps() async {
    String startLocation = _startLocationController.text;
    String destination = _destinationController.text;
    String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&origin=$startLocation&destination=$destination&travelmode=transit';
    if (await canLaunchUrlString(googleMapsUrl)) {
      await launchUrlString(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _startLocationController.dispose();
    super.dispose();
  }
}
