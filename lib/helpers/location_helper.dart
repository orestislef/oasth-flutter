import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class LocationHelper {
  static Future<LocationData?> getUserLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    // Check location permissions
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    // Get user's location
    try {
      locationData = await location.getLocation();
      return locationData;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<dynamic> explainLocationPermission({required BuildContext context}) {
    return showAdaptiveDialog(
      context: context,
      builder: _buildDialog(),
    );
  }

  _buildDialog() {
    return Builder(
      builder: (context) {
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
      },
    );
  }
}
