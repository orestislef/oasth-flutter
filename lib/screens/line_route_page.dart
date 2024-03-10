import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/bus_location.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/screens/stop_page.dart';

class RoutePage extends StatelessWidget {
  const RoutePage(
      {super.key,
      required this.details,
      required this.stops,
      this.hasAppBar = true,
      required this.routeCode});

  final bool hasAppBar;
  final List<Details> details;
  final List<Stop> stops;
  final String routeCode;

  @override
  Widget build(BuildContext context) {
    List<LatLng> points = [];
    for (var detail in details) {
      points.add(
          LatLng(double.parse(detail.routedY), double.parse(detail.routedX)));
    }

    List<Marker> markers = [];
    for (var stop in stops) {
      markers.add(
        Marker(
          width: 100,
          height: 300,
          rotate: true,
          alignment: Alignment.center,
          point: LatLng(double.parse(stop.stopLat), double.parse(stop.stopLng)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.black),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Text(
                  stop.stopDescription,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              IconButton.filled(
                icon: const Icon(Icons.follow_the_signs),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StopPage(stop: stop),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: hasAppBar
          ? AppBar(
              title: Text('route'.tr()),
            )
          : null,
      body: FutureBuilder<BusLocation>(
        future: Api.getBusLocation(routeCode),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            BusLocation busLocation = snapshot.data!;
            return _buildMap(
                context: context,
                points: points,
                markers: markers,
                busLocation: busLocation);
          } else {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
        },
      ),
    );
  }

  Widget _buildMap(
      {required BuildContext context,
      required List<LatLng> points,
      required List<Marker> markers,
      required BusLocation busLocation}) {
    if (busLocation.busLocation.isNotEmpty) {
      for (var bus in busLocation.busLocation) {
        markers.add(
          Marker(
            rotate: true,
            alignment: Alignment.center,
            point: LatLng(double.parse(bus.csLat!), double.parse(bus.csLng!)),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(5.0),
                  backgroundBlendMode: BlendMode.difference),
              child: const Icon(Icons.directions_bus_outlined),
            ),
          ),
        );
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: FlutterMap(
        mapController: MapController(),
        options: MapOptions(
          maxZoom: 18.0,
          minZoom: 8.0,
          applyPointerTranslucencyToLayers: true,
          initialCameraFit: CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(20.0),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          PolylineLayer(polylines: [
            Polyline(
              gradientColors: [Colors.blue, Colors.red],
              points: points,
              strokeWidth: 5,
              strokeJoin: StrokeJoin.round,
            ),
          ]),
          MarkerLayer(
            markers: markers,
            alignment: Alignment.center,
          ),
        ],
      ),
    );
  }
}
