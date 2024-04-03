import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/helpers/language_helper.dart';
import 'package:oasth/helpers/location_helper.dart';
import 'package:oasth/helpers/text_broadcaster.dart';
import 'package:oasth/screens/stop_page.dart';

import '../api/responses/route_detail_and_stops.dart';

class MapWithNearbyStations extends StatefulWidget {
  const MapWithNearbyStations({super.key, this.hasBackButton = false});

  final bool hasBackButton;

  @override
  State<MapWithNearbyStations> createState() => _MapWithNearbyStationsState();
}

class _MapWithNearbyStationsState extends State<MapWithNearbyStations> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: widget.hasBackButton
          ? FloatingActionButton.extended(
              backgroundColor: Colors.blue.shade900,
              onPressed: () {
                Navigator.pop(context);
              },
              label: Text('back'.tr(),
                  style: const TextStyle(color: Colors.white)),
              icon: Icon(Icons.adaptive.arrow_back, color: Colors.white),
            )
          : null,
      body: FutureBuilder(
        future: LocationHelper.getUserLocation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          LocationData? locationData = snapshot.data;
          return FutureBuilder(
              future: Api.getAllStops2(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const CircularProgressIndicator.adaptive(),
                        const SizedBox(height: 10),
                        Text('loading_nearby_stops'.tr(),
                            textAlign: TextAlign.start),
                        const SizedBox(height: 10),
                        StreamBuilder<String>(
                            stream: TextBroadcaster.getTextStream(),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? '',
                                textAlign: TextAlign.start,
                              );
                            }),
                      ],
                    ),
                  );
                }
                return _mapWithStations(
                    stops: snapshot.data as List<Stop>,
                    locationData: locationData);
              });
        },
      ),
    );
  }

  Widget _mapWithStations(
      {required List<Stop> stops, required LocationData? locationData}) {
    MapController mapController = MapController();
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialRotation: locationData?.heading ?? 0.0,
        maxZoom: 18.0,
        minZoom: 8.0,
        initialCenter: LatLng(
          locationData?.latitude ?? 40.629269,
          locationData?.longitude ?? 22.947412,
        ),
        initialZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.oasth.oast',
        ),
        CurrentLocationLayer(
          alignPositionOnUpdate: AlignOnUpdate.once,
          alignDirectionOnUpdate: AlignOnUpdate.once,
          style: const LocationMarkerStyle(
            marker: DefaultLocationMarker(
              child: Icon(
                Icons.navigation,
                color: Colors.white,
              ),
            ),
            markerSize: Size(40, 40),
            markerDirection: MarkerDirection.heading,
          ),
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            rotate: true,
            maxZoom: 18.0,
            size: const Size(40, 40),
            markers: _buildMarkers(stops: stops),
            builder: (BuildContext context, List<Marker> markers) {
              return markers.isNotEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue[900]?.withOpacity(0.7),
                      ),
                      child: Center(
                        child: Text(
                          _buildClusterMarkerCount(markers.length),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers({required List<Stop> stops}) {
    List<Marker> markers = [];
    for (var stop in stops) {
      markers.add(
        Marker(
            height: 70,
            width: 200,
            rotate: true,
            point: LatLng(
              double.parse(stop.stopLat!),
              double.parse(stop.stopLng!),
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
                          ? stop.stopDescriptionEng ?? 'no_description'.tr()
                          : stop.stopDescription ?? 'no_description'.tr(),
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

  String _buildClusterMarkerCount(int length) {
    if (length <= 1000) {
      return length.toString();
    } else if (length <= 10000) {
      return '~${length ~/ 1000}k';
    } else if (length <= 1000000) {
      return '~${(length ~/ 1000).toStringAsFixed(0)}k';
    }

    return '999k+';
  }
}
