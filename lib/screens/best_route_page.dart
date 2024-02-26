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
  String _startLocation = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _loading
                ? const CircularProgressIndicator.adaptive()
                : ElevatedButton(
                    onPressed: () {
                      _getCurrentLocation();
                    },
                    child: const Text('Get Current Location Street'),
                  ),
            const SizedBox(height: 16.0),
            TextField(
              controller: TextEditingController(text: _startLocation),
              decoration: const InputDecoration(
                labelText: 'Start Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _launchMaps();
              },
              child: const Text('Get Directions'),
            ),
          ],
        ),
      ),
    );
  }

  _getCurrentLocation() async {
    setState(() {
      _loading = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _loading = false;
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
        _loading = false;
      });
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      setState(() {
        _startLocation = '${placemarks[0].street},'
                ' ${placemarks[0].locality},'
                ' ${placemarks[0].postalCode},'
                ' ${placemarks[0].country}'
            .toString();
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  _launchMaps() async {
    String startLocation = _startLocation;
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
    super.dispose();
  }
}
