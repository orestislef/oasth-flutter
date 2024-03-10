import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/stop_details.dart';
import 'package:oasth/helpers/language_helper.dart';

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
        title: Text(LanguageHelper.getLanguageUsedInApp(context) == 'en'
            ? widget.stop.stopDescriptionEng!
            : widget.stop.stopDescription!),
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
                    '${'street'.tr()}: ${widget.stop.stopStreet ?? 'n_a'.tr()}'),
                if (widget.stop.stopStreetEng != null &&
                    widget.stop.stopStreetEng!.isNotEmpty)
                  Text(
                      '${'english_street'.tr()}: ${widget.stop.stopStreetEng ?? 'n_a'.tr()}'),
                Text(
                    '${'route_stop_order'.tr()}: ${widget.stop.routeStopOrder}'),
                Text(
                    '${'stop_amea'.tr()}: ${widget.stop.stopAmea == '0' ? '❌' : '✔️'}'),
                const SizedBox(height: 10.0),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'stop_interval_hint'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w300),
                    textAlign: TextAlign.right,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.rectangle,
                    border: Border(
                      top: BorderSide(width: 2.0, color: Colors.blue.shade900),
                      left: BorderSide(width: 2.0, color: Colors.blue.shade900),
                      right:
                          BorderSide(width: 2.0, color: Colors.blue.shade900),
                      bottom:
                          BorderSide(width: 2.0, color: Colors.blue.shade900),
                    ),
                    borderRadius: const BorderRadius.all(
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
                                return Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                        '${'bus'.tr()}: ${stopArrivals.stopDetails[index].routeCode!} ${'in'.tr()} ${stopArrivals.stopDetails[index].btime2!} ${'minutes'.tr()}',
                                        style: const TextStyle(
                                          color: Colors.amberAccent,
                                        ),
                                      ),
                                    ),
                                    index != stopArrivals.stopDetails.length - 1
                                        ? const Divider(
                                            color: Colors.amberAccent,
                                            thickness: 0.5,
                                            indent: 1.0,
                                            endIndent: 10.0,
                                          )
                                        : Container(),
                                  ],
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: FlutterMap(
                mapController: MapController(),
                options: MapOptions(
                  maxZoom: 18.0,
                  minZoom: 8.0,
                  initialCenter: LatLng(
                    double.parse(widget.stop.stopLat!),
                    double.parse(widget.stop.stopLng!),
                  ),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.oasth.oast',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        rotate: true,
                        width: 40.0,
                        height: 40.0,
                        point: LatLng(double.parse(widget.stop.stopLat!),
                            double.parse(widget.stop.stopLng!)),
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade900),
                          child: const Icon(
                            Icons.follow_the_signs,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
