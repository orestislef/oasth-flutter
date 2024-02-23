import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/stop_details.dart';

class StopPage extends StatelessWidget {
  const StopPage({super.key, required this.stop});

  final Stops stop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stop.stopDescription),
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
                Text('Description: ${stop.stopDescription}'),
                Text('English Description: ${stop.stopDescriptionEng}'),
                Text('Street: ${stop.stopStreet ?? "N/A"}'),
                Text('English Street: ${stop.stopStreetEng ?? "N/A"}'),
                Text('Heading: ${stop.stopHeading}'),
                Text('Latitude: ${stop.stopLat}'),
                Text('Longitude: ${stop.stopLng}'),
                Text('Route Stop Order: ${stop.routeStopOrder}'),
                Text('Stop Type: ${stop.stopType}'),
                Text('Stop Amea: ${stop.stopAmea}'),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.rectangle,
                    border: Border(
                      top: BorderSide(width: 2.0, color: Colors.grey),
                      left: BorderSide(width: 2.0, color: Colors.grey),
                      right: BorderSide(width: 2.0, color: Colors.grey),
                      bottom: BorderSide(width: 2.0, color: Colors.grey),
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                  height: MediaQuery.of(context).size.height * 0.20,
                  width: double.infinity,
                  child: FutureBuilder(
                      future: Api.getStopArrivals(stop.stopCode!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          StopArrivals stopArrivals = snapshot.data!;
                          if (stopArrivals.stopDetails.isEmpty) {
                            return const Text('No stop details found');
                          } else {
                            return Scrollbar(
                              child: ListView.builder(
                                itemCount: stopArrivals.stopDetails.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return ListTile(
                                    leading: Text(
                                      '| Bus: ${stopArrivals.stopDetails[index].routeCode!} |',
                                      style: const TextStyle(
                                          color: Colors.amberAccent),
                                    ),
                                    title: Text(
                                      'in ${stopArrivals.stopDetails[index].btime2!} minutes',
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                    trailing: Text(
                                      'veh code: ${stopArrivals.stopDetails[index].vehCode!}',
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        } else {
                          return const Text('Loading...');
                        }
                      }),
                ),
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
