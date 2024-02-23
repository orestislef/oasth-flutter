import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:oasth/route_detail_and_stops.dart';

class StopPage extends StatelessWidget {
  const StopPage({super.key, required this.stop});

  final StopsBean stop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stop.stopDescr),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Show all information
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description: ${stop.stopDescr}'),
                Text('English Description: ${stop.stopDescrEng}'),
                Text('Street: ${stop.stopStreet ?? "N/A"}'),
                Text('English Street: ${stop.stopStreetEng ?? "N/A"}'),
                Text('Heading: ${stop.stopHeading}'),
                Text('Latitude: ${stop.stopLat}'),
                Text('Longitude: ${stop.stopLng}'),
                Text('Route Stop Order: ${stop.routeStopOrder}'),
                Text('Stop Type: ${stop.stopType}'),
                Text('Stop Amea: ${stop.stopAmea}'),
                const Text('Get Route Details'),
              ],
            ),
          ),
          // Map with a marker
          Expanded(
            child: FlutterMap(
              mapController: MapController(),
              options: MapOptions(
                initialCenter: LatLng(
                    double.parse(stop.stopLat), double.parse(stop.stopLng)),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(double.parse(stop.stopLat),
                          double.parse(stop.stopLng)),
                      child: const Icon(Icons.location_on),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
