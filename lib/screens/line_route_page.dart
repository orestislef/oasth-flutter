import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/screens/stop_page.dart';

class RoutePage extends StatelessWidget {
  const RoutePage(
      {super.key,
      required this.details,
      required this.stops,
      this.hasAppBar = true});

  //have to pass ROUTE_CODE to take bus location info

  final bool hasAppBar;
  final List<Details> details;
  final List<Stops> stops;

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
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.20,
          rotate: true,
          point: LatLng(double.parse(stop.stopLat), double.parse(stop.stopLng)),
          child: InkWell(
            enableFeedback: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StopPage(stop: stop),
                ),
              );
            },
            child: Column(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(5.0),
                    backgroundBlendMode: BlendMode.luminosity,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4.0, 2.0, 2.0, 4.0),
                    child: Text(
                      stop.stopDescription,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    backgroundBlendMode: BlendMode.difference,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.signpost_outlined,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
        appBar: hasAppBar
            ? AppBar(
                title: const Text('Route'),
              )
            : null,
        body: FlutterMap(
          mapController: MapController(),
          options: MapOptions(
            applyPointerTranslucencyToLayers: true,
            initialCameraFit: CameraFit.coordinates(
              coordinates: points,
              padding: const EdgeInsets.all(20.0),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
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
        ));
  }
}
