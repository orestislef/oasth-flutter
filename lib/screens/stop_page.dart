import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/stop_details.dart';

class StopPage extends StatefulWidget {
  const StopPage({super.key, required this.stop});

  final Stop stop;

  @override
  State<StopPage> createState() => _StopPageState();
}

class _StopPageState extends State<StopPage> {
  late Timer _timer;
  late Future<StopArrivals> _futureStopArrivals;

  @override
  void initState() {
    super.initState();
    _futureStopArrivals = Api.getStopArrivals(widget.stop.stopCode!);
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      setState(() {
        _futureStopArrivals = Api.getStopArrivals(widget.stop.stopCode!);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stop.stopDescription),
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
                Text(
                    '${'english_description'.tr()}: ${widget.stop.stopDescriptionEng}'),
                Text(
                    '${'street'.tr()}: ${widget.stop.stopStreet ?? 'n_a'.tr()}}'),
                if (widget.stop.stopStreetEng != null &&
                    widget.stop.stopStreetEng.isNotEmpty)
                  Text(
                      '${'english_street'.tr()}: ${widget.stop.stopStreetEng ?? 'n_a'.tr()}'),
                Text(
                    '${'route_stop_order'.tr()}: ${widget.stop.routeStopOrder}'),
                Text(
                    '${'stop_amea'.tr()}: ${widget.stop.stopAmea == '0' ? '❌' : '✔️'}'),
                const SizedBox(height: 10.0),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.rectangle,
                    border: Border(
                      top: BorderSide(width: 2.0, color: Colors.blueGrey),
                      left: BorderSide(width: 2.0, color: Colors.blueGrey),
                      right: BorderSide(width: 2.0, color: Colors.blueGrey),
                      bottom: BorderSide(width: 2.0, color: Colors.blueGrey),
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(15.0),
                    ),
                  ),
                  height: MediaQuery.of(context).size.height * 0.20,
                  width: double.infinity,
                  child: FutureBuilder(
                    future: _futureStopArrivals,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(
                            backgroundColor: Colors.blueGrey,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.amber),
                          ),
                        );
                      } else if (snapshot.hasData) {
                        StopArrivals stopArrivals =
                            snapshot.data as StopArrivals;
                        if (stopArrivals.stopDetails.isEmpty) {
                          return Center(
                            child: Text(
                              'no_stop_details'.tr(),
                              style: const TextStyle(
                                color: Colors.amberAccent,
                              ),
                            ),
                          );
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
                                    '${'in'.tr()} ${stopArrivals.stopDetails[index].btime2!} ${'minutes'.tr()}',
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            '${'error'.tr()}: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else {
                        return const Center(
                          child: Text(
                            'Unknown error',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }
                    },
                  ),
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
                  double.parse(widget.stop.stopLat),
                  double.parse(widget.stop.stopLng),
                ),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.oasth.oast',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(double.parse(widget.stop.stopLat),
                          double.parse(widget.stop.stopLng)),
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
