import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationHelper {
  static Future<Position?> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Get user's location
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<dynamic> explainLocationPermission({required BuildContext context}) {
    return showAdaptiveDialog(
      context: context,
      builder: (context) => _buildDialog(context),
    );
  }

  Widget _buildDialog(BuildContext context) {
    return AlertDialog(
      title: Text('location_permission_explain'.tr()),
      actions: [
        TextButton(
          child: Text('no'.tr()),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: Text('yes'.tr()),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
