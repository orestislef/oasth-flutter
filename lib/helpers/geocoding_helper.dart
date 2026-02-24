import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String type; // 'address' or 'stop'

  const GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.type,
  });
}

class GeocodingHelper {
  // Thessaloniki bounding box
  static const double _minLon = 22.7;
  static const double _maxLon = 23.1;
  static const double _minLat = 40.5;
  static const double _maxLat = 40.75;

  /// Reverse geocode coordinates to a human-readable address.
  /// Uses the native geocoding package (no API key needed on mobile).
  /// Falls back to Nominatim if native geocoding fails.
  static Future<String> reverseGeocode(double lat, double lng) async {
    if (!kIsWeb) {
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];
          if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
          if (p.subLocality != null && p.subLocality!.isNotEmpty) {
            parts.add(p.subLocality!);
          }
          if (p.locality != null && p.locality!.isNotEmpty) {
            parts.add(p.locality!);
          }
          if (parts.isNotEmpty) return parts.join(', ');
        }
      } catch (e) {
        debugPrint('[Geocoding] Native reverse geocoding failed: $e');
      }
    } else {
      debugPrint('[Geocoding] Skipping native reverse geocoding on web');
    }

    // Fallback to Nominatim
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?format=json&lat=$lat&lon=$lng&zoom=18'
          '&accept-language=en',
        ),
        headers: {'User-Agent': 'OasthTelematicsApp/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final parts = <String>[];
          final road =
              address['road'] ?? address['pedestrian'] ?? address['footway'];
          if (road != null) parts.add(road.toString());
          final number = address['house_number'];
          if (number != null && parts.isNotEmpty) {
            parts[0] = '${parts[0]} $number';
          }
          final suburb = address['suburb'] ?? address['neighbourhood'];
          if (suburb != null) parts.add(suburb.toString());
          if (parts.isNotEmpty) return parts.join(', ');
          return data['display_name']?.toString() ??
              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        }
      }
    } catch (e) {
      debugPrint('[Geocoding] Nominatim reverse geocoding failed: $e');
    }

    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  /// Search for addresses in the Thessaloniki area using Nominatim (free, no key).
  static Future<List<GeocodingResult>> searchAddress(String query) async {
    if (query.length < 3) return [];

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json'
        '&q=${Uri.encodeComponent(query)}'
        '&countrycodes=gr'
        '&viewbox=$_minLon,$_minLat,$_maxLon,$_maxLat'
        '&bounded=1'
        '&limit=5'
        '&addressdetails=1'
        '&accept-language=en',
      );

      final response = await http.get(uri, headers: {
        'User-Agent': 'OasthTelematicsApp/1.0'
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return GeocodingResult(
            displayName: _buildShortName(item as Map<String, dynamic>),
            latitude: double.tryParse(item['lat']?.toString() ?? '') ?? 0,
            longitude: double.tryParse(item['lon']?.toString() ?? '') ?? 0,
            type: 'address',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[Geocoding] Address search failed: $e');
    }

    return [];
  }

  static String _buildShortName(Map<String, dynamic> item) {
    final address = item['address'] as Map<String, dynamic>?;
    if (address != null) {
      final parts = <String>[];
      final road = address['road'] ?? address['pedestrian'];
      if (road != null) parts.add(road.toString());
      final houseNumber = address['house_number'];
      if (houseNumber != null && parts.isNotEmpty) {
        parts[0] = '${parts[0]} $houseNumber';
      }
      final suburb = address['suburb'] ?? address['neighbourhood'];
      if (suburb != null) parts.add(suburb.toString());
      final city = address['city'] ?? address['town'] ?? address['village'];
      if (city != null) parts.add(city.toString());
      if (parts.isNotEmpty) return parts.join(', ');
    }
    final displayName = item['display_name']?.toString() ?? '';
    if (displayName.length > 60) {
      return '${displayName.substring(0, 57)}...';
    }
    return displayName;
  }
}
