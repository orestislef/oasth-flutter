import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/helpers/language_helper.dart';
import 'package:oasth/helpers/location_helper.dart';
import 'package:oasth/screens/stop_page.dart';

import '../api/responses/route_detail_and_stops.dart';

class MapWithNearbyStations extends StatefulWidget {
  const MapWithNearbyStations({super.key});

  @override
  State<MapWithNearbyStations> createState() => _MapWithNearbyStationsState();
}

class _MapWithNearbyStationsState extends State<MapWithNearbyStations> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: LocationHelper.getUserLocation(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          LocationData? locationData = snapshot.data;
          if (locationData != null) {
            return FutureBuilder(
                future: Api.getAllStops(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _mapWithStations(
                        stops: snapshot.data as List<Stop>,
                        locationData: locationData);
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                });
          }
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _mapWithStations(
      {required List<Stop> stops, required LocationData locationData}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 400,
        child: FlutterMap(
          mapController: MapController(),
          options: MapOptions(
            initialCenter: LatLng(
              locationData.latitude!,
              locationData.longitude!,
            ),
            initialZoom: 17.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.oasth.oast',
            ),
            MarkerLayer(
              markers: _buildMarkers(stops: stops, locationData: locationData),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(
      {required List<Stop> stops, required LocationData locationData}) {
    List<Marker> markers = [];
    markers.add(
      Marker(
        rotate: true,
        point: LatLng(locationData.latitude!, locationData.longitude!),
        child: const Icon(
          Icons.circle,
          color: Colors.blue,
          size: 30,
        ),
      ),
    );
    for (var stop in stops) {
      markers.add(
        Marker(
            height: 70,
            width: 200,
            rotate: true,
            point: LatLng(
              double.parse(stop.stopLat),
              double.parse(stop.stopLng),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      LanguageHelper.getLanguageUsedInApp(context) == 'en'
                          ? stop.stopDescriptionEng
                          : stop.stopDescription,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    elevation: 10.0,
                    shadowColor: Colors.blue.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  onPressed: () {
                    _onPressMarker(stop: stop);
                  },
                  icon: const Icon(
                    Icons.follow_the_signs,
                    size: 15,
                  ),
                ),
              ],
            )),
      );
    }
    return markers;
  }

  void _onPressMarker({required Stop stop}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StopPage(
          stop: stop,
        ),
      ),
    );
  }
}
